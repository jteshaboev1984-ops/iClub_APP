# iClub AI v2.1 — Actual-Schema Evidence Audit & Scratch RPC

**Date:** 2026-10-14  
**Master Plan:** §48 / P7 trusted real-schema domain evidence  
**Release:** QA/SCRATCH ONLY; production/global AI NO-GO.

## Verified basis: LIVE production metadata, read-only

Read-only `information_schema` and `pg_proc` queries inspected **schema metadata and function definitions only** in the existing iClub Supabase project. No learner row, answer, entitlement or academic result was selected or changed.

1. Practice source of truth: `public.practice_sessions_v4(id,user_id,subject_id,status,finalized_at,question_ids,legacy_attempt_id)` and `public.practice_session_answers_v4(session_id,question_id,is_correct,answered_at,...)`. **There are no `user_id`, `server_checked`, `is_final`, `topic_key` or `revision` columns on the answer table.** Earlier JavaScript examples used these names as required **normalized proof claims**, not as existing DB columns. The scratch-only service derives the safe claims only after owner-bound session/finalized answer checks. It never equates `legacy_attempt_id` to `practice_sessions_v4.id`.
2. Tour source of truth: `public.tour_attempts`, `public.tours`, and **`public.tour_session_runtime_v4(attempt_id,user_id,tour_id,finalized_at,...)`**. The attempt row has no `finalized_at` field. A finalized runtime row and `status IN ('submitted','time_expired')` are independently required.
3. **Archive unlock is NOT a stored `unlocked` column** on `tour_attempts` or `tours`. The existing `public.get_tour_review_safe_v4` and `get_tour_review_full_safe_v4` require `today in Asia/Tashkent > tours.end_date`; on or before the last day review is closed. Their definitions were inspected read-only. The scratch RPC derives `unlocked` for a **verified owner and finalized runtime**, with a positive date-based `unlock_revision`. Even if an old Tour is no longer `is_active`, its historical archive may be read when other gates pass.
4. `public.lessons` has `id,subject_id,title,topic,order_no`; it does **not** certify `lesson_specific`, `is_video` or any AI source-revision. Those fields require independent content/UX governance; existing subject-wide Telegram videos cannot acquire invented lesson-specific readiness.
5. `public.get_practice_progress_summary` is an authenticated **Practice-only** read function, not a cross-subject signed Home next-action plan or universal Profile readiness metric. Home/Profile, general navigation, specific subject overview and a verified server `current_screen` have **no proven live app-wide v2 RPCs**. They remain denied, not supplied by mock data.

## Concrete QA implementation

`qa/sql_drafts/iclub_ai_v21_real_schema_screen_proof_UNAPPLIED.sql` implements the **existing-record subset** of the single proposed `get_iclub_ai_v21_screen_evidence_service` RPC. It is guarded for **local `iclub_ai_v21_scratch_*` databases only**, not a migration. Its `SECURITY DEFINER` is `search_path=''` and EXECUTE is granted only to `service_role` (revoked from public/anon/authenticated).

Supported metadata-only kinds: `practice_session_v4`, `practice_answer_v4`, `tour_attempt`, `tour_runtime`, `tour_archive_access`. Every read is scoped by **verified Edge principal user ID**, exact session/question/attempt selectors, enrolled active subject, existing kill switch and protected-assessment guard. The actual SQL never outputs raw answers, correction keys, academic scores or a tutor conversation. The **entire SQL body is read-only** apart from the local-only DDL of this proposed function.

Explicitly DENIED kinds: `current_screen`, Home, Profile, navigation/general scope, subject overview and Lessons. This is intentional, not a beta-ready limitation to hide with a guessed generic model response. Existing `qa/edge_v21/screen_proof_services.ts` remains the single typed client for these 11 readers, and existing app-wide admission and content governance remain mandatory after source lookup.

## Tested

`qa/sql_drafts/iclub_ai_v21_real_schema_screen_proof_local_pg.psql` creates a complete **synthetic-only** minimal table set with the introspected column shapes, imports the above UNAPPLIED SQL, asserts positive results and checks:
- Active, unfinalized, missing-answer and foreign Practice deny;
- Tour archive closed on end date, closed before end, missing finalization, foreign owner deny;
- Date-open finalized Tour permitted as **domain metadata**, NOT AI response entitlement;
- Protected assessment, disabled gateway/kill switch, deactivated subject and removed enrollment deny;
- No raw answer or mark appears in proof; service-role-only function privileges;
- Unsupported Home/Profile/general/current-screen/lesson deny.

Integrated as **13th** independent scratch PostgreSQL suite `realproof` in the existing offline GitHub Actions workflow. The suite runs in an empty local Docker/Postgres database under a transaction ending with `ROLLBACK`, then CI drops the database. No migrations, remote hosts, paid providers or real learner accounts.

## Remaining exact blockers

1. Need an independently reviewed server-owned **short-lived current screen revision** and a trustworthy authenticated mapping of current `/context` handles to real views; actual `getScopedContext` does not supply all fields required by the Deno app-wide adapter. Browser DOM alone never authorizes AI.
2. Only if governance sources are approved, create per-feature/subject/topic/locale release and genuine read-only server evidence for Home, Profile, general help and subject overview. No synthetic source or unfinished content is a live release.
3. For Lessons, independently implement the lesson-specific source boundary; never infer it from Telegram subject videos.
4. Before any beta enablement: isolated end-to-end RPC/Edge, complete account/screen/assessment/proof rotation, monetary and abuse gates, UI binding approval and Mathematics Tutor parity. This stage does not install any RPC in production.

**Do not promote `_UNAPPLIED.sql` into `supabase/migrations/` without explicit owner permission and a separate controlled release plan.**
