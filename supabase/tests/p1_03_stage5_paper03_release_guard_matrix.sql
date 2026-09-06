\set ON_ERROR_STOP on
\echo 'P1-03 Stage-5 Paper03 release guard matrix'

begin;

do $$
declare
  v_program bigint;
  v_p1 bigint;
  v_p5 bigint;
  v_p1_profile bigint;
  v_p5_profile bigint;
  v_status jsonb;
  v_failed boolean;
  v_contracts int;
begin
  select id into v_program from private.exam_prep_program_versions
    where program_key='math_as_p1_p5' and version_key='p1_p5_canonical_v1_0' and status='active';
  select id into v_p1 from private.exam_prep_assessments
    where assessment_key='p1_stage4_full_paper_03' and assessment_version='av1' and status='approved';
  select id into v_p5 from private.exam_prep_assessments
    where assessment_key='p5_stage4_full_paper_03' and assessment_version='av1' and status='approved';
  select id into v_p1_profile from private.exam_prep_component_paper_profiles
    where program_version_id=v_program and component_code='P1' and profile_version='9709_2026_2027_v1' and status='published';
  select id into v_p5_profile from private.exam_prep_component_paper_profiles
    where program_version_id=v_program and component_code='P5' and profile_version='9709_2026_2027_v1' and status='published';
  if v_program is null or v_p1 is null or v_p5 is null or v_p1_profile is null or v_p5_profile is null then
    raise exception 'P1-03 Stage5 Paper03 guard baseline missing';
  end if;

  v_status:=private.exam_prep_stage5_paper03_release_readiness_v1('P1');
  if coalesce((v_status->>'ready')::boolean,true) or v_status->>'reason_code'<>'stage5_policy_pending' then
    raise exception 'P1-03 Stage5 Paper03 P1 did not start locked %',v_status::text;
  end if;
  v_status:=private.exam_prep_stage5_paper03_release_readiness_v1('P5');
  if coalesce((v_status->>'ready')::boolean,true) or v_status->>'reason_code'<>'stage5_policy_pending' then
    raise exception 'P1-03 Stage5 Paper03 P5 did not start locked %',v_status::text;
  end if;

  v_failed:=false;
  begin
    update private.exam_prep_assessments set status='published' where id=v_p1;
  exception when others then
    if position('stage5_policy_pending' in sqlerrm)=0 then raise; end if;
    v_failed:=true;
  end;
  if not v_failed then raise exception 'P1-03 Stage5 Paper03 published while policy pending'; end if;

  -- CI-only governance simulation. Everything below is rolled back.
  update private.exam_prep_stage5_release_controls
    set stage5_policy_status='approved',paper03_release_status='approved',updated_at=now()
    where status='active';
  update private.exam_prep_stage4_release_controls
    set stage4_policy_status='approved',paper02_release_status='approved',updated_at=now()
    where status='active';
  update private.exam_prep_stage3_exit_rules set key_registry_status='approved' where status='active';

  insert into private.exam_prep_stage3_key_skills(rule_version,program_version_id,component_code,skill_code,governance_basis)
  select rule_version,v_program,'P1','P1-QUA-01','P1-03 rollback-only Stage5 Paper03 fixture'
    from private.exam_prep_stage3_exit_rules where status='active';
  insert into private.exam_prep_stage3_key_skills(rule_version,program_version_id,component_code,skill_code,governance_basis)
  select rule_version,v_program,'P5','P5-DAT-01','P1-03 rollback-only Stage5 Paper03 fixture'
    from private.exam_prep_stage3_exit_rules where status='active';

  -- Actual policy functions are intentionally absent in production; CI stubs only prove the final lock layers.
  execute $q$
    create or replace function private.exam_prep_stage4_exit_status_v1(uuid,bigint,text)
    returns jsonb language sql stable set search_path='' as
    'select jsonb_build_object(''ready'',false,''reason_code'',''ci_stub'',''stage4_unlocked'',false)'
  $q$;
  execute $q$
    create or replace function private.exam_prep_stage5_readiness_status_v1(uuid,bigint,text)
    returns jsonb language sql stable set search_path='' as
    'select jsonb_build_object(''ready'',false,''reason_code'',''ci_stub'',''stage5_unlocked'',false)'
  $q$;

  v_status:=private.exam_prep_stage5_paper03_release_readiness_v1('P1');
  if not coalesce((v_status->>'ready')::boolean,false) or v_status->>'reason_code'<>'ready' then
    raise exception 'P1-03 Stage5 Paper03 P1 not ready after CI approvals %',v_status::text;
  end if;
  v_status:=private.exam_prep_stage5_paper03_release_readiness_v1('P5');
  if not coalesce((v_status->>'ready')::boolean,false) or v_status->>'reason_code'<>'ready' then
    raise exception 'P1-03 Stage5 Paper03 P5 not ready after CI approvals %',v_status::text;
  end if;

  update private.exam_prep_assessments set status='published' where id in (v_p1,v_p5);

  v_failed:=false;
  begin
    insert into private.exam_prep_timed_assessment_contracts(
      assessment_id,paper_profile_id,contract_version,attempt_kind,timing_rule,marks_available,fixed_time_limit_sec,
      strict_timing,comparison_scope,comparability_key,min_operational_stage,status,published_at
    ) values(v_p1,v_p1_profile,'tcv1','full_paper','official_full',75,null,true,'full','p1-full-paper-03-v1',4,'published',now());
  exception when others then
    if position('exam_prep_stage5_paper03_min_stage_too_low' in sqlerrm)=0 then raise; end if;
    v_failed:=true;
  end;
  if not v_failed then raise exception 'P1-03 Stage5 Paper03 accepted P1 minimum Stage4'; end if;

  v_failed:=false;
  begin
    insert into private.exam_prep_timed_assessment_contracts(
      assessment_id,paper_profile_id,contract_version,attempt_kind,timing_rule,marks_available,fixed_time_limit_sec,
      strict_timing,comparison_scope,comparability_key,min_operational_stage,status,published_at
    ) values(v_p5,v_p5_profile,'tcv1','full_paper','official_full',50,null,true,'full','p5-full-paper-03-v1',4,'published',now());
  exception when others then
    if position('exam_prep_stage5_paper03_min_stage_too_low' in sqlerrm)=0 then raise; end if;
    v_failed:=true;
  end;
  if not v_failed then raise exception 'P1-03 Stage5 Paper03 accepted P5 minimum Stage4'; end if;

  insert into private.exam_prep_timed_assessment_contracts(
    assessment_id,paper_profile_id,contract_version,attempt_kind,timing_rule,marks_available,fixed_time_limit_sec,
    strict_timing,comparison_scope,comparability_key,min_operational_stage,status,published_at
  ) values
    (v_p1,v_p1_profile,'tcv1','full_paper','official_full',75,null,true,'full','p1-full-paper-03-v1',5,'published',now()),
    (v_p5,v_p5_profile,'tcv1','full_paper','official_full',50,null,true,'full','p5-full-paper-03-v1',5,'published',now());

  select count(*) into v_contracts from private.exam_prep_timed_assessment_contracts
    where assessment_id in (v_p1,v_p5) and status='published' and min_operational_stage=5;
  if v_contracts<>2 then raise exception 'P1-03 Stage5 Paper03 valid Stage5 contracts count=%',v_contracts; end if;
end $$;

rollback;

do $$
declare v_forms int; v_contracts int; begin
  if (select stage5_policy_status from private.exam_prep_stage5_release_controls where status='active')<>'pending'
     or (select paper03_release_status from private.exam_prep_stage5_release_controls where status='active')<>'pending' then
    raise exception 'P1-03 Stage5 Paper03 rollback left Stage5 approvals';
  end if;
  if (select stage4_policy_status from private.exam_prep_stage4_release_controls where status='active')<>'pending'
     or (select paper02_release_status from private.exam_prep_stage4_release_controls where status='active')<>'pending' then
    raise exception 'P1-03 Stage5 Paper03 rollback left Stage4 approvals';
  end if;
  if (select key_registry_status from private.exam_prep_stage3_exit_rules where status='active')<>'pending'
     or exists(select 1 from private.exam_prep_stage3_key_skills) then
    raise exception 'P1-03 Stage5 Paper03 rollback left Stage3 key governance';
  end if;
  if to_regprocedure('private.exam_prep_stage4_exit_status_v1(uuid,bigint,text)') is not null
     or to_regprocedure('private.exam_prep_stage5_readiness_status_v1(uuid,bigint,text)') is not null then
    raise exception 'P1-03 Stage5 Paper03 rollback left CI stubs';
  end if;
  select count(*) into v_forms from private.exam_prep_assessments
    where assessment_key in ('p1_stage4_full_paper_03','p5_stage4_full_paper_03') and assessment_version='av1' and status='approved';
  if v_forms<>2 then raise exception 'P1-03 Stage5 Paper03 rollback did not restore approved forms=%',v_forms; end if;
  select count(*) into v_contracts from private.exam_prep_timed_assessment_contracts c join private.exam_prep_assessments a on a.id=c.assessment_id
    where a.assessment_key in ('p1_stage4_full_paper_03','p5_stage4_full_paper_03');
  if v_contracts<>0 then raise exception 'P1-03 Stage5 Paper03 rollback left contracts=%',v_contracts; end if;
end $$;

\echo 'P1-03 Stage-5 Paper03 release guard matrix: GREEN'
