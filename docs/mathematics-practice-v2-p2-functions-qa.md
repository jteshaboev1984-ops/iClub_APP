# Mathematics Practice v2 — Practice 2 Functions & Transformations QA Report

Date: 2026-10-06  
Branch: `work/mathematics-practice-v2-refresh-20261006`  
Scope: `P1-FUN-01…P1-FUN-08`  
Production data changed: NO

## Status

Practice 2 has a complete 80-question draft and has passed the first full bank-level mathematical/mechanical review.

It is **not yet approved for production publication**. As with Practice 1, publication remains gated by evaluator hardening, server-side delivery/diagnostic validation, AI safety integration and final runtime QA.

## Reviewed bank

- Total questions: 80
- P1-FUN-01: 8
- P1-FUN-02: 10
- P1-FUN-03: 10
- P1-FUN-04: 12
- P1-FUN-05: 8
- P1-FUN-06: 10
- P1-FUN-07: 10
- P1-FUN-08: 12
- MCQ: 61
- Input: 19
- Easy / Medium / Hard: 21 / 40 / 19

The bank stays inside the canonical P1 Functions scope:
- language of function/domain/range/one-one/inverse/composition;
- restricted-domain range;
- composite functions and domain compatibility;
- one-one/inverse with correct domain;
- inverse graphs;
- translations;
- reflections;
- stretches/compressions and simple combinations with point mapping.

No modulus content is included.

## Mathematical review

The full bank was re-read with the correct answer and explanation exposed after authoring.

Checks covered:
- function/domain/range definitions;
- one-to-one and inverse-function assumptions;
- inverse algebra and branch choice;
- composition order and intermediate-domain restrictions;
- restricted quadratic ranges;
- graph point mapping;
- translation sign conventions;
- reflection axes;
- horizontal reciprocal scale factors;
- vertical scale factors;
- combined transformations;
- reverse point-mapping problems.

### Defects found and corrected during the build

1. **Q081 — duplicate option**
   - A draft contained two identical range options.
   - The duplicate distractor was replaced before bank-level QA.

2. **Q071 — explanation depended on answer position**
   - The explanation said “the third mapping”.
   - It was rewritten to identify the mathematical mapping itself, so later option shuffling cannot corrupt the explanation.

3. **Q098 and Q101 — too close to existing Tour 2 inverse-value task**
   - Both were redesigned into reverse/difference forms.
   - This keeps the same canonical skill but avoids a cosmetic Practice→Tour clone.

4. **Inverse-graph assumptions**
   - Q109, Q110, Q113 and Q115 now explicitly state that f is one-to-one, instead of relying on an implicit assumption that f⁻¹ exists as a function.

## Primitive-error / answer-position QA

The first authored sequence accidentally showed a visible answer-position pattern even though counts looked balanced. This was caught before publication.

The entire MCQ bank was then rebalanced by moving option payloads together with their diagnostic mappings.

Current 61-MCQ distribution:

- A = 15
- B = 15
- C = 15
- D = 16

Current sequence:
`BCADBCDACDBCBADBCDADBCADCCDADBACBCADBCACBACDBAADBDCABADBADCBD`

Checks:
- longest same-letter run = 2;
- no `ABCDABCD`-type cycle;
- no skill with >40% of its correct answers in one letter position;
- no localized duplicate option text;
- correct option is uniquely longest in only 3/61 items and uniquely shortest in 4/61, so there is no systematic length clue.

A permanent repository guard was added:
`scripts/math-practice-v2-functions-qa.cjs`

It checks bank size, skill coverage, qtype/difficulty bands, EN/RU/UZ fields, option structure, duplicate stems/options, diagnostic integrity, input contracts, answer-position balance, runs and obvious cycles.

## Diagnostic review

Functions uses **31 governed deterministic diagnostic codes**.

Current review result:
- 31/31 codes are used;
- no used code is missing from the catalog;
- no diagnostic code crosses to the wrong canonical skill;
- correct options carry no error diagnosis;
- wrong options keep their diagnostic meaning when answer positions are shuffled;
- input-specific diagnosis is attached only to exact authored wrong answers.

File:
`content/math/practice_v2/p2_functions/diagnostic_catalog.json`

AI remains downstream of these results and may not invent or strengthen a diagnosis.

## Practice ↔ Tour 2 separation

Season 2 Tour 2 was inspected read-only.

The review intentionally allows the same canonical skill to appear in both layers, but rejects cosmetic copies that can be solved by remembering a Practice template.

Two direct inverse-value Practice items were redesigned because Tour 2 already contains the same basic answer form.

Other superficially similar pairs were retained where the evidence role is materially different, for example:
- Practice direct composition vs Tour composite-domain transfer;
- Practice restricted-range work vs Tour inverse-function work;
- Practice direct point mapping vs Tour multi-transformation transfer;
- Practice basic stretch/compression principles vs Tour combined transformation/vertex mapping.

No Tour question, Tour membership or Tour result was modified.

## Current input-evaluator compatibility

All 19 authored input contracts were simulated against the current scalar production evaluator.

Result:
- false acceptance of rejected examples: **0**
- accepted examples currently rejected: **3**

All three blockers are Unicode-minus variants:
- Q110: `−6`
- Q139: `−15`
- Q142: `−32`

This is the same known evaluator-hardening dependency seen in Practice 1. Content is not weakened to work around it.

## AI source-card alignment

Production currently contains one approved, runtime-allowed, original-iClub theory source card for **every P1-FUN-01…08 skill in EN/RU/UZ**: 24 cards total.

The English cards were inspected skill-by-skill and match the governed content:
- FUN-01: function/domain/range/one-one/inverse/composition language;
- FUN-02: restricted-domain range;
- FUN-03: composition order + domain compatibility;
- FUN-04: one-one/inverse/domain-range swap;
- FUN-05: inverse graph reflection in y=x;
- FUN-06: translations;
- FUN-07: coordinate-axis reflections;
- FUN-08: vertical/horizontal scaling and point mapping.

They are marked `original_iclub`, approved and runtime allowed. The default remains to reuse them rather than duplicate them.

## Gate result

| Gate | Result |
|---|---|
| 8 canonical Functions skills covered | PASS |
| No modulus/out-of-P1 leakage | PASS |
| Mathematical bank review | PASS |
| MCQ unique-answer/mechanical structure | PASS |
| Primitive answer-position QA | PASS after rebalance |
| Deterministic diagnostics | PASS |
| EN/RU/UZ structural coverage | PASS |
| Practice/Tour 2 separation review | PASS after redesigns |
| AI source-card availability | PASS |
| Current production input evaluator | BLOCKED — Unicode minus normalization required |
| Production publication | NOT YET |

Next content block under the active plan is Practice 3 — Coordinate Geometry.
