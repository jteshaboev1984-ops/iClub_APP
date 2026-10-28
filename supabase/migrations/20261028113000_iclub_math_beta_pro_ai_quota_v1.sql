-- Pro-equivalent 14 units/5h for EXACT manually granted Math Exam Prep beta.
-- Each generated answer: 5 units; prepared help: 1 unit.
-- Other beta accounts retain 3/5h and old 3-unit generation cost.
-- No subscription, grades, scores, receipts, usage reset or budget increases.
BEGIN;
SET LOCAL lock_timeout='3s';
SET LOCAL statement_timeout='90s';
DO $pre$
BEGIN
 IF (SELECT count(*) FROM private.iclub_ai_practice_beta_grants_v1 WHERE enabled)<>3
 OR NOT EXISTS(SELECT 1 FROM private.iclub_ai_practice_context_v1_control
   WHERE singleton=1 AND enabled AND owner_user_id IS NULL AND NOT error_enabled)
 OR NOT EXISTS(SELECT 1 FROM private.iclub_ai_practice_freeform_pc3_control WHERE singleton=1 AND enabled)
 OR NOT EXISTS(SELECT 1 FROM private.iclub_ai_practice_receipt_v1_control WHERE singleton=1 AND enabled)
 OR NOT EXISTS(SELECT 1 FROM private.iclub_ai_v21_freeform_budget_control
   WHERE singleton=1 AND enabled AND owner_permitted AND include_free_beta
   AND model='gpt-5.4-mini' AND maximum_lifetime_microusd=5000000
   AND maximum_per_request_microusd=50000 AND maximum_per_learner_microusd=750000
   AND maximum_parallel=2 AND output_token_cap=384)
 OR NOT EXISTS(SELECT 1 FROM private.iclub_plan_policies pp
   JOIN private.iclub_ai_usage_policies po ON po.usage_policy_code=pp.ai_usage_policy_code
   WHERE pp.plan_code='pro' AND pp.is_active AND pp.policy_version='global_ai_tariffs_v1'
   AND po.is_active AND po.policy_version='global_ai_tariffs_v1'
   AND po.period_seconds=18000 AND po.allowance_units=14
   AND po.generation_weight=5 AND po.prepared_weight=1)
 THEN RAISE EXCEPTION 'Math beta Pro rollout safety prerequisite changed'; END IF;
END $pre$;

CREATE OR REPLACE FUNCTION private.iclub_ai_math_beta_pro_quota_eligible_v1(p_user_id uuid)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path TO ''
AS $eligible$
 SELECT p_user_id IS NOT NULL AND EXISTS(
  SELECT 1 FROM private.iclub_ai_practice_beta_grants_v1 g
  JOIN private.exam_prep_beta_members bm ON bm.user_id=g.user_id
    AND bm.member_status='active' AND bm.service_mode='ai_assist'
  JOIN private.exam_prep_beta_cohorts c ON c.id=bm.cohort_id
    AND c.program_key='math_as_p1_p5' AND c.cohort_status='canary'
  JOIN private.exam_prep_beta_consents con ON con.user_id=g.user_id
    AND con.cohort_id=c.id AND con.consent_scope='exam_prep_controlled_beta_v1'
    AND con.consent_status='granted' AND con.revoked_at IS NULL
  JOIN private.exam_prep_feature_entitlements ent ON ent.user_id=g.user_id
    AND ent.entitlement_status='active' AND ent.core_access AND ent.ai_assist
    AND (ent.valid_from IS NULL OR ent.valid_from<=now())
    AND (ent.valid_until IS NULL OR ent.valid_until>now())
  JOIN private.iclub_ai_v21_beta_members global_ai ON global_ai.user_id=g.user_id
    AND global_ai.enabled AND global_ai.consent_at IS NOT NULL
    AND global_ai.consent_version='global_ai_beta_v21'
  JOIN private.iclub_plan_policies plan ON plan.plan_code='pro'
    AND plan.is_active AND plan.policy_version='global_ai_tariffs_v1'
    AND plan.ai_usage_policy_code='pro_v1'
  JOIN private.iclub_ai_usage_policies pol
    ON pol.usage_policy_code=plan.ai_usage_policy_code
    AND pol.is_active AND pol.policy_version='global_ai_tariffs_v1'
    AND pol.period_seconds=18000 AND pol.allowance_units=14
    AND pol.prepared_weight=1 AND pol.generation_weight=5
  WHERE g.user_id=p_user_id AND g.enabled
    AND EXISTS(SELECT 1 FROM private.iclub_ai_practice_context_v1_control
       WHERE singleton=1 AND enabled AND owner_user_id IS NULL)
    AND EXISTS(SELECT 1 FROM private.iclub_ai_practice_freeform_pc3_control
       WHERE singleton=1 AND enabled)
    AND EXISTS(SELECT 1 FROM private.iclub_ai_practice_receipt_v1_control
       WHERE singleton=1 AND enabled)
 )
$eligible$;
REVOKE ALL ON FUNCTION private.iclub_ai_math_beta_pro_quota_eligible_v1(uuid) FROM PUBLIC,anon,authenticated;

CREATE OR REPLACE FUNCTION public.reserve_iclub_ai_v21_freeform_quota_v1(p_request_id uuid, p_user_id uuid, p_request_fingerprint text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE c private.iclub_ai_v21_beta_control%rowtype;
 u private.iclub_ai_v21_beta_usage%rowtype;
 v_now timestamptz:=clock_timestamp();
 v_units integer:=3;v_weight integer:=3;
BEGIN
 IF p_request_id IS NULL OR p_user_id IS NULL
 OR p_request_fingerprint !~ '^[a-f0-9]{64}$'
 THEN RETURN jsonb_build_object('allowed',false,'reason','invalid_quota_request'); END IF;
 -- Exact SAME lock order as existing prepared-Help RPC, so prepared(1)
 -- cannot arrive concurrently and overbook generated(3).
 SELECT * INTO c FROM private.iclub_ai_v21_beta_control
 WHERE singleton=1 FOR UPDATE;
 IF NOT FOUND OR NOT c.beta_enabled OR NOT c.prepared_enabled
 OR c.generation_enabled OR c.approved_release='none'
 OR NOT EXISTS(SELECT 1 FROM private.iclub_ai_v21_freeform_budget_control
  WHERE singleton=1 AND enabled AND owner_permitted AND include_free_beta)
 OR NOT EXISTS(SELECT 1 FROM private.iclub_ai_v21_beta_members
  WHERE user_id=p_user_id AND enabled AND consent_at IS NOT NULL
   AND consent_version='global_ai_beta_v21')
 THEN RETURN jsonb_build_object('allowed',false,'reason','beta_generation_disabled'); END IF;
 IF private.iclub_ai_has_active_protected_assessment_v1(p_user_id)
 OR EXISTS (SELECT 1 FROM public.practice_sessions_v4
 WHERE user_id=p_user_id AND status='in_progress')
 THEN RETURN jsonb_build_object('allowed',false,'reason','active_assessment'); END IF;
 IF EXISTS(SELECT 1 FROM private.iclub_ai_v21_freeform_quota_holds
   WHERE request_id=p_request_id)
 OR EXISTS(SELECT 1 FROM private.iclub_ai_v21_beta_deliveries
   WHERE request_id=p_request_id)
 THEN RETURN jsonb_build_object('allowed',false,'reason','request_already_seen'); END IF;
 INSERT INTO private.iclub_ai_v21_beta_usage(user_id,started_at,committed_count)
 VALUES(p_user_id,v_now,0) ON CONFLICT(user_id) DO NOTHING;
 SELECT * INTO u FROM private.iclub_ai_v21_beta_usage
 WHERE user_id=p_user_id FOR UPDATE;
 IF u.started_at<=v_now-interval '5 hours' THEN
  UPDATE private.iclub_ai_v21_beta_usage
  SET started_at=v_now,committed_count=0,updated_at=v_now
  WHERE user_id=p_user_id;
  u.started_at:=v_now;u.committed_count:=0;
 END IF;
 IF private.iclub_ai_math_beta_pro_quota_eligible_v1(p_user_id) THEN
  v_units:=14;v_weight:=5;
 END IF;
 IF u.committed_count+v_weight>v_units
 THEN RETURN jsonb_build_object('allowed',false,
   'reason','usage_exhausted','reset_at',u.started_at+interval '5 hours'); END IF;
 INSERT INTO private.iclub_ai_v21_freeform_quota_holds(
 request_id,user_id,request_fingerprint,period_started_at,weight,state)
 VALUES(p_request_id,p_user_id,p_request_fingerprint,u.started_at,v_weight,'reserved');
 UPDATE private.iclub_ai_v21_beta_usage
 SET committed_count=committed_count+v_weight,updated_at=v_now WHERE user_id=p_user_id;
 RETURN jsonb_build_object('allowed',true,'weight',v_weight);
END $function$

CREATE OR REPLACE FUNCTION public.finish_iclub_ai_v21_freeform_quota_v1(p_request_id uuid, p_user_id uuid, p_request_fingerprint text, p_outcome text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE h private.iclub_ai_v21_freeform_quota_holds%rowtype;
 u private.iclub_ai_v21_beta_usage%rowtype;
 final_state text:=p_outcome;
 denied boolean:=false;
BEGIN
 PERFORM 1 FROM private.iclub_ai_v21_beta_control
 WHERE singleton=1 FOR UPDATE;
 SELECT * INTO h FROM private.iclub_ai_v21_freeform_quota_holds
  WHERE request_id=p_request_id FOR UPDATE;
 IF h.request_id IS NULL OR h.user_id IS DISTINCT FROM p_user_id
 OR h.request_fingerprint IS DISTINCT FROM p_request_fingerprint
 OR h.state<>'reserved' OR p_outcome NOT IN('completed','released')
 THEN RETURN jsonb_build_object('ok',false,'reason','quota_settlement_denied'); END IF;
 SELECT * INTO u FROM private.iclub_ai_v21_beta_usage
 WHERE user_id=p_user_id FOR UPDATE;
 IF p_outcome='completed' AND (
  NOT EXISTS(SELECT 1 FROM private.iclub_ai_v21_beta_members
   WHERE user_id=p_user_id AND enabled
   AND consent_version='global_ai_beta_v21' AND consent_at IS NOT NULL)
  OR NOT EXISTS(SELECT 1 FROM private.iclub_ai_v21_beta_control
   WHERE singleton=1 AND beta_enabled AND prepared_enabled
    AND NOT generation_enabled AND approved_release<>'none')
  OR NOT EXISTS(SELECT 1 FROM private.iclub_ai_v21_freeform_budget_control
   WHERE singleton=1 AND enabled AND owner_permitted)
  OR NOT EXISTS(SELECT 1 FROM private.iclub_ai_v21_freeform_budget_ledger
   WHERE request_id=p_request_id AND user_id=p_user_id
   AND request_fingerprint=p_request_fingerprint AND state='charged')
  OR private.iclub_ai_has_active_protected_assessment_v1(p_user_id)
  OR EXISTS(SELECT 1 FROM public.practice_sessions_v4
   WHERE user_id=p_user_id AND status='in_progress')
 ) THEN
  -- A charged provider response is still a real cost, but a revoked/blocked
  -- user must NOT receive or pay learner units for the model explanation.
  final_state:='released';denied:=true;
 END IF;
 IF final_state='released' AND u.started_at=h.period_started_at THEN
  UPDATE private.iclub_ai_v21_beta_usage SET
   committed_count=greatest(0,committed_count-h.weight),
   updated_at=clock_timestamp()
  WHERE user_id=p_user_id;
 END IF;
 UPDATE private.iclub_ai_v21_freeform_quota_holds
 SET state=final_state,finished_at=clock_timestamp()
 WHERE request_id=p_request_id;
 IF denied THEN
  RETURN jsonb_build_object('ok',false,'released',true,
   'reason','generation_no_longer_authorized');
 END IF;
 RETURN jsonb_build_object('ok',true,'state',final_state);
END $function$

CREATE OR REPLACE FUNCTION public.deliver_iclub_ai_v21_beta_prepared_service(p_user_id uuid, p_request_id uuid, p_help_key text, p_locale text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
 c private.iclub_ai_v21_beta_control%rowtype;
 m private.iclub_ai_v21_beta_members%rowtype;
 s private.iclub_ai_v21_beta_help_sources%rowtype;
 u private.iclub_ai_v21_beta_usage%rowtype;
 old private.iclub_ai_v21_beta_deliveries%rowtype;
 v_now timestamptz := clock_timestamp();
 v_limit integer:=3;
BEGIN
 IF p_user_id IS NULL OR p_request_id IS NULL
 OR p_locale NOT IN ('ru','uz','en')
 OR p_help_key NOT IN (
  'support_help','catalog_help','ratings_help','home_next',
  'practice_rules','practice_after','tour_rules','books_help','about_help',
  'notifications_help','community_help','certificates_help',
  'profile_meaning','video_help','recs_help','archive_help',
  'nav_home','nav_courses','nav_ratings','nav_profile','nav_about','nav_support'
 ) THEN RETURN jsonb_build_object('ok',false,'reason','in_development'); END IF;

 -- The singleton row lock serializes read/grant/quota, including two workers.
 SELECT * INTO c FROM private.iclub_ai_v21_beta_control
  WHERE singleton=1 FOR UPDATE;
 IF NOT FOUND OR NOT c.beta_enabled OR NOT c.prepared_enabled
 OR c.generation_enabled OR c.approved_release='none' THEN
  RETURN jsonb_build_object('ok',false,'reason','beta_not_enabled'); END IF;

 SELECT * INTO m FROM private.iclub_ai_v21_beta_members
  WHERE user_id=p_user_id;
 IF NOT FOUND OR NOT m.enabled OR m.consent_version<>'global_ai_beta_v21'
 OR m.consent_at IS NULL THEN
  RETURN jsonb_build_object('ok',false,'reason','beta_not_enabled'); END IF;

 -- Protection is derived from server academic tables, never browser view hints.
 IF private.iclub_ai_has_active_protected_assessment_v1(p_user_id)
 OR EXISTS (
  SELECT 1 FROM public.practice_sessions_v4
  WHERE user_id=p_user_id AND status='in_progress'
 ) THEN
  RETURN jsonb_build_object('ok',false,'reason','active_assessment'); END IF;

 SELECT * INTO s FROM private.iclub_ai_v21_beta_help_sources
  WHERE help_key=p_help_key AND locale=p_locale FOR SHARE;
 IF NOT FOUND OR NOT s.published OR s.revoked
 OR NOT s.content_reviewed OR NOT s.rights_reviewed
 OR NOT s.locale_reviewed OR s.approved_at IS NULL
 OR encode(extensions.digest(convert_to(s.message,'UTF8'),'sha256'),'hex')
    <>s.source_hash THEN
  RETURN jsonb_build_object('ok',false,'reason','in_development'); END IF;

 -- A same-ID retry is idempotent only for the SAME owner/key/version/revision;
 -- after revocation, neither new nor historical messages are returned.
 SELECT * INTO old FROM private.iclub_ai_v21_beta_deliveries
  WHERE request_id=p_request_id;
 IF FOUND THEN
  IF old.user_id=p_user_id AND old.help_key=p_help_key
  AND old.locale=p_locale AND old.source_hash=s.source_hash
  AND old.source_version=s.source_version
  AND old.publication_revision=s.publication_revision THEN
   RETURN jsonb_build_object('ok',true,'message',s.message,
     'mode','prepared','academic_state_changed',false,
     'provider_called',false,'replayed',true);
  END IF;
  RETURN jsonb_build_object('ok',false,'reason','request_conflict');
 END IF;

 INSERT INTO private.iclub_ai_v21_beta_usage(user_id,started_at,committed_count)
 VALUES (p_user_id,v_now,0)
 ON CONFLICT(user_id) DO NOTHING;
 SELECT * INTO u FROM private.iclub_ai_v21_beta_usage
  WHERE user_id=p_user_id FOR UPDATE;
 IF u.started_at <= v_now-interval '5 hours' THEN
  UPDATE private.iclub_ai_v21_beta_usage
   SET started_at=v_now,committed_count=0,updated_at=v_now
   WHERE user_id=p_user_id;
  u.committed_count:=0;
 END IF;
 IF private.iclub_ai_math_beta_pro_quota_eligible_v1(p_user_id) THEN v_limit:=14; END IF;
 IF u.committed_count>=v_limit THEN
  RETURN jsonb_build_object('ok',false,'reason','usage_exhausted',
    'reset_at',u.started_at+interval '5 hours'); END IF;
 INSERT INTO private.iclub_ai_v21_beta_deliveries(
  request_id,user_id,help_key,locale,source_version,source_hash,publication_revision
 ) VALUES (
  p_request_id,p_user_id,p_help_key,p_locale,
  s.source_version,s.source_hash,s.publication_revision
 );
 UPDATE private.iclub_ai_v21_beta_usage
 SET committed_count=committed_count+1,updated_at=v_now
 WHERE user_id=p_user_id;

 RETURN jsonb_build_object('ok',true,'message',s.message,
  'mode','prepared','academic_state_changed',false,
  'provider_called',false,'replayed',false);
END $function$

DO $post$ BEGIN
 IF has_function_privilege('authenticated','private.iclub_ai_math_beta_pro_quota_eligible_v1(uuid)','EXECUTE')
 OR has_function_privilege('anon','private.iclub_ai_math_beta_pro_quota_eligible_v1(uuid)','EXECUTE')
 THEN RAISE EXCEPTION 'Unsafe quota helper privileges'; END IF;
END $post$;
COMMIT;