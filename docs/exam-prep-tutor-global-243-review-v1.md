# Exam Prep AI Tutor — Global 243/243 Content Governance Review v1

Status: GLOBAL REVIEW IN PROGRESS
Runtime: OFF
Date: 2026-10-05

## Scope

This review covers the full learner-first Tutor Card corpus for Cambridge AS Mathematics Exam Prep:

- 81 canonical skills;
- P1: 45 skills;
- P5: 36 skills;
- EN / RU / UZ for every skill;
- 243 Tutor Cards total;
- four learner-facing variants per card:
  - main explanation;
  - simpler explanation;
  - alternative explanation;
  - focus/check explanation.

The corpus remains DRAFT and runtime OFF throughout this review.

## Why this is a separate gate

Completing 243 cards is not the same as approving them for learner runtime.

The global review checks the corpus as one governed product:
- exact canonical coverage;
- P1/P5 separation;
- source linkage;
- trilingual completeness;
- content integrity;
- learner-facing language;
- variant independence;
- formatting;
- preservation of the existing production AI path.

Only after this review is GREEN may a separate approval/runtime-ready migration be considered.

## Production read-only audit at start of global review

Verified on 2026-10-05:

- expected canonical skill-locale rows: 243;
- actual learner-first Tutor Cards: 243;
- distinct canonical skills: 81;
- missing expected rows: 0;
- unexpected rows: 0;
- bad 3-locale skill groups: 0;
- bad source-card links: 0;
- blank content fields: 0;
- literal backslash-n formatting defects: 0;
- internal implementation terminology hits: 0;
- exact duplicate full-content groups: 0;
- stale content hashes: 0;
- approved learner-first cards: 0;
- runtime learner-first cards: 0.

Content thickness read-only checks:
- minimum main explanation length: 354 characters;
- minimum simple explanation length: 125 characters;
- minimum alternative explanation length: 172 characters;
- minimum focus explanation length: 154 characters.

Variant integrity:
- main = simple duplicates: 0;
- main = alternative duplicates: 0;
- main = focus duplicates: 0;
- simple = alternative duplicates: 0;
- simple = focus duplicates: 0;
- alternative = focus duplicates: 0.

Component firewall:
- P1 cards mentioning Paper 5: 0;
- P5 cards mentioning Paper 1: 0;
- component/key mismatches: 0;
- invalid locales: 0.

Production learner-state baseline remains unchanged:
- users: 1442;
- Practice answers: 8770;
- Tour answers: 6267;
- certificates: 157;
- AI-entitled real beta learners: 3;
- Mentor-entitled learners: 0;
- synthetic identities: 0;
- active-plan transition hard anomalies: 0.

## Corpus-level acceptance rules

### 1. Exact coverage

The expected set is generated from the active canonical P1/P5 syllabus nodes crossed with EN/RU/UZ.

Required:
- exactly 243 expected rows;
- exactly 243 learner-first cards;
- exactly 81 canonical skills;
- one and only one card for each component + skill + locale;
- no unexpected skill/locale card.

### 2. Exact source linkage

Every Tutor Card must link to one approved/runtime theory source card with identical:
- component;
- skill;
- locale.

No missing or cross-linked source is accepted.

### 3. P1/P5 firewall

Required:
- Tutor Card component matches the canonical skill owner;
- tutor_card_key prefix matches component;
- no raw opposite-paper IDs or learner-facing cross-component implementation language.

### 4. Learner-facing language

Reject any learner-facing text that exposes internal implementation vocabulary such as:
- raw canonical skill IDs;
- source_card;
- action_code;
- item_type;
- process_step;
- learner_context;
- service mode;
- mastery as an internal state label.

Normal mathematical terms remain allowed.

### 5. Content completeness and thickness

All five learner-facing text fields must be non-empty:
- title;
- main;
- simple;
- alternative;
- focus.

The global mechanical floor is deliberately below the writing-standard target so formulas and concise mathematical explanations are not punished:
- main >= 300 characters;
- simple >= 100 characters;
- alternative >= 140 characters;
- focus >= 100 characters.

The writing standard remains the stronger editorial rule.

### 6. Variant independence

Within one card, no two explanation variants may be exactly identical.

The four variants must continue to serve different purposes:
- main = concept/method;
- simple = reduced cognitive load;
- alternative = different mental model;
- focus = checks/traps.

### 7. Formatting and integrity

Required:
- no literal backslash-n sequence in learner-facing fields;
- stored content hash matches the current content;
- no exact duplicated full four-variant content package across different cards;
- no HTML/script injection surface introduced in curated content.

### 8. Runtime safety

During this review:
- approval_status remains draft;
- is_runtime_allowed remains false;
- Tutor runtime count remains zero;
- existing provider-backed topic explanation remains unchanged.

No review PR may write learner evidence, stages, entitlements, Practice, Tours, ratings, certificates, users, or localStorage.

## Mathematical/trilingual review model

Mathematical equivalence is primarily enforced by:
1. the per-block reviewed worked-example anchors;
2. the per-block EN/RU/UZ CI parity gates;
3. exact canonical skill boundaries in each block review;
4. this global structural/source/firewall audit.

A crude “all numeric characters must be byte-identical across translations” rule is NOT used as a release criterion, because natural EN/RU/UZ prose may express quantities differently while preserving the same mathematics. The reviewed worked-example anchors remain the stronger signal.

## Decision after this review

This review does not itself activate Tutor Cards.

If all global gates remain GREEN, the next change must be a separate, reversible governance package that:
1. records approval of the reviewed 243-card version;
2. makes the approved version runtime-readable without changing learner academic state;
3. keeps provider-backed free-text follow-up available;
4. changes only the controlled-beta default for topic explanation in a separate canary;
5. retains an immediate fallback to the existing provider-backed path.

No mass rollout is implied.
