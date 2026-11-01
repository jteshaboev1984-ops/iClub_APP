# Mathematics 9709 P1/P5 — independent second-pass academic audit

Status: **IN PROGRESS**; **1,254 / 1,448 current items** have undergone a second-pass academic review (numerical derivations where applicable, conceptual validation for model-selection items). This is **not independent human certification**. Prepared 2026-10-30 at owner's request. This plan governs **content quality**, not mass-rollout approval. Existing learner answers/sessions are immutable.

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
| P5-CNT-01 to CNT-05 (published + reserve) | 75 | **75 independently derived factorial/combinatorial results, 0 mismatches** | Five read-only SQL formula-oracle fixtures executed against live Supabase; source/choices EN/RU/UZ reviewed |
| P5-DAT-01 through DAT-10 (published + reserve) | 150 | **150 answer/semantics checks, zero observed mismatches** | 10 independent source-level read-only SQL fixtures executed against Supabase; regression CI | 
| P5-DRV-01 through DRV-03 (published + reserve) | 45 | **45 distribution/expectation/variance answers matched** | Three read-only SQL oracles executed against Supabase; independent numeric regression CI |
| P1-CIR-01/02 and P1-QUA-01..06 (published + reserve) | 120 | **120 correct keyed answers verified with independent geometry and algebra derivations** | Eight read-only live SQL oracle fixtures, numerical regression and locale consistency checks |
| P1-TRI-01..05 and P1-SER-01..05 (published + reserve) | 150 | **149 previously correct, 1 wrong published MCQ key repaired, all 150 current keys matched after correction** | Independent trigonometry/series calculations, 2 read-only 75-item live fixtures, corrected Q10101/assessment466 and live postflight |
| P1-FUN-01..08 (published + reserve) | 120 | **120 live source stems and keyed answers reviewed; 120/120 oracle matches** | Two 60-item SQL source oracles, independent inverse/domain/range/transformation numerical tests, EN/RU/UZ checks |
| P1-COO-01..06 (published + reserve) | 90 | **90 live source stems and keyed answers reviewed; 90/90 oracle matches** | Two 45-item SQL source oracles, independent line/circle/chord/tangency numerical tests, EN/RU/UZ checks |
| P1-DIF-01..07 and P1-INT-01..05 (published+reserve) | 180 | **180 independently solved from live stems; 180/180 current keys match** | Live read-only 180-row FULL JOIN answer-oracle + locale checks + numerical calculus regression |
| P1-DIF/INT latest written tasks | 39 | **39 stem-to-solution and criterion-level checks, zero confirmed defects** | Read-only live expected result fragments, rubric sum, locale checks + calculus numerical regression |
| **Remaining current-bank and written items** | **194** | **NOT YET ACADEMICALLY RECHECKED** | 91 other P1 + 103 P5 current written tasks |

## 2026-10-31 P5 seven-skill second-pass batch

- BIN-03 (15): binomial mean and variance, inverse parameters, nondegenerate mean/variance ratio. Formula oracle **15/15**.
- GEO-03 (15): expected trial number, time-to-first-success, cubic-tail relation. Formula oracle **15/15**.
- NOR-02 (15): z-scores, normal CDF and tail values, including Unicode minus normalization. Formula oracle **15/15**.
- PRO-01 (15): Cartesian sample-space counting, independence, ordered outcomes, coins/dice/spinners. Formula oracle **15/15**.
- BIN-01 (15), GEO-01 (15), NOR-01 (15): conditions for valid binomial/geometric/normal models; inspected all answer choices for semantic validity and live RU/UZ option alignment. **45/45 source structure checks passed**. These are conceptual decisions, **not numeric solutions**.
- Across all 105: no missing language options, no duplicate literal MCQ alternatives and no EN/RU/UZ option number conflicts (one verbal Russian «первом испытании» vs English digit 1 is equivalent). Numeric stem token mismatches due to spelled English numbers and Russian semicolon decimal notation were inspected; none is a confirmed translation defect.
- Four read-only fixtures have **already executed against Supabase and passed** (30 + 15 + 15 + 45). Regression runs through GitHub Actions; student state is untouched. No new confirmed academic errors in this batch.
- Total after this batch **285 / 1,448 reviewed; 1,163 remain**. This is not a claim that all handwritten solution steps, all semantic equivalences or all future deliveries have been exhaustively tested.

## 2026-10-31 P5 Counting audit (new batch)

All 75 published+reserve source questions in CNT-01 through CNT-05 were independently calculated using factorials, combinations, repeated-letter multisets and position/adjacency constraints. Five read-only SQL arithmetic oracle fixtures each checked 15 question IDs against their current keyed choice and returned **0 errors / 15** on live Supabase. Four-language (EN source plus RU/UZ) option cardinality/numeric token comparisons showed no confirmed semantic discrepancy; the one number-token flag was equivalent Russian wording «трёхзначного» for English «3-digit». Every MCQ retains four distinct literal alternatives. No learner data or published content was changed.

Cumulative current audit coverage is now **360/1,448 reviewed**, **1,088 remaining**; do not call this independent human certification or a full end-to-end exam validation.

## 2026-10-31 P5 Data & Statistics second-pass batch

The 150 current P5-DAT-01 to DAT-10 source questions (60 published and 90 reserve) were read individually, checking chart selection, stem-and-leaf, box plots, histogram frequency density, cumulative frequency, means, spread transformations, comparison of datasets, sums-of-squares variance and grouped/coded means. Ten **independent mathematical/conceptual source-level oracle SQL fixtures** compared 15 answers per skill against current keys; **all 150 matched** when executed read-only on Supabase. Numeric expressions are independently derived from source stems; some chart-selection and interpretive answers are textual, and are reviewed semantically instead of being called numerical calculations. The ten live fixture runs returned zero flagged discrepancies.

EN/RU/UZ option counts and non-empty stems/explanations all passed; no repeated literal alternatives or invalid keyed choice was found. Six numerical-option false-positive flags are caused by the translated paraphrase 'middle 50%' where EN describes 'middle spread', not by mathematical differences. Six numerical-stem false positives arose from spelled-out English numbers or equivalent notations x̄² versus mean². No confirmed error requiring an immutable replacement was found. Published questions, reserve content, academic QA statuses, and student state were **not modified**.

Overall reviewed **510/1,448** current items; **938** remain. This coverage counts independently derived answer oracles and manually inspected conceptual alternatives, not an external human examination, not exhaustive proof of correct translation semantics, and not learner E2E or weekly beta authorization.

## 2026-10-31 Discrete Random Variables — final P5 question-bank family

All 45 P5-DRV-01, DRV-02 and DRV-03 questions (18 published and 27 reserve) were independently recomputed or semantically reviewed: probability normalization, distribution validity, linear expectations, expected payoffs, E(X²)−E(X)² and standard deviations (including square-root and fractional exact forms). Three independent live SQL source-key fixtures each returned **15 checked, zero mismatches**. Their numerical oracles parse exact fractions separately; descriptive or radical-text keys are checked explicitly with separate numerical computation. EN/RU/UZ stems, explanations and MCQ choices were inspected for completeness and number consistency; zero missing translations or option-number mismatches, zero duplicate literal alternatives and zero invalid MCQ answer keys. No confirmed mathematical defects requiring correction, so source rows were not rewritten.

**P5 question-bank scope milestone:** All 540 published/reserve P5 questions across 36 skills have now undergone a second academic review by AI with formula recomputation for numerical questions and concept/choice review for model questions. This is **not** a completed review of the 103 current written P5 tasks, not human academic certification, and does not authorize a general learner rollout. Total current-item ledger: **555/1,448** (540 P5 question-bank + 15 P1 question-bank), with **893 pending** (660 P1 question-bank + 233 current written P1/P5 tasks). Historical source versions and 1,990 recorded learner responses/548 sessions were not altered by this read-only batch.

## 2026-11-01 P1 Circular Measure and Quadratics second-pass batch

The 120 current published/reserve questions (48 published, 72 reserve) across P1-CIR-01/02 and P1-QUA-01..06 were read at the level of original English stems, keyed options and English solution explanations. Independent checks include degree/radian conversion, arc length and sector perimeter, completing squares, vertex extrema, discriminant and tangency boundaries, real-root solutions, strict/non-strict polynomial inequalities, simultaneous intersection systems and quartic substitutions. Eight read-only live Supabase source-level oracle SQL fixtures each returned **15 checked and 0 mismatches**. Independent arithmetic/algebraic property checks are also supplied in a separate Node regression test; these are a second method beyond checking the database's saved key.

All 120 question prompts, explanations and options are present in EN/RU/UZ; no invalid MCQ answer index, duplicate literal option, locale-option number change or differing inequality symbol was flagged. These checks do not prove exhaustive semantic equivalence of all translated wording. No confirmed mathematical defect requiring a source replacement was discovered in this batch.

Cumulative current-item second-pass coverage: **675 / 1,448**, comprising **540 P5 bank, 135 P1 bank and 0 full written-task solutions** in this second-pass counting methodology; **773 pending** (540 current P1 bank + 233 current written P1/P5 tasks). Previous written-task repair and structural QA do not silently count as full independent written-solution review. Historical learner answers/sessions, mass rollout NO_GO and skipped learner E2E/beta remain unchanged.

## 2026-11-01 P1 Trigonometry & Series academic corrections

**Discovered and repaired a substantive live mathematical key defect** in published `P1TRI02-A01` (`public.questions.id=7142`): the question explicitly asks `sin 210°`; keyed option **C = −√3/2** was wrong while the explanation correctly shows `sin(180°+30°)=−1/2`, which is **option A**. This is not a translation or formatting issue: it could incorrectly score a learner. Confirmed zero related session items, zero existing learning-pack sessions/authorizations/goal snapshots/review starts. Cloned Q**10101** with key **A**, all three language alternatives and explanations intact, governed content-key `P1TRI02-A01-QA20261101` and assessment **466/v2** with all other items unchanged. Old source question was **not overwritten**; old content meta and unused assessment **35422/v1** were retired. Single-transaction guarded versioned repair was executed and the separate read-only live postflight **PASSED**; explicit provenance is owner-requested AI-assisted verification, not human approval.

The 150 current P1-TRI-01..05 and P1-SER-01..05 source questions (60 published, 90 reserve) were independently examined: ranges, principal-value inverse functions, exact special angles, trigonometric identities and interval boundary solutions; binomial coefficients, AP/GP classification, nth terms, finite sums, convergence and infinite tails. Two read-only source-key fixtures completed **75/75 TRI and 75/75 SER with zero mismatches AFTER correction**. Additional numeric/symbolic regression includes independent trigonometric values, degrees-to-radians, exact radicals, polynomial convolution, arithmetic/geometric sums and enumeration of inclusive vs strict solution domains. The key fixtures are compared to independently reviewed solutions, not treated as mathematical proof by themselves.

EN/RU/UZ checks for all 150 confirmed no missing stems/rationales, invalid choice indices, repeated literal alternatives, option numeric mismatch, or mismatch in inequality signs. Two stem-number lexical differences for `P1TRI03-M01` are equivalent instructions: “1 decimal place” vs “0.1° precision”, **not** a proven translation error. Full human semantic qualification is unavailable. P1 current bank still has **390 unchecked questions**. Total reviewed second-pass current items: **825/1,448**; **623 outstanding (390 P1 bank + 233 written)**. Old student state and mass launch NO_GO remain untouched.

## 2026-11-01 P1 Functions and Coordinate Geometry second pass (210 items)

A previously blocked Supabase connector **recovered** and a read-only SELECT 1 healthcheck succeeded. Review used **live current Supabase question text and answer keys**, not just historical GitHub migrations. P1-FUN two 60-key fixtures and P1-COO two 45-key fixtures compare independently read/derived answers with actual live published/reserve answer options; **all four executions returned zero discrepancies** (60/60 + 60/60 + 45/45 + 45/45). FULL JOIN detects missing/extra keys. Independent numeric regression includes inverse functions, quadratic restricted extrema, line gradients and intercepts, midpoint, circle equation, perpendicularity, chord lengths, tangency, and point transformations.

A separate live EN/RU/UZ inspection covered all 210 stems, explanations, four MCQ alternatives, key type, literal/numeric duplicate alternatives, numerical and inequality-sign agreement. Results: zero missing locales, zero bad choice structures, zero duplicate lists, zero mismatched stem numbers/operators. One Russian variant for P1FUN08-L02 adds the equivalent words “в 4 раза” to scale factor 1/4; this is semantically consistent. Previously fixed P1FUN06-A01 now correctly keys left/down; the P1FUN05-A02 intersection explanation in the live database contains the repaired derivation. No new mathematically confirmed defect; **no production content mutation**.

**Cumulative review: 1,035/1,448 current items; 413 pending** (105 P1 Differentiation, 75 P1 Integration, 233 current written P1/P5 tasks). This is AI-assisted academic QA, not independent human certification. Automated property calculations independently check representative mathematical problems; they are not a full proof that every translated sentence is equivalent. Learner E2E/beta stages remain incomplete. Mass rollout remains NO_GO; student progress must stay immutable.

## 2026-11-01 P1 Differentiation and Integration — complete question-bank second pass

All 105 P1-DIF-01..07 and 75 P1-INT-01..05 questions, across published and reserve, were independently solved from their live English question stems and all four English choices (or exact input). A frozen 180-item key oracle was compared read-only with actual live production question IDs/keys using FULL JOIN: **180 checked, 0 mismatches**, including input fractions/signs. Additional independently implemented numerical differentiation, definite integration, convergence-safe improper integral, geometric area and volume tests are in the Node regression. Live RU/UZ stems and explanations and EN/RU/UZ option structures: **180/180 present; 0 invalid option lengths; 0 duplicate literal MCQ options**. Eighteen numeric-token/notation translation flags were individually inspected; they reflect comma-vs-dot decimals, mathematical exponents or equivalent bounds, not proven translation defects. This is AI-assisted academic QA, not a human examiner sign-off and not exhaustive human translation proofreading.

**Syllabus scope check:** Official Cambridge 9709 syllabus v3 (2026–2027), section 1.8 printed page 22 explicitly includes simple improper integrals such as x^(-1/2) from 0 to 1. Therefore current x^(-1/2) from 0 to 4 examples are within scope; no edits or forced retirement. Source: https://www.cambridgeinternational.org/Images/697427-2026-2027-syllabus.pdf .

**New cumulative status:** **1,215/1,448** current items independently reviewed by AI: all **675 P1 and 540 P5** multiple-choice/input sources, with **233 written tasks (130 latest P1 + 103 latest P5)** remaining for independent complete solution/rubric examination. Old versions, 1,990 learner responses and 548 sessions unchanged. Mass rollout still **NO_GO**; previously deferred learner E2E/beta phases not revived.

## 2026-11-01 P1 Calculus written tasks — 39 current latest versions

Second-pass written-solution and marking audit for **22 Differentiation and 17 Integration** current tasks, including full-paper mixed sets. Each English prompt and rubric criterion was inspected against derivative rules, stationary classification, related rates, reverse chain rule, boundary/infinite-limit handling, signed versus total area and disk volume computations. An independently derived representative numerical/exact result per task was confirmed against the current rubric via a reproducible **39/39 live read-only FULL JOIN**; **0 rubric-answer, missing-locale, max-mark sum or expected-key discrepancies**. Node numerical calculation also checks representative full task solutions rather than only stored answer text. No new confirmed mathematical error requiring versioning. This remains AI-assisted math review; it is **not** examiner-human signoff, not proof of complete English/Russian/Uzbek mathematical prose equivalence, and not E2E beta evidence.

**Progress:** **1,254 / 1,448** independently reviewed current academic items; remaining **194 written tasks (91 P1, 103 P5)**. No question/task revisions, learner history, feature flags, scoring authority or rollout state changed. Mass rollout remains NO_GO.
