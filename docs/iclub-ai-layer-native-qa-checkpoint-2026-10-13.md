# iClub AI Layer v2.1 — Native QA evidence and P3 status wiring
**Verified 2026-10-13 · Dedicated GitHub QA branch only · NO production deployment**

## Exact independently verifiable test evidence

**GitHub Actions run:** https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/38346873724  
**Commit verified by CI:** `ec955ee8528bb23acf127f35a5c2be1db23d01d2`  
**Conclusion:** SUCCESS, including all requested CI steps, with no failed jobs.

- Native **Node.js 22**: **338/338 tests PASS** across 20 source-backed suites, not the previous simulated V8 runner. Full autonomous test includes source-release governance, cross-subject readiness, Maths Tutor compatibility, P1/P5 skill/locale isolation, Economy/Chemistry Practice exact-question, Tours, 1:3 synthetic billing, reply idempotency, UI protection and deferred content states.
- Additional **8/8** synthetic smoke metering scenarios pass.
- Existing Exam Prep subject isolation regression: six non-Mathematics subjects, Maths beta and six late-response races: GREEN.
- Native **PostgreSQL 16** in GitHub Actions ephemeral Docker service: **4 of 4 distinct local scratch suites PASS**, each on a uniquely named newly created empty `iclub_ai_v21_scratch_ci_*` database: `meter`, `math`, `practice`, `release`. The SQL scripts run against an actual PostgreSQL engine; the synthetic fixtures are discarded/dropped after completion. **No real Supabase project was contacted by CI.**
- Explicit protected-file SHA/diff check against production baseline `9afc7b44aead03b2a30544e6e7d4c4eb8670efbf` passed: `exam-prep/`, `supabase/functions/exam-prep-ai/`, `supabase/migrations/`, `index.html`, `app.js` unchanged on the QA branch.

## Local Docker PostgreSQL safety improvement

The initial test attempt failed because PostgreSQL-in-Docker reports its *internal Docker network interface address*, not the host runner's `127.0.0.1`. The guard was overly strict. Updated QA-only `qa/run-ai-layer-v21-postgres-local.sh` and all four UNAPPLIED SQL / transaction fixtures to require **both**:
1. An empty database with the exact `iclub_ai_v21_scratch_*` naming pattern and a runner-specified `127.0.0.1` connection; remote host names or IPs are rejected by the shell.
2. A true local server interface **or** a private Docker bridge interface `172.16.0.0/12` with `application_name='iclub_ai_v21_local_scratch'`. This accommodates the ephemeral GitHub Actions Postgres service but does not allow non-scratch databases.

Any invocation on real production database names is rejected by each UNAPPLIED SQL draft, even when not using the safe runner. **No DDL/DML was applied to production.**

## P3 user-facing not-ready status improvement, subsequent to CI commit

QA branch `global-ai-ui.js` now treats server `in_development`, `subject_not_ready`, `approved_source_missing`, `source_not_ready`, `no_source` and `topic_not_released` as a single **localized status**. The user sees:
- RU: **«В разработке. AI-помощь по этой теме пока готовится.»**
- UZ: **«Ishlab chiqilmoqda. Bu mavzu bo‘yicha AI yordami hali tayyorlanmoqda.»**
- EN: **“In development. AI help for this topic is being prepared.”**

No call to quota-exhaustion UI is triggered by that branch. Existing expensive-route insufficiency, protected exam hiding and old Maths Exam Prep UI remain independent. Two new offline interface contract tests were added in `qa/ai-layer-v21-interface-guard.test.cjs`. **The final UI patch was subsequently verified in native GitHub Actions:** run https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/38347173145, commit `e514cde3f72141cc9a89874410c64754dc1a0605`, SUCCESS. **340/340** native Node tests passed, plus 8 smoke tests, four separate PostgreSQL scratch suites (meter/math/practice/release), and protected Exam Prep file check. Do not describe the later commit as already covered by the earlier CI SHA.

## NO-GO gates still open (no learner rollout)

1. The public app does not yet import the new content-handoff gate or have a deployed, JWT-bound new AI Edge route. Everything remains QA-only.
2. The SQL drafts are not installed; production topic-publication service and reviewed source publisher are absent. Content/cards/questions remain another chat's responsibility; this chat supplies only the technical receiver.
3. Distributed Edge cold-start/idempotent completed requests and concurrent cross-worker charging need real integration tests. The local PostgreSQL meter suite tests sequential accounting/TTL/rollover, **not true concurrent clients across Edge instances**.
4. Provenance/ACL/RLS review on full production schema, provider spending/safety, and end-to-end mobile RU/UZ/EN via a **single deliberately approved protected Preview** remain pending.
5. Owner approval for a controlled beta and the temporary mixed 1:3 tariffs remains separately required. Never reroute existing Mathematics Exam Prep Tutor.

**Production/main modifications:** 0. **Supabase writes:** 0. **Vercel deployments initiated:** 0. This checkpoint uses only GitHub Actions ephemeral infrastructure.

## Final consolidated QA verification — 2026-10-13

The later green run [38347173145](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/38347173145) supersedes the earlier 338-test checkpoint for final technical verification. Native **Node.js 22: 340/340** PASS; additional **8/8** smoke PASS; native **PostgreSQL 16: 4/4** scratch test suites PASS; legacy Maths isolation and protected file checks PASS. All QA runners and SQL files are fully isolated from production, deployed Edge functions, real learners and working Supabase. The SHA above is the tested snapshot.
