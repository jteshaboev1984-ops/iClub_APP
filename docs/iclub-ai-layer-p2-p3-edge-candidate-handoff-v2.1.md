# iClub AI Layer — P2/P3 unified server request candidate v2.1

**Date:** 2026-10-13 · **Status:** QA branch, synthetic service-backed handler; not a deployed Edge Function.

## Architectural ownership

This workstream implements **only the technical AI Layer**. Academic cards, questions, explanations, assessment editorial approval, video transcripts and subject lesson content come from the separate content workstream. No academic content has been created or modified in this workstream. All source text within test fixtures is explicitly labelled synthetic testing data.

The original production `supabase/functions/global-ai/index.ts` and `supabase/functions/exam-prep-ai/index.ts` remain untouched. The new preview candidate is `qa/ai-layer-v21-edge-request.cjs` and **not** an active Supabase function. Do not import it into `exam-prep-ai` or switch learner routes without explicit release approval.

## Implemented full request sequence

The candidate accepts exactly one supported POST body with `intent=status|answer`, opaque `contextHandle`, `appLocale` and, for answers, a unique UUID `requestId` and *either* an approved `promptKey` or a freeform `question`. Unrecognized fields like client-selected subject, topic, plan, entitlement, quota, grade, readiness or source ID are rejected. The bearer is authenticated by an injected backend service; the principal is NEVER inferred from the request body.

1. For status, look up the active authenticated server context, global emergency flag, current subject and cohort, exact surface×subject×feature×topic×locale publication, and an independent current source version/hash/rights proof. Incomplete content returns localized **«В разработке»**, **«Ishlab chiqilmoqda»**, or **“In development”** with zero charge. A protected assessment hides the surface altogether. Published content in a closed cohort remains unavailable.
2. For an answer, classify the approved prepared action or source-grounded generated route. Freeform language is inferred from the text; ambiguous language and silent locale switching are denied. Do not take a topic, learner or pricing route from the browser.
3. Retrieve the exact server-side approved source bundle and independently verify its source identity, version, SHA-256 integrity attestation, runtime approval, editorial QA, conflict-free rights, locale and publication revision. A text-only topic source cannot automatically answer an unrelated exact Practice question. That remains controlled by the independent Practice authority RPC.
4. For generation, check server-side provider monetary permission **before** reserving a unit. Server policy (temporary QA Free3/Plus9/Pro14) and route weight (prepared1/generated3) are independent of the HTTP body.
5. Hash the server-owned learner ID, opaque active handle, source hash/version/revision, route and normalized question to produce an immutable request fingerprint, and separately hash the context session. Call v2 **atomic quota reservation** and then the new **durable delivery claim**, so another worker/retry cannot launch a duplicate provider call.
6. Before the provider call, **re-authenticate the bearer**, recheck the current learner policy and provider monetary budget, and independently reread the current protected-assessment state, screen revision, cohort, topic publication, source hash and rights. Fail closed on a mismatch.
7. Return exact prepared response text from an already validated approved variant, or (for QA only) call an injected `generateSynthetic` provider that never makes real network calls or generates academic content. Check output presence/length/basic unsafe markup. **These checks alone are not sufficient for production model safety.**
8. Re-run all authorization/source checks **after** the async provider. If output and permissions still hold, settle learner quota and durable request tombstone **in one PostgreSQL transaction** via the P7 finish RPC. Otherwise settle `released` (zero learner units). An ambiguous database outcome is never declared successful.
9. Return only a compact learner-facing result. No private source keys, content hash, pricing weights, transcript history, prompt provenance, grading details or raw progress to the browser. Never write to Practice/Tours/Exam Prep progress, evidence, certification, mastery or localStorage.

## Required privileged adapters before a *real* Edge Preview

The `CandidateEdgeRequest` constructor currently accepts injected **synthetic** implementations. A subsequent protected and deliberately reviewed Edge adapter must implement:

| Service | Trust requirement |
|---|---|
| `authenticate(bearer)` | Verify JWT through Supabase Auth with a user-scoped client; do not decode or trust client ID locally |
| `getServerTimeMs` / `getScopedContext` | Auth-bound, expiring, revisioned *server-created* context handles, correct current screen, owner and protected activity |
| `getGlobalState` / `isProtected` | Existing global kill switch, separate owner beta release flag and protected-assessment RPC |
| `getSubjectActive` / `isRolloutAuthorized` | Live subject membership, user entitlement and independently authorized cohort |
| `getPublishedRelease` | New service-only `get_iclub_ai_topic_release_service_v21` RPC, with per-language/topic/feature approved publication row |
| `getLiveSourceProof` | Independent current source and rights/version/integrity proof; cannot use static card metadata as authorization |
| `getSourceBundle` | Server-only exact current approved contents; independently verify actual source integrity, QA status, rights, hash/revision and scope; NO synthetic filler allowed |
| `getPolicy` / `providerBudgetAllows` | Server-owned account entitlement and financial caps; never client-supplied plan |
| `reserveUsage` | Service-only `reserve_iclub_ai_usage_service_v2`, atomic shared allowance |
| `claimDelivery` | Service-only `claim_iclub_ai_delivery_service_v21`, unique request ID and session/source fingerprints |
| `finishDelivery` | Service-only `finish_iclub_ai_delivery_service_v21`; atomic charge or refund |
| `generateSynthetic` | MUST be replaced by a separately authorized production model adapter with safe, approved source and output policy. Not enabled in production |

**Critical:** the four new v2 SQL service functions and topic publication schema remain under **UNAPPLIED scratch-only** QA files. They cannot be called in current production Supabase. Production Auth, real context minting, complete source/rights attestation, RLS and provider secrets were not exercised by these tests.

## Verified native QA

**Final security-hardened GitHub Actions run:** [#38350530047](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/38350530047); tested code commit `3daf24e60379c1837f77be53e11a554c811931b0`. **SUCCESS**.

- Native Node.js 22: **382/382** passing tests across **22** suites, including **28 new end-to-end handler scenarios** and **2 new post-publication race cases**.
- Eight additional synthetic metering smoke cases PASS. Existing Mathematics Exam Prep subject-isolation and late-response regression PASS.
- Native PostgreSQL 16: **six** separate scratch-only suites PASS (`meter`, `math`, `practice`, `release`, `claim`, `atomic`).
- Two concurrent PostgreSQL client sessions: exactly one durable provider claim, the other denied; controlled mid-settlement exception correctly rolls back the quota and delivery state.
- Protected Math Exam Prep files, migration directory and app entrypoints compared unchanged to production baseline; Vercel builds 0, real Supabase writes 0, deployments 0.

## Strict release blockers

- The candidate is **CommonJS in the QA directory**, not directly executable as the deployed Deno Edge application. Real TypeScript/Deno handler and credentials-scoped SDK adapters are **not yet implemented**. Passing Node tests does not certify an Edge runtime.
- No migration has been applied and no content publisher has been deployed. A card appearing in another workstream is not by itself permission to enable a real beta.
- Provider tests are synthetic only; real provider costs, output safety, prompt-injection handling and confidential-data minimization need independent review.
- A durable tombstone avoids double execution but does not guarantee retrieval of a completed reply if the HTTP response is lost. Session-bound privacy-reviewed short-lived encrypted receipt remains an open design.
- Any per-request `releaseApproved` and cohort flags must remain OFF for real users until explicit architect approval; real data/progress, production/main and existing Exam Prep remain unchanged.
- Proceed only after authenticated Deno Edge adapter, local/Preview environment verification, reversible SQL deployment review, mobile RU/UZ/EN user-journey QA and explicit beta approval. Use one protected Preview at the justified time, not repeated Vercel builds.
