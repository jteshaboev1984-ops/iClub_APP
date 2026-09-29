# Exam Prep AW1–4 annual reserve release v1

Date: 2026-09-29  
Scope: content versions `4803` (P1) and `4804` (P5).

## Release contents

The release adds governed reserve depth for the nine AW1–4 skills:

- 18 additional diagnostic items;
- 18 additional isolated delayed-retest items;
- 9 additional mixed/transfer items;
- 54 approved misconception rules for the new diagnostics;
- 24 governed holdout assessment containers.

It adds no duplicate written tasks and no new teaching pack.

## Resulting annual depth

For each target skill, the governed cross-version bank reaches:

- 3 diagnostic items;
- 8 learning/transfer items in total;
- 4 delayed-retest items;
- at least 2 published written tasks.

All new diagnostic/retest/mixed items remain `reserve` + `withheld`.

## Publication model

Versions 4803/4804 use release mode `supplemental_reserve`.

That mode is allowed only when a separate published full-floor baseline already exists for every included skill. It cannot establish first coverage and cannot bypass the normal scope, mathematics, language, technical, copyright, diagnostic-rule, holdout, source-isolation or annual-depth gates.

## Learner and legacy safety

At release preflight the target versions must have:

- zero Exam Prep learner sessions;
- zero Practice answer references;
- zero Tour answer references.

The release does not modify users, existing progress, existing evidence, Practice/Tours attempts or answers, certificates, ratings, localStorage, or historical sessions.

## Runtime boundary

Release is valid only under the current controlled-beta boundary:

- Core ON;
- AI Assist OFF;
- Mentor Care OFF;
- kill switch OFF.

## Rollback

Rollback retires future selection:

- retire the reserve assessments;
- set the new reserve metadata exposure to `retired`;
- retire the content versions.

No content row, learner response, evidence event or historical session is deleted or rewritten.
