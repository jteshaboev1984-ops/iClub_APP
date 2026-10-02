-- P2-04 Stage 4 Timed Consolidation / comparability acceptance matrix.
-- Rollback-only synthetic learner plus structural policy checks.
\set ON_ERROR_STOP on
\echo 'P2-04 Stage 4 Timed Consolidation matrix'

BEGIN;

DO $$
DECLARE
  v_program bigint;
  v_user uuid:='00000000-0000-4000-8000-000000002204'::uuid;
  v_p1 jsonb;
  v_p5 jsonb;
  v_def text;
  v_scope_p1 int;
  v_scope_p5 int;
BEGIN
  select id into v_program
  from private.exam_prep_program_versions
  where program_key='math_as_p1_p5'
    and version_key='p1_p5_canonical_v1_0'
    and status='active';

  if v_program is null then
    raise exception 'P2-04 active canonical program missing';
  end if;

  if to_regprocedure('private.exam_prep_stage4_exit_status_v1(uuid,bigint,text)') is null
     or to_regprocedure('private.exam_prep_stage4_raw_evidence_v1(uuid,bigint,text)') is null
     or to_regprocedure('private.exam_prep_stage4_timed_section_gate_v1(uuid,bigint,text,text)') is null
     or to_regprocedure('public.get_exam_prep_stage4_consolidation_safe_v1(text)') is null
  then
    raise exception 'P2-04 Stage-4 evaluator/safe API objects missing';
  end if;

  if has_function_privilege('anon','public.get_exam_prep_stage4_consolidation_safe_v1(text)','EXECUTE')
     or not has_function_privilege('authenticated','public.get_exam_prep_stage4_consolidation_safe_v1(text)','EXECUTE')
  then
    raise exception 'P2-04 learner API privilege boundary drift';
  end if;

  if not exists(
    select 1
    from private.exam_prep_stage4_exit_rules
    where status='active'
      and min_compatible_full_attempts=2
      and require_unattempted_nonworsening
      and require_after_time_nonworsening
      and require_one_improvement_or_zero
      and allow_explicit_corrective_plan
  ) then
    raise exception 'P2-04 approved comparable/trend/corrective rule drift';
  end if;

  select count(*) into v_scope_p1
  from private.exam_prep_stage4_timed_section_scope sc
  join private.exam_prep_stage4_exit_rules r on r.rule_version=sc.rule_version
  where r.status='active' and sc.component_code='P1' and sc.required;

  select count(*) into v_scope_p5
  from private.exam_prep_stage4_timed_section_scope sc
  join private.exam_prep_stage4_exit_rules r on r.rule_version=sc.rule_version
  where r.status='active' and sc.component_code='P5' and sc.required;

  if v_scope_p1<1 or v_scope_p5<1 then
    raise exception 'P2-04 timed-section denominator missing P1=% P5=%',v_scope_p1,v_scope_p5;
  end if;

  select pg_get_functiondef('private.exam_prep_stage4_raw_evidence_v1(uuid,bigint,text)'::regprocedure)
  into v_def;
  if position('s.session_type=''paper''' in v_def)=0
     or position('t.attempt_kind=''full_paper''' in v_def)=0
     or position('t.timing_rule=''official_full''' in v_def)=0
     or position('t.comparison_scope=''full''' in v_def)=0
     or position('and t.strict_timing' in v_def)=0
     or position('and t.timing_comparable' in v_def)=0
     or position('private.exam_prep_timed_score_comparable_v1(t.session_id)' in v_def)=0
  then
    raise exception 'P2-04 comparable-full definition drifted';
  end if;

  select pg_get_functiondef('private.exam_prep_stage4_exit_status_v1(uuid,bigint,text)'::regprocedure)
  into v_def;
  if position('two_comparable_full_attempts_incomplete' in v_def)=0
     or position('timing_trend_incomplete' in v_def)=0
     or position('timed_section_majority_incomplete' in v_def)=0
     or position('l3_or_corrective_plan_incomplete' in v_def)=0
  then
    raise exception 'P2-04 fail-closed reason chain drifted';
  end if;

  if (select count(*) from private.exam_prep_timed_assessment_contracts t
      join private.exam_prep_component_paper_profiles p on p.id=t.paper_profile_id
      join private.exam_prep_assessments a on a.id=t.assessment_id
      where p.program_version_id=v_program and p.component_code='P1'
        and a.status='published' and t.status='published'
        and t.attempt_kind='full_paper' and t.timing_rule='official_full'
        and t.comparison_scope='full' and t.strict_timing
        and t.marks_available=p.official_total_marks)<2
     or
     (select count(*) from private.exam_prep_timed_assessment_contracts t
      join private.exam_prep_component_paper_profiles p on p.id=t.paper_profile_id
      join private.exam_prep_assessments a on a.id=t.assessment_id
      where p.program_version_id=v_program and p.component_code='P5'
        and a.status='published' and t.status='published'
        and t.attempt_kind='full_paper' and t.timing_rule='official_full'
        and t.comparison_scope='full' and t.strict_timing
        and t.marks_available=p.official_total_marks)<2
  then
    raise exception 'P2-04 two governed comparable full-paper forms per component are not available';
  end if;

  insert into auth.users(id,email,role,aud)
  values(v_user,'p204-stage4@invalid.example','authenticated','authenticated');

  insert into public.users(id,first_name,last_name,language_code)
  values(v_user,'P204','Stage4','en');

  insert into private.exam_prep_feature_entitlements(
    user_id,entitlement_status,core_access,ai_assist,mentor_care_entitled,
    cohort_key,valid_from
  ) values(
    v_user,'active',true,false,false,'p204-stage4',now()
  );

  insert into private.exam_prep_exam_profiles(
    user_id,program_version_id,exam_series,target_grade,
    total_student_hours_available,mathematics_hours_budget,active_week_no,
    created_by,updated_by
  ) values(
    v_user,v_program,'May/June 2027','A',12,6,25,v_user,v_user
  );

  update private.exam_prep_feature_config
  set rollout_state='controlled_beta',
      core_enabled=true,
      ai_enabled=false,
      mentor_enabled=false,
      kill_switch=false,
      updated_at=now()
  where id=1;

  perform set_config('request.jwt.claim.sub',v_user::text,true);
  perform set_config('request.jwt.claim.role','authenticated',true);

  v_p1:=public.get_exam_prep_stage4_consolidation_safe_v1('P1');
  v_p5:=public.get_exam_prep_stage4_consolidation_safe_v1('P5');

  if v_p1->>'component_code'<>'P1'
     or v_p5->>'component_code'<>'P5'
     or (v_p1->>'ready')::boolean
     or (v_p5->>'ready')::boolean
     or v_p1->>'reason_code'<>'stage3_exit_incomplete'
     or v_p5->>'reason_code'<>'stage3_exit_incomplete'
     or (v_p1->>'comparable_full_required')::int<>2
     or (v_p5->>'comparable_full_required')::int<>2
     or coalesce((v_p1->>'modified_or_topic_results_count_as_comparable_full')::boolean,true)
     or coalesce((v_p5->>'modified_or_topic_results_count_as_comparable_full')::boolean,true)
     or coalesce((v_p1->>'component_isolation')::boolean,false) is not true
     or coalesce((v_p5->>'component_isolation')::boolean,false) is not true
  then
    raise exception 'P2-04 learner-safe payload mismatch P1=% P5=%',v_p1,v_p5;
  end if;

  if v_p1 ?| array['rule_version','program_version_id','selected_family_key','timed_section_gate']
     or v_p5 ?| array['rule_version','program_version_id','selected_family_key','timed_section_gate']
  then
    raise exception 'P2-04 internal Stage-4 implementation fields leaked to learner payload';
  end if;

  begin
    perform public.get_exam_prep_stage4_consolidation_safe_v1('P3');
    raise exception 'P2-04 invalid component unexpectedly accepted';
  exception when others then
    if sqlerrm not like '%exam_prep_bad_component%' then raise; end if;
  end;
END
$$;

ROLLBACK;

DO $$
DECLARE v_n int;
BEGIN
  select count(*) into v_n
  from auth.users
  where email='p204-stage4@invalid.example';
  if v_n<>0 then
    raise exception 'P2-04 synthetic user residue=%',v_n;
  end if;
END
$$;

\echo 'P2-04 Stage 4 Timed Consolidation matrix: GREEN'
