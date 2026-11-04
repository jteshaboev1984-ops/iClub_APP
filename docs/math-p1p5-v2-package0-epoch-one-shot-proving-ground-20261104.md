# Mathematics P1/P5 — Package 0 P0-09: release-epoch and one-shot authorization proving ground

**2026-11-04 • Issue #450 • DRAFT • test-only, no release permission.** This is a continuation of the v2 workplan, P0-08 schema-drift inspection and earlier full 32-table synthetic rollback/independent restore. It is not an executable production migration or real-user cleanup procedure.

## Specific problem being closed

The original synthetic cleanup already proved a correctly ordered 32-table delete and rollback against the real migration schema. It did **not** prove that a real release request could be authorized only once, that an old mobile tab would fail after an epoch boundary, that active attempts block a reset, or that a missing restore/release SHA or a newly discovered FK would stop it. Those are independent technical controls.

P0-08 also found two proposed new per-user tables in unmerged PRs #469 and #470:
- `exam_prep_periodic_study_report_receipts_v1` has no `program_version_id`. **HOLD** for explicit retention / program-and-epoch classification; otherwise old receipts can suppress reports after a learner restart.
- `exam_prep_learner_exam_dates_v1` has user+program+component ownership. **REVIEW** for future scoped reset after the combined release SHA is frozen.

The original 32-table list is therefore provisional, not a release manifest. No existing academic source bank, content, audit or AI consent becomes a cleanup target simply because its table name begins `exam_prep_`.

## P0-09 disposable, executable proof

[SQL test](../supabase/tests/p1p5_v2_package0_epoch_one_shot_disposable_only.sql) runs solely inside the PostgreSQL 17 GitHub Actions database named `iclub_p1p5_package0_test`. It refuses other database names. All roles, tables and functions live inside a transaction ending in `ROLLBACK`; GitHub CI checks the disposable schema is absent afterward.

The test deliberately uses **fabricated data only** and creates a **model**, not a production-capable function. It verifies:

| Attack / boundary | Expected behavior |
| --- | --- |
| Learner granted neither cleanup function nor direct DELETE privilege | Permission denied |
| No architect approval or no independently restored backup / retention sign-off | Reset denied |
| Exam Prep write intake not paused | Reset denied |
| Active learner assessment in flight | Reset denied |
| A newly discovered dependency / FK drift | Reset denied |
| Wrong release SHA | Reset denied |
| Approved, scoped one-shot on a single fake Mathematics learner | Exactly three synthetic beta-state rows cleared; epoch increment + receipt atomic |
| Same one-shot request repeated | Denied |
| Old phone tab submits under prior epoch | Denied, no resurrection |
| New epoch learner writes | Accepted once intake reopens |
| Other Mathematics learner, Economics data, Tour/Practice/certificate, AI/audit fixture | Unchanged |
| Transaction rollback after demonstration | Three prelaunch rows, old epoch, unused ticket and absence of receipt restored |

**Proof:** [Package 0 isolated guard Actions run #41770388986](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/41770388986) completed SUCCESS, including the named step **`P0-09 isolated one-shot epoch authorization and replay/rollback matrix`** and source-scope checks. This was executed against disposable PostgreSQL 17 with no production credentials or records.

## Critical limits (not accepted yet)

1. The synthetic PostgreSQL `SESSION_USER` identities are a privilege fixture; they do **not** substitute for hosted Supabase Auth / signed learner JWT / Telegram entry verification. Hosted auth remains an independent gate.
2. The mock DELETE touches `p0_09_fixture.test_progress` only. It does **not** apply authorization to the original 32 production-shaped tables, the two newly drafted tables, or any history-bearing row. The earlier real-migration 32-table rehearsal and this epoch fixture have separate scopes and must be jointly exercised on an accepted candidate before release.
3. Test flags `explicit_approval=true` and `production_backup_restored=true` belong **only to fake data in the disposable transaction**; they do not represent any human GO or real encrypted production backup.
4. This exercise verifies single-call replay denial and row-lock discipline, but not a real multi-connection concurrent race, old hosted client offline-pending operations, or a production crash halfway through the protected cutover. Those remain engineering acceptance work.
5. In-flight app sessions must be quiesced by a future narrowly scoped server enforcement mechanism; it is not safe to rely on one browser flag, client clock or user logout. The final server design must bind issuance, submission, retries and post-reset academic read to the release epoch.
6. All current user history, Exam Prep beta data, current Mathematics Practice, Tours, certificates and other subjects remain untouched. No live migration, role grant, cleanup procedure or deployment was applied.

## Next P0-10 engineering acceptance (without live changes)

**Prove the combined case**, not another isolated paper design: review the exact accepted migration ordering for #469/#470/#471; determine receipt retention and date-table allowlist; introduce a versioned internal release-epoch/maintenance control that cannot be written by browser/JWT roles, and use true PostgREST/JWT old-tab negative cases against a disposable full-schema database. Prove the scoped 32+approved-new-table reset, idempotence, FK graph, protected-record fingerprints and backup/independent restore together. All permissions and data protections must fail closed. Only after these tests and a separately verified encrypted production backup can the architect approve the exact release SHA, manifest and one-shot run. Until then **NO_GO**.

References: [v2 workplan](math-p1p5-release-workplan-v2-20261102.md), [P0 release authorization contract](math-p1p5-v2-package0-release-authorization-contract.md), [P0-08 scope-drift proof](math-p1p5-v2-package0-draft-schema-drift-20261104.md), [execution ledger](math-p1p5-v2-execution-ledger.md).
