\set ON_ERROR_STOP on
\echo 'P1-03 Stage-4 Paper02 release guard matrix'

begin;

do $$
declare
  v_program bigint;
  v_p1_paper02 bigint;
  v_p5_paper02 bigint;
  v_status jsonb;
  v_failed boolean;
begin
  select id into v_program
  from private.exam_prep_program_versions
  where program_key='math_as_p1_p5' and version_key='p1_p5_canonical_v1_0' and status='active';
  select id into v_p1_paper02
  from private.exam_prep_assessments
  where assessment_key='p1_stage4_full_paper_02' and assessment_version='av1' and status='approved';
  select id into v_p5_paper02
  from private.exam_prep_assessments
  where assessment_key='p5_stage4_full_paper_02' and assessment_version='av1' and status='approved';
  if v_program is null or v_p1_paper02 is null or v_p5_paper02 is null then
    raise exception 'P1-03 Stage4 release guard matrix baseline missing';
  end if;

  v_status:=private.exam_prep_stage4_paper02_release_readiness_v1('P1');
  if coalesce((v_status->>'ready')::boolean,true)
     or v_status->>'reason_code'<>'stage4_policy_pending'
     or v_status->>'stage4_policy_status'<>'pending'
     or v_status->>'paper02_release_status'<>'pending' then
    raise exception 'P1-03 Stage4 release guard did not start P1 fail-closed %',v_status::text;
  end if;
  v_status:=private.exam_prep_stage4_paper02_release_readiness_v1('P5');
  if coalesce((v_status->>'ready')::boolean,true)
     or v_status->>'reason_code'<>'stage4_policy_pending' then
    raise exception 'P1-03 Stage4 release guard did not start P5 fail-closed %',v_status::text;
  end if;

  -- Layer 1: a direct assessment publication attempt is blocked while Stage4 policy is pending.
  v_failed:=false;
  begin
    update private.exam_prep_assessments set status='published' where id=v_p1_paper02;
  exception when others then
    if position('exam_prep_stage4_policy_not_approved' in sqlerrm)=0 then raise; end if;
    v_failed:=true;
  end;
  if not v_failed then raise exception 'P1-03 Stage4 release guard allowed P1 Paper02 with policy pending'; end if;

  -- Simulate explicit governance approval only inside rollback CI.
  update private.exam_prep_stage4_release_controls
  set stage4_policy_status='approved',paper02_release_status='approved',updated_at=now()
  where status='active';

  -- Layer 2: release is still blocked because Stage3 key-skill governance is pending.
  v_failed:=false;
  begin
    update private.exam_prep_assessments set status='published' where id=v_p1_paper02;
  exception when others then
    if position('exam_prep_stage3_key_registry_not_approved' in sqlerrm)=0 then raise; end if;
    v_failed:=true;
  end;
  if not v_failed then raise exception 'P1-03 Stage4 release guard ignored pending Stage3 key registry'; end if;

  update private.exam_prep_stage3_exit_rules
  set key_registry_status='approved'
  where status='active';

  -- Layer 3: approved-but-empty registry is also rejected.
  v_failed:=false;
  begin
    update private.exam_prep_assessments set status='published' where id=v_p1_paper02;
  exception when others then
    if position('exam_prep_stage3_key_registry_empty' in sqlerrm)=0 then raise; end if;
    v_failed:=true;
  end;
  if not v_failed then raise exception 'P1-03 Stage4 release guard accepted empty P1 key registry'; end if;

  insert into private.exam_prep_stage3_key_skills(
    rule_version,program_version_id,component_code,skill_code,governance_basis
  )
  select rule_version,v_program,'P1','P1-QUA-01','P1-03 rollback-only release-guard fixture'
  from private.exam_prep_stage3_exit_rules where status='active';

  -- Component firewall: a governed P1 key must not satisfy P5.
  v_status:=private.exam_prep_stage4_paper02_release_readiness_v1('P5');
  if coalesce((v_status->>'ready')::boolean,true)
     or v_status->>'reason_code'<>'stage3_key_registry_empty'
     or (v_status->>'stage3_key_count')::int<>0 then
    raise exception 'P1-03 Stage4 release guard P1 key leaked into P5 readiness %',v_status::text;
  end if;
  v_failed:=false;
  begin
    update private.exam_prep_assessments set status='published' where id=v_p5_paper02;
  exception when others then
    if position('exam_prep_stage3_key_registry_empty' in sqlerrm)=0 then raise; end if;
    v_failed:=true;
  end;
  if not v_failed then raise exception 'P1-03 Stage4 release guard let P1 keys unlock P5 Paper02'; end if;

  -- Layer 4: P1 governance labels alone are insufficient; actual Stage4 evaluator must exist.
  v_failed:=false;
  begin
    update private.exam_prep_assessments set status='published' where id=v_p1_paper02;
  exception when others then
    if position('exam_prep_stage4_exit_policy_not_deployed' in sqlerrm)=0 then raise; end if;
    v_failed:=true;
  end;
  if not v_failed then raise exception 'P1-03 Stage4 release guard allowed P1 Paper02 without Stage4 evaluator'; end if;
end $$;

-- CI-only stand-in proving the final guard layer. It is rolled back and never ships.
create or replace function private.exam_prep_stage4_exit_status_v1(
  p_user_id uuid,p_program_version_id bigint,p_component_code text
)
returns jsonb
language sql
stable
set search_path=''
as $$
  select jsonb_build_object('ready',false,'reason_code','p103_ci_only_stub','stage4_unlocked',false);
$$;

do $$
declare
  v_program bigint;
  v_p1_paper02 bigint;
  v_p5_paper02 bigint;
  v_p1_profile bigint;
  v_p5_profile bigint;
  v_status jsonb;
  v_failed boolean;
  v_contracts int;
begin
  select id into v_program
  from private.exam_prep_program_versions
  where program_key='math_as_p1_p5' and version_key='p1_p5_canonical_v1_0' and status='active';
  select a.id into v_p1_paper02
  from private.exam_prep_assessments a
  where a.assessment_key='p1_stage4_full_paper_02' and a.assessment_version='av1' and a.status='approved';
  select a.id into v_p5_paper02
  from private.exam_prep_assessments a
  where a.assessment_key='p5_stage4_full_paper_02' and a.assessment_version='av1' and a.status='approved';
  select p.id into v_p1_profile
  from private.exam_prep_component_paper_profiles p
  where p.program_version_id=v_program and p.component_code='P1'
    and p.profile_version='9709_2026_2027_v1' and p.status='published';
  select p.id into v_p5_profile
  from private.exam_prep_component_paper_profiles p
  where p.program_version_id=v_program and p.component_code='P5'
    and p.profile_version='9709_2026_2027_v1' and p.status='published';
  if v_program is null or v_p1_paper02 is null or v_p5_paper02 is null
     or v_p1_profile is null or v_p5_profile is null then
    raise exception 'P1-03 Stage4 release guard final-layer baseline missing';
  end if;

  v_status:=private.exam_prep_stage4_paper02_release_readiness_v1('P1');
  if not coalesce((v_status->>'ready')::boolean,false) or v_status->>'reason_code'<>'ready' then
    raise exception 'P1-03 Stage4 release guard P1 did not become ready after simulated approvals %',v_status::text;
  end if;

  -- P5 must still be blocked until it receives its OWN governed key row.
  v_status:=private.exam_prep_stage4_paper02_release_readiness_v1('P5');
  if coalesce((v_status->>'ready')::boolean,true)
     or v_status->>'reason_code'<>'stage3_key_registry_empty'
     or (v_status->>'stage3_key_count')::int<>0 then
    raise exception 'P1-03 Stage4 release guard P5 component firewall failed before own key %',v_status::text;
  end if;

  insert into private.exam_prep_stage3_key_skills(
    rule_version,program_version_id,component_code,skill_code,governance_basis
  )
  select rule_version,v_program,'P5','P5-DAT-01','P1-03 rollback-only P5 release-guard fixture'
  from private.exam_prep_stage3_exit_rules where status='active';

  v_status:=private.exam_prep_stage4_paper02_release_readiness_v1('P5');
  if not coalesce((v_status->>'ready')::boolean,false)
     or v_status->>'reason_code'<>'ready'
     or (v_status->>'stage3_key_count')::int<>1 then
    raise exception 'P1-03 Stage4 release guard P5 did not become ready with own key %',v_status::text;
  end if;

  update private.exam_prep_assessments set status='published' where id in (v_p1_paper02,v_p5_paper02);

  -- Even with all governance simulated, neither Paper02 may use the Stage-3 default.
  v_failed:=false;
  begin
    insert into private.exam_prep_timed_assessment_contracts(
      assessment_id,paper_profile_id,contract_version,attempt_kind,timing_rule,marks_available,fixed_time_limit_sec,
      strict_timing,comparison_scope,comparability_key,min_operational_stage,status,published_at
    ) values(
      v_p1_paper02,v_p1_profile,'tcv1','full_paper','official_full',75,null,
      true,'full','p1-full-paper-02-v1',3,'published',now()
    );
  exception when others then
    if position('exam_prep_stage4_paper02_min_stage_too_low' in sqlerrm)=0 then raise; end if;
    v_failed:=true;
  end;
  if not v_failed then raise exception 'P1-03 Stage4 release guard accepted P1 Paper02 minimum Stage3'; end if;

  v_failed:=false;
  begin
    insert into private.exam_prep_timed_assessment_contracts(
      assessment_id,paper_profile_id,contract_version,attempt_kind,timing_rule,marks_available,fixed_time_limit_sec,
      strict_timing,comparison_scope,comparability_key,min_operational_stage,status,published_at
    ) values(
      v_p5_paper02,v_p5_profile,'tcv1','full_paper','official_full',50,null,
      true,'full','p5-full-paper-02-v1',3,'published',now()
    );
  exception when others then
    if position('exam_prep_stage4_paper02_min_stage_too_low' in sqlerrm)=0 then raise; end if;
    v_failed:=true;
  end;
  if not v_failed then raise exception 'P1-03 Stage4 release guard accepted P5 Paper02 minimum Stage3'; end if;

  insert into private.exam_prep_timed_assessment_contracts(
    assessment_id,paper_profile_id,contract_version,attempt_kind,timing_rule,marks_available,fixed_time_limit_sec,
    strict_timing,comparison_scope,comparability_key,min_operational_stage,status,published_at
  ) values
    (v_p1_paper02,v_p1_profile,'tcv1','full_paper','official_full',75,null,
     true,'full','p1-full-paper-02-v1',4,'published',now()),
    (v_p5_paper02,v_p5_profile,'tcv1','full_paper','official_full',50,null,
     true,'full','p5-full-paper-02-v1',4,'published',now());

  select count(*) into v_contracts
  from private.exam_prep_timed_assessment_contracts
  where assessment_id in (v_p1_paper02,v_p5_paper02)
    and status='published' and min_operational_stage=4;
  if v_contracts<>2 then
    raise exception 'P1-03 Stage4 release guard failed valid P1/P5 Stage4-only contracts count=%',v_contracts;
  end if;

  raise notice 'P1-03 Stage-4 Paper02 release guard matrix: GREEN';
end $$;

rollback;

-- Everything simulated above must disappear; production-like baseline remains locked.
do $$
declare
  v_control private.exam_prep_stage4_release_controls%rowtype;
  v_p2 int;
  v_contracts int;
begin
  select * into v_control from private.exam_prep_stage4_release_controls where status='active';
  if v_control.stage4_policy_status<>'pending' or v_control.paper02_release_status<>'pending' then
    raise exception 'P1-03 Stage4 release guard rollback left governance approval';
  end if;
  if to_regprocedure('private.exam_prep_stage4_exit_status_v1(uuid,bigint,text)') is not null then
    raise exception 'P1-03 Stage4 release guard rollback left CI-only evaluator';
  end if;
  if (select key_registry_status from private.exam_prep_stage3_exit_rules where status='active')<>'pending' then
    raise exception 'P1-03 Stage4 release guard rollback left Stage3 key registry approved';
  end if;
  select count(*) into v_p2 from private.exam_prep_assessments
  where assessment_key in ('p1_stage4_full_paper_02','p5_stage4_full_paper_02') and assessment_version='av1' and status='approved';
  if v_p2<>2 then raise exception 'P1-03 Stage4 release guard rollback did not restore both approved Paper02 forms count=%',v_p2; end if;
  select count(*) into v_contracts
  from private.exam_prep_timed_assessment_contracts c
  join private.exam_prep_assessments a on a.id=c.assessment_id
  where a.assessment_key in ('p1_stage4_full_paper_02','p5_stage4_full_paper_02');
  if v_contracts<>0 then raise exception 'P1-03 Stage4 release guard rollback left Paper02 contracts=%',v_contracts; end if;
  if exists(select 1 from private.exam_prep_stage3_key_skills) then
    raise exception 'P1-03 Stage4 release guard rollback left synthetic key registry rows';
  end if;
end $$;

\echo 'P1-03 Stage-4 Paper02 release guard matrix: GREEN'
