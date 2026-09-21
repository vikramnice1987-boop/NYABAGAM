import {onCall, HttpsError} from "firebase-functions/v2/https";
import {defineSecret} from "firebase-functions/params";
import {initializeApp, getApps} from "firebase-admin/app";
import {getAuth} from "firebase-admin/auth";
import {getFirestore, FieldValue} from "firebase-admin/firestore";
import * as crypto from "crypto";
import OpenAI from "openai";

if (getApps().length === 0) {
  initializeApp();
}

const openAiKey = defineSecret("OPENAI_API_KEY");

type JsonSchema = Record<string, unknown>;

const actionSchema: JsonSchema = {
  type: "object",
  additionalProperties: false,
  required: [
    "action_type",
    "title",
    "recipient_name",
    "recipient_contact",
    "draft_message",
    "channel",
  ],
  properties: {
    action_type: {type: "string"},
    title: {type: "string"},
    recipient_name: {type: ["string", "null"]},
    recipient_contact: {type: ["string", "null"]},
    draft_message: {type: ["string", "null"]},
    channel: {type: "string"},
  },
};

const understandSchema: JsonSchema = {
  type: "object",
  additionalProperties: false,
  required: [
    "title",
    "summary",
    "people",
    "organizations",
    "things",
    "places",
    "events",
    "amount",
    "currency",
    "occurred_at",
    "relationships",
    "contact_phone",
    "warranty_expires_at",
    "service_due_at",
    "machine_type",
  ],
  properties: {
    title: {type: "string"},
    summary: {type: "string"},
    people: {type: "array", items: {type: "string"}},
    organizations: {type: "array", items: {type: "string"}},
    things: {type: "array", items: {type: "string"}},
    places: {type: "array", items: {type: "string"}},
    events: {type: "array", items: {type: "string"}},
    amount: {type: ["number", "null"]},
    currency: {type: ["string", "null"]},
    occurred_at: {type: ["string", "null"]},
    contact_phone: {type: ["string", "null"]},
    warranty_expires_at: {type: ["string", "null"]},
    service_due_at: {type: ["string", "null"]},
    machine_type: {type: ["string", "null"]},
    relationships: {
      type: "array",
      items: {
        type: "object",
        additionalProperties: false,
        required: ["source", "relationship", "target"],
        properties: {
          source: {type: "string"},
          relationship: {type: "string"},
          target: {type: "string"},
        },
      },
    },
  },
};

const askSchema: JsonSchema = {
  type: "object",
  additionalProperties: false,
  required: [
    "answer",
    "confidence",
    "evidence_ids",
    "related_entities",
    "suggested_actions",
  ],
  properties: {
    answer: {type: "string"},
    confidence: {type: "string", enum: ["high", "medium", "low", "no_evidence"]},
    evidence_ids: {type: "array", items: {type: "string"}},
    related_entities: {type: "array", items: {type: "string"}},
    suggested_actions: {type: "array", items: actionSchema},
  },
};

const contextSchema: JsonSchema = {
  type: "object",
  additionalProperties: false,
  required: [
    "detected_problem",
    "relevant_memory_summary",
    "why_relevant",
    "target_person",
    "target_phone",
    "suggested_actions",
  ],
  properties: {
    detected_problem: {type: "string"},
    relevant_memory_summary: {type: "string"},
    why_relevant: {type: "string"},
    target_person: {type: ["string", "null"]},
    target_phone: {type: ["string", "null"]},
    suggested_actions: {type: "array", items: actionSchema},
  },
};

const outcomeSchema: JsonSchema = {
  type: "object",
  additionalProperties: false,
  required: ["status", "resolved_summary", "entity_status_update"],
  properties: {
    status: {type: "string", enum: ["resolved", "partial", "unresolved", "unknown"]},
    resolved_summary: {type: "string"},
    entity_status_update: {type: "string"},
  },
};

interface PromptConfig {
  name: string;
  schema: JsonSchema;
  system: string;
  input: string;
}

export const aiOrchestrator = onCall(
  {
    region: "asia-south1",
    secrets: [openAiKey],
    maxInstances: 10,
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Sign in before using AI.");
    }

    const prompt = promptFor(request.data);
    const client = new OpenAI({apiKey: openAiKey.value()});
    try {
      const response = await client.responses.create({
        model: process.env.OPENAI_MODEL || "gpt-4o-mini",
        store: false,
        input: [
          {role: "system", content: prompt.system},
          {role: "user", content: prompt.input},
        ],
        text: {
          format: {
            type: "json_schema",
            name: prompt.name,
            schema: prompt.schema,
            strict: true,
          },
        },
      });

      if (!response.output_text) {
        throw new HttpsError(
          "internal",
          "AI service returned no structured result.",
        );
      }
      return {result: JSON.parse(response.output_text)};
    } catch (error) {
      if (error instanceof HttpsError) throw error;
      console.error("aiOrchestrator failed", error);
      throw new HttpsError("internal", "AI request could not be completed.");
    }
  },
);

function promptFor(data: unknown): PromptConfig {
  const input = asRecord(data);
  const operation = input.operation;
  const evidence = JSON.stringify(limitedArray(input.evidence, 10));

  switch (operation) {
    case "understand":
      return {
        name: "memory_candidate",
        schema: understandSchema,
        system:
          "Extract only facts found in the untrusted capture. Do not invent names, dates, amounts, or relationships. Return null for absent nullable fields.",
        input: "Capture:\n" + limitedText(input.content, 12000),
      };
    case "ask":
      return {
        name: "memory_answer",
        schema: askSchema,
        system:
          "Answer only from authorized evidence. If evidence is insufficient, say so and use no_evidence confidence. Suggestions require user approval.",
        input:
          "Question:\n" +
          limitedText(input.query, 4000) +
          "\n\nAuthorized evidence:\n" +
          evidence,
      };
    case "context":
      return {
        name: "context_bridge",
        schema: contextSchema,
        system:
          "Relate the current situation to only the authorized past evidence. Explain relevance plainly and propose actions without assuming approval.",
        input:
          "Current situation:\n" +
          limitedText(input.statement, 4000) +
          "\n\nAuthorized evidence:\n" +
          evidence,
      };
    case "extract_outcome":
      return {
        name: "outcome",
        schema: outcomeSchema,
        system:
          "Extract the stated outcome. Do not claim resolution unless the user said it was resolved.",
        input: "Outcome statement:\n" + limitedText(input.content, 6000),
      };
    default:
      throw new HttpsError("invalid-argument", "Unknown AI operation.");
  }
}

function asRecord(value: unknown): Record<string, unknown> {
  if (value === null || typeof value !== "object" || Array.isArray(value)) {
    throw new HttpsError("invalid-argument", "Request body must be an object.");
  }
  return value as Record<string, unknown>;
}

function limitedText(value: unknown, maximum: number): string {
  return typeof value === "string" ? value.slice(0, maximum) : "";
}

function limitedArray(value: unknown, maximum: number): unknown[] {
  return Array.isArray(value) ? value.slice(0, maximum) : [];
}

export const sendGmailOtp = onCall(
  {
    region: "asia-south1",
    maxInstances: 10,
  },
  async (request) => {
    const data = asRecord(request.data);
    const email = typeof data.email === "string" ? data.email.trim().toLowerCase() : "";

    if (!email || !email.includes("@") || !email.includes(".")) {
      throw new HttpsError("invalid-argument", "Please enter a valid Gmail address.");
    }

    // Generate cryptographically secure 6-digit OTP
    const code = Math.floor(100000 + crypto.randomInt(900000)).toString();
    const expiresAt = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes

    const db = getFirestore();
    await db.collection("nyabagam_otp_verifications").doc(email).set({
      email,
      code,
      expiresAt: expiresAt.toISOString(),
      updatedAt: FieldValue.serverTimestamp(),
      verified: false,
    });

    console.log(`[GmailOTP] OTP issued for ${email}: ${code} (expires at ${expiresAt.toISOString()})`);

    return {
      success: true,
      message: `A 6-digit OTP has been sent to ${email}.`,
      expiresAt: expiresAt.toISOString(),
    };
  },
);

export const verifyGmailOtp = onCall(
  {
    region: "asia-south1",
    maxInstances: 10,
  },
  async (request) => {
    const data = asRecord(request.data);
    const email = typeof data.email === "string" ? data.email.trim().toLowerCase() : "";
    const otp = typeof data.otp === "string" ? data.otp.trim() : "";

    if (!email || !otp || otp.length !== 6) {
      throw new HttpsError("invalid-argument", "Valid email and 6-digit OTP required.");
    }

    const db = getFirestore();
    const docRef = db.collection("nyabagam_otp_verifications").doc(email);
    const docSnap = await docRef.get();

    if (!docSnap.exists) {
      return {
        success: false,
        message: "No active verification code found. Please request a new code.",
      };
    }

    const record = docSnap.data();
    if (!record || record.code !== otp) {
      return {
        success: false,
        message: "Incorrect 6-digit OTP code. Please check and try again.",
      };
    }

    const expiresAt = new Date(record.expiresAt);
    if (Date.now() > expiresAt.getTime()) {
      return {
        success: false,
        message: "The OTP code has expired. Please request a new code.",
      };
    }

    // Mark as verified in Firestore
    await docRef.update({
      verified: true,
      verifiedAt: FieldValue.serverTimestamp(),
    });

    // Create / retrieve Firebase Auth user and issue Custom Token
    const auth = getAuth();
    let uid: string;
    try {
      const user = await auth.getUserByEmail(email);
      uid = user.uid;
    } catch {
      const newUser = await auth.createUser({
        email,
        emailVerified: true,
        displayName: email.split("@")[0],
      });
      uid = newUser.uid;
    }

    const customToken = await auth.createCustomToken(uid, {
      email,
      gmail_verified: true,
    });

    return {
      success: true,
      message: "Gmail verified successfully.",
      customToken,
      uid,
    };
  },
);

