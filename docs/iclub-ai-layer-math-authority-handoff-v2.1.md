# iClub AI Layer v2.1 — Mathematics verified-source server handoff

**Date:** 2026-10-12 · **Status:** QA branch only, SQL unexecuted, NO GO for real learners.

## Purpose

Replace the untrustworthy browser-provided `subject_key`, `component_code`, `skill_code`, completion and content-readiness hints with a service-only admission proof derived from **existing, unchanged** Mathematics Exam Prep tables. Do not replace the existing `exam-prep-ai` Edge function or change its rules or beta entitlements.

## Verified existing source tables (Supabase SELECT/metadata only)

- `private.exam_prep_sessions`: `id`, `user_id`, `status`, `finalized_at`, `component_code`. Finalized P1/P5 session is required but **alone does not establish a specific skill**.
- `private.exam_prep_session_items`: `session_id`, `primary_skill_code`. Ensures that the requested skill belongs to that actual assessment.
- `private.exam_prep_evidence_events`: `user_id`, `session_id`, `component_code`, `skill_code`, `verification_status`. Current `app_verified` is required; `self_reviewed` and `app_checked_noncredit` alone cannot unlock the AI route.
- `private.exam_prep_ai_tutor_cards`: `source_card_key`, `component_code`, `skill_code`, `locale`, `content_version`, `approval_status`, `is_runtime_allowed`, `content_hash`. Current approved Tutor content is `tutor_v3_learner_first`, 32-char content hash.
- `private.exam_prep_ai_source_cards`: `source_card_key`, `component_code`, `skill_code`, `locale`, `card_type`, `source_version`, `approval_status`, `rights_status`, `is_runtime_allowed`, `content_hash`. Rights status `original_iclub` and current approval are mandatory; approved source hash has 64 chars.
- `private.iclub_global_ai_runtime_config` and existing `private.iclub_ai_has_active_protected_assessment_v1`: existing global kill switch and protected exam/Tour block. Do not bypass or rewrite them.

These are facts from **metadata and aggregate read-only queries**. No student answers, identity rows or progress were retrieved.

## Delivered technical package (QA branch)

1. `qa/sql_drafts/iclub_ai_math_skill_context_v21_UNAPPLIED.sql`: new **service-role-only, read-only** proof function `public.get_iclub_ai_math_skill_context_service_v2(uuid,uuid,text,text)`, built directly over the verified tables above. It checks owner + finalized P1/P5 + session-item skill + verified evidence + live Tutor and rights-cleared source for the requested RU/UZ/EN. Returns **metadata/hashes**, not source text, answers, grade or progress. Embedded name+localhost guard prevents accidental direct production execution. No DDL in `supabase/migrations`.
2. `qa/ai-layer-v21-math-authority-service.cjs`: server-side mock interface to the proof RPC. Requires JWT-bound principal from the Edge, server-minted scoped context, trusted global guard and topic/locale release gate. The same learner/session/revision/source is checked again before delivery. **Cannot be used by the browser; not imported by the running Edge**.
3. `qa/ai-layer-v21-math-authority-service.test.cjs`: **19/19** saved-source V8 behavior cases passed, including cross-user, legacy Tutor isolation, wrong subject/skill/locale, revoked source, expired context, changed screen/session during answer, disabled Global AI and revalidation before delivery.
4. `qa/ai-layer-v21-math-authority-sql.test.cjs`: **14/14** static source-contract checks passed for role restriction, ownership, source/evidence joins, readiness rights, no academic writes and scratch-only harness.
5. `qa/sql_drafts/iclub_ai_math_authority_local_pg.psql`: end-to-end PostgreSQL fixture in one transaction that `ROLLBACK`s the synthetic roles/tables/users, with cases for gateway OFF, real success, foreign user, wrong skill, active exam, unverified evidence, retired Tutor and restricted source. **Prepared, NOT EXECUTED**.
6. `qa/run-ai-layer-v21-postgres-local.sh`: now supports `ICLUB_PGTEST_SUITE=meter` and `math`, each only in a new empty local scratch database, never against production. The 16-suite offline runner includes the new JavaScript and static SQL checks.

## Mandatory backend sequence for subsequent integration

- Verify real auth bearer server-side, inspect context handle and subject/skill authorization, ensure not in protected active assessment.
- Call existing Global AI guard; when disabled, return unavailable without source/provider call.
- Call service-only Math proof RPC. Require exact source and Tutor content hashes and verify topic/language/feature gate. Do **not** treat the 243-card metadata snapshot as a runtime permission.
- Fetch approved source text via existing read-only Tutor/source RPCs; cross-check source ID/version/hashes with proof and perform output safety review.
- Reserve **new** mixed quota only after release and source proof; handle one requested response ID idempotently across server restarts. Verify full context again immediately before provider call and before reply delivery.
- Do not touch old `exam-prep-ai`. Never write AI output into placements, evidence, responses, retests, stages, skills, Practice/Tours, certifications or localStorage.

## NO-GO barriers and deferred product decisions

**No PostgreSQL execution** completed; source-only checks cannot prove syntax/runtime/concurrency. Need real isolated PG, RLS/auth review, Edge deployment/test authorization, live-source fidelity, correct error/timeout release and distributed idempotent replay. Temporary 1 prepared / 3 generated and five-hour quota remain provisional until provider economics, quality and owner review. Existing Mathematics Exam Prep and its three AI beta entitlements must remain independent; separate owner approval required for any real Global AI beta.

**Production, Supabase writes, main and Vercel deployments: none for this milestone.**
