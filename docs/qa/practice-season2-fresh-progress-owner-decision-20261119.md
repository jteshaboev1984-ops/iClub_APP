# Practice Season 2 — new progress without deleting learning history

**Owner decision:** 2026-11-19, iClub project conversation, recorded in [Issue #574](https://github.com/jteshaboev1984-ops/iClub_APP/issues/574#issuecomment-7000324835). Owner explicitly approved a **fresh count for Practice** with Season 2. This supersedes the previous *pending* status in the Mathematics-specific content correction document from Draft PR #577.

**Status:** implementation candidate in [Draft PR #579](https://github.com/jteshaboev1984-ops/iClub_APP/pull/579); NO publication, runtime activation, production SQL or historical reset has occurred.

## Narrow operational meaning

- **Owner-confirmed 2026-11-19:** Practice has its own new count **per subject** from the official start date of **Tour 1 for that same subject**, never from a global Mathematics or independent season timestamp. An undated Tour1 leaves that subject on its previous published season; all prior data, question banks and Tour unlocking remain intact.
- Old Practice answers, historical scores, recommendations and attempts remain in the database; **previous totals are archived, not deleted, converted into fictitious zero scores, or changed retroactively**. New view must offer an understandable archived-history entry.
- **Tour results and certificates are not reset.** Tour Season 2 uses its distinct official season records. **Exam Prep Paper results and verified marks are not reset.**
- **Practice bank generation is NOT academic season.** The installed/staged bank-generation mechanism increments on a separately governed full-bank replacement, not because Season 2 starts. Mathematics Practice v2's existing 495 records are not republished to restart scores.
- No start date is invented. Live `Season 2` was checked as `draft` with no published Tour 1 dates; a new Practice period is only active once the subject's Tour1 has a valid published start/end window, the corresponding season is `current`/`closed`, and local start date is reached. After Tour1 closes the season boundary remains stable.
- `2026-11-01` is **only a synthetic PG17 fixture date**, never a proposed real release date. Convert each subject's `public.tours.tour_no=1.start_date` to **00:00 Asia/Tashkent**; assign a Practice attempt to a period by creation time, not completion time.
- **Owner-confirmed layout:** always put the genuinely active Tour and related Practice first. If none is active, show honest latest-completed/upcoming state; never mark undated Tours active. Keep archived previous-season history in **one quiet closed-by-default section at the bottom**, not a prominent season picker. No stale lifetime best/progress may masquerade as Season2. This is implemented in a Draft; production remains unchanged.

## Completed staged technical portion

- `supabase/candidates/practice_season2_progress_safe_v1.sql`: no table updates; user-owned and subject-filtered read-only results; main Practice current attempt count, best, recent; separate archived main attempt count; voluntary topic practice current/archived session counts and correct/answered totals.
- `supabase/tests/practice_season2_progress_safe_isolated.sql`: ephemeral PostgreSQL 17 fixture verifies draft/current/closed, Asia/Tashkent day boundary, lab exclusion, cross-user/subject privacy, unauthorized access, no changes to old answers or scores.
- `app.js` now uses the read-only season boundary only when the API explicitly confirms active Season 2. Current Tour Practice mastered-question counts exclude old attempts; the prior attempts and local history are not deleted. Current-period records are filtered by their server creation timestamp. An old all-time best is **never** represented as the Season 2 best; if only a capped 30-entry sample is available, its derived best is honestly labeled as a recent-sample best.
- `practice-results-tabs.js` and its scoped stylesheet now position the **current Tour banner first** and keep recent Practice results in their existing Tour/Topic tabs. A **single** bottom archive (outside both tabs) is collapsed by default. It retains the accepted Mathematics Exam Prep **3 recent + native <details> + 5 per click** behavior, bounded samples and old Topic review actions. No changes to `index.html`, UX531-owned branch, Tour/Exam Prep runtimes or academic banks.
- This staged client is **not live**, and production database schema remains unchanged. When the new RPC is not installed or Season 2 is still draft, the new period UI stays hidden and existing history remains. The main Practice start view has new-period stats; legacy all-time My Recommendations and dedicated review history remain accessible, without pretending their rows are Season-2-only.

## Final scoped owner confirmation — Tour1 focus and archive placement

On 19 November 2026, owner explicitly approved:
1. **New Practice period per subject:** starts with **that subject's own Tour 1 official launch date**.
2. **Primary Practice screen:** show the current active Tour and its available Practice at the top, ahead of learning mode tabs. When no Tour is currently active, display the real last-completed/upcoming status, not fictional activity.
3. **Archived seasons:** move history below the learning area into **one collapsed bottom archive**, not a top season chooser and not repeated in each Tour/Topic panel.
4. Retain previous attempts, answer history, rankings, certificates, mastery evidence and topic review; future-only selector behavior must not use cross-season answers to block newly opened Season2 questions.

**Live-selector cutover dependency:** the installed `start_practice_session_auto_safe_v5` and `start_practice_topic_drill_safe_v5` still resolve a global `current` season; the former also excludes previously correct questions across all time. `supabase/candidates/practice_subject_tour1_runtime_v5_future.sql` stages source-preserving replacements for these two functions (no hosted DB writes) and a separate synthetic PG17 regression tests Math S2 with Economics still in S1. This candidate must pass exact-head tests and receive separate owner GO to publish. It does **not** override the deployed function while this Draft is open.

## UI history source reconciliation — accepted Exam Prep versus Practice

Read live GitHub `main` (not an unmerged UX screenshot) before implementation:

- `exam-prep/exam-prep-live.js`: `historyListMarkup` + `bindHistoryDisclosure` show **three recent results**, a native disclosure, then **five older** per click. Core and ungraded Paper stay separate. Existing RPC limits (20 Core, 30 Paper) are displayed honestly as a limited sample, not invented cursor pagination.
- `exam-prep/exam-prep-host.css`: subtle bordered history rows, compact labels/dates, mobile one-column layouts, native keyboard-accessible controls. Exam Prep Paper execution is ungraded; this does not imply Practice Paper scores.
- `practice-results-tabs.js`: before this work Tour history used a bespoke 3+show-all button and Topic history displayed a five-row preview. In this source Draft both now use the **same 3+5 disclosure behavior** as Exam Prep while keeping original safe review listeners. Previously unbounded button expansion is retired; no attempt deletion.
- New Season 2 Practice **recent** history is visible inside existing **By Tour / By Topic** panels. **Past seasons are NOT nested there:** a single collapsed low-priority archive follows both learning panels at the bottom. No new global navigation or top season chooser; the 20-row cap is explicitly disclosed and is not cursor pagination.
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
4. Owner must separately approve **merge, any live SQL, UI release, official Tour1 dates, and season activation**. No permission to delete, truncate, reset archived learner data or retime previous attempts.

## Owner-approved Season1 Practice availability until Season2 launches (2026-11-19)

**Owner's explicit correction:** “до открытия 2 сезона можно оставить открытым практику 1 сезона и закрыт когда откроется 2 сезон.” This confirms *Practice access*, not retroactive Tour status. The record remains season- and subject-scoped; it does not authorize a new Tour, changing dates, republishing a bank, or deleting previous attempts.

**Lifecycle contract, per individual subject:**

| Verified state | New Practice starts | Existing Tour / certificates | Read-only History |
| --- | --- | --- | --- |
| S1 officially opened; S2 draft/undated/future | **S1 Practice stays open**, even when S1 Tours are already officially closed | S1 Tour remains closed, no changes | S1 current Practice results and older pre-S1 records are accessible; do not say S1 Tours are currently active |
| This subject's S2 Tour1 start reached at **00:00 Asia/Tashkent**, valid start/end + season `current` or `closed` | **S1 Practice closes for new starts; S2 Practice opens**, with a fresh period count | S1 Tour remains closed; S2 Tour gates unchanged | S1 records remain available via previous season, with no reset/regrade |
| Mathematics S2 starts but Chemistry/Economics/Biology/Informatics S2 Tour1 is still undated | **Only Mathematics switches**. Each other subject remains in S1 Practice | Other-subject Tours are not started by Mathematics | Subject-owned S1 records remain accessible |

“Closes” here means **no new S1 period attempts** and no reopening unfinished S1 client session IDs through either staged v5 Start endpoint after official per-subject S2 cutoff. Same published Practice question pool may be reused for *new* S2 sessions; bank generation does not change, and completed records remain immutable. The separate existing Practice answer/finalize/resume flows need an explicit cross-midnight in-progress-session review before full release; this Draft does **not** claim to have closed every possible already-open browser session or deleted paused drafts. Never silently discard a saved draft or misattribute a late S1 finalization to S2.

**Source-only candidate:** Staged owner-scoped read RPC `get_practice_season2_progress_safe_v1` now returns `practice_access` with `open_season_no=1`, `season1_new_attempts_open=true` until S2 opens; the same RPC flips to `open_season_no=2`, `season1_new_attempts_open=false` after subject-specific S2 activation. The earlier S1 `history_snapshot` also marks `practice_open=true`. In the Academy OS statistic-area status banner, show small RU/UZ/EN captions without a duplicate Start button; the separate History uses the **“Текущая практика”** badge while S1 Practice is open even though S1 Tours are closed, and **“Текущий сезон”** once S2 is officially active. Historical S1 becomes a previous season, without fake Season 0.

Staged `start_practice_session_auto_safe_v5` / `start_practice_topic_drill_safe_v5` already choose the latest published per-subject Tour1 season (not the global `current` season). Added a narrow idempotency guard refusing unfinished pre-S2 client IDs after S2 cutover for that subject only. Current published functions are **unchanged** until a separately authorized migration. All tests use disposable PostgreSQL17, synthetic sessions, signed JWT/PostgREST only where explicitly exercised, and multilingual Chromium. Owner-approved visual order and Topic one-tap Start remain unchanged.

**Release HOLD:** all five hosted Season2 Tour1 dates remain NULL/draft at last read-only checkpoint; new RPC and staged v5 selectors are not installed. Do not publish SQL / enable seasons from an acceptance of UI. The old Topic-catalog-load incident, cross-boundary already-open draft/submission audit, UX531 integrated source release firewall, and >20-row cursor retrieval remain separate gates.

## Late-finalization boundary defect — separate source candidate (2026-11-19)

A specific authenticated **installed** source inspection on 2026-11-19 confirmed the legacy v5 Tour Practice finalizer `public.finalize_practice_session_safe_v5(bigint,integer)` creates a row in `public.practice_attempts` **when the quiz is finalized**, without passing `created_at`; that column defaults to `now()`. The already-approved per-season read-only progress filters `practice_attempts.created_at`. Therefore, a Practice session started in S1 but finalized after the official S2 Tour1 cutoff **would appear in S2 fresh progress**, even though it belongs to the old session. This conflicts with owner-approved Season1-archive preservation. This was a **real code/schema mismatch identified before release**, not evidence that live learners have already been affected (S2 remains draft/undated).

**Narrow future-only solution in an isolated child Draft:** `supabase/candidates/practice_finalizer_season_boundary_v5_future.sql` copies the exact installed v5 finalizer definition (hosted `pg_get_functiondef` MD5 `c002f4b8856233b0c05845fed0d19f6e` on 2026-11-19) and changes **only** the server result timestamp for an already-started S1 session that completes after this **subject's own** officially published S2 Tour1 opening. In that boundary case, new `practice_attempts.created_at` is set to the saved `practice_sessions_v4.created_at`. Otherwise created_at remains the existing `now()`. Session `finalized_at` remains the true completion time; question order, keys, grading, answer diagnostics, idempotency, existing progress rows and other-subject functions are unchanged. **No retroactive edits or in-place regrading**. Subject S2 remains `draft` or without Tour1 dates → S1 Practice still works with the original timestamp semantics.

**Why not simply reject late finalizations?** They may contain already completed learner work and saved answers. The verified, bounded choice is to finish that existing session and attribute it to S1, while all **new** starts after cutover go to S2. This does not reopen S1 for new attempts, and does not delete paused drafts. Do not claim a signed HTTP finalizer test unless run separately; the attached PG17 test uses synthetic authenticated-role UUID, and the existing same-workflow JWT/PostgREST step verifies the read-only progress RPC.

**Test:** disposable PG17 fixture `supabase/tests/practice_finalizer_season_boundary_isolated.sql` verifies S1 started→S2 finalized stays S1, normal S2 keeps now(), undated Chemistry does not inherit Mathematics cutoff, normal draft S2 does not close S1, old rows unchanged, wrong-owner rejection, per-session idempotency and answer/diagnostic preservation. Same existing Practice PG17 workflow runs this separate database in addition to the previously approved selectors, progress, signed HTTP and visual regressions. No hosted production SQL or content is changed.

**Release HOLD:** separate explicit owner GO for replacing the live v5 finalizer, revalidation of the exact installed definition MD5 against release time (stop on source drift), and end-to-end client resume and server submit behavior near midnight. Child Draft remains unpublished; never interpret the code candidate as authorized to modify production.
