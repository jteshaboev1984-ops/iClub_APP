# Issue #450 — D09-06: weekly reports continue after year three

**2026-11-05 · DRAFT · no new learner restrictions.** Built on [D10-02 PR #485](https://github.com/jteshaboev1984-ops/iClub_APP/pull/485) exact head `2d77ed0df1db30997a75ca48c58d04df1a91cd4d`, independently verified **70/70 Actions SUCCESS**. Public release status unchanged.

## Actual bug

Both earlier migrations `20261103025000_exam_prep_p1p5_periodic_study_reports_v1.sql` and `20261104131000_exam_prep_p1p5_evidence_led_weekly_focus_v1.sql` contained `IF v_week_number BETWEEN 1 AND 156`. A student's genuinely completed 157th or later week would produce **no weekly summary**, although months continued to be recorded. This is inconsistent with the architect's no fixed study-duration limit and with the explicit D09-05 comment that the 36-week curriculum programme is not a weekly reporting cap.

No academic reason establishes 156 weeks as a mandatory end of a learner's use, especially while different Cambridge exam sessions and extended preparation remain possible.

## Narrow nonblocking correction

The two **draft-only** SQL definitions now use `IF v_week_number >= 1` instead. This is not a new report schedule, daily reminder, grade change, new time recommendation or a modification to the planned-hours user choice. It simply preserves the existing **once per actually completed seven-day period** behavior after the previous arbitrary ceiling.

- **Same immutable diagnostic T0**, same P1/P5 independent academic evidence, one shared student-selected Math budget, existing monthly report behavior and one report/period/owner unique receipt.
- No backfill of skipped weeks; existing no-backlog behavior remains.
- No automatic hour increase, access lock, Core limits, new consent gates, or extra user alerts.
- No change to prior weekly plan identities, old scores, answers, sessions, stored periods or certificate/Tour/Practice data.

## Verification

The actual disposable PG17 D09-05 receipt test remains intact for week one. It now adds a **second 200-week scenario** under the **same disposable PostgreSQL transaction**: guarded synthetic-only academic clock, authenticated owner, genuine seeded P1/P5 Stage0, legitimate current evidence, one new weekly receipt despite `week>156`, duplicate dashboard call with no second receipt, original plan/session counts retained and other owner untouched. A single `ROLLBACK` and existing postflight checks restore the original clock and ensure **zero report residue**. A monthly summary may accompany the long-week claim, preserving the original month cycle.

This scenario is not real elapsed time or measured learner activity. It proves a *server boundary*, not 200 weeks of actual learning and not Cambridge-required teaching hours.

No changes to `main`, production Supabase, Vercel, live user data, localStorage, feature flags, original Extra Hard question content, or agreed three time choices. New blockers remain forbidden without architect approval. Full exact-head CI must complete before engineering acceptance.
