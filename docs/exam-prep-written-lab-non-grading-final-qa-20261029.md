# Exam Prep — written and laboratory non-grading boundary: final QA checkpoint
**Date:** 29 October 2026  
**Scope:** Economics 9708 P2/P4, Chemistry 9701 P3/P5 practical-skills cards, existing generic Written Core.  
**Release decision:** QA guard only, **no new learner release, no automatic grading, no production data mutation**.

## Source of truth
- `docs/exam-prep-written-learning-contract-v1.md` v1.3 and machine-readable `exam-prep/contracts/written-learning-contract-v1.json`: iClub prepares for exams; it is **not an examiner**. A learner views a question, works independently outside the app, optionally checks approved assessment criteria and presses Next. Next is an idempotent recorded *plan advancement*, not evidence of correctness, a grade, mastery, or review.
- `docs/exam-prep-chemistry-j13-independent-tutor-labs-gated-20261027.md`: Chemistry P3/P5 material explains practical skills; reading does **not** validate experimental work, laboratory competence or an exam result. Both independently gated until authorised release.
- Mentor Care is the **only** approved channel for an individual human review, with separately active service entitlement and mentor assignment. Do not generate AI grading, a mentor queue for Core learners or an essay upload/self-check prerequisite.
- 2026–2028 Economics 9708 syllabus v2: https://www.cambridgeinternational.org/Images/697423-2026-2028-syllabus.pdf. Economics has objective multiple-choice P1/P3 and written P2/P4; the latter are externally assessed by Cambridge in the real exams, **not app-assessed** in iClub. P2 and P4 have 20-mark Section A and two 20-mark essay sections. AO1/AO2/AO3 are examination assessment objectives, not automatic iClub marks.

## Evidence performed on live Supabase (read-only)
Repeatable query: `scripts/qa-exam-prep-written-lab-no-grading-readonly.sql` runs within `BEGIN TRANSACTION READ ONLY ... ROLLBACK`. Checked 22 exact editorial versions, 22 private assessment-criteria allocations, 20 Section A maximum marks each for P2 and P4, and written plan steps with **no grade, marks_awarded, is_correct or mastery columns**. Checked Chemistry independent P3/P5 lab-delivery switches OFF and both public lab-catalog/lesson functions STABLE (not database-writing). Neither anon criteria EXECUTE nor direct authenticated private mark scheme SELECT is permitted.

At this checkpoint: Economics written plans 1, 12 ordered items, 3 advanced and 1 historically joined beta user. Chemistry J13 practical-card releases 0; active Maths version 1. No subject selection, sessions, plan, attempts, answers, grades, access, localStorage, Tours or Practice changed.

## Frontend evidence and permanent guard
Added `scripts/qa-exam-prep-written-lab-no-grading-v1.cjs` with explicit invariants against essay submission/auto-grading in Economics Core, against Chemistry practical-skills marks/mastery, and against unauthorised task criteria disclosures. Validates RU/UZ/EN wording, correct Chemistry P3/P5 independent access flags, and protected Written Core Next/idempotence. `.github/workflows/exam-prep-non-grading-boundary.yml` runs it on relevant PRs/main changes alongside the older written policy/controller and Chemistry lab response checks.

**Legacy Mathematics distinction:** `exam-prep/exam-prep-live.js` still contains a separate learner-entered **timed self-mark** flow. It is not an automatic iClub essay grade and is outside this change. Do **not** silently delete or rewrite this existing product behavior or user history. If the architect later disallows manual self-report as well, that is a separate approved scope and migration audit.

## Limits / remaining acceptance
- This QA does not impersonate a live student or run a real, signed-in smartphone session. Screenshots and current user study progress must be checked by an eligible learner with genuine consent/permissions; do not create fake accounts, scores or grades.
- Published beta content remains a **subset of 12** of the 22 reviewed written task versions; remaining 10 are held OFF. No full syllabus or official Cambridge mark-scheme status is claimed. Internal mark allocations for author-created exercises are Cambridge-aligned instructional maxima, not officially published per-question exam marks.
- Final sign-off requires physical mobile RU/UZ/EN screenshots, first/end/return-to-task navigation, save/resume after reopen, owner/non-owner boundary, and at least two distinct real users completing authorised exercises before expanding release. Current per-paper access remains untouched.
- P1/P3 MCQ deterministic auto marking is **permitted** where correct answer and server-owned session truth are valid. Chemistry Entry/Recheck/P1 deterministic questions are separate from the LAB practical card route.
- The open issue from older docs about generic Maths open recruitment and feature flags is outside this QA. Avoid changing Maths access settings while 6 historic session accounts may depend on the current gates.

**Change scope:** additive QA script, read-only SQL audit and CI policy; no application UI, Supabase migrations or production configuration modified.
