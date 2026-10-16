# iClub AI v2.1 — hosted Auth and Practice access boundaries (metadata-only audit)

**Date:** 16 October 2026. **Scope:** read-only production catalog + isolated QA hardening; Global AI remains OFF. **Branch:** `qa/iclub-ai-layer-v21-20261012`.

## What was checked against live Supabase — safely

Observed project `iClub_APP` (`mmmduffgpvwjdpruzikw`) using *catalog-only SELECT*, not selecting actual records from user, JWT, session, learner result, academic answer, or commerce tables.

- `auth.users`, `auth.sessions`, `auth.identities`, `auth.refresh_tokens`, and `auth.audit_log_entries`: RLS enabled; no `SELECT` table grants to `anon` or `authenticated`. No actual user rows inspected.
- `public.practice_sessions_v4`, `public.practice_session_answers_v4`, `public.questions`, and `private.iclub_global_ai_runtime_config`: RLS enabled, no direct `SELECT` grants to `anon` or `authenticated`.
- `public.user_subjects`: table-level SELECT grants exist, but RLS is enabled. Inspected policy definitions `user_subjects_select_own` and `user_subjects_rw_own`; each uses `user_id = auth.uid()`. This is observed catalog configuration only; it is **not** an authenticated cross-account runtime proof.
- `public.subjects`: readable subject catalog. This does **not** authorize AI.
- Existing `practice-ai` and `exam-prep-ai` remain separate deployed functions; `get_iclub_ai_v21_*` and resolver candidate are not production-deployed. The previously established 24+1 RPC release blockers remain.

Source reference for Supabase Auth semantics: Supabase official JWT claims reference `https://supabase.com/docs/guides/auth/jwt-fields` and Securing Edge Functions guide `https://supabase.com/docs/guides/functions/auth`. The hosted GoTrue `/auth/v1/user` endpoint is relied upon for *future* JWT verification; **no real learner JWT was tested** and no claim is made that the new Global AI candidate is running against Supabase.

## Actual QA-code improvement

- `qa/edge_v21/supabase_services.ts`: bearer must be verified by the trusted Auth service, and Auth must explicitly return `role: authenticated` with UUID identity. A missing role, `anon`/`service_role`, invalid UUID, or an included foreign `aud` fails closed. User-chosen payloads cannot inject their identity or entitlement.
- `qa/edge_v21/supabase_services_test.ts`: tests reject forged token when Auth responds 401 and reject id-shaped JSON without an authenticated role, wrong audience, foreign or privileged roles.
- `.github/workflows/iclub-ai-real-preview-qa.yml`: trigger protection for changes to both server adapter and its tests; added original P9 `NO_GO` regression.
- `qa/ai-v21-live-release-auth-catalog-readonly-20261016.json`: narrow, non-identifying live catalog snapshot (RLS grants, selected own-subject policy predicates; no learner data).
- `qa/ai-v21-live-release-safety-gate.cjs`: exact catalog checks refuse changed RLS, direct read grants, missing own-subject policy conditions or fake hosted Auth approval.
- `qa/ai-v21-live-release-safety-gate.test.cjs`: forgeries, RLS tampering and fabricated successful hosted verification are rejected.

## Strictly unresolved

1. A live `auth/v1/user` check with a real signed learner JWT was **not** carried out; doing so requires a separately approved genuine test account and environment.
2. RLS metadata is not a proof of runtime behavior across accounts. This phase did **not** read user data or perform an impersonation.
3. New Global AI v2.1 server RPCs (24 core plus one exact Practice resolver) and Edge are **unapplied**. A green synthetic HTTP + scratch PostgreSQL test cannot substitute for deployment-readiness review.
4. No signed editorial original/source-rights + RU/UZ/EN publication exists for real student error explanations.
5. The actual approved Preview is still an entirely isolated instructional demonstration, not real AI access.

**Preserve:** production, all student progress, localStorage, Supabase schema, tuition/tariffs, mathematics tutor, accepted AI Option A logo, and the approved one-click QA user experience.

**Next safe technical step:** finish a negative deployment-readiness test of current-screen and source-release server contracts against disposable PostgreSQL, without connecting to or writing real accounts or shipping v2.1.
