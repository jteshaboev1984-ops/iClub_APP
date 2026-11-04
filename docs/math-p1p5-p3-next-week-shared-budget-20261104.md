# Mathematics P1/P5 — next-week shared hours (P3 candidate)

**2026-11-04 — DRAFT, NOT RELEASED.** Integrates with D09–D11 and issue #450. Existing stable weekly plan generator, objective stage/method rules, recovery, consent, Practice/Tours and other subjects are untouched.

## User flow

After the learner explicitly **Keeps**, **Accepts** or **Changes** the study time, the existing approved server writer owns any chosen-hour change. On the NEXT effective weekly period, the already-governed plan is built by `ensure_exam_prep_balanced_weekly_plan_safe_v1`, NOT by a new plan generator. Once its owned active plan is available, `ensure_my_exam_prep_weekly_budget_safe_v1(component, plan_id)` freezes one shared user+programme+week Math **AVAILABLE time** record for both P1 and P5.

Allocation is grounded in existing current objective-covered versus still-unverified skill evidence, using the existing iClub estimated remaining guided-effort projection for each component. It splits ONLY the student's elected Math weekly time; P1+P5 share equals Math's total. It is a scheduling aid, NOT official Cambridge personal study hours and NOT the estimated minutes required to complete any given problem.

The current week is never silently rewritten. Changed chosen hours and profile revision are reflected at the first plan opening for a subsequent effective week. No quotas: students may study longer, including work outside the application. Priority time slots in the UI mean **available** minutes, NOT verified academic duration, mastery, or a guarantee of task completion.

## Existing evidence and no duplication

- Existing plan items retain unchanged learning/correction/due-retest, priority/order/status and their saved answer/session authorizations.
- No new goal, question, assessment, correction, stage or objective score is created by the time budget RPC.
- Up to 3 priorities only from the existing active owned plan, each showing an available time slot based on the frozen component share; never more than its allocated Math minutes.
- Only `private.exam_prep_weekly_budget_snapshots_v1` is newly persisted, keyed by real learner, Math program and effective week. This table must enter the exact scoped prelaunch backup/reset/restore/FK inventory before any public GO.
- A missing or unavailable time-estimate source fails closed on the optional capacity display; it NEVER prevents the existing academic plan being opened.
- The archived D11 Keep decision is referenced only when it matches the profile revision and budget captured for the week.

## Remaining release prerequisites

1. Treat 69 exact-SHA CI checks, including real owner JWT/PostgREST/PG17 and RU/UZ/EN browser, as engineering evidence only, not as independent academic QA.
2. Academic approval of per-skill difficulty/effort norms and higher-stage objective evidence, without unverified written self marks.
3. Complete frozen cleanup list including the new snapshot/choice/Extra Hard attempt tables; encrypted backup, independent restore, epoch/JWT guard and separate architect release GO.

**NO_GO.**
