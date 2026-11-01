# Exam Prep — written-answer authority & controlled beta acceptance, 2026-11-01

**Scope:** Cambridge AS Mathematics P1/P5 written learning and governed controlled beta. Architect authorised resumption of previously deferred stages. This checkpoint adds **isolated engineering E2E**; it does not invent real learner sessions, human examiner marks, retrospective weekly reviews, or beta sign-off.

## Governing contract

- `docs/exam-prep-written-learning-contract-v1.md` v1.3: iClub is **not an essay examiner**. Written work done externally; criteria optional; "Next" advances the plan but never means correct, scored, or mastered.
- `docs/exam-prep-written-reasoning-audit-v1.md`: deterministic companion MCQ is `app_checked_noncredit`; genuine free written work is `self_reviewed` absent authorised mentor.
- Uploaded signed `07_Beta_Release_Plan_P1_P5_v1.1`: controlled 12–20 learner cohort, Core can function without AI/Mentor, learner consent, no legacy mutation, 15-profile synthetic matrix, real 72-hour observation, four real weekly reviews before expansion, separate service-mode hold points and rollback.
- Legacy Maths timed written `submit_exam_prep_timed_written_self_mark_safe_v1` is explicitly **learner-supplied self-mark**, not automatic or AI grade; it must never be advertised as examiner verification.

## Fresh production checks (read-only; no auth impersonation)

At 2026-11-01, `private.exam_prep_written_understanding_checks` contains 180 published **MCQ** companion checks on 175 tasks. A live call to the genuine `private.exam_prep_evaluate_written_understanding_v1` over each task constructed three sets: every correct option, every incorrect alternate, and null/unsubmitted. Results: **175/175** correct cases fully correct, **175/175** wrong cases zero correct, **175/175** null cases zero credit; no mismatches. Reproducible fixture `scripts/fixtures/exam-prep-written-companion-180-acceptance-readonly.sql`. No free-response equivalence examiner exists in the approved runtime. Correct mathematical forms `1/2`, `0.5`, `2/4`, `50%` or equivalent algebraic derivations are not individually judged by the written Core. This is an intentional non-crediting policy, **not proof that AI can evaluate any arbitrary written solution**.

The live `submit_exam_prep_response_safe_v1` writes written answers with `is_correct=NULL`, `verification_status=self_reviewed`, and companion metadata `understanding_authority=app_checked_noncredit`. The client cannot submit `is_correct`, `correct_answer`, `mastery`, `skill_state`, or `verification_status`. `advance_exam_prep_written_step_safe_v1` is authenticated/owner-scoped and idempotent, and does not award marks.

Current real cohort `math_as_p1_p5_beta_2026_09_01`: canary, planned capacity 12, wave 1, 3 active members, 3 granted consents and 3 active Core entitlements. Among active members, **2** have actual Exam Prep sessions: **32 sessions** (30 finalised, 2 still active; P1=26, P5=6); 2 sessions started within the past 7 days at snapshot. The production gate `private.exam_prep_beta_expansion_gate_v1` returns `ready=false`, `reason_code=four_real_weekly_reviews_incomplete`, `real_weekly_review_count=0`, `green_last_four_count=0`. Runway hard floor and 4-week target are green; zero recorded blocking Sev0/Sev1. These facts are not equivalent to four complete weekly reviews.

Core remains enabled only under controlled-beta gating. No service flag, membership, consent, mentor assignment, AI activation, or rollout setting was changed by this audit.

## Isolated E2E test battery

1. Real Written Core controller + actual user-facing Written Core view in Chromium. Scenarios: open authenticated-authorised synthetic task; optional criteria; Next without criteria; no essay/photo/score input; noncredit of all mathematically equivalent on-paper solution formats; repeated click/idempotence; lost server ACK but committed operation; true offline failure and explicit retry; unauthorised task fail-closed; no horizontal overflow. Matrix **RU/UZ/EN × 375/1280px × 5 cases = 30 browser scenarios**.
2. Existing authorised weekly learner flow in real renderer with injected **synthetic** RPC and zero network, including resume and retry.
3. Existing timed/full-paper answer ACK and recovery browser matrix.
4. Existing non-grading, written-core idempotence and cross-subject boundary guard suites.
5. Independent noncredit equivalence boundary examples run against real Written Core controller (not a fictitious essay-marker implementation).

Scripts: `scripts/exam-prep-written-beta-isolated-browser-acceptance.cjs`, `scripts/exam-prep-written-equivalent-methods-noncredit-regression.cjs`; continuous gate: `.github/workflows/exam-prep-written-beta-isolated-e2e.yml`. All tests block external web traffic and do not create production accounts, data, grades or progress.

## Outstanding real-world acceptance — do not misstate as completed

- **Real signed-in device journey is still necessary**: with *existing consenting beta learner* under their own authentication, confirm home → Mathematics → Exam Prep P1/P5 → learning → written criteria/Next → resume after logout/reopen, plus timed writing in RU/UZ/EN on mobile and desktop. The QA automation cannot legitimately use learners' sessions or create new real learner responses. Enrolment requires explicit student consent.
- Record actual user-provided QA evidence and usability issues from at least **two different** consenting learners, with device/browser and version. Existing session counts alone cannot prove that the new mobile journey passed.
- Conduct first 72h monitored deployment/feature state evaluation **when an actual new release/wave occurs**; do not retrospectively manufacture 72h evidence.
- Run **four genuine weekly Core reviews** with security, P1/P5 progression, offline/resume, accessibility, i18n, response duplication, service isolation and real support metrics. Missing reviews are not marked GREEN on the strength of synthetic tests.
- Expanded beta remains **NO_GO** until `exam_prep_beta_expansion_gate_v1` reports ready and the human owner authorises an explicit wave; mass rollout stays **NO_GO**. Mentor Care is separately held when staffing capacity is not demonstrated. AI optional failures must not break Core.
- The approved Beta Plan expects 12–20 eventual participants across independent Core, AI and limited Mentor modes, not direct onboarding all users as Mentor. No unapproved user account creation, flags, payment, live grading or learner mutations are permitted.

## Stop conditions

Stop expansion immediately for any cross-user access, answer-key leak, P1/P5 mixing, duplicated grade/progress, invalid content versions, unconfirmed save represented as success, false written mastery, real safeguarding issue or unavailable rollback. Preserve evidence and patch only confirmed faults through version-safe changes.
