# J-22 — isolated physical PostgreSQL backup/restore evidence and production recovery hold

Date: 2026-10-28.

## Owner priority
Protect the already-used iClub production application, database, browser localStorage and actual learner academic progress. Chemistry must remain inaccessible to learners; technical code integration is independent from content release.

## Source and availability facts
- Project `mmmduffgpvwjdpruzikw` currently belongs to a Supabase organization reporting `plan=free`. Official Supabase Database Backups documentation says automatic daily backups are available for Pro, Team and Enterprise projects; a Free project must establish its own securely stored and regularly tested database exports. Do **not** claim Supabase daily-backup or PITR coverage for this project. Documentation: https://supabase.com/docs/guides/platform/backups
- Official Supabase `Restore to a new project` documentation: https://supabase.com/docs/guides/platform/clone-project . This is a paid-plan feature requiring physical backups and carries separate charges. It clones database data, but **not Storage objects, Edge Functions or Auth settings/API keys**. Enabling it requires separate budget/plan decisions and a secure clone procedure; none were executed here.
- Supabase connected integration exposes `restore_project`, but that operation is not a safe isolated production-data clone. **Never invoke it on production as a test**. `list_branches` returned no branch, and ordinary development branching does not bring over production data.
- The existing P2-79 recovery/rollback/disaster test validates logical application rollback and idempotency. It is valuable but NOT a real PostgreSQL physical backup restoration.

## New verified J-22 recovery test
- Script: `scripts/qa-chemistry-9701-j22-isolated-backup-restore.sh`.
- Automated CI: `.github/workflows/chemistry-9701-j22-isolated-backup-restore.yml`.
- Successful GitHub Actions job: https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/40671098917/job/122757766813 .
- Latest successful second run: https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/40671106913/job/122757795912 .
- Implementation: disposable PostgreSQL **17** service and matching PostgreSQL 17 `pg_dump -Fc` / `pg_restore` clients. No production connection strings, anon keys, passwords, source records or student identities are loaded. The script rejects nonlocal database hosts and unexpected credentials.
- Physical backup of six **synthetic production-shaped tables**; fresh-database restore; full row fingerprint equality; two synthetic Mathematics answers, one Practice attempt with two answers, 12 Chemistry LAB drafts; restored foreign-key relationship, six forced-RLS controls and all Chemistry release switches OFF.
- Simulated destructive loss applied **only to the disposable source fixture after backup**. Previously restored independent database remained bitwise-equivalent by deterministic fingerprint.
- The initial CI failed because Ubuntu's bundled `pg_dump` was version 16 while the disposable server was version 17. Pinned both dump and restore client to PostgreSQL 17, reran successfully. This was a fixture/tool compatibility repair, not a production incident.
- The workflow uploads a short result log only; it does NOT upload the database dump, PII or credentials.

## Live source verification, read-only
- Production snapshot during J-22: `private.exam_prep_responses` = 1,987; `public.practice_answers` = 4,856; all Chemistry P3/P5/Tutor switches OFF; no A Level/Tutor personalized permissions; `can_publish=false`; `backup_restore_tested=false`.
- Learner counts can change naturally. A read-only row count is neither a complete backup nor evidence that every row was preserved after a restore.

## What this does and does not prove
**PASS:** PostgreSQL custom-format snapshot/restore mechanism works on isolated synthetic production-shaped fixtures, with referential consistency, RLS metadata, static Chemistry gates and protection from simulated independent data loss. No risk to production.
**NOT PROVEN:** a real backup of **all** production iClub data has been captured, retained securely and restored into a separate isolated system; Supabase authentication, Storage objects, Edge Functions, settings, secrets, backup freshness, RPO and RTO have not been validated.
Therefore **do not set `backup_restore_tested=true` in the production Chemistry gate.**

## Real production-data recovery prerequisite
To close the final source-data recoverability condition without risking students:
1. Make an owner-approved budget/privacy decision: either implement encrypted off-platform production PostgreSQL exports using the correct read-only operational credentials, or use a Supabase plan with physical backups and the supported paid `Restore to a new project` function.
2. Verify successful, up-to-date secure backup capture, protected storage, access restrictions and retention.
3. Restore into a **new isolated** environment; disable cron, outbound `pg_net`, Edge Function side effects, email/SMS and all app network integrations before any test user auth.
4. Validate schemas, table counts and representative normalized fingerprints for Mathematics, Practice, Tours, Economics, Chemistry, user profiles, evidence, RLS and Auth/Storage boundaries; prove restart/recovery without affecting production.
5. Record restore timestamp, backup snapshot age, verified bytes and exact source/target boundaries, responsible operator, observed recovery timings, cleanup and explicit signoff.
6. Only then consider operational gate `backup_restore_tested`; Chemistry learner rollout still requires **separate explicit owner GO**.

## Integration decision
PR #388 remains draft/NO AUTO MERGE while source-data restore proof is absent; synthetic rehearsal is a **partial** recovery gate. No production or learner data write was performed by J-22.
