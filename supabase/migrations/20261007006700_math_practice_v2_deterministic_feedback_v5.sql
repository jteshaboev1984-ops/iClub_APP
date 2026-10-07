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
