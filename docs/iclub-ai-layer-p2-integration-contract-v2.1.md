# iClub AI Layer — P2 Integration Contract v2.1
Date: 2026-10-12. Status: QA-only, implementation preparation, no release approval.

## Sources checked
- Project document 06 AI Layer Safety Architecture v1.1: browser requests have no academic authority; the server authenticates, checks assessment protection, builds verified learner context, and reads only approved/versioned sources. AI cannot mutate academic state.
- Project document 04 Content Governance Model v1.1: content reuse requires provenance, academic checks, approved versions; legacy Practice/Tours/history IDs and evidence must remain intact.
- Project document 03 Exam Prep Integration Architecture v1.0: Mathematics Exam Prep remains an isolated sub-application. Preserve its tiny host bridge and existing user/local drafts.
- 44 owner decisions rounds 1–8 plus TEMPORARY 1:3 mixed quota clarification and permission to reuse the existing Preview for synthetic UI without requiring a new cloud Supabase project.

## Findings from existing Global AI edge code (READ-ONLY)
- Existing source: supabase/functions/global-ai/index.ts.
- Authenticated user and service guard: currentUser(authorization) and get_iclub_global_ai_guard_service_v1.
- Current request extracts locale, subject_key, scope_code, component_code, skill_code from client payload. The real guard handles entitlements and protected assessments, but per-screen/topic/language authoritative context must be verified before extending the runtime. Do not treat client hints as academic truth.
- Existing Math gateway uses versioned Tutor/theory sources and separately reserves learner tariff usage and provider cost. It is dormant at the global runtime.
- Existing v1 SQL function reserve_iclub_ai_usage_service_v1 can set exhausted=true after one insufficient costly request. Old generated weight=5. Neither may be silently changed in production.
- QA branch global-ai-ui.js/css: active protected exam hides AI mark fully; route_insufficient gets a distinct response without setting global usageExhausted. This is not yet connected to a v2 SQL response.

## Mandatory v2 server flow
1. Server authenticates the current learner. Client supplies a question/quick prompt and a short-lived context handle, NOT a trusted academic context.
2. Server fetches and verifies context ownership, active screen and subject, entitlement, release cohort, finished Practice or server-unlocked Tour archive.
3. Run protected assessment guard before source retrieval/cache/model and repeat the guard when a race could occur before the provider call.
4. Resolve question language from the learner's question. Ambiguous EN/UZ or mixed-language questions do not silently change languages. Quick prompts are versioned per locale.
5. Verify readiness for surface x subject x feature x topic x locale, source rights, content QA/version, and no conflicts.
6. Choose exact prepared response (1 temporary unit), or approved source-backed generation (3 temporary units). Never substitute an unrelated cheap card.
7. Atomically reserve from ONE global user allowance shared by all subjects. If the costly route does not fit, reject ONLY that route: e.g. remaining=2, generated=3 denied, two prepared=1 still permitted. Nothing charged on failure.
8. Separately enforce SERVER-owned monetary provider budget, then validate output. Finalize only a successful answer. Release reservations on refusal/provider error/timeouts. Request IDs must be idempotent and bound to user, route and content fingerprint.
9. Return to learner a clean response without private source keys, quota weights, raw context or another user's data. AI may not write placement, mastery, evidence, progress, certification or rankings.

## Independent readiness and rollout
- One topic or locale can become ready without opening the entire subject. All eight offline QA gates must be green: content, rights, version, correctness, negative tests, assessment protection, locale and accessibility.
- Automated enablement is limited to a previously owner-approved release cohort (38C + 21A). No topic-level Vercel deployment (42A). Emergency feature stop leaves unrelated AI functions running; global new-AI emergency stop remains possible (43A).
- Initial Preview uses synthetic learners and responses. Existing Preview can share production Supabase connectivity, but NEW AI mock and metering tests MUST NOT write there. No new test account creation for AI.

## QA implementation saved in GitHub
- qa/ai-layer-v21-preview-gateway.cjs and test: 20/20 inspected-source checks PASS.
- qa/ai-layer-v21-authority-gate.cjs and test: 17/17 checks PASS.
- qa/ai-layer-v21-readiness-registry.cjs and test: 12/12 checks PASS.
- qa/ai-layer-v21-synthetic-pipeline.cjs and test: 13/13 checks PASS, including cross-subject quota and server-owned provider budget.
- qa/ai-layer-v21-interface-guard.test.cjs: seven Node test cases prepared; targeted direct JS/CSS checks passed.
- qa/ai-layer-metering-v21.synthetic.js: eight initial offline checks passed.
- qa/run-ai-layer-v21-offline.cjs: consolidated local Node command without Vercel/Supabase/provider.

These are offline behavioral tests of the committed QA files in a JS harness. They DO NOT prove real PostgreSQL RPC behavior, a browser e2e run or an active Global AI product. Do not describe them as production acceptance.

## Next implementation gate
- Prepare and locally validate a NEW, reversible v2 SQL migration and complete idempotency tests in isolated PostgreSQL; never edit or replay an already-shipped migration against production.
- Build the real server adapter around authoritative ownership/assessment RPC, per-skill versioned sources and language readiness. Unknown/unsupported subject fails closed.
- Integrate only into protected synthetic Preview after offline and contract QA; preserve current Mathematics Exam Prep unchanged.
- Accumulate work for ONE necessary Vercel deployment instead of spending quota on microsteps. Preview deployment and any real beta permissions remain owner-controlled.

STOP: No production/main/Supabase writes, no real AI provider calls, no payments or migrations, no new production user, no release.
