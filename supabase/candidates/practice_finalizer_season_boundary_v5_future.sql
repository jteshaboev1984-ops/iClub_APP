-- #574 · SOURCE-ONLY FUTURE CANDIDATE; NEVER installed by this PR.
-- Exact installed function captured via hosted pg_get_functiondef SELECT on
-- 2026-11-19; MD5 for drift preflight: c002f4b8856233b0c05845fed0d19f6e.
-- Only change: preserve S1 attribution when an already-started S1 Tour Practice
-- finishes AFTER its own S2 Tour1 official opening. Other finalizations use
-- original now(), scores/answers/diagnostics/status/idempotency unchanged.
-- This is not a new scoring or bank-generation policy. Requires separate
-- owner GO, source-diff approval and isolated signed HTTP before live install.
begin;

CREATE OR REPLACE FUNCTION public.finalize_practice_session_safe_v5(p_session_id bigint, p_total_time integer)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'private', 'auth', 'pg_temp'
AS $function$
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
  v_subject_s2_cutoff timestamptz;
  v_attempt_period_time timestamptz;
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

  -- The existing finalizer creates its Practice attempt on completion.
  -- An S1 quiz started before its subject's official S2 Tour1 cutoff may
  -- complete afterwards. Store the verified SESSION START time only for
  -- that boundary case, so the attempt belongs to Season1 History.
  -- All ordinary attempts keep the original now() created_at semantics.
  v_attempt_period_time:=now();
  select (t.start_date::timestamp at time zone 'Asia/Tashkent')
    into v_subject_s2_cutoff
  from public.seasons sn
  join public.tours t on t.season_id=sn.id
    and t.subject_id=v_s.subject_id and t.tour_no=1
  where sn.season_no=2
    and sn.status in ('current','closed')
    and t.start_date is not null and t.end_date is not null
    and t.start_date<=t.end_date
    and (t.start_date::timestamp at time zone 'Asia/Tashkent') <= statement_timestamp()
    and v_s.created_at < (t.start_date::timestamp at time zone 'Asia/Tashkent')
  order by t.start_date asc limit 1;
  if v_subject_s2_cutoff is not null then
    v_attempt_period_time:=v_s.created_at;
  end if;

  insert into public.practice_attempts(
    user_id,subject_id,score,percent,time_seconds,is_lab,created_at
  ) values(
    v_uid,
    v_s.subject_id,
    v_score,
    v_percent,
    greatest(coalesce(p_total_time,0),0),
    false,
    v_attempt_period_time
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
$function$

revoke all on function public.finalize_practice_session_safe_v5(bigint,integer)
  from public,anon;
grant execute on function public.finalize_practice_session_safe_v5(bigint,integer)
  to authenticated,service_role;

commit;
