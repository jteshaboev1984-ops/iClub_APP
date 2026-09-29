# Exam Prep AW5–8 annual reserve — independent QA v1

Date: 2026-09-29  
Scope: canonical AW5–8 E2 block only  
Versions: P1 `4807`, P5 `4808`  
Status after this change: **draft / withheld / not learner-selectable**

## Boundary

This review does not publish content, expand the cohort, enable AI Assist or Mentor Care, or mutate learner evidence/history. Existing Practice/Tours/ratings/certificates/localStorage remain outside this change.

The governing scope is the canonical P1/P5 registry derived from Cambridge 9709. Complete Pure Mathematics 1 and Complete Probability & Statistics 1 are mapping/explanation aids only; no protected source question, answer, mark-scheme wording or diagram is copied.

## Independent review completed

The full 70-item AW5–8 annual-reserve candidate surface was independently checked:

- P1: 40 machine items across 8 skills.
- P5: 30 machine items across 6 skills.
- 28 diagnostic items and all 84 diagnostic misconception rules.
- 28 isolated delayed-retest items.
- 14 mixed/transfer items.
- RU/UZ/EN learner-facing wording for the reviewed reserve.
- Correct answers and explanations were independently recalculated/re-solved.

The draft remains structurally correct: exactly +2 diagnostic, +2 isolated retest and +1 mixed item per target skill; no new written task is needed because every target skill already has at least two governed written tasks.

## QA finding

No remaining wrong answer key was found after the already-merged TATTOO repeated-letter correction. The main independent-review issue was **evidence freshness**: several delayed-retest items were mathematically correct but too close to published teaching/retest templates and therefore weaker than intended as delayed evidence.

Thirteen retests are strengthened:

### P1

- `P1FUN06-R03`: inverse translation from a transformed minimum.
- `P1FUN07-R04`: inverse point mapping under both-axis reflections; removes the awkward “translation through the origin” distractor.
- `P1FUN08-R04`: inverse point mapping under horizontal/vertical scaling.
- `P1COO01-R03`: recover intercept from two points instead of direct rearrangement.
- `P1COO02-R04`: recover an endpoint from a midpoint.
- `P1COO03-R03`: derive a perpendicular line from the gradient of a line through two points.
- `P1CIR01-R03`: mixed radians/degrees transfer rather than a bare conversion.
- `P1TRI01-R03`: infer amplitude from graph range.

### P5

- `P5CNT01-R03`: combine unordered committee selection with ordered role assignment.
- `P5CNT02-R04`: infer `n` from a permutation count.
- `P5CNT03-R03`: identify the repeated-object overcount factor.
- `P5CNT04-R03`: fixed-end restriction with internal order.
- `P5PRO01-R03`: infer a missing sample-space factor.

These remain inside their canonical skill definitions and do not cross-credit P1/P5 mastery.

## Safety invariants

The correction migration fails closed unless:

1. versions 4807/4808 exist and are still draft;
2. the exact 40/30 candidate surfaces exist;
3. no learner Exam Prep session references the versions;
4. no Practice/Tour history references any target question;
5. all source question rows are inactive and draft;
6. all 13 correction targets exist;
7. corrected trilingual surfaces are complete;
8. corrected answers match the independently solved answer map;
9. corrected retests do not exactly reuse a published same-skill English stem;
10. frozen source snapshots are refreshed and exact.

## Publication decision

**NOT PUBLISHED by this review.**

After this independent-QA change is green, the safe sequence remains:

1. install the four draft authoring migrations and this correction migration into production;
2. verify versions 4807/4808 remain draft/withheld and history-free;
3. run the governed `supplemental_reserve` release floor;
4. only then prepare a separate publication migration + release contract + retirement rollback rehearsal.

Core remains controlled-beta; AI Assist and Mentor Care remain OFF.
