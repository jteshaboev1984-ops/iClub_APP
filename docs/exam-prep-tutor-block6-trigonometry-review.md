# Exam Prep Tutor Content — Block 6 Trigonometry Review

Status: AUTHORING REVIEW
Scope: P1-TRI-01...05, EN/RU/UZ
Runtime: OFF
Date: 2026-10-05

## Source and scope cross-check

Canonical owner: P1.
Official section: 1.5 Trigonometry.
Canonical source map: P1-TRI-01...05.
Book mapping: Complete Pure Mathematics 1, Chapter 5 Trigonometry, pages 86-104.
Existing approved theory source cards confirm the P1 scope:
- shapes, periods and key values of sin, cos and tan;
- simple graph transformations;
- exact values and quadrant symmetry;
- inverse trig functions return principal values;
- use graph/unit-circle patterns to find every solution in the required interval;
- basic identities sin²x + cos²x = 1 and tan x = sin x / cos x.

Explicit firewall:
- addition formulae;
- double-angle formulae;
- other post-P1 trigonometric extensions
must not be introduced into these Tutor Cards.

## Exact learner-facing boundaries

### P1-TRI-01 — Graphs of sin, cos and tan

Teach:
- the characteristic shapes;
- periods;
- key zeros/maxima/minima/asymptotes where relevant;
- simple transformations.

Core facts:
- sin x and cos x have period 2π and range [-1,1];
- tan x has period π;
- tan x has vertical asymptotes at π/2 + kπ.

Reviewed transformation example:
y = 2 sin x + 1.
It keeps period 2π, has vertical scale factor 2 and is shifted up 1.

Do not turn this card into a full general transformations lesson; Functions already owns the general transformation rules.

### P1-TRI-02 — Exact values and related-angle symmetry

Teach the standard exact values for 0, π/6, π/4, π/3 and π/2 and how reference angles/quadrant signs generate related values.

Reviewed examples:
sin(5π/6) = 1/2.
cos(2π/3) = -1/2.

The key learner idea is:
same reference angle gives the same magnitude; the quadrant determines the sign.

### P1-TRI-03 — Principal values of inverse trig functions

Teach that inverse trig on a calculator returns one principal value, not every angle with that sine/cosine/tangent.

Principal-value intervals:
- sin⁻¹: [-π/2, π/2];
- cos⁻¹: [0, π];
- tan⁻¹: (-π/2, π/2).

Reviewed examples:
sin⁻¹(1/2) = π/6.
cos⁻¹(-1/2) = 2π/3.
tan⁻¹(1) = π/4.

This skill is about interpreting the calculator/inverse function correctly, not yet enumerating every interval solution; P1-TRI-05 owns interval completeness.

### P1-TRI-04 — Basic trigonometric identities

Only use the approved P1 core identities:

sin²x + cos²x = 1

tan x = sin x / cos x.

Reviewed application:

sin²x / (1 - cos x)
= (1 - cos²x) / (1 - cos x)
= 1 + cos x,

where the original denominator is non-zero.

Teaching emphasis:
- transform one side of an identity;
- use a known identity deliberately;
- factor/cancel only when algebraically valid.

Do not introduce addition, subtraction or double-angle identities.

### P1-TRI-05 — Simple trig equations on a stated interval

Teach the full solution process:
1. find a principal/reference angle;
2. use graph/quadrant symmetry and periodicity;
3. list every solution in the stated interval;
4. check interval endpoints and calculator mode.

Reviewed example:

sin x = 1/2,  0 ≤ x ≤ 2π

gives

x = π/6, 5π/6.

Alternative graph interpretation:
solutions are the x-coordinates where y=sin x intersects y=1/2 over the required interval.

## Learner-first standard

Each skill has four distinct variants:
- main: meaning + method + compact reviewed example;
- simple: lower cognitive load;
- alternative: genuinely different mental model;
- focus: quick checks and procedural traps.

Do not infer a personal misconception in static content.
Do not show internal IDs or implementation terminology.

## Trilingual parity

EN/RU/UZ must preserve:
- the same formulas;
- the same exact values;
- the same intervals;
- the same transformation parameters;
- the same solution sets;
- the same scope firewall.

Natural school-level phrasing is preferred over literal translation.

## Technical acceptance

- 15/15 new Block 6 cards.
- Three locales per skill.
- Total learner-first draft count after Block 6 = 87.
- Exact source-card component/skill/locale linkage.
- DRAFT and runtime OFF only.
- No addition/double-angle formula leakage.
- No internal IDs in learner-facing text.
- No legacy, entitlement or academic-state writes.
- Dedicated Block 6 CI gate GREEN.

## Runtime decision

NO runtime switch in Block 6.
The provider-backed topic explanation remains the production default until the global 243/243 reviewed runtime-ready gate is satisfied.
