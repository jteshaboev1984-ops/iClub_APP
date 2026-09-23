# P5 language and notation remediation (DRAFT, 21 Sep 2026)

Related: #137 (ten untranslated prose-choice questions in the original P5 slice), #139 (seven NOR-06 notation/English-term defects), #126 (separate human composition-approval provenance), #136 (written-rubric languages). **Not a production migration or academic approval.**

## Verified scope: opening Representation sets (#137)

- Ten question IDs carry English-language prose in RU/UZ MCQ answer options: 6249, 6250, 6251, 6252, 6253, 6254, 6258, 6267, 6268, 6269. Four other MCQ option arrays in those eight sets are numeric-only and do not require translation. Six identical-option matches elsewhere are purely symbolic/numeric controls; do not count them as ten more failures.
- One finalized P5 diagnostic session has one frozen affected item and one saved answer; none of the original eight assessments was active at the inspection instant. All observed Exam Prep sessions belong to the three active beta accounts, which the owner identifies as the owner's test accounts. This is **not** a blanket authorization to delete accounts or unrelated data.
- Two retest question IDs 6249/6251 are also in single-retest sets; mixed question IDs 6267/6268 are also in canonical mixed sets. Verify all original and downstream memberships. Keep diagnostic/retest/holdout materials confidential.
- Legacy `public.questions` rows remain intentionally `is_active=false`, `quality_status='draft'`; private content metadata controls Exam Prep. Never activate them for Practice/Tours.

## New independent scope: P5 NOR-06 (#139)

- Scan of 252 unique published P5 questions found seven IDs 6830–6836 in content version `p5_aw21_24_nor06_v1` whose RU/UZ stems still contain English `normal approximation`; five also contain English `continuity correction`. Six Russian stems have the malformed-looking two-parameter binomial notation `Bin(n,0,d)` (extra comma after decimal localization). The seventh question, 6835, has the same issue in all four RU answer options. The Russian explanation of 6835 inherits it too. Uzbek uses decimal points in these binomial expressions.
- Rule: mathematical `Bin(n,p)` must remain an unambiguous **two-argument** expression, preferably retaining the decimal point inside the function across EN/RU/UZ. Standalone displayed decimal answers can be localized only when accepted by the learner-facing validator and no delimiters become ambiguous. Reviewers must verify the notation and `N(mean, variance)` convention, continuity bounds and numerical choices.
- A conservative copied-prose heuristic also flagged `Geometric(p)` in item 6603. This can be valid conventional distribution notation and is **not** counted as a confirmed translation defect. Reviewer to decide if notation is acceptable.

## Prepared but deliberately NOT committed to this public repository

Two private reviewer-only candidate files exist outside the repo:

- `p5_ru_uz_options_candidate_20260921.json`: exact source EN option order, ten proposed RU + UZ option arrays (80 localized choices); question stems and keys stay unchanged at proposal stage. One mixed source stem may ambiguously connect its mean calculation with subsequent median/spread comparison; do not silently rewrite it.
- `p5_nor06_localization_candidate_20260921.json`: seven proposed RU/UZ stems with consistent `Bin(n,p)` notation; two proposed RU option arrays and limited revised explanations where mathematical notation or mixed-language wording requires it.

Both are **AI-prepared drafts**, not reviewer approval. Actual texts, answer positions and other protected assessment content must not be copied into public PRs/issues/CI fixtures. Independent mathematician plus RU/UZ linguistic reviewer must verify and provide attributable, genuinely dated sign-off before live use.

## Release approach — no authorization yet

1. Fresh SELECT-only preflight must pin all 17 exact question IDs, source hashes, assessment memberships, lesson links, active/finalized sessions and test-account ownership, compare approved source/translation candidates and check for new non-test usage. If assumptions changed, stop; do not infer disposability from three account membership counts alone.
2. Verify the entire P5 mathematical meaning, response options/distractors, unchanged correct position, RU/UZ mobile readability, numeric notation and P1/P5 separation. #126 composition-level approval and #136 rubric localization are independent and cannot be replaced by content QA flags or green CI.
3. Owner permits not retaining specifically scoped Exam Prep test attempts, but this does not imply wholesale deletion. In-place change is acceptable only after establishing frozen-session/API/metadata hash contracts or obtaining a separately approved reset limited to affected **Exam Prep test records**; otherwise create a new content/question version. Never alter Practice, Tours, rankings, certificates, accounts, unrelated questions, or original migrations. Never backdate `approved_at` or fabricate a reviewer.
4. Build one atomic, repeatable, expected-old-value/expected-hash guarded migration; block concurrent affected active sessions and preserve diagnostic/retest confidentiality. Test realistic PostgreSQL replay, full recovery/rollback, locale rendering, input evaluation, old/future sessions and unrelated-data fingerprints on a disposable database. No production DML or merge/deploy without separate explicit owner approval.
5. Reconcile all seventeen candidate changes with actual academic reviews and the *current* production baseline, then monitor production after any authorized release. No silent feature-flag or beta enrollment changes.

## Preventing recurrence

Synthetic helper `scripts/exam-prep-p5-option-language-guard.cjs` flags unchanged English **prose** answer choices, excludes numeric/formula-only candidates including conventional distribution-function notation, and independently flags ambiguous `Bin(n,0,d)` and English `normal approximation` / `continuity correction` in RU/UZ stems. CI contains only fabricated fixtures; it does **not** read production or install the gate in the current publishing pipeline. A reviewed future private publisher must invoke these checks plus human three-language QA before marking future content approved/published.

**State:** 17 candidate items identified across two distinct defects, private translation drafts prepared, synthetic regression available. NO production SQL, test deletion, academic sign-off, release or learner-data changes.
