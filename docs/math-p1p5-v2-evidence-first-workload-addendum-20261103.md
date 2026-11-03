# Mathematics Exam Prep P1/P5 — normative change-control addendum: results-first remaining workload
**Version:** v2.1-D01 | **Architect decision:** 2026-11-03 | **Scope:** v2.0 roadmap Package 2 / Package 3 | **Issue:** #450

## Decision
Accept the architect's principle that **an individual learner's demonstrated results determine the remaining work**. Every unresolved canonical skill contributes actionable learning/correction/checking work, and completed verified work removes it from the outstanding workload. Supersedes any interpretation that each learner must be assigned a full baseline learning duration for each of all 81 skills.

### Essential correction: wrong response is evidence, not a separate full lesson
The denominator is the **distinct outstanding learning phase** `(component_code, skill_code, action_code)`, not every incorrect response. Repeated wrong answers within one unresolved skill must not multiply a full subject teaching allocation. A new error can legitimately reopen a correction only through the existing deterministic engine. An old error previously corrected and retested must not stay as a new time charge. No manual/AI scoring of written solutions.

### Unknown ≠ weak
No objective evidence -> targeted check, not automatically the full study duration. When evidence indicates skill mastered at its objectively verifiable level, do not blindly allocate full introductory learning; still handle delayed retests, mixed transfer, unscored written work and exam readiness separately. P1 and P5 keep distinct records and independent deadlines. Prerequisite learning may be shared only once as study effort, never as cross-component mastery credit.

### Time calculation boundary
Only with independently reviewed active-study minimum/maximum duration estimates for **each pending action**:

`remaining_targeted_minutes_min/max = SUM(approved duration for each distinct still-required action)`.

This is not automatically the total to achieve an AS grade: separate common prerequisites, ongoing revision, multi-skill transfer and uninterrupted P1=110/P5=75-minute paper attempts must be accounted for without duplication. Real in-app response elapsed_ms and question time_limit_sec are not proven self-study minute norms; Cambridge guided learning hours are not a per-skill student timetable. Unreviewed action durations keep the full numerical estimate NULL; never fabricate a recommendation.

### Preserved learner choice and product boundary
The learner can exceed their schedule; no quota, cap, penalty or automatic change. Recompute at completed weekly/monthly periods and after meaningful diagnostic/progress changes. When reliable time bands and scheduling are available, show exactly three choices: leave existing schedule, accept recommendation, enter custom schedule; only a confirmed selection changes future plans. No daily progress messages.

## Implementation/checkpoint
Draft [PR #470](https://github.com/jteshaboev1984-ops/iClub_APP/pull/470) adds a server-authoritative, owner-only, read-only 81-skill remaining-work projection using existing `private.exam_prep_skill_states`, `exam_prep_skill_contracts` and syllabus nodes; plus an offline interval-summing model that remains non-authoritative and returns NULL without independent reviewed ranges. Dedicated actual JWT/PostgREST/PG17 E2E and negative-case tests guard unknown/multiple errors/privacy/time caps and no fabricated hours. See [implementation policy](https://github.com/jteshaboev1984-ops/iClub_APP/blob/feature/math-p1p5-workload-registry-v1-20261103/docs/math-p1p5-p2-09-results-led-remaining-work-policy-v1.md).

**This addendum does not authorize production DDL/DML, flags, beta cleanup, deployments or a GO.** Original roadmap content/source hierarchy, service capabilities and separate release authorization remain valid unless explicitly overridden here.
