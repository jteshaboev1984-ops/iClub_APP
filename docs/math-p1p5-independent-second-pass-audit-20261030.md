# Mathematics 9709 P1/P5 — independent second-pass academic audit

Status: **IN PROGRESS**; **285 / 1,448 current items** have undergone a second-pass academic review (numerical derivations where applicable, conceptual validation for model-selection items). This is **not independent human certification**. Prepared 2026-10-30 at owner's request. This plan governs **content quality**, not mass-rollout approval. Existing learner answers/sessions are immutable.

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
- Both legacy source questions had **zero** learner session-item exposures and their two parent pack versions had **zero** sessions, issued authorizations, goal references or review starts at preflight. **DONE:** released corrected source questions **10100 and 10099** and learning pack **465/v3**. Retired unused old packs **35421/v1 and 464/v2**, and old defective content metadata, without altering original question text or any learner data. The read-only live postflight **PASSED**.
- P1-CIR-03 **15/15** latest published+reserve question keys now checked with independent geometry oracles and against live keyed answers: after two corrections, **0 discrepancies**. P5-BIN-02 and P5-GEO-02 **30/30** latest published+reserve question keys independently computed with binomial/geometric probability formulas and live keyed-answer assertions: **0 discrepancies**. This is *45/1,448* items, **not** whole-bank academic completion.
- Previous checks passed 1,215 question-bank structure/translation-presence checks and 334 published written rubric/locale count checks; these are structural QA, **not** independent solutions.

## Operational quality bar

Every release should record: original ID and immutable source, new ID, changed EN/RU/UZ stem/key/explanation/alternatives, actual expected mathematical output, deployed assessment version, rows/session counts before/after and test results. Never claim an independent human reviewer or broad learner signoff. A failed atomic SQL transaction is a rollback, not a published fix.

## Progress ledger

| Group | Count | State | Evidence |
| --- | ---: | --- | --- |
| Question-bank structure (both stages) | 1,215 | Verified structurally, not math | SQL read-only key/4-option/nonempty/i18n checks |
| Published written total marks, locale rows/checksums | 334 versions | Verified structurally, not all math | Prior all-published SQL check |
| P1-CIR-03 published + reserve question family | 15 | **15 independently recalculated; 2 corrected and verified** | Sin/radian geometry, live 15/15 key contract |
| P5-BIN-02 and P5-GEO-02 published + reserve | 30 | **30 independently recalculated; 0 mismatches** | Independent probability formulas, live 30/30 key contract |
| P5-NOR-03/04/06 and P5-PRO-02/06 | 75 | **75 key derivations matched; no new defects** | PR #434: 60 live source oracles and 15 inverse-normal checks |
| P5-NOR-05 and P5-PRO-03/04/05 | 60 | **60 computed/conceptual answers matched** | Read-only live SQL calculations in 2026-10-31 session |
| P5-BIN-03, GEO-03, PRO-01 and NOR-02 | 60 | **60 formula-based mathematical checks, no mismatches** | Four-skill read-only SQL oracles and CI |
| P5-BIN-01, GEO-01 and NOR-01 | 45 | **45 reviewed conceptually against all four answer choices** | All three model-choice families inspected; live source structure check, 0 issues |
| **Remaining current-bank and written items** | **1,163** | **NOT YET ACADEMICALLY RECHECKED** | Do not claim completed semantic audit |

## 2026-10-31 P5 seven-skill second-pass batch

- BIN-03 (15): binomial mean and variance, inverse parameters, nondegenerate mean/variance ratio. Formula oracle **15/15**.
- GEO-03 (15): expected trial number, time-to-first-success, cubic-tail relation. Formula oracle **15/15**.
- NOR-02 (15): z-scores, normal CDF and tail values, including Unicode minus normalization. Formula oracle **15/15**.
- PRO-01 (15): Cartesian sample-space counting, independence, ordered outcomes, coins/dice/spinners. Formula oracle **15/15**.
- BIN-01 (15), GEO-01 (15), NOR-01 (15): conditions for valid binomial/geometric/normal models; inspected all answer choices for semantic validity and live RU/UZ option alignment. **45/45 source structure checks passed**. These are conceptual decisions, **not numeric solutions**.
- Across all 105: no missing language options, no duplicate literal MCQ alternatives and no EN/RU/UZ option number conflicts (one verbal Russian «первом испытании» vs English digit 1 is equivalent). Numeric stem token mismatches due to spelled English numbers and Russian semicolon decimal notation were inspected; none is a confirmed translation defect.
- Four read-only fixtures have **already executed against Supabase and passed** (30 + 15 + 15 + 45). Regression runs through GitHub Actions; student state is untouched. No new confirmed academic errors in this batch.
- Total after this batch **285 / 1,448 reviewed; 1,163 remain**. This is not a claim that all handwritten solution steps, all semantic equivalences or all future deliveries have been exhaustively tested.
