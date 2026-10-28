-- Narrow compatibility fix for the existing Pro beta quota rollout.
-- Production evidence: PostgreSQL rejected a 5-unit reservation because
-- original quota_holds_weight_check only allowed 3. The shared usage
-- counter was also limited to 3; both constraints must be updated together.
-- No attempt, score, consent, request, quota, receipt or budget rows change.
BEGIN;
SET LOCAL lock_timeout='3s';
SET LOCAL statement_timeout='60s';
DO $pre$
DECLARE quota_check text; usage_check text;
BEGIN
 SELECT pg_get_constraintdef(c.oid) INTO quota_check FROM pg_constraint c
 WHERE c.conrelid='private.iclub_ai_v21_freeform_quota_holds'::regclass
   AND c.conname='iclub_ai_v21_freeform_quota_holds_weight_check'
   AND c.contype='c';
 SELECT pg_get_constraintdef(c.oid) INTO usage_check FROM pg_constraint c
 WHERE c.conrelid='private.iclub_ai_v21_beta_usage'::regclass
   AND c.conname='iclub_ai_v21_beta_usage_committed_count_check'
   AND c.contype='c';
 IF quota_check IS DISTINCT FROM 'CHECK ((weight = 3))'
    OR usage_check IS DISTINCT FROM 'CHECK (((committed_count >= 0) AND (committed_count <= 3)))'
 THEN RAISE EXCEPTION 'Legacy quota checks differ; abort without modification'; END IF;
 IF (SELECT count(*) FROM private.iclub_ai_practice_beta_grants_v1 WHERE enabled)<>3
 OR NOT EXISTS(SELECT 1 FROM private.iclub_ai_practice_context_v1_control
  WHERE singleton=1 AND enabled AND owner_user_id IS NULL AND NOT error_enabled)
 OR NOT EXISTS(SELECT 1 FROM private.iclub_ai_practice_freeform_pc3_control
  WHERE singleton=1 AND enabled)
 OR NOT EXISTS(SELECT 1 FROM private.iclub_ai_practice_receipt_v1_control
  WHERE singleton=1 AND enabled)
 OR NOT EXISTS(SELECT 1 FROM private.iclub_ai_v21_freeform_budget_control
  WHERE singleton=1 AND enabled AND owner_permitted AND include_free_beta
    AND model='gpt-5.4-mini' AND maximum_lifetime_microusd=5000000
    AND maximum_per_request_microusd=50000
    AND maximum_per_learner_microusd=750000 AND maximum_parallel=2)
 OR NOT EXISTS(SELECT 1 FROM private.iclub_plan_policies plan
   JOIN private.iclub_ai_usage_policies policy
    ON policy.usage_policy_code=plan.ai_usage_policy_code
   WHERE plan.plan_code='pro' AND plan.is_active
     AND plan.policy_version='global_ai_tariffs_v1'
     AND policy.is_active AND policy.policy_version='global_ai_tariffs_v1'
     AND policy.period_seconds=18000 AND policy.allowance_units=14
     AND policy.generation_weight=5 AND policy.prepared_weight=1)
 OR strpos(pg_get_functiondef(
   'public.reserve_iclub_ai_v21_freeform_quota_v1(uuid,uuid,text)'::regprocedure),
   'v_weight:=5')=0
 OR strpos(pg_get_functiondef(
   'public.finish_iclub_ai_v21_freeform_quota_v1(uuid,uuid,text,text)'::regprocedure),
   'committed_count-h.weight')=0
 THEN RAISE EXCEPTION 'Pro beta code or financial safety invariant differs; abort'; END IF;
END $pre$;
-- Atomic constraints: allow only original 3-unit requests or approved
-- 5-unit Pro generation; allow shared counters from 0 through 14.
ALTER TABLE private.iclub_ai_v21_freeform_quota_holds
 DROP CONSTRAINT iclub_ai_v21_freeform_quota_holds_weight_check,
 ADD CONSTRAINT iclub_ai_v21_freeform_quota_holds_weight_check
 CHECK (weight IN (3,5)) NOT VALID;
ALTER TABLE private.iclub_ai_v21_beta_usage
 DROP CONSTRAINT iclub_ai_v21_beta_usage_committed_count_check,
 ADD CONSTRAINT iclub_ai_v21_beta_usage_committed_count_check
 CHECK (committed_count>=0 AND committed_count<=14) NOT VALID;
ALTER TABLE private.iclub_ai_v21_freeform_quota_holds
 VALIDATE CONSTRAINT iclub_ai_v21_freeform_quota_holds_weight_check;
ALTER TABLE private.iclub_ai_v21_beta_usage
 VALIDATE CONSTRAINT iclub_ai_v21_beta_usage_committed_count_check;
DO $post$
DECLARE quota_check text;usage_check text;
BEGIN
 SELECT pg_get_constraintdef(c.oid) INTO quota_check FROM pg_constraint c
 WHERE c.conrelid='private.iclub_ai_v21_freeform_quota_holds'::regclass
 AND c.conname='iclub_ai_v21_freeform_quota_holds_weight_check';
 SELECT pg_get_constraintdef(c.oid) INTO usage_check FROM pg_constraint c
 WHERE c.conrelid='private.iclub_ai_v21_beta_usage'::regclass
 AND c.conname='iclub_ai_v21_beta_usage_committed_count_check';
 IF quota_check NOT LIKE '%weight = ANY%' AND quota_check NOT LIKE '%weight IN%'
 THEN RAISE EXCEPTION 'Unexpected quota constraint: %', quota_check; END IF;
 IF usage_check NOT LIKE '%committed_count <= 14%'
 THEN RAISE EXCEPTION 'Unexpected usage constraint: %', usage_check; END IF;
 IF EXISTS(SELECT 1 FROM pg_constraint c WHERE c.conname IN (
 'iclub_ai_v21_freeform_quota_holds_weight_check',
 'iclub_ai_v21_beta_usage_committed_count_check') AND NOT c.convalidated)
 THEN RAISE EXCEPTION 'Constraints were not validated'; END IF;
END $post$;
COMMIT;
