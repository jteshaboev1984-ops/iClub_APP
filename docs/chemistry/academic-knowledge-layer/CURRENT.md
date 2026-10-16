# Chemistry 9701 — Academic Knowledge Layer v5 / stable current package

**Date:** 2026-10-16. **State:** DRAFT / NOT APPROVED / NOT RUNTIME. **No Supabase, learner data, repository main or Vercel change.**

## Product role
The same principle as Mathematics Exam Prep: skill-centred original academic theory, then learner-first AI Tutor explanations, then only validated question↔skill mappings. Multiple-choice success alone does not establish laboratory proficiency.

## Content currently in this package
- 166 unique iClub editorial skill families (165 carried intact from v4 and **1 added** for C60 fullerene, Cambridge Chemistry 9701 §4.2.1(b)).
- 498 theory cards (EN/RU/UZ, one per skill per locale), 498 four-field Tutor cards; **996 authored records**.
- 58 previously ambiguous fallback links retained and explicitly reviewed at English-stem level; **#8546 now candidate-mapped to CHEM9701-04-05**, with no mastery permission. The 572 other links are still heuristic and require per-question academic approval. The existing 630-row candidate mapping lives in the already established GitHub QA branch; v5 is not claiming those mappings certified.
- 14 separately verified official subsection relationships, **not a complete post-by-post syllabus crosswalk** for 166 families. No false claim of full Cambridge 9701 academic signoff.

## Specific academic correction in v5
Syllabus §4.2.1(b) includes buckminsterfullerene C60 among *simple molecular* solids. The new EN/RU/UZ material distinguishes strong covalent bonds **within** individual cages and weaker forces **between** molecules. One cage contains 60 vertices, 90 edges, 12 pentagonal and 20 hexagonal faces (the numerical face count is editorial enrichment; it is not individually specified as mandatory by the syllabus). This repairs a genuine gap underlying active question #8546, which asks about 12 pentagonal rings.

## QA and limits
- All structural/hashing checks in `07_OBJECTIVE_QA_v5.json` passed. Every card content hash re-computed from exact stored text; every tutor points to its theory card in the correct language. No card is runtime-allowed.
- Cyrillic/Latin script and content-length checks are **indicators only**, not guarantees of semantic translation or high-quality alternative teaching explanations. Refer to `07_OBJECTIVE_QA_v5.json` for the number of short alternative explanations requiring editorial attention. Those flags are not resolved by automatically lengthening text.
- Full official learning outcome-by-outcome crosswalk, science/editorial read-through for each of the 996 language-specific texts, all 630 live question options and secondary-skill mapping, and learner Preview/E2E **remain OPEN**.
- The mathematics `private.exam_prep_*` runtime tables are untouched and not appropriate Chemistry targets. No generation permission has been granted to Chemistry.

## Safe release workflow (future, not executed)
1. Finish original-Cambridge outcome mapping, reject or label enrichment.
2. Confirm EN/RU/UZ academic meaning and distinct learner-first Tutor modalities.
3. Confirm per-question active ID/source hash/option/answer and primary/secondary skill role for each of 630 questions; exclude unreviewed rows from diagnostic results.
4. Stage Chemistry-only additively, test private answer-key confidentiality and learner Preview, then obtain a separate user-authorised release decision.

## Library hygiene
All v1/v2/v3 temporary packages and reports for this Knowledge Layer have been deleted from the iClub Library. This v5 archive is the sole current comprehensive package; v4 was retained only until the new archive was verified, then removed. Underlying content evolution remains auditable via immutable card keys and existing GitHub QA notes. We do not save repeated transient snapshots to the Library.

**Authority:** Cambridge International AS & A Level Chemistry 9701 2025–2027 V1, `https://www.cambridgeinternational.org/Images/664563-2025-2027-syllabus.pdf`; Chemistry Tour Map v1.0 and Lawrie/Ryan/Norris Chemistry Coursebook 3e (for curricular organisation and explanations, not republished textbook copy).