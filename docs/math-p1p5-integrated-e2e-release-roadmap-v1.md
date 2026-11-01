# Mathematics P1/P5 — Integrated E2E Digital Release Test Roadmap v1.0

**Created:** 2026-11-01 | **Decision owner:** iClub product architect | **Executor:** ChatGPT via linked GitHub/Supabase/Vercel tools and GitHub Actions.
**Status:** APPROVED PLAN / IMPLEMENTATION NOT YET STARTED. Do not mark stages complete without evidence.
**Canonical continuation reference:** this file on `main`; keep one ledger here across conversations. Do not restart audits or silently overwrite completed stages.
**Scope:** Cambridge AS Mathematics Exam Prep P1/P5 *technical end-to-end behavior and release readiness*. Distinguish content publication from mass learner rollout.
**Related closed roadmap:** `docs/exam-prep-synthetic-validation-roadmap-p2-62-p2-80.md` (engineering GREEN does NOT equal real learner release evidence).
**Related written checkpoint:** `docs/exam-prep-written-equivalence-beta-acceptance-20261101.md`.
**Normative source of truth:** project-approved P1/P5 Master Implementation Plan v1.1; Beta Release Plan v1.1; Academic Syllabus Source Map; Content Governance Model; AI Layer Safety Architecture; Mentor Care Operating Model; annual roadmap compliance; `docs/exam-prep-written-learning-contract-v1.md`. When policies conflict, do not silently choose a new product rule: surface the contradiction for the owner.

## Owner decisions and boundaries (permanent)

1. Complete engineering/testing **in ordinary ChatGPT conversations** using linked GitHub, Supabase and Vercel; **ChatGPT Work is optional, not required**; use Codex sparingly only for code-heavy work if warranted.
2. Do NOT force a human to answer all 1,448 questions. Reuse the completed AI-assisted academic second pass and existing source checks; add deterministic 100% metadata/routing coverage and behavior-type tests. Do NOT claim machine tests prove independent human academic certification.
3. Build **one integrated automated test pipeline** proving: *real learner-facing P1/P5 interface → authenticated HTTP client → actual compatible Exam Prep RPC/database permissions → isolated database write → returned response → rendered UI state → sign-out/reload/resume → independent server truth*. Distinguish an actual local Supabase API/Auth stack from existing JS mocked RPC browser tests and direct SQL tests; both are useful, neither alone is sufficient.
4. Production Supabase project **`mmmduffgpvwjdpruzikw` is READ-ONLY** for these tests. NEVER use live learner accounts/tokens, synthetic writes or feature-flag changes in production; never clone private learner PII into fixtures.
5. Do not modify or wipe existing learner scores, sessions, entitlements, permissions, localStorage, registration, Practice, Tours, ratings, certificates, or live academic answers. Stage fixes in feature branches; additive/versioned; validate against exact SHA; rollback without repairing learner history.
6. Do not bypass `private.exam_prep_beta_expansion_gate_v1` or `private.exam_prep_p3_01_mass_core_rollout_gate_v1`; simulated weeks/AI scores/CI results MUST NOT create fake human reviews, beta sign-offs or mass GO. Governance remains a separate owner approval.
7. Core must work with AI and Mentor OFF. Written Core supplies task/criteria/Next, but does not automatically grade arbitrary free-form solutions: `self_reviewed` / `app_checked_noncredit` do not add mastery. Optional timed-paper learner self-mark must never be represented as examiner grade.
8. Report and fix real defects, not only write audit reports. Do not alter product decisions without owner sign-off. Preserve private answer keys and protected assessment material; never commit secrets, real answers or personal data to CI logs/artifacts.
9. This roadmap and its status ledger must survive chats. Update status + linked exact commits/CI runs and blockers here **after each substantial completed stage**. A new conversation starts by reading this roadmap and linked checkpoints, not re-planning.

## Verified baseline (snapshot 2026-11-01; never treat as immutable future state)

- Source bank: **1,448 current distinct objects** = 486 released machine learning questions (P1 270/P5 216) + 729 governed withheld diagnostic/mixed/retest items (P1 405/P5 324) + 233 current published written tasks (P1 130/P5 103). The 729 are intentional holdouts, *not unfinished drafts*. 70 P1/P5 content versions published and 716 assessments published at snapshot; no outstanding draft assessments. All 233 current written tasks linked in published assessments.
- Existing second-pass academic review: `docs/math-p1p5-independent-second-pass-audit-20261030.md`, completed 1,448/1,448; human examiner certification not claimed. Existing static/quality/source and 180 companion MCQ test coverage. Preserve historical written versions.
- Existing simulated/CI validation: `supabase/tests/p2_67_canonical_scenario_matrix_v2.sql` (15 canonical profiles + 18 adversarial variants); `.github/workflows/p2-73-core-engineering-dress-rehearsal.yml` (3 deterministic seeds, isolated PostgreSQL); P2-78 600/10 scope isolation; `supabase/tests/p2_79_recovery_rollback_disaster_matrix.sql`; `.github/workflows/exam-prep-written-beta-isolated-e2e.yml` (30 localized browser cases, **synthetic RPC**); `scripts/weekly-flow-native-browser-journey.cjs`, `.github/scripts/p2_55_full_learner_journey_regression.js`.
- **Critical identified coverage gap**: browser/HTTP/Auth/actual RPC state are not established to be exercised *as a single chain* by these separate suites. The 30 Written Core browser scenarios use a generic Economics P2 example, not independent full Mathematics P1/P5 real-server journeys.
- Production remains operational; the content is published. However `rollout_state=controlled_beta`, `qa_open_all_core=true` and `qa_open_all_weekly=true` were verified; **do not switch either off** without a migration of access for existing users. Mass release gate was `NO_GO`, reason `four_real_weekly_reviews_incomplete`, real weekly reviews 0, staff reviewer roles 0. Legacy access/progress require explicit preservation.
- At snapshot 8 scheduled retest events, 0 completed retests; diagnostic and learning sessions existed but no observed real-user mixed/timed/paper completed journey. This is a real-world validation gap, not evidence of a functional defect.
- Vercel production latest observed READY at main commit `9853bfa4499c50bc3dd5977c29b54f83e34bc0d3`. Verify again before any candidate deployment.

## Execution: four substantial stages (do not split into micro-tasks)

### STAGE A — Trace and coverage-gap inventory
**State: COMPLETE — 2026-11-01, source and live RPC inventory verified; not full-stack E2E.**
- Trace all Mathematics Core journey entrypoints, front-end event handlers, API adapters, auth/session handling, Supabase RPCs, item selection, scoring/evidence, weekly plans, correction, delayed retest, mixed transfer, timed/full paper, written criteria and resume.
- Reuse the existing tests instead of rerunning every past academic audit. Produce **source-path + RPC + authoritative table + invariant + test evidence** mapping. Specifically label tests as real API, real PostgreSQL direct, or mocked browser: never conflate them.
- Inspect current branch/main versions, relevant migration order and exact consumer/contract compatibility. Identify smallest gap closure for authentic local API/Auth and real test identities. Work from schema/approved sanitized content; never copy production learners or export confidential question keys to public GitHub.
**Done when:** traceability matrix covers every major P1/P5 state-changing route, each has an authoritative invariant and test type, and missing integrated paths are clearly enumerated.

### STAGE B — Integrated isolated authenticated E2E
**State: NOT STARTED.**
- Reuse ephemeral PostgreSQL 17 `p2-73` setup. Add local compatible Auth + PostgREST/Supabase API (or verified equivalent with actual auth.uid(), JWT claims, roles and grants) in CI. Must label any remaining simulated transport as simulation, not real full-stack acceptance.
- Use synthetic IDs and sessions ONLY in isolated DB/temporary containers. Create minimum sanitized fixture pack that exercises actual P1/P5 content version selection and answer mechanisms without leaking protected answer keys. Fail the test if it targets a production hostname/project/key, lacks explicit isolation marker, or has access to real learner data.
- Drive actual iClub Mathematics P1/P5 host with Playwright and authenticate fake test users through local auth. Trace via HTTP: profile → entry → diagnostic → answer/finalize → placement → learning/weekly plan → correction → fresh delayed retest → mixed → timed/paper → written criteria/Next → logout/reopen/resume. If progression is evidence-gated, synthesize **valid incremental academic evidence**, not raw stage flips or calendar advancement.
- Compare UI, HTTP response, Postgres event/evidence, and expected independent model after each transition; assert no P1/P5 or cross-user leakage. Record exact SHA, deterministic seed, anonymized trace and DB assertions. Protect marks and full-solution keys before finalization.
**Done when:** integrated authenticated P1 AND P5 paths pass through real client→API→DB roundtrips (no mocked core RPC for claimed passes); exact reproducible CI evidence exists and no production mutation.

### STAGE C — Model-based, fault, locale, coverage and concurrency battery
**State: NOT STARTED.**
- Reuse 15 canonical learners + 18 adversarial variants (strong P1/weak P5, opposite, both weak, mixed accuracy, interruption, repeated errors, recovery). Drive varied correct/incorrect/unsubmitted/invalid/duplicate inputs and student progression by a seeded model/state machine; keep objective outcomes consistent with server-authoritative key and written noncredit.
- For **all 1,448 current items**, run structural integrity, publish/holdout, skill P1/P5, task version, localization, eligibility, item-to-assessment routing, option/marking metadata and exposure-rule checks; do not equate this with re-solving mathematical content. Count every item once, preserve old versions/historical sessions.
- Test RU/UZ/EN on mobile/desktop viewport, long mathematics formula rendering, text clipping, tap targets, error states. Preserve Telegram WebApp-specific check for short real device smoke later.
- Fault inject: offline before/after commit, lost ACK, retry/reopen, double taps, concurrent tabs, stale/expired auth, retired item, timer deadline, time-zone boundary, insufficient entitlement, direct RPC spoofing, cross-user read/write attempt, spoofed stage/mastery, answer-key leaks, AI/Mentor unavailable. For future retests use controlled test-server clock or clock abstraction, not falsified evidence or unsafe production timestamps.
- Reuse P2-78 600/10 and P2-79 rollback suites; re-run on exact candidate only when relevant changes. Use trace/screenshot/diagnostic artifacts only from synthetic data and redact keys/secrets.
**Done when:** every required behavior class and all 81 skills are covered, 1,448/1,448 structural routing assertions pass, critical safety invariants all pass on repeatable seeds and zero uncontrolled false progression/data contamination.

### STAGE D — Consolidated release engineering and residual real-user boundary
**State: NOT STARTED.**
- Build one orchestrated, reproducible GitHub Actions job/workflow: fast contract checks → isolated integration DB/auth/HTTP → actual P1/P5 browser journey → model/fault/locales → state integrity/rollback → report. Run against candidate SHA; fail closed on any critical regression. Do not make paid AI calls by default.
- At every failure: collect deterministic reproducer; patch only confirmed defect in protected branch; run full impacted regressions; report **fixed and verified** vs **unfixed/blocker**. Confirm no change to production learner data and preexisting Practice/Tour/cert/localStorage guarantees.
- Return evidence matrix with scenarios covered, actual vs mocked labels, P1/P5 independent results, untouched user-data guarantees, CI links and current deployment/version. Produce separate verdicts: (1) content published; (2) engineering E2E pass/fail; (3) real-user beta evidence; (4) mass release governance.
- Existing real beta gate still requires **actual** consented accounts on real Telegram/browser, at least 2 independent users for sampled smoke, 4 authorized weekly human reviews with honest evidence, 72h monitored rollout after a real wave, and controlled access migration for historic users. Synthetic/CI cannot mark these complete or turn on mass rollout.
**Done when:** one reproducible green candidate-specific pipeline + no Sev0/Sev1 and a separate honest list of real-world decision blockers. Mass GO only after current server gates and architect's explicit approval.

## Non-negotiable invariants to assert throughout

- Never alter existing real user progress, live sessions, registration, legacy Practice/Tours/rating/certificates, or localStorage; no destructive migrations or clearing user data.
- Authenticated account A cannot read/modify B's plans, answers, keys or level. Anonymous users cannot invoke protected RPCs. Fake JWT/role/feature state does not grant authority.
- Question version, item type, skill, timed contract and component remain stable for each existing session; no duplicate submit/finalize on retries; no answer confirmation before durable commit.
- Written external solution and companion MCQ do not silently award mastery, marks or readiness. P1 and P5 academic evidence never mix.
- Withheld diagnostic/retest/mixed reserve is selected only through the approved governed flow and must not be exposed as ordinary learning content.
- Test output must never include production secrets, user PII, or correct answers to unreleased protected content.

## Working ledger (UPDATE THIS FILE after each stage)

| Stage | State | Exact SHA / PR / workflow evidence | Findings / next action |
| --- | --- | --- | --- |
| A: trace & gap | **COMPLETE** | PR #451; 61/61 production read-only RPC permission audit; GitHub Actions run 41321004984 GREEN; `docs/math-p1p5-e2e-stage-a-source-server-trace-20261101.md` | Client/UI/source and authoritative DB route matrix saved. Remaining genuine Auth/HTTP→PostgreSQL integration isolated under Stage B. |
| B: real-stack isolated E2E | NOT STARTED | — | Supply disposable Auth/API/DB, synthetic learner and actual P1/P5 click path |
| C: model/fault/locale/coverage | NOT STARTED | — | Extend 15+18 profiles, validate 1,448 structural mappings; no fake grading |
| D: integrated gate + release report | NOT STARTED | — | Orchestrate reproducible CI; preserve distinct real-world governance decision |

**Completed prerequisites, do not redo without new defect:** math source second pass 1,448/1,448; source publication; P2-62..P2-80 engineering campaign; existing 30 isolated browser cases; 180 companion MCQ validation.

**Current blocker to automatic mass release (not a bank publication blocker):** real four weekly reviews missing; QA-open global overrides need safe reconciliation; no licensed human sign-off invented.

## Continuation instruction for a NEW ChatGPT conversation

> **Продолжай iClub APP — цифровой E2E-полигон Mathematics P1/P5. Прочитай на GitHub `jteshaboev1984-ops/iClub_APP`, ветка `main`, файл `docs/math-p1p5-integrated-e2e-release-roadmap-v1.md`, затем связанные документы. Проверь текущие статусы/CI, не повторяй завершённые проверки, продолжай с первого незавершённого этапа. Все изменения через защищённую ветку и проверки, production Supabase только read-only; прогресс пользователей и исторические записи не менять. После каждого крупного этапа обнови ledger в roadmap с точными ссылками на PR, коммит и CI. Если обнаружишь ошибки — исправляй их с повторным тестом; не ограничивайся отчётами. Массовый релиз не включай без отдельного решения владельца и действующих серверных шлюзов.**

## Stage A execution evidence — 2026-11-01

- **Production READ-ONLY:** literal 61-function source inventory generated from the 3 real client adapters; exact replay of `scripts/fixtures/exam-prep-math-p1p5-61-rpc-live-readonly.sql` returned `expected_client_rpcs=61`, `passed_exact_public_auth_only=61`, `missing_or_ambiguous=0`, `authenticated_missing=0`, `anonymous_leak=0`, `failed_function_names=[]`. No student data or session rows accessed by the fixture.
- **GitHub CI GREEN:** `Mathematics P1/P5 Source to RPC Trace Guard`, exact PR run ID `41321004984`, job ID `124891011085`, conclusion `success`, includes syntax and real-repo route invariant checks.
- **Actual work:** PR [#451](https://github.com/jteshaboev1984-ops/iClub_APP/pull/451) adds a zero-network Node client-RPC boundary guard, SELECT-only live function inventory, detailed 15-route UI→RPC→private storage trace matrix and source-level CI workflow. No app runtime code or migration altered.
- **Gap discovered, prioritized:** legacy PostgreSQL simulation and mocked Chromium are well-covered *separately*, but a single actual authorized HTTP/PostgREST→RPC→isolated DB→UI roundtrip for both P1 and P5 remains **UNPROVEN**. Generic Written Core browser fixture is Economics P2; Math-specific written E2E needs authentic server path. Do not claim Stage B passed.
- **No real release action:** all production flags/entitlements/sessions/Practice/Tours/certificates untouched. Existing mass-release `NO_GO` remains separate.

## Change log

- **2026-11-01 / v1.1:** Stage A finished with 61/61 real schema/auth-grant audit + source trace CI GREEN; gap matrix and Stage B scope documented; no changes to production users.
- **2026-11-01 / v1.0:** Created durable integrated E2E release roadmap at owner request. All four new stages NOT STARTED; historical completed work preserved and referenced. No code, config, learner or release-state modifications authorized by this documentation.
