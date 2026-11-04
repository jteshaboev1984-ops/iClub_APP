# Mathematics P1/P5 — P2-09. Remaining work from actual learner results

**Decision adopted 2026-11-03 from the architect:** study workload must follow **what the learner has already proved and what remains to do**, rather than an identical 81-skill study-hours quota. **Qualified correction:** do not multiply an entire skill's study hours by the number of wrong answers. This document supersedes any interpretation requiring all 81 skills to be re-taught regardless of existing evidence; it does **not** waive source/QA/independent-review requirements for numerically stated minutes.

## Why raw incorrect-answer arithmetic fails in the current real database

Read-only, aggregated production inspection found:

| Mathematics component | Current learner-skill state rows | No objective evidence | Rows with unresolved correction |
| --- | ---: | ---: | ---: |
| P1 | 4,590 | 3,091 | 1,074 |
| P5 | 2,484 | 2,438 | 9 |

These are **state rows**, not distinct pupils, independent unanswered exam problems or confirmed poor knowledge. Many skill rows are unobserved, so summing only wrong responses would omit large portions of the syllabus. Repeated wrong attempts on the same skill may reflect one unresolved misconception, rather than several full teaching cycles. Previously wrong but subsequently confirmed material cannot remain as full new teaching work forever.

## Approved conceptual rule: per-skill remaining action, not per-error tuition

Authoritative inputs are already computed privately by the existing Exam Prep deterministic engine: `private.exam_prep_skill_states` (component, skill, objective evidence and level, confirmed coverage, corrections, retest and transfer state), `private.exam_prep_skill_contracts` (skill-specific requirements), `private.exam_prep_syllabus_nodes` (81 curriculum skills). No legacy Practice/Tour attempt is converted into Exam Prep mastery.

- **No objective observation:** `targeted_check`. Do not assume either weak or mastered; a positive targeted check can prevent unnecessary teaching.
- **Observed with unresolved correction:** one `correction` action for this skill **regardless of repeated wrong attempts**. A later delayed retest is still required where governed; it is not counted as a second full explanation before the correction has been resolved.
- **Observed but unconfirmed without active correction:** `targeted_practice`. The deterministic engine can decide subsequent remediation; one wrong click is not the same as failure to learn a whole topic.
- **Objective coverage confirmed:** only still-required `delayed_retest`, `mixed_transfer`, or `written_work_unscored` steps. Completing the written activity is **not** an examiner-verified method mark or a grade.
- **Contract missing:** cannot guess a phase. Surface `academic_contract_missing` as a blocking academic-source defect, not a learner problem.

Track one outstanding action per **(P1 or P5, canonical skill, phase)**. Do not count each incorrect response as a new tuition unit. Keep shared prerequisite study separate and unique across both components, with no transfer of P1 mastery into P5 or vice versa. Closing correction or demonstrating a skill recomputes the work; history remains immutable. A new error may reopen a genuinely unresolved action, but the same old wrong answers do not force perpetual additional hours.

## How time can eventually be summed

**Only after academic QA of action-specific active-study intervals** (rather than generic `time_limit_sec`, Cambridge guided learning hours, unreliable beta `elapsed_ms`, or arbitrary question counts):

`targeted_min/max = Σ [approved min/max active-study minutes for each distinct pending (component, skill, action)]`

If **any** required action duration is not approved, the full numerical result is `NULL` and the user sees only the task-based plan. Revision, common prerequisites, written-method practice and full-paper sitting need separate governed logistics; the current script's sum is therefore **targeted tasks only**, not complete AS Exam Ready hours. Actual optional work beyond iClub remains unknown; do not backfill it from login or inactivity.

P1/P5 share one Mathematics weekly budget but have different confirmed paper dates; sum **tasks**, never two independent full copies of calendar capacity. Once all required activities and review/paper logistics are approved, the time engine can compare a bounded workload to remaining shared calendar capacity and offer exactly three consent choices. Until then, no numerical advice, change to hours, exam grade prediction, written self-mark, learning quota or daily reminder.

## What is implemented in draft PR #470

- [Read-only owner-only 81-skill remaining-work API](../supabase/migrations/20261103036000_exam_prep_p1p5_remaining_work_from_evidence_v1.sql) behind the existing authenticated Core guard. No question-answer keys, protected assessment inventory or other-user records in the output; all minutes `NULL`.
- [Deterministic offline action-time-sum proof](../scripts/math-p1p5-result-led-time-sum-v1.cjs): tests unobserved checks, many repeated wrong responses collapsing into one action, successful correction decreasing remaining workload, missing duration disabling the sum, and different independent reviewers. **All concrete numerical minutes appearing in this unit test are explicitly synthetic and are never personal recommendations.**
- [Authenticated real RPC / PG17 E2E](../scripts/p1p5-package2-workload-owner-evidence-e2e.cjs) checks actual P1/P5 evidence categories, per-skill idempotence, privacy restrictions and no invented hours.
- The original 81-skill source/observation QA files and corrections/retest safety contract remain unchanged.

**Status:** evidence-first **task inventory implementation, draft and isolated CI only**. Academic review of actual duration data and safe student-facing numerical recommendations remain open. Public release / production cleanup / migrations / flags **NO_GO** pending separately approved gates.
