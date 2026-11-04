# Mathematics P1/P5 Issue #450 — P0-12 full write-surface inventory before release epoch

**2026-11-04 | READ-ONLY live metadata | draft engineering risk register | public NO_GO.** No backend mutation, release gate or user-data reset is authorized.

## Factual Supabase production baseline

Queried the **live PostgreSQL catalog only** (function names/definitions and privilege metadata, no learner records), project `mmmduffgpvwjdpruzikw`. The reproducible [SELECT-only query](../supabase/tests/p1p5_v2_package0_write_entrypoints_readonly.sql) identifies the exact current public API set and the existing central Core-access guard.

| Catalog criterion | Live observation on 2026-11-04 | Correct interpretation |
| --- | ---: | --- |
| Public functions whose name includes `exam_prep` | 134 | Function objects/overloads, not API requests or enrolled learners |
| Functions marked SECURITY DEFINER in this set | 134 | High-impact privilege boundary; direct row security cannot substitute for a verified caller guard |
| Executable by role `authenticated` | 98 | Scope for authorization review, includes Core/mentor/beta workflows |
| Executable by `anon` | 0 | Good, but it does not prevent stale *valid* signed learner JWTs |
| Direct Exam Prep DML pattern candidates | 46 | Conservative **text pattern**, may miss dynamic SQL, indirect helper writes and unqualified table names |
| Of those, authenticated callable | 25 | High-priority direct learner write entrypoints; **not an exhaustive writer count** |
| Authenticated callable functions whose body mentions central `exam_prep_require_core_access_v1` | 75 | The remaining 23 require their own read-only audit; this says nothing definitive about their mutation capability |
| Authenticated callable functions with textual release/academic/progress epoch marker | 0 | **Does not prove absence of all indirect epochs**; central guard separately confirmed no epoch control |

**Confirmed central guard:** `private.exam_prep_require_core_access_v1()` verifies `auth.uid()`, membership in `public.users`, `private.exam_prep_feature_config` rollout/core/kill switch and either broad QA access or an active Core entitlement. **It does not compare a request/session academic epoch**. That is not a defect in the current controlled beta; it becomes a critical prelaunch reset blocker because signed old browser requests could remain valid after a once-only beta-progress purge.

## Highest-value stale-client surfaces to fence first

Before any real cleanup, inspect exact current source and existing idempotency/ownership logic for:
- Session and assessment writes: `start_exam_prep_next_diagnostic_safe_v1`, session authorization, `submit_exam_prep_response_safe_v1`, `finalize_exam_prep_session_safe_v1`, `finalize_exam_prep_timed_safe_v1` and written step progression.
- Progress and planning writers: `ensure_exam_prep_weekly_goals_safe_v1`, learning review, correction/retest/revalidation, `save_exam_prep_exam_profile_v2`, exam-date/profile/schedule writers (including **draft PRs #469/#470**), and generated weekly flows.
- Integrity and authorization: `record_exam_prep_integrity_event_safe_v1`, `authorize_exam_prep_timed_safe_v1`, any retry/session-authorizations and nested private helpers; old UI/API routes may call more than one routine.
- Separate protected administrative or mentor/AI paths: **do not revoke or rewrite these blindly** as if all 98 are learner-progress writers. Keep required beta consent/audits, restricted AI entitlements and human-review controls.

**Important:** A name/regex inventory does not prove a closed call graph. The query explicitly looks for public wrappers outside the `exam_prep` name group and must be reconciled with current GitHub/Vercel client calls and any Edge Functions before a final epoch migration is declared comprehensive.

## P0-12 acceptance decision

- **No global auth/feature kill switch rewrite in production now.** Core learning continues in the current beta.
- A future release-epoch service must bind the active user+program+learning epoch to newly issued sessions, item submissions, idempotent retries, correction/retest writes, plan generation, exam-profile updates and claims, with a forced legacy-client refresh path. No time quota or progress auto-promotion.
- Use server-enforced write-intake quiescence before reset. Deny old-epoch requests even with a still-valid JWT; do not rely on a browser variable alone. Advance the epoch only within a validated one-shot, backup-backed release transaction.
- Test true multi-connection concurrent write/cleanup, loss of ACK, device offline replay, 0/1/2 component diagnostics, both P1/P5 isolation, all retained old notifications and session provenance. Simulated P0-09 privileges and P0-10 overlay tests remain useful **partial** proofs only.
- Review final combined PR SHA migration order, direct and nested RPC write map, exact table/FK scope, independently restored encrypted production backup, and obtain separate architect GO. Until then **NO_GO**.

See [Issue #450](https://github.com/jteshaboev1984-ops/iClub_APP/issues/450), [v2 roadmap](math-p1p5-release-workplan-v2-20261102.md), [P0-09 mock authorization](math-p1p5-v2-package0-epoch-one-shot-proving-ground-20261104.md), [P0-10/P0-11 combined scope](math-p1p5-p0-10-p0-11-combined-scope-and-receipts-20261104.md) and [execution ledger](math-p1p5-v2-execution-ledger.md).
