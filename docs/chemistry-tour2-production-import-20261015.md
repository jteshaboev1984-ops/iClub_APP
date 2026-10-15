# Chemistry 9701 — Tour 2 | Production database import result

**Date:** 2026-10-15 (UTC). **Database:** iClub_APP Supabase (`mmmduffgpvwjdpruzikw`).

**Outcome:** Successful content-only draft import, separate from user-facing publication.

## Content import

- Source archive: `Chemistry_9701_Tour2_FINAL_OFFLINE_RC_2026-10-15.zip`.
- 79 new question rows in `public.questions`: 59 Practice + 20 Tour.
- 28 numerical input, 51 MCQ.
- New generated database IDs: **8498–8576** (79 distinct IDs).
- All 79 records have `subject_id=4`, `quality_status='draft'`, `is_active=false`, `quality_flag=NULL`.
- 79/79 exact matches to staged source records on all stored question, explanation, option and translation fields, answer key, difficulty, topic/subtopic, book reference and individual time limit.
- 59 new Practice question time limits sum to 5840 seconds as a descriptive sum only (there is no global timer). Twenty Tour time limits sum to 1895 seconds as a descriptive sum only.
- 8 source-labelled `BOOK_ONLY_EXTENSION` supplementary questions remain so labelled in the private staging registry; not counted as independent mandatory syllabus outcomes.

## Provenance and mapping

- Private staging/mapping relation: `private.chemistry_t2_stage_20261015`.
- 79 source `candidate_id` identifiers each map to exactly one new `public.questions.id` in column `question_id`.
- JSON content and MD5 fingerprint for each candidate preserved in the mapping relation.
- Migration `chemistry_t2_stage_bank_20261015` created the staging table; `chemistry_t2_79_inactive_questions_20261015_v2` imported questions atomically.
- An earlier attempted migration was stopped and rolled back by the live `questions_quality_flag_check` constraint (only NULL or `A` allowed). It inserted **zero** committed question rows. The corrected migration uses `quality_flag=NULL`.

## Existing production preserved

- Chemistry rows before import: 867; after import: **946**.
- Old Chemistry input rows: **154**, frozen ordered-ID MD5 `979f55f0e3d95b712a2313e3f8124745` unchanged.
- Existing Practice 2 (pool ID 18): **70 active linked questions**, unchanged.
- All 11 previously selected KEEP IDs retained as active, published and unmodified. Existing KEEP timers sum 840 seconds, unchanged.
- Other-subject questions after import: 5927; no other-subject insert in migration.
- All new question rows have **zero links** in `public.practice_pool_questions` and `public.tour_questions` and are **not available to learners**.
- No changes to historical answers, user progress, ratings, certificates or notifications; no schema change to old scoring functions or frontend, no deployment to production.

## Remaining release implementation

This database import **is finished**. User-facing activation is **not** part of it. To switch the active Practice 2 bank and Tour 2, first install question-ID-scoped strict numeric answer handling for the 28 inputs and verify the three answer submission paths; then perform an explicit content switch that does not delete historic pool/tour links or reset existing user data. Tour 2 has more than one season instance in the live database, so a season-specific publication decision is essential. No notification, access or reset should be inferred from the import.

**Result:** 79/79 inserted correctly; no existing user-facing content switched.