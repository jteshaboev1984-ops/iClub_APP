-- Exam Prep Stage-6 Final Calibration v1.
-- Stage 5 -> 6 requires the component-specific deterministic App Readiness gate.
-- Stage 6 is a taper/calibration surface only: it does not create mastery, grades or Mentor Verified readiness.

begin;

create table if not exists private.exam_prep_stage6_rules (
  rule_version text primary key,
  status text not null check(status in ('draft','active','retired')),
  require_stage5_readiness boolean not null default true,
  allow_new_mastery_claims boolean not null default false check(allow_new_mastery_claims=false),
  source_note text not null,
  created_at timestamptz not null default now()
);
create unique index if not exists exam_prep_stage6_rules_one_active_idx
  on private.exam_prep_stage6_rules((status)) where status='active';
alter table private.exam_prep_stage6_rules enable row level security;
revoke all on private.exam_prep_stage6_rules from public,anon,authenticated;
grant all on private.exam_prep_stage6_rules to service_role;
do $$ begin execute 'create trigger exam_prep_stage6_rules_audit_v1 after insert or update or delete on private.exam_prep_stage6_rules for each row execute function private.exam_prep_audit_row_change_v1()'; exception when duplicate_object then null; end $$;

insert into private.exam_prep_stage6_rules(rule_version,status,require_stage5_readiness,allow_new_mastery_claims,source_note)
values(
  'stage6_final_calibration_v1_2026_09_07','active',true,false,
  'Master Plan / Mentor Care Stage 6: protect performance rather than chase new mastery; taper workload, use short reserved/targeted work, address at most the remaining evidence-driven issue, confirm exam logistics through approved profile/process, and never manufacture L4/L5/readiness from last-minute volume.'
);

update private.exam_prep_operational_stage_rules
set status='retired'
where status='active';

insert into private.exam_prep_operational_stage_rules(
  rule_version,status,stage1_to_2_min_coverage_pct,stage2_to_3_min_coverage_pct,
  fast_track_to_stage2,max_automatic_stage,source_note
) values (
  'operational_stage_v4_2026_09_07','active',15.00,80.00,true,6,
  'Complete Stage 0-6 operational taxonomy. Stage 0-5 semantics preserved. Stage 5 -> 6 requires private.exam_prep_stage5_readiness_status_v1 ready for the same learner/program/component. Stage 6 creates no new mastery/readiness claim.'
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
  v_stage4 jsonb;
  v_stage5 jsonb;
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

  if v_target>=4 and v_rule.max_automatic_stage>=5 then
    v_stage4:=private.exam_prep_stage4_exit_status_v1(new.user_id,new.program_version_id,new.component_code);
    if coalesce((v_stage4->>'ready')::boolean,false) then v_target:=5; end if;
  end if;

  if v_target>=5 and v_rule.max_automatic_stage>=6 then
    v_stage5:=private.exam_prep_stage5_readiness_status_v1(new.user_id,new.program_version_id,new.component_code);
    if coalesce((v_stage5->>'ready')::boolean,false) then v_target:=6; end if;
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
    new.stage_hold_reason:=format('Stage 2 Syllabus Building active; Stage 3 requires %s%% confirmed coverage.',v_rule.stage2_to_3_min_coverage_pct);
  elsif new.operational_stage=3 then
    new.stage_gate_status:='operational';
    new.stage_hold_reason:='Stage 3 Syllabus Closure active. Stage 4 requires complete component closure, governed key-skill evidence and the first comparable full-paper baseline.';
  elsif new.operational_stage=4 then
    new.stage_gate_status:='operational';
    new.stage_hold_reason:='Stage 4 Timed Consolidation active. Stage 5 requires two compatible strict full papers, stable timing/unattempted evidence and resolved corrective work.';
  elsif new.operational_stage=5 then
    new.stage_gate_status:='operational';
    new.stage_hold_reason:='Stage 5 Exam Readiness active. Stage 6 requires the component-specific App Readiness evidence gate; no date or weighted average can promote it.';
  else
    new.stage_gate_status:='operational';
    new.stage_hold_reason:='Stage 6 Final Calibration active. Protect performance with short targeted work and logistics; no new mastery claim is created from calibration volume.';
  end if;
  return new;
end;
$$;

revoke all on function private.exam_prep_apply_stage0_gate_v1() from public,anon,authenticated;
grant execute on function private.exam_prep_apply_stage0_gate_v1() to service_role;

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
  order by updated_at desc limit 1;

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
declare
  v_rule private.exam_prep_stage6_rules%rowtype;
  v_max smallint;
  v_thresholds int;
  v_cfg private.exam_prep_feature_config%rowtype;
begin
  select * into v_rule from private.exam_prep_stage6_rules where status='active';
  if v_rule.rule_version is null or not v_rule.require_stage5_readiness or v_rule.allow_new_mastery_claims then
    raise exception 'Stage6 policy v1 invalid';
  end if;
  if to_regprocedure('private.exam_prep_stage5_readiness_status_v1(uuid,bigint,text)') is null then raise exception 'Stage6 requires Stage5 readiness evaluator'; end if;
  if to_regprocedure('public.get_exam_prep_final_calibration_safe_v1(text)') is null then raise exception 'Stage6 safe RPC missing'; end if;
  select max_automatic_stage into v_max from private.exam_prep_operational_stage_rules where status='active';
  if v_max<>6 then raise exception 'Stage6 policy v1: complete taxonomy requires ceiling 6 got=%',v_max; end if;
  select count(*) into v_thresholds from private.exam_prep_stage5_thresholds where status='approved';
  if v_thresholds<>0 then raise exception 'Stage6 policy v1: this release must not fabricate readiness thresholds'; end if;
  select * into v_cfg from private.exam_prep_feature_config where program_key='math_as_p1_p5';
  if v_cfg.rollout_state<>'controlled_beta' or not v_cfg.core_enabled or v_cfg.ai_enabled or v_cfg.mentor_enabled or v_cfg.kill_switch then raise exception 'Stage6 policy v1: Core-only canary boundary drift'; end if;
end $$;

commit;
