# P5 initial eight: RU/UZ option remediation protocol (DRAFT, 21 Sep 2026)

Related: #137 (ten untranslated prose-choice questions), #126 (independent assessment-composition review). Not a production migration or approval.

## Verified scope (read-only)

- Exactly ten question IDs with English-language prose in RU/UZ options: 6249, 6250, 6251, 6252, 6253, 6254, 6258, 6267, 6268, 6269. Four other MCQ option arrays in the opening slice are numeric-only and do not require translation. Six other P5 matches in the wider audit are symbolic/notation-only controls, NOT proven translation defects.
- One finalized P5 diagnostic session has one frozen affected item and one saved answer; no currently active session on the eight original sets at inspection time. All Exam Prep sessions observed fall within the three active beta accounts, which the owner says are all the owner's test accounts. No assertion about identity verification or permission to delete unrelated user records is implied.
- Affected question IDs 6249 and 6251 are also referenced by single-retest assessments; IDs 6267 and 6268 by canonical mixed assessments. Validate all twelve relevant assessment memberships, not only the original eight sets. Preserve reserve/holdout confidentiality.
- The legacy `public.questions` rows are deliberately `is_active=false`, `quality_status='draft'`; the private content metadata controls Exam Prep availability. Do not activate legacy question pools or alter Practice/Tours.

## Prepared but intentionally NOT committed

A private reviewer-only file `p5_ru_uz_options_candidate_20260921.json` contains the 10 proposed Russian and Uzbek answer-choice arrays (80 strings). It is **not** checked into this publicly visible repository because some questions are protected diagnostic/retest/mixed items. The proposed strings are AI-prepared candidates only. Independent qualified mathematical review and RU/UZ linguistic sign-off are still REQUIRED; do not record or infer human approval before it occurs. Review question wording, answer uniqueness, distractors, option order, P5 syllabus alignment and whether one mixed question ambiguously pairs a mean with a later median/spread comparison.

## Release approach (not authorized)

1. Freeze a fresh read-only full baseline: exact ten IDs, all assessment memberships, the three active beta-account IDs, all frozen session items and responses, current QA metadata and 10 current question snapshot hashes. Reconfirm no non-beta accounts or new active sessions reference these objects. If the assumptions change, stop and redesign; test-account claim alone is not evidence that every referenced record is disposable.
2. Compare proposed localized options with the original English positions A–D. Review all ten mathematical meanings independently, RU and UZ readability at mobile width, unchanged correct choice positions, and all downstream uses. Reconcile #126 composition-level approval independently; item-level `qa_language_status=pass` cannot serve as human sign-off.
3. Choose a genuinely scoped data change only after reviewer approval. Since the owner explicitly does not require retention of **these Exam Prep test attempts**, an uncomplicated in-place option correction may be considered ONLY if preflight proves all historical/frozen/session/API/hash contracts remain valid or a separately authorized reset can be limited exactly to those test Exam Prep objects. Never silently delete test accounts, Practice/Tours progress, certificates, rankings, or any unrelated academic data. If contracts cannot be proven, use new question/content versions instead. Do not mutate preexisting migration history or counterfeit `approved_at`.
4. An authorized migration must pin exact expected old option arrays and metadata hashes, verify protected exposure, prevent concurrent active affected sessions, update only agreed content in one atomic transaction, and have a separately tested safe rollback that does not rewrite any non-test evidence. Run disposable PostgreSQL and RU/UZ/EN visual checks before proposing a production operation.
5. Recheck affected and unaffected question populations, memberships and all user-data fingerprints. Do not merge/release, run production DML, expand beta or alter Core/AI/Mentor flags without separate owner approval.

## Preventing recurrence

Isolated synthetic helper `scripts/exam-prep-p5-option-language-guard.cjs` detects unchanged English **prose** options in either RU or UZ but explicitly excludes numeric/symbolic answer choices. CI executes only synthetic data, never source assessment payloads or a production query. Future authoring/publish pipeline must invoke a reviewed version of this helper against private candidate objects, in addition to human trilingual QA; this PR does not yet install that production gate.

**State:** protected translations prepared privately, generic detection regression drafted in public code, no human sign-off, no release or production SQL. Future correction may discard only specifically approved test-session history, not entire users or any non-test data.
