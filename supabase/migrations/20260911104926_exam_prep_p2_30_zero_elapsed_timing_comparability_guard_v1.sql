begin;

-- P2-30: strict timed evidence needs measurable server elapsed time.
-- We do not invent a minimum-performance-duration threshold. We only reject
-- the impossible zero-second case from comparability/readiness evidence.
-- Historical raw attempts are preserved unchanged; readers reinterpret them safely.

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

do $$
declare
  v_oid oid;
  v_def text;
  v_old text;
  v_new text;
begin
  select p.oid into v_oid
  from pg_proc p join pg_namespace n on n.oid=p.pronamespace
  where n.nspname='public' and p.proname='finalize_exam_prep_timed_safe_v1'
    and pg_get_function_identity_arguments(p.oid)='p_session_id uuid, p_idempotency_key text, p_completion_reason text';
  if v_oid is null then raise exception 'P2-30 timed finalizer missing'; end if;
  v_def:=pg_get_functiondef(v_oid);
  v_old:='  v_timing_comp:=v_strict and p_completion_reason<>''administrative_stop'';';
  v_new:='  v_timing_comp:=v_strict and p_completion_reason<>''administrative_stop'' and v_elapsed>0;';
  if position(v_old in v_def)=0 then raise exception 'P2-30 finalizer timing anchor missing'; end if;
  execute replace(v_def,v_old,v_new);

  select p.oid into v_oid
  from pg_proc p join pg_namespace n on n.oid=p.pronamespace
  where n.nspname='public' and p.proname='get_exam_prep_timed_result_safe_v1'
    and pg_get_function_identity_arguments(p.oid)='p_session_id uuid';
  if v_oid is null then raise exception 'P2-30 timed result reader missing'; end if;
  v_def:=pg_get_functiondef(v_oid);
  v_old:='  v_score_comp:=v_b.timing_comparable and v_pending_in=0 and v_pending_after=0 and v_b.attempt_kind<>''diagnostic_full'';';
  v_new:='  v_score_comp:=private.exam_prep_timed_score_comparable_v1(v_b.session_id);';
  if position(v_old in v_def)=0 then raise exception 'P2-30 result score anchor missing'; end if;
  v_def:=replace(v_def,v_old,v_new);
  v_old:='    ''timing_comparable'',v_b.timing_comparable,''score_comparable'',v_score_comp,';
  v_new:='    ''timing_comparable'',(v_b.timing_comparable and v_b.server_elapsed_sec>0),''score_comparable'',v_score_comp,';
  if position(v_old in v_def)=0 then raise exception 'P2-30 result timing anchor missing'; end if;
  execute replace(v_def,v_old,v_new);
end $$;

revoke execute on function public.finalize_exam_prep_timed_safe_v1(uuid,text,text) from public,anon;
grant execute on function public.finalize_exam_prep_timed_safe_v1(uuid,text,text) to authenticated,service_role;
revoke execute on function public.get_exam_prep_timed_result_safe_v1(uuid) from public,anon;
grant execute on function public.get_exam_prep_timed_result_safe_v1(uuid) to authenticated,service_role;

commit;