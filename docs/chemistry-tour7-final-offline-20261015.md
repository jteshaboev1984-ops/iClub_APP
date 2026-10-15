# Chemistry 9701 — Tour 7 offline completion, 2026-10-15

**Result: final offline authoring complete; no production publication, database change, API call with writes, or student data reset.**

## Verified content
- Tour7: 20 original questions (slots 1–20), EN/RU/UZ questions, options, answer keys and explanations; individual timing; textbook Ch24–30 and 2025–27 syllabus outcome references. Distribution: Ch24=3, Ch25=3, Ch26=2, Ch27=3, Ch28=3, Ch29=3, Ch30=3.
- Format: 16 MCQ / 4 numeric input; difficulty easy=6, medium=9, hard=5; MCQ correct keys A=B=C=D=4. All four inputs have question-specific integer/3-significant-figures grading policies.
- Synthetic routes: slot 19 (ethylbenzene → N-methylbenzamide) and slot 20 (propanal → 2-hydroxybutanoic acid) are genuinely multi-step; slot12 also covers enantioselective pharmaceutical synthesis.
- Practice7: **66 existing KEEP** plus **4 new input replacements** for old IDs 5364, 5366, 5368, 5369, improving technical clarity and variety. No existing question text is altered.
- One-pass scientific checks: eliminated unsupported fac/mer naming, book-only benzene sulfonation, and non-required diastereomer nomenclature. Replaced these with specifically grounded 2025–2027 Cambridge outcomes (optical isomerism of [Ni(en)3]2+, methylbenzene side-chain chlorination, chiral catalyst application). Replaced non-syllabus-focused degree-of-polymerisation arithmetic with repeat-unit ester linkage interpretation.
- Correct numeric keys independently reproduced: Tour 3, 2.95, 3, 226; Practice +3, 2, 4, 2.
- Deterministic offline checks: **1350/1350 passed** after editorial correction.
- Lexical comparison: 24 current candidates against 104 prior Tour3–Tour6 frozen items, 0 high-overlap flags at token-Jaccard≥0.45. Official production Chemistry questions checked by read-only hash-based query for exact duplicate English stems, 0 matches. This is not a complete human semantic-equivalence review.

## Last observed production (read-only, not changed)
- Practice7 `pool_id=24`: 70 active records, 70 MCQ, with complete EN/RU/UZ and no empty question/explanation fields. Four old IDs proposed for replacement have no Tour references and no other Practice-pool references.
- Tour7 Season2 `tour_id=85`: 20 existing old questions, not opened; Season2 status `draft`, no Tour7 attempts.
- New Tour7/Practice7 publication: **0 items imported or activated**.
- Tours1–2 have previously been switched in production. Tour3 remains partially pre-staged (10/33 in private staging) and should be completed by the authorised importer before switching other pending tours. Tours4–6 remain frozen offline.

## Release boundary
Human review of scientific accuracy and RU/UZ/EN wording remains independent of structural tests. No authenticated student answer-save E2E was executed. This package is an offline release candidate, not approval to send announcements, reset Practice results, alter Season1, open Season2 or apply SQL to production.

**Next step:** complete an authorised, idempotent Tour3 release flow; thereafter install Tour4–7 using one controlled migration pipeline with current membership snapshots, scoped grading and postflight. No repeated rewriting of Tour7 content without a demonstrable issue.