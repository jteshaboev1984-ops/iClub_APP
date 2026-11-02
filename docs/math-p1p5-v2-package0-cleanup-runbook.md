# iClub Math P1/P5 v2 — Package 0 controlled prelaunch test-data cleanup design

**Issue #450 | draft PR #468 | 2026-11-02. THIS IS NOT AN EXECUTABLE DELETE RUNBOOK AND NOT GO.**

## Purpose and decision boundary

Architect has approved *at final release* a **one-time reset of all prelaunch Mathematics Exam Prep learner academic/test progress, including beta participants**. This does NOT authorize deleting accounts, Practice after its already-published v2 bank switch, Tours, certificates, other subjects, program content, AI entitlements or historical consent/audit records without separate retention decision. Earlier owner-approved Mathematics Practice reset was applied at its own October 2026 publish and must **never** be re-run as part of Math Exam Prep cutover.

**Source evidence:** [v2 plan](math-p1p5-release-workplan-v2-20261102.md), [governance delta](math-p1p5-v2-governance-addendum-20261102.md), [ledger](math-p1p5-v2-execution-ledger.md), [read-only executable report](../supabase/tests/p1p5_v2_package0_cleanup_scope_report_readonly.sql), [disposable PG17 rehearsal](../supabase/tests/p1p5_v2_package0_cleanup_isolated_fk_rehearsal.sql).

## Verified snapshot (not permanent totals)

Production SELECT-only 2026-11-02: 32 proposed Math Exam Prep learner-state tables, 19,794 rows; 38 inbound foreign keys to candidate state, one potential retained Mentor child; 548 authorizations linked to 548 sessions in BOTH directions through RESTRICT FKs. Even a temporary table-wide DELETE in any order cannot be deemed safe without full incoming FK analysis. 122 total private tables named exam_prep_*, many are content/policy/governance and **are not learner progress**.

**Release sample protected baseline:** 1,476 public.users, 881 Math subject enrollments, 149 Math Tours attempts, 2,477 Math Tour answers, 66 Mathematics certificates, 15 Math Practice v4 sessions, 14 Practice v4 drills, 13 Math Practice attempts, 496 other subject Practice attempts, 3 active AI grants, 3 beta consent records, 14,748 audit events; published math bank = numeric generation 2, release key math_p1_practice_v2_2026_10_07. Other subject Exam Prep data includes active controlled Economics beta and MUST be isolated.

## Provisional 32-table learner-reset scope — verification still required

Groups:
- **Identity-bound academic profile/state:** exam_prep_exam_profiles, exam_prep_exam_map_revisions, exam_prep_exam_appointments, exam_prep_exam_ops_confirmations, exam_prep_component_placements, exam_prep_component_access_gates, exam_prep_prerequisite_states, exam_prep_skill_states, exam_prep_stage_states.
- **Sessions and evidence:** exam_prep_session_authorizations, exam_prep_sessions, exam_prep_session_items, exam_prep_responses, exam_prep_evidence_events, exam_prep_integrity_events, exam_prep_legacy_evidence_references.
- **Corrections/retest/recovery:** exam_prep_correction_cases, exam_prep_correction_actions, exam_prep_retest_events, exam_prep_recovery_cases, exam_prep_progress_revalidation_cases, exam_prep_progress_revalidation_items, exam_prep_human_review_recommendations.
- **Planning/weekly flows:** exam_prep_weekly_plans, exam_prep_weekly_plan_items, exam_prep_weekly_goal_snapshots, exam_prep_weekly_flow_enrollment_v1, exam_prep_learning_review_starts_v1.
- **Written/timed traces:** exam_prep_written_session_check_snapshots, exam_prep_written_step_advances_v1, exam_prep_timed_attempt_results, exam_prep_timed_written_self_marks.

**Do not convert this provisional classification into DELETE SQL yet.** Each target needs final program_id/user ownership, cross-subject/AI check, current FK graph, any new migration columns, idempotent repeatability, exact row counts, and encrypted per-table backup before GO.

## Exception/retention register (requires decision before final GO)

| Data family | Prelaunch decision |
|---|---|
| public.users/auth.users, user_subjects | **Keep** — real registered accounts |
| Tour, Tour answers/certificates, school data | **Keep** — production history |
| Practice published v2 (numeric gen=2), browser practice_history_v3 namespace, current session/drill history | **Keep** — existing published bank; never re-run Mathematics Practice reset |
| Economics/Chemistry/Bio/CS Exam Prep and Olympiad content | **Keep** — own future controlled releases |
| Mathematics syllabus, approved source/question bank, 334 written tasks, assessments, QA review/skill contracts, mapping, versioned release policy | **Keep** |
| AI entitlements for three beta users and AI policy | **Keep** until future tariff AI separate rollout, preserve ownership and bill/audit gates |
| Beta membership and consents | **Hold**, preserve for now; decide if beta enrollment closes at final GO while independent AI consent is maintained |
| Staff roles, safeguarding events, mentor assignments, mentor reviews | **Hold** — not ordinary learner progress; legal/operational policy |
| 14,748 audit rows (actor/target IDs, before/after JSON) | **Hold** — separate audit retention/privacy policy; not safe to auto-delete or recreate as imaginary real reviews |
| Exam Prep synthetic scenario catalogs, synthetic clocks, historical validation records | **Keep** — engineering test/governance, clean active synthetic runs by their own already-governed APIs |
| Cache/render-only data | **Hold until exact source map** — avoid localStorage.clear and preserve user authentication keys |

## SQL/dependency risks discovered

**New verified DAG proof (2026-11-02):** [dynamic SELECT-only structural proof](../supabase/tests/p1p5_v2_package0_fk_graph_readonly.sql) returned GRAPH_PRECHECK_PASS_NO_DELETE_AUTHORIZED against actual production: 32 nodes, 37 internal FKs and zero cycles **only after two** nullable authorization links are conceptually excluded. This analysis changed no data. Read-only ownership check across all 28 direct-user scope tables found zero rows owned by accounts without a Mathematics subject selection.

1. exam_prep_session_authorizations.consumed_session_id -> exam_prep_sessions.id is nullable but RESTRICT / NOT DEFERRABLE.
2. exam_prep_session_authorizations.correction_case_id -> exam_prep_correction_cases.id is ALSO nullable and RESTRICT / NOT DEFERRABLE. It creates a SECOND cycle via correction_cases -> evidence_events -> responses -> session_items -> sessions -> authorizations. **Both** nullable authorization links require review and explicit transactional handling before any cleanup.
3. exam_prep_sessions.authorization_id -> exam_prep_session_authorizations.id is NOT NULL and RESTRICT / NOT DEFERRABLE.
4. exam_prep_mentor_queue_items.recommendation_id -> exam_prep_human_review_recommendations.id is a **retained table referencing a proposed reset table**; currently zero non-NULL references. Must stop if it becomes populated.
5. Session items, responses, integrity events, evidence events, correction actions, retest events, learning review starts, weekly goal snapshots have multiple RESTRICT back-links. A single "DELETE sessions" would fail; do not remove FK constraints to force deletion.
6. Audit JSON and local browser keys are NOT fully represented by FK analysis; must be separately inspected for stale beta state before public access.
7. Numeric snapshot counts can change while app remains live; MUST re-run preflight at exact release boundary under safe writes blockade.

## Immutable-evidence permission boundary (new confirmed blocker)

Production function `private.exam_prep_block_immutable_mutation_v1()` intentionally rejects UPDATE/DELETE of objective responses, immutable evidence, correction actions, integrity events, learning review starts and timed result rows. Only a special transaction-local **synthetic cleanup** GUC `iclub.exam_prep_synthetic_cleanup=on` allows DELETE. The current authorized `public.cleanup_exam_prep_beta_synthetic_progress_v1/v2` cleanup depends on this GUC but **also requires** synthetic-present development state, no real-review epoch, AI off, kill switch on, no active beta sessions. The live production state is `real_monitoring` with an established epoch, QA Core open and AI beta enabled, so **these old synthetic cleanup procedures are NOT valid for the future prelaunch real-beta reset**.

The disposable full 32-table rehearsal deliberately verifies that immutable rows reject deletion *without* this GUC, then uses the existing GUC only with guarded synthetic local accounts and entirely rolled-back transactions. This is permitted synthetic test behavior, **not** authority to set the same GUC on production for real students.

**Release requirement:** design and review a NEW narrowly authorized, versioned one-shot prelaunch-cleanup service with strict architect-approved release epoch, locked write intake, independently verified backup/restore, user/program allowlist, concurrent transaction isolation, full integrity checks, auditable before/after row manifest and no exposed public SQL bypass. Preserve immutable protections during ordinary usage; only explicitly governed release cleanup may erase old test facts. Do not disable triggers or globally grant cleanup permissions.

## Required isolated full-schema acceptance (PARTIALLY completed)

An **actual current-migrations PG17 regression** now passes on two fake P1/P5 accounts: [full-schema FK cycle and SAVEPOINT test](../supabase/tests/p1p5_v2_package0_full_schema_fk_rollback.sql) through [real HTTP/Chromium GitHub Actions run 41499740468](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/41499740468), all job steps GREEN. This confirms one actual session/authorization FK pair under real schema constraints, not a complete 32-table deletion or backup restore. The separate simplified PG17 model now additionally verifies the correction/evidence cycle after a *second* nullable unlink ([run 41499740447](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/41499740447), GREEN).

1. Apply actual current migration stack in disposable PostgreSQL 17 using existing project replay procedure (cf. .github/workflows/exam-prep-p1p5-isolated-http-e2e.yml); create a proper governed fake Math learner, plus a fake other-user and protected fake Tour/Practice/certificate records.
2. Rehearse deterministic **scoped and reversible** cleanup against all actual 32 learner tables and both branches of every FK. Use SAVEPOINT/ROLLBACK; verify retained Mentor queue cannot reference deletable content.
3. Verify pre/post per-table counts and academic state of other users and subjects, source content counts, protected Tours/Practice/cert fingerprints, active AI grants and consent history unchanged.
4. Test interrupted cleanup (transaction rollback), duplicate execution (idempotency), late existing browser tokens and epoch/cache reset. An already-open beta tab must not reinsert stale academic progress or overwrite post-launch data.
5. Refuse run if new incoming FK, missing backup, policy ambiguity, unexpected user ownership, question-bank content variation, mismatched count or unauthorized subject appears.

## Future release-time procedure, NOT authorized now

**G0:** Receive explicit architect release GO. Check new *versioned* accelerated public-core gate, exact release SHA and all required tests. Decide the beta-consent/audit retention scope.

**G1:** Temporarily prevent new Mathematics Exam Prep writes through a dedicated governed maintenance mode (not app-wide kill switch); let existing non-Math subjects/Tours/Practice continue. Verify no in-flight math request or protected assessment. A new client that still carries old beta credentials must fail closed against old epoch.

**G2:** Take an encrypted, access-limited, recoverable snapshot of ONLY affected Math Exam Prep rows and their parents/children (plus minimal FK identifiers for restore) using approved backup facilities. Verify byte counts/checksums in a secure storage outside GitHub, validate restore to an isolated database. Never upload real answers or personal data into CI or GitHub.

**G3:** Execute final owner-scoped read-only exact tables/rows/FK/protected-invariant report. Compare to the backup manifest. Stop on any unknown table, new FK or retained Mentor reference.

**G4:** In one reviewed and authorized database transaction: assert rollout still locked; detach only nullable FK links that connect prelaunch targeted objects; delete all protected child/dependent rows in verified topological order; delete targeted sessions/authorizations; never disable constraints or reset public users/Practice/Tours. Verify all intended Math learner-state rows cleared and protected states byte-equivalent. On error ROLLBACK.

**G5:** Publish controlled public Math Core code and *versioned* access gate (not blind controlled_beta -> mass string), preserve three AI beta grants, set initial learner epoch so returning accounts start a fresh Math Exam Prep diagnostic, no old local beta state resurrection. Economics/Chemistry etc show development for public launch, old beta records preserved.

**G6:** Short real hosted auth/mobile smoke after isolated E2E, then controlled public opening. Check new data insertion and regression (P1/P5 independent, exam dates, schedule choices, no written marks, Extra Hard). No fabricated four human weekly reviews or 72-hour fake pass.

**Rollback after new users begin learning:** do not restore an old beta snapshot over any newer genuine learning record. First roll back feature code/gate safely; restoring prelaunch beta data needs a special collision-free reconciliation plan, not generic DB PITR overwriting the active site.

## Minimal current proof

Production real schema: read-only 32-table, 19,794-row scope report and two-FK-cut DAG PASS; no data changes. Synthetic PG17 [41499740447](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/41499740447) GREEN on both cycles, retained Mentor blocker, idempotent delete and rollback. Actual current-migrations P1/P5 isolated HTTP/Chromium [41499740468](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/41499740468) GREEN including full-schema session/authorization FK rollback and all existing integrated tests. All **32-table cleanup**, user-epoch replay and encrypted backup/restore remain outstanding; release remains NO_GO.

[GitHub Actions #41498044157](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/41498044157) GREEN on a simplified two-learner PostgreSQL 17 model with real RESTRICT cycle and retained Mentor blocker, idempotent scoped delete and rollback. This test **does not** prove all 122-table production migrations. Actual production SELECT-only scope report completed with 19,794 candidate rows. Public release remains **NO_GO**.

## Exact next engineer action

Work on the **remaining actual 32-table deletion/restore drill** using PG17 and current migrations; both cycles now mapped and tested at two levels. Inspect newest main SHA and compare PR #468 branch; do not rewrite already-green diagnostic/HTTP/600x10 CI. After full rehearsal, update docs/math-p1p5-v2-execution-ledger.md and GitHub Issue #450.
