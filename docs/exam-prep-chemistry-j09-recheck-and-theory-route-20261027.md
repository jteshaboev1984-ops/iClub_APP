# iClub Chemistry 9701 — J-09: unseen rechecks and exact lesson access (27.10.2026)

**Status:** completed as unreleased development work; Chemistry program, entry access, P1 and Chemistry subject library all remain **OFF**. The existing working branch `work/chemistry-9701-j02-auth-host-20261026` was reused. No new branch, no PR, no merge, no Vercel production deployment.

## 1. Original independent follow-up/recheck bank

- Created **22 fresh trilingual original AS recheck MCQs**, one per official syllabus unit 1–22; every question has four options, one private answer key, EN/RU/UZ explanations and an explicit skill mapping.
- **These 22 are different from J-07's 22 original entry-check questions and the 45 original private P1 drafts.** Exact English stem intersection is zero with both banks and within the recheck bank. There are skill/topic overlaps where necessary, but different academic stems and contexts; **not** a claim that they measure a statistically independent skill or mastery.
- The bank, all answers/options/explanations and history of editorial corrections remain entirely in **private Supabase**, not public GitHub, including historical Git commits. Public migrations contain only schema, security, gates and preflight metadata.
- First academic map review exposed a genuine problem: the original Group 2 flame-colour item did not have an explicit learning outcome in the project's official 9701 source map. It was replaced with an in-syllabus Group 2 chemical-reaction item. Nine additional handwritten syllabus-point references were brought into exact agreement with `private.iclub_exam_core_skills_v1`. **All ten superseded original manuscripts have been preserved privately** in `private.iclub_exam_chemistry_recheck_revisions_v1`, not destroyed.
- Final private source scan: **22/22 units**, zero canonical syllabus-point mismatches, zero non-AS/out-of-scope skill rows, zero duplicate English stems against the existing source banks, 4 distinct options and explanations in all three languages.
- **154/154 internal AI review gates** (seven per item) recorded with exact content hashes: syllabus scope, correct-answer/scientific reasoning, distractor quality, EN/RU/UZ, independence from prior wording. No outside reviewer or certification. **All recheck release/mastery flags permanently false** at the source table by CHECK constraints. This is a small *form* of 22 new topics, not yet reliable evidence of mastery.
- J-09 creates **no learner-facing recheck or retest endpoint**. No new personal attempts, no grading, no progress or retest achievements are generated. Delivery and later recheck interpretation are explicitly reserved for J-10.

## 2. Safe, exact Theory lesson route in the shared Entry UI

- Added `public.iclub_exam_chemistry_entry_lesson_v1(session_id,skill_key,language)`. It requires a live authenticated Chemistry/Maths-beta-eligible account, separate consent/owner GO, ownership of a **finalized** entry attempt, a skill included in that attempt, and **the exact Chemistry library version actively published and visible to learners**. Invalid, foreign, unfinished and hidden library access fails closed.
- The RPC returns only `title`, the source `explanation`, exact `skill_key`, `syllabus_point` and `tour_number`. It returns **no AI Tutor explanation, hidden book sections, private keys or scores/mastery credit**.
- Modified the existing `public.iclub_exam_chemistry_entry_review_v1` so every topic indicates `lesson_available` **only when the matching exact version of the Chemistry Theory is actually visible**. Closed library = no per-topic lesson button. It is not a client-side guess about availability.
- Updated `exam-prep/exam-prep-chemistry-entry-native.js`: contextual **«Изучить тему» / «Mavzuni o‘rganish» / «Study topic»** buttons for eligible topics; opens a read-only in-host Theory card with plain `textContent`, suitable long-line wrapping and back to the exact list. Hidden/unavailable lessons show a safe localized message, not a link that bypasses content gating.
- **This is direct skill-specific Theory rendering**, not a deep link into the existing Tours player or Video Lessons. Those interfaces have different navigation and release contracts; neither was guessed or modified. Chemistry library's `active_version` is currently NULL and `visible_to_learners=false`, so no learner is currently shown these buttons.
- Supabase lesson/read logic is saved to the matching GitHub migration `20261027121929_chemistry_9701_j09_exact_theory_route_only_when_visible_v1.sql`, reconstructed from the live applied function definitions and confirmed with exact permissions.

## 3. Tests and safety

- Tested the authenticated server path with an **existing eligible Mathematics beta account identity simulated inside BEGIN/ROLLBACK**, not a real browser sign-in. Before finalize, Theory blocked; after finalize, library still hidden → `lesson_not_released`, zero lesson buttons. Briefly setting the Chemistry library's `visible_to_learners=true` and exact `active_version` **inside the uncommitted SQL transaction only** returned the correct Theory for the requested skill, with no AI Tutor and no mastery. A skill absent from the test was blocked. All temporary release and visibility changes rolled back.
- Repeatable synthetic JS `node scripts/qa-chemistry-9701-j09-lesson-ui.cjs`: **16/16 scenarios**. Previous J08 Entry UI regression still **11/11**, plus 13 source/scope checks: all pass. Real browser desktop/mobile acceptance still outstanding.
- Repeatable production read-only SQL `scripts/qa-chemistry-9701-j09-recheck-lessons-readonly.sql`: **36/36**. No real Entry/P1 Chemistry attempts, no synthetic leftover, no release approvals/consents, Chemistry Core Draft/OFF and library hidden with NULL active version.
- Mathematics **544 sessions, 1,979 answers**; Practice **502 attempts, 4,816 answers**; Economics **one existing native attempt**; user subject selections at least **2,098**. Original 26 older private Chemistry variants, 45 P1 private originals and 40+4 current P1 draft blueprint preserved. No `public.questions`, Tours progress, localStorage, or active end-user grades modified.

## J-10 precise next steps, without GO

1. Design a **distinct, account-owned, owner-released recheck engine** using the 22 **unseen** items. It must link post-learning evidence to the prior Entry result without presenting a second attempt of known answers, and must not credit mastery from one new question. Must require another exact manifest and consent/eligibility.
2. Add a controlled recheck UI in the same shared Host only after the owner gate and exact item audit; verify timeouts, resumption, answers/explanations, user privacy and continued separation from Mathematics, Economics and Practice.
3. Decide how/when the separate Chemistry Theory package will be validated and published. It currently remains **not learner-visible**; lesson buttons must stay hidden until that release.
4. Real end-to-end desktop/mobile testing with an actual consenting beta participant and visual/accessibility checks, followed by owner GO before touching `main` or Vercel. Synchronize the working branch against newer unrelated `main` commits without reverting production improvements.
5. Keep P2/P3/P4/P5 independent. Lab/written components are not tested by these 22 multiple-choice questions.

**No user-facing Chemistry launch was made during J-09.**
