# Mathematics Practice v2 — Controlled Release Runbook

Release version: `math_p1_practice_v2_2026_10_07`  
Protected invariant: **Mathematics Tour structure, attempts and answers must not change because of this release.**  
Practice history policy: preserve old Practice attempts/answers and local history; switch only the learner-facing active bank.

## Release model

This release is a **membership switch**, not a destructive replacement.

- Existing Mathematics Practice question rows remain in the database.
- Existing Practice attempts, answers, sessions and diagnoses remain in the database.
- Existing Tour rows/results remain untouched.
- Old active Practice pool memberships are turned off.
- 495 staged Practice v2 memberships are turned on atomically.
- New v2 questions are published in the same transaction.
- New deterministic diagnostics are published in the same transaction.
- A protected Tour fingerprint is calculated before and after the transaction. Any difference aborts the release.
- Rollback restores the exact archived old membership IDs; it does not delete new history.

This design prevents foreign-key/history loss and avoids touching protected Tour evidence.

## Phase A — additive database preparation

Apply, in timestamp order, the branch migrations up to and including:

1. `20261007002000_math_practice_v2_unicode_minus_normalization_v1.sql`
2. `20261007003000_math_practice_v2_close_legacy_answer_oracles_v1.sql`
3. `20261007004000_math_practice_v2_metadata_foundation_v1.sql`
4. `20261007005000_math_practice_v2_topic_drill_pool_gate_v1.sql`
5. `20261007006000_math_practice_v2_selector_v5.sql`
6. `20261007006500_math_practice_v2_current_mistakes_v5.sql`
7. `20261007006700_math_practice_v2_deterministic_feedback_v5.sql`
8. `20261007007000_math_practice_v2_tour_invariant_audit_v1.sql`
9. `20261007007500_math_practice_v2_atomic_release_switch_v1.sql`

Important: migration 07500 **defines** private publish/rollback functions; it does not publish the bank.

After additive migrations, run the SQL regression suite for the Practice v2 migrations. Do not continue if any regression fails.

## Phase B — stage content while invisible

Generate the deterministic staging package from the exact release commit:

```bash
node scripts/math-practice-v2-build-staging-sql.cjs --check --out /tmp/math-practice-v2-stage.sql
```

Record the generator's:
- release version;
- manifest SHA-256;
- 495 question count;
- diagnostic catalog count;
- diagnostic mapping count.

Apply the generated staging SQL.

Expected state after staging:
- 495 new question rows exist;
- all 495 have `questions.is_active=false`;
- all 495 have `questions.quality_status='draft'`;
- all 495 new pool memberships are inactive;
- private metadata has all four QA statuses passed;
- metadata lifecycle is approved but runtime is false;
- diagnostic catalog runtime is false;
- no staged Practice v2 question belongs to a Tour.

Learners must still see the legacy Practice bank at this point.

## Phase C — deploy v5 learner runtime

Deploy the branch frontend/runtime with:
- main Practice selector v5;
- topic drill v5;
- current-bank mistake review/drill v5;
- session/drill answer submit v5;
- session finalizer v5;
- Practice review v5;
- Unicode-minus input normalisation;
- deterministic mistake guidance in Practice review.

Old open clients may continue an already-started v4 Practice session because v4 resume/submit/finalize compatibility is intentionally retained until those sessions finish.

Do not publish Practice v2 yet.

## Phase D — mandatory READ-ONLY preflight

Run:

`supabase/preflight/math_practice_v2_release_preflight.sql`

The script is explicitly read-only and rolls back at the end.

It must prove, among other gates:
- 7 active Mathematics Practice pools;
- 490 active legacy memberships immediately before cutover;
- zero active Practice↔Tour overlap;
- exactly 495 staged v2 questions;
- exact per-Practice staged sizes:
  - P1 68
  - P2 80
  - P3 68
  - P4 77
  - P5 66
  - P6 70
  - P7 66
- staged membership order is contiguous inside every Practice;
- every content QA gate is passed;
- all staged questions and memberships are still invisible;
- no staged question is a Tour question;
- protected Tour snapshot is available.

If any assertion fails, **do not run the publish function**. Diagnose the drift first.

## Phase E — atomic publish

Only after Phases A–D are green, call:

```sql
select private.publish_math_practice_v2_release_v1(
  'math_p1_practice_v2_2026_10_07'
);
```

Expected result:
- `ok=true`
- `status='published'`
- `old_memberships_disabled=490`
- `new_memberships_enabled=495`
- `active_bank=495`
- `tour_invariant_unchanged=true`

The function itself:
- archives exact old/new membership IDs;
- fingerprints all protected Mathematics Tour structure/results;
- closes superseded v4 selector entrypoints;
- disables exactly the old active Practice memberships;
- publishes v2 questions/diagnostics/runtime metadata;
- activates exactly the 495 v2 memberships;
- validates exact per-Practice counts;
- fingerprints Tours again;
- raises an exception and rolls the whole transaction back if the protected Tour fingerprint differs.

It does **not** delete Practice history and contains no Tour DML.

## Phase F — mandatory post-publish audit

Immediately run:

`supabase/preflight/math_practice_v2_post_publish_audit.sql`

Required result:
- 495 active Mathematics Practice memberships;
- exact P1–P7 counts;
- all old archived active membership IDs now inactive;
- all new membership IDs active;
- all v2 question/runtime/diagnostic gates published correctly;
- zero Practice v2 ↔ Tour overlap;
- release audit stores equal Tour snapshots before/after;
- unsafe/superseded learner entrypoints are not executable;
- required v5 learner entrypoints are executable.

Also run:

`supabase/preflight/math_practice_v2_inflight_compatibility_audit.sql`

It must confirm that already-started v4 Practice sessions/drills can still resume, submit and finalize after cutover. Only the superseded v4 start/select entrypoints are retired.

Then run a controlled learner smoke path:
- open each Practice 1–7;
- confirm the displayed total matches 68/80/68/77/66/70/66;
- start/resume a session;
- answer one MCQ correctly and incorrectly in a test account;
- answer a negative numeric Input using Unicode minus;
- finish a session;
- open error review and confirm deterministic “why/how to fix” text;
- check topic drill and mistake drill;
- verify Tour screens/results are unchanged.

No real learner result should be manually edited during smoke testing.

## Rollback trigger

Rollback is appropriate if the new Practice learner flow has a material runtime defect that cannot safely be fixed immediately.

Call:

```sql
select private.rollback_math_practice_v2_release_v1(
  'math_p1_practice_v2_2026_10_07'
);
```

Rollback:
- disables the exact 495 v2 memberships;
- restores the exact archived old active membership IDs;
- disables v2 runtime metadata/source diagnostics;
- **does not delete v2 question rows or v2 learner history**;
- leaves published v2 question rows readable so an already-started v2 session and historical review can finish;
- fingerprints Tours immediately before and after rollback and aborts if they change.

Then run:

`supabase/preflight/math_practice_v2_post_rollback_audit.sql`

Do not re-enable unsafe legacy answer-oracle or selector entrypoints after rollback. The v5 runtime is deliberately compatible with the restored legacy pool membership.

## Learner-history behaviour

The active-question completion count is calculated against the current pool question IDs. Because Practice v2 has new IDs, old correct answers do not falsely mark new questions complete.

Local Practice history is **not deleted**. The UI filters tour-level Practice best/last statistics against the current active question IDs, so a legacy attempt is preserved locally but does not masquerade as a result on the new bank.

Tour history has a separate protected path and is not reset or recalculated.

## Learner communication

A release notice should say only what the learner needs to know:

RU:
> Практика по Mathematics обновлена: задания теперь лучше соответствуют темам и уровню Cambridge AS. Ваши результаты Tours сохранены. Прогресс в обновлённой Practice считается по новому набору заданий.

UZ:
> Mathematics Practice yangilandi: topshiriqlar endi Cambridge AS mavzulari va darajasiga yaxshiroq mos keladi. Tour natijalaringiz saqlangan. Yangilangan Practice dagi progress yangi topshiriqlar to‘plami bo‘yicha hisoblanadi.

EN:
> Mathematics Practice has been updated so the questions better match Cambridge AS topics and level. Your Tour results are preserved. Progress in the updated Practice is measured on the new question bank.

Do not expose migration, database, selector, diagnostic-code or reset terminology to learners.
