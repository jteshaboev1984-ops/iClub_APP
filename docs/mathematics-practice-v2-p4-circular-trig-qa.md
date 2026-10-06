# Mathematics Practice v2 — Practice 4 Circular Measure + Trigonometry QA Report

Date: 2026-10-06  
Branch: `work/mathematics-practice-v2-refresh-20261006`  
Scope: `P1-CIR-01…03` + `P1-TRI-01…05`  
Production data changed: NO

## Status

Practice 4 has a complete **77-question** draft and has passed the first full bank-level mathematical/mechanical review.

It is **not approved for production publication yet**. Publication remains gated by evaluator hardening, secure server-side delivery/checking, final AI source-card approval where supplements are needed, and runtime QA.

## Canonical coverage

- P1-CIR-01 — degrees ↔ radians: 8
- P1-CIR-02 — arc length and recovery of r/θ: 9
- P1-CIR-03 — sector area and composite sector/segment problems: 10
- P1-TRI-01 — sin/cos/tan graphs and simple transformations: 10
- P1-TRI-02 — exact values and related-angle symmetries: 10
- P1-TRI-03 — principal inverse-trig values and calculator interpretation: 8
- P1-TRI-04 — basic trigonometric identities: 10
- P1-TRI-05 — simple trigonometric equations on stated intervals: 12

Total: 77  
MCQ / input: 49 / 28  
Easy / Medium / Hard: 22 / 32 / 23

The bank stays inside the P1 firewall. Addition/double-angle identities and post-P1 binomial-style trig expansions are not used.

## Mathematical/content review

The bank was reviewed against the canonical map and the current Season 2 Tour 4.

Checks covered:
- degree/radian conversion;
- arc length s=rθ and reverse problems;
- sector perimeter vs arc length;
- sector area ½r²θ;
- composite sector/segment reasoning;
- sin/cos/tan graph periods, ranges, shifts and asymptotes;
- exact trig values and related-angle signs;
- inverse-trig principal ranges and calculator mode;
- base identities sin²x+cos²x=1 and tan x=sin x/cos x;
- algebraic simplification without illegal cancellation;
- complete trig-equation solution sets on bounded intervals;
- transformed input intervals;
- quadratic/factored trig branches without dropping solutions.

### Defects caught and corrected

1. **Q221 — ambiguous MCQ**
   - The draft asked for the largest angle but included two equivalent 135° choices.
   - One distractor was changed so exactly one correct answer remains.

2. **Q270 — malformed qtype**
   - A numeric input item was temporarily authored with a non-supported qtype label.
   - Corrected to `input`; answer contract retained.

3. **Q254/Q262 — duplicate English stem**
   - Two exact-value items shared the same question text.
   - Q262 was rewritten to a distinct prompt while preserving its mathematical target.

4. **Practice↔Tour similarity**
   - Direct Tour-like exact-value/equation items were redesigned where the structure was too close:
     - Q254 changed from a single direct `sin210°` lookup to a combined exact-value relation;
     - Q255 changed from a direct `cos330°` lookup to a symmetry relation;
     - Q284 changed from direct `tan x=1/√3` to a translated-input equation.
   - Other similar pairs were retained only where the evidence role is materially different (reverse arc/sector problems, transformed equations, segment/composite problems).

No Tour question, Tour membership or Tour result was changed.

## Primitive-error / option-position QA

After authoring, all MCQ option payloads were rebalanced together with their deterministic diagnostic codes.

Current 49-MCQ distribution:
- A = 12
- B = 12
- C = 12
- D = 13

Current sequence:
`BDACADCDBADCACDABBDACCBDACADCBDBACBDCABBDCABDACDB`

Checks:
- longest same-letter run = 2;
- no obvious `ABCDABCD` cycle;
- no skill has >40% of its correct answers in one position;
- no duplicated localized option text remains;
- no duplicate English stem remains.

Permanent repository guard added:
`scripts/math-practice-v2-circular-trig-qa.cjs`

## Deterministic diagnostics

Practice 4 uses a governed catalog of **30 diagnostic codes** covering:
- radian conversion;
- arc/sector formulas;
- sector/segment decomposition;
- graph period/range/translation/asymptotes;
- reference angles/quadrant signs;
- principal inverse values/calculator mode;
- Pythagorean/tangent identities and algebra;
- interval completeness, period and quadratic trig branches.

Current structural review:
- every wrong MCQ option has a diagnostic code;
- no correct option has an error diagnosis;
- no used code crosses a canonical-skill boundary;
- diagnostic movement during option shuffling preserved the intended misconception mapping.

Two catalog codes are currently unused by this first bank:
- `CIR02_PERIMETER`
- `TRI05_EXTRANEOUS_RANGE`

They remain catalog capacity only and do not create learner diagnoses unless an authored answer path explicitly supports them.

## Input evaluator compatibility

All 28 input contracts were checked against the current scalar Practice evaluator.

Result:
- false acceptance of authored rejected examples: **0**
- authored accepted examples currently rejected: **3**

The three failures are Unicode-minus variants:
- Q256: `−1`
- Q261: `−2`
- Q264: `−30`

This is the same known evaluator-normalization blocker already seen in Practices 1–3.

## EN/RU/UZ review

All 77 questions have EN/RU/UZ:
- stems;
- MCQ options where applicable;
- explanations.

Numeric-symbol parity was checked mechanically and flagged only ordering/word-form differences caused by Uzbek/Russian grammar; no mathematical-number contradiction was found in that pass.

## AI safety/source-card review

Production has approved/runtime-allowed theory cards for all eight canonical skills in EN/RU/UZ.

However, source-card existence was not treated as sufficient by itself. Under the AI-layer safety architecture, runtime explanation must stay within approved source coverage, and lack of adequate approved evidence must produce `no_source` rather than model-memory completion.

The existing cards were sufficient for most authored content, but additional governed coverage is useful for:
- CIR-02 sector-perimeter → arc-length recovery;
- TRI-01 transformed graph period/range/asymptote handling;
- TRI-05 transformed/factored/quadratic trig equation completeness.

A draft non-runtime supplement was therefore created:
`content/math/practice_v2/p4_circular_trigonometry/ai_source_card_supplements.json`

It contains original iClub EN/RU/UZ drafts for those three skills and is explicitly:
- `approval_status=draft`
- `is_runtime_allowed=false`
- `rights_status=original_iclub`

## Gate result

| Gate | Result |
|---|---|
| 8 canonical Circular/Trig skills covered | PASS |
| P1 scope firewall | PASS |
| Mathematical bank review | PASS |
| MCQ unique/mechanical structure | PASS |
| Primitive answer-position QA | PASS |
| Deterministic diagnostics | PASS |
| EN/RU/UZ structural coverage | PASS |
| Practice/Tour 4 separation review | PASS after targeted redesigns |
| Existing AI source-card availability | PASS |
| Supplemental AI source coverage | DRAFT — requires normal review/approval before runtime |
| Current production input evaluator | BLOCKED — Unicode minus normalization required |
| Production publication | NOT YET |

Next content block under the active plan is Practice 5 — Binomial Expansion + Series.
