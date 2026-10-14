# iClub AI v2.1 — Trusted Server Evidence Adapter (QA only)

**Date:** 2026-10-14  
**Master Plan:** §46; P2/P5/P6 (source-specific admission), P4 legacy Tutor isolation.  
**Branch:** `qa/iclub-ai-layer-v21-20261012`  
**Release status:** **CONTRACT IMPLEMENTED, LIVE BACKEND NO-GO**.

## Reuse instead of a parallel AI

`qa/ai-layer-v21-trusted-server-adapter.cjs` uses the existing **one** `QAAppWideFeatureAdmission` and its existing `ContentHandoffGate`. It does not reimplement readiness, published source proof, rollout, entitlement, reply/billing or the protected assessment gate. It supplies a server-verified `getVerifiedScreenEvidence(uid, contextHandle)` result and the existing app-wide admission decides eligibility. No subject-specific AI instances are created.

The constructor **requires all named readers**. Missing readers fail closed at creation; missing or inconsistent rows fail closed per request. Every reader must be implemented using **authenticated read-only server queries/RPCs**. Passing a browser-payload imitation of a reader is forbidden. Caller owns JWT verification, verified user identity, protected assessment state, and server-owned current screen. There are no DB writes in the adapter.

## Exact evidence and actual repository-model anchors

| Surface | Independent server evidence necessary | Rejected states |
|---|---|---|
| General help | Approved, current server navigation instructions for an allowed view | Unknown/closed view, stale source |
| Subject overview | Approved current overview for exact subject and Courses view | Other subject, no subject release |
| Home | User-owned, verified next-actions aggregate + positive aggregate revision | Client progress, foreign aggregate, stale revision |
| Profile | User-owned verified metrics + positive aggregate revision | Guessed statistics, foreign aggregate |
| Lessons | Exact `public.lessons.id`, active subject, actual lesson-specific non-video source, authorized access | Subject-wide Telegram video, missing exact lesson |
| Practice | `public.practice_sessions_v4`: owner, `status='finalized'`, `finalized_at`, `question_ids`; `public.practice_session_answers_v4`: exact checked, final question, topic | Active/unfinished Practice, foreign answer, legacy attempt ID, mismatched question |
| Tours | `public.tour_attempts` and separate finalized tour runtime; independently verified archive unlock for exact attempt and owner | Simply submitted Tour, locked archive, missing runtime, other learner |

The first five subjects and future English/SAT/IELTS require independently published source, rights, cohort and locale gates. Subject activation alone is never enough. The specific `Practice` source RPC in `qa/sql_drafts/iclub_ai_practice_exact_source_v21_UNAPPLIED.sql` accepts only one currently approved **exact question** source; topic-level cards are not a substitute. None of the UNAPPLIED SQL files is a production migration.

## Temporal and privacy boundaries

The server-side screen record must match authenticated user ID, opaque context handle, context revision, current view and positive revision. The adapter checks it **after** collecting domain evidence; `QAAppWideFeatureAdmission` checks the full proof again after the separate content/release checks. Proof hashes derive from server-owned metadata. No raw question answers, result details, personal progress, student chat or keys are returned. AI cannot award grades, marks, mastery, certificates or retests.

Existing Mathematics Exam Prep Tutor remains independent: no routing to its endpoints, no double metering, no parity claim and no changes to `exam-prep/`, `app.js`, `index.html` or its existing Edge Function.

## Verification

`qa/ai-layer-v21-trusted-server-adapter.test.cjs` covers positive synthetic admission for all seven surfaces, independent subject/source readiness and negative owner, active Practice, question mismatch, Tour finalization/unlock, lesson specificity, unverified aggregates, revoked/stale screen, expiry, source conflict and global AI OFF. Registered under `qa/run-ai-layer-v21-offline.cjs`. Complete CI additionally runs existing Node, Deno, PostgreSQL scratch, Chromium and frozen Exam Prep regressions. Green synthetic tests confirm **contract behaviour, not live availability**.

## Remaining real integration blockers — NO-GO

1. `qa/edge_v21/supabase_services.ts.getScopedContext` currently exposes only a subset of fields required by the full app-wide adapter. The UNAPPLIED scoped-context SQL draft only supports lesson/practice selectors, not a server current-view proof for Home/Profile/General/Tours. The actual app.js UI also lacks final exact Lessons and V4 Practice selector wiring.
2. No currently deployed, verified user-scoped read APIs are connected for the seven evidence readers and global screen revision. Source/rights/locale approval is not established for most subjects. A generic UI screenshot or synthetic green test is not such proof.
3. The existing isolated `qa/edge_v21/index.ts` and `CandidateEdgeRequest` remain on their previously validated content gate; they do not yet invoke this new app-wide adapter. **Do not silently switch /answer or the existing Mathematics Tutor.**
4. Staging integration requires architect-approved isolated server/current-screen proof and reviewed RPCs, a full browser/Edge exercise, budgets/abuse tests, release approval and independent parity checks. Until then missing evidence must resolve to **«В разработке»**, and any protected examination must remain hidden and server-blocked.

No production database, live student, paid model, preview, PR, new branch or migration was used in this block.
