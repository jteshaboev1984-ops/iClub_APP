# Mathematics Practice v2 — Practice 5 Binomial Expansion + Series QA Report

Date: 2026-10-06  
Branch: `work/mathematics-practice-v2-refresh-20261006`  
Scope: `P1-SER-01…P1-SER-05`  
Production data changed: NO

## Status

Practice 5 now has a complete **66-question** draft and has passed the first full bank-level mathematical/mechanical review.

It is **not approved for production publication yet**. Publication remains gated by evaluator hardening, secure server-side delivery/checking, final runtime QA and the already defined release process.

## Canonical coverage

- P1-SER-01 — positive-integer binomial expansion and requested terms/coefficients: 14
- P1-SER-02 — recognise arithmetic/geometric progressions from term structure: 10
- P1-SER-03 — arithmetic nth term / finite sum / inverse problems: 14
- P1-SER-04 — geometric nth term / finite sum / inverse problems: 16
- P1-SER-05 — convergence and sum to infinity: 12

Total: 66  
MCQ / input: 27 / 39  
Easy / Medium / Hard: 16 / 31 / 19

The bank stays inside P1 scope:
- positive-integer binomial only;
- no rational/negative-power approximation expansion;
- explicit AP/GP recognition;
- finite AP/GP work;
- `|r|<1` convergence and `S∞=a/(1−r)`.

## Mathematical/content review

The complete bank was re-read with the correct answer and explanation exposed.

Checks included:
- binomial coefficients and term indexing;
- powers/signs/multipliers in `(a+bx)^n`;
- coefficient-ratio and parameter problems;
- AP vs GP vs neither/both classification;
- `u_n=a+(n−1)d` and arithmetic finite sums;
- reverse AP problems using terms/sums;
- `u_n=ar^(n−1)` and finite GP sums;
- negative ratios and alternating signs;
- reverse GP problems from terms and sums;
- convergence `|r|<1`;
- sum-to-infinity direct, inverse and parameter-range problems;
- quadratic parameter convergence.

### Defects / weak patterns found and corrected

1. **MCQ position bias**
   - Initial authored bank had no correct D answers and a visible B-heavy pattern.
   - Entire MCQ bank was rebalanced by moving full option payloads together with their diagnostics.

Current 27-MCQ distribution:
- A = 7
- B = 7
- C = 7
- D = 6

No skill has a >40% correct-position concentration and the longest same-letter run is 2.

2. **Practice↔Tour 5 overlap**
   Several authored items were too close to existing Season 2 Tour 5 constructions and were redesigned:
   - Q294: direct x² coefficient → ratio of x²/x coefficients;
   - Q299: direct parameter-from-x² coefficient → parameter from coefficient ratio;
   - Q300: independent-term construction close to Tour → mixed product coefficient transfer;
   - Q306: direct exponent-from-one coefficient → exponent from relation between two coefficients;
   - Q332: direct GP 8th-term question → reverse first-term problem;
   - Q335: same non-consecutive GP ratio setup as Tour → combined term + finite-sum inverse problem.

No Tour item, Tour membership or Tour result was modified.

3. **Scope firewall**
   - Rational/approximation binomial expansion is excluded.
   - Binomial tasks use positive integer powers.
   - Convergence work is geometric-series convergence only.

## Deterministic diagnostics

A governed catalog of **27 diagnostic codes** was created for:
- binomial coefficient/index/power/sign/multiplier mistakes;
- AP/GP structural recognition;
- AP nth-term/sum/inverse conditions;
- GP nth-term/sum/ratio/negative-ratio conditions;
- convergence, infinity formula, denominator sign and parameter ranges.

Every authored wrong MCQ option has a deterministic diagnostic mapping and no correct option carries a diagnostic.

Some catalog codes remain unused in this first bank; they remain inactive catalog capacity and do not create learner diagnoses until an authored answer path explicitly supports them.

## Input evaluator compatibility

All 39 input contracts were checked against the current scalar Practice evaluator.

Result:
- false acceptance of rejected examples: **0**
- authored accepted examples currently rejected: **4**

All four failures are the same Unicode-minus normalization issue:
- Q296: `−40`
- Q312: `−1.5`
- Q315: `−2`
- Q334: `−0.25`

No content workaround was introduced.

## EN/RU/UZ review

All 66 questions contain EN/RU/UZ stems and explanations; all MCQ options are trilingual.

A mechanical numeric-symbol parity check found only ordering/word-form differences caused by sentence structure (for example Uzbek placing the term count later in the sentence). No mathematical-value contradiction was identified in that pass.

## AI source-card review

Production already contains approved/runtime-allowed original iClub theory cards for every `P1-SER-01…05` skill in EN/RU/UZ.

The English cards were inspected:
- SER-01 explicitly limits binomial work to positive integer powers and rejects rational/negative-power series;
- SER-02 covers AP/GP/neither recognition and negative/fractional ratios;
- SER-03 covers AP nth term, sum and inverse work;
- SER-04 covers GP nth term, finite sum, inverse work and negative ratios;
- SER-05 covers `|r|<1`, `S∞` and negative-ratio convergence.

For this bank, the existing approved cards are sufficient; no new AI source-card supplement is currently required.

## Gate result

| Gate | Result |
|---|---|
| 5 canonical Series skills covered | PASS |
| Positive-integer binomial firewall | PASS |
| AP/GP/convergence legacy gaps repaired | PASS |
| Mathematical bank review | PASS |
| MCQ mechanical structure | PASS |
| Primitive answer-position QA | PASS after rebalance |
| Deterministic diagnostics | PASS |
| EN/RU/UZ structural coverage | PASS |
| Practice/Tour 5 separation | PASS after six redesigns |
| Approved AI source coverage | PASS |
| Current production input evaluator | BLOCKED — Unicode minus normalization required |
| Production publication | NOT YET |

Next content block under the active plan is Practice 6 — Differentiation (`P1-DIF-01…07`).
