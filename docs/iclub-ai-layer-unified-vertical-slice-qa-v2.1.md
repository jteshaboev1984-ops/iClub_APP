# Unified AI Layer v2.1 — integrated preview contract (QA only)
Date: 2026-10-12. Status: **synthetic candidate only**. Do not deploy or expose to real learners.

## What was built

The QA module `qa/ai-layer-v21-unified-vertical-slice.cjs` composes the already-reviewed independent contracts into one request lifecycle:

1. Authenticated server principal plus resource kind/id, with no academic authority from the browser. Existing schema-backed `MockServerContextResolver` confirms session owner, finalized status and all protected-assessment rules. Tour archive additionally requires completed attempt, separately finalized runtime record, and explicit archive unlock.
2. **Separate server evidence lookup** (`getTopicEvidence`) binds a verified skill/topic to that exact learner, finished resource, component and subject. A finished Math session by itself is *not* sufficient because it does not contain a specific source skill ID.
3. **Governed source lookup** (`getReviewedSource`) must return approved, rights-cleared, QA-passed, non-conflicting, versioned source for subject × surface × feature × topic × locale. Mathematics P1/P5 source key must additionally match the 243-entry metadata-only Tutor catalog. The actual server adapter is a TODO; mocks provide no production authorization.
4. Existing independent feature-registry release gate checks readiness, locale, topic and authorized rollout cohort. Preview accepts **synthetic learner** only. Owner-controlled real beta stays disabled.
5. Exact prepared prompt = 1 temporary usage unit. Unstructured source-backed mock-generation = 3 temporary units. A text prompt is not silently classified as a ready card, and source/plan/provider-budget permission comes only from server services. One user's allowance is global across Math, Practice and Tours; expensive shortfall does not block affordable prepared responses.
6. The request is reserved, reconfirmed before processing, and reconfirmed after any async provider call. Failed or undeliverable requests release learner quota. Two simultaneous requests cannot exceed the shared limit. Response is validated for nonempty/size and basic script-marker safety; this is **not** full provider hallucination/schema safety QA.
7. A short-lived session-bound receipt allows a safe repeated response without repeating the provider call or charging again. A new examination/permission/source revocation prevents replay. This receipt and the completed-ID ledger are process-local test mocks, **not sufficient for distributed Edge restarts**.
8. Learner output contains only response text and status; no source keys, weights, progress, answer keys or hidden server evidence. All existing academic state remains read-only.

## Testing

`qa/ai-layer-v21-unified-vertical-slice.test.cjs`: **26/26** stored-source scenarios executed successfully in the isolated V8 test runner. Scenarios include academic context authentication, Practice completion, Tour archive lock, Math source-key binding, server-only language/plan/route, source revoke mid-generation, quota failure, budget, 4 concurrent generation requests against Plus9, retries, active assessments, invalid output and protection from client spoofing.

Runner `qa/run-ai-layer-v21-offline.cjs` now contains **14 test suites**, including this one. **The full combined 14-suite run was not completed** because the connector call limit interrupted the attempt. Actual native Node/PostgreSQL/browser execution remains open.

## Hard boundaries before real integration

- **Do not import** this QA module into `global-ai-ui.js`, active `supabase/functions/global-ai/index.ts`, or the existing `exam-prep-ai` Edge handler.
- Replace `getTopicEvidence` with a real, scoped, server-only mapping to an approved deterministic evidence ID; verify item membership, learner ownership, source scope, no active assessment; preserve P1/P5 independence.
- Replace `getReviewedSource` with versioned academic/rights governance, release flags and actual source content; the metadata snapshot alone is insufficient for authorization.
- Replace mock `PreviewLedger` with local-PostgreSQL-tested, atomic and versioned v2 tariff RPC, and a durable minimum idempotency record across Edge instances. Keep raw chat session-only.
- Replace `generateMock` with a separately approved provider integration, formal output schema, safe feedback, pricing controls and a second protected-assessment check before response delivery.
- Run exact-source native Node suite, PostgreSQL scratch test including concurrency/TTL and protected browser Preview once worth the Vercel quota. Rollout and original Math Tutor migration require explicit owner decision.

**Verified non-action:** no update to production/main, Supabase database, real learners or their progress, current Math Tutor, or Vercel deployments.
