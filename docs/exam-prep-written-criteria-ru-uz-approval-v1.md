# P1/P5 written criteria — reviewed RU / UZ localization

Status: technical approval workflow, NOT an academic translation approval.
Sources: Content Governance Model P1/P5 v1.1 and docs/exam-prep-written-learning-contract-v1.md.

## Production audit, 26 October 2026

P1: 130 published written tasks with 674 English criterion rules.
P5: 103 published written tasks with 540 English criterion rules.
Together: 233 tasks, 1,214 criterion rows, 1,199 unique English rules.
RU approved source values: 0 / 1,214. UZ approved source values: 0 / 1,214.
The pre-existing per-task qa_language_status=pass DOES NOT indicate rubric-rule RU/UZ equivalence approval.
All criterion identifiers are nonblank and unique within each source task/version.

## Technical fix

- Approved RU and UZ values are held in private.exam_prep_written_criteria_locale_v1, keyed to task ID, original task version, criterion ID, locale and English-rule checksum.
- A translation must have independent academic/language review references and a review timestamp.
- Draft translations, incomplete translations, mismatched checksum and unreviewed translations are NOT shown as approved.
- Already approved records cannot be silently edited or deleted; correction requires a new task version and a new academic workflow.
- Original English rule, marks, response rows, evidence, score, mastery, history and active sessions are not edited.
- The existing safe learner criteria RPC returns a reviewed locale only for a learner's own active learning item. Future items and other learners stay inaccessible.
- The P1/P5 activation trigger rejects enabling a component until 100% of its published QA-passed rubric rules have approved RU AND UZ values, or pre-existing reviewed inline localizations.
- Production stays OFF with empty allowlist until both academic review and owner release approval are complete.
- The learner UI explains that translated criteria are not yet approved. Optional Next remains independent of viewing criteria.
- Existing timed/paper mark-scheme visibility and server authority remain unchanged.

## Reviewer-only process

1. Use a PRIVATE admin environment to run a SELECT over published written task IDs, task_version, criteria id/order, English rule, source rule MD5 and source mark allocation. Never commit protected rubric texts to public GitHub, screenshots or an unsecured spreadsheet.
2. Translate EACH of the 1,214 English rules into accurate RU and UZ. Preserve notation, intervals, mathematical meaning, numerical accuracy, restrictions, and allocated marks.
3. Independent mathematics and native-language reviewers must approve each locale against its EXACT task version / criterion ID. English texts, original marks and source versions remain immutable.
4. A service-role-only publishing transaction may insert approved translations after recording both reviewer evidence references. Merely setting qa_language_status=pass is insufficient.
5. Run the private read-only coverage SQL in scripts/fixtures/math-written-localization-coverage.sql: missing_ru and missing_uz must both equal 0 for BOTH P1 and P5.
6. Repeat disposable PG17 + 68 Chromium scenarios, then controlled-beta authenticated smoke. Only then may the owner explicitly activate the three already consented Mathematics beta accounts.
7. Rollback means flags OFF, NEVER deleting old advances, answers, or reviewed locale records.

No English fallback disguised as RU/UZ; no AI-generated approval; no synthetic marks or mastery. This document contains NO private rubric text.