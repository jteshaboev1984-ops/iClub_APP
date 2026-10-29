# Chemistry 9701 J23 — internal two-pass QA protocol (no external reviewer)
Date: 2026-10-29
Status: **CLOSED, not authorised for student release**

## Responsibility and evidentiary limits
The project architect delegated science, editorial, EN/RU/UZ, content-source checking and technical QA to the assistant because no independent external expert is available. **No independent human expert approval is claimed.** Repeated reviews by the same assistant are still internal reviews, not independent certification. The user is not expected to review source code.

An internal QA result may be documented as `AI_SELF_REVIEW_PASS` only for the particular checks actually performed. It must not be converted silently to an academic signoff, copyright permission, official Cambridge endorsement, content publication, learner-enrolment permission, or backup/restore evidence.

## QA method
1. **Science pass:** Read the candidate English question and keyed answer for every AS skill; check calculations, oxidation states, molecular structures, conditions, products, and whether the question actually tests what the supplied answer explains. Resolve each confirmed defect by append-only closed edition, never edit live/legacy content. Compare the syllabus scope with the *official* Cambridge 9701 2025–2027 specification and the attached Lawrie/Ryan/Norris chemistry coursebook when relevant.
2. **Language pass:** Verify critical concepts and scientific quantities across EN/RU/UZ, including formulae, units, signs, concentration values and whether a question leaks its own answer. Check the assistant-authored questions and previously corrected locales directly; record any residual untranslated/omitted or ambiguous wording. A numerical scan is not, by itself, evidence of complete linguistic equivalence.
3. **Technical pass:** Validate 91 unique Theory keys, six non-empty fields in all 273 locales, 273 unique Tutor references, exact canonical source digests, exact Theory/Tutor bundle SHA-256, private-schema RLS/no role access, immutable 154 historical rows, correct treatment of enrichment-only topic 10-04 and closed J24/J25 controls. Test the actual Python packager on safe synthetic input; run the **same packager against exact private v5 byte files** only once the protected export path is verified.
4. **Safe restoration:** The public GitHub repo holds SQL structure and metadata, not secret Chemistry questions or answers. A demonstrably restorable private authoring seed/back-up is mandatory before a release migration or any main merge. Never rely on the public PR as a backup of private authored content.

## Passes actually completed so far
- English question/answer science and wording review: **91/91** in the assistant's own second pass.
- Previously logged bounded reviews: all 29 newly authored check prompts in three languages and eight rewritten self-checks in three languages. Those passes did not certify every Tutor paragraph.
- A second wording pass identified six further ambiguous or answer-revealing self-checks (07-02, 07-05, 08-02, 11-02, 19-02, 19-03). They were reworded in all EN/RU/UZ variants, **18 locale question changes**, and their existing science answers were left unchanged.
- The numeric EN/RU/UZ cross-check covered **91/91** skills. Differences were traced to number words, an optional example and wording scope; no incorrect numeric result established by the scan. This is an algorithmic check, not full semantic proof.
- Earlier v4 repairs changed four prompts in three other skills. v5 retains v4, overwrites none of its original rows and keeps all 154 historical Theory entries intact.
- Official Cambridge syllabus 2025–2027, section 7.2, specifically includes pH titration-curve sketches and indicator selection at AS. Reference: https://www.cambridgeinternational.org/Images/664563-2025-2027-syllabus.pdf , printed page 24.
- Additional item CHEM9701-10-04 remains **NON-creditable enrichment**: `syllabus_point=NO_EXPLICIT_9701_OUTCOME`. Existing J24 server catalogue uses `syllabus_point NOT LIKE '%NO_EXPLICIT%'` to distinguish outcomes, and returns `can_credit_mastery=false`.

## Current protected candidate v5
- Version: `chemistry9701_j23_20261029_as_91_sixfield_candidate_v5`
- Source store: `private.iclub_exam_chemistry_j23_as_source_bundle_v1`
- 91 Theory cards, 273 EN/RU/UZ Tutor locale links.
- v4 to v5 changes: 6 cards, exactly 18 question locale fields; **all 273 check answers unchanged**; 85 cards identical.
- Package SHA-256: `be3e9c84398984f4f0812ae97f29ffe35a8c5a86a28542a7c027eefc64b45c2f`
- All stored card digest and Tutor-pointer checks passed; J24 `enabled=false`, J25 `audience_mode=closed`.

## Still to complete without an external expert
- A deliberate remaining semantic RU/UZ and Tutor body pass, with fixes in new private versions if needed.
- Exact-byte export of protected Theory and Tutor, actual local Python packager run and comparison to the authoritative SHA-256.
- Secured private content seed backup + tested restore, so the publicly committed migrations can be replayed in a clean environment without loss.
- Documented rights/source-originality screening and an explicit **architect-controlled** release decision. Assistant quality review is neither a legal licence nor an official Cambridge endorsement.

**Release policy:** no Chemistry beta invitations/consent. Continue safely in Draft PR #397, OFF/CLOSED, without touching pupils, scores, Tours, Practice, Mathematics, Economics, AI or local progress.

## Latest automated Tutor/number second-pass evidence
- V5 91-skill trilingual numerical scan: the only RU question digit mismatch is the equivalent written-out Russian ordinal “third Period”; answer-number differences concern equivalent written-out numerals (05-03), Russian written-out Period 3 and Group 2 (09-04, 10-02), or an optional propan-2-ol example present only in EN (16-02). **No confirmed numeric science contradiction**. The remaining EN-only example is a minor explanation-parity difference, not a calculation defect. This check is numeric, not a claim of complete translation certification.
- 273 Tutor locale records × five required text fields = **1,365 Tutor fields** checked; 0 blank fields, 0 common-word cross-language leakage flags (untranslated Uzbek words in RU, Russian instructions in UZ/EN).
- The exact GitHub read-only SQL verifier `supabase/tests/chemistry_j23_v5_bundle_readonly.sql` was run against closed Supabase v5: Theory=91, Tutor=273 and exact Theory/Tutor/combined SHA-256 booleans all true.
- The **actual Python packager** still has not been run against the 1.4MB protected source bytes. The Python test file in GitHub is synthetic-only and has not yielded a verified CI job run; do not conflate those two checks.
- All original source, previous candidate versions and learner progress remain untouched; RLS private tables retain no anon/authenticated read grants.

## J24 read-only upgrade compatibility preflight
A read-only join of the **closed v5** candidate with `private.iclub_exam_core_skills_v1` (Chemistry 9701, AS, current curriculum version) found exactly 91/91 matching skill keys, 0 tour-number mismatches, 0 syllabus-point mismatches and 1 correctly labelled enrichment-only item. All 91 v5 content hashes differ from original hash values as required for new six-field lessons. This is **compatibility evidence**, not a new core-skills version or J24 activation. Avoid simply switching a hard-coded release version without atomically reconciling Theory, Tutor and skill-hash pointers. J24 remains disabled, J25 closed.
