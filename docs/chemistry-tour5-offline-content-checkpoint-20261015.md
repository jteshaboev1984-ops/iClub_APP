# Chemistry 9701 — Tour 5: 20 original questions (offline academic review)

**Source contract:** `Tour Map v1.0 — Chemistry`, Tour 5, chapters 14–18, and `Cambridge International AS & A Level Chemistry Coursebook`, third edition by Lawrie. These are **textbook-level** citations, not a claim of independent Cambridge examiner approval.

**Status:** COMPLETE OFFLINE AUTHORING / QA PASS / **NOT INSTALLED**. No write, change, activation, user reset, notification, branch merge, or Vercel deployment has occurred in this Tour 5 task.

## Structure

| Scope | Slots | Content focus |
|---|---|---|
| Chapter 14 — Introduction to organic chemistry | 1, 7, 12, 16 | nomenclature, E/Z, chirality, enumerating alcohol isomers |
| Chapter 15 — Hydrocarbons | 2, 6, 8, 13 | bromine-water test, monoalkene formula, electrophilic addition, mild oxidation |
| Chapter 16 — Halogenoalkanes | 3, 9, 14, 20 | substitution, electron-flow mechanism, nitrile chain extension, substitution vs elimination |
| Chapter 17 — Alcohols, esters, carboxylic acids | 4, 10, 15, 17 | controlled oxidation, dehydration, ester naming, limiting-reagent ester yield |
| Chapter 18 — Carbonyl compounds | 5, 11, 18, 19 | IR spectroscopy, HCN addition mechanism, iodoform test, carbonyl addition yield |

- **Question modes:** 16 four-choice MCQs plus 4 numeric inputs (slots 6, 14, 17, 19).
- **Difficulty/order:** 6 easy / 9 medium / 5 hard. MCQ keys exactly A/B/C/D = 4/4/4/4.
- **Mechanistic reasoning:** slot 8 electrophilic addition via more stable secondary carbocation; slot 9 nucleophilic substitution electron-pair arrows; slot 11 carbonyl nucleophilic addition via CN⁻; slot 20 competition between aqueous nucleophilic substitution and ethanolic elimination.
- **Theory-based diagnostics:** IR C=O vs broad O–H, iodoform test, spatial stereoisomerism, careful limitation to the reagent/condition stated.
- **Timing:** individual `time_limit_sec` range 55–180 seconds; sum 2,100 seconds = 35 minutes, *not a separate overall countdown*.

## Independently recalculated numeric keys

| Slot | Expected | Calculation | Input format |
|---|---|---|---|
| 6 | `10` | C₅H₁₀ gives 2 × 5 hydrogens | integer only |
| 14 | `4` | 3-carbon propyl group + 1 carbon introduced by CN | integer only |
| 17 | `15.8` | limiting ethanol: min(0.250,0.180) × 88.0 = 15.84 → 15.8 g | 3 significant figures |
| 19 | `2.13` | (1.45 / 58.0) × 85.0 = 2.125 → 2.13 g | 3 significant figures |

The answer-format rules are attached to candidates as `answer_policy`; **they are not yet installed in Supabase**. No automatic grading or authenticated user-session E2E was run for Tour 5.

## Honest scope of QA

`qa_tour5.py` validates structure, language field completeness, timer range, chapter balance, key balance, empty input options, canonical fields, four independent calculations and exact English wording duplication within these 20 and the 56 candidate items from Tours 3 and 4 included in the existing offline archive. It is **not** a native EN/RU/UZ specialist signoff, nor a semantic screen against all historic Chemistry questions in the live database. A broad Supabase read-only query was blocked in this turn; no attempts to bypass that block were made.

## Practical next steps (one-pass)

1. When permitted, read only the currently active Practice 5 pool (id `19`) and all protected Chemistry Tour sources; classify all 70 Practice items as KEEP / REPLACE / FIX. Work only on evidenced problems. Preserve every old `question_id` and user answer.
2. Run a genuine semantic similarity screen for these 20 Tour 5 candidates against the **full old subject corpus and both seasons**, not merely Tours 3/4 offline. Resolve only actual collisions and scientific errors.
3. Build **one immutable release payload** with the final KEEP mapping and any necessary Practice replacements; verify original question content/checksums, strict numeric policies and the second-season *draft* Tour 5 (id `83`) state.
4. If authorized migration execution is available, install via the standard guarded/idempotent Chemistry staged migration, create only new question IDs, preserve the originals, and link only the intended Practice 5 and draft Tour 5. No content switch unless both transaction checks and scorer routing pass. Do not use legacy 24-item loader with existing Tour links.
5. Check final new question IDs, 70 Practice links, 20 draft Tour links, user/history invariants; leave Season 2/tour 5 inactive. Do not reset Chemistry Practice or send any in-app notification without separate explicit release decision.

**No round-trip editorial work is needed after this candidate unless an actual error/collision is found.**