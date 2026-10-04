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

## Locked learner-first writing standard

Status: APPROVED CONTENT STANDARD as of 2026-10-04. Use this standard for all new Tutor Cards until a versioned replacement is explicitly approved.

### Core learner goal

A learner who presses **Explain this topic** is usually not asking for a syllabus definition. The Tutor Card should help the learner understand:

1. what is happening;
2. why the method/idea works;
3. how to use it;
4. one compact worked example when the skill is procedural and an example genuinely helps.

The content should feel like a strong teacher explaining one idea in 30–60 seconds on a phone, not like a textbook paragraph or syllabus summary.

### Main explanation

Target:
- one exact canonical skill only;
- normally 90–170 words;
- learner-facing language;
- explain meaning first, then method;
- include one compact worked example for procedural skills when useful;
- finish with the key reason/interpretation the learner should understand;
- keep formula lines visually separable from prose;
- no internal IDs/system terminology;
- no invented personal weakness or academic state;
- no answer-key behavior.

Preferred structure for a procedural skill:
- what the idea is / why it is useful;
- one small example;
- what the result means;
- one sentence capturing the underlying idea.

### Simple explanation

Target:
- normally 50–110 words;
- genuinely lower cognitive load, not merely shorter wording;
- reduce abstraction and terminology;
- use one very small example if it clarifies the idea;
- preserve all essential mathematical conditions.

### Alternative explanation

Target:
- normally 60–130 words;
- a different mental model, representation or route to the same idea;
- must not be a paraphrase of the main explanation;
- must not introduce a neighboring syllabus topic.

Examples of useful alternative angles:
- reverse an expansion;
- geometric interpretation;
- position on a graph;
- area/probability interpretation;
- link between given information and the quantity being sought.

### Focus explanation

Target:
- normally 30–80 words;
- tell the learner what to check while working;
- include common procedural traps only when academically justified by the source/material;
- never claim “you make this mistake” unless the live learner context proves it;
- concise enough to scan during study.

### Skill-specific shape, not rigid templates

The four-field structure is fixed, but the teaching shape is allowed to vary by skill type:

- procedural algebra/calculus: method + short worked example;
- graph/function skills: interpretation + visual/coordinate meaning;
- probability/statistics: define the event/region first, then calculation;
- conceptual/model-selection skills: example/non-example or decision rule may be stronger than calculation;
- proof/argument skills: logic chain and condition checking are more important than a numeric example.

Do not force every skill into the same prose pattern.

### Worked-example rule

A worked example is preferred when it materially improves understanding, but it must:
- stay strictly within the canonical skill;
- use small, clean numbers;
- be pre-written and reviewed;
- not come from a protected assessment/past-paper answer key;
- not introduce an unreviewed method;
- fit on a mobile screen without becoming a mini-lesson.

### Exact skill boundary

One Tutor Card = one canonical skill. Do not drift into the whole syllabus family.

For example, a Completing the Square card may explain completed-square form, vertex/shape meaning and the algebra needed to get there. It must not expand into a general lesson on discriminants, quadratic inequalities, linear–quadratic systems or reducing equations to quadratics.

### Learner language

Never show internal implementation language such as:
- canonical skill;
- source card;
- mastery/evidence state;
- action_code/item_type/process_step;
- operational stage;
- internal P1/P5 skill IDs.

The learner sees normal mathematical language only.

### Personalisation boundary

Static Tutor Cards may say “a common mistake is…” only when academically justified.
Static cards must never say “you are making this mistake” or infer a personal misconception.

Personalised claims are reserved for the governed live learner-context layer.

### RU / UZ / EN parity

The three languages must be mathematically equivalent, but they do not need to be literal translations.

Every locale must preserve:
- the same mathematical idea;
- the same conditions;
- the same worked-example values;
- the same conclusion;
- the same level of hinting/difficulty;
- equivalent notation.

Natural school-level phrasing is preferred over literal translation.

### Mobile/premium presentation constraint

A first explanation should usually be understandable in 30–60 seconds.
Prefer:
- 2–4 short paragraphs;
- isolated formula/example lines;
- one clear teaching idea per paragraph;
- no walls of text.

If a card needs substantially more space, split complexity into the pre-written follow-up variants rather than making the first answer longer.

### Four variants must solve four different learner needs

- **main_explanation** = understand the idea and method;
- **simple_explanation** = reduce cognitive load;
- **alternative_explanation** = offer a genuinely different mental model;
- **focus_explanation** = know what to check / avoid while working.

Do not create four stylistic paraphrases of the same paragraph.

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

## Current block status

- Block 0 — foundation: DONE
- Block 1 — learner-first pilot standard: DONE / production storage updated, runtime remains OFF
- Block 2 — P1 Quadratics family P1-QUA-02…06: DONE / production storage updated, runtime remains OFF
- Block 3 — P1 Functions family P1-FUN-01…08: DONE / production storage updated, runtime remains OFF
- Block 4 — P1 Coordinate geometry P1-COO-01,03…06: IN PROGRESS (P1-COO-02 already covered by Block 1 pilot)
- Production provider-free switch: NOT STARTED; requires full 243/243 reviewed runtime-ready coverage

## Block implementation sequence

Work in reviewed blocks. Every block must finish its own source/scope/content/locale/CI checks before the next block is promoted.

1. **Block 0 — foundation (DONE):** freeze architecture, add private Tutor Card storage, service-only retrieval, coverage audit and CI.
2. **Block 1 — learner-first pilot standard:** supersede the original draft pilot with the locked learner-first standard for P1-QUA-01, P1-COO-02 and P5-NOR-02 in RU / UZ / EN. Keep runtime OFF.
3. **Block 2 — P1 Quadratics family:** author P1-QUA-02…06 in all three locales using the same standard; cross-check exact canonical boundaries before acceptance.
4. Continue by coherent syllabus families, not arbitrary row batches. Each family gets source-map review, content review, trilingual equivalence review and technical validation.
5. When all 81 skills × 3 locales exist, run global coverage and cross-skill drift checks.
6. Move content through review states; do not mark learner-runtime ready merely because a row exists.
7. Require 243/243 approved/runtime-ready before changing production theory_explanation default.
8. Only then change theory_explanation to provider-free verified_template.
9. Add provider-free simple / alternative / focus chips.
10. Keep learner-written follow-up provider-backed, bounded and source/context locked.
11. Run controlled-beta smoke, verify provider-cost reduction and confirm academic/legacy parity before any wider rollout.

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
