# Issue #450 — D09 first diagnostic T0 freeze (historic Extra Hard source rule superseded)

**2026-11-04 — DRAFT/NO_GO.** Builds only on [DRAFT PR #479](https://github.com/jteshaboev1984-ops/iClub_APP/pull/479), exactly 70/70 GREEN source SHA `86f335e9363ef4ffd97beed38be4784c35152a3a`. This change needs its **own exact-head CI** before engineering acceptance.

## D09-02: first genuine Stage0 date

The previous [D09 read-only projection](math-p1p5-p3-d09-diagnostic-periods-20261104.md) followed the **latest** finalized diagnostic. Later repeats could shift `diagnostic_completed_at`, changing weekly/monthly reporting despite no new enrollment. To prevent this for *new* genuinely completed Stage0 transitions:

- New private, RLS-protected `exam_prep_diagnostic_t0_snapshots_v1` stores **exactly one** first completed date per (user,program,P1 or P5), captured server-side by the existing placement transition from incomplete to `stage0_complete=true`. Uses the last finalized diagnostic **at that instant**; no diagnostic means no fabricated row.
- Replay/revalidation, another session or changed exam profile cannot overwrite the original snapshot (`ON CONFLICT DO NOTHING` plus database UPDATE blocker). No previous placements, history, sessions, grades, evidence or active plan rows are rewritten.
- Owner-only `get_exam_prep_diagnostic_periods_safe_v1` reads the stored frozen T0 when available and exposes `anchor_immutable:true`; historical already-completed beta users who predate the trigger receive the existing derived date with `anchor_immutable:false`. **No silent bulk backfill from potentially later repeat sessions**.
- The existing single weekly/monthly report owner RPC now uses `min(COALESCE(frozen_t0, existing_verified_diagnostic_end))`, stabilizing both seven-day and calendar-month periods. One-time receipts and no-daily-alert policy remain unchanged; no unverified real-life study hours are invented.
- The canonical legacy `private.exam_prep_effective_active_week_v1` and original plan IDs still use the profile week for compatibility. Freezing individual diagnostic epochs **does not** change this old planning identity; revising the shared plan-week clock would require separate safe historical-plan migration and rollback proof.
- The test asserts actual P1/P5 first-diagnostic records in **disposable** PG17 after signed HTTP diagnostic, attempts a forbidden direct T0 update, toggles only synthetic placement within `BEGIN…ROLLBACK`, tests no session/correction/other-user drift and verifies report source. Signed HTTP test proves authorized RPC and honest fallback; all new SQL is DRAFT, not applied to production.

## Extra Hard — historical 2026-11-04 decision explicitly superseded

**CURRENT as of 2026-11-06:** the architect discontinued recovery of the lost
12 originals and approved a fresh, newly authored **6 P1 + 6 P5** trilingual
Extra Hard bank. The 12 new tasks are complete and private, 12/12 math QA,
bank `math-extra-hard-2026-11-original-v2`, not published/imported. The prior “same original 12”
constraint is **withdrawn**; do not attempt lost-source recovery or restore
obsolete bank placeholders. See
[the governing current document](math-p1p5-extra-hard-secure-content-governance-20261104.md).

**No production changes, no deletion of user data, no reset, no main merge or live migration, no Vercel.** All changes remain draft, public launch NO_GO.
