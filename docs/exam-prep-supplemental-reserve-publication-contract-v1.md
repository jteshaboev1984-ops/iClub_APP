# Exam Prep supplemental reserve publication contract v1

Date: 2026-09-29  
Status: architecture only; installs a publication guard and **does not publish content**.

## Why this path exists

A normal governed content version contains a complete first-coverage floor for each skill. A supplemental-learning version has its own explicit path for an additional learning pack.

The AW1–4 annual-reserve top-up is different: it deliberately contains only additional diagnostic, delayed-retest and mixed/transfer reserve. Requiring it to duplicate learning and written content would waste reserve and weaken role separation. Allowing it through the normal publication guard without a separate contract would weaken safety.

The new `supplemental_reserve` release mode therefore permits a reserve-only version only when the learner already has a separate fully governed published baseline.

## Required shape

For every skill in a supplemental-reserve version:

- exactly 2 additional diagnostic items;
- exactly 2 additional isolated delayed-retest items;
- exactly 1 additional mixed/transfer item;
- no duplicated written task in the reserve-only version.

All five candidate items remain withheld reserve evidence.

Assessments must be:

- two published diagnostic variants, each with one item per included skill;
- two published one-item retest assessments per included skill;
- one published same-component mixed set with one item per included skill;
- question-only, holdout-only and P1/P5 isolated.

## QA and evidence gates

Before the content version may become published:

- copyright, scope, mathematics, language and technical QA are all PASS;
- diagnostic misconception rules are approved;
- public source questions remain inactive/draft;
- frozen source snapshots match exactly;
- every included skill already has a separate fully governed baseline;
- cross-version annual depth reaches at least 3 diagnostics, 8 learning/transfer items, 4 delayed retests and 2 published written tasks;
- at least 20% of retest/mixed/unseen-capable content remains withheld.

The reserve version cannot establish first coverage by itself.

## Existing paths preserved

The publication trigger keeps all previous branches:

1. supplemental learning;
2. supplemental reserve;
3. normal complete content version;
4. written-only timed/paper version.

The new branch does not relax any previous floor.

## Security

The release profile table remains private. The supplemental-reserve floor is service-role only and is not executable by anon or authenticated browser roles.

## Rollback

Installing this architecture is reversible without learner data repair because it registers and publishes no content. A later content release using this path must use retirement for future selection if rollback is required; learner history is never deleted or rewritten.
