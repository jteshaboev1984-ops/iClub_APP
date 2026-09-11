begin;

create or replace function private.exam_prep_correction_work_rank_v1(p_status text)
returns smallint
language sql
immutable
security definer
set search_path=''
as $$
  select case p_status
    when 'reopened' then 0::smallint
    when 'remediating' then 1::smallint
    when 'open' then 2::smallint
    else 9::smallint
  end;
$$;
revoke all on function private.exam_prep_correction_work_rank_v1(text) from public,anon,authenticated;
grant execute on function private.exam_prep_correction_work_rank_v1(text) to service_role;
comment on function private.exam_prep_correction_work_rank_v1(text) is
'Weekly correction priority: failed/reopened loop first, then in-progress remediation, then older open work. Retest-due items are handled by their separate retest queue.';

do $$
declare
  v_oid oid;
  v_def text;
  v_old text;
  v_new text;
begin
  v_old:='order by c.opened_at';
  v_new:='order by private.exam_prep_correction_work_rank_v1(c.status), case when c.status in (''reopened'',''remediating'') then c.updated_at end desc nulls last, c.opened_at';

  select p.oid into v_oid from pg_proc p join pg_namespace n on n.oid=p.pronamespace
  where n.nspname='public' and p.proname='generate_exam_prep_weekly_plan_safe_v2'
    and pg_get_function_identity_arguments(p.oid)='p_component_code text';
  if v_oid is null then raise exception 'P2-26 v2 planner function missing'; end if;
  v_def:=pg_get_functiondef(v_oid);
  if position(v_old in v_def)=0 then raise exception 'P2-26 v2 planner patch anchor missing'; end if;
  execute replace(v_def,v_old,v_new);

  select p.oid into v_oid from pg_proc p join pg_namespace n on n.oid=p.pronamespace
  where n.nspname='public' and p.proname='generate_exam_prep_weekly_plan_safe_v3'
    and pg_get_function_identity_arguments(p.oid)='p_component_code text';
  if v_oid is null then raise exception 'P2-26 v3 planner function missing'; end if;
  v_def:=pg_get_functiondef(v_oid);
  if position(v_old in v_def)=0 then raise exception 'P2-26 v3 planner patch anchor missing'; end if;
  execute replace(v_def,v_old,v_new);

  select p.oid into v_oid from pg_proc p join pg_namespace n on n.oid=p.pronamespace
  where n.nspname='private' and p.proname='exam_prep_correction_queue_payload_v1'
    and pg_get_function_identity_arguments(p.oid)='p_user_id uuid, p_component_code text';
  if v_oid is null then raise exception 'P2-26 correction queue function missing'; end if;
  v_def:=pg_get_functiondef(v_oid);
  v_old:='order by sequence_no,opened_at';
  v_new:='order by case when status=''retest_due'' and retest_due_at is not null and retest_due_at<=now() then 0 when status=''reopened'' then 1 when status=''remediating'' then 2 when status=''open'' then 3 when status=''retest_due'' then 4 else 9 end, case when status in (''reopened'',''remediating'') then updated_at end desc nulls last, sequence_no, opened_at';
  if position(v_old in v_def)=0 then raise exception 'P2-26 correction queue patch anchor missing'; end if;
  execute replace(v_def,v_old,v_new);
end $$;

revoke execute on function public.generate_exam_prep_weekly_plan_safe_v2(text) from public,anon;
grant execute on function public.generate_exam_prep_weekly_plan_safe_v2(text) to authenticated,service_role;
revoke execute on function public.generate_exam_prep_weekly_plan_safe_v3(text) from public,anon;
grant execute on function public.generate_exam_prep_weekly_plan_safe_v3(text) to authenticated,service_role;
revoke all on function private.exam_prep_correction_queue_payload_v1(uuid,text) from public,anon,authenticated;
grant execute on function private.exam_prep_correction_queue_payload_v1(uuid,text) to service_role;

commit;