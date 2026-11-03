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

## 2A. Verified historical Cambridge topic-teaching reference (distinct from 81 skill norms)

Found Cambridge Assessment International Education-authored **Mathematics 9709 Schemes of Work, Version 1, for examinations from 2020**. Both documents give approximate *guided teaching/contact time* by **syllabus topic** (not by 81 fine-grained skills, not a total personal study quota):

| Paper | Topics | Guided teaching-time suggestions in the historical Scheme of Work |
| --- | --- | --- |
| P1 Pure Mathematics 1 | 1.1 Quadratics, 1.2 Functions, 1.3 Coordinate geometry, 1.4 Circular measure, 1.5 Trigonometry, 1.6 Series, 1.7 Differentiation, 1.8 Integration | **10, 10, 10, 4, 14, 10, 16, 16 hours** respectively; combined 90 hours |
| P5 Probability & Statistics 1 | 5.1 Representation of data, 5.2 Permutations and combinations, 5.3 Probability, 5.4 Discrete random variables, 5.5 Normal distribution | **14, 4, 12, 8, 12 hours** respectively; combined 50 hours |

Sources: [Cambridge-authored P1 scheme PDF, hosted by an educational institution](https://cdnsm5-ss20.sharpschool.com/UserFiles/Servers/Server_4756360/File/Academics/Magnet%20Program%20-%20Cambridge%20AICE/Cambridge%20Resources%20for%20Teaching/Mathematics%20Pure%20Math%20Paper%201%20Scheme%20of%20Work.pdf); [Cambridge-authored P5 scheme PDF, external archive](https://peipeimaths.wordpress.com/wp-content/uploads/2020/04/9709_y20-22_sw_probstats1_v1.pdf). Both original documents explicitly date themselves **from 2020**. Cambridge's [current official 2026–27 syllabus](https://www.cambridgeinternational.org/Images/697427-2026-2027-syllabus.pdf) describes about **180 guided learning hours for an AS qualification**, but does **not** authorize converting these topic contact hours into individual unsupervised skill workload.

**Strict product limit:** these 140 total historical topic-guided contact hours are not asserted to equal the full 180-hour 2026 AS program, nor should the difference be invented or assigned to learners. Scheme of Work history may require update for 2026–27. Therefore the new `private.exam_prep_historical_topic_teaching_refs_v1` stores the 13 entries with status `historical_reference_unverified_for_2026_27`, source URLs, and `approved_as_personal_study_norm=false` (database CHECK blocks false-to-true mutation). This historical register is independent of 81 source-backed **unreviewed numeric skill norms**. No aggregate, topic or skill number is displayed as an individual iClub recommendation yet.

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

## 3A. Working read-only learner evidence projection — no invented times

A separate additive public owner-only RPC `get_exam_prep_workload_review_projection_safe_v1()` now joins:
- Actual 45 P1 / 36 P5 canonical skill source rows with **latest** real objective skill evidence per learner, component and skill code (no double-counting retired engine versions).
- True `stage0_complete` placement and last finalized component diagnostic session. An unfinished diagnostic wave is not counted as a completed diagnosis.
- Own existing confirmed exam appointment snapshot, chosen total Mathematics weekly budget, and verified source registration status.
- An official Cambridge 2026–27 exam-duration **minimum uninterrupted Paper block**: **P1 = 110 minutes (1 hour 50 minutes)** and **P5 = 75 minutes (1 hour 15 minutes)** (assessment overview pp. 14–15 of the current [official syllabus](https://www.cambridgeinternational.org/Images/697427-2026-2027-syllabus.pdf)). These are sitting durations, **not** a daily lesson cap, a personal study-hours recommendation or a Cambridge readiness score.

Crucial classification: a missing per-skill record or zero objective observations is **unknown**, not `weak`; an objective observation with insufficient coverage is *observed but not confirmed*; stronger confirmed objective evidence with no unresolved correction is reported separately. Evidence consisting only of a written answer or mentor note does not silently become an independently marked objective answer. All summed personal workload and daily-minute recommendations remain `NULL`, `recommendation_accept_enabled=false`; this RPC cannot change a saved schedule, unlock/lock lessons, issue notifications or alter skill-state records.

The read-only source and evidence view `private.exam_prep_workload_academic_review_queue_v1` allows a genuine content reviewer to inspect each of the 81 skills with the current 9709 syllabus paragraph, textbook reference, prerequisites, proof obligations, unreviewed iClub time fields, and related *historical teaching-time context* by topic. Authenticated learners and anonymous users have no direct access to the private view. Do not treat displaying its historical topic hours as academic approval of a skill range.

A source-integrity PG17 step and a signed-JWT PostgREST step use the already established **two disposable CI actors**, **not invented progress**, to assert 45/36, objective-vs-unknown classification, owner access, exact official 110/75 paper blocks and absolutely no fabricated recommended study hours. They do not modify genuine Supabase records.

## 3B. Real published-question inventory and timing-data suitability (2026-11-03, SELECT-only)

Compared the actual active-program **81 source skills** with `private.exam_prep_question_content_meta`, published content versions, `private.exam_prep_written_tasks`, published assessment routes, `public.questions.time_limit_sec` and existing actual response `elapsed_ms`. This is grounded in the real deployed bank, not a manufactured learner scenario.

| Real bank, QA `pass` for mathematics/language/technical/scope | P1 | P5 |
| --- | ---: | ---: |
| Canonical skills | 45 | 36 |
| Published objective questions | 270 | 216 |
| Protected reserve questions, **not to expose in student API** | 405 | 324 |
| Previously retired objective questions | 3 | 0 |
| Objective published questions **per skill** | 6 | 6 |
| Protected reserve objective questions **per skill** | 9 | 9 |
| Published written tasks (total, all maths/language/technical QA `pass`) | 170 | 164 |
| Published written tasks per skill | 2–7 | 2–12 |
| Skills without at least one published objective + written task | 0 | 0 |
| Time-limit of an individual published objective question | 25–90 s | 30–90 s |

Distinct question IDs rather than repeated assessment links are counted. All current 81 skills are also represented by a **published diagnostic, learning and retest assessment**; the actual paper and timed assessment mappings are much narrower, and their recorded raw marks do not justify a personal grade forecast. Required-mastery evidence in the original `01_Academic_Syllabus_Source_Map_P1_P5_v1.0` uses **four distinct pedagogical evidence templates**, not 81 Cambridge-issued workload benchmarks (P1 19 routine/transfer, 16 contextual/proof, 5 diagram/interpretation, 5 recognition/transfer; P5 12/14/5/5 respectively). The original map expressly states that **81 is an iClub decomposition of official content bullets**, not an official Cambridge skill count.

**Critical deployment invariant:** all 1,218 current Exam Prep question records have `public.questions.is_active=false` because Exam Prep uses its separate permissioned question/assessment lifecycle. Within its own protected content metadata **486 are published, 729 protected reserve and 3 retired**, all with academic QA status `pass`. **Do not bulk-set `public.questions.is_active=true`** or send reserve IDs/pool counts to students. Existing genuine signed HTTP/Chromium E2E already confirms the intended private published route works.

The measured response-time field `private.exam_prep_responses.elapsed_ms` is **not suitable as a self-study-time estimator** on the present beta data: P1 diagnostic-machine median among plausibly nonzero values was only **~1.4 seconds** across 1,401 qualifying responses; P5 diagnostic-machine had **46 responses** (median ~21 seconds), and P5 learning-machine had only **3 responses**. These observations can contain test/synthetic actors, fast taps or client timing limitations; no validated user classification, active foreground session-time accounting or out-of-app learning. Avoid drawing a population learning-rate conclusion. A per-item question deadline is a *maximum examination time for that question*, not a typical learning block, and it excludes explanation, working, corrections, revision, and delayed retests.

Implementation: new private, read-only `exam_prep_skill_content_calibration_inventory_v1` joins current 81 syllabus source rows with independently approved/published objective questions, protected reserves (internal only), written exercises, actual published diagnostic/learning/retest routes and per-item timer limits. It records explicit **false** flags for any attempt to interpret question timers, observed elapsed_ms or historic 2020 teacher-contact hours as personal study norms. A strict PG17 check requires core published question/written/route coverage and no false time claims. The view performs **zero** student state writes, entitlement updates or learner-facing reserve exposure.

**Academic decision:** current data establish **content availability**, but not a defensible `minutes to learn skill` interval. Leave all 81 `estimated_core_min/max_minutes` and `estimated_revision_min/max_minutes` NULL pending authentic instructional time evidence and mathematical review of representative written/routine/transfer methods. Never replace the original unknown state with a negative readiness label, and never create daily reminders or study-hour access caps.

## 3C. Real pupil-chosen shared calendar capacity — not required workload

The additive read-only, owner-only `public.get_exam_prep_shared_study_capacity_safe_v1()` now provides a numerically accurate **capacity-only** part of the future calculator. It uses the existing protected Math exam profile's explicitly selected `mathematics_hours_budget`, the real `stage0_complete` component diagnosis + finalized diagnostic timestamp, own already confirmed P1/P5 centre exam appointments, and the server's governed academic clock. For a future paper at time `t`, the *unchanged plan* would make available:

`round(chosen Math weekly hours × max(seconds until t,0) / 604800, 2)`.

The calculation uses fractional weeks rather than rounding each week up, and **P1 and P5 share a single Mathematics budget**. The API returns time to the **earliest** and **latest** *ready* paper, **not** two additive paper-hour allowances. It deliberately emits `horizon_hours_additive_across_p1_p5=false`, `capacity_is_recommendation=false`, `capacity_is_access_limit=false`, `may_study_above_plan=true` and `recommended_study_hours_per_week=null`. It cannot write a profile, grade, lesson session, correction or any previously earned evidence. The same real signed HTTP E2E actor completes authentic Stage 0, saves two school-date test inputs through the existing owner-only appointment RPC, and asserts both capacity values directly from exact timestamps and the student-elected weekly hours. The test dates are not official Cambridge claims.

This is *calendar availability at the student's chosen pace*, not a statement that the learner needs this many hours for A, that this amount is sufficient, or that either paper is ready. Students can still study beyond their scheduled time with **no time-based lock**. If a paper date is not confirmed, has passed, or its diagnostic is incomplete, the API returns a reason and no fabricated numeric capacity for that paper. Genuine **skill learning requirements remain unknown** until an independently reviewed 81-skill academic model has credible minimum/maximum study intervals; only then can a requested change of hours be compared with available time and shown through the agreed three consent actions.

The public `lessons` table has only **7** rows for Mathematics subject 5 and no video-duration field; this cannot supply missing teaching-hour calibration. The two provided coursebooks are image-only PDFs, so no claim of automated per-exercise timed reading or independent textbook-minute audit is justified.

## 3D. Direct legacy date-save bypass: fail-closed without destructive migration

The existing authenticated `save_my_exam_prep_exam_appointment_v1` does not itself validate the scheduled start against the learner's selected Cambridge exam year/series. Package 1 introduces a stricter opt-in UI save RPC, but a legacy direct RPC may still exist. We **do not revoke or rewrite** the legacy endpoint during beta because that could break the existing authorized exam-day workflow.

The additive private `exam_prep_exam_date_matches_series_v1(series,start)` checks the year and eligible local Uzbekistan paper months (May/June session may include April; Oct/Nov session can begin in September). Both owner-only read-only workload review and chosen-hours shared-capacity APIs **fail closed** for a date outside the declared exam series: status `exam_date_series_mismatch`, no deadline counted or capacity inflated. This uses no production data write or learner reset. A genuine signed PostgREST CI actor saves an intentionally invalid date through the existing legacy v1 API, confirms both projections reject it, then re-saves its original valid date and confirms the two-paper capacity is restored. Those dates are **disposable test inputs only**, never official Cambridge dates.

The correct future permanent fix is a reviewed, backwards-compatible server validation policy for *all* appointment writes, after checking Stage 4 legacy clients and migration history; this is not a request to strip current permissions from production users.

## 4. Boundaries and next step

This PR is **not** academic certification of all 81 skill-time intervals. All current numeric skill norms are intentionally missing. Next is source-specific individual time-range review (a real academic task), then independently checked readiness engine and genuine UI consent controls. No production deployment, no cleanup, no Stage D mass-Core GO. Preserve the approved course and historical user progress across upgrades.
