# Mathematics Practice v2 — Practice 1 Quadratics QA Report

Date: 2026-10-06  
Branch: `work/mathematics-practice-v2-refresh-20261006`  
Scope: `P1-QUA-01…P1-QUA-06`  
Production data changed: NO

## Status

Practice 1 content has passed the second-pass mathematical and learner-facing language review.

It is **not yet approved for production publication**. Technical validation remains blocked until the governed input evaluator and server delivery/diagnostic path accept the authored answer contracts without weakening answer security or AI authority boundaries.

## Reviewed bank

- Total questions: 68
- P1-QUA-01: 10
- P1-QUA-02: 12
- P1-QUA-03: 14
- P1-QUA-04: 10
- P1-QUA-05: 12
- P1-QUA-06: 10
- MCQ: 41
- Input: 27
- Easy / Medium / Hard: 16 / 34 / 18

The difficulty split is within the approved architecture band and reflects reasoning demand rather than coefficient size.

## Mathematical review

Every authored item was re-solved in a second pass. The review checked:

- mathematical correctness of the stem;
- uniqueness of the intended answer;
- correctness of each MCQ option;
- validity of the worked explanation;
- parameter restrictions and interval endpoints;
- transformed-variable back-substitution;
- real-number domain restrictions;
- tangency/repeated-root conditions;
- simultaneous-equation back-substitution;
- scalar input contract consistency.

### Defects found and corrected during review

1. **Q051 — simultaneous system**
   - Earlier draft used a system whose written factorisation/claimed answer did not match the equation.
   - The item was replaced with a mathematically consistent system and re-solved.
   - Current canonical answer: `2`.

2. **Q017 — duplicate mathematically correct MCQ choices**
   - Earlier draft contained `3 ± √8` and `3 ± 2√2` as separate options; these are equivalent.
   - The entire parameter item was redesigned, not patched cosmetically.
   - Current item has one and only one correct option.

3. Difficulty labels were recalibrated after a review found the first draft too hard-heavy.

## Primitive-error guard

Current correct-answer distribution across the 41 MCQs:

- A = 10
- B = 10
- C = 10
- D = 11

Longest run of the same correct letter: **2**.

No simple repeated cycle such as `ABCDABCD` is present.

Per-skill answer positions are also distributed; no sufficiently large skill subset is dominated by one answer position beyond the architecture limit.

A repository QA guard now checks:

- duplicate question IDs;
- duplicate English stems;
- required EN/RU/UZ fields;
- four-option A/B/C/D structure;
- correct option membership;
- correct-option diagnostic leakage;
- missing diagnostic mapping on wrong options;
- duplicate option text;
- unknown diagnostic codes;
- accepted/rejected input overlap;
- canonical answer coverage;
- skill counts;
- qtype counts;
- difficulty bands;
- correct-letter distribution;
- same-letter runs;
- obvious fixed cycles.

File: `scripts/math-practice-v2-content-qa.cjs`

## Diagnostic review

The Quadratics diagnostic set was consolidated into **30 governed diagnostic codes**.

Checks passed:

- all 30 catalog codes are currently used;
- no used code is missing from the catalog;
- every used code belongs to the same primary canonical skill as the question;
- the correct MCQ option never carries an error diagnosis;
- wrong-option diagnoses are deterministic authoring mappings, not AI inference;
- the catalog includes EN/RU/UZ deterministic feedback and next action.

File: `content/math/practice_v2/p1_quadratics/diagnostic_catalog.json`

AI remains downstream of this deterministic result. It may explain an established diagnostic; it may not create or strengthen one.

## EN / RU / UZ review

All 68 questions, options and explanations were reviewed across EN/RU/UZ.

Checks included:

- same mathematical task;
- same numbers and conditions;
- same answer space;
- same interval strictness;
- same parameter restrictions;
- no learner-facing internal development terminology;
- natural learner-facing wording.

Polish fixes included removing unnecessary emphasis/capitalisation, improving Russian/Uzbek phrasing, and correcting a width/length wording mismatch in the rectangle explanation.

## Practice ↔ Tour separation

Season 2 Tour 1 was inspected read-only against the new Practice 1 bank.

Several Practice drafts were judged too close to existing Tour tasks and were redesigned before publication:

- Q005
- Q013
- Q017
- Q023
- Q037
- Q054
- Q060

The objective was not to remove shared canonical skills. Practice and Tour must assess the same knowledge. The correction was to avoid cosmetic number changes or nearly identical task structures where a better teaching/transfer form was available.

Tour results, Tour membership and Tour question rows were not changed.

## Input evaluator compatibility

The current production scalar evaluator was simulated against every authored Practice 1 accepted/rejected example.

Current result:

- false acceptance of rejected examples: **0**
- accepted examples currently rejected by production evaluator: **3**

All three failures are Unicode-minus variants:

- Q002: `−4`
- Q004: `−7`
- Q015: `−12`

This is an expected technical blocker already identified in the architecture. The authored contract is correct; production must normalize Unicode minus server-side before these questions are published.

No content should be weakened merely to accommodate this legacy limitation.

## Source / AI source-card alignment

Practice 1 remains inside:

- P1 Section 1.1 Quadratics;
- canonical skills P1-QUA-01…06;
- Complete Pure Mathematics 1, Chapter 1, printed pp. 2–20.

Existing approved/runtime-allowed iClub theory source cards for all six Quadratics skills were inspected. They are original iClub content and exist in EN/RU/UZ.

Default implementation decision:

- reuse approved cards after final runtime compatibility testing;
- do not duplicate cards simply because Practice was rebuilt;
- version a card only if a real academic/content gap is found.

## Gate result

| Gate | Result |
|---|---|
| Canonical skill coverage | PASS |
| P1 scope firewall | PASS |
| Mathematical correctness second pass | PASS |
| MCQ answer uniqueness | PASS after corrections |
| Primitive answer-position QA | PASS |
| Deterministic diagnostic mapping | PASS |
| EN/RU/UZ learner content | PASS |
| Practice/Tour separation review | PASS after redesigns |
| Current production input evaluator | BLOCKED — Unicode minus hardening required |
| Production publication | NOT YET |

Next work continues under the active working plan. The next content block is Practice 2 Functions & transformations, while evaluator hardening is kept as a mandatory release dependency rather than bypassed in content.
