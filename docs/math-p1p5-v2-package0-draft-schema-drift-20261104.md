# Issue #450 — P0-08 cross-PR prelaunch learner-state drift (4 November 2026)

**Status: production SELECT-only verified; initial 32-table reset plan is NOT complete against draft features. NO_GO.** This is an additive safety finding, not permission to perform a reset or merge PRs. This document belongs to draft PR #468 and is an extension of the Package 0 release authorization contract.

## What changed after the original 2026-11-02 cleanup rehearsal

The isolated 32-table exercise and independent PG17 restore were successful on the **then-current schema**, but subsequent draft features propose two additional per-user tables. Read their exact SQL, not just a feature summary:

| Draft feature | Proposed table | Explicit ownership | Required release review |
| --- | --- | --- | --- |
| [PR #469](https://github.com/jteshaboev1984-ops/iClub_APP/pull/469), weekly/monthly reports | `private.exam_prep_periodic_study_report_receipts_v1` | `user_id` + `period_kind` + `period_ended_at` (PK). **No `program_version_id`.** | **HOLD.** A blanket cleanup based only on `user_id` could affect reports not provably confined to the Math P1/P5 program after future program expansion. Confirm exact scope and decide whether historic notification receipts are retained or governed-reset; require a versioned ownership/epoch contract before any delete. |
| [PR #470](https://github.com/jteshaboev1984-ops/iClub_APP/pull/470), learner-selected dates (P2-16 migration 20261103042000) | `private.exam_prep_learner_exam_dates_v1` | `user_id`, `program_version_id`, `component_code` (PK) | **REVIEW.** This is Math learner planning state outside the original 32 tables. If included in final beta progress reset, join a verified Math program version and exact approved user cohort; never delete table-wide. |
| [PR #469](https://github.com/jteshaboev1984-ops/iClub_APP/pull/469), study schedule | Existing `private.exam_prep_exam_profiles` gets two additive cadence columns | Already one of 32 provisional tables | Column-level drift must be checked before restore. Do not restore older row definitions over genuine post-release work. |
| [PR #471](https://github.com/jteshaboev1984-ops/iClub_APP/pull/471), Stage C countdown | No new learner table | Read-only getter contract and client timer | No change to deletion allowlist; still requires code/deployment acceptance separately. |

The new source registers in PR #470 (81-skill norms, historical teaching references and protected academic calibration) are **content/governance**, not beta learner attempts; they must not be swept into the learner reset because their names start `exam_prep_`. PR #470 P2-17 uses the existing governed profile writer for study hours; never rewrite an existing learner's evidence when applying a scheduling change.

## Fresh read-only production check (2026-11-04)

Ran [the new metadata-only SQL inspection](../supabase/tests/p1p5_v2_package0_future_tables_readonly.sql) against Supabase project `mmmduffgpvwjdpruzikw` (PostgreSQL 17). **Both proposed learner tables are currently ABSENT in production**: no production PR migration applied. The database continues to have 122 private `exam_prep_%` tables; this broader count is NOT a reset-table count. None of these checks read or expose a learner's report/date content or perform DML/DDL.

## Mandatory additional fail-closed acceptance before one-shot launch reset

1. Rebuild the scope manifest from the **exact combined and accepted release candidate SHA**, not from draft PR #468's old 32-table list. Classify each installed new learner table and each new column, incoming FK, subject/program key, ownership and epoch. Pending classifications block reset.
2. For periodic receipts, establish a **program/epoch-safe boundary** or an explicit, reviewed retention decision. Old receipts may otherwise suppress a first post-reset weekly/monthly report; do not call this harmless test data or indiscriminately erase other-subject notifications.
3. If learner-selected dates are accepted, test that the scope derives from **both** the approved Math program version and exact intended user set. Verify dates for a different user/program survive byte-identical.
4. Extend disposable, real-migration PG17 two-user + protected-record regression to the additional approved table(s), both nullable legacy FK cuts, idempotent repeated operation, immutable protection, and independent encrypted production-specific backup/restore acceptance at GO.
5. Version, test and require the **real release epoch, write quiescence and restricted one-shot authorization** before any production delete. Never use the synthetic-only GUC for real participants. An old browser tab, delayed RPC, or pending retry must not resurrect prelaunch progress or circumvent the new epoch.
6. The architect must separately approve release SHA, final table allowlist, report-retention policy and protected-data manifest. Until then the automatic result is **NO_GO**, including when GitHub Actions are green. No user/local state can be cleared from this check.

**Result:** a concrete newly identified P0 schema-drift blocker and a reproducible SELECT-only inspection. Real release-authorization, epoch guard and scoped production backup remain **open**. Work on Package 1/2 and Stage C in separate draft PRs is preserved; there is no reason to redo their already verified E2E.

References: [v2 roadmap](math-p1p5-release-workplan-v2-20261102.md), [original authorization contract](math-p1p5-v2-package0-release-authorization-contract.md), [execution ledger](math-p1p5-v2-execution-ledger.md), [Issue #450](https://github.com/jteshaboev1984-ops/iClub_APP/issues/450).
