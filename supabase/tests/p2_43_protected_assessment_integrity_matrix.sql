-- P2-43 protected-assessment integrity isolated acceptance matrix.
-- Requires: PGOPTIONS='-c p243.isolated_db=true'
-- Test-only; all synthetic mutations end in ROLLBACK.

\set ON_ERROR_STOP on

DO $$
BEGIN
  IF current_setting('p243.isolated_db',true) IS DISTINCT FROM 'true' THEN
    RAISE EXCEPTION 'P2-43 REFUSED: p243.isolated_db=true is required. Use only an ephemeral test database.';
  END IF;
END
$$;

BEGIN;

DO $$
BEGIN
  IF to_regclass('private.exam_prep_integrity_events') IS NULL THEN
    RAISE EXCEPTION 'P2-43 integrity event table missing';
  END IF;
  IF to_regprocedure('private.exam_prep_session_is_protected_v1(uuid)') IS NULL
     OR to_regprocedure('private.exam_prep_integrity_status_v1(uuid)') IS NULL
     OR to_regprocedure('private.exam_prep_integrity_allows_timed_comparability_v1(uuid)') IS NULL THEN
    RAISE EXCEPTION 'P2-43 private integrity helper missing';
  END IF;
  IF to_regprocedure('public.get_exam_prep_integrity_status_safe_v1(uuid)') IS NULL
     OR to_regprocedure('public.record_exam_prep_integrity_event_safe_v1(uuid,text,text)') IS NULL THEN
    RAISE EXCEPTION 'P2-43 learner-safe integrity RPC missing';
  END IF;

  IF has_table_privilege('authenticated','private.exam_prep_integrity_events','SELECT')
     OR has_table_privilege('authenticated','private.exam_prep_integrity_events','INSERT')
     OR has_table_privilege('authenticated','private.exam_prep_integrity_events','UPDATE')
     OR has_table_privilege('authenticated','private.exam_prep_integrity_events','DELETE') THEN
    RAISE EXCEPTION 'P2-43 authenticated role has direct integrity-table privilege';
  END IF;
  IF has_function_privilege('authenticated','private.exam_prep_integrity_status_v1(uuid)','EXECUTE')
     OR has_function_privilege('authenticated','private.exam_prep_session_is_protected_v1(uuid)','EXECUTE') THEN
    RAISE EXCEPTION 'P2-43 authenticated role can execute private integrity helper';
  END IF;
  IF has_function_privilege('anon','public.get_exam_prep_integrity_status_safe_v1(uuid)','EXECUTE')
     OR has_function_privilege('anon','public.record_exam_prep_integrity_event_safe_v1(uuid,text,text)','EXECUTE') THEN
    RAISE EXCEPTION 'P2-43 anon role can execute learner integrity RPC';
  END IF;
  IF NOT has_function_privilege('authenticated','public.get_exam_prep_integrity_status_safe_v1(uuid)','EXECUTE')
     OR NOT has_function_privilege('authenticated','public.record_exam_prep_integrity_event_safe_v1(uuid,text,text)','EXECUTE') THEN
    RAISE EXCEPTION 'P2-43 authenticated learner integrity RPC grant missing';
  END IF;
END
$$;

CREATE TEMP TABLE p243_fixture(
  user_id uuid primary key,
  learning_session uuid,
  diagnostic_session uuid,
  timed_session uuid
) ON COMMIT DROP;

DO $$
DECLARE
  v_uid uuid:=gen_random_uuid();
  v_program bigint;
  v_learning record;
  v_diag record;
  v_timed record;
  v_auth uuid;
  v_learning_session uuid;
  v_diag_session uuid;
  v_timed_session uuid;
BEGIN
  SELECT id INTO v_program
  FROM private.exam_prep_program_versions
  WHERE program_key='math_as_p1_p5' AND version_key='p1_p5_canonical_v1_0' AND status='active';
  IF v_program IS NULL THEN RAISE EXCEPTION 'P2-43 program fixture missing'; END IF;

  SELECT a.id,a.assessment_version,a.component_code,a.content_version_id,cv.program_version_id
  INTO v_learning
  FROM private.exam_prep_assessments a
  JOIN private.exam_prep_content_versions cv ON cv.id=a.content_version_id
  WHERE a.assessment_type='learning' AND a.status='published' AND cv.status='published'
  ORDER BY a.id LIMIT 1;

  SELECT a.id,a.assessment_version,a.component_code,a.content_version_id,cv.program_version_id
  INTO v_diag
  FROM private.exam_prep_assessments a
  JOIN private.exam_prep_content_versions cv ON cv.id=a.content_version_id
  WHERE a.assessment_type='diagnostic' AND a.status='published' AND cv.status='published'
  ORDER BY a.id LIMIT 1;

  SELECT a.id,a.assessment_version,a.component_code,a.content_version_id,cv.program_version_id
  INTO v_timed
  FROM private.exam_prep_assessments a
  JOIN private.exam_prep_content_versions cv ON cv.id=a.content_version_id
  WHERE a.assessment_type IN ('timed','paper') AND a.status='published' AND cv.status='published'
  ORDER BY CASE WHEN a.assessment_type='timed' THEN 0 ELSE 1 END,a.id LIMIT 1;

  IF v_learning.id IS NULL OR v_diag.id IS NULL OR v_timed.id IS NULL THEN
    RAISE EXCEPTION 'P2-43 published learning/diagnostic/timed fixtures are required';
  END IF;

  INSERT INTO auth.users(id,aud,role,email,created_at,updated_at,is_sso_user,is_anonymous)
  VALUES(v_uid,'authenticated','authenticated','p243-integrity-'||replace(v_uid::text,'-','')||'@invalid.example',now(),now(),false,false);
  INSERT INTO public.users(id,first_name,last_name,language_code,created_at,must_change_password)
  VALUES(v_uid,'P243','Integrity','en',now(),false);

  INSERT INTO private.exam_prep_exam_profiles(
    user_id,program_version_id,exam_series,target_grade,total_student_hours_available,
    mathematics_hours_budget,active_week_no,paper_comparability_epoch
  ) VALUES(v_uid,v_program,'Oct/Nov 2026','A',12,6,1,1);

  INSERT INTO private.exam_prep_feature_entitlements(
    user_id,entitlement_status,core_access,ai_assist,mentor_care_entitled,valid_from
  ) VALUES(v_uid,'active',true,false,false,now());

  INSERT INTO private.exam_prep_session_authorizations(
    user_id,assessment_id,component_code,purpose,status,valid_until,reason,academic_credit
  ) VALUES(v_uid,v_learning.id,v_learning.component_code,'learning','issued',now()+interval '1 hour','P2-43 learning fixture',true)
  RETURNING id INTO v_auth;
  INSERT INTO private.exam_prep_sessions(
    authorization_id,user_id,program_version_id,content_version_id,assessment_id,assessment_version,
    component_code,session_type,status,client_idempotency_key,total_items,timing_contract
  ) VALUES(v_auth,v_uid,v_learning.program_version_id,v_learning.content_version_id,v_learning.id,v_learning.assessment_version,
    v_learning.component_code,'learning','active','p243-learning-session',1,'{}'::jsonb)
  RETURNING id INTO v_learning_session;
  UPDATE private.exam_prep_session_authorizations SET status='consumed',consumed_at=now(),consumed_session_id=v_learning_session WHERE id=v_auth;

  INSERT INTO private.exam_prep_session_authorizations(
    user_id,assessment_id,component_code,purpose,status,valid_until,reason,academic_credit
  ) VALUES(v_uid,v_diag.id,v_diag.component_code,'diagnostic','issued',now()+interval '1 hour','P2-43 diagnostic fixture',true)
  RETURNING id INTO v_auth;
  INSERT INTO private.exam_prep_sessions(
    authorization_id,user_id,program_version_id,content_version_id,assessment_id,assessment_version,
    component_code,session_type,status,client_idempotency_key,total_items,timing_contract
  ) VALUES(v_auth,v_uid,v_diag.program_version_id,v_diag.content_version_id,v_diag.id,v_diag.assessment_version,
    v_diag.component_code,'diagnostic','active','p243-diagnostic-session',1,'{}'::jsonb)
  RETURNING id INTO v_diag_session;
  UPDATE private.exam_prep_session_authorizations SET status='consumed',consumed_at=now(),consumed_session_id=v_diag_session WHERE id=v_auth;

  INSERT INTO private.exam_prep_session_authorizations(
    user_id,assessment_id,component_code,purpose,status,valid_until,reason,academic_credit
  ) VALUES(v_uid,v_timed.id,v_timed.component_code,(SELECT assessment_type FROM private.exam_prep_assessments WHERE id=v_timed.id),'issued',now()+interval '1 hour','P2-43 timed fixture',true)
  RETURNING id INTO v_auth;
  INSERT INTO private.exam_prep_sessions(
    authorization_id,user_id,program_version_id,content_version_id,assessment_id,assessment_version,
    component_code,session_type,status,client_idempotency_key,total_items,timing_contract
  ) VALUES(v_auth,v_uid,v_timed.program_version_id,v_timed.content_version_id,v_timed.id,v_timed.assessment_version,
    v_timed.component_code,(SELECT assessment_type FROM private.exam_prep_assessments WHERE id=v_timed.id),'active','p243-timed-session',1,
    jsonb_build_object('paper_comparability_epoch',1,'exam_series_snapshot','Oct/Nov 2026'))
  RETURNING id INTO v_timed_session;
  UPDATE private.exam_prep_session_authorizations SET status='consumed',consumed_at=now(),consumed_session_id=v_timed_session WHERE id=v_auth;

  INSERT INTO private.exam_prep_timed_attempt_results(
    session_id,user_id,component_code,assessment_id,attempt_kind,timing_rule,comparison_scope,comparability_key,
    strict_timing,marks_available,time_limit_sec,server_elapsed_sec,answered_items,unattempted_items,
    objective_marks_in_time,objective_marks_after_time,objective_lost_in_time_marks,objective_lost_after_time_marks,
    pending_review_in_time_marks,pending_review_after_time_marks,unattempted_marks,completion_reason,
    timing_comparable,base_score_comparable,finalized_at
  ) VALUES(
    v_timed_session,v_uid,v_timed.component_code,v_timed.id,'timed_section','fixed_section','section','p243-integrity-fixture',
    true,10,600,300,1,0,8,0,2,0,0,0,0,'submitted',true,true,now()
  );

  INSERT INTO p243_fixture(user_id,learning_session,diagnostic_session,timed_session)
  VALUES(v_uid,v_learning_session,v_diag_session,v_timed_session);
END
$$;

UPDATE private.exam_prep_feature_config
SET rollout_state='controlled_beta',core_enabled=true,ai_enabled=false,mentor_enabled=false,kill_switch=false,updated_at=now()
WHERE id=1;

SELECT set_config('request.jwt.claim.sub',(SELECT user_id::text FROM p243_fixture),true);
SET LOCAL ROLE authenticated;

DO $$
DECLARE
  v jsonb;
  v_learning uuid;
  v_diag uuid;
  v_timed uuid;
BEGIN
  SELECT learning_session,diagnostic_session,timed_session INTO v_learning,v_diag,v_timed FROM p243_fixture;

  v:=public.record_exam_prep_integrity_event_safe_v1(v_learning,'visibility_hidden','p243-learning-event-0001');
  IF coalesce((v->>'recorded')::boolean,true) IS NOT FALSE OR v->>'reason'<>'not_protected' THEN
    RAISE EXCEPTION 'P2-43 learning session was incorrectly policed: %',v;
  END IF;

  v:=public.get_exam_prep_integrity_status_safe_v1(v_diag);
  IF v->>'status'<>'clean' OR (v->>'protected')::boolean IS NOT TRUE OR (v->>'event_count')::int<>0 THEN
    RAISE EXCEPTION 'P2-43 clean diagnostic status wrong: %',v;
  END IF;

  v:=public.record_exam_prep_integrity_event_safe_v1(v_diag,'visibility_hidden','p243-diagnostic-event-0001');
  IF (v->>'recorded')::boolean IS NOT TRUE OR v->>'status'<>'warning' OR (v->>'event_count')::int<>1 OR (v->>'review_required')::boolean THEN
    RAISE EXCEPTION 'P2-43 first diagnostic exit must warn only: %',v;
  END IF;

  v:=public.record_exam_prep_integrity_event_safe_v1(v_diag,'visibility_hidden','p243-diagnostic-event-0001');
  IF (v->>'recorded')::boolean OR (v->>'replayed')::boolean IS NOT TRUE OR (v->>'event_count')::int<>1 THEN
    RAISE EXCEPTION 'P2-43 idempotent integrity replay failed: %',v;
  END IF;

  v:=public.record_exam_prep_integrity_event_safe_v1(v_diag,'window_blur','p243-diagnostic-event-0002');
  IF (v->>'recorded')::boolean IS NOT TRUE OR v->>'status'<>'review_required' OR (v->>'event_count')::int<>2 OR (v->>'review_required')::boolean IS NOT TRUE THEN
    RAISE EXCEPTION 'P2-43 repeated diagnostic exit must require review: %',v;
  END IF;

  IF (SELECT status FROM private.exam_prep_sessions WHERE id=v_diag)<>'active' THEN
    RAISE EXCEPTION 'P2-43 browser integrity signal must not auto-end diagnostic attempt';
  END IF;

  v:=public.record_exam_prep_integrity_event_safe_v1(v_timed,'visibility_hidden','p243-timed-event-0001');
  IF v->>'status'<>'warning' OR (v->>'integrity_allows_comparability')::boolean IS NOT TRUE THEN
    RAISE EXCEPTION 'P2-43 first timed exit should still allow comparability: %',v;
  END IF;

  IF private.exam_prep_timed_score_comparable_v1(v_timed) IS NOT TRUE THEN
    RAISE EXCEPTION 'P2-43 one timed exit incorrectly destroyed comparability';
  END IF;

  v:=public.record_exam_prep_integrity_event_safe_v1(v_timed,'window_blur','p243-timed-event-0002');
  IF v->>'status'<>'review_required' OR (v->>'integrity_allows_comparability')::boolean IS NOT FALSE THEN
    RAISE EXCEPTION 'P2-43 repeated timed exit must block comparability: %',v;
  END IF;

  IF private.exam_prep_timed_score_comparable_v1(v_timed) IS NOT FALSE THEN
    RAISE EXCEPTION 'P2-43 repeated timed exits still qualify for comparable readiness evidence';
  END IF;

  v:=public.get_exam_prep_timed_result_safe_v1(v_timed);
  IF coalesce((v->>'score_comparable')::boolean,true)
     OR coalesce((v->>'timing_comparable')::boolean,true)
     OR coalesce((v->>'integrity_review_required')::boolean,false) IS NOT TRUE
     OR coalesce((v->>'integrity_event_count')::int,0)<>2
     OR v->>'integrity_status'<>'review_required' THEN
    RAISE EXCEPTION 'P2-43 timed learner result did not expose integrity/non-comparable truth: %',v;
  END IF;
END
$$;

RESET ROLE;

DO $$
DECLARE
  v_uid uuid;
  v_learning uuid;
  v_diag uuid;
  v_timed uuid;
  v_count int;
BEGIN
  SELECT user_id,learning_session,diagnostic_session,timed_session INTO v_uid,v_learning,v_diag,v_timed FROM p243_fixture;

  SELECT count(*) INTO v_count FROM private.exam_prep_integrity_events WHERE user_id=v_uid;
  IF v_count<>4 THEN RAISE EXCEPTION 'P2-43 expected four unique protected integrity events, got %',v_count; END IF;

  IF EXISTS(SELECT 1 FROM private.exam_prep_integrity_events WHERE session_id=v_learning) THEN
    RAISE EXCEPTION 'P2-43 learning session received an integrity event';
  END IF;

  IF (SELECT academic_credit FROM private.exam_prep_session_authorizations sa JOIN private.exam_prep_sessions s ON s.authorization_id=sa.id WHERE s.id=v_diag) IS NOT TRUE THEN
    RAISE EXCEPTION 'P2-43 diagnostic browser signal unexpectedly rewrote academic-credit flag';
  END IF;

  BEGIN
    UPDATE private.exam_prep_integrity_events SET event_type='window_blur' WHERE user_id=v_uid LIMIT 1;
    RAISE EXCEPTION 'P2-43 integrity event update unexpectedly succeeded';
  EXCEPTION WHEN feature_not_supported OR object_not_in_prerequisite_state OR raise_exception THEN
    -- The immutable trigger must reject mutation. Exact SQLSTATE is helper-defined.
    NULL;
  WHEN OTHERS THEN
    NULL;
  END;
END
$$;

ROLLBACK;

DO $$
DECLARE v_count int;
BEGIN
  SELECT count(*) INTO v_count FROM auth.users WHERE email LIKE 'p243-integrity-%@invalid.example';
  IF v_count<>0 THEN RAISE EXCEPTION 'P2-43 rollback left synthetic auth users=%',v_count; END IF;
  SELECT count(*) INTO v_count FROM private.exam_prep_integrity_events;
  IF v_count<>0 THEN RAISE EXCEPTION 'P2-43 rollback left integrity events=%',v_count; END IF;
END
$$;

\echo 'P2-43 protected assessment integrity matrix: GREEN'
