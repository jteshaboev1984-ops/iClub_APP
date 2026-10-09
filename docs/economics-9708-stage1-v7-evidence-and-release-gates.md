# Economics 9708 — Stage 1 source-based atomic skill review, batch v7

**Date:** 2026-10-09 | **Stage:** 1 IN PROGRESS | **Promotion:** BLOCKED | **Status:** teacher-review candidates only, no released content

## Sources and fixed academic hierarchy
- **Assessment authority:** [Cambridge International AS & A Level Economics 9708 syllabus, 2026–2028, version 2](https://www.cambridgeinternational.org/Images/697423-2026-2028-syllabus.pdf), subject content printed pages 15–34, sections referenced by their official point identifiers.
- **Secondary explanatory source:** user-provided *Economics for Cambridge International AS & A Level*, fourth edition, especially Ch13, 17–19, 21, 23–25, 28, 30, 33–36, 40, 43–44, 47, 50–52. Chapter title alignment checked using actual extracted textbook contents and sample chapter 33/44 learning intentions; no copied questions, original figures or passages.
- **Tour scope:** user-provided `Tour Map v1.0 — Economics (по книге) для 7 туров.docx`: Tour 1 Ch1–11; Tour 2 Ch12–20; Tour 3 Ch21–29; Tour 4 Ch30–37; Tour 5 Ch38–40; Tour 6 Ch41–47; Tour 7 Ch48–54. Book Ch54 is exam preparation, not a new Cambridge syllabus topic. The Tour Map gives teaching placement, **not permission to change** existing production pool/assessment membership.
- **Agreed implementation order:** `docs/subject-ai-content-expansion-master-plan-v1.md`. Economics must pass Stage 1 before Stage 2/3 learner cards are deemed source-backed; Chemistry then Biology, Informatics deferred.

## Actual completed academic decisions

This pass reviewed the first **32** remaining medium-priority `one_to_one_placeholder` parents in the previous `v6` register, against numbered official syllabus items and textbook chapter boundaries. Each received a rationale and source marker, captured individually in:

**`docs/economics-9708-v7-source-checked-decision-log-v1.csv`** (32 exact point rows with old draft action, source, level, chapter, Tour, new child keys, scope decision, caution and unapproved flags).

- **19** parent placeholders judged compound and converted into **45** provisional child actions.
- **13** kept **one integrated learner action**; retaining does not mean academically approved.
- Net candidate increase **+26** (436 → **462**). All **253** numbered syllabus parents remain represented.
- **155** one-to-one placeholders remain without individual scope decision; they are enumerated in `docs/economics-9708-remaining-atomic-review-queue-v4.csv`. Current heuristic priority distribution: **48 medium, 107 lower**. A lower score is not academic approval.
- **Latest provisional register:** `docs/economics-9708-atomic-candidate-register-v7.csv`. Historical v4/v5/v6 source state retained in the working Git branch; no previous production key replaced.

### Explicit examination-scope protections
1. **AS 5.1.1** names three government macroeconomic policy objectives but explicitly says conflicts/trade-offs are **not required** at that level. Three separate objective analyses are proposals; no AS conflict testing imported from A Level.
2. **AS 5.3.2** names interest rates, money supply and credit regulations. The monetary policy expansionary vs contractionary distinction is a **separate official 5.3.3** and was retained as one comparison.
3. **AS 5.4.3** supplies training, infrastructure and technology as **examples** of supply-side tools, not an exhaustive set of three mandatory standalone student skills; kept integrated.
4. **AS 6.1.2** requires the **trading possibility curve**, alongside trade benefits. **AS 6.1.3** has three separate dimensions: measuring, reasons for changes in and consequences of terms of trade.
5. **AS 6.4.3** only distinguishes floating-rate depreciation and appreciation. Any domestic output, employment and AD/AS consequences are assessed separately in **6.4.5**. Fixed-rate devaluation/revaluation is A Level, not this item.
6. **A Level 7.4.1/7.4.2** separately contain **total** (SC=PC+EC, SB=PB+EB) and **marginal** (MSC=MPC+MEC, MSB=MPB+MEB) cost/benefit calculations; these are distinct candidate calculation types.
7. **A Level 7.4.4** explicitly considers positive/negative consumption/production externalities: four different diagram cases. **7.4.6** names asymmetric information and moral hazard; adverse selection may be an explanatory example but was **not** added as an extra mandatory official syllabus item.
8. **A Level 7.5.9** separately names normal, subnormal and supernormal profit definitions; **7.5.10** names supernormal/subnormal profit calculation.
9. **A Level 8.3.7** gives one combined competitive equilibrium wage/employment determination, not two independent market equilibria; **8.3.10** names transfer earnings, economic rent and influencing factors.
10. **A Level 9.4.2** requires **definition of money supply only**; the pre-existing candidate wording incorrectly added a price-level-change competency, which is now removed. A Level **9.4.3** is quantity theory (MV=PT), not an AS Tour 2 mastery requirement despite legacy misplaced practice Q2540 (question untouched).
11. **A Level 11.3.4** has two distinct comparison settings (through time and across countries), **11.4.3** differentiates employment-sector composition and trade composition, **11.5.2** separates trade and investment without duplicating FDI-specific 11.5.4.
12. **A Level 11.5.7** remains one institution-specific outcome: the World Bank's role. Detailed project examples are useful source teaching but not independently enumerated Cambridge requirements.

### Visual source QA
Existing draft `docs/economics-diagrams-v0/lorenz-gini-038.svg` contained an **incorrectly positioned textual label** `A=0.19` outside the shaded A region. Source vector text position corrected; area arithmetic unchanged: under Lorenz B=0.31, between equality and Lorenz A=0.19, hence Gini=1−2×0.31=0.38. Geometry of label against line coordinates was checked. **No actual rendered 390px mobile QA or multi-language in-image axis label QA has been performed. Do not release the SVG.**

## Stage-1 gates remaining
- **155** parent decisions; each requires the actual numbered syllabus section and textbook context, not keyword-only decomposition.
- Reconcile potential duplicate/synonymous candidates across different official parent points and produce a defensible final canonical skill denominator rather than using provisional **462**.
- For each final atomic skill, distinguish **verified precise question+answer mapping**, partial topic association, and missing assessment source. In this draft **every key still has `verified_precise_question_ids=NONE_VERIFIED`**; parent-question candidates cannot be inherited as child evidence.
- 40 source-parent overview drafts across EN/RU/UZ (120 locale drafts/480 text variants) are **not approved child-specific Tutor content**; final child-to-parent mapping and independent EN/RU/UZ academic/rights QA are required.
- Graph visual mobile rendering and accessibility, original worked examples, answer-key protected content and historical question-tier misplacements remain gated.
- Only separate user authorization can enable Stage 6 runtime integration. No deploy/merge implied by these documents.

**Operational safety:** no Vercel API calls, builds, previews or deploys. No existing learner or assessment, correct answers, question IDs, Practice/Tours, Exam Prep attempts/scores/mastery, user accounts, entitlements, certificates, payments, localStorage or AI flags modified. GitHub Draft PR only; private Supabase tracker metadata may be updated in place.
