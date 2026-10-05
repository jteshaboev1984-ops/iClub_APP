# Exam Prep AI Tutor — Provider-Free Topic Canary v1

Status: IMPLEMENTATION CANARY
Date: 2026-10-05
Scope: existing controlled-beta AI-entitled learners only
Tutor corpus: tutor_v2_learner_first, 243/243 approved + runtime-readable

## Product behavior

For **Explain this topic**:
- keep the existing Exam Prep AI guard;
- keep active-assessment blackout;
- keep exact P1/P5 + skill + locale binding;
- resolve the reviewed Tutor Card through service_role;
- return main_explanation with mode=verified_template;
- generated=false;
- provider_called=false;
- academic_state_changed=false;
- make zero provider budget reservation and zero OpenAI call.

For the three pre-written follow-up chips on a topic:
- Explain more simply → simple_explanation;
- Explain it differently → alternative_explanation;
- What should I focus on? → focus_explanation;
- mode=verified_template;
- generated=false;
- provider_called=false;
- no provider budget reservation / no OpenAI call.

For a learner-written follow-up question:
- retain the existing context_followup provider path;
- keep the same component/skill/locale;
- keep deterministic-context hash binding;
- keep approved-source binding;
- keep previous-output hash binding;
- keep the two-turn maximum;
- keep prompt-injection prefilter, budget, timeout and output validation.

## Fallback

If the exact Tutor Card cannot be resolved or does not match the current approved source-card binding, do not show partial/untrusted curated content.

Fall through to the existing governed provider-backed theory explanation path.

## Thread compatibility

A follow-up parent may now be either:
- generated; or
- verified_template.

The output hash, deterministic snapshot hash and source-card set must still match before a follow-up continues.

This permits:
- curated main → curated chip → provider-backed learner question;
- curated main → provider-backed learner question;
while preserving the existing thread integrity checks.

## Learner-facing copy

The first topic button no longer claims that the first response is generated “with AI”.
It reads as a normal Tutor action:
- RU: «Объяснить эту тему»
- UZ: «Bu mavzuni tushuntirish»
- EN: «Explain this topic»

The curated source note explicitly says the first response is based on reviewed iClub learning material.

The iClub AI mark stays visible because the whole Tutor surface still owns the bounded clarification flow.

## Safety invariants

No changes to:
- users;
- Practice / Tours;
- ratings / certificates;
- learner academic state;
- evidence / mastery / stage / readiness;
- correction / retest state;
- entitlement or cohort membership;
- localStorage;
- Mentor Care state;
- P1/P5 ownership.

## Canary exit evidence

Before merge/deploy:
- Edge static safety contract GREEN;
- Deno type-check GREEN;
- browser AI UI regression GREEN;
- host regression GREEN;
- no active-assessment surface;
- curated response initializes the bounded thread;
- curated chip can chain into a learner-written provider question;
- static variants return before provider reservation/call.

After deploy:
- exactly 3 existing AI-entitled beta learners remain;
- Mentor entitlement remains 0;
- legacy counts unchanged;
- transition audit hard anomalies remain 0;
- 243/243 Tutor Cards remain approved/runtime-readable.

## Reversion

Code-only reversion:
- restore provider-backed theory routing in exam-prep-ai;
- restore generated-only thread-parent acceptance;
- restore prior UI asset pins.

Tutor Card governance data remains intact; no content/database rollback is required.
