# Mathematics Practice v2 — Practice 6 Differentiation QA Report

Date: 2026-10-06  
Branch: `work/mathematics-practice-v2-refresh-20261006`  
Scope: `P1-DIF-01…P1-DIF-07`  
Production data changed: NO

## Status

Practice 6 now has a complete **70-question** draft and has passed the first full bank-level mathematical/mechanical review.

It is **not approved for production publication yet**. Publication remains gated by evaluator hardening, secure server-side delivery/checking, final source-card approval where supplementation is needed, and runtime QA.

## Canonical coverage

- P1-DIF-01 — derivative as tangent gradient / instantaneous rate / limit of secant gradients: 8
- P1-DIF-02 — power rule including rational powers and repeated differentiation: 12
- P1-DIF-03 — chain rule for supported composite powers: 10
- P1-DIF-04 — tangent and normal equations: 10
- P1-DIF-05 — increasing/decreasing intervals from derivative sign: 9
- P1-DIF-06 — connected rates with correct signs/units: 9
- P1-DIF-07 — stationary points, classification and optimisation: 12

Total: 70  
MCQ / input: 35 / 35  
Easy / Medium / Hard: 18 / 32 / 20

This repairs the historical Tour Map gap where mandatory differentiation had not been covered by the old Practice/Tour-map source structure.

## Mathematical/content review

The authored bank was re-read against the canonical map, Chapters 8–9 and current Season 2 Tour 6.

Checks covered:
- secant gradient versus instantaneous derivative;
- limit-definition simplification;
- power rule and constants;
- roots/reciprocals as rational powers;
- second derivatives;
- chain rule and the inner derivative factor;
- tangent/normal point + gradient + equation;
- derivative-sign interval analysis;
- strict monotonicity parameter conditions;
- connected-rate chains, signs and dimensions;
- stationary coordinates;
- derivative-sign and second-derivative classification;
- stationary inflexion;
- parameter conditions;
- one-variable optimisation and domain handling.

### Defects / weak patterns caught and corrected

1. **Q388 — inconsistent authored parameter condition**
   - Initial draft used gradient 108 for `y=(3x+c)³` while expecting `c=1`.
   - The independent check showed that this implies `(3+c)²=12`, not `c=1`.
   - The question was corrected to gradient 144, after which `c=1` follows exactly.

2. **Primitive MCQ answer-position failure**
   - The raw authored bank had **33/35 correct answers in A**, with one B, one C and no D.
   - The full option payloads were rebalanced together with diagnostic mappings.

Current 35-MCQ distribution:
- A = 8
- B = 9
- C = 10
- D = 8

Current sequence:
`BDACBACADBCBDBCACBDACDACADBCABDCCBD`

Checks:
- longest same-letter run = 2;
- no obvious ABCD-cycle;
- no skill with >=5 MCQs has >40% of correct answers in one position;
- no duplicate localized option text;
- no duplicate English stem.

3. **Practice ↔ Tour 6 separation**
   - Q409 was changed from a direct circle-area-rate task, which was too close to Tour 6, to a linked rectangle-rate task.
   - Q417 was changed from a direct cubic-volume rate task to a reverse rate problem.
   - Q397 moved away from the exact `y=x³−3x, x=1` curve already used by Tour 6.
   - Remaining similarity hits are shared canonical mathematics with materially different evidence roles (for example second-derivative value vs full derivative expression, combined chain rule vs single direct chain-rule item).

No Tour question, membership or result was changed.

## Deterministic diagnostics

A governed catalog of **31 Differentiation diagnostic codes** was created.

Current bank use:
- 26/31 codes are used by authored distractors/input rules;
- every wrong MCQ option has a diagnostic mapping;
- no correct option carries an error diagnosis;
- no used code crosses its canonical skill boundary.

Five codes remain unused capacity:
- `DIF03_VALUE_SUBSTITUTION`
- `DIF06_GEOMETRY_FORMULA`
- `DIF07_Y_COORDINATE`
- `DIF07_OPTIMISATION_MODEL`
- `DIF07_DOMAIN_BOUNDARY`

They do not create learner diagnoses unless a future authored answer path deterministically supports them.

## Input evaluator compatibility

All 35 input contracts were checked against the current scalar Practice evaluator.

Result:
- false acceptance of authored rejected examples: **0**
- authored accepted examples currently rejected: **5**

All five are the known Unicode-minus issue:
- Q392: `−1`
- Q410: `−1.6`
- Q416: `−2.25`
- Q418: `−4`
- Q427: `−1`

The content was not weakened to work around the old evaluator.

## EN/RU/UZ review

All 70 questions contain EN/RU/UZ stems and explanations; every MCQ option is trilingual.

Mechanical numeric-symbol parity was run. The flagged cases were caused by sentence-order differences or repeated explanatory values, not a detected mathematical contradiction.

## AI safety/source-card review

Production currently has one approved/runtime-allowed original-iClub theory card for every `P1-DIF-01…07` skill in EN/RU/UZ.

The existing cards are sufficient for:
- derivative meaning;
- power rule;
- chain rule;
- tangent/normal;
- increasing/decreasing;
- core connected-rates method;
- stationary points and optimisation.

The new DIF-06 bank deliberately includes broader but still syllabus-aligned connected-rate models (rectangle, square, cube, circumference, sector and an implicitly related pair). The existing approved DIF-06 card gives the general chain method but only a circle-area worked model.

To avoid silent model-memory expansion, a draft non-runtime supplement was created:
`content/math/practice_v2/p6_differentiation/ai_source_card_supplements.json`

It is explicitly:
- `approval_status=draft`
- `is_runtime_allowed=false`
- `rights_status=original_iclub`

Until approved, runtime AI must use existing approved material only and return `no_source` where that is insufficient.

## Permanent QA guard

Added:
`scripts/math-practice-v2-differentiation-qa.cjs`

It checks:
- total / per-skill / qtype / difficulty counts;
- key ranges and source refs;
- EN/RU/UZ completeness;
- duplicate stems/options;
- A/B/C/D structure;
- deterministic diagnostic integrity;
- input contracts;
- MCQ answer-position balance;
- same-letter runs and obvious cycles.

## Gate result

| Gate | Result |
|---|---|
| 7 canonical Differentiation skills covered | PASS |
| Historical differentiation coverage gap repaired | PASS |
| Mathematical bank review | PASS after Q388 correction |
| MCQ mechanical structure | PASS |
| Primitive answer-position QA | PASS after rebalance |
| Deterministic diagnostics | PASS |
| EN/RU/UZ structural coverage | PASS |
| Practice/Tour 6 separation | PASS after targeted redesigns |
| Existing approved AI source-card availability | PASS |
| Broader DIF-06 source coverage | DRAFT supplement — not runtime allowed |
| Current production input evaluator | BLOCKED — Unicode minus normalization required |
| Production publication | NOT YET |

Next content block under the active plan is Practice 7 — Integration (`P1-INT-01…05`).
