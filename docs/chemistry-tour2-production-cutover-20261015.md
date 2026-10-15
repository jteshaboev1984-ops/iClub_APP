# Chemistry 9701 — Tour 2 database cutover completed

**Date:** 2026-10-15. **Database:** iClub APP production Supabase. **No main/deployment change.**

## Completed database operations

1. Previous operation: 79 new questions imported as inactive drafts (DB IDs 8498–8576, 59 Practice + 20 Tour).
2. Migration `chemistry_t2_strict_numeric_28_scope_20261015`: private numeric rules for 28 input questions and strictly scoped evaluator branches in `public.iclub_eval_practice_question_safe_v4` / `public.iclub_eval_tour_question_safe_v4`.
3. Migration `chemistry_t2_practice_pool18_atomic_cutover_20261015`: active Chemistry Practice 2 pool ID 18 now has exactly 70 linked questions: 59 new and 11 existing untouched question records. All old links retained but the non-target ones are inactive. Practice 2 is live.
4. Migration `chemistry_t2_season2_draft_tour80_question_links_20261015`: Chemistry Tour 2 for **Season 2 only**, tour ID 80, now has 20 newly prepared question links. Its original 20 links remain but inactive. The tour object remains inactive and Season 2 remains `draft`, with no dates. **Tour 2 is staged, not publicly open.**

## Read-only post-cutover checks verified

- Source integrity: 79/79 active and published; RU / UZ / EN stems and explanations complete 79/79, source keys 79/79, timer values 79/79, options for 51 MCQs, numeric policies for 28 inputs.
- Strict numerical regression against the actual PostgreSQL core evaluator: **565/565 PASS** (6 SQL batches).
- Real public Practice and Tour evaluator functions: correct keys accepted **79/79 in each**, malformed keys rejected **79/79 in each**, Tour answered=false yields wrong **79/79**. These are database evaluation calls, not authenticated student answer-save E2E.
- Practice 2: 70 live links; 59 new + 11 old, 24 numeric + 46 MCQ, 70 distinct positions, total per-question timing values 6680 seconds (descriptive sum only, not a global timer).
- Season 2 Tour 2: 20 live *question links inside inactive tour*, 4 numeric questions, 1895 total seconds as per-question sum. Tour ID 80 remains inactive; Season 2 remains `draft`.
- Closed Season 1 Tour 2 (tour ID 66) still has 20 active links and five historical attempts; it was not modified. There were zero attempts or active runtime sessions for the draft Season 2 Tour 2 before its cutover.
- All original 154 Chemistry numeric question IDs retain MD5 `979f55f0e3d95b712a2313e3f8124745`. No original `public.questions` row was edited or deactivated; no user answer, rating, certificate or progress table was written by the three migrations.
- Supplementary syllabus classification: eight source-labelled `BOOK_ONLY_EXTENSION` questions retained as extensions, not counted as independent required Cambridge syllabus outcomes.

## Safe restoration (manual only, NOT executed)

The before-cutover pool-link snapshots are `private.chemistry_t2_pool18_link_snapshot_20261015` (83 rows) and `private.chemistry_t2_tour80_link_snapshot_20261015` (20 rows). They do not include or need student data. The three executed SQL files are preserved for audit, **not for rerunning**. If restoring a previous pool selection, deactivate new pool links and restore old link flags and positions from snapshot **without deleting new question records or their answers**. Leave new question IDs globally active for already-open attempts. Do **not** revert strict scoring while any new numeric question may be answered. A real user-problem incident must be handled as a separate controlled decision.

No authenticated student-session or browser E2E was executed; no new user or fake progress was created. The live user-facing Practice pool switch has been performed and the evaluation/read-only content paths have passed. Scheduling/opening Season 2 Tour 2 remains a separate calendar and access action.