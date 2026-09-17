# Exam Prep Progress UX v1 — approved implementation contract

Status: APPROVED PRODUCT BEHAVIOUR; IMPLEMENTATION IN ISOLATED BRANCH ONLY. Date: 2026-09-17. Design references: Master Implementation Plan v1.1, annual roadmap compliance audit, 81-skill canonical map. Stitch visual exploration postponed until after functional implementation. This document is the working specification until acceptance; retain in project history afterward as the decision record.

## 1. Observed baseline (read-only, 2026-09-17)

Production main at audit: `801f9636a0954e6583034e6d78b839d229b86863`. Existing `exam-prep-live.js` calls `generateWeeklyPlan(component, 'normal')` after a finalized non-diagnostic learning session and replaces the plan screen. Existing `generate_exam_prep_weekly_plan_safe_v2` supersedes the active plan, inserts a new one, then creates up to three new `pending` items. V3 calls V2 and can replace its individual slots for mixed/retest/revalidation. The weekly items have only `pending/completed/superseded` state, but there is no reconciliation that marks weekly items complete when their bound sessions finalize. The completion screen introduced by `exam-prep-learner-flow-ux.js` already exists and reports answered/saved counts and next action. Keep it; extend rather than duplicate.

Read-only aggregate verification at this baseline: one Exam Prep profile, six P1 plans in active week 1 (five superseded, one active), three items per version, all 18 still `pending`; five different historical P1 plan versions each have a finalized session bound to the first correction priority. These aggregate facts demonstrate that the visible `0/3` or repeated `3 items` cannot be interpreted as zero student activity. Do not publish private IDs or fabricate a completed weekly goal from these sessions.

## 2. Academic invariants

- Exactly one existing Mathematics subject; P1 = 45 and P5 = 36 canonical iClub skills; no combined mastery/readiness percentage.
- Stage E0–E6 and coverage/mastery/retest/readiness remain server-determined, versioned and separate by component. An active week is a planning window, not an automatic stage advancement. Thirty-six active weeks are an orientation, not guaranteed readiness.
- Weekly commitments, completed study sessions, confirmed coverage, verified skill level, correction closure and app readiness are different facts. A completed session is never sufficient proof of mastery. Error closure still requires a valid delayed retest.
- One learner-facing weekly plan displays **at most three stable goals PER COMPONENT**. A goal may contain several sessions or changes of action within the same correction case. A changing exercise never silently creates an extra goal.
- Never change/delete/rewrite historical Practice, Tours, attempts, ratings, certificates, existing Exam Prep evidence, existing plan history, localStorage or pending operations. All new structures additive and reversible by feature flag. AI and Mentor Care are not required.

## 3. Server-owned weekly goal projection (implement before visual counters)

Identify a goal by `user + program_version + component + active_week_no + stable_goal_id`; do NOT identify it solely by `(active plan_id, priority_order)` because regeneration changes `plan_id`. Snapshot the first eligible weekly planning commitments in order, up to three, with original plan/item linkage and immutable identity. A correction goal is anchored to its original `correction_case_id` (and component/skill), learning to the component/skill and assignment, mixed to its exact assessment, and retest to its correction case or approved retention skill. Repeated sessions under regenerated plans with the same provenance belong to the existing goal. New urgent work may replace a slot only through an explicit, audited reason and a record of the displaced goal; never erase previous work, reset the week's goal denominator or silently relabel previously completed work.

On first activation for an existing learner, recover authentic anchors and actual sessions from historical plan and authorization/evidence relationships. Preserve verified session counts. If historical evidence cannot prove weekly-goal completion, show `История занятий сохранена; выполнение прежних недельных целей не подтверждено` instead of inventing a backfill. Missing plan or server access means no fabricated `0/3`, no optimistic cache and no client-side persistence of authority.

The server read contract must expose `contract_version`, `component_code`, `active_week_no`, stable goals (up to three), authoritative goal completion/phase and provenance, total finalized study sessions, confirmed coverage and mastery separately, current pending actionable item binding, open correction facts, and retest due timestamps where known. Do not send answer keys, private rubrics, another learner's data, or infer correctness from an answered-item count. Count distinct finalized session IDs, not overlapping rows, replays or plan versions. No cross-component counts except a separately, explicitly named total sessions number where academically appropriate.

## 4. Goal semantics and progress denominator

Display `completed_goals / original_goals_count`. Use the original frozen denominator (1–3) and clarify when fewer than three were initially planned. Use no percentage if denominator is 0. A displayed step `2 из 3` is permissible only if those exact three steps are truly specified and verified by the server; otherwise use text statuses.

Goal states: `not_started`, `in_progress`, `weekly_work_done`, `waiting_retest`, `completed`, `needs_rework`, `paused`, `replaced`, and `unavailable`. For a correction, reaching server-confirmed `remediation_completed` may complete the week's assigned remediation commitment **without** closing its correction case; show open correction and dated retest separately. Retest success closes correction only under existing academic rules. Failed retest must never appear as a resolved correction. Learning/mixed/timed activities can count as completed weekly work after authorized finalized evidence, not as skill mastery. Unverifiable written evidence must never be presented as mentor verified. A later reopening preserves historical activity facts and adds `needs_rework` without deleting evidence.

When an urgent task causes replanning, show a brief human explanation, preserve old goals and their progress, and expose the new actionable task clearly without depicting it as a fourth weekly commitment. On week rollover, archive the old week, retain achieved goals, explicitly carry unfinished tasks forward and start a new goal denominator; changing calendar dates never promotes stage/mastery.

## 5. Required screens (enhance current UI)

1. Overview: separate P1/P5 cards with current stage, confirmed coverage if available, verified skill facts, completed sessions, open corrections and one next action. Show week N/36 as orientation. No invented readiness percentage. Saved exam plan/edit remains single instance.
2. Weekly plan: persistent goal titles, `N из M целей`, actual step/action and open-correction/retention distinctions. Current task actions use the latest authorized plan binding, never a stale plan ID. Display why a step repeats and which goal it advances. When no actionable content is available, explain that state rather than showing a dead button.
3. After-session screen: existing completion screen with trusted BEFORE/AFTER change from server snapshot, saved response count, machine-correct count ONLY if server-confirmed, verified academic changes/unchanged reasons, remaining work and one primary action. Never claim `3/4 correct` from `3/4 answered`.
4. Waiting for retest: show completion of present week's work, correction still open, precise server-supplied due date or `Дата уточняется`, disabled early-retest action and next available optional activity.

All learner-facing copy must be natural and QA-reviewed in RU/UZ/EN. Avoid `L1`, `L2`, `evidence`, `ledger`, `state machine`, `лестница` and other internal labels.

## 6. Deployment sequence and acceptance gates

A. Lock data contract and regression fixtures in branch. B. Implement additive server goal ledger/read API and isolated SQL tests in a non-production sandbox/rollback transaction. C. Add separate namespaced UI adapter/presentation (feature flag default OFF); do not grow `app.js` with domain logic. D. Run deterministic tests: 3→2→1, 3→3 regenerated, five sessions under one correction, completed remediation/awaiting delayed retest, failed retest/reopen, P1/P5 isolation, new week, recovery, plan change, time travel, stale request, duplicate submissions, cross-user RLS, AI OFF, no mentor, three languages, phone/desktop and all legacy regressions. E. Take read-only production baseline and verify unchanged counts/history. F. Controlled cohort release only after green tests and explicit production gate.

No Supabase production DDL/DML, GitHub main merge or Vercel production deploy is authorized by merely creating this design contract. The branch may contain safe proposed migrations and tests; a failed verification blocks rollout without deleting any prior learner data.
