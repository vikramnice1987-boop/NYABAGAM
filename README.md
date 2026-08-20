# NYABAGAM V1

Flutter foundation for the memory lifecycle: Capture → Understand → Remember → Ask → Context → Action → Outcome → Memory update.

## Run locally

Supply only the Supabase URL and public anon key to the app; never supply an OpenAI key to Flutter.

```powershell
flutter run --dart-define=SUPABASE_URL=https://your-project.supabase.co --dart-define=SUPABASE_ANON_KEY=your-public-anon-key
```

The trusted AI boundary is `supabase/functions/ai-memory`. Set its `OPENAI_API_KEY` and optional `OPENAI_MODEL` as Supabase Edge Function secrets before deployment. It returns a JSON-schema-constrained candidate and uses `store: false`; the OpenAI key never enters the mobile app.

Apply the migration in `supabase/migrations` to create the user-scoped sources and memories tables. With Supabase configuration supplied, NYABAGAM uses email magic-link authentication and writes confirmed text memories to those tables. Without it, the capture flow remains available with its development-only in-memory store.

## Structure

- `lib/core`: configuration, theme, navigation, Supabase and AI boundaries
- `lib/features`: feature-first UI and future data/domain layers
- `supabase/functions`: trusted integrations; OpenAI belongs here
