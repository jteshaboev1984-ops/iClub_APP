# Exam Prep supplemental learning publication contract v1

Status: **architecture only; no content release performed by this change**

## Problem

The original content-version publish guard correctly assumes that a normal question-bearing content version is a complete governed skill floor: diagnostic + learning + retest + mixed + written evidence. A second learning pack intentionally contains only additional learning practice. Treating it as a normal full-floor version would either block publication or tempt duplication of protected diagnostic/retest content.

## Decision

Keep the original full-floor rule unchanged by default. Add one explicit private release mode:

- `supplemental_learning`

A content version receives this mode only through a private, versioned release-profile row. Absence of a profile means the existing full-floor/written-only rules continue exactly as before.

## Supplemental-learning gate

A registered supplemental version can publish only if all of the following are true:

1. Every included canonical skill already has a separate, fully governed published baseline.
2. The supplemental version contains only learning-role machine questions.
3. Each included skill has exactly three QA-passed learning questions.
4. Each included skill has exactly one QA-passed written task/rubric.
5. Exactly one published learning assessment per skill contains those three machine items plus that written task.
6. No holdout, diagnostic, retest, mixed, timed or unseen role can enter the supplemental version.
7. Public source-question rows remain inactive/draft; delivery remains through governed Exam Prep assessments.
8. Question snapshots remain exact.
9. If the release profile requires written-understanding companions, each written task has exactly one published, QA-passed companion check.
10. Browser roles receive no direct access to the release-profile table or guard helper.

## Authority and rollback

Supplemental content can add practice variety but cannot establish first syllabus coverage, mastery, placement or readiness. The deterministic engine and existing P1/P5 component boundary remain unchanged.

Rollback is two-layered:

- learner delivery can be stopped by retiring/unpublishing the supplemental assessment/content version without rewriting historical responses;
- the architecture extension can be superseded by a later migration restoring the prior publish-guard definition. Existing full-floor and written-only branches remain present in this version.

No feature flag, entitlement, AI setting, Mentor Care setting, legacy Practice/Tour content, user progress or localStorage is changed by this architecture migration.
