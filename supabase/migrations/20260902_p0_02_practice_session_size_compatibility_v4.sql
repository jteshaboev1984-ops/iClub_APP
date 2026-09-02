-- iClub APP — P0-02 Practice session size compatibility fix
-- Current production Practice builds UP TO 10 unanswered questions.
-- Near pool exhaustion, a valid final session may contain fewer than 10.
-- This replaces only the unused v4 start RPC; no historical rows are rewritten.

begin;

create or replace function public.start_practice_session_safe_v4(
  p_pool_id bigint,
  p_client_session_id text,
  p_question_ids bigint[]
)
returns jsonb
language plpgsql
security definer
set search_path = public, auth, pg_temp
as $$
declare
  v_uid uuid := auth.uid();
  v_pool public.practice_pools%rowtype;
  v_s public.practice_sessions_v4%rowtype;
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
  from public.practice_sessions_v4 s
  where s.user_id=v_uid and s.client_session_id=trim(p_client_session_id)
  limit 1;

  if v_s.id is not null then
    if v_s.pool_id <> p_pool_id then
      raise exception 'client_session_scope_mismatch' using errcode='22023';
    end if;
    return jsonb_build_object(
      'session_id',v_s.id,
      'status',v_s.status,
      'question_count',cardinality(v_s.question_ids),
      'legacy_attempt_id',v_s.legacy_attempt_id,
      'resumed',true
    );
  end if;

  select * into v_pool
  from public.practice_pools p
  where p.id=p_pool_id and p.is_active is true;

  if v_pool.id is null then
    raise exception 'pool_not_found_or_inactive' using errcode='P0002';
  end if;

  if p_question_ids is null or cardinality(p_question_ids) not between 1 and 10 then
    raise exception 'practice_question_selection_must_have_1_to_10' using errcode='22023';
  end if;

  select array_agg(x.qid order by x.ord)
  into v_qids
  from unnest(p_question_ids) with ordinality x(qid,ord)
  where x.qid is not null;

  v_total := coalesce(cardinality(v_qids),0);

  if v_total not between 1 and 10 then
    raise exception 'practice_question_selection_must_have_1_to_10' using errcode='22023';
  end if;

  if (select count(distinct qid) from unnest(v_qids) q(qid)) <> v_total then
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

  insert into public.practice_sessions_v4(
    user_id,subject_id,pool_id,client_session_id,question_ids
  ) values(
    v_uid,v_pool.subject_id,p_pool_id,trim(p_client_session_id),v_qids
  ) returning * into v_s;

  return jsonb_build_object(
    'session_id',v_s.id,
    'status',v_s.status,
    'question_count',v_total,
    'legacy_attempt_id',null,
    'resumed',false
  );
exception when unique_violation then
  select * into v_s
  from public.practice_sessions_v4 s
  where s.user_id=v_uid and s.client_session_id=trim(p_client_session_id)
  limit 1;

  if v_s.id is null then raise; end if;
  if v_s.pool_id <> p_pool_id then
    raise exception 'client_session_scope_mismatch' using errcode='22023';
  end if;

  return jsonb_build_object(
    'session_id',v_s.id,
    'status',v_s.status,
    'question_count',cardinality(v_s.question_ids),
    'legacy_attempt_id',v_s.legacy_attempt_id,
    'resumed',true
  );
end;
$$;

revoke all on function public.start_practice_session_safe_v4(bigint,text,bigint[]) from public,anon;
grant execute on function public.start_practice_session_safe_v4(bigint,text,bigint[]) to authenticated;

comment on function public.start_practice_session_safe_v4(bigint,text,bigint[]) is
'P0-02 safe Practice start. Accepts 1-10 active questions from one active pool, preserving short final sessions near pool exhaustion.';

commit;
