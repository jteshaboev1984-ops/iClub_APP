# Issue #450 — D09-01 diagnostic-anchored weekly progress calendar (DRAFT)

**Created 2026-11-04. Parent source:** [P3-03 full 70/70 GREEN DRAFT PR #478](https://github.com/jteshaboev1984-ops/iClub_APP/pull/478), exact parent SHA `d5897fffb951ea2be34ff07966f640d476180010`.

## Defect and source correction

The existing DRAFT `claim_exam_prep_periodic_study_report_safe_v1` used the global Exam Prep **profile creation timestamp** for weekly boundaries, while already using the first actual completed component diagnostic for monthly boundaries and the receipt key. Therefore a weekly report could be anchored to the wrong seven-day period. This change aligns the single weekly report with the first genuinely completed P1 or P5 diagnostic. No daily reminders, guessed outside-study minutes, automatic schedule increase or study quota are introduced. The existing `(user, program, diagnostic anchor, period kind, period end)` receipt key still ensures at most one weekly/monthly result per period, including across devices.

A new **read-only** owner-scoped projection `public.get_exam_prep_diagnostic_periods_safe_v1()` returns independent component P1 and P5 completed seven-day counts and next boundaries, sourced solely from each component's real verified Stage0 status and finalized diagnostic sessions, exactly as the current `get_exam_prep_personal_horizon_safe_v1()`. Pending diagnostic returns **unknown**, never zero weakness, fabricated pace or a forecast. It does not advance academic stage, create a weekly plan, write receipts, change hours or allocate study time.

The pure private period calculator is tested for 6d23h59m59s, the exact seventh day, two periods, independent P1/P5 anchors three days apart, 36/37 weeks and a null / future diagnostic. The same source is exercised with **real signed owner JWT→PostgREST→PostgreSQL 17** after the existing Chromium end-to-end date and budget flow, including anonymous rejection, owner isolation and agreement with the currently published personal-horizon anchors.

## Scope and remaining governance

- **No production write or release:** all changes remain in DRAFT PR, not merged. No live Supabase migration, no Vercel deployment, no cleanup, no Practice/Tours/certificate touching.
- The **account-wide stable weekly plan generator** still derives `active_week_no` from `exam_prep_exam_profiles.created_at`. This change deliberately does not replace that production-established planner clock, prevent recovery or corrupt old plans. Diagnostics and the existing plan can have different calendar windows; using diagnostic weeks for plan IDs would be a separate migration and safety review.
- The **historical original immutable T0** is **not fully solved**. The existing horizon currently derives `max(finalized_at)` for diagnostics when Stage0 is complete; a later finalized repeat could move that derived anchor. The new read-only API openly reports `anchor_immutable:false` and `anchor_source:current_horizon_latest_finalized_diagnostic`. A versioned one-time server-owned original-T0 ledger and safe profile/epoch transition are prerequisites before D09 can be declared complete.
- The joint weekly report anchor is the first completed paper diagnostic to avoid duplicate student reports; independent paper calendars are read-only projections. Paper-specific forecasts and pace adjustments need further verified objective evidence and approved time standards; no invented Cambridge-specific per-item minutes.
- This check is an **engineering** E2E in disposable PG17, not real weeks elapsed or external academic validation. Staged release and public GO remain **NO_GO**.

**Verification target:** full exact-SHA GitHub Actions GREEN, plus [D09 isolated SQL](../supabase/tests/p1p5_p3_d09_component_diagnostic_period_contract.sql) and [D09 actual authenticated HTTP](../scripts/p1p5-p3-d09-diagnostic-periods-real-http.cjs). Do not inherit previous PR #478 checks on the new commit.
