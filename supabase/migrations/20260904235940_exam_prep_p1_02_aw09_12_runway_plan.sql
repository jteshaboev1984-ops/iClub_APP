-- P1-02 continuation: AW9-12 governed runway plan.
-- Planning rows only. New skills remain learner-inaccessible until a published
-- governed content version independently satisfies the full P1-02 skill floor.
-- This migration is additive and must leave the controlled beta fail-closed.

begin;

with pv as (
  select id from private.exam_prep_program_versions
  where program_key='math_as_p1_p5' and version_key='p1_p5_canonical_v1_0'
)
insert into private.exam_prep_content_runway_releases(
  program_version_id,runway_version,release_key,component_code,
  active_week_from,active_week_through,schedule_status,release_note
)
select pv.id,'annual_runway_v1','aw09_12_core_coverage_ii','P1',9,12,'active',
       'AW9-12 governed runway: complete Quadratics core, composite/inverse Functions bridge, circle equation and arc-length progression; target ~47% cumulative P1 skill coverage.'
from pv
union all
select pv.id,'annual_runway_v1','aw09_12_core_coverage_ii','P5',9,12,'active',
       'AW9-12 governed runway: cumulative-frequency/boxplot/spread bridge, combinations completion and probability-by-counting/independence progression; target ~44% cumulative P5 skill coverage.'
from pv
on conflict(program_version_id,runway_version,release_key,component_code) do nothing;

with rel as (
  select r.id,r.component_code
  from private.exam_prep_content_runway_releases r
  join private.exam_prep_program_versions pv on pv.id=r.program_version_id
  where pv.program_key='math_as_p1_p5'
    and pv.version_key='p1_p5_canonical_v1_0'
    and r.runway_version='annual_runway_v1'
    and r.release_key='aw09_12_core_coverage_ii'
), skills(component_code,skill_code) as (values
  ('P1','P1-QUA-04'),('P1','P1-QUA-05'),('P1','P1-QUA-06'),
  ('P1','P1-FUN-03'),('P1','P1-FUN-04'),('P1','P1-FUN-05'),
  ('P1','P1-COO-04'),('P1','P1-CIR-02'),
  ('P5','P5-DAT-05'),('P5','P5-DAT-03'),('P5','P5-DAT-07'),
  ('P5','P5-CNT-05'),('P5','P5-PRO-02'),('P5','P5-PRO-04')
)
insert into private.exam_prep_content_runway_release_skills(release_id,skill_code,required_for_release)
select rel.id,s.skill_code,true
from rel join skills s using(component_code)
on conflict(release_id,skill_code) do update set required_for_release=excluded.required_for_release;

-- The release may depend on skills inside the same AW9-12 window, but it may not
-- introduce a forward/cyclic prerequisite. Every skill prerequisite must already
-- be in an earlier active release or appear earlier in canonical sequence inside
-- this same release.
do $$
declare
  v_program bigint;
  v_bad int;
begin
  select id into v_program
  from private.exam_prep_program_versions
  where program_key='math_as_p1_p5' and version_key='p1_p5_canonical_v1_0';

  with current_release as (
    select r.component_code,rs.skill_code,n.sequence_no
    from private.exam_prep_content_runway_releases r
    join private.exam_prep_content_runway_release_skills rs on rs.release_id=r.id and rs.required_for_release
    join private.exam_prep_syllabus_nodes n
      on n.program_version_id=r.program_version_id
     and n.component_code=r.component_code
     and n.skill_code=rs.skill_code
    where r.program_version_id=v_program
      and r.release_key='aw09_12_core_coverage_ii'
      and r.schedule_status='active'
  ), earlier as (
    select distinct rs.skill_code
    from private.exam_prep_content_runway_releases r
    join private.exam_prep_content_runway_release_skills rs on rs.release_id=r.id and rs.required_for_release
    where r.program_version_id=v_program
      and r.schedule_status='active'
      and r.active_week_through<9
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

  if v_bad<>0 then
    raise exception 'AW9-12 runway prerequisite closure violations=%',v_bad;
  end if;
end $$;

-- Planning invariants: AW1-12 cumulative coverage becomes 21/45 P1 and 16/36 P5.
do $$
declare
  v_p1_count int;
  v_p5_count int;
begin
  select count(distinct rs.skill_code) into v_p1_count
  from private.exam_prep_content_runway_release_skills rs
  join private.exam_prep_content_runway_releases r on r.id=rs.release_id
  where r.runway_version='annual_runway_v1'
    and r.schedule_status='active'
    and r.active_week_from<=12
    and r.component_code='P1'
    and rs.required_for_release;

  select count(distinct rs.skill_code) into v_p5_count
  from private.exam_prep_content_runway_release_skills rs
  join private.exam_prep_content_runway_releases r on r.id=rs.release_id
  where r.runway_version='annual_runway_v1'
    and r.schedule_status='active'
    and r.active_week_from<=12
    and r.component_code='P5'
    and rs.required_for_release;

  if v_p1_count<>21 then
    raise exception 'AW9-12 P1 cumulative runway target must be 21 skills, got %',v_p1_count;
  end if;
  if v_p5_count<>16 then
    raise exception 'AW9-12 P5 cumulative runway target must be 16 skills, got %',v_p5_count;
  end if;
end $$;

-- Deployment invariant: a schedule extension must never activate the beta.
do $$
declare
  v_cfg private.exam_prep_feature_config%rowtype;
  v_active int;
begin
  select * into v_cfg from private.exam_prep_feature_config where id=1;
  if v_cfg.rollout_state<>'off'
     or v_cfg.core_enabled
     or v_cfg.ai_enabled
     or v_cfg.mentor_enabled
     or not v_cfg.kill_switch then
    raise exception 'P1-02 AW9-12 runway planning requires fail-closed feature state';
  end if;

  select count(*) into v_active
  from private.exam_prep_feature_entitlements
  where entitlement_status='active';
  if v_active<>0 then
    raise exception 'P1-02 AW9-12 runway planning found active entitlements=%',v_active;
  end if;
end $$;

commit;