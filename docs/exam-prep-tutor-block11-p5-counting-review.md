# Exam Prep Tutor Content — Block 11 P5 Permutations and Combinations Review

Status: AUTHORING REVIEW
Scope: P5-CNT-01…05, EN/RU/UZ
Runtime: OFF
Date: 2026-10-05

## Source and scope cross-check

Canonical owner: P5 only.
Official section: 5.2 Permutations and combinations.
Canonical source map: P5-CNT-01…05.
Book mapping: Complete Probability & Statistics 1, Ch6 Permutations and combinations, pp. 98–111.

Approved theory source cards confirm the required Paper 5 counting ideas:
- decide first whether order matters;
- use the product rule for successive choices;
- use n! for arrangements of distinct objects;
- divide by repeat factorials for identical objects;
- handle restrictions with fixed positions, blocks, subtraction or cases;
- use nCr when order does not matter;
- if selection is followed by arrangement, count both stages.

## Exact learner-facing boundaries

### P5-CNT-01 — Ordered arrangements vs unordered selections

Core decision:
Does changing the order create a different outcome?

Reviewed contrast:
From 4 people A, B, C, D:
- ordered choice of 3 positions: 4×3×2 = 24;
- unordered committee of 3: 4C3 = 4.

Teaching emphasis:
make the order decision before selecting a formula.

### P5-CNT-02 — Permutations of distinct objects

Reviewed example:
5 distinct books in a row:
5! = 120 arrangements.

Teaching emphasis:
successive positions have 5, then 4, then 3, then 2, then 1 choices; factorial is compact product-rule notation.

### P5-CNT-03 — Repeated/identical objects

Reviewed example:
LEVEL has 5 letters with L repeated twice and E repeated twice.

Distinct arrangements:
5! / (2!2!) = 30.

Teaching emphasis:
ordinary 5! overcounts because swapping identical letters does not create a new arrangement.

### P5-CNT-04 — Restricted arrangements

Reviewed example:
A, B, C, D, E in a row with A and B together.

Treat A and B as one block:
4! arrangements of the block + C + D + E,
and 2 internal orders AB/BA.

Total together = 4!×2 = 48.

If the question asks for A and B apart:
5! - 48 = 72.

Teaching emphasis:
choose a restriction strategy deliberately: block, fixed position, complement, or cases.

### P5-CNT-05 — Combinations and mixed selection/arrangement

Reviewed example:
Choose 3 people from 8:
8C3 = 56.

If those 3 are then assigned one chair:
8C3×3 = 168.

Teaching emphasis:
selection and arrangement are separate stages. nCr handles the unordered selection; multiply by the number of role/order assignments afterwards when required.

## Learner-first standard

Each skill contains:
- main explanation;
- genuinely simpler explanation;
- different mental model;
- concise focus/trap check.

No internal IDs, no answer-key language, no invented learner-specific weakness.

## Trilingual parity

EN/RU/UZ preserve:
- identical counting examples;
- identical numerical results;
- identical distinction between ordered and unordered outcomes;
- identical restriction logic;
- equivalent notation.

## Technical acceptance

- 15/15 new Block 11 cards.
- Three locales per skill.
- Total learner-first draft count after Block 11 = 183.
- Total covered skills after Block 11 = 61.
- Exact source-card component/skill/locale linkage.
- DRAFT and runtime OFF only.
- No P1/P5 cross-component leakage.
- No legacy, entitlement or academic-state writes.
- Dedicated Block 11 CI gate GREEN.

## Runtime decision

NO runtime switch in Block 11.
Provider-backed topic explanation remains production default until the global 243/243 reviewed runtime-ready gate is satisfied.
