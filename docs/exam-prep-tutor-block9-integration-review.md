# Exam Prep Tutor Content — Block 9 Integration Review

Status: AUTHORING REVIEW
Scope: P1-INT-01...05, EN/RU/UZ
Runtime: OFF
Date: 2026-10-05

## Source and scope cross-check

Canonical owner: P1.
Official section: 1.8 Integration.
Canonical source nodes: P1-INT-01...05.
Existing approved theory source cards define the Paper 1 scope:
- integration as reverse differentiation;
- powers and (ax+b)^n, with n≠-1 where the power rule applies;
- constant of integration and boundary/point conditions;
- definite integrals, including the simple P1 endpoint-improper case;
- geometric area with sign/intersection splitting where needed;
- volume of revolution about a coordinate axis using π times the integral of radius squared.

Scope firewall:
- no integration by parts;
- no general substitution methods beyond reversing the linear-factor chain pattern;
- no logarithmic/exponential integration;
- no post-P1 trigonometric integration.

## Exact learner-facing boundaries

### P1-INT-01 — Antiderivatives

Core reverse power rule:

∫x^n dx = x^(n+1)/(n+1) + C, for n≠-1.

For a linear inside expression, compensate for its derivative.

Reviewed example:

∫[6x² + 4(2x+1)^3] dx

= 2x³ + 1/2(2x+1)^4 + C.

Teaching emphasis:
- integration reverses differentiation;
- increase the power by 1, then divide;
- for (ax+b)^n, account for the inner coefficient a;
- indefinite integrals need C.

### P1-INT-02 — Constant of integration

Reviewed example:

dy/dx = 6x - 4,

and the curve passes through (2,5).

Integrate:

y = 3x² - 4x + C.

Substitute (2,5):

5 = 12 - 8 + C,

so C=1.

Hence

y = 3x² - 4x + 1.

### P1-INT-03 — Definite integrals

A definite integral evaluates an antiderivative between limits.

Reviewed endpoint-improper example:

∫ from 0 to 4 of x^(-1/2) dx.

Because the integrand is undefined at 0, interpret the lower endpoint as a limit:

lim a→0+ [2√x] from a to 4
= lim a→0+ (4 - 2√a)
= 4.

Teaching emphasis:
- substitute upper minus lower;
- an improper endpoint needs the limiting step;
- the definite integral is signed accumulation.

### P1-INT-04 — Area between curves

Reviewed example:
y=x and y=x² between x=0 and x=1.

The upper curve is y=x.

Area
= ∫ from 0 to 1 of (x-x²) dx
= [x²/2 - x³/3] from 0 to 1
= 1/6.

Teaching emphasis:
top minus bottom; split the interval when the ordering changes; physical area must be positive.

### P1-INT-05 — Volume of revolution

Reviewed example:
y=x, 0≤x≤2, rotated about the x-axis.

Radius = y = x.

Volume

V = π∫ from 0 to 2 of x² dx
= π[x³/3] from 0 to 2
= 8π/3.

Teaching emphasis:
identify the radius from the stated axis, square it, use the correct limits and include π.

## Learner-first standard

Every skill has:
- main: meaning + method + one reviewed example;
- simple: lower cognitive load;
- alternative: another mental model;
- focus: quick checks and common errors.

No static card infers a personal mistake.
No internal IDs, mastery/evidence language or implementation terminology.

## Trilingual parity

EN/RU/UZ preserve:
- identical functions and limits;
- identical constants and points;
- identical antiderivatives;
- identical area/volume answers;
- identical endpoint condition and limiting result;
- the same Paper 1 scope.

## Technical acceptance

- 15/15 new Block 9 cards.
- Three locales per skill.
- Total learner-first draft count after Block 9 = 138.
- All 45 canonical P1 skills then have a learner-first EN/RU/UZ Tutor Card.
- One existing P5 pilot skill remains from Block 1.
- Exact source-card component/skill/locale linkage.
- DRAFT and runtime OFF only.
- No post-P1 integration methods.
- No legacy, entitlement or academic-state writes.
- Dedicated Block 9 CI gate GREEN.

## Runtime decision

NO runtime switch in Block 9.
Completing P1 is a content milestone only. The provider-backed topic explanation remains production default until the global 243/243 reviewed runtime-ready gate is satisfied.
