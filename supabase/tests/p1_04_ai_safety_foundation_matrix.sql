-- P1-04 AI safety foundation isolated acceptance matrix.
-- Requires: PGOPTIONS='-c p104.isolated_db=true'
-- Test-only; all synthetic mutations end in ROLLBACK.

\set ON_ERROR_STOP on

DO $$
BEGIN
  IF current_setting('p104.isolated_db',true) IS DISTINCT FROM 'true' THEN
    RAISE EXCEPTION 'P1-04 REFUSED: p104.isolated_db=true is required. Use only an ephemeral test database.';
  END IF;
END
$$;

BEGIN;

DO $$
DECLARE v_policy record; v_count int; v_runtime text;
BEGIN
  SELECT * INTO v_policy FROM private.exam_prep_ai_policy WHERE id=1;
  IF NOT FOUND OR v_policy.generation_enabled THEN
    RAISE EXCEPTION 'P1-04 baseline must keep generation disabled';
  END IF;
  IF v_policy.allowed_locales<>ARRAY['ru','uz','en']::text[] THEN
    RAISE EXCEPTION 'P1-04 locale contract drifted: %',v_policy.allowed_locales;
  END IF;
  SELECT runtime_status INTO v_runtime FROM private.exam_prep_optional_capability_status WHERE capability_code='ai_assist';
  IF v_runtime<>'shadow' THEN RAISE EXCEPTION 'P1-04 runtime must be shadow after endpoint deployment, got %',v_runtime; END IF;
  SELECT count(*) INTO v_count FROM private.exam_prep_ai_source_cards;
  IF v_count<>0 THEN RAISE EXCEPTION 'P1-04 baseline source cards unexpectedly seeded=%',v_count; END IF;
  SELECT count(*) INTO v_count FROM private.exam_prep_ai_audit;
  IF v_count<>0 THEN RAISE EXCEPTION 'P1-04 baseline audit unexpectedly nonempty=%',v_count; END IF;
END
$$;

DO $$
BEGIN
  IF has_function_privilege('anon','public.get_exam_prep_ai_guard_v1(text,text,text,integer)','EXECUTE') THEN
    RAISE EXCEPTION 'P1-04 anon can execute learner guard';
  END IF;
  IF NOT has_function_privilege('authenticated','public.get_exam_prep_ai_guard_v1(text,text,text,integer)','EXECUTE') THEN
    RAISE EXCEPTION 'P1-04 authenticated learner guard missing';
  END IF;
  IF has_function_privilege('authenticated','public.get_exam_prep_ai_source_cards_service_v1(text,text,text,text,integer)','EXECUTE') THEN
    RAISE EXCEPTION 'P1-04 authenticated can execute service source reader';
  END IF;
  IF has_function_privilege('authenticated','public.record_exam_prep_ai_audit_service_v1(uuid,uuid,text,text,text,text,jsonb,text,text,text,text,uuid,text,uuid[],text[],text,text,integer,integer,integer,numeric,text,text[],text)','EXECUTE') THEN
    RAISE EXCEPTION 'P1-04 authenticated can execute service audit writer';
  END IF;
  IF has_table_privilege('authenticated','private.exam_prep_ai_policy','SELECT')
     OR has_table_privilege('authenticated','private.exam_prep_ai_source_cards','SELECT')
     OR has_table_privilege('authenticated','private.exam_prep_ai_audit','SELECT')
     OR has_table_privilege('authenticated','private.exam_prep_ai_daily_usage','SELECT') THEN
    RAISE EXCEPTION 'P1-04 authenticated has direct private AI table read';
  END IF;
END
$$;

CREATE TEMP TABLE p104_user(user_id uuid primary key) ON COMMIT DROP;
INSERT INTO p104_user VALUES(gen_random_uuid());
GRANT SELECT ON p104_user TO authenticated,service_role;

INSERT INTO auth.users(id,aud,role,email,created_at,updated_at,is_sso_user,is_anonymous)
SELECT user_id,'authenticated','authenticated','p104-ai-'||replace(user_id::text,'-','')||'@invalid.example',now(),now(),false,false
FROM p104_user;

INSERT INTO public.users(id,first_name,last_name,language_code,created_at,must_change_password)
SELECT user_id,'P104','AI Safety','en',now(),false FROM p104_user;

UPDATE private.exam_prep_feature_config
SET rollout_state='controlled_beta',core_enabled=true,ai_enabled=true,mentor_enabled=false,kill_switch=false,updated_at=now()
WHERE id=1;

INSERT INTO private.exam_prep_feature_entitlements(
  user_id,entitlement_status,core_access,ai_assist,mentor_care_entitled,valid_from
)
SELECT user_id,'active',true,true,false,now() FROM p104_user;

UPDATE private.exam_prep_optional_capability_status
SET runtime_status='ready',gate_version='p1-04-isolated-test',updated_at=now()
WHERE capability_code='ai_assist';

UPDATE private.exam_prep_ai_policy
SET generation_enabled=true,updated_at=now()
WHERE id=1;

SELECT set_config(
  'request.jwt.claim.sub',
  (SELECT user_id::text FROM p104_user),
  true
);

SET LOCAL ROLE authenticated;

DO $$
DECLARE v jsonb;
BEGIN
  v:=public.get_exam_prep_ai_guard_v1('PX','progress_summary','ru',10);
  IF (v->>'allowed')::boolean OR v->>'reason'<>'invalid_component' THEN
    RAISE EXCEPTION 'P1-04 invalid component not blocked: %',v;
  END IF;

  v:=public.get_exam_prep_ai_guard_v1('P1','forbidden_mutation','ru',10);
  IF (v->>'allowed')::boolean OR v->>'reason'<>'interaction_not_allowed' THEN
    RAISE EXCEPTION 'P1-04 invalid interaction not blocked: %',v;
  END IF;

  v:=public.get_exam_prep_ai_guard_v1('P1','progress_summary','xx',10);
  IF (v->>'allowed')::boolean OR v->>'reason'<>'locale_not_allowed' THEN
    RAISE EXCEPTION 'P1-04 invalid locale not blocked: %',v;
  END IF;

  v:=public.get_exam_prep_ai_guard_v1('P1','progress_summary','en',2001);
  IF (v->>'allowed')::boolean OR v->>'reason'<>'input_too_long' THEN
    RAISE EXCEPTION 'P1-04 long input not blocked: %',v;
  END IF;

  v:=public.get_exam_prep_ai_guard_v1('P1','mentor_report_draft','en',20);
  IF (v->>'allowed')::boolean OR v->>'reason'<>'mentor_actor_required' THEN
    RAISE EXCEPTION 'P1-04 learner mentor-report request not blocked: %',v;
  END IF;

  v:=public.get_exam_prep_ai_guard_v1('P1','progress_summary','en',20);
  IF coalesce((v->>'allowed')::boolean,false) IS NOT TRUE OR v->>'mode'<>'ready' THEN
    RAISE EXCEPTION 'P1-04 clean entitled request did not reach ready guard: %',v;
  END IF;
END
$$;

RESET ROLE;

DO $$
DECLARE
  v_uid uuid;
  v_ass record;
  v_auth uuid;
BEGIN
  SELECT user_id INTO v_uid FROM p104_user;
  SELECT a.id assessment_id,a.assessment_version,a.component_code,c.id content_version_id,c.program_version_id
  INTO v_ass
  FROM private.exam_prep_assessments a
  JOIN private.exam_prep_content_versions c ON c.id=a.content_version_id
  WHERE a.component_code='P5'
  ORDER BY a.id
  LIMIT 1;
  IF v_ass.assessment_id IS NULL THEN RAISE EXCEPTION 'P1-04 no P5 assessment fixture available'; END IF;

  INSERT INTO private.exam_prep_session_authorizations(
    user_id,assessment_id,component_code,purpose,status,valid_until,reason
  ) VALUES(
    v_uid,v_ass.assessment_id,'P5','diagnostic','consumed',now()+interval '1 hour','P1-04 active-assessment guard fixture'
  ) RETURNING id INTO v_auth;

  INSERT INTO private.exam_prep_sessions(
    authorization_id,user_id,program_version_id,content_version_id,assessment_id,assessment_version,
    component_code,session_type,status,client_idempotency_key,total_items
  ) VALUES(
    v_auth,v_uid,v_ass.program_version_id,v_ass.content_version_id,v_ass.assessment_id,v_ass.assessment_version,
    'P5','diagnostic','active','p104-protected-session-0001',1
  );
END
$$;

SET LOCAL ROLE authenticated;
DO $$
DECLARE v jsonb;
BEGIN
  v:=public.get_exam_prep_ai_guard_v1('P5','theory_explanation','ru',20);
  IF (v->>'allowed')::boolean OR v->>'reason'<>'active_assessment' OR v->>'mode'<>'blocked' THEN
    RAISE EXCEPTION 'P1-04 active assessment did not block before AI path: %',v;
  END IF;

  v:=public.get_exam_prep_ai_guard_v1('P1','theory_explanation','ru',20);
  IF coalesce((v->>'allowed')::boolean,false) IS NOT TRUE THEN
    RAISE EXCEPTION 'P1-04 P5 protected session incorrectly blocked P1 component: %',v;
  END IF;
END
$$;
RESET ROLE;

INSERT INTO private.exam_prep_ai_source_cards(
  source_card_key,component_code,skill_code,card_type,locale,source_version,title,body_text,
  approval_status,rights_status,is_runtime_allowed,content_hash,approved_at
) VALUES
('p104:p1:theory:en:v1','P1',null,'theory','en','v1','P1 approved source','Original iClub P1 test source.','approved','original_iclub',true,'1111111111111111',now()),
('p104:p5:theory:en:v1','P5',null,'theory','en','v1','P5 approved source','Original iClub P5 test source.','approved','original_iclub',true,'2222222222222222',now()),
('p104:p1:draft:en:v1','P1',null,'theory','en','v1','Draft source','Must never be returned.','draft','original_iclub',false,'3333333333333333',null);

SET LOCAL ROLE service_role;
DO $$
DECLARE v jsonb;
BEGIN
  v:=public.get_exam_prep_ai_source_cards_service_v1('P1','en','theory',null,8);
  IF jsonb_array_length(v)<>1 OR v#>>'{0,component_code}'<>'P1' OR v#>>'{0,source_card_key}'<>'p104:p1:theory:en:v1' THEN
    RAISE EXCEPTION 'P1-04 P1 source allowlist/component isolation failed: %',v;
  END IF;
  v:=public.get_exam_prep_ai_source_cards_service_v1('P5','en','theory',null,8);
  IF jsonb_array_length(v)<>1 OR v#>>'{0,component_code}'<>'P5' OR v#>>'{0,source_card_key}'<>'p104:p5:theory:en:v1' THEN
    RAISE EXCEPTION 'P1-04 P5 source allowlist/component isolation failed: %',v;
  END IF;
END
$$;
RESET ROLE;

CREATE TEMP TABLE p104_academic_before AS
SELECT
  (SELECT count(*) FROM private.exam_prep_evidence_events) evidence_count,
  (SELECT count(*) FROM private.exam_prep_stage_states) stage_count,
  (SELECT count(*) FROM private.exam_prep_component_placements) placement_count,
  (SELECT count(*) FROM private.exam_prep_correction_cases) correction_count,
  (SELECT count(*) FROM private.exam_prep_retest_events) retest_count;

SET LOCAL ROLE service_role;
DO $$
DECLARE
  v_request uuid:=gen_random_uuid();
  v_uid uuid;
  v_first boolean;
  v_second boolean;
BEGIN
  SELECT user_id INTO v_uid FROM p104_user;
  v_first:=public.record_exam_prep_ai_audit_service_v1(
    v_request,v_uid,'P1','progress_summary','en','fallback',
    jsonb_build_object('test_only',true),
    'exam_prep_ai_policy_v1','exam_prep_ai_prompt_v1','exam_prep_ai_retrieval_v1','exam_prep_ai_response_v1',
    null,'p104-snapshot','{}'::uuid[],ARRAY['p104:p1:theory:en:v1'],null,null,12,0,0,0,'model_not_configured',ARRAY['test_only'],'p104-output-hash'
  );
  v_second:=public.record_exam_prep_ai_audit_service_v1(
    v_request,v_uid,'P1','progress_summary','en','fallback',
    jsonb_build_object('test_only',true),
    'exam_prep_ai_policy_v1','exam_prep_ai_prompt_v1','exam_prep_ai_retrieval_v1','exam_prep_ai_response_v1',
    null,'p104-snapshot','{}'::uuid[],ARRAY['p104:p1:theory:en:v1'],null,null,12,0,0,0,'model_not_configured',ARRAY['test_only'],'p104-output-hash'
  );
  IF v_first IS NOT TRUE OR v_second IS NOT FALSE THEN
    RAISE EXCEPTION 'P1-04 audit idempotency failed first=% second=%',v_first,v_second;
  END IF;
END
$$;
RESET ROLE;

DO $$
DECLARE v_count int; v_usage int; b record; a record;
BEGIN
  SELECT count(*) INTO v_count FROM private.exam_prep_ai_audit WHERE interaction_type='progress_summary' AND mode='fallback';
  IF v_count<>1 THEN RAISE EXCEPTION 'P1-04 audit row count expected 1 got %',v_count; END IF;
  SELECT request_count INTO v_usage FROM private.exam_prep_ai_daily_usage WHERE user_id=(SELECT user_id FROM p104_user) AND usage_date=current_date;
  IF v_usage<>1 THEN RAISE EXCEPTION 'P1-04 usage idempotency expected 1 got %',v_usage; END IF;

  SELECT * INTO b FROM p104_academic_before;
  SELECT
    (SELECT count(*) FROM private.exam_prep_evidence_events) evidence_count,
    (SELECT count(*) FROM private.exam_prep_stage_states) stage_count,
    (SELECT count(*) FROM private.exam_prep_component_placements) placement_count,
    (SELECT count(*) FROM private.exam_prep_correction_cases) correction_count,
    (SELECT count(*) FROM private.exam_prep_retest_events) retest_count
  INTO a;
  IF row_to_json(a)::text<>row_to_json(b)::text THEN
    RAISE EXCEPTION 'P1-04 AI audit/guard path mutated academic state before=% after=%',row_to_json(b),row_to_json(a);
  END IF;
END
$$;

ROLLBACK;

DO $$
DECLARE v_count int; v_runtime text; v_generation boolean;
BEGIN
  SELECT count(*) INTO v_count FROM auth.users WHERE email LIKE 'p104-ai-%@invalid.example';
  IF v_count<>0 THEN RAISE EXCEPTION 'P1-04 rollback left synthetic auth users=%',v_count; END IF;
  SELECT count(*) INTO v_count FROM private.exam_prep_ai_audit;
  IF v_count<>0 THEN RAISE EXCEPTION 'P1-04 rollback left audit rows=%',v_count; END IF;
  SELECT count(*) INTO v_count FROM private.exam_prep_ai_source_cards;
  IF v_count<>0 THEN RAISE EXCEPTION 'P1-04 rollback left source cards=%',v_count; END IF;
  SELECT generation_enabled INTO v_generation FROM private.exam_prep_ai_policy WHERE id=1;
  IF v_generation THEN RAISE EXCEPTION 'P1-04 rollback left generation enabled'; END IF;
  SELECT runtime_status INTO v_runtime FROM private.exam_prep_optional_capability_status WHERE capability_code='ai_assist';
  IF v_runtime<>'shadow' THEN RAISE EXCEPTION 'P1-04 rollback failed to restore shadow runtime=%',v_runtime; END IF;
END
$$;

\echo 'P1-04 AI safety foundation matrix: GREEN'
