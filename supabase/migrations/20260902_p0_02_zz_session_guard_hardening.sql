-- iClub APP — P0-02 session guard hardening
-- Runs after v3 contract + Tour evaluator parity patch.
-- Additive/replacement-only for new v3 RPCs. Does not rewrite historical data.

begin;

-- =========================================================
-- 1. Practice start: preserve legacy 10-question session semantics
--    and bind a client session id to exactly one pool.
-- =========================================================

create or replace function public.start_practice_session_safe_v3(
  p_pool_id bigint,
  p_client_session_id text,
  p_question_ids bigint[] default null
)
returns jsonb
language plpgsql
security definer
set search_path = public, auth, pg_temp
as $$
declare
  v_uid uuid := auth.uid();
  v_pool public.practice_pools%rowtype;
  v_s public.practice_sessions_v3%rowtype;
  v_qids bigint[];
  v_total integer;
  v_allowed integer;
begin
  if v_uid is null then raise exception 'not_authenticated' using errcode='28000'; end if;
  if p_pool_id is null or p_pool_id <= 0 then raise exception 'invalid_pool_id' using errcode='22023'; end if;
  if p_client_session_id is null or length(trim(p_client_session_id)) not between 8 and 128 then
    raise exception 'invalid_client_session_id' using errcode='22023';
  end if;

  select * into v_s
  from public.practice_sessions_v3 s
  where s.user_id=v_uid and s.client_session_id=trim(p_client_session_id)
  limit 1;

  if v_s.id is not null then
    if v_s.pool_id <> p_pool_id then
      raise exception 'client_session_scope_mismatch' using errcode='22023';
    end if;
    return jsonb_build_object(
      'session_id',v_s.id,'status',v_s.status,
      'question_count',cardinality(v_s.question_ids),
      'legacy_attempt_id',v_s.legacy_attempt_id,'resumed',true
    );
  end if;

  select * into v_pool
  from public.practice_pools p
  where p.id=p_pool_id and p.is_active is true;
  if v_pool.id is null then raise exception 'pool_not_found_or_inactive' using errcode='P0002'; end if;

  -- Current production Practice attempts are 10-question sessions.
  -- The existing client selects the concrete 10 IDs (including its no-repeat logic);
  -- the server validates that exact set rather than trusting score/correctness.
  if p_question_ids is null or cardinality(p_question_ids) <> 10 then
    raise exception 'practice_question_selection_must_have_10' using errcode='22023';
  end if;

  select array_agg(x.qid order by x.ord)
  into v_qids
  from unnest(p_question_ids) with ordinality x(qid,ord)
  where x.qid is not null;

  v_total := coalesce(cardinality(v_qids),0);
  if v_total <> 10 then raise exception 'practice_question_selection_must_have_10' using errcode='22023'; end if;

  if (select count(distinct x) from unnest(v_qids) x) <> v_total then
    raise exception 'duplicate_question_ids' using errcode='22023';
  end if;

  select count(*)::integer into v_allowed
  from public.practice_pool_questions ppq
  join public.questions q on q.id=ppq.question_id
  where ppq.pool_id=p_pool_id
    and ppq.is_active is true
    and q.is_active is true
    and q.subject_id=v_pool.subject_id
    and ppq.question_id=any(v_qids);

  if v_allowed <> v_total then
    raise exception 'question_not_in_active_pool' using errcode='22023';
  end if;

  insert into public.practice_sessions_v3(user_id,subject_id,pool_id,client_session_id,question_ids)
  values(v_uid,v_pool.subject_id,p_pool_id,trim(p_client_session_id),v_qids)
  returning * into v_s;

  return jsonb_build_object(
    'session_id',v_s.id,'status',v_s.status,'question_count',v_total,
    'legacy_attempt_id',null,'resumed',false
  );
exception when unique_violation then
  select * into v_s
  from public.practice_sessions_v3 s
  where s.user_id=v_uid and s.client_session_id=trim(p_client_session_id)
  limit 1;
  if v_s.id is null then raise; end if;
  if v_s.pool_id <> p_pool_id then
    raise exception 'client_session_scope_mismatch' using errcode='22023';
  end if;
  return jsonb_build_object(
    'session_id',v_s.id,'status',v_s.status,
    'question_count',cardinality(v_s.question_ids),
    'legacy_attempt_id',v_s.legacy_attempt_id,'resumed',true
  );
end;
$$;

-- =========================================================
-- 2. Practice submit: first accepted answer is immutable.
--    Retries are idempotent; a changed retry cannot improve the score
--    after the correct answer has already been revealed.
-- =========================================================

create or replace function public.submit_practice_session_answer_safe_v3(
  p_session_id bigint,
  p_question_id bigint,
  p_user_answer text,
  p_picked_index integer,
  p_time_spent integer
)
returns jsonb
language plpgsql
security definer
set search_path = public, auth, pg_temp
as $$
declare
  v_uid uuid := auth.uid();
  v_s public.practice_sessions_v3%rowtype;
  v_q public.questions%rowtype;
  v_eval jsonb;
  v_saved public.practice_session_answers_v3%rowtype;
  v_answered integer;
  v_score integer;
  v_was_existing boolean := false;
begin
  if v_uid is null then raise exception 'not_authenticated' using errcode='28000'; end if;

  select * into v_s
  from public.practice_sessions_v3 s
  where s.id=p_session_id and s.user_id=v_uid;
  if v_s.id is null then raise exception 'session_not_found' using errcode='P0002'; end if;
  if v_s.status <> 'in_progress' then raise exception 'session_not_in_progress' using errcode='55000'; end if;
  if not (p_question_id=any(v_s.question_ids)) then raise exception 'question_not_in_session' using errcode='22023'; end if;

  select * into v_q
  from public.questions q
  where q.id=p_question_id and q.is_active is true and q.subject_id=v_s.subject_id;
  if v_q.id is null then raise exception 'question_not_found_or_subject_mismatch' using errcode='P0002'; end if;

  select * into v_saved
  from public.practice_session_answers_v3 a
  where a.session_id=p_session_id and a.question_id=p_question_id;
  v_was_existing := v_saved.session_id is not null;

  if not v_was_existing then
    v_eval := public.iclub_eval_question_safe_v3(p_question_id,p_user_answer,p_picked_index);

    insert into public.practice_session_answers_v3(
      session_id,question_id,user_answer,picked_index,is_correct,time_spent,answered_at
    ) values(
      p_session_id,p_question_id,v_eval->>'selected_answer',p_picked_index,
      coalesce((v_eval->>'is_correct')::boolean,false),
      greatest(coalesce(p_time_spent,0),0),now()
    )
    on conflict(session_id,question_id) do nothing;

    select * into v_saved
    from public.practice_session_answers_v3 a
    where a.session_id=p_session_id and a.question_id=p_question_id;
  end if;

  if v_saved.session_id is null then
    raise exception 'practice_answer_save_failed' using errcode='55000';
  end if;

  select count(*)::integer,count(*) filter(where a.is_correct is true)::integer
  into v_answered,v_score
  from public.practice_session_answers_v3 a
  where a.session_id=p_session_id;

  return jsonb_build_object(
    'ok',true,'session_id',p_session_id,'question_id',p_question_id,
    'is_correct',v_saved.is_correct,
    'answered',v_answered,'score_so_far',v_score,'question_count',cardinality(v_s.question_ids),
    'correct_answer',v_q.correct_answer,
    'explanation',v_q.explanation,
    'explanation_ru',v_q.explanation_ru,
    'explanation_uz',v_q.explanation_uz,
    'explanation_en',v_q.explanation_en,
    'idempotent',v_was_existing
  );
end;
$$;

-- =========================================================
-- 3. Tour start: enforce server-side eligibility and exact 20-question Tour.
--    A client session id is bound to exactly one Tour.
-- =========================================================

create or replace function public.start_tour_attempt_safe_v3(
  p_tour_id bigint,
  p_client_session_id text
)
returns jsonb
language plpgsql
security definer
set search_path = public, auth, pg_temp
as $$
declare
  v_uid uuid := auth.uid();
  v_tour public.tours%rowtype;
  v_attempt public.tour_attempts%rowtype;
  v_rt public.tour_session_runtime_v3%rowtype;
  v_qids bigint[];
  v_attempt_id bigint;
  v_today date := (now() at time zone 'Asia/Tashkent')::date;
begin
  if v_uid is null then raise exception 'not_authenticated' using errcode='28000'; end if;
  if p_tour_id is null or p_tour_id <= 0 then raise exception 'invalid_tour_id' using errcode='22023'; end if;
  if p_client_session_id is null or length(trim(p_client_session_id)) not between 8 and 128 then
    raise exception 'invalid_client_session_id' using errcode='22023';
  end if;

  select * into v_rt
  from public.tour_session_runtime_v3 r
  where r.user_id=v_uid and r.client_session_id=trim(p_client_session_id)
  limit 1;

  if v_rt.attempt_id is not null then
    if v_rt.tour_id <> p_tour_id then
      raise exception 'client_session_scope_mismatch' using errcode='22023';
    end if;
    return jsonb_build_object(
      'attempt_id',v_rt.attempt_id,'question_count',cardinality(v_rt.question_ids),
      'finalized',v_rt.finalized_at is not null,'resumed',true
    );
  end if;

  select * into v_tour
  from public.tours t
  where t.id=p_tour_id and t.is_active is true;
  if v_tour.id is null then raise exception 'tour_not_found_or_inactive' using errcode='P0002'; end if;

  if v_tour.start_date is null or v_tour.end_date is null
     or v_today < v_tour.start_date or v_today > v_tour.end_date then
    raise exception 'tour_not_open' using errcode='55000';
  end if;

  if not exists(
    select 1 from public.users u
    where u.id=v_uid and coalesce(u.is_school_student,false) is true
  ) then
    raise exception 'tour_requires_school_student' using errcode='42501';
  end if;

  if not exists(
    select 1 from public.user_subjects us
    where us.user_id=v_uid
      and us.subject_id=v_tour.subject_id
      and us.mode='competitive'
  ) then
    raise exception 'tour_subject_not_competitive_for_user' using errcode='42501';
  end if;

  select * into v_attempt
  from public.tour_attempts a
  where a.user_id=v_uid and a.tour_id=p_tour_id
  limit 1;

  if v_attempt.id is not null then
    select * into v_rt
    from public.tour_session_runtime_v3 r
    where r.attempt_id=v_attempt.id and r.user_id=v_uid;

    if v_rt.attempt_id is not null and v_rt.finalized_at is null then
      return jsonb_build_object(
        'attempt_id',v_rt.attempt_id,'question_count',cardinality(v_rt.question_ids),
        'finalized',false,'resumed',true
      );
    end if;

    raise exception 'already_attempted' using errcode='23505';
  end if;

  select array_agg(tq.question_id order by tq.order_no,tq.id)
  into v_qids
  from public.tour_questions tq
  join public.questions q on q.id=tq.question_id and q.is_active is true
  where tq.tour_id=p_tour_id
    and tq.is_active is true
    and q.subject_id=v_tour.subject_id;

  if coalesce(cardinality(v_qids),0) <> 20 then
    raise exception 'tour_question_count_not_20' using errcode='55000';
  end if;

  insert into public.tour_attempts(user_id,tour_id,score,percent,total_time,status)
  values(v_uid,p_tour_id,0,0,0,'submitted')
  returning id into v_attempt_id;

  insert into public.tour_session_runtime_v3(
    attempt_id,user_id,tour_id,client_session_id,question_ids
  ) values(
    v_attempt_id,v_uid,p_tour_id,trim(p_client_session_id),v_qids
  );

  return jsonb_build_object(
    'attempt_id',v_attempt_id,'question_count',cardinality(v_qids),
    'finalized',false,'resumed',false
  );
exception when unique_violation then
  select * into v_attempt
  from public.tour_attempts a
  where a.user_id=v_uid and a.tour_id=p_tour_id
  limit 1;
  if v_attempt.id is null then raise; end if;

  select * into v_rt
  from public.tour_session_runtime_v3 r
  where r.attempt_id=v_attempt.id and r.user_id=v_uid;

  if v_rt.attempt_id is null or v_rt.finalized_at is not null then
    raise exception 'already_attempted' using errcode='23505';
  end if;

  return jsonb_build_object(
    'attempt_id',v_rt.attempt_id,'question_count',cardinality(v_rt.question_ids),
    'finalized',false,'resumed',true
  );
end;
$$;

-- =========================================================
-- 4. Tour submit: server-enforce no-back/first-answer law.
--    Retries are idempotent and still reveal no correctness.
-- =========================================================

create or replace function public.submit_tour_answer_safe_v3(
  p_attempt_id bigint,
  p_question_id bigint,
  p_user_answer text,
  p_picked_index integer,
  p_time_spent integer,
  p_answered boolean default true,
  p_finish_reason text default null
)
returns jsonb
language plpgsql
security definer
set search_path=public,auth,pg_temp
as $$
declare
  v_uid uuid := auth.uid();
  v_rt public.tour_session_runtime_v3%rowtype;
  v_eval jsonb;
  v_saved public.tour_session_answers_v3%rowtype;
  v_count integer;
  v_was_existing boolean := false;
begin
  if v_uid is null then raise exception 'not_authenticated' using errcode='28000'; end if;

  select * into v_rt
  from public.tour_session_runtime_v3 r
  where r.attempt_id=p_attempt_id and r.user_id=v_uid;
  if v_rt.attempt_id is null then raise exception 'tour_session_not_found' using errcode='P0002'; end if;
  if v_rt.finalized_at is not null then raise exception 'tour_session_finalized' using errcode='55000'; end if;
  if not (p_question_id=any(v_rt.question_ids)) then raise exception 'question_not_in_tour_session' using errcode='22023'; end if;

  select * into v_saved
  from public.tour_session_answers_v3 a
  where a.attempt_id=p_attempt_id and a.question_id=p_question_id;
  v_was_existing := v_saved.attempt_id is not null;

  if not v_was_existing then
    v_eval := public.iclub_eval_tour_question_safe_v3(
      p_question_id,p_user_answer,p_picked_index,coalesce(p_answered,true)
    );

    insert into public.tour_session_answers_v3(
      attempt_id,question_id,user_answer,answered,is_correct,time_spent,finish_reason,answered_at
    ) values(
      p_attempt_id,p_question_id,v_eval->>'selected_answer',coalesce(p_answered,true),
      coalesce((v_eval->>'is_correct')::boolean,false),
      greatest(coalesce(p_time_spent,0),0),
      nullif(trim(coalesce(p_finish_reason,'')),''),now()
    )
    on conflict(attempt_id,question_id) do nothing;

    select * into v_saved
    from public.tour_session_answers_v3 a
    where a.attempt_id=p_attempt_id and a.question_id=p_question_id;
  end if;

  if v_saved.attempt_id is null then
    raise exception 'tour_answer_save_failed' using errcode='55000';
  end if;

  select count(*)::integer into v_count
  from public.tour_session_answers_v3 a
  where a.attempt_id=p_attempt_id;

  return jsonb_build_object(
    'ok',true,'attempt_id',p_attempt_id,'question_id',p_question_id,
    'recorded',true,'recorded_count',v_count,
    'question_count',cardinality(v_rt.question_ids),
    'idempotent',v_was_existing
  );
end;
$$;

-- Keep intended browser grants after CREATE OR REPLACE.
revoke all on function public.start_practice_session_safe_v3(bigint,text,bigint[]) from public,anon;
revoke all on function public.submit_practice_session_answer_safe_v3(bigint,bigint,text,integer,integer) from public,anon;
revoke all on function public.start_tour_attempt_safe_v3(bigint,text) from public,anon;
revoke all on function public.submit_tour_answer_safe_v3(bigint,bigint,text,integer,integer,boolean,text) from public,anon;

grant execute on function public.start_practice_session_safe_v3(bigint,text,bigint[]) to authenticated;
grant execute on function public.submit_practice_session_answer_safe_v3(bigint,bigint,text,integer,integer) to authenticated;
grant execute on function public.start_tour_attempt_safe_v3(bigint,text) to authenticated;
grant execute on function public.submit_tour_answer_safe_v3(bigint,bigint,text,integer,integer,boolean,text) to authenticated;

comment on function public.start_practice_session_safe_v3(bigint,text,bigint[]) is
'P0-02 Practice start: exactly 10 active pool questions; client session is pool-bound.';
comment on function public.submit_practice_session_answer_safe_v3(bigint,bigint,text,integer,integer) is
'P0-02 Practice submit: first accepted answer is immutable; retries are idempotent.';
comment on function public.start_tour_attempt_safe_v3(bigint,text) is
'P0-02 Tour start: date, school-student, competitive-subject, one-attempt, and 20-question guards.';
comment on function public.submit_tour_answer_safe_v3(bigint,bigint,text,integer,integer,boolean,text) is
'P0-02 Tour submit: server-enforced no-back; first accepted answer immutable; no correctness returned.';

commit;
