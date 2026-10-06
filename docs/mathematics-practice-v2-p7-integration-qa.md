# Mathematics Practice v2 — Practice 7 Integration QA Report

Date: 2026-10-07  
Branch: `work/mathematics-practice-v2-refresh-20261006`  
Scope: `P1-INT-01…P1-INT-05`  
Production data changed: NO

## Status

Practice 7 now has a complete **66-question** draft and has passed the first full bank-level mathematical/mechanical review.

This completes authored P1 Practice v2 coverage across all 45 canonical P1 skills.

It is **not approved for production publication yet**. Publication remains gated by global cross-bank QA, evaluator hardening, secure server-side delivery/checking, runtime QA and governed migration/release.

## Canonical coverage

- P1-INT-01 — antiderivatives of powers and supported `(ax+b)^n` forms: 14
- P1-INT-02 — constant of integration and point/boundary conditions: 12
- P1-INT-03 — definite integrals, including simple improper endpoint cases: 14
- P1-INT-04 — geometric area against axes/lines/curves with splitting where required: 14
- P1-INT-05 — volumes of revolution about the x-axis with correct limits: 12

Total: 66  
MCQ / input: 28 / 38  
Easy / Medium / Hard: 16 / 24 / 26

The bank stays inside the canonical P1 Integration firewall and uses Chapter 10, printed pp. 173–200.

## Mathematical/content review

The complete bank was reviewed against the canonical map, the approved theory-source cards and current Season 2 Tour 7.

Checks included:
- integration power rule;
- constants and linear combinations;
- roots/negative fractional powers where supported;
- compensation for the inner coefficient in `(ax+b)^n`;
- derivative-back-checks of antiderivatives;
- point/boundary conditions and recovery of full curves;
- upper-minus-lower definite integration;
- signed accumulation versus geometric area;
- endpoint-improper integrals using one-sided limits;
- area below the axis;
- area across sign changes;
- intersections before area integration;
- top-minus-bottom ordering;
- parameter-from-area tasks;
- disc-volume formula `V=π∫y²dx`;
- reverse parameter/limit volume tasks.

### Defects / weak patterns caught and corrected

1. **Q475 — evaluator-hostile repeating decimal**
   - Initial draft asked for the area `32/3` as a decimal input.
   - The current scalar evaluator does not support exact rational equivalence, so this would force an unreasonable long decimal.
   - The item was redesigned to ask for `3 × area`, giving the exact integer 32.

2. **Q478 — real mathematical error caught in second-pass audit**
   - Initial total area for `y=x²−4` on `−3≤x≤3` was incorrectly written as `44/3`.
   - Independent split-area recomputation showed:
     - central area `32/3`;
     - two outer pieces total `14/3`;
     - correct total = **46/3**.
   - Correct answer, distractor placement and all EN/RU/UZ explanations were corrected.

3. **Primitive MCQ option-position failure**
   - Raw authored Integration bank initially had **all 28 MCQ correct answers in A**.
   - Full option payloads and their diagnostic codes were shuffled together.

Current 28-MCQ distribution:
- A = 7
- B = 7
- C = 7
- D = 7

Current sequence:
`BDACBDACCADBDBCADBACBDACBDCA`

Checks:
- longest same-letter run = 2;
- no obvious ABCD cycle;
- no skill with >=5 MCQs has >40% in one correct position;
- no duplicate localized option text remains;
- no duplicate English stem remains.

4. **Practice ↔ Tour 7 separation**
   - Q444 changed from a direct “find C” construction close to Tour 7 into a recover-curve-then-transfer value task.
   - Q480 changed away from the Tour’s same cubic/interval axis-area shape into a different crossing-area transfer task.
   - Q486 changed from a direct volume of `y=x²` construction close to the Tour’s direct volume item into a reverse parameter-from-volume problem.
   - Remaining similarity is unavoidable shared canonical mathematics and is retained only where Practice serves a routine teaching role while Tour independently checks transfer.

No Tour question, membership, attempt, answer or result was changed.

## Deterministic diagnostics

A governed catalog of **24 Integration diagnostic codes** was created.

The bank covers deterministic mistakes around:
- integration power/coefficient rules;
- inner linear factor;
- missing `+C`;
- rational powers;
- point/boundary substitution;
- upper-minus-lower;
- endpoint limits;
- signed integral vs geometric area;
- intersections;
- top/bottom order;
- area splitting;
- radius-squared and π in revolution volumes;
- limits/model selection.

Every authored wrong MCQ option has a deterministic diagnostic mapping and no correct option carries an error diagnosis.

Four catalog codes remain unused capacity:
- `INT03_CONSTANT_CANCELS`
- `INT04_PARAMETER_AREA`
- `INT05_AXIS_RADIUS`
- `INT05_WASHER`

They remain inactive and do not create learner diagnoses unless a future authored answer path deterministically supports them.

## Input evaluator compatibility

All 38 input contracts were checked against the current scalar Practice evaluator.

Result:
- false acceptance of authored rejected examples: **0**
- authored accepted examples currently rejected: **2**

Both failures are the already known Unicode-minus normalization blocker:
- Q439: `−4`
- Q465: `−8`

No content workaround was introduced.

## EN/RU/UZ review

All 66 questions contain EN/RU/UZ:
- stems;
- MCQ options where applicable;
- explanations.

Numeric-symbol parity was checked mechanically. Flagged cases were sentence-order differences or word forms such as “three times”, not detected mathematical contradictions.

## AI safety/source-card review

Production has one approved/runtime-allowed original iClub theory card in EN/RU/UZ for every `P1-INT-01…05`.

The approved cards already cover:
- antiderivatives and `(ax+b)^n`;
- constant of integration and boundary conditions;
- definite integrals plus endpoint-improper handling;
- area with intersections/splitting;
- volume of revolution about the x-axis.

For the authored Practice 7 bank, existing approved source coverage is sufficient. **No new AI source-card supplement is currently required.**

Runtime rules remain unchanged:
- deterministic evaluator establishes correctness;
- AI may only explain established results;
- active Tour remains protected;
- no approved source → `no_source`, not model-memory completion.

## Permanent QA guard

Added:
`scripts/math-practice-v2-integration-qa.cjs`

It checks:
- total/per-skill/qtype/difficulty counts;
- key ranges and source refs;
- EN/RU/UZ completeness;
- duplicate stems/options;
- A/B/C/D structure;
- deterministic diagnostic integrity;
- input answer contracts;
- correct-option balance;
- same-letter runs and obvious cycles.

## Gate result

| Gate | Result |
|---|---|
| 5 canonical Integration skills covered | PASS |
| Historical Integration coverage gap repaired | PASS |
| Mathematical bank review | PASS after Q478 correction |
| Validator-safe input design | PASS except known Unicode-minus runtime blocker |
| MCQ mechanical structure | PASS |
| Primitive answer-position QA | PASS after rebalance |
| Deterministic diagnostics | PASS |
| EN/RU/UZ structural coverage | PASS |
| Practice/Tour 7 separation | PASS after targeted redesigns |
| Approved AI source coverage | PASS |
| Current production input evaluator | BLOCKED — Unicode minus normalization required |
| Production publication | NOT YET |

Next macro step under the active plan: **global Practice v2 cross-bank audit across all 495 authored P1 items and all 45 canonical skills**, followed by evaluator/security/runtime implementation work.
