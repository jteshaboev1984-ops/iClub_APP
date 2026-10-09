# Economics 9708 — Stage 1 consolidated progress gate v2
**Date: 2026-10-09 | Decision: CONTINUE SOURCE MAPPING, DO NOT PROMOTE | User data and production unchanged**

## Authority and order
Approved master plan: `docs/subject-ai-content-expansion-master-plan-v1.md`. Authority: [Cambridge International AS & A Level Economics 9708 syllabus v2, examination 2026–2028](https://www.cambridgeinternational.org/Images/697423-2026-2028-syllabus.pdf). Scope and teaching resource: user's uploaded *Economics fourth edition* with 53 topical chapters and user's seven-Tour Economics Map.

**We remain in Stage 1**, determining the academically supportable syllabus → chapter → Tour → independent learning actions; no Stage 2/3 source-to-child promotion and no Stage 6 integration authorisation.

## Actual decisions completed in this pass
1. **Previous v4 academic source matrix grounded:** `docs/economics-9708-v4-focused-syllabus-alignment-audit-v1.csv` identifies all 23 Cambridge parent points decomposed in v4 (76 children), with exact parent chapter and risk category. For 9.4.7 the official syllabus says liquidity preference while textbook Ch44 elaborates its three reasons for money demand; 9.4.8 explicitly names two interest theories. These are source-based *proposals*, not teacher-approved children.
2. **Corrections to draft source logic** (all non-runtime):
   - `9.4.7`: distinction between **interest-driven movement along** money demand and **income-driven shift**.
   - `11.5.4`: FDI definition/consequences are required; a comparison with portfolio investment must not become a compulsory skill.
   - `2.2.5`: corrected Price/Quantity **reversed axis labels** in EN/RU/UZ diagram captions; corrected the PED SVG footer and the EN/RU/UZ AS learner explanations from derivative notation to straight-line gradient/percentage comparison.
3. **First 14 high-risk atomicity items actually resolved with source-based editorial decisions.** Of 14 identified by a word-based risk heuristic, **10 are truly compound** and were split into a total of **37 proposed independently diagnosable children**, while **four were deliberately retained as one integrated competence each**, all pending teacher sign-off:
   - Split: `6.3.4` (domestic/external current-account consequences), `7.5.1` (fixed/variable and TP/AP/MP/diminishing returns), `7.5.7` (internal/external diseconomies), `7.7.4` (cartel conditions/consequences), `9.3.2` (equilibrium/disequilibrium/hysteresis), `9.4.1` (definition/functions/characteristics of money), `10.1.1` (seven expressly listed macro policy objectives), `11.1.1` (three BOP accounts), `11.1.2` (five macro policies affecting BOP), `11.6.2` (four forms of integration, plus a combined comparison).
   - **Retain-one with explicit editorial rationale:** `7.3.6` (holistic causes of market failure), `9.2.4` (evaluate effectiveness of growth policies), `9.3.3` (single comparison of voluntary/involuntary unemployment), `10.3.3` (holistic evaluation of macro government failure). These may still be split after independent academic review; no final examiner approval implied.
   - Question candidates from superseded parent `-BASE` keys were **not copied as verified child-question coverage**.
4. **Master working register is now `docs/economics-9708-atomic-candidate-register-v6.csv`:** 253 distinct official numbered syllabus parent points → **436 provisional actions** with no duplicated keys; **187 remain unreviewed one-to-one placeholders**. The `v5` and `v4` registers remain in Git history for lineage. 436 is **not** an approved learning-skill denominator.
5. **Next untouched workload:** `docs/economics-9708-remaining-atomic-review-queue-v3.csv` contains precisely 187 remaining one-to-one placeholders, ranked using **heuristic flags only**, not graded academically. Distribution: 0 high (all 14 reviewed), 80 medium, 107 lower. No low-risk item is approved by default.

## Diagrams (source stored; learner release blocked)
Original saved SVG drafts remain in `docs/economics-diagrams-v0/`:
- `straight-line-ped.svg` (Q horizontal, P vertical; point elasticities 4/1/0.25).
- `lorenz-gini-038.svg` (original area-based grouped example Gini 0.38).
- `ad-as-short-run-equilibrium.svg` (AD/SRAS intersection, no unwarranted full-employment claim).
- `expectations-augmented-phillips.svg` (SR and LR models).

Captions `locale-captions-v0.json` have EN/RU/UZ correct axis metadata, but the source images remain primarily English, and **a 600×420 SVG downscaled to 390px may have unreadably small text**. No rendered mobile, mathematical teacher or bilingual graphic review was performed this pass. Do **not** display these SVGs in learner UI yet. They are reusable design source assets, not completed Stage 5 diagrams.

## Prohibitions and signoff gates
- All 436 provisional rows retain `verified_precise_question_ids=NONE_VERIFIED` and `runtime_allowed=false`. No fabricated child-to-question verification.
- Earlier 40 original trilingual parent-topic overview drafts (120 locale records, 480 explanations) **cannot** be counted as independent child-specific, professionally approved Tutor cards.
- Review 187 remaining, then reconcile duplicate/synonymous actions across parent points, check historical tier mismatches (A Level MV=PT Q2540 appearing in an AS Practice pool), and get source/teacher approval of final atomic map **before** other stages are promoted.
- Do not alter existing question texts, correct answers, Tour/Practice placement, answers, attempt histories, grades, progress, payments, certificates, localStorage or global AI settings.
- **No Vercel API calls, builds, preview, provider AI generation, merges or deployment.** Informatics deferred.

**Next sequence:** source-check highest-ranked medium rows, decide retain/split with evidence; only then resolve fine-grained question and Tutor source mappings. Continue in Draft PR #337.
