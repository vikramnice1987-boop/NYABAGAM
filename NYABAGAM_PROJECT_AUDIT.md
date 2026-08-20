# NYABAGAM V1 — Comprehensive Project Audit

**Document Version:** 1.0.0  
**Date:** 2026-08-20  
**Author:** Lead Software Architect & Engineering Lead  
**Status:** Approved Baseline Audit  

---

## 1. Executive Summary

NYABAGAM is conceived as a private personal memory companion built on the 8-stage memory lifecycle:
$$\text{Capture} \longrightarrow \text{Understand} \longrightarrow \text{Remember} \longrightarrow \text{Ask} \longrightarrow \text{Context} \longrightarrow \text{Action} \longrightarrow \text{Outcome} \longrightarrow \text{Memory Update}$$

This audit establishes the baseline technical state of the existing repository located at `C:\Users\Vikram -Evvo\.codex\.chatgpt-projects\g-p-6a82da48b9d48191876f8c211359a40e\nyabagam` against the 36 master specification documents (PRD, TRD, Backend Schema, Data Model ERD, Memory Engine Spec, State Management Rules, AI Specification, UI/UX Design System, etc.).

Currently, the codebase contains an initial proof-of-concept skeleton (Capture, Review, and Save with basic text and a mock/minimal Supabase table). All remaining major subsystems—the relational entity graph, vector search (pgvector), hybrid retrieval, Context Bridge, Action approval engine, Outcome resolution, Design System, state management architecture, comprehensive error handling, and security hardening—remain to be built.

---

## 2. Environment & Toolchain Audit

| Component | Target / Specification | Current State | Status / Assessment |
|---|---|---|---|
| **Flutter SDK** | Stable 3.x+ (Mobile Android/iOS) | Flutter 3.44.7 (channel stable) |  Compatible & Ready |
| **Dart SDK** | ^3.12.2 | Dart 3.12.2 |  Compatible & Ready |
| **Flutter Analyze** | 0 lints / errors | Passed (0 issues) |  Clean baseline |
| **Flutter Test** | All tests passing | 1 test passed (`widget_test.dart`) |  Passing but minimal |
| **Backend** | Supabase (PostgreSQL 15+ & pgvector) | Configured via `--dart-define` |  Minimal local schema |
| **AI Runtime** | Supabase Edge Functions + OpenAI API | Single minimal Edge Function (`ai-memory`) |  Needs full orchestrator |

---

## 3. Existing Repository & Codebase Inventory

### 3.1 Dependencies (`pubspec.yaml`)
* **Existing Dependencies:**
  * `flutter`: SDK
  * `cupertino_icons: ^1.0.8`
  * `go_router: ^17.1.0`
  * `supabase_flutter: ^2.12.0`
  * `flutter_lints: ^6.0.0` (dev)
* **Missing Essential Dependencies (mandated by TRD/PRD):**
  * `flutter_riverpod` or structured state management
  * `record` / `audioplayers` / `path_provider` for audio capture
  * `intl` / `flutter_localizations` for localization & formatting
  * `uuid` for client-side idempotency keys & correlation IDs
  * `flutter_secure_storage` for token/session management
  * `shared_preferences` / local cache
  * `url_launcher` for Action execution (e.g. WhatsApp / phone / email dispatch)

### 3.2 File Structure
```
lib/
├── app/
│   └── app.dart                           # MaterialApp.router configuration
├── bootstrap.dart                         # Initialization & Supabase setup
├── main.dart                              # Entrypoint
├── core/
│   ├── ai/
│   │   └── ai_gateway.dart                # Basic Edge Function invocation
│   ├── config/
│   │   └── app_environment.dart           # String.fromEnvironment configuration
│   ├── router/
│   │   └── app_router.dart                # GoRouter route definitions
│   ├── supabase/
│   │   └── supabase_service.dart          # Supabase client singleton
│   └── theme/
│       └── app_theme.dart                 # Basic ThemeData with color seeds
└── features/
    ├── auth/presentation/
    │   ├── auth_gate.dart                 # StreamSubscription on auth state
    │   └── sign_in_page.dart              # OTP magic link input
    ├── capture/presentation/
    │   └── capture_page.dart              # Multiline text input
    ├── flow/presentation/
    │   └── flow_stage_page.dart           # Placeholder page for stages
    ├── home/presentation/
    │   └── home_page.dart                 # List of stages + CTA
    ├── memory/
    │   ├── data/
    │   │   ├── memory_repository.dart     # Interface + InMemory repository
    │   │   └── supabase_memory_repository.dart # Direct DB insert repository
    │   └── domain/
    │       └── memory_candidate.dart      # Candidate model
    ├── remember/presentation/
    │   └── memory_saved_page.dart         # Success confirmation screen
    └── understand/presentation/
        └── memory_review_page.dart        # Candidate review screen
```

---

## 4. Subsystem-by-Subsystem Audit

### 4.1 Database & Supabase Schema
* **Current Schema (`20260819000000_memory_foundation.sql`):**
  * Contains only 2 tables: `public.memory_sources` and `public.memories`.
  * Stores entities as unstructured JSON in `memories.metadata`.
* **Missing Tables (P0 per Backend Schema & Data Model ERD):**
  * `profiles` & `user_preferences`
  * `people`, `organizations`, `things`, `places`, `events`
  * `relationships` (typed graph links with validity dates)
  * `memory_entities` (polymorphic or explicit join tables)
  * `memory_embeddings` (pgvector 1536/3072-dim embeddings + IVFFlat/HNSW indexes)
  * `actions`, `approvals`, `action_events`
  * `outcomes` & `state_history`
  * `conversations`, `messages`, `context_requests`, `context_results`
  * `notifications` & `audit_events`
* **Missing Database Functions / RPCs:**
  * `search_memories()`: Hybrid keyword + vector retrieval RPC.
  * `find_related_context()`: Entity graph traversal RPC.
  * `confirm_memory_candidate()`: Atomic transaction RPC for memory + entity links.
  * `record_action_outcome()`: Atomic transaction for outcome + current status update.

### 4.2 AI Architecture & Edge Functions
* **Current State:**
  * `supabase/functions/ai-memory/index.ts` contains a single endpoint that forwards content to OpenAI `responses` endpoint with strict JSON schema.
* **Missing AI Components (per AI Specification & Architecture):**
  * Server-side AI Orchestrator with modular, versioned system prompts.
  * Speech transcription (Whisper / dedicated audio endpoint).
  * Entity & Relationship resolution engine (disambiguating against existing user entities).
  * Hybrid retrieval orchestrator (combining keyword, semantic vector, and relationship expansion).
  * Context Engine (generating Situation $\rightarrow$ Memory $\rightarrow$ Relevance $\rightarrow$ Action).
  * Message drafting engine (controllable, un-hallucinated drafts for WhatsApp, SMS, Email).
  * Outcome extraction engine (updating current status while preserving history).
  * Prompt injection defense & input normalization.

### 4.3 UI/UX & Design System
* **Current State:**
  * Basic default Flutter Material 3 widgets with standard buttons and cards.
  * Home screen is a simple linear list of routes.
* **Missing UI/UX Components (per Design System & UI/UX Brief):**
  * Centralized design tokens (`NyColors`, `NyTypography`, `NySpacing`, `NyRadius`, `NyElevations`).
  * Core reusable components: `NyButton`, `NyTextField`, `NyCard`, `NyMemoryCard`, `NyEntityChip`, `NyEvidenceCard`, `NyStatusChip`, `NyLoadingState`, `NyEmptyState`, `NyErrorState`, `NyActionApproval`, `NyContextBridge`, `NyBottomNav`.
  * Proper 4-tab App Shell: **Home**, **History / Memories**, **Ask**, **Profile** + elevated Capture Action.
  * Voice recording capture interface (waveform, timer, audio state).
  * Multi-entity candidate review editor (allowing user inline editing of detected people, things, dates, amounts).
  * Context Bridge card with "Why am I seeing this?" evidence disclosure.
  * Action proposal review bottom sheet with explicit approval step.

### 4.4 State Management & Business Rules
* **Current State:**
  * Ad-hoc `setState` inside individual StatefulWidget classes.
  * UI state tightly coupled to widget lifecycles.
* **Missing Architecture (per State Management & Business Rules doc):**
  * Explicit 4-layer state architecture (UI state, Sync state, Domain state, Persisted state).
  * Structured domain state machines:
    * Source lifecycle: `CREATED -> UPLOADING -> UPLOADED -> PROCESSING -> PROCESSED | FAILED`
    * Memory Candidate lifecycle: `GENERATED -> NEEDS_REVIEW -> EDITED -> CONFIRMED | REJECTED`
    * Memory lifecycle: `ACTIVE -> UPDATED -> SUPERSEDED | FORGOTTEN | DELETED`
    * Action lifecycle: `PROPOSED -> APPROVED -> EXECUTING -> COMPLETED | FAILED | UNKNOWN`
    * Outcome lifecycle: `PENDING -> COMPLETED | PARTIAL | FAILED | UNKNOWN`
  * Centralized `AppError` hierarchy with error classification (`VALIDATION_ERROR`, `UNAUTHORIZED`, `FORBIDDEN`, `NOT_FOUND`, `CONFLICT`, `NETWORK_OFFLINE`, `AI_UNAVAILABLE`, `RATE_LIMITED`).

### 4.5 Security & Privacy Audit
* **Strengths:**
  * RLS is enabled on `memory_sources` and `memories`.
  * AI API keys are not exposed in Flutter client code (they reside in Edge Functions).
* **Vulnerabilities / Gaps to Fix:**
  * Edge function currently does not verify caller's JWT token (`auth.uid()`) to restrict requests to authenticated users.
  * In-memory repository fallback allows unauthenticated memory creation that is lost on restart without user notification.
  * No secure storage implementation for sensitive cached tokens.
  * Missing deletion cascade & soft-delete privacy controls.

---

## 5. Summary of Gaps & Technical Debt

1. **Database Schema:** 90% of normalized entity graph and vector tables are missing.
2. **AI Layer:** Hybrid retrieval, intent detection, Context Engine, and Action drafting are missing.
3. **Flutter App Flow:** Ask, Context, Action, Outcome, History, and Profile screens are placeholders.
4. **State Management:** Lack of Riverpod/StateNotifier structure.
5. **Design System:** Needs `Ny*` component library and token system.
6. **Testing:** Only 1 simple widget test; zero unit, repository, RLS, or integration tests.

---

## 6. Recommended Implementation Sequence

1. **Milestone 1 — Foundation & Database Architecture (Backend First)**
   * Complete PostgreSQL migration with all 18 tables, constraints, indexes, and RLS policies.
   * Configure pgvector and storage bucket security policies.
   * Implement database RPC functions (`search_memories`, `find_related_context`, `confirm_memory_candidate`).
2. **Milestone 2 — Design System & Flutter Foundation**
   * Implement design tokens and reusable `Ny*` component library.
   * Implement 4-tab shell navigation with `go_router`.
   * Configure state management (Riverpod) and unified `AppError` architecture.
3. **Milestone 3 — Authentication & User Profile Layer**
   * Supabase Auth integration with secure token persistence, profile creation, and session recovery.
4. **Milestone 4 — Multi-Modal Capture & AI Understanding**
   * Voice audio recording + text capture.
   * Supabase Edge Function AI Orchestrator for schema-validated extraction.
   * Candidate review and editing UI with entity chips.
5. **Milestone 5 — Memory Engine, Entity Graph & Search**
   * Canonical memory repository with entity/relationship persistence.
   * pgvector embedding worker and hybrid search retrieval.
   * History and memory detail screens with provenance disclosure.
6. **Milestone 6 — Context Engine & Ask NYABAGAM**
   * Natural language memory search ("Ask") with grounded evidence display.
   * Context Bridge ("My AC isn't working" $\rightarrow$ surfaces Ravi / CoolCare history).
7. **Milestone 7 — Action Approval & Outcome Resolution**
   * Action proposal generator, approval bottom sheet, and WhatsApp/SMS dispatcher.
   * Outcome recorder updating current status while preserving history.
8. **Milestone 8 — End-to-End Testing, QA & Production Hardening**
   * Comprehensive unit, widget, repository, and integration tests for the full AC/Ravi lifecycle.
   * Accessibility, dark mode, offline, and error recovery audits.
