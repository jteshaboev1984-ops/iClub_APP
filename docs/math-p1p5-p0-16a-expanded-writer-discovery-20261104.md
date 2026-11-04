# Issue #450 — P0-16A: expanded academic-epoch writer discovery

**2026-11-04 · Actual live Supabase PostgreSQL catalog, SELECT-only · DRAFT engineering evidence · PUBLIC NO_GO**

## Executed, reproducible evidence

- New [read-only expanded graph](../supabase/tests/p1p5_v2_package0_rpc_write_graph_expanded_readonly.sql) was actually executed against the current production **function metadata only**, not learner rows.
- Compared with [P0-15 narrow graph](../supabase/tests/p1p5_v2_package0_rpc_write_graph_readonly.sql): previous **98 authenticated-callable named Exam Prep RPC roots**, **37** candidates reaching a narrowly parsed `exam_prep_` write. Earlier counts were sound for their narrower *heuristic*, not proof of exhaustive writes.
- P0-16A scans **all 580 current public/private catalog functions** for qualified nested calls, up to depth seven, and examines *any* source-text DML. It finds **43** authenticated named roots with possible write reachability: **41** reach a textual `exam_prep_` DML, and **2** are Chemistry-specific consent DML paths. **0** of the 43 have a detected release/academic epoch marker in the scanned call chain. Dynamic-SQL detector returns **0**, which **does not prove the absence** of dynamic or unqualified calls.
- Reproducible sorted root source fingerprint at the inspected production snapshot: `38d9e896fb7eb2ab70e9f550d97b0ef9`. This is a review/drift indicator, not a trusted security signature or release authorization.
- All SQL is `SELECT` over `pg_proc` / `pg_namespace`, not over user data, test attempts, content or entitlements.

## Four additional Mathematics routes missed by P0-15

| Additional public RPC | Actual qualified path reaching candidate DML | Correct treatment |
| --- | --- | --- |
| `get_exam_prep_diagnostic_progress_safe_v1` | `private.rebuild_exam_prep_placement_v1` | **Getter with side effects**; pre/post-release epoch and maintenance checks needed |
| `get_exam_prep_placement_safe_v1` | `private.rebuild_exam_prep_placement_v1` | **Getter with side effects**; same boundary |
| `get_exam_prep_state_safe_v1` | `private.rebuild_exam_prep_state_v1` | **Getter with side effects**; stage/evidence cannot revive prelaunch beta state |
| `grant_my_exam_prep_beta_consent_v1` | `public.record_exam_prep_beta_consent_v1` | Governance/consent writer; protect ownership and audit retention **without** applying a blanket Core learner reset |

Two other broad-DML routes are `grant_my_exam_prep_chemistry_consent_v1` and `revoke_my_exam_prep_chemistry_consent_v1`. They are **not Mathematics cleanup candidates**. Preserve Chemistry history, permissions and consent.

This is **confirmed source-call reachability**, not proof that each route writes in every invocation. A `GET`-named RPC must not be counted as read-only merely because its name starts with `get_`. A text match is not a completed runtime exploit or a security gate.

## P0-16B mandatory implementation and acceptance contract (NOT YET DONE)

1. **Reconcile full exact release candidate** — current 98 roots, 43 expanded candidates, 7 previous non-Core-guard groups, private/public wrappers, overloads, triggers, Edge/REST and future draft PR #469–#476 routes. Build an exhaustive **signed-off owner/scope-specific manifest**. Any unclassified reachable write means NO_GO. Do not assume the source hash or these counts are stable.
2. **Server-owned epoch and maintenance state** — new versioned additive private state initially disabled; preserve historical Core/AI/mentor/consent/audit information. One academic epoch per learner/program (and component-owned session evidence); freeze issuance and in-flight writes transactionally at authorized reset. Existing `private.exam_prep_require_core_access_v1()` is a `STABLE` entitlement guard, **not** an epoch/locking fence.
3. **Bind all genuine writes and reads with side effects** — on issuance (diagnostic, learning, timed/paper, correction, retest, weekly) record the server-issued epoch/authorization, then atomically validate it **inside** the response, finalization, profile, scheduling, report, getter-rebuild and queue paths before any mutation. A user-input epoch number or a fresh user-wide flag alone is insufficient: an old valid JWT/old phone tab could otherwise re-enter.
4. **Handle old-device and lost-ACK retries** — stale previously issued authorizations rejected with non-retryable conflict (P0-13 uses `PT409`), valid in-epoch identical retries idempotent, changed-payload retries denied. In-flight transaction holds a compatible epoch row lock through commit; reset waits, never races. Do not change official P1/P5 paper time/attempt behavior.
5. **Preserve unrelated records** — never delete users, current Practice v3, Tours, ratings/certificates, other subjects, AI grants, beta consent/audit history, and pending legitimate learner drafts before an exact GO. New D11 time decisions, weekly-budget snapshots and period receipts from unmerged PRs must be independently classified in one final cleanup manifest.
6. **Full independent disposable full-schema test** — use exact combined migration order (not a synthetic-only endpoint): real signed JWT → PostgREST → PostgreSQL 17/Chromium, pre-cutover old authorized client, same learner other device, simultaneous finalizer/reset, stale offline retry, P1/P5 independence, getter-rebuild, non-Math preservation, protected fingerprints, backup/restore. Keep source-only CI and hosted/device tests distinct.
7. **Separate release gate** — require frozen exact source SHA, classification owner, independent SQL/security review, versioned retention decision, live encrypted backup independently restored (only with separate authorization), explicit architect GO for one-shot scope. Do not execute release cleanup, enable public flags, merge or deploy as a byproduct of this checkpoint.

## What is and is not completed

**COMPLETED P0-16A:** extended production-safe catalog investigation, independently identified four additional Mathematics routes and two out-of-scope Chemistry consents, wrote executable read-only source inventory, preserved the PR #468 isolated branch. No real learner data were read or modified.

**OPEN P0-16B:** complete real runtime RPC epoch fencing, complete source/Edge/trigger inventory, full exact-schema adversarial E2E and authorized cutoff. **PUBLIC NO_GO.**

Related: [Issue #450](https://github.com/jteshaboev1984-ops/iClub_APP/issues/450), [P0-15](math-p1p5-p0-15-live-rpc-writer-coverage-20261104.md), [P0-13/14 disposable signed JWT/lock proof](math-p1p5-p0-13-p0-14-signed-epoch-and-concurrency-20261104.md), [v2 execution ledger](math-p1p5-v2-execution-ledger.md).
