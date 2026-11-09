# Mathematics P1/P5 — factual 41-migration reconciliation (2026-11-09)

This **read-only source/history reconciliation** covers the exact diff between public `main` `29667084fe25c8c3fbb8a7df3909876ef53d6af7` and unmerged integration candidate `6cb125731dd5fecfb354ddd8f91073629183198f` (#516). It is NOT a database migration execution plan by itself.

## Ground truth

- Existing iClub Supabase uses PostgreSQL **17.6**. The live database records **792 migrations**; among those, the only 2026-11 records are `20261109040824 exam_prep_extra_hard_optional_noncredit_v1_20261109`; `20261109040842 exam_prep_extra_hard_bank_pointer_original_v2_20261109`; `20261109073034 exam_prep_extra_hard_catalog_topic_progress_v1_20261109`. None of the 41 draft filenames below appears as a same-named applied migration. **Absence from history does not prove SQL functions are absent** (manual deployment or separately named releases may exist).
- **Extra Hard V4.3 already live**: 42 published protected tasks, 24 P1/18 P5; release bank pointer `math-extra-hard-2026-11-full-v4` enabled; immutable 42-task content fingerprint `17dcea35cb50de348f62394d49be1f64`. **Do not replay old Extra Hard migrations** because their catalog, bank-pointer and data model overlap the separately deployed Nov 9 implementation. Never re-import/edit these 42 rows.
- **Confirmed production D03 gap:** `public.submit_exam_prep_timed_written_self_mark_safe_v1` is callable by `authenticated`; live JS advertises self-mark controls. The existing unmerged `20261104110000` migration disables this direct RPC and redefines the objective-only result contract; it requires source-dependent review before applying.
- **Confirmed P4/P6 gaps:** private execution comparator and stage5 operational completion helpers missing; `public_math_core_enabled` absent. The 20261105 stage and public-membership migrations have NOT been activated. Do not use original Core beta flags as a workaround.
- DRAFT #492 is 231 commits/162 changed files, DRAFT #516 stacked source is **344 commits/225 changed files, diverged by the already published #517 main change**. Merge neither as-is.

## Draft migration map — 41 source files, not 41 automatic live actions

The status category is a **workstream assignment**, not a claimed functional test. Before deciding to apply, compare full function definitions, grants, RLS and dependent objects in the CURRENT database. Build a deterministic subset on fresh PG17 and promote only with signed owner-controlled migration GO.

| # | Draft migration file | Initial disposition |
|---:|---|---|
| 1 | `20261103023000_exam_prep_p1p5_personal_horizon_v1.sql` | P1 PROFILE/TIMELINE — pending |
| 2 | `20261103024000_exam_prep_p1p5_study_schedule_v1.sql` | P1 PROFILE/TIMELINE — pending |
| 3 | `20261103025000_exam_prep_p1p5_periodic_study_reports_v1.sql` | P3 WEEKLY — pending |
| 4 | `20261103030000_exam_prep_p1p5_workload_norm_registry_v1.sql` | P2 SOURCE/TIME — pending |
| 5 | `20261103031000_exam_prep_p1p5_historical_topic_teaching_references_v1.sql` | INTEGRATION — inspect dependencies before port |
| 6 | `20261103032000_exam_prep_p1p5_workload_review_projection_v1.sql` | P2 SOURCE/TIME — pending |
| 7 | `20261103033000_exam_prep_p1p5_workload_academic_review_queue_v1.sql` | P2 SOURCE/TIME — pending |
| 8 | `20261103034000_exam_prep_p1p5_real_content_calibration_inventory_v1.sql` | P2 SOURCE/TIME — pending |
| 9 | `20261103035000_exam_prep_p1p5_shared_study_capacity_v1.sql` | P2 SOURCE/TIME — pending |
| 10 | `20261103036000_exam_prep_p1p5_remaining_work_from_evidence_v1.sql` | INTEGRATION — inspect dependencies before port |
| 11 | `20261103037000_exam_prep_p1p5_action_time_norm_registry_v1.sql` | P2 SOURCE/TIME — pending |
| 12 | `20261103038000_exam_prep_p1p5_action_calibration_candidates_v1.sql` | P2 SOURCE/TIME — pending |
| 13 | `20261103039000_exam_prep_p1p5_conditional_learning_trajectory_v1.sql` | INTEGRATION — inspect dependencies before port |
| 14 | `20261103040000_exam_prep_simple_learning_timeline_v1.sql` | INTEGRATION — inspect dependencies before port |
| 15 | `20261103041000_exam_prep_simple_cambridge_source_time_estimate_v1.sql` | P2 SOURCE/TIME — pending |
| 16 | `20261103042000_exam_prep_learner_chosen_dates_v1.sql` | P1 PROFILE/TIMELINE — pending |
| 17 | `20261103043000_exam_prep_student_accept_weekly_study_target_v1.sql` | P3 WEEKLY — pending |
| 18 | `20261104080000_exam_prep_stage_c_timed_session_clock_restore_v1.sql` | INTEGRATION — inspect dependencies before port |
| 19 | `20261104110000_exam_prep_p1p5_disable_written_self_marks_v1.sql` | D03 BLOCKER (staged, not applied) |
| 20 | `20261104120000_exam_prep_p1p5_extra_hard_optional_noncredit_v1.sql` | ALREADY-LIVE-OVERLAP (compare definitions; DO NOT REPLAY) |
| 21 | `20261104121000_exam_prep_p1p5_keep_weekly_time_decision_v1.sql` | P3 WEEKLY — pending |
| 22 | `20261104122000_exam_prep_p1p5_shared_weekly_time_snapshot_v1.sql` | P3 WEEKLY — pending |
| 23 | `20261104123000_exam_prep_p1p5_diagnostic_period_readonly_v1.sql` | P3 WEEKLY — pending |
| 24 | `20261104124000_exam_prep_p1p5_first_diagnostic_t0_immutable_v1.sql` | P1 PROFILE/TIMELINE — pending |
| 25 | `20261104125000_exam_prep_p1p5_horizon_consistent_frozen_t0_v1.sql` | P1 PROFILE/TIMELINE — pending |
| 26 | `20261104130000_exam_prep_p1p5_legacy_planner_diagnostic_display_bridge_v1.sql` | INTEGRATION — inspect dependencies before port |
| 27 | `20261104131000_exam_prep_p1p5_evidence_led_weekly_focus_v1.sql` | P3 WEEKLY — pending |
| 28 | `20261105070000_exam_prep_p1p5_true_diagnostic_timeline_and_future_dates_v1.sql` | P1 PROFILE/TIMELINE — pending |
| 29 | `20261105081000_exam_prep_p1p5_weekly_pace_precision_v1.sql` | P3 WEEKLY — pending |
| 30 | `20261105090000_exam_prep_p1p5_four_syllabus_scope_corrections_v1.sql` | INTEGRATION — inspect dependencies before port |
| 31 | `20261105095000_exam_prep_p1_paper1_integration_scope_completion_v1.sql` | INTEGRATION — inspect dependencies before port |
| 32 | `20261105112000_exam_prep_p1p5_fresh_retest_math_prompt_priority_v1.sql` | INTEGRATION — inspect dependencies before port |
| 33 | `20261105153000_exam_prep_p1p5_timed_execution_comparable_v1.sql` | P4 PAPER — stage after D03 |
| 34 | `20261105154000_exam_prep_p1p5_stage3_stage4_execution_evidence_v1.sql` | P4 PAPER — stage after D03 |
| 35 | `20261105155000_exam_prep_p1p5_stage5_operational_calibration_v1.sql` | P4 PAPER — stage after D03 |
| 36 | `20261105160000_exam_prep_p1p5_timed_finalization_state_sync_v1.sql` | P4 PAPER — stage after D03 |
| 37 | `20261105161000_exam_prep_p1p5_ignore_whitespace_only_written_execution_v1.sql` | P4 PAPER — stage after D03 |
| 38 | `20261105170000_exam_prep_math_public_core_membership_default_off_v1.sql` | P6 MASS ACCESS — OFF until separate GO |
| 39 | `20261106103000_exam_prep_p1p5_diagnostic_prompt_novelty_v1.sql` | INTEGRATION — inspect dependencies before port |
| 40 | `20261106140000_exam_prep_extra_hard_new_12_bank_version_v2.sql` | ALREADY-LIVE-OVERLAP (compare definitions; DO NOT REPLAY) |
| 41 | `20261106173000_exam_prep_extra_hard_catalog_topic_progress_v1.sql` | ALREADY-LIVE-OVERLAP (compare definitions; DO NOT REPLAY) |

## Migration release rules

1. Never rely solely on filename: compare live `pg_catalog` functions/columns, track applied Nov 9 migrations, and reconcile schema drift. Skip/deprecate duplicate Extra Hard migrations without editing release state. Do not silently mark old files applied.
2. Process contracts in dependency order: **D03 source+RPC firewall first**; profile/time/calendar (P1); validated Cambridge vs iClub time norms (P2); weekly choice/adherence (P3); verified Paper execution vs written score (P4); public Math membership P6 OFF; integration E2E P7; controlled mass GO P8.
3. Early versioned 20261103 files and later 20261105 retrofits may use string-sensitive function rewrites. Each requires exact live function anchor, signature, grants and privilege checks. A codebase migration file being unmerged is **not** permission to run on live.
4. Apply only to disposable PG17 first with signed JWT/PostgREST and Chromium on the **new exact integrated SHA**, not old CI counts. Use one meaningful comprehensive acceptance after source integration; avoid repeating 42-question academic QA or full old 53-step tests.
5. **Preservation:** never reset `public.users`, any real learner's Practice/Tours/certificates, Mathematics Paper attempts/answers, others' subjects, localStorage, or private V4.3 original content. One Extra Hard attempt already existed at last read; do not assume the bank is unused.
6. P0-16B remains separate **open** source/old-token writer audit, previously deprioritized by architect. Do not declare safe nor require arbitrary endless new gates; resolve a concrete cross-system risk before mass rollout if independently confirmed.
7. Beta cleanup is deferred for **separate explicit permission and per-record test/real partition**; the November 9 owner permission was for Extra Hard **publication only**, not deletion or mass Core enable.

## Short restart instruction

> Resume Issue #450 from the **newest v2.2 main-integration checkpoint**, not the older P4-06 or V4.1 'NEXT' lines. Confirm main/current Vercel SHA and active database with SELECT only; protect live Extra Hard V4.3 and the first real attempt. Finish the first unfinished PR-branch dependency (D03), perform targeted PG17/JWT browser checks, log exact commit + CI, then continue P1–P3→P4 Stage3–6→P6 access OFF→one integration acceptance. No blanket #492/#516 merge, no repeated content QA, no student-score fiction, no mandatory Mentor, no beta cleanup without separate GO.
