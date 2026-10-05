# Exam Prep AI Tutor — 243/243 Approval & Runtime-Readiness v1

Status: GOVERNANCE PACKAGE — PRE-MERGE
Date: 2026-10-05
Scope: Cambridge AS Mathematics P1 + P5 Tutor Cards
Runtime default switch: NOT INCLUDED

## Purpose

This package promotes the already reviewed learner-first Tutor Card corpus from:

- approval_status = draft
- is_runtime_allowed = false

to:

- approval_status = approved
- is_runtime_allowed = true

for exactly the reviewed content version:

tutor_v2_learner_first

The package does **not** change the current production topic-explanation path. The Edge Function still uses the existing provider-backed flow because no runtime routing code is modified here.

This is a governance/readiness step only.

## Entry evidence

The prior global review is complete and GREEN:

- 243/243 expected skill-locale cards exist;
- 81/81 canonical skills covered;
- P1 = 45 skills = 135 locale cards;
- P5 = 36 skills = 108 locale cards;
- missing rows = 0;
- unexpected rows = 0;
- bad source links = 0;
- bad locale groups = 0;
- blank/thin content failures = 0;
- duplicate variants = 0;
- duplicate full content packages = 0;
- stale hashes = 0;
- internal implementation terminology hits = 0;
- P1/P5 firewall failures = 0;
- formatting/markup hygiene failures = 0;
- approved cards before this package = 0;
- runtime cards before this package = 0.

PR #309 merged the global review gate with all relevant checks GREEN.

## What this package may change

Only governance fields on private.exam_prep_ai_tutor_cards for content_version tutor_v2_learner_first:

- approval_status
- is_runtime_allowed
- approved_at
- approved_by
- updated_at

No learner-facing production routing is changed.

## What this package must never change

- users
- learner academic state
- evidence
- stage
- mastery
- readiness
- correction/retest state
- feature entitlements
- cohort membership
- Practice answers
- Tour answers
- ratings
- certificates
- localStorage
- source-card content
- P1/P5 skill ownership
- Mentor Care state

## Approval identity

No synthetic approver UUID is invented.

approved_by remains NULL because the product decision is recorded through the versioned repository review/merge history rather than a fabricated application user identity.

approved_at records the database promotion time.

## Runtime-readiness meaning

is_runtime_allowed = true means the service-role lookup may retrieve the card.

It does **not** mean the learner automatically sees the card.

The production Edge Function does not yet call the Tutor Card lookup, so production behavior remains provider-backed until a separate canary PR changes routing.

## Atomic promotion rules

The migration refuses to run unless:

- exactly 243 tutor_v2_learner_first cards exist;
- exactly 81 canonical skills exist;
- all 243 are still DRAFT/runtime OFF;
- no learner-first card is already approved/runtime;
- every source-card link is exact and approved/runtime;
- all content hashes are current.

After promotion it requires:

- 243 approved/runtime cards;
- 243 service-readable cards;
- coverage expected=243;
- ready=243;
- missing=0;
- P1 ready=135;
- P5 ready=108;
- browser roles still cannot read private storage or execute service lookup.

## Reversion

A separate emergency reversion file is included.

It reverts only the Tutor Card governance fields back to:

- approval_status = draft
- is_runtime_allowed = false
- approved_at = NULL
- approved_by = NULL

The reversion does not touch learner state or legacy systems.

## Next step after this package

Only after this package is merged, applied to production and postchecked may the controlled-beta provider-free canary be implemented.

That later canary must:

1. keep the active-assessment guard;
2. keep AI entitlement gating;
3. require exact component + skill + locale Tutor Card;
4. return verified_template for the main explanation;
5. keep generated=false;
6. keep academic_state_changed=false;
7. make zero provider calls for curated main/simple/alternative/focus variants;
8. keep learner-written follow-up provider-backed and bounded;
9. retain immediate fallback to the existing provider-backed theory explanation;
10. stay limited to the existing controlled beta until separately approved.
