# iClub Exam Prep — Stage 4: ordered private written-plan path

**Date:** 2026-10-22  
**Status:** PRIVATE SERVER HARDENING INSTALLED / ECONOMICS NO-GO.  
**Migration:** `20261022152858_iclub_exam_core_written_ordered_path_private_v1.sql`.  
**Scope:** additive changes only to private Economics-compatible written-plan infrastructure. Existing Mathematics, Practice, Tours, localStorage and learner history remain outside the change.

## Why this stage exists

Stage 3 introduced a private `open / criteria / advance / status` service. Its `advance_v1` is idempotent and checks learner/program/task access, but does not itself enforce an earlier `open` or previous ordered steps. `advance_v1` remains private and unchanged. Future student integration **must not** call it as the authoritative ordered-plan progression method.

## Implemented, not released

1. A partial unique index on `(learner_user_id, program_key, version_key)` where plan `status='active'`. Exactly one active plan per learner/program/version; drafts and historical closed plans remain intact.
2. `private.iclub_exam_core_written_next_item_v1(program_key, version_key, language)` finds the *first* pending step by plan order. It does not skip a draft/unreleased first step and never returns answer requirements. It checks auth identity, active learner access, published native program, enable switch, released/academically reviewed task and available localization.
3. `private.iclub_exam_core_written_advance_v2(item_id, task_key, task_version, task_token, idempotency_key)` checks all Stage 3 ownership, program, content and service gates **plus** `opened_at IS NOT NULL` and no lower-priority pending steps. It atomically advances the row, protecting duplicate requests using the existing nonce and row lock.
4. Both functions are accessible only to `service_role`; `anon` and `authenticated` have no direct `EXECUTE` privilege. No public wrappers, UI imports, new learner entitlements or content publication were added.

**Academic semantics:** `advanced` means only a study-plan navigation fact. No score, mastery, readiness, text submission, AI rating or mentor task is written or inferred.

## Post-migration database checks (2026-10-22)

| Check | Observed |
|---|---|
| Migration installed | 20261022152858 |
| Private tasks | 22 EN-only drafts |
| Released written tasks | 0 |
| Learner written plans / steps / access assignments | 0 / 0 / 0 |
| Economics program | `draft`, `launch_enabled=false` |
| New partial unique index | Present |
| New functions directly executable by anon/authenticated | No |
| New functions executable by service_role | Yes |
| No-auth guard on both new functions | Passed SQL expected-denial test |
| Legacy Mathematics sessions / responses | 543 / 1976 |
| Legacy Practice attempts / answers | 502 / 4816 |
| User-subject selections | 2098 |

These are count/permission/denial checks, **not** authenticated positive-path, concurrency, end-to-end or row-checksum verification. Production learner E2E has **not** passed.

## Critical implementation rules for next stage

- Build the native plan generator as a separate, versioned service. Order by explicit `priority_order`, do not copy Mathematics plan tables and do not pre-create active user plans merely because they have opened the subject.
- For normal written practice, use the Stage 4 ordered advancement, not the old `advance_v1`. Preserve existing `written-core-controller-v1.js` until it is intentionally paired with a newly reviewed transport.
- The presently private `open_v1` can open a known item ID without checking earlier pending items. If the UX requires strict ordered opening, build and test an **ordered open successor** before releasing a student endpoint. No direct access to the existing private RPCs is allowed from the browser.
- A protected public RPC or Edge Function transport must use the learner JWT and server-side access checks; never ship service_role credentials to the client. Test cross-account isolation, repeated `Next`, lost responses/recovery and disconnection before granting use.
- Academic QA and RU/UZ/EN localization for all 22 draft tasks remain pending. Section A source documents, diagrams and command-words must be verified. Do not make them `approved`/released prematurely.
- Strict sequence is currently a **closed implementation assumption**. Before learner rollout the architect must decide whether future plan entries can be deliberately opened out of order; any deviation needs explicit scoped policy, not bypassing `advance_v2`.
- Full timed Paper 2/4 essay storage/marking is a separate unresolved policy. No automatic unreviewed essay scores.
- Keep `Economics NO-GO` and `launch_enabled=false` until native server plan + authenticated E2E + browser QA + release authorization.

## Preservation and rollback

No historical rows were migrated or altered. The migration adds one index and two private functions; they are unused by the production host. If a later integration fails, keep the Economics flag OFF and revert the new transport/deployment without deleting attempts, data, migrations or user history.

**Next engineering unit:** native Economics plan selection and ordered open/criteria/status transport in a closed environment, with authenticated testing after academic sign-off; then the MCQ bank QA and fully governed diagnostic runtime.
