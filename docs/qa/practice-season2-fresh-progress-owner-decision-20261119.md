# Practice Season 2 — new progress without deleting learning history

**Owner decision:** 2026-11-19, iClub project conversation, recorded in [Issue #574](https://github.com/jteshaboev1984-ops/iClub_APP/issues/574#issuecomment-7000324835). Owner explicitly approved a **fresh count for Practice** with Season 2. This supersedes the previous *pending* status in the Mathematics-specific content correction document from Draft PR #577.

**Status:** implementation candidate in [Draft PR #579](https://github.com/jteshaboev1984-ops/iClub_APP/pull/579); NO publication, runtime activation, production SQL or historical reset has occurred.

## Narrow operational meaning

- Applies to **Practice progress for all five subjects** from the new academic Season 2 boundary, while preserving each existing question bank, its session permissions, current Tour unlocking and every prior record. New progress is counted only from *newly started* Practice attempts and finalized topic sessions after the actual official start of Season 2.
- Old Practice answers, historical scores, recommendations and attempts remain in the database; **previous totals are archived, not deleted, converted into fictitious zero scores, or changed retroactively**. New view must offer an understandable archived-history entry.
- **Tour results and certificates are not reset.** Tour Season 2 uses its distinct official season records. **Exam Prep Paper results and verified marks are not reset.**
- **Practice bank generation is NOT academic season.** The installed/staged bank-generation mechanism increments on a separately governed full-bank replacement, not because Season 2 starts. Mathematics Practice v2's existing 495 records are not republished to restart scores.
- No new season start date is invented. `public.seasons.season_no=2` was verified as **`draft` with `start_date=NULL`** in live Supabase; only actual published current/closed Season 2 with a nonfuture date activates new-count reads.
- For clarity the read-only API candidate uses `2026-11-01` solely as a **synthetic fixture date** and interprets a published `start_date` at **00:00 Asia/Tashkent**. Cross-boundary sessions remain assigned to the period of their **creation**, not reclassified by when they finish.
- On production release, actual user-facing UI must present **Season 2 current progress** and an **Archive / previous results** entry without silently displaying old best scores as current progress. The current legacy Practice and topic-history screens are unchanged in this candidate; their eventual integration is part of release acceptance, not already accomplished.

## Completed staged technical portion

- `supabase/candidates/practice_season2_progress_safe_v1.sql`: no table updates; user-owned and subject-filtered read-only results; main Practice current attempt count, best, recent; separate archived main attempt count; voluntary topic practice current/archived session counts and correct/answered totals.
- `supabase/tests/practice_season2_progress_safe_isolated.sql`: ephemeral PostgreSQL 17 fixture verifies draft/current/closed, Asia/Tashkent day boundary, lab exclusion, cross-user/subject privacy, unauthorized access, no changes to old answers or scores.
- No changes to `app.js`, `practice-results-tabs.js`, database schema on production, Tour/Exam Prep runtime or academic content banks.

## Remaining release acceptance

1. Validate exact PR HEAD in CI and independently inspect affected live schema read-only; do not assume previous CI still applies after future edits.
2. Connect the owner-approved Period 2 counters into Practice UI in a dedicated, conflict-checked implementation package; show archived results separately and retain accessibility in RU/UZ/EN.
3. Run signed authenticated HTTP/PostgREST E2E against disposable PostgreSQL 17 and Chromium UI checks; confirm session boundary and no history deletion, RLS/EXECUTE, no unintended effect on older periods.
4. Owner must separately approve **merge, any live SQL, UI release, start_date assignment, and season activation**. No permission to delete, truncate, reset archived learner data or retime previous attempts.
