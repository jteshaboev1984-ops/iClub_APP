# Mathematics Practice v2 — Practice 3 Coordinate Geometry QA Report

Date: 2026-10-06  
Branch: `work/mathematics-practice-v2-refresh-20261006`  
Scope: `P1-COO-01…P1-COO-06`  
Production data changed: NO

## Status

Practice 3 now has a complete **68-question** draft and has passed the first full bank-level mathematical/mechanical review.

It is **not approved for production publication yet**. Publication remains gated by evaluator hardening, secure server-side delivery/checking, final AI source-card approval, and runtime QA.

## Canonical coverage

The bank follows the governed coordinate-geometry skill map:

- P1-COO-01 — equation of a straight line from point/gradient/two points: 11
- P1-COO-02 — line forms, distance, midpoint, gradient and intersection: 11
- P1-COO-03 — parallel/perpendicular gradient conditions: 9
- P1-COO-04 — equation of a circle, expanded form, centre and radius: 12
- P1-COO-05 — line-circle and circle-geometry problems combining algebra and geometry: 13
- P1-COO-06 — intersections/tangency/parameter conditions through roots/discriminant: 12

Total: 68  
MCQ / input: 36 / 32  
Easy / Medium / Hard: 15 / 33 / 20

The legacy gap identified in the canonical map is intentionally repaired: circle content is no longer reduced mainly to straight-line work.

## Mathematical review

The complete bank was re-read with the keyed answer and explanation visible.

Checks included:
- point-gradient and two-point line equations;
- equivalent line forms and intercepts;
- distance/midpoint/gradient/intersection;
- parallel/perpendicular and horizontal/vertical special cases;
- circle standard ↔ expanded form;
- completing the square;
- radius/centre/diameter construction;
- point position relative to a circle;
- simultaneous line-circle intersections;
- chord midpoint/perpendicular-bisector geometry;
- radius-tangent perpendicularity;
- tangent equations;
- quadratic roots as intersection coordinates;
- discriminant sign and intersection count;
- parameter conditions for tangency;
- centre-to-line distance as an equivalent tangency method.

### Defects caught and corrected

1. **Q204 — keyed answer disagreed with the mathematics**
   - The explanation correctly derived `3x+y=17`, but the initial correct key pointed to another option.
   - The answer key and diagnostics were corrected before QA completion.

2. **MCQ answer-position failure**
   - The authored draft had **zero D answers** and a strong position bias.
   - All option payloads were rebalanced together with their deterministic diagnostic mappings.

Current 36-MCQ distribution:
- A = 9
- B = 9
- C = 9
- D = 9

Current answer sequence:
`BDACDCADCBADBADCBCABCDADBCADCBCABDAB`

Checks:
- longest same-letter run = 1;
- no obvious ABCD-cycle pattern;
- no canonical skill has >40% of correct answers in one option position;
- no duplicated localized options;
- no systematic “correct answer is longest/shortest” clue was found.

3. **Practice ↔ Tour 3 cosmetic similarity**
   - Q160 direct-distance task was redesigned into a reverse-distance problem.
   - Q161 direct-midpoint task was redesigned into a reverse-midpoint problem.
   - Q163 direct line-intersection task was redesigned into a reverse-intersection recognition problem.
   - Q177 direct perpendicular-gradient pattern was redesigned to require deriving one line’s gradient before finding the perpendicular quantity.
   - Tour 3 itself was not changed.

The remaining similarities are shared canonical mathematics rather than number-swapped copies.

## Deterministic diagnostics

A governed catalog of **28 Coordinate Geometry diagnostic codes** was created.

Current bank usage:
- 26/28 codes are used by authored distractors/input rules;
- 0 wrong options are missing a diagnostic mapping;
- 0 correct options carry an error diagnosis;
- 0 diagnostic mappings cross canonical skill boundaries.

Two catalog codes are intentionally available but unused in this first bank:
- `COO02_DISTANCE_FORMULA`
- `COO04_POINT_TEST`

They remain draft catalog capacity, not learner diagnoses, until an authored wrong path explicitly supports them.

AI remains downstream: it may explain an established deterministic code; it may not invent or strengthen one.

## Input evaluator compatibility

All 32 input contracts were simulated against the current production scalar evaluator.

Result:
- false acceptance of rejected examples: **0**
- authored accepted examples currently rejected: **5**

All five failures are the known Unicode-minus normalization blocker:
- Q150: `−2`
- Q170: `−2`
- Q207: `−1`
- Q208: `−6`
- Q215: `−12`

The content is not weakened to work around this. Evaluator hardening remains a release prerequisite.

## AI safety/source-card review

The current production source-card index contains one approved/runtime-allowed EN/RU/UZ theory card for every `P1-COO-01…06` skill: 18 cards total.

However, source sufficiency was checked against the new question bank rather than treating card existence as enough.

Finding:
- COO-01…04 are adequately represented by the current approved cards for the authored core explanations.
- The current COO-05 card explains line-circle simultaneous equations, but **does not sufficiently cover** the new governed chord/tangent/point-position geometry.
- The current COO-06 card explains discriminant-based tangency, but **does not sufficiently cover** the centre-to-line distance method used in some authored transfer items.

Under the AI safety architecture, this is not filled by model intuition. Insufficient approved source coverage must produce `no_source`.

Therefore a **draft, non-runtime supplement** was created:
`content/math/practice_v2/p3_coordinate_geometry/ai_source_card_supplements.json`

It contains reviewed-intent EN/RU/UZ draft theory expansions for COO-05 and COO-06 covering:
- point position via distance squared;
- line-circle substitution;
- radius ⟂ tangent;
- chord/perpendicular-bisector geometry;
- discriminant intersection logic;
- parameter tangency;
- equivalent centre-to-line distance tangency.

These drafts are explicitly:
- `approval_status=draft`
- `is_runtime_allowed=false`
- `rights_status=original_iclub`

They must not enter AI retrieval until normal content/language/rights approval is complete.

## Permanent QA guard

Repository guard added:
`scripts/math-practice-v2-coordinate-geometry-qa.cjs`

It checks:
- total/skill/qtype/difficulty counts;
- key ranges;
- EN/RU/UZ presence;
- duplicate stems/options;
- exact A/B/C/D structure;
- deterministic diagnostic integrity;
- input contracts;
- answer-position balance;
- same-letter runs;
- obvious cyclic answer patterns.

## Gate result

| Gate | Result |
|---|---|
| 6 canonical Coordinate Geometry skills covered | PASS |
| Circle-content legacy gap repaired | PASS |
| Mathematical second-pass review | PASS after Q204 correction |
| MCQ unique/mechanical structure | PASS |
| Primitive answer-position QA | PASS after full rebalance |
| Deterministic diagnostics | PASS |
| EN/RU/UZ structural coverage | PASS |
| Practice/Tour 3 separation review | PASS after four redesigns |
| Current production AI card existence | PASS |
| Sufficient AI source coverage for all new authored explanations | BLOCKED — COO-05/06 supplement requires review/approval |
| Current production input evaluator | BLOCKED — Unicode minus normalization required |
| Production publication | NOT YET |

Next content block under the active plan is Practice 4 — Circular Measure + Trigonometry.
