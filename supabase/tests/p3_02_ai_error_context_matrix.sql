-- P3-02 deterministic established-error context matrix.
-- Isolated CI only. Creates one rollback-only synthetic learner and never calls a model.
\set ON_ERROR_STOP on

DO $$
BEGIN
  IF current_setting('p302.isolated_db', true) IS DISTINCT FROM 'true' THEN
    RAISE EXCEPTION 'P3-02 AI error-context matrix requires p302.isolated_db=true';
  END IF;
END
$$;

BEGIN;

CREATE TEMP TABLE p302_error_fixture(
  component_code text primary key,
  user_id uuid not null,
  session_id uuid not null,
  expected_feedback_en text not null,
  expected_next_en text not null
) ON COMMIT DROP;

CREATE TEMP TABLE p302_error_state_before AS
SELECT
  (SELECT count(*) FROM private.exam_prep_evidence_events) AS evidence_count,
  (SELECT count(*) FROM private.exam_prep_skill_states) AS skill_state_count,
  (SELECT count(*) FROM private.exam_prep_stage_states) AS stage_state_count,
  (SELECT count(*) FROM private.exam_prep_component_placements) AS placement_count,
  (SELECT count(*) FROM private.exam_prep_correction_cases) AS correction_count,
  (SELECT count(*) FROM private.exam_prep_retest_events) AS retest_count,
  (SELECT count(*) FROM private.exam_prep_readiness_signoffs) AS readiness_count;

DO $$
DECLARE
  v_uid uuid:=gen_random_uuid();
  v_run text:='SV-P302CI-AI-ERROR';
  v_component text;
  v_ass record;
  v_auth uuid;
  v_session uuid;
BEGIN
  PERFORM private.register_exam_prep_synthetic_validation_run_v1(
    v_run,'p302-ai-error-context-v1',repeat('4',40),'p3-02',30202,'ai_shadow',
    'Rollback-only deterministic AI error-context validation'
  );

  INSERT INTO auth.users(id,aud,role,email,created_at,updated_at,is_sso_user,is_anonymous)
  VALUES(v_uid,'authenticated','authenticated','exam-prep-sv-p302-error-'||replace(v_uid::text,'-','')||'@invalid.example',now(),now(),false,false);

  INSERT INTO public.users(id,first_name,last_name,language_code,created_at,must_change_password)
  VALUES(v_uid,'P302','Synthetic Error Context','en',now(),false);

  INSERT INTO private.exam_prep_synthetic_identities(
    user_id,run_id,identity_kind,fixture_profile_key,identity_status,evidence_ref,purpose
  ) VALUES(
    v_uid,v_run,'learner','SVF-P302-AI-ERROR','active','p3-02-ai-error-context',
    'Dedicated rollback-only P3-02 synthetic learner; never real beta evidence.'
  );

  INSERT INTO private.exam_prep_feature_entitlements(
    user_id,entitlement_status,core_access,ai_assist,mentor_care_entitled,cohort_key,valid_from
  ) VALUES(v_uid,'active',true,true,false,null,now());

  FOREACH v_component IN ARRAY ARRAY['P1','P5']::text[] LOOP
    SELECT
      a.id assessment_id,a.assessment_version,a.content_version_id,cv.program_version_id,
      ai.question_id,ai.primary_skill_code,m.id content_meta_id,
      d.answer_match,d.feedback_en,d.next_action_en
    INTO v_ass
    FROM private.exam_prep_assessments a
    JOIN private.exam_prep_content_versions cv ON cv.id=a.content_version_id
    JOIN private.exam_prep_assessment_items ai
      ON ai.assessment_id=a.id AND ai.question_id IS NOT NULL
    JOIN private.exam_prep_question_content_meta m
      ON m.question_id=ai.question_id
     AND m.content_version_id=a.content_version_id
     AND m.reserve_role='diagnostic'
    JOIN private.exam_prep_diagnostic_rules d
      ON d.content_meta_id=m.id
     AND d.status='approved'
    WHERE a.component_code=v_component
      AND a.assessment_type='diagnostic'
      AND a.status='published'
    ORDER BY a.id,ai.item_order,d.approved_at DESC NULLS LAST,d.id DESC
    LIMIT 1;

    IF v_ass.assessment_id IS NULL OR v_ass.answer_match IS NULL THEN
      RAISE EXCEPTION 'P3-02 missing published deterministic diagnostic fixture for %',v_component;
    END IF;

    INSERT INTO private.exam_prep_session_authorizations(
      user_id,assessment_id,component_code,purpose,status,valid_until,reason
    ) VALUES(
      v_uid,v_ass.assessment_id,v_component,'diagnostic','consumed',now()+interval '1 hour',
      'P3-02 rollback-only AI error context fixture'
    ) RETURNING id INTO v_auth;

    INSERT INTO private.exam_prep_sessions(
      authorization_id,user_id,program_version_id,content_version_id,assessment_id,assessment_version,
      component_code,session_type,status,client_idempotency_key,total_items,finalized_at,finalize_idempotency_key
    ) VALUES(
      v_auth,v_uid,v_ass.program_version_id,v_ass.content_version_id,v_ass.assessment_id,v_ass.assessment_version,
      v_component,'diagnostic','finalized',
      'p302-ai-error-'||lower(v_component)||'-0001',1,now(),'p302-final-'||lower(v_component)||'-0001'
    ) RETURNING id INTO v_session;

    INSERT INTO private.exam_prep_session_items(
      session_id,item_order,item_kind,question_id,primary_skill_code,reserve_role,
      is_holdout,content_meta_id,item_version
    ) VALUES(
      v_session,1,'question',v_ass.question_id,v_ass.primary_skill_code,'diagnostic',
      false,v_ass.content_meta_id,'p302-error-context-v1'
    );

    INSERT INTO private.exam_prep_responses(
      session_id,item_order,user_id,client_idempotency_key,response_kind,user_answer,
      selected_answer,is_correct,evaluator_version,elapsed_ms
    ) VALUES(
      v_session,1,v_uid,'p302-response-'||lower(v_component)||'-0001','machine',
      v_ass.answer_match,v_ass.answer_match,false,'p302-error-context-v1',1000
    );

    INSERT INTO p302_error_fixture(component_code,user_id,session_id,expected_feedback_en,expected_next_en)
    VALUES(v_component,v_uid,v_session,v_ass.feedback_en,v_ass.next_action_en);
  END LOOP;
END
$$;

DO $$
BEGIN
  IF has_function_privilege('anon','public.get_exam_prep_ai_error_context_safe_v1(text,uuid,integer,text)','EXECUTE')
     OR NOT has_function_privilege('authenticated','public.get_exam_prep_ai_error_context_safe_v1(text,uuid,integer,text)','EXECUTE')
     OR has_function_privilege('authenticated','private.exam_prep_ai_error_context_payload_v1(uuid,text,uuid,integer,text)','EXECUTE')
  THEN
    RAISE EXCEPTION 'P3-02 AI error context privilege boundary failed';
  END IF;
END
$$;

SELECT set_config('request.jwt.claim.sub',(SELECT user_id::text FROM p302_error_fixture LIMIT 1),true);
SELECT set_config('request.jwt.claim.role','authenticated',true);

SET LOCAL ROLE authenticated;
DO $$
DECLARE
  v_component text;
  v_locale text;
  v jsonb;
  v_fixture record;
BEGIN
  FOREACH v_component IN ARRAY ARRAY['P1','P5']::text[] LOOP
    SELECT * INTO v_fixture FROM p302_error_fixture WHERE component_code=v_component;

    FOREACH v_locale IN ARRAY ARRAY['en','ru','uz']::text[] LOOP
      v:=public.get_exam_prep_ai_error_context_safe_v1(v_component,v_fixture.session_id,1,v_locale);

      IF coalesce((v->>'mapped')::boolean,false) IS NOT TRUE
         OR v->>'component_code'<>v_component
         OR v->>'locale'<>v_locale
         OR v->>'diagnostic_feedback' IS NULL
         OR v->>'next_action' IS NULL
         OR v->>'skill_code' IS NULL
      THEN
        RAISE EXCEPTION 'P3-02 mapped context failed component=% locale=% payload=%',v_component,v_locale,v;
      END IF;

      IF lower(v::text) LIKE '%correct_answer%'
         OR lower(v::text) LIKE '%answer_key%'
         OR lower(v::text) LIKE '%selected_answer%'
         OR lower(v::text) LIKE '%distractor_code%'
      THEN
        RAISE EXCEPTION 'P3-02 answer-bearing/private field escaped safe context: %',v;
      END IF;

      IF v_locale='en'
         AND (v->>'diagnostic_feedback'<>v_fixture.expected_feedback_en
              OR v->>'next_action'<>v_fixture.expected_next_en)
      THEN
        RAISE EXCEPTION 'P3-02 safe context no longer matches approved deterministic rule expected=%/% got=%/%',
          v_fixture.expected_feedback_en,v_fixture.expected_next_en,v->>'diagnostic_feedback',v->>'next_action';
      END IF;
    END LOOP;

    v:=public.get_exam_prep_ai_error_context_safe_v1(v_component,v_fixture.session_id,99,'en');
    IF coalesce((v->>'mapped')::boolean,true)
       OR v->>'reason'<>'no_approved_diagnostic_mapping'
    THEN
      RAISE EXCEPTION 'P3-02 unmapped item did not fail closed: %',v;
    END IF;
  END LOOP;
END
$$;
RESET ROLE;

SET LOCAL ROLE service_role;
DO $$
DECLARE
  v_component text;
  v_locale text;
  v jsonb;
BEGIN
  FOREACH v_component IN ARRAY ARRAY['P1','P5']::text[] LOOP
    FOREACH v_locale IN ARRAY ARRAY['en','ru','uz']::text[] LOOP
      v:=public.get_exam_prep_ai_source_cards_service_v1(v_component,v_locale,'error_explanation',null,8);
      IF jsonb_array_length(v)<>1
         OR v#>>'{0,source_card_key}'<>lower(v_component)||':error_explanation:'||v_locale||':v1'
      THEN
        RAISE EXCEPTION 'P3-02 error source-card allowlist failed component=% locale=% cards=%',v_component,v_locale,v;
      END IF;
    END LOOP;
  END LOOP;
END
$$;
RESET ROLE;

DO $$
DECLARE b record; a record;
BEGIN
  SELECT * INTO b FROM p302_error_state_before;
  SELECT
    (SELECT count(*) FROM private.exam_prep_evidence_events) AS evidence_count,
    (SELECT count(*) FROM private.exam_prep_skill_states) AS skill_state_count,
    (SELECT count(*) FROM private.exam_prep_stage_states) AS stage_state_count,
    (SELECT count(*) FROM private.exam_prep_component_placements) AS placement_count,
    (SELECT count(*) FROM private.exam_prep_correction_cases) AS correction_count,
    (SELECT count(*) FROM private.exam_prep_retest_events) AS retest_count,
    (SELECT count(*) FROM private.exam_prep_readiness_signoffs) AS readiness_count
  INTO a;

  IF row_to_json(a)::text<>row_to_json(b)::text THEN
    RAISE EXCEPTION 'P3-02 error context mutated academic state before=% after=%',row_to_json(b),row_to_json(a);
  END IF;
END
$$;

RESET ROLE;
SELECT set_config('request.jwt.claim.sub','',true);
SELECT set_config('request.jwt.claim.role','',true);
ROLLBACK;

DO $$
DECLARE v_count integer;
BEGIN
  SELECT count(*) INTO v_count FROM auth.users WHERE email LIKE 'exam-prep-sv-p302-error-%@invalid.example';
  IF v_count<>0 THEN RAISE EXCEPTION 'P3-02 rollback left synthetic auth users=%',v_count; END IF;
  SELECT count(*) INTO v_count FROM private.exam_prep_synthetic_validation_runs WHERE run_id='SV-P302CI-AI-ERROR';
  IF v_count<>0 THEN RAISE EXCEPTION 'P3-02 rollback left synthetic run=%',v_count; END IF;
  SELECT count(*) INTO v_count FROM private.exam_prep_synthetic_identities WHERE fixture_profile_key='SVF-P302-AI-ERROR';
  IF v_count<>0 THEN RAISE EXCEPTION 'P3-02 rollback left synthetic identity=%',v_count; END IF;
END
$$;

\echo 'P3-02 deterministic established-error context matrix: GREEN'
