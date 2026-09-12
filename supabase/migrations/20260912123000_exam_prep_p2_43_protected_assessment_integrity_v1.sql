begin;

-- P2-43: protected-assessment integrity foundation.
-- Additive only: no legacy Practice/Tours mutation and no learner-history rewrite.
-- Browser focus signals are evidence for integrity review, not a security boundary.
-- Two or more recorded exits make strict timed/full-paper results non-comparable;
-- learning/correction work remains unaffected and protected attempts are never deleted.

create table if not exists private.exam_prep_integrity_events (
  id uuid primary key default gen_random_uuid(),
  session_id uuid not null references private.exam_prep_sessions(id) on delete restrict,
  user_id uuid not null references public.users(id) on delete cascade,
  event_type text not null check(event_type in ('visibility_hidden','window_blur')),
  client_event_id text not null check(char_length(client_event_id) between 8 and 160),
  recorded_at timestamptz not null default now(),
  unique(session_id,user_id,client_event_id)
);

create index if not exists exam_prep_integrity_events_session_idx
  on private.exam_prep_integrity_events(session_id,recorded_at,id);

alter table private.exam_prep_integrity_events enable row level security;
revoke all on private.exam_prep_integrity_events from public,anon,authenticated;
grant all on private.exam_prep_integrity_events to service_role;

drop trigger if exists exam_prep_integrity_events_immutable_v1 on private.exam_prep_integrity_events;
create trigger exam_prep_integrity_events_immutable_v1
before update or delete on private.exam_prep_integrity_events
for each row execute function private.exam_prep_block_immutable_mutation_v1();

create or replace function private.exam_prep_session_is_protected_v1(p_session_id uuid)
returns boolean
language sql
stable
security definer
set search_path=''
as $$
  select coalesce((
    select
      s.session_type in ('diagnostic','retest','mixed','timed','paper')
      or exists(
        select 1
        from private.exam_prep_session_items si
        where si.session_id=s.id
          and coalesce(si.reserve_role,'') in ('diagnostic','retest','mixed','timed','unseen')
      )
    from private.exam_prep_sessions s
    where s.id=p_session_id
  ),false);
$$;
revoke all on function private.exam_prep_session_is_protected_v1(uuid) from public,anon,authenticated;
grant execute on function private.exam_prep_session_is_protected_v1(uuid) to service_role;

create or replace function private.exam_prep_integrity_status_v1(p_session_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path=''
as $$
declare
  v_s private.exam_prep_sessions%rowtype;
  v_protected boolean:=false;
  v_count integer:=0;
  v_status text:='not_applicable';
  v_review boolean:=false;
  v_allows_comparability boolean:=true;
begin
  select * into v_s from private.exam_prep_sessions where id=p_session_id;
  if v_s.id is null then
    return jsonb_build_object(
      'policy_version','exam_prep_integrity_v1',
      'session_id',p_session_id,
      'protected',false,
      'event_count',0,
      'status','not_found',
      'review_required',false,
      'integrity_allows_comparability',false
    );
  end if;

  v_protected:=private.exam_prep_session_is_protected_v1(v_s.id);
  if v_protected then
    select count(*)::integer into v_count
    from private.exam_prep_integrity_events e
    where e.session_id=v_s.id and e.user_id=v_s.user_id;

    if v_count=0 then
      v_status:='clean';
    elsif v_count=1 then
      v_status:='warning';
    else
      v_status:='review_required';
      v_review:=true;
    end if;
  end if;

  if v_s.session_type in ('timed','paper') and v_review then
    v_allows_comparability:=false;
  end if;

  return jsonb_build_object(
    'policy_version','exam_prep_integrity_v1',
    'session_id',v_s.id,
    'component_code',v_s.component_code,
    'session_type',v_s.session_type,
    'session_status',v_s.status,
    'protected',v_protected,
    'event_count',v_count,
    'status',v_status,
    'review_required',v_review,
    'integrity_allows_comparability',v_allows_comparability
  );
end;
$$;
revoke all on function private.exam_prep_integrity_status_v1(uuid) from public,anon,authenticated;
grant execute on function private.exam_prep_integrity_status_v1(uuid) to service_role;

create or replace function private.exam_prep_integrity_allows_timed_comparability_v1(p_session_id uuid)
returns boolean
language sql
stable
security definer
set search_path=''
as $$
  select coalesce((private.exam_prep_integrity_status_v1(p_session_id)->>'integrity_allows_comparability')::boolean,false);
$$;
revoke all on function private.exam_prep_integrity_allows_timed_comparability_v1(uuid) from public,anon,authenticated;
grant execute on function private.exam_prep_integrity_allows_timed_comparability_v1(uuid) to service_role;

create or replace function public.get_exam_prep_integrity_status_safe_v1(p_session_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path=''
as $$
declare
  v_uid uuid;
  v_s private.exam_prep_sessions%rowtype;
begin
  v_uid:=private.exam_prep_require_core_access_v1();
  select * into v_s
  from private.exam_prep_sessions
  where id=p_session_id and user_id=v_uid;
  if v_s.id is null then raise exception 'exam_prep_session_not_found' using errcode='P0002'; end if;
  return private.exam_prep_integrity_status_v1(v_s.id);
end;
$$;
revoke execute on function public.get_exam_prep_integrity_status_safe_v1(uuid) from public,anon;
grant execute on function public.get_exam_prep_integrity_status_safe_v1(uuid) to authenticated,service_role;

create or replace function public.record_exam_prep_integrity_event_safe_v1(
  p_session_id uuid,
  p_event_type text,
  p_client_event_id text
)
returns jsonb
language plpgsql
security definer
set search_path=''
as $$
declare
  v_uid uuid;
  v_s private.exam_prep_sessions%rowtype;
  v_inserted integer:=0;
  v_status jsonb;
begin
  v_uid:=private.exam_prep_require_core_access_v1();
  if p_session_id is null then raise exception 'exam_prep_session_required'; end if;
  if p_event_type not in ('visibility_hidden','window_blur') then raise exception 'exam_prep_integrity_bad_event_type'; end if;
  if p_client_event_id is null or char_length(p_client_event_id) not between 8 and 160 then
    raise exception 'exam_prep_integrity_bad_client_event_id';
  end if;

  select * into v_s
  from private.exam_prep_sessions
  where id=p_session_id and user_id=v_uid
  for update;
  if v_s.id is null then raise exception 'exam_prep_session_not_found' using errcode='P0002'; end if;

  if v_s.status<>'active' then
    return private.exam_prep_integrity_status_v1(v_s.id) || jsonb_build_object(
      'recorded',false,'replayed',false,'reason','session_not_active'
    );
  end if;

  if not private.exam_prep_session_is_protected_v1(v_s.id) then
    return private.exam_prep_integrity_status_v1(v_s.id) || jsonb_build_object(
      'recorded',false,'replayed',false,'reason','not_protected'
    );
  end if;

  insert into private.exam_prep_integrity_events(session_id,user_id,event_type,client_event_id)
  values(v_s.id,v_uid,p_event_type,p_client_event_id)
  on conflict(session_id,user_id,client_event_id) do nothing;
  get diagnostics v_inserted=row_count;

  v_status:=private.exam_prep_integrity_status_v1(v_s.id);
  return v_status || jsonb_build_object(
    'recorded',(v_inserted=1),
    'replayed',(v_inserted=0),
    'reason',case when v_inserted=1 then 'recorded' else 'idempotent_replay' end
  );
end;
$$;
revoke execute on function public.record_exam_prep_integrity_event_safe_v1(uuid,text,text) from public,anon;
grant execute on function public.record_exam_prep_integrity_event_safe_v1(uuid,text,text) to authenticated,service_role;

-- Strict timed/full-paper comparability is interpreted dynamically, so historical
-- rows are preserved and a flagged attempt simply stops qualifying for readiness.
create or replace function private.exam_prep_timed_score_comparable_v1(p_session_id uuid)
returns boolean
language sql
stable security definer
set search_path=''
as $$
  select coalesce((
    select t.timing_comparable
       and t.server_elapsed_sec>0
       and t.attempt_kind<>'diagnostic_full'
       and private.exam_prep_integrity_allows_timed_comparability_v1(t.session_id)
       and coalesce(nullif(s.timing_contract->>'paper_comparability_epoch','')::int,1)=coalesce(p.paper_comparability_epoch,1)
       and (
         nullif(trim(p.exam_series),'') is null
         or lower(trim(coalesce(nullif(s.timing_contract->>'exam_series_snapshot',''),p.exam_series)))=lower(trim(p.exam_series))
       )
       and greatest(
             0,
             t.pending_review_in_time_marks - coalesce((
               select sum(sm.max_marks)
               from private.exam_prep_timed_written_self_marks sm
               where sm.session_id=t.session_id and sm.was_in_time
             ),0)
           )=0
       and greatest(
             0,
             t.pending_review_after_time_marks - coalesce((
               select sum(sm.max_marks)
               from private.exam_prep_timed_written_self_marks sm
               where sm.session_id=t.session_id and not sm.was_in_time
             ),0)
           )=0
    from private.exam_prep_timed_attempt_results t
    join private.exam_prep_sessions s on s.id=t.session_id
    join private.exam_prep_exam_profiles p on p.user_id=t.user_id and p.program_version_id=s.program_version_id
    where t.session_id=p_session_id
  ),false);
$$;
revoke all on function private.exam_prep_timed_score_comparable_v1(uuid) from public,anon,authenticated;
grant execute on function private.exam_prep_timed_score_comparable_v1(uuid) to service_role;

create or replace function public.get_exam_prep_timed_result_safe_v1(p_session_id uuid)
returns jsonb
language plpgsql
stable security definer
set search_path=''
as $$
declare
  v_uid uuid; v_b private.exam_prep_timed_attempt_results%rowtype;
  v_self_in integer:=0; v_self_after integer:=0; v_self_in_max integer:=0; v_self_after_max integer:=0;
  v_pending_in integer; v_pending_after integer; v_earned_in integer; v_earned_after integer; v_lost_in integer; v_lost_after integer; v_score_comp boolean;
  v_integrity jsonb;
begin
  v_uid:=private.exam_prep_require_core_access_v1();
  select * into v_b from private.exam_prep_timed_attempt_results where session_id=p_session_id and user_id=v_uid;
  if v_b.session_id is null then raise exception 'exam_prep_timed_result_not_found' using errcode='P0002'; end if;
  select
    coalesce(sum(marks_awarded) filter(where was_in_time),0),coalesce(sum(marks_awarded) filter(where not was_in_time),0),
    coalesce(sum(max_marks) filter(where was_in_time),0),coalesce(sum(max_marks) filter(where not was_in_time),0)
    into v_self_in,v_self_after,v_self_in_max,v_self_after_max
  from private.exam_prep_timed_written_self_marks where session_id=v_b.session_id and user_id=v_uid;
  v_pending_in:=greatest(0,v_b.pending_review_in_time_marks-v_self_in_max);
  v_pending_after:=greatest(0,v_b.pending_review_after_time_marks-v_self_after_max);
  v_earned_in:=v_b.objective_marks_in_time+v_self_in;
  v_earned_after:=v_b.objective_marks_after_time+v_self_after;
  v_lost_in:=v_b.objective_lost_in_time_marks+(v_self_in_max-v_self_in);
  v_lost_after:=v_b.objective_lost_after_time_marks+(v_self_after_max-v_self_after);
  v_integrity:=private.exam_prep_integrity_status_v1(v_b.session_id);
  v_score_comp:=private.exam_prep_timed_score_comparable_v1(v_b.session_id);
  return jsonb_build_object(
    'session_id',v_b.session_id,'component_code',v_b.component_code,'attempt_kind',v_b.attempt_kind,'timing_rule',v_b.timing_rule,
    'comparison_scope',v_b.comparison_scope,'comparability_key',v_b.comparability_key,'strict_timing',v_b.strict_timing,
    'marks_available',v_b.marks_available,'time_limit_sec',v_b.time_limit_sec,'server_elapsed_sec',v_b.server_elapsed_sec,
    'answered_items',v_b.answered_items,'unattempted_items',v_b.unattempted_items,
    'marks_in_time',v_earned_in,'marks_after_time',v_earned_after,
    'lost_answered_marks_in_time',v_lost_in,'lost_answered_marks_after_time',v_lost_after,
    'pending_review_in_time_marks',v_pending_in,'pending_review_after_time_marks',v_pending_after,
    'unattempted_marks',v_b.unattempted_marks,'completion_reason',v_b.completion_reason,
    'timing_comparable',(v_b.timing_comparable and v_b.server_elapsed_sec>0 and coalesce((v_integrity->>'integrity_allows_comparability')::boolean,false)),
    'score_comparable',v_score_comp,
    'integrity_policy_version',v_integrity->>'policy_version',
    'integrity_status',v_integrity->>'status',
    'integrity_event_count',coalesce((v_integrity->>'event_count')::integer,0),
    'integrity_review_required',coalesce((v_integrity->>'review_required')::boolean,false),
    'in_time_percent',round((100.0*v_earned_in/v_b.marks_available)::numeric,1),
    'score_status',case when v_pending_in+v_pending_after>0 then 'pending_self_review' when v_score_comp then 'provisional_comparable' else 'non_comparable' end,
    'readiness_claim',false,'finalized_at',v_b.finalized_at
  );
end;
$$;
revoke execute on function public.get_exam_prep_timed_result_safe_v1(uuid) from public,anon;
grant execute on function public.get_exam_prep_timed_result_safe_v1(uuid) to authenticated,service_role;

commit;
