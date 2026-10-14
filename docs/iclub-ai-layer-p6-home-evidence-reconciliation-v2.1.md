# iClub AI v2.1 — P6 Home evidence reconciliation, before any planning logic

**2026-10-14. Read-only source analysis, QA branch. Status: NO-GO.**

## Actual unchanged Home implementation

- `renderHome()` reads `loadProfile()`, filters via `filterActiveUserSubjects(profile.subjects || [])` and separately renders competitive subject cards and pinned Study subjects (up to four). These are app-selected/locally represented directions; they are **not a server-signed cross-subject next-action priority**.
- `computeHomeCompetitiveStats(subjectKey)` reads tours and attempts from Supabase, counts attempts with statuses `submitted`, `time_expired`, **also `anti_cheat`**, and uses the browser `new Date()` / local calendar date to choose the tour window. It also supplies fallback fields including module/tour 1 and progress 0 when information is missing; this is valid as an app rendering fallback but is **not suitable as an AI proof of actual mastery or a next step**. A cache prevents frequent reads.
- `computeHomeStudyPracticeStats(subjectKey)` delegates to `computePracticeStageStats`, caches locally and falls back to zero counters. Thus a visible tile fraction is not a server-verified planner signal.
- `homeCompetitiveCardEl()` and `homePinnedTileEl()` navigate to `courses` / `subject-hub`. They do **not** directly mint a dedicated AI-context or choose the next lesson. `renderSubjectHub()` separately calls `iClubCommercialAccessUI.guardStudy(subjectKey)` and `isSubjectActive(subjectKey)`, so the direct Home button route must not be described as a confirmed commercial-access bypass based on call-site inspection alone.

## Eligibility conditions for three technically proposed Home action classes

| Proposed action identifier | What would need independent authority | Release status |
|---|---|---|
| `continue_enrolled_subject` | Current JWT owner, active subject, current enrollment/mode, commercial study entitlement, nonprotected active exam, allowed destination | Not a ranked or approved Home recommendation |
| `review_finalized_practice` | Owner-bound `practice_sessions_v4` with true finalization and `practice_session_answers_v4` in the correct subject, approved finalized review, source/locale release and current screen | No cross-subject planner exists |
| `review_open_tour_archive` | Owner-bound `tour_attempts` plus `tour_session_runtime_v4.finalized_at`, matching subject, valid submitted/time_expired status, **Tashkent-local Tour end-date has passed** and current archive entitlement | No planner; never send a pupil into an unreleased Tour |

These types in `qa/ai-layer-v21-p6-home-next-action-proof.cjs` are **technical candidates**, not product-approved learner priorities. No recommendation sequence, weights or tie-breaking rule is proposed. It would be incorrect to pick 'lowest percentage' or 'most incomplete subject' without the architect-approved pedagogical policy and certified data source.

## Cross-source conflicts that must NOT be silently reconciled

1. Legacy Home Tour completion displays may count `anti_cheat` statuses; the existing server-proof Tour archive requires a finalized runtime, `submitted/time_expired`, and expiry of the tour window. These are not interchangeable.
2. Legacy Home uses device calendar dates; the server archive proof uses Tashkent date semantics. Client-clock tour-open/closed decisions are not a verified rule for the AI.
3. Home "0 progress" can be an intentional fallback when Supabase data is unavailable; it is not necessarily an observed zero score or a learning deficit.
4. Pinned Study cards limit display to four; omitted subjects or local pin selection should not be converted into a cross-subject AI ranking.
5. Commercial `guardStudy` is evaluated during the target hub rendering; the future planner must still check the entitlement independently before proposing the action and again at execution.

## Safety / next work

Do **not** create `home_next_actions` from browser-computed tiles or Profile activity counts. First agree on permissible actions/priority rules, then construct a dedicated server-owned owner-scoped read-only planner with immutable revision, per-action evidence, server-local time, protected exam and rights checks, and independent editorial release RU/UZ/EN. The previously built QA planner admission validator is NOT that planner and is NOT wired into production.

**No modifications** to app.js, index.html, Supabase, student data, localStorage, main, Vercel or production Edge. The Global AI stays OFF.
