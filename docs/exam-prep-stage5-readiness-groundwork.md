# Exam Prep Stage-5 Exam Readiness Groundwork

**Program:** `math_as_p1_p5`  
**Scope:** Cambridge AS Mathematics 9709 P1 + P5  
**Status:** **GROUNDWORK ONLY — NO STAGE-5 POLICY / NO EXAM-READY CLAIM**  
**Date:** 2026-09-06

## 1. Existing governed law

The current stage catalog already states that Stage 5 — **Exam Readiness** — requires:

- at least **three comparable strict attempts**;
- a **last-three trend**;
- fundamentals / corrections closed;
- **minimal unattempted** work;
- App Readiness must remain distinct from Mentor-Verified readiness.

This is enough to define the evidence that must be collected, but it is **not enough to invent the final readiness threshold**.

## 2. What is now implemented safely

Production now contains the private raw reader:

`private.exam_prep_stage5_raw_readiness_v1(user_id, program_version_id, component_code)`

It is service-role only and does not expose a learner-facing readiness result.

For the requested component it records:

- whether a Stage-4 evaluator exists and its result, if one is later deployed;
- total comparable strict full-paper attempts;
- comparison-family count;
- the largest compatible family;
- the latest **three** attempts from that family in chronological order;
- each attempt's unattempted marks/share;
- each attempt's after-time marks/share;
- elapsed-time share;
- current L3 / below-L3 skill counts;
- unresolved correction-case count;
- unresolved correction-skill count.

The reader deliberately returns:

- `stage5_policy_status='not_deployed'`;
- `stage5_ready=false`;
- `stage5_unlocked=false`;
- `stage6_unlocked=false`.

No numeric readiness threshold is hidden inside the reader.

## 3. Facts we can already enforce without a new policy decision

These are structural facts, not discretionary cutoffs:

1. P1 and P5 evidence remain completely separate.
2. Only finalized, strict, official-full, timing-comparable and finally score-comparable full-paper attempts count.
3. Attempts must belong to one compatible timing/profile family before they can form a last-three sequence.
4. Completed attempt facts are immutable; historical performance cannot be edited to manufacture a trend.
5. Stage 5 cannot be reached before Stage 4 is genuinely complete.
6. Calendar time alone cannot create Exam Readiness.
7. Mentor Care is not required for deterministic Core/App Readiness.
8. Stage 6 remains separately gated.

## 4. Decisions that must NOT be invented in code

### A. Meaning of “last-three trend”

The source law requires a last-three trend, but it does not specify the exact predicate.

Still undecided:

- must all three attempts improve monotonically;
- may one flat attempt be acceptable;
- should the comparison use first→third, attempt-to-attempt movement, or both;
- should the trend be based only on completion/time deficits, or also marks;
- how much deterioration, if any, is tolerable.

Until approved, the raw reader reports the three attempts but does not grade the trend.

### B. Meaning of “minimal unattempted”

The source plan contains no numeric maximum.

Therefore there is currently **no approved value** such as 0%, 2%, 5%, one question, or a marks-based cap.

`minimal_unattempted_threshold_status='not_defined_in_source_plan'` is intentional.

### C. Meaning of “fundamentals closed”

The current architecture has canonical skills, Stage-3 key skills, prerequisite nodes, objective levels and correction cases, but the source does not explicitly say which of those constitutes the Stage-5 “fundamentals” set.

The Stage-3 key-skill registry itself is still governance-pending, so it cannot silently become the Stage-5 fundamentals registry.

### D. Meaning of “corrections closed”

The reader reports active correction facts, but the final rule still needs an explicit policy decision on whether Stage 5 requires:

- zero unresolved correction cases of any kind;
- zero unresolved cases only for governed fundamental/key skills;
- or another documented closure rule.

### E. Paper-form diversity

The source says three comparable strict attempts, but does not require three distinct paper forms.

A distinct-form minimum must not be invented unless explicitly approved.

### F. Recency window

No source rule currently says that the three attempts must fall within a fixed number of days or weeks.

No arbitrary recency window is introduced.

## 5. Correct release order

The safe sequence remains:

1. obtain real learner consent and start the controlled Core beta;
2. collect real diagnostic → correction → delayed-retest → timed/full-paper evidence;
3. approve the Stage-3 key-skill registry;
4. approve and deploy Stage-4 progression/exit policy;
5. use actual beta evidence to resolve the Stage-5 policy decisions above;
6. version and test the final Stage-5 policy;
7. only then allow an App Readiness claim;
8. keep Mentor-Verified readiness as a separate optional human-verification layer.

## 6. Current production boundary

As of this groundwork release:

- Stage-5 raw evidence reader: **deployed**;
- Stage-5 readiness policy: **not deployed**;
- Stage-4 evaluator: **not deployed**;
- Stage-4 policy: **pending**;
- Stage-3 key registry: **pending / 0 rows**;
- automatic stage ceiling: **3**;
- controlled beta: **off**;
- active Exam Prep entitlements: **0**;
- learner sessions/timed results/stage rows: **0**.

Therefore no learner can currently be labelled Stage 5 / Exam Ready, and no such claim is made by this groundwork.