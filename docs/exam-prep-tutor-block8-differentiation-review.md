# Exam Prep Tutor Content — Block 8 Differentiation Review

Status: AUTHORING REVIEW
Scope: P1-DIF-01...07, EN/RU/UZ
Runtime: OFF
Date: 2026-10-05

## Source and scope cross-check

Canonical owner: P1.
Official section: 1.7 Differentiation.
Canonical source nodes: P1-DIF-01...07.
Existing approved theory source cards define the Paper 1 scope:
- derivative as gradient and instantaneous rate of change;
- power rule for allowed rational powers;
- chain rule for (ax+b)^n;
- tangent and normal;
- increasing/decreasing intervals from derivative sign;
- connected rates with consistent signs and units;
- stationary points, classification, sketching and optimisation.

Scope firewall:
- no product/quotient rule;
- no exponential/logarithmic differentiation;
- no implicit/parametric differentiation;
- no post-P1 calculus methods.

## Exact learner-facing boundaries

### P1-DIF-01 — Meaning of the derivative

Teach the derivative as:
- gradient of the tangent;
- instantaneous rate of change;
- limit of average gradients in a simple case.

Reviewed example:
f(x)=x² at x=3.

[f(3+h)-f(3)]/h
= [(3+h)²-9]/h
= 6+h.

As h→0, the derivative is 6.

### P1-DIF-02 — Differentiating powers

Core rule:

d/dx(x^n)=n x^(n-1)

for the allowed rational powers in Paper 1.

Reviewed example:

y=4x³+3x^(1/2)

dy/dx=12x²+(3/2)x^(-1/2).

Linear combinations are differentiated term by term.

### P1-DIF-03 — Chain rule for (ax+b)^n

Reviewed example:

y=(3x-1)^4

dy/dx=4(3x-1)^3 × 3
=12(3x-1)^3.

Teaching emphasis:
differentiate the outside power, then multiply by the derivative of the inside linear expression.

### P1-DIF-04 — Tangent and normal

Reviewed example:
y=x² at x=2.

Point: (2,4).
Derivative: dy/dx=2x.
Tangent gradient =4.

Tangent:
y-4=4(x-2).

Normal gradient =-1/4.

Normal:
y-4=-(1/4)(x-2).

### P1-DIF-05 — Increasing and decreasing intervals

Reviewed example:

y=x³-3x

dy/dx=3x²-3
=3(x-1)(x+1).

Therefore:
- increasing for x<-1;
- decreasing for -1<x<1;
- increasing for x>1.

Teaching emphasis:
interval behaviour comes from the sign of the derivative, not just where the derivative equals zero.

### P1-DIF-06 — Rates of change and connected rates

Reviewed example:
A=πr² and dr/dt=2 cm/s.

dA/dt
= dA/dr × dr/dt
=2πr × 2.

At r=5 cm:

dA/dt=20π cm²/s.

Teaching emphasis:
- identify the shared variable;
- connect rates by the chain rule;
- preserve sign and units.

### P1-DIF-07 — Stationary points and optimisation

Reviewed example:

y=x³-3x.

dy/dx=3(x-1)(x+1), so stationary points occur at x=-1 and x=1.

Coordinates:
(-1,2) and (1,-2).

Derivative sign:
+ to - at x=-1 ⇒ local maximum;
- to + at x=1 ⇒ local minimum.

For optimisation, first express the required quantity as one-variable function, then find and classify its stationary point within the allowed domain.

## Learner-first standard

Every skill has:
- main: meaning + method + one reviewed example;
- simple: lower cognitive load;
- alternative: another mental model;
- focus: quick checks and common mistakes.

No static card should infer a personal misconception.
No internal IDs, mastery/evidence terminology or implementation language.

## Trilingual parity

EN/RU/UZ preserve:
- the same functions and numerical examples;
- the same derivative results;
- the same tangent/normal equations;
- the same intervals and stationary points;
- the same rate units;
- the same P1 scope.

## Technical acceptance

- 21/21 new Block 8 cards.
- Three locales per skill.
- Total learner-first draft count after Block 8 = 123.
- Exact source-card component/skill/locale linkage.
- DRAFT and runtime OFF only.
- No product/quotient/log/exp/implicit/parametric drift.
- No legacy, entitlement or academic-state writes.
- Dedicated Block 8 CI gate GREEN.

## Runtime decision

NO runtime switch in Block 8.
Provider-backed topic explanation remains the production default until the global 243/243 reviewed runtime-ready gate is satisfied.
