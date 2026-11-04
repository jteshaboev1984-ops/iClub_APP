# Mathematics P1/P5 Issue #450 — P0-10 combined scoped rollback / P0-11 period receipts

**4 November 2026 • DRAFT release-safety verification • no production GO.**

## P0-10 — verified earlier exact source

Earlier full migrated PostgreSQL 17 + signed HTTP/Chromium [GitHub Actions #41771990741](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/41771990741) completed **SUCCESS** on the branch before the subsequent P0-11 receipt-key improvement. Its scope was the authentic existing 32-table two-fake-user deletion/rollback with a prospectively mirrored unmerged learner-chosen-date table from PR #470 (P2-16, migration 20261103042000) and a prospective report-receipts table from PR #469. It validated unknown retained FK denial, two-user isolation, precise date deletion, receipt retention, repeated idempotence and SAVEPOINT restoration. The draft composite overlay was assembled with an exact original 32-table SQL file, using only a CI temporary script and a full transaction ending in ROLLBACK. The original 32-table script itself was not rewritten.

**Do not overclaim:** draft future tables were *prospective copies of SQL table definitions*, not actual migrations replayed from merged PRs; the old-format report receipt retention was an intentionally OPEN release blocker. The independent synthetic backup/restore is still a separate test. This is not a production backup, no controlled release epoch was installed and no real user data was touched.

## P0-11 — safer receipt ownership and new-diagnostic cycle isolation

Found a concrete lifecycle collision: the first draft PR #469 created weekly/monthly receipts with uniqueness only on `(user_id,period_kind,period_ended_at)`. That lacks a program key and a learning-cycle discriminator. After a planned one-time Mathematics beta reset, older receipts could accidentally suppress a newly completed week/month if the period boundary is equal, and a future multi-program reuse could mix a report family.

**Draft-only technical remediation** applied in [PR #469](https://github.com/jteshaboev1984-ops/iClub_APP/pull/469), source migration `20261103025000_exam_prep_p1p5_periodic_study_reports_v1.sql`:

- Add foreign-keyed `program_version_id` and factual `diagnostic_anchor_at` to the private receipts primary key: `(user_id,program_version_id,diagnostic_anchor_at,period_kind,period_ended_at)`.
- Insert both values from the existing **server-authorized** Exam Prep profile and **actually completed** component-diagnostic anchor. They cannot be supplied by the client; public authenticated direct table INSERT/DELETE is still revoked.
- Preserve one receipt per actual complete week/month per educational cycle across devices by `ON CONFLICT DO NOTHING`. Old receipt rows remain as audit/notification evidence; a new diagnostic cycle can issue fresh summaries even for the same calendar period.
- No hourly learning quota, daily reminder, AI/mentor authority, learner stage/evidence rewrite or cross-subject data sharing; user-visible copy remains unchanged.

The [prospective PG17 full-schema overlay](../supabase/tests/p1p5_v2_package0_future_state_overlay_disposable.sql) was updated to mirror this new DRAFT receipt definition and explicitly checks **same learner/same calendar period across two different diagnostic anchors** is permitted, while exact same-anchor replay is rejected. It continues to retain the receipt rows rather than deleting them, uses only fake IDs and rolls back all changes.

**Independent acceptance still required:** Exact current PR #469 migration must pass its signed JWT/PostgREST/PG17 and relevant periodic-report tests; the updated P0-10/P0-11 composite overlay also needs a new exact SHA CI PASS before treating this improvement as verified. The diagnostic anchor is a useful cycle discriminator but does not replace the required **versioned launch epoch and stale beta session write rejection**. An old phone can still call legacy endpoints until server-enforced epoch guards are actually installed. No time-based study limitations are introduced.

## Remaining Package 0 stop gates

1. Final accepted combined PR migration order and actual installed new-table + FK graph must be audited again. A draft prospective overlay cannot substitute for final schema review.
2. Preserve real historical receipt records, mentor/safeguarding/audit consent and three AI entitlements pending documented retention approval; do not delete an entire `exam_prep_*` table.
3. Versioned, restricted one-use live release authorization and server-side epoch fencing across **all** session creation/submit/recovery/plan RPCs; verify old signed JWT and queued retry fail closed.
4. Real, encrypted, restricted production backup with independently proven restore; current fake PostgreSQL 17 archive is not that backup.
5. Separate explicit architect GO for exact manifest, release SHA, cutoff time and protected baseline. **Public NO_GO** remains binding.

References: [v2 roadmap](math-p1p5-release-workplan-v2-20261102.md), [release authorization](math-p1p5-v2-package0-release-authorization-contract.md), [P0-08 drift](math-p1p5-v2-package0-draft-schema-drift-20261104.md), [P0-09 epoch fixture](math-p1p5-v2-package0-epoch-one-shot-proving-ground-20261104.md), [issue](https://github.com/jteshaboev1984-ops/iClub_APP/issues/450).
