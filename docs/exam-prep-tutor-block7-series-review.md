# Exam Prep Tutor Content — Block 7 Series Review

Status: AUTHORING REVIEW
Scope: P1-SER-01...05, EN/RU/UZ
Runtime: OFF
Date: 2026-10-05

## Source and scope cross-check

Canonical owner: P1.
Official section: 1.6 Series.
Canonical source map:
- P1-SER-01 — binomial expansion, Complete Pure Mathematics 1, Ch6, pp. 109–116;
- P1-SER-02...05 — arithmetic/geometric progressions and convergence, Ch7, pp. 120–133.

Approved source cards confirm the P1 scope:
- positive-integer binomial expansion;
- arithmetic progression with constant difference d;
- geometric progression with constant ratio r;
- finite nth-term and sum formulae;
- infinite geometric series only when |r|<1.

Scope firewall:
- no rational/negative-power binomial expansion;
- no approximation/binomial-series extension;
- no post-P1 infinite-series techniques.

## Exact learner-facing boundaries

### P1-SER-01 — Binomial expansion for positive integer n

Teach the positive-integer binomial theorem using coefficients from nCr.

Reviewed example:

(2+x)^4
= 16 + 32x + 24x² + 8x³ + x⁴.

Hence the coefficient of x² is 24.

Teaching emphasis:
- keep the powers of the first term descending and x ascending;
- match the requested power before calculating the whole expression when possible;
- this skill is restricted to positive integer powers.

### P1-SER-02 — Recognising arithmetic and geometric progressions

Arithmetic progression:
constant difference.

Example:
3, 7, 11, 15, ...
difference = 4.

Geometric progression:
constant ratio.

Example:
2, 6, 18, 54, ...
ratio = 3.

Non-example:
1, 2, 4, 7, ...
neither constant difference nor constant ratio.

Teaching emphasis:
do not classify from the first two terms only; check the pattern across several consecutive terms.

### P1-SER-03 — Arithmetic progression nth term and finite sum

Core formulae:

u_n = a + (n-1)d

S_n = n/2 [2a + (n-1)d].

Reviewed example:
a=5, d=3.

u_10 = 5 + 9×3 = 32.

S_10 = 10/2 [2×5 + 9×3] = 185.

Inverse problems use the same formulae backwards to solve for a, d or n.

### P1-SER-04 — Geometric progression nth term and finite sum

Core formulae:

u_n = ar^(n-1)

S_n = a(1-r^n)/(1-r), for r≠1.

Reviewed example:
a=3, r=2.

u_6 = 3×2^5 = 96.

S_6 = 3(1-2^6)/(1-2) = 189.

Inverse problems use equations formed from known terms/sums to recover a, r or n.

### P1-SER-05 — Infinite geometric series

A geometric series converges only when

|r| < 1.

Then

S_infinity = a/(1-r).

Reviewed example:
a=12, r=1/3.

S_infinity
= 12/(1-1/3)
= 18.

If |r|≥1, the terms do not shrink to zero in the required way, so no finite sum to infinity exists.

## Learner-first standard

Every skill has four distinct variants:
- main: meaning + method + one reviewed worked example;
- simple: low cognitive load;
- alternative: another mental model;
- focus: exam-facing checks/traps.

Do not infer personal mistakes in static content.
Do not expose internal IDs, mastery/evidence terminology or implementation details.

## Trilingual parity

EN/RU/UZ must preserve:
- identical formulas;
- identical example numbers and answers;
- identical progression type;
- identical convergence condition;
- equivalent mathematical meaning and level of help.

Natural school-level language is preferred over literal translation.

## Technical acceptance

- 15/15 new Block 7 cards.
- Three locales per skill.
- Total learner-first draft count after Block 7 = 102.
- Exact source-card component/skill/locale linkage.
- DRAFT and runtime OFF only.
- No rational/negative binomial or other post-P1 drift.
- No internal IDs in learner-facing text.
- No legacy, entitlement or academic-state writes.
- Dedicated Block 7 CI gate GREEN.

## Runtime decision

NO runtime switch in Block 7.
The provider-backed topic explanation remains the production default until the global 243/243 reviewed runtime-ready gate is satisfied.
