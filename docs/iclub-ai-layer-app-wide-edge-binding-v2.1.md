# iClub AI Layer v2.1 — единственный app-wide Edge admission (QA)
**Дата:** 2026-10-14  
**Этап Master Plan:** §47; P2/P5/P6/P7 server binding.  
**Статус:** QA Edge integration and negative regression implemented; real RPC deployment and Global AI release **NO-GO**.

## 1. What changed
The already existing `CandidateEdgeRequest` now accepts an optional trusted admission object and uses the **same check** both before source/billing work and again after reservation, authentication and async source reads. The Deno QA runtime `qa/edge_v21/runtime.ts` injects `TrustedAppWideServerAdapter` into this ONE candidate. The original standalone Node adapter tests still use the existing `ContentHandoffGate`; no second AI provider, tutor or frontend was built.

The app-wide admission result carries a server-only `proofHash` in addition to `proofRevision`, `route`, `surface` and `subject`. The request revalidation compares them, so same-revision content/screen proof drift cannot authorize a stale reply. Neither digest nor source/progress payload is returned by public `/answer` or `/context`.

## 2. One read-only server RPC interface — proposed, not deployed
`qa/edge_v21/screen_proof_services.ts` adds eleven typed readers over **one** proposed `get_iclub_ai_v21_screen_evidence_service` function. Each read sends the verified user ID from JWT plus exact selector metadata: current screen, navigation, subject overview, Home next actions, Profile aggregate, exact Lesson, finalized Practice V4 session and exact answer, Tour attempt, finalization runtime and opened archive. The private service must return `allowed=true` and `evidence.user_id`, `evidence.evidence_kind` and exact selector echoes. Any missing function, missing permission, foreign owner, selector mismatch or server error returns `null` (never falls back to browser data).

`qa/edge_v21/supabase_services.ts` attaches those readers to the existing Supabase service-role RPC bridge. It also exposes the existing opaque context's **server-supplied** current view and precise lesson/session/question/tour selector fields. The `get_iclub_ai_v21_general_scope_service` contract independently gates General Help without inventing a `general` row in `public.subjects`. A missing General Help RPC denies. Normal subject activation remains read-only; source publication, rights, locale and rollout are checked separately.

**Important:** these RPC names express the expected trusted interface. Neither is asserted to exist in the live Supabase instance. This code does not implement SQL, grant access or create tables. The current `qa/sql_drafts/iclub_ai_scoped_context_v21_UNAPPLIED.sql` supports only Lesson/Practice and does not yet have app-wide current-view proofs. Hence actual Home, Profile, General Help, opened Tours and subject-level rollout must remain CLOSED.

## 3. Negative and end-to-end QA
- Node complete suite, Deno compiler and QA HTTP flow, 12 isolated PostgreSQL scratch suites, Chromium actual viewports, frozen Mathematics subject isolation, provider budget/delivery races remain CI gates.
- `screen_proof_services_test.ts` checks all eleven reader contracts and rejection of missing RPC, unrelated owner, kind or selector, malformed IDs. No direct table read or production DB connection.
- Deno `e2e_synthetic_test.ts` performs JWT → short-lived Lesson or Practice context → trusted exact proof → source → quota claim → prepared reply in **synthetic in-memory fake backend only**. It also verifies active assessments, logout/revoke, unpublished locale, invalid JWT, network loss and page-proof change during source loading. That last event prevents response and releases the learner quota hold.
- User-produced subject/course/lesson/plan claims never grant permission. No model provider connected.

## 4. Release blockers
1. Build and **independently review** the required server-only RPC implementation or equivalent authoritative read-only views, with real database schema/permission checks in an **isolated** environment. The current test fixture is not proof of real completeness or source approval.
2. Define actual screen lifetime and revision authority without inserting permanent conversations and without mutating academic progress or localStorage. The app has no verified exact server-side current screen for all surfaces today.
3. Approve user-facing UI bridge from actual app.js to V2 context selectors, including separate complete Practice V4 and lesson-specific non-video screens. Keep old Mathematics Exam Prep Tutor unchanged.
4. After independently protected staging tests, prove exact topic/locale/rights/rollout, robustness and billing, then request explicit owner permission before any beta/production use, provider spending or new Preview.

The QA Edge entrypoint is **not** imported by `supabase/functions/`, `index.html`, `app.js`, `exam-prep/` or main. No migration, provider, live learner, PR, branch or Preview was used here.
