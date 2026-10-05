# Exam Prep Tutor Content — Block 13 Discrete Random Variables Review

Status: AUTHORING REVIEW
Scope: P5-DRV-01...03, P5-BIN-01...03, P5-GEO-01...03, EN/RU/UZ
Runtime: OFF
Date: 2026-10-05

## Source and scope cross-check

Canonical owner: P5 only.
Official section: 5.4 Discrete random variables.

Book mapping:
- P5-DRV-01...03 — Complete Probability & Statistics 1, Ch5 Discrete random variables, pp. 84–96.
- P5-BIN-01...03 — Ch7 The binomial distribution, pp. 115–131.
- P5-GEO-01...03 — Ch8 The geometric distribution, pp. 133–145.

Existing approved source cards confirm:
- a discrete distribution has non-negative probabilities summing to 1;
- E(X)=ΣxP(X=x);
- Var(X)=E(X²)-[E(X)]²;
- binomial conditions: fixed n, two outcomes, constant p, independent trials;
- P(X=r)=nCr p^r(1-p)^(n-r), mean=np, variance=np(1-p);
- geometric model counts trials until first success with constant p and independence;
- P(X=r)=(1-p)^(r-1)p and E(X)=1/p;
- cumulative probabilities and complements must be interpreted carefully.

## Exact skill boundaries and reviewed examples

### P5-DRV-01 — Discrete probability distributions

Teach:
- possible x-values are discrete;
- every probability is between 0 and 1;
- probabilities sum to 1;
- use the total-to-one rule to find an unknown probability.

Reviewed example:
X takes values 0, 1, 2 with probabilities 0.2, k, 0.5.

0.2 + k + 0.5 = 1

so

k = 0.3.

### P5-DRV-02 — Expectation

Teach:

E(X)=ΣxP(X=x)

as a probability-weighted long-run mean.

Reviewed example:
Using probabilities 0.2, 0.3, 0.5 for X=0,1,2:

E(X)=0(0.2)+1(0.3)+2(0.5)=1.3.

Interpretation:
1.3 is a long-run average, not a value X must take in one trial.

### P5-DRV-03 — Variance and standard deviation

Teach:

Var(X)=E(X²)-[E(X)]²

and

SD(X)=√Var(X).

Reviewed example:
For X=0,1,2 with probabilities 0.2,0.3,0.5:

E(X)=1.3
E(X²)=0²(0.2)+1²(0.3)+2²(0.5)=2.3
Var(X)=2.3-1.3²=0.61
SD(X)=√0.61≈0.781.

### P5-BIN-01 — Recognising a binomial model

All four conditions must hold:
- fixed number n of trials;
- two outcomes per trial;
- constant success probability p;
- independent trials.

Reviewed example:
10 independent seeds are tested; each germinates with probability 0.7.
If X is the number that germinate, then X is binomial with n=10, p=0.7.

Teaching emphasis:
A fixed sample size alone is not enough; all four conditions matter.

### P5-BIN-02 — Binomial probabilities

Core formula:

P(X=r)=nCr p^r(1-p)^(n-r).

Reviewed example:
X is binomial with n=5, p=0.4.

Point probability:

P(X=2)=5C2(0.4)²(0.6)³=0.3456.

Cumulative probability:

P(X≤1)
=P(X=0)+P(X=1)
=0.33696.

Teaching emphasis:
Translate wording into the correct integer set before calculating.
Complements may simplify “at least” / “more than” questions.

### P5-BIN-03 — Binomial mean, variance and inverse parameters

Core facts:

E(X)=np
Var(X)=np(1-p).

Reviewed example:
X is binomial with n=20 and E(X)=6.

20p=6
p=0.3.

Then

Var(X)=20(0.3)(0.7)=4.2.

Teaching emphasis:
Use mean/variance equations to recover unknown parameters, then check 0≤p≤1.

### P5-GEO-01 — Recognising a geometric model

Teach the model as waiting time to the first success.

Conditions:
- repeated trials;
- two outcomes;
- constant success probability p;
- independent trials;
- X counts the trial number on which the first success occurs.

Reviewed example:
Each independent attempt succeeds with probability 0.2.
X = number of attempts until the first success.
This is a geometric model with p=0.2.

### P5-GEO-02 — Geometric probabilities

Core formula:

P(X=r)=(1-p)^(r-1)p.

Reviewed example:
p=0.25.

P(X=3)
=(0.75)²(0.25)
=0.140625.

For no success in the first 3 trials:

P(X>3)=(0.75)³=0.421875.

Therefore

P(X≤3)=1-(0.75)³=0.578125.

### P5-GEO-03 — Geometric expectation and inverse p

Core fact:

E(X)=1/p.

Reviewed example:
If the expected waiting time to first success is 5 trials,

1/p=5

so

p=0.2.

Teaching emphasis:
Expectation is a long-run average waiting time, not a guaranteed first-success trial.

## Learner-first standard

Each skill gets four distinct variants:
- main = understand meaning + method + reviewed example;
- simple = lower cognitive load;
- alternative = different mental model;
- focus = compact checks/traps.

No static card may claim a learner-specific misconception.
No internal IDs or implementation language appear learner-facing.

## Trilingual parity

EN/RU/UZ must preserve:
- the same distributions;
- the same numerical values;
- the same probabilities and results;
- the same model conditions;
- the same interpretation;
- equivalent notation and difficulty.

## Technical acceptance

- 27/27 new Block 13 cards.
- Three locales per skill.
- Total learner-first draft count after Block 13 = 228.
- Total learner-first canonical skills after Block 13 = 76.
- Exact source-card component/skill/locale linkage.
- DRAFT and runtime OFF only.
- No cross-component leakage.
- No legacy, entitlement or academic-state writes.
- Dedicated Block 13 CI gate GREEN.

## Runtime decision

NO runtime switch in Block 13.
Provider-backed topic explanation remains production default until all 243 reviewed Tutor Cards are approved and runtime-ready.
