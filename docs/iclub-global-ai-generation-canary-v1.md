# iClub Global AI generated Mathematics canary v1

Date: 2026-10-06
Status: implemented in GitHub, dormant, not deployed/activated for learners.

## Scope

Generated Global iClub AI is promoted only for the already-governed Mathematics Exam Prep adapter:

- subject: Mathematics
- scope: Exam Prep
- components: P1 and P5
- context: exact current skill
- source: exact approved runtime theory source card for that skill and locale
- eligible plans: Plus and Pro only
- rollout: server-authorized canary only before public approval

Free remains prepared-answer-only. Unsupported subjects/scopes never fall through to a generic model.

## Request order

A generated request is admitted only in this order:

1. authenticated learner;
2. Global AI gateway + canary rollout;
3. Plus/Pro generation capability;
4. protected-assessment guard;
5. FULL subject/scope readiness + reviewed adapter;
6. exact current P1/P5 skill validation;
7. approved exact-skill theory source retrieval;
8. hidden 5-hour tariff usage reservation;
9. independent provider budget/concurrency reservation;
10. model call;
11. provider cost finalization;
12. output safety/source-bound validation;
13. learner usage completion;
14. generated answer delivery.

The model cannot run before the protected-assessment and source checks.

## Source boundary

The provider receives only:

- learner's current question;
- human-readable P1/P5 component label;
- approved exact-skill theory card title/body;
- strict system instructions.

It does not receive:

- raw chat history;
- other subject threads;
- answer keys;
- mastery/readiness state;
- hidden tariff units;
- user profile data beyond what the gateway already used for authorization;
- database/internal identifiers.

If the approved source cannot support the question, the provider is instructed to return an internal no-source sentinel; that sentinel is never shown to the learner.

## No actions / no academic authority

Generated output is text only.

Global AI cannot:
- navigate;
- start or submit tests;
- save learner answers;
- change subject selections;
- change mastery/readiness/placement/progression;
- assign marks;
- change rankings/certificates/recommendations/history.

Every response keeps academic_state_changed=false.

## Learner usage accounting

Prepared and generated answers remain one visible iClub AI experience.

Internal 5-hour policy remains:
- Free: 3 units, prepared weight 1, generation disabled;
- Plus: 9 units, prepared weight 1, generation weight 5;
- Pro: 14 units, prepared weight 1, generation weight 5.

No counter is exposed.

A generated request consumes learner allowance only after:
- provider response exists;
- provider output passes validation;
- learner usage finalization succeeds.

Provider timeout/error, missing source, budget block, assessment block, validation rejection, or failed delivery does not consume learner allowance.

A failed first request does not start the learner's 5-hour window because the provisional usage period is released/closed with no successful response.

## Provider cost guard

Global AI owns a separate atomic provider budget pool using the same proven reservation pattern as the existing Exam Prep AI.

Current conservative canary defaults:
- global provider ceiling: USD 0.50/day;
- per-user provider ceiling: USD 0.05/day;
- per-request reservation ceiling: USD 0.01;
- max concurrent provider calls: 2;
- max user provider calls: 20/day;
- provider lease TTL: 45 seconds.

Model configuration:
- model: gpt-5.6-luna;
- max output: 220 tokens;
- timeout: 12 seconds;
- provider storage: disabled (store:false).

These are operational safety ceilings, not learner-facing plan limits. They must be re-costed before public rollout.

If provider output is generated but rejected by validation, real provider cost is still recorded, while learner allowance is released.

## Output validation

Generated text is rejected if it contains, among other things:
- unsafe HTML/script markup;
- raw LaTeX commands;
- unexpected links;
- internal identifiers;
- unsupported numerical claims not present in the source/question;
- wrong output locale;
- claims of changing progress/mastery/readiness;
- guaranteed grades/results;
- answer-key/final-mark authority.

Pure numbered-list markers are ignored by the numeric-claim validator so formatting such as 1. / 2) does not cause a false rejection.

## Canary/public rollout

Nothing in this phase turns generation on.

Default state remains:
- generation_enabled=false;
- Global AI rollout=off;
- no beta accounts assigned here;
- no production migration applied;
- no production Edge deployment performed.

Before a real beta:
1. complete/merge the full dormant stack;
2. identify the exact three beta accounts explicitly;
3. map them intentionally to Free / Plus / Pro test states;
4. verify provider secret/configuration in the controlled environment;
5. enable Global AI only for the canary cohort;
6. run funded real-provider acceptance;
7. inspect cost/audit/validation behavior;
8. keep kill switches ready;
9. do not promote to all without separate architect approval.
