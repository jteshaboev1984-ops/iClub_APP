-- Exam Prep Stage-4 operational access + Paper02 release v1.
-- Preserves Stage 0-3 rules exactly, adds Stage 3 -> 4 only through the governed Stage-3 exit evaluator,
-- and publishes the already QA-governed original iClub Paper02 forms behind min_operational_stage=4.
-- Stage 5 remains locked. AI/Mentor/legacy data are untouched.

begin;

alter table private.exam_prep_operational_stage_rules
  drop constraint if exists exam_prep_operational_stage_rules_max_automatic_stage_check;
alter table private.exam_prep_operational_stage_rules
  add constraint exam_prep_operational_stage_rules_max_automatic_stage_check
  check(max_automatic_stage between 1 and 6);

update private.exam_prep_operational_stage_rules
set status='retired'
where status='active';

insert into private.exam_prep_operational_stage_rules(
  rule_version,status,stage1_to_2_min_coverage_pct,stage2_to_3_min_coverage_pct,
  fast_track_to_stage2,max_automatic_stage,source_note
) values (
  'operational_stage_v2_2026_09_07','active',15.00,80.00,true,4,
  'Stage 0-3 semantics preserved from operational_stage_v1_2026_09_05. Stage 3 -> 4 is now allowed only when private.exam_prep_stage3_exit_status_v1 is ready for the same learner/program/component. Stage 5+ remains separately locked.'
);

create or replace function private.exam_prep_apply_stage0_gate_v1()
returns trigger
language plpgsql
security definer
set search_path=''
as $$
declare
  v_gate private.exam_prep_component_access_gates%rowtype;
  v_place private.exam_prep_component_placements%rowtype;
  v_rule private.exam_prep_operational_stage_rules%rowtype;
  v_stage3 jsonb;
  v_target smallint:=0;
  v_fast_track boolean:=false;
begin
  select * into v_rule from private.exam_prep_operational_stage_rules r where r.status='active' order by r.created_at desc limit 1;
  select * into v_gate from private.exam_prep_component_access_gates g where g.user_id=new.user_id and g.program_version_id=new.program_version_id and g.component_code=new.component_code order by g.updated_at desc limit 1;
  select * into v_place from private.exam_prep_component_placements p where p.user_id=new.user_id and p.program_version_id=new.program_version_id and p.component_code=new.component_code order by p.derived_at desc limit 1;

  if v_rule.rule_version is null then
    new.operational_stage:=0;
    new.stage_gate_status:='blocked_dependency';
    new.stage_hold_reason:='Operational-stage rule version is missing; fail closed.';
    return new;
  end if;

  if v_gate.user_id is not null and v_place.user_id is not null and v_place.stage0_complete and v_gate.max_unlocked_stage>=1 then v_target:=1; end if;
  v_fast_track:=coalesce(v_rule.fast_track_to_stage2,false) and coalesce(v_gate.advanced_route_access,false);
  if v_target>=1 and coalesce(v_place.prerequisite_blocker_count,0)=0 and (coalesce(new.coverage_pct,0)>=v_rule.stage1_to_2_min_coverage_pct or v_fast_track) then v_target:=2; end if;
  if v_target>=2 and coalesce(new.coverage_pct,0)>=v_rule.stage2_to_3_min_coverage_pct then v_target:=3; end if;
  if v_target>=3 and v_rule.max_automatic_stage>=4 then
    v_stage3:=private.exam_prep_stage3_exit_status_v1(new.user_id,new.program_version_id,new.component_code);
    if coalesce((v_stage3->>'ready')::boolean,false) then v_target:=4; end if;
  end if;

  new.operational_stage:=least(v_target,v_rule.max_automatic_stage);
  if new.operational_stage=0 then
    new.stage_gate_status:=case when coalesce(new.evidence_stage_candidate,0)>0 then 'evidence_candidate' else 'blocked_dependency' end;
    new.stage_hold_reason:='Stage 0 placement/prerequisite gate is not complete; higher stages remain fail closed.';
  elsif new.operational_stage=1 then
    new.stage_gate_status:='operational';
    if coalesce(v_place.prerequisite_blocker_count,0)>0 then new.stage_hold_reason:='Stage 1 Foundation remains active because an explicit prerequisite blocker is open.';
    else new.stage_hold_reason:=format('Stage 1 Foundation active; Stage 2 requires %s%% confirmed coverage or governed fast-track.',v_rule.stage1_to_2_min_coverage_pct); end if;
  elsif new.operational_stage=2 then
    new.stage_gate_status:='operational';
    new.stage_hold_reason:=format('Stage 2 Syllabus Building active; Stage 3 requires %s%% confirmed coverage. Timed sections and modified papers are allowed; full paper remains closed.',v_rule.stage2_to_3_min_coverage_pct);
  elsif new.operational_stage=3 then
    new.stage_gate_status:='operational';
    new.stage_hold_reason:='Stage 3 Syllabus Closure active. Stage 4 requires 100% confirmed component coverage, all canonical skills at least L2, governed key skills at L3, no unknown section, and a comparable first full-paper baseline.';
  else
    new.stage_gate_status:='operational';
    new.stage_hold_reason:='Stage 4 Timed Consolidation active. Stage 5 remains separately evidence-gated; calendar time cannot promote the learner.';
  end if;
  return new;
end;
$$;

revoke all on function private.exam_prep_apply_stage0_gate_v1() from public,anon,authenticated;
grant execute on function private.exam_prep_apply_stage0_gate_v1() to service_role;

update private.exam_prep_stage4_release_controls
set paper02_release_status='approved',
    source_note=source_note || ' Release amendment 2026-09-07: Stage-4 operational access v1 approved; original iClub Paper02 forms may be published only behind min operational stage 4.',
    updated_at=now()
where status='active';

do $$ declare v_p1 jsonb; v_p5 jsonb; begin
  v_p1:=private.exam_prep_stage4_paper02_release_readiness_v1('P1');
  v_p5:=private.exam_prep_stage4_paper02_release_readiness_v1('P5');
  if not coalesce((v_p1->>'ready')::boolean,false) or not coalesce((v_p5->>'ready')::boolean,false) then raise exception 'Stage4 Paper02 release readiness failed P1=% P5=%',v_p1,v_p5; end if;
end $$;

update private.exam_prep_assessments
set status='published'
where assessment_key in ('p1_stage4_full_paper_02','p5_stage4_full_paper_02') and assessment_version='av1' and status='approved';

with target as (
  select a.id,a.component_code,a.assessment_key,p.id as paper_profile_id,p.official_total_marks
  from private.exam_prep_assessments a
  join private.exam_prep_content_versions cv on cv.id=a.content_version_id
  join private.exam_prep_component_paper_profiles p
    on p.program_version_id=cv.program_version_id and p.component_code=a.component_code
   and p.profile_version='9709_2026_2027_v1' and p.status='published'
  where a.assessment_key in ('p1_stage4_full_paper_02','p5_stage4_full_paper_02')
    and a.assessment_version='av1' and a.status='published'
)
insert into private.exam_prep_timed_assessment_contracts(
  assessment_id,paper_profile_id,contract_version,attempt_kind,timing_rule,
  marks_available,fixed_time_limit_sec,strict_timing,comparison_scope,comparability_key,status,published_at,min_operational_stage
)
select id,paper_profile_id,
       case component_code when 'P1' then 'p1_stage4_full_paper_02_contract_v1' else 'p5_stage4_full_paper_02_contract_v1' end,
       'full_paper','official_full',official_total_marks,null,true,'full',
       case component_code when 'P1' then 'p1-full-paper-02-v1' else 'p5-full-paper-02-v1' end,
       'published',now(),4
from target;

do $$
declare v_max smallint; v_published int; v_contracts int; v_bad int; v_cfg private.exam_prep_feature_config%rowtype; begin
  select max_automatic_stage into v_max from private.exam_prep_operational_stage_rules where status='active';
  if v_max<>4 then raise exception 'Stage4 access release: expected max automatic stage 4 got=%',v_max; end if;
  select count(*) into v_published from private.exam_prep_assessments where assessment_key in ('p1_stage4_full_paper_02','p5_stage4_full_paper_02') and assessment_version='av1' and status='published';
  if v_published<>2 then raise exception 'Stage4 access release: Paper02 assessment publish mismatch=%',v_published; end if;
  select count(*) into v_contracts from private.exam_prep_timed_assessment_contracts c join private.exam_prep_assessments a on a.id=c.assessment_id where a.assessment_key in ('p1_stage4_full_paper_02','p5_stage4_full_paper_02') and c.status='published' and c.attempt_kind='full_paper' and c.timing_rule='official_full' and c.comparison_scope='full' and c.strict_timing and c.min_operational_stage=4;
  if v_contracts<>2 then raise exception 'Stage4 access release: Paper02 contract mismatch=%',v_contracts; end if;
  select count(*) into v_bad from private.exam_prep_timed_assessment_contracts c join private.exam_prep_assessments a on a.id=c.assessment_id where a.assessment_key in ('p1_stage4_full_paper_02','p5_stage4_full_paper_02') and private.exam_prep_timed_effective_min_stage_v1(c.attempt_kind,c.min_operational_stage::integer)<4;
  if v_bad<>0 then raise exception 'Stage4 access release: Paper02 stage leakage=%',v_bad; end if;
  if exists(select 1 from private.exam_prep_stage_states where operational_stage>4) then raise exception 'Stage4 access release: learner stage above approved ceiling'; end if;
  select * into v_cfg from private.exam_prep_feature_config where program_key='math_as_p1_p5';
  if v_cfg.rollout_state<>'controlled_beta' or not v_cfg.core_enabled or v_cfg.ai_enabled or v_cfg.mentor_enabled or v_cfg.kill_switch then raise exception 'Stage4 access release: Core-only canary boundary drift'; end if;
end $$;

commit;