-- Mathematics Practice v2 — deterministic post-answer feedback v5
-- Branch-only migration. Does not change learner rows until called.
--
-- Correctness remains owned by iclub_eval_practice_question_safe_v4.
-- This layer only maps an already-saved wrong answer to an authored, published
-- diagnostic rule. If no exact authored rule exists, the result is "unmapped".
-- AI is not involved in correctness or diagnosis.

create or replace function private.practice_match_answer_diagnostic_v5(
  p_question_id bigint,
  p_selected_answer text
)
returns jsonb
language plpgsql
stable
security definer
set search_path to 'public','private','pg_temp'
as $function$
declare
  v_qtype text;
  v_diag public.question_answer_diagnostics%rowtype;
begin
  select lower(coalesce(q.qtype,'mcq'))
  into v_qtype
  from public.questions q
  where q.id=p_question_id;

  if v_qtype is null then
    return null;
  end if;

  if v_qtype='mcq' then
    select d.* into v_diag
    from public.question_answer_diagnostics d
    where d.question_id=p_question_id
      and d.quality_status='published'
      and d.is_correct is false
      and d.answer_kind='mcq_option'
      and upper(trim(coalesce(d.answer_key,d.answer_value,'')))
          =upper(trim(coalesce(p_selected_answer,'')))
    order by d.id
    limit 1;
  else
    select d.* into v_diag
    from public.question_answer_diagnostics d
    where d.question_id=p_question_id
      and d.quality_status='published'
      and d.is_correct is false
      and d.answer_kind='input_exact'
      and public.iclub_normalize_answer(coalesce(d.answer_value,d.answer_key,''))
          =public.iclub_normalize_answer(coalesce(p_selected_answer,''))
    order by d.id
    limit 1;
  end if;

  if v_diag.id is null then
    return null;
  end if;

  return jsonb_build_object(
    'diagnostic_id',v_diag.id,
    'diagnostic_code',nullif(v_diag.rule_json->>'diagnostic_code',''),
    'mistake_type',v_diag.mistake_type,
    'weak_skill',v_diag.weak_skill,
    'feedback_ru',v_diag.feedback_ru,
    'feedback_uz',v_diag.feedback_uz,
    'feedback_en',v_diag.feedback_en,
    'next_action_ru',v_diag.next_action_ru,
    'next_action_uz',v_diag.next_action_uz,
    'next_action_en',v_diag.next_action_en,
    'recommended_topic',v_diag.recommended_topic,
    'recommended_subtopic',v_diag.recommended_subtopic,
    'recommended_lesson_id',v_diag.recommended_lesson_id
  );
end;
$function$;

revoke all on function private.practice_match_answer_diagnostic_v5(bigint,text)
from public,anon,authenticated;


create or replace function public.submit_practice_session_answer_safe_v5(
  p_session_id bigint,
  p_question_id bigint,
  p_user_answer text,
  p_picked_index integer,
  p_time_spent integer
)
returns jsonb
language plpgsql
security definer
set search_path to 'public','private','auth','pg_temp'
as $function$
declare
  v_uid uuid:=auth.uid();
  v_s public.practice_sessions_v4%rowtype;
  v_q public.questions%rowtype;
  v_eval jsonb;
  v_saved public.practice_session_answers_v4%rowtype;
  v_answered integer;
  v_score integer;
  v_question_count integer;
  v_was_existing boolean:=false;
  v_diag jsonb;
  v_diag_status text;
begin
  if v_uid is null then
    raise exception 'not_authenticated' using errcode='28000';
  end if;

  select * into v_s
  from public.practice_sessions_v4 s
  where s.id=p_session_id
    and s.user_id=v_uid;

  if v_s.id is null then
    raise exception 'session_not_found' using errcode='P0002';
  end if;
  if v_s.status<>'in_progress' then
    raise exception 'session_not_in_progress' using errcode='55000';
  end if;

  v_question_count:=coalesce(cardinality(v_s.question_ids),0);
  if v_question_count not between 1 and 10 then
    raise exception 'invalid_session_question_count' using errcode='55000';
  end if;
  if not (p_question_id=any(v_s.question_ids)) then
    raise exception 'question_not_in_session' using errcode='22023';
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
  from public.practice_session_answers_v4 a
  where a.session_id=p_session_id
    and a.question_id=p_question_id;

  v_was_existing:=v_saved.session_id is not null;

  if not v_was_existing then
    v_eval:=public.iclub_eval_practice_question_safe_v4(
      p_question_id,p_user_answer,p_picked_index
    );

    insert into public.practice_session_answers_v4(
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
    from public.practice_session_answers_v4 a
    where a.session_id=p_session_id
      and a.question_id=p_question_id;
  end if;

  if v_saved.session_id is null then
    raise exception 'practice_answer_save_failed' using errcode='55000';
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

  select
    count(*)::integer,
    count(*) filter(where a.is_correct is true)::integer
  into v_answered,v_score
  from public.practice_session_answers_v4 a
  where a.session_id=p_session_id
    and a.question_id=any(v_s.question_ids);

  return jsonb_build_object(
    'ok',true,
    'session_id',p_session_id,
    'question_id',p_question_id,
    'is_correct',v_saved.is_correct,
    'answered',v_answered,
    'score_so_far',v_score,
    'question_count',v_question_count,
    'correct_answer',v_q.correct_answer,
    'explanation',v_q.explanation,
    'explanation_ru',v_q.explanation_ru,
    'explanation_uz',v_q.explanation_uz,
    'explanation_en',v_q.explanation_en,
    'diagnostic_status',v_diag_status,
    'diagnostic',v_diag,
    'idempotent',v_was_existing
  );
end;
$function$;

revoke all on function public.submit_practice_session_answer_safe_v5(bigint,bigint,text,integer,integer)
from public,anon;
grant execute on function public.submit_practice_session_answer_safe_v5(bigint,bigint,text,integer,integer)
to authenticated,service_role;


create or replace function public.get_practice_session_diagnostic_safe_v5(
  p_session_id bigint,
  p_question_id bigint
)
returns jsonb
language plpgsql
stable
security definer
set search_path to 'public','private','auth','pg_temp'
as $function$
declare
  v_uid uuid:=auth.uid();
  v_saved public.practice_session_answers_v4%rowtype;
  v_diag jsonb;
begin
  if v_uid is null then
    raise exception 'not_authenticated' using errcode='28000';
  end if;

  select a.* into v_saved
  from public.practice_sessions_v4 s
  join public.practice_session_answers_v4 a
    on a.session_id=s.id
   and a.question_id=p_question_id
  where s.id=p_session_id
    and s.user_id=v_uid
    and p_question_id=any(s.question_ids)
  limit 1;

  if v_saved.session_id is null then
    raise exception 'answered_session_question_not_found' using errcode='P0002';
  end if;

  if v_saved.is_correct then
    return jsonb_build_object(
      'session_id',p_session_id,
      'question_id',p_question_id,
      'is_correct',true,
      'diagnostic_status','not_needed',
      'diagnostic',null
    );
  end if;

  v_diag:=private.practice_match_answer_diagnostic_v5(
    p_question_id,v_saved.user_answer
  );

  return jsonb_build_object(
    'session_id',p_session_id,
    'question_id',p_question_id,
    'is_correct',false,
    'diagnostic_status',case when v_diag is null then 'unmapped' else 'mapped' end,
    'diagnostic',v_diag
  );
end;
$function$;

revoke all on function public.get_practice_session_diagnostic_safe_v5(bigint,bigint)
from public,anon;
grant execute on function public.get_practice_session_diagnostic_safe_v5(bigint,bigint)
to authenticated,service_role;


create or replace function public.submit_practice_drill_answer_safe_v5(
  p_session_id bigint,
  p_question_id bigint,
  p_user_answer text,
  p_picked_index integer,
  p_time_spent integer
)
returns jsonb
language plpgsql
security definer
set search_path to 'public','private','auth','pg_temp'
as $function$
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

revoke all on function public.submit_practice_drill_answer_safe_v5(bigint,bigint,text,integer,integer)
from public,anon;
grant execute on function public.submit_practice_drill_answer_safe_v5(bigint,bigint,text,integer,integer)
to authenticated,service_role;


-- Persist the already server-evaluated session evidence without re-running a legacy
-- client-shaped bulk evaluator. This removes the last need for learner finalization
-- to depend on submit_practice_attempt().
create or replace function public.finalize_practice_session_safe_v5(
  p_session_id bigint,
  p_total_time integer
)
returns jsonb
language plpgsql
security definer
set search_path to 'public','private','auth','pg_temp'
as $function$
declare
  v_uid uuid:=auth.uid();
  v_s public.practice_sessions_v4%rowtype;
  v_answered integer;
  v_question_count integer;
  v_attempt_id bigint;
  v_score integer;
  v_percent numeric;
  v_row record;
  v_practice_answer_id bigint;
  v_diag jsonb;
begin
  if v_uid is null then
    raise exception 'not_authenticated' using errcode='28000';
  end if;

  select * into v_s
  from public.practice_sessions_v4 s
  where s.id=p_session_id
    and s.user_id=v_uid
  for update;

  if v_s.id is null then
    raise exception 'session_not_found' using errcode='P0002';
  end if;

  v_question_count:=coalesce(cardinality(v_s.question_ids),0);
  if v_question_count not between 1 and 10 then
    raise exception 'invalid_session_question_count' using errcode='55000';
  end if;

  if v_s.status='finalized' and v_s.legacy_attempt_id is not null then
    select pa.score,pa.percent
    into v_score,v_percent
    from public.practice_attempts pa
    where pa.id=v_s.legacy_attempt_id
      and pa.user_id=v_uid;

    return jsonb_build_object(
      'ok',true,
      'session_id',v_s.id,
      'attempt_id',v_s.legacy_attempt_id,
      'score',coalesce(v_score,0),
      'percent',coalesce(v_percent,0),
      'question_count',v_question_count,
      'idempotent',true,
      'finalizer_version','v5'
    );
  end if;

  if v_s.status<>'in_progress' then
    raise exception 'session_not_in_progress' using errcode='55000';
  end if;

  select count(*)::integer
  into v_answered
  from public.practice_session_answers_v4 a
  where a.session_id=p_session_id
    and a.question_id=any(v_s.question_ids);

  if v_answered<>v_question_count then
    raise exception 'session_answers_incomplete' using errcode='55000';
  end if;

  select count(*) filter(where a.is_correct is true)::integer
  into v_score
  from public.practice_session_answers_v4 a
  where a.session_id=p_session_id
    and a.question_id=any(v_s.question_ids);

  v_percent:=case
    when v_question_count>0
      then round((v_score::numeric/v_question_count::numeric)*100,2)
    else 0
  end;

  insert into public.practice_attempts(
    user_id,subject_id,score,percent,time_seconds,is_lab
  ) values(
    v_uid,
    v_s.subject_id,
    v_score,
    v_percent,
    greatest(coalesce(p_total_time,0),0),
    false
  )
  returning id into v_attempt_id;

  for v_row in
    select
      a.question_id,
      a.user_answer,
      a.is_correct,
      a.time_spent
    from public.practice_session_answers_v4 a
    join lateral unnest(v_s.question_ids) with ordinality x(qid,ord)
      on x.qid=a.question_id
    where a.session_id=p_session_id
    order by x.ord
  loop
    insert into public.practice_answers(
      attempt_id,question_id,user_answer,is_correct,time_spent
    ) values(
      v_attempt_id,
      v_row.question_id,
      nullif(v_row.user_answer,''),
      v_row.is_correct,
      greatest(coalesce(v_row.time_spent,0),0)
    )
    returning id into v_practice_answer_id;

    if v_row.is_correct then
      v_diag:=null;
    else
      v_diag:=private.practice_match_answer_diagnostic_v5(
        v_row.question_id,
        v_row.user_answer
      );
    end if;

    insert into public.user_answer_diagnosis(
      user_id,
      subject_id,
      attempt_type,
      attempt_id,
      practice_answer_id,
      tour_answer_id,
      question_id,
      selected_answer,
      is_correct,
      diagnostic_id,
      mistake_type,
      weak_skill,
      feedback_ru,
      feedback_uz,
      feedback_en,
      next_action_ru,
      next_action_uz,
      next_action_en
    ) values(
      v_uid,
      v_s.subject_id,
      'practice',
      v_attempt_id,
      v_practice_answer_id,
      null,
      v_row.question_id,
      nullif(v_row.user_answer,''),
      v_row.is_correct,
      nullif(v_diag->>'diagnostic_id','')::bigint,
      nullif(v_diag->>'mistake_type',''),
      nullif(v_diag->>'weak_skill',''),
      nullif(v_diag->>'feedback_ru',''),
      nullif(v_diag->>'feedback_uz',''),
      nullif(v_diag->>'feedback_en',''),
      nullif(v_diag->>'next_action_ru',''),
      nullif(v_diag->>'next_action_uz',''),
      nullif(v_diag->>'next_action_en','')
    );
  end loop;

  update public.practice_sessions_v4
  set status='finalized',
      legacy_attempt_id=v_attempt_id,
      finalized_at=now()
  where id=p_session_id
    and user_id=v_uid;

  return jsonb_build_object(
    'ok',true,
    'session_id',p_session_id,
    'attempt_id',v_attempt_id,
    'score',v_score,
    'percent',v_percent,
    'question_count',v_question_count,
    'idempotent',false,
    'finalizer_version','v5'
  );
end;
$function$;

revoke all on function public.finalize_practice_session_safe_v5(bigint,integer)
from public,anon;
grant execute on function public.finalize_practice_session_safe_v5(bigint,integer)
to authenticated,service_role;


create or replace function public.get_practice_review_full_safe_v5(
  p_attempt_id bigint
)
returns table(
  question_id bigint,
  user_answer text,
  is_correct boolean,
  time_spent integer,
  correct_answer text,
  explanation text,
  explanation_ru text,
  explanation_uz text,
  explanation_en text,
  topic text,
  subtopic text,
  book_ref text,
  difficulty text,
  qtype text,
  question_text text,
  question_text_ru text,
  question_text_uz text,
  question_text_en text,
  options_text text,
  options_text_ru text,
  options_text_uz text,
  options_text_en text,
  image_url text,
  diagnostic_status text,
  diagnostic jsonb
)
language sql
stable
security definer
set search_path to 'public','private','auth','pg_temp'
as $function$
  select
    a.question_id,
    a.user_answer,
    a.is_correct,
    a.time_spent,
    q.correct_answer,
    q.explanation,
    q.explanation_ru,
    q.explanation_uz,
    q.explanation_en,
    q.topic,
    q.subtopic,
    q.book_ref,
    q.difficulty,
    q.qtype,
    q.question_text,
    q.question_text_ru,
    q.question_text_uz,
    q.question_text_en,
    q.options_text,
    q.options_text_ru,
    q.options_text_uz,
    q.options_text_en,
    q.image_url,
    case
      when a.is_correct then 'not_needed'
      when d.diagnostic_id is not null then 'mapped'
      else 'unmapped'
    end as diagnostic_status,
    case
      when not a.is_correct and d.diagnostic_id is not null then
        jsonb_build_object(
          'diagnostic_id',d.diagnostic_id,
          'diagnostic_code',nullif(qad.rule_json->>'diagnostic_code',''),
          'mistake_type',d.mistake_type,
          'weak_skill',d.weak_skill,
          'feedback_ru',d.feedback_ru,
          'feedback_uz',d.feedback_uz,
          'feedback_en',d.feedback_en,
          'next_action_ru',d.next_action_ru,
          'next_action_uz',d.next_action_uz,
          'next_action_en',d.next_action_en
        )
      else null
    end as diagnostic
  from public.practice_attempts pa
  join public.practice_answers a
    on a.attempt_id=pa.id
  join public.questions q
    on q.id=a.question_id
  left join public.user_answer_diagnosis d
    on d.practice_answer_id=a.id
   and d.attempt_type='practice'
  left join public.question_answer_diagnostics qad
    on qad.id=d.diagnostic_id
  where pa.id=p_attempt_id
    and pa.user_id=auth.uid()
    and not public.iclub_practice_drill_question_protected_v4(q.id)
  order by a.id;
$function$;

revoke all on function public.get_practice_review_full_safe_v5(bigint)
from public,anon;
grant execute on function public.get_practice_review_full_safe_v5(bigint)
to authenticated,service_role;
