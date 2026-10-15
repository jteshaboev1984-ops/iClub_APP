# iClub Chemistry 9701 — R4 targeted content correction package

**Date:** 2026-10-15  
**State:** OFFLINE EDITORIAL DRAFT / NOT INSTALLED  
**Production:** untouched in R4 (no Supabase mutation, old ID rewrite, grade/certificate recalculation, Season2 activation, code or UI change).

## 1. Basis and why this is a targeted release

The R3 630-row traceability register includes **56 IDs with actual recorded findings**, not 56 wrong answers. R4 did not repeat previous answer-delivery regression, author a replacement for every quality note, or grant an unearned blanket PASS. This pass prepares **eight complete, new-ID candidates** with source references, English/Russian/Uzbek content, four diagnostic MCQ alternatives, reasoned explanations, immutable content SHA256, and a guarded future-only change contract.

Authoritative documents: Tour Map v1.0 Chemistry; Chemistry Subject Decision v3.1 and Addendum v3.2; Academic Content Operating Standard v3.0; original question diagnostic change protocol; R3 factual ledger; [Cambridge International 9701 syllabus 2025–2027](https://www.cambridgeinternational.org/Images/664563-2025-2027-syllabus.pdf). Cambridge learning-outcome sections refer to official syllabus numbering, **not Coursebook chapter numbering**.

## 2. Eight content replacements — all PREPARED, none deployed

| Live ID | Existing bank | Trigger | New test skill / safer replacement | New correct key |
|---:|---|---|---|:---:|
| **3373** | Practice4 | **P0** two defensible MCQ answers (SiCl₄ and AlCl₃) | Explicit SiO₂ product uniquely identifies SiCl₄; official §9.2.5 | A |
| **3106** | Practice3 | P1 vague temperature-equilibrium precondition | Closed reversible SO₂/O₂/SO₃ equilibrium, response of Kc and composition; official §7.1.3/7.1.9 | B |
| **4757** | Practice6 | P1 duplicate of #4694 | **Avogadro constant measured through electrolysis** using Q, Cu mass, stoichiometric electrons, elementary charge; §24.1.2–4 | B |
| **9797** | Season2 Tour5 | P1 exposed answer from Practice5 #4359 | Two-step halogenoalkane-to-aldehyde route with selective distillation; official AS organic | D |
| **9801** | Season2 Tour5 | P1 same HBr/propene product as Practice5 #4343 | 2-Methylpropene acid hydration, tertiary carbocation and product; official §14.2 and §16.1 | C |
| **9824** | Season2 Tour6 | P1 repeated Fe/I E° example and RU/UZ scientific-term problem | **Nernst quantitative calculation**, E = +0.281 V; official §24.2.9 | B |
| **9831** | Season2 Tour6 | P1 near-identical rate-law template to Practice6 #4703 | **Liquid-liquid partition coefficient** from measured moles and two unequal volumes; §25.2.1–3 | C |
| **9835** | Season2 Tour6 | P1 non-required ΔSsys+ΔSsurr calculation | **ΔG° = −nFE°cell**, −96.5 kJ mol⁻¹; official §24.2.10 | B |

The five Season2 Tour replacements intentionally retain each replaced question's **correct-letter distribution**. The Tour6 compulsory syllabus gaps (Avogadro method, Nernst, ΔG/Ecell, partition coefficients) are now all *represented among the eight proposed items*, but they are **not yet covered in live production**, because the candidates remain offline.

## 3. Independent checks done in R4

- 8 unique source IDs matched to all 8 correct original tour/bank memberships documented in the R3 register.
- 8 fully authored MCQ items, 24 language versions, 96 option texts, 24 diagnostic descriptions of wrong answers.
- All question keys and correct option texts checked individually, not inferred from the previous server evaluator.
- Numeric derivations recalculated independently: L from Cu deposition **6.03 × 10²³ mol⁻¹**, Nernst Cu²⁺/Cu **+0.281 V**, Kpc **8.00**, ΔG° **−96.5 kJ mol⁻¹**.
- All eight candidate SHA256 content hashes validated, all items have a distinct original reference ID and `DRAFT_EDITORIAL_HOLD_NOT_INSTALLED` status.
- **No external chemistry reviewer and no RU/UZ academic language reviewer has signed off.** The offline QA does not substitute for their approval or end-to-end Preview checks.

See `R4_VALIDATION_RESULTS.json` for the reproducible checks and `R4_EIGHT_CHANGE_DECISIONS.csv` for exact IDs and hashes.

## 4. Remaining R1–R3 findings — preserved, not made invisible

- Of the 56 flagged IDs: **8 now have complete future-version candidates**; **12 Practice7 language-mixing IDs require specialist terminology decisions**; remaining **36** preserve their previous documented findings for subsequent scope, explanation, difficulty, or enrichment classification. Nothing is silently marked approved or closed.
- The 12 language matters are detailed in `R4_LOCALISATION_TERMINOLOGY_REVIEW.md`. This is a controlled terminology guide, not an automated field-level text patch.
- Book-only enrichment issues (e.g. some Tour2 items) are not automatically scientific mistakes; their exam-coverage role must be approved in subject blueprint rather than rewritten solely for a quota.
- Low-difficulty questions incorrectly tagged `hard` require deliberate calibration; do not quietly modify historic `difficulty` metadata linked to real answers.

## 5. Future release gate — not yet requested/executed

1. External chemistry and RU/UZ review of the **eight exact candidate hashes**; unresolved objection => HOLD.
2. Architect's explicit scope approval, then read-only before-state snapshot and history impact; confirm original membership and activity.
3. Build in protected Preview with realistic student workflow, independently validate keys/distractors and locale layout.
4. Atomic insert of eight **new IDs** and switch of eight membership links only, preserving all 630 linked positions and closed Season2 state. Old question rows/history/answers remain; no retroactive grade recalculation.
5. Verify final membership counts and rollback reference, release report. No main/Vercel deployment required for this content-only proposal unless runtime QA detects a UI problem.

**Deliverable status:** academic authoring / QA draft complete for eight prioritized items. Production release is **not** complete or authorised by this package. Further professional signoffs and a separately approved cutover remain necessary.