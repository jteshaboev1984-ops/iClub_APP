# Mathematics Practice — diagnostic-only QA and release runbook

Status: **owner-approved diagnostic-only operational procedure (2026-11-21)**; new chats apply it after verifying this document is present in current GitHub `main`. Scope: existing Mathematics Practice v2 **wrong-option feedback / diagnostic-code / next-action** fixes where stems, distractor meanings, answer keys, evaluator, scoring, timing, membership, and learner history stay unchanged. This is **not** automatic approval for another release.

Sources: [AGENTS.md](../../AGENTS.md), [CHAT_PROTOCOL](CHAT_PROTOCOL.md), [WORKSTREAMS](WORKSTREAMS.md), [Practice release gate](../practice-bank-generations-release-gate.md), canonical [Issue #574](https://github.com/jteshaboev1984-ops/iClub_APP/issues/574), actual source generator `scripts/math-practice-v2-build-staging-sql.cjs`. Published precedents: [#628](https://github.com/jteshaboev1984-ops/iClub_APP/pull/628), [#629](https://github.com/jteshaboev1984-ops/iClub_APP/pull/629), [#631](https://github.com/jteshaboev1984-ops/iClub_APP/pull/631). These are **historical receipts**, never live-state proofs.

## Decision boundary before starting

- Read the three mandatory root/workstream instructions from fresh GitHub `main`; inspect the **latest comments** in the canonical Issue, relevant approved academic/source requirements, current PR ownership, main HEAD, branch HEAD, exact-HEAD CI, and current hosted state. Existing QA receipts eliminate *repeated* auditing; they do not eliminate *drift* checks.
- Decide if the actual error is limited to **the explanation attached to an incorrect option**. If stem, option meaning, correct answer, evaluator, score or answer contract changes, **STOP this in-place procedure**: use approved academic review and history-safe versioning/future-only release or the separately authorized correction contract. Existing historical attempts must not be silently reinterpreted or regraded.
- A saved answer or an active session is **not** a reason to leave a demonstrably false explanation unfixed, but neither is it authorization to delete responses. Protect existing legacy/main/drill answers, sessions, progress, Tour results, ratings and certificates.
- Keep the work to one meaningful, nonoverlapping Mathematics Practice batch. No PR-per-question, no stale Draft-stack replay, no broad rewrite of valid shared diagnostics, no other subject, Tours, Exam Prep, or runtime refactor.

## Checklist: reproduce → stage → release → read back

### 1. Independently prove the wrong-option diagnostic is false

1. Locate the **exact active** question ID, question key/skill, wrong option letter, its displayed EN/RU/UZ value and current `diagnostic_code`. Read the corresponding approved shared-catalog `feedback` and `next_action`, not just a label.
2. Mathematically test the proposed misconception against the **specific option**: direct substitution, sign analysis, bounds reversal (which must negate the definite integral), derivative zero at a named stationary point, range/domain, or another appropriate independent method. Check at least one counterexample or direct calculation when possible.
3. Explicitly compare wrong options that **truly do fit** the old diagnostic; leave those untouched. A generic mistake diagnosis must not assert what the student internally did unless the chosen answer actually supports it. Prefer precise, actionable feedback rather than made-up cognitive process.
4. Verify the new explanation and suggested next step in **English, Russian and Uzbek**. Confirm they agree with the actual task and mathematical solution, and do not imply unverified marks or mastery.
5. Separate **proved defects** from plausible but still ambiguous feedback; do not put unproved candidates into the release batch.

### 2. Make one isolated, source-only Draft PR

- Branch from freshly verified main; confirm no other active PR owns the same content/catalog/guard files. Use existing authored `content/math/practice_v2/<module>/<skill>.json` and per-module `diagnostic_catalog.json`. Change only intended wrong-option code links; append minimal new, narrowly correct trilingual catalog entries if a shared definition would otherwise become false elsewhere.
- Leave stems, option text, correct answer, scorer, difficulty, IDs, pool membership, source metadata, timer, answer contracts and prior corrections unchanged. Never edit learner history.
- Extend the **existing** `scripts/math-practice-confirmed10-source-guard.cjs` to allow only the current exact option/ID map while preserving earlier approved published corrections. Use a small independent math oracle in the **existing** Global Practice QA workflow; adapt staging-generator diagnostic catalog counts to the actual new source totals, never weaken guards just to turn CI green.
- Run proportionate exact-HEAD CI: Global Practice QA and the relevant isolated PG17 compatibility/versioning suites. Fix failing tests or evidence; don't call a mock/full-bank JSON check a real authenticated E2E. **Signed JWT→PostgREST→PG17→Chromium** is warranted when runtime, authorization, scorer, sessions/resume, history or progress changes, **not automatically** for diagnostic-only content text.
- A passing test applies to its **tested HEAD SHA** only. Re-run/check after branch edits or material rebases; account for concurrent main merges and actual file overlap.

### 3. Hosted Supabase preflight — **SELECT ONLY**

For the **exact target IDs + option letters**, confirm on the current live DB:

- Every question is published/active, is in **exactly one active Mathematics Practice pool**, has **zero Tour links**, and satisfies the current private QA/runtime eligibility flags. Read current bank totals and MCQ/input distribution as **observed baselines, not hard-coded product norms** (historically 495 total, 277 MCQ / 218 input).
- All old option-specific `rule_json.diagnostic_code` assignments match; their EN/RU/UZ feedback and next-actions match the old approved catalog. Every **proposed new code is absent** unless intentionally handled by a separately reviewed idempotent procedure.
- Inventory existing legacy/main V4/drill answer records and any active sessions **without learner-identifying output**. Record counts of rows, **not numbers of unique students**. No question, Tour or answer data in public Issues, CI logs or artifacts.
- Rebuild and compare each **existing canonical SHA-256** question content hash from the *actual stored* question/meta fields and per-option diagnostic codes. Use the repository generator’s **recursively key-sorted JSON stable serialization** from `scripts/math-practice-v2-build-staging-sql.cjs`; do not hash only the question text, and include the complete source hash field list, timing and answer contract. Compute the proposed **new** question hashes and new catalog hashes from the reviewed exact-source content.
- Pin full preimage **MD5 of each complete question row, private metadata row and targeted option diagnostic row**, plus its current code and catalog feedback. If a hash, old code, locale, source/DB identity, membership or expected row count differs, **abort and investigate**, not retry blindly.
- For already future-only/versioned question records, inspect the **actual version-specific hash/versioning contract**; do not blindly reuse an original-release hash recipe.

### 4. Owner GO, exact-head merge and atomic live content update

1. Show the exact IDs/options, mathematical proof, new catalog entries, PR/HEAD, completed CI run IDs, current source/base relationship, live preflight and history risk. Obtain **specific owner authorization to merge/publish this one batch**. Earlier permission for #628/#629/#631 or a docs PR does **not** authorize a new batch.
2. Re-read main, PR HEAD, changed files and CI immediately before merging. Merge with `expected_head_sha` only if this exact package still passes; verify the returned merge SHA. **Main merge is not proof of Supabase publication**. An automatic Vercel build may follow a merge: report deployment separately, without inventing it.
3. For authorized **diagnostic-only** publication, execute one guarded **atomic PostgreSQL transaction** in live Supabase, with no schema migration:
   - Recheck expected bank/target membership and absence of new catalog conflicts; lock each target question and private meta row, then each option diagnostic row (`FOR UPDATE`). Match pinned full-row MD5, old canonical hash, old code, old catalog feedback/actions, QA flags and absence of Tour overlaps.
   - Insert only the new private approved, runtime-allowed diagnostic catalog rows with correctly recomputed catalog SHA-256.
   - Reassign only listed wrong-option `public.question_answer_diagnostics` `rule_json.diagnostic_code` / `feedback_en/ru/uz` / `next_action_en/ru/uz` values, using the new catalog. Assert **exactly one affected row per option**.
   - Update only the corresponding `private.practice_v2_question_meta.content_hash` values and assert **exactly one row per question**. Assert final target counts; let any unexpected mismatch **RAISE EXCEPTION**, rolling back all updates.
   - Never UPDATE/DELETE the student answer, session, score, progress, rating, certificate, Tour or unrelated question tables. Do not reinterpret previously scored answers.
4. **Type-safe SQL guards:** PostgreSQL `text[]` and `jsonb` are not directly comparable. If verifying `secondary_skill_codes` against JSON, use `to_jsonb(m.secondary_skill_codes)` (or equivalent explicit type handling). A transaction rejected by a preflight/type error is **not a partial publication**: confirm rollback and preimages before a corrected retry. Never claim success from a merge or from a failed SQL attempt.

### 5. Independent post-publication read-back

- Outside the write transaction, independently SELECT active per-option codes and compare **all EN/RU/UZ feedback + next actions** to the new approved private catalog. Count exact successes / intended targets (e.g. `8/8`), not mere presence.
- Independently recompute stored **question and catalog SHA-256** by the canonical generator serialization and verify each equals metadata/catalog hash (not simply 64-character length). Verify each changed question remains active with one correct Practice membership and zero Tour links; all current pool IDs unique, all current QA/runtime eligible as expected, no changes to MCQ/input composition.
- Compare historical answer/session counts and scores to preflight; retained record counts do not prove unique learners. Confirm no changes to keys/option meanings/scorer and no unrelated user/Tour data changes. Where runtime or progress changed, require separate genuine signed end-to-end evidence.
- State **ACTUALLY PUBLISHED / VERIFIED** only after successful DB read-back. For failures or drift, say **HOLD** and what was and was not applied; do not silently rerun partial operations.

### 6. Durable checkpoint, branch hygiene and next work

- Record in **canonical Issue #574**: owner GO source/scope, exact original question IDs and wrong-option letters (without publishing protected answer text/keys), source PR HEAD, squash/merge SHA, **CI run IDs at exact HEAD**, transaction result and rollback incidents, counts and SHA checks, unchanged learner history, real test level, remaining blocker and next independently provable batch.
- Close superseded PRs and delete obsolete merged source branches **if the connector supports it**; otherwise record the cleanup blocker. Keep only necessary grouped Drafts. Do not create new process architecture or a new PR just to repeat the same bank audit.
- This runbook belongs to **Mathematics Practice diagnostic-only fixes**. Other academic content revisions have different gates; this runbook does not waive product approval or general release safety.

## New-chat continuation

Start with: **“Продолжи Mathematics Practice diagnostics по Issue #574. Прочитай AGENTS.md, CHAT_PROTOCOL, WORKSTREAMS и этот runbook из актуального GitHub main, затем последние Issue-комментарии и PR/HEAD/CI. Не повторяй опубликованные #628/#629/#631. Доказанные ошибки группируй в один Draft PR, делай отдельную математическую проверку и RU/UZ/EN. Live Supabase — только SELECT до моего точного разрешения на конкретный merge и атомарную публикацию. История, ключи, оценки, Tours и чужие ветки неприкосновенны.”**

This example is a **navigation prompt**, not a substitute for checking the latest state. New chats do not inherit this chat's live authorization.
