# iClub Economics Exam Prep — native runtime contract, Stage 1 (26.10.2026)
**Status:** Academic MCQ source banks approved; runtime NOT built; app Economics remains CLOSED. **No production changes** from Stage 1 source/contract work.

## Verified baseline (direct from production Supabase + current GitHub main)

- Economics 9708 v1 P1 and P3 each have **36** approved MCQ mappings, 30 main +6 reserve ID blueprints; P1 AS has 35 unique approved skills, P3 A has 36. Internal QA source snapshots and three-language explanations were approved earlier; **do not repeat academic QA without a new defect**.
- `private.iclub_exam_core_native_content_allowlist_v1` is **service_role-only**, and returns 36 safe metadata records per paper, with `can_issue_learner_task=false`; **not a learner question API**.
- `private.iclub_exam_core_native_plan_preflight_v1` remains `blocked`: `paper_not_published`, `assessment_runtime_not_verified`, `learner_diagnostic_and_plan_evidence_missing`.
- Existing `public.get_my_exam_prep_program_shell_v1(text,text)` requires `auth.uid()`, native subject program published/enabled, enrolled active subject and published papers. It rightly returns empty while Economics is `draft/off`. It contains paper/display metadata, NOT answer keys, issued sessions or results.
- Math `exam-prep/exam-prep-host.js` explicitly gates for `MATHEMATICS_KEY='mathematics'`, Math `exam-prep/exam-prep-live.js` contains P1/P5 user controller and Math `exam-prep/exam-prep-api.js` calls Math-specific functions and `math_as_p1_p5` version.
- Existing Math persistence `private.exam_prep_sessions`, `private.exam_prep_session_items`, `private.exam_prep_session_authorizations`, timed results and weekly plans refers to its own `private.exam_prep_program_versions` and assessments. **Do not attach Economics to these rows or reuse a Math authorization by altering the program/version IDs.**
- Existing `private.iclub_exam_core_written_plans_v1` and `private.iclub_exam_core_written_plan_items_v1` are for *written tasks*. **Do not repurpose them as MCQ sessions.** No native Economics MCQ session/item/answer persistence is implemented yet.
- Active Math program version count 1. Economics program and P1/P3 papers all `draft/off`, `anon`/`authenticated` cannot select private candidate rows or execute service-only content allowlist.

## Product continuity requirement

**One shared visual host**; the Economics screen must look and behave like Mathematics in styling, typography, symmetric layout, states, safe back navigation, localizations RU/UZ/EN, progress summary, correction/retest flow and error handling. Existing Mathematics stays on `legacy_adapter` until distinct regression approval. Do **not** clone Mathematics as a separate Economics app. Do **not** remove the present non-Math gate before native E2E acceptance. This directly implements `docs/exam-prep-multisubject-shell-contract-v1.json` and `docs/exam-prep-multisubject-visual-functional-parity-v1.md`.

## Production-safe server contract (future stage, NOT applied)

Only an authenticated learner with active own enrollment, a server-assigned capacity/consent scope (if beta policy requires it), matching Economics version, `launch_enabled=true`, current published paper and allowed session purpose may start a diagnostic/timed session. The server must enforce all of these, not the client.

Proposed minimal operations for a **future versioned native interface** (names illustrative, not existing functions):
1. `get_my_exam_prep_native_status` — read-only learner-specific program capabilities, actual paper status, prior sessions, no keys. For current Economics must return **OFF**.
2. `start_my_exam_prep_native_session` — authenticated, idempotent, creates durable owned session, freezes paper version, exact item IDs and source MD5, randomized option display order per learner. Exactly **30 distinct source IDs** with proper level and approved paper/skills; one examination must not repeat a question or a canonical skill unnecessarily. Guard repeated submissions/ongoing attempts and session/ownership.
3. `get_my_exam_prep_native_session` — read own started session only; expose translated stem and displayed A–D options **without `correct_answer`, source answer index, correct/incorrect flags before finalization, or unpublished explanation**. Format RU/UZ/EN and time limit must be server-owned.
4. `submit_my_exam_prep_native_answer` — server checks session ownership/status, paper, item order and allowed mapped choice; idempotency key; deadline is server time, not browser timer. Freeze first legitimate response; never trust client `is_correct`, marks, elapsed time or skill mastery.
5. `finalize_my_exam_prep_native_session` — once only; server checks deadline and item statuses, grades from private correct choice after frozen display permutation; stores immutable submitted answers, exact question/version references, source hash and outcome; unattempted items count as 0. No automatic grade on client.
6. `get_my_exam_prep_native_result` — return only own finalized grade, unit/skill breakdown and corrections; explanations shown **after** grading only, with explicit correctness. Reliable navigation result → learning → error review → retest, without granting mastery from Theory page views.
7. Plan generation/retest must store attribution to that particular `session_id` / skill and be idempotent; an old test may be repeated if the architect permits prior exposure. **Do not promise unseen questions.** The same item cannot appear twice in the *same* attempt.

**Persistence gap:** Existing legacy Math sessions cannot safely be reused as-is, and existing native written plan tables are not MCQ answer stores. A durable native `session / frozen item / response` design (or an independently reviewed, backward-compatible extension of a truly shared existing table) is needed before steps 2–7. This must be assessed as **necessary infrastructure**, not built speculatively in production. Explicit schema design, unique constraints, ownership RLS/SECURITY DEFINER boundary, immutable result records and rollback required. No future frontend work should depend on browser localStorage as the source of learner score or progress.

## Source and rollout invariants

- No `service_role` keys or unreleased answer keys in HTML/JS/static JSON/public GitHub; browser only receives the specific authorized learner item WITHOUT the answer. Use private server-side grading. Never emit the entire 72-question source bank to a client.
- Every original question source snapshot must match reviewed hash; halt issuance for changes/blocked rows (9044, 9732, 8751).
- Keep P1 (30 MCQ / 60 min, AS Units1–6) separate from P3 (30 MCQ / 75 min, A Units7–11). P2/P4 are **written-response/essays**, not graded by MCQ machinery.
- Preserve all existing Math, Practice, Tours, course progress, login, localStorage, users, prior attempts and scores. Do not use ad hoc `DELETE`, `TRUNCATE`, reset, destructive migration, changing old user IDs or editing old source questions.
- Beta until explicit architect GO, authenticated E2E proof, no unbounded cross-subject reads and negative tests of denied/expired/duplicate/user-spoofed attempts. Deployment needs a documented simple rollback that switches Economics OFF without rolling back or deleting student data.

## Stage 1 source guard actually implemented, NOT a live exam

Two **offline-only test files** were added to public GitHub, NOT referenced by the app frontend, scripts loaded by index, server RPC or production deploy:
- `scripts/qa-economics-mcq-contract-v1.cjs` — validates the **actual pinned GitHub P1/P3 approval evidence + 30/6 blueprints**, all skill mappings and held ID exclusions, also supplies an explicitly fail-closed preview `evaluateLaunchGuard` which never authorizes an attempt.
- `scripts/qa-economics-mcq-contract-v1.test.cjs` — 11 Node tests for positive source/blueprint match and negative cases: repeated item/skill, QA failure, missing ID, wrong version/units, answer-key leakage, disabled Econ, forged `ready`, Math cross-route.
Run from repository root:
```sh
node scripts/qa-economics-mcq-contract-v1.cjs
node --test scripts/qa-economics-mcq-contract-v1.test.cjs
```
Locally verified **11/11 synthetic cases PASS** on the authored equivalent script; additionally checked the **real current GitHub** approval/blueprint JSON files programmatically, both matched exact **30+6**, QA evidence **36/36**, no duplicate items/skills in main, no held ID and complete unit spread. **These checks are static; they do not prove production native session E2E.**

## Next execution stage

1. Determine the **smallest safe persistent native session schema** (use truly existing reusable objects only if FK + ownership isolation makes them safe; otherwise justify a small number of new Economics-native records). No DDL without isolation/rollback tests.
2. Author and test a non-exposed **server-only dry-run** of ownership, idempotency, freeze/shuffle, deadline, grading and correction. Deny unauthorized users and math cross-access. Run against synthetic users or inside a ROLLBACK transaction only; do not change production users' data.
3. Integrate one native gate/adapter into the existing host **only after** the full server runtime and beta negative tests; visual parity with Mathematics, no new layout. Keep Economics OFF until architect GO.
4. In parallel Paper2/Paper4 written governance, no automatic essays grading.

**Economics status at end of this stage: CLOSED, no learner evidence changed; Math active untouched.**
