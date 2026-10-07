# Mathematics Practice v2 Refresh — Working Plan

Status: ACTIVE  
Branch: `work/mathematics-practice-v2-refresh-20261006`  
Baseline main SHA: `823ef7df6dabf08c1a5e616ffbdd33379d8cf14d`  
Owner decision: preserve Tour results/history as the protected user-data boundary; Mathematics Practice may be rebuilt and its progress may be reset as part of the announced update.


## Current checkpoint — 2026-10-07

- Block 1 Content Architecture 2.0: COMPLETE / gate passed.
- Block 2 full P1 content production: COMPLETE — 495 original items across all 45 canonical P1 skills.
- Global content QA: PASS — 277 MCQ / 218 input; difficulty 124/226/145; A/B/C/D=68/69/70/70; max same-letter run=2.
- Input evaluator regression: PASS across all 218 input questions, 478 accepted cases, 654 rejected cases and 25 Unicode-minus cases.
- Deterministic diagnostics, EN/RU/UZ, Practice↔Tour separation and AI source-card coverage are complete for all seven Practices.
- Block 3 migration/cleanup design: REVISED / COMPLETE. Owner explicitly approved a Mathematics Practice reset. Legacy Practice progress/history is deleted at cutover; legacy Practice questions are cleaned up after post-publish smoke QA, except any row still referenced by Tour or another protected system.
- Live production baseline rechecked READ ONLY: 7 active Mathematics Practice pools, 490 active memberships, zero active Practice↔active Tour overlap.
- Protected Mathematics Tour baseline: 14 Tours, 300 Tour memberships, 149 attempts, 2477 answer rows. Deterministic fingerprints recorded in `docs/mathematics-practice-v2-live-production-baseline-2026-10-07.md`.
- Current legacy Mathematics Practice reset scope at the latest READ-ONLY baseline: 411 attempts and 4074 answers. This Practice-only progress is intentionally disposable; Tour progress is not.
- Current Mathematics v4 session/drill rows at baseline: 0 / 0. Under the approved reset policy, any legacy Practice session that appears before cutover is intentionally cleared rather than carried across.
- Additive branch-only runtime hardening prepared: Unicode-minus normalization; legacy answer-oracle closure; private v2 metadata; pool-gated topic drill v5; skill/role-aware selector v5; current-bank mistakes v5; deterministic post-answer feedback/finalizer/review v5. Mathematics v5 fails closed against metadata-less legacy questions during the deploy→publish cutover window, preventing new old-bank Practice state after the one-time browser reset.
- Deterministic 495-question staging generator prepared with per-Practice contiguous order and invisible staging gates.
- Reset-aware atomic publish prepared. In one transaction it fingerprints Tours, deletes legacy Mathematics Practice progress/runtime rows, disables the 490 old memberships, publishes 495 new memberships, and proves the Tour fingerprint is unchanged. It contains no Tour DML.
- READ-ONLY schema compatibility preflight, release preflight, post-publish/reset audit, post-cleanup audit and post-rollback audit are prepared. The live schema compatibility preflight was executed against production READ ONLY and passed.
- Controlled release runbook revised to the simple reset model: Tour results stay intact; Mathematics Practice starts fresh on the new bank.
- Latest Mathematics Practice v2 Global QA run after release-safety and UI fallback checks: PASS (run 51). Staging manifest hash: `da7ae9cc9987df4d4655e880157c03611a842abba6663d4c3366932293144383`; 495 questions; 201 diagnostic catalog entries; 868 diagnostic mappings.
- Production/Supabase writes from this Practice v2 work: NONE. All migrations/content remain branch-only.
- Block 4 implementation package is prepared. Current branch QA is run against current `main` through the draft integration PR; no separate Supabase branch is required.
- Next macro gate: finish integration QA against current `main`, recheck production READ-ONLY, then run the controlled production sequence: additive migrations → invisible staging → read-only preflight → reset/publish → smoke QA → safe legacy-question cleanup.


## Purpose

Rebuild Mathematics Practice so that:

- Practice teaches from the approved source/canonical skill map.
- Tour independently checks knowledge and transfer.
- Deterministic server logic decides correctness and any established diagnostic rule.
- AI Tutor only explains/personalizes already-established facts from approved, versioned iClub source cards.
- Core remains fully usable when AI is OFF/unavailable.
- Existing Tour results remain unchanged and auditable.

## Non-negotiable invariants

1. Tour history is protected.
   - No retroactive score recalculation.
   - No rewrite of submitted Tour answers.
   - No loss of Tour attempts, scores, certificates or downstream Tour-derived history.
   - Any legacy question needed to interpret preserved Tour history remains available as historical data even if removed from future learner-facing content.

2. Practice is intentionally reset for this release.
   - Legacy Mathematics Practice attempts, answers, diagnoses, sessions, Practice review events, Practice-derived recommendations, Practice-derived learning roadmaps/AI diagnosis snapshots and local Practice history do not need to be preserved. Tour-derived recommendations, Tour-derived learning roadmaps and Mathematics certificates remain protected.
   - Weak legacy Practice questions do not remain learner-facing.
   - Physical deletion of legacy question rows happens only after the new bank passes smoke QA and only when no Tour or other protected dependency references them.
   - Any question referenced by Tour remains in the database even if its old Practice membership is removed.

3. Academic authority boundary.
   - Correctness = deterministic evaluator.
   - Error/weak-skill label = deterministic rule or explicit unmapped.
   - AI must never decide correctness, invent a misconception, change mastery/progression/readiness/marks/grade, alter P1/P5 mapping, or create evidence.
   - AI output is optional and disposable; Core must continue identically in academic state with AI OFF.

4. Source boundary.
   - Coursebooks/Cambridge materials may guide content authoring and mapping.
   - Learner-facing AI runtime uses only approved, versioned iClub source cards and deterministic context.
   - No open-web learner RAG in governed Mathematics.
   - No protected coursebook/past-paper/mark-scheme content in runtime unless explicitly approved by rights/workflow.
   - Missing or conflicting approved source => no_source / deterministic fallback.

5. Active assessment protection.
   - Active Tour/protected assessment gets no targeted solution, answer check, tailored hint, next step, option elimination, paraphrased answer, or answer-key retrieval from AI.
   - Guard is server-derived and runs before cache/retrieval/model.
   - Post-submit explanation only when server eligibility permits it.

6. Answer-key security.
   - Pre-answer client/model payloads do not expose correct_answer, private diagnostics or post-answer explanations.
   - Server validates user/session/question membership and evaluates answers.

7. EN/RU/UZ equivalence.
   - Same mathematics, numbers, constraints, answer space, difficulty, diagnostic meaning and academic conclusion in all three languages.

## Target learning chain

Practice 1 -> Ch1 -> Quadratics  
Practice 2 -> Ch2 -> Functions & transformations  
Practice 3 -> Ch3 -> Coordinate geometry  
Practice 4 -> Ch4-5 -> Circular measure + Trigonometry  
Practice 5 -> Ch6-7 -> Binomial + Series  
Practice 6 -> Ch8-9 -> Differentiation  
Practice 7 -> Ch10 -> Integration

Practice teaches. Tour checks independent recall/application/transfer.

## Question design standard

A new question is publishable only when all required contracts are defined together:

- canonical skill / same-component secondary skill mapping;
- source reference;
- difficulty based on reasoning demand, not bigger numbers;
- question role: direct application / variation / misconception trap / reverse problem / transfer / mixed;
- qtype;
- answer contract;
- deterministic explanation;
- diagnostic mapping for intentional wrong paths, otherwise unmapped;
- safe fallback feedback;
- EN/RU/UZ mathematical equivalence;
- technical validator tests;
- optional approved source card for AI/theory/error explanation.

### MCQ standard

- Exactly one unambiguous correct option.
- Every wrong option must be mathematically plausible and, when tagged diagnostically, intentionally correspond to a reviewed misconception.
- A distractor that does not prove a specific misconception must not produce a specific diagnosis.
- Options must not leak the answer by length, grammar, sign convention, units, formatting or repeated wording.

### Input standard

Input is used only when deterministic evaluation can accept all intended mathematically correct representations and reject incorrect ones.

Do not publish free input merely because it looks educational. If equivalence is unsafe:
- narrow the requested answer to a scalar/unique object;
- or use a properly designed MCQ;
- or first implement and validate a dedicated evaluator contract.

## Explanation standard

Core explanation must work without AI.

Correct answer:
- concise principle;
- application to the current task;
- result/check when useful.

Wrong answer with established diagnostic:
- what the submitted answer demonstrates;
- why that step is wrong;
- correct principle/next step;
- concise worked correction.

Wrong answer without defensible diagnostic:
- no invented cause;
- explicit generic/unmapped feedback;
- correct principle and safe next step.

AI may only explain/rephrase this established state using approved sources.

## Anti-pattern / primitive-error QA

Every generated batch must pass mechanical checks before academic review.

Mandatory checks include:
- correct MCQ option distribution is reasonably balanced across A/B/C/D over each sufficiently large batch;
- reject obvious patterns such as all/mostly A, cyclic ABCD repetition, long runs of the same correct letter, or a correct-letter pattern correlated with difficulty/topic;
- no duplicate or near-template-copy questions unless intentionally distinct by learning role;
- no same stem with only coefficient swaps presented as transfer;
- no duplicate option text;
- no two mathematically correct options;
- no correct option consistently longest/shortest/most precise;
- no distractor equal to correct answer after normalization;
- no answer leakage in wording/image/units;
- no unsupported hard label for routine one-step work;
- no silent out-of-P1 scope content;
- no Practice/Tour cloning that lets memorization replace transfer;
- all accepted input variants tested;
- representative rejected input variants tested;
- Unicode minus, decimal separator, whitespace and renderer-safe notation tested where relevant;
- every image/diagram checked against all language variants and mobile rendering.

## Work blocks

### Block 1 — Mathematics Content Architecture 2.0
Deliver the complete 7-Practice blueprint:
- canonical skill coverage;
- learning sequence;
- question-role allocation;
- target difficulty distribution;
- qtype strategy;
- answer/evaluator contracts;
- misconception taxonomy;
- Core explanation standard;
- AI source-card needs;
- Practice-to-Tour transfer specification.

Gate: architecture cross-checked against syllabus/source map, Content Governance and AI Safety Architecture.

### Block 2 — Full content production
Produce the new Practice bank with:
- original questions;
- deterministic answers/evaluator contracts;
- reviewed distractors;
- diagnostic rules;
- deterministic explanations;
- EN/RU/UZ;
- source cards;
- diagrams/assets where needed.

Gate: batch mechanical QA + mathematical QA + language QA + source/provenance QA.

### Block 3 — Migration and cleanup design
Before any destructive production change:
- snapshot protected Tour counts and fingerprints;
- identify the exact legacy Mathematics Practice question set;
- reset only Practice-owned attempts, answers, diagnoses, sessions, review events, Practice-derived recommendations and Practice-derived learning roadmaps/AI diagnosis snapshots;
- switch the active bank atomically;
- keep old question rows until the new bank passes smoke QA;
- then delete only legacy question rows with no Tour or other protected reference;
- move Mathematics local Practice history to a new storage namespace and run a one-time pre-app cleanup of stale Mathematics Practice draft/runtime/recommendation state so old browser state cannot reappear; preserve Tour local state and Tour recommendations.

Gate: prove Tour structure/results are unchanged before and after reset, publish and cleanup.

### Block 4 — System implementation and full QA
Implement governed content/evaluator path, then test:
- answer correctness;
- accepted/rejected input variants;
- all MCQ distractors;
- diagnostic feedback;
- AI ON/OFF parity;
- no_source/fallback/provider failure;
- active Tour guard;
- answer-key secrecy;
- EN/RU/UZ;
- mobile;
- reload/resume/retry/idempotency;
- no cross-user leakage;
- no P1/P5 leakage.

Gate: identical deterministic academic result with AI ON and OFF.

### Block 5 — Release
- preserve Tour results and structure;
- stage the new bank invisibly;
- reset legacy Mathematics Practice progress at cutover;
- publish the 495-question bank atomically;
- run post-publish learner smoke QA;
- only after smoke QA, physically clean legacy Practice-only question rows while retaining Tour-linked/protected rows;
- monitor evaluator/feedback anomalies; rollback is available before legacy-question cleanup and does not restore deleted Practice progress.

## Recurring alignment checkpoint

At the end of every substantial block:
1. compare delivered work against this plan;
2. compare against canonical syllabus/source map;
3. compare against Content Governance;
4. compare against AI Layer Safety Architecture;
5. verify protected Tour-history invariant;
6. rerun primitive-error QA, including correct-answer option distribution;
7. record deviations explicitly before continuing.

No deviation is accepted silently.

## Completion condition

This plan stays ACTIVE until all five blocks pass their gates and post-release Tour-history integrity is confirmed. Only then may status be changed to COMPLETE.
