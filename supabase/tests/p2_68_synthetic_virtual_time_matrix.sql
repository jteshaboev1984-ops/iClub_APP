\set ON_ERROR_STOP on

DO $$
BEGIN
  IF current_setting('p268.isolated_db', true) IS DISTINCT FROM 'true' THEN
    RAISE EXCEPTION 'P2-68 REFUSED: isolated test database required';
  END IF;
END
$$;

BEGIN;

DO $$
DECLARE
  v_run text:='SV-P268CI-RUN-0001';
  v_uid uuid;
  v_real_uid uuid:=gen_random_uuid();
  v_program bigint;
  v_clock jsonb;
  v_t0 timestamptz;
  v_now timestamptz;
  v_real_now timestamptz;
  v_blocked boolean:=false;
  v_week smallint;
  v_stage_before smallint;
  v_stage_after smallint;
  v_skill text;
  v_delay smallint;
  v_learning_ass bigint;
  v_learning_cv bigint;
  v_learning_ver text;
  v_question bigint;
  v_role text;
  v_meta bigint;
  v_md5 text;
  v_auth uuid;
  v_session uuid:=gen_random_uuid();
  v_response uuid;
  v_evidence uuid;
  v_case uuid;
  v_rt uuid;
  v_retest_payload jsonb;
  v_retest_ass bigint;
  v_retest_cv bigint;
  v_retest_ver text;
  v_retest_question bigint;
  v_retest_role text;
  v_retest_meta bigint;
  v_retest_md5 text;
  v_retest_session uuid:=gen_random_uuid();
  v_retest_response uuid;
  v_retest_evidence uuid;
  v_state private.exam_prep_skill_states%rowtype;
  v_legacy_before jsonb;
  v_beta_before jsonb;
  v_users_before bigint;
  v_cleanup jsonb;
  v_complete jsonb;
BEGIN
  SELECT count(*) INTO v_users_before FROM public.users;
  SELECT jsonb_build_object(
    'practice_attempts',(SELECT count(*) FROM public.practice_attempts),
    'practice_answers',(SELECT count(*) FROM public.practice_answers),
    'tour_attempts',(SELECT count(*) FROM public.tour_attempts),
    'tour_answers',(SELECT count(*) FROM public.tour_answers),
    'certificates',(SELECT count(*) FROM public.certificates)
  ) INTO v_legacy_before;
  SELECT jsonb_build_object(
    'members',(SELECT count(*) FROM private.exam_prep_beta_members),
    'consents',(SELECT count(*) FROM private.exam_prep_beta_consents),
    'weekly_reviews',(SELECT count(*) FROM private.exam_prep_beta_weekly_reviews)
  ) INTO v_beta_before;

  SELECT id INTO v_program
  FROM private.exam_prep_program_versions
  WHERE program_key='math_as_p1_p5'
    AND version_key='p1_p5_canonical_v1_0'
    AND status='active';
  IF v_program IS NULL THEN RAISE EXCEPTION 'P2-68 canonical program missing'; END IF;

  PERFORM private.register_exam_prep_canonical_synthetic_run_v2(
    v_run,'p2_67_canonical_v2_0',repeat('8',40),'p2-68',26801,'core','p2-68-clock-run-proof'
  );
  v_uid:=private.create_exam_prep_synthetic_identity_v1(
    v_run,'learner','SVF-P268-LEARNER-01','p2-68-identity-proof',
    'Dedicated P2-68 synthetic academic-clock learner.','en'
  );

  v_blocked:=false;
  BEGIN
    PERFORM private.exam_prep_effective_academic_now_v1(v_uid);
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM='exam_prep_synthetic_virtual_clock_run_not_active' THEN
      v_blocked:=true;
    ELSE
      RAISE;
    END IF;
  END;
  IF NOT v_blocked THEN RAISE EXCEPTION 'P2-68 synthetic clock failed open before run start'; END IF;

  PERFORM private.transition_exam_prep_synthetic_validation_run_v1(
    v_run,'registered','running',null,null,jsonb_build_object('p2_68','clock-start')
  );

  v_blocked:=false;
  BEGIN
    PERFORM private.exam_prep_effective_academic_now_v1(v_uid);
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM='exam_prep_synthetic_virtual_clock_unavailable' THEN
      v_blocked:=true;
    ELSE
      RAISE;
    END IF;
  END;
  IF NOT v_blocked THEN RAISE EXCEPTION 'P2-68 running synthetic identity used real clock before initialization'; END IF;

  v_clock:=private.initialize_exam_prep_synthetic_clock_v1(v_run,'p2-68-clock-init-proof');
  v_t0:=(v_clock->>'virtual_now')::timestamptz;
  IF v_clock->>'clock_status'<>'active'
     OR (v_clock->>'step_no')::int<>0
     OR coalesce((v_clock->>'idempotent')::boolean,true) THEN
    RAISE EXCEPTION 'P2-68 clock initialization invalid: %',v_clock;
  END IF;

  v_clock:=private.initialize_exam_prep_synthetic_clock_v1(v_run,'p2-68-clock-init-repeat');
  IF coalesce((v_clock->>'idempotent')::boolean,false) IS NOT TRUE
     OR (v_clock->>'virtual_now')::timestamptz IS DISTINCT FROM v_t0 THEN
    RAISE EXCEPTION 'P2-68 clock re-initialization reset epoch: %',v_clock;
  END IF;

  v_blocked:=false;
  BEGIN
    UPDATE private.exam_prep_synthetic_run_clocks
    SET virtual_now=virtual_now+interval '1 hour'
    WHERE run_id=v_run;
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM='exam_prep_synthetic_clock_direct_write_forbidden' THEN v_blocked:=true; ELSE RAISE; END IF;
  END;
  IF NOT v_blocked THEN RAISE EXCEPTION 'P2-68 direct clock mutation was allowed'; END IF;

  v_blocked:=false;
  BEGIN
    PERFORM private.advance_exam_prep_synthetic_clock_v1(
      v_run,v_t0,1209601,'must reject a jump larger than fourteen days'
    );
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM='exam_prep_synthetic_clock_advance_out_of_range' THEN v_blocked:=true; ELSE RAISE; END IF;
  END;
  IF NOT v_blocked THEN RAISE EXCEPTION 'P2-68 oversized virtual jump was allowed'; END IF;

  INSERT INTO auth.users(id,aud,role,email,created_at,updated_at,is_sso_user,is_anonymous)
  VALUES(
    v_real_uid,'authenticated','authenticated',
    'p268-real-'||replace(v_real_uid::text,'-','')||'@invalid.example',
    now(),now(),false,false
  );
  INSERT INTO public.users(id,first_name,last_name,language_code,created_at,must_change_password)
  VALUES(v_real_uid,'P268','Real Clock Control','en',now(),false);
  INSERT INTO private.exam_prep_exam_profiles(user_id,program_version_id,active_week_no)
  VALUES(v_real_uid,v_program,1);

  v_real_now:=private.exam_prep_effective_academic_now_v1(v_real_uid);
  IF abs(extract(epoch from (v_real_now-now())))>5 THEN
    RAISE EXCEPTION 'P2-68 real user did not remain on server clock: % vs %',v_real_now,now();
  END IF;

  INSERT INTO private.exam_prep_feature_entitlements(
    user_id,entitlement_status,core_access,ai_assist,mentor_care_entitled,cohort_key,valid_from
  ) VALUES(v_uid,'active',true,false,false,null,now());

  INSERT INTO private.exam_prep_exam_profiles(user_id,program_version_id,active_week_no)
  VALUES(v_uid,v_program,1);

  UPDATE private.exam_prep_feature_config
  SET rollout_state='internal_alpha',core_enabled=true,ai_enabled=false,mentor_enabled=false,kill_switch=false
  WHERE id=1;

  PERFORM private.rebuild_exam_prep_state_v1(v_uid,'P1');
  SELECT operational_stage INTO v_stage_before
  FROM private.exam_prep_stage_states
  WHERE user_id=v_uid AND program_version_id=v_program
    AND component_code='P1' AND engine_version='objective_state_v1';

  v_week:=private.exam_prep_effective_active_week_v1(v_uid);
  IF v_week<>1 THEN RAISE EXCEPTION 'P2-68 initial active week expected 1 got %',v_week; END IF;

  v_clock:=private.advance_exam_prep_synthetic_clock_v1(
    v_run,v_t0,1209600,'advance first bounded two-week academic interval'
  );
  v_now:=(v_clock->>'virtual_now')::timestamptz;
  v_clock:=private.advance_exam_prep_synthetic_clock_v1(
    v_run,v_now,3600,'cross the exact two-week boundary after profile creation'
  );
  v_now:=(v_clock->>'virtual_now')::timestamptz;

  v_week:=private.exam_prep_effective_active_week_v1(v_uid);
  IF v_week<>3 THEN RAISE EXCEPTION 'P2-68 accelerated active week expected 3 got %',v_week; END IF;

  PERFORM private.rebuild_exam_prep_state_v1(v_uid,'P1');
  SELECT operational_stage INTO v_stage_after
  FROM private.exam_prep_stage_states
  WHERE user_id=v_uid AND program_version_id=v_program
    AND component_code='P1' AND engine_version='objective_state_v1';

  IF v_stage_after IS DISTINCT FROM v_stage_before THEN
    RAISE EXCEPTION 'P2-68 clock-only progression changed stage % -> %',v_stage_before,v_stage_after;
  END IF;
  IF EXISTS(SELECT 1 FROM private.exam_prep_evidence_events WHERE user_id=v_uid) THEN
    RAISE EXCEPTION 'P2-68 clock-only progression generated evidence';
  END IF;

  SELECT c.skill_code,c.min_retest_delay_days
  INTO v_skill,v_delay
  FROM private.exam_prep_skill_contracts c
  WHERE c.program_version_id=v_program
    AND c.component_code='P1'
    AND c.min_retest_delay_days>0
    AND EXISTS(
      SELECT 1
      FROM private.exam_prep_assessments a
      JOIN private.exam_prep_assessment_items ai ON ai.assessment_id=a.id
      WHERE a.component_code='P1' AND a.assessment_type='learning' AND a.status='published'
        AND ai.primary_skill_code=c.skill_code AND ai.question_id IS NOT NULL
    )
    AND private.exam_prep_fresh_retest_content_ready_v1(v_uid,'P1',c.skill_code)
  ORDER BY c.skill_code
  LIMIT 1;
  IF v_skill IS NULL THEN RAISE EXCEPTION 'P2-68 delayed-retest fixture skill unavailable'; END IF;

  SELECT a.id,a.content_version_id,a.assessment_version,
         ai.question_id,ai.reserve_role,m.id,m.question_snapshot_md5
  INTO v_learning_ass,v_learning_cv,v_learning_ver,
       v_question,v_role,v_meta,v_md5
  FROM private.exam_prep_assessments a
  JOIN private.exam_prep_assessment_items ai ON ai.assessment_id=a.id
  JOIN private.exam_prep_question_content_meta m
    ON m.content_version_id=a.content_version_id AND m.question_id=ai.question_id
  WHERE a.component_code='P1' AND a.assessment_type='learning' AND a.status='published'
    AND ai.primary_skill_code=v_skill AND ai.question_id IS NOT NULL
  ORDER BY a.id,ai.item_order
  LIMIT 1;
  IF v_learning_ass IS NULL THEN RAISE EXCEPTION 'P2-68 baseline learning fixture missing'; END IF;

  INSERT INTO private.exam_prep_session_authorizations(
    user_id,assessment_id,component_code,purpose,status,valid_until,reason,academic_credit
  ) VALUES(
    v_uid,v_learning_ass,'P1','learning','issued',clock_timestamp()+interval '1 hour',
    'P2-68 causal baseline evidence',true
  ) RETURNING id INTO v_auth;

  INSERT INTO private.exam_prep_sessions(
    id,authorization_id,user_id,program_version_id,content_version_id,assessment_id,
    assessment_version,component_code,session_type,status,client_idempotency_key,total_items
  ) VALUES(
    v_session,v_auth,v_uid,v_program,v_learning_cv,v_learning_ass,
    v_learning_ver,'P1','learning','active','p268-baseline-session',1
  );

  INSERT INTO private.exam_prep_session_items(
    session_id,item_order,item_kind,question_id,primary_skill_code,reserve_role,
    is_holdout,content_meta_id,question_snapshot_md5,item_version
  ) VALUES(
    v_session,1,'question',v_question,v_skill,v_role,false,v_meta,v_md5,v_learning_ver||'|p268-baseline'
  );

  INSERT INTO private.exam_prep_responses(
    session_id,item_order,user_id,client_idempotency_key,response_kind,user_answer,
    is_correct,evaluator_version,elapsed_ms
  ) VALUES(
    v_session,1,v_uid,'p268-baseline-response','machine','synthetic-correct',
    true,'p268_fixture_v1',1000
  ) RETURNING id INTO v_response;

  INSERT INTO private.exam_prep_evidence_events(
    user_id,component_code,skill_code,session_id,response_id,evidence_type,
    verification_status,is_correct,evidence_payload,source_version
  ) VALUES(
    v_uid,'P1',v_skill,v_session,v_response,'learning',
    'app_verified',true,jsonb_build_object('p2_68','baseline'),v_learning_ver||'|p268'
  ) RETURNING id INTO v_evidence;

  UPDATE private.exam_prep_sessions
  SET status='finalized',finalized_at=clock_timestamp(),last_activity_at=clock_timestamp(),
      finalize_idempotency_key='p268-baseline-final'
  WHERE id=v_session;

  IF (SELECT created_at FROM private.exam_prep_evidence_events WHERE id=v_evidence)
       IS DISTINCT FROM v_now THEN
    RAISE EXCEPTION 'P2-68 baseline evidence was not stamped with virtual time';
  END IF;

  PERFORM private.rebuild_exam_prep_state_v1(v_uid,'P1');
  SELECT * INTO v_state
  FROM private.exam_prep_skill_states
  WHERE user_id=v_uid AND program_version_id=v_program
    AND component_code='P1' AND skill_code=v_skill AND engine_version='objective_state_v1';
  IF v_state.has_delayed_successful_retest THEN
    RAISE EXCEPTION 'P2-68 delayed retest became true before retest evidence existed';
  END IF;

  INSERT INTO private.exam_prep_correction_cases(
    user_id,component_code,skill_code,status,opened_from_evidence_id,engine_version,reason
  ) VALUES(
    v_uid,'P1',v_skill,'retest_due',v_evidence,'objective_state_v1',
    jsonb_build_object('p2_68','delayed-retest-timing-proof')
  ) RETURNING id INTO v_case;

  INSERT INTO private.exam_prep_retest_events(
    correction_case_id,user_id,component_code,skill_code,status,due_not_before
  ) VALUES(
    v_case,v_uid,'P1',v_skill,'scheduled',
    v_now + (v_delay::double precision * interval '1 day')
  ) RETURNING id INTO v_rt;

  IF (SELECT opened_at FROM private.exam_prep_correction_cases WHERE id=v_case)
       IS DISTINCT FROM v_now
     OR (SELECT created_at FROM private.exam_prep_retest_events WHERE id=v_rt)
       IS DISTINCT FROM v_now THEN
    RAISE EXCEPTION 'P2-68 correction/retest anchors were not virtual-time stamped';
  END IF;

  PERFORM set_config('request.jwt.claim.sub',v_uid::text,true);
  PERFORM set_config('request.jwt.claim.role','authenticated',true);

  v_blocked:=false;
  BEGIN
    PERFORM public.authorize_exam_prep_retest_safe_v1(v_case);
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM='exam_prep_retest_too_early' THEN v_blocked:=true; ELSE RAISE; END IF;
  END;
  IF NOT v_blocked THEN RAISE EXCEPTION 'P2-68 delayed retest authorized before virtual due time'; END IF;

  v_blocked:=false;
  BEGIN
    PERFORM private.advance_exam_prep_synthetic_clock_v1(
      v_run,v_t0,3600,'stale expected virtual time must fail closed'
    );
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM='exam_prep_synthetic_clock_stale_expected_time' THEN v_blocked:=true; ELSE RAISE; END IF;
  END;
  IF NOT v_blocked THEN RAISE EXCEPTION 'P2-68 stale expected clock snapshot was accepted'; END IF;

  v_clock:=private.advance_exam_prep_synthetic_clock_v1(
    v_run,v_now,(v_delay::bigint*86400),'reach governed delayed-retest eligibility point'
  );
  v_now:=(v_clock->>'virtual_now')::timestamptz;

  v_retest_payload:=public.authorize_exam_prep_retest_safe_v1(v_case);
  v_retest_ass:=(v_retest_payload->>'assessment_id')::bigint;
  v_auth:=(v_retest_payload->>'authorization_id')::uuid;
  IF v_retest_ass IS NULL OR v_auth IS NULL THEN
    RAISE EXCEPTION 'P2-68 delayed retest did not authorize at virtual due point: %',v_retest_payload;
  END IF;

  SELECT a.content_version_id,a.assessment_version,
         ai.question_id,ai.reserve_role,m.id,m.question_snapshot_md5
  INTO v_retest_cv,v_retest_ver,
       v_retest_question,v_retest_role,v_retest_meta,v_retest_md5
  FROM private.exam_prep_assessments a
  JOIN private.exam_prep_assessment_items ai ON ai.assessment_id=a.id
  JOIN private.exam_prep_question_content_meta m
    ON m.content_version_id=a.content_version_id AND m.question_id=ai.question_id
  WHERE a.id=v_retest_ass
    AND ai.primary_skill_code=v_skill
    AND ai.question_id IS NOT NULL
  ORDER BY ai.item_order
  LIMIT 1;
  IF v_retest_question IS NULL THEN RAISE EXCEPTION 'P2-68 authorized retest has no machine item'; END IF;

  INSERT INTO private.exam_prep_sessions(
    id,authorization_id,user_id,program_version_id,content_version_id,assessment_id,
    assessment_version,component_code,session_type,status,client_idempotency_key,total_items
  ) VALUES(
    v_retest_session,v_auth,v_uid,v_program,v_retest_cv,v_retest_ass,
    v_retest_ver,'P1','retest','active','p268-retest-session',1
  );

  INSERT INTO private.exam_prep_session_items(
    session_id,item_order,item_kind,question_id,primary_skill_code,reserve_role,
    is_holdout,content_meta_id,question_snapshot_md5,item_version
  ) VALUES(
    v_retest_session,1,'question',v_retest_question,v_skill,v_retest_role,false,
    v_retest_meta,v_retest_md5,v_retest_ver||'|p268-retest'
  );

  INSERT INTO private.exam_prep_responses(
    session_id,item_order,user_id,client_idempotency_key,response_kind,user_answer,
    is_correct,evaluator_version,elapsed_ms
  ) VALUES(
    v_retest_session,1,v_uid,'p268-retest-response','machine','synthetic-correct',
    true,'p268_fixture_v1',1000
  ) RETURNING id INTO v_retest_response;

  INSERT INTO private.exam_prep_evidence_events(
    user_id,component_code,skill_code,session_id,response_id,evidence_type,
    verification_status,is_correct,evidence_payload,source_version
  ) VALUES(
    v_uid,'P1',v_skill,v_retest_session,v_retest_response,'retest',
    'app_verified',true,jsonb_build_object('p2_68','delayed-retest'),v_retest_ver||'|p268'
  ) RETURNING id INTO v_retest_evidence;

  UPDATE private.exam_prep_sessions
  SET status='finalized',finalized_at=clock_timestamp(),last_activity_at=clock_timestamp(),
      finalize_idempotency_key='p268-retest-final'
  WHERE id=v_retest_session;

  IF (SELECT created_at FROM private.exam_prep_evidence_events WHERE id=v_retest_evidence)
       IS DISTINCT FROM v_now
     OR (SELECT completed_at FROM private.exam_prep_retest_events WHERE id=v_rt)
       IS DISTINCT FROM v_now
     OR (SELECT resolved_at FROM private.exam_prep_correction_cases WHERE id=v_case)
       IS DISTINCT FROM v_now THEN
    RAISE EXCEPTION 'P2-68 completed delayed cycle did not preserve virtual chronology';
  END IF;

  IF (SELECT status FROM private.exam_prep_correction_cases WHERE id=v_case)<>'resolved'
     OR (SELECT status FROM private.exam_prep_retest_events WHERE id=v_rt)<>'completed' THEN
    RAISE EXCEPTION 'P2-68 governed delayed corrective cycle did not close';
  END IF;

  PERFORM private.rebuild_exam_prep_state_v1(v_uid,'P1');
  SELECT * INTO v_state
  FROM private.exam_prep_skill_states
  WHERE user_id=v_uid AND program_version_id=v_program
    AND component_code='P1' AND skill_code=v_skill AND engine_version='objective_state_v1';
  IF v_state.has_delayed_successful_retest IS NOT TRUE THEN
    RAISE EXCEPTION 'P2-68 delayed successful retest was not recognized after causal evidence';
  END IF;

  IF EXISTS(
    SELECT 1 FROM private.exam_prep_evidence_events
    WHERE user_id=v_uid AND component_code='P5'
  ) THEN
    RAISE EXCEPTION 'P2-68 P1 synthetic chronology leaked evidence into P5';
  END IF;

  v_real_now:=private.exam_prep_effective_academic_now_v1(v_real_uid);
  IF abs(extract(epoch from (v_real_now-now())))>5 THEN
    RAISE EXCEPTION 'P2-68 synthetic clock changed real-user time after advance';
  END IF;

  v_complete:=private.complete_exam_prep_synthetic_run_v1(
    v_run,1,jsonb_build_object('p2_68','virtual-time-green')
  );
  IF v_complete->>'run_status'<>'completed' THEN
    RAISE EXCEPTION 'P2-68 run completion failed: %',v_complete;
  END IF;
  IF (SELECT clock_status FROM private.exam_prep_synthetic_run_clocks WHERE run_id=v_run)<>'frozen'
     OR NOT EXISTS(
       SELECT 1 FROM private.exam_prep_synthetic_timeline_events
       WHERE run_id=v_run AND event_type='clock_frozen'
     ) THEN
    RAISE EXCEPTION 'P2-68 terminal run did not freeze virtual clock';
  END IF;

  v_blocked:=false;
  BEGIN
    PERFORM private.exam_prep_effective_academic_now_v1(v_uid);
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM='exam_prep_synthetic_virtual_clock_run_not_active' THEN v_blocked:=true; ELSE RAISE; END IF;
  END;
  IF NOT v_blocked THEN RAISE EXCEPTION 'P2-68 terminal synthetic run still exposed academic clock'; END IF;

  v_cleanup:=private.cleanup_exam_prep_synthetic_run_v1(
    v_run,1,'p2-68-cleanup-proof','I_CONFIRM_SYNTHETIC_RUN_CLEANUP_V1'
  );
  IF v_cleanup->>'cleanup_status'<>'clean'
     OR coalesce((v_cleanup->>'deleted_identity_count')::int,-1)<>1 THEN
    RAISE EXCEPTION 'P2-68 cleanup failed: %',v_cleanup;
  END IF;
  IF EXISTS(SELECT 1 FROM private.exam_prep_synthetic_identities WHERE run_id=v_run)
     OR EXISTS(SELECT 1 FROM public.users WHERE id=v_uid)
     OR EXISTS(SELECT 1 FROM auth.users WHERE id=v_uid) THEN
    RAISE EXCEPTION 'P2-68 cleanup left synthetic learner residue';
  END IF;
  IF NOT EXISTS(SELECT 1 FROM private.exam_prep_synthetic_run_clocks WHERE run_id=v_run AND clock_status='frozen')
     OR (SELECT count(*) FROM private.exam_prep_synthetic_timeline_events WHERE run_id=v_run)<4 THEN
    RAISE EXCEPTION 'P2-68 cleanup removed run-level virtual-time audit history';
  END IF;

  DELETE FROM public.users WHERE id=v_real_uid;
  DELETE FROM auth.users WHERE id=v_real_uid;

  IF (SELECT count(*) FROM public.users)<>v_users_before THEN
    RAISE EXCEPTION 'P2-68 real public-user baseline changed';
  END IF;
  IF v_legacy_before IS DISTINCT FROM jsonb_build_object(
    'practice_attempts',(SELECT count(*) FROM public.practice_attempts),
    'practice_answers',(SELECT count(*) FROM public.practice_answers),
    'tour_attempts',(SELECT count(*) FROM public.tour_attempts),
    'tour_answers',(SELECT count(*) FROM public.tour_answers),
    'certificates',(SELECT count(*) FROM public.certificates)
  ) THEN
    RAISE EXCEPTION 'P2-68 virtual-time harness mutated legacy learner state';
  END IF;
  IF v_beta_before IS DISTINCT FROM jsonb_build_object(
    'members',(SELECT count(*) FROM private.exam_prep_beta_members),
    'consents',(SELECT count(*) FROM private.exam_prep_beta_consents),
    'weekly_reviews',(SELECT count(*) FROM private.exam_prep_beta_weekly_reviews)
  ) THEN
    RAISE EXCEPTION 'P2-68 virtual-time harness mutated real beta controls';
  END IF;

  IF has_table_privilege('anon','private.exam_prep_synthetic_run_clocks','SELECT')
     OR has_table_privilege('authenticated','private.exam_prep_synthetic_run_clocks','SELECT')
     OR has_table_privilege('authenticated','private.exam_prep_synthetic_timeline_events','SELECT')
     OR has_function_privilege('authenticated','private.initialize_exam_prep_synthetic_clock_v1(text,text)','EXECUTE')
     OR has_function_privilege('authenticated','private.advance_exam_prep_synthetic_clock_v1(text,timestamp with time zone,bigint,text)','EXECUTE')
     OR has_function_privilege('authenticated','private.exam_prep_effective_academic_now_v1(uuid)','EXECUTE') THEN
    RAISE EXCEPTION 'P2-68 browser virtual-time boundary failed';
  END IF;
END
$$;

ROLLBACK;

DO $$
DECLARE v_count int;
BEGIN
  SELECT count(*) INTO v_count
  FROM private.exam_prep_synthetic_validation_runs
  WHERE run_id='SV-P268CI-RUN-0001';
  IF v_count<>0 THEN RAISE EXCEPTION 'P2-68 rollback left synthetic run rows=%',v_count; END IF;

  SELECT count(*) INTO v_count
  FROM private.exam_prep_synthetic_run_clocks
  WHERE run_id='SV-P268CI-RUN-0001';
  IF v_count<>0 THEN RAISE EXCEPTION 'P2-68 rollback left synthetic clock rows=%',v_count; END IF;

  SELECT count(*) INTO v_count
  FROM private.exam_prep_synthetic_timeline_events
  WHERE run_id='SV-P268CI-RUN-0001';
  IF v_count<>0 THEN RAISE EXCEPTION 'P2-68 rollback left synthetic timeline rows=%',v_count; END IF;
END
$$;

\echo 'P2-68 incremental evidence and virtual-time harness: GREEN'
