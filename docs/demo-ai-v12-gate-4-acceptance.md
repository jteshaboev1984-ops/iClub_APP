# iClub APP — Demo AI v1.2 — Gate 4 acceptance

Date: 2026-07-10
Branch: `demo-ai-v12`
Route: `/diagnostic-demo.html`
Rollback checkpoint before Gate 4: `47b26280dadcfb3f5ca13c82b28cef6b184a7891`

## Scope completed

- Added a deterministic skill map for the seven current diagnostic questions and the historical Economics evidence.
- Added option-level distractor diagnosis for every option in the seven-question route.
- Added one synthetic timeline shared by all plans:
  - Practice 1 — 10/10;
  - Practice 2 — 10/10;
  - Practice 3 — 10/10;
  - closed Tour 4 — 6/20;
  - Practice 4 after the tour — 10/10;
  - current seven-question diagnosis — dynamic.
- Added question-level Tour 4 evidence with exactly 20 answers and 14 historical errors.
- Added question-level Practice 4 evidence with exactly 10 correct answers and a deliberately different skill coverage.
- Added the approved skill statuses: `insufficient`, `needs_verification`, `current_session`, `new_question`, `delayed`, and `transfer`.
- Added repeated-error and positive-signal rules based on actual current answers.
- Added explicit unverified Tour 4 errors which were not rechecked by Practice 4 or the current diagnosis.
- Added 10 verified reinforcement questions and deterministic targeted-set selection.
- Added `what_can_be_concluded` and `what_cannot_be_concluded` output with evidence IDs.
- Added confidence calculation and claim-to-evidence mapping.
- Added a layered Pro trajectory UI:
  - brief conclusion;
  - basis and attempt timeline;
  - skill evidence and statuses;
  - confused concepts;
  - improvements;
  - unverified errors;
  - permitted and prohibited conclusions;
  - targeted verified set.
- Added Diagnostic Engine details to the hidden technical panel.

## Key acceptance cases

### Approved demo path

The engine detects repeated confusion across utility, indifference curves, allocative efficiency, productive efficiency and firm growth. Confidence becomes `high`, and the targeted set prioritises those unresolved skills.

### Manual correction of question 5

Changing question 5 from `B` (`TR = TC`) to `A` (`P = MC`) removes the repeated-error state for `allocative_efficiency_condition` and changes it to a `new_question` positive signal. The targeted set narrows accordingly.

### Practice 4 versus Tour 4

The engine does not compare 100% and 30% as if they measured the same material. It checks skill coverage and reports that Practice 4 did not independently recheck the majority of Tour 4 errors.

## Deterministic contract

The engine returns structured data containing:

- `historicalSummary`;
- `currentAttemptSummary`;
- `skills`;
- `pairs`;
- `repeatedErrors`;
- `positiveSignals`;
- `whatCanBeConcluded`;
- `whatCannotBeConcluded`;
- `targetedQuestionIds`;
- `confidence`;
- `claimEvidence`.

The language model does not calculate score, correctness, skill status, confidence, evidence or targeted question IDs.

## Safety

- Production Supabase is not loaded.
- Production reads/writes remain 0.
- No real learner identifiers are used.
- Demo writes only to `iclub_demo_v12.*`.
- The reinforcement set contains no active-tour question.
- CSP remains `connect-src 'none'`.
- `main` is unchanged.

## Checks completed

- JavaScript syntax checks passed locally for Gate 4 data, engine and UI modules.
- Static validation passed: Tour 4 = 6/20, Practice 4 = 10/10, Tour 4 errors = 14.
- Reinforcement validation passed: 10 unique verified IDs, no active-tour item.
- Approved-path deterministic test passed.
- Question-5 manual-correction test passed.
- Vercel preview deployment succeeded.
