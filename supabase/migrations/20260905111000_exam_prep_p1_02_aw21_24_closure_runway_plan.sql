-- P1-02 continuation: AW21-24 syllabus-closure governed runway plan.
-- Planning rows only. No learner access is granted by this migration.
-- Closure target: all remaining canonical skills -> 45/45 P1 and 36/36 P5.

begin;

with pv as (
  select id from private.exam_prep_program_versions
  where program_key='math_as_p1_p5' and version_key='p1_p5_canonical_v1_0'
)
insert into private.exam_prep_content_runway_releases(
  program_version_id,runway_version,release_key,component_code,
  active_week_from,active_week_through,schedule_status,release_note
)
select pv.id,'annual_runway_v1','aw21_24_syllabus_closure','P1',21,24,'active',
       'AW21-24 syllabus-closure runway: remaining coordinate geometry, differentiation applications and integration; cumulative target 45/45 P1 skills (100%).'
from pv
union all
select pv.id,'annual_runway_v1','aw21_24_syllabus_closure','P5',21,24,'active',
       'AW21-24 syllabus-closure runway: remaining data comparison/coding plus normal distribution procedures through normal approximation; cumulative target 36/36 P5 skills (100%).'
from pv
on conflict(program_version_id,runway_version,release_key,component_code) do nothing;

with rel as (
  select r.id,r.component_code
  from private.exam_prep_content_runway_releases r
  join private.exam_prep_program_versions pv on pv.id=r.program_version_id
  where pv.program_key='math_as_p1_p5'
    and pv.version_key='p1_p5_canonical_v1_0'
    and r.runway_version='annual_runway_v1'
    and r.release_key='aw21_24_syllabus_closure'
), skills(component_code,skill_code) as (values
  ('P1','P1-COO-05'),('P1','P1-COO-06'),
  ('P1','P1-DIF-05'),('P1','P1-DIF-06'),('P1','P1-DIF-07'),
  ('P1','P1-INT-01'),('P1','P1-INT-02'),('P1','P1-INT-03'),('P1','P1-INT-04'),('P1','P1-INT-05'),
  ('P5','P5-DAT-08'),('P5','P5-DAT-09'),('P5','P5-DAT-10'),
  ('P5','P5-NOR-02'),('P5','P5-NOR-03'),('P5','P5-NOR-04'),('P5','P5-NOR-05'),('P5','P5-NOR-06')
)
insert into private.exam_prep_content_runway_release_skills(release_id,skill_code,required_for_release)
select rel.id,s.skill_code,true from rel join skills s using(component_code)
on conflict(release_id,skill_code) do update set required_for_release=excluded.required_for_release;

-- Every canonical prerequisite must be either in an earlier release or earlier
-- in canonical sequence inside the same AW21-24 component release.
do $$
declare v_program bigint; v_bad int;
begin
  select id into v_program from private.exam_prep_program_versions
  where program_key='math_as_p1_p5' and version_key='p1_p5_canonical_v1_0';

  with current_release as (
    select r.component_code,rs.skill_code,n.sequence_no
    from private.exam_prep_content_runway_releases r
    join private.exam_prep_content_runway_release_skills rs on rs.release_id=r.id and rs.required_for_release
    join private.exam_prep_syllabus_nodes n
      on n.program_version_id=r.program_version_id
     and n.component_code=r.component_code and n.skill_code=rs.skill_code
    where r.program_version_id=v_program
      and r.release_key='aw21_24_syllabus_closure' and r.schedule_status='active'
  ), earlier as (
    select distinct rs.skill_code
    from private.exam_prep_content_runway_releases r
    join private.exam_prep_content_runway_release_skills rs on rs.release_id=r.id and rs.required_for_release
    where r.program_version_id=v_program and r.schedule_status='active' and r.active_week_through<21
  )
  select count(*) into v_bad
  from current_release target
  join private.exam_prep_prerequisite_edges e
    on e.program_version_id=v_program
   and e.target_component_code=target.component_code
   and e.to_skill_code=target.skill_code
  where (e.from_node_code like 'P1-%' or e.from_node_code like 'P5-%')
    and not exists(select 1 from earlier x where x.skill_code=e.from_node_code)
    and not exists(
      select 1 from current_release prior
      where prior.skill_code=e.from_node_code
        and prior.component_code=target.component_code
        and prior.sequence_no<target.sequence_no
    );
  if v_bad<>0 then raise exception 'AW21-24 prerequisite closure violations=%',v_bad; end if;
end $$;

-- Closure schedule covers every canonical P1/P5 skill exactly through AW24.
do $$
declare v_p1 int; v_p5 int;
begin
  select count(distinct rs.skill_code) into v_p1
  from private.exam_prep_content_runway_release_skills rs
  join private.exam_prep_content_runway_releases r on r.id=rs.release_id
  where r.runway_version='annual_runway_v1' and r.schedule_status='active'
    and r.active_week_from<=24 and r.component_code='P1' and rs.required_for_release;
  select count(distinct rs.skill_code) into v_p5
  from private.exam_prep_content_runway_release_skills rs
  join private.exam_prep_content_runway_releases r on r.id=rs.release_id
  where r.runway_version='annual_runway_v1' and r.schedule_status='active'
    and r.active_week_from<=24 and r.component_code='P5' and rs.required_for_release;
  if v_p1<>45 then raise exception 'AW21-24 P1 closure target must be 45, got %',v_p1; end if;
  if v_p5<>36 then raise exception 'AW21-24 P5 closure target must be 36, got %',v_p5; end if;
end $$;

-- Planning must remain fail-closed and must not create learner runtime state.
do $$
declare v_cfg private.exam_prep_feature_config%rowtype; v_active int;
begin
  select * into v_cfg from private.exam_prep_feature_config where id=1;
  if v_cfg.rollout_state<>'off' or v_cfg.core_enabled or v_cfg.ai_enabled or v_cfg.mentor_enabled or not v_cfg.kill_switch then
    raise exception 'P1-02 AW21-24 planning requires fail-closed feature state';
  end if;
  select count(*) into v_active from private.exam_prep_feature_entitlements where entitlement_status='active';
  if v_active<>0 then raise exception 'P1-02 AW21-24 planning found active entitlements=%',v_active; end if;
  if exists(select 1 from private.exam_prep_sessions)
     or exists(select 1 from private.exam_prep_component_placements)
     or exists(select 1 from private.exam_prep_weekly_plans)
     or exists(select 1 from private.exam_prep_evidence_events) then
    raise exception 'P1-02 AW21-24 planning found unexpected learner runtime state';
  end if;
end $$;

commit;
