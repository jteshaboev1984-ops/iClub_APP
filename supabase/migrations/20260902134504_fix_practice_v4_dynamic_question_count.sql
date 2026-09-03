-- Production-applied Supabase migration 20260902134504 / fix_practice_v4_dynamic_question_count.
-- Keeps valid Practice sessions at 1..10 questions near pool exhaustion.

create or replace function public.submit_practice_session_answer_safe_v4(
  p_session_id bigint,
  p_question_id bigint,
  p_user_answer text,
  p_picked_index integer,
  p_time_spent integer
)
returns jsonb
language plpgsql
security definer
set search_path to 'public','auth','pg_temp'
as $function$
declare
  v_uid uuid := auth.uid();
  v_s public.practice_sessions_v4%rowtype;
  v_q public.questions%rowtype;
  v_eval jsonb;
  v_saved public.practice_session_answers_v4%rowtype;
  v_answered integer;
  v_score integer;
  v_question_count integer;
  v_was_existing boolean := false;
begin
  if v_uid is null then raise exception 'not_authenticated' using errcode='28000'; end if;
  select * into v_s from public.practice_sessions_v4 s where s.id=p_session_id and s.user_id=v_uid;
  if v_s.id is null then raise exception 'session_not_found' using errcode='P0002'; end if;
  if v_s.status <> 'in_progress' then raise exception 'session_not_in_progress' using errcode='55000'; end if;
  v_question_count := coalesce(cardinality(v_s.question_ids),0);
  if v_question_count not between 1 and 10 then raise exception 'invalid_session_question_count' using errcode='55000'; end if;
  if not (p_question_id=any(v_s.question_ids)) then raise exception 'question_not_in_session' using errcode='22023'; end if;
  select * into v_q from public.questions q where q.id=p_question_id and q.is_active is true and q.subject_id=v_s.subject_id;
  if v_q.id is null then raise exception 'question_not_found_or_subject_mismatch' using errcode='P0002'; end if;
  select * into v_saved from public.practice_session_answers_v4 a where a.session_id=p_session_id and a.question_id=p_question_id;
  v_was_existing := v_saved.session_id is not null;
  if not v_was_existing then
    v_eval := public.iclub_eval_practice_question_safe_v4(p_question_id,p_user_answer,p_picked_index);
    insert into public.practice_session_answers_v4(session_id,question_id,user_answer,picked_index,is_correct,time_spent,answered_at)
    values(p_session_id,p_question_id,v_eval->>'selected_answer',p_picked_index,coalesce((v_eval->>'is_correct')::boolean,false),greatest(coalesce(p_time_spent,0),0),now())
    on conflict(session_id,question_id) do nothing;
    select * into v_saved from public.practice_session_answers_v4 a where a.session_id=p_session_id and a.question_id=p_question_id;
  end if;
  if v_saved.session_id is null then raise exception 'practice_answer_save_failed' using errcode='55000'; end if;
  select count(*)::integer,count(*) filter(where a.is_correct is true)::integer into v_answered,v_score
  from public.practice_session_answers_v4 a
  where a.session_id=p_session_id and a.question_id=any(v_s.question_ids);
  return jsonb_build_object(
    'ok',true,'session_id',p_session_id,'question_id',p_question_id,'is_correct',v_saved.is_correct,
    'answered',v_answered,'score_so_far',v_score,'question_count',v_question_count,
    'correct_answer',v_q.correct_answer,'explanation',v_q.explanation,
    'explanation_ru',v_q.explanation_ru,'explanation_uz',v_q.explanation_uz,'explanation_en',v_q.explanation_en,
    'idempotent',v_was_existing
  );
end;
$function$;

create or replace function public.finalize_practice_session_safe_v4(
  p_session_id bigint,
  p_total_time integer
)
returns jsonb
language plpgsql
security definer
set search_path to 'public','auth','pg_temp'
as $function$
declare
  v_uid uuid := auth.uid();
  v_s public.practice_sessions_v4%rowtype;
  v_answered integer;
  v_question_count integer;
  v_payload jsonb;
  v_attempt_id bigint;
  v_score integer;
  v_percent numeric;
begin
  if v_uid is null then raise exception 'not_authenticated' using errcode='28000'; end if;
  select * into v_s from public.practice_sessions_v4 s where s.id=p_session_id and s.user_id=v_uid for update;
  if v_s.id is null then raise exception 'session_not_found' using errcode='P0002'; end if;
  v_question_count := coalesce(cardinality(v_s.question_ids),0);
  if v_question_count not between 1 and 10 then raise exception 'invalid_session_question_count' using errcode='55000'; end if;
  if v_s.status='finalized' and v_s.legacy_attempt_id is not null then
    select pa.score,pa.percent into v_score,v_percent from public.practice_attempts pa where pa.id=v_s.legacy_attempt_id and pa.user_id=v_uid;
    return jsonb_build_object('ok',true,'session_id',v_s.id,'attempt_id',v_s.legacy_attempt_id,'score',coalesce(v_score,0),'percent',coalesce(v_percent,0),'question_count',v_question_count,'idempotent',true);
  end if;
  if v_s.status <> 'in_progress' then raise exception 'session_not_in_progress' using errcode='55000'; end if;
  select count(*)::integer into v_answered from public.practice_session_answers_v4 a where a.session_id=p_session_id and a.question_id=any(v_s.question_ids);
  if v_answered <> v_question_count then raise exception 'session_answers_incomplete' using errcode='55000'; end if;
  select jsonb_agg(jsonb_build_object('question_id',a.question_id,'user_answer',a.user_answer,'picked_index',a.picked_index,'time_spent',a.time_spent) order by x.ord)
  into v_payload
  from public.practice_session_answers_v4 a
  join lateral unnest(v_s.question_ids) with ordinality x(qid,ord) on x.qid=a.question_id
  where a.session_id=p_session_id;
  v_attempt_id := public.submit_practice_attempt(v_s.subject_id,0,0,greatest(coalesce(p_total_time,0),0),coalesce(v_payload,'[]'::jsonb));
  if v_attempt_id is null then raise exception 'practice_finalize_failed' using errcode='55000'; end if;
  update public.practice_sessions_v4 set status='finalized',legacy_attempt_id=v_attempt_id,finalized_at=now() where id=p_session_id and user_id=v_uid;
  select pa.score,pa.percent into v_score,v_percent from public.practice_attempts pa where pa.id=v_attempt_id and pa.user_id=v_uid;
  return jsonb_build_object('ok',true,'session_id',p_session_id,'attempt_id',v_attempt_id,'score',coalesce(v_score,0),'percent',coalesce(v_percent,0),'question_count',v_question_count,'idempotent',false);
end;
$function$;

revoke all on function public.submit_practice_session_answer_safe_v4(bigint,bigint,text,integer,integer) from public, anon;
grant execute on function public.submit_practice_session_answer_safe_v4(bigint,bigint,text,integer,integer) to authenticated, service_role;
revoke all on function public.finalize_practice_session_safe_v4(bigint,integer) from public, anon;
grant execute on function public.finalize_practice_session_safe_v4(bigint,integer) to authenticated, service_role;
