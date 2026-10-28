-- Complete the finalized Practice AI access fix for ONLY the individually
-- authorized Math/Exam Prep Pro beta: a separate unfinished Practice row
-- must not block a VERIFIED FINALIZED result's bounded model quota or
-- editorially reviewed general help. All live Tour/Exam Prep protection
-- and any non-beta user's previous restriction remain fail-closed.
-- No score, attempt, learner, usage, budget, receipt or subscription writes.
BEGIN;
SET LOCAL lock_timeout='3s';
SET LOCAL statement_timeout='65s';
DO $guard$
BEGIN
 IF strpos(pg_get_functiondef('public.reserve_iclub_ai_v21_freeform_quota_v1(uuid,uuid,text)'::regprocedure),
 'OR EXISTS (SELECT 1 FROM public.practice_sessions_v4')=0
 OR strpos(pg_get_functiondef('public.deliver_iclub_ai_v21_beta_prepared_service(uuid,uuid,text,text)'::regprocedure),
 'OR EXISTS (')=0
 OR strpos(pg_get_functiondef('public.finish_iclub_ai_v21_freeform_quota_v1(uuid,uuid,text,text)'::regprocedure),
    'OR EXISTS(SELECT 1 FROM public.practice_sessions_v4')=0
 OR (SELECT count(*) FROM private.iclub_ai_practice_beta_grants_v1 WHERE enabled)<>3
 OR (SELECT count(*) FROM private.iclub_ai_practice_beta_grants_v1 g
      WHERE g.enabled AND private.iclub_ai_math_beta_pro_quota_eligible_v1(g.user_id))<>1
 OR NOT EXISTS(SELECT 1 FROM private.iclub_ai_v21_freeform_budget_control
      WHERE singleton=1 AND enabled AND maximum_lifetime_microusd=5000000
        AND maximum_per_request_microusd=50000 AND maximum_per_learner_microusd=750000)
 THEN RAISE EXCEPTION 'Finalized beta quota/help prerequisite differs'; END IF;
END $guard$;
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
 -- In the consented Mathematics beta only, an unrelated resumable
 -- Practice session cannot invalidate a verified FINALIZED result. The
 -- context RPC still checks full ownership/finalization and the client
 -- hides the mark on the live quiz screen.
 IF private.iclub_ai_has_active_protected_assessment_v1(p_user_id)
 OR (NOT private.iclub_ai_math_beta_pro_quota_eligible_v1(p_user_id)
   AND EXISTS (SELECT 1 FROM public.practice_sessions_v4
    WHERE user_id=p_user_id AND status='in_progress'))
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
END $function$;

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
 -- General prepared navigation never contains a question/answer key.
 -- For the exact enrolled + consented Pro beta, a different abandoned
 -- Practice session must not disable all approved product help.
 IF private.iclub_ai_has_active_protected_assessment_v1(p_user_id)
 OR (NOT private.iclub_ai_math_beta_pro_quota_eligible_v1(p_user_id)
   AND EXISTS (
    SELECT 1 FROM public.practice_sessions_v4
    WHERE user_id=p_user_id AND status='in_progress'))
 THEN RETURN jsonb_build_object('ok',false,'reason','active_assessment'); END IF;

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
END $function$;

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
  OR (NOT private.iclub_ai_math_beta_pro_quota_eligible_v1(p_user_id)
   AND EXISTS(SELECT 1 FROM public.practice_sessions_v4
    WHERE user_id=p_user_id AND status='in_progress'))
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
END $function$;

DO $check$
BEGIN
 IF strpos(pg_get_functiondef('public.reserve_iclub_ai_v21_freeform_quota_v1(uuid,uuid,text)'::regprocedure),
  'NOT private.iclub_ai_math_beta_pro_quota_eligible_v1(p_user_id)')=0
 OR strpos(pg_get_functiondef('public.deliver_iclub_ai_v21_beta_prepared_service(uuid,uuid,text,text)'::regprocedure),
  'NOT private.iclub_ai_math_beta_pro_quota_eligible_v1(p_user_id)')=0
 OR strpos(pg_get_functiondef('public.finish_iclub_ai_v21_freeform_quota_v1(uuid,uuid,text,text)'::regprocedure),
  'NOT private.iclub_ai_math_beta_pro_quota_eligible_v1(p_user_id)')=0
 OR strpos(pg_get_functiondef('public.reserve_iclub_ai_v21_freeform_quota_v1(uuid,uuid,text)'::regprocedure),
  'private.iclub_ai_has_active_protected_assessment_v1(p_user_id)')=0
 OR strpos(pg_get_functiondef('public.deliver_iclub_ai_v21_beta_prepared_service(uuid,uuid,text,text)'::regprocedure),
  'private.iclub_ai_has_active_protected_assessment_v1(p_user_id)')=0
 OR has_function_privilege('authenticated','public.reserve_iclub_ai_v21_freeform_quota_v1(uuid,uuid,text)','EXECUTE')
 OR has_function_privilege('authenticated','public.deliver_iclub_ai_v21_beta_prepared_service(uuid,uuid,text,text)','EXECUTE')
 OR has_function_privilege('authenticated','public.finish_iclub_ai_v21_freeform_quota_v1(uuid,uuid,text,text)','EXECUTE')
 THEN RAISE EXCEPTION 'Quota/help visibility exception is not restricted or guards missing'; END IF;
END $check$;
COMMIT;
