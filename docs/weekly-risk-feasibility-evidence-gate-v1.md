# Weekly risk and feasibility: evidence gate (DRAFT, not a release)

This file has no runtime effect. Do not merge, deploy, install SQL, enable a flag or update learner records from this document alone.

## Grounded product requirements

- Stages depend on academic evidence, not the calendar. The 36-week roadmap's dates are planning windows. The learner chooses an exam series, not Cambridge's official examination dates; target-grade changes never follow automatically from a missed goal.
- Preserve distinct P1/P5 academic mastery and correction/retest evidence. The mathematical weekly budget is one **shared** budget for Mathematics, not a separate amount available to each component. The roadmap's 8–18 hours weekly are the *total for several subjects*, not Mathematics time.
- The existing Exam Plan editor is the sole place to change available hours, target grade and supported exam series. Never add a duplicate editor or silently regenerate an unfinished weekly plan.
- Approved recovery after a learner-reported 1–7-day interruption uses reserve capacity; 14–21 days has a separate fourteen-day 50/25/15/10 activity split; >one month calls for rebaseline and exam-series feasibility review. These source recovery policies are **not** proof that a currently unanswered weekly goal is at risk or that every learner has this time available.

## Verified code contracts and missing evidence

- `private.exam_prep_effective_active_week_v1(user_id)` is derived from the profile start, not a completion or workload forecast.
- `private.exam_prep_weekly_plan_items.due_at` is nullable and is primarily populated for delayed retests from `retest_events.due_not_before`, an **earliest eligibility timestamp**, not a deadline to complete the exam or a task-duration estimate. Never use this value as a late-work deadline in an at-risk algorithm.
- The existing exam profile supplies `total_student_hours_available` and a shared `mathematics_hours_budget` per week. It does **not** provide a user's available future hours for each remaining day, actual hours already spent, or independently vetted duration estimates for pending tasks.
- Existing progress reports return completed/frozen goals and finalization evidence, not the expected time to complete each remaining original goal. A study session's elapsed answer telemetry is not a vetted forward task-time estimate.
- The prior-week read-only proposal can report verified missed work **after** a closed week, and it fails closed on missing/ambiguous plans. Do not silently promote that historical verdict into a current-week probability or grade forecast.

## Conditions BEFORE shipping predictive risk or precise catch-up hours

1. The server identifies one stable current-week plan, exactly matched frozen goals, verified status and relevant evidence across devices, and supplies a trusted week-end timestamp. An active session must be resumed before any new task is started.
2. The learner's available time *remaining until that exact week-end* must be confirmed or conservatively bounded within their already approved Mathematics budget, without borrowing the total multi-subject budget. A 14-day recovery budget cannot be counted twice for P1 and P5.
3. Each pending original goal must have an approved estimated duration with provenance, including a different treatment for correction, retest and written checking; never infer this from the number of questions, a generic unit-time assumption, or previous attempt length.
4. Confirm that an eligible assessment/learning pack is actually available and unexposed when fresh content is required; do not recommend replaying the sole exposed four-item pack as new evidence or consume held-out diagnostic/retest reserves.
5. Only then compare **bounded remaining time** to **approved task estimates** and report a sourced, explainable workload review. Missing evidence returns `insufficient_information` and offers existing next tasks and the existing Exam Plan editor, not a risk score, fake feasible plan, extra study hours or automatic grade/session changes.
6. Validate study breaks and scheduled retest eligibility separately; no grades, stages, mastery, certificates, Tours/Practice or historical plans can change as a side effect of viewing guidance. Revoke warnings when newer finalized server evidence arrives; delayed older reads must not restore them.

## Decision for architect (not implied approval)

The current profile only records a weekly Mathematics budget. Before promising an individual *ahead-of-deadline* feasibility estimate, agree how to obtain the student's **remaining free hours by day** and how approved **task-duration ranges** are governed. Until then, the implementation must remain factual/read-only and must not present predictions.
