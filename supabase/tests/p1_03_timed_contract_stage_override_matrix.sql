\set ON_ERROR_STOP on
\echo 'P1-03 per-contract timed minimum-stage override matrix'

begin;

do $$
declare
  v_program bigint;
  v_profile bigint;
  v_p1_paper01 bigint;
  v_p1_paper02 bigint;
  v_user uuid := '00000000-0000-4000-8000-000000001055'::uuid;
  v_catalog jsonb;
  v_auth jsonb;
  v_failed boolean;
begin
  select id into v_program
  from private.exam_prep_program_versions
  where program_key='math_as_p1_p5' and version_key='p1_p5_canonical_v1_0' and status='active';
  select id into v_profile
  from private.exam_prep_component_paper_profiles
  where program_version_id=v_program and component_code='P1' and profile_version='9709_2026_2027_v1' and status='published';
  select id into v_p1_paper01
  from private.exam_prep_assessments
  where assessment_key='p1_stage3_full_paper_01' and assessment_version='av1' and status='published';
  select id into v_p1_paper02
  from private.exam_prep_assessments
  where assessment_key='p1_stage4_full_paper_02' and assessment_version='av1' and status='approved';
  if v_program is null or v_profile is null or v_p1_paper01 is null or v_p1_paper02 is null then
    raise exception 'P1-03 min-stage override matrix governed baseline missing';
  end if;

  -- Backward compatibility and fail-closed lower-bound semantics.
  if private.exam_prep_timed_effective_min_stage_v1('full_paper',null)<>3
     or private.exam_prep_timed_effective_min_stage_v1('full_paper',4)<>4
     or private.exam_prep_timed_effective_min_stage_v1('timed_section',null)<>2
     or private.exam_prep_timed_effective_min_stage_v1('timed_section',3)<>3 then
    raise exception 'P1-03 min-stage override matrix effective mapping drift';
  end if;

  v_failed:=false;
  begin
    perform private.exam_prep_timed_effective_min_stage_v1('full_paper',2);
  exception when others then
    if position('exam_prep_timed_stage_override_below_base' in sqlerrm)=0 then raise; end if;
    v_failed:=true;
  end;
  if not v_failed then raise exception 'P1-03 min-stage override matrix accepted below-base full-paper override'; end if;

  -- Release Paper02 only inside this rollback transaction, explicitly Stage-4-only.
  update private.exam_prep_assessments
  set status='published'
  where id=v_p1_paper02 and status='approved';

  insert into private.exam_prep_timed_assessment_contracts(
    assessment_id,paper_profile_id,contract_version,attempt_kind,timing_rule,marks_available,fixed_time_limit_sec,
    strict_timing,comparison_scope,comparability_key,min_operational_stage,status,published_at
  ) values(
    v_p1_paper02,v_profile,'tcv1','full_paper','official_full',75,null,
    true,'full','p1-full-paper-02-v1',4,'published',now()
  );

  if (select private.exam_prep_timed_effective_min_stage_v1(c.attempt_kind,c.min_operational_stage)
      from private.exam_prep_timed_assessment_contracts c where c.assessment_id=v_p1_paper02)<>4 then
    raise exception 'P1-03 min-stage override matrix Paper02 effective stage is not 4';
  end if;

  -- Synthetic Core entitlement exists only inside rollback CI.
  insert into auth.users(id,email,role,aud)
  values(v_user,'p103-stage4-contract-override@invalid.example','authenticated','authenticated');
  insert into public.users(id,first_name,last_name,language_code)
  values(v_user,'P103','Stage4ContractOverride','en');
  insert into private.exam_prep_feature_entitlements(
    user_id,entitlement_status,core_access,ai_assist,mentor_care_entitled,cohort_key,valid_from
  ) values(v_user,'active',true,false,false,'p103-ci',now()-interval '1 hour');
  update private.exam_prep_feature_config
  set rollout_state='controlled_beta',core_enabled=true,ai_enabled=false,mentor_enabled=false,kill_switch=false,updated_at=now()
  where program_key='math_as_p1_p5';

  -- Stage 3: Paper01 is available; Stage-4-only Paper02 is hidden and direct authorization is blocked.
  insert into private.exam_prep_stage_states(
    user_id,program_version_id,component_code,engine_version,denominator_count,l0_count,l1_count,l2_count,l3_count,
    coverage_count,coverage_pct,open_correction_count,retest_due_count,evidence_stage_candidate,operational_stage,
    stage_gate_status,app_readiness_estimate,app_readiness_reason
  ) values(
    v_user,v_program,'P1','objective_state_v1',45,9,0,36,0,36,80,0,0,3,3,
    'synthetic_stage3_override_fixture',false,'P1-03 rollback-only fixture'
  );

  perform set_config('request.jwt.claim.sub',v_user::text,true);
  v_catalog:=public.get_exam_prep_timed_catalog_safe_v1('P1');
  if not exists(
    select 1 from jsonb_array_elements(v_catalog->'assessments') j
    where (j->>'assessment_id')::bigint=v_p1_paper01 and (j->>'min_operational_stage')::int=3
  ) then
    raise exception 'P1-03 min-stage override matrix Stage3 catalog lost Paper01 %',v_catalog::text;
  end if;
  if exists(
    select 1 from jsonb_array_elements(v_catalog->'assessments') j
    where (j->>'assessment_id')::bigint=v_p1_paper02
  ) then
    raise exception 'P1-03 min-stage override matrix Stage3 catalog exposed Stage4 Paper02 %',v_catalog::text;
  end if;

  v_failed:=false;
  begin
    perform public.authorize_exam_prep_timed_safe_v1(v_p1_paper02);
  exception when others then
    if position('exam_prep_timed_stage_gate_not_met required=4 current=3' in sqlerrm)=0 then raise; end if;
    v_failed:=true;
  end;
  if not v_failed then raise exception 'P1-03 min-stage override matrix Stage3 direct authorization bypassed Stage4 gate'; end if;

  -- Ephemeral fixture-only Stage 4: Paper02 becomes visible and authorizable.
  update private.exam_prep_stage_states
  set evidence_stage_candidate=4,operational_stage=4,stage_gate_status='synthetic_stage4_override_fixture',
      app_readiness_reason='P1-03 rollback-only fixture',derived_at=now()
  where user_id=v_user and program_version_id=v_program and component_code='P1' and engine_version='objective_state_v1';

  v_catalog:=public.get_exam_prep_timed_catalog_safe_v1('P1');
  if not exists(
    select 1 from jsonb_array_elements(v_catalog->'assessments') j
    where (j->>'assessment_id')::bigint=v_p1_paper02
      and (j->>'min_operational_stage')::int=4
      and (j->>'current_operational_stage')::int=4
  ) then
    raise exception 'P1-03 min-stage override matrix Stage4 catalog did not expose Paper02 %',v_catalog::text;
  end if;

  v_auth:=public.authorize_exam_prep_timed_safe_v1(v_p1_paper02);
  if (v_auth->>'assessment_id')::bigint<>v_p1_paper02
     or (v_auth->>'min_operational_stage')::int<>4
     or (v_auth->>'current_operational_stage')::int<>4
     or v_auth->>'attempt_kind'<>'full_paper' then
    raise exception 'P1-03 min-stage override matrix Stage4 authorization payload wrong %',v_auth::text;
  end if;

  raise notice 'P1-03 per-contract timed minimum-stage override matrix: GREEN';
end $$;

rollback;

-- Rollback must preserve the production release boundary for Paper02.
do $$
declare v_p2 bigint; begin
  select id into v_p2 from private.exam_prep_assessments
  where assessment_key='p1_stage4_full_paper_02' and assessment_version='av1' and status='approved';
  if v_p2 is null then raise exception 'P1-03 min-stage override matrix rollback did not restore approved Paper02'; end if;
  if exists(select 1 from private.exam_prep_timed_assessment_contracts where assessment_id=v_p2) then
    raise exception 'P1-03 min-stage override matrix rollback left Paper02 timed contract';
  end if;
end $$;

\echo 'P1-03 per-contract timed minimum-stage override matrix: GREEN'
