# Mathematics Practice v2 — Global QA, Evaluator & Runtime Security Audit

Date: 2026-10-07  
Branch: `work/mathematics-practice-v2-refresh-20261006`  
Production database writes from this work: **NONE**

## 1. Global P1 content gate

The complete P1 Practice v2 bank is now present in the work branch:

- 495 original questions
- 45/45 canonical P1 skills
- 277 MCQ
- 218 scalar input
- 124 easy / 226 medium / 145 hard

Global MCQ correct-position distribution:

- A = 68
- B = 69
- C = 70
- D = 70
- longest same-letter run = 2

The global guard runs every module guard first and then checks the whole bank for:
- module totals;
- Q001–Q495 continuity;
- all 45 canonical skills;
- duplicate keys/stems/options;
- EN/RU/UZ completeness;
- input-contract restrictions;
- diagnostic skill boundaries;
- correct-option position balance/cycles.

Latest GitHub Actions global QA run: **PASS**.

## 2. Evaluator regression

Added:
`scripts/math-practice-v2-evaluator-regression.cjs`

Latest CI result:

- input questions = 218
- authored accepted cases checked = 478
- authored rejected cases checked = 654
- Unicode-minus accepted cases = 25
- errors = 0

A branch-only database migration was prepared:
`20261007002000_math_practice_v2_unicode_minus_normalization_v1.sql`

It changes only the shared answer-normalisation helpers so `−`, `–`, and `—` are normalised to ASCII `-`, while retaining current comma-decimal, whitespace and lowercase behaviour.

A SQL regression file was also added:
`supabase/tests/math_practice_v2_unicode_minus_normalization_v1.sql`

Neither migration nor test has been executed against production.

## 3. Frontend Unicode-minus gate

The current app validates numeric Practice input client-side before sending it to the deterministic server evaluator. That validator previously rejected Unicode minus.

Instead of rewriting the large production `app.js` file, a narrow capture-phase normaliser was added:

`security/practice-v2-input-normalization.js`

It changes Unicode minus/dash characters only when:
- the target is `#practice-input`; and
- the whole candidate value is numeric.

Text/token answers are therefore not globally rewritten.

The script is wired before `app.js` in `index.html` and is covered by the Practice v2 CI workflow.

## 4. Production answer-key exposure audit — READ ONLY

Production metadata was inspected without writes.

### Direct table path

`public.questions`:
- RLS = enabled
- authenticated SELECT = false
- anon SELECT = false
- no learner SELECT policy found

No public VIEW exposing a `correct_answer` column was found.

Therefore the current learner cannot read the raw `questions.correct_answer` column directly through normal authenticated/anon table access.

### Current session-bound Practice path

`get_practice_session_resume_safe_v4`:
- requires the session to belong to `auth.uid()`;
- returns `correct_answer` and explanation only after that exact question already has a saved answer.

`submit_practice_session_answer_safe_v4`:
- requires owned session;
- requires the question to be in that server-created session;
- evaluates server-side;
- first answer is idempotently stored;
- only then returns correctness/correct answer/explanation.

This path satisfies the pre-answer answer-key boundary.

## 5. Legacy answer-oracle exposure found

Three older authenticated RPCs remain executable in production even though the current frontend does not use them:

1. `submit_practice_attempt(...)`
   - can construct a legacy attempt from arbitrary active question IDs of the chosen subject.

2. `submit_practice_answer_safe(...)`
   - can evaluate an arbitrary active same-subject question inside an owned legacy attempt.

3. `get_practice_review_safe_v4(...)`
   - is older than the protected-question-aware full review path.

Together, the first two can act as an answer oracle outside the current session-membership contract.

A branch-only migration was prepared to revoke authenticated direct execution:

`20261007003000_math_practice_v2_close_legacy_answer_oracles_v1.sql`

Trusted postgres/service-role compatibility remains. The current safe v4 finalizer can continue its internal server-side compatibility call after learner EXECUTE is revoked.

Regression file:
`supabase/tests/math_practice_v2_legacy_rpc_exposure_v1.sql`

Not applied to production yet.

## 6. Topic-drill bypass found and hardened in v5

The current `start_practice_topic_drill_safe_v4` selects any active same-subject question matching topic/subtopic, except protected Tour questions. It does **not** require the question to belong to an available Practice pool.

That can bypass Practice pool/tour availability semantics.

Prepared v5:
`20261007005000_math_practice_v2_topic_drill_pool_gate_v1.sql`

`start_practice_topic_drill_safe_v5` requires:
- active Practice pool membership;
- pool availability under current season/tour timing;
- existing protected-Tour question guard;
- for Practice v2 metadata rows: `lifecycle_state='published'` and `is_runtime_allowed=true`.

The work-branch safe frontend adapter now targets v5. Production is unchanged.

Regression file:
`supabase/tests/math_practice_v2_topic_drill_pool_gate_v1.sql`

## 7. Practice v2 private metadata foundation

Prepared:
`20261007004000_math_practice_v2_metadata_foundation_v1.sql`

Private governed tables:
- `private.practice_v2_question_meta`
- `private.practice_v2_diagnostic_catalog`

They carry stable content key, Practice number, canonical skill, secondary skills, granular role, source reference, answer contract, content hash, QA states and runtime/lifecycle gates.

No learner access is granted to these private tables.

This provides the missing server-side structure required for a skill/role-aware selector without putting governance metadata in browser payloads.

## 8. Main Practice selector v5

The production v4 selector is mostly difficulty-driven: 3 easy + 5 medium + 2 hard plus random fill.

Prepared:
`20261007006000_math_practice_v2_selector_v5.sql`

The new selector keeps the same server-owned 1–10 question session contract and existing Tour lock behaviour, but within difficulty buckets it also uses:

- canonical skill round-robin before repeating one skill;
- previous wrong-skill history;
- exact question wrong history;
- lower exposure to the same authored role;
- transfer-capable role preference, especially for hard items;
- exclusion of questions already answered correctly;
- Practice v2 published/runtime metadata gate.

It writes into the existing `practice_sessions_v4`, so resume/submit/finalize ownership and evidence contracts stay unchanged.

Regression file:
`supabase/tests/math_practice_v2_selector_v5.sql`

The work-branch frontend adapter now targets:
- `start_practice_session_auto_safe_v5`
- `start_practice_topic_drill_safe_v5`

while resume/submit/finalize remain on the already-hardened v4 contracts.

## 9. CI status

`.github/workflows/math-practice-v2-global-qa.yml` now gates:
- all 7 module guards;
- 495-item global guard;
- 218-input evaluator regression;
- Unicode-minus frontend normaliser syntax/wiring;
- safe assessment adapter syntax/wiring;
- main selector v5 wiring;
- topic drill v5 wiring;
- absence of direct legacy answer-submission RPCs from the frontend adapter.

Latest run after v5 wiring: **PASS**.

## 10. Release status

Content production: **COMPLETE**  
Global content QA: **PASS**  
Target evaluator simulation: **PASS**  
Frontend minus normalisation: **PREPARED + CI PASS**  
Legacy RPC closure: **PREPARED, DB integration not run**  
Private metadata foundation: **PREPARED, DB integration not run**  
Topic drill v5: **PREPARED, DB integration not run**  
Main selector v5: **PREPARED, DB integration not run**  
Production migration/release: **NOT STARTED**

Next gate: build the deterministic 495-question staging/import package, validate it against the live dependency/Tour invariants in READ ONLY mode, then run the migrations and import only in a controlled release sequence after final preflight.
