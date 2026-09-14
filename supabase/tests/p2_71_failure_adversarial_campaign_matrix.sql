\set ON_ERROR_STOP on

DO $$
BEGIN
  IF current_setting('p271.isolated_db', true) IS DISTINCT FROM 'true' THEN
    RAISE EXCEPTION 'P2-71 REFUSED: isolated test database required';
  END IF;
END
$$;

BEGIN;

-- P2-71 actively attacks learner-state/security boundaries. Every synthetic
-- write is contained by this transaction and is rolled back at the end.
DO $$
BEGIN
  IF has_table_privilege('authenticated','public.questions','SELECT') THEN
    RAISE EXCEPTION 'P2-71 authenticated can directly SELECT answer-bearing questions';
  END IF;
  IF has_table_privilege('authenticated','private.exam_prep_sessions','SELECT')
     OR has_table_privilege('authenticated','private.exam_prep_responses','SELECT')
     OR has_table_privilege('authenticated','private.exam_prep_evidence_events','SELECT')
     OR has_table_privilege('authenticated','private.exam_prep_session_items','SELECT') THEN
    RAISE EXCEPTION 'P2-71 authenticated can directly read private session/evidence tables';
  END IF;
  IF has_table_privilege('authenticated','private.exam_prep_sessions','UPDATE')
     OR has_table_privilege('authenticated','private.exam_prep_responses','INSERT')
     OR has_table_privilege('authenticated','private.exam_prep_evidence_events','INSERT') THEN
    RAISE EXCEPTION 'P2-71 authenticated can directly mutate private session/evidence tables';
  END IF;
  IF has_function_privilege('anon','public.start_exam_prep_session_safe_v1(uuid,text)','EXECUTE')
     OR has_function_privilege('anon','public.submit_exam_prep_response_safe_v1(uuid,integer,jsonb,text,integer,text)','EXECUTE')
     OR has_function_privilege('anon','public.finalize_exam_prep_session_safe_v1(uuid,text)','EXECUTE') THEN
    RAISE EXCEPTION 'P2-71 anon can execute learner session RPCs';
  END IF;
END
$$;

CREATE TEMP TABLE p271_fixture(
  user_a uuid primary key,
  user_b uuid not null,
  p1_learning bigint not null,
  p5_learning bigint not null,
  protected_diagnostic bigint not null,
  p1_timed bigint not null,
  p1_session uuid,
  p5_session uuid,
  diagnostic_session uuid,
  abandoned_session uuid,
  retake_session uuid,
  timed_session uuid,
  first_p1_item smallint,
  first_p1_key text,
  first_p1_response uuid
) ON COMMIT DROP;

CREATE OR REPLACE FUNCTION pg_temp.p271_issue_and_start_v1(
  p_user_id uuid,
  p_assessment_id bigint,
  p_component text,
  p_purpose text,
  p_start_key text
)
RETURNS uuid
LANGUAGE plpgsql
AS $$
DECLARE
  v_auth uuid;
  v_start jsonb;
BEGIN
  INSERT INTO private.exam_prep_session_authorizations(
    user_id,assessment_id,component_code,purpose,status,valid_until,reason,academic_credit
  ) VALUES(
    p_user_id,p_assessment_id,p_component,p_purpose,'issued',clock_timestamp()+interval '1 hour',
    'P2-71 rollback-only adversarial fixture',true
  ) RETURNING id INTO v_auth;

  PERFORM set_config('request.jwt.claim.sub',p_user_id::text,true);
  PERFORM set_config('request.jwt.claim.role','authenticated',true);
  v_start:=public.start_exam_prep_session_safe_v1(v_auth,p_start_key);
  RETURN (v_start->>'session_id')::uuid;
END
$$;

CREATE OR REPLACE FUNCTION pg_temp.p271_finish_non_timed_v1(
  p_user_id uuid,
  p_session_id uuid,
  p_prefix text
)
RETURNS jsonb
LANGUAGE plpgsql
AS $$
DECLARE
  v_item record;
  v_payload jsonb;
BEGIN
  PERFORM set_config('request.jwt.claim.sub',p_user_id::text,true);
  PERFORM set_config('request.jwt.claim.role','authenticated',true);

  FOR v_item IN
    SELECT si.item_order,si.item_kind,q.correct_answer
    FROM private.exam_prep_session_items si
    LEFT JOIN private.exam_prep_responses r
      ON r.session_id=si.session_id AND r.item_order=si.item_order
    LEFT JOIN public.questions q ON q.id=si.question_id
    WHERE si.session_id=p_session_id AND r.id IS NULL
    ORDER BY si.item_order
  LOOP
    IF v_item.item_kind='question' THEN
      v_payload:=jsonb_build_object('answer',v_item.correct_answer);
    ELSE
      v_payload:=jsonb_build_object('artifact',jsonb_build_object(
        'working','P2-71 isolated adversarial working',
        'method','synthetic validation'
      ));
    END IF;
    PERFORM public.submit_exam_prep_response_safe_v1(
      p_session_id,v_item.item_order,v_payload,
      p_prefix||'-i'||lpad(v_item.item_order::text,3,'0'),1000,'en'
    );
  END LOOP;

  RETURN public.finalize_exam_prep_session_safe_v1(p_session_id,p_prefix||'-final');
END
$$;

DO $$
DECLARE
  v_a uuid:=gen_random_uuid();
  v_b uuid:=gen_random_uuid();
  v_program bigint;
  v_p1 bigint;
  v_p5 bigint;
  v_diag bigint;
  v_timed bigint;
BEGIN
  SELECT id INTO v_program
  FROM private.exam_prep_program_versions
  WHERE program_key='math_as_p1_p5' AND version_key='p1_p5_canonical_v1_0' AND status='active';
  IF v_program IS NULL THEN RAISE EXCEPTION 'P2-71 canonical program missing'; END IF;

  SELECT a.id INTO v_p1
  FROM private.exam_prep_assessments a
  WHERE a.component_code='P1' AND a.assessment_type='learning' AND a.status='published'
    AND EXISTS(SELECT 1 FROM private.exam_prep_assessment_items ai WHERE ai.assessment_id=a.id AND ai.question_id IS NOT NULL)
  ORDER BY a.id LIMIT 1;

  SELECT a.id INTO v_p5
  FROM private.exam_prep_assessments a
  WHERE a.component_code='P5' AND a.assessment_type='learning' AND a.status='published'
    AND EXISTS(SELECT 1 FROM private.exam_prep_assessment_items ai WHERE ai.assessment_id=a.id AND ai.question_id IS NOT NULL)
  ORDER BY a.id LIMIT 1;

  SELECT a.id INTO v_diag
  FROM private.exam_prep_assessments a
  WHERE a.assessment_type='diagnostic' AND a.status='published'
    AND EXISTS(SELECT 1 FROM private.exam_prep_assessment_items ai WHERE ai.assessment_id=a.id AND ai.question_id IS NOT NULL)
  ORDER BY CASE WHEN a.component_code='P1' THEN 0 ELSE 1 END,a.id LIMIT 1;

  -- Current governed timed/full-paper content is written-working based. That is
  -- intentional; P2-71 attacks its rubric/correctness boundary with a written item.
  SELECT a.id INTO v_timed
  FROM private.exam_prep_assessments a
  JOIN private.exam_prep_timed_assessment_contracts tc ON tc.assessment_id=a.id AND tc.status='published'
  WHERE a.component_code='P1' AND a.assessment_type IN ('timed','paper') AND a.status='published'
    AND EXISTS(SELECT 1 FROM private.exam_prep_assessment_items ai WHERE ai.assessment_id=a.id)
  ORDER BY CASE WHEN a.assessment_type='timed' THEN 0 ELSE 1 END,a.id LIMIT 1;

  IF v_p1 IS NULL OR v_p5 IS NULL OR v_diag IS NULL OR v_timed IS NULL THEN
    RAISE EXCEPTION 'P2-71 published learning/diagnostic/timed fixtures required';
  END IF;

  INSERT INTO auth.users(id,aud,role,email,created_at,updated_at,is_sso_user,is_anonymous)
  VALUES
    (v_a,'authenticated','authenticated','p271-a-'||replace(v_a::text,'-','')||'@invalid.example',now(),now(),false,false),
    (v_b,'authenticated','authenticated','p271-b-'||replace(v_b::text,'-','')||'@invalid.example',now(),now(),false,false);
  INSERT INTO public.users(id,first_name,last_name,language_code,created_at,must_change_password)
  VALUES
    (v_a,'P271','AdversaryA','en',now(),false),
    (v_b,'P271','AdversaryB','en',now(),false);

  INSERT INTO private.exam_prep_feature_entitlements(
    user_id,entitlement_status,core_access,ai_assist,mentor_care_entitled,valid_from
  ) VALUES
    (v_a,'active',true,false,false,now()-interval '1 minute'),
    (v_b,'active',true,false,false,now()-interval '1 minute');

  INSERT INTO p271_fixture(user_a,user_b,p1_learning,p5_learning,protected_diagnostic,p1_timed)
  VALUES(v_a,v_b,v_p1,v_p5,v_diag,v_timed);
END
$$;

UPDATE private.exam_prep_feature_config
SET rollout_state='controlled_beta',core_enabled=true,ai_enabled=false,mentor_enabled=false,kill_switch=false,updated_at=now()
WHERE id=1;

-- Unauthenticated and malformed starts fail closed.
DO $$
DECLARE v_a uuid; v_p1 bigint; v_auth uuid; v_failed boolean;
BEGIN
  SELECT user_a,p1_learning INTO v_a,v_p1 FROM p271_fixture;
  PERFORM set_config('request.jwt.claim.sub','',true);
  PERFORM set_config('request.jwt.claim.role','authenticated',true);
  v_failed:=false;
  BEGIN
    PERFORM public.get_exam_prep_session_safe_v1(gen_random_uuid(),'en');
  EXCEPTION WHEN OTHERS THEN
    IF position('exam_prep_auth_required' in SQLERRM)=0 THEN RAISE; END IF;
    v_failed:=true;
  END;
  IF NOT v_failed THEN RAISE EXCEPTION 'P2-71 unauthenticated session read unexpectedly succeeded'; END IF;

  INSERT INTO private.exam_prep_session_authorizations(
    user_id,assessment_id,component_code,purpose,status,valid_until,reason,academic_credit
  ) VALUES(v_a,v_p1,'P1','learning','issued',now()+interval '1 hour','P2-71 malformed start',true)
  RETURNING id INTO v_auth;
  PERFORM set_config('request.jwt.claim.sub',v_a::text,true);
  v_failed:=false;
  BEGIN
    PERFORM public.start_exam_prep_session_safe_v1(v_auth,'short');
  EXCEPTION WHEN OTHERS THEN
    IF position('exam_prep_bad_idempotency_key' in SQLERRM)=0 THEN RAISE; END IF;
    v_failed:=true;
  END;
  IF NOT v_failed THEN RAISE EXCEPTION 'P2-71 malformed start idempotency key was accepted'; END IF;
END
$$;

-- Refresh/reconnect, offline replay, duplicate submit/finalize and stale-key attacks.
DO $$
DECLARE
  v_a uuid; v_p1 bigint; v_p5 bigint; v_auth uuid; v_other_auth uuid; v_session uuid;
  v_start jsonb; v_refresh jsonb; v_item smallint; v_answer text; v_submit jsonb; v_replay jsonb;
  v_resp uuid; v_responses_before int; v_evidence_before int; v_failed boolean;
BEGIN
  SELECT user_a,p1_learning,p5_learning INTO v_a,v_p1,v_p5 FROM p271_fixture;
  INSERT INTO private.exam_prep_session_authorizations(
    user_id,assessment_id,component_code,purpose,status,valid_until,reason,academic_credit
  ) VALUES(v_a,v_p1,'P1','learning','issued',now()+interval '1 hour','P2-71 P1 session',true)
  RETURNING id INTO v_auth;

  PERFORM set_config('request.jwt.claim.sub',v_a::text,true);
  PERFORM set_config('request.jwt.claim.role','authenticated',true);
  v_start:=public.start_exam_prep_session_safe_v1(v_auth,'p271-p1-start-0001');
  v_session:=(v_start->>'session_id')::uuid;
  IF coalesce((v_start->>'resumed')::boolean,true) THEN RAISE EXCEPTION 'P2-71 first start reported resumed'; END IF;

  v_start:=public.start_exam_prep_session_safe_v1(v_auth,'p271-p1-start-0001');
  IF (v_start->>'session_id')::uuid<>v_session OR coalesce((v_start->>'resumed')::boolean,false) IS NOT TRUE THEN
    RAISE EXCEPTION 'P2-71 refresh/start retry did not resume exact session: %',v_start;
  END IF;
  v_refresh:=public.get_exam_prep_session_safe_v1(v_session,'en');
  IF v_refresh->>'status'<>'active' THEN RAISE EXCEPTION 'P2-71 reconnect lost active state'; END IF;

  INSERT INTO private.exam_prep_session_authorizations(
    user_id,assessment_id,component_code,purpose,status,valid_until,reason,academic_credit
  ) VALUES(v_a,v_p5,'P5','learning','issued',now()+interval '1 hour','P2-71 stale-key conflict',true)
  RETURNING id INTO v_other_auth;
  v_failed:=false;
  BEGIN PERFORM public.start_exam_prep_session_safe_v1(v_other_auth,'p271-p1-start-0001');
  EXCEPTION WHEN OTHERS THEN IF position('exam_prep_idempotency_conflict' in SQLERRM)=0 THEN RAISE; END IF; v_failed:=true; END;
  IF NOT v_failed THEN RAISE EXCEPTION 'P2-71 stale start key rebound to another authorization'; END IF;

  SELECT si.item_order,q.correct_answer INTO v_item,v_answer
  FROM private.exam_prep_session_items si JOIN public.questions q ON q.id=si.question_id
  WHERE si.session_id=v_session AND si.item_kind='question' ORDER BY si.item_order LIMIT 1;
  IF v_item IS NULL THEN RAISE EXCEPTION 'P2-71 P1 machine item missing'; END IF;

  v_failed:=false;
  BEGIN
    PERFORM public.submit_exam_prep_response_safe_v1(
      v_session,v_item,jsonb_build_object('answer',v_answer,'is_correct',true),
      'p271-forged-server-field-0001',1000,'en'
    );
  EXCEPTION WHEN OTHERS THEN IF position('exam_prep_server_owned_field_rejected' in SQLERRM)=0 THEN RAISE; END IF; v_failed:=true; END;
  IF NOT v_failed THEN RAISE EXCEPTION 'P2-71 forged server-owned correctness accepted'; END IF;

  v_submit:=public.submit_exam_prep_response_safe_v1(
    v_session,v_item,jsonb_build_object('answer',v_answer),'p271-p1-answer-0001',1000,'en'
  );
  v_resp:=(v_submit->>'response_id')::uuid;
  IF v_resp IS NULL OR coalesce((v_submit->>'replayed')::boolean,true) THEN RAISE EXCEPTION 'P2-71 first submit wrong'; END IF;

  SELECT count(*) INTO v_responses_before FROM private.exam_prep_responses WHERE session_id=v_session;
  SELECT count(*) INTO v_evidence_before FROM private.exam_prep_evidence_events WHERE session_id=v_session;
  v_replay:=public.submit_exam_prep_response_safe_v1(
    v_session,v_item,jsonb_build_object('answer','different-offline-body'),
    'p271-p1-answer-0001',999999,'ru'
  );
  IF (v_replay->>'response_id')::uuid<>v_resp OR coalesce((v_replay->>'replayed')::boolean,false) IS NOT TRUE THEN
    RAISE EXCEPTION 'P2-71 offline duplicate submit was not replay-safe: %',v_replay;
  END IF;
  IF (SELECT count(*) FROM private.exam_prep_responses WHERE session_id=v_session)<>v_responses_before
     OR (SELECT count(*) FROM private.exam_prep_evidence_events WHERE session_id=v_session)<>v_evidence_before THEN
    RAISE EXCEPTION 'P2-71 duplicate submit created duplicate response/evidence';
  END IF;

  v_failed:=false;
  BEGIN PERFORM public.submit_exam_prep_response_safe_v1(
    v_session,v_item,jsonb_build_object('answer',v_answer),'p271-p1-answer-newkey-0002',1000,'en'
  ); EXCEPTION WHEN OTHERS THEN IF position('exam_prep_item_already_answered' in SQLERRM)=0 THEN RAISE; END IF; v_failed:=true; END;
  IF NOT v_failed THEN RAISE EXCEPTION 'P2-71 same item accepted second idempotency key'; END IF;

  UPDATE p271_fixture SET p1_session=v_session,first_p1_item=v_item,first_p1_key='p271-p1-answer-0001',first_p1_response=v_resp
  WHERE user_a=v_a;
END
$$;

-- Cross-user isolation.
DO $$
DECLARE v_b uuid; v_session uuid; v_item smallint; v_failed boolean;
BEGIN
  SELECT user_b,p1_session,first_p1_item INTO v_b,v_session,v_item FROM p271_fixture;
  PERFORM set_config('request.jwt.claim.sub',v_b::text,true);
  PERFORM set_config('request.jwt.claim.role','authenticated',true);
  v_failed:=false;
  BEGIN PERFORM public.get_exam_prep_session_safe_v1(v_session,'en');
  EXCEPTION WHEN OTHERS THEN IF position('exam_prep_session_not_found' in SQLERRM)=0 THEN RAISE; END IF; v_failed:=true; END;
  IF NOT v_failed THEN RAISE EXCEPTION 'P2-71 cross-user read succeeded'; END IF;
  v_failed:=false;
  BEGIN PERFORM public.submit_exam_prep_response_safe_v1(v_session,v_item,'{"answer":"A"}'::jsonb,'p271-cross-user-submit-0001',1000,'en');
  EXCEPTION WHEN OTHERS THEN IF position('exam_prep_session_not_found' in SQLERRM)=0 THEN RAISE; END IF; v_failed:=true; END;
  IF NOT v_failed THEN RAISE EXCEPTION 'P2-71 cross-user submit succeeded'; END IF;
  v_failed:=false;
  BEGIN PERFORM public.finalize_exam_prep_session_safe_v1(v_session,'p271-cross-user-final-0001');
  EXCEPTION WHEN OTHERS THEN IF position('exam_prep_session_not_found' in SQLERRM)=0 THEN RAISE; END IF; v_failed:=true; END;
  IF NOT v_failed THEN RAISE EXCEPTION 'P2-71 cross-user finalize succeeded'; END IF;
END
$$;

-- Simulated network/kill-switch interruption must preserve resumable state.
UPDATE private.exam_prep_feature_config SET kill_switch=true,updated_at=now() WHERE id=1;
DO $$
DECLARE v_a uuid; v_session uuid; v_failed boolean;
BEGIN
  SELECT user_a,p1_session INTO v_a,v_session FROM p271_fixture;
  PERFORM set_config('request.jwt.claim.sub',v_a::text,true);
  v_failed:=false;
  BEGIN PERFORM public.get_exam_prep_session_safe_v1(v_session,'en');
  EXCEPTION WHEN OTHERS THEN IF position('exam_prep_core_unavailable' in SQLERRM)=0 THEN RAISE; END IF; v_failed:=true; END;
  IF NOT v_failed THEN RAISE EXCEPTION 'P2-71 kill-switch did not stop learner RPC'; END IF;
  IF (SELECT status FROM private.exam_prep_sessions WHERE id=v_session)<>'active' THEN
    RAISE EXCEPTION 'P2-71 interruption corrupted active session';
  END IF;
END
$$;
UPDATE private.exam_prep_feature_config SET kill_switch=false,updated_at=now() WHERE id=1;

DO $$
DECLARE
  v_a uuid; v_session uuid; v_payload jsonb; v_final jsonb; v_resp uuid; v_replay jsonb; v_failed boolean; v_count int;
BEGIN
  SELECT user_a,p1_session,first_p1_response INTO v_a,v_session,v_resp FROM p271_fixture;
  PERFORM set_config('request.jwt.claim.sub',v_a::text,true);
  v_payload:=public.get_exam_prep_session_safe_v1(v_session,'en');
  IF v_payload->>'status'<>'active' THEN RAISE EXCEPTION 'P2-71 reconnect did not recover active session'; END IF;

  v_final:=pg_temp.p271_finish_non_timed_v1(v_a,v_session,'p271-p1-complete');
  IF v_final->>'status'<>'finalized' OR coalesce((v_final->>'replayed')::boolean,true) THEN
    RAISE EXCEPTION 'P2-71 first finalization wrong: %',v_final;
  END IF;
  SELECT count(*) INTO v_count FROM private.exam_prep_responses WHERE session_id=v_session;
  v_final:=public.finalize_exam_prep_session_safe_v1(v_session,'p271-stale-final-key-9999');
  IF v_final->>'status'<>'finalized' OR coalesce((v_final->>'replayed')::boolean,false) IS NOT TRUE
     OR (SELECT count(*) FROM private.exam_prep_responses WHERE session_id=v_session)<>v_count THEN
    RAISE EXCEPTION 'P2-71 duplicate/stale finalize mutated finalized state';
  END IF;

  v_replay:=public.submit_exam_prep_response_safe_v1(
    v_session,(SELECT first_p1_item FROM p271_fixture),'{"answer":"network-retry-body"}'::jsonb,
    (SELECT first_p1_key FROM p271_fixture),123456,'uz'
  );
  IF (v_replay->>'response_id')::uuid<>v_resp OR coalesce((v_replay->>'replayed')::boolean,false) IS NOT TRUE THEN
    RAISE EXCEPTION 'P2-71 post-finalize offline replay failed';
  END IF;

  v_failed:=false;
  BEGIN PERFORM public.submit_exam_prep_response_safe_v1(
    v_session,(SELECT first_p1_item FROM p271_fixture),'{"answer":"A"}'::jsonb,
    'p271-post-final-new-action-0001',1000,'en'
  ); EXCEPTION WHEN OTHERS THEN IF position('exam_prep_session_not_active' in SQLERRM)=0 THEN RAISE; END IF; v_failed:=true; END;
  IF NOT v_failed THEN RAISE EXCEPTION 'P2-71 new response accepted after finalization'; END IF;
END
$$;

-- Abandon/retry and P1/P5 firewall.
DO $$
DECLARE
  v_a uuid; v_p1 bigint; v_p5 bigint; v_abandoned uuid; v_retake uuid; v_p5_session uuid;
  v_bad_auth uuid; v_failed boolean; v_item smallint; v_answer text; v_before_p1 int;
BEGIN
  SELECT user_a,p1_learning,p5_learning INTO v_a,v_p1,v_p5 FROM p271_fixture;
  v_abandoned:=pg_temp.p271_issue_and_start_v1(v_a,v_p1,'P1','learning','p271-abandon-start-0001');
  UPDATE private.exam_prep_sessions SET status='abandoned',last_activity_at=now() WHERE id=v_abandoned;
  PERFORM set_config('request.jwt.claim.sub',v_a::text,true);

  v_failed:=false;
  BEGIN PERFORM public.finalize_exam_prep_session_safe_v1(v_abandoned,'p271-abandon-final-0001');
  EXCEPTION WHEN OTHERS THEN IF position('exam_prep_session_abandoned' in SQLERRM)=0 THEN RAISE; END IF; v_failed:=true; END;
  IF NOT v_failed THEN RAISE EXCEPTION 'P2-71 abandoned session finalized'; END IF;

  SELECT si.item_order,q.correct_answer INTO v_item,v_answer
  FROM private.exam_prep_session_items si JOIN public.questions q ON q.id=si.question_id
  WHERE si.session_id=v_abandoned AND si.item_kind='question' ORDER BY si.item_order LIMIT 1;
  v_failed:=false;
  BEGIN PERFORM public.submit_exam_prep_response_safe_v1(v_abandoned,v_item,jsonb_build_object('answer',v_answer),'p271-abandon-submit-0001',1000,'en');
  EXCEPTION WHEN OTHERS THEN IF position('exam_prep_session_not_active' in SQLERRM)=0 THEN RAISE; END IF; v_failed:=true; END;
  IF NOT v_failed THEN RAISE EXCEPTION 'P2-71 abandoned session accepted response'; END IF;

  v_retake:=pg_temp.p271_issue_and_start_v1(v_a,v_p1,'P1','learning','p271-retake-start-0001');
  IF v_retake=v_abandoned OR (SELECT status FROM private.exam_prep_sessions WHERE id=v_retake)<>'active' THEN
    RAISE EXCEPTION 'P2-71 fresh retake after abandon failed';
  END IF;

  INSERT INTO private.exam_prep_session_authorizations(
    user_id,assessment_id,component_code,purpose,status,valid_until,reason,academic_credit
  ) VALUES(v_a,v_p1,'P5','learning','issued',now()+interval '1 hour','P2-71 forged component auth',true)
  RETURNING id INTO v_bad_auth;
  v_failed:=false;
  BEGIN PERFORM public.start_exam_prep_session_safe_v1(v_bad_auth,'p271-forged-scope-start-0001');
  EXCEPTION WHEN OTHERS THEN IF position('exam_prep_authorization_scope_mismatch' in SQLERRM)=0 THEN RAISE; END IF; v_failed:=true; END;
  IF NOT v_failed THEN RAISE EXCEPTION 'P2-71 forged P1->P5 authorization succeeded'; END IF;

  v_p5_session:=pg_temp.p271_issue_and_start_v1(v_a,v_p5,'P5','learning','p271-p5-start-0001');
  SELECT si.item_order,q.correct_answer INTO v_item,v_answer
  FROM private.exam_prep_session_items si JOIN public.questions q ON q.id=si.question_id
  WHERE si.session_id=v_p5_session AND si.item_kind='question' ORDER BY si.item_order LIMIT 1;
  SELECT count(*) INTO v_before_p1 FROM private.exam_prep_evidence_events WHERE user_id=v_a AND component_code='P1';
  PERFORM public.submit_exam_prep_response_safe_v1(v_p5_session,v_item,jsonb_build_object('answer',v_answer),'p271-p5-answer-0001',1000,'en');
  IF (SELECT count(*) FROM private.exam_prep_evidence_events WHERE user_id=v_a AND component_code='P1')<>v_before_p1 THEN
    RAISE EXCEPTION 'P2-71 P5 response changed P1 evidence';
  END IF;
  IF EXISTS(
    SELECT 1 FROM private.exam_prep_evidence_events e
    JOIN private.exam_prep_sessions s ON s.id=e.session_id
    WHERE e.user_id=v_a AND e.session_id IN (v_p5_session,(SELECT p1_session FROM p271_fixture))
      AND e.component_code<>s.component_code
  ) THEN RAISE EXCEPTION 'P2-71 cross-component evidence leakage'; END IF;

  UPDATE p271_fixture SET abandoned_session=v_abandoned,retake_session=v_retake,p5_session=v_p5_session WHERE user_a=v_a;
END
$$;

-- Protected machine assessment: the learner may see their selected answer, but
-- never correctness, answer key or feedback/explanation while the attempt is active.
DO $$
DECLARE
  v_a uuid; v_ass bigint; v_component text; v_session uuid; v_item smallint; v_answer text;
  v_submit jsonb; v_state jsonb;
BEGIN
  SELECT f.user_a,f.protected_diagnostic,a.component_code
  INTO v_a,v_ass,v_component
  FROM p271_fixture f JOIN private.exam_prep_assessments a ON a.id=f.protected_diagnostic;
  v_session:=pg_temp.p271_issue_and_start_v1(v_a,v_ass,v_component,'diagnostic','p271-protected-diag-start-0001');
  SELECT si.item_order,q.correct_answer INTO v_item,v_answer
  FROM private.exam_prep_session_items si JOIN public.questions q ON q.id=si.question_id
  WHERE si.session_id=v_session AND si.item_kind='question' ORDER BY si.item_order LIMIT 1;
  IF v_item IS NULL THEN RAISE EXCEPTION 'P2-71 protected diagnostic machine item missing'; END IF;

  v_submit:=public.submit_exam_prep_response_safe_v1(
    v_session,v_item,jsonb_build_object('answer',v_answer),'p271-protected-diag-answer-0001',1000,'en'
  );
  IF v_submit ? 'is_correct' OR v_submit ? 'explanation' OR v_submit ? 'diagnostic_feedback' OR v_submit ? 'next_action' THEN
    RAISE EXCEPTION 'P2-71 protected active submit leaked correctness/feedback: %',v_submit;
  END IF;
  IF coalesce((v_submit->>'feedback_deferred')::boolean,false) IS NOT TRUE THEN
    RAISE EXCEPTION 'P2-71 protected active submit did not declare deferred feedback';
  END IF;

  v_state:=public.get_exam_prep_session_safe_v1(v_session,'en');
  IF EXISTS(
    SELECT 1 FROM jsonb_array_elements(v_state->'items') x
    WHERE x ? 'correct_answer' OR x ? 'explanation' OR x ? 'is_correct'
  ) THEN RAISE EXCEPTION 'P2-71 protected active projection leaked answer/correctness: %',v_state; END IF;
  UPDATE p271_fixture SET diagnostic_session=v_session WHERE user_a=v_a;
END
$$;

-- Timed/full-paper failure paths. Current governed timed content is written work,
-- so the protected secret is the rubric/self-review plus any correctness fields.
DO $$
DECLARE
  v_a uuid; v_timed bigint; v_component text; v_purpose text; v_session uuid; v_state jsonb;
  v_item smallint; v_submit jsonb; v_failed boolean; v_evt jsonb; v_final jsonb; v_review jsonb;
  v_deadline timestamptz; v_limit int; v_marks int;
BEGIN
  SELECT f.user_a,f.p1_timed,a.component_code,a.assessment_type
  INTO v_a,v_timed,v_component,v_purpose
  FROM p271_fixture f JOIN private.exam_prep_assessments a ON a.id=f.p1_timed;
  v_session:=pg_temp.p271_issue_and_start_v1(v_a,v_timed,v_component,v_purpose,'p271-timed-start-0001');

  SELECT nullif(timing_contract->>'deadline_at','')::timestamptz,
         nullif(timing_contract->>'time_limit_sec','')::int,
         nullif(timing_contract->>'marks_available','')::int
  INTO v_deadline,v_limit,v_marks FROM private.exam_prep_sessions WHERE id=v_session;
  IF v_deadline IS NULL OR v_limit IS NULL OR v_limit<=0 OR v_marks IS NULL OR v_marks<=0 OR v_deadline<=now() THEN
    RAISE EXCEPTION 'P2-71 timed server snapshot incomplete deadline=% limit=% marks=%',v_deadline,v_limit,v_marks;
  END IF;

  v_state:=public.get_exam_prep_session_safe_v1(v_session,'en');
  IF EXISTS(
    SELECT 1 FROM jsonb_array_elements(v_state->'items') x
    WHERE x ? 'correct_answer' OR x ? 'explanation' OR x ? 'is_correct' OR x ? 'rubric' OR x ? 'self_review'
  ) THEN RAISE EXCEPTION 'P2-71 active timed projection leaked protected material: %',v_state; END IF;

  v_failed:=false;
  BEGIN PERFORM public.get_exam_prep_timed_review_pack_safe_v1(v_session,'en');
  EXCEPTION WHEN OTHERS THEN IF position('exam_prep_review_pack_requires_finalized_attempt' in SQLERRM)=0 THEN RAISE; END IF; v_failed:=true; END;
  IF NOT v_failed THEN RAISE EXCEPTION 'P2-71 active timed review pack exposed'; END IF;

  SELECT si.item_order INTO v_item FROM private.exam_prep_session_items si
  WHERE si.session_id=v_session AND si.item_kind='written' ORDER BY si.item_order LIMIT 1;
  IF v_item IS NULL THEN RAISE EXCEPTION 'P2-71 timed written item missing'; END IF;
  v_submit:=public.submit_exam_prep_response_safe_v1(
    v_session,v_item,jsonb_build_object('artifact',jsonb_build_object('working','P2-71 timed working')),
    'p271-timed-written-0001',1000,'en'
  );
  IF v_submit ? 'is_correct' OR v_submit ? 'explanation' OR v_submit ? 'diagnostic_feedback' OR v_submit ? 'next_action' THEN
    RAISE EXCEPTION 'P2-71 active timed submit leaked protected evaluation: %',v_submit;
  END IF;

  v_state:=public.get_exam_prep_session_safe_v1(v_session,'en');
  IF EXISTS(
    SELECT 1 FROM jsonb_array_elements(v_state->'items') x
    WHERE x ? 'correct_answer' OR x ? 'explanation' OR x ? 'is_correct' OR x ? 'rubric' OR x ? 'self_review'
  ) THEN RAISE EXCEPTION 'P2-71 timed refresh leaked protected material'; END IF;

  v_failed:=false;
  BEGIN PERFORM public.finalize_exam_prep_timed_safe_v1(v_session,'p271-timed-early-expire-0001','time_expired');
  EXCEPTION WHEN OTHERS THEN IF position('exam_prep_timer_not_expired' in SQLERRM)=0 THEN RAISE; END IF; v_failed:=true; END;
  IF NOT v_failed THEN RAISE EXCEPTION 'P2-71 early timer-expired finalization succeeded'; END IF;

  v_evt:=public.record_exam_prep_integrity_event_safe_v1(v_session,'visibility_hidden','p271-integrity-0001');
  IF v_evt->>'status'<>'warning' OR coalesce((v_evt->>'event_count')::int,0)<>1 THEN RAISE EXCEPTION 'P2-71 first integrity event wrong: %',v_evt; END IF;
  v_evt:=public.record_exam_prep_integrity_event_safe_v1(v_session,'visibility_hidden','p271-integrity-0001');
  IF coalesce((v_evt->>'replayed')::boolean,false) IS NOT TRUE OR coalesce((v_evt->>'event_count')::int,0)<>1 THEN
    RAISE EXCEPTION 'P2-71 integrity-event idempotency failed: %',v_evt;
  END IF;
  v_evt:=public.record_exam_prep_integrity_event_safe_v1(v_session,'window_blur','p271-integrity-0002');
  IF v_evt->>'status'<>'review_required' OR coalesce((v_evt->>'integrity_allows_comparability')::boolean,true) THEN
    RAISE EXCEPTION 'P2-71 repeated focus/visibility exit did not block comparability: %',v_evt;
  END IF;

  -- Internal isolated-test clock acceleration. Authenticated learners have no
  -- direct UPDATE privilege on this row (asserted above).
  UPDATE private.exam_prep_sessions
  SET timing_contract=jsonb_set(timing_contract,'{deadline_at}',to_jsonb((clock_timestamp()-interval '1 second')::text),true)
  WHERE id=v_session;

  PERFORM set_config('request.jwt.claim.sub',v_a::text,true);
  v_final:=public.finalize_exam_prep_timed_safe_v1(v_session,'p271-timed-final-0001','time_expired');
  IF v_final->>'completion_reason'<>'time_expired'
     OR (SELECT status FROM private.exam_prep_sessions WHERE id=v_session)<>'finalized' THEN
    RAISE EXCEPTION 'P2-71 timer-expiry finalization failed: %',v_final;
  END IF;
  IF coalesce((v_final->>'score_comparable')::boolean,true)
     OR coalesce((v_final->>'integrity_review_required')::boolean,false) IS NOT TRUE THEN
    RAISE EXCEPTION 'P2-71 integrity violation did not survive finalization: %',v_final;
  END IF;

  v_final:=public.finalize_exam_prep_timed_safe_v1(v_session,'p271-timed-stale-final-9999','time_expired');
  IF coalesce((v_final->>'replayed')::boolean,false) IS NOT TRUE THEN
    RAISE EXCEPTION 'P2-71 duplicate timed finalize was not replay-safe';
  END IF;

  v_review:=public.get_exam_prep_timed_review_pack_safe_v1(v_session,'en');
  IF v_review->>'status'<>'finalized' OR jsonb_array_length(v_review->'items')<1 THEN
    RAISE EXCEPTION 'P2-71 finalized timed review pack unavailable: %',v_review;
  END IF;
  UPDATE p271_fixture SET timed_session=v_session WHERE user_a=v_a;
END
$$;

-- Final ownership/component consistency before rollback.
DO $$
DECLARE v_a uuid; v_b uuid; v_p1 uuid; v_p5 uuid; v_diag uuid; v_timed uuid;
BEGIN
  SELECT user_a,user_b,p1_session,p5_session,diagnostic_session,timed_session
  INTO v_a,v_b,v_p1,v_p5,v_diag,v_timed FROM p271_fixture;
  IF EXISTS(
    SELECT 1 FROM private.exam_prep_evidence_events e
    JOIN private.exam_prep_sessions s ON s.id=e.session_id
    WHERE e.user_id IN (v_a,v_b) AND e.component_code<>s.component_code
  ) THEN RAISE EXCEPTION 'P2-71 final audit found cross-component evidence'; END IF;
  IF EXISTS(
    SELECT 1 FROM private.exam_prep_responses r JOIN private.exam_prep_sessions s ON s.id=r.session_id
    WHERE r.user_id IN (v_a,v_b) AND r.user_id<>s.user_id
  ) THEN RAISE EXCEPTION 'P2-71 final audit found cross-user response ownership'; END IF;
  IF EXISTS(
    SELECT 1 FROM private.exam_prep_evidence_events e JOIN private.exam_prep_sessions s ON s.id=e.session_id
    WHERE e.user_id IN (v_a,v_b) AND e.user_id<>s.user_id
  ) THEN RAISE EXCEPTION 'P2-71 final audit found cross-user evidence ownership'; END IF;
  IF (SELECT status FROM private.exam_prep_sessions WHERE id=v_p1)<>'finalized'
     OR (SELECT status FROM private.exam_prep_sessions WHERE id=v_p5)<>'active'
     OR (SELECT status FROM private.exam_prep_sessions WHERE id=v_diag)<>'active'
     OR (SELECT status FROM private.exam_prep_sessions WHERE id=v_timed)<>'finalized' THEN
    RAISE EXCEPTION 'P2-71 terminal session states inconsistent';
  END IF;
END
$$;

ROLLBACK;

DO $$
DECLARE v_count int;
BEGIN
  SELECT count(*) INTO v_count FROM auth.users WHERE email LIKE 'p271-%@invalid.example';
  IF v_count<>0 THEN RAISE EXCEPTION 'P2-71 rollback left synthetic auth users=%',v_count; END IF;
  SELECT count(*) INTO v_count FROM public.users WHERE first_name='P271' AND last_name IN ('AdversaryA','AdversaryB');
  IF v_count<>0 THEN RAISE EXCEPTION 'P2-71 rollback left synthetic public users=%',v_count; END IF;
END
$$;

\echo 'P2-71 failure and adversarial campaign matrix: GREEN'
