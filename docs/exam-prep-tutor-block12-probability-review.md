# Exam Prep Tutor Content — Block 12 Probability Review

Status: AUTHORING REVIEW
Scope: P5-PRO-01...06, EN/RU/UZ
Runtime: OFF
Date: 2026-10-05

## Source and scope cross-check

Canonical owner: P5 only.
Official section: 5.3 Probability.
Canonical source map: P5-PRO-01...06.
Book mapping: Complete Probability & Statistics 1, Chapter 4 Probability, pp. 63–82.

Existing approved source cards confirm the governed P5 probability scope:
- complete sample spaces without omissions or duplicates;
- counting methods for equally likely outcomes;
- addition rule and complements;
- conditional probability;
- independence and multiplication;
- probability trees for sequential events;
- probability updates for sampling without replacement.

## Exact learner-facing boundaries and reviewed examples

### P5-PRO-01 — Sample spaces

Teach how to list every possible outcome exactly once and use equally likely outcomes correctly.

Reviewed example:
Two fair coin tosses:
S = {HH, HT, TH, TT}.
Exactly one head:
{HT, TH}, so probability = 2/4 = 1/2.

Teaching emphasis:
HT and TH are different ordered outcomes.
A probability denominator based on counting is valid only when the listed outcomes are equally likely.

### P5-PRO-02 — Probability by counting

Teach probability as

favourable equally likely outcomes / total equally likely outcomes,

with permutations/combinations used to count rather than list when appropriate.

Reviewed example:
Choose 2 objects from 6, where 3 are red and 3 are blue.
Total selections = C(6,2)=15.
Both red = C(3,2)=3.
Probability = 3/15 = 1/5.

Teaching emphasis:
Use combinations when order does not matter; numerator and denominator must count outcomes using the same model.

### P5-PRO-03 — Addition rule, complements and mutually exclusive events

Core rule:

P(A ∪ B) = P(A) + P(B) - P(A ∩ B).

Complement:

P(A') = 1 - P(A).

For mutually exclusive events:

P(A ∩ B)=0,

so probabilities add directly.

Reviewed example:
One fair die.
A = even = {2,4,6}.
B = greater than 4 = {5,6}.
A ∩ B = {6}.
Therefore

P(A ∪ B)=3/6+2/6-1/6=4/6=2/3.

Teaching emphasis:
Do not double-count overlap.

### P5-PRO-04 — Multiplication rule and independence

General multiplication rule:

P(A ∩ B)=P(A)P(B|A).

If A and B are independent:

P(B|A)=P(B),

so

P(A ∩ B)=P(A)P(B).

Reviewed independent example:
A fair coin and a fair die.
P(head and 6)=1/2 × 1/6 = 1/12.

Teaching emphasis:
Do not multiply marginal probabilities unless independence is justified.

### P5-PRO-05 — Conditional probability

Core rule:

P(A|B)=P(A ∩ B)/P(B),

with P(B)>0.

Reviewed count example:
Among 20 students, 12 study Mathematics, 8 study Physics, and 5 study both.
Given that a student studies Mathematics, the relevant group has 12 students.
5 of those also study Physics.

P(Physics | Mathematics)=5/12.

Teaching emphasis:
Conditioning creates a new restricted sample space.

### P5-PRO-06 — Probability trees and without replacement

Teach:
- branch probabilities sum to 1 at each split;
- multiply probabilities along a path;
- add mutually exclusive complete paths for an event;
- update probabilities after each draw when there is no replacement.

Reviewed example:
Bag contains 3 red and 2 blue counters. Draw 2 without replacement.

P(R then B)=3/5 × 2/4 = 3/10.

P(one of each)
= P(RB)+P(BR)
= 3/5×2/4 + 2/5×3/4
= 3/5.

Teaching emphasis:
The second-stage denominator is 4, not 5, because one counter has already been removed.

## Learner-first standard

Each canonical skill gets four genuinely different variants:
- main: meaning + method + one reviewed worked example;
- simple: reduced cognitive load;
- alternative: different mental model or representation;
- focus: compact checks and procedural traps.

Static Tutor Cards never infer a learner-specific misconception.
No internal IDs or implementation language are learner-facing.

## Trilingual parity

EN/RU/UZ must preserve:
- identical mathematical examples;
- identical counts and probabilities;
- identical conditions;
- identical solution/conclusion;
- equivalent notation and hinting level.

Natural school-level language is preferred over literal translation.

## Technical acceptance

- 18/18 new Block 12 cards.
- Three locales per skill.
- Total learner-first draft count after Block 12 = 201.
- Total learner-first canonical skills after Block 12 = 67.
- Exact source-card component/skill/locale linkage.
- DRAFT and runtime OFF only.
- No P1/P5 leakage.
- No legacy, entitlement or academic-state writes.
- Dedicated Block 12 CI gate GREEN.

## Runtime decision

NO runtime switch in Block 12.
The provider-backed topic explanation remains production default until 243/243 reviewed Tutor Cards are approved and runtime-ready.
