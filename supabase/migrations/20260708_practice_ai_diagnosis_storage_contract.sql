-- Practice AI diagnosis storage contract
-- Safe scope:
-- - does not modify practice_attempts, practice_answers, ratings, certificates or tour data;
-- - stores AI diagnosis snapshots in existing learning_roadmaps;
-- - only authenticated users can create/read their own diagnosis archive.

create unique index if not exists learning_roadmaps_practice_ai_attempt_uidx
on public.learning_roadmaps (user_id, source_type, source_id)
where source_type = 'practice_ai_diagnosis';

create index if not exists learning_roadmaps_practice_ai_archive_idx
on public.learning_roadmaps (user_id, subject_id, created_at desc)
where source_type = 'practice_ai_diagnosis';

create or replace function public.get_practice_ai_diagnosis(p_attempt_id bigint)
returns jsonb
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_auth_user uuid := auth.uid();
  v_result jsonb;
begin
  if v_auth_user is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;

  select to_jsonb(lr)
  into v_result
  from public.learning_roadmaps lr
  where lr.user_id = v_auth_user
    and lr.source_type = 'practice_ai_diagnosis'
    and lr.source_id = p_attempt_id
  limit 1;

  return v_result;
end;
$$;

create or replace function public.create_practice_ai_diagnosis(p_attempt_id bigint)
returns jsonb
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_auth_user uuid := auth.uid();
  v_attempt record;
  v_existing jsonb;
  v_total integer := 0;
  v_correct integer := 0;
  v_errors integer := 0;
  v_percent numeric := 0;
  v_priority_topics jsonb := '[]'::jsonb;
  v_mistake_patterns jsonb := '[]'::jsonb;
  v_source_refs jsonb := '[]'::jsonb;
  v_main_focus text := null;
  v_message_ru text;
  v_message_uz text;
  v_message_en text;
  v_plan jsonb;
  v_new_id bigint;
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

  select public.get_practice_ai_diagnosis(p_attempt_id)
  into v_existing;

  if v_existing is not null then
    return v_existing;
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
      pa.id as practice_answer_id,
      pa.question_id,
      coalesce(nullif(q.topic, ''), 'General') as topic,
      nullif(q.subtopic, '') as subtopic,
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
  topic_counts as (
    select
      topic,
      coalesce(subtopic, topic) as subtopic,
      coalesce(weak_skill, coalesce(subtopic, topic)) as weak_skill,
      count(*)::integer as errors
    from wrong_answers
    group by topic, coalesce(subtopic, topic), coalesce(weak_skill, coalesce(subtopic, topic))
    order by count(*) desc, topic asc
    limit 5
  )
  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'topic', topic,
        'subtopic', subtopic,
        'weak_skill', weak_skill,
        'errors', errors
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
        'subtopic', subtopic,
        'book_ref', book_ref,
        'errors', errors
      ) order by errors desc, topic asc
    ),
    '[]'::jsonb
  )
  into v_source_refs
  from refs;

  v_main_focus := coalesce(
    v_priority_topics #>> '{0,weak_skill}',
    v_priority_topics #>> '{0,topic}',
    'Закрепление результата'
  );

  v_message_ru := case
    when v_errors = 0 then 'Ошибок в этой практике не найдено. Сохраните результат и продолжайте закрепление следующими заданиями.'
    else v_main_focus || ' выбран как главный фокус, потому что эта зона чаще всего связана с ошибками в текущей попытке. Начните с короткого повторения, затем откройте разбор ошибок и закрепите похожими заданиями.'
  end;

  v_message_uz := case
    when v_errors = 0 then 'Bu mashqda xato topilmadi. Natijani saqlang va keyingi mashqlar bilan mustahkamlashni davom ettiring.'
    else v_main_focus || ' asosiy fokus sifatida tanlandi, chunki joriy urinishdagi xatolar ko‘proq shu yo‘nalish bilan bog‘liq. Avval qisqa takrorlang, keyin xatolar tahlilini oching va o‘xshash savollar bilan mustahkamlang.'
  end;

  v_message_en := case
    when v_errors = 0 then 'No mistakes were found in this practice attempt. Save this result and continue reinforcing with the next practice set.'
    else v_main_focus || ' was selected as the main focus because this area is most connected to the mistakes in the current attempt. Start with a short review, then open the mistake review and reinforce with similar questions.'
  end;

  v_plan := jsonb_build_object(
    'version', 'practice_ai_diagnosis_v1',
    'attempt_id', p_attempt_id,
    'subject_id', v_attempt.subject_id,
    'score', v_correct,
    'total', v_total,
    'errors', v_errors,
    'percent', v_percent,
    'main_focus', v_main_focus,
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
    'diagnostic_rules_v1'
  )
  returning id into v_new_id;

  select to_jsonb(lr)
  into v_result
  from public.learning_roadmaps lr
  where lr.id = v_new_id;

  return v_result;
end;
$$;

create or replace function public.get_ai_diagnosis_archive(
  p_subject_id bigint default null,
  p_limit integer default 20
)
returns jsonb
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_auth_user uuid := auth.uid();
  v_limit integer := least(greatest(coalesce(p_limit, 20), 1), 50);
  v_result jsonb;
begin
  if v_auth_user is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;

  select coalesce(jsonb_agg(to_jsonb(x) order by x.created_at desc), '[]'::jsonb)
  into v_result
  from (
    select
      lr.id,
      lr.subject_id,
      s.title as subject_title,
      lr.source_id as practice_attempt_id,
      lr.main_weakness,
      lr.priority_topics,
      lr.plan_json,
      lr.message_ru,
      lr.message_uz,
      lr.message_en,
      lr.created_at,
      (lr.plan_json ->> 'score')::integer as score,
      (lr.plan_json ->> 'total')::integer as total,
      (lr.plan_json ->> 'errors')::integer as errors,
      (lr.plan_json ->> 'percent')::numeric as percent
    from public.learning_roadmaps lr
    left join public.subjects s on s.id = lr.subject_id
    where lr.user_id = v_auth_user
      and lr.source_type = 'practice_ai_diagnosis'
      and (p_subject_id is null or lr.subject_id = p_subject_id)
    order by lr.created_at desc
    limit v_limit
  ) x;

  return v_result;
end;
$$;

create or replace function public.has_ai_diagnosis_archive(p_subject_id bigint default null)
returns boolean
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_auth_user uuid := auth.uid();
  v_exists boolean := false;
begin
  if v_auth_user is null then
    return false;
  end if;

  select exists(
    select 1
    from public.learning_roadmaps lr
    where lr.user_id = v_auth_user
      and lr.source_type = 'practice_ai_diagnosis'
      and (p_subject_id is null or lr.subject_id = p_subject_id)
  )
  into v_exists;

  return v_exists;
end;
$$;

revoke all on function public.get_practice_ai_diagnosis(bigint) from public, anon;
revoke all on function public.create_practice_ai_diagnosis(bigint) from public, anon;
revoke all on function public.get_ai_diagnosis_archive(bigint, integer) from public, anon;
revoke all on function public.has_ai_diagnosis_archive(bigint) from public, anon;

grant execute on function public.get_practice_ai_diagnosis(bigint) to authenticated;
grant execute on function public.create_practice_ai_diagnosis(bigint) to authenticated;
grant execute on function public.get_ai_diagnosis_archive(bigint, integer) to authenticated;
grant execute on function public.has_ai_diagnosis_archive(bigint) to authenticated;

comment on function public.create_practice_ai_diagnosis(bigint) is
'Creates or returns a saved AI diagnosis snapshot for the authenticated user''s practice attempt. Does not modify attempt score/history.';

comment on function public.get_ai_diagnosis_archive(bigint, integer) is
'Returns saved AI diagnosis snapshots for the authenticated user. Intended for Practice/Resources/Profile archive UI.';
