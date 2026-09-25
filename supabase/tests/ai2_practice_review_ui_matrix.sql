\set ON_ERROR_STOP on

BEGIN;

CREATE TEMP TABLE ai2_ui_ids(user_id uuid primary key) ON COMMIT DROP;

DO $ai2ui$
DECLARE v_uid uuid:=gen_random_uuid();
BEGIN
  INSERT INTO auth.users(id,aud,role,email,created_at,updated_at,is_sso_user,is_anonymous)
  VALUES(v_uid,'authenticated','authenticated','ai2-ui-'||replace(v_uid::text,'-','')||'@invalid.example',now(),now(),false,false);

  INSERT INTO public.users(id,first_name,last_name,language_code,created_at,must_change_password)
  VALUES(v_uid,'AI2','Review UI Synthetic','en',now(),false);

  INSERT INTO public.questions(
    id,subject_id,topic,subtopic,difficulty,qtype,question_text,options_text,correct_answer,
    explanation,is_active,question_text_ru,question_text_uz,question_text_en,
    options_text_ru,options_text_uz,options_text_en,explanation_ru,explanation_uz,explanation_en,
    book_ref,time_limit_sec,quality_status
  ) VALUES(
    700002,7,'Demand','Complementary goods','medium','mcq','Synthetic review question','A|B|C|D','B',
    'Private review explanation must remain server-private.',true,
    'RU synthetic','UZ synthetic','EN synthetic','A|B|C|D','A|B|C|D','A|B|C|D',
    'RU private','UZ private','EN private','AI2 UI fixture',60,'published'
  );

  INSERT INTO public.practice_attempts(id,user_id,subject_id,score,percent,time_seconds,is_lab)
  OVERRIDING SYSTEM VALUE
  VALUES(800002,v_uid,7,0,0,24,false);

  INSERT INTO public.practice_answers(attempt_id,question_id,user_answer,is_correct,time_spent)
  OVERRIDING SYSTEM VALUE
  VALUES(800002,700002,'A',false,24);

  INSERT INTO ai2_ui_ids VALUES(v_uid);
END
$ai2ui$;

DO $ai2ui$
DECLARE
  v_uid uuid:=(SELECT user_id FROM ai2_ui_ids LIMIT 1);
  v_ctx jsonb;
BEGIN
  v_ctx:=public.get_practice_ai_review_question_context_service_v1(v_uid,800002,700002,'en');
  IF v_ctx IS NULL
     OR v_ctx->>'context_type'<>'practice_review_answer_v1'
     OR v_ctx->>'attempt_id'<>'800002'
     OR v_ctx->>'question_id'<>'700002'
     OR v_ctx->>'subject_key'<>'economics'
     OR coalesce((v_ctx->>'is_correct')::boolean,true)
     OR v_ctx->>'user_answer'<>'A' THEN
    RAISE EXCEPTION 'AI-2 review question context incorrect: %',v_ctx;
  END IF;

  IF lower(v_ctx::text) LIKE '%correct_answer%'
     OR lower(v_ctx::text) LIKE '%private review explanation%'
     OR lower(v_ctx::text) LIKE '%explanation_en%' THEN
    RAISE EXCEPTION 'AI-2 review context leaked private answer material: %',v_ctx;
  END IF;
END
$ai2ui$;

SELECT set_config('request.jwt.claim.sub',(SELECT user_id::text FROM ai2_ui_ids LIMIT 1),true);
SELECT set_config('request.jwt.claim.role','authenticated',true);

SET LOCAL ROLE authenticated;
DO $ai2ui$
DECLARE v jsonb;
BEGIN
  v:=public.get_practice_ai_ui_context_v1(800002,'en');
  IF coalesce((v->>'enabled')::boolean,true)
     OR coalesce((v->>'result_summary_enabled')::boolean,true)
     OR jsonb_array_length(v->'explainable_question_ids')<>0 THEN
    RAISE EXCEPTION 'AI-2 dormant UI did not fail closed: %',v;
  END IF;
END
$ai2ui$;
RESET ROLE;

UPDATE private.practice_ai_policy
SET rollout_state='controlled_beta',
    enabled=true,
    generation_enabled=true,
    kill_switch=false,
    updated_at=now()
WHERE id=1;

INSERT INTO private.practice_ai_entitlements(
  user_id,entitlement_status,post_answer_enabled,result_summary_enabled,valid_from
)
SELECT user_id,'active',true,true,now()
FROM ai2_ui_ids;

INSERT INTO private.practice_ai_source_cards(
  source_card_key,subject_key,question_id,topic,subtopic,card_type,locale,source_version,
  title,body_text,approval_status,rights_status,is_runtime_allowed,content_hash,approved_at
) VALUES
(
  'ai2-ui:economics:q700002:answer:en:v1','economics',700002,'Demand','Complementary goods',
  'answer_explanation','en','ai2-ui-v1','Complements',
  'Complementary goods are used together. Use the recorded checked result and this principle only.',
  'approved','original_iclub',true,repeat('a',64),now()
),
(
  'ai2-ui:economics:result:en:v1','economics',null,null,null,
  'result_context','en','ai2-ui-v1','Practice result',
  'A completed Practice result can guide review, but it does not prove mastery or exam readiness.',
  'approved','original_iclub',true,repeat('b',64),now()
);

SET LOCAL ROLE authenticated;
DO $ai2ui$
DECLARE v jsonb;
BEGIN
  v:=public.get_practice_ai_ui_context_v1(800002,'en');
  IF coalesce((v->>'enabled')::boolean,false) IS NOT TRUE
     OR coalesce((v->>'result_summary_enabled')::boolean,false) IS NOT TRUE
     OR jsonb_array_length(v->'explainable_question_ids')<>1
     OR v#>>'{explainable_question_ids,0}'<>'700002' THEN
    RAISE EXCEPTION 'AI-2 entitled UI availability incorrect: %',v;
  END IF;

  v:=public.get_practice_ai_ui_context_v1(999999,'en');
  IF coalesce((v->>'enabled')::boolean,true) THEN
    RAISE EXCEPTION 'AI-2 UI exposed unowned/missing attempt: %',v;
  END IF;
END
$ai2ui$;
RESET ROLE;

INSERT INTO public.tour_attempts(user_id,tour_id,status)
OVERRIDING SYSTEM VALUE
SELECT user_id,999,'in_progress' FROM ai2_ui_ids;

SET LOCAL ROLE authenticated;
DO $ai2ui$
DECLARE v jsonb;
BEGIN
  v:=public.get_practice_ai_ui_context_v1(800002,'en');
  IF coalesce((v->>'enabled')::boolean,true) THEN
    RAISE EXCEPTION 'AI-2 Practice AI UI stayed visible during active Tour: %',v;
  END IF;
END
$ai2ui$;
RESET ROLE;

ROLLBACK;

DO $ai2ui$
DECLARE v_count integer;
BEGIN
  SELECT count(*) INTO v_count FROM auth.users WHERE email like 'ai2-ui-%@invalid.example';
  IF v_count<>0 THEN RAISE EXCEPTION 'AI-2 UI rollback left users=%',v_count; END IF;
  SELECT count(*) INTO v_count FROM private.practice_ai_source_cards WHERE source_card_key like 'ai2-ui:%';
  IF v_count<>0 THEN RAISE EXCEPTION 'AI-2 UI rollback left source cards=%',v_count; END IF;
END
$ai2ui$;

\echo 'AI-2 Practice review UI contract matrix: GREEN'
