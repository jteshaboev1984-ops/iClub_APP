# AI Layer P2/P5 — existing DB authority map v2.1
**2026-10-12 · QA-only · schema verified read-only in production Supabase. No learner rows inspected, and no DML/DDL performed.**

## Source-of-truth discovery

| New AI intent | Existing authoritative evidence | Required checks | Not enough by itself |
|---|---|---|---|
| Mathematics Exam Prep result | `private.exam_prep_sessions` (`id uuid`, `user_id uuid`, `component_code`, `session_type`, `status`, `finalized_at`, `content_version_id`) | Owner=current authenticated learner; `status='finalized'`, `finalized_at` present; only P1/P5; no active protected assessment | A finalized session does **not** prove which specific skill/source to retrieve; `skill_code` is not in this session table |
| Practice explanation after finish | `public.practice_sessions_v4` (`id bigint`, `user_id`, `subject_id`, `status`, `finalized_at`) joined server-side with `public.subjects` | Owner match; `status='finalized'`, `finalized_at` present; subject ID resolves to active subject, entitlement verifies access | UI claim `practice_completed` or client-supplied `subject_key` |
| Archived Tour explanation | `public.tour_attempts` (`id bigint`, `user_id`, `tour_id`, `status`) + `public.tour_session_runtime_v4` (`attempt_id`, `user_id`, `tour_id`, `finalized_at`) + `public.tours` -> `public.subjects` | `tour_attempts.status in ('submitted','time_expired')`; finalized runtime record with identical learner/attempt/tour; separate **server-verified archive unlock**; subject entitlement; protected assessment guard | The Tour attempt itself has **no `finalized_at` column**; submitted state alone does **not** authorize archive or reveal protected answers |

`public.tour_attempts.status` constraint explicitly allows `in_progress`, `submitted`, `time_expired`, `anti_cheat`, `abandoned`. Both anti-cheat and abandoned are **not** completed archive routes.

`private.exam_prep_sessions.status` permits `active`, `finalized`, `abandoned` and requires `finalized_at` on finalized records. `public.practice_sessions_v4.status` permits `in_progress`, `finalized`, `abandoned`.

## Existing server guard to preserve
Existing `public.get_iclub_global_ai_guard_service_v1` already confirms entitlement, rollout and a server-side active-protected-assessment guard. New code may **add** per-session ownership, subject/topic/locale governance and a second guard before delivery but must not alter or bypass the working guard. Existing Mathematics `exam-prep-ai` remains independent. Client may supply a resource handle and question text but never completion, ownership, academic grading, tariff or source readiness as authority.

## New QA-only implementation
- `qa/ai-layer-v21-server-context-existing-db.cjs`: server service interface for read-only context verification, protected assessment, ownership, subject mapping, completed attempt and separate archive unlock. It rechecks after asynchronous lookups; returns only eligibility metadata, `topic:null` and `sourceReady:false`. Therefore it **cannot** authorize an AI call or quota charge alone.
- `qa/ai-layer-v21-server-context-existing-db.test.cjs`: **21/21** isolated source-code tests passed: Math P1/P5, Practice finalized, Tours submitted/time_expired and separate runtime, archival entitlement, foreign user attempts, resource spoofing, revoke-while-processing and fail-closed backend errors.
- Registered in `qa/run-ai-layer-v21-offline.cjs` (13 suites total). This is not yet a complete native Node run, local PostgreSQL test or browser integration.

## P2 integration requirements before any live routing
1. Use a **server-authenticated** current learner; read session/attempt by validated ID and compare actual `user_id`. Never claim browser subject/status to be trustworthy.
2. Add a server-side context handle (or an equivalent authenticated scoped lookup), with revocation checks on subject switch, exam start and archive availability.
3. Map exact subject × feature × topic × locale to a **current approved versioned source**; the eligibility resolver alone deliberately returns no topic.
4. Recheck protected assessment and evidence freshness before paid provider call and before response delivery.
5. Preserve the old mathematics `exam-prep-ai` endpoint, user progress/local drafts, entitlements and P1/P5 firewall.
6. Deploy no new beta; stay with synthetic fixtures until native tests, scratch PostgreSQL, protected Preview and explicit owner decision.

**NO-GO:** client `finalized:true`, screenshot of completed result, or new GUI navigation are not proof. No live Global AI write, no Vercel build, no source/grade leakage.
