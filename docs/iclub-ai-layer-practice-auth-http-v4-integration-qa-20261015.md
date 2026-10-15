# iClub AI v2.1 — verified Practice HTTP integration, 15 October 2026

**Branch:** `qa/iclub-ai-layer-v21-20261012`
**State:** isolated QA GREEN. **Production Global AI:** OFF / NO-GO.
**Preview:** the last approved protected real-app visual Preview was not modified or redeployed by this phase.

## Source-of-truth resolution — evidence from actual iClub code

The immutable live `app.js` publishes a `practiceAiAttemptId` marker on finalized Practice result and review screens, derived from `safePersistedResult.attemptId`. This is computed from `finalResult.attempt_id`, not `finalResult.session_id`.

The actual `supabase/migrations/20261007006700_math_practice_v2_deterministic_feedback_v5.sql` contains `public.finalize_practice_session_safe_v5`. That finalizer returns both `attempt_id = v_attempt_id` and `session_id = p_session_id`, and records `legacy_attempt_id = v_attempt_id` in `public.practice_sessions_v4`. Thus the UI attempt marker is a **legacy Practice attempt ID**, not the canonical V4 session ID. This is now also guarded by `qa/ai-v21-practice-source-contract.test.cjs`. These are separate values even where they happen to be numerically equal in any test or dataset.

The editor-approved course/lesson/source and the question ownership are independent: DOM title, client-selected IDs and source-readiness flags are never proof. The actual video screen uses subject-level Telegram lessons, which is not evidence for a specific approved academic topic/transcript.

## New QA-only server + client implementation

- `qa/edge_v21/context_core.ts`: strict additional `resolvePracticeV4` action on the **existing** /context route, after the existing authenticated principal check. Accepts only `attemptReference` and `questionId` from the request; all user/subject/score/source/answer/plan fields are rejected. A new resolver-specific key is refused on all older actions. RPC response is whitelisted to 5 non-academic selector fields, and authorization is not inferred from this mapping.
- `qa/edge_v21/practice_resolver_service.ts`: an isolated, localhost-only, service-role PostgREST RPC adapter; rejects remote Supabase origins, validates exact owner and numbers, handles failures without leaking private errors or service secrets.
- `qa/edge_v21/index.ts`: composes this new local-only candidate with the previously implemented Edge services **only behind** the existing `isolatedQaStartupAllowed` gate. No deployed production Edge entrypoint or Vercel runtime imports it.
- `qa/ai-layer-v21-ui-transport.cjs`: a new JWT-bound resolver request that cancels stale navigation/logout before and after asynchronous requests, never mints itself. The existing context mint then **re-checks** owner, finalized question and protected-exam constraints.
- `qa/ai-v21-real-academic-screen-bridge.cjs`: now requires the same source-approved `ru`/`uz`/`en` locale throughout selected-question verification, status and prepared answer. A ready RU answer is not admission for UZ or EN.
- Original `app.js`, `index.html`, `global-ai-ui.js`, `global-ai-ui.css`, `exam-prep/` and production `supabase/migrations/` remain unchanged.

**Additional RPC inventory:** `resolve_iclub_ai_v21_practice_attempt_service` is one **proposed, unapplied** service-role-only read-only SQL contract, tracked separately from the frozen 24-RPC v2.1 deployment preflight. The original 24 production release gates have NOT been silently amended or bypassed. To authorize a future rollout, the inventory, permissions, policy and live metadata snapshot must undergo fresh explicit review.

## Tests and exact independence

GitHub Actions **`38745573516` — GREEN**, pinned at `2c2ec74638315ad62343a6392e118386e24efb40`:

1. **Offline real-app acceptance:** original UI source frozen; Chromium navigates actual Home/Study and enforces Practice/Tour blackout; node tests for server selector, ID source drift, exact RU/UZ/EN release, JWT transport races, replay and asynchronous navigation invalidation; in-memory Deno /context HTTP tests reject forged body keys and wrong Origin/Auth.
2. **Local PostgreSQL function:** synthetic finalized Practice maps `legacy_attempt_id` to the **owned** exact V4 session + answered question, rejects a foreign learner, active session, missing question, ambiguous legacy reference, withdrawn enrollment, inactive subject, protected assessment and kill switch.
3. **Actual localhost HTTP → PostgreSQL:** a local Auth **identity shim** (synthetic tokens, **not signed real JWTs**) delegates through the actual TypeScript service adapter to a real disposable PostgreSQL 16 resolver function. Exact owner V4 resolution succeeds; direct browser RPC, foreign identity, unverified question, protected active assessment, revoked access and kill switch fail. A separately absent V4 context mint and source-publication RPC continue to deny; no academic response is generated.

All databases use fresh `iclub_ai_v21_scratch_*` names on localhost, then are dropped; no production, subscriber, tariff, real learner, provider or academic progress data is accessed or altered.

## Unresolved STOP conditions before integrated beta

1. Hosted real Supabase Auth/JWT validation and trusted current-screen authority are **not** tested in a production-connected environment. The local Auth identity shim is synthetic.
2. Proposed 25th resolver RPC and original V2 SQL contracts are **not installed** in production. The QA-only Edge is not deployed as the learner AI service.
3. There is **no released, versioned, rights-approved RU/UZ/EN question source** allowing an explanation. The test explicitly confirms that a canonical selector is not a source publication and that absent mint/source gates refuse authorization.
4. Practice-level **result summary** and question-level **error explanation** are separate feature contracts. The new resolver covers explicitly selected questions only. Do not silently reuse it for full-result coaching.
5. Tour archive, lesson/video, Home/Profile evidence and independent Mathematics P1/P5 exam safety remain governed by their existing separate proof contracts.
6. Final iClub AI brand mark, cohort, budget, tariff and production kill-switch release need distinct owner approvals. Controlled beta stays unchanged and Global AI stays OFF.

## Next bounded QA milestone

Develop a **source-governed prepared-error explanation** using separately authenticated `practice_result` context, verified finalized answer and editor-approved, rights-checked source. Demonstrate RU/UZ/EN isolation, cancellation on navigation, zero provider calls and zero academic mutations entirely within disposable QA. Do not attach to production or treat a synthetic green test as commercial readiness.
