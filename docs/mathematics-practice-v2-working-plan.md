# Mathematics Practice v2 Refresh — Working Plan

Status: ACTIVE  
Branch: `work/mathematics-practice-v2-refresh-20261006`  
Baseline main SHA: `823ef7df6dabf08c1a5e616ffbdd33379d8cf14d`  
Owner decision: preserve Tour results/history as the protected user-data boundary; Mathematics Practice may be rebuilt and its progress may be reset as part of the announced update.


## Current checkpoint — 2026-10-06

- Block 1 Content Architecture 2.0: COMPLETE / gate passed.
- Block 2 content production: IN PROGRESS.
- Practice 1 Quadratics: 68/68 authored across P1-QUA-01…06.
- Second-pass mathematical review: passed after corrections.
- Learner-facing EN/RU/UZ question/option/explanation review: passed for Practice 1.
- Mechanical primitive-error guard: active; current MCQ keys A/B/C/D = 10/10/10/11, longest same-letter run = 2.
- Deterministic diagnostic catalog: 30 reviewed codes; all currently used and skill-aligned.
- Season 2 Tour 1 separation review: completed; overly similar Practice items were redesigned.
- Technical publication status: BLOCKED intentionally until evaluator hardening and accepted/rejected input validation are complete.
- Production/Supabase user data: unchanged by this work.

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

2. Practice may be replaced.
   - Weak legacy Practice questions do not need to remain active.
   - Practice progress may be reset only as an intentional release decision announced to users.
   - Physical deletion of legacy question rows is allowed only after dependency audit proves they are not required by Tour/history/audit integrity.

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
- snapshot protected Tour/history counts and integrity;
- dependency graph for legacy Mathematics question IDs;
- classify legacy question rows: protected historical / reusable / retire / deletable;
- define Practice-progress reset behavior;
- define user communication;
- define rollback/recovery evidence.

Gate: prove Tour history is unaffected.

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
- announce Mathematics Practice reset/update before release;
- preserve Tour results;
- release only after all gates pass;
- post-release integrity check against protected Tour baseline;
- monitor evaluator/feedback anomalies and rollback without rewriting Tour history.

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
