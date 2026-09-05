-- P1-03 / operational-stage hardening.
-- Makes Stage 1 -> 2 -> 3 progression machine-readable and evidence-driven.
-- Stage 4+ remains deliberately disabled in this rule version.
-- No learner entitlement, feature-flag or legacy mutation.
begin;

create table if not exists private.exam_prep_operational_stage_rules (
  rule_version text primary key,
  status text not null check (status in ('draft','active','retired')),
  stage1_to_2_min_coverage_pct numeric(5,2) not null check (stage1_to_2_min_coverage_pct between 0 and 100),
  stage2_to_3_min_coverage_pct numeric(5,2) not null check (stage2_to_3_min_coverage_pct between 0 and 100),
  fast_track_to_stage2 boolean not null default true,
  max_automatic_stage smallint not null default 3 check (max_automatic_stage between 1 and 3),
  source_note text not null,
  created_at timestamptz not null default now(),
  check (stage2_to_3_min_coverage_pct >= stage1_to_2_min_coverage_pct)
);

create unique index if not exists exam_prep_operational_stage_rules_one_active_idx
  on private.exam_prep_operational_stage_rules ((status)) where status='active';

insert into private.exam_prep_operational_stage_rules(
  rule_version,status,stage1_to_2_min_coverage_pct,stage2_to_3_min_coverage_pct,
  fast_track_to_stage2,max_automatic_stage,source_note
) values (
  'operational_stage_v1_2026_09_05','active',15.00,80.00,true,3,
  'Master Implementation Plan v1.1: Stage 1 exits at 10-15% confirmed coverage or evidence-backed fast-track; conservative implementation uses 15%. Stage 2 Syllabus Building culminates at the 75-80% checkpoint; conservative implementation uses 80%. Stage 3 is Syllabus Closure and is the first stage allowed to access full-paper baseline work. Stage 4+ remains separately gated.'
)
on conflict(rule_version) do update set
  status=excluded.status,
  stage1_to_2_min_coverage_pct=excluded.stage1_to_2_min_coverage_pct,
  stage2_to_3_min_coverage_pct=excluded.stage2_to_3_min_coverage_pct,
  fast_track_to_stage2=excluded.fast_track_to_stage2,
  max_automatic_stage=excluded.max_automatic_stage,
  source_note=excluded.source_note;

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
  v_target smallint := 0;
  v_fast_track boolean := false;
begin
  select * into v_rule
  from private.exam_prep_operational_stage_rules r
  where r.status='active'
  order by r.created_at desc
  limit 1;

  select * into v_gate
  from private.exam_prep_component_access_gates g
  where g.user_id=new.user_id
    and g.program_version_id=new.program_version_id
    and g.component_code=new.component_code
  order by g.updated_at desc
  limit 1;

  select * into v_place
  from private.exam_prep_component_placements p
  where p.user_id=new.user_id
    and p.program_version_id=new.program_version_id
    and p.component_code=new.component_code
  order by p.derived_at desc
  limit 1;

  if v_rule.rule_version is null then
    new.operational_stage:=0;
    new.stage_gate_status:='blocked_dependency';
    new.stage_hold_reason:='Operational-stage rule version is missing; fail closed.';
    return new;
  end if;

  -- Stage 1 is still owned by the existing placement/prerequisite gate.
  if v_gate.user_id is not null
     and v_place.user_id is not null
     and v_place.stage0_complete
     and v_gate.max_unlocked_stage>=1 then
    v_target:=1;
  end if;

  v_fast_track:=coalesce(v_rule.fast_track_to_stage2,false)
                and coalesce(v_gate.advanced_route_access,false);

  -- Stage 1 -> 2: prerequisites must not contain an explicit blocker and
  -- either conservative 15% confirmed coverage or an approved fast-track route is required.
  if v_target>=1
     and coalesce(v_place.prerequisite_blocker_count,0)=0
     and (
       coalesce(new.coverage_pct,0)>=v_rule.stage1_to_2_min_coverage_pct
       or v_fast_track
     ) then
    v_target:=2;
  end if;

  -- Stage 2 -> 3: no calendar auto-advance. The final Syllabus-Building
  -- checkpoint is the conservative 80% confirmed-coverage threshold.
  if v_target>=2
     and coalesce(new.coverage_pct,0)>=v_rule.stage2_to_3_min_coverage_pct then
    v_target:=3;
  end if;

  new.operational_stage:=least(v_target,v_rule.max_automatic_stage);

  if new.operational_stage=0 then
    new.stage_gate_status:=case when coalesce(new.evidence_stage_candidate,0)>0 then 'evidence_candidate' else 'blocked_dependency' end;
    new.stage_hold_reason:='Stage 0 placement/prerequisite gate is not complete; higher stages remain fail closed.';
  elsif new.operational_stage=1 then
    new.stage_gate_status:='operational';
    if coalesce(v_place.prerequisite_blocker_count,0)>0 then
      new.stage_hold_reason:='Stage 1 Foundation remains active because an explicit prerequisite blocker is open.';
    else
      new.stage_hold_reason:=format(
        'Stage 1 Foundation active; Stage 2 requires %.2f%% confirmed coverage or governed fast-track.',
        v_rule.stage1_to_2_min_coverage_pct
      );
    end if;
  elsif new.operational_stage=2 then
    new.stage_gate_status:='operational';
    new.stage_hold_reason:=format(
      'Stage 2 Syllabus Building active; Stage 3 requires %.2f%% confirmed coverage. Timed sections and modified papers are allowed; full paper remains closed.',
      v_rule.stage2_to_3_min_coverage_pct
    );
  else
    new.stage_gate_status:='operational';
    new.stage_hold_reason:='Stage 3 Syllabus Closure active. Full-paper baseline work is allowed; Stage 4+ remains separately gated and is not auto-awarded by coverage.';
  end if;

  return new;
end;
$$;

revoke all on function private.exam_prep_apply_stage0_gate_v1() from public,anon,authenticated;
grant execute on function private.exam_prep_apply_stage0_gate_v1() to service_role;

-- Keep the placement/access projection numerically aligned with the authoritative stage row.
-- gate_status remains a placement-status enum and is intentionally not overloaded with stage semantics.
create or replace function private.exam_prep_sync_access_gate_stage_v1()
returns trigger
language plpgsql
security definer
set search_path=''
as $$
begin
  update private.exam_prep_component_access_gates g
  set current_operational_stage=new.operational_stage,
      max_unlocked_stage=new.operational_stage,
      gate_reason=coalesce(new.stage_hold_reason,g.gate_reason),
      updated_at=now()
  where g.user_id=new.user_id
    and g.program_version_id=new.program_version_id
    and g.component_code=new.component_code
    and g.rule_version=(
      select g2.rule_version
      from private.exam_prep_component_access_gates g2
      where g2.user_id=new.user_id
        and g2.program_version_id=new.program_version_id
        and g2.component_code=new.component_code
      order by g2.updated_at desc
      limit 1
    );
  return new;
end;
$$;

revoke all on function private.exam_prep_sync_access_gate_stage_v1() from public,anon,authenticated;
grant execute on function private.exam_prep_sync_access_gate_stage_v1() to service_role;

drop trigger if exists exam_prep_stage_access_sync_v1 on private.exam_prep_stage_states;
create trigger exam_prep_stage_access_sync_v1
after insert or update on private.exam_prep_stage_states
for each row execute function private.exam_prep_sync_access_gate_stage_v1();

-- Deployment invariant: rules may be installed only while live beta is fail closed.
do $$
declare
  v_cfg private.exam_prep_feature_config%rowtype;
  v_active int;
begin
  select * into v_cfg from private.exam_prep_feature_config where program_key='math_as_p1_p5';
  if v_cfg.rollout_state<>'off' or v_cfg.core_enabled or v_cfg.ai_enabled or v_cfg.mentor_enabled or not v_cfg.kill_switch then
    raise exception 'P1-03 operational-stage rule deployment requires fail-closed feature state';
  end if;
  select count(*) into v_active from private.exam_prep_feature_entitlements where entitlement_status='active';
  if v_active<>0 then raise exception 'P1-03 operational-stage rule deployment active entitlement residue=%',v_active; end if;
end $$;

commit;