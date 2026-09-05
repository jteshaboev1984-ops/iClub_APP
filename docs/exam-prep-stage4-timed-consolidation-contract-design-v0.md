# Exam Prep Stage-4 Timed Consolidation Contract Design v0

**Program:** `math_as_p1_p5`  
**Scope:** Cambridge AS Mathematics 9709 P1 + P5  
**Status:** **DESIGN ONLY — NO STAGE-4 UNLOCK / NO PRODUCTION DDL**  
**Date:** 2026-09-05  
**Current automatic stage ceiling:** `3`

## 1. Normative source law

The Master Implementation Plan v1.1 defines Stage 4, separately per component, as **Timed Consolidation**. Its exit gate is:

- at least **2 comparable full attempts** for the component;
- **timing/unattempted trend improving**;
- **all canonical skills at least L3, or an explicit corrective plan** for the remaining lower-level skills;
- strict timed analysis.

The annual roadmap places Stage 4 around AW25–28 and recommends a full paper roughly every two active weeks per component. That cadence is a planning rule, not a calendar promotion trigger. The roadmap checkpoint is P1 >=2 and P5 >=2 comparable attempts while retaining 100% coverage.

Stage 5 is separate and stricter: at least 3 comparable strict attempts plus last-three/readiness conditions. Stage 4 must not pre-implement or weaken Stage 5.

## 2. Entry and exit must remain separate

### Proposed Stage-4 entry dependency

A component may only become eligible for Stage 4 after the governed Stage-3 exit evaluator for that same component returns `ready=true`.

That already implies:

- 100% canonical coverage;
- every canonical skill >=L2;
- governance-approved key skills >=L3;
- at least one finally score-comparable official full-paper baseline;
- no unknown syllabus section.

This document does not approve the pending Stage-3 key-skill registry and therefore does not make any learner Stage-4 eligible today.

### Stage-4 exit evidence

Stage-4 exit is a later evidence decision. It cannot be inferred from Stage-4 entry, active week, paper count alone, syllabus coverage alone or a single aggregate percentage.

## 3. Existing production objects to reuse

No parallel `paper_attempts` table is needed. Current P1-03 objects already hold the required raw timed facts.

### Comparable full-paper facts

Reuse:

- `private.exam_prep_sessions`
  - user/program/component ownership;
  - assessment/version;
  - finalized status;
  - immutable `timing_contract` snapshot, including `paper_profile_version`, official marks/duration and component.
- `private.exam_prep_timed_attempt_results`
  - `attempt_kind`;
  - `timing_rule`;
  - `comparison_scope`;
  - exact-form `comparability_key`;
  - `strict_timing`;
  - available marks;
  - server elapsed seconds;
  - in-time / after-time marks;
  - unattempted items / marks;
  - timing comparability;
  - finalized timestamp.
- `private.exam_prep_timed_written_self_marks`
  - written marks after self-review.
- `private.exam_prep_timed_score_comparable_v1(session_id)`
  - final score-comparability truth after pending written review is closed.

A Stage-4 comparable attempt must continue to be component-owned and must not count `timed_section`, `modified_paper` or `diagnostic_full` as a comparable full-paper result.

## 4. Comparable family vs exact paper identity

Production verification found that current full-paper `comparability_key` values are **form-specific** (`p1-full-paper-01-v1`, `p5-full-paper-01-v1`). Therefore equality of `comparability_key` must **not** become the Stage-4 definition of comparability: otherwise two different original full-paper forms could never form the required comparable pair.

For Stage 4, two attempts belong to the same **comparison family** when their immutable snapshots agree on the academic/condition dimensions that make full-paper performance comparable, including:

- same `user_id`;
- same `program_version_id`;
- same `component_code`;
- compatible `paper_profile_version` / official syllabus profile;
- finalized `session_type='paper'`;
- `attempt_kind='full_paper'`;
- `timing_rule='official_full'`;
- `comparison_scope='full'`;
- `strict_timing=true`;
- same official marks/time contract for the component;
- final score-comparability helper returns true.

`comparability_key` remains useful as **exact form / contract identity**, duplicate/repeat analysis and audit metadata. Different exact keys may be members of the same Stage-4 comparison family when the immutable profile/condition dimensions above match.

A later implementation must also fail closed across a changed syllabus/profile family even when both attempts happen to be called full papers.

## 5. Timed trend facts that can already be computed

For each comparable full attempt, the server can deterministically expose:

- exact `comparability_key` / form identity;
- comparison-family identity derived from immutable snapshot fields;
- `marks_available`;
- finally reviewed in-time marks;
- finally reviewed after-time marks;
- `unattempted_marks`;
- `unattempted_items`;
- `server_elapsed_sec`;
- `time_limit_sec`;
- normalized unattempted-mark share;
- normalized in-time/after-time shares;
- chronological attempt order within the compatible family;
- delta versus the previous compatible full attempt.

These are facts. They are not yet a Stage-4 promotion predicate.

## 6. Governance gap A — “timing/unattempted trend improving”

The normative plan requires an improving timing/unattempted trend but does not define a numeric threshold or exact mathematical predicate.

Therefore v0 must **not** invent any of the following:

- a minimum score gain;
- a required percentage-point improvement;
- a maximum allowed unattempted-mark count;
- a fixed elapsed-time reduction;
- a rule that score improvement can compensate for worsening time completion;
- a predicted Cambridge grade threshold.

### Safe design response

A future evaluator may calculate a `timing_trend_facts` object, but until a versioned trend rule is approved it must return:

- `trend_policy_status='pending'`;
- `trend_gate_ready=false`.

The raw facts should include at least the latest two attempts from one compatible comparison family and their normalized deltas. This preserves enough evidence for governance without hiding a threshold in code.

## 7. Governance gap B — “all skills >=L3 or explicit corrective plan”

Current state engine already exposes per-skill `objective_level`, unresolved correction count and retest evidence. Current correction/planning objects already support explicit linkage:

- `exam_prep_correction_cases` is component/skill owned;
- `exam_prep_weekly_plan_items` can link a correction case and skill, with item types including `correction` and `retest`;
- `exam_prep_retest_events` links the correction case, skill and delayed retest state.

This is enough to avoid inventing a separate Stage-4 planner.

However, the Master Plan does not define which exact combination of those objects is sufficient to call a lower-than-L3 skill an **explicit corrective plan**.

### Safe design response

A future evaluator should expose, for every canonical skill below L3:

- skill code and current objective level;
- active correction-case id/status if present;
- linked pending/completed weekly-plan action if present;
- linked scheduled/authorized/completed retest if present;
- next due timestamp if present;
- `corrective_plan_qualified` only under a separately versioned qualification rule.

Until that rule is approved:

- `corrective_plan_policy_status='pending'`;
- any component containing a skill below L3 must remain fail closed for Stage-4 exit.

This is intentionally stricter than silently treating any open correction case as a valid plan.

## 8. Proposed read-only Stage-4 status shape

A later implementation can expose a service-role/private evaluator with a payload shaped conceptually as:

```text
{
  component_code,
  stage3_exit_ready,
  comparable_full_attempt_count_total,
  comparison_family_count,
  max_compatible_family_attempt_count,
  comparison_families,
  exact_form_keys,
  trend_family_key,
  timing_trend_facts: {
    attempt_1,
    attempt_2,
    unattempted_mark_share_delta,
    in_time_mark_share_delta,
    after_time_mark_share_delta,
    elapsed_share_delta
  },
  trend_policy_status,
  trend_gate_ready,
  canonical_skill_count,
  l3_or_higher_count,
  below_l3_count,
  below_l3_corrective_links,
  corrective_plan_policy_status,
  corrective_plan_gate_ready,
  stage4_exit_ready,
  reason_code,
  stage5_unlocked: false
}
```

This shape is descriptive only; no function or table is created by this design document.

## 9. Reason-code precedence for a future evaluator

Fail closed in this order:

1. `stage3_exit_incomplete`
2. `comparable_full_attempts_incomplete`
3. `trend_policy_pending`
4. `timing_unattempted_trend_incomplete`
5. `corrective_plan_policy_pending`
6. `l3_or_corrective_plan_incomplete`
7. `ready`

A Stage-4 evaluator returning `ready` must still set `stage5_unlocked=false`. Stage-5 progression is a separate release.

## 10. Future rollback-only test matrix

Before any production DDL, CI must prove at least:

### Component firewall

- P1 attempts never satisfy P5 count and vice versa;
- P1 skill/correction links never satisfy P5 corrective coverage and vice versa.

### Comparable attempts

- 0/1 compatible full attempts block;
- 2 different finally reviewed strict full-paper forms under the same immutable component/profile/condition family satisfy the count fact;
- different exact `comparability_key` values do **not** by themselves make two forms incomparable;
- a changed `paper_profile_version` / incompatible family does not merge into the prior family;
- modified paper does not count;
- timed section does not count;
- diagnostic full does not count;
- unresolved written self-review does not count.

### Trend

- raw normalized trend facts are reproducible from persisted results within one compatible family;
- no stage promotion occurs while trend policy is pending;
- no score-only shortcut exists.

### L3 / corrective plan

- all canonical skills >=L3 satisfies this branch without corrective exceptions;
- any <L3 skill is enumerated explicitly;
- a component remains blocked while corrective-plan qualification policy is pending;
- later approved qualification must require component/skill exact linkage and fresh action/retest evidence;
- stale/superseded/unrelated plans cannot satisfy the gate.

### Safety/residue

- `max_automatic_stage` remains 3 until a separate Stage-4 implementation release is explicitly approved;
- no beta consent/cohort/entitlement change;
- no AI/Mentor enablement;
- no legacy Tours/Practice/history mutation;
- no `public.questions` activation;
- zero synthetic residue after rollback test.

## 11. Implementation sequence after governance decisions

The earliest safe implementation sequence is:

1. approve/version the Stage-3 key-skill registry separately;
2. keep Stage 4 locked and verify Stage-3 evaluator against the approved registry;
3. approve a numeric/logical `timing_unattempted_trend` rule;
4. approve the minimum `explicit_corrective_plan` qualification rule;
5. implement a **read-only Stage-4 evidence evaluator first**, still with `max_automatic_stage=3`;
6. run the full P1-03 regression line plus the Stage-4 rollback matrix;
7. apply evaluator DDL only after GREEN and verify production fail-closed state;
8. only in a later release wire Stage 3 -> 4 operational promotion;
9. Stage 4 -> 5 remains a separate contract/release.

## 12. What this design deliberately does not do

It does not:

- approve the Stage-3 key-skill proposal;
- populate the Stage-3 key-skill registry;
- define an unsupported trend threshold;
- define an unsupported corrective-plan qualification shortcut;
- create Stage-4 tables/functions;
- raise `max_automatic_stage`;
- activate any learner or controlled-beta capability;
- alter AI Assist or Mentor Care;
- alter legacy state/history;
- change Vercel configuration.
