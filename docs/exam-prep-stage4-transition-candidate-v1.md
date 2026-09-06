# Exam Prep Stage-3 → Stage-4 Transition Candidate v1

**Program:** `math_as_p1_p5`  
**Scope:** Cambridge AS Mathematics 9709 P1 + P5  
**Status:** **TEST-ONLY CANDIDATE — NOT APPROVED / NOT DEPLOYED AS STAGE-4 POLICY**  
**Date:** 2026-09-06  
**Production automatic stage ceiling:** `3`  
**Paper 02:** **UNRELEASED**  
**Controlled beta:** **OFF**

## 1. Purpose

This candidate connects the already deployed Stage-3 exit evidence and Stage-4 raw evidence into one rollback-only decision model. It is designed to test whether the future Stage-4 rules are internally coherent before any production Stage-4 progression exists.

Nothing in this candidate approves Stage 4, publishes Paper 02, changes learner entitlements, starts the beta, activates AI/Mentor, or changes Vercel.

## 2. Candidate Stage-4 entry dependency

Stage-4 entry eligibility begins only after the existing production Stage-3 exit evaluator for the same component reports `ready=true`.

That means the component already has:

- 100% canonical syllabus coverage;
- every canonical skill at least L2;
- governance-selected key skills at least L3;
- at least one finally score-comparable official full-paper baseline;
- no unknown syllabus section.

The test uses the existing 15-skill proposal only as a rollback fixture: 8 P1 skills and 7 P5 skills. It does **not** approve or populate the production registry.

## 3. Candidate Stage-4 exit logic

The test-only candidate follows the Master Plan contract:

1. Stage-3 exit is complete for that component.
2. At least **2 compatible, finally reviewed, strict full-paper attempts** exist in one comparison family.
3. Timing/unattempted performance is improving under the candidate rule.
4. Every canonical skill is at least L3, **or** every remaining lower-than-L3 skill has a current, exact corrective plan.
5. Stage 5 remains locked and separate.

Even when all candidate conditions pass, the test returns `stage4_unlocked=false`. The purpose is to validate the decision logic before wiring operational progression.

## 4. Candidate timing rule

No score threshold is invented.

For the latest two compatible full-paper attempts:

- unattempted-mark share must not worsen;
- after-time share must not worsen;
- at least one of those two deficits must improve;
- if both deficits are already zero, remaining at zero is acceptable;
- invalid or missing values fail closed.

A score/review result cannot compensate for worsening time completion.

## 5. Candidate explicit-corrective-plan rule

A lower-than-L3 skill qualifies only when it has an exact active correction case and a concrete current next action linked to the same learner, component and skill.

The candidate accepts either:

- an active weekly-plan `correction`/`retest` action that is still pending and has a non-expired `due_at`; or
- a genuinely future `scheduled` retest with `due_not_before`; or
- an `authorized` retest that has a real authorization id.

The following do **not** qualify:

- an open correction case by itself;
- a pending action with no due time;
- an overdue/stale pending action;
- a scheduled retest whose due boundary has already passed;
- unrelated skill/component/user plans.

This closes the main weakness in candidate v0, where a stale label could look like a valid corrective plan.

## 6. Rollback-only end-to-end matrix

The new matrix proves, using synthetic data that is rolled back:

- production-like baseline starts with Stage-3 key registry pending/empty and Stage 4 locked;
- the full 15-key proposal can be used as a CI fixture without becoming production governance;
- one comparable full paper can complete Stage-3 exit but is insufficient for Stage-4 consolidation;
- a second different full-paper form under the same official profile can form the required comparable pair;
- improving timing plus two papers still fails when a remaining L2 skill has no corrective plan;
- an overdue corrective action still fails;
- a future exact corrective action can make the candidate evaluator report `ready`;
- even in that `ready` state, Stage 4 is **not** wired or unlocked;
- worsening an after-time dimension immediately fails the timing gate even when the corrective plan is valid;
- restoring the timing evidence restores the candidate result;
- P1 evidence cannot satisfy P5;
- the automatic stage ceiling remains 3;
- feature state and entitlements remain off;
- rollback removes all synthetic approvals, registry rows, Paper-02 contract, synthetic learner and runtime evidence.

## 7. Production boundary

Until a later explicit governance release, production remains:

- `key_registry_status='pending'` with 0 Stage-3 key rows;
- `stage4_policy_status='pending'`;
- `paper02_release_status='pending'`;
- no production Stage-4 exit evaluator;
- `max_automatic_stage=3`;
- Paper 02 assessments approved but unreleased and without timed contracts;
- controlled beta off, no active Exam Prep entitlements;
- AI Assist off;
- Mentor Care off.

A later production release must still be separately approved. Passing this candidate test is evidence that the future rules are technically coherent; it is not permission to activate them.