\set ON_ERROR_STOP on

BEGIN;

insert into public.subjects(id,subject_key,title,type,is_active)
values(4,'chemistry','Chemistry','main',true)
on conflict(id) do update
set subject_key=excluded.subject_key,title=excluded.title,type=excluded.type,is_active=excluded.is_active;

insert into public.practice_pools(id,subject_id,tour_no,title,is_active)
values(7200,4,1,'AI4 Chemistry topic source fixture',true);

insert into public.questions(
  id,subject_id,topic,subtopic,difficulty,qtype,question_text,options_text,correct_answer,
  explanation,is_active,question_text_ru,question_text_uz,question_text_en,
  options_text_ru,options_text_uz,options_text_en,explanation_ru,explanation_uz,explanation_en,
  book_ref,time_limit_sec,quality_status
) values
(720001,4,'Atomic structure','Fixture atomic structure','medium','mcq','Atomic fixture','A|B|C|D','A','PRIVATE',true,
 'RU','UZ','EN','A|B|C|D','A|B|C|D','A|B|C|D','RU','UZ','EN','AI4 Chemistry',60,'published'),
(720002,4,'Electrons in atoms','Fixture electrons','medium','mcq','Electron fixture','A|B|C|D','A','PRIVATE',true,
 'RU','UZ','EN','A|B|C|D','A|B|C|D','A|B|C|D','RU','UZ','EN','AI4 Chemistry',60,'published'),
(720003,4,'Stoichiometry','Fixture stoichiometry','medium','input','Stoich fixture',null,'1','PRIVATE',true,
 'RU','UZ','EN',null,null,null,'RU','UZ','EN','AI4 Chemistry',60,'published'),
(720004,4,'Atoms, molecules and stoichiometry','Fixture mixed','medium','input','Mixed fixture',null,'1','PRIVATE',true,
 'RU','UZ','EN',null,null,null,'RU','UZ','EN','AI4 Chemistry',60,'published'),
(720005,4,'Chemical','Fixture chemical','medium','mcq','Chemical fixture','A|B|C|D','A','PRIVATE',true,
 'RU','UZ','EN','A|B|C|D','A|B|C|D','A|B|C|D','RU','UZ','EN','AI4 Chemistry',60,'published');

insert into public.practice_pool_questions(pool_id,question_id,order_no,is_active)
values
(7200,720001,1,true),
(7200,720002,2,true),
(7200,720003,3,true),
(7200,720004,4,true),
(7200,720005,5,true);

DO $$
DECLARE
  v_total integer;
  v_bad integer;
BEGIN
  select count(*) into v_total
  from private.practice_ai_source_cards
  where subject_key='chemistry'
    and source_version='iclub_practice_ai_chemistry_p1_topic_v1_2026_09_25';

  if v_total<>15 then
    raise exception 'AI-4 Chemistry P1 topic source row count incorrect: %',v_total;
  end if;

  select count(*) into v_bad
  from (
    select topic,
           count(*) as card_count,
           count(distinct locale) as locale_count
    from private.practice_ai_source_cards
    where subject_key='chemistry'
      and source_version='iclub_practice_ai_chemistry_p1_topic_v1_2026_09_25'
    group by topic
  ) x
  where x.card_count<>3 or x.locale_count<>3;

  if v_bad<>0 then
    raise exception 'AI-4 Chemistry P1 topic locale coverage incomplete: %',v_bad;
  end if;

  select count(*) into v_bad
  from private.practice_ai_source_cards
  where subject_key='chemistry'
    and source_version='iclub_practice_ai_chemistry_p1_topic_v1_2026_09_25'
    and (
      question_id is not null
      or subtopic is not null
      or card_type<>'answer_explanation'
      or locale not in ('ru','uz','en')
      or approval_status<>'approved'
      or rights_status<>'original_iclub'
      or is_runtime_allowed is not true
      or content_hash is null
      or length(content_hash)<>64
    );

  if v_bad<>0 then
    raise exception 'AI-4 Chemistry P1 topic source boundary failed: %',v_bad;
  end if;
END
$$;

SET LOCAL ROLE service_role;

DO $$
DECLARE
  v jsonb;
  s jsonb;
  p jsonb;
  cards jsonb;
BEGIN
  v:=public.get_practice_ai_coverage_snapshot_service_v1('chemistry');

  if jsonb_array_length(v->'subjects')<>1 or jsonb_array_length(v->'pools')<>1 then
    raise exception 'AI-4 Chemistry coverage shape incorrect: %',v;
  end if;

  s:=v->'subjects'->0;
  p:=v->'pools'->0;

  if (s->>'total_questions')::int<>5
     or (s->>'source_any_ru_questions')::int<>5
     or (s->>'source_any_uz_questions')::int<>5
     or (s->>'source_any_en_questions')::int<>5
     or (s->>'source_any_all_locales_questions')::int<>5
     or (s->>'source_precise_all_locales_questions')::int<>0
     or (s->>'deterministic_diagnosis_questions')::int<>0
     or (s->>'diagnostic_any_source_ready_questions')::int<>0
     or (s->>'diagnostic_precise_source_ready_questions')::int<>0 then
    raise exception 'AI-4 Chemistry broad coverage counts incorrect: %',s;
  end if;

  if (p->>'tour_no')::int<>1
     or (p->>'total_questions')::int<>5
     or (p->>'source_any_all_locales_questions')::int<>5
     or (p->>'source_precise_all_locales_questions')::int<>0
     or (p->>'deterministic_diagnosis_questions')::int<>0 then
    raise exception 'AI-4 Chemistry pool coverage counts incorrect: %',p;
  end if;

  cards:=public.get_practice_ai_source_cards_service_v1(
    'chemistry','en','answer_explanation',720001,'Atomic structure','Fixture atomic structure',6
  );

  if jsonb_array_length(cards)<1
     or cards->0->>'topic'<>'Atomic structure'
     or cards->0->>'locale'<>'en'
     or cards->0->>'subject_key'<>'chemistry'
     or cards->0->>'subtopic' is not null then
    raise exception 'AI-4 Chemistry broad source retrieval failed: %',cards;
  end if;
END
$$;

RESET ROLE;

ROLLBACK;

\echo 'AI-4 Chemistry Practice 1 topic source matrix: GREEN'
