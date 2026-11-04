# Issue #450 — P3-03 next weekly period, actual database rollover E2E (draft)

**2026-11-04. Source base:** exact 70/70 GREEN [DRAFT PR #476](https://github.com/jteshaboev1984-ops/iClub_APP/pull/476) SHA `64f0ffefcec23a92cb2e12966540341dde6405ea`. **NO_GO**, no production change.

## Roadmap requirement and bounded evidence

The [v2.0 roadmap](math-p1p5-release-workplan-v2-20261102.md) Package 3 and D09/D11 mandate: one seven-day cycle, only consented changes in selected study hours, next week's actual plan uses the latest confirmed hours, uninterrupted pending sessions/retests/corrections, separate P1/P5 academic evidence and dates, and no daily warnings or study-time access quotas.

The previous PR #476 signed owner JWT/PostgREST/Chromium+PG17 E2E verified **only one effective week**. This new P3-03 exercise proves the **first rollover** using the existing code after the same real migrated fixture. It is not a new plan generator or a new student-progress mutation.

1. In the existing genuine JWT/Chromium stage, fake learner A initially chose **6h Math** and captured week 1 **360 min** in one P1/P5 snapshot.
2. After the signed browser saved a **30 minutes × 7 days = 3.5h** study schedule, the existing week 1 snapshot must still be **360 min** (no mutation during week).
3. After the full real signed browser horizon test has independently saved **different** future P1 and P5 centre-confirmed dates, one **isolated PostgreSQL 17 SQL transaction** simulates eight elapsed days by moving **only fake A's `exam_prep_exam_profiles.created_at`**. It does NOT change real/system clock, exams, other users or official attempt timers.
4. Reuse the real `ensure_exam_prep_balanced_weekly_plan_safe_v1` for fresh P1 and P5 week 2 plans. The new shared budget is **210 minutes total**, always split once, not 210 minutes each. Same-week reopens are immutable, and week-1 plan IDs are rejected for week 2.
5. Fingerprint and retain week-1 snapshot and existing priority rows, old session records, authorizations, corrections, another fake learner, legacy Practice/Tour/certificates; preserve P1 and P5 independent confirmed exam dates. No additional marks, stages, questions or fabricated source-based norm.
6. Test is unconditionally wrapped in `BEGIN ... ROLLBACK` with a second post-rollback test asserting that the original fake profile week and absence of week-2 plans/snapshots have been restored. A SQL error makes the `psql` connection end and rolls back too.

**Exact reusable test:** [P3-03 next-week rollback SQL](../supabase/tests/p1p5_p3_03_next_week_rollover_disposable.sql) is appended as a guarded step to [existing full isolated E2E workflow](../.github/workflows/exam-prep-p1p5-isolated-http-e2e.yml), after the actual P1/P5 date/horizon browser test. No production migration or runtime behavior is added in this patch. The source uses a local PostgreSQL-auth claim context for temporal rollover; it does **not** claim the P3-03 step itself performed new signed JWT/GoTrue requests. The earlier genuine signed HTTP E2E remains independently required.

## Known roadmap gaps (DO NOT FALSELY MARK COMPLETE)

- Current live `private.exam_prep_effective_active_week_v1` uses `exam_prep_exam_profiles.created_at` and caps to 36, **not per-paper diagnostic-completed-at**. The v2 roadmap's independent `T0` anchors and year-long week 36+ policy are not automatically satisfied by this test. Changing that global active-week function without full source migration/race/security audit could break existing users and is out of this test-only PR. Record as **D09 remaining decision**.
- The selected 3.5-hour budget is not an approved personalized Cambridge guided-hours prescription. Neither verified study minutes outside iClub nor precise problem durations exist.
- This is one controlled 7-to-8-day elapsed transition, not evidence of 7 actual days, 15+18 human profiles, full multiple-month reports, real Telegram devices or hosted GoTrue.
- Clean-up, main merge, production Supabase, Vercel deployments, rollout flags, entitlement changes and reset are **deferred**, subject to separate explicit architect GO.

**Acceptance:** first actual exact-head CI of this PR must report successful PostgreSQL 17 rollover and full source/Stage D checks. Until then state is **PENDING, NO_GO**, not inherited 70/70.
