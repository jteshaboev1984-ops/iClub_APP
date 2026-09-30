# Exam Prep AW9–12 annual reserve release v1

Date: 2026-09-30  
Versions: P1 `4811`, P5 `4812`  
Release mode: `supplemental_reserve`

## Decision

The independently reviewed AW9–12 annual-reserve top-up is eligible for governed publication only after the full release CI stack passes.

This is a reserve-only expansion. It adds future diagnostic, delayed-retest and mixed/transfer depth without replacing any existing learner evidence, learning pack, written task, Practice record, Tour record or certificate.

## Release surface

Across 14 canonical skills:

- 28 diagnostic reserve items: +2 per skill.
- 28 delayed-retest reserve items: +2 per skill.
- 14 mixed/transfer reserve items: +1 per skill.
- 70 machine reserve items total.
- 84 diagnostic misconception rules: three wrong-option diagnoses for each diagnostic item.
- 34 holdout assessments: 4 diagnostic variants, 28 isolated one-item retests and 2 mixed transfer sets.
- No new written tasks. Each target skill already has at least two governed published written tasks outside these reserve-only versions.

After release, each target skill has the annual numeric runway of 3 diagnostics, 8 learning/transfer items, 4 delayed retests and at least 2 written tasks.

## Independent QA carried forward

The release is pinned to the independent second-pass review from PR #239.

The review corrected or strengthened reserve items where answer logic, mathematical framing, learner-language quality, delayed-retest independence or transfer quality needed improvement. It also locks representative corrected stems and the reviewed answer map before publication.

Diagnostic answer positions remain balanced independently by component:

- P1: A/B/C/D = 4/4/4/4.
- P5: A/B/C/D = 3/3/3/3.

## Exposure and evidence safety

Publication changes only governed reserve state:

- the content versions become published;
- machine metadata becomes lifecycle `reserve`;
- exposure remains `withheld`;
- diagnostic rules become approved;
- assessment containers become published holdouts;
- source rows in `public.questions` remain inactive and quality status `draft`.

The release does not make reserve questions directly learner-visible and does not mutate historical learner evidence.

## Fail-closed gates

Publication fails unless all of the following remain true:

1. versions 4811/4812 are the exact reviewed drafts;
2. all 70 machine items have complete EN/RU/UZ content and exact frozen snapshots;
3. all 28 diagnostics have three reviewed misconception rules;
4. all 34 assessment containers preserve exact reserve roles and holdout isolation;
5. no written tasks exist inside these reserve-only versions;
6. no learner session, Practice answer or Tour answer references either target version;
7. every target skill has a separate governed full-floor baseline;
8. the supplemental-reserve floor is ready for P1 and P5 before version publication;
9. public source questions remain inactive/draft;
10. controlled beta remains active with Core ON, AI Assist OFF, Mentor Care OFF and kill switch OFF.

## Rollback

The release contract rehearses retirement of future reserve selection without deleting governed content or rewriting historical evidence. The transaction is rolled back and the published reserve state must be restored exactly.

## Non-goals

This release does not expand the beta cohort, enable AI Assist, enable Mentor Care, alter localStorage, change Practice/Tours/certificates, publish new written tasks or claim learner exam readiness.
