# Economics 9708 — Trilingual source/Tutor editorial draft ledger v2

**Date:** 2026-10-09 | **Status:** ALL 21 PRIORITY EVIDENCE-GAP TOPICS DRAFTED; **NOT academically approved, NOT live**.

Official curriculum: Cambridge International AS & A Level Economics 9708, exams 2026–2028, Version 2, subject-content pages 15–34. Scope reference: user-supplied 4th-edition Economics coursebook. Original learner examples authored for iClub; no textbook passages, past-paper questions or protected answer keys reproduced.

## Produced files and topics

| Source package | Official numbered syllabus points | Topic count |
|---|---|---:|
| `docs/economics-9708-trilingual-theory-tutor-pilot-v0.json` | `3.2.5`, `7.3.3`, `8.3.10` | 3 |
| `docs/economics-9708-trilingual-theory-tutor-batch2-v0.json` | `1.6.1`, `7.5.7`, `7.7.4`, `9.3.3`, `11.5.7` | 5 |
| `docs/economics-9708-trilingual-tutor-batch3a-v0.json` | `2.2.5`, `2.2.6`, `2.5.4` | 3 |
| `docs/economics-9708-trilingual-tutor-batch3b-v0.json` | `4.3.4`, `4.3.10`, `4.3.11`, `6.3.4` | 4 |
| `docs/economics-9708-trilingual-tutor-batch3c-v0.json` | `7.2.3`, `7.5.1`, `7.5.8` | 3 |
| `docs/economics-9708-trilingual-tutor-batch3d-v0.json` | `7.8.4`, `10.3.3`, `11.2.1` | 3 |
| **TOTAL** | **21 distinct official syllabus point IDs** | **21** |

Each topic includes **EN, RU, UZ** and **4 distinct original explanation variants** (main, simpler, alternative, understanding check) per locale.

**Totals: 21 topics × 3 locales = 63 unpublished locale records; 63 × 4 explanations = 252 unpublished explanatory variants.** Some later batches also include independently authored worked examples and English diagram blueprints for subsequent graph rendering and mathematical checking. An English diagram blueprint is **not** an approved graph or localised visual.

## Focused quality check — results
- All six versioned content packages fetched from the GitHub working branch.
- All 21 expected official point IDs present, each with exactly three locale codes (EN/RU/UZ), no duplicate point-locale pairs.
- All 63 records have real topic titles and all four explanations; no empty explanation fields or short placeholder labels.
- All 63 records have `runtime_allowed=false`; none marked academically approved.
- A misaligned title/explanation-field structure in the **earlier second batch** was corrected on the same isolated feature branch before publication; exact prior state remains traceable in Git history.
- **Structure and cardinality QA PASS; academic correctness, formula conventions, localisation, rights and exam-quality QA NOT YET PASSED.**

## Next actual implementation work (not another global audit)
1. **Targeted academic review of 21 topic drafts**, especially PED straight-line formula/point elasticities; surplus shifts; AD/AS curves; indifference diagram with substitution and income effects; TR/AR/MR calculations; nominal/real/trade-weighted exchange-rate quotation directions.
2. Render and independently validate the graph blueprints **before** learner use; include correct EN/RU/UZ axis labels and legible mobile diagrams (390px viewport) when UI integration is authorised.
3. Address **18 partially evidenced official subpoints** in `docs/economics-9708-61-evidence-gap-triage-v1.csv`, prioritising precise distinctions: liquidity preference vs liquidity trap, expectations-augmented vs short-run Phillips curve, calculation vs interpretation of Gini, and subsidy incidence.
4. Resolve **1 historically mis-tiered candidate**, official 9.4.3 quantity of money; do not alter historical Practice/Tour rows or learner outcomes.
5. Complete the still-open **atomic skill** decomposition and final question-to-skill QA; do not treat 21 drafted parent explanations as exhaustive mastery of all atomic child skills.
6. Only after separate user release approval may new versioned sources be integrated; do not merge automatically.

## Production, privacy and cost safeguards
**No Vercel API/build/deployment, no provider AI generation calls, no changes to learner data, protected question banks, answers, Practice or Tours, Exam Prep evidence, certificates, ratings, payments, localStorage, role privileges or UI flags.** This is GitHub draft source and private Supabase workplan tracking, nothing learner-facing.
