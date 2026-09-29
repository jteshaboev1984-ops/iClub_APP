-- Disposable isolated regression for the first governed weekly-plan entry point.
-- It intentionally stops at the existing Stage 0 gate and rolls back every synthetic row.
\set ON_ERROR_STOP on
begin;
do $test$
declare
  v_uid uuid:=gen_random_uuid();
  v_program bigint;
  v_error text;
  v_expected_gate boolean:=false;
  v_def text;
begin
  select id into strict v_program
  from private.exam_prep_program_versions
  where program_key='math_as_p1_p5'
    and version_key='p1_p5_canonical_v1_0'
    and status='active';

  insert into auth.users(id,aud,role,email,created_at,updated_at,is_sso_user,is_anonymous)
  values(v_uid,'authenticated','authenticated','weekly-first-launch-fix@invalid.example',now(),now(),false,false);

  insert into public.users(id,first_name,created_at,must_change_password)
  values(v_uid,'WeeklyFirstLaunchFixFixture',now(),false);

  insert into private.exam_prep_feature_entitlements(
    user_id,entitlement_status,core_access,ai_assist,mentor_care_entitled
  ) values(v_uid,'active',true,false,false);

  insert into private.exam_prep_exam_profiles(
    user_id,program_version_id,exam_series,target_grade,
    total_student_hours_available,mathematics_hours_budget,active_week_no
  ) values(v_uid,v_program,'May/June 2027','A',12,6,1);

  insert into private.exam_prep_weekly_flow_enrollment_v1(
    user_id,enabled,approved_by,approved_at
  ) values(v_uid,true,'00000000-0000-4000-8000-000000000001',clock_timestamp());

  perform set_config('request.jwt.claim.sub',v_uid::text,true);
  perform set_config('request.jwt.claim.role','authenticated',true);

  begin
    perform public.ensure_exam_prep_balanced_weekly_plan_safe_v1('P1');
  exception when others then
    get stacked diagnostics v_error=message_text;
    if v_error<>'exam_prep_stage0_required_before_weekly_plan' then
      raise exception 'balanced first-plan entry failed before governed Stage 0 gate: %',v_error;
    end if;
    v_expected_gate:=true;
  end;

  if not v_expected_gate then
    raise exception 'Stage 0 incomplete fixture unexpectedly passed the weekly-plan gate';
  end if;

  if exists(
    select 1 from private.exam_prep_weekly_plans
    where user_id=v_uid
  ) then
    raise exception 'Stage 0 denial created a phantom weekly plan';
  end if;

  v_def:=lower(pg_get_functiondef(
    'public.ensure_exam_prep_balanced_weekly_plan_safe_v1(text)'::regprocedure
  ));
  if position('order by p.generated_at desc, p.id desc' in v_def)=0
     or position('order by p.created_at desc' in v_def)<>0
  then
    raise exception 'weekly-plan first-launch timestamp contract drifted';
  end if;

  raise notice 'WEEKLY FIRST-LAUNCH FIX GREEN: selector compiled, Stage 0 gate preserved, zero phantom plans';
end
$test$;
rollback;

do $verify$
begin
  if exists(select 1 from public.users where first_name='WeeklyFirstLaunchFixFixture')
     or exists(select 1 from auth.users where email='weekly-first-launch-fix@invalid.example')
  then
    raise exception 'weekly first-launch synthetic fixture survived rollback';
  end if;
  raise notice 'WEEKLY FIRST-LAUNCH FIX ZERO RESIDUE';
end
$verify$;
