# Exam Prep Tutor Content — Block 12 P5 Probability Review

Status: AUTHORING REVIEW
Scope: P5-PRO-01…06, EN/RU/UZ
Runtime: OFF
Date: 2026-10-05

## Source and scope cross-check

Canonical owner: P5 only.
Official section: 5.3 Probability.
Canonical source map: P5-PRO-01…06.
Book mapping: Complete Probability & Statistics 1, Ch4 Probability, pp. 63–82.

Approved theory source cards confirm the Paper 5 core:
- define sample spaces without omissions or duplicates;
- use counting only when outcomes are equally likely;
- addition rule: P(A∪B)=P(A)+P(B)-P(A∩B);
- complement: P(A')=1-P(A);
- conditional probability: P(A|B)=P(A∩B)/P(B);
- independence: P(A∩B)=P(A)P(B);
- probability trees for sequential events;
- without replacement, update probabilities after each draw.

## Exact learner-facing boundaries

### P5-PRO-01 — Sample spaces
Reviewed example: two coin tosses.
Sample space: HH, HT, TH, TT.
Teach completeness and no duplicates; distinguish an outcome from an event.

### P5-PRO-02 — Probability by counting
Reviewed example: choose 2 balls from 5, with 2 red and 3 blue.
All unordered pairs are equally likely:
total = 5C2 = 10.
Both red = 2C2 = 1.
Probability = 1/10.
Teach favourable/total counting only after confirming equiprobability.

### P5-PRO-03 — Addition rule and complements
Reviewed example:
P(A)=0.6, P(B)=0.5, P(A∩B)=0.2.
P(A∪B)=0.6+0.5-0.2=0.9.
P(A')=0.4.
Teach why overlap is subtracted once.

### P5-PRO-04 — Multiplication rule and independence
Reviewed example:
P(A)=0.4, P(B)=0.5, P(A∩B)=0.2.
Since 0.4×0.5=0.2, A and B are independent.
Teach that independence is a condition to verify/use, not an automatic assumption.

### P5-PRO-05 — Conditional probability
Reviewed example:
P(A∩B)=0.18, P(B)=0.6.
P(A|B)=0.18/0.6=0.3.
Teach the denominator as the restricted sample space after B is known to have occurred.

### P5-PRO-06 — Probability trees
Reviewed without-replacement example:
Bag: 3 red, 2 blue; draw 2 without replacement.
P(RR)=3/5×2/4=3/10.
P(exactly one red)=3/5×2/4 + 2/5×3/4 = 3/5.
Teach multiply along a branch, add mutually exclusive successful paths, and update second-draw probabilities after the first draw.

## Learner-first standard

Each skill contains four distinct variants:
- main: meaning + method + compact reviewed example;
- simple: lower cognitive load;
- alternative: different mental model;
- focus: procedural checks and common traps.

Static cards do not infer personal misconceptions and do not expose internal product terminology.

## Trilingual parity

EN/RU/UZ preserve:
- the same sample spaces;
- the same probabilities and arithmetic;
- the same independence/conditional logic;
- the same tree structure and without-replacement update;
- equivalent mathematical meaning and difficulty.

## Technical acceptance

- 18/18 new Block 12 cards.
- Three locales per skill.
- Total learner-first draft count after Block 12 = 201.
- Total covered skills after Block 12 = 67.
- Exact source-card component/skill/locale linkage.
- DRAFT and runtime OFF only.
- No P1/P5 cross-component leakage.
- No academic-state/entitlement/legacy writes.
- Dedicated Block 12 CI gate GREEN.

## Runtime decision

NO runtime switch in Block 12.
Provider-backed topic explanation remains the production default until the global 243/243 reviewed runtime-ready gate is satisfied.
