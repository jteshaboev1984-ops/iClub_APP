# Mathematics 9709 P1/P5 — independent second-pass academic audit

Status: **IN PROGRESS**, not independently human-certified. Prepared 2026-10-30 at owner's request. This plan governs **content quality**, not mass-rollout approval. Existing learner answers/sessions are immutable.

## Source inventory (read-only Supabase, 2026-10-30)

| Item | P1 | P5 | Combined |
| --- | ---: | ---: | ---: |
| Published question-bank questions (MCQ + input) | 270 | 216 | 486 |
| Reserve question-bank questions (MCQ + input) | 405 | 324 | 729 |
| Current published written tasks (one latest version per content-version/task-key) | 130 | 103 | 233 |
| **Distinct items for second-pass review** | **805** | **643** | **1,448** |

Note: the database has 334 published written **versions**; 101 older published versions are not additional distinct current tasks. Historic versions remain immutable, but can be audited for harm to existing sessions if evidence appears.

## Audit method: different from earlier database integrity checks

1. **Freeze the inventory and risk-order work**: capture item ID, content-key, latest version, lifecycle, component, skill and source snapshot. Published first (719), then reserve (729). Add a discrete disposition for each object: `independently_verified`, `corrected_and_retested`, `needs_academic_review`, `not_yet_checked`. Do not convert machine completeness into academic verification.
2. **Blind numerical / symbolic recomputation**: compute from the **question stem** with a separate derivation before viewing the keyed answer, explanation or marking criteria. Use deterministic numerical oracles for geometry, algebra, probability/distributions, statistics and rounding/tolerance. Flag inconsistent stem assumptions as defects even if the saved key follows those wrong assumptions. Validate all four MCQ alternatives, including uniqueness, not only the keyed one.
3. **Adversarial checking**: test boundary values (strict vs non-strict inequalities, continuity corrections, radians/degrees, exact vs rounded results, binomial/geometric assumptions, normal variance vs SD), and detect possible ambiguity, impossible constraints or hidden alternative answers.
4. **Written tasks**: independently derive the complete solution, then compare with each mark criterion. Confirm criterion marks sum to maximum, no omitted demanded steps, same method/precision and appropriate treatment of mathematically equivalent solutions.
5. **Translation equivalence**: EN/RU/UZ conditions, constants, logical quantifiers, units, rounding rules, choices and rubric wording. Hash-valid translations are **not** proof of semantic equivalence.
6. **Fix in versioned batches**: never rewrite a source question used historically. Clone new `public.questions`, create distinct governed content-meta with full immutable snapshot, clone assessment to a new version, replace only defective item references. Keep old attempts unchanged and prevent faulty versions from being selected for fresh learners once safe. Each correction needs mathematical assertions + static SQL mutation safety + read-only live postflight. Retire old packs only when zero sessions and no other consumers.
7. **Quality/rollout gate**: after 1,448 independently logged dispositions, spot-check UI rendering EN/RU/UZ and live routing separately. Keep mass rollout **NO_GO** until user accepts learner E2E and independent observational beta; previously skipped stages 2 and 3 stay skipped.

## Initial second-pass findings and action

- Published `P1CIR03-A01` (source question 7154; learning pack v1/v2) says r=10, theta=0.8, and triangle area 24. A genuine central triangle has area `50*sin(0.8)=35.8678045...`, segment `40-50*sin(0.8)=4.1321955...` (2 d.p. = 4.13), **not 16**. A published MCQ key is therefore invalid for the stated geometry.
- Published `P1CIR03-A03` (source question 7140; same packs) says r=6, theta=2.2, central triangle area 14.4. Correct value `18*sin(2.2)=14.5529353...`; segment `39.6-18*sin(2.2)=25.0470647...` (2 d.p. = 25.05), **not 25.2**.
- Both legacy source questions have **zero** learner session-item exposures; their two parent pack versions also have **zero** sessions as of the preflight audit. Preserve legacy source records for traceability, but release corrected replacements and retire only these old unused packs after all guards pass.
- Other P1-CIR-03 questions (15 item keys total: 6 published, 9 reserve) were reviewed against arc/sector/annular geometry; no *additional confirmed* defect in that focused family yet. This is **not** whole-bank academic completion.
- Previous checks passed 1,215 question-bank structure/translation-presence checks and 334 published written rubric/locale count checks; these are structural QA, **not** independent solutions.

## Operational quality bar

Every release should record: original ID and immutable source, new ID, changed EN/RU/UZ stem/key/explanation/alternatives, actual expected mathematical output, deployed assessment version, rows/session counts before/after and test results. Never claim an independent human reviewer or broad learner signoff. A failed atomic SQL transaction is a rollback, not a published fix.

## Progress ledger

| Group | Count | State | Evidence |
| --- | ---: | --- | --- |
| Question-bank structure (both stages) | 1,215 | Verified structurally, not math | SQL read-only key/4-option/nonempty/i18n checks |
| Published written total marks, locale rows/checksums | 334 versions | Verified structurally, not all math | Prior all-published SQL check |
| P1-CIR-03 published + reserve question family | 15 | Focused geometric review; 2 confirmed defects | Trigonometric derivation and regression |
| All remaining current-bank and written solutions | 1,433 | **NOT YET INDEPENDENTLY SOLVED** | Work queue; do not claim completion |
