# Exam Prep Tutor Content — Block 10A Data Representation Review

Status: AUTHORING REVIEW
Scope: P5-DAT-01...05, EN/RU/UZ
Runtime: OFF
Date: 2026-10-05

## Source and scope cross-check

Canonical owner: P5.
Official section: 5.1 Representation of data.

Canonical source mapping:
- P5-DAT-01 — Complete Probability & Statistics 1, Chapters 2–3, pp. 14–59;
- P5-DAT-02...05 — Complete Probability & Statistics 1, Chapter 3 Representation of data, pp. 34–59.

Approved theory source cards confirm:
- choose a display by data type and purpose;
- stem-and-leaf preserves individual values;
- box plots show median, quartiles and spread;
- histogram bar area represents frequency, so unequal widths require frequency density;
- cumulative-frequency graphs support quartiles, percentiles and proportions.

## Exact learner-facing boundaries

### P5-DAT-01 — Choosing a data display

Teach a decision, not a memorised list:
- exact individual values visible → stem-and-leaf;
- compact comparison of centre/spread → box plot;
- continuous grouped data, especially unequal class widths → histogram;
- quartiles/percentiles/proportions from accumulated counts → cumulative-frequency graph.

The explanation must mention why a display is suitable and what information it hides or preserves.

### P5-DAT-02 — Stem-and-leaf diagrams

Reviewed data:
12, 14, 17, 21, 21, 25, 32.

Display:
1 | 2 4 7
2 | 1 1 5
3 | 2
Key: 2 | 5 means 25.

Teaching emphasis:
- sort leaves;
- preserve duplicates;
- include a key;
- each observation remains recoverable.

### P5-DAT-03 — Box-and-whisker plots

Reviewed five-number summary:
minimum 4, Q1 8, median 12, Q3 18, maximum 25.

Therefore:
IQR = 18-8 = 10,
range = 25-4 = 21.

Teaching emphasis:
- box from Q1 to Q3;
- median line inside box;
- whiskers to the appropriate extremes under the stated convention;
- if an outlier convention is supplied, apply that convention consistently rather than inventing another rule.

### P5-DAT-04 — Histograms and frequency density

Reviewed unequal-width example:
0<t≤10, frequency 20 → class width 10, density 2.
10<t≤30, frequency 30 → class width 20, density 1.5.

Core relation:

frequency density = frequency / class width.

Teaching emphasis:
bar area, not bar height alone, represents frequency.

### P5-DAT-05 — Cumulative frequency

For N=80 observations:
- Q1 is read at cumulative frequency 20;
- median at cumulative frequency 40;
- Q3 at cumulative frequency 60;
- 75th percentile also corresponds to cumulative frequency 60.

For a proportion, read the cumulative count from the graph and divide by N.

Teaching emphasis:
the vertical axis is accumulated count; quartile positions are fractions of total frequency.

## Learner-first standard

Every skill has four distinct variants:
- main: meaning + method + compact example;
- simple: lower cognitive load;
- alternative: another mental model;
- focus: quick checks/common traps.

Static content does not infer a personal error and does not expose internal IDs or governance terminology.

## Trilingual parity

EN/RU/UZ preserve:
- the same examples;
- the same frequencies and class widths;
- the same five-number summary;
- the same cumulative-frequency positions;
- equivalent mathematical meaning and level of help.

## Technical acceptance

- 15/15 new Block 10A cards.
- Three locales per skill.
- Total learner-first draft count after Block 10A = 153.
- Exact source-card component/skill/locale linkage.
- DRAFT and runtime OFF only.
- No legacy, entitlement or academic-state writes.
- Dedicated Block 10A CI gate GREEN.

## Runtime decision

NO runtime switch in Block 10A.
Provider-backed topic explanation remains production default until the complete 243/243 reviewed runtime-ready matrix is reached.
