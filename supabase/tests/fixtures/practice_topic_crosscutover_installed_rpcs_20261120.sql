-- Isolated CI QA ONLY: verified installed public RPC source snapshots, 2026-11-20.
-- Snapshot functions are deployed into DISPOSABLE PostgreSQL17 by the test.
-- No live SQL changes, no learner data, no question bank, no stored answers.
-- Re-check live md5(pg_get_functiondef()) BEFORE using this QA snapshot for
-- a later candidate. Do not treat this as a production migration.
-- get_practice_drill_resume_safe_v4 md5: 5fbe4c2400fbf6c413a6676626da22c6
-- submit_practice_drill_answer_safe_v5 md5: c834661c5a34a223b54342ee6ca132c1

-- get_practice_drill_resume_safe_v4
CREATE OR REPLACE FUNCTION public.get_practice_drill_resume_safe_v4(p_session_id bigint)
 RETURNS TABLE(order_no integer, id bigint, subject_id bigint, time_limit_sec integer, question_text text, question_text_ru text, question_text_uz text, question_text_en text, options_text text, options_text_ru text, options_text_uz text, options_text_en text, image_url text, topic text, subtopic text, difficulty text, qtype text, book_ref text, input_kind text, was_answered boolean, saved_user_answer text, saved_picked_index integer, saved_is_correct boolean, saved_time_spent integer, correct_answer text, explanation text, explanation_ru text, explanation_uz text, explanation_en text)
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO 'public', 'auth', 'pg_temp'
AS $function$
  select
    x.ord::integer,
    q.id,
    q.subject_id,
    q.time_limit_sec,
    q.question_text,
    q.question_text_ru,
    q.question_text_uz,
    q.question_text_en,
    q.options_text,
    q.options_text_ru,
    q.options_text_uz,
    q.options_text_en,
    q.image_url,
    q.topic,
    q.subtopic,
    q.difficulty,
    q.qtype,
    q.book_ref,
    case
      when lower(coalesce(q.qtype,'mcq')) <> 'input' then null
      when split_part(trim(coalesce(q.correct_answer,'')),'|',1) ~ '^[+-]?[0-9]+([.][0-9]+)?([eE][+-]?[0-9]+)?$' then 'numeric'
      when split_part(trim(coalesce(q.correct_answer,'')),'|',1) ~ '^[A-Za-z][A-Za-z0-9]*$' then 'token'
      else 'text'
    end as input_kind,
    (a.session_id is not null) as was_answered,
    a.user_answer as saved_user_answer,
    a.picked_index as saved_picked_index,
    case when a.session_id is not null then a.is_correct else null end as saved_is_correct,
    case when a.session_id is not null then a.time_spent else null end as saved_time_spent,
    case when a.session_id is not null then q.correct_answer else null end as correct_answer,
    case when a.session_id is not null then q.explanation else null end as explanation,
    case when a.session_id is not null then q.explanation_ru else null end as explanation_ru,
    case when a.session_id is not null then q.explanation_uz else null end as explanation_uz,
    case when a.session_id is not null then q.explanation_en else null end as explanation_en
  from public.practice_drill_sessions_v4 s
  cross join lateral unnest(s.question_ids) with ordinality x(qid,ord)
  join public.questions q on q.id=x.qid and (q.is_active is true or (
    s.status='finalized' and s.drill_type='rec_topic'
    and left(s.client_session_id,22)='practice_topic_choice_'
    and exists(select 1 from public.practice_drill_answers_v4 a0 where a0.session_id=s.id and a0.question_id=q.id)
    and not public.iclub_practice_drill_question_protected_v4(q.id)
  ))
  left join public.practice_drill_answers_v4 a
    on a.session_id=s.id and a.question_id=q.id
  where s.id=p_session_id and s.user_id=auth.uid()
  order by x.ord;
$function$;

-- submit_practice_drill_answer_safe_v5
CREATE OR REPLACE FUNCTION public.submit_practice_drill_answer_safe_v5(p_session_id bigint, p_question_id bigint, p_user_answer text, p_picked_index integer, p_time_spent integer)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'private', 'auth', 'pg_temp'
AS $function$
declare
  v_uid uuid:=auth.uid();
  v_s public.practice_drill_sessions_v4%rowtype;
  v_q public.questions%rowtype;
  v_eval jsonb;
  v_saved public.practice_drill_answers_v4%rowtype;
  v_answered integer:=0;
  v_score integer:=0;
  v_count integer:=0;
  v_was_existing boolean:=false;
  v_diag jsonb;
  v_diag_status text;
begin
  if v_uid is null then
    raise exception 'not_authenticated' using errcode='28000';
  end if;

  select * into v_s
  from public.practice_drill_sessions_v4 s
  where s.id=p_session_id
    and s.user_id=v_uid
  for update;

  if v_s.id is null then
    raise exception 'practice_drill_session_not_found' using errcode='P0002';
  end if;
  if v_s.status not in ('in_progress','finalized') then
    raise exception 'practice_drill_session_not_available' using errcode='55000';
  end if;
  if not (p_question_id=any(v_s.question_ids)) then
    raise exception 'question_not_in_drill_session' using errcode='22023';
  end if;

  select * into v_q
  from public.questions q
  where q.id=p_question_id
    and q.is_active is true
    and q.subject_id=v_s.subject_id;

  if v_q.id is null then
    raise exception 'question_not_found_or_subject_mismatch' using errcode='P0002';
  end if;

  select * into v_saved
  from public.practice_drill_answers_v4 a
  where a.session_id=p_session_id
    and a.question_id=p_question_id;

  v_was_existing:=v_saved.session_id is not null;

  if not v_was_existing then
    if v_s.status='finalized' then
      raise exception 'practice_drill_session_finalized' using errcode='55000';
    end if;

    v_eval:=public.iclub_eval_practice_question_safe_v4(
      p_question_id,p_user_answer,p_picked_index
    );

    insert into public.practice_drill_answers_v4(
      session_id,question_id,user_answer,picked_index,is_correct,time_spent,answered_at
    ) values(
      p_session_id,
      p_question_id,
      v_eval->>'selected_answer',
      p_picked_index,
      coalesce((v_eval->>'is_correct')::boolean,false),
      greatest(coalesce(p_time_spent,0),0),
      now()
    )
    on conflict(session_id,question_id) do nothing;

    select * into v_saved
    from public.practice_drill_answers_v4 a
    where a.session_id=p_session_id
      and a.question_id=p_question_id;
  end if;

  if v_saved.session_id is null then
    raise exception 'practice_drill_answer_save_failed' using errcode='55000';
  end if;

  if v_saved.is_correct then
    v_diag:=null;
    v_diag_status:='not_needed';
  else
    v_diag:=private.practice_match_answer_diagnostic_v5(
      p_question_id,v_saved.user_answer
    );
    v_diag_status:=case when v_diag is null then 'unmapped' else 'mapped' end;
  end if;

  v_count:=cardinality(v_s.question_ids);

  select
    count(*)::integer,
    count(*) filter(where a.is_correct)::integer
  into v_answered,v_score
  from public.practice_drill_answers_v4 a
  where a.session_id=p_session_id
    and a.question_id=any(v_s.question_ids);

  if v_answered>=v_count and v_s.status='in_progress' then
    update public.practice_drill_sessions_v4
    set status='finalized',
        finalized_at=coalesce(finalized_at,now())
    where id=p_session_id
      and user_id=v_uid;
    -- Only voluntarily chosen Practice-by-topic; never recommendation drills or Tours.
    if v_s.drill_type='rec_topic' and left(v_s.client_session_id,22)='practice_topic_choice_' then
      insert into public.recommendations
        (user_id,subject_id,source_type,topic,subtopic,practice_drill_session_id)
      select v_uid,v_s.subject_id,'practice',q.topic,q.subtopic,v_s.id
      from public.practice_drill_answers_v4 a
      join public.questions q on q.id=a.question_id and q.subject_id=v_s.subject_id
      where a.session_id=v_s.id and a.is_correct is false and nullif(trim(q.topic),'') is not null
        and not exists (
          select 1 from public.recommendations r
          where r.user_id=v_uid and r.subject_id=v_s.subject_id
            and r.source_type='practice' and r.bank_generation=v_s.bank_generation
            and r.practice_drill_session_id is not null
            and r.topic=q.topic and coalesce(r.subtopic,'')=coalesce(q.subtopic,'')
        )
      group by q.topic,q.subtopic
      on conflict do nothing;
    end if;
  end if;

  return jsonb_build_object(
    'ok',true,
    'session_id',p_session_id,
    'question_id',p_question_id,
    'is_correct',v_saved.is_correct,
    'answered',v_answered,
    'score_so_far',v_score,
    'question_count',v_count,
    'correct_answer',v_q.correct_answer,
    'explanation',v_q.explanation,
    'explanation_ru',v_q.explanation_ru,
    'explanation_uz',v_q.explanation_uz,
    'explanation_en',v_q.explanation_en,
    'diagnostic_status',v_diag_status,
    'diagnostic',v_diag,
    'complete',(v_answered>=v_count),
    'idempotent',v_was_existing
  );
end;
$function$;
