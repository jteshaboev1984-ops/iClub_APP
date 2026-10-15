# iClub APP — Chemistry 9701: Tours 1–7 production installation COMPLETED

**Verified 2026-10-15.** Supabase production project `mmmduffgpvwjdpruzikw`. This is a record of actual database operations, not an offline plan. Original source map: `Tour Map v1.0 — Chemistry`; question sources: coursebook/Lawrie 3e and existing tour candidate packages.

## All seven live Practice banks

| Tour | Practice pool ID | Published/available | New Practice questions | Preserved existing Practice questions | Live numeric / MCQ |
|---|---:|---:|---:|---:|---:|
| 1 | 22 | 70 | 50 | 20 | 20 / 50 |
| 2 | 18 | 70 | 59 | 11 | 24 / 46 |
| 3 | 23 | 70 | 13 | 57 | 12 / 58 |
| 4 | 21 | 70 | 3 | 67 | 13 / 57 |
| 5 | 19 | 70 | 4 | 66 | 2 / 68 |
| 6 | 20 | 70 | 4 | 66 | 4 / 66 |
| 7 | 24 | 70 | 4 | 66 | 4 / 66 |
| **Total** | | **490** | **137** | **353** | **79 / 411** |

All seven Practice pools have **70 distinct active ordering positions**. Old question records are not globally disabled or deleted; prior pool links are retained but non-target links are inactive. No user answers, saved progress, ranking or certification tables were written by these installations.

## All seven Season 2 Tour banks

| Tour | Season 2 tour ID | New original questions linked | Input / MCQ | Tour open? |
|---|---:|---:|---:|---|
| 1 | 79 | 20 | 4 / 16 | No |
| 2 | 80 | 20 | 4 / 16 | No |
| 3 | 81 | 20 | 4 / 16 | No |
| 4 | 82 | 20 | 4 / 16 | No |
| 5 | 83 | 20 | 4 / 16 | No |
| 6 | 84 | 20 | 4 / 16 | No |
| 7 | 85 | 20 | 4 / 16 | No |
| **Total** | | **140** | **28 / 112** | **All closed** |

Season 2 remains **`draft`**. No Season 2 Tour was opened, scheduled, or given dates and **all seven have zero attempts**. Previous Season 1 Tour links were not modified; **43 historic attempts** remain. In particular, a historical Season 1 Tour7 active flag was outside the authorised Season 2 content cutover and remains a separate access review item.

## New question records and assessment checks

- **277** distinct new Chemistry question IDs (70 Tour1 phase, 79 Tour2 phase, 33 Tour3, 23 Tour4, 24 Tour5, 24 Tour6, 24 Tour7). **277/277** new question records are active and published; **277/277** have EN/RU/UZ stems and explanations and individual time limits. Chemistry question table total **1,144** (previously 867 before these phases).
- Both production evaluator functions were executed directly against every one of the 277 new IDs. Each passed all **five** checks: correct Practice answer accepted, correct Tour answer accepted, deliberately invalid Practice and Tour answers rejected, and unanswered Tour result rejected. **277/277**, zero failures (**1,385 individual assertions**).
- Strict Chemistry input evaluation: **28/28** new Tour4–7 policies present and ready (12 integer-only, 15 significant-figures, 1 decimal-places). Their canonical answers, incorrect precision examples, and nonnumeric inputs were tested: **28/28** in each category. Additional real tests passed on scientific notation, mandatory positive sign, and decimal precision. Previous Tour3 **5/5** numeric policies ready; prior Tour1/Tour2 routes remain intact.
- Original 154 Chemistry numeric question ID fingerprint still `979f55f0e3d95b712a2313e3f8124745` (MD5 of the ordered ID list).
- **Change scopes:** question records, controlled links in specified Practice pools and draft Season2 Tours, and two scoped evaluation functions only. All user progress/history tables, season dates, schedules, client code, GitHub main and Vercel were not changed by the release.

## Recorded release migrations executed successfully

1. `chemistry_tour3_stage_33_atomic_source_verified_20261015`
2. `chemistry_tour3_add_33_inactive_drafts_20261015`
3. `chemistry_tour3_scoped_numeric_policy_and_dispatch_20261015`
4. `chemistry_tour3_practice23_tour81_atomically_cutover_20261015`
5. `chemistry_tour4_7_scoped_strict_numeric_infrastructure_20261015`
6. `chemistry_tour4_atomic_content_and_practice_cutover_20261015`
7. `chemistry_tour5_atomic_content_and_practice_cutover_20261015`
8. `chemistry_tour6_atomic_content_and_practice_cutover_20261015`
9. `chemistry_tour7_atomic_content_and_practice_cutover_20261015`

The previously executed Tour1/Tour2 migrations also remain recorded in Supabase. The new Tour3–7 SQL migration source files are included in the accompanying archive. Do not rerun them; they are intended as an audit record.

## Restoration assets (manual guarded incident response only)

- Earlier Tour1/Tour2 original pool and Tour link snapshot tables in `private` remain.
- For Tours3–7, both original Practice and Tour link snapshots are stored in `private.chemistry_t{tour}_pool{pool}_original_links_20261015` and `private.chemistry_t{tour}_tour{tour_id}_original_links_20261015`. Confirmed snapshot row counts: T3 **70/20**, T4 **90/20** (Pool4 had 20 pre-existing inactive links), T5 **70/20**, T6 **70/20**, T7 **70/20**.
- Function backups stored in private audit tables, including `private.chemistry_release_evaluator_backup_20261015` and `private.chemistry_t3_evaluator_before_backup_20261015`.
- Do not delete imported question rows, delete user answers, reset localStorage, or downgrade scorer while new question attempts could exist. Restoring link memberships requires a separately approved, fresh state check.

## Remaining product work — not another content implementation cycle

The **database installation and server evaluation checks are complete**. An authenticated end-to-end student session through the real web UI was not executed; no claim is made about a completed browser E2E. Opening Season 2 and confirming its dates/access is a **separate decision**. The eight Tour2 coursebook-only supplementary items are still labelled as supplements, not independent official syllabus outcomes.

This file supersedes the old Chemistry HOLD and offline-only status descriptions. Tours3–7 are no longer on installation hold.