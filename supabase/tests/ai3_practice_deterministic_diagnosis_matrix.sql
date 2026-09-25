\set ON_ERROR_STOP on

BEGIN;

CREATE TEMP TABLE ai3_ids(
  user_id uuid not null,
  attempt_id bigint not null,
  mapped_question_id bigint not null,
  unmapped_question_id bigint not null
) ON COMMIT DROP;
GRANT SELECT ON ai3_ids TO service_role;

DO $ai3$
DECLARE
  v_uid uuid:=gen_random_uuid();
  v_attempt bigint;
  v_mapped bigint:=700101;
  v_unmapped bigint:=700102;
  v_answer_mapped bigint;
  v_answer_unmapped bigint;
BEGIN
  INSERT INTO auth.users(id,aud,role,email,created_at,updated_at,is_sso_user,is_anonymous)
  VALUES(v_uid,'authenticated','authenticated','ai3-diagnosis-'||replace(v_uid::text,'-','')||'@invalid.example',now(),now(),false,false);

  INSERT INTO public.users(id,first_name,last_name,language_code,created_at,must_change_password)
  VALUES(v_uid,'AI3','Diagnosis Synthetic','en',now(),false);

  INSERT INTO public.questions(
    id,subject_id,topic,subtopic,difficulty,qtype,question_text,options_text,correct_answer,
    explanation,is_active,question_text_ru,question_text_uz,question_text_en,
    options_text_ru,options_text_uz,options_text_en,explanation_ru,explanation_uz,explanation_en,
    book_ref,time_limit_sec,quality_status
  ) VALUES
  (
    v_mapped,7,'Demand','Complementary goods','medium','mcq',
    'Synthetic mapped question','A|B|C|D','B','PRIVATE CORRECT EXPLANATION',true,
    'RU mapped','UZ mapped','EN mapped','A|B|C|D','A|B|C|D','A|B|C|D',
    'RU PRIVATE','UZ PRIVATE','EN PRIVATE','AI3 fixture',60,'published'
  ),
  (
    v_unmapped,7,'Demand','Supply shift','medium','mcq',
    'Synthetic unmapped question','A|B|C|D','C','PRIVATE UNMAPPED EXPLANATION',true,
    'RU unmapped','UZ unmapped','EN unmapped','A|B|C|D','A|B|C|D','A|B|C|D',
    'RU PRIVATE 2','UZ PRIVATE 2','EN PRIVATE 2','AI3 fixture',60,'published'
  );

  INSERT INTO public.practice_attempts(user_id,subject_id,score,percent,time_seconds,is_lab)
  OVERRIDING SYSTEM VALUE
  VALUES(v_uid,7,0,0,40,false)
  RETURNING id INTO v_attempt;

  INSERT INTO public.practice_answers(attempt_id,question_id,user_answer,is_correct,time_spent)
  OVERRIDING SYSTEM VALUE
  VALUES(v_attempt,v_mapped,'A',false,20)
  RETURNING id INTO v_answer_mapped;

  INSERT INTO public.practice_answers(attempt_id,question_id,user_answer,is_correct,time_spent)
  OVERRIDING SYSTEM VALUE
  VALUES(v_attempt,v_unmapped,'A',false,20)
  RETURNING id INTO v_answer_unmapped;

  INSERT INTO public.user_answer_diagnosis(
    user_id,subject_id,attempt_type,attempt_id,practice_answer_id,question_id,selected_answer,is_correct,
    diagnostic_id,mistake_type,weak_skill,
    feedback_ru,feedback_uz,feedback_en,
    next_action_ru,next_action_uz,next_action_en
  ) VALUES
  (
    v_uid,7,'practice',v_attempt,v_answer_mapped,v_mapped,'A',false,
    900001,'direction_error','Complementary goods',
    'Проверьте направление изменения спроса на дополняющий товар.',
    'To‘ldiruvchi tovarga talab o‘zgarishi yo‘nalishini tekshiring.',
    'Check the direction of the demand change for the complementary good.',
    'Повторите связь между дополняющими товарами.',
    'To‘ldiruvchi tovarlar o‘rtasidagi bog‘lanishni takrorlang.',
    'Review the relationship between complementary goods.'
  ),
  (
    v_uid,7,'practice',v_attempt,v_answer_unmapped,v_unmapped,'A',false,
    null,null,null,
    null,null,null,null,null,null
  );

  INSERT INTO ai3_ids VALUES(v_uid,v_attempt,v_mapped,v_unmapped);
END
$ai3$;

DO $$
BEGIN
  IF has_function_privilege(
       'authenticated',
       'public.get_practice_ai_review_question_context_service_v1(uuid,bigint,bigint,text)',
       'EXECUTE'
     )
     OR has_function_privilege(
       'anon',
       'public.get_practice_ai_review_question_context_service_v1(uuid,bigint,bigint,text)',
       'EXECUTE'
     )
     OR has_function_privilege(
       'authenticated',
       'public.get_practice_ai_result_context_service_v1(uuid,bigint,text)',
       'EXECUTE'
     ) THEN
    RAISE EXCEPTION 'AI-3 deterministic diagnosis context became browser-executable';
  END IF;
END
$$;

SET LOCAL ROLE service_role;

DO $$
DECLARE
  v_uid uuid:=(SELECT user_id FROM ai3_ids LIMIT 1);
  v_attempt bigint:=(SELECT attempt_id FROM ai3_ids LIMIT 1);
  v_mapped bigint:=(SELECT mapped_question_id FROM ai3_ids LIMIT 1);
  v_unmapped bigint:=(SELECT unmapped_question_id FROM ai3_ids LIMIT 1);
  v_en jsonb;
  v_ru jsonb;
  v_uz jsonb;
  v_none jsonb;
  v_result jsonb;
BEGIN
  v_en:=public.get_practice_ai_review_question_context_service_v1(v_uid,v_attempt,v_mapped,'en');
  IF coalesce((v_en->>'diagnostic_mapped')::boolean,false) IS NOT TRUE
     OR v_en#>>'{diagnostic,mistake_type}'<>'direction_error'
     OR v_en#>>'{diagnostic,weak_skill}'<>'Complementary goods'
     OR v_en#>>'{diagnostic,feedback}'<>'Check the direction of the demand change for the complementary good.'
     OR v_en#>>'{diagnostic,next_action}'<>'Review the relationship between complementary goods.' THEN
    RAISE EXCEPTION 'AI-3 mapped English diagnosis context incorrect: %',v_en;
  END IF;

  v_ru:=public.get_practice_ai_review_question_context_service_v1(v_uid,v_attempt,v_mapped,'ru');
  IF v_ru#>>'{diagnostic,feedback}'<>'Проверьте направление изменения спроса на дополняющий товар.'
     OR v_ru#>>'{diagnostic,next_action}'<>'Повторите связь между дополняющими товарами.' THEN
    RAISE EXCEPTION 'AI-3 mapped Russian diagnosis context incorrect: %',v_ru;
  END IF;

  v_uz:=public.get_practice_ai_review_question_context_service_v1(v_uid,v_attempt,v_mapped,'uz');
  IF v_uz#>>'{diagnostic,feedback}'<>'To‘ldiruvchi tovarga talab o‘zgarishi yo‘nalishini tekshiring.'
     OR v_uz#>>'{diagnostic,next_action}'<>'To‘ldiruvchi tovarlar o‘rtasidagi bog‘lanishni takrorlang.' THEN
    RAISE EXCEPTION 'AI-3 mapped Uzbek diagnosis context incorrect: %',v_uz;
  END IF;

  v_none:=public.get_practice_ai_review_question_context_service_v1(v_uid,v_attempt,v_unmapped,'en');
  IF coalesce((v_none->>'diagnostic_mapped')::boolean,true)
     OR v_none->'diagnostic' IS DISTINCT FROM 'null'::jsonb THEN
    RAISE EXCEPTION 'AI-3 invented diagnosis for an unmapped answer: %',v_none;
  END IF;

  IF lower(v_en::text) like '%correct_answer%'
     OR lower(v_en::text) like '%answer_key%'
     OR lower(v_en::text) like '%private correct explanation%'
     OR lower(v_en::text) like '%"b"%' THEN
    RAISE EXCEPTION 'AI-3 diagnosis context leaked private answer material: %',v_en;
  END IF;

  v_result:=public.get_practice_ai_result_context_service_v1(v_uid,v_attempt,'en');
  IF jsonb_array_length(v_result->'diagnostic_patterns')<>1
     OR v_result#>>'{diagnostic_patterns,0,mistake_type}'<>'direction_error'
     OR (v_result#>>'{diagnostic_patterns,0,occurrence_count}')::int<>1
     OR v_result#>>'{diagnostic_patterns,0,feedback}'<>'Check the direction of the demand change for the complementary good.' THEN
    RAISE EXCEPTION 'AI-3 result summary did not isolate deterministic mapped diagnosis: %',v_result;
  END IF;

  IF lower(v_result::text) like '%correct_answer%'
     OR lower(v_result::text) like '%answer_key%'
     OR lower(v_result::text) like '%user_answer%'
     OR lower(v_result::text) like '%private%' THEN
    RAISE EXCEPTION 'AI-3 result diagnosis context leaked answer-bearing data: %',v_result;
  END IF;
END
$$;

RESET ROLE;

ROLLBACK;

DO $$
DECLARE v_count integer;
BEGIN
  SELECT count(*) INTO v_count
  FROM auth.users
  WHERE email like 'ai3-diagnosis-%@invalid.example';
  IF v_count<>0 THEN
    RAISE EXCEPTION 'AI-3 rollback left synthetic users=%',v_count;
  END IF;
END
$$;

\echo 'AI-3 deterministic Practice diagnosis matrix: GREEN'
