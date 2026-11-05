# Issue #450 — D09-03: one first diagnostic date for all P1/P5 read-only horizons

**2026-11-04 DRAFT, NO_GO.** Built on [D09-02 PR #480](https://github.com/jteshaboev1984-ops/iClub_APP/pull/480), exact parent SHA `3c4f0d73207ed2a44ef04b33bcaf4a173c50ae33` (70/70 GREEN). New head must have its **own** full E2E and CI result.

## Verified source mismatch and exact repair

The latest Stage0 diagnostic date was used by two existing *read-only* owner RPCs — `get_exam_prep_personal_horizon_safe_v1()` and `get_exam_prep_shared_study_capacity_safe_v1()`. When a learner later completed another diagnostic, that latest date could disagree with the first immutable Stage0 T0 used by the D09-02 component-period API and periodic reports.

Both original RPC contracts are preserved, with unchanged names, auth, planned Math budget, paper times (P1 110min / P5 75min), user-confirmed exam dates, grade honesty and study-access rules. The only change is that the date comes from the existing **one owner-only** `get_exam_prep_diagnostic_periods_safe_v1()` read projection. It uses immutable first T0 for new verified Stage0 transitions; old already-completed beta learners retain their previous derived fallback, explicitly marked unfrozen. A safe additive `diagnostic_anchor_immutable` boolean is returned for each paper in the two horizon payloads.

The one shared student-chosen Mathematics availability remains single and nonadditive: P1 and P5 are NOT given separate 3.5-hour/6-hour budgets, and there is no quota, forced additional time, artificial verified Cambridge hours, inferred study activity outside iClub, grade, objective score or stage credit. No client writes, learner records or stable plan generator changes.

## Disposable E2E acceptance

- Existing full JWT→PostgREST→PG17→Chromium test confirms two separately dated P1/P5 Stage0 components with genuine school-confirmed test appointment UI, same signed owner and one shared Maths capacity.
- Expanded signed HTTP D09 contract compares `diagnostic_completed_at` **exactly** across frozen owner period projection, personal P1/P5 horizon and source-backed shared capacity. Confirms `diagnostic_anchor_immutable` provenance and individual P1 110 / P5 75 exam timers, without conflating exam times and study quotas.
- Expanded *BEGIN…ROLLBACK* PostgreSQL 17 disposable-only first-T0 test temporarily shifts an existing fake learner's most recent finalized P1 diagnostic forward within its own nested exception subtransaction, proves both read APIs still use original P1/P5 T0 and one shared Math budget, then rolls back the injected recent timestamp. Existing real owner sessions, corrections, another learner and preexisting plans remain unchanged after the full rollback.
- The same workflow must grep the explicit D09-03 proof notice. If migrations fail, RPC mismatch occurs or latest diagnostic unexpectedly changes an anchor, the whole workflow fails.

## Scope

No new prompt/question text, no Extra Hard replacement bank. **Architect's original 12 tasks** (6 P1, 6 P5) remain the sole intended first set. The original exact payload is still not recovered from the current rebuilt public branch or personal context; do not invent or silently reauthor it. Existing Extra Hard shell stays OFF with empty protected bank.

**Not yet solved:** the preexisting `private.exam_prep_effective_active_week_v1` uses the common profile creation date for historical plan IDs and clamps to 36; the new independent P1/P5 diagnostic calendars and existing shared weekly budget cannot be rekeyed globally without a separate migration/rollback and real multi-week compatibility verification. Valid plan IDs, reopens, corrections and protected attempts must take precedence. D09 evidence-led recommendation refinement remains open.

No main merge, production Supabase migration, Vercel deploy, feature rollout, cleanup, resetting progress or touching Economics/Chemistry/Practice/Tours/certificates. **PUBLIC NO_GO.**
