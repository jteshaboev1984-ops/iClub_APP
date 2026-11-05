# Issue #450 — D09-04 / Package 3: legacy weekly-plan identity vs real diagnostic week

**2026-11-04, DRAFT/NO_GO.** Builds from [D09-03 DRAFT PR #481](https://github.com/jteshaboev1984-ops/iClub_APP/pull/481), exact 70/70 GREEN SHA `73d3b4ad227706ed81113874b6efe10a7169e035`.

## Problem verified in existing source

`private.exam_prep_effective_active_week_v1(user)` still derives one shared planner `active_week_no` from Exam Prep profile `created_at`, with a 36-week maximum, and both paper plan IDs/goal snapshots/session authorization paths use that week. Genuine paper diagnostic dates can be different: P1 first verified Stage0 may be completed earlier than P5. The D09 first-completion periods, weekly report and personal exam horizons correctly use their independently frozen dates, but rewriting the existing global week number from those dates would shift or orphan completed plans, pending correction cases/retests and one frozen P1/P5 Mathematics budget.

**Do not treat the current shared plan week ID as synonymous with the academic seven-day week from diagnostic T0.** Deliberately keep both notions, and avoid rekeying any existing row.

## Implemented bridge, not a competing generator

- Existing owner-only `ensure_my_exam_prep_weekly_budget_safe_v1(component, current_plan_id)` keeps exact account/week/plan authorization checks, guarded one Math budget snapshot and all existing priorities. Additive response includes `planner_week_kind=legacy_shared_plan_id`, `legacy_plan_id_preserved=true`, `diagnostic_period_never_rekeys_existing_plan=true`, and P1/P5 independent **read-only** diagnostic period number, next seven-day boundary, honest source immutability. The one existing `get_exam_prep_diagnostic_periods_safe_v1()` owns the period calculation, not a new clock or plan generator.
- Client adapter validates exact plan ownership plus both academic period fields. On absent/invalid optional budget data it safely shows the original plan and remains usable, rather than inventing a week or starting new attempts.
- Existing plan card shows the **saved plan week** and the **selected paper's week since completed diagnostic** separately in RU/UZ/EN. Example: `Неделя учебного плана 5 · Неделя с диагностики 3`. No terms like internal `T0`, `legacy`, `epoch` appear to learners. The 1–3 existing priorities, P1/P5 selected minutes and user-set Math total are untouched. Mobile and desktop share natural one-line wrapping and existing symmetrical layout.
- This is a **presentation and provenance bridge**, not a new independent paper planner. The planning week count still capped at 36 by historical system, even if D09 academic week exceeds 36. We must separately decide/prove forward-only week-clock evolution and historical attempt safety; no unsafe global switch without reviewed architecture.

## Acceptance

1. The existing real JWT→PostgREST→PG17 diagnostic + plan E2E checks the newly exposed week 1–∞ from both independent P1/P5 read RPCs against each paper's SAME owned shared-week budget response, verifies old plan ID is unchanged, and tests foreign owner/wrong component/unknown plan denied. The already existing same-budget reopen, old plan item preservation, 6h→3.5h next-week rollover and correction/retest/security checks remain.
2. A focused native Chromium test creates **only synthetic UI mocks** (no production or fake successful academic scoring) and verifies RU/UZ/EN at 390px/1280px. Example planner week **5** vs separate P1 week **1** and P5 week **3**. Valid original priority and 300 total elected minutes (190 P1+110 P5) still display without mutation or horizontal overflow.
3. Stage D, real signed user E2E, P2-78 load/recovery, rollback and all existing exact-SHA CI must finish GREEN before technical acceptance. A passing browser mock alone is not a substitute for real auth/database E2E.

**Extra Hard content:** Architect's decision remains to use exactly the same 12 original authored problems (6 P1, 6 P5) and not create replacements. Current public feature branch has secure OFF/EMPTY shell; original multilingual payload was excluded from rewritten history and has **not** yet been exactly recovered or loaded. No invented answers, invented review or public content export.

## Release scope

No `main` merge, no live Supabase schema/data mutations, no Vercel deployment or enable flag, no pilot reset or cleanup. No protected answers, existing user/local progress, Practice/Tours/certificates, Chemistry or Economics updates. Public **NO_GO** remains until architect's separate GO and prelaunch audit.
