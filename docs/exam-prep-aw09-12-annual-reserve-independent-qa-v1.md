# Exam Prep AW9–12 annual reserve — independent QA v1

Date: 2026-09-30  
Versions: P1 `4811`, P5 `4812`  
Status after review: **draft / withheld / holdout / not learner-selectable**

## Review boundary

This review covers the complete AW9–12 annual-reserve draft only:

- 70 machine items;
- 28 diagnostic items;
- 28 delayed retests;
- 14 mixed/transfer items;
- 84 diagnostic misconception rules;
- 34 holdout assessment containers.

It does not publish the reserve, expand the beta cohort, enable AI Assist or Mentor Care, or alter existing learner evidence, Practice, Tours, certificates, ratings or localStorage.

## Independent evidence-freshness review

The draft was compared skill-by-skill against the already governed baseline and the published AW9–12 supplemental-learning pack.

A lexical-overlap screen was used only as a detection aid; every flagged item was then reviewed for mathematical structure and evidence role. The review found multiple cases that were mathematically correct but too close to an already published teaching/diagnostic/retest template to be strong annual reserve evidence.

## Corrections

Thirty-eight draft items were materially strengthened before any publication review.

The changes include:

- replacing number-swapped arc-length, circle, inverse-function, cumulative-frequency, spread, combinations and probability templates;
- replacing a box-plot delayed retest that was effectively the same reverse-fence question as a published learning item;
- replacing direct point-swap inverse-graph checks with reflection geometry, distance, gradient and fixed-point transfer;
- replacing direct line/parabola repeats with setup, inverse-parameter and alternative simultaneous-equation evidence;
- replacing repeated transformed-quadratic solution-count templates with substitution recognition, reverse-parameter and structurally different transformed expressions;
- replacing repeated standard-deviation/IQR/range scaling questions with conceptual transformation and combined-measure transfer;
- replacing repeated independence/product templates with conditional, union and reverse inference.

All corrected learner-facing surfaces were updated symmetrically in EN/RU/UZ. Frozen source snapshots were refreshed only for the corrected draft rows.

## Safety locks

The draft contract now additionally pins the 38-item independent-QA answer map and representative corrected stems. Existing gates still require:

- exact 70-item role cardinality;
- prospective annual floor of 3 diagnostics, 8 learning/transfer machine items, 4 delayed retests and at least 2 written tasks per target skill;
- all reserve items draft/withheld;
- every assessment item holdout;
- 84 complete trilingual misconception rules;
- exact source snapshots;
- no exact same-skill published stem reuse;
- no learner session, Practice or Tour references;
- unchanged controlled-beta Core-only feature boundary.

## Decision

**NOT PUBLISHED by this review.**

The safe next step is to run the full CI matrix, merge the QA correction only after GREEN, apply it to the history-free production draft, verify production invariants again, and only then prepare a separate governed `supplemental_reserve` publication.
