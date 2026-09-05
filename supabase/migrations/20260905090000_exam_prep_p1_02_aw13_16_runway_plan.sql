-- P1-02 continuation: AW13-16 governed runway plan.
-- Target: end-AW16 60-65% first coverage per component, consistent with annual roadmap.
-- Planning rows only: no skill becomes learner-ready until a published content version
-- independently satisfies the existing governed content floor.

begin;

with pv as (
  select id from private.exam_prep_program_versions
  where program_key='math_as_p1_p5' and version_key='p1_p5_canonical_v1_0'
)
insert into private.exam_prep_content_runway_releases(
  program_version_id,runway_version,release_key,component_code,
  active_week_from,active_week_through,schedule_status,release_note
)
select pv.id,'annual_runway_v1','aw13_16_core_coverage_iii','P1',13,16,'active',
       'AW13-16 governed runway: close Circular/Trigonometry, then introduce Series and Differentiation foundations; cumulative target 29/45 = 64.4%.'
from pv
union all
select pv.id,'annual_runway_v1','aw13_16_core_coverage_iii','P5',13,16,'active',
       'AW13-16 governed runway: close core Probability, then introduce discrete random variables plus Binomial/Geometric model recognition; cumulative target 23/36 = 63.9%.'
from pv
on conflict(program_version_id,runway_version,release_key,component_code) do nothing;

with rel as (
  select r.id,r.component_code
  from private.exam_prep_content_runway_releases r
  join private.exam_prep_program_versions pv on pv.id=r.program_version_id
  where pv.program_key='math_as_p1_p5'
    and pv.version_key='p1_p5_canonical_v1_0'
    and r.runway_version='annual_runway_v1'
    and r.release_key='aw13_16_core_coverage_iii'
), skills(component_code,skill_code) as (values
  ('P1','P1-CIR-03'),
  ('P1','P1-TRI-02'),('P1','P1-TRI-03'),('P1','P1-TRI-04'),('P1','P1-TRI-05'),
  ('P1','P1-SER-01'),('P1','P1-SER-02'),('P1','P1-DIF-01'),
  ('P5','P5-PRO-05'),('P5','P5-PRO-06'),
  ('P5','P5-DRV-01'),('P5','P5-DRV-02'),('P5','P5-DRV-03'),
  ('P5','P5-BIN-01'),('P5','P5-GEO-01')
)
insert into private.exam_prep_content_runway_release_skills(release_id,skill_code,required_for_release)
select rel.id,s.skill_code,true
from rel join skills s using(component_code)
on conflict(release_id,skill_code) do update set required_for_release=excluded.required_for_release;

-- Prerequisite closure: a canonical skill prerequisite must be in an earlier active release,
-- or earlier in canonical sequence inside this same AW13-16 slice. Shared PR-* nodes are
-- outside the P1/P5 denominator and remain governed by the prerequisite layer.
do $$
declare v_program bigint; v_bad int;
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
      and r.release_key='aw13_16_core_coverage_iii'
      and r.schedule_status='active'
  ), earlier as (
    select distinct rs.skill_code
    from private.exam_prep_content_runway_releases r
    join private.exam_prep_content_runway_release_skills rs on rs.release_id=r.id and rs.required_for_release
    where r.program_version_id=v_program
      and r.schedule_status='active'
      and r.active_week_through<13
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

  if v_bad<>0 then raise exception 'AW13-16 runway prerequisite closure violations=%',v_bad; end if;
end $$;

-- Coverage checkpoint: AW16 should land inside the roadmap's 60-65% band independently
-- for P1 and P5, never through a combined denominator.
do $$
declare v_p1 int; v_p5 int; v_p1_pct numeric; v_p5_pct numeric;
begin
  select count(distinct rs.skill_code) into v_p1
  from private.exam_prep_content_runway_release_skills rs
  join private.exam_prep_content_runway_releases r on r.id=rs.release_id
  where r.runway_version='annual_runway_v1' and r.schedule_status='active'
    and r.active_week_from<=16 and r.component_code='P1' and rs.required_for_release;

  select count(distinct rs.skill_code) into v_p5
  from private.exam_prep_content_runway_release_skills rs
  join private.exam_prep_content_runway_releases r on r.id=rs.release_id
  where r.runway_version='annual_runway_v1' and r.schedule_status='active'
    and r.active_week_from<=16 and r.component_code='P5' and rs.required_for_release;

  v_p1_pct:=100.0*v_p1/45.0;
  v_p5_pct:=100.0*v_p5/36.0;
  if v_p1<>29 or v_p1_pct<60 or v_p1_pct>65 then
    raise exception 'AW16 P1 coverage target invalid count=% pct=%',v_p1,v_p1_pct;
  end if;
  if v_p5<>23 or v_p5_pct<60 or v_p5_pct>65 then
    raise exception 'AW16 P5 coverage target invalid count=% pct=%',v_p5,v_p5_pct;
  end if;
end $$;

-- Schedule extension must remain completely fail-closed.
do $$
declare v_cfg private.exam_prep_feature_config%rowtype; v_active int;
begin
  select * into v_cfg from private.exam_prep_feature_config where id=1;
  if v_cfg.rollout_state<>'off' or v_cfg.core_enabled or v_cfg.ai_enabled or v_cfg.mentor_enabled or not v_cfg.kill_switch then
    raise exception 'P1-02 AW13-16 runway planning requires fail-closed feature state';
  end if;
  select count(*) into v_active from private.exam_prep_feature_entitlements where entitlement_status='active';
  if v_active<>0 then raise exception 'P1-02 AW13-16 runway planning found active entitlements=%',v_active; end if;
end $$;

commit;
