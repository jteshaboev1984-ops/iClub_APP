# Exam Prep Stage-3 Key-Skill Governance Decision Pack

**Program:** `math_as_p1_p5`  
**Scope:** Cambridge AS Mathematics 9709 P1 + P5  
**Status:** **DECISION SUPPORT ONLY — NO KEY SKILLS APPROVED**  
**Production registry:** `pending / 0 rows`  
**Automatic stage ceiling:** `3`  
**Stage 4:** **LOCKED**

## 1. Why this decision pack exists

The Stage-3 Syllabus Closure exit law is already machine-readable and production-deployed. A learner may exit Stage 3 only when, independently for a component:

- canonical syllabus coverage is 100%;
- every canonical skill is at least L2;
- the governed **key skills** are at least L3;
- at least one official full-paper attempt is finally score-comparable after written self-review;
- there is no unknown syllabus section.

The source plans specify the **key-skills ≥ L3** requirement but do not enumerate the canonical skill codes that form the key-skill set. Existing `skill_contracts` also do not provide a safe one-to-one surrogate for “key”.

Therefore production intentionally remains fail closed:

- active Stage-3 exit rule: `stage3_exit_v1_2026_09_05`;
- `key_registry_status='pending'`;
- `private.exam_prep_stage3_key_skills` contains 0 governed rows;
- `max_automatic_stage=3`;
- evaluator reason for both components is currently `key_registry_pending`.

This document defines how the missing governance decision must be made without hiding a product-policy choice inside code.

## 2. Non-negotiable rules

These are release invariants, not decision options.

1. **Component firewall.** P1 codes may only govern P1; P5 codes may only govern P5.
2. **Canonical-only.** Every selected code must already exist in `private.exam_prep_syllabus_nodes` for the active canonical program version.
3. **No inferred registry.** A contract profile, prerequisite count, full-paper appearance or content density may be a candidate signal but may not silently become the registry rule.
4. **Explicit basis per skill.** Every selected code must have a human-readable `governance_basis` stating why that exact skill deserves the stronger L3 closure requirement.
5. **No Stage-4 change in the registry decision.** Approving key codes and wiring Stage 4 are separate releases. Registry approval alone must not increase `max_automatic_stage` above 3.
6. **No learner activation side effect.** Registry work must not create entitlements, sessions, evidence, consent, cohort approval or feature activation.
7. **No denominator change.** P1 remains 45 canonical skills; P5 remains 36; total remains 81.
8. **No legacy mutation.** Tours, Practice, history, ratings, certificates and legacy active-question state are out of scope.

## 3. Candidate evidence signals available today

The following signals already exist in the governed schema and may be reviewed together. None is authoritative by itself.

| Signal | What it can tell reviewers | Why it cannot decide alone |
|---|---|---|
| `requires_mixed_for_l3=true` | the skill contract already requires mixed evidence for L3 | only one contract profile uses this flag; the source plan does not say all and only such skills are “key” |
| direct downstream prerequisite count | how many later canonical skills directly depend on the skill | foundational skills can be highly connected without being the intended Stage-3 key set |
| `contract_profile='model_selection'` | learner must choose/recognise the correct model rather than only execute a routine | model-selection is a contract category, not a documented synonym for “key skill” |
| `contract_profile='graph_construction'` | graph production/interpretation is central | graph skills should not automatically dominate the registry |
| `contract_profile='context_reasoning'` | contextual reasoning/interpretation matters | the plans do not define key skills by profile label |
| appearance in governed full paper | the skill is sampled in the first comparable paper design | one paper is a sampling instrument, not the whole syllabus law |
| official syllabus section | supports breadth review across the component | the plans do not state one-key-skill-per-section or another section quota |
| learner evidence after beta starts | shows actual error persistence / transfer weakness | no live learner evidence exists yet and it must not be fabricated |

### Current read-only signal observations

A read-only production query on 2026-09-05 showed examples of high dependency centrality and/or mixed-L3 contracts. These rows are **candidates for review, not approvals**.

#### P1 — strong current signals

| Skill | Section | Contract profile | `mixed_for_l3` | Direct downstream dependencies |
|---|---|---|---:|---:|
| `P1-FUN-01` | 1.2 Functions | model_selection | yes | 6 |
| `P1-DIF-02` | 1.7 Differentiation | routine_transfer | no | 5 |
| `P1-QUA-03` | 1.1 Quadratics | routine_transfer | no | 5 |
| `P1-CIR-01` | 1.4 Circular measure | routine_transfer | no | 4 |
| `P1-COO-01` | 1.3 Coordinate geometry | routine_transfer | no | 4 |
| `P1-SER-02` | 1.6 Series | model_selection | yes | 2 |
| `P1-DIF-01` | 1.7 Differentiation | model_selection | yes | 1 |
| `P1-TRI-03` | 1.5 Trigonometry | model_selection | yes | 1 |
| `P1-QUA-06` | 1.1 Quadratics | model_selection | yes | 0 |

Other P1 skills with direct downstream count ≥2 include `P1-QUA-01`, `P1-CIR-02`, `P1-COO-02`, `P1-COO-03`, `P1-DIF-03`, `P1-FUN-06`, `P1-INT-01`, `P1-INT-03`, `P1-QUA-04`, `P1-TRI-01`, and `P1-TRI-02`.

#### P5 — strong current signals

| Skill | Section | Contract profile | `mixed_for_l3` | Direct downstream dependencies |
|---|---|---|---:|---:|
| `P5-PRO-03` | 5.3 Probability | routine_transfer | no | 5 |
| `P5-DAT-06` | 5.1 Representation of data | routine_transfer | no | 4 |
| `P5-PRO-04` | 5.3 Probability | context_reasoning | no | 4 |
| `P5-DAT-07` | 5.1 Representation of data | routine_transfer | no | 3 |
| `P5-DRV-01` | 5.4 Discrete random variables | context_reasoning | no | 3 |
| `P5-DRV-02` | 5.4 Discrete random variables | routine_transfer | no | 3 |
| `P5-BIN-01` | 5.4 Discrete random variables | model_selection | yes | 2 |
| `P5-CNT-01` | 5.2 Permutations and combinations | model_selection | yes | 2 |
| `P5-GEO-01` | 5.4 Discrete random variables | model_selection | yes | 2 |
| `P5-PRO-01` | 5.3 Probability | model_selection | yes | 2 |
| `P5-NOR-01` | 5.5 Normal distribution | model_selection | yes | 1 |

Other P5 skills with direct downstream count ≥2 include `P5-CNT-02`, `P5-CNT-05`, `P5-DAT-05`, and `P5-NOR-02`.

Again: these tables are **not** the production registry and must never be copied wholesale into it without an explicit governance decision.

## 4. Required governance questions before any code is selected

The approving reviewer(s) must answer these questions explicitly:

1. What does “key” mean for this product: prerequisite centrality, model-selection/transfer risk, exam-method importance, graph/method dependence, repeated learner failure risk, or a documented combination?
2. Is the key set intended to be **minimal** (only bottleneck skills) or **representative** (a broader set across syllabus sections)?
3. Must each official syllabus section be represented, or is section coverage irrelevant to the key registry? The current source plans do not answer this.
4. Should the initial registry be fixed before live learner evidence, or should a small provisional registry be reviewed after the first controlled-beta evidence window?
5. How should a key skill be removed or replaced later without invalidating historical learner Stage-3 decisions?
6. Who is the accountable approver for the registry version and its future revisions?

Until these questions are resolved, `key_registry_status` must remain `pending`.

## 5. Approval worksheet — intentionally blank

No skill is approved by this document. Fill this table only through the explicit governance decision.

### P1 approved key skills

| Skill code | Governance basis | Evidence signals considered | Approver | Decision date |
|---|---|---|---|---|
| _TBD_ | _TBD_ | _TBD_ | _TBD_ | _TBD_ |

### P5 approved key skills

| Skill code | Governance basis | Evidence signals considered | Approver | Decision date |
|---|---|---|---|---|
| _TBD_ | _TBD_ | _TBD_ | _TBD_ | _TBD_ |

## 6. Read-only candidate-analysis query

This query may be rerun before the decision. It does not mutate the registry or stage state.

```sql
with nodes as (
  select
    n.program_version_id,
    n.component_code,
    n.skill_code,
    n.official_syllabus_section,
    n.canonical_description,
    n.prerequisites_text,
    c.contract_profile,
    c.requires_written_for_l2,
    c.requires_transfer_for_l3,
    c.requires_mixed_for_l3,
    c.requires_retest_for_l3
  from private.exam_prep_syllabus_nodes n
  join private.exam_prep_skill_contracts c
    on c.program_version_id=n.program_version_id
   and c.skill_code=n.skill_code
  where n.program_version_id=(
    select id
    from private.exam_prep_program_versions
    where program_key='math_as_p1_p5'
      and version_key='p1_p5_canonical_v1_0'
      and status='active'
  )
), downstream as (
  select
    n.component_code,
    n.skill_code,
    count(*) filter (
      where d.prerequisites_text like '%'||n.skill_code||'%'
    ) as direct_downstream
  from nodes n
  cross join nodes d
  where d.component_code=n.component_code
  group by n.component_code,n.skill_code
)
select
  n.component_code,
  n.skill_code,
  n.official_syllabus_section,
  n.contract_profile,
  n.requires_mixed_for_l3,
  d.direct_downstream,
  n.canonical_description
from nodes n
join downstream d using(component_code,skill_code)
order by
  n.component_code,
  n.requires_mixed_for_l3 desc,
  d.direct_downstream desc,
  n.skill_code;
```

## 7. Release protocol after governance approval

Registry approval must be implemented as a separate governed release, not as an ad-hoc SQL edit.

Required sequence:

1. Record the approved P1/P5 codes and a non-empty `governance_basis` for every row.
2. Create one versioned migration that inserts only those canonical rows into `private.exam_prep_stage3_key_skills`.
3. In the same migration, change `key_registry_status` from `pending` to `approved` only after validating the exact expected registry rows.
4. Keep `max_automatic_stage=3` unchanged.
5. Extend the rollback-only P1-03 matrix to prove:
   - exact registry membership;
   - P1/P5 component firewall;
   - non-key L2 + all key L3 is accepted by the evaluator;
   - any selected key falling to L2 returns `key_l3_incomplete`;
   - missing coverage or any canonical L2 failure still blocks closure;
   - missing comparable full-paper baseline still blocks closure;
   - `stage4_unlocked=false` remains true even when evaluator `ready=true`.
6. Run the complete P1-03 CI line before production apply.
7. Apply exact migration to production only after GREEN.
8. Re-run security/performance advisors and the production fail-closed snapshot.
9. Only in a later, separately designed release may Stage-4 progression consume a governance-approved Stage-3 exit result.

## 8. What this pack deliberately does not decide

This document does **not**:

- select any key skill code;
- change `key_registry_status`;
- populate `private.exam_prep_stage3_key_skills`;
- raise the automatic stage ceiling above 3;
- define unsupported numeric Stage-4 improvement thresholds;
- approve or activate the controlled beta;
- grant learner consent or entitlements;
- activate AI Assist or Mentor Care;
- alter legacy Tours/Practice/history;
- change Vercel configuration.

The next production-changing step is therefore **blocked on an explicit governance decision, not on missing engineering infrastructure**.
