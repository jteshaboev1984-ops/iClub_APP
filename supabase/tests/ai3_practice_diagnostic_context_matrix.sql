\set ON_ERROR_STOP on

BEGIN;

CREATE TEMP TABLE ai3_ids(
  user_id uuid not null,
  mapped_answer_id bigint not null,
  unmapped_answer_id bigint not null,
  correct_answer_id bigint not null
) ON COMMIT DROP;

DO $ai3$
DECLARE
  v_uid uuid:=gen_random_uuid();
  v_mapped bigint;
  v_unmapped bigint;
  v_correct bigint;
BEGIN
  INSERT INTO auth.users(id,aud,role,email,created_at,updated_at,is_sso_user,is_anonymous)
  VALUES(v_uid,'authenticated','authenticated','ai3-diagnostic-'||replace(v_uid::text,'-','')||'@invalid.example',now(),now(),false,false);

  INSERT INTO public.users(id,first_name,last_name,language_code,created_at,must_change_password)
  VALUES(v_uid,'AI3','Diagnostic Synthetic','en',now(),false);

  INSERT INTO public.questions(
    id,subject_id,topic,subtopic,difficulty,qtype,question_text,options_text,correct_answer,
    explanation,is_active,question_text_ru,question_text_uz,question_text_en,
    options_text_ru,options_text_uz,options_text_en,explanation_ru,explanation_uz,explanation_en,
    book_ref,time_limit_sec,quality_status
  ) VALUES
  (700003,7,'Demand','Complementary goods','medium','mcq','Mapped synthetic','A|B|C|D','A',
   'Private mapped explanation',true,'RU mapped','UZ mapped','EN mapped','A|B|C|D','A|B|C|D','A|B|C|D',
   'RU private','UZ private','EN private','AI3 mapped',60,'published'),
  (700004,7,'Demand','Unmapped','medium','mcq','Unmapped synthetic','A|B|C|D','A',
   'Private unmapped explanation',true,'RU unmapped','UZ unmapped','EN unmapped','A|B|C|D','A|B|C|D','A|B|C|D',
   'RU private','UZ private','EN private','AI3 unmapped',60,'published'),
  (700005,7,'Demand','Correct mapped','medium','mcq','Correct synthetic','A|B|C|D','A',
   'Private correct explanation',true,'RU correct','UZ correct','EN correct','A|B|C|D','A|B|C|D','A|B|C|D',
   'RU private','UZ private','EN private','AI3 correct',60,'published');

  INSERT INTO public.practice_attempts(id,user_id,subject_id,score,percent,time_seconds,is_lab)
  OVERRIDING SYSTEM VALUE
  VALUES(800003,v_uid,7,1,33.33,70,false);

  INSERT INTO public.practice_answers(attempt_id,question_id,user_answer,is_correct,time_spent)
  OVERRIDING SYSTEM VALUE
  VALUES(800003,700003,'B',false,20)
  RETURNING id INTO v_mapped;

  INSERT INTO public.practice_answers(attempt_id,question_id,user_answer,is_correct,time_spent)
  OVERRIDING SYSTEM VALUE
  VALUES(800003,700004,'C',false,25)
  RETURNING id INTO v_unmapped;

  INSERT INTO public.practice_answers(attempt_id,question_id,user_answer,is_correct,time_spent)
  OVERRIDING SYSTEM VALUE
  VALUES(800003,700005,'A',true,25)
  RETURNING id INTO v_correct;

  INSERT INTO public.user_answer_diagnosis(
    user_id,subject_id,attempt_type,attempt_id,practice_answer_id,question_id,
    selected_answer,is_correct,diagnostic_id,mistake_type,weak_skill,
    feedback_ru,feedback_uz,feedback_en,next_action_ru,next_action_uz,next_action_en
  ) VALUES
  (v_uid,7,'practice',800003,v_mapped,700003,'B',false,9101,'direction_error','Complement demand shift direction',
   'RU mapped feedback','UZ mapped feedback','EN mapped feedback',
   'RU mapped action','UZ mapped action','EN mapped action'),
  (v_uid,7,'practice',800003,v_unmapped,700004,'C',false,null,'fallback_guess','Should never be treated as mapped',
   'RU fallback','UZ fallback','EN fallback','RU fallback action','UZ fallback action','EN fallback action'),
  (v_uid,7,'practice',800003,v_correct,700005,'A',true,9102,'should_not_surface','Correct answer must not become misconception',
   'RU correct','UZ correct','EN correct','RU correct action','UZ correct action','EN correct action');

  INSERT INTO ai3_ids VALUES(v_uid,v_mapped,v_unmapped,v_correct);
END
$ai3$;

DO $ai3$
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
     ) THEN
    RAISE EXCEPTION 'AI-3 diagnostic context became browser-executable';
  END IF;
END
$ai3$;

SET LOCAL ROLE service_role;

DO $ai3$
DECLARE
  v_uid uuid:=(SELECT user_id FROM ai3_ids LIMIT 1);
  v_en jsonb;
  v_ru jsonb;
  v_uz jsonb;
  v_unmapped jsonb;
  v_correct jsonb;
  v_result jsonb;
BEGIN
  v_en:=public.get_practice_ai_review_question_context_service_v1(v_uid,800003,700003,'en');
  v_ru:=public.get_practice_ai_review_question_context_service_v1(v_uid,800003,700003,'ru');
  v_uz:=public.get_practice_ai_review_question_context_service_v1(v_uid,800003,700003,'uz');

  IF v_en->>'context_type'<>'practice_review_answer_v2'
     OR coalesce((v_en->>'diagnostic_mapped')::boolean,false) IS NOT TRUE
     OR v_en#>>'{diagnostic,mistake_type}'<>'direction_error'
     OR v_en#>>'{diagnostic,weak_skill}'<>'Complement demand shift direction'
     OR v_en#>>'{diagnostic,feedback}'<>'EN mapped feedback'
     OR v_en#>>'{diagnostic,next_action}'<>'EN mapped action' THEN
    RAISE EXCEPTION 'AI-3 mapped English diagnosis incorrect: %',v_en;
  END IF;

  IF v_ru#>>'{diagnostic,feedback}'<>'RU mapped feedback'
     OR v_ru#>>'{diagnostic,next_action}'<>'RU mapped action'
     OR v_uz#>>'{diagnostic,feedback}'<>'UZ mapped feedback'
     OR v_uz#>>'{diagnostic,next_action}'<>'UZ mapped action' THEN
    RAISE EXCEPTION 'AI-3 locale-specific diagnosis drift ru=% uz=%',v_ru,v_uz;
  END IF;

  IF lower(v_en::text) LIKE '%diagnostic_id%'
     OR lower(v_en::text) LIKE '%correct_answer%'
     OR lower(v_en::text) LIKE '%private mapped explanation%' THEN
    RAISE EXCEPTION 'AI-3 context leaked internal/answer-key data: %',v_en;
  END IF;

  v_unmapped:=public.get_practice_ai_review_question_context_service_v1(v_uid,800003,700004,'en');
  IF coalesce((v_unmapped->>'diagnostic_mapped')::boolean,true)
     OR v_unmapped->'diagnostic' IS DISTINCT FROM 'null'::jsonb THEN
    RAISE EXCEPTION 'AI-3 invented diagnosis for unmapped answer: %',v_unmapped;
  END IF;

  v_correct:=public.get_practice_ai_review_question_context_service_v1(v_uid,800003,700005,'en');
  IF coalesce((v_correct->>'diagnostic_mapped')::boolean,true)
     OR v_correct->'diagnostic' IS DISTINCT FROM 'null'::jsonb THEN
    RAISE EXCEPTION 'AI-3 surfaced misconception for correct answer: %',v_correct;
  END IF;

  v_result:=public.get_practice_ai_result_context_service_v1(v_uid,800003,'en');
  IF jsonb_array_length(v_result->'diagnostic_patterns')<>1
     OR v_result#>>'{diagnostic_patterns,0,mistake_type}'<>'direction_error'
     OR v_result#>>'{diagnostic_patterns,0,weak_skill}'<>'Complement demand shift direction' THEN
    RAISE EXCEPTION 'AI-3 result pattern must include only deterministic mapped diagnosis: %',v_result;
  END IF;
END
$ai3$;

RESET ROLE;

ROLLBACK;

DO $ai3$
DECLARE v_count integer;
BEGIN
  SELECT count(*) INTO v_count FROM auth.users WHERE email like 'ai3-diagnostic-%@invalid.example';
  IF v_count<>0 THEN RAISE EXCEPTION 'AI-3 rollback left synthetic users=%',v_count; END IF;
END
$ai3$;

\echo 'AI-3 deterministic Practice diagnosis matrix: GREEN'
