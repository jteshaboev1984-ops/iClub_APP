# iClub APP / Chemistry 9701 — Tour 3 continuation and Tour 4 content handoff

**Date:** 2026-10-15. **Release stage:** TOUR 3 BLOCKED / TOUR 4 CONTENT-ONLY CANDIDATE. Do not mistake this artifact for production installation.

## Immutable source of truth

- Tour 3: `TOUR3_33_TRILINGUAL_PRODUCTION_CANDIDATES.json` — SHA256 `1d8ade083da2c1f670facb2144f95efb506aca2d775a2a8becb4d73155ab3344`. Distribution: 13 Practice replacements and 20 Tour, five typed inputs.
- Tour 4: `TOUR4_23_TRILINGUAL_OFFLINE_RELEASE_CANDIDATES.json` — SHA256 `6c8e08af7e942be4cd29fb968728ca9f9d8b5ae0dac2b8cd155ee7ac2b37be51`. Distribution: 3 Practice replacements, 20 new Tour, six typed inputs total.
- Tour 4 live original Practice baseline: **70 existing IDs**, 67 KEEP, 3 REPLACE (old `3353`, `3380`, `3406`). Supabase SELECT-only verified that there were zero missing and zero unexpected IDs. Original #3406 is referenced by **closed Season 1 Tour 4 ID 68**, so NEVER globally deactivate/delete/edit this record. Change only the Practice 4 membership at future cutover.

## Tour 3: latest verified state, no production cutover

Supabase (`mmmduffgpvwjdpruzikw`): private `chemistry_t3_stage_20261015` has 10 candidates, all `question_id=NULL`, 0 checksum mismatches. Old Practice 3 pool 23 still serves 70 questions and draft Season 2 Tour 3 (`tour_id=81`) retains 20 old links and 0 attempts; Season 2 is draft. **No new Tour 3 question imported to public.questions.**

Read-only analysis of all seven original offline stage scripts confirmed their 33 contained JSON objects exactly match the frozen source; the first two scripts contain the ten staged candidates. Corrected `01_ATOMIC_STAGE33_CORRECTED_NOT_EXECUTED.sql` addresses a concrete safety defect in the prior stage script: previous `ON CONFLICT DO NOTHING` did not compare retained row content to the current source. The corrected design holds a table lock, validates 33 unique source IDs, refuses any existing source mismatch, inserts only missing candidates, and asserts full equality before commit. This SQL is **NOT EXECUTED** and is not permission to bypass the platform safety denial.

Normal next dependency, only when explicitly allowed by the platform's tool protections: complete Tour 3 staging, import 33 inactive drafts, install five numeric policies with the exact current evaluator checksum gates, atomically link Practice 3 and draft Tour 3. Before any action re-read actual baseline. If a platform safety control blocks it, STOP; do not retry through alternate channels.

## Tour 4: finished original content draft, not database-installed

- Existing Practice pool ID 21: **70 questions**, breakdown Periodicity 17, Group 2 16, Group 17 20, Nitrogen 17 (verified via Supabase READ-ONLY). The complete existing ID set was checked against the packaged manifest.
- **67 KEEP + 3 NEW replacements** (original IDs 3353, 3380, 3406); preserve the two legacy INPUT positions by replacing #3353/#3406 with different **three-significant-figure calculations**, and replace #3380 with an MCQ involving NH3 + HCl → NH4Cl.
- New **Tour 4 Season 2**, intended tour ID 82 (currently a closed draft): 20 original EN/RU/UZ questions, **5 per textbook Ch.10/11/12/13**, 6 easy / 9 medium / 5 hard, 16 MCQ (A/B/C/D=4/4/4/4) and 4 numeric inputs (explicitly 3 significant figures).
- Individual Tour clocks total **2225 seconds (37 min 5 sec)** as a descriptive sum of individual maxima; DO NOT add a global tour time limit.
- Four Tour numeric values independently recalculated: `0.600`, `0.480`, `5.64`, `12.0`. Two numeric Practice replacements: `0.0200`, `0.0300`; three Tour MCQ quantitative keys independently recalculated: slots 17→`1.17 g`, 18→`42.0%`, 19→`50.0%`.
- Structural/arithmetic QA **566/566 assertions PASS**; independent structural candidate validator PASS; exact English-stem collisions with existing Chemistry DB = **0** (verified READ-ONLY).
- Book-scope verification: Tour Map v1.0 — Chemistry and Chemistry Coursebook 3e chapters 10–13. A candidate antacid-use reference not grounded in Ch11 was corrected to an in-scope basic hydroxide neutralisation question. Q19 was changed to a distinct quantitative halide-mixture reasoning question. This is not a native-language or independent external academic sign-off.
- `Practice 4` currently remains the prior 70 questions; `Season 2 Tour 4` remains closed and unchanged. **No Tour 4 SQL installation, new database IDs, user attempts, notifications, or data resets.**

## Invariants for future allowed cutover

1. Never use the historical `import_chemistry_s2_batch` importer for these updated pre-populated tours: it requires 24 items (20 FINAL/4 RESERVE), blank Tour and may mutate questions by equal English text.
2. Maintain existing Chemistry T1/T2 policies and both server evaluator routes, old progress and Tour histories.
3. Use immutable manifest and 1-to-1 mapping IDs; import drafts inactive before any link changes; policies before activation; no deletes.
4. One atomic cutover in Practice 4 pool 21 (70 active: 67 old + 3 new) and Tour 4 draft tour 82 (20 new) with exact BEFORE link snapshots. No season open, tour open, or user notification.
5. Do not attempt an alternate transport for a tool-denied SQL payload. Offline Tour 5 work can continue independently.