# Exam Prep Tutor Content — Block 14 Normal Distribution Review

Status: AUTHORING REVIEW
Scope: P5-NOR-01 and P5-NOR-03...06, EN/RU/UZ
P5-NOR-02: already covered by the learner-first Block 1 pilot
Runtime: OFF
Date: 2026-10-05

## Source and scope cross-check

Canonical owner: P5 only.
Official section: 5.5 The normal distribution.

Book mapping:
- P5-NOR-01,03,04,05 — Complete Probability & Statistics 1, Ch9 The normal distribution, pp. 147–171.
- P5-NOR-06 — Ch10 Normal approximation to binomial, pp. 173–179.

Existing approved source cards confirm:
- normal models use mean μ and variance σ² and a symmetric bell-shaped curve;
- standardisation uses Z=(X-μ)/σ;
- intervals/tails must be matched to the required region;
- inverse-normal reasoning is used for quantiles and unknown μ/σ;
- normal approximation to binomial uses mean np and variance np(1-p), only when appropriate, with continuity correction.

## Exact skill boundaries and reviewed examples

### P5-NOR-01 — Recognising and sketching a normal model

Teach:
- notation X ~ N(μ,σ²);
- μ is the centre/mean;
- σ is the standard deviation, so variance is σ²;
- the curve is symmetric about μ;
- the sketch should show μ and useful locations such as μ±σ when relevant.

Reviewed example:

X ~ N(70, 8²).

Mean = 70.
Standard deviation = 8.
Variance = 64.

Useful sketch markers:
μ-σ = 62,
μ = 70,
μ+σ = 78.

Do not turn this card into probability calculation; P5-NOR-03 owns direct probabilities.

### P5-NOR-03 — Direct normal probabilities

Teach:
- translate the event into an interval/tail;
- standardise boundaries;
- use the correct region;
- use symmetry/complements where useful.

Reviewed example:

X ~ N(100, 15²).

Find P(85<X<115).

The boundaries give z=-1 and z=1, so

P(85<X<115)=P(-1<Z<1)≈0.6827.

Teaching emphasis:
draw/visualise the required region before using table/calculator.

### P5-NOR-04 — Inverse normal quantiles

Teach:
- a probability/percentile is given;
- inverse normal returns the boundary that leaves that area to the left, unless the tool is configured otherwise;
- convert between z and X scales when needed.

Reviewed example:

X ~ N(50,10²).

The 90th percentile has left-tail area 0.90.
For the standard normal, z≈1.282.

x = 50 + 1.282(10)
≈ 62.82.

Teaching emphasis:
distinguish a probability from the x-value that produces it.

### P5-NOR-05 — Finding unknown μ and/or σ

Teach:
- convert probability conditions into z-equations;
- one unknown generally needs one independent condition;
- two unknowns need two independent conditions.

Reviewed example:

P(X<44)=0.1587
and
P(X<56)=0.8413.

These correspond to z=-1 and z=1.

Therefore

(44-μ)/σ=-1
(56-μ)/σ=1.

Solving gives

μ=50,
σ=6.

Teaching emphasis:
attach the correct sign and tail to each z-value before solving algebraically.

### P5-NOR-06 — Normal approximation to binomial

Teach:
- first confirm the normal approximation is appropriate;
- for X~B(n,p), use approximate normal mean np and variance np(1-p);
- translate discrete integer boundaries to the continuous normal model with continuity correction;
- then standardise and find the required probability.

Reviewed example:

X ~ B(100,0.4).

Approximate with

Y ~ N(40,24).

For P(X≤45), apply continuity correction:

P(X≤45) ≈ P(Y<45.5).

Then

z=(45.5-40)/√24≈1.123,

so

P(X≤45)≈0.8692.

Teaching emphasis:
continuity correction belongs at the discrete-to-continuous boundary translation, before standardisation.

## Learner-first standard

Each skill gets four genuinely distinct variants:
- main = meaning + method + reviewed example;
- simple = lower cognitive load;
- alternative = different mental model;
- focus = compact checks/traps.

Static content does not infer learner-specific mistakes.
No internal IDs or implementation terminology appear learner-facing.

## Trilingual parity

EN/RU/UZ must preserve:
- the same distributions and parameters;
- the same z-values;
- the same intervals/tails;
- the same continuity-correction boundary;
- the same final numerical results;
- equivalent notation and difficulty.

## Technical acceptance

- 15/15 new Block 14 cards.
- Three locales per new skill.
- P5-NOR-02 remains exactly the existing three-locale Block 1 card set.
- Total learner-first draft count after Block 14 = 243.
- Total learner-first canonical skills after Block 14 = 81.
- Exact source-card component/skill/locale linkage.
- DRAFT and runtime OFF only.
- No cross-component leakage.
- No legacy, entitlement or academic-state writes.
- Dedicated Block 14 CI gate GREEN.

## Runtime decision

NO automatic runtime switch in Block 14.

After 243/243 authoring exists, the next phase is a separate global content/governance review:
- verify 243/243 trilingual parity;
- cross-skill drift review;
- source-link audit;
- approve/runtime-ready transition only through a governed migration;
- then controlled-beta provider-free topic explanation canary.

Until that later gate passes, provider-backed topic explanation remains production default.
