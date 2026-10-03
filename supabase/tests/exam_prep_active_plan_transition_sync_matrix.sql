-- Active weekly-plan transition sync matrix.
-- Disposable PostgreSQL only; all fixture rows roll back.
\set ON_ERROR_STOP on
DO $$ BEGIN
  IF current_setting('progress_ux.isolated_db',true) IS DISTINCT FROM 'true' THEN
    RAISE EXCEPTION 'PLAN TRANSITION SYNC REFUSED: isolated database required';
  END IF;
END $$;

BEGIN;

DO $matrix$
DECLARE
  u1 uuid:=gen_random_uuid();
  u2 uuid:=gen_random_uuid();
  prog bigint;
  p1_plan uuid;
  p5_plan uuid;
  p1_case uuid;
  p5_case uuid;
  p1_rt1 uuid;
  p1_rt2 uuid;
  p5_rt uuid;
  p1_learning bigint;
  p1_mixed bigint;
  p5_retest bigint;
  auth_id uuid;
  session_id uuid;
  content_id bigint;
  ass_ver text;
  item record;
  due1 timestamptz:=clock_timestamp()+interval '2 days';
  due2 timestamptz:=clock_timestamp()+interval '4 days';
  due5 timestamptz:=clock_timestamp()+interval '3 days';
  audit jsonb;
BEGIN
  INSERT INTO auth.users(id,aud,role,email,created_at,updated_at,is_sso_user,is_anonymous)
  VALUES
    (u1,'authenticated','authenticated','transition-sync-p1@invalid.example',now(),now(),false,false),
    (u2,'authenticated','authenticated','transition-sync-p5@invalid.example',now(),now(),false,false);
  INSERT INTO public.users(id,first_name,created_at,must_change_password)
  VALUES
    (u1,'PlanTransitionSync',now(),false),
    (u2,'PlanTransitionSync',now(),false);

  SELECT id INTO STRICT prog
  FROM private.exam_prep_program_versions
  WHERE program_key='math_as_p1_p5'
    AND version_key='p1_p5_canonical_v1_0'
    AND status='active';

  INSERT INTO private.exam_prep_exam_profiles
    (user_id,program_version_id,exam_series,target_grade,total_student_hours_available,
     mathematics_hours_budget,active_week_no)
  VALUES
    (u1,prog,'May/June 2027','A',12,6,1),
    (u2,prog,'May/June 2027','A',12,6,1);

  INSERT INTO private.exam_prep_correction_cases
    (user_id,component_code,skill_code,status,engine_version,reason)
  VALUES
    (u1,'P1','P1-CIR-01','open','objective_state_v1','{"fixture":"transition_sync"}'::jsonb)
  RETURNING id INTO p1_case;

  INSERT INTO private.exam_prep_correction_cases
    (user_id,component_code,skill_code,status,engine_version,reason)
  VALUES
    (u2,'P5','P5-DAT-01','open','objective_state_v1','{"fixture":"transition_sync"}'::jsonb)
  RETURNING id INTO p5_case;

  INSERT INTO private.exam_prep_weekly_plans
    (user_id,program_version_id,component_code,active_week_no,plan_version,status,policy_note)
  VALUES(u1,prog,'P1',1,91,'active','Transition sync P1 fixture')
  RETURNING id INTO p1_plan;

  INSERT INTO private.exam_prep_weekly_plan_items
    (plan_id,priority_order,item_type,skill_code,correction_case_id,action_code,action_payload)
  VALUES
    (p1_plan,1,'correction','P1-CIR-01',p1_case,'COMPLETE_CORRECTION_ANALOGUES',
      '{"analogue_floor":3,"analogue_ceiling":6,"written_or_unprompted_required":true}'::jsonb),
    (p1_plan,2,'learning','P1-QUA-01',null,'BUILD_FIRST_COVERAGE','{}'::jsonb),
    (p1_plan,3,'mixed_transfer','P1-CIR-01',null,'COMPLETE_MIXED_TRANSFER','{}'::jsonb);

  INSERT INTO private.exam_prep_weekly_plans
    (user_id,program_version_id,component_code,active_week_no,plan_version,status,policy_note)
  VALUES(u2,prog,'P5',1,91,'active','Transition sync P5 fixture')
  RETURNING id INTO p5_plan;

  INSERT INTO private.exam_prep_weekly_plan_items
    (plan_id,priority_order,item_type,skill_code,correction_case_id,action_code,action_payload)
  VALUES
    (p5_plan,1,'correction','P5-DAT-01',p5_case,'COMPLETE_CORRECTION_ANALOGUES',
      '{"analogue_floor":3,"analogue_ceiling":6,"written_or_unprompted_required":true}'::jsonb),
    (p5_plan,2,'retest','P5-DAT-02',null,'COMPLETE_RETENTION_RETEST','{}'::jsonb);

  -- P1 regular learning finalization must complete only its own plan item.
  SELECT a.id,a.content_version_id,a.assessment_version
  INTO STRICT p1_learning,content_id,ass_ver
  FROM private.exam_prep_assessments a
  WHERE a.component_code='P1' AND a.assessment_type='learning' AND a.status='published'
  ORDER BY a.id LIMIT 1;

  INSERT INTO private.exam_prep_session_authorizations
    (user_id,assessment_id,component_code,purpose,status,valid_until,reason,
     academic_credit,plan_id,plan_priority_order)
  VALUES(u1,p1_learning,'P1','learning','issued',now()+interval '1 hour',
         'transition sync learning fixture',true,p1_plan,2)
  RETURNING id INTO auth_id;

  session_id:=gen_random_uuid();
  INSERT INTO private.exam_prep_sessions
    (id,authorization_id,user_id,program_version_id,content_version_id,assessment_id,
     assessment_version,component_code,session_type,status,client_idempotency_key,total_items)
  VALUES(session_id,auth_id,u1,prog,content_id,p1_learning,ass_ver,'P1','learning','active',
         'transition-sync-learning',1);

  UPDATE private.exam_prep_sessions
  SET status='finalized',finalized_at=clock_timestamp(),last_activity_at=clock_timestamp(),
      finalize_idempotency_key='transition-sync-learning-final'
  WHERE id=session_id;

  SELECT * INTO STRICT item
  FROM private.exam_prep_weekly_plan_items
  WHERE plan_id=p1_plan AND priority_order=2;
  IF item.status<>'completed' THEN
    RAISE EXCEPTION 'regular learning did not complete active plan item: %',row_to_json(item);
  END IF;

  -- P1 mixed finalization uses the same generic completion law.
  SELECT a.id,a.content_version_id,a.assessment_version
  INTO STRICT p1_mixed,content_id,ass_ver
  FROM private.exam_prep_assessments a
  WHERE a.component_code='P1' AND a.assessment_type='mixed' AND a.status='published'
  ORDER BY a.id LIMIT 1;

  INSERT INTO private.exam_prep_session_authorizations
    (user_id,assessment_id,component_code,purpose,status,valid_until,reason,
     academic_credit,plan_id,plan_priority_order)
  VALUES(u1,p1_mixed,'P1','mixed','issued',now()+interval '1 hour',
         'transition sync mixed fixture',true,p1_plan,3)
  RETURNING id INTO auth_id;

  session_id:=gen_random_uuid();
  INSERT INTO private.exam_prep_sessions
    (id,authorization_id,user_id,program_version_id,content_version_id,assessment_id,
     assessment_version,component_code,session_type,status,client_idempotency_key,total_items)
  VALUES(session_id,auth_id,u1,prog,content_id,p1_mixed,ass_ver,'P1','mixed','active',
         'transition-sync-mixed',1);

  UPDATE private.exam_prep_sessions
  SET status='finalized',finalized_at=clock_timestamp(),last_activity_at=clock_timestamp(),
      finalize_idempotency_key='transition-sync-mixed-final'
  WHERE id=session_id;

  IF (SELECT status FROM private.exam_prep_weekly_plan_items
      WHERE plan_id=p1_plan AND priority_order=3)<>'completed' THEN
    RAISE EXCEPTION 'mixed transfer did not complete active plan item';
  END IF;

  -- Correction -> delayed retest must preserve slot identity and original correction payload.
  UPDATE private.exam_prep_correction_cases
  SET status='retest_due',updated_at=clock_timestamp()
  WHERE id=p1_case;

  IF (SELECT item_type FROM private.exam_prep_weekly_plan_items
      WHERE plan_id=p1_plan AND priority_order=1)<>'correction' THEN
    RAISE EXCEPTION 'case moved before a real retest event existed';
  END IF;

  INSERT INTO private.exam_prep_retest_events
    (correction_case_id,user_id,component_code,skill_code,status,due_not_before)
  VALUES(p1_case,u1,'P1','P1-CIR-01','scheduled',due1)
  RETURNING id INTO p1_rt1;

  SELECT id INTO STRICT p1_plan
  FROM private.exam_prep_weekly_plans
  WHERE user_id=u1 AND component_code='P1' AND status='active';

  SELECT * INTO STRICT item
  FROM private.exam_prep_weekly_plan_items
  WHERE plan_id=p1_plan AND priority_order=1;
  IF item.item_type<>'retest'
     OR item.action_code<>'COMPLETE_DELAYED_RETEST'
     OR item.due_at IS DISTINCT FROM due1
     OR item.status<>'pending'
     OR item.action_payload->>'transition_original_action_code'<>'COMPLETE_CORRECTION_ANALOGUES'
     OR item.action_payload->'transition_original_action_payload'->>'analogue_floor'<>'3' THEN
    RAISE EXCEPTION 'correction -> retest transition wrong: %',row_to_json(item);
  END IF;

  -- Failed retest / reopened case must route the same slot back to remediation.
  UPDATE private.exam_prep_retest_events
  SET status='completed',completed_at=clock_timestamp()
  WHERE id=p1_rt1;
  UPDATE private.exam_prep_correction_cases
  SET status='reopened',resolved_at=null,updated_at=clock_timestamp()
  WHERE id=p1_case;

  SELECT id INTO STRICT p1_plan
  FROM private.exam_prep_weekly_plans
  WHERE user_id=u1 AND component_code='P1' AND status='active';

  SELECT * INTO STRICT item
  FROM private.exam_prep_weekly_plan_items
  WHERE plan_id=p1_plan AND priority_order=1;
  IF item.item_type<>'correction'
     OR item.action_code<>'COMPLETE_CORRECTION_ANALOGUES'
     OR item.due_at IS NOT NULL
     OR item.action_payload->>'analogue_floor'<>'3'
     OR item.status<>'pending' THEN
    RAISE EXCEPTION 'failed retest did not restore correction route: %',row_to_json(item);
  END IF;

  -- A second remediation cycle may schedule a new delayed retest without duplicating the slot.
  UPDATE private.exam_prep_correction_cases
  SET status='retest_due',updated_at=clock_timestamp()
  WHERE id=p1_case;
  INSERT INTO private.exam_prep_retest_events
    (correction_case_id,user_id,component_code,skill_code,status,due_not_before)
  VALUES(p1_case,u1,'P1','P1-CIR-01','scheduled',due2)
  RETURNING id INTO p1_rt2;

  SELECT id INTO STRICT p1_plan
  FROM private.exam_prep_weekly_plans
  WHERE user_id=u1 AND component_code='P1' AND status='active';

  SELECT * INTO STRICT item
  FROM private.exam_prep_weekly_plan_items
  WHERE plan_id=p1_plan AND priority_order=1;
  IF item.item_type<>'retest' OR item.due_at IS DISTINCT FROM due2 OR item.status<>'pending' THEN
    RAISE EXCEPTION 'second correction -> retest transition wrong: %',row_to_json(item);
  END IF;

  -- Passing the delayed retest closes the same active item.
  UPDATE private.exam_prep_retest_events
  SET status='completed',completed_at=clock_timestamp()
  WHERE id=p1_rt2;
  UPDATE private.exam_prep_correction_cases
  SET status='resolved',resolved_at=clock_timestamp(),updated_at=clock_timestamp()
  WHERE id=p1_case;

  IF (SELECT status FROM private.exam_prep_weekly_plan_items
      WHERE plan_id=p1_plan AND priority_order=1)<>'completed' THEN
    RAISE EXCEPTION 'resolved correction did not complete active plan item';
  END IF;

  -- P5 symmetry: same transition law, no P1/P5 cross-component mutation.
  UPDATE private.exam_prep_correction_cases
  SET status='retest_due',updated_at=clock_timestamp()
  WHERE id=p5_case;
  INSERT INTO private.exam_prep_retest_events
    (correction_case_id,user_id,component_code,skill_code,status,due_not_before)
  VALUES(p5_case,u2,'P5','P5-DAT-01','scheduled',due5)
  RETURNING id INTO p5_rt;

  SELECT id INTO STRICT p5_plan
  FROM private.exam_prep_weekly_plans
  WHERE user_id=u2 AND component_code='P5' AND status='active';

  SELECT * INTO STRICT item
  FROM private.exam_prep_weekly_plan_items
  WHERE plan_id=p5_plan AND priority_order=1;
  IF item.item_type<>'retest'
     OR item.action_code<>'COMPLETE_DELAYED_RETEST'
     OR item.due_at IS DISTINCT FROM due5 THEN
    RAISE EXCEPTION 'P5 correction -> retest symmetry failed: %',row_to_json(item);
  END IF;

  IF (SELECT status FROM private.exam_prep_weekly_plan_items
      WHERE plan_id=p1_plan AND priority_order=1)<>'completed' THEN
    RAISE EXCEPTION 'P5 transition mutated P1 plan';
  END IF;

  -- Retention-style retest without a correction case completes after finalized retest session.
  SELECT a.id,a.content_version_id,a.assessment_version
  INTO STRICT p5_retest,content_id,ass_ver
  FROM private.exam_prep_assessments a
  WHERE a.component_code='P5' AND a.assessment_type='retest' AND a.status='published'
  ORDER BY a.id LIMIT 1;

  INSERT INTO private.exam_prep_session_authorizations
    (user_id,assessment_id,component_code,purpose,status,valid_until,reason,
     academic_credit,plan_id,plan_priority_order)
  VALUES(u2,p5_retest,'P5','retest','issued',now()+interval '1 hour',
         'transition sync retention fixture',true,p5_plan,2)
  RETURNING id INTO auth_id;

  session_id:=gen_random_uuid();
  INSERT INTO private.exam_prep_sessions
    (id,authorization_id,user_id,program_version_id,content_version_id,assessment_id,
     assessment_version,component_code,session_type,status,client_idempotency_key,total_items)
  VALUES(session_id,auth_id,u2,prog,content_id,p5_retest,ass_ver,'P5','retest','active',
         'transition-sync-retention',1);

  UPDATE private.exam_prep_sessions
  SET status='finalized',finalized_at=clock_timestamp(),last_activity_at=clock_timestamp(),
      finalize_idempotency_key='transition-sync-retention-final'
  WHERE id=session_id;

  IF (SELECT status FROM private.exam_prep_weekly_plan_items
      WHERE plan_id=p5_plan AND priority_order=2)<>'completed' THEN
    RAISE EXCEPTION 'retention retest did not complete active plan item';
  END IF;

  audit:=private.exam_prep_active_plan_transition_audit_v1();
  IF (audit->>'hard_anomaly_count')::integer<>0 THEN
    RAISE EXCEPTION 'transition audit not clean after lifecycle matrix: %',audit;
  END IF;

  IF has_function_privilege('authenticated',
       'private.exam_prep_reconcile_active_plan_transitions_v1(uuid,text)','EXECUTE')
     OR has_function_privilege('service_role',
       'private.exam_prep_reconcile_active_plan_transitions_v1(uuid,text)','EXECUTE')
     OR has_function_privilege('anon',
       'private.exam_prep_active_plan_transition_audit_v1()','EXECUTE') THEN
    RAISE EXCEPTION 'private transition functions exposed';
  END IF;

  RAISE NOTICE 'Active plan transition sync PASS: learning, mixed, correction->retest, failed retest->correction, pass->complete, P1/P5 isolation, retention completion';
END;
$matrix$;

ROLLBACK;

DO $$ BEGIN
  IF EXISTS(SELECT 1 FROM public.users WHERE first_name='PlanTransitionSync')
     OR EXISTS(SELECT 1 FROM auth.users WHERE email LIKE 'transition-sync-%@invalid.example') THEN
    RAISE EXCEPTION 'transition sync matrix left synthetic residue';
  END IF;
  RAISE NOTICE 'Active plan transition sync rollback PASS';
END $$;
