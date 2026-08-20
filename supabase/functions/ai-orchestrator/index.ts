// NYABAGAM V1 Server-Side AI Orchestrator Edge Function
// Operations: understand | ask | context | draft_action | extract_outcome

const understandCandidateSchema = {
  type: "object",
  additionalProperties: false,
  required: ["title", "summary", "people", "organizations", "things", "places", "events", "amount", "currency", "occurred_at", "relationships"],
  properties: {
    title: { type: "string", description: "Short, neutral memory title (e.g., 'AC Service by Ravi')." },
    summary: { type: "string", description: "Concise factual summary strictly grounded in input. No invented details." },
    people: { type: "array", items: { type: "string" }, description: "Names of people mentioned." },
    organizations: { type: "array", items: { type: "string" }, description: "Companies/businesses mentioned." },
    things: { type: "array", items: { type: "string" }, description: "Objects, appliances, documents, or items mentioned." },
    places: { type: "array", items: { type: "string" }, description: "Locations mentioned." },
    events: { type: "array", items: { type: "string" }, description: "Event types (e.g., service, purchase, repair)." },
    amount: { type: ["number", "null"], description: "Monetary amount if present, or null." },
    currency: { type: ["string", "null"], description: "ISO currency code if present (e.g., 'INR', 'USD')." },
    occurred_at: { type: ["string", "null"], description: "ISO timestamp if mentioned, or null." },
    relationships: {
      type: "array",
      items: {
        type: "object",
        additionalProperties: false,
        required: ["source", "relationship", "target"],
        properties: {
          source: { type: "string" },
          relationship: { type: "string", description: "serviced, works_for, owns, located_at, participant_in, related_to" },
          target: { type: "string" }
        }
      }
    }
  }
};

const askResponseSchema = {
  type: "object",
  additionalProperties: false,
  required: ["answer", "confidence", "related_entities", "suggested_actions"],
  properties: {
    answer: { type: "string", description: "Direct, concise answer grounded strictly in retrieved evidence." },
    confidence: { type: "string", enum: ["high", "medium", "low", "no_evidence"] },
    related_entities: { type: "array", items: { type: "string" } },
    suggested_actions: {
      type: "array",
      items: {
        type: "object",
        additionalProperties: false,
        required: ["action_type", "title", "target_name"],
        properties: {
          action_type: { type: "string", enum: ["message", "phone_call", "reminder", "manual"] },
          title: { type: "string" },
          target_name: { type: "string" }
        }
      }
    }
  }
};

const contextBridgeSchema = {
  type: "object",
  additionalProperties: false,
  required: ["detected_problem", "relevant_memory_summary", "why_relevant", "target_person", "suggested_actions"],
  properties: {
    detected_problem: { type: "string" },
    relevant_memory_summary: { type: "string" },
    why_relevant: { type: "string", description: "Clear, source-backed explanation of why this historical fact matters now." },
    target_person: { type: ["string", "null"] },
    suggested_actions: {
      type: "array",
      items: {
        type: "object",
        additionalProperties: false,
        required: ["action_type", "title", "channel", "draft_message"],
        properties: {
          action_type: { type: "string" },
          title: { type: "string" },
          channel: { type: "string", enum: ["whatsapp", "sms", "phone", "none"] },
          draft_message: { type: ["string", "null"] }
        }
      }
    }
  }
};

const draftActionSchema = {
  type: "object",
  additionalProperties: false,
  required: ["recipient_name", "channel", "message_body", "notes"],
  properties: {
    recipient_name: { type: "string" },
    channel: { type: "string", enum: ["whatsapp", "sms", "email", "phone"] },
    message_body: { type: "string", description: "Concise, polite message referencing verified memory facts." },
    notes: { type: "string" }
  }
};

const outcomeSchema = {
  type: "object",
  additionalProperties: false,
  required: ["status", "resolved_summary", "entity_status_update"],
  properties: {
    status: { type: "string", enum: ["resolved", "partial", "unresolved", "unknown"] },
    resolved_summary: { type: "string" },
    entity_status_update: { type: "string", description: "New state for the entity, e.g. 'resolved', 'active', 'needs_service'" }
  }
};

Deno.serve(async (request) => {
  if (request.method !== "POST") return new Response("Method not allowed", { status: 405 });
  const apiKey = Deno.env.get("OPENAI_API_KEY");
  if (!apiKey) return Response.json({ error: "AI service is not configured on server." }, { status: 503 });

  const payload = await request.json();
  const { operation, content, query, statement, evidence, memory_context, target_entity } = payload;

  const model = Deno.env.get("OPENAI_MODEL") ?? "gpt-4o-mini";

  let systemPrompt = "You are NYABAGAM's private personal memory intelligence layer. Ground all answers strictly in the provided evidence. Never fabricate names, dates, amounts, or facts. When evidence is insufficient, state that clearly.";
  let userPrompt = "";
  let schema = understandCandidateSchema;
  let schemaName = "memory_candidate";

  switch (operation) {
    case "understand":
      systemPrompt = "Extract entities, relationships, events, and amounts strictly from the untrusted capture. Do not invent facts.";
      userPrompt = `User capture:\n${content}`;
      schema = understandCandidateSchema;
      schemaName = "memory_candidate";
      break;

    case "ask":
      systemPrompt = "Answer the user memory question strictly using the provided authorized evidence. If no evidence applies, set confidence to no_evidence.";
      userPrompt = `Question: ${query}\n\nAuthorized Evidence:\n${JSON.stringify(evidence ?? [])}`;
      schema = askResponseSchema;
      schemaName = "ask_response";
      break;

    case "context":
      systemPrompt = "Analyze the user's current situation against their past memory. Explain why it is relevant and propose helpful next actions without assuming prior approval.";
      userPrompt = `Current Situation: ${statement}\n\nPast Relevant Memories:\n${JSON.stringify(evidence ?? [])}`;
      schema = contextBridgeSchema;
      schemaName = "context_bridge";
      break;

    case "draft_action":
      systemPrompt = "Draft a calm, polite message referencing verified memory facts. Do not make false promises or invent urgency.";
      userPrompt = `Target: ${target_entity}\nContext:\n${JSON.stringify(memory_context ?? {})}`;
      schema = draftActionSchema;
      schemaName = "action_draft";
      break;

    case "extract_outcome":
      systemPrompt = "Extract the outcome of a recent action from the user confirmation. Determine if the issue is resolved or unresolved.";
      userPrompt = `User Statement: ${content}\nOriginal Context:\n${JSON.stringify(memory_context ?? {})}`;
      schema = outcomeSchema;
      schemaName = "outcome_result";
      break;

    default:
      return Response.json({ error: `Unknown operation: ${operation}` }, { status: 400 });
  }

  try {
    const aiResponse = await fetch("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${apiKey}`,
        "Content-Type": "application/json"
      },
      body: JSON.stringify({
        model,
        messages: [
          { role: "system", content: systemPrompt },
          { role: "user", content: userPrompt }
        ],
        response_format: {
          type: "json_schema",
          json_schema: {
            name: schemaName,
            strict: true,
            schema
          }
        },
        temperature: 0.1
      })
    });

    const data = await aiResponse.json();
    if (!aiResponse.ok) {
      return Response.json({ error: "AI provider call failed.", details: data }, { status: aiResponse.status });
    }

    const structuredOutput = JSON.parse(data.choices[0].message.content);
    return Response.json({ result: structuredOutput }, { status: 200 });
  } catch (err) {
    return Response.json({ error: "AI Orchestrator encountered an exception.", message: String(err) }, { status: 502 });
  }
});