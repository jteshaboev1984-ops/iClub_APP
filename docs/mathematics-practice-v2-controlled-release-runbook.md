# Mathematics Practice v2 — Controlled Release Runbook

Release version: `math_p1_practice_v2_2026_10_07`  
Protected invariant: **Mathematics Tour structure, questions needed by Tour, attempts, answers and results must not change because of this release.**  
Owner-approved Practice policy: **legacy Mathematics Practice progress/history does not need to be preserved.**

## Release model

This release is a controlled **Practice reset + new bank publish**. Exam Prep learner-facing copy is aligned with this policy in EN/RU/UZ: Tours are preserved, while Mathematics Practice starts fresh on the updated question set.

What is intentionally reset:
- legacy Mathematics Practice attempts and answers;
- Practice-only diagnoses;
- legacy Practice runtime sessions/drills;
- Practice-derived legacy Exam Prep evidence;
- Mathematics recommendations created from Practice;
- Practice review-opened events and saved Practice-derived learning roadmaps / AI diagnosis snapshots;
- old Mathematics local Practice history in the browser.

What is protected:
- all non-Mathematics subjects and their Practice data;
- user identity/account tables;
- all Mathematics Tours;
- Tour attempts, answers, results and certificates;
- Tour recommendations;
- Tour-derived learning roadmaps;
- any legacy question row still referenced by a Tour;
- any legacy question row still required by another protected/non-Practice dependency.

Old Practice question rows are not physically deleted at the exact cutover. First the new bank is published and smoke-tested. Only after that, a separate cleanup removes old Practice-only question rows that have no protected references.

This gives a simple learner result — Practice starts fresh — while keeping a short rollback window before old question cleanup.

## Phase 0 — live READ-ONLY checks

Run:

`supabase/preflight/math_practice_v2_schema_compatibility.sql`

Then recheck current production counts and the protected Tour fingerprint READ-ONLY.

Expected baseline before release:
- 1 active Mathematics subject;
- exactly 7 active Mathematics Practice pools;
- 490 active legacy Practice memberships;
- 495 staged v2 questions after staging;
- zero staged v2 question ↔ Tour overlap.

User activity can increase the number of legacy Practice attempts before cutover. That does not block release because those Practice rows are intentionally reset.

## Phase A — additive database preparation

Apply, in timestamp order:

1. `20261007002000_math_practice_v2_unicode_minus_normalization_v1.sql`
2. `20261007003000_math_practice_v2_close_legacy_answer_oracles_v1.sql`
3. `20261007004000_math_practice_v2_metadata_foundation_v1.sql`
4. `20261007005000_math_practice_v2_topic_drill_pool_gate_v1.sql`
5. `20261007006000_math_practice_v2_selector_v5.sql`
6. `20261007006500_math_practice_v2_current_mistakes_v5.sql`
7. `20261007006700_math_practice_v2_deterministic_feedback_v5.sql`
8. `20261007007000_math_practice_v2_tour_invariant_audit_v1.sql`
9. `20261007007500_math_practice_v2_atomic_release_switch_v1.sql`

Migration 07500 only defines private reset/publish/rollback/cleanup functions. It does not run the reset by itself.

Run the SQL definition regressions before continuing.

## Phase B — stage the new bank invisibly

Generate:

```bash
node scripts/math-practice-v2-build-staging-sql.cjs --check --out /tmp/math-practice-v2-stage.sql
```

Record:
- release version;
- manifest SHA-256;
- 495 question count;
- 201 diagnostic catalog rows;
- 868 diagnostic mappings.

Apply the generated staging SQL.

Required staged state:
- 495 new questions;
- all new questions inactive + draft;
- all new memberships inactive;
- all QA gates passed;
- diagnostic runtime disabled;
- no staged question linked to Tour.

Learners still use the old Practice bank at this point.

## Phase C — deploy the v5 Practice runtime

Deploy the frontend/runtime with:
- v5 Practice selector;
- topic drill v5;
- current-bank mistake review/drill v5;
- deterministic answer evaluation/feedback;
- Unicode-minus normalization;
- Mathematics local Practice history namespace `practice_history_v3`;
- a one-time pre-app Mathematics Practice cleanup that removes only stale Mathematics Practice draft/history/recommendation/runtime state and leaves Tour state/storage untouched.

The old Mathematics local Practice history or paused legacy session therefore cannot reappear after the database reset. The cleanup marks itself complete once, so new v2 Practice progress created afterward is preserved.

During this short pre-publish window, Mathematics v5 selectors/readers fail closed against legacy questions: Mathematics cannot create a new old-bank Practice session after the one-time browser reset. Other subjects keep their legacy-compatible Practice behavior. The learner sees a short “Practice is being updated” message if they try to start Mathematics at that exact moment.

Do not publish the new bank yet.

## Phase D — mandatory READ-ONLY preflight

Run:

`supabase/preflight/math_practice_v2_release_preflight.sql`

It must prove:
- exactly 7 active Mathematics Practice pools;
- exactly 490 active legacy memberships immediately before cutover;
- exactly 495 staged v2 questions;
- exact per-Practice sizes: 68 / 80 / 68 / 77 / 66 / 70 / 66;
- 201 diagnostic catalog rows;
- 868 diagnostic mappings;
- staged content is still invisible;
- QA gates are passed;
- no v2 Practice question is linked to Tour;
- protected Tour snapshot function is available.

If any assertion fails, do not publish.

## Phase E — reset + atomic publish

Call:

```sql
select private.publish_math_practice_v2_release_v1(
  'math_p1_practice_v2_2026_10_07'
);
```

Inside one transaction the function:
- fingerprints protected Mathematics Tours;
- archives the exact 490 legacy Practice membership IDs and 490 legacy question IDs;
- blocks old v4 Practice entrypoints;
- deletes legacy Mathematics Practice attempts/answers, Practice-only diagnoses, sessions/drills, Practice review events, Practice-derived recommendations, Practice-derived learning roadmaps/AI diagnosis snapshots and Practice-derived legacy evidence;
- disables the 490 old Practice memberships;
- publishes the 495 v2 questions/diagnostics;
- activates the 495 new memberships;
- validates exact Practice counts;
- fingerprints Tours again;
- aborts the entire transaction if the Tour fingerprint changed.

It performs **no Tour DML**, no user/account DML and no reset of Practice data for any non-Mathematics subject.

Expected result includes:
- `status='published'`;
- `practice_progress_reset=true`;
- `old_memberships_disabled=490`;
- `new_memberships_enabled=495`;
- `active_bank=495`;
- `tour_invariant_unchanged=true`.

## Phase F — immediate post-publish audit

Run:

`supabase/preflight/math_practice_v2_post_publish_audit.sql`

Required:
- active bank = 495;
- exact P1–P7 counts;
- old memberships inactive;
- new memberships active;
- Practice attempts reset to zero;
- legacy Practice sessions/drills reset to zero;
- Practice-only diagnoses reset to zero;
- Practice-derived legacy evidence reset;
- Mathematics Practice recommendations reset to zero while Tour recommendations remain untouched;
- Practice-derived learning roadmaps/AI diagnosis snapshots reset while Tour-derived roadmaps remain untouched;
- protected Mathematics certificates remain unchanged;
- superseded v4 Practice write/start entrypoints not executable;
- the read-only v4 resume readers still required by the v5 frontend remain executable;
- required v5 entrypoints executable;
- Tour snapshot before/after cutover unchanged.

Then run learner smoke QA on a test account:
- open Practice 1–7;
- start a session;
- answer MCQ correctly and incorrectly;
- answer Input including Unicode minus;
- finish the session;
- check deterministic mistake feedback;
- check topic drill and mistake drill;
- refresh/reopen and confirm the new Practice progress persists;
- verify Tour pages/results still work and were not reset.

## Phase G — legacy Practice question cleanup

Only after Phase F is green, call:

```sql
select private.cleanup_math_practice_v1_questions_v1(
  'math_p1_practice_v2_2026_10_07'
);
```

The cleanup:
- removes the retired old Practice memberships;
- physically deletes only legacy questions with no Tour reference and no other protected/non-Practice dependency;
- automatically retains every Tour-linked legacy question;
- fingerprints Tours before and after cleanup;
- aborts if the protected Tour fingerprint changes.

Then run:

`supabase/preflight/math_practice_v2_post_cleanup_audit.sql`

At the current READ-ONLY baseline, 4 of the 490 legacy Practice questions have historical Tour links, so those question rows are expected to remain unless the production state changes before release. Their Practice memberships are still removed.

## Rollback

Rollback is available **between Phase E and Phase G**:

```sql
select private.rollback_math_practice_v2_release_v1(
  'math_p1_practice_v2_2026_10_07'
);
```

Rollback:
- disables the new v2 bank;
- restores the archived old Practice memberships;
- restores the safe v4 Practice entrypoints;
- deletes any new Mathematics Practice sessions/progress/recommendations created after the v2 publish, because Practice progress is disposable for this release;
- leaves the deployed v5 frontend usable: v5 Mathematics permits legacy-question fallback only when this release has already reached `published` lifecycle but its v2 runtime metadata has been disabled by rollback;
- does not restore deleted legacy Practice progress;
- does not touch Tours.

Therefore a database rollback before legacy-question cleanup does not require an emergency frontend rollback merely to make Mathematics Practice usable again. Before first publish, the same v5 code remains fail-closed against legacy Mathematics questions, so this rollback compatibility cannot reopen the old bank during the normal cutover window.

After legacy question cleanup, rollback to the old bank is intentionally blocked because old Practice-only question rows may already be deleted.

## Stop conditions

Stop immediately if:
- any Tour fingerprint changes inside reset/publish/cleanup;
- the staged v2 bank is not exactly 495;
- any new v2 question is linked to Tour;
- the active post-publish bank is not exactly 495;
- any required v5 Practice endpoint is unavailable;
- post-publish Practice reset rows are not zero;
- learner smoke QA exposes a correctness, navigation, language or persistence defect.

The protected boundary is simple: **Practice may reset. Tours may not.**
