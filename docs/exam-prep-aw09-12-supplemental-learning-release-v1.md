# Exam Prep AW9–12 supplemental learning release v1

Date: 2026-09-30  
Versions: P1 `4809`, P5 `4810`  
Release mode: `supplemental_learning`

## Decision

The independently reviewed AW9–12 supplemental-learning packs are eligible for governed publication after all CI gates pass.

This release adds a second governed learning pack for 14 canonical skills. It does not alter existing learner evidence or legacy Practice/Tours data.

## Release surface

- P1: 8 skills, 24 machine learning items, 8 written tasks, 8 understanding checks.
- P5: 6 skills, 18 machine learning items, 6 written tasks, 6 understanding checks.
- Total: 42 machine learning items, 14 written tasks, 14 understanding checks.
- 14 learning assessment containers, each exactly 3 machine items + 1 written task.

The public source-question rows remain inactive/draft. Governed private learning metadata becomes published/released only through the supplemental-learning release path.

## Independent QA carried forward

The release is pinned to the independent second-pass correction set:

- 18 machine surfaces were strengthened or corrected;
- direct number-swaps and near-duplicates of published evidence were replaced where they weakened learning diversity;
- one probability answer leak was removed;
- one inverse-function explanation was corrected to avoid an overbroad general claim;
- learner-facing assessment titles were changed from internal release terminology to natural “additional practice” wording in EN/RU/UZ;
- frozen source snapshots were refreshed only for corrected draft rows.

## Safety invariants

Publication fails closed unless:

1. versions 4809/4810 are the exact draft targets;
2. all 42 machine rows are draft/withheld and history-free before release;
3. all 14 written tasks and 14 understanding checks are draft and complete;
4. all 14 assessments have exact 3-machine + 1-written shape;
5. all source questions remain inactive/draft with exact frozen snapshots;
6. the independent-QA answer map and learner-facing title cleanup are present;
7. every target skill already has a separate governed baseline;
8. the supplemental-learning floor is green for each component;
9. no learner session, Practice or Tour history references the target versions;
10. controlled beta remains active with AI Assist and Mentor Care OFF.

## Rollback

The release contract rehearses future-selection retirement in a transaction without deleting content or rewriting evidence. It then rolls back and requires the governed published state to be restored exactly.

## Non-goals

This release does not expand the beta cohort, enable AI Assist, enable Mentor Care, alter localStorage, change legacy ratings/certificates, or claim learner exam readiness.
