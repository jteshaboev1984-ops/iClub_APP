# iClub Chemistry 9701 — Academic Knowledge Layer v3: content-complete draft

**Prepared:** 2026-10-16. **Release status:** `DRAFT / NOT INSTALLED / RUNTIME DISABLED`.

## Consolidated scope

- **152 / 152** internal iClub skill definitions have authored theory and Tutor-card records on **EN, RU and UZ**.
- **456 theory source cards** and **456 Tutor cards**, 912 learner-language entries in total.
- v2's **69 skill families / 414 records** retained without changes to their underlying card dictionaries. New v3 contributes **83 families / 498 records**.
- **37 numbered theoretical syllabus-topic groups** plus **12 cross-tour practical skills** are represented by the editorial taxonomy. This is *not* an official outcome-by-outcome signed compliance certificate.
- **630 live question IDs** have a separate **heuristic candidate map** in the `chemistry-academic-audit` GitHub branch; **no question mappings are promoted or used to infer mastery**.

## Content construction

Each drafted theory card contains a focused chemical rule, worked example or reaction, and a misconception check. Each Tutor card has four populated fields (`main`, `simple`, `alternative`, `focus`). For new v3 entries, the `alternative` field presents the worked example first and then the underlying rule; **it is an editorial draft, not proof of meaningfully different adaptive tutoring strategies**. More demanding Tutor pedagogy QA is still needed.

Across 83 new families, the coverage includes Period 3/Group 2/17 and nitrogen/sulfur chemistry, organic mechanisms and identification, advanced electrochemistry/thermodynamics/kinetics, spectroscopy, synthesis and supervised experimental method. Original chemistry explanation wording is used; no textbook paragraphs are copied.

## Checks and important caveats

- Structural/locale/referential/content-hash/permission checks: **26/26 PASS**.
- Targeted independent chemical arithmetic assertions: **18/18 PASS**. Includes isotope weighted mean, calorimetry, electrolysis, Faraday/Avogadro calculation, cell potentials, Gibbs energy, weak-acid pH, Ksp, distribution coefficient and half-life.
- Preview JavaScript syntax and HTML payload validated offline. **Chromium did not complete visual rendering** in the available runtime, so screenshots/real browser QA are **not claimed**.
- RU/UZ text presence and writing-system gate checked, and one LAB-04 RU/UZ column inversion repaired before packaging. **Full bilingual semantic and terminology review has not been completed**. AI self-review is not external expert approval.
- 152 skill names/definitions are iClub editorial breakdowns. The `official_outcome_subcode=NOT_YET_LINE_BY_LINE_VERIFIED` status must not be cleared without the official section-by-section syllabus crosswalk.
- The current 630 question-to-skill mapping is *not* safe to drive progress, tutoring or diagnosis: prior provisional mapping had 522 stem matches, 50 metadata matches and 58 unmatched fallback assignments; these counts are heuristic.
- Practical competence cannot be certified solely by MCQ/input; real supervised evidence is needed.

## Installation safeguards

No production Supabase tables, question banks, scores, localStorage, learner records, GitHub main, Vercel or AI readiness flags were modified during v3 preparation. Content may first enter a **separate restricted draft staging store**, then pass syllabus/locale/scientific/UX gates and an explicit additive runtime release decision. Existing mathematics P1/P5 stores must not be re-used as Chemistry program rows.

## Remaining work before enabling the layer

1. Produce authoritative **official learning-outcome crosswalk** for all 152 editorial skills; resolve syllabus-only and book-extension mismatches.
2. Perform full **academic and EN/RU/UZ terminology/meaning editorial acceptance** on all 912 cards; refine Tutor simple/alternative explanations where they are too close to core text.
3. Review each of **630 current question→skill mappings** against question snapshots, including the 58 unmatched cases; add secondary skills only when independently justified.
4. Build **subject-specific read-only/staged integration and Preview E2E**, preserve historical progress, and keep protected Tour answer keys inaccessible to Tutor mid-assessment.
5. Use a separate user-authorised release to mark selected source/tutor entries `approved`, `runtime_allowed`, and any subject readiness changes; do not enable them now.

**Conclusion:** Card *authorship coverage* is 152/152. Academic/runtime *release readiness* is not yet granted.