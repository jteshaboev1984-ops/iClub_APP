-- iClub APP — P0-02 Tour evaluator parity patch
-- BRANCH ONLY. Runs after the additive v3 contract.
-- Mirrors current Tour client input semantics so security migration does not change scoring.

begin;

create or replace function public.iclub_tour_input_is_correct_v3(
  p_user_answer text,
  p_expected_answer text
)
returns boolean
language plpgsql
immutable
set search_path=public,pg_temp
as $$
declare
  v_user text := trim(translate(coalesce(p_user_answer,''), '−–—', '---'));
  v_expected text := trim(translate(coalesce(p_expected_answer,''), '−–—', '---'));
  v_user_num double precision;
  v_expected_num double precision;
  v_diff double precision;
  v_scale double precision;
  v_expected_signed boolean;
begin
  if v_user='' or v_expected='' then return false; end if;

  -- Numeric mode: dot decimal, optional sign/e-notation, strict sign parity,
  -- relative tolerance 1e-9. This mirrors current Tour browser logic.
  if v_expected ~ '^[+-]?[0-9]+([.][0-9]+)?([eE][+-]?[0-9]+)?$' then
    if v_user !~ '^[+-]?[0-9]+([.][0-9]+)?([eE][+-]?[0-9]+)?$' then return false; end if;

    v_expected_signed := v_expected ~ '^[+-]';
    if v_expected_signed then
      if left(v_expected,1) <> left(v_user,1) then return false; end if;
    elsif v_user ~ '^[+-]' then
      return false;
    end if;

    begin
      v_user_num := v_user::double precision;
      v_expected_num := v_expected::double precision;
    exception when others then
      return false;
    end;

    v_diff := abs(v_user_num-v_expected_num);
    v_scale := greatest(1::double precision,abs(v_user_num),abs(v_expected_num));
    return v_diff <= v_scale*1e-9;
  end if;

  -- Formula/token mode: ASCII letter followed by alphanumerics, case-insensitive.
  if v_expected ~ '^[A-Z][A-Za-z0-9]*$' then
    if v_user !~ '^[A-Za-z][A-Za-z0-9]*$' then return false; end if;
    return lower(v_user)=lower(v_expected);
  end if;

  -- Free text fallback: normalize dash variants, remove whitespace, case-insensitive.
  return lower(regexp_replace(v_user,'\\s+','','g'))
       = lower(regexp_replace(v_expected,'\\s+','','g'));
end;
$$;

create or replace function public.iclub_eval_tour_question_safe_v3(
  p_question_id bigint,
  p_user_answer text,
  p_picked_index integer default null,
  p_answered boolean default true
)
returns jsonb
language plpgsql
security definer
set search_path=public,auth,pg_temp
as $$
declare
  v_q public.questions%rowtype;
  v_selected text;
  v_correct boolean := false;
begin
  select q.* into v_q from public.questions q
  where q.id=p_question_id and q.is_active is true;
  if v_q.id is null then raise exception 'question_not_found_or_inactive' using errcode='P0002'; end if;

  if coalesce(p_answered,true) is false then
    return jsonb_build_object('selected_answer',null,'is_correct',false);
  end if;

  if lower(coalesce(v_q.qtype,''))='mcq' then
    if p_picked_index is not null and p_picked_index between 0 and 25 then
      v_selected := chr(65+p_picked_index);
    elsif upper(trim(coalesce(p_user_answer,''))) ~ '^[A-Z]$' then
      v_selected := upper(trim(p_user_answer));
    elsif trim(coalesce(p_user_answer,'')) ~ '^[0-9]+$'
      and trim(p_user_answer)::integer between 0 and 25 then
      v_selected := chr(65+trim(p_user_answer)::integer);
    else
      v_selected := upper(trim(coalesce(p_user_answer,'')));
    end if;
    v_correct := upper(trim(coalesce(v_selected,'')))=upper(trim(coalesce(v_q.correct_answer,'')));
  else
    v_selected := trim(coalesce(p_user_answer,''));
    v_correct := public.iclub_tour_input_is_correct_v3(v_selected,v_q.correct_answer);
  end if;

  return jsonb_build_object('selected_answer',nullif(v_selected,''),'is_correct',v_correct);
end;
$$;

revoke all on function public.iclub_tour_input_is_correct_v3(text,text) from public,anon,authenticated;
revoke all on function public.iclub_eval_tour_question_safe_v3(bigint,text,integer,boolean) from public,anon,authenticated;

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
  v_count integer;
begin
  if v_uid is null then raise exception 'not_authenticated' using errcode='28000'; end if;

  select * into v_rt from public.tour_session_runtime_v3 r
  where r.attempt_id=p_attempt_id and r.user_id=v_uid;
  if v_rt.attempt_id is null then raise exception 'tour_session_not_found' using errcode='P0002'; end if;
  if v_rt.finalized_at is not null then raise exception 'tour_session_finalized' using errcode='55000'; end if;
  if not (p_question_id=any(v_rt.question_ids)) then raise exception 'question_not_in_tour_session' using errcode='22023'; end if;

  v_eval := public.iclub_eval_tour_question_safe_v3(
    p_question_id,p_user_answer,p_picked_index,coalesce(p_answered,true)
  );

  insert into public.tour_session_answers_v3(
    attempt_id,question_id,user_answer,answered,is_correct,time_spent,finish_reason,answered_at
  ) values(
    p_attempt_id,p_question_id,v_eval->>'selected_answer',coalesce(p_answered,true),
    coalesce((v_eval->>'is_correct')::boolean,false),greatest(coalesce(p_time_spent,0),0),
    nullif(trim(coalesce(p_finish_reason,'')),''),now()
  )
  on conflict(attempt_id,question_id) do update set
    user_answer=excluded.user_answer,
    answered=excluded.answered,
    is_correct=excluded.is_correct,
    time_spent=excluded.time_spent,
    finish_reason=excluded.finish_reason,
    answered_at=now();

  select count(*)::integer into v_count
  from public.tour_session_answers_v3 a where a.attempt_id=p_attempt_id;

  return jsonb_build_object(
    'ok',true,'attempt_id',p_attempt_id,'question_id',p_question_id,
    'recorded',true,'recorded_count',v_count,'question_count',cardinality(v_rt.question_ids)
  );
end;
$$;

revoke all on function public.submit_tour_answer_safe_v3(bigint,bigint,text,integer,integer,boolean,text) from public,anon;
grant execute on function public.submit_tour_answer_safe_v3(bigint,bigint,text,integer,integer,boolean,text) to authenticated;

commit;
