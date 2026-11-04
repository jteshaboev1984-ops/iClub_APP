# Mathematics P1/P5 v2 — Package 0 prelaunch reset authorization contract

**Issue #450 · 2026-11-02 · DRAFT SAFETY CONTRACT · NOT release GO**

This document translates the architect-approved **goal** (one-time clearing of prelaunch Mathematics Exam Prep learner test progress at launch) into **explicit gates**. It does not authorize clearing any existing beta account now, changing production feature configuration, deploying the application or executing the synthetic-only cleanup entrypoint on a real learner.

## Verified engineering evidence, separate from approval

- Production SELECT-only report: 32 *provisional* learner-state tables and 19,794 rows at the 2026-11-02 sample, 37 internal FKs and one retained Mentor inbound FK. Actual snapshot must be repeated at release boundary.
- Two independent nullable FK cuts required: `exam_prep_session_authorizations.consumed_session_id` and `exam_prep_session_authorizations.correction_case_id`; actual production FK-graph SELECT verifies zero remaining internal cycles afterward.
- [Full 32-table isolated transaction test](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/41502015565): GREEN only on disposable PostgreSQL 17 with two fake learner accounts, real schema, 32 target tables, immutable-row refusal, scoped cleanup, idempotent repeat and SAVEPOINT rollback.
- [Independent synthetic custom backup and restore](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/41503416002): GREEN; separate restored PostgreSQL 17 database, matching deterministic fingerprints, archive discarded. This **does not mean a backup of real production users has been made**.
- Existing `private.exam_prep_block_immutable_mutation_v1()` rejects ordinary updates and deletes. The synthetic-only GUC is **not authorization** to delete real beta progress. A versioned, independently reviewed real-release mechanism is needed.

## Proposed keep/clear register — release decision still required

| Record family | Proposed prelaunch disposition | Guard |
| --- | --- | --- |
| Authentication, `public.users`, `user_subjects`, school profile | **KEEP** | Never part of Math Exam Prep cleanup |
| Mathematics and all other Tours, answers, ratings, certificates | **KEEP** | Independent production domain |
| Published Mathematics Practice bank v2, client history namespace `practice_history_v3`, drafts and attempts | **KEEP** | Prior Practice rollout already happened; never repeat reset |
| Economics/Chemistry/Biology/CS user states and their beta history | **KEEP** | Component/subject isolation |
| Mathematics Exam Prep syllabus, source map, approved questions, written tasks, content versions, QA, academic contract, paper metadata | **KEEP** | Source of new postlaunch learning |
| Exactly three AI Assist entitlements, AI consent/policy and AI audit/usage | **KEEP pending separate AI launch** | No fourth entitlement from Core release |
| Beta cohort membership and explicit beta consent records | **HOLD / KEEP initially** | Historical authorization must not be fabricated or destroyed; optional retirement requires separate explicit decision |
| 14,748 historical `exam_prep_audit_events` at 2026-11-02 sample | **HOLD / KEEP initially** | Audits may include user IDs and before/after data; security/privacy retention review separate from academic progress reset |
| Staff, safeguarding, mentor reviews/assignments, service incidents | **HOLD / KEEP initially** | Not automatically learner academic test progress |
| Candidate Mathematics Exam Prep learner profile, P1/P5 stages, skills, per-user plans, sessions/answers/evidence/corrections, written traces and retests | **RESET only once at GO, after new versioned authorization** | Exact ownership/descendant list, source program id, user allowlist; not table-wide indiscriminate DELETE |
| Synthetic test identities and QA evidence repositories | **KEEP governed engineering records** | Existing dedicated synthetic cleanup flow only for verified synthetic fixtures |

No retention duration, consent revocation or deletion of existing genuine records is newly approved by this draft. On uncertainty, keep data and block the launch reset.

## Required one-shot operation contract — NOT implemented

**A. Approvals.** Architect must explicitly authorize the *exact* release candidate SHA, dated program key `math_as_p1_p5`, intended classes of real prelaunch data, and precisely which audit/consent/AI/history rows are retained. An engineering CI PASS or draft PR alone is not GO.

**B. Stop new writes, not the app.** Implement a server-controlled Mathematics Exam Prep maintenance/epoch boundary with an isolated authorized release path. Do not switch off Practice/Tours or unrelated subject routes. Check in-flight sessions, pending idempotent retries, stale mobile tabs, existing participant session locks and authorization tokens. Disallow old beta submissions from recreating prior academic progress after reset.

**C. Backup and recovery.** Produce an encrypted, access-restricted, user-scoped production backup with per-table count and checksum manifest. Verify a restore in a separate controlled environment, without uploading personal rows to GitHub or placing archives in public storage. Refuse to proceed on any mismatch or missing evidence.

**D. Fresh fail-closed preflight.** Lock the chosen reset epoch; compare active program/content version, 32-table candidate FK graph, every indirect child, retained Mentor links, user/subject ownership, three AI grants and consent states, public protected-data fingerprints and target row counts to the approved manifest. Any schema drift or newly retained-table inbound reference means STOP.

**E. Separate versioned authorization.** Design an internal-only, non-public, one-use, security-reviewed cleanup function for real prelaunch Mathematics test progress. It must neither rely on opening `iclub.exam_prep_synthetic_cleanup` to live users nor disable immutable triggers broadly. Privileges must be limited to the release executor, one exact approved program and release epoch, and covered by negative access tests for `anon`, `authenticated`, beta user and ordinary service calls.

**F. Atomic, scoped mutation only after GO.** Verify origin and protected counters; address the *two* nullable FK cut points, dependents and root records in a reviewed transaction; assert intended rows cleared and protected rows byte-identical. Rollback on mismatch. Persist a non-forgeable audit result and retired prelaunch epoch. Never silently reset localStorage or global app state.

**G. Fresh learning, rollback safety.** The new P1/P5 diagnostic begins only under the new epoch. Immediately test Core study and competitive access, AI-only three users, no subject bleed, login from old phone, protected answers and idempotence. If any genuine postlaunch learning exists, do not restore a prelaunch snapshot over it: first withdraw the release path safely and reconcile conflicts case-by-case.

## Release acceptance and negative test matrix

| Case | Required evidence |
| --- | --- |
| Old beta tab submits after new epoch | Rejected or explicitly upgraded without resurrecting previous learning |
| Active diagnostic/learning/Paper while preparing purge | No silent deletion; quiescence or safe abort shown |
| Anonymous, normal learner, fourth non-AI learner invokes cleanup | Server denies; no side effects |
| One immutable response without special release permission | DELETE denied (already tested in isolated PG17) |
| New FK from retained table to reset table | Preflight fails closed |
| Missing actual production backup/restore manifest | Release cleanup denied |
| One of 3 AI entitlements changed | Cleanup denied and entire transaction rolls back |
| Non-Math/Practice/Tours/certificate fingerprint differs | Rollback, NO_GO |
| Full 32-table repeated scoped cleanup in isolated CI | Idempotent (already GREEN) |
| Archive/restore of two known fake learners | Independent PG17 restore exact match (already GREEN) |
| New real data written after launch | No blanket PITR over genuine data |

## Current decision and handoff

**TECHNICAL SYNTHETIC PROOFS: GREEN; REAL PRODUCTION RESET: NOT AUTHORIZED; PUBLIC MASS CORE: NO_GO.**

First outstanding engineering work is a versioned **real-prelaunch release-epoch + one-shot authorization design** and negative E2E tests, then a genuinely safeguarded production backup/restore only when release-time authorization is given. Independently start Package 1 by read-only academic source/date discovery only if the architect permits parallel non-release work; do not silently treat this contract as Package 0 GO.

Sources: [approved v2 workplan](math-p1p5-release-workplan-v2-20261102.md), [change-control addendum](math-p1p5-v2-governance-addendum-20261102.md), [execution ledger](math-p1p5-v2-execution-ledger.md), [protected data runbook](math-p1p5-v2-package0-cleanup-runbook.md).
