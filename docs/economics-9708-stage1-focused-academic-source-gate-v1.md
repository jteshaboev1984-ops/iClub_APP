# Economics 9708 — focused academic-source gate, 2026-10-09 (Stage 1)

**Authorisation:** academic preparation only. **Economics Stage 1 = IN_PROGRESS, academic canon and runtime publication NOT approved.** Informatics still deferred. No Vercel API calls, builds, previews, deployment or production/user changes.

## Source authority used for this pass

1. Official Cambridge International AS & A Level Economics **9708 examinations 2026–2028, version 2**, [official PDF](https://www.cambridgeinternational.org/Images/697423-2026-2028-syllabus.pdf) (subject-content printed pp. 15–34).
2. User-uploaded *Economics for Cambridge International AS & A Level, fourth edition*; extracted the **actual contents and chapter 44.7** for the nuanced liquidity-preference motives and chapter 44 loanable-funds treatment.
3. User-uploaded `Tour Map v1.0 — Economics (по книге) для 7 туров.docx`. It assigns book chapters 1–11 / 12–20 / 21–29 / 30–37 / 38–40 / 41–47 / 48–53 to Tours 1–7. This describes planning order, not official assessment requirements.
4. Persistent master plan `docs/subject-ai-content-expansion-master-plan-v1.md`. No Stage 2/3 promotion before accepted Stage 1 canonical denominator.

## Official syllabus matching of the latest 23 decomposed parents

**Machine-readable, source-scoped evidence:** `docs/economics-9708-v4-focused-syllabus-alignment-audit-v1.csv`.

All **23** targeted Cambridge numbered parent points were compared to their syllabus wording/numbered components and actual coursebook chapter assignments. These hold **76** *provisional* child learning actions in `docs/economics-9708-atomic-candidate-register-v4.csv`. Source classification: **21** parent splits follow explicit Cambridge listed components; **2** require more interpretation (money-demand motives within 9.4.7 and comparing the two theories within 9.4.8). The supplied book Ch44 supports transactions, precautionary and speculative motives and both interest-rate theories. Scope alignment is **not** a teacher's approval of atomic decomposition, correct answers, question evidence, RU/UZ texts, or exam-ready depth.

Corrections made on the **draft branch**, preserving all Git history:
- **9.4.7:** distinguished an income-driven **shift** in the liquidity-preference schedule from an interest-rate-driven **movement along** a given money-demand curve. The earlier wording misleadingly suggested both could shift the entire curve.
- **11.5.4:** made the mandatory FDI outcome its **definition**, not a comparison to portfolio investing. The official 11.5.4 requires definition and consequences of FDI; portfolio comparison can enrich the teaching text but must not be a compulsory evidence requirement.

No official numbers, draft key counts, question/answer links or runtime flags were modified by these two scope corrections.

## Cross-language/graph academic corrections

- **2.2.5 PED graph axis captions:** Existing `docs/economics-diagrams-v0/locale-captions-v0.json` had **horizontal Price / vertical Quantity** across EN/RU/UZ, contrary to the source SVG (**Q horizontal / P vertical**). Corrected all 3 locales. The source file `straight-line-ped.svg` retains the original Q=10−P numerical model.
- **AS-level explanation complexity:** In `docs/economics-9708-trilingual-tutor-batch3a-v0.json` (2.2.5, all three locales), replaced unnecessary derivative notation `dQ/dP` with constant **straight-line gradient / percentage reasoning**. The small print in `straight-line-ped.svg` was brought into agreement. Numerical conclusions (|PED| = 4, 1, 0.25 for representative points) unchanged.
- **Gini rule:** AS 3.3.2 expects interpretation and **does not require numerical Gini calculation**; A Level 11.4.2 does require it. Keep all Gini-number examples A Level only, without silently reusing them to prove AS skill readiness.
- **Graphics promotion blocker:** Four saved English-original SVG graphics plus 12 EN/RU/UZ external caption sets exist, but the *image labels themselves* are not translated for RU/UZ; fixed 600-wide viewBoxes downscaled to a 390px screen imply potentially small type. **No rendered 390px visual QA, accessibility/language QA or teacher approval has been completed. Do not use them on learner screens.** Source assets remain in `docs/economics-diagrams-v0/`, not runtime resources.

## Remaining Stage 1 work — no repeated full-bank audit

The `v4` provisional index retains **409 draft action keys across 253 official numerical syllabus parent points**, but **201 are still unsplit one-to-one placeholders** and the final approved denominator is UNKNOWN. The 409 number **must not** become any learner-facing skill total.

A new **read-only, ranked editorial queue** `docs/economics-9708-remaining-atomic-review-queue-v1.csv` contains all remaining 201 placeholders. Automated *triage only* based on draft action wording: **14 higher**, **80 medium**, **107 lower** complexity flags. This is not an official Cambridge classification and no item is automatically approved by low heuristic risk. For each flagged official parent, a reviewer must compare the actual Cambridge point and any bullet subrequirements, textbook treatment, tier and Tour, then choose retain-one / split-to-children / merge-redundant with a short evidence-based explanation. Preserve source/version history.

Next start with the 14 high-risk rows, then unresolved medium complexity; **do not generate more unapproved Tutor cards** until the relevant atomic skills have been source-confirmed.

## Important blockers not to misstate as GREEN

1. **201** provisional one-to-one parent-to-skill rows require source-level atomicity decisions.
2. Newly split **76** proposed child rows have **zero independently verified precise question/answer mappings**. Parent-topic draft cards cannot be counted as 76 independent approved Tutor sources.
3. Assessment and source rights, 390px graphics, accessible chart axes, translations and rigorous academic checking remain unresolved.
4. Earlier prepared **40 parent-topic overview explanations on EN/RU/UZ** remain draft *overviews*, not approved theory/Tutor coverage for every child action.
5. Do not relabel student mastery, move historical questions between Tours or correct any legacy scores as a side effect of mapping.

**Result of this slice:** 23/23 targeted source scopes recorded with cautions; specific *draft-only* errors fixed; 201 remaining decisions safely queued. **Economics Stage 1 stays IN_PROGRESS.** Separate release authorisation is still required even after academic QA.
