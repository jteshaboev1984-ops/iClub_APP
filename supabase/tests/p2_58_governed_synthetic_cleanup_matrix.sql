\set ON_ERROR_STOP on

DO $$
BEGIN
  IF current_setting('p258.isolated_db', true) IS DISTINCT FROM 'true'
     AND current_setting('p238.isolated_db', true) IS DISTINCT FROM 'true' THEN
    RAISE EXCEPTION 'P2-58 REFUSED: p258.isolated_db=true or p238.isolated_db=true is required. Use only an ephemeral test database.';
  END IF;
END
$$;

BEGIN;

DO $$
DECLARE
  v_uid uuid:=gen_random_uuid();
  v_cohort_id bigint;
  v_program bigint;
  v_assessment record;
  v_assessment_item record;
  v_auth uuid;
  v_session uuid;
  v_payload jsonb;
  v_blocked boolean:=false;
BEGIN
  SELECT id INTO v_program
  FROM private.exam_prep_program_versions
  WHERE program_key='math_as_p1_p5'
    AND version_key='p1_p5_canonical_v1_0'
    AND status='active';

  SELECT a.id,a.assessment_version,a.component_code,a.content_version_id,cv.program_version_id
  INTO v_assessment
  FROM private.exam_prep_assessments a
  JOIN private.exam_prep_content_versions cv ON cv.id=a.content_version_id
  WHERE a.assessment_type='diagnostic'
    AND a.status='published'
    AND cv.status='published'
  ORDER BY a.id
  LIMIT 1;

  SELECT ai.item_order,ai.question_id,ai.written_task_id,ai.primary_skill_code,
         ai.reserve_role,ai.is_holdout
  INTO v_assessment_item
  FROM private.exam_prep_assessment_items ai
  WHERE ai.assessment_id=v_assessment.id
  ORDER BY ai.item_order
  LIMIT 1;

  IF v_program IS NULL OR v_assessment.id IS NULL OR v_assessment_item.item_order IS NULL THEN
    RAISE EXCEPTION 'P2-58 canonical diagnostic fixture missing';
  END IF;

  INSERT INTO private.exam_prep_beta_cohorts(
    cohort_key,program_key,cohort_status,planned_size,current_wave,monitoring_hours,notes
  ) VALUES(
    'p258-ci-cohort','math_as_p1_p5','canary',12,1,72,'isolated P2-58 governed cleanup validation'
  ) RETURNING id INTO v_cohort_id;

  INSERT INTO private.exam_prep_beta_expansion_controls(
    cohort_id,development_data_state,required_validation_generation
  ) VALUES(v_cohort_id,'synthetic_present','p2_36_expansion_v1');

  INSERT INTO auth.users(id,aud,role,email,created_at,updated_at,is_sso_user,is_anonymous)
  VALUES(
    v_uid,'authenticated','authenticated',
    'p258-'||replace(v_uid::text,'-','')||'@invalid.example',
    now(),now(),false,false
  );
  INSERT INTO public.users(id,first_name,last_name,language_code,created_at,must_change_password)
  VALUES(v_uid,'P258','Governed Cleanup','en',now(),false);

  INSERT INTO private.exam_prep_beta_members(
    cohort_id,user_id,service_mode,activation_wave,member_status
  ) VALUES(v_cohort_id,v_uid,'core',1,'candidate');

  PERFORM public.record_exam_prep_beta_consent_v1(
    'p258-ci-cohort',v_uid,'p2-58-test-consent',now()
  );

  UPDATE private.exam_prep_beta_members
  SET member_status='active',activated_at=now(),updated_at=now()
  WHERE cohort_id=v_cohort_id AND user_id=v_uid;

  INSERT INTO private.exam_prep_feature_entitlements(
    user_id,entitlement_status,core_access,ai_assist,mentor_care_entitled,cohort_key,valid_from
  ) VALUES(v_uid,'active',true,false,false,'p258-ci-cohort',now());

  INSERT INTO private.exam_prep_exam_profiles(
    user_id,program_version_id,exam_series,target_grade,total_student_hours_available,
    mathematics_hours_budget,active_week_no,paper_comparability_epoch
  ) VALUES(v_uid,v_program,'Oct/Nov 2026','A',12,6,1,1);

  INSERT INTO private.exam_prep_session_authorizations(
    user_id,assessment_id,component_code,purpose,status,valid_until,reason,academic_credit
  ) VALUES(
    v_uid,v_assessment.id,v_assessment.component_code,'diagnostic','issued',
    now()+interval '1 hour','P2-58 cleanup fixture',true
  ) RETURNING id INTO v_auth;

  INSERT INTO private.exam_prep_sessions(
    authorization_id,user_id,program_version_id,content_version_id,assessment_id,assessment_version,
    component_code,session_type,status,client_idempotency_key,total_items,timing_contract,finalized_at
  ) VALUES(
    v_auth,v_uid,v_assessment.program_version_id,v_assessment.content_version_id,v_assessment.id,v_assessment.assessment_version,
    v_assessment.component_code,'diagnostic','finalized','p258-cleanup-session',1,'{}'::jsonb,now()
  ) RETURNING id INTO v_session;

  UPDATE private.exam_prep_session_authorizations
  SET status='consumed',consumed_at=now(),consumed_session_id=v_session
  WHERE id=v_auth;

  INSERT INTO private.exam_prep_session_items(
    session_id,item_order,item_kind,question_id,written_task_id,primary_skill_code,
    reserve_role,is_holdout,content_meta_id,item_version
  ) VALUES(
    v_session,1,
    case when v_assessment_item.question_id is not null then 'question' else 'written' end,
    v_assessment_item.question_id,v_assessment_item.written_task_id,
    v_assessment_item.primary_skill_code,v_assessment_item.reserve_role,v_assessment_item.is_holdout,
    null,'p258-fixture'
  );

  INSERT INTO private.exam_prep_integrity_events(
    session_id,user_id,event_type,client_event_id
  ) VALUES(v_session,v_uid,'visibility_hidden','p258-integrity-event-0001');

  UPDATE private.exam_prep_feature_config
  SET rollout_state='controlled_beta',core_enabled=true,ai_enabled=false,mentor_enabled=false,kill_switch=false,updated_at=now()
  WHERE id=1;

  BEGIN
    PERFORM public.cleanup_exam_prep_beta_synthetic_progress_v1(
      'p258-ci-cohort',4,'p2-58-kill-switch-proof','I_CONFIRM_SYNTHETIC_EXAM_PREP_CLEANUP_V1'
    );
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM<>'exam_prep_cleanup_requires_controlled_beta_kill_switch' THEN RAISE; END IF;
    v_blocked:=true;
  END;
  IF NOT v_blocked THEN RAISE EXCEPTION 'P2-58 cleanup did not require kill switch'; END IF;

  UPDATE private.exam_prep_feature_config SET kill_switch=true,updated_at=now() WHERE id=1;

  v_blocked:=false;
  BEGIN
    DELETE FROM private.exam_prep_session_items WHERE session_id=v_session;
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM<>'immutable_exam_prep_fact' THEN RAISE; END IF;
    v_blocked:=true;
  END;
  IF NOT v_blocked THEN RAISE EXCEPTION 'P2-58 immutable fact delete was possible outside governed cleanup'; END IF;

  v_blocked:=false;
  BEGIN
    PERFORM public.cleanup_exam_prep_beta_synthetic_progress_v1(
      'p258-ci-cohort',999,'p2-58-snapshot-proof','I_CONFIRM_SYNTHETIC_EXAM_PREP_CLEANUP_V1'
    );
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM NOT LIKE 'exam_prep_cleanup_snapshot_mismatch expected=% actual=%' THEN RAISE; END IF;
    v_blocked:=true;
  END;
  IF NOT v_blocked THEN RAISE EXCEPTION 'P2-58 stale expected row count did not block cleanup'; END IF;

  v_payload:=public.cleanup_exam_prep_beta_synthetic_progress_v1(
    'p258-ci-cohort',4,'p2-58-clean-proof','I_CONFIRM_SYNTHETIC_EXAM_PREP_CLEANUP_V1'
  );

  IF coalesce((v_payload->>'before_blocking_rows')::int,-1)<>4
     OR coalesce((v_payload->>'after_blocking_rows')::int,-1)<>0
     OR v_payload->>'development_data_state'<>'clean'
     OR coalesce((v_payload->>'real_monitoring_armed')::boolean,true) THEN
    RAISE EXCEPTION 'P2-58 cleanup result contract wrong: %',v_payload;
  END IF;

  IF EXISTS(select 1 from private.exam_prep_sessions where user_id=v_uid)
     OR EXISTS(select 1 from private.exam_prep_session_authorizations where user_id=v_uid)
     OR EXISTS(select 1 from private.exam_prep_exam_profiles where user_id=v_uid)
     OR EXISTS(select 1 from private.exam_prep_integrity_events where user_id=v_uid)
     OR EXISTS(select 1 from private.exam_prep_session_items where session_id=v_session) THEN
    RAISE EXCEPTION 'P2-58 learner-scoped synthetic rows remain after cleanup';
  END IF;

  IF NOT EXISTS(select 1 from private.exam_prep_beta_members where cohort_id=v_cohort_id and user_id=v_uid and member_status='active')
     OR NOT EXISTS(select 1 from private.exam_prep_beta_consents where cohort_id=v_cohort_id and user_id=v_uid)
     OR NOT EXISTS(select 1 from private.exam_prep_feature_entitlements where user_id=v_uid)
     OR NOT EXISTS(select 1 from public.users where id=v_uid) THEN
    RAISE EXCEPTION 'P2-58 cleanup removed preserved control or public-user state';
  END IF;

  IF (select development_data_state from private.exam_prep_beta_expansion_controls where cohort_id=v_cohort_id)<>'clean' THEN
    RAISE EXCEPTION 'P2-58 expansion control not moved to clean state';
  END IF;

  IF has_function_privilege('anon','public.cleanup_exam_prep_beta_synthetic_progress_v1(text,integer,text,text)','EXECUTE')
     OR has_function_privilege('authenticated','public.cleanup_exam_prep_beta_synthetic_progress_v1(text,integer,text,text)','EXECUTE') THEN
    RAISE EXCEPTION 'P2-58 cleanup function became browser-executable';
  END IF;
END
$$;

ROLLBACK;

DO $$
DECLARE v_count int;
BEGIN
  SELECT count(*) INTO v_count FROM auth.users WHERE email LIKE 'p258-%@invalid.example';
  IF v_count<>0 THEN RAISE EXCEPTION 'P2-58 rollback left synthetic auth users=%',v_count; END IF;
  SELECT count(*) INTO v_count FROM private.exam_prep_integrity_events WHERE client_event_id='p258-integrity-event-0001';
  IF v_count<>0 THEN RAISE EXCEPTION 'P2-58 rollback left integrity residue=%',v_count; END IF;
END
$$;

\echo 'P2-58 governed synthetic cleanup matrix: GREEN'
