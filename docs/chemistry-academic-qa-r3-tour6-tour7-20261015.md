# iClub Chemistry 9701 — Academic Content QA, R3 (Tours 6–7)

**Date:** 2026-10-15. **Mode:** READ-ONLY, no production changes. **Sources:** current live `public.questions` membership Practice6/7 (pools 20/24) and Season2 Tour6/7 (tour 84/85), Tour Map v1.0, iClub Academic Content Operating Standard v3.0 and [official Cambridge International 9701 2025–2027 syllabus](https://www.cambridgeinternational.org/Images/664563-2025-2027-syllabus.pdf). Earlier R1/R2 results preserved; no repeated server regression tests.

## 1. Actual review scope

- Reviewed the **180 currently linked English questions** individually for Tours **6 and 7**: 140 Practice plus 40 Season2 Tour. The read covered the live stem, MCQ options, key and rationale, not merely the prepublication archive. For numeric items, assessed the given worked solution and its result; this is not a full independent external answer-key signoff.
- Earlier R2 recorded an internal English first pass of the 360 questions of Tours 2–5. Tour 1 has earlier targeted editorial evidence, but **the entire 630-item corpus must NOT be marked fully independently approved**.
- Performed **targeted** live Russian/Uzbek reads of the newly suspicious Tour 6–7 items, plus a narrow language-mixing screen. This is not an end-to-end 180-item professional translation signoff.
- Kept every old audit finding and every source ID in the 630-row ledger; **20 new item-level findings** were appended (12 P1; 8 P2) without losing R1/R2 comments.
- No actual numeric server evaluations were repeated. Prior release correctness regression is not scientific proof of the answer key.

## 2. High-priority content findings

| Priority | Live ID(s) | Proven issue | Safe editorial action |
|---|---|---|---|
| P1 | **4694, 4757** | Practice6 has two near-identical questions asking which ion in ethanoic acid/ethanoate buffer neutralises added H⁺; both accept acetate. | Replace *one future question*, preserve old IDs/history. |
| P1 | **4701, 9824** | Practice6 and Season2 Tour6 share exactly the same Fe³⁺/Fe²⁺ and I₂/I⁻ potentials (+0.77/+0.54 V) and same numerical answer **+0.23 V**. The Tour answer is exposed in Practice. | Replace future Tour #9824 with a distinct original electrode-potential problem. |
| P1 | **9824** | Live RU stem says **«E° элемента»** and UZ says **«E°element»**, mistranslating the standard cell potential `E°cell`. | Correct scientific terminology in a candidate new version, RU «стандартная ЭДС гальванического элемента», UZ equivalent. |
| P1 | **5310, 5319, 5345, 5353, 5378** | Practice7 `hard` labels on straightforward recall: polyester ester link, molecular ion mass, polyamide link, NMR integration, Tollens aldehyde-vs-ketone. | Recalibrate difficulty for future questions or replace with genuinely multi-step hard items. |
| P1 | **4717, 4734** | Practice6 `hard` used for single-substitution `k=0.693/t½` or two-potential subtraction; beyond-trivial distractors absent. | Calibrate difficulty or redesign higher-level question. |
| P1 | **9835** | Season2 Tour6 requires adding entropy of system and surroundings to infer feasibility. **Cambridge syllabus §23.3.3 explicitly notes using `ΔS° = ΔSsurr + ΔSsys` is not required.** The arithmetic/key are correct but the *required-outcome classification* is not. | Mark as enrichment; for a compulsory exam-aligned Tour slot, replace with required thermodynamics item before Season2 opening. |

**Carried forward, not rediagnosed:** confirmed ambiguous Practice4 **#3373** (P0), Tour6 **#9831 ↔ Practice #4703**, Tour5 crossbank overlaps **#4343 ↔ #9801**, **#4359 ↔ #9797**, and earlier R1/R2 evidence. Do not conflate `P1` quality overlap with wrong answers.

## 3. Localisation problems (item-specific evidence)

- **#5310 UZ**: `polyester`, `hydroxyl`, `carboxyl functional group`, `ester` embedded in Uzbek scientific explanation.
- **#5319 UZ**: `Mass spectrum da molecular ion peak` instead of consistent Uzbek chemistry vocabulary.
- **#5345 UZ**: `polyamide`, `amide` embedded without consistent localization.
- **#5317, #5333, #5340, #5353, #5355, #5367, #5371, #5373**: English spectroscopy/polymer terminology remains in RU and/or UZ. These are **P2 technical language consistency flags**, not automatically scientifically wrong meanings.
- **#9824 RU/UZ** is more substantive (P1), because an established electrochemical symbol is replaced by a potentially misleading natural-language term.

A narrow English-expression screen of Tour6/7 detected **6 RU stems and 11 UZ stems in Practice7** among a predefined list of phrases, and **one each in Tour6**. This is *not* a measurement of all possible translation errors, only a reproducible triage for human review. Suggested terminology is in `Targeted_Correction_Directions_NOT_INSTALLED.json` and must be accepted by a language specialist before use.

## 4. Official 9701 learning outcome coverage gaps in Tour 6

Cambridge official required A Level content includes:

- **§24.2.9:** quantitative concentration dependence of electrode potential using the **Nernst equation**;
- **§24.2.10:** `ΔG° = −nFE°cell`;
- **§25.2:** partition coefficients (`Kpc`), calculation and interpretation;
- **§24.1.4:** determination of Avogadro's constant by an electrolytic method.

**None of the current 90 Tour6 questions** explicitly tests these four outcome families in its English stem. This was confirmed by reviewing the 90 current stems and a narrow zero-match search. This does **not** prove that the entire Chemistry app lacks these outcomes elsewhere. It proves only gaps **in this 90-item Tour6 bank**. These objectives are in the official syllabus even though Tour Map v1.0's brief coverage list did not mention all of them. Scope additions should follow architect approval and remain within the current 70+20 slot contract.

A syllabus *section candidate* has been recorded against the Tour6/7 rows in `630_Question_QA_Traceability_Ledger_v3.csv`, **not** an item-level approved learning-outcome mapping. The exact official learning outcome/signoff remains open.

## 5. Constrained priorities, no repeat loops

1. **P0 from previous round:** #3373 already has a draft with separate future `question_id`. In production the question remains live; history/answers must not be silently edited. Needs its own controlled fix/approval.
2. **Before Season2:** #9835 mandatory-syllabus fit and #9824 Practice–Tour answer leak are the most urgent content matters; Tour6 stays closed pending authorisation to launch.
3. **Practice currently visible:** eliminate the near-duplicate #4694/#4757 through future-only candidate switch if approved; calibrate difficulty for the seven noted items. Do not edit old `correct_answer`, options, or previous responses.
4. **Languages:** consolidate a single RU/UZ terminology guide for NMR, ester/polymer, cell potential, then perform targeted correction of actual rows based on a signed localized version.
5. **Coverage:** address identified Tour6 Nernst/ΔG–Ecell/Kpc/electrolytic-Avogadro gaps by replacing low-value slots, not increasing 70/20 or disturbing learner progress.

## 6. Audit integrity and counts

- **630/630** live question IDs remain in the combined register; **180** received new R3 internal English review coverage.
- Ledger R2 had **36 IDs** with documented problems, including one P0. R3 adds **20 distinct IDs**; consolidated ledger now has **56 IDs with recorded issues**, not 56 independently verified wrong answers. Old findings have NOT been erased.
- Full independent chemistry/language review, original graphical evidence inspection, and all-exam-paper coverage signoff remain **PENDING**. No general `PASS` has been granted merely from server checks.
- **No Supabase INSERT, UPDATE, DELETE, migrations, grade recalculation, resets, Season2 activation, GitHub main, Vercel, or user-data mutation** occurred in R3.

## Appendix — attached files

- `630_Question_QA_Traceability_Ledger_v3.csv`: 630 real IDs, all historical notes, R3 per-ID coverage + findings, no manufactured PASS.
- `Round3_New_Findings.csv`: 20 new documented item findings.
- `Targeted_Correction_Directions_NOT_INSTALLED.json`: language terminology and candidate future-only action notes; **not executable SQL**, not authorized release.

**Sources:** Cambridge 9701 official `https://www.cambridgeinternational.org/Images/664563-2025-2027-syllabus.pdf`, especially PDF pp. 39–43; Tour Map v1.0 Chemistry; live Supabase current question membership/read-only queries 2026-10-15; Academic Content Operating Standard v3.0; prior iClub change protocol on question history.