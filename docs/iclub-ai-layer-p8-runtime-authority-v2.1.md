# iClub AI v2.1 — §31 read-only authority bridge (QA only)

**Date:** 2026-10-13. **Baseline:** `9afc7b44aead03b2a30544e6e7d4c4eb8670efbf`. **Branch:** `qa/iclub-ai-layer-v21-20261012`.

## Verified production metadata (SELECT/pg_catalog only)

On 13 October, the real private runtime singleton was `ui_enabled=false`, `gateway_enabled=false`, `generation_enabled=false`, `kill_switch=true`, and `global_ai_rollout_mode=off`. The existing `public.get_iclub_global_ai_guard_service_v1`, `private.iclub_ai_has_active_protected_assessment_v1`, `private.iclub_rollout_allows_user_v1`, `public.get_iclub_subject_access_guard_service_v1`, and `public.get_iclub_subscription_capabilities_service_v1` signatures and implementation were verified in live system catalogs without learner data access.

Existing readiness currently includes broad `global/basic` and one `exam_prep/full` scope. v1's academic gate requires subject-wide `full`; the approved v2 design instead uses its OWN exact subject/topic/locale **editorial source proof** on top of existing v1 *cohort, enrollment, subject-opening, subscription, protected-exam and runtime* controls. It does not override the v1 guard, change its behavior, or route the existing Mathematics Tutor through v2.

## Implemented as an unapplied scratch-only SQL draft

`qa/sql_drafts/iclub_ai_v21_live_authority_UNAPPLIED.sql` defines five service-role RPCs matching `qa/edge_v21/supabase_services.ts`. It is protected by local/scratch hostname and database guards; there are NO changes to production migrations.

1. **Runtime:** Reads current v1 flags and a separate default-DENY owner release-control row. No owner approval row means `release_approved=false`; published content alone cannot enable learner access.
2. **Protected assessment:** Calls the current v1 server protection guard and treats null/exception as protected.
3. **Rollout:** Requires explicit owner release, runtime not killed, v1 cohort function, existing real subject enrollment + active status, v1 subject-opening entitlement guard, an unprotected learner, and exact Lesson/finished Practice feature/topic shape. Other surfaces remain denied until separately verified.
4. **Entitlement:** Uses existing subscription capabilities and maps valid Free/Plus/Pro into the **temporary** `*_qa_v2` meter policies. Unknown plans/unresolved capabilities denied; Plus/Pro cannot receive generation policy where existing capability denies generation. No production tariff writes.
5. **Provider budget:** Always returns denied, even if source and cohort are ready. The existing Mathematics Exam Prep money ledger is not reusable as a Global AI budget. Monetary caps, reservations and provider configuration remain for a further separately reviewed stage; NEVER activate real paid generation before then.

Only `service_role` has EXECUTE on these learner-service RPCs. It receives **no update privilege** on independent release control. No learner or Edge RPC can approve a release. Reviewer/publisher authority from §30 is unchanged.

## Synthetic test and scope

The native PostgreSQL local suite injects synthetic v1-interface stubs and checks runtime OFF, missing owner permission, canary, Biology/Chemistry/Economics/Informatics enrollment, subject-opening restriction, unexpected screen, role grants, Free/Plus/Pro entitlement, active exam, subject revocation, global kill switch and provider DENY. All state is reverted by `ROLLBACK`. Node checks SQL controls, Deno tests exact Edge RPC calls. This does **not** validate real Supabase installation, paid provider billing or synthetic Preview browser paths.

## Still NO-GO

Real owner approval and actor identity, secure production migration, atomic monetary provider budget/lease, short-lived encrypted delivery receipt and retention policy, source/editor-signature authenticated intake, actual Supabase Edge bundler validation, protected synthetic browser Preview, tariff decision and beta approval remain outstanding. No production, main, learner data, original Mathematics Exam Prep or deployed functions were changed.
