# Exam Prep AI Tutor — Block 3 Functions Review v1

Status: AUTHORING REVIEW
Scope: P1-FUN-01…08, EN/RU/UZ
Runtime: OFF
Date: 2026-10-04

## Source/scope cross-check

Canonical owner: P1 only.
Official section: 1.2 Functions.
Book mapping: Complete Pure Mathematics 1, Ch2 Functions and transformations, pp. 24–42.
Every Tutor Card remains linked to its existing approved/runtime theory source card.

The source-card family is intentionally broader than each canonical node, so each Tutor Card must narrow the explanation to the exact skill below.

## Exact skill boundaries and teaching choices

### P1-FUN-01 — Function language: domain, range, one-one, inverse, composition
Teach the vocabulary as one mapping system:
- domain = allowed inputs;
- range = outputs actually produced;
- one-one = no two allowed inputs give the same output;
- inverse reverses a one-one mapping;
- composition feeds one function's output into another.
Example anchor: f(x)=2x+1.
Do not turn this card into a full inverse/composition calculation lesson; those have their own skills.

### P1-FUN-02 — Range with a restricted domain
Example anchor: f(x)=x² on -2≤x≤3 gives 0≤f(x)≤9.
Teaching emphasis: use the restricted input interval and check turning points/endpoints; do not assume the unrestricted range.

### P1-FUN-03 — Composite functions
Example anchor:
f(x)=2x+1, g(x)=x²
f(g(x))=2x²+1
g(f(x))=(2x+1)².
Teaching emphasis: order matters; the output of the inner function must be allowed as input to the outer function.

### P1-FUN-04 — One-one condition and inverse function
Example anchor:
f(x)=2x+3 ⇒ f⁻¹(x)=(x-3)/2.
Counterexample idea: x² is not one-one on all real numbers; a restriction such as x≥0 is needed before taking a single-valued inverse.
Do not teach inverse-graph reflection here beyond a brief connection; P1-FUN-05 owns that.

### P1-FUN-05 — Graph of an inverse
Example anchor:
If (1,5) lies on y=f(x), then (5,1) lies on y=f⁻¹(x).
Teaching emphasis: swap coordinates; reflection in y=x.
Explicitly distinguish f⁻¹(x) from 1/f(x).

### P1-FUN-06 — Graph translations
Example anchor:
y=x² → y=(x-3)²+2 is right 3, up 2.
Rules:
y=f(x)+a: vertical shift by a.
y=f(x-a): horizontal shift right by a.
Teaching emphasis: horizontal sign appears opposite.

### P1-FUN-07 — Graph reflections
Rules:
y=-f(x): reflect in x-axis, (x,y)→(x,-y).
y=f(-x): reflect in y-axis, (x,y)→(-x,y).
Example point anchor: (2,6).

### P1-FUN-08 — Stretches/compressions and simple combinations
Rules:
y=af(x): vertical scale factor |a|.
y=f(bx): horizontal scale factor 1/|b|.
Example point anchors:
(1,1) → (1,2) under y=2f(x);
(1,1) → (1/2,1) under y=f(2x).
Combination anchor:
y=2f(x-3)+1 maps (x,y)→(x+3,2y+1).
Teaching emphasis: transformations outside f act on y directly; transformations inside f act on x inversely.

## Trilingual parity

EN/RU/UZ must preserve:
- the same formulas;
- the same example values;
- the same domains/ranges;
- the same transformation directions/factors;
- the same point mappings;
- equivalent warning strength.

Natural school-level language is preferred over literal translation.

## Premium learner check

Each main explanation should be understandable in about one mobile minute and should not repeat the whole Functions chapter.
Simple, alternative and focus variants must each solve a different learner need.

## Technical acceptance before merge

- 24/24 new Block 3 rows exist.
- 3/3 locales for each of eight Functions skills.
- Exact component/skill/locale source-card linkage.
- All new rows remain DRAFT/runtime OFF.
- Total learner-first draft count after Block 3 = 48.
- Exact worked-example parity across EN/RU/UZ.
- No internal IDs or implementation wording in learner-facing content.
- No literal backslash-n formatting.
- No legacy/academic-state/entitlement writes.
- Full repository CI GREEN.

## Runtime decision

NO runtime switch in Block 3.
Provider-backed theory explanation remains production default until the global 243/243 review gate is satisfied.
