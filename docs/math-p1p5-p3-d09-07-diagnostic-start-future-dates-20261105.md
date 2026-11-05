# Issue #450 · Mathematics D09-07 — real diagnostic start, no 3-year personal-date ceiling

**2026-11-05 · DRAFT ONLY / no production change / no new blocker.** Based on [DRAFT PR #486](https://github.com/jteshaboev1984-ops/iClub_APP/pull/486) exact head `4fbdc829bf1b9d27168f1c7a5fae8d39be539309` with 70/70 GitHub Actions SUCCESS.

## Cross-package discrepancy actually found

A pupil's profile is created **before** Stage0. Yet the effective personal timeline RPC `get_exam_prep_simple_learning_timeline_safe_v1()` in P2-16 still returned `profile.created_at` as both the whole journey's `start_at` and **each paper's** `start_at`. Other D09 period, individual horizon, shared weekly capacity and report APIs already use the **first genuinely completed P1/P5 diagnostic** (frozen T0 for new learners, transparent derived fallback for old beta records). This presents two different starting points for the same learner. It is a factual timeline inconsistency, not a request to rewrite actual progress.

The P2-16 voluntary-date UI also had `max=today+3 years`; its owner RPC rejected a future personal exam date more than three years away. This arbitrary upper bound would prevent choosing later 2030+ paper dates even though the learner can continue to study and Cambridge 2028–2030 syllabus cycles already exist. These are **personal** dates, not assertions about Cambridge's official zone-dependent timetable.

## Narrow technical corrections

- Adds `20261105070000_exam_prep_p1p5_true_diagnostic_timeline_and_future_dates_v1.sql`. Replaces only the two original owner-scoped functions while preserving all existing signatures, privileges, source-verified 45/36 counts, time estimates, chosen hour budgets, exam-date fallback, past-date rejection, explicit Save, and original safe user records. No new table, role grant or policy.
- The timeline reuses the existing authenticated `get_exam_prep_diagnostic_periods_safe_v1()`. `P1.start_at` and `P5.start_at` are **separate verified Stage0 completion timestamps**. The combined `start_at` is their earliest known completion, or `NULL` if neither completed. Profile registration stays available as a separate provenance field `profile_created_at`. Each component includes `diagnostic_start_status` and `diagnostic_anchor_immutable` inherited from the canonical period read, never invented. No data mutation.
- Personal date-save RPC accepts any valid future P1/P5 calendar date that PostgreSQL can represent, with the existing explicit Save and today's/past-day validation. No claim that a future calendar date is an official Cambridge appointment; previous official appointment history is unchanged. Clear still works atomically.
- RU/UZ/EN learner UI displays individual P1/P5 start dates (or natural «После диагностики» / «Diagnostikadan so‘ng» / «After diagnostic»), and no longer uses account signup as a fake diagnostic date. Dates after 2029 are available. Invalid dates such as February 30 rejected client-side; the owner RPC additionally validates database date types. This removes an existing arbitrary blocker; it does not invent a new one.
- All three previously agreed user time choices (Keep / Accept suggested / Choose another) remain intact. No background schedule change, new daily notices or study-hour limit.

## Exact safety and verification

- Signed owner JWT → local PostgREST → disposable PostgreSQL 17 compares the one-line timeline's **actual P1/P5 start dates and immutability** to existing verified independent period RPC; anonymous request denied.
- Guarded **single transaction with ROLLBACK** exercises the real owner date-save function with dates **4 and 8 years** ahead, confirms persisted personal dates and preserved two diagnostic starts, then rejects today's date, verifies voluntary clear, unchanged profile revision, plan/session counts, and isolation of second synthetic user. Original saved date rows are snapshotted before transaction and checked exactly after rollback; no fake 2030 dates survive.
- Existing RU/UZ/EN JS smoke and Chromium visual checks extended to verify differing P1/P5 starts, absence of false signup start, no 3-year cap, no fabricated invalid calendar date and responsive layouts.
- Full exact new head 70-check Actions required to make any engineering readiness assertion. CI success is not academic approval of individual study duration or Original Extra Hard restoration.

**Change exclusions:** NO merges, production Supabase commands/migrations, Vercel deploy, beta cleanup, user progress reset, localStorage writes, Practice/Tours/certificates/other-subject changes. [PR #484](https://github.com/jteshaboev1984-ops/iClub_APP/pull/484) with an unapproved new hours gate remains **closed and excluded**. Original 12 Extra Hard (6 P1/6 P5) not fabricated or replaced. Any release/rollout action remains a separate architect GO; this work introduces **no new release blocker**.
