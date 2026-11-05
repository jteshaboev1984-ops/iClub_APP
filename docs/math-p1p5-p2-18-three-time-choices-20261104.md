# Mathematics P1/P5 — P2-18 weekly study-time choices

**Architect decisions D09–D11, issue #450.** This is a DRAFT integrated product change; no live Supabase migrations, user-data cleanup, release, or `main` merge.

## Existing authoritative paths, reused

- **Keep my hours** — `public.keep_my_exam_prep_timeline_weekly_time_safe_v1` locks the authenticated owner's existing Exam Prep profile, recomputes the relevant P1/P5 recommendation *on the server*, verifies the exact expected current budget/profile revision/target and records the learner's shortfall acknowledgment with idempotency. It does **not** update chosen hours or objective results, does not claim an exam grade, and does not cap learning. For lost acknowledgement, the same rendered UI retains its idempotency key.
- **Accept recommended** — unchanged existing `public.accept_my_exam_prep_timeline_weekly_target_safe_v1`, which checks the owner, profile revision, existing budget, server's current calculation and total weekly capacity. Only this deliberate click can apply the suggested budget.
- **Specify another** — focuses the existing Mathematics minutes/day and days/week editor. No duplicate calculator, localStorage or new server plan. Only the editor's explicit **Save** calls `save_exam_prep_study_schedule_safe_v1`, which enforces valid calendar minutes/days and total budget.

The UI presents `current → suggested hours/week` and the approximate additional weekly time, with original iClub-source/uncertainty disclaimer. Choices shown only with a real shortfall. If the recommendation exceeds the total available budget, Accept is omitted while Keep/Other remain available. When there is no date or no shortfall, the timeline does not manufacture an action. RU/UZ/EN and mobile layout use the same three-choice order.

## Verification

Existing native timeline smoke + Chromium visual acceptance check RU/UZ/EN and mobile/desktop, persistent Keep decision with no budget change, Other focus without a write, and exactly one Accept update. Existing synthetic owner JWT/PG17/PostgREST E2E now additionally checks the Keep decision, retry, stale revision rejection, and preserved profile hours. This is ordinary product QA, not a new waiting-period/repeated-beta condition.

## Remaining package 3 boundary

The keep-decision event itself does not manufacture a new objective knowledge result or a Stage 3–6 promotion. The normal next period must still use actual completed learning and current chosen hours to generate a feasible prioritized plan; final release depends on the combined academic/backup/epoch control and separate architect GO. The Extra Hard protected bank stays EMPTY/OFF.
