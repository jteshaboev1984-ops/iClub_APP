-- Stage-6 Final Calibration hotfix v1.
-- exam_prep_stage_states uses derived_at (not updated_at). Keep the safe RPC otherwise unchanged.
-- Additive function replacement only; no learner evidence, legacy state, entitlements or readiness policy are changed.

begin;

create or replace function public.get_exam_prep_final_calibration_safe_v1(p_component_code text)
returns jsonb
language plpgsql
stable
security definer
set search_path=''
as $$
declare
  v_uid uuid;
  v_program bigint;
  v_profile private.exam_prep_exam_profiles%rowtype;
  v_ready jsonb;
  v_stage smallint:=0;
  v_open_cases int:=0;
  v_latest_skill text;
  v_latest_case uuid;
  v_actions jsonb;
begin
  v_uid:=private.exam_prep_require_core_access_v1();
  if p_component_code not in ('P1','P5') then raise exception 'exam_prep_bad_component'; end if;

  select * into v_profile from private.exam_prep_exam_profiles where user_id=v_uid;
  v_program:=v_profile.program_version_id;
  if v_program is null then raise exception 'exam_prep_profile_required'; end if;

  v_ready:=private.exam_prep_stage5_readiness_status_v1(v_uid,v_program,p_component_code);
  select coalesce(operational_stage,0) into v_stage
  from private.exam_prep_stage_states
  where user_id=v_uid and program_version_id=v_program and component_code=p_component_code
  order by derived_at desc limit 1;

  select count(*),
         (array_agg(skill_code order by updated_at desc,id desc))[1],
         (array_agg(id order by updated_at desc,id desc))[1]
  into v_open_cases,v_latest_skill,v_latest_case
  from private.exam_prep_correction_cases
  where user_id=v_uid and component_code=p_component_code
    and status in ('open','remediating','retest_due','reopened');

  v_actions:=jsonb_build_array(
    jsonb_build_object('action_code','short_targeted_work','priority',1,'purpose','Maintain exam form with short evidence-driven work; do not reopen the whole syllabus.'),
    jsonb_build_object('action_code','timing_and_logistics','priority',2,'purpose','Confirm component timing and exam logistics through the approved exam-profile process.'),
    jsonb_build_object('action_code','taper','priority',3,'purpose','Reduce bulk workload and protect sleep/recovery; calibration volume does not create new mastery.')
  );

  if v_open_cases>0 then
    v_actions:=jsonb_build_array(jsonb_build_object(
      'action_code','close_recurring_issue','priority',1,'purpose','Resolve the highest-priority remaining evidence-based correction before adding optional work.',
      'skill_code',v_latest_skill,'correction_case_id',v_latest_case
    )) || v_actions;
  end if;

  return jsonb_build_object(
    'available',coalesce((v_ready->>'ready')::boolean,false),
    'component_code',p_component_code,
    'operational_stage',v_stage,
    'exam_series',v_profile.exam_series,
    'target_grade',v_profile.target_grade,
    'readiness',v_ready - 'threshold_version',
    'open_correction_cases',v_open_cases,
    'actions',v_actions,
    'new_mastery_allowed',false,
    'mentor_verified_readiness',false,
    'note','Final Calibration is component-specific taper/logistics support. It is not a predicted Cambridge grade and does not create Mentor Verified readiness.'
  );
end;
$$;

revoke execute on function public.get_exam_prep_final_calibration_safe_v1(text) from public,anon;
grant execute on function public.get_exam_prep_final_calibration_safe_v1(text) to authenticated,service_role;

do $$
declare v_def text; begin
  select pg_get_functiondef('public.get_exam_prep_final_calibration_safe_v1(text)'::regprocedure) into v_def;
  if position('order by derived_at desc' in lower(v_def))=0 then
    raise exception 'Stage6 final calibration hotfix: derived_at state ordering missing';
  end if;
  if position('order by updated_at desc limit 1' in lower(v_def))>0 then
    raise exception 'Stage6 final calibration hotfix: stale stage-state updated_at lookup remains';
  end if;
end $$;

commit;