# Exam Prep AW9–12 supplemental learning — independent QA v1

Date: 2026-09-30  
Versions: P1 `4809`, P5 `4810`  
Status after this review: **draft / withheld / not learner-selectable**

## Boundary

This review is limited to the AW9–12 supplemental-learning draft. It does not publish content, expand the beta cohort, enable AI Assist or Mentor Care, or mutate learner evidence/history, Practice, Tours, ratings, certificates or localStorage.

The canonical 81-skill P1/P5 registry and Cambridge 9709 scope control the academic objective. Complete Pure Mathematics 1 and Complete Probability & Statistics 1 are mapping/explanation aids only; no protected question, solution, diagram or mark-scheme wording is copied.

## Independent review completed

The complete candidate surface was reviewed after draft installation:

- P1: 24 machine learning items across 8 skills;
- P5: 18 machine learning items across 6 skills;
- 14 written tasks;
- 14 written-understanding checks;
- 14 learning assessment containers, each exactly 3 machine items + 1 written task;
- EN/RU/UZ learner-facing wording;
- mathematical answer/explanation checks;
- comparison against already-published same-skill learning, diagnostic, mixed and retest content.

## Findings and corrections

The first draft was structurally safe but several items were too close to already-published templates. Eighteen machine surfaces were strengthened or corrected before publication can be considered.

Key changes include:

- P1 quadratic inequalities: replaced direct opposite-inequality/number-swap variants with different structures and contextual transfer.
- P1 simultaneous relations: replaced the same line/parabola pair already used by a published diagnostic.
- P1 transformed quadratics: replaced a published-retest equation with a different transformed equation.
- P1 inverse graphs: strengthened point-swap evidence with an additional midpoint/reflection property.
- P1 inverse-function intersection: removed an overbroad explanation and replaced it with a direct algebraic verification for the specific linear function.
- P1 circles: replaced a simple centre/radius number-swap with a diameter-endpoints reconstruction task.
- P1 circular measure: replaced direct formula number-swaps with perimeter and equal-angle transfer tasks.
- P5 box plots: strengthened comparison and reverse outlier-fence reasoning.
- P5 spread: replaced a bare range number-swap with transformed-data reasoning.
- P5 combinations: replaced direct committee number-swaps with exact-one restriction and complement counting.
- P5 probability via combinations: strengthened selection structures and removed an answer leak from the stem.
- P5 multiplication/independence: replaced a direct numerical variant with reverse conditional-probability reasoning.

Learner-facing assessment titles were also changed from internal release language such as “supplemental learning” to natural “additional practice” wording in EN/RU/UZ.

## QA locks

The draft contract now locks:

1. exact 24/18 machine cardinality;
2. 14 written tasks and 14 understanding checks;
3. 14 exact 3+1 assessment packs;
4. trilingual completeness and unique MCQ options;
5. component answer-position balance;
6. the 18 corrected answer keys;
7. representative corrected stem invariants, including removal of the P5 probability answer leak;
8. absence of internal release wording in learner-facing titles;
9. exact frozen question snapshots;
10. no exact published same-skill English-stem reuse;
11. zero Exam Prep learner sessions and zero Practice/Tour references.

## Publication decision

**NOT PUBLISHED by this review.**

Safe next sequence after CI is green:

1. merge this independent-QA correction;
2. apply the correction migration to production while versions 4809/4810 remain draft and history-free;
3. verify production state and baseline counts;
4. prepare a separate governed `supplemental_learning` publication migration and release contract;
5. publish only if the existing supplemental-learning floor and independent release audit are green.

Core remains controlled beta. AI Assist and Mentor Care remain OFF.
