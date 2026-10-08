# Mathematics Practice v2 — Controlled Release Runbook

Release version: `math_p1_practice_v2_2026_10_07`  
Protected invariant: **Mathematics Tour structure, questions needed by Tour, attempts, answers and results must not change because of this release.**  
Owner-approved Practice policy: **legacy Mathematics Practice progress/history does not need to be preserved.**

## Verified production checkpoint — 2026-10-08 (READ-ONLY)

This is the **actual** state of the live Mathematics Practice release at the checkpoint, not a claim that the new bank is already published:

| Gate | Live evidence | Decision |
|---|---|---|
| Additive v2 SQL foundations (Phase A) | All nine listed migrations recorded as installed | Already completed — do not blindly reapply |
| Invisible staging (Phase B) | 495 staged original questions (68/80/68/77/66/70/66); 201 approved diagnostics; 868 draft mappings; zero duplicate content keys | Already completed — do not duplicate staging |
| QA / invisibility | All four item QA statuses passed; zero staged active question or membership; zero Tour links | PASS in read-only inspection |
| Legacy learner-facing Practice | Seven active pools, 490 active memberships | Expected, still live |
| Atomic release switch | Zero rows for `math_p1_practice_v2_2026_10_07` in release audit | **NOT published**; do not clear current Practice data |
| Mathematics Tour protection | 14 Tours, 300 memberships, 149 attempts, 2,477 answers; four legacy Practice question IDs retain Tour references | Fingerprints checked and preserved at this checkpoint |
| PR #336 post-publish proof RPC | `public.is_math_practice_v2_published_safe_v1()` does **not** exist in live DB | **HOLD** until approved protective SQL and frontend are installed |
| Existing `main` client reset | `security/practice-v2-local-reset.js` still executes eagerly before publish and also clears the v3 namespace | Replace only through the approved guarded PR #336 implementation |

**Resume at Phase C** rather than redoing finished content/staging work. Use the **one architect-approved unified #327 production deployment** to ship the PR #336 post-publish guard (corrected client script/cache pins) alongside the other dormant features. Within that SAME controlled release window, install and verify its additive SQL proof function **before** switching the bank. The SQL proof installation and later atomic bank switch require no extra Vercel deployment. Never activate the atomic publish while the old eager script is serving users. Re-run Phase D immediately before Phase E to detect drift. For this live database, changing the 490 legacy membership baseline or protected Tour fingerprint requires fresh review.

This checkpoint is not deployment authorization. No production write was made to produce it.

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
- the authenticated server-side publication-proof function `is_math_practice_v2_published_safe_v1()` from `20261008110000_math_practice_v2_post_publish_local_reset_gate_v1.sql`;
- the gated local reset from PR #336: never run Mathematics browser cleanup merely because a new script has loaded. `app.js` invokes `iclubMathPracticeV2ResetAfterPublish` only after registration; it performs cleanup only when the server confirms the 495-question bank and a `published` switch audit.

**Important correction to the original release procedure (PR #336): pre-publish local cleanup is prohibited.** The old eager `security/practice-v2-local-reset.js` shipped before publication and could clear old local drafts/history just by loading the app. Replace it with the publication-gated version and its updated script cache pins; this fix must be present before any future bank-switch rollout. An unauthenticated client, offline/error/timeout response, staged bank, rollback or missing proof function leaves all local data untouched. The new `practice_history_v3` namespace is never cleared by this legacy cleanup.

During the short pre-publish window, Mathematics v5 selectors/readers fail closed against metadata-less legacy questions: Mathematics cannot create new old-bank Practice state; other subjects keep their legacy-compatible Practice behavior. The learner may see “Practice is being updated”. This is independent of local cleanup, which **remains OFF until successful publication**.

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

Then verify the **post-publish browser cleanup gate** on an already approved test account. The authenticated proof must return `true` only after the release audit is `published` and all 495 new memberships/questions are active. One-time cleanup may remove *legacy Mathematics Practice* local state only; preserve Tour data, non-Mathematics local state, Exam Prep state and all newly written `practice_history_v3` data. Reload and confirm it is idempotent. If publication proof is unavailable or false, do not clear any local data.

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
- the old eager pre-publish local reset script is still loaded or the post-publish gate is missing/not independently validated.

The protected boundary is simple: **Practice may reset. Tours may not.**
