# Exam Prep AW5–8 governed annual reserve release v1

Date: 2026-09-29  
Versions: P1 `4807`, P5 `4808`  
Release mode: `supplemental_reserve`

## Decision

The independently reviewed AW5–8 annual reserve top-up is eligible for governed publication as **withheld reserve evidence**.

This release does not create a new learner-facing teaching pack. The source `public.questions` rows remain inactive/draft; the private content metadata is published as `lifecycle_state=reserve`, `exposure_state=withheld`. Selection remains server-governed.

## Exact annual-depth delta

For each of the 14 target skills:

- +2 diagnostic items;
- +2 isolated delayed-retest items;
- +1 mixed/transfer item.

Total new machine reserve:

- P1: 8 skills × 5 = 40 items;
- P5: 6 skills × 5 = 30 items;
- total = 70;
- diagnostics = 28;
- retests = 28;
- mixed = 14;
- diagnostic misconception rules = 84;
- published reserve assessment containers = 34;
- new written tasks = 0.

The existing governed written reserve already provides at least two written tasks per target skill.

## Independent QA carried forward

The release is pinned to the second-pass QA correction set for 13 delayed retests. These retests use inverse/transfer/reconstruction evidence rather than simple number-swaps of published teaching items.

All 70 candidate items were independently re-solved/rechecked before this publication step. EN/RU/UZ, source mapping, frozen snapshots, exact answer map, assessment isolation and misconception-rule coverage remain enforced by contracts.

## Safety boundary

Publication must fail closed unless:

1. versions 4807/4808 are exact draft targets;
2. all 70 rows are still draft/withheld before transition;
3. all 84 diagnostic rules are reviewed draft rules;
4. all 34 assessments are exact holdout-only containers;
5. every target skill already has a separate governed published baseline;
6. the prospective cross-version annual floor reaches 3 diagnostic / 8 learning-transfer / 4 retest / at least 2 written;
7. the governed holdout floor remains at least 20%;
8. there is zero Exam Prep learner-session history and zero Practice/Tour history against the versions;
9. Core remains controlled-beta with AI Assist and Mentor Care OFF.

## Rollback

The release contract rehearses retirement inside a transaction:

- published reserve assessments → retired;
- withheld reserve metadata → retired exposure;
- published content versions → retired;
- no row is deleted or rewritten.

The transaction is then rolled back and the published reserve state must be restored exactly.

## Non-goals

This release does **not** expand the beta cohort, enable AI Assist, enable Mentor Care, modify legacy Practice/Tours, rewrite existing user history, or change localStorage.
