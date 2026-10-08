# Mathematics Practice v2 — Content Architecture 2.0

Status: BLOCK 1 / ACTIVE DESIGN  
Working plan: `docs/mathematics-practice-v2-working-plan.md`  
Scope of this document: P1 Practice architecture and its relationship to Tours, evaluator contracts, diagnostics and AI safety.

## 1. Academic basis

The P1 Practice bank is built on the canonical 45-skill map:

- Quadratics: 6 skills
- Functions: 8 skills
- Coordinate geometry: 6 skills
- Circular measure: 3 skills
- Trigonometry: 5 skills
- Series: 5 skills
- Differentiation: 7 skills
- Integration: 5 skills

Every atomic question has exactly one primary P1 skill. Secondary skills may be attached only when they are real dependencies. Prerequisites never create P1 mastery by themselves.

Out-of-P1 content is excluded from the new bank, including modulus, addition/double-angle trigonometric formulae and rational/negative-binomial extensions.

## 2. Product model

### Practice
Purpose: learn, apply, identify a mistake, understand it, and transfer the idea.

A Practice question may:
- teach a rule through application;
- expose a reviewed misconception;
- give post-submit deterministic feedback;
- offer optional AI explanation only after allowed context is established;
- reuse the same canonical skill across genuinely different representations.

### Tour
Purpose: independently verify retained knowledge and transfer.

A Tour item must not be a numerical reskin of Practice. The same skill may appear, but the representation, task direction or combination must require independent recognition.

During an active protected Tour, targeted AI assistance remains blocked.

## 3. Target bank size

The new bank is not constrained by the legacy 70-per-Practice number. Target total: **506 original P1 Practice questions**.

| Practice | Canonical area | Target questions | MCQ | Input |
|---|---|---:|---:|---:|
| 1 | Quadratics | 68 | 41 | 27 |
| 2 | Functions & transformations | 80 | 61 | 19 |
| 3 | Coordinate geometry | 68 | 39 | 29 |
| 4 | Circular measure + Trigonometry | 80 | 54 | 26 |
| 5 | Binomial + Series | 64 | 31 | 33 |
| 6 | Differentiation | 80 | 48 | 32 |
| 7 | Integration | 66 | 35 | 31 |
| **Total** | 45 P1 skills | **506** | **309** | **197** |

This is a production target, not a reason to keep a weak item. A question may be removed during QA; publication requires coverage and quality, not exact quota.

## 4. Skill allocation

### Practice 1 — Quadratics

| Skill | Learning target | Count | MCQ | Input |
|---|---|---:|---:|---:|
| P1-QUA-01 | completed-square form; vertex/shape information | 10 | 5 | 5 |
| P1-QUA-02 | discriminant; root type/number; parameter conditions | 12 | 8 | 4 |
| P1-QUA-03 | solve quadratics; choose factorisation/formula/completing square | 14 | 6 | 8 |
| P1-QUA-04 | quadratic inequalities and interval endpoints | 10 | 8 | 2 |
| P1-QUA-05 | simultaneous linear + quadratic systems | 12 | 6 | 6 |
| P1-QUA-06 | equations quadratic in a transformed expression | 10 | 8 | 2 |

### Practice 2 — Functions & transformations

| Skill | Learning target | Count | MCQ | Input |
|---|---|---:|---:|---:|
| P1-FUN-01 | function/domain/range/one-one/inverse/composition language | 8 | 7 | 1 |
| P1-FUN-02 | range under domain restriction | 10 | 8 | 2 |
| P1-FUN-03 | composite functions and domain/range compatibility | 10 | 5 | 5 |
| P1-FUN-04 | one-one condition and inverse with correct domain | 12 | 9 | 3 |
| P1-FUN-05 | function/inverse graph reflection in y=x | 8 | 7 | 1 |
| P1-FUN-06 | horizontal/vertical translations | 10 | 8 | 2 |
| P1-FUN-07 | reflections in coordinate axes | 10 | 8 | 2 |
| P1-FUN-08 | stretches/compressions and combined point mapping | 12 | 9 | 3 |

### Practice 3 — Coordinate geometry

| Skill | Learning target | Count | MCQ | Input |
|---|---|---:|---:|---:|
| P1-COO-01 | equation of line from point/gradient/two points | 11 | 5 | 6 |
| P1-COO-02 | line forms, distance, midpoint, gradient, intersection | 11 | 5 | 6 |
| P1-COO-03 | parallel/perpendicular gradient conditions | 9 | 6 | 3 |
| P1-COO-04 | circle equation; expanded form; centre/radius | 12 | 6 | 6 |
| P1-COO-05 | line-circle and circle geometry using algebra + geometry | 13 | 9 | 4 |
| P1-COO-06 | intersection/tangency/parameters via roots/discriminant | 12 | 8 | 4 |

### Practice 4 — Circular measure + Trigonometry

| Skill | Learning target | Count | MCQ | Input |
|---|---|---:|---:|---:|
| P1-CIR-01 | degrees ↔ radians | 8 | 3 | 5 |
| P1-CIR-02 | arc length; unknown r or theta | 9 | 4 | 5 |
| P1-CIR-03 | sector area; composite sector/segment problems | 10 | 7 | 3 |
| P1-TRI-01 | sin/cos/tan graphs and simple transformations | 11 | 9 | 2 |
| P1-TRI-02 | exact values and related-angle symmetries | 10 | 5 | 5 |
| P1-TRI-03 | principal inverse-trig values and calculator output | 8 | 6 | 2 |
| P1-TRI-04 | prove/apply basic identities | 11 | 10 | 1 |
| P1-TRI-05 | solve simple trig equations on a stated interval | 13 | 10 | 3 |

### Practice 5 — Binomial + Series

| Skill | Learning target | Count | MCQ | Input |
|---|---|---:|---:|---:|
| P1-SER-01 | positive-integer binomial terms/coefficients | 14 | 6 | 8 |
| P1-SER-02 | recognise AP vs GP structure | 8 | 7 | 1 |
| P1-SER-03 | AP nth term/finite sum, including inverse problems | 14 | 5 | 9 |
| P1-SER-04 | GP nth term/finite sum, including inverse problems | 14 | 5 | 9 |
| P1-SER-05 | convergence and sum to infinity | 14 | 8 | 6 |

### Practice 6 — Differentiation

| Skill | Learning target | Count | MCQ | Input |
|---|---|---:|---:|---:|
| P1-DIF-01 | derivative as gradient/rate; simple limit-definition interpretation | 8 | 7 | 1 |
| P1-DIF-02 | powers with rational exponent and linear combinations | 14 | 5 | 9 |
| P1-DIF-03 | chain rule for (ax+b)^n | 12 | 5 | 7 |
| P1-DIF-04 | tangent and normal equations | 12 | 6 | 6 |
| P1-DIF-05 | increasing/decreasing intervals from derivative sign | 10 | 8 | 2 |
| P1-DIF-06 | rate-of-change/connected rates with units/signs | 10 | 7 | 3 |
| P1-DIF-07 | stationary points, nature, sketch/optimisation | 14 | 10 | 4 |

### Practice 7 — Integration

| Skill | Learning target | Count | MCQ | Input |
|---|---|---:|---:|---:|
| P1-INT-01 | antiderivatives of powers and (ax+b)^n | 15 | 6 | 9 |
| P1-INT-02 | constant of integration + point/boundary condition | 12 | 5 | 7 |
| P1-INT-03 | definite integrals, including the canonical simple improper endpoint case | 13 | 5 | 8 |
| P1-INT-04 | area between curve/axes/lines/two curves; split region when needed | 15 | 11 | 4 |
| P1-INT-05 | volume of revolution with correct limits | 11 | 8 | 3 |

## 5. Question-role composition

Every skill family must contain more than routine repetitions.

Target mix over each Practice bank:

- 20–25% direct application
- 15–20% representation/variation
- 15–20% intentional misconception traps
- 10–15% reverse/inverse problems
- 20–25% transfer
- 10–15% mixed within the owning P1 component

A transfer item must change more than numbers. At least one of these must change:
- representation;
- task direction;
- required model selection;
- graph/algebra connection;
- parameter role;
- context;
- combination with a secondary canonical skill.

## 6. Difficulty contract

Difficulty describes reasoning demand.

### Easy
- one main idea;
- direct recognition/application;
- low decision load;
- no hidden multi-step inference.

### Medium
- choose a method;
- 2–3 meaningful steps;
- domain/condition awareness or non-trivial interpretation.

### Hard
- transfer or inverse problem;
- parameter/condition reasoning;
- multiple representations;
- mixed same-component dependencies;
- need to reject a tempting but structurally wrong approach.

Target bank distribution: approximately **25% easy / 50% medium / 25% hard**.

A routine one-step item is not allowed to receive a hard label simply because coefficients are awkward.

## 7. Answer-contract architecture

Correctness is deterministic. AI never decides whether an answer is correct.

### Supported publication classes

1. **MCQ_SINGLE**
   - exactly one correct option;
   - option selection evaluated server-side.

2. **INTEGER_EXACT**
   - one signed integer.

3. **NUMERIC_EXACT**
   - one exact decimal/integer value after safe normalization.

4. **NUMERIC_TOLERANCE**
   - only when the question explicitly requires a rounded/approximate answer;
   - tolerance and rounding contract are stored separately from display answer.

5. **RATIONAL_EXACT**
   - planned governed evaluator for equivalent rational forms;
   - must not be published as free input until validator tests pass.

6. **SYMBOLIC_EQUIVALENCE**
   - future governed evaluator only;
   - no publication until domain-aware equivalence is independently validated.

7. **INTERVAL_SET / MULTI_VALUE_SET**
   - future governed evaluator only;
   - until then use MCQ or reformulate to one scalar/end-point/count.

### Safe authoring rule

When a mathematical result has many equivalent forms and no governed evaluator exists, do not use free input.

Examples:
- equation of a line -> MCQ or ask for gradient/intercept as one scalar;
- quadratic inequality solution set -> MCQ or ask one endpoint/count where pedagogically valid;
- inverse-function expression -> MCQ unless symbolic evaluator is approved;
- trig exact surd expression -> MCQ unless exact symbolic evaluator is approved;
- derivative/integral expression -> MCQ or ask a scalar coefficient/value at a point.

This is not a reduction in difficulty. The reasoning can remain hard while the final machine-checkable evidence is narrow.

## 8. Required evaluator improvements before new Input publication

The current evaluator is string/numeric based and is not sufficient for arbitrary mathematical equivalence.

Minimum production hardening:

- normalize Unicode minus variants safely;
- distinguish display answer from acceptance policy;
- explicit decimal separator policy;
- explicit sign policy;
- approved numeric tolerance only when requested by the stem;
- reject extra units/text when the contract says number-only;
- rational-equivalence evaluator only after independent tests;
- no permissive algebraic string matching presented as mathematical equivalence.

Every input question must ship with:
- accepted examples;
- rejected examples;
- boundary examples;
- locale formatting examples where relevant.

## 9. MCQ distractor and diagnostic contract

Distractors are written before option order is randomized.

Each distractor has:
- a stable distractor code;
- mathematical derivation showing how that wrong answer can arise;
- a diagnosis confidence class:
  - **specific**: the option intentionally and uniquely supports the misconception;
  - **broad**: supports only a broader review message;
  - **unmapped**: no diagnostic claim.

AI may never upgrade broad/unmapped into a specific misconception.

### Initial misconception families

Quadratics:
- QUA_COMPLETE_SQUARE_SIGN
- QUA_VERTEX_COORD_SWAP
- QUA_DISCRIMINANT_FORMULA
- QUA_DISCRIMINANT_CONDITION
- QUA_ROOT_SIGN
- QUA_METHOD_INCOMPLETE
- QUA_INEQUALITY_SIGN_REGION
- QUA_INTERVAL_ENDPOINT
- QUA_SIMULTANEOUS_SUBSTITUTION
- QUA_TRANSFORMED_VARIABLE_BACKSUB

Functions:
- FUN_DOMAIN_RANGE_SWAP
- FUN_RANGE_IGNORES_RESTRICTION
- FUN_COMPOSITION_ORDER
- FUN_COMPOSITION_DOMAIN
- FUN_INVERSE_RECIPROCAL_CONFUSION
- FUN_INVERSE_DOMAIN
- FUN_TRANSLATION_DIRECTION
- FUN_REFLECTION_AXIS
- FUN_STRETCH_FACTOR_DIRECTION
- FUN_POINT_MAPPING

Coordinate geometry:
- COO_GRADIENT_ORDER
- COO_LINE_FORM_SUBSTITUTION
- COO_PERPENDICULAR_SIGN_RECIPROCAL
- COO_MIDPOINT_DISTANCE_CONFUSION
- COO_CIRCLE_CENTRE_SIGN
- COO_RADIUS_SQUARED
- COO_TANGENCY_DISCRIMINANT
- COO_INTERSECTION_SUBSTITUTION

Circular/Trig:
- CIR_DEG_RAD_FACTOR
- CIR_ARC_FORMULA
- CIR_SECTOR_FORMULA
- TRI_GRAPH_PERIOD
- TRI_GRAPH_PHASE_DIRECTION
- TRI_QUADRANT_SIGN
- TRI_EXACT_VALUE
- TRI_INVERSE_PRINCIPAL_VALUE
- TRI_IDENTITY_ILLEGAL_CANCEL
- TRI_EQUATION_MISSED_SOLUTIONS
- TRI_INTERVAL_FILTER

Series:
- SER_BINOMIAL_TERM_INDEX
- SER_BINOMIAL_COEFFICIENT
- SER_AP_GP_MODEL
- SER_NTH_VS_SUM
- SER_COMMON_DIFFERENCE_RATIO
- SER_GP_POWER_INDEX
- SER_INFINITY_CONVERGENCE
- SER_INFINITY_FORMULA

Differentiation:
- DIF_POWER_EXPONENT
- DIF_CHAIN_FACTOR
- DIF_GRADIENT_AT_POINT
- DIF_NORMAL_NEG_RECIPROCAL
- DIF_INCREASE_SIGN
- DIF_STATIONARY_CONDITION
- DIF_STATIONARY_NATURE
- DIF_CONNECTED_RATE_CHAIN
- DIF_RATE_UNIT_SIGN

Integration:
- INT_POWER_EXPONENT
- INT_LINEAR_FACTOR
- INT_MISSING_C
- INT_BOUNDARY_CONSTANT
- INT_DEFINITE_LIMIT_ORDER
- INT_SIGNED_VS_AREA
- INT_REGION_SPLIT
- INT_VOLUME_SQUARE
- INT_VOLUME_LIMITS

These codes are authoring/QA candidates, not automatic diagnoses until a reviewed question maps an exact wrong path to them.

## 10. Core feedback contract

Every question must provide a complete non-AI learning path.

### Correct
- state the principle;
- show the essential application;
- give the result;
- optional quick check.

### Incorrect + specific diagnostic
- identify the exact established error without blaming/labeling the learner;
- show why it fails here;
- show the correct next mathematical step;
- finish with the relevant rule.

### Incorrect + broad/unmapped
- do not invent a cause;
- state that the submitted result does not satisfy the required condition;
- show the relevant principle and next step;
- link to the approved skill/theory resource.

## 11. AI integration

The new Practice bank follows the AI Safety Architecture.

### AI authority
AI may:
- explain an already-established submitted error;
- explain approved theory;
- rephrase/translate the same authoritative context.

AI may not:
- decide correctness;
- invent a diagnostic tag;
- inspect the private answer-key corpus;
- change mastery/evidence/stage/retest/readiness/marks/grade;
- alter canonical mapping;
- solve or check an active protected Tour item.

### Source cards

Current production already has one approved/runtime-allowed P1 theory card per canonical P1 skill in EN/RU/UZ.

Default policy:
- reuse those cards after skill-by-skill academic QA against the new question bank;
- do not create duplicates merely because Practice is rebuilt;
- add a new version only when the existing card is incomplete/incorrect for the governed skill;
- use deterministic diagnostic feedback + the approved theory card for established-error explanation;
- add dedicated error source cards only where a recurring misconception genuinely requires additional approved context.

If approved context is missing/conflicting, the route returns no_source/fallback; Core feedback still works.

## 12. Practice-to-Tour separation

For every canonical skill, content production maintains two different evidence roles.

Practice item:
- may be instructional;
- may expose misconception-specific distractors;
- may show solution/feedback after submission;
- may use a direct form before progressing to transfer.

Tour item:
- no instructional help while active;
- must be unseen/independent for the learner where the Tour claims fresh evidence;
- must require recognition/application/transfer rather than template recall;
- should not reuse Practice numbers, diagram, stem structure or distractor pattern.

No question ID is intentionally shared between new Practice and new Tour banks.

## 13. Correct-option placement and primitive-error prevention

Correct-option placement happens only after the mathematical item and distractors are approved.

Mechanical release rules for every Practice MCQ batch:

- whole-Practice A/B/C/D distribution target: each option approximately 20–30%;
- no option may dominate because of topic/difficulty;
- no run of the same correct letter longer than 3;
- reject obvious cycles such as ABCDABCD or repeated fixed patterns;
- no skill family with a sufficiently large MCQ set may have a single correct letter dominating >40%;
- correct-option placement is independent of difficulty;
- diagnostic codes attach to option meaning, not to A/B/C/D position;
- option reordering must not break explanation/diagnostic mapping.

Additional primitive checks:
- no duplicate correct options after normalization;
- no two correct mathematical answers;
- no correct option systematically longer/more precise;
- no unit/grammar clue;
- no duplicate distractors;
- no image/text mismatch;
- no repeated question where only coefficients changed and learning role stayed the same.

## 14. Session selection requirement

The existing 3 easy / 5 medium / 2 hard selection alone is not sufficient as a final learning policy.

The updated selector must eventually account for:
- unresolved canonical skills;
- learning role already seen;
- previous wrong paths;
- questions already answered correctly;
- need for transfer rather than repeated direct forms;
- diversity across subskills within the active Practice.

Difficulty remains one input, not the whole selector.

## 15. QA gates for content production

A question cannot reach learner-facing publication until:

1. source/scope mapping pass;
2. independent mathematical solve pass;
3. answer contract/evaluator tests pass;
4. distractor uniqueness/correctness pass;
5. diagnostic inference pass or explicit unmapped;
6. deterministic explanation pass;
7. EN/RU/UZ equivalence pass;
8. mobile/render/notation pass;
9. duplicate/template-similarity pass;
10. answer-letter distribution batch pass;
11. AI-context compatibility pass;
12. Practice/Tour separation pass.

## 16. Block 1 alignment result

Architecture check against working-plan invariants:

- Practice teaches / Tour checks: PASS
- 45 canonical P1 skills covered: PASS
- out-of-scope firewall retained: PASS
- deterministic correctness/diagnosis: PASS
- AI optional/non-authoritative: PASS
- approved source-card runtime only: PASS
- active Tour guard retained: PASS
- EN/RU/UZ equivalence required: PASS
- primitive correct-letter pattern check explicitly required: PASS
- Tour-history preservation remains outside content rewrite and protected by migration gate: PASS

Next production block: author the complete new Practice bank against this architecture, beginning with Practice 1 Quadratics as one complete content batch, not isolated micro-items.
