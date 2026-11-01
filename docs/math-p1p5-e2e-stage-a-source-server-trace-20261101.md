# iClub Mathematics 9709 P1/P5 — Stage A Source/Server Trace and E2E Gap Matrix

**Date:** 2026-11-01  
**Scope:** first substantial stage of `docs/math-p1p5-integrated-e2e-release-roadmap-v1.md`.  
**Evidence class:** actual main-branch source inspection + **production read-only** `pg_proc` inventory, joined to existing isolated PostgreSQL/browser tests. **Not** a claim of completed authenticated E2E, browser coverage for every task, or release approval.

## Exam Prep real call graph — current actual files

```text
index.html: learner subject hub + #exam-prep-host-root
   ↓ (cached versioned assets)
exam-prep/exam-prep-host.js: open({subjectKey, language}), fail closed on subject mismatch
   ↓
exam-prep/exam-prep-api.js: public API facade, window.sb.rpc(name, payload)
   ↙                         ↓                          ↘
exam-prep/exam-prep-live.js  exam-prep-weekly-flow-adapter.js  exam-prep-progress-ux-api.js
   ↓                        ↓                                 ↓
       authenticated Supabase PostgREST RPC / public.*_safe_v1-v3
           ↓ auth.uid() / owner/capability/feature checks
       private.exam_prep_* authoritative functions and tables
           ↓
       response / permission failure / retry reconciliation
           ↓
       learner UI, resume, weekly progress
```

No browser-side `.from(...)` direct table fetch exists in the **three audited Math Exam Prep RPC adapters**. Other unrelated app sources are outside this narrow assertion. All wrappers fail when `window.sb.rpc` is unavailable. The weekly adapter explicitly rejects invalid P1/P5 components and lacks Core permission, and refuses to treat lost ACK as confirmed start.

The generic Written Core standalone widget `exam-prep/runtime/written-core-controller-v1.js` is a **shared other-subject component**. The previous 30 browser cases use an Economics P2 synthetic example. Actual Math P1/P5 written handling must be checked through `exam-prep-live.js` + Math-specific public RPCs; do not claim the generic widget fixture proves that path.

## Read-only live DB ↔ actual source compatibility checkpoint

Extracted RPC names from `exam-prep-api.js`, `exam-prep-weekly-flow-adapter.js` and `exam-prep-progress-ux-api.js`:

- Main API exposes **53** statically named RPCs.
- Weekly adapter and Progress UX add **8** unique RPC names, total **61**.
- Production `pg_proc` exact-name lookup: **61/61 present in public schema** (one public signature each at snapshot).
- **61/61** have `authenticated EXECUTE`; **0/61** have `anon EXECUTE`.
- This verifies **endpoint existence and grants**, **not** correct behavior, effective user-specific access, authorized PostgREST JSON payloads, or role/RLS proof under actual JWT.
- Reusable executable code regression: `scripts/exam-prep-math-p1p5-source-rpc-trace.cjs`; read-only live SQL: `scripts/fixtures/exam-prep-math-p1p5-61-rpc-live-readonly.sql`. The source regression runs on matching frontend PRs and manual dispatch, and fails if source RPC contract drifts.

## Authoritative feature-path traceability matrix

The main UI file `exam-prep/exam-prep-live.js` binds the routines listed below to the public API facade. "Production read-only" means the relevant definition and permissions were examined, not that an authorized learner action was sent.

| Learner behavior / source seam | Actual client/public RPC chain | Private authoritative dependency (examples from current production `pg_get_functiondef`) | Invariant / required remaining E2E |
| --- | --- | --- | --- |
| Open Math subject | `index.html` → `exam-prep-host.js` → `capabilities` / `get_exam_prep_capabilities_v1` | `exam_prep_feature_config`, `exam_prep_feature_entitlements`, `users` | Reject wrong subject/unregistered/unauthorized users; do not infer access from front-end flag |
| Save exam profile | `saveExamProfile` / `save_exam_prep_exam_profile_v2` | server owned profile and governed plan rebasing | Same account, P1/P5 independent, no silent academic reset |
| Start diagnostic P1/P5 | `startNextDiagnostic` / `start_exam_prep_next_diagnostic_safe_v1` | `exam_prep_component_placements`, `exam_prep_session_authorizations`, `exam_prep_sessions`, approved assessments | Unique issued session; idempotency; approved source; no cross-paper leak |
| Fetch question/session | `getSession` / `get_exam_prep_session_safe_v1` | `exam_prep_session_items`, `exam_prep_responses`, `questions`, frozen MCQ option ordering | Owner scoped; frozen version; no pre-answer answer-key/correctness exposure |
| Answer/write evidence | `submitResponse` / `submit_exam_prep_response_safe_v1` | `exam_prep_eval_session_question_v1`, `exam_prep_safe_response_payload_v1`, `exam_prep_evidence_events`, `exam_prep_responses` | Server grading only; one durable response; bogus mastery/score rejected; no credit on unknown ACK |
| Finalize and review | `finalizeSession`, `sessionReview` / `finalize_exam_prep_session_safe_v1`, `get_exam_prep_session_review_safe_v1` | `exam_prep_sessions`, `exam_prep_responses` | No double finalization; review only when authorized; protected key timing |
| Written paper learning | `getSessionWritten`, `writtenCriteria`, `advanceWrittenStep`, `finalizeSessionWritten` | `exam_prep_written_tasks`, `exam_prep_written_criteria_locale_v1`, `exam_prep_written_step_advances_v1` | Criteria optional; Next is plan step only, not verified correct/mastery |
| Weekly plan (legacy facade) | `weeklyPlan`, `generateWeeklyPlan`, `authorizePlanItem` → `get_exam_prep_weekly_plan_safe_v2`, `generate_exam_prep_weekly_plan_safe_v3`, `authorize_exam_prep_plan_item_safe_v1` | `exam_prep_weekly_plans`, `exam_prep_weekly_plan_items` and canonical Core entitlement | Correct learner/week/goal, independent P1/P5 and atomic plan revisions |
| Weekly safe cutover | `exam-prep-weekly-flow-adapter.js`: `ensure_exam_prep_balanced_weekly_plan_safe_v1`, `authorize_exam_prep_goal_once_safe_v1`, `start_exam_prep_plan_session_once_safe_v1`, `start_exam_prep_learning_review_safe_v1` | `exam_prep_weekly_plans`, `exam_prep_session_authorizations`, `exam_prep_sessions`, `exam_prep_learning_review_starts_v1` | No fake second fresh pack; replay after lost ACK; no duplicate goal or changed authorization identity |
| Correction / delayed retest | `correctionQueue`, `authorizePlanItem`; plan item may be `retest`; server also implements `authorize_exam_prep_retest_safe_v1` | `exam_prep_correction_cases`, `exam_prep_retest_events`, `exam_prep_session_authorizations` | Cannot issue before due; fresh item distinct from learning; completed retest changes only warranted evidence |
| Mixed transfer | published `mixed` assessment and governed plan item through `authorizePlanItem`/start session | `exam_prep_assessments`, `exam_prep_assessment_items`, component/skill constraints | Same-paper, distinct reserve role, no false written mastery |
| Timed practice / full paper | `timedCatalog`, `authorizeTimed`, `startSession`, `finalizeTimed`, `timedResult` | `exam_prep_timed_assessment_contracts`, `exam_prep_timed_assessment_items`, `exam_prep_timed_attempt_results` | Server-owned deadline, valid score comparability and finalization, no client-forged time |
| Timed written self-mark | `submitTimedSelfMark` / `submit_exam_prep_timed_written_self_mark_safe_v1` | `exam_prep_timed_written_self_marks` | Learner self-mark clearly identified, never examiner or machine authority |
| Recovery and interruptions | `recovery`, `recordInterruption`, `authorizeRevalidationItem` | `exam_prep_recovery_cases` and approved revalidation ledger | Same account and exact frozen evidence; resume old session without losing history |
| Readiness and outcomes | `readinessSummary`, `stage4Consolidation`, `finalCalibration` | `exam_prep_skill_states`, `exam_prep_stage_states`, timed/diagnostic evidence | No readiness from unverified written work, synthetic time, or cross-P1/P5 data |
| Progress read model | `exam-prep-progress-ux-api.js` / `get_exam_prep_weekly_progress_safe_v1` | `exam_prep_weekly_goal_snapshots`, `exam_prep_weekly_plans`, `exam_prep_retest_events`, `exam_prep_skill_states` | Snapshot represents authoritative state; missing plan is not silently fabricated |

**Interpretation:** the above is a logical route inventory, not every RPC's exhaustive dependencies. Source-of-truth function definitions are in live `pg_proc` and versioned `supabase/migrations`; check the latest installed version rather than trusting an early migration's original body.

## Existing evidence classes (no false equivalence)

| Test / source | Real runtime parts | What it does NOT establish |
| --- | --- | --- |
| New source trace test + read-only permission SQL | Real checked-in client sources + actual production PostgreSQL function catalog (SQL run separately) | Does not create authenticated JWT requests or execute Exam Prep action |
| `.github/workflows/p2-73-core-engineering-dress-rehearsal.yml` | Disposable PostgreSQL 17, versioned migrations, 3 deterministic seeds, CI JS browser | Browser can still substitute `window.sb.rpc`; not proof of single real HTTP flow |
| `supabase/tests/p2_69_full_stage0_6_core_simulation.sql` | Real database functions using isolated synthetic evidence | Not actual browser login/UX, real student, or production time |
| `supabase/tests/p2_67_canonical_scenario_matrix_v2.sql` | 15 canonical profiles + 18 adversarial variants | Models, not production pupils or consent |
| `scripts/weekly-flow-native-browser-journey.cjs`, `.github/scripts/p2_55_full_learner_journey_regression.js` | Real UI renderer in Chromium | Inject synthetic `window.sb.rpc` or equivalent fake client |
| `scripts/exam-prep-written-beta-isolated-browser-acceptance.cjs` | Shared Written Core controller/view, 30 RU/UZ/EN phone/desktop cases | Fixture depicts Economics P2; does not run Math P1/P5 authenticated actual DB |
| `scripts/exam-prep-timed-answer-ack-browser.cjs` | Math live UI timed/paper failure/retry path | Synthetic RPC/fixture, not actual authenticated timed database write |
| `supabase/tests/p2_79_recovery_rollback_disaster_matrix.sql` | Isolated rollback/replay failure campaign | Not real network, Telegram, or live 72h monitoring |
| Published 1,448 academic content checkpoint | Actual versioned content with independent AI-assisted review | Not a new full-stack Math E2E nor independent human certification |

## Gap priority and Stage B exact acceptance

**P0 integration gap:**
- Build a disposable, compatible local Auth/PostgREST stack driving the actual SQL schema on ephemeral PostgreSQL 17. A *mocked* `window.sb.rpc` or direct `psql` cannot be relabeled "authenticated full-stack E2E".
- Provide synthetic `auth.users`/app `users` and all necessary roles/claims *only* inside disposable environment with zero secret/production URL ingress.
- Configure an isolated client browser `window.sb` to speak HTTP to that local API and insist on actual auth.uid()/EXECUTE/row ownership. Validate one complete P1 and one complete P5 branch before expanding into faults.
- Record exact browser request trace and database state after: profile → diagnostic → answer/finalize → learning plan → learning/written step → correction → due retest → mixed → timed/full paper → logout/restart/resume. Respect evidence requirements; don't force change of stage.
- Prove correctness via **separate** expected-state oracle, not echoing a mocked RPC. No grants to `anon` for protected functions.
- Check that P1/P5 host current versioned asset loading, locale, Telegram wrapping and completed session history remain compatible.

**P1 secondary gaps:**
- True controlled server clock for due retest/time limits and expiry, with time-zone edge cases (CI only).
- Distinct actual Math P1/P5 written criteria/Next path, rather than shared Economics P2 fixture.
- Automated static 1,448/1,448 routing check against frozen per-version metadata, separate from already closed mathematical second pass.
- Full browser artifact with localized screenshots and redacted trace on error; audit unauthorized requests in two simulated users and separate P1/P5.
- Explicit sample of real consented Telegram client remains a separate acceptance step, not synthetic.

**Live-data caveat:** we observed **61/61** RPC existence/auth-only grants in production, but existing global `qa_open_all_core=true` and `qa_open_all_weekly=true` mean current access is broader than the official small beta. Neither flag may be changed just to make a synthetic test pass. Mass rollout governance is separately `NO_GO` due to missing four real weekly reviews, irrespective of content publication.

## Stage A decision

**SOURCE + SERVER CATALOG TRACE VERIFIED; single authenticated end-to-end path still UNPROVEN.** This is not a defect announcement and does not unblock mass rollout. At the first integrated Stage B PR, prioritize the true HTTP/Auth/database path, not more mocked UI cases.

## Trace verification / audit command

- `node scripts/exam-prep-math-p1p5-source-rpc-trace.cjs` — validates 61 source RPCs, client source wiring, host bootstrap and noncredit/retry guards using built-in Node libraries, no network.
- In production Supabase SQL editor or read-only connector only: run `scripts/fixtures/exam-prep-math-p1p5-61-rpc-live-readonly.sql`. Expected **61 / 61** exactly one public function with authenticated but no anon execute, missing/ambiguous=0. Does not touch any learner data.
- Review current GitHub Actions CI run on exact stage-A PR SHA; do not regard this as Stage B pass.

**Update note:** Stage A will be marked complete in canonical roadmap only after the above source regression CI is GREEN and the live SQL fixture rechecks GREEN, with recorded exact PR/SHA.
