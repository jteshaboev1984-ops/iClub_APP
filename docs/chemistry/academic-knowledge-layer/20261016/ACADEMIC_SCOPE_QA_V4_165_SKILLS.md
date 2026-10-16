# Chemistry 9701 Knowledge Layer — academic scope remediation v4

**Date:** 2026-10-16. **Release:** DRAFT; not installed in Supabase; runtime NOT enabled.

## Grounded finding

The v3 bundle's 152 authored skill families were *not* equivalent to coverage of every official Cambridge 9701 learning outcome. In the **2025–2027 V1 syllabus** (URL below), specifically unrepresented or materially thin outcomes were identified in sections 26.2, 27.1, 28.1/28.2/28.3/28.4/28.5, 29.3/29.4, 33.1, 37.1/37.2/37.4. These were not fixed by claiming a generic 'Analytical techniques' card covered all of chromatography.

New v4 content: **13 missing / underrepresented skills**, each with original EN/RU/UZ theory and Tutor cards (78 new records). Existing v3 had 152 skills/912 cards, v4 has **165 skills, 495 theory and 495 Tutor = 990 card records**. The RU content wrongly containing Uzbek in `CHEM9701-26-04` was corrected in both Russian theory and Tutor. An additional integrity defect was discovered: **84 v2 theory and 84 v2 Tutor hashes were stale**, despite the older QA claiming an all-hash PASS. Those 168 records now have corrected SHA256 and `draft-v4` immutable keys, with authored body/explanation text unchanged. All other original learning texts remain unchanged.

## Newly covered official requirements

- 26.2 homogeneous and heterogeneous catalytic cycles (adsorption/desorption; regenerated intermediates).
- 27.1 Group 2 hydroxide/sulfate solubility and enthalpy of solution.
- 28.1.2 required sketches of dxy and dz2 orbitals; text supports learning but **hands-on sketch evidence is still necessary**.
- 28.2 geometry and coordination number; 28.3 d-orbital splitting/colour; 28.4 stereoisomerism; 28.5 Kstab expressions/calculations.
- 29.3 sp2/aromatic geometry; 29.4 enantiomers, racemates and chiral pharmaceuticals.
- 33.1 special oxidation of methanoic and ethanedioic acids.
- 37.1 TLC and Rf; 37.2 GLC, retention times and calibrated peak areas; 37.4 NMR TMS/deuterated solvent/D2O exchange.

**Official authority:** https://www.cambridgeinternational.org/Images/664563-2025-2027-syllabus.pdf. Original text is not copied from syllabus/coursebook. `04_OFFICIAL_SUBSECTION_VERIFIED_13.csv` identifies independently matched syllabus subsections; it is not a signed full outcome crosswalk for all 165 skills.

## QA truthfulness

- 24/24 targeted structural, **recomputed SHA256**, authority and small arithmetic checks PASS. Previous v3 hash PASS was inaccurate for 168 items; v4 explicitly corrects this.
- The card count reflects **authored draft records, not 100% syllabus certification**. Original 152 skills still require official outcome-by-outcome verification, including omissions not detected by this targeted pass (see C60 §4.2 finding).
- Both theory and Tutor text EN/RU/UZ require further full editorial review; text labels and Cyrillic-presence checks are not equivalent to semantic translation review.
- Existing 630 question mapping remains a separate heuristic, with 522 stem matches, 50 metadata matches and 58 unmatched fallback mappings as recorded in the GitHub QA branch. It has NOT been treated as verified even when a new skill explains a question. **Do not infer mastery from it.**
- Existing learner-facing UI Preview/E2E and integration QA are NOT performed by this text/content audit.
- Chemistry global AI generation and academic runtime permission remain unchanged, disabled.

## Addressed question mapping fallback batch

**58/58 prior `NO_MATCH` fallback questions reviewed** against their live EN stems and topic/subtopic (read-only Supabase). **57 received a plausible, manually selected primary-skill candidate**; all remain unapproved and runtime disabled. Question **#8546** tests C60 fullerene cage geometry, which is explicitly included by syllabus §4.2.1(b) but insufficiently represented by existing content, so it is deliberately **UNMAPPED** rather than falsely credited to giant covalent/metallic bonding. **No learner mastery credit** is issued. The other 572 of 630 heuristic links still need individual academic approval; this batch does not claim 630/630 validated mappings.

## Next release-gates, as one workstream

1. Audit all 165 skills against every relevant numbered outcome; map existing and added skills exactly or mark book-only enrichment, then identify remaining outcome gaps.
2. Review all 990 card texts scientifically and for semantic translation accuracy; ensure Tutor simple/alternative explanations are genuinely differentiated.
3. Reclassify all 630 *live* question IDs one by one with primary+optional secondary skill, retain question-content hashes, and fail closed on unreviewed links.
4. Stage additive Chemistry-only content in protected draft namespace, validate server-side answer-key privacy, run learner Preview and request explicit release authorisation.

## Production safety

No DB/schema, existing 630 question bank, student answers, grades, progress, main or Vercel changes were made. The output includes no production SQL and all cards remain DRAFT/NOT RUNTIME ALLOWED.