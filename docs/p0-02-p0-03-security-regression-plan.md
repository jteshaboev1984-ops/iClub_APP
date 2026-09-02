# iClub APP — P0-02 / P0-03 Security Regression Plan

Status: branch-only implementation gate. No production cutover is authorized by this file.

## Purpose

Move legacy Practice and Tours from browser-readable answer keys/client-authoritative Tour correctness to server-authoritative safe delivery without changing historical attempts, pool/tour membership, rankings, certificates, localStorage contracts, or one-attempt Tour semantics.

## Non-negotiable order

1. Revalidate live production baseline and hashes.
2. Apply **P0-02 additive** `20260902_p0_02_safe_legacy_assessment_contract_v3.sql` only.
3. Smoke-test new RPCs with controlled test identity; old frontend remains operational.
4. Deploy frontend that uses v3 RPCs while old policies still exist.
5. Run Practice/Tour parity + recovery + anti-cheat regression.
6. Recheck history counts/hashes.
7. Only then apply **P0-03 cutover** from the separately reviewed cutover SQL.
8. Re-run all regression tests and integrity hashes.
9. Exam Prep host bridge remains OFF until security + isolation gates are green.

## P0-02 database acceptance

- New runtime tables exist, RLS enabled.
- `anon` and `authenticated` have no direct table access to runtime tables.
- Only authenticated callers execute public v3 session RPCs.
- Internal evaluator is not browser-callable.
- No historical Practice/Tour rows are updated/deleted by migration.
- No legacy pool/tour memberships are changed.
- No feature flag is enabled.

### Safe payload assertions

Pre-answer Practice/Tour delivery must contain none of:
- `correct_answer`
- `explanation`
- `explanation_ru`
- `explanation_uz`
- `explanation_en`
- `is_correct`
- diagnostic private rule fields

Practice answer submission may return correctness + explanation **only for the already submitted item**.

Active Tour answer submission must return only acknowledgement/progress counts; it must not return `is_correct`, answer key, or explanation.

## Practice parity matrix

Test MCQ and input for RU/UZ/EN display content.

1. Start a selected subset from an active Practice pool.
2. Server rejects any question not in the selected active pool.
3. Selected order is preserved.
4. Correct MCQ parity matches legacy server `submit_practice_attempt`.
5. Incorrect MCQ parity matches legacy.
6. Exact input parity matches legacy normalization.
7. Numeric input parity matches legacy normalization.
8. Per-answer feedback reveals only that answered question.
9. Session resume returns same question set.
10. Finalize before all selected questions answered is rejected.
11. Finalize after all answers creates exactly one legacy `practice_attempts` row.
12. Finalize creates exactly N `practice_answers` rows.
13. Final score/percent is produced by existing server-authoritative `submit_practice_attempt`.
14. Repeated finalize is idempotent and does not duplicate legacy rows.
15. Practice review RPC is owner-only and returns post-attempt answer/explanation.
16. Existing historical attempts remain bit-for-bit logically unchanged.

## Tour parity matrix

1. Tour cannot start before `start_date` or after `end_date`.
2. Inactive Tour cannot start.
3. Existing historical attempt blocks a new attempt.
4. Active unfinished v3 runtime may resume the same consumed attempt.
5. Question list is server-derived from active `tour_questions`; client cannot inject IDs.
6. Pre-answer payload contains no secrets.
7. MCQ correctness is server-computed.
8. Input correctness is server-computed.
9. Active answer submit returns no correctness.
10. Multiple submits for same question update private runtime row only.
11. Finalization fills omitted questions as unanswered/incorrect.
12. Finalization copies exactly N rows to legacy `tour_answers`.
13. Final score = count of server-correct rows; denominator = frozen session question count.
14. Status only accepts `submitted`, `time_expired`, `anti_cheat`, `abandoned`.
15. Finalize is idempotent.
16. `UNIQUE(user_id,tour_id)` remains intact.
17. Existing rating SELECT behavior remains intact during staged migration.
18. Tour review RPC is unavailable until official Tour window has ended.
19. After close, owner can review answer key/explanations through review RPC.
20. Historical Tour rows and scores are unchanged.

## P0-03 cutover acceptance

Before applying cutover, code search on deployed frontend must show no active direct path that selects:
- `questions.correct_answer`
- question explanations before answer
- nested Tour question secrets
- direct Tour answer/attempt INSERT/UPDATE/DELETE

After cutover:
- `questions_public_read` absent.
- `tour_questions_public_read` absent.
- direct Tour write policies absent.
- active/upcoming Tour question content excluded from `safe_questions_public`.
- active/upcoming Tour question content excluded from generic `get_safe_questions_by_ids`.
- Tour session-authorized delivery still works only after valid start.
- ratings still read `tour_attempts` using the existing authenticated SELECT path.

## Integrity snapshot before and after

Record and compare:
- total questions; Math total/active/published counts;
- Practice attempt/answer counts before any controlled test rows;
- Tour attempt/answer counts before any controlled test rows;
- active Practice pool membership counts and semantic membership hash;
- active Tour membership counts and semantic membership hash;
- historical Practice answer semantic hash;
- historical Tour answer semantic hash;
- ratings/certificate counts;
- current production deployment SHA.

Controlled test rows must be identified separately and never confused with history drift.

## Rollback

### Before P0-03
P0-02 is additive. Old frontend/policies still work. Roll back frontend deployment; new private runtime tables/RPCs may remain dormant until explicitly removed later.

### After P0-03
If Sev0/Sev1 appears:
1. immediately restore previous known-good frontend deployment;
2. restore the reviewed legacy read/write policies only if required to keep the old frontend functional;
3. do **not** delete or rewrite historical attempts/answers;
4. disable Exam Prep host entry/flag;
5. compare integrity snapshot before further action.

No rollback step may reset localStorage, delete attempts, rebuild rankings, or rewrite question semantics.

## Go / No-Go

P0-02 PASS requires additive RPC smoke tests + parity tests + unchanged baseline integrity.

P0-03 PASS requires safe frontend deployed, no browser answer-key path, active Tour content firewall, no direct Tour correctness/write path, and second integrity audit.

Any unresolved answer-key exposure, one-attempt regression, score mismatch, recovery regression, or history drift = NO-GO for Exam Prep production connection.
