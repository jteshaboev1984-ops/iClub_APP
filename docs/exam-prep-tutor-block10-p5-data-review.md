# Exam Prep Tutor Content — Block 10 P5 Representation of Data Review

Status: AUTHORING REVIEW
Scope: P5-DAT-01…10, EN/RU/UZ
Runtime: OFF
Date: 2026-10-05

## Source and scope cross-check

Canonical owner: P5 only.
Official section: 5.1 Representation of data.
Canonical source map: P5-DAT-01…10.
Book mapping:
- Complete Probability & Statistics 1, Ch2 Measures of location and spread, pp. 14–29;
- Complete Probability & Statistics 1, Ch3 Representation of data, pp. 34–59;
- P5-DAT-01 and P5-DAT-08 span both chapters.

Existing approved theory source cards confirm the required P5 ideas:
- choose a display that matches data type and purpose;
- stem-and-leaf preserves individual values;
- box plots expose median, quartiles and spread;
- histogram height is frequency density, while bar area represents frequency;
- cumulative-frequency graphs support quartiles, percentiles and proportions;
- compare data using both location and spread;
- keep mean/standard-deviation conventions consistent for raw, grouped, coded and combined data.

## Exact learner-facing boundaries

### P5-DAT-01 — Choosing a data representation
Teach the decision, not construction details:
- stem-and-leaf when individual values should remain visible;
- box plot for compact median/quartile/spread comparison;
- histogram for continuous grouped data, especially unequal class widths;
- cumulative-frequency graph for quartiles, percentiles and proportions.
A good choice must match both data type and the question being asked.

### P5-DAT-02 — Stem-and-leaf diagrams
Reviewed example data:
12, 14, 17, 21, 21, 24, 29.
Key: 1|2 means 12.
Leaves must be ordered and repeated values kept.

### P5-DAT-03 — Box-and-whisker plots
Reviewed five-number summary:
minimum 4, Q1 7, median 10, Q3 15, maximum 20.
IQR = 8.
Teach construction/reading and comparison using median plus spread.
If a question supplies an outlier rule or marked outliers, interpret them, but do not invent an outlier convention.

### P5-DAT-04 — Histograms and frequency density
Reviewed unequal-width example:
0–10 with frequency 20 -> density 2;
10–30 with frequency 30 -> density 1.5.
Teach:
frequency density = frequency / class width.
Bar area, not height alone, corresponds to frequency.

### P5-DAT-05 — Cumulative frequency
Reviewed total frequency N=80:
Q1 at cumulative frequency 20;
median at 40;
Q3 at 60;
90th percentile at 72.
Teach how to move from a target cumulative frequency to the corresponding data value on the graph.

### P5-DAT-06 — Mean, median and mode
Reviewed raw data:
2, 4, 4, 7, 8.
Mean = 5, median = 4, mode = 4.
Teach what each measure represents and that grouped-data means use class midpoints as estimates where appropriate.
Selection of measure must be tied to the data/purpose.

### P5-DAT-07 — Range, IQR and standard deviation
Teach:
range = maximum - minimum;
IQR = Q3 - Q1;
standard deviation measures spread about the mean using all values.
Reviewed quartile example:
Q1=4, Q3=10 -> IQR=6.
Interpret larger spread measures as greater variability, while respecting the convention supplied/used in the course.

### P5-DAT-08 — Comparing data sets
Reviewed comparison:
Set A: median 52, IQR 8.
Set B: median 48, IQR 14.
Conclusion:
A has the higher typical value and smaller spread.
Contextual wording must mention both location and spread rather than only saying one set is “better”.

### P5-DAT-09 — Mean and standard deviation from totals
Reviewed summary totals:
n=5, Σx=30, Σx²=220.
Mean = 6.
Variance = 220/5 - 6² = 8.
Standard deviation = √8.
For grouped data, use the appropriate frequencies/midpoints and clearly treat results as estimates where grouping requires it.

### P5-DAT-10 — Coded and combined data
Reviewed combined-data example:
Group A: n=20, mean=50 -> total 1000.
Group B: n=30, mean=60 -> total 1800.
Combined mean = 2800/50 = 56.

Reviewed coding relation:
y=(x-50)/10, so x=10y+50.
If coded mean ȳ=1.2, then x̄=62.
Teach transforming totals/summary measures carefully rather than reconstructing every raw value.

## Learner-first standard

Each skill receives four distinct variants:
- main: meaning + method + one compact reviewed example where useful;
- simple: reduced cognitive load;
- alternative: different mental model/representation;
- focus: quick checks and procedural traps.

Static cards never infer a personal misconception.
No internal skill IDs or implementation vocabulary appears in learner-facing text.

## Trilingual parity

EN/RU/UZ must preserve:
- the same examples and numbers;
- the same formulas;
- the same conclusions;
- the same graph/summary interpretation;
- equivalent caveats about grouped estimates and conventions.

Natural school-level language is preferred over literal translation.

## Technical acceptance

- 30/30 new Block 10 cards.
- Three locales per skill.
- Existing P5-NOR-02 pilot remains exactly one 3-locale card set.
- Total learner-first draft count after Block 10 = 168.
- Total covered skills after Block 10 = 56.
- Exact source-card component/skill/locale linkage.
- DRAFT and runtime OFF only.
- No P1/P5 cross-component leakage.
- No legacy, entitlement or academic-state writes.
- Dedicated Block 10 CI gate GREEN.

## Runtime decision

NO runtime switch in Block 10.
Provider-backed topic explanation remains production default until the global 243/243 reviewed runtime-ready gate is satisfied.
