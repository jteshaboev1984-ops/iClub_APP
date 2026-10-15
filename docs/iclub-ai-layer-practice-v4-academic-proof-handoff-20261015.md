# iClub AI v2.1 — Practice V4 server-proof integration checkpoint

**Date:** 15 October 2026
**Scope:** Existing QA branch only: `qa/iclub-ai-layer-v21-20261012`.
**Academic release:** NO-GO. **Production and student data:** untouched.

## Exact real-app findings

1. The real `app.js` sets `data-practice-ai-attempt-id` on `courses-practice-result` / `courses-practice-review` after the existing Safe V4 result. It also sets `data-practice-ai-subject-key`. A review question row can carry `data-practice-ai-question-id`.
2. The schema verified by the earlier read-only source audit and local real-schema fixtures has distinct `public.practice_sessions_v4.id` and `public.practice_sessions_v4.legacy_attempt_id`. A UI attempt marker **must not** be substituted for `practice_sessions_v4.id` without authenticated server resolution.
3. The existing `courses-video` is presently a subject-level Telegram video group. `state.courses.lessonId` is the primary subject lesson ID for existing video events, NOT editorial proof of a specific AI lesson/transcript. No academic-topic mint may rely on it.
4. Browser labels, DOM classes, `localStorage`, question text, correctness and inferred school progress are **never** authority for the answer.

## New, independently testable QA components

- `qa/ai-v21-real-academic-screen-bridge.cjs`: zero-network client selection candidate for an explicitly selected question row in the actual Practice review. Rejects active Practice/Tour, Exam Prep, extra/unknown active views, malformed IDs, foreign rows, view/auth/locale changes and stale asynchronous answers. No automatic calls on navigation. Uses a trusted server resolver and then the existing independent `QaV21ScreenClient.openPractice(sessionId, questionId)` to invoke an authenticated context mint. Requires `status.state=available` and `route=practice_result` before any prepared academic request. Does **not** import into production files.
- `qa/ai-v21-real-academic-screen-bridge.test.cjs`: 13 tests covering exact selectors, server ownership boundary, mock source readiness, double selection, races, logout and blackout. They are part of QA Preview CI.
- `qa/sql_drafts/iclub_ai_v21_practice_attempt_resolution_UNAPPLIED.sql`: proposed **service-role-only** read-only RPC returning ONLY canonical selector metadata. Uses the existing `practice_sessions_v4`, `practice_session_answers_v4`, `subjects` and `user_subjects` structure. It denies on kill switch, active assessment, incomplete session, answer without a confirmed timestamp/verdict, invalid ownership, deactivated subject, withdrawn enrollment or ambiguous legacy reference. It grants no execution to `anon` or `authenticated`. The authenticated Edge must derive `p_user_id` from JWT, never a client field.
- `qa/sql_drafts/iclub_ai_v21_practice_attempt_resolution_local_pg.psql`: fresh synthetic Postgres 16 data in an empty `iclub_ai_v21_scratch_*` DB, with `ROLLBACK`; validates canonical ID, zero direct learner grants and multiple fail-closed states.

## QA evidence

- GitHub Actions run `38742215433`: **both jobs GREEN**.
- `offline-preview-acceptance`: 10 preserved UI/contract tests + 13 new academic bridge tests, native Chromium real-app tab transition/Practice/Tour blackouts and unchanged protected source checks.
- `isolated-practice-mapping-postgres`: disposable database with runtime off/on, exact owned V4 session, foreign/unknown/incomplete attempts, missing question, active assessment, inactive subject, revoked enrollment, unanswered question and ambiguous legacy reference.
- No production database, paid provider, source publication, tariff, `main`, original `app.js`, `global-ai-ui.js`, `index.html` or Mathematics Tutor was modified.

## What is **not** ready

- The resolver is an **UNAPPLIED SQL DRAFT**. It is not yet wired to a production or hosted Preview Auth/JWT Edge service; the v2.1 RPC deployment remains an explicit separate approval gate.
- The existing protected Vercel Preview remains a synthetic navigation/UI Preview. These new QA components are not compiled into it, and the old URL should not be presented as proof of real source-backed tutoring.
- No approved source bundle / topic / language release has been provided for genuine question explanations. Without it, only navigation help or clearly labelled `in_development` may be shown.
- The browser cannot prove account ownership or finalized status. Those checks occur at the server and must be repeated at the final mint/answer point; this drafted resolver does **not** by itself grant access.
- Lessons/video/Tour archive, Home and Profile trusted academic data contracts require their own independent server and source proofs.
- Final iClub AI symbol and beta cohort/provider spending are pending separate product decisions.

## Next safe integration target

Implement a typed QA-only resolver action in the already isolated v2.1 Edge and prove an **end-to-end JWT-bound HTTP → resolver → existing Practice context mint → source gate** chain against disposable PostgreSQL. Use no live Supabase/production URL or user credentials. Until that passes and the architect explicitly authorizes a server-backed Preview, keep the current QA UI mock and production Global AI OFF.
