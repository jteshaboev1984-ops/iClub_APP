# Mathematics P1/P5 — Package 2: source register and workload approval boundary

**State:** implementation scaffold, DRAFT. **No personal-hour recommendation yet.** Issue [#450](https://github.com/jteshaboev1984-ops/iClub_APP/issues/450). Separate PR, no production migration or data modification authorized.

## 1. Existing academic evidence (production checked SELECT-only, 2026-11-03)

The **active** `math_as_p1_p5` canonical map contains **81 distinct skills: 45 P1 and 36 P5**, all with a Cambridge 9709 official syllabus section, canonical skill code, full official syllabus URL, book chapter and prerequisites field. The component sources reflect **11 distinct P1** textbook chapter mappings and **10 distinct P5** mappings. Source mapping is a *content syllabus*, **not** a researched duration for any skill.

Existing `private.exam_prep_syllabus_nodes` (single academic source of truth) is retained unchanged. The new registry is seeded exclusively through `INSERT ... SELECT` from these existing rows; it does not synthesize source paragraphs or assign minutes by dividing a course total. A specific syllabus edition/version belongs to `program_version_id`; changes to syllabus require a versioned source migration, not overwriting historical user evidence.

Course reference: <https://www.cambridgeinternational.org/Images/697427-2026-2027-syllabus.pdf> (canonical source URL already used by the source map). The general Cambridge AS guided-learning benchmark, if verified against the official document, is a **whole qualification planning reference**, never evidence that an individual P1-QUA-01/P5 skill needs exactly N minutes of personal study. Distinguish formal teaching, independent practice, corrections, delayed retests and actual Paper sitting time.

## 2. New durable source register

Migration `20261103030000_exam_prep_p1p5_workload_norm_registry_v1.sql` adds:

- Private `exam_prep_skill_workload_norms_v1`, keyed to exact source `(program_version_id,skill_code)`, with authenticated learner direct access **revoked**, RLS enabled, and no changes to public question banks or user learning records.
- The **81 source-linked draft entries** are inserted with all numeric time fields **NULL** and state `unreviewed`.
- Optional future intervals (minimum/maximum in minutes) for learning and revision are **iClub estimates aligned to Cambridge content**, not Cambridge-issued per-skill norms. A row cannot reach `approved` unless intervals are coherent, methodology is explained, review and **independent** approval identities and timestamps exist.
- Safe owner-only `public.get_exam_prep_workload_norm_status_safe_v1()` can report academically approved coverage by paper, but always returns `numeric_recommendation_enabled=false` until the verified scheduling engine exists. Nothing in current live UI calls this function.
- PostgreSQL 17 migration replay checks 81 source-bound rows, exact 45/36 split, zero published per-skill minutes and no premature review status. No fake learners needed for this source-integrity assertion.

## 3. Required independent academic review, not a fake target

Before approval of numeric ranges, for **each** skill record a defensible mathematical teaching path, baseline prior knowledge, whether mastery can be established by app-verified objective evidence, independent guided vs self-study assumptions, representative written/MCQ balance, correction and delayed-retest time, source provenance and valid uncertainty interval. Published exercises and time limits for answering a question **do not equal hours needed to learn a skill**.

Retain prerequisites and unknowable evidence separately: the entry diagnostic only samples part of the full 81-skill syllabus, so `unknown` cannot automatically be treated as `weak` or `mastered`. Strong students may require fewer preparatory minutes but still need appropriate mixed transfer and complete Paper practice; no promise of A or A* probability is supported.

The resulting engine must:
1. Combine P1 and P5 without double-counting common revision time and preserve component-specific academic states.
2. Translate *approved* interval workload to calendar time remaining from **completed diagnostic → each confirmed exam date**.
3. Account for new evidence and true completed 7-day study periods, unverified answers and prerequisite blockers, plus full uninterrupted exam Paper time (separate from ordinary 30-minute sessions).
4. Show achievable/minimum/maximum time **and** explain when the examination deadline is too close. Never fabricate an official timetable; learner-confirmed centre time and officially verified Cambridge schedules have distinct provenance.
5. Offer exactly three consent actions — `Оставить моё время`, `Принять рекомендуемое`, `Указать другое время` — **only when** estimates were independently approved. No silent change to a learner budget or blocked lessons when a student exceeds planned hours.
6. Produce progress advice **only once at the end of a completed week/month**, not daily. Never turn session count into inferred hours and never assume learning outside iClub did not happen.

## 4. Boundaries and next step

This PR is **not** academic certification of all 81 skill-time intervals. All current numeric skill norms are intentionally missing. Next is source-specific individual time-range review (a real academic task), then independently checked readiness engine and genuine UI consent controls. No production deployment, no cleanup, no Stage D mass-Core GO. Preserve the approved course and historical user progress across upgrades.
