\set ON_ERROR_STOP on

BEGIN;

insert into public.subjects(id,subject_key,title,type,is_active)
values(4,'chemistry','Chemistry','main',true)
on conflict(id) do update
set subject_key=excluded.subject_key,title=excluded.title,type=excluded.type,is_active=excluded.is_active;

insert into public.practice_pools(id,subject_id,tour_no,title,is_active)
values(7300,4,1,'AI4 Chemistry Atomic structure precise fixture',true);

delete from public.questions where id in (1909,1914,1916,1921,1925,1929,1933,1943,1944,1954,1959,1964,3041,3043,3044);

insert into public.questions(
  id,subject_id,topic,subtopic,difficulty,qtype,question_text,options_text,correct_answer,
  explanation,is_active,question_text_ru,question_text_uz,question_text_en,
  options_text_ru,options_text_uz,options_text_en,explanation_ru,explanation_uz,explanation_en,
  book_ref,time_limit_sec,quality_status
) values
(1909,4,'Atomic structure','Deflection in an electric field','medium','mcq','Fixture 1909','A|B|C|D','A','PRIVATE',true,
 'RU','UZ','EN','A|B|C|D','A|B|C|D','A|B|C|D','RU','UZ','EN','AI4 Chemistry P1 Atomic structure',60,'published'),
(1914,4,'Atomic structure','Formation of positive ions','medium','mcq','Fixture 1914','A|B|C|D','A','PRIVATE',true,
 'RU','UZ','EN','A|B|C|D','A|B|C|D','A|B|C|D','RU','UZ','EN','AI4 Chemistry P1 Atomic structure',60,'published'),
(1916,4,'Atomic structure','Properties of a neutral atom','medium','mcq','Fixture 1916','A|B|C|D','A','PRIVATE',true,
 'RU','UZ','EN','A|B|C|D','A|B|C|D','A|B|C|D','RU','UZ','EN','AI4 Chemistry P1 Atomic structure',60,'published'),
(1921,4,'Atomic structure','Charge of a neutron','medium','mcq','Fixture 1921','A|B|C|D','A','PRIVATE',true,
 'RU','UZ','EN','A|B|C|D','A|B|C|D','A|B|C|D','RU','UZ','EN','AI4 Chemistry P1 Atomic structure',60,'published'),
(1925,4,'Atomic structure','Periodic table position','medium','mcq','Fixture 1925','A|B|C|D','A','PRIVATE',true,
 'RU','UZ','EN','A|B|C|D','A|B|C|D','A|B|C|D','RU','UZ','EN','AI4 Chemistry P1 Atomic structure',60,'published'),
(1929,4,'Atomic structure','Particle not deflected in an electric field','medium','mcq','Fixture 1929','A|B|C|D','A','PRIVATE',true,
 'RU','UZ','EN','A|B|C|D','A|B|C|D','A|B|C|D','RU','UZ','EN','AI4 Chemistry P1 Atomic structure',60,'published'),
(1933,4,'Atomic structure','Mass number','medium','mcq','Fixture 1933','A|B|C|D','A','PRIVATE',true,
 'RU','UZ','EN','A|B|C|D','A|B|C|D','A|B|C|D','RU','UZ','EN','AI4 Chemistry P1 Atomic structure',60,'published'),
(1943,4,'Atomic structure','Relative atomic mass (Ar)','medium','mcq','Fixture 1943','A|B|C|D','A','PRIVATE',true,
 'RU','UZ','EN','A|B|C|D','A|B|C|D','A|B|C|D','RU','UZ','EN','AI4 Chemistry P1 Atomic structure',60,'published'),
(1944,4,'Atomic structure','Electrons in Cl⁻','medium','input','Fixture 1944',null,'1','PRIVATE',true,
 'RU','UZ','EN',null,null,null,'RU','UZ','EN','AI4 Chemistry P1 Atomic structure',60,'published'),
(1954,4,'Atomic structure','Neutrons in copper isotope','medium','input','Fixture 1954',null,'1','PRIVATE',true,
 'RU','UZ','EN',null,null,null,'RU','UZ','EN','AI4 Chemistry P1 Atomic structure',60,'published'),
(1959,4,'Atomic structure','Smallest relative mass of subatomic particles','medium','mcq','Fixture 1959','A|B|C|D','A','PRIVATE',true,
 'RU','UZ','EN','A|B|C|D','A|B|C|D','A|B|C|D','RU','UZ','EN','AI4 Chemistry P1 Atomic structure',60,'published'),
(1964,4,'Atomic structure','Electrons in Fe³⁺','medium','input','Fixture 1964',null,'1','PRIVATE',true,
 'RU','UZ','EN',null,null,null,'RU','UZ','EN','AI4 Chemistry P1 Atomic structure',60,'published'),
(3041,4,'Atomic structure','Rutherford scattering and the nucleus','medium','mcq','Fixture 3041','A|B|C|D','A','PRIVATE',true,
 'RU','UZ','EN','A|B|C|D','A|B|C|D','A|B|C|D','RU','UZ','EN','AI4 Chemistry P1 Atomic structure',60,'published'),
(3043,4,'Atomic structure','Electron count in aluminium ion','medium','input','Fixture 3043',null,'1','PRIVATE',true,
 'RU','UZ','EN',null,null,null,'RU','UZ','EN','AI4 Chemistry P1 Atomic structure',60,'published'),
(3044,4,'Atomic structure','Mass and charge in the nucleus','medium','mcq','Fixture 3044','A|B|C|D','A','PRIVATE',true,
 'RU','UZ','EN','A|B|C|D','A|B|C|D','A|B|C|D','RU','UZ','EN','AI4 Chemistry P1 Atomic structure',60,'published');

insert into public.practice_pool_questions(pool_id,question_id,order_no,is_active)
values
(7300,1909,1,true),
(7300,1914,2,true),
(7300,1916,3,true),
(7300,1921,4,true),
(7300,1925,5,true),
(7300,1929,6,true),
(7300,1933,7,true),
(7300,1943,8,true),
(7300,1944,9,true),
(7300,1954,10,true),
(7300,1959,11,true),
(7300,1964,12,true),
(7300,3041,13,true),
(7300,3043,14,true),
(7300,3044,15,true);

DO $$
DECLARE
  v_total integer;
  v_bad integer;
BEGIN
  select count(*) into v_total
  from private.practice_ai_source_cards
  where subject_key='chemistry'
    and source_version='iclub_practice_ai_chemistry_p1_atomic_structure_precise_v1_2026_09_25';

  if v_total<>45 then
    raise exception 'AI-4 Chemistry Atomic structure precise row count incorrect: %',v_total;
  end if;

  select count(*) into v_bad
  from (
    select question_id,
           count(*) as card_count,
           count(distinct locale) as locale_count
    from private.practice_ai_source_cards
    where subject_key='chemistry'
      and source_version='iclub_practice_ai_chemistry_p1_atomic_structure_precise_v1_2026_09_25'
    group by question_id
  ) x
  where x.card_count<>3 or x.locale_count<>3;

  if v_bad<>0 then
    raise exception 'AI-4 Chemistry Atomic structure locale coverage incomplete: %',v_bad;
  end if;

  select count(*) into v_bad
  from private.practice_ai_source_cards
  where subject_key='chemistry'
    and source_version='iclub_practice_ai_chemistry_p1_atomic_structure_precise_v1_2026_09_25'
    and (
      question_id is null
      or topic<>'Atomic structure'
      or subtopic is null
      or card_type<>'answer_explanation'
      or locale not in ('ru','uz','en')
      or approval_status<>'approved'
      or rights_status<>'original_iclub'
      or is_runtime_allowed is not true
      or content_hash is null
      or length(content_hash)<>64
    );

  if v_bad<>0 then
    raise exception 'AI-4 Chemistry Atomic structure precise source boundary failed: %',v_bad;
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
  s:=v->'subjects'->0;
  p:=v->'pools'->0;

  if jsonb_array_length(v->'subjects')<>1 or jsonb_array_length(v->'pools')<>1 then
    raise exception 'AI-4 Chemistry Atomic structure coverage shape incorrect: %',v;
  end if;

  if (s->>'total_questions')::int<>15
     or (s->>'source_any_all_locales_questions')::int<>15
     or (s->>'source_precise_ru_questions')::int<>15
     or (s->>'source_precise_uz_questions')::int<>15
     or (s->>'source_precise_en_questions')::int<>15
     or (s->>'source_precise_all_locales_questions')::int<>15
     or (s->>'deterministic_diagnosis_questions')::int<>0
     or (s->>'diagnostic_precise_source_ready_questions')::int<>0 then
    raise exception 'AI-4 Chemistry Atomic structure precise coverage incorrect: %',s;
  end if;

  if (p->>'tour_no')::int<>1
     or (p->>'total_questions')::int<>15
     or (p->>'source_precise_all_locales_questions')::int<>15 then
    raise exception 'AI-4 Chemistry Atomic structure pool coverage incorrect: %',p;
  end if;

  cards:=public.get_practice_ai_source_cards_service_v1(
    'chemistry','en','answer_explanation',1944,'Atomic structure','Electrons in Cl⁻',6
  );

  if jsonb_array_length(cards)<1
     or (cards->0->>'question_id')::bigint<>1944
     or cards->0->>'subtopic'<>'Electrons in Cl⁻'
     or cards->0->>'locale'<>'en' then
    raise exception 'AI-4 Chemistry exact source retrieval did not rank question card first: %',cards;
  end if;
END
$$;

RESET ROLE;

ROLLBACK;

\echo 'AI-4 Chemistry Practice 1 Atomic structure precise source matrix: GREEN'
