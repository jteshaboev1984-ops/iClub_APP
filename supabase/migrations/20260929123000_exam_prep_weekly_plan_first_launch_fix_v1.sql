-- Production-safe first weekly-plan launch fix.
-- Scope: function definition only. No tables, learner rows, plans, responses or history are rewritten.
-- Root cause: exam_prep_weekly_plans has generated_at, not created_at.

begin;

do $guard$
begin
  if to_regprocedure('public.ensure_exam_prep_balanced_weekly_plan_safe_v1(text)') is null
     or to_regprocedure('public.ensure_exam_prep_stable_weekly_plan_safe_v1(text)') is null
     or to_regprocedure('private.exam_prep_balance_new_normal_plan_v1(uuid,bigint,text,smallint,uuid)') is null
  then
    raise exception 'exam_prep_weekly_plan_launch_fix_precondition_missing';
  end if;

  if not exists (
    select 1
    from information_schema.columns
    where table_schema='private'
      and table_name='exam_prep_weekly_plans'
      and column_name='generated_at'
  ) then
    raise exception 'exam_prep_weekly_plan_launch_fix_generated_at_missing';
  end if;
end
$guard$;

create or replace function public.ensure_exam_prep_balanced_weekly_plan_safe_v1(
  p_component_code text
) returns jsonb language plpgsql security definer set search_path = '' as $function$
declare
  v_uid uuid;
  v_program bigint;
  v_week smallint;
  v_existing_plan uuid;
  v_result jsonb;
  v_current jsonb;
begin
  v_uid:=private.exam_prep_require_core_access_v1();
  if p_component_code not in ('P1','P5') then raise exception 'exam_prep_bad_component'; end if;

  select program_version_id into v_program
  from private.exam_prep_exam_profiles
  where user_id=v_uid;
  v_week:=private.exam_prep_effective_active_week_v1(v_uid);
  if v_program is null or v_week is null then raise exception 'exam_prep_profile_required'; end if;

  -- Use the same learner/component lock as the released weekly-flow authority.
  perform pg_advisory_xact_lock(hashtextextended('ep-stable-plan:'||v_uid::text||':'||p_component_code,0));

  select p.id into v_existing_plan
  from private.exam_prep_weekly_plans p
  where p.user_id=v_uid
    and p.program_version_id=v_program
    and p.component_code=p_component_code
    and p.active_week_no=v_week
    and p.status='active'
  order by p.generated_at desc, p.id desc
  limit 1;

  -- Keep the sealed released function unchanged. It remains the sole creator
  -- of the stable weekly plan and keeps all recovery/concurrency guarantees.
  v_result:=public.ensure_exam_prep_stable_weekly_plan_safe_v1(p_component_code);

  -- Never rewrite an already active plan. Balance only a plan created by this
  -- exact call, before it is exposed to the learner for the first time.
  if v_existing_plan is null
     and v_result->>'status'='created'
     and v_result->>'plan_id' is not null
  then
    perform private.exam_prep_balance_new_normal_plan_v1(
      v_uid,v_program,p_component_code,v_week,(v_result->>'plan_id')::uuid
    );
    v_current:=public.get_exam_prep_weekly_plan_safe_v2(p_component_code);
    if v_current->>'plan_id' is distinct from v_result->>'plan_id' then
      raise exception 'exam_prep_balanced_plan_projection_mismatch';
    end if;
    return v_current || jsonb_build_object(
      'contract_version','stable_weekly_plan_v1',
      'status','created',
      'created',true
    );
  end if;

  return v_result;
end
$function$;

revoke all on function public.ensure_exam_prep_balanced_weekly_plan_safe_v1(text) from public,anon;
grant execute on function public.ensure_exam_prep_balanced_weekly_plan_safe_v1(text) to authenticated;

commit;
