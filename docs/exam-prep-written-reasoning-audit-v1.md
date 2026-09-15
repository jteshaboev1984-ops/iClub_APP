# Exam Prep Written Reasoning Audit v1

Status: implementation input for the live Cambridge AS Mathematics P1+P5 Exam Prep module.

Baseline SHA: `88d476a9706c84bb69b45d8c15a9b1aa4851f25b`.

## Safety boundary

- Existing written task prompts, rubrics and learner responses are historical records and are not rewritten in place.
- P1 and P5 evidence remain separate.
- Free written reasoning remains `self_reviewed` unless an authorised mentor verifies it.
- AI does not mark the written response and cannot raise mastery.
- Any deterministic companion check introduced by this work is app-checked support evidence only in v1. It must not silently convert the whole written task into an app-verified written answer.
- Protected timed/paper sessions must not expose correct companion-check answers before feedback is allowed.

## Current production finding

The live bank contains 152 published written tasks. A conservative union scan of task prompts and rubric criteria identified 67 tasks that contain an explanation, justification, interpretation, proof, modelling reason, communication reason, or equivalent method statement that should not be treated as plain unverified free text only.

- P1: 30 tasks
- P5: 37 tasks

Current live written-response history is very small but already real: `P1CIR01-W01` has three non-synthetic written responses. Therefore its existing task row/rubric must remain immutable. The companion mechanism is additive.

## Treatment model

Every listed task keeps the original written response. The companion layer checks only a narrow deterministic idea that can be objectively established, for example a conversion identity, condition, model assumption, sign rule, probability identity, or interpretation distinction.

The written answer still captures mathematical communication, proof structure, graph/diagram quality, contextual explanation, or examiner-style working. Those claims remain self-reviewed or mentor-verified according to the existing authority model.

### Group A — deterministic rule/reason

These are the strongest candidates for one or more structured machine-checkable companion steps. The app can validate a precise rule/condition/result without pretending to grade the complete written explanation.

**P1 (16)**

- `P1CIR01-W01` [P1-CIR-01]
- `P1FP02-Q03` [P1-COO-06]
- `P1TB01-Q01` [P1-COO-06]
- `P1TB01-Q03` [P1-DIF-07]
- `P1FUN01-W01` [P1-FUN-01]
- `P1FUN02-W01` [P1-FUN-02]
- `P1FUN03-W01` [P1-FUN-03]
- `P1FP01-Q02` [P1-FUN-04]
- `P1INT03-W01` [P1-INT-03]
- `P1INT04-W01` [P1-INT-04]
- `P1QUA02-W01` [P1-QUA-02]
- `P1QUA04-W01` [P1-QUA-04]
- `P1SER01-W01` [P1-SER-01]
- `P1SER02-W01` [P1-SER-02]
- `P1SER05-W01` [P1-SER-05]
- `P1TB02-Q02` [P1-SER-05]

**P5 (23)**

- `P5BIN02-W01` [P5-BIN-02]
- `P5FP03-Q04` [P5-BIN-02]
- `P5BIN03-W01` [P5-BIN-03]
- `P5CNT01-W01` [P5-CNT-01]
- `P5CNT02-W01` [P5-CNT-02]
- `P5CNT03-W01` [P5-CNT-03]
- `P5CNT04-W01` [P5-CNT-04]
- `P5CNT05-W01` [P5-CNT-05]
- `P5DAT07-W01` [P5-DAT-07]
- `P5DRV01-W01` [P5-DRV-01]
- `P5DRV03-W01` [P5-DRV-03]
- `P5FP02-Q06` [P5-GEO-02]
- `P5FP03-Q05` [P5-GEO-02]
- `P5GEO02-W01` [P5-GEO-02]
- `P5FP01-Q06` [P5-GEO-03]
- `P5MM01-Q04` [P5-NOR-06]
- `P5NOR06-W01` [P5-NOR-06]
- `P5PRO01-W01` [P5-PRO-01]
- `P5PRO02-W01` [P5-PRO-02]
- `P5PRO04-W01` [P5-PRO-04]
- `P5FP03-Q03` [P5-PRO-05]
- `P5MM01-Q02` [P5-PRO-05]
- `P5PRO05-W01` [P5-PRO-05]

### Group B — interpretation/context

A deterministic companion check can verify the core distinction or interpretation, but the learner's own wording still matters and remains written evidence.

**P1 (6)**

- `P1CIR02-W01` [P1-CIR-02]
- `P1COO06-W01` [P1-COO-06]
- `P1DIF01-W01` [P1-DIF-01]
- `P1FP01-Q08` [P1-DIF-06]
- `P1TRI02-W01` [P1-TRI-02]
- `P1TRI03-W01` [P1-TRI-03]

**P5 (5)**

- `P5DAT01-W01` [P5-DAT-01]
- `P5DAT06-W01` [P5-DAT-06]
- `P5DAT08-W01` [P5-DAT-08]
- `P5DRV02-W01` [P5-DRV-02]
- `P5GEO03-W01` [P5-GEO-03]

### Group C — written/visual method remains authoritative

These tasks contain proof, graph/diagram/tree/sign-chart or other method quality that cannot be honestly reduced to a multiple-choice result. A companion check may validate a prerequisite principle, but it must never replace review of the written/visual artefact.

**P1 (8)**

- `P1COO03-W01` [P1-COO-03]
- `P1DIF05-W01` [P1-DIF-05]
- `P1DIF07-W01` [P1-DIF-07]
- `P1FUN05-W01` [P1-FUN-05]
- `P1FUN06-W01` [P1-FUN-06]
- `P1FUN07-W01` [P1-FUN-07]
- `P1FUN08-W01` [P1-FUN-08]
- `P1TRI04-W01` [P1-TRI-04]

**P5 (9)**

- `P5BIN01-W01` [P5-BIN-01]
- `P5DAT04-W01` [P5-DAT-04]
- `P5DAT05-W01` [P5-DAT-05]
- `P5GEO01-W01` [P5-GEO-01]
- `P5NOR01-W01` [P5-NOR-01]
- `P5FP01-Q03` [P5-PRO-05]
- `P5FP02-Q03` [P5-PRO-06]
- `P5PRO06-W01` [P5-PRO-06]
- `P5TB02-Q02` [P5-PRO-06]

## First concrete companion contract: P1CIR01-W01

The existing learner-facing written task is retained unchanged.

Companion check 1 verifies the reference identity: `180° = π rad`.

Companion check 2 verifies the reciprocal product: `(π/180) × (180/π) = 1`.

Companion check 3 verifies the meaning: converting degrees to radians and then converting back restores the original numerical angle measure in the original unit.

The learner then still writes the explanation in their own words. A response such as “the factors cancel to 1, so applying the second conversion reverses the first” is mathematically sufficient; “because they are flipped” is not enough as written reasoning.

## v1 acceptance rules

1. Companion answers are evaluated server-side. Correct indices/rationales never appear in the active browser payload.
2. The result is stored as non-crediting app-checked metadata attached to the written response. Existing `written/self_reviewed` evidence remains unchanged in authority.
3. The written text is still required.
4. Missing companion metadata preserves the current behaviour exactly.
5. Existing sessions and responses remain readable; no migration rewrites learner artefacts.
6. Timed/paper feedback follows the existing active-assessment feedback guard.
7. RU/UZ/EN are mandatory for every published companion check.
8. A later version may promote specific objective checks to credit only after explicit evidence-contract review; v1 does not do this.

## Rollout order

1. Add the private companion-check contract and safe server evaluation with no behaviour change for tasks that have no companion rows.
2. Seed `P1CIR01-W01` as the regression/reference case.
3. Run DB/security/frontend regressions and prove old written-response history is unchanged.
4. Expand Group A in small governed batches, then Group B, then Group C prerequisite checks.
5. Re-audit all 67 tasks after the final batch; written/mentor authority remains unchanged throughout.
