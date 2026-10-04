# Exam Prep AI Tutor — Curated Tutor Content Plan v1

Status: ACTIVE IMPLEMENTATION PLAN
Owner decision: approved by product architect
Scope: Cambridge AS Mathematics P1 + P5 controlled beta
Date: 2026-10-04

## Product decision

The first learner action **Explain this topic** should not call the external AI provider when a reviewed iClub Tutor Card exists.

Instead:
1. iClub returns a pre-written, reviewed learner-facing explanation for the exact skill + locale.
2. The learner can use pre-written follow-up options without provider cost:
   - Explain more simply
   - Explain another way
   - What should I pay attention to?
3. Only a learner-written follow-up question enters the governed AI provider flow.
4. Provider follow-up remains bound to the same component, skill, approved source set and current learner context.
5. Maximum provider follow-ups remain bounded by the current mini-thread policy.

This is additive. Exam Prep Core remains fully functional with AI off.

## Why

Goals:
- make the first explanation instant and deterministic;
- remove unnecessary provider cost;
- improve consistency across RU / UZ / EN;
- keep a premium Tutor experience;
- keep approved source grounding;
- preserve academic-state authority boundaries;
- preserve the option for real AI clarification when static content is insufficient.

## Data model

Create a separate governed table for learner-facing Tutor Cards. Do not overload the existing grounding/source-card table.

One row = one canonical skill + one locale + one content version.

Required learner-facing fields:
- title
- main_explanation
- simple_explanation
- alternative_explanation
- focus_explanation

Governance fields:
- tutor_card_key
- component_code
- skill_code
- locale
- content_version
- source_card_key
- approval_status
- is_runtime_allowed
- content_hash
- approved_at / approved_by
- created_at / updated_at

Only service_role may read the private storage directly.

## Coverage target

Canonical scope:
- P1 = 45 skills
- P5 = 36 skills
- total = 81 skills
- locales = RU / UZ / EN
- total Tutor Cards = 243

Each Tutor Card contains four reviewed learner-facing explanation variants.

Runtime switch for provider-free topic explanation is allowed only after:
- 243/243 skill-locale cards exist;
- 243/243 are approved;
- 243/243 are runtime-allowed;
- RU / UZ / EN are mathematically equivalent;
- source-card link exists for every card;
- no active-assessment leakage;
- no P1/P5 cross-component leakage;
- all CI is GREEN.

Until full coverage is approved, the existing provider-backed theory explanation remains the production fallback.

## Pilot first

Before full authoring, create a 3-skill pilot across all three locales:
- P1-QUA-01 — Completing the square
- P1-COO-02 — Distance, midpoint and intersection
- P5-NOR-02 — Standardisation and z-values

Pilot = 9 Tutor Cards.

Pilot cards remain DRAFT / runtime OFF until product review approves the content standard.

## Writing standard

Main explanation:
- one focused skill only;
- learner-facing language;
- 90–160 words target;
- explain the core idea, not the whole syllabus family;
- include notation only where necessary;
- no internal IDs or system terminology;
- no invented academic state;
- no answer-key behavior.

Simple explanation:
- 50–100 words target;
- simpler language, same mathematical meaning;
- avoid removing essential conditions.

Alternative explanation:
- 60–120 words target;
- explain the same idea from a different angle;
- do not introduce a new topic.

Focus explanation:
- 30–70 words target;
- what the learner should notice/check;
- common procedural trap only if source-supported;
- no inferred personal misconception.

All four variants must stay inside the exact canonical skill boundary.

## Runtime design after full approval

For theory_explanation:
- guard still runs;
- active protected assessment still blocks;
- entitlement still required;
- exact component + skill + locale card required;
- return mode = verified_template;
- generated = false;
- academic_state_changed = false;
- provider call = 0;
- provider cost = 0;
- audit row still written.

For pre-written follow-up chips:
- return the corresponding stored variant;
- no provider call;
- audit as verified_template;
- still require valid current capability and protected-assessment guard.

For learner-written follow-up:
- use current bounded context_followup path;
- same approved source card;
- same skill/component/locale;
- current minimized learner context;
- provider only for the free-text question;
- existing budget, concurrency, timeout and safety validation remain.

## Safety invariants

Never change:
- placement
- mastery
- evidence
- stage
- readiness
- retest state
- progression
- marks
- grade
- mentor decisions
- P1/P5 mapping
- Practice
- Tours
- ratings
- certificates
- existing learner history
- localStorage

Mentor Care remains OFF unless independently authorized.

## Rollout sequence

1. Freeze this plan in repo.
2. Add private Tutor Card schema + service-only retrieval.
3. Add CI for permissions, uniqueness, component firewall and coverage.
4. Author 3-skill pilot in RU / UZ / EN as DRAFT.
5. Review pilot wording/visual behavior.
6. Lock writing standard.
7. Author remaining 78 skills × 3 locales.
8. Run mathematical/content QA.
9. Require 243/243 approved/runtime-ready.
10. Only then change theory_explanation to provider-free verified_template.
11. Add provider-free chip variants.
12. Keep free-text follow-up provider-backed and bounded.
13. Production canary, audit cost reduction, then wider rollout if approved.

## Completion definition

This plan stays active until all of the following are true:
- 243/243 Tutor Cards approved;
- all four variants completed for every card;
- production theory explanation uses verified_template by default;
- provider is used only for learner-written follow-up in this flow;
- full CI GREEN;
- controlled-beta smoke GREEN;
- legacy and academic-state postchecks unchanged.

Do not delete or supersede this plan silently. If architecture changes, create a versioned replacement document and reference this file.
