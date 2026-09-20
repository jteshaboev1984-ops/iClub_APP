-- READ-ONLY public RPC surface inventory. No DDL, enrollment or academic writes.
-- Seven-RPC rollback is INSUFFICIENT if any other client-callable public RPC
-- may generate a plan or create a non-plan learning/mixed/retest authorization.
-- Do not interpret a successful SQL execution as a passing release gate.
BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ READ ONLY;
WITH exposed(signature, category, required_behavior) AS (
 VALUES
 ('public.generate_exam_prep_weekly_plan_safe_v1(text,text)','uncovered_plan_generator','enrolled: existing stable plan or explicit-change-only'),
 ('public.generate_exam_prep_weekly_plan_safe_v2(text)','plan_generator','enrolled: stable plan'),
 ('public.generate_exam_prep_weekly_plan_safe_v3(text)','plan_generator','enrolled: stable plan'),
 ('public.authorize_exam_prep_plan_item_safe_v1(uuid,integer)','numeric_plan_authorizer','enrolled: exact goal identity required'),
 ('public.authorize_exam_prep_correction_safe_v1(uuid)','uncovered_nonplan_authorizer','enrolled: no unbound fresh-credit authorization'),
 ('public.authorize_exam_prep_mixed_safe_v1(text)','uncovered_nonplan_authorizer','enrolled: no unbound fresh-credit authorization'),
 ('public.authorize_exam_prep_retest_safe_v1(uuid)','uncovered_nonplan_authorizer','enrolled: no unbound fresh-credit authorization'),
 ('public.start_exam_prep_session_safe_v1(uuid,text)','session_starter','enrolled: guard BOTH plan and nonplan academic-credit routes'),
 ('public.start_exam_prep_next_diagnostic_safe_v1(text,text)','explicit_exception','keep Stage 0 diagnostics functional'),
 ('public.authorize_exam_prep_timed_safe_v1(bigint)','explicit_exception','keep stage-gated timed practice functional'),
 ('public.authorize_exam_prep_revalidation_item_safe_v1(uuid,integer)','explicit_exception','keep governed revalidation independent'),
 ('public.save_exam_prep_exam_profile_v1(text,text,numeric,numeric)','exam_profile','preserve historical editor access and audit'),
 ('public.save_exam_prep_exam_profile_v2(text,text,numeric,numeric)','exam_profile','preserve current editor, no lost evidence')
)
SELECT jsonb_agg(jsonb_build_object(
 'signature',x.signature,'category',x.category,'contract',x.required_behavior,
 'present',p.oid IS NOT NULL,
 'authenticated_execute',CASE WHEN p.oid IS NOT NULL THEN has_function_privilege('authenticated',p.oid,'EXECUTE') ELSE false END,
 'owner_guard_in_body',CASE WHEN p.oid IS NOT NULL THEN position('private.exam_prep_weekly_flow_enrolled_v1' IN pg_get_functiondef(p.oid))>0 ELSE false END,
 'body_md5',CASE WHEN p.oid IS NOT NULL THEN md5(pg_get_functiondef(p.oid)) ELSE null END
) ORDER BY x.signature) AS exposed_rpc_inventory
FROM exposed x LEFT JOIN pg_proc p ON p.oid=to_regprocedure(x.signature);
COMMIT;
-- Release MUST fail if any non-exception generator/authorizer/starter route
-- lacks approved server-side enrollment-safe routing; verify inner delegates too.
-- This probe alone cannot prove a body is safe: inspect it and race-test it.
