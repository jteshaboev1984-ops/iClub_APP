# Chemistry 9701 — Tour 3 | One-pass result and safe continuation

**Status: READY FOR GUARDED DATABASE COMPLETION; NOT INSTALLED / NOT LIVE.**
**Date:** 2026-10-15. **Subject:** Chemistry (subject_id=4). **Season 2 Tour 3:** id 81, draft/inactive. **Practice 3:** pool id 23.

## Completed educational work

- Verified the current Practice 3 bank of 70 against the 3rd-edition Chemistry coursebook's Chapters 7, 8 and 9, the approved *Tour Map v1.0*, and the existing 20 Season 2 Tour 3 questions.
- Identified 13 redundant/question-overlapping existing Practice positions. Prepared 13 fully authored, trilingual replacements rather than editing the original public.question rows. **57 original Practice items remain KEEP**. Original source IDs: 3116, 3129, 3122, 3118, 3133, 3135, 3140, 3144, 3147, 3149, 3151, 3152, 3157.
- Replaced the previously drafted formal `rate = k[A]²[B]` exercise with Ch.9 interval-rate calculation; created a separate Ch.9 continuous-conductivity monitoring problem. No A-Level-only rate-law claim in the Tour 3 AS source mapping.
- Authored **20 original Tour questions**: Ch7 7, Ch8 7, Ch9 6; 16 MCQ and 4 numeric inputs; difficulty 6 easy, 9 medium, 5 hard, and four MCQ keys A/B/C/D each. Per-question clocks total 2130 seconds (35:30): NOT a global Tour clock.
- Prepared **33 total new question rows**, five with strict explicit **three-significant-figure** answer contracts, in EN/RU/UZ with individual explanations. The 5 numerical keys and dependent calculation ratios were independently recomputed; 798 deterministic authoring QA assertions passed.
- Compared all 33 new English question texts with the present 70 Practice 3 + 20 Season 2 Tour 3 texts; **0 literal duplicates**. Two high lexical similarities are distinct tasks; one resembles an old question that is in the planned replacement set. This is a similarity screen, not an external expert signature.

## Actual database outcome, verified READ-ONLY

1. Created `private.chemistry_t3_stage_20261015`: a private metadata-only staging table (no privileges for anon/authenticated).
2. **10/33** candidate payloads staged. Their `question_id` values remain null: **0/33 new `public.questions` created**, and **0 Tour 3/Practice 3 links switched**.
3. Public Practice 3 is still the previous 70 items; Season 2 Tour 3 remains its prior 20-question draft, inactive, and has zero attempts.
4. Attempting further stage writes hit a platform safety/tool block. **No workaround was attempted.** Do not claim publication or complete production integration.
5. Prior Chemistry Tours 1 and 2, historical student answers, results, ratings, certificates, localStorage, production deployment, GitHub main, and published schedules were **not changed in this Tour 3 pass**.

## Single ordered completion (when the legitimate DB tool is available)

1. `01_stage_to_33_idempotent_DO_NOT_RUN_UNTIL_UNBLOCKED.sql`: complete private stage from 10 to 33. Verify `staged_count=33`, `checksum_errors=0`, `mapped_database_rows=0`. This script is idempotent and does not overwrite existing payloads; a source mismatch is a HOLD.
2. `02_import_33_inactive_drafts_ONLY_AFTER_STAGE33.sql`: atomically create 33 inactive `draft` questions, allocate new ID values and save their ID mapping in private staging. Verify 33 correct multilingual rows with keys/timers, still unlinked.
3. `03_install_5_strict_numeric_and_scoped_scorer_AFTER_IMPORT.sql`: reuse already-tested Chemistry numeric core; install five question-specific policies and insert one new clause into each of the existing Practice/Tour server evaluators, **only** for the five newly imported Chemistry Tour 3 numeric IDs. The script halts if evaluator source MD5s have changed since audit. It does not alter other questions' numerical grading.
4. Before opening content, execute READ-ONLY evaluator regressions (new five numeric keys, all 33 keys, negatives, unanswered Tour, and previously deployed Tours 1–2). Then `04_atomic_practice3_tour3_draft_switch_LAST.sql`: snap old links, activate/publish 33 new questions, replace only the 13 Practice pool 23 links with new IDs, preserve 57 original KEEP entries, and swap the 20 question links **only inside the still-inactive Tour 81 of Season 2**. Transaction aborts on drift and never touches user answer/progress tables.
5. Postflight: Practice 3 70 active questions = 57 KEEP + 13 new; Season 2 Tour 3 20 new questions, Tour 81 remains inactive; Season 1 Tour 3 and previous Tours unaffected, all 33 keys and RU/UZ/EN fields correct. Create one production result report and move to Tour 4.

**No additional branch, isolated project, local/user reset, notifications, Vercel deployment, Season 2 activation or main merge in this execution plan.**

## Artifacts

- `TOUR3_33_TRILINGUAL_PRODUCTION_CANDIDATES.json` — canonical candidate/ID mapping source.
- `TOUR3_20_TRILINGUAL_ORIGINAL_DRAFT.json` — original Tour 3 questions.
- `TOUR3_13_PRACTICE_REPLACEMENTS_FINAL_CANDIDATE.json` — the 13 exact replacement targets and explanation in three languages.
- `TOUR3_AUTHORING_QA.json`, `TOUR3_OFFLINE_QA_RESULT.json` and `offline_qa.py` — self-contained checks.
- Four numbered **not-yet-executed** SQL drafts, each explicitly ordered and release-gated.

**External academic and native-reader signoff and authenticated end-to-end session-save tests were not performed.** These are known residual risks; successful offline tests do not prove them.