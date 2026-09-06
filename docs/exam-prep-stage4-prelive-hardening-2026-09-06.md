# Exam Prep Stage-4 Pre-Live Hardening Evidence — 2026-09-06

**Program:** `math_as_p1_p5`  
**Branch:** `main`  
**Scope:** deterministic Core / P1-03 pre-live hardening  
**Decision:** **STAGE 4 REMAINS LOCKED. PAPER 02 REMAINS UNRELEASED. CONTROLLED BETA REMAINS OFF.**

## 1. Why this record exists

This record captures the Stage-4 preparation added after the 2026-09-05 release-readiness record. The work below prepares safe future Stage-4 operation but does not approve Stage 4, does not unlock any learner, and does not publish the second full-paper forms.

## 2. Second full-paper forms are prepared but not released

Two original iClub-authored full-paper forms are pre-positioned in production:

| Component | Assessment | Items | Marks | Syllabus breadth | Current assessment state | Timed contract |
|---|---|---:|---:|---:|---|---:|
| P1 | `p1_stage4_full_paper_02` | 10 written | 75 | 8 / 8 sections | `approved` | 0 |
| P5 | `p5_stage4_full_paper_02` | 7 written | 50 | 5 / 5 sections | `approved` | 0 |

Their governed content versions are published so the tasks/rubrics are versioned and QA-governed, but the assessments themselves are not published and have no timed contracts. Therefore they are not learner-visible and cannot be started.

Source commit for the two forms: `d678a00c0721608150d5982874d7d53c59534330`.

## 3. Per-contract minimum-stage hardening is deployed

The timed contract now supports an optional `min_operational_stage` override. Existing contracts keep their old behavior when this field is `NULL`.

The effective-stage rule is fail closed:

- the attempt-kind default remains the floor;
- an override may only raise the minimum stage, never lower it;
- existing Paper 01 forms remain effective Stage 3;
- future Paper 02 contracts can be explicitly Stage-4-only.

The catalog and the direct authorization RPC both enforce the same effective minimum stage. This prevents a learner from bypassing the catalog by directly requesting authorization.

Production migration: `20260905160000_exam_prep_p1_03_timed_contract_stage_override.sql`.

Full regression before production deployment passed after the fixture corrections; the Stage-3 case hides Paper 02 and rejects direct authorization, while the rollback-only Stage-4 case exposes and authorizes it.

## 4. Stage-4 raw evidence reader is deployed but cannot unlock Stage 4

Production includes read-only function:

`private.exam_prep_stage4_raw_evidence_v1(uuid,bigint,text)`

It reads factual evidence only, including:

- comparable official full-paper attempts;
- comparison families across different forms under the same official timing/profile conditions;
- unattempted-mark and after-time shares;
- canonical skill levels;
- skills below L3;
- correction cases and concrete pending/scheduled remediation actions.

It deliberately returns:

- `trend_policy_status='not_deployed'`;
- `corrective_plan_policy_status='not_deployed'`;
- `stage4_exit_ready=false`;
- `stage4_unlocked=false`;
- `stage5_unlocked=false`.

Production read-only verification against a staged Core candidate returned zero attempts, P1 denominator 45, P5 denominator 36 and no Stage-4 unlock.

Source commit: `0cfadfef47e931430a7f9260344f0ebe9ff54c75`.

## 5. Stage-4 policy remains proposal-only

A rollback-only policy proposal has been tested in CI but is not a production policy. The proposal currently treats timing improvement conservatively: unattempted share and after-time share must not worsen, and a corrective plan must contain a concrete linked next action. Score alone cannot compensate for timing deterioration.

This proposal must not be treated as approved governance. No production Stage-4 exit evaluator exists yet.

## 6. Paper 02 now has an additional release lock

Production includes the fail-closed control:

`private.exam_prep_stage4_release_controls`

Active control:

- `control_version='stage4_paper02_release_guard_v1_2026_09_06'`;
- `stage4_policy_status='pending'`;
- `paper02_release_status='pending'`;
- Stage-3 key registry must be approved and non-empty for the component;
- required Paper 02 minimum stage is 4.

Paper 02 publication is blocked at two levels: assessment publication and timed-contract publication. Before release can succeed, all of the following must be true:

1. Stage-4 policy is explicitly approved;
2. Paper 02 release is explicitly approved;
3. Stage-3 key-skill registry is approved;
4. that component has at least one governed key-skill row;
5. the real Stage-4 exit evaluator is deployed;
6. per-contract stage hardening is deployed;
7. the Paper 02 contract explicitly resolves to Stage 4 or later.

A single flag change is therefore not enough to release the second paper accidentally.

Production migration: `20260905160500_exam_prep_p1_03_stage4_paper02_release_guard.sql`.

## 7. Regression evidence

Final full P1-03 regression run after integrating the release guard and updating the rollback fixtures:

- workflow run: `34001156468`;
- result: **SUCCESS**.

The run passed the existing content runway regression, timed/modified-paper flow, Stage 1→2→3 transitions, Stage-3 exit evaluator, key-skill proposal matrix, Stage-4 evidence/policy proposal matrices, raw evidence reader, per-contract minimum-stage override, Stage-4 Paper 02 release guard, and final zero-residue check.

All synthetic Stage-4 approvals, key-skill rows, learners and evaluator stubs used by tests are created only inside rollback transactions and are verified absent afterward.

## 8. Production state after deployment

Verified after deployment:

| Control | State |
|---|---|
| P1 Paper 02 | `approved`, timed contracts `0` |
| P5 Paper 02 | `approved`, timed contracts `0` |
| P1 Paper 02 release readiness | `false / stage4_policy_pending` |
| P5 Paper 02 release readiness | `false / stage4_policy_pending` |
| Stage-3 key registry | `pending / 0 rows` |
| real Stage-4 exit evaluator | absent |
| automatic stage ceiling | `3` |
| learner consent | `0 / 3` |
| active Exam Prep entitlements | `0` |
| Exam Prep sessions | `0` |
| evidence events | `0` |
| timed results | `0` |
| authoritative stage-state rows | `0` |
| rollout | `off` |
| Core | `false` |
| AI Assist | `false` |
| Mentor Care | `false` |
| kill switch | `true` |

The new Stage-4 release-control table is not readable or writable by `anon` or `authenticated` clients.

## 9. Current boundary

**Complete:** second P1/P5 forms prepared; raw Stage-4 evidence reading; per-contract Stage-4 access hardening; fail-closed Paper 02 release governance; rollback-only policy experimentation.

**Still intentionally incomplete:** governance-approved Stage-3 key-skill registry; authoritative Stage-4 exit policy/evaluator; Paper 02 release; real learner Stage-4 evidence; controlled-beta activation; AI/Mentor activation.

No Vercel configuration was changed by this work.
