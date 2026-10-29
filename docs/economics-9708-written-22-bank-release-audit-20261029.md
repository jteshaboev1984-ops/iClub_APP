# Economics 9708 P2/P4 — ten held written tasks: academic QA and controlled beta expansion
Date: 29 October 2026. Architect authorised reviewing and releasing the remaining 10 tasks **if needed**. The release is limited to the previously authorised Economics written beta population; no change to general/public access.

## Necessity of the ten held tasks
These are **not duplicates**: the original 12-task beta presented only a selection of the four-section alternatives. The ten held tasks complete the first version of the iClub written practice bank:
- Paper 2 (six): `P2.B1.b` (subsidy vs maximum price, 12 marks); `P2.B2.a` (XED substitutes/complements, 8); `P2.B2.b` (tax revenue limits of PED, 12); `P2.C1.b` (supply-side vs fiscal spending, 12); `P2.C2.a` (current-account deficit causes, 8); `P2.C2.b` (currency depreciation evaluation, 12).
- Paper 4 (four): `P4.A.b` (expenditure switching vs reducing, 4); `P4.A.d` (vocational training vs FX-market intervention, 6); `P4.B2` (negative production externality / policy, 20); `P4.C2` (GDP per head as development indicator, 20).

## Academic source and review
Official Cambridge International AS & A Level Economics 9708 syllabus v2, 2026–2028: https://www.cambridgeinternational.org/Images/697423-2026-2028-syllabus.pdf, assessment overview and pp 35–36. P2 has Section A approximately six linked source parts (20 marks), Section B/C one chosen essay from a pair of structured two-part questions (20 marks each). P4 has a four-part compulsory source question (20 marks) and unstructured alternative B/C essays (20 marks each). All released tasks are original iClub **practice**, not official Cambridge paper questions or their authentic mark schemes; offering both essay alternatives sequentially is **practice**, not a 60-mark timed exam simulation.

Production verification before release:
- Reviewed content version `economics_9708_written_editorial_candidate_v3_20261027`, **22/22** academic/language/source approved, EN/RU/UZ question and response-standard fields; 10 held, 12 previously released.
- The **ten distinct held prompts** were examined for syllabus level, economic causality, expected response, translations and non-duplication. Concepts and mark maxima are coherent; no unverified academic corrections to historic data are made as part of access expansion.
- All 22 private assessment scheme hashes match the corresponding approved task content; mark allocations add up (`max_marks = AO1+AO2 + AO3`). Paper 2/4 Section A respectively sum to 20.
- Two source cards (fictional Isara and Nerava), all ten Section A source bindings, released/approved in all locales; `private.iclub_exam_written_source_ready_v1` true for **22/22** tasks.
- Safe `public.iclub_exam_written_criteria_v1` exposes only the rubric/AO exam criteria, **never** private example answers, calculations or solution points. No automatic essay grading, score or mastery and no lab work grading.

## Data migration and user protection
`supabase/migrations/20261029121518_iclub_economics_written_complete_22_beta_v1.sql` is narrow:
1. Assert release approval for exactly the 10 held tasks and 22 total, locale/source/security gates and original 12-task release state. Flip the **ten exact** `release_enabled` booleans.
2. For an existing active written plan, **append ten additional pending tasks** after the existing 12, preserving original order, tokens, statuses, nonces, timestamps and all advance history. A prior learner never loses the current next task or repeats one merely because an expansion was installed. Historical withdrawn/archived plans remain unchanged.
3. Replace `iclub_econ_written_start_v2()` with the same checked auth/eligibility/current 3-seat beta/validity controls, now inserting a complete **22-step P2→P4** plan for new eligible learners. No extra consent button/row and no public enrolment.
4. Keep task source versions/hashes, owner-only session access, all other subjects, historical MCQ, Practice/Tours, localStorage and Mentors unchanged.

### Rollback verification
Live PostgreSQL `BEGIN … ROLLBACK` trial compiled the migration, preserved three existing advanced steps, verified existing owner start replay/idempotence, and exercised **all 19 remaining tasks in sequence** (including the ten held items), with explicit criteria in EN/RU/UZ and an expected owner-only access denial. A completed 22-step plan returned a completed status in the rollback-only trial. Real production progress was not advanced by these simulated actions.

## Release boundary and aftercare
The architect's acceptance of current Economics UI stands. This only expands the **question bank** within that UI; it does not turn Economics into a public/full-syllabus Cambridge examination product. The 3-seat controlled beta limit remains, and older 22 English-only drafts remain unavailable. Further full-syllabus coverage or timed Paper 2/Paper 4 authentic option-choice mocks require separately approved work and qualified academic review.

**The migration must be applied only after CI passes.** Once actually applied, append final migration ledger, production counts and test result in the working plan. Never rewrite completed learner steps or reopen archived users automatically.
