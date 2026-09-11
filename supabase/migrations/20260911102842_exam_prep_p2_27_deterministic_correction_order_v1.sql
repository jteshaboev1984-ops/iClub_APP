begin;

do $$
declare
  v_oid oid;
  v_def text;
  v_old text;
  v_new text;
begin
  select p.oid into v_oid from pg_proc p join pg_namespace n on n.oid=p.pronamespace
  where n.nspname='public' and p.proname='generate_exam_prep_weekly_plan_safe_v2'
    and pg_get_function_identity_arguments(p.oid)='p_component_code text';
  if v_oid is null then raise exception 'P2-27 v2 planner missing'; end if;
  v_def:=pg_get_functiondef(v_oid);

  v_old:='order by r.due_not_before nulls first,c.opened_at';
  v_new:='order by r.due_not_before nulls first,c.opened_at,c.skill_code';
  if position(v_old in v_def)=0 then raise exception 'P2-27 retest order anchor missing'; end if;
  v_def:=replace(v_def,v_old,v_new);

  v_old:='order by private.exam_prep_correction_work_rank_v1(c.status), case when c.status in (''reopened'',''remediating'') then c.updated_at end desc nulls last, c.opened_at';
  v_new:='order by private.exam_prep_correction_work_rank_v1(c.status), case when c.status in (''reopened'',''remediating'') then c.updated_at end desc nulls last, c.opened_at, c.skill_code';
  if position(v_old in v_def)=0 then raise exception 'P2-27 v2 correction order anchor missing'; end if;
  v_def:=replace(v_def,v_old,v_new);
  execute v_def;

  select p.oid into v_oid from pg_proc p join pg_namespace n on n.oid=p.pronamespace
  where n.nspname='public' and p.proname='generate_exam_prep_weekly_plan_safe_v3'
    and pg_get_function_identity_arguments(p.oid)='p_component_code text';
  if v_oid is null then raise exception 'P2-27 v3 planner missing'; end if;
  v_def:=pg_get_functiondef(v_oid);
  v_old:='order by private.exam_prep_correction_work_rank_v1(c.status), case when c.status in (''reopened'',''remediating'') then c.updated_at end desc nulls last, c.opened_at';
  v_new:='order by private.exam_prep_correction_work_rank_v1(c.status), case when c.status in (''reopened'',''remediating'') then c.updated_at end desc nulls last, c.opened_at, c.skill_code';
  if position(v_old in v_def)=0 then raise exception 'P2-27 v3 correction order anchor missing'; end if;
  execute replace(v_def,v_old,v_new);
end $$;

revoke execute on function public.generate_exam_prep_weekly_plan_safe_v2(text) from public,anon;
grant execute on function public.generate_exam_prep_weekly_plan_safe_v2(text) to authenticated,service_role;
revoke execute on function public.generate_exam_prep_weekly_plan_safe_v3(text) from public,anon;
grant execute on function public.generate_exam_prep_weekly_plan_safe_v3(text) to authenticated,service_role;

commit;