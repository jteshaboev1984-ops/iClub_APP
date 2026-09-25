\set ON_ERROR_STOP on

DO $$
DECLARE
  v_total integer;
  v_answer integer;
  v_result integer;
  v_bad integer;
  v jsonb;
  v_locale text;
  v_q bigint;
BEGIN
  select count(*) into v_total
  from private.practice_ai_source_cards
  where source_version='iclub_practice_ai_economics_pilot_v1_2026_09_25';

  select count(*) into v_answer
  from private.practice_ai_source_cards
  where source_version='iclub_practice_ai_economics_pilot_v1_2026_09_25'
    and card_type='answer_explanation';

  select count(*) into v_result
  from private.practice_ai_source_cards
  where source_version='iclub_practice_ai_economics_pilot_v1_2026_09_25'
    and card_type='result_context';

  if v_total<>15 or v_answer<>12 or v_result<>3 then
    raise exception 'AI-2 Economics source-pack count drift total=% answer=% result=%',v_total,v_answer,v_result;
  end if;

  select count(*) into v_bad
  from private.practice_ai_source_cards c
  where c.source_version='iclub_practice_ai_economics_pilot_v1_2026_09_25'
    and (
      c.subject_key<>'economics'
      or c.approval_status<>'approved'
      or c.rights_status<>'original_iclub'
      or c.is_runtime_allowed is not true
      or c.locale not in ('ru','uz','en')
      or char_length(c.content_hash)<>64
    );

  if v_bad<>0 then
    raise exception 'AI-2 Economics source-pack governance drift rows=%',v_bad;
  end if;

  select count(*) into v_bad
  from private.practice_ai_source_cards c
  where c.source_version='iclub_practice_ai_economics_pilot_v1_2026_09_25'
    and c.question_id in (1018,1022,2548);

  if v_bad<>0 then
    raise exception 'AI-2 source pack included non-Practice pilot questions rows=%',v_bad;
  end if;

  select count(*) into v_bad
  from private.practice_ai_source_cards c
  where c.source_version='iclub_practice_ai_economics_pilot_v1_2026_09_25'
    and lower(c.body_text) similar to '%(answer key|correct_answer|private explanation|system prompt)%';

  if v_bad<>0 then
    raise exception 'AI-2 source pack contains forbidden/internal wording rows=%',v_bad;
  end if;

  foreach v_q in array array[1071,1081,1115,1135]::bigint[] loop
    foreach v_locale in array array['en','ru','uz']::text[] loop
      v:=public.get_practice_ai_source_cards_service_v1(
        'economics',v_locale,'answer_explanation',v_q,null,null,6
      );
      if jsonb_array_length(v)<>1
         or (v#>>'{0,question_id}')::bigint<>v_q
         or v#>>'{0,locale}'<>v_locale
         or v#>>'{0,card_type}'<>'answer_explanation' then
        raise exception 'AI-2 exact question source retrieval failed q=% locale=% rows=%',v_q,v_locale,v;
      end if;
    end loop;
  end loop;

  foreach v_locale in array array['en','ru','uz']::text[] loop
    v:=public.get_practice_ai_source_cards_service_v1(
      'economics',v_locale,'result_context',null,null,null,6
    );
    if jsonb_array_length(v)<>1
       or v#>>'{0,locale}'<>v_locale
       or v#>>'{0,card_type}'<>'result_context'
       or v#>>'{0,question_id}' is not null then
      raise exception 'AI-2 result source retrieval failed locale=% rows=%',v_locale,v;
    end if;
  end loop;

  v:=public.get_practice_ai_source_cards_service_v1(
    'biology','en','answer_explanation',1071,null,null,6
  );
  if jsonb_array_length(v)<>0 then
    raise exception 'AI-2 source subject isolation failed rows=%',v;
  end if;
END
$$;

\echo 'AI-2 Economics Practice source pack: GREEN'
