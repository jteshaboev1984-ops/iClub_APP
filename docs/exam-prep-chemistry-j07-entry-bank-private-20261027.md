# iClub Chemistry 9701 — J-07: independent AS entry check (27.10.2026)

**Status:** implemented and tested as a completely closed, separate **private draft**. **NOT a released student feature**, not an official Cambridge paper, not statistically calibrated. No change to production `main`, Vercel, Maths, Economics, Tours, Practice, localStorage or user history.

**Git branch:** Continue existing `work/chemistry-9701-j02-auth-host-20261026` only. No new branch made. Historical work branches with unique source remain untouched.

## Academic source/meaning

- Source of syllabus boundaries: official <https://www.cambridgeinternational.org/Images/664563-2025-2027-syllabus.pdf>; internal existing `private.iclub_exam_core_skills_v1` and 22-unit 9701 map.
- Created **22 new original MCQs** (one per AS unit 1–22), each EN/RU/UZ with four independent answer options, correct key and explanatory note. Entire bodies/options/answer keys reside **only in private Supabase**; the public GitHub branch contains database DDL, metadata review and QA scripts **without questions, keys or academic item content**.
- Each item uses a **different mapped skill than the existing fixed 40-question Paper 1 editorial blueprint**, and no exact English stem duplicates any of the 45 privately drafted P1 originals. Skill and exact-text divergence does *not* mathematically prove semantic independence or exam calibration; internal academic review addressed this conservatively.
- The 22 questions comprise a **short orientation/entry screen**, expected approximately 30 minutes in the technical harness; each topic has **one item only**. This cannot justify a stable mastered/not-mastered verdict, accurate readiness percentage, target Cambridge grade or automatic placement. Any actual student UI must state that limitation.
- **No external experts**, according to owner's instruction. Performed own internal chemistry, math, distractor, English/Russian/Uzbek translation, format and distinct-source checks. All **154/154 metadata QA gates** recorded as `internal_ai_pass` with `reviewer_type=internal_ai` and pinned item MD5. **No human/external endorsement or release approval.** 22 source rows remain `can_issue_learner=false`, `can_grade_mastery=false`, `can_be_p1_paper=false` by CHECK; all 22 stay private.
- Found exact **22/22 links** from entry skills to the existing trilingual Theory + Tutor content (metadata-only, no theory content exposed). The matching internal `Tour Map` is not assumed identical to official syllabus topic numbering; original syllabus/skill keys are authoritative.

## DB assets (all additive, private, unreleased)

1. `private.iclub_exam_chemistry_entry_items_v1`: 22 confidential original drafts; FORCE RLS, no user read/grant, forced draft-only status.
2. `private.iclub_exam_chemistry_entry_review_v1`: 7 AI gates per question (154 total), snapshot hashes and reviewer type.
3. `private.iclub_exam_chemistry_entry_preflight_v1`: metadata-only security-invoker QA/difference view; no answer keys.
4. `private.iclub_exam_chemistry_entry_study_links_v1`: metadata-only map to existing 22 theory/tutor skills with RU/UZ/EN availability; no study text.
5. `private.iclub_exam_chemistry_entry_shadow_v1` plus four private **service-role-only** RPCs `..._shadow_start_v1(text)`, `..._shadow_get_v1(uuid,text)`, `..._shadow_answer_v1(uuid,integer,integer)`, `..._shadow_finish_v1(uuid)`. These accept only synthetic QA sessions (fixed technical owner) and are **deliberately callable only while Chemistry remains Draft/OFF**. No authenticated learner API or UI was created. They cannot award mastery or real P1 credit.
6. Migration files recorded with the **actual** applied Supabase version numbers in the current working branch. All schema scripts are metadata/structure only; SQL that creates confidential questions was executed directly in privileged private Supabase, never committed to public Git.

## Proof and scope

- Private integrity: 22 rows, **one per 22 syllabus units**, 154 AI-review slots, 22 current hash-pinned seven-gate results, 0 selected P1 skill overlaps, 0 exact English duplicate stems in all existing 45 P1 originals, 22 trilingual theory + tutor links.
- Transactional **ROLLBACK** technical workflow: start 22 items; idempotent restart; RU/UZ/EN questions; no correct answer/explanation before finish; 21 answers submitted (one wrong, one skipped), server result **20/22**, correct review explanations after finish; second finish idempotent and later answer blocked. A second ROLLBACK scenario verified expiry: late save rejected, 0/22 finalised correctly and finish replay immutable.
- Read-only regression: `scripts/qa-chemistry-9701-j07-private-entry-readonly.sql` **31/31 PASS**. Chemistry beta/program remain OFF, no consent or real/synthetic attempts remain. Earlier 26 original variants and 45 P1 drafts intact; Math/Practice/Economics baselines preserved.
- Supabase security advisor returns 3 **INFO** `rls_enabled_no_policy` findings on the three intentionally inaccessible private J07 tables. All have **FORCE RLS** with student table permissions and EXECUTE on private QA functions revoked. Not production-exposed.

## Honest remaining J-08 steps

- Design and implement separate **authenticated, account-owned entry session transport** and gated UI in the existing shared Exam Prep Host, distinct from P1. Review consent/owner release terms; **do not reuse service-only shadow sessions** for real learners.
- Add independent unseen follow-up items per skill/topic for recheck, not a repeated memorized diagnostic or Paper 1 item. Currently 22 one-per-unit entries are insufficient for trustworthy subtopic-level judgment.
- Map safe learner-facing RU/UZ/EN entry results to the existing syllabus-linked Theory/Tutor journey, explain errors and offer later independent retests; never claim mastery based on one answer. P2/3/4/5 remain distinct.
- Full visual browser/device walkthrough, real consenting learner acceptance, security/rollback test, explicit owner GO. **Do not launch or publish automatically.**
