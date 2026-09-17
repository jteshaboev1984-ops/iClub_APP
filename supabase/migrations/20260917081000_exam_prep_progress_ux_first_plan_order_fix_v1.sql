-- Additive Progress UX hardening: two plan versions can share transaction timestamp.
-- The first weekly goal set MUST follow ascending plan_version, not random UUID tie-break.
-- This is a function-definition-only correction. It writes no learner data.
begin;
do $guard$
declare
  v_source text;
  v_old constant text := 'order by p.generated_at,p.id limit 1;';
  v_new constant text := 'order by p.plan_version,p.generated_at,p.id limit 1;';
begin
  select pg_get_functiondef('public.ensure_exam_prep_weekly_goals_safe_v1(text)'::regprocedure) into v_source;
  if v_source is null or strpos(v_source,v_old)=0 then
    raise exception 'progress_ux_anchor_patch_unexpected_function_definition';
  end if;
  execute replace(v_source,v_old,v_new);
end;
$guard$;
commit;
