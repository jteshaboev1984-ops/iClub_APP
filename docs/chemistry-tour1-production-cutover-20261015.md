# Chemistry 9701 — Tour 1 production cutover (2026-10-15)

**Status: Practice 1 LIVE; Season 2 Tour 1 PREPARED/CLOSED.** Main/Vercel and student records untouched.

## Verifiably completed

- Source: `Chemistry_9701_Tour1_v3.15_OFFLINE_QA_2026-10-14.zip` under original Tour Map v1.0 (chapters 1–3). Eight `CURRENT_8_LEGACY_NEW_VERSION_PATCHES.json` deltas were resolved against original active production questions to make new fully filled question rows. All historical originals retained.
- Candidate registry: `private.chemistry_t1_stage_20261015` 70 new IDs, **9237–9306**, consists of **42 authored Practice + 8 version-safe rebuilt Practice + 20 authored Tour**. Existing **20 KEEP Practice IDs** preserved.
- All 70 new question records imported as inactive first; 62/62 authored EN/RU/UZ and answers matched source snapshot, 8 patch clones derived from approved source rows. After policy readiness and checks, marked published/active. Old rows were not edited or globally disabled.
- Applied question-owned policy `private.chemistry_t1_typed_policy_20261015`: 17 new typed inputs + two exact legacy chemical formulas = **19**. Supports explicit significant figures, fixed decimal place, integer literal and case-sensitive chemical formulas, with optional typographic subscripts only where prompt allows. Public Practice/Tour evaluators selectively dispatch by exact scoped question IDs. Chemistry Tour 2 grader remains scoped separately, and other subjects remain on their previous pathways.
- **190/190 real PostgreSQL typed-policy regression cases PASS** after two faulty test *expectations* were corrected. Live Practice/Tour evaluator checks for every new question were executed inside an explicitly rolled-back temporary activation. After switch, **70/70 Tour 1** and **79/79 Tour 2** correct/incorrect/timeout checks passed for both evaluator paths.
- Practice 1 `pool_id=22` active exactly **70** = **50 new + 20 unchanged**; 20 inputs; 70 unique positions. Previous 70 links preserved in `private.chemistry_t1_pool22_original_links_20261015` and original non-KEEP links archived as inactive, not deleted.
- Tour 1 Season 2 `tour_id=79` active **question links** exactly **20 new** (4 inputs); old 20 links archived in `private.chemistry_t1_tour79_original_links_20261015`. Tour itself remains INACTIVE, Season 2 remains DRAFT with no dates.
- Closed Season 1 Tour 1 ID 65 retains all 6 prior attempts and 20 questions. Practice 2 remains 70 live questions. No data reset, student notifications, score recalculation, or Vercel deployment.

## Two non-content obstacles corrected during operation

1. Original private staging `DO` block accidentally shadowed a SQL table alias with an unassigned PL/pgSQL `record`. Replaced identifier; initial transaction did not write candidate rows.
2. Historic Practice 1 pool used `order_no=1` on all 70 memberships. Final atomic switch retained legacy links and assigned a deterministic 1–70 order by original question ID for currently available rows. Initial preflight attempt rolled back.

## Purposeful source correction

The 2026-10-14 regression CSV expected that Tour 1 question 08 would accept `0.09` although its authored EN stem expressly requires **three significant figures** and its key is `0.0900`. New server policy uses the question's required precision; `0.0900` accepted, `0.09` rejected. Two erroneous *test-fixture* expectations (integer-only decimal equivalent; unchanged `MgO` subscript replacement) were also corrected before the final 190-case PASS. The original 2026-10-14 archive remains immutable.

## Residual release boundary

A complete user-authenticated browser answer-save E2E was not executed and is not claimed. Season 2 opening/schedule and related notifications are separate and unchanged. A targeted case-specific fix may still be warranted if a real user reports an issue, without undoing past answers. The former offline independent academic/native-language reviewer HOLD is not misrepresented as independent human signoff.

## Next

Tour 3 chapters 7–9: inspect current Practice 3 (pool 23), retain valid questions; author 20 *new* Season 2 Tour 3 tasks, typed scoring, per-question timing, then perform the same atomic history-preserving switch for pool 23 and season-2 Tour 81. Do not rewrite Tour 1 or Tour 2 absent an identified defect.