-- AI diagnosis v2: choose main focus by top-level topic, not arbitrary subtopic.
-- Safe: writes only learning_roadmaps snapshots for the authenticated user's practice attempt.

create or replace function public.practice_ai_label_ru(p_key text)
returns text
language sql
stable
as $$
  select case lower(btrim(coalesce(p_key, '')))
    when 'macroeconomy' then 'Макроэкономика'
    when 'government intervention' then 'Госрегулирование'
    when 'circular flow' then 'Кругооборот доходов'
    when 'examples of injections' then 'Вливания в кругооборот'
    when 'injections' then 'Вливания в кругооборот'
    when 'examples of leakages' then 'Утечки из кругооборота'
    when 'leakages' then 'Утечки из кругооборота'
    when 'largest component of aggregate demand' then 'Компоненты совокупного спроса'
    when 'real gdp concept' then 'Реальный ВВП'
    when 'wages and leftward shift of sras' then 'Сдвиги SRAS'
    when 'calculating net exports' then 'Чистый экспорт'
    when 'fisher equation' then 'Уравнение Фишера'
    when 'phillips curve' then 'Кривая Филлипса'
    when 'characteristics of public goods' then 'Общественные блага'
    when 'maximum price and shortage' then 'Максимальная цена и дефицит'
    when 'progressive and regressive taxes' then 'Прогрессивные и регрессивные налоги'
    else nullif(btrim(coalesce(p_key, '')), '')
  end;
$$;

create or replace function public.practice_ai_label_uz(p_key text)
returns text
language sql
stable
as $$
  select case lower(btrim(coalesce(p_key, '')))
    when 'macroeconomy' then 'Makroiqtisodiyot'
    when 'government intervention' then 'Davlat aralashuvi'
    when 'circular flow' then 'Daromadlar aylanishi'
    when 'examples of injections' then 'Aylanishga qo‘shiladigan oqimlar'
    when 'injections' then 'Aylanishga qo‘shiladigan oqimlar'
    when 'examples of leakages' then 'Aylanishdan chiqib ketadigan oqimlar'
    when 'leakages' then 'Aylanishdan chiqib ketadigan oqimlar'
    when 'largest component of aggregate demand' then 'Yalpi talab tarkibiy qismlari'
    when 'real gdp concept' then 'Real YaIM'
    when 'wages and leftward shift of sras' then 'SRAS siljishlari'
    when 'calculating net exports' then 'Sof eksport'
    when 'fisher equation' then 'Fisher tenglamasi'
    when 'phillips curve' then 'Phillips egri chizig‘i'
    when 'characteristics of public goods' then 'Jamoat tovarlari'
    when 'maximum price and shortage' then 'Maksimal narx va taqchillik'
    when 'progressive and regressive taxes' then 'Progressiv va regressiv soliqlar'
    else nullif(btrim(coalesce(p_key, '')), '')
  end;
$$;

create or replace function public.practice_ai_label_en(p_key text)
returns text
language sql
stable
as $$
  select case lower(btrim(coalesce(p_key, '')))
    when 'examples of injections' then 'Injections into the circular flow'
    when 'injections' then 'Injections into the circular flow'
    when 'examples of leakages' then 'Leakages from the circular flow'
    when 'leakages' then 'Leakages from the circular flow'
    else nullif(btrim(coalesce(p_key, '')), '')
  end;
$$;

CREATE OR REPLACE FUNCTION public.create_practice_ai_diagnosis(p_attempt_id bigint)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'auth'
AS $function$
declare
  v_auth_user uuid := auth.uid();
  v_attempt record;
  v_existing_id bigint;
  v_existing_version text;
  v_total integer := 0;
  v_correct integer := 0;
  v_errors integer := 0;
  v_percent numeric := 0;
  v_priority_topics jsonb := '[]'::jsonb;
  v_mistake_patterns jsonb := '[]'::jsonb;
  v_source_refs jsonb := '[]'::jsonb;
  v_main_focus text := null;
  v_main_focus_ru text;
  v_main_focus_uz text;
  v_main_focus_en text;
  v_message_ru text;
  v_message_uz text;
  v_message_en text;
  v_plan jsonb;
  v_result jsonb;
begin
  if v_auth_user is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;

  select pa.*
  into v_attempt
  from public.practice_attempts pa
  where pa.id = p_attempt_id
    and pa.user_id = v_auth_user
  limit 1;

  if not found then
    raise exception 'practice_attempt_not_found_or_not_owned' using errcode = '42501';
  end if;

  select lr.id, lr.plan_json ->> 'version'
  into v_existing_id, v_existing_version
  from public.learning_roadmaps lr
  where lr.user_id = v_auth_user
    and lr.source_type = 'practice_ai_diagnosis'
    and lr.source_id = p_attempt_id
  limit 1;

  if v_existing_id is not null and v_existing_version = 'practice_ai_diagnosis_v2' then
    select to_jsonb(lr) into v_result
    from public.learning_roadmaps lr
    where lr.id = v_existing_id;
    return v_result;
  end if;

  select
    count(*)::integer,
    count(*) filter (where pa.is_correct)::integer,
    count(*) filter (where not pa.is_correct)::integer
  into v_total, v_correct, v_errors
  from public.practice_answers pa
  where pa.attempt_id = p_attempt_id;

  v_percent := case when v_total > 0 then round((v_correct::numeric / v_total::numeric) * 100, 0) else 0 end;

  with wrong_answers as (
    select
      pa.question_id,
      coalesce(nullif(q.topic, ''), 'General') as topic,
      coalesce(nullif(q.subtopic, ''), coalesce(nullif(q.topic, ''), 'General')) as subtopic,
      nullif(q.book_ref, '') as book_ref,
      nullif(uad.mistake_type, '') as mistake_type,
      nullif(uad.weak_skill, '') as weak_skill
    from public.practice_answers pa
    join public.questions q on q.id = pa.question_id
    left join public.user_answer_diagnosis uad
      on uad.attempt_type = 'practice'
     and uad.attempt_id = pa.attempt_id
     and uad.question_id = pa.question_id
    where pa.attempt_id = p_attempt_id
      and not pa.is_correct
  ),
  sub_counts as (
    select
      topic,
      subtopic,
      coalesce(weak_skill, subtopic) as weak_skill,
      count(*)::integer as errors
    from wrong_answers
    group by topic, subtopic, coalesce(weak_skill, subtopic)
  ),
  topic_counts as (
    select
      topic,
      count(*)::integer as errors,
      coalesce(
        jsonb_agg(
          jsonb_build_object(
            'subtopic', subtopic,
            'subtopic_ru', public.practice_ai_label_ru(subtopic),
            'subtopic_uz', public.practice_ai_label_uz(subtopic),
            'subtopic_en', public.practice_ai_label_en(subtopic),
            'weak_skill', weak_skill,
            'weak_skill_ru', public.practice_ai_label_ru(weak_skill),
            'weak_skill_uz', public.practice_ai_label_uz(weak_skill),
            'weak_skill_en', public.practice_ai_label_en(weak_skill),
            'errors', errors
          ) order by errors desc, subtopic asc
        ),
        '[]'::jsonb
      ) as subtopics
    from sub_counts
    group by topic
    order by count(*) desc, topic asc
    limit 5
  )
  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'topic', topic,
        'topic_ru', public.practice_ai_label_ru(topic),
        'topic_uz', public.practice_ai_label_uz(topic),
        'topic_en', public.practice_ai_label_en(topic),
        'errors', errors,
        'subtopics', subtopics
      ) order by errors desc, topic asc
    ),
    '[]'::jsonb
  )
  into v_priority_topics
  from topic_counts;

  with wrong_answers as (
    select
      coalesce(nullif(uad.mistake_type, ''), 'needs_review') as mistake_type,
      count(*)::integer as errors
    from public.practice_answers pa
    left join public.user_answer_diagnosis uad
      on uad.attempt_type = 'practice'
     and uad.attempt_id = pa.attempt_id
     and uad.question_id = pa.question_id
    where pa.attempt_id = p_attempt_id
      and not pa.is_correct
    group by coalesce(nullif(uad.mistake_type, ''), 'needs_review')
    order by count(*) desc, mistake_type asc
    limit 5
  )
  select coalesce(
    jsonb_agg(
      jsonb_build_object('mistake_type', mistake_type, 'errors', errors)
      order by errors desc, mistake_type asc
    ),
    '[]'::jsonb
  )
  into v_mistake_patterns
  from wrong_answers;

  with refs as (
    select
      coalesce(nullif(q.topic, ''), 'General') as topic,
      nullif(q.subtopic, '') as subtopic,
      nullif(q.book_ref, '') as book_ref,
      count(*)::integer as errors
    from public.practice_answers pa
    join public.questions q on q.id = pa.question_id
    where pa.attempt_id = p_attempt_id
      and not pa.is_correct
      and nullif(q.book_ref, '') is not null
    group by coalesce(nullif(q.topic, ''), 'General'), nullif(q.subtopic, ''), nullif(q.book_ref, '')
    order by count(*) desc, topic asc
    limit 5
  )
  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'topic', topic,
        'topic_ru', public.practice_ai_label_ru(topic),
        'topic_uz', public.practice_ai_label_uz(topic),
        'topic_en', public.practice_ai_label_en(topic),
        'subtopic', subtopic,
        'subtopic_ru', public.practice_ai_label_ru(subtopic),
        'subtopic_uz', public.practice_ai_label_uz(subtopic),
        'subtopic_en', public.practice_ai_label_en(subtopic),
        'book_ref', book_ref,
        'errors', errors
      ) order by errors desc, topic asc
    ),
    '[]'::jsonb
  )
  into v_source_refs
  from refs;

  v_main_focus := coalesce(v_priority_topics #>> '{0,topic}', 'Закрепление результата');
  v_main_focus_ru := public.practice_ai_label_ru(v_main_focus);
  v_main_focus_uz := public.practice_ai_label_uz(v_main_focus);
  v_main_focus_en := public.practice_ai_label_en(v_main_focus);

  v_message_ru := case
    when v_errors = 0 then 'Ошибок в этой практике не найдено. Сохраните результат и продолжайте закрепление следующими заданиями.'
    else 'Тема «' || v_main_focus_ru || '» выбрана как главный фокус, потому что в ней больше всего ошибок в текущей попытке. Начните с короткого повторения, затем откройте разбор ошибок и закрепите похожими заданиями.'
  end;

  v_message_uz := case
    when v_errors = 0 then 'Bu mashqda xato topilmadi. Natijani saqlang va keyingi mashqlar bilan mustahkamlashni davom ettiring.'
    else '«' || v_main_focus_uz || '» mavzusi asosiy fokus sifatida tanlandi, chunki joriy urinishda eng ko‘p xato shu yo‘nalishda. Avval qisqa takrorlang, keyin xatolar tahlilini oching va o‘xshash savollar bilan mustahkamlang.'
  end;

  v_message_en := case
    when v_errors = 0 then 'No mistakes were found in this practice attempt. Save this result and continue reinforcing with the next practice set.'
    else v_main_focus_en || ' was selected as the main focus because it has the highest number of mistakes in the current attempt. Start with a short review, then open the mistake review and reinforce with similar questions.'
  end;

  v_plan := jsonb_build_object(
    'version', 'practice_ai_diagnosis_v2',
    'attempt_id', p_attempt_id,
    'subject_id', v_attempt.subject_id,
    'score', v_correct,
    'total', v_total,
    'errors', v_errors,
    'percent', v_percent,
    'main_focus', v_main_focus,
    'main_focus_ru', v_main_focus_ru,
    'main_focus_uz', v_main_focus_uz,
    'main_focus_en', v_main_focus_en,
    'priority_topics', v_priority_topics,
    'mistake_patterns', v_mistake_patterns,
    'source_refs', v_source_refs,
    'steps', jsonb_build_array(
      jsonb_build_object(
        'order_no', 1,
        'action_key', 'open_source',
        'title_ru', 'Повторить ключевую идею',
        'title_uz', 'Asosiy g‘oyani takrorlash',
        'title_en', 'Review the key idea',
        'text_ru', 'Откройте источник по главному фокусу и восстановите правило темы.',
        'text_uz', 'Asosiy fokus bo‘yicha manbani oching va mavzu qoidasini tiklang.',
        'text_en', 'Open the source for the main focus and review the topic rule.'
      ),
      jsonb_build_object(
        'order_no', 2,
        'action_key', 'open_review',
        'title_ru', 'Разобрать ошибки',
        'title_uz', 'Xatolarni tahlil qilish',
        'title_en', 'Review mistakes',
        'text_ru', 'Сравните свои ответы с правильной логикой в разборе ошибок.',
        'text_uz', 'Javoblaringizni xatolar tahlilidagi to‘g‘ri mantiq bilan solishtiring.',
        'text_en', 'Compare your answers with the correct reasoning in the mistake review.'
      ),
      jsonb_build_object(
        'order_no', 3,
        'action_key', 'start_mini_training',
        'title_ru', 'Закрепить практикой',
        'title_uz', 'Mashq bilan mustahkamlash',
        'title_en', 'Reinforce with practice',
        'text_ru', 'Пройдите короткий набор похожих вопросов по главному фокусу.',
        'text_uz', 'Asosiy fokus bo‘yicha o‘xshash savollardan iborat qisqa blokni bajaring.',
        'text_en', 'Complete a short set of similar questions for the main focus.'
      )
    )
  );

  if v_existing_id is not null then
    update public.learning_roadmaps
    set
      main_weakness = v_main_focus,
      priority_topics = v_priority_topics,
      plan_json = v_plan,
      message_ru = v_message_ru,
      message_uz = v_message_uz,
      message_en = v_message_en,
      ai_enhanced = true,
      ai_model = 'diagnostic_rules_v2'
    where id = v_existing_id;
  else
    insert into public.learning_roadmaps (
      user_id,
      subject_id,
      source_type,
      source_id,
      main_weakness,
      priority_topics,
      plan_json,
      message_ru,
      message_uz,
      message_en,
      ai_enhanced,
      ai_model
    ) values (
      v_auth_user,
      v_attempt.subject_id,
      'practice_ai_diagnosis',
      p_attempt_id,
      v_main_focus,
      v_priority_topics,
      v_plan,
      v_message_ru,
      v_message_uz,
      v_message_en,
      true,
      'diagnostic_rules_v2'
    )
    returning id into v_existing_id;
  end if;

  select to_jsonb(lr) into v_result
  from public.learning_roadmaps lr
  where lr.id = v_existing_id;

  return v_result;
end;
$function$;

revoke all on function public.create_practice_ai_diagnosis(bigint) from public, anon;
grant execute on function public.create_practice_ai_diagnosis(bigint) to authenticated;

comment on function public.create_practice_ai_diagnosis(bigint) is
'Practice AI diagnosis v2: topic-level focus, localized labels, learning_roadmaps snapshot.';
