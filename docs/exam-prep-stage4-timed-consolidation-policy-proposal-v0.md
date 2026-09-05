# Exam Prep Stage-4 Timed Consolidation Policy Proposal v0

**Program:** `math_as_p1_p5`  
**Scope:** Cambridge AS Mathematics 9709 P1 + P5  
**Status:** **REVIEW-ONLY PROPOSAL — NOT AUTHORITATIVE / NO PRODUCTION UNLOCK**  
**Date:** 2026-09-05  
**Automatic stage ceiling while this proposal is unapproved:** `3`

## 1. Purpose

The Master Implementation Plan requires Stage-4 Timed Consolidation to use, separately by component:

- at least 2 comparable full-paper attempts;
- improving timing / unattempted trend;
- all canonical skills at least L3, or an explicit corrective plan for each remaining lower-level skill.

The source plan does not define a numeric timing-trend threshold and does not define the minimum object graph that qualifies as an explicit corrective plan. This document proposes a conservative deterministic v0 rule for review and rollback-only testing. It does **not** approve or deploy either rule.

## 2. Comparison family

Two full-paper attempts may belong to the same comparison family when the immutable session timing/profile snapshot matches on:

- `program_version_id`;
- `component_code`;
- `paper_profile_version`;
- `attempt_kind='full_paper'`;
- `timing_rule='official_full'`;
- `comparison_scope='full'`;
- `strict_timing=true`;
- official marks available;
- official time limit.

`comparability_key` is treated as exact form/contract identity, not as the Stage-4 family identity. Different original forms under the same Cambridge profile can therefore be comparable; a changed paper profile/version cannot be silently merged.

Only finally score-comparable attempts after written self-review may enter the family.

## 3. Proposed trend rule v0

### 3.1 Facts

For the latest two finally comparable attempts in one compatible family define:

- `U = unattempted_marks / marks_available`;
- `A = after_time_attempted_marks / marks_available`.

For current P1-03 result rows:

`after_time_attempted_marks = objective_marks_after_time + objective_lost_after_time_marks + pending_review_after_time_marks`.

This is a timing-pressure fact, not a score. Correctness must not compensate for completing more work after the official deadline.

`server_elapsed_sec / time_limit_sec` remains reportable evidence but is **not** a promotion predicate: legitimately using the full official duration is not itself a timing failure.

### 3.2 Proposed predicate

`trend_gate_ready_v0 = true` only when:

1. latest `U <= previous U`;
2. latest `A <= previous A`;
3. and at least one of the following is true:
   - latest `U < previous U`;
   - latest `A < previous A`;
   - latest `U = 0` and latest `A = 0`.

Consequences:

- improvement in one timing dimension cannot compensate for worsening the other;
- a flat positive timing deficit does not count as improvement;
- once both timing deficits are zero, maintaining zero remains acceptable;
- aggregate paper score is deliberately absent from this predicate;
- no arbitrary percentage-point threshold is invented.

This rule is intentionally conservative and uses only the direction of timing evidence required by the source plan.

## 4. Proposed explicit corrective-plan rule v0

For one canonical skill currently below L3, `corrective_plan_qualified_v0 = true` only when an exact active correction case exists for the same:

- learner;
- component;
- skill.

The correction case status must be one of:

- `open`;
- `remediating`;
- `retest_due`;
- `reopened`.

In addition, at least one concrete next action must exist through one of the existing governed paths.

### Path A — active weekly plan

All must match exactly:

- active weekly plan belongs to the same learner and component;
- pending plan item is `correction` or `retest`;
- item references the same `correction_case_id`;
- item references the same `skill_code`;
- `due_at` is not null.

### Path B — scheduled/authorized retest

All must match exactly:

- same correction case;
- same learner;
- same component;
- same skill;
- retest status is `scheduled` or `authorized`;
- `due_not_before` is not null.

An open case alone is insufficient. A plan/retest for another component, another skill or another case is insufficient. A completed plan item with no next action is insufficient.

The proposal intentionally introduces no arbitrary freshness window. Overdue state should remain visible as a separate operational signal rather than being hidden inside the definition of “explicit plan”.

## 5. Proposed Stage-4 exit composition

Even if this proposal is later approved, Stage-4 exit would still require all of the following for the same component:

1. Stage-3 exit already complete;
2. at least 2 finally comparable full attempts in one compatible comparison family;
3. proposed trend predicate passes on the latest two attempts in that family;
4. every canonical skill is either at least L3 or has a qualifying explicit corrective plan under the approved rule;
5. component firewall holds;
6. Stage-5 remains separately locked.

This document does not change Stage-3 entry/exit, the pending Stage-3 key-skill registry, or the Stage-5 contract.

## 6. Rollback-only validation requirements

CI must prove at minimum:

### Trend truth table

- both timing dimensions improve -> pass;
- one improves while the other worsens -> fail;
- both remain positive and unchanged -> fail;
- both are already zero and remain zero -> pass;
- null/out-of-range shares -> fail closed.

### Corrective plan

- no correction case -> fail;
- exact active correction case alone -> fail;
- exact active case + exact pending active-plan action with due date -> pass;
- another skill/component must not pass;
- exact active case + exact scheduled retest with due date -> pass.

### Safety

- proposal creates no production policy row;
- no Stage-4 production evaluator or unlock is created;
- `max_automatic_stage` remains 3;
- no cohort, consent, entitlement, learner-session or evidence state is changed after rollback;
- AI Assist / Mentor Care remain untouched;
- no legacy state or `public.questions` activation.

## 7. Approval boundary

A future governance decision may approve, modify or reject this proposal. Only after explicit approval should the rules become versioned production policy rows and a read-only Stage-4 evaluator be deployed. Stage 3 -> 4 operational promotion remains a later, separate release even after evaluator deployment.
