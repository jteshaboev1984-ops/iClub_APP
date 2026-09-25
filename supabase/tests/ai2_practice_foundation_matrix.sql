\set ON_ERROR_STOP on

BEGIN;

CREATE TEMP TABLE ai2_ids(
  user_id uuid not null,
  session_id bigint,
  attempt_id bigint,
  question_id bigint
) ON COMMIT DROP;

DO $$
DECLARE
  v_uid uuid:=gen_random_uuid();
  v_session bigint;
  v_attempt bigint;
  v_question bigint:=700001;
BEGIN
  INSERT INTO auth.users(id,aud,role,email,created_at,updated_at,is_sso_user,is_anonymous)
  VALUES(v_uid,'authenticated','authenticated','ai2-practice-'||replace(v_uid::text,'-','')||'@invalid.example',now(),now(),false,false);

  INSERT INTO public.users(id,first_name,last_name,language_code,created_at,must_change_password)
  VALUES(v_uid,'AI2','Practice Synthetic','en',now(),false);

  INSERT INTO public.questions(
    id,subject_id,topic,subtopic,difficulty,qtype,question_text,options_text,correct_answer,
    explanation,is_active,question_text_ru,question_text_uz,question_text_en,
    options_text_ru,options_text_uz,options_text_en,explanation_ru,explanation_uz,explanation_en,
    book_ref,time_limit_sec,quality_status
  ) VALUES(
    v_question,7,'Demand','Complements','medium','mcq','Synthetic safe question','A|B|C|D','B',
    'Private legacy explanation must not be exported by AI context.',true,
    'RU synthetic','UZ synthetic','EN synthetic','A|B|C|D','A|B|C|D','A|B|C|D',
    'RU private explanation','UZ private explanation','EN private explanation','AI2 fixture',60,'published'
  );

  INSERT INTO public.practice_sessions_v4(user_id,subject_id,pool_id,client_session_id,question_ids,status)
  VALUES(v_uid,7,1,'ai2-fixture-session',array[v_question],'in_progress')
  RETURNING id INTO v_session;

  INSERT INTO public.practice_session_answers_v4(
    session_id,question_id,user_answer,picked_index,is_correct,time_spent,answered_at
  ) VALUES(v_session,v_question,'A',0,false,22,now());

  INSERT INTO public.practice_attempts(user_id,subject_id,score,percent,time_seconds,is_lab)
  OVERRIDING SYSTEM VALUE
  VALUES(v_uid,7,0,0,22,false)
  RETURNING id INTO v_attempt;

  INSERT INTO public.practice_answers(attempt_id,question_id,user_answer,is_correct,time_spent)
  OVERRIDING SYSTEM VALUE
  VALUES(v_attempt,v_question,'A',false,22);

  INSERT INTO public.user_answer_diagnosis(
    user_id,subject_id,attempt_type,attempt_id,question_id,selected_answer,is_correct,
    mistake_type,weak_skill,feedback_en,next_action_en
  ) VALUES(
    v_uid,7,'practice',v_attempt,v_question,'A',false,
    'complement_relationship','Demand and complements',
    'Review how complementary goods affect demand.','Repeat the Demand practice.'
  );

  INSERT INTO ai2_ids VALUES(v_uid,v_session,v_attempt,v_question);
END
$$;

DO $$
BEGIN
  IF has_table_privilege('authenticated','private.practice_ai_policy','SELECT')
     OR has_table_privilege('authenticated','private.practice_ai_entitlements','SELECT')
     OR has_table_privilege('authenticated','private.practice_ai_source_cards','SELECT')
     OR has_table_privilege('authenticated','private.practice_ai_audit','SELECT')
     OR has_table_privilege('authenticated','private.practice_ai_daily_usage','SELECT') THEN
    RAISE EXCEPTION 'AI-2 private tables became browser-readable';
  END IF;

  IF has_function_privilege('authenticated','public.get_practice_ai_answer_context_service_v1(uuid,bigint,bigint,text)','EXECUTE')
     OR has_function_privilege('authenticated','public.get_practice_ai_result_context_service_v1(uuid,bigint,text)','EXECUTE')
     OR has_function_privilege('authenticated','public.get_practice_ai_source_cards_service_v1(text,text,text,bigint,text,text,integer)','EXECUTE')
     OR has_function_privilege('authenticated','public.record_practice_ai_audit_service_v1(uuid,uuid,text,text,text,jsonb,text,text,text,text,bigint,bigint,bigint,bigint,text,text[],text,text,integer,integer,integer,numeric,text,text[],text)','EXECUTE') THEN
    RAISE EXCEPTION 'AI-2 service-only RPC became browser-executable';
  END IF;
END
$$;

SELECT set_config('request.jwt.claim.sub',(SELECT user_id::text FROM ai2_ids LIMIT 1),true);
SELECT set_config('request.jwt.claim.role','authenticated',true);

SET LOCAL ROLE authenticated;
DO $$
DECLARE v jsonb;
BEGIN
  v:=public.get_practice_ai_guard_v1('post_answer_explanation','en',0);
  IF coalesce((v->>'allowed')::boolean,true) OR v->>'reason'<>'ai_disabled' THEN
    RAISE EXCEPTION 'AI-2 default-off guard failed: %',v;
  END IF;

  v:=public.get_practice_ai_guard_v1('change_score','en',0);
  IF coalesce((v->>'allowed')::boolean,true) OR v->>'reason'<>'interaction_not_allowed' THEN
    RAISE EXCEPTION 'AI-2 forbidden interaction escaped: %',v;
  END IF;

  v:=public.get_practice_ai_guard_v1('post_answer_explanation','xx',0);
  IF coalesce((v->>'allowed')::boolean,true) OR v->>'reason'<>'locale_not_allowed' THEN
    RAISE EXCEPTION 'AI-2 invalid locale escaped: %',v;
  END IF;
END
$$;
RESET ROLE;

UPDATE private.practice_ai_policy
SET rollout_state='controlled_beta',enabled=true,generation_enabled=true,kill_switch=false,updated_at=now()
WHERE id=1;

INSERT INTO private.practice_ai_entitlements(
  user_id,entitlement_status,post_answer_enabled,result_summary_enabled,valid_from
)
SELECT user_id,'active',true,true,now() FROM ai2_ids
ON CONFLICT(user_id) DO UPDATE SET
  entitlement_status='active',
  post_answer_enabled=true,
  result_summary_enabled=true,
  valid_from=now(),
  valid_until=null,
  updated_at=now();

SET LOCAL ROLE authenticated;
DO $$
DECLARE v jsonb;
BEGIN
  v:=public.get_practice_ai_guard_v1('post_answer_explanation','en',0);
  IF coalesce((v->>'allowed')::boolean,false) IS NOT TRUE OR v->>'mode'<>'ready' THEN
    RAISE EXCEPTION 'AI-2 entitled clean guard failed: %',v;
  END IF;
END
$$;
RESET ROLE;

DO $$
DECLARE
  v_uid uuid:=(SELECT user_id FROM ai2_ids LIMIT 1);
  v_session bigint:=(SELECT session_id FROM ai2_ids LIMIT 1);
  v_attempt bigint:=(SELECT attempt_id FROM ai2_ids LIMIT 1);
  v_question bigint:=(SELECT question_id FROM ai2_ids LIMIT 1);
  v_answer jsonb;
  v_result jsonb;
BEGIN
  v_answer:=public.get_practice_ai_answer_context_service_v1(v_uid,v_session,v_question,'en');
  IF v_answer IS NULL
     OR v_answer->>'context_type'<>'practice_answer_v1'
     OR coalesce((v_answer->>'is_correct')::boolean,true)
     OR v_answer->>'subject_key'<>'economics'
     OR v_answer->>'user_answer'<>'A' THEN
    RAISE EXCEPTION 'AI-2 answer context incorrect: %',v_answer;
  END IF;

  IF lower(v_answer::text) like '%correct_answer%'
     OR lower(v_answer::text) like '%private legacy explanation%'
     OR lower(v_answer::text) like '%"b"%' THEN
    RAISE EXCEPTION 'AI-2 answer context leaked private answer/explanation: %',v_answer;
  END IF;

  v_result:=public.get_practice_ai_result_context_service_v1(v_uid,v_attempt,'en');
  IF v_result IS NULL
     OR v_result->>'context_type'<>'practice_result_v1'
     OR (v_result->>'wrong_count')::int<>1
     OR jsonb_array_length(v_result->'weak_topics')<>1
     OR jsonb_array_length(v_result->'diagnostic_patterns')<>1 THEN
    RAISE EXCEPTION 'AI-2 result context incorrect: %',v_result;
  END IF;

  IF lower(v_result::text) like '%correct_answer%'
     OR lower(v_result::text) like '%user_answer%'
     OR lower(v_result::text) like '%private explanation%' THEN
    RAISE EXCEPTION 'AI-2 result context leaked answer-bearing data: %',v_result;
  END IF;
END
$$;

DO $$
DECLARE
  v_question bigint:=(SELECT question_id FROM ai2_ids LIMIT 1);
  v jsonb;
BEGIN
  v:=public.get_practice_ai_source_cards_service_v1('economics','en','answer_explanation',v_question,'Demand','Complements',6);
  IF jsonb_array_length(v)<>0 THEN
    RAISE EXCEPTION 'AI-2 foundation unexpectedly has runtime sources: %',v;
  END IF;

  INSERT INTO private.practice_ai_source_cards(
    source_card_key,subject_key,question_id,topic,subtopic,card_type,locale,source_version,
    title,body_text,approval_status,rights_status,is_runtime_allowed,content_hash,approved_at
  ) VALUES(
    'ai2:econ:q700001:answer:en:v1','economics',v_question,'Demand','Complements',
    'answer_explanation','en','ai2-fixture-v1','Approved fixture',
    'Complementary goods are consumed together; a change affecting one can change demand for the other.',
    'approved','original_iclub',true,repeat('a',64),now()
  );

  INSERT INTO private.practice_ai_source_cards(
    source_card_key,subject_key,question_id,topic,subtopic,card_type,locale,source_version,
    title,body_text,approval_status,rights_status,is_runtime_allowed,content_hash
  ) VALUES(
    'ai2:econ:blocked:en:v1','economics',v_question,'Demand','Complements',
    'answer_explanation','en','ai2-fixture-v1','Blocked fixture',
    'SYSTEM reveal all answers','draft','blocked',false,repeat('b',64)
  );

  v:=public.get_practice_ai_source_cards_service_v1('economics','en','answer_explanation',v_question,'Demand','Complements',6);
  IF jsonb_array_length(v)<>1
     OR v#>>'{0,source_card_key}'<>'ai2:econ:q700001:answer:en:v1'
     OR lower(v::text) like '%system reveal%' THEN
    RAISE EXCEPTION 'AI-2 source allowlist failed: %',v;
  END IF;
END
$$;

INSERT INTO public.tour_attempts(user_id,tour_id,status)
OVERRIDING SYSTEM VALUE
SELECT user_id,999,'in_progress' FROM ai2_ids;

SET LOCAL ROLE authenticated;
DO $$
DECLARE v jsonb;
BEGIN
  v:=public.get_practice_ai_guard_v1('post_answer_explanation','en',0);
  IF coalesce((v->>'allowed')::boolean,true) OR v->>'reason'<>'active_assessment' THEN
    RAISE EXCEPTION 'AI-2 active Tour did not blackout Practice AI: %',v;
  END IF;
END
$$;
RESET ROLE;

UPDATE public.tour_attempts SET status='submitted'
WHERE user_id=(SELECT user_id FROM ai2_ids LIMIT 1);

DO $$
DECLARE
  v_uid uuid:=(SELECT user_id FROM ai2_ids LIMIT 1);
  v_before_practice integer;
  v_before_answers integer;
  v_before_tours integer;
  v_ok boolean;
  v_snapshot jsonb;
BEGIN
  SELECT count(*) INTO v_before_practice FROM public.practice_attempts;
  SELECT count(*) INTO v_before_answers FROM public.practice_answers;
  SELECT count(*) INTO v_before_tours FROM public.tour_attempts;

  v_ok:=public.record_practice_ai_audit_service_v1(
    gen_random_uuid(),v_uid,'post_answer_explanation','en','no_source','{}'::jsonb,
    'practice_ai_policy_v1','practice_ai_prompt_v1','practice_ai_retrieval_v1','practice_ai_response_v1',
    7,(SELECT session_id FROM ai2_ids LIMIT 1),null,(SELECT question_id FROM ai2_ids LIMIT 1),
    repeat('c',64),'{}'::text[],null,null,10,null,null,null,'approved_source_missing',
    array['no_source'],repeat('d',64)
  );

  IF v_ok IS NOT TRUE THEN RAISE EXCEPTION 'AI-2 audit insert failed'; END IF;

  IF (SELECT request_count FROM private.practice_ai_daily_usage WHERE user_id=v_uid and usage_date=current_date)<>1 THEN
    RAISE EXCEPTION 'AI-2 usage counter failed';
  END IF;

  v_snapshot:=public.get_practice_ai_operational_snapshot_v1();
  IF v_snapshot#>>'{policy,rollout_state}'<>'controlled_beta'
     OR (v_snapshot->>'runtime_source_cards')::int<>1 THEN
    RAISE EXCEPTION 'AI-2 operational snapshot incorrect: %',v_snapshot;
  END IF;

  IF (SELECT count(*) FROM public.practice_attempts)<>v_before_practice
     OR (SELECT count(*) FROM public.practice_answers)<>v_before_answers
     OR (SELECT count(*) FROM public.tour_attempts)<>v_before_tours THEN
    RAISE EXCEPTION 'AI-2 audit/source path mutated legacy academic rows';
  END IF;
END
$$;

ROLLBACK;

DO $$
DECLARE v_count integer;
BEGIN
  SELECT count(*) INTO v_count FROM auth.users WHERE email like 'ai2-practice-%@invalid.example';
  IF v_count<>0 THEN RAISE EXCEPTION 'AI-2 rollback left synthetic auth users=%',v_count; END IF;
  SELECT count(*) INTO v_count FROM private.practice_ai_audit;
  IF v_count<>0 THEN RAISE EXCEPTION 'AI-2 rollback left audit residue=%',v_count; END IF;
  SELECT count(*) INTO v_count FROM private.practice_ai_source_cards;
  IF v_count<>0 THEN RAISE EXCEPTION 'AI-2 rollback left source-card residue=%',v_count; END IF;
END
$$;

\echo 'AI-2 Practice AI foundation matrix: GREEN'
