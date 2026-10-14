# iClub AI v2.1 — §49 Trusted Current Screen Authority (QA only)

**Date:** 2026-10-14. **Branch:** `qa/iclub-ai-layer-v21-20261012`. **Production release:** NO-GO.

## Objective and existing-code reuse

The next Master Plan block after §48 is a **single, verified, 90-second current-screen authority** for the already existing QA Edge and unified AI Tutor. Rather than introducing tables, the SQL expands the prior `private.iclub_ai_v21_current_screen` (one row per learner, active opaque handle and strictly increasing revision) and `private.iclub_ai_v21_scoped_contexts` (90-second handle, subject, feature, exact academic selectors, revocation flag). These structures are in the original **UNAPPLIED scratch-only SQL**, **not** in deployed production.

A mint request never asserts a subject, answer, score, grade, readiness or source rights. The Edge derives `p_user_id` only after validating the JWT. The existing single service-role context RPC validates the relevant existing academic rows. It atomically changes the current handle and revision under the same per-learner advisory lock. An old browser tab cannot revoke a newer context.

## Screen contract implemented in QA

- **Practice:** minted only for the authenticated owner, a finalized `practice_sessions_v4.id`, exact included and answered `practice_session_answers_v4.question_id`, active subject and enrollment. A `legacy_attempt_id` never substitutes the V4 ID.
- **Lessons:** minted only for an existing `public.lessons.id`, active subject and enrollment. It is *not* evidence that the lesson has its own AI-approved source or is not a Telegram subject video; the existing independent content gate remains closed without that proof.
- **Tour archive:** `mint_iclub_ai_v21_tour_archive_context_service` is added to the SAME context lifecycle, not a separate AI system. It uses `public.tour_attempts`, `public.tour_session_runtime_v4`, `public.tours`, `public.subjects` and `public.user_subjects`. Requires owner, `submitted` or `time_expired`, matching runtime row with `finalized_at`, enrollment and **Asia/Tashkent current date strictly AFTER `end_date`**, matching the live `get_tour_review_full_safe_v4` gate. An inactive historic Tour may still be reviewed when its archive is open.
- **Screen proof:** the existing single `get_iclub_ai_v21_screen_evidence_service` now implements `current_screen` only when an active server-issued scoped context exists, matches one current handle/revision, survives read-time domain authorization, is not revoked and has not expired. It returns only owner ID, handle, `screen_N` revision, `current_view='courses'` and monotonic revision. It cannot mint a screen or create readiness.
- **Read-time rechecks:** context resolution separately revalidates the current owner, global kill switch, active protected assessment, Practice completion / Lesson enrollment / Tour archive accessibility. Leaving a screen revokes the active handle and increments revision; duplicate same-context mint is idempotent, not an extension of TTL.

The isolated Deno `/context` now recognizes `mintTourArchive` with only positive `tourAttemptId` as selector, alongside the existing `mint`, `mintLesson` and `revoke`. Request body subject/topic/plan/score/user ID remains forbidden. `qa/edge_v21/supabase_services.ts` maps it to the guarded **UNAPPLIED** mint RPC. `/answer` continues to use `TrustedAppWideServerAdapter`, independent source readiness, per-language governance, protected-exam blackout and request accounting.

## Scope boundaries

This is **server-issued scoped intent** for the Courses contexts, *not proof of the actual pixels currently displayed on a real student's phone*. The client must still notify navigation/logout and revoke handles; QA client/Edge wiring and race proof require an independently permitted Preview. A stale tab is blocked after server navigation, revocation or TTL; backend cannot detect an unreported browser navigation by itself. Home, Profile, General Help, non-lesson subject overviews and subject-wide videos have **no authenticated current-screen mint or approved aggregate-source RPC in this milestone** and remain **«В разработке» / NO-GO**.

No real student data, progress rows, raw answer keys, localStorage, chat transcripts, new billing, paid provider, `app.js`, `index.html`, `exam-prep/`, `supabase/functions/` or production migration is modified. The existing Mathematics Tutor stays unchanged, with no double charging.

## Verification and next remaining blocker

`qa/sql_drafts/iclub_ai_scoped_context_local_pg.psql` tests matching handle/revision, account isolation, exact selectors, one active screen, duplicate mint, screen swap, revoke, expiry, protected examination, loss of topic entitlement, Tour finalization invalidation and reclosed archive. It creates artificial table rows **only** in disposable local scratch PostgreSQL and ends in `ROLLBACK`. Independent `realproof` confirms source metadata and the strict Tour date gate. Deno tests verify the one `/context` action and fail-closed service role adapter.

**Next:** before real beta, obtain separate architect-approved isolated runtime and UI binding, build authenticated current-screen mint for General/Home/Profile (without inventing next-actions), and verify real source/locale entitlements. Only then evaluate cutover. A green scratch test is **not** production AI readiness.
