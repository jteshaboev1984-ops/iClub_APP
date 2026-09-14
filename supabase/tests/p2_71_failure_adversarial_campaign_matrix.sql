\set ON_ERROR_STOP on

DO $$
BEGIN
  IF current_setting('p271.isolated_db', true) IS DISTINCT FROM 'true' THEN
    RAISE EXCEPTION 'P2-71 REFUSED: isolated test database required';
  END IF;
END
$$;

BEGIN;

-- P2-71 actively attacks the learner-safe Exam Prep state/security boundaries.
-- Every mutation is synthetic and ends in ROLLBACK.
DO $$
BEGIN
  IF has_table_privilege('authenticated','public.questions','SELECT') THEN
    RAISE EXCEPTION 'P2-71 answer-key boundary failed: authenticated can SELECT public.questions';
  END IF;
  IF has_table_privilege('authenticated','private.exam_prep_sessions','SELECT')
     OR has_table_privilege('authenticated','private.exam_prep_responses','SELECT')
     OR has_table_privilege('authenticated','private.exam_prep_evidence_events','SELECT')
     OR has_table_privilege('authenticated','private.exam_prep_session_items','SELECT') THEN
    RAISE EXCEPTION 'P2-71 private session/evidence tables are directly readable by authenticated';
  END IF;
  IF has_table_privilege('authenticated','private.exam_prep_sessions','UPDATE')
     OR has_table_privilege('authenticated','private.exam_prep_responses','INSERT')
     OR has_table_privilege('authenticated','private.exam_prep_evidence_events','INSERT') THEN
    RAISE EXCEPTION 'P2-71 private session/evidence tables are directly writable by authenticated';
  END IF;
  IF has_function_privilege('anon','public.start_exam_prep_session_safe_v1(uuid,text)','EXECUTE')
     OR has_function_privilege('anon','public.submit_exam_prep_response_safe_v1(uuid,integer,jsonb,text,integer,text)','EXECUTE')
     OR has_function_privilege('anon','public.finalize_exam_prep_session_safe_v1(uuid,text)','EXECUTE') THEN
    RAISE EXCEPTION 'P2-71 anon can execute authenticated learner session RPC';
  END IF;
END
$$;

CREATE TEMP TABLE p271_fixture(
  user_a uuid primary key,
  user_b uuid not null,
  p1_learning bigint not null,
  p5_learning bigint not null,
  p1_timed bigint not null,
  p1_session uuid,
  p5_session uuid,
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
  v_final jsonb;
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

  v_final:=public.finalize_exam_prep_session_safe_v1(p_session_id,p_prefix||'-final');
  RETURN v_final;
END
$$;

DO $$
DECLARE
  v_a uuid:=gen_random_uuid();
  v_b uuid:=gen_random_uuid();
  v_program bigint;
  v_p1 bigint;
  v_p5 bigint;
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

  SELECT a.id INTO v_timed
  FROM private.exam_prep_assessments a
  JOIN private.exam_prep_timed_assessment_contracts tc ON tc.assessment_id=a.id AND tc.status='published'
  WHERE a.component_code='P1' AND a.assessment_type IN ('timed','paper') AND a.status='published'
    AND EXISTS(SELECT 1 FROM private.exam_prep_assessment_items ai WHERE ai.assessment_id=a.id AND ai.question_id IS NOT NULL)
  ORDER BY CASE WHEN a.assessment_type='timed' THEN 0 ELSE 1 END,a.id LIMIT 1;

  IF v_p1 IS NULL OR v_p5 IS NULL OR v_timed IS NULL THEN
    RAISE EXCEPTION 'P2-71 published P1/P5 learning + P1 timed fixtures required';
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

  INSERT INTO p271_fixture(user_a,user_b,p1_learning,p5_learning,p1_timed)
  VALUES(v_a,v_b,v_p1,v_p5,v_timed);
END
$$;

UPDATE private.exam_prep_feature_config
SET rollout_state='controlled_beta',core_enabled=true,ai_enabled=false,mentor_enabled=false,kill_switch=false,updated_at=now()
WHERE id=1;

-- Unauthorized / malformed RPCs fail closed.
DO $$
DECLARE
  v_a uuid;
  v_p1 bigint;
  v_auth uuid;
  v_failed boolean;
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
  ) VALUES(v_a,v_p1,'P1','learning','issued',now()+interval '1 hour','P2-71 malformed payload fixture',true)
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

-- Start/reconnect/refresh/idempotency and stale-action campaign on P1.
DO $$
DECLARE
  v_a uuid;
  v_p1 bigint;
  v_p5 bigint;
  v_auth uuid;
  v_p5_auth uuid;
  v_session uuid;
  v_start jsonb;
  v_refresh jsonb;
  v_item smallint;
  v_answer text;
  v_submit jsonb;
  v_replay jsonb;
  v_resp uuid;
  v_responses_before int;
  v_evidence_before int;
  v_failed boolean;
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

  -- Simulate refresh/reconnect: same authorization + same key must return the exact active session.
  v_start:=public.start_exam_prep_session_safe_v1(v_auth,'p271-p1-start-0001');
  IF (v_start->>'session_id')::uuid<>v_session OR coalesce((v_start->>'resumed')::boolean,false) IS NOT TRUE THEN
    RAISE EXCEPTION 'P2-71 start retry did not resume the same session: %',v_start;
  END IF;
  v_refresh:=public.get_exam_prep_session_safe_v1(v_session,'en');
  IF v_refresh->>'status'<>'active' THEN RAISE EXCEPTION 'P2-71 refresh/reconnect lost active state: %',v_refresh; END IF;

  -- A stale start key cannot be rebound to a different authorization/component.
  INSERT INTO private.exam_prep_session_authorizations(
    user_id,assessment_id,component_code,purpose,status,valid_until,reason,academic_credit
  ) VALUES(v_a,v_p5,'P5','learning','issued',now()+interval '1 hour','P2-71 stale-start conflict',true)
  RETURNING id INTO v_p5_auth;
  v_failed:=false;
  BEGIN
    PERFORM public.start_exam_prep_session_safe_v1(v_p5_auth,'p271-p1-start-0001');
  EXCEPTION WHEN OTHERS THEN
    IF position('exam_prep_idempotency_conflict' in SQLERRM)=0 THEN RAISE; END IF;
    v_failed:=true;
  END;
  IF NOT v_failed THEN RAISE EXCEPTION 'P2-71 stale start key rebound to another authorization'; END IF;

  SELECT si.item_order,q.correct_answer INTO v_item,v_answer
  FROM private.exam_prep_session_items si
  JOIN public.questions q ON q.id=si.question_id
  WHERE si.session_id=v_session AND si.item_kind='question'
  ORDER BY si.item_order LIMIT 1;
  IF v_item IS NULL THEN RAISE EXCEPTION 'P2-71 P1 question fixture missing'; END IF;

  -- Malformed/server-owned fields must never be accepted from the client.
  v_failed:=false;
  BEGIN
    PERFORM public.submit_exam_prep_response_safe_v1(
      v_session,v_item,jsonb_build_object('answer',v_answer,'is_correct',true),
      'p271-forged-server-field-0001',1000,'en'
    );
  EXCEPTION WHEN OTHERS THEN
    IF position('exam_prep_server_owned_field_rejected' in SQLERRM)=0 THEN RAISE; END IF;
    v_failed:=true;
  END;
  IF NOT v_failed THEN RAISE EXCEPTION 'P2-71 client forged server-owned correctness'; END IF;

  v_submit:=public.submit_exam_prep_response_safe_v1(
    v_session,v_item,jsonb_build_object('answer',v_answer),
    'p271-p1-answer-0001',1000,'en'
  );
  v_resp:=(v_submit->>'response_id')::uuid;
  IF v_resp IS NULL OR coalesce((v_submit->>'replayed')::boolean,true) THEN
    RAISE EXCEPTION 'P2-71 first response submission wrong: %',v_submit;
  END IF;

  SELECT count(*) INTO v_responses_before FROM private.exam_prep_responses WHERE session_id=v_session;
  SELECT count(*) INTO v_evidence_before FROM private.exam_prep_evidence_events WHERE session_id=v_session;

  v_replay:=public.submit_exam_prep_response_safe_v1(
    v_session,v_item,jsonb_build_object('answer','adversarial-different-body'),
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
  BEGIN
    PERFORM public.submit_exam_prep_response_safe_v1(
      v_session,v_item,jsonb_build_object('answer',v_answer),
      'p271-p1-answer-stale-0002',1000,'en'
    );
  EXCEPTION WHEN OTHERS THEN
    IF position('exam_prep_item_already_answered' in SQLERRM)=0 THEN RAISE; END IF;
    v_failed:=true;
  END;
  IF NOT v_failed THEN RAISE EXCEPTION 'P2-71 same item accepted a second idempotency key'; END IF;

  UPDATE p271_fixture
  SET p1_session=v_session,first_p1_item=v_item,first_p1_key='p271-p1-answer-0001',first_p1_response=v_resp
  WHERE user_a=v_a;
END
$$;

-- Cross-user isolation: another entitled learner must see the session as nonexistent.
DO $$
DECLARE
  v_a uuid; v_b uuid; v_session uuid; v_item smallint; v_failed boolean;
BEGIN
  SELECT user_a,user_b,p1_session,first_p1_item INTO v_a,v_b,v_session,v_item FROM p271_fixture;
  PERFORM set_config('request.jwt.claim.sub',v_b::text,true);
  PERFORM set_config('request.jwt.claim.role','authenticated',true);

  v_failed:=false;
  BEGIN PERFORM public.get_exam_prep_session_safe_v1(v_session,'en');
  EXCEPTION WHEN OTHERS THEN IF position('exam_prep_session_not_found' in SQLERRM)=0 THEN RAISE; END IF; v_failed:=true; END;
  IF NOT v_failed THEN RAISE EXCEPTION 'P2-71 cross-user session read succeeded'; END IF;

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

-- Kill-switch/offline interruption must not corrupt the active session; reconnect resumes it.
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
    RAISE EXCEPTION 'P2-71 interrupted flow mutated active session state';
  END IF;
END
$$;
UPDATE private.exam_prep_feature_config SET kill_switch=false,updated_at=now() WHERE id=1;

DO $$
DECLARE v_a uuid; v_session uuid; v_payload jsonb; v_final1 jsonb; v_final2 jsonb; v_resp uuid; v_replay jsonb; v_failed boolean; v_count int;
BEGIN
  SELECT user_a,p1_session,first_p1_response INTO v_a,v_session,v_resp FROM p271_fixture;
  PERFORM set_config('request.jwt.claim.sub',v_a::text,true);
  v_payload:=public.get_exam_prep_session_safe_v1(v_session,'en');
  IF v_payload->>'status'<>'active' THEN RAISE EXCEPTION 'P2-71 reconnect did not recover active session'; END IF;

  v_final1:=pg_temp.p271_finish_non_timed_v1(v_a,v_session,'p271-p1-complete');
  IF v_final1->>'status'<>'finalized' OR coalesce((v_final1->>'replayed')::boolean,true) THEN
    RAISE EXCEPTION 'P2-71 first finalization wrong: %',v_final1;
  END IF;
  SELECT count(*) INTO v_count FROM private.exam_prep_responses WHERE session_id=v_session;

  v_final2:=public.finalize_exam_prep_session_safe_v1(v_session,'p271-p1-complete-final');
  IF v_final2->>'status'<>'finalized' OR coalesce((v_final2->>'replayed')::boolean,false) IS NOT TRUE THEN
    RAISE EXCEPTION 'P2-71 duplicate finalize was not replay-safe: %',v_final2;
  END IF;
  -- A stale/different finalize key is also read-only after commit: no second finalization/state mutation.
  v_final2:=public.finalize_exam_prep_session_safe_v1(v_session,'p271-stale-final-key-9999');
  IF v_final2->>'status'<>'finalized' OR (SELECT count(*) FROM private.exam_prep_responses WHERE session_id=v_session)<>v_count THEN
    RAISE EXCEPTION 'P2-71 stale finalize action mutated finalized state';
  END IF;

  -- Delayed/offline replay of an already committed response still works after finalization.
  v_replay:=public.submit_exam_prep_response_safe_v1(
    v_session,(SELECT first_p1_item FROM p271_fixture),'{"answer":"network-retry-body"}'::jsonb,
    (SELECT first_p1_key FROM p271_fixture),123456,'uz'
  );
  IF (v_replay->>'response_id')::uuid<>v_resp OR coalesce((v_replay->>'replayed')::boolean,false) IS NOT TRUE THEN
    RAISE EXCEPTION 'P2-71 post-finalize offline replay failed: %',v_replay;
  END IF;

  v_failed:=false;
  BEGIN
    PERFORM public.submit_exam_prep_response_safe_v1(
      v_session,(SELECT first_p1_item FROM p271_fixture),'{"answer":"A"}'::jsonb,
      'p271-post-final-new-action-0001',1000,'en'
    );
  EXCEPTION WHEN OTHERS THEN
    IF position('exam_prep_session_not_active' in SQLERRM)=0 THEN RAISE; END IF;
    v_failed:=true;
  END;
  IF NOT v_failed THEN RAISE EXCEPTION 'P2-71 new response was accepted after finalization'; END IF;
END
$$;

-- Abandon/retry boundary and P1<->P5 scope firewall.
DO $$
DECLARE
  v_a uuid; v_p1 bigint; v_p5 bigint; v_abandoned uuid; v_retake uuid; v_p5_session uuid;
  v_bad_auth uuid; v_failed boolean; v_item smallint; v_answer text; v_before_other int;
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
  IF NOT v_failed THEN RAISE EXCEPTION 'P2-71 abandoned session accepted new response'; END IF;

  -- A new authorization/key can recover after an abandoned attempt without reviving it.
  v_retake:=pg_temp.p271_issue_and_start_v1(v_a,v_p1,'P1','learning','p271-retake-start-0001');
  IF v_retake=v_abandoned OR (SELECT status FROM private.exam_prep_sessions WHERE id=v_retake)<>'active' THEN
    RAISE EXCEPTION 'P2-71 legitimate retake did not create a fresh active session';
  END IF;

  -- Deliberately malformed component authorization must fail closed.
  INSERT INTO private.exam_prep_session_authorizations(
    user_id,assessment_id,component_code,purpose,status,valid_until,reason,academic_credit
  ) VALUES(v_a,v_p1,'P5','learning','issued',now()+interval '1 hour','P2-71 cross-component forged auth',true)
  RETURNING id INTO v_bad_auth;
  v_failed:=false;
  BEGIN PERFORM public.start_exam_prep_session_safe_v1(v_bad_auth,'p271-forged-scope-start-0001');
  EXCEPTION WHEN OTHERS THEN IF position('exam_prep_authorization_scope_mismatch' in SQLERRM)=0 THEN RAISE; END IF; v_failed:=true; END;
  IF NOT v_failed THEN RAISE EXCEPTION 'P2-71 forged P1->P5 authorization scope succeeded'; END IF;

  v_p5_session:=pg_temp.p271_issue_and_start_v1(v_a,v_p5,'P5','learning','p271-p5-start-0001');
  SELECT si.item_order,q.correct_answer INTO v_item,v_answer
  FROM private.exam_prep_session_items si JOIN public.questions q ON q.id=si.question_id
  WHERE si.session_id=v_p5_session AND si.item_kind='question' ORDER BY si.item_order LIMIT 1;
  SELECT count(*) INTO v_before_other FROM private.exam_prep_evidence_events WHERE user_id=v_a AND component_code='P1';
  PERFORM public.submit_exam_prep_response_safe_v1(v_p5_session,v_item,jsonb_build_object('answer',v_answer),'p271-p5-answer-0001',1000,'en');
  IF (SELECT count(*) FROM private.exam_prep_evidence_events WHERE user_id=v_a AND component_code='P1')<>v_before_other THEN
    RAISE EXCEPTION 'P2-71 P5 response changed P1 evidence';
  END IF;
  IF EXISTS(
    SELECT 1
    FROM private.exam_prep_evidence_events e
    JOIN private.exam_prep_sessions s ON s.id=e.session_id
    WHERE e.user_id=v_a AND e.session_id IN (v_p5_session,(SELECT p1_session FROM p271_fixture))
      AND e.component_code<>s.component_code
  ) THEN
    RAISE EXCEPTION 'P2-71 cross-component evidence leakage detected';
  END IF;

  UPDATE p271_fixture SET abandoned_session=v_abandoned,retake_session=v_retake,p5_session=v_p5_session WHERE user_a=v_a;
END
$$;

-- Protected timed attempt: answer/correctness firewall, real timer expiry, integrity events and retry safety.
DO $$
DECLARE
  v_a uuid; v_timed bigint; v_auth uuid; v_start jsonb; v_session uuid; v_state jsonb; v_submit jsonb;
  v_item smallint; v_answer text; v_failed boolean; v_evt jsonb; v_final jsonb; v_review jsonb;
  v_deadline timestamptz; v_limit int; v_marks int;
BEGIN
  SELECT user_a,p1_timed INTO v_a,v_timed FROM p271_fixture;
  INSERT INTO private.exam_prep_session_authorizations(
    user_id,assessment_id,component_code,purpose,status,valid_until,reason,academic_credit
  )
  SELECT v_a,a.id,a.component_code,a.assessment_type,'issued',now()+interval '1 hour','P2-71 protected timed fixture',true
  FROM private.exam_prep_assessments a WHERE a.id=v_timed
  RETURNING id INTO v_auth;

  PERFORM set_config('request.jwt.claim.sub',v_a::text,true);
  PERFORM set_config('request.jwt.claim.role','authenticated',true);
  v_start:=public.start_exam_prep_session_safe_v1(v_auth,'p271-timed-start-0001');
  v_session:=(v_start->>'session_id')::uuid;

  SELECT nullif(timing_contract->>'deadline_at','')::timestamptz,
         nullif(timing_contract->>'time_limit_sec','')::int,
         nullif(timing_contract->>'marks_available','')::int
  INTO v_deadline,v_limit,v_marks
  FROM private.exam_prep_sessions WHERE id=v_session;
  IF v_deadline IS NULL OR v_limit IS NULL OR v_limit<=0 OR v_marks IS NULL OR v_marks<=0 OR v_deadline<=now() THEN
    RAISE EXCEPTION 'P2-71 timed server snapshot incomplete: deadline=% limit=% marks=%',v_deadline,v_limit,v_marks;
  END IF;

  v_state:=public.get_exam_prep_session_safe_v1(v_session,'en');
  IF EXISTS(
    SELECT 1 FROM jsonb_array_elements(v_state->'items') x
    WHERE x ? 'correct_answer' OR x ? 'explanation' OR x ? 'is_correct' OR x ? 'selected_answer'
  ) THEN RAISE EXCEPTION 'P2-71 active timed projection leaked protected correctness/answer data: %',v_state; END IF;

  v_failed:=false;
  BEGIN PERFORM public.get_exam_prep_timed_review_pack_safe_v1(v_session,'en');
  EXCEPTION WHEN OTHERS THEN IF position('exam_prep_review_pack_requires_finalized_attempt' in SQLERRM)=0 THEN RAISE; END IF; v_failed:=true; END;
  IF NOT v_failed THEN RAISE EXCEPTION 'P2-71 active timed review pack was exposed'; END IF;

  SELECT si.item_order,q.correct_answer INTO v_item,v_answer
  FROM private.exam_prep_session_items si JOIN public.questions q ON q.id=si.question_id
  WHERE si.session_id=v_session AND si.item_kind='question' ORDER BY si.item_order LIMIT 1;
  IF v_item IS NULL THEN RAISE EXCEPTION 'P2-71 timed question fixture missing'; END IF;
  v_submit:=public.submit_exam_prep_response_safe_v1(v_session,v_item,jsonb_build_object('answer',v_answer),'p271-timed-answer-0001',1000,'en');
  IF v_submit ? 'is_correct' OR v_submit ? 'selected_answer' OR v_submit ? 'explanation' OR v_submit ? 'diagnostic_feedback' THEN
    RAISE EXCEPTION 'P2-71 active timed submit leaked correctness: %',v_submit;
  END IF;

  v_state:=public.get_exam_prep_session_safe_v1(v_session,'en');
  IF EXISTS(
    SELECT 1 FROM jsonb_array_elements(v_state->'items') x
    WHERE x ? 'correct_answer' OR x ? 'explanation' OR x ? 'is_correct' OR x ? 'selected_answer'
  ) THEN RAISE EXCEPTION 'P2-71 active timed refresh leaked correctness after answer'; END IF;

  -- A fake early time_expired action must be rejected.
  v_failed:=false;
  BEGIN PERFORM public.finalize_exam_prep_timed_safe_v1(v_session,'p271-timed-early-expire-0001','time_expired');
  EXCEPTION WHEN OTHERS THEN IF position('exam_prep_timer_not_expired' in SQLERRM)=0 THEN RAISE; END IF; v_failed:=true; END;
  IF NOT v_failed THEN RAISE EXCEPTION 'P2-71 early timer-expired finalization succeeded'; END IF;

  -- Focus/visibility events are idempotent and repeated exits require review without exposing answers.
  v_evt:=public.record_exam_prep_integrity_event_safe_v1(v_session,'visibility_hidden','p271-integrity-0001');
  IF v_evt->>'status'<>'warning' OR coalesce((v_evt->>'event_count')::int,0)<>1 THEN RAISE EXCEPTION 'P2-71 first integrity event wrong: %',v_evt; END IF;
  v_evt:=public.record_exam_prep_integrity_event_safe_v1(v_session,'visibility_hidden','p271-integrity-0001');
  IF coalesce((v_evt->>'replayed')::boolean,false) IS NOT TRUE OR coalesce((v_evt->>'event_count')::int,0)<>1 THEN
    RAISE EXCEPTION 'P2-71 integrity-event idempotency failed: %',v_evt;
  END IF;
  v_evt:=public.record_exam_prep_integrity_event_safe_v1(v_session,'window_blur','p271-integrity-0002');
  IF v_evt->>'status'<>'review_required' OR coalesce((v_evt->>'integrity_allows_comparability')::boolean,true) THEN
    RAISE EXCEPTION 'P2-71 repeated integrity exit did not block comparability: %',v_evt;
  END IF;

  -- Internal test-only clock acceleration: learner cannot update this private row, but lets CI exercise true expiry without waiting.
  UPDATE private.exam_prep_sessions
  SET timing_contract=jsonb_set(timing_contract,'{deadline_at}',to_jsonb((clock_timestamp()-interval '1 second')::text),true)
  WHERE id=v_session;

  PERFORM set_config('request.jwt.claim.sub',v_a::text,true);
  v_final:=public.finalize_exam_prep_timed_safe_v1(v_session,'p271-timed-final-0001','time_expired');
  IF v_final->>'completion_reason'<>'time_expired' OR v_final->>'status'<>'finalized' THEN
    RAISE EXCEPTION 'P2-71 real expiry finalization failed: %',v_final;
  END IF;
  IF coalesce((v_final->>'score_comparable')::boolean,true) OR coalesce((v_final->>'integrity_review_required')::boolean,false) IS NOT TRUE THEN
    RAISE EXCEPTION 'P2-71 integrity violation did not survive timed finalization: %',v_final;
  END IF;

  v_final:=public.finalize_exam_prep_timed_safe_v1(v_session,'p271-timed-final-stale-9999','time_expired');
  IF coalesce((v_final->>'replayed')::boolean,false) IS NOT TRUE THEN RAISE EXCEPTION 'P2-71 duplicate timed finalize not replay-safe: %',v_final; END IF;

  v_review:=public.get_exam_prep_timed_review_pack_safe_v1(v_session,'en');
  IF v_review->>'status'<>'finalized' THEN RAISE EXCEPTION 'P2-71 post-finalize review pack unavailable'; END IF;

  UPDATE p271_fixture SET timed_session=v_session WHERE user_a=v_a;
END
$$;

-- Final component/data-integrity assertions before rollback.
DO $$
DECLARE v_a uuid; v_b uuid; v_p1 uuid; v_p5 uuid; v_timed uuid;
BEGIN
  SELECT user_a,user_b,p1_session,p5_session,timed_session INTO v_a,v_b,v_p1,v_p5,v_timed FROM p271_fixture;
  IF EXISTS(
    SELECT 1 FROM private.exam_prep_evidence_events e
    JOIN private.exam_prep_sessions s ON s.id=e.session_id
    WHERE e.user_id IN (v_a,v_b) AND e.component_code<>s.component_code
  ) THEN RAISE EXCEPTION 'P2-71 final audit found cross-component evidence'; END IF;
  IF EXISTS(
    SELECT 1 FROM private.exam_prep_responses r
    JOIN private.exam_prep_sessions s ON s.id=r.session_id
    WHERE r.user_id IN (v_a,v_b) AND r.user_id<>s.user_id
  ) THEN RAISE EXCEPTION 'P2-71 final audit found cross-user response ownership'; END IF;
  IF EXISTS(
    SELECT 1 FROM private.exam_prep_evidence_events e
    JOIN private.exam_prep_sessions s ON s.id=e.session_id
    WHERE e.user_id IN (v_a,v_b) AND e.user_id<>s.user_id
  ) THEN RAISE EXCEPTION 'P2-71 final audit found cross-user evidence ownership'; END IF;
  IF (SELECT status FROM private.exam_prep_sessions WHERE id=v_p1)<>'finalized'
     OR (SELECT status FROM private.exam_prep_sessions WHERE id=v_p5)<>'active'
     OR (SELECT status FROM private.exam_prep_sessions WHERE id=v_timed)<>'finalized' THEN
    RAISE EXCEPTION 'P2-71 terminal session states are inconsistent';
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
