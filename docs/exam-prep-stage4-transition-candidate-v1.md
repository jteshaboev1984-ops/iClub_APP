# Exam Prep Stage-3 → Stage-4 Transition Candidate v1

**Program:** `math_as_p1_p5`  
**Scope:** Cambridge AS Mathematics 9709 P1 + P5  
**Status:** **TEST-ONLY CANDIDATE — NOT APPROVED / NOT DEPLOYED AS STAGE-4 POLICY**  
**Date:** 2026-09-06  
**Production automatic stage ceiling:** `3`  
**Paper 02:** **UNRELEASED**  
**Controlled beta:** **OFF**

## 1. Purpose

This candidate connects the already deployed Stage-3 exit evidence and Stage-4 raw evidence into one rollback-only decision model. It tests whether the future Stage-4 rules are internally coherent before any production Stage-4 progression exists.

Nothing in this candidate approves Stage 4, publishes Paper 02, changes learner entitlements, starts the beta, activates AI/Mentor, or changes Vercel.

## 2. Candidate Stage-4 entry dependency

Stage-4 entry eligibility begins only after the existing production Stage-3 exit evaluator for the same component reports `ready=true`.

That means the component already has:

- 100% canonical syllabus coverage;
- every canonical skill at least L2;
- governance-selected key skills at least L3;
- at least one finally score-comparable official full-paper baseline;
- no unknown syllabus section.

The tests use the existing 15-skill proposal only as a rollback fixture: 8 P1 skills and 7 P5 skills. They do **not** approve or populate the production registry.

## 3. Candidate Stage-4 exit logic

The test-only candidate follows the Master Plan contract:

1. Stage-3 exit is complete for that component.
2. At least **2 compatible, finally reviewed, strict full-paper attempts** exist in one comparison family.
3. Timing/unattempted performance is improving under the candidate rule.
4. Every canonical skill is at least L3, **or** every remaining lower-than-L3 skill has a current, exact corrective plan.
5. Stage 5 remains locked and separate.

Even when all candidate conditions pass, the tests return `stage4_unlocked=false`. The purpose is to validate the decision logic before wiring operational progression.

## 4. Candidate timing rule

No score threshold is invented.

For the latest two compatible full-paper attempts:

- unattempted-mark share must not worsen;
- after-time share must not worsen;
- at least one of those two deficits must improve;
- if both deficits are already zero, remaining at zero is acceptable;
- invalid or missing values fail closed.

A score/review result cannot compensate for worsening time completion.

Completed timed attempts are immutable. A past attempt cannot be rewritten to make a trend look better or worse. A deterioration and a later recovery must be represented by **new full-paper attempts**. This was explicitly verified by the candidate regression after the first draft of the matrix tried to mutate a completed result and was correctly rejected by the existing immutable-fact guard.

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

## 6. P1 rollback-only end-to-end matrix

The P1 candidate matrix proves, using synthetic data that is rolled back:

- production-like baseline starts with Stage-3 key registry pending/empty and Stage 4 locked;
- the full 15-key proposal can be used as a CI fixture without becoming production governance;
- one comparable full paper can complete Stage-3 exit but is insufficient for Stage-4 consolidation;
- a second different full-paper form under the same official profile can form the required comparable pair;
- improving timing plus two papers still fails when a remaining L2 skill has no corrective plan;
- an overdue corrective action still fails;
- a future exact corrective action can make the candidate evaluator report `ready`;
- even in that `ready` state, Stage 4 is **not** wired or unlocked;
- completed attempt facts cannot be edited;
- a new attempt with worsening after-time evidence immediately fails the timing gate even when the corrective plan is valid;
- a later new attempt with improved timing can restore the candidate result;
- P1 evidence cannot satisfy P5;
- the automatic stage ceiling remains 3;
- feature state and entitlements remain off;
- rollback removes all synthetic approvals, registry rows, Paper-02 contract, synthetic learner and runtime evidence.

Final corrected P1 regression: workflow run `34012521669` — **SUCCESS**.

## 7. P5 symmetry matrix

A separate rollback-only P5 matrix proves the positive path is not accidentally P1-specific:

- P5 Stage-3 exit becomes eligible only from P5 evidence;
- one P5 full-paper baseline is insufficient for Stage-4 consolidation;
- P5 Paper 02 is temporarily represented only inside rollback with a Stage-4-only contract;
- two compatible P5 full-paper forms with improved completion still fail while a remaining non-key L2 skill has no current corrective plan;
- a current exact P5 corrective action can make the candidate result `ready`;
- that `ready` result still does not unlock Stage 4 or Stage 5;
- P5 evidence cannot satisfy P1;
- rollback restores Paper 02 to approved/unreleased and deletes all synthetic learner/runtime evidence.

P5 symmetry regression: workflow run `34012673804` — **SUCCESS**. The same run also passed the full existing P1-03 regression chain and the final zero-activation-residue check.

## 8. Production boundary verified after the regressions

A fresh read-only production snapshot after the final P5 run confirms:

- controlled-beta cohort remains `draft`, wave `0`, with 3 staged learners and **0 / 3 consent grants**;
- rollout remains `off`;
- Core, AI Assist and Mentor Care remain disabled;
- kill switch remains on;
- active Exam Prep entitlements = `0`;
- Exam Prep sessions = `0`;
- authoritative stage rows = `0`;
- timed attempt results = `0`;
- evidence events = `0`;
- automatic stage ceiling = `3`;
- Stage-3 key registry remains `pending` with `0` rows;
- Stage-4 policy remains `pending`;
- Paper-02 release remains `pending`;
- no production Stage-4 exit evaluator exists;
- P1 Paper 02 remains `approved` with `0` timed contracts;
- P5 Paper 02 remains `approved` with `0` timed contracts.

Therefore the candidate regressions provide technical evidence only. They do not constitute Stage-4 governance approval or learner activation.

## 9. Production boundary for future work

Until a later explicit governance release, production must remain:

- `key_registry_status='pending'` with 0 Stage-3 key rows;
- `stage4_policy_status='pending'`;
- `paper02_release_status='pending'`;
- no production Stage-4 exit evaluator;
- `max_automatic_stage=3`;
- Paper 02 assessments approved but unreleased and without timed contracts;
- controlled beta off, no active Exam Prep entitlements;
- AI Assist off;
- Mentor Care off.

A later production release must still be separately approved. Passing these candidate tests shows that the future rules are technically coherent; it is not permission to activate them.