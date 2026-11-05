# Mathematics P1/P5 D10-07 — two verified integration competency gaps

**2026-11-05 · Issue #450 · architect-controlled DRAFT.**
Base: D10-06 verified [PR #490](https://github.com/jteshaboev1984-ops/iClub_APP/pull/490), exact 71/71; no current production implementation.

## Actual academic evidence, not just source-section counts

Source: [official Cambridge 9709 syllabus for examinations 2026–2027, §1.8, printed p.22](https://www.cambridgeinternational.org/Images/697427-2026-2027-syllabus.pdf#page=22). The syllabus explicitly includes (a) simple improper integrals with an **infinite upper bound**, and (b) volumes of revolution about a coordinate axis when the rotated region **does not touch that axis**, such as regions between curves. The project-supplied textbook *Complete Pure Mathematics 1*, chapter 10, printed pp.173–200, remains the source for integration technique.

Only **read-only** queries were made against live content. For each of existing canonical `P1-INT-03` and `P1-INT-05`, the bank contains **6 published + 9 protected reserve objective items**. The English prompts inspected, across *all 15 per skill*, contain **no infinite-upper-bound integral** for `P1-INT-03`, and **no non-axis-bounded two-curve volume** for `P1-INT-05`. The existing *published written* tasks for both skills were inspected separately; these two corresponding capabilities were likewise not exercised there. This is specifically a **coverage gap**, not an assertion that existing content or answer keys are incorrect. No existing objective or written item was removed, replaced, republished or edited.

## Changes made to the source contract

- Additive compare-and-set migration updates **only two canonical descriptions** under the same existing program version/skill codes, without changing the 81-row keys or any user, mastery, progress, score, question, answer, reserve or saved date.
- Original 81-skill JSON review pack and Russian learner-facing descriptions reflect both authentic syllabus cases. Existing complete RU/UZ/EN titles are unchanged.
- Learner-view asset version and corresponding existing source-pinned test are updated **together**, preventing old cached academic descriptions. No new user-facing screens, quiz restrictions, study-hour model, readiness requirement or calendar/learning access cap.
- Extend the existing original 81-skill academic source guard with both expected descriptions and regression counterexamples.
- Add isolated PostgreSQL 17 read-only verification of the two exact descriptions, 45+36 skill IDs, original 6-published/9-reserve status per skill, and written source preservation.

## Original new questions prepared privately, not deployed

A private downloaded ZIP `iClub_P1_INT03_INT05_Private_Supplements_20261105.zip`, SHA256 `3019e0510cff472baba292dff3e145a110c349dcc3526953b973d2093321a568`, contains **12 original standard objective + 4 original ungraded written** P1 integration supplements across these two gaps (6+2 for each). Each includes RU/UZ/EN prompts and explanations/solutions, source and learning objectives, exact checked SymPy integral/limit metadata. A **second independent archive parse/verification** checked all 16 exact integrals, four answer choices per MCQ, correct letters, unique task keys, all 3 languages, and written non-self-grading status. For annular-volume tasks the integrands are nonnegative across the stated intervals.

This separate ZIP does not contain any of the architect's 12 original P1/P5 Extra Hard and does not attempt their recreation. It is **not** a production content import, it is not published, and it creates **no** learner access or additional release blocker. Answers and solutions are not committed to public GitHub. No other subjects, Tours, Practice, certificates, personalized planning, 4-year date window, or localStorage modified.

## Release boundary

Draft PR and isolated CI are technical checks only. **No merge, no production Supabase write, no Vercel deployment, no user data reset** without separate architect instruction. Independent content reviewer approval has not been claimed.
