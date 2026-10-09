# Economics 9708 — Stage 1, A Level source-scope batch v9

**Date:** 2026-10-09. **Decision:** Stage 1 stays IN_PROGRESS; **no academic approval and no learner-facing publication**.

## Authority and immutable product boundary

- **Official Cambridge scope:** [Cambridge International AS & A Level Economics 9708, examinations 2026–2028, v2](https://www.cambridgeinternational.org/Images/697423-2026-2028-syllabus.pdf), A Level content printed pp. 24–34, especially §§7.1–11.6. A Level candidates additionally study AS topics; A Level-addition parent points must not silently become AS-only requirements.
- **User-supplied textbook:** Economics fourth edition, book Chapters 30–37, 39–41, 43, 46, 49–50, 52–53. Coursebook elaboration is learning support, not independent exam authority.
- **Approved seven-Tour teaching order:** Tour 4 = book Ch30–37, Tour 5 = Ch38–40, Tour 6 = Ch41–47, Tour 7 = Ch48–54. Changing a draft syllabus/skill ID **does not move a real Practice/Tour question**, change a question bank or rewrite any past attempts.
- **Product safety contract:** `docs/economics-9708-curriculum-practice-runtime-separation-contract-v1.md`. Keep distinct the *official syllabus subpoint*, *coursebook/Tour*, *provisional atomic learning action*, *immutable question ID with active pool membership*, and *approved versioned theory/Tutor sources*.

## Actual v9 delivered

Read and scoped the **first 28 medium-flagged A Level parent points** from prior queue v5 against numbered Cambridge requirements. Made **28 provisional source-led decisions**: **9 split into 18 candidate children**, **19 retained as one integrated teachable/assessable skill**. Net candidate change **+9**.

| Metric | v8 | v9 |
|---|---:|---:|
| Official numbered parent points represented | 253 | 253 |
| Distinct provisional candidate skill actions | 479 | **488** |
| Unreviewed one-to-one parent placeholders | 135 | **107** |
| Source-scoped decisions in this batch | — | 28 |
| Tentatively split parent points in batch | — | 9 |
| Tentatively retained integrated parent points | — | 19 |

**Latest register:** `docs/economics-9708-atomic-candidate-register-v9.csv`. **Line-by-line rationale, exact original and proposed action, tier, book chapter and Tour:** `docs/economics-9708-v9-source-checked-decision-log-v1.csv`. **Remaining work:** `docs/economics-9708-remaining-atomic-review-queue-v6.csv` (107 items; 43 heuristic score-2, 35 score-1, 29 score-0). Heuristics are *not* academic judgements.

### Source guardrails and corrections in v9

1. **7.1.1:** independent definition-and-calculation procedures for total and marginal utility; **7.1.4** remains one derivation of individual demand, not a fresh non-required calculus technique.
2. **7.2.1:** meaning of indifference curves and meaning of budget lines can be diagnosed separately; **7.2.2** is one integrated explanation of causes of changes to the budget constraint; do not confuse with normal/inferior/Giffen price and income effects in 7.2.3.
3. **7.3.2:** separate productive and allocative efficiency conditions. **7.3.4** requires the **definition** of dynamic efficiency, not another compulsory R&D evaluation.
4. **7.4.7:** applied use of costs and benefits, explicitly **without compulsory net present value calculation**.
5. **7.5.3–7.5.4:** distinguish long-run *production function* (all inputs variable, returns to scale) from long-run *cost function* (LRAC shape, minimum efficient scale); no mapping of evidence by chapter alone.
6. **7.7.5:** owner–manager principal-agent problem retained as one concept; **7.8.1:** profit-maximisation is its own purpose, not a blanket claim of mastery of oligopoly/competitive performance.
7. **8.2.2:** Cambridge requires difference between *equity and efficiency*; broad mandatory appraisal of government trade-offs would overstate this point. **8.2.4** only names the poverty trap.
8. **8.3.5:** wage and non-wage factors affecting labour supply split; **8.3.9** labour-market determination of wage differentials kept integrated.
9. **9.1.3** inflationary/deflationary national-income gaps and **9.2.2** positive/negative output gaps are related but **not automatically the same source skill**. **9.3.5** pattern/trend interpretation and **9.3.7** policy effectiveness remain different abilities.
10. **10.2.2–10.2.4:** Cambridge names one relationship at each official point (BOP/inflation, growth/inflation, growth/BOP). Keep integrated; do not invent three new policy-subcourse requirements.
11. **11.2.2:** fixed versus managed exchange-rate determination each has an independent explanatory mechanism; **11.2.4** compares exchange-rate changes across systems; **11.2.5** separately requires Marshall–Lerner and the J-curve.
12. **11.3.1:** classification of economies by development level; avoid compulsory extra stage theories. **11.5.6:** role of the IMF only; conditional lending details are context, not separately compulsory Cambridge skills. **11.6.3:** trade creation and diversion are two different integration effects.

### Preventing methodology/progress duplication

**NEW:** `docs/economics-9708-v9-cross-parent-overlap-guard-v1.csv`, documenting **14 pairs of related official parent points** with their precise scope boundary. Each is tagged **KEEP_DISTINCT_PENDING_CANONICAL_REVIEW**, **not an automatic merge**. Especially protect (a) total/marginal utility vs derived demand; (b) budget-line meaning vs changes vs price effects; (c) production vs cost measures; (d) inflationary/deflationary national-income gaps vs output gaps; (e) exchange-rate regimes vs rate changes vs J-curve/Marshall–Lerner; and (f) IMF vs World Bank.

This guard prevents a future code integration from assuming that a shared question or parent-level theory draft proves mastery of multiple child skills. **No question_id, score, attempt, progress, Tour membership or active/inactive status has been touched.**

## Readback verification — PASS, not stage approval

All four new v9 source artifacts were fetched back from GitHub. Automated structural assertions passed:

- **488** unique provisional keys, **253** represented Cambridge numbered parent points, correct existing book Ch ↔ Tour ranges;
- **28** logged decisions, 9 split and 19 retained, **107** still-unreviewed points exactly matched to queue;
- **14** source-existing parent pairs in overlap guard;
- **zero** draft actions permitted in runtime; **all exact question-answer mapping remains `NONE_VERIFIED`**.

**Still BLOCKED:** confirm canonical minimal independent skill denominator after remaining 107 parents and overlap review; expert academic and translator approval; exact question-to-skill and protected correct-answer evidence; mobile SVG multilingual rendering and accessibility; copyrighted-source and learner-safety QA. Earlier 40 parent-topic source drafts (120 EN/RU/UZ cards, 480 variants) are **not** independently approved cards for 488 atomics.

## Live production freeze

The original approved Economics Tour Map had 60 Practice questions/Tour while the production state (previous read-only check) has 70 active questions/Tour, 490 active references, plus seven inactive Tour 2 associations. This remains an architect-held policy discrepancy, **not** a license to remove/move questions or alter progress.

No Vercel calls, builds, deployments, merges, AI activation, provider generation, production database writes or end-user changes. Only isolated draft GitHub files and the service-only private Stage 1 progress metadata are permitted. Chemistry and Biology stay queued. Informatics stays deferred.

**Stage 1 status: IN_PROGRESS.** Next: source-review remaining 107 parents, then reconcile child duplicates and prepare a defensible denominator; do not launch learner content until separate approval.
