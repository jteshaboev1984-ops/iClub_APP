\set ON_ERROR_STOP on
BEGIN;

DO $$
DECLARE v_total integer; v_bad integer;
BEGIN
 select count(*) into v_total
 from private.practice_ai_source_cards
 where subject_key='chemistry'
   and source_version='iclub_practice_ai_chemistry_p1_electrons_precise_v1_2026_09_25';
 if v_total<>54 then
   raise exception 'AI-4 Chemistry Electrons precise row count incorrect: %',v_total;
 end if;

 select count(*) into v_bad from (
   select question_id,count(*) card_count,count(distinct locale) locale_count
   from private.practice_ai_source_cards
   where subject_key='chemistry'
     and source_version='iclub_practice_ai_chemistry_p1_electrons_precise_v1_2026_09_25'
   group by question_id
 ) x where card_count<>3 or locale_count<>3;
 if v_bad<>0 then
   raise exception 'AI-4 Chemistry Electrons locale coverage incomplete: %',v_bad;
 end if;

 select count(*) into v_bad
 from private.practice_ai_source_cards
 where subject_key='chemistry'
   and source_version='iclub_practice_ai_chemistry_p1_electrons_precise_v1_2026_09_25'
   and (
     question_id is null or topic<>'Electrons in atoms' or subtopic is null
     or card_type<>'answer_explanation' or locale not in ('ru','uz','en')
     or approval_status<>'approved' or rights_status<>'original_iclub'
     or is_runtime_allowed is not true or content_hash is null or length(content_hash)<>64
   );
 if v_bad<>0 then
   raise exception 'AI-4 Chemistry Electrons precise source boundary failed: %',v_bad;
 end if;
END $$;

SET LOCAL ROLE service_role;

DO $$
DECLARE v jsonb; s jsonb; p jsonb; cards jsonb;
BEGIN
 v:=public.get_practice_ai_coverage_snapshot_service_v1('chemistry');
 if jsonb_array_length(v->'subjects')<>1 or jsonb_array_length(v->'pools')<>1 then
   raise exception 'AI-4 Chemistry Electrons coverage shape incorrect: %',v;
 end if;
 s:=v->'subjects'->0;
 p:=v->'pools'->0;

 if (s->>'total_questions')::int<>18
    or (s->>'source_any_all_locales_questions')::int<>18
    or (s->>'source_precise_all_locales_questions')::int<>18
    or (s->>'deterministic_diagnosis_questions')::int<>0
    or (s->>'diagnostic_precise_source_ready_questions')::int<>0 then
   raise exception 'AI-4 Chemistry Electrons precise coverage incorrect: %',s;
 end if;

 if (p->>'total_questions')::int<>18 or (p->>'source_precise_all_locales_questions')::int<>18 then
   raise exception 'AI-4 Chemistry Electrons pool coverage incorrect: %',p;
 end if;

 cards:=public.get_practice_ai_source_cards_service_v1(
   'chemistry','en','answer_explanation',3039,'Electrons in atoms','First ionisation energy across Period 3',6
 );
 if jsonb_array_length(cards)<1
    or (cards->0->>'question_id')::bigint<>3039
    or cards->0->>'subtopic'<>'First ionisation energy across Period 3'
    or cards->0->>'locale'<>'en' then
   raise exception 'AI-4 Chemistry Electrons exact retrieval failed: %',cards;
 end if;
END $$;

RESET ROLE;
ROLLBACK;
\echo 'AI-4 Chemistry Practice 1 Electrons precise source matrix: GREEN'
