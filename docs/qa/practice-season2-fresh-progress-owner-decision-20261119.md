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
- `app.js` now uses the read-only season boundary only when the API explicitly confirms active Season 2. Current Tour Practice mastered-question counts exclude old attempts; the prior attempts and local history are not deleted. Current-period records are filtered by their server creation timestamp. An old all-time best is **never** represented as the Season 2 best; if only a capped 30-entry sample is available, its derived best is honestly labeled as a recent-sample best.
- `practice-results-tabs.js` and its existing stylesheet add consistent, non-destructive Practice History presentation for both Tour and Topic tabs. Uses the accepted Mathematics Exam Prep **three recent + native <details> + five per click** pattern, with a bounded recent sample and separate collapsible previous-season archive. Historic owner review controls remain in the dedicated Topic history. No changes to `index.html`, the UX531-owned integration branch, Tour/Exam Prep runtimes or academic banks.
- This staged client is **not live**, and production database schema remains unchanged. When the new RPC is not installed or Season 2 is still draft, the new period UI stays hidden and existing history remains. The main Practice start view has new-period stats; legacy all-time My Recommendations and dedicated review history remain accessible, without pretending their rows are Season-2-only.

## UI history source reconciliation — accepted Exam Prep versus Practice

Read live GitHub `main` (not an unmerged UX screenshot) before implementation:

- `exam-prep/exam-prep-live.js`: `historyListMarkup` + `bindHistoryDisclosure` show **three recent results**, a native disclosure, then **five older** per click. Core and ungraded Paper stay separate. Existing RPC limits (20 Core, 30 Paper) are displayed honestly as a limited sample, not invented cursor pagination.
- `exam-prep/exam-prep-host.css`: subtle bordered history rows, compact labels/dates, mobile one-column layouts, native keyboard-accessible controls. Exam Prep Paper execution is ungraded; this does not imply Practice Paper scores.
- `practice-results-tabs.js`: before this work Tour history used a bespoke 3+show-all button and Topic history displayed a five-row preview. In this source Draft both now use the **same 3+5 disclosure behavior** as Exam Prep while keeping original safe review listeners. Previously unbounded button expansion is retired; no attempt deletion.
- New Season 2 Practice history is visible inside existing **By Tour / By Topic** panels, without adding duplicate global navigation or changing iClub stack headers. It shows new attempts separately from a native **Previous seasons** disclosure and a small honest note if an older sample exceeds the 20-row cap. It is a *read-only history preview*, not server-side cursor pagination.
- UI copy in **RU / UZ / EN**; CSS is scoped to Practice surfaces and reuses existing sapphire tokens, quiet borders, keyboard focus ring and responsive layout. Check 320/375/430/1440 widths and correct tab mode.
- `scripts/practice-season2-history-chromium.cjs`: synthetic real Chromium DOM test added to PostgreSQL17/HTTP workflow; covers both existing histories and new period history, disclosure batches, capped-note, three languages and four viewports. Do not report pass until exact-head CI completes.

**Known independent follow-up:** the My Recommendations area still provides its signed all-time Topic/Tour history and per-question review. Its records must not be mistaken for a second-season total. A later server-cursor/history integration may extend older than 20 records; the present source candidate is intentionally not a full-history fetch or destructive reset.

## Academy OS visual parity — 2026-11-19

Owner instructed the Practice History work to follow the **recently accepted iClub Academy OS visual style**, not introduce a competing color palette or alternative app navigation.

**Verified source of truth:** current released `main` `visual/iclub-academy-ux531-b04b08.css`, which defines `--academy-paper: #fff`, `--academy-text: #142b50`, `--academy-edge: #ccdcf4`, `--academy-radius-lg: 20px`, `--academy-quiet-shadow`, focus `--academy-focus: #377bdf`, and the existing sapphire family. Approved behavior for Exam Prep History is in `exam-prep/exam-prep-live.js` (3 recent + 5 older), and the existing Practice History module remains `practice-results-tabs.js`.

**Applied in Draft #579 only:**
- Replaced the new Season 2 History's earlier ad hoc `--v3-*` card defaults with the **exact inherited Academy OS tokens** for paper/ink/edge/radius/quiet shadow/text contrast and keyboard focus. History uses *quiet white cards*, **not** a second competitive-blue hero; the accepted topbar and the single Back authority remain unchanged.
- The topical all-time history preview inside the Practice Topic selector is visually suppressed **only** while an authenticated server says Season 2 period is active. This avoids duplicate/conflicting lifetime totals under new Season 2 totals. The old preview is restored before Season 2; all underlying records stay intact and older results are available in the new archive.
- Removed redundant repetition of the "new results" label before the period date. The history explicitly identifies the Season 2 start date without making up user scores or dates. RU/UZ/EN use the same functional structure.
- No CSS changes to the released shared Academy files, no `index.html`, `topbar`, Exam Prep, UX-owned #562, rating, Tour or global navigation changes.

**Visual contract tested against *actual Academy OS CSS*** by `scripts/practice-season2-history-chromium.cjs` (rather than using test-local assumed colors): computed background `rgb(255,255,255)`, edge `rgb(204,220,244)`, radius `20px`, ink `rgb(20,43,80)`, soft elevation present; ensure duplicate all-time Topic history is hidden during active S2 and restored when not active. Tests run with real Chromium in RU/UZ/EN at 320/375/430/1440 px along with native 3+5 disclosure and no horizontal overflow. No real-user screenshot or owner phone approval is claimed.

**Remaining product consideration (not part of this styling edit):** there is no user-friendly Tour number on legacy `public.practice_attempts`; the new history safely shows attempt date and actual percentage without inventing a tour. Any future linked display must join verified owner-authorized `practice_sessions_v4` and `practice_pools` records without exposing additional student data. Likewise, showing archive records beyond the 20-row API sample requires a separate cursor-paginated read-only design.

## Remaining release acceptance

1. Validate exact PR HEAD in CI and independently inspect affected live schema read-only; do not assume previous CI still applies after future edits.
2. Confirm actual Practice UI integration on the exact draft SHA, including refreshed Season2 mastered counts, older best-history labeling, 3+5 disclosure and separate archive in three languages. Do not reuse an earlier SHA's CI as proof.
3. Verify signed authenticated HTTP/PostgREST E2E against disposable PostgreSQL 17 and real Chromium UI (320–1440px), existing Practice client regression workflows and question-preservation rules. Resolve only actual failures; no silent test bypass.
4. Owner must separately approve **merge, any live SQL, UI release, start_date assignment, and season activation**. No permission to delete, truncate, reset archived learner data or retime previous attempts.
