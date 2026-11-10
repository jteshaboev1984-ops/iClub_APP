# Economics 9708 Stage 1 — Integrity / Coverage Report v1

**Audit date:** 2026-10-09. **Status:** DATA / STRUCTURE QA PASS; academic skill mapping STILL IN PROGRESS. This report is not a learner-facing release, not a tutor-card approval, and not an endorsement of all existing question content.

## Authoritative source
Official [Cambridge Economics 9708 2026–2028 v2](https://www.cambridgeinternational.org/Images/697423-2026-2028-syllabus.pdf); coursebook 4th ed. and approved 7-tour map are secondary. AS topics 1.1–6.5; A Level adds 7.1–11.6. Distinguish **numbered syllabus subpoints** from eventual **atomic teachable iClub skills**.

## Machine-checked stage 1 evidence

| Tour | Level | Numbered syllabus subpoints accounted for | Subpoints with at least one selected current Practice candidate | Subpoints without a selected candidate (NOT proven coverage gaps) |
|---:|---|---:|---:|---:|
| 1 | AS | 51 | 37 | 14 |
| 2 | AS | 46 | 35 | 11 |
| 3 | AS | 34 | 29 | 5 |
| 4 | A Level additions | 47 | 36 | 11 |
| 5 | A Level additions | 17 | 15 | 2 |
| 6 | A Level additions | 33 | 23 | 10 |
| 7 | A Level additions | 25 | 17 | 8 |
| **Total** | | **253** | **192** | **61** |

- Seven draft matrices enumerate **253 distinct official numeric identifiers / 253 expected / missing 0 / extra 0 / duplicates 0**.
- All selected Practice IDs in the seven matrices were validated as members of their **own subject + active pool + correct tour**. That is **structural referential QA only**; no proof of skill-level, language, correctness or mark-scheme correspondence.
- 490 Economics Practice links: 458 **single numbered chapter**, 24 **ranged chapters** (all in Practice Tour 7), and 8 **without parsable chapter**. These types must remain separate in future mapping.
- 140 Season 2 Tour question links already exist, but they were **not used as candidates for active Tour AI**. Any further analysis must obey protected assessment and archive/review restrictions.
- Chapter 45 has 11 Practice Tour 6 items but no Season 2 Tour 6 question; this is a **sampling discrepancy for academic review**, not justification for altering existing Tours.
- Prototype split of five wide A Level subpoints into **45 preliminary distinct learner actions** is filed in `docs/economics-9708-atomic-skill-split-prototypes-v1.md`. This is a design demonstration, not final total skills.

## Priority REVIEW findings, non-destructive
1. **AS ⇄ A Level leakage:** Tour 2 Practice Q2537, Q2538 (A Level Marshall–Lerner/J-curve), Q2533/Q2543 (A Level multiplier), Q2540 (A Level MV=PT), possibly other questions.
2. **Question `book_ref` misclassification even when chapter is numeric:** Tour 1 Q1080 fixed cost under Ch8 but official A Level 7.5; Q1081 allocative efficiency Ch11 but A Level 7.3; Q1136 public good under Ch1 but official AS 1.6 / Ch6.
3. **Ranged refs are not canonical crosswalks:** Ch48–49 Marshall–Lerner/J-curve maps to 11.2.5; Ch52–53 trade creation/diversion maps to 11.6.3.
4. **AS concepts embedded in A Level pool:** Tour 7 Ch52 Q5406/Q5439 are terms-of-trade concepts (official AS 6.1.3); Ch53 Q5400 and Q5437 are protectionism basics (official AS 6.2), although more complex evaluations can legitimately reinforce later content.
5. **Zero selected candidates in this first pass** must be triaged with Season 2 and full-banked questions, not treated as certain question shortages. Notably: 7.3.3 Pareto, 7.4.6 moral hazard, 8.3.10 economic rent, 9.4.7–9.4.8 liquidity preference/interest theory, 10.2.5 expectations-augmented Phillips, 11.3.3 full MEW/MPI/Kuznets and 11.5.6–11.5.7 IMF/World Bank.
6. Tour 7 `book_ref` sometimes includes Ch54, the book's assessment-methodology chapter. It is **not** a standalone 54th official numbered content topic.

## Academic completeness: what is NOT yet proven
- Exact scope per individual question by full stem, options, correct answer, and trilingual explanation.
- Whether candidate question links assess all concepts under each subpoint, and enough diagram/calculation/reasoned evaluation evidence for Cambridge Papers 1–4.
- Independent academic proof and complete versioned canonical skill denominator for all 253 parents.
- Original non-copied RU/UZ/EN theory cards, learner-first Tutor variants, diagnoses, or runtime source-completeness.
- Global/Practice AI activation; intentionally prohibited pending separate release gate.

## Next non-runtime actions
1. Prioritise the 61 subpoints without selected candidate links, inspect all existing eligible questions in approved academic read-only processes, and classify `candidate`, `verified`, `insufficient_evidence`, `outside_level`.
2. Complete parent-to-atomic-skill decomposition across all 253, with source/level/PR evidence and original content only after QA.
3. Independent educator/architect decision on out-of-scope and mis-tiered legacy questions; preserve history and never repair in place.
4. Review academic integrity and language consistency of every proposed skill before generating the governed source/Tutor cards.

## Production and cost controls
- No mutations of production questions, Practice/Tours, students, scores, attempt history, ratings, localStorage or entitlements.
- No AI runtime change, no Vercel calls/builds/deployments, no preview costs intentionally incurred.
- Working branch `feat/subject-ai-content-expansion-20261008`; Draft PR #337, no automatic merge.
