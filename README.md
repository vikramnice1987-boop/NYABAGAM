# NYABAGAM V1

NYABAGAM is a private personal-memory companion with a complete V1 lifecycle:
Capture → Understand → Remember → Ask → Context → Action → Outcome → Memory
update.

## Production foundation

- Firebase Authentication: Google Sign-In is primary; Firebase email-link
  sign-in is available as an alternative.
- Cloud Firestore: user-scoped source, entity, and memory documents.
- Cloud Storage: private capture attachments, separated from Firestore data.
- Cloud Functions: authenticated OpenAI boundary; no OpenAI key reaches Flutter.
- Local-only fallback: capture and review remain runnable when Firebase has not
  yet been configured.

## Connect a Firebase project

1. Create a Firebase project and register Android (com.nyabagam.nyabagam),
   iOS, and Web apps as needed.
2. Enable Google and Email link under Firebase Authentication.
3. Run flutterfire configure from this directory. Commit the generated
   lib/firebase_options.dart and platform configuration files, but never a
   service-account credential.
4. Deploy the access rules and index:

       firebase deploy --only firestore:rules,firestore:indexes,storage

5. In firebase/functions, install dependencies, set the secret, then deploy:

       npm install
       firebase functions:secrets:set OPENAI_API_KEY
       firebase deploy --only functions

6. Add the Android SHA-1 and SHA-256 fingerprints to Firebase, download the
   refreshed configuration, and configure the Firebase authorized domain /
   Android App Link for email-link completion.

The Firebase command generated options are preferred. .env.example lists
Dart-define names for controlled development builds only; they are client
configuration values, not secrets.

## Run locally

Without Firebase configuration, the app uses its local development repository:

       flutter run

After configuring Firebase, use the FlutterFire-generated options or approved
build-time FIREBASE_* values. Do not pass OPENAI_API_KEY to Flutter.

## Structure

- lib/core: configuration, Firebase boundary, AI, design system and routing
- lib/features: feature-first presentation, domain and data layers
- firebase: Firestore/Storage rules, indexes and Cloud Functions
