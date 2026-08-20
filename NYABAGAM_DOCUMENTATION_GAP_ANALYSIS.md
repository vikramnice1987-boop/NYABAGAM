# NYABAGAM V1 — Documentation Gap Analysis & Cross-Check

**Document Version:** 1.0.0  
**Date:** 2026-08-20  
**Author:** Lead Software Architect & Lead Systems Engineer  
**Status:** Approved Gap Analysis  

---

## 1. Objective & Scope

This document evaluates the 36 master specification documents (PRD, TRD, Backend Schema, Data Model ERD, Memory Engine Specification, State Management Rules, AI Architecture, API Specification, UI/UX Design Brief, Design System, etc.) against the codebase located at `C:\Users\Vikram -Evvo\.codex\.chatgpt-projects\g-p-6a82da48b9d48191876f8c211359a40e\nyabagam`.

It identifies:
1. Missing Requirements
2. Specification Conflicts & Resolutions
3. Codebase vs. Specification Discrepancies
4. Schema & API Mismatches
5. UI & Business Rule Mismatches
6. AI & Memory Engine Mismatches
7. Security & Authorization Mismatches

---

## 2. Specification Conflict Analysis & Resolutions

When cross-referencing the 36 documents, several design decisions and minor document tensions were analyzed. In accordance with the project rules, we do not silently pick an arbitrary interpretation:

| Area | Document A | Document B | Conflict / Tension | Safest Architectural Interpretation |
|---|---|---|---|---|
| **Memory Entity Links** | *Data Model ERD* (§19): Suggests `memory_entities` polymorphic table (`entity_type`, `entity_id`). | *Backend Schema* (§15, DB-LINK-01): Mentions polymorphic links require service validation because Postgres cannot enforce polymorphic FKs. | Polymorphic foreign keys cannot be enforced by PostgreSQL integrity constraints and can complicate Row Level Security. | **Resolution:** Use a clean join model with explicit type validation in database RPCs and API layer, or typed foreign keys where referential integrity is critical. All queries enforce `user_id` directly. |
| **Authentication & In-Memory Mode** | *PRD* (§18) & *TRD* (§6): All user memory is private and requires Supabase Auth and RLS. | *Codebase* (`InMemoryMemoryRepository`): Allows running without Supabase configuration using in-memory store. | In-memory store allows local dev exploration, but risks user confusion and data loss if treated as production. | **Resolution:** Strict separation. In-memory repository is retained ONLY as an isolated testing/preview fixture. Production builds enforce Supabase authentication and display clear offline/unauthenticated banners. |
| **AI Invocation Channel** | *AI Spec* (§3): All AI calls must go through a server-side AI Orchestrator with prompt versioning. | *Existing Code* (`AiGateway.dart`): Calls a single `ai-memory` Edge Function directly from Flutter. | Bypassing an orchestrator prevents multi-step reasoning, hybrid retrieval context injection, and structured intent handling. | **Resolution:** Expand Edge Function into a unified `ai-orchestrator` supporting operations: `understand`, `ask`, `context`, `draft_action`, and `extract_outcome`. |
| **Navigation Structure** | *PRD* (§21) & *Design System* (§27): Primary navigation is 4 tabs: **Home**, **History (Memories)**, **Ask**, **Profile** + elevated Capture CTA. | *Existing Code* (`app_router.dart`): Linear list route (`/`, `/capture`, `/understand`, `/remember`, `/<stage>`). | Current router renders an un-nested list of dummy stage pages without a bottom navigation bar. | **Resolution:** Implement a `StatefulShellRoute.indexedStack` in GoRouter with the 4 standard tabs and a modal/pushed Capture flow as specified in the Design System. |

---

## 3. Detailed Gap Matrix by Domain

### 3.1 Backend & Database Schema Gaps

| Entity / Capability | Required by Specifications | Existing in Repository | Severity | Action Required |
|---|---|---|---|---|
| **Profiles & Preferences** | `profiles` (id, user_id, display_name, timezone, created_at), `user_preferences` | Missing | **P0** | Add tables in migration with automatic profile creation trigger on signup. |
| **Domain Entities** | `people`, `organizations`, `things`, `places`, `events` with `user_id`, `name`, `attributes` | Missing (stored as plain strings in JSON) | **P0** | Create normalized tables with user-scoped unique indexes and foreign keys. |
| **Relationships Graph** | `relationships` table (`source_id`, `target_id`, `relationship_type`, `valid_from`, `valid_to`) | Missing | **P0** | Implement relationships table to model typed connections (e.g. `Ravi -> serviced -> AC`). |
| **Memory Provenance & Evidence** | `memory_sources` linked to `memories`, with storage paths and excerpts | Minimal `memory_sources` table without storage policies | **P0** | Enhance `memory_sources` to support audio/images/documents and RLS storage policies. |
| **Semantic Embeddings** | `memory_embeddings` with `vector(1536)` (pgvector) and HNSW/IVFFlat indexes | Missing pgvector extension and table | **P0** | Enable `vector` extension, create embeddings table, and add cosine distance indexes. |
| **Action & Outcome Tables** | `actions` (status: proposed/approved/executing/completed), `action_events`, `outcomes` | Missing | **P0** | Create action lifecycle tables with idempotency keys and approval timestamps. |
| **Context & Conversations** | `conversations`, `messages`, `context_requests`, `context_results` | Missing | **P1** | Add conversation and context history tables. |

---

### 3.2 AI & Memory Engine Gaps

| AI Capability | Specification Contract | Current Codebase | Gap Assessment |
|---|---|---|---|
| **Entity Extraction** | Extract people, organizations, things, dates, monetary amounts, and service types into typed JSON. | Basic extraction of string arrays (`people`, `things`, `events`). | Model lacks amount, organization, and date extraction; no disambiguation against existing entities. |
| **Hybrid Retrieval** | Combine keyword search, pgvector similarity, entity graph traversal, and recency ranking. | No retrieval engine exists. | Critical gap: Cannot answer "Who serviced my AC?" without manual SQL lookups. |
| **Context Bridge Engine** | Input: "My AC isn't working." $\rightarrow$ Detects Thing(AC) $\rightarrow$ retrieves Ravi (CoolCare) service history $\rightarrow$ explains why relevant $\rightarrow$ proposes action. | Placeholder screen (`FlowStagePage`). | Complete subsystem missing; must be implemented in Edge Function + Flutter presentation. |
| **Action & Message Drafter** | Draft contextual, un-hallucinated message (e.g. WhatsApp to Ravi) with user review and approval. | Placeholder screen. | Subsystem missing. |
| **Outcome Resolution Engine** | Input: "Ravi fixed it." $\rightarrow$ extracts outcome $\rightarrow$ updates AC status to `resolved`/`working` $\rightarrow$ preserves historical record. | Placeholder screen. | Subsystem missing. |
| **Prompt Injection Protection** | Treat user inputs as untrusted data; separate system instructions from input content. | Minimal single prompt. | Needs prompt hardening and strict schema constraints. |

---

### 3.3 Flutter Presentation & UI/UX Gaps

| UI Component / Screen | Design System Specification | Codebase Implementation | Gap Assessment |
|---|---|---|---|
| **App Shell & Navigation** | 4-tab bottom navigation (`Home`, `History`, `Ask`, `Profile`) + thumb-accessible Capture FAB. | Flat ListView on HomePage. | Needs `ScaffoldWithNavBar` shell. |
| **Design System Tokens** | `NyColors`, `NyTypography`, `NySpacing`, `NyRadius`, `NyElevations` supporting Light & Dark themes. | Standard Material 3 `ThemeData.from(colorScheme)`. | Needs complete token library and ThemeExtension. |
| **Reusable Components** | `NyButton`, `NyTextField`, `NyCard`, `NyMemoryCard`, `NyEntityChip`, `NyEvidenceCard`, `NyStatusChip`, `NyActionApproval`, `NyContextBridge`. | Raw Material buttons and cards. | Missing 10+ core design system widgets. |
| **Voice Capture UI** | Audio recording with start/stop/cancel, live waveform/duration, and audio preview. | Plain multiline TextField only. | Voice capture UI and audio pipeline missing. |
| **Candidate Review Screen** | Rich editor with interactive entity chips (add/remove people, things, organizations, dates, amounts). | Read-only summary card with text lists. | User cannot edit individual detected entities before confirming. |
| **Ask NYABAGAM Screen** | Chat/Search hybrid interface showing grounded answers, expandable evidence chips, and related actions. | Static text placeholder. | Full Ask screen missing. |
| **Context Bridge Screen** | Card layout: Current Situation $\rightarrow$ Past Memory $\rightarrow$ Why Relevant $\rightarrow$ Proposed Action. | Static text placeholder. | Full Context Bridge missing. |
| **Action & Outcome UI** | Action approval sheet with editable message draft, dispatch triggers, and outcome logger. | Static text placeholder. | Full Action/Outcome UI missing. |

---

### 3.4 State Management & Error Handling Gaps

| Requirement | State Management Rules Specification | Existing Codebase |
|---|---|---|
| **Architecture** | Feature-first layered architecture with Riverpod `StateNotifier`/`AsyncNotifier`. | Plain `StatefulWidget` with local `setState`. |
| **State Representation** | Explicit states: `initial`, `loading`, `success`, `empty`, `error`, `retrying`, `offline`, `unauthorized`. | Boolean flags (`_isUnderstanding`, `_isSubmitting`). |
| **Centralized Error Model** | `AppError` with `code`, `userMessage`, `retryable`, `severity`, and `metadata`. | Raw `try/catch` with generic snackbars or `error.toString()`. |
| **Offline & Sync State** | Local capture queue with sync status indicator. | Not implemented. |

---

## 4. Documentation Traceability & Verification Matrix

| Specification Document | Codebase Mapping Target | Current Implementation % |
|---|---|---|
| **PRD & TRD** | Entire application architecture | ~15% (Initial POC) |
| **Backend Schema & ERD** | `supabase/migrations/` | ~10% (2 of 18 tables) |
| **AI Specification & Orchestration** | `supabase/functions/ai-orchestrator/` | ~15% (Basic candidate schema) |
| **Memory Engine Specification** | `lib/features/memory/`, `lib/features/understand/` | ~20% (Candidate $\rightarrow$ Confirmed) |
| **Design System & UI/UX Brief** | `lib/core/theme/`, `lib/shared/widgets/` | ~10% (Basic theme) |
| **API Specification** | `lib/core/networking/`, Edge Functions | ~15% |
| **State Management & Business Rules** | `lib/core/errors/`, Riverpod providers | ~5% |
| **Security & Privacy Specification** | Supabase RLS, Secure Storage | ~20% |
| **QA Test Plan** | `test/`, `integration_test/` | ~5% (1 widget test) |

---

## 5. Architectural Alignment Strategy

To bridge all identified gaps systematically without breaking existing working code:

1. **Step 1:** Build the comprehensive, production-grade PostgreSQL database schema via a clean, versioned Supabase migration (`20260820000000_nyabagam_core_schema.sql`).
2. **Step 2:** Implement the complete Flutter Design System and component library (`lib/shared/components/` & `lib/core/theme/`).
3. **Step 3:** Implement the Riverpod state management and centralized `AppError` infrastructure.
4. **Step 4:** Build the server-side AI Orchestrator Edge Function supporting multi-modal extraction, hybrid search, context generation, and message drafting.
5. **Step 5:** Implement feature modules in exact dependency order (Auth $\rightarrow$ Capture $\rightarrow$ Understand $\rightarrow$ Memory/Graph $\rightarrow$ Ask $\rightarrow$ Context $\rightarrow$ Action $\rightarrow$ Outcome).
6. **Step 6:** Implement end-to-end automated test suites for the flagship AC/Ravi journey and general memory lifecycle.
