# Exam Prep Stage-3 Key-Skill Registry Proposal v0

**Program:** `math_as_p1_p5`  
**Scope:** Cambridge AS Mathematics 9709 P1 + P5  
**Status:** **PROPOSAL ONLY — NOT APPROVED / NOT PRODUCTION REGISTRY**  
**Proposal key:** `stage3_key_skill_proposal_v0_2026_09_05`  
**Production registry remains:** `pending / 0 rows`  
**Automatic stage ceiling remains:** `3`

## 1. Purpose

This document turns the Stage-3 key-skill governance blocker into a concrete, reviewable proposal without changing product policy in production.

The proposal follows a **balanced bottleneck** principle:

- every official P1/P5 syllabus section is represented;
- selected skills should test transfer, model choice, integrated method or interpretation rather than only routine execution;
- dependency centrality and first-full-paper presence are supporting signals, not automatic selectors;
- a skill with a high mechanical score is not selected if a stronger L3 transfer bottleneck exists in the same section;
- P5 section 5.4 is treated as three model families: general discrete random variables, Binomial and Geometric.

This proposal is deliberately not written to `private.exam_prep_stage3_key_skills`.

## 2. Proposed P1 key skills — 8

| Section | Skill | Why it is proposed for L3 closure | Supporting signals |
|---|---|---|---|
| 1.1 Quadratics | `P1-QUA-03` | Choosing and executing the appropriate quadratic-solving method is a foundational transfer bottleneck used by later algebraic work. | 5 direct downstream dependencies |
| 1.2 Functions | `P1-FUN-01` | Function/domain/range/one-one/inverse/composition language is the central model-selection layer for the whole Functions section. | `model_selection`, mixed evidence required for L3, 6 downstream |
| 1.3 Coordinate geometry | `P1-COO-05` | Line-circle problems require algebra/geometry integration rather than a single routine. | `context_reasoning`, sampled in first full paper |
| 1.4 Circular measure | `P1-CIR-03` | Composite sector/segment problems require correct model construction and multi-step transfer. | `context_reasoning`, sampled in first full paper |
| 1.5 Trigonometry | `P1-TRI-05` | Solving trig equations on a stated interval tests solution structure and avoidance of lost/extraneous solutions. | `context_reasoning`, sampled in first full paper |
| 1.6 Series | `P1-SER-02` | Correctly recognising arithmetic vs geometric structure is the model-choice bottleneck before formula execution. | `model_selection`, mixed evidence required for L3, 2 downstream |
| 1.7 Differentiation | `P1-DIF-07` | Stationary points/nature/sketch/optimisation combine derivative execution with interpretation and decision-making. | `context_reasoning`, sampled in first full paper |
| 1.8 Integration | `P1-INT-04` | Area between curves/axes/lines requires region interpretation, limits and decomposition rather than routine antiderivatives alone. | `context_reasoning`, sampled in first full paper |

## 3. Proposed P5 key skills — 7

| Section | Skill | Why it is proposed for L3 closure | Supporting signals |
|---|---|---|---|
| 5.1 Representation of data | `P5-DAT-08` | Comparing datasets by location/spread and producing a contextual conclusion is the section's strongest interpretation/transfer bottleneck. | `context_reasoning` |
| 5.2 Permutations and combinations | `P5-CNT-05` | Mixed selection-arrangement problems require choosing and combining counting models correctly. | `context_reasoning`, sampled in first full paper, 2 downstream |
| 5.3 Probability | `P5-PRO-05` | Conditional probability is an important model/interpretation bottleneck and interacts with sequential probability reasoning. | `context_reasoning`, sampled in first full paper |
| 5.4 Discrete random variables | `P5-DRV-01` | Validating/building a discrete distribution tests probability structure before expectation/variance routines. | `context_reasoning`, 3 downstream |
| 5.4 Discrete random variables | `P5-BIN-01` | Recognising when Binomial assumptions hold is a model-selection requirement, not just formula substitution. | `model_selection`, mixed evidence required for L3, 2 downstream |
| 5.4 Discrete random variables | `P5-GEO-01` | Recognising first-success/Geometric structure and assumptions is a separate model-selection bottleneck from Binomial. | `model_selection`, mixed evidence required for L3, 2 downstream |
| 5.5 The normal distribution | `P5-NOR-06` | Normal approximation to Binomial combines approximation conditions, parameter conversion and continuity correction. | `context_reasoning`, sampled in first full paper |

## 4. Why this is not simply the highest-score-per-section list

A read-only composite signal check used mixed-L3, dependency count, contract profile and first-full-paper presence. It was useful for surfacing candidates but produced several examples where mechanical rank and desired Stage-3 L3 transfer bottleneck diverged:

- `P1-QUA-06` scores strongly because it is `model_selection + mixed_for_l3`, but `P1-QUA-03` is much more dependency-central and governs the general quadratic-solving choice used later;
- `P5-DAT-06` has high dependency centrality, but mean/median/mode calculation is less suitable as the sole L3 closure bottleneck than `P5-DAT-08` contextual comparison;
- `P5-NOR-01` is strong model recognition, but `P5-NOR-06` requires the broader transfer chain of checking approximation conditions and applying continuity correction.

Therefore the proposal uses score data as evidence, not authority.

## 5. Proposal invariants

The accompanying rollback-only CI matrix must prove all of the following:

1. exactly 8 proposed P1 codes and 7 proposed P5 codes;
2. all 15 codes exist in the active canonical 81-skill map;
3. component firewall is exact;
4. all 8 P1 official sections and all 5 P5 official sections are represented;
5. P5 section 5.4 contains the three explicit model-family bottlenecks `DRV-01`, `BIN-01`, `GEO-01`;
6. every proposed skill has at least one defensible governed signal: mixed-L3 contract, transfer/model/context profile, dependency centrality or first-full-paper presence;
7. production-like registry state remains `pending` and contains zero rows;
8. `max_automatic_stage` remains 3;
9. feature state remains fail closed and no learner/runtime residue is created.

## 6. Governance status

This proposal does **not** resolve the human/product governance decision by itself. It is intended to make that decision small and explicit.

Possible outcomes later:

- approve the proposal unchanged;
- replace individual codes with documented rationale;
- add/remove codes while preserving component/section logic;
- defer approval until the first controlled-beta learner evidence window.

Until one of those outcomes is explicitly approved, production must remain:

- `key_registry_status='pending'`;
- `private.exam_prep_stage3_key_skills = 0 rows`;
- `max_automatic_stage=3`;
- Stage 4 locked.
