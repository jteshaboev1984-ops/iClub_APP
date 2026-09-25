\set ON_ERROR_STOP on

BEGIN;

INSERT INTO public.practice_pools(id,subject_id,tour_no,title,is_active)
VALUES(7100,7,1,'AI4 coverage fixture',true);

INSERT INTO public.questions(
  id,subject_id,topic,subtopic,difficulty,qtype,question_text,options_text,correct_answer,
  explanation,is_active,question_text_ru,question_text_uz,question_text_en,
  options_text_ru,options_text_uz,options_text_en,explanation_ru,explanation_uz,explanation_en,
  book_ref,time_limit_sec,quality_status
) VALUES
(710001,7,'Demand','Fixture mapped','medium','mcq','Fixture one','A|B|C|D','A','PRIVATE',true,
 'RU one','UZ one','EN one','A|B|C|D','A|B|C|D','A|B|C|D','RU private','UZ private','EN private','AI4',60,'published'),
(710002,7,'Demand','Fixture source-only','medium','mcq','Fixture two','A|B|C|D','B','PRIVATE',true,
 'RU two','UZ two','EN two','A|B|C|D','A|B|C|D','A|B|C|D','RU private','UZ private','EN private','AI4',60,'published');

INSERT INTO public.practice_pool_questions(pool_id,question_id,order_no,is_active)
VALUES(7100,710001,1,true),(7100,710002,2,true);

INSERT INTO public.question_answer_diagnostics(question_id,is_correct,mistake_type,quality_status)
VALUES
(710001,false,'fixture_misconception','published'),
(710001,true,null,'published'),
(710002,false,'draft_only_should_not_count','draft');

INSERT INTO private.practice_ai_source_cards(
  source_card_key,subject_key,question_id,topic,subtopic,card_type,locale,source_version,
  title,body_text,approval_status,rights_status,is_runtime_allowed,content_hash,approved_at,updated_at
) VALUES
('ai4:q710001:ru','economics',710001,'Demand','Fixture mapped','answer_explanation','ru','ai4-fixture','RU','RU source','approved','original_iclub',true,repeat('a',64),now(),now()),
('ai4:q710001:uz','economics',710001,'Demand','Fixture mapped','answer_explanation','uz','ai4-fixture','UZ','UZ source','approved','original_iclub',true,repeat('b',64),now(),now()),
('ai4:q710001:en','economics',710001,'Demand','Fixture mapped','answer_explanation','en','ai4-fixture','EN','EN source','approved','original_iclub',true,repeat('c',64),now(),now()),
('ai4:q710002:en','economics',710002,'Demand','Fixture source-only','answer_explanation','en','ai4-fixture','EN2','EN source only','approved','original_iclub',true,repeat('d',64),now(),now()),
('ai4:q710002:ru-draft','economics',710002,'Demand','Fixture source-only','answer_explanation','ru','ai4-fixture','RU draft','draft source','draft','original_iclub',false,repeat('e',64),null,now());

DO $$
BEGIN
  IF has_function_privilege(
       'authenticated',
       'public.get_practice_ai_coverage_snapshot_service_v1(text)',
       'EXECUTE'
     )
     OR has_function_privilege(
       'anon',
       'public.get_practice_ai_coverage_snapshot_service_v1(text)',
       'EXECUTE'
     ) THEN
    RAISE EXCEPTION 'AI-4 coverage snapshot became browser-executable';
  END IF;
END
$$;

SET LOCAL ROLE service_role;

DO $$
DECLARE
  v jsonb;
  s jsonb;
  p jsonb;
BEGIN
  v:=public.get_practice_ai_coverage_snapshot_service_v1('economics');

  IF jsonb_array_length(v->'subjects')<>1 OR jsonb_array_length(v->'pools')<>1 THEN
    RAISE EXCEPTION 'AI-4 coverage shape incorrect: %',v;
  END IF;

  s:=v->'subjects'->0;
  p:=v->'pools'->0;

  IF (s->>'total_questions')::int<>2
     OR (s->>'source_ru_questions')::int<>1
     OR (s->>'source_uz_questions')::int<>1
     OR (s->>'source_en_questions')::int<>2
     OR (s->>'source_all_locales_questions')::int<>1
     OR (s->>'deterministic_diagnosis_questions')::int<>1
     OR (s->>'diagnostic_source_ready_questions')::int<>1 THEN
    RAISE EXCEPTION 'AI-4 subject coverage counts incorrect: %',s;
  END IF;

  IF (p->>'tour_no')::int<>1
     OR (p->>'total_questions')::int<>2
     OR (p->>'diagnostic_source_ready_questions')::int<>1 THEN
    RAISE EXCEPTION 'AI-4 pool coverage counts incorrect: %',p;
  END IF;

  IF lower(v::text) like '%correct_answer%'
     OR lower(v::text) like '%answer_key%'
     OR lower(v::text) like '%fixture misconception%' THEN
    RAISE EXCEPTION 'AI-4 coverage snapshot leaked content rather than counts: %',v;
  END IF;
END
$$;

RESET ROLE;

ROLLBACK;

\echo 'AI-4 Practice AI coverage snapshot matrix: GREEN'
