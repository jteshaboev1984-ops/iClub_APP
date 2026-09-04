-- P1-02 continuation: AW5-8 governed runway plan.
-- Planning rows only; readiness remains RED until full governed content packs exist.

begin;

with pv as (
  select id from private.exam_prep_program_versions
  where program_key='math_as_p1_p5' and version_key='p1_p5_canonical_v1_0'
)
insert into private.exam_prep_content_runway_releases(
  program_version_id,runway_version,release_key,component_code,
  active_week_from,active_week_through,schedule_status,release_note
)
select pv.id,'annual_runway_v1','aw05_08_core_coverage_i','P1',5,8,'active',
       'AW5-8 governed runway: prerequisite-closed P1 Functions/Coordinate/Circular/Trigonometry slice targeting ~25-30% cumulative coverage.'
from pv
union all
select pv.id,'annual_runway_v1','aw05_08_core_coverage_i','P5',5,8,'active',
       'AW5-8 governed runway: prerequisite-closed P5 Counting/Probability slice targeting ~25-30% cumulative coverage.'
from pv
on conflict(program_version_id,runway_version,release_key,component_code) do nothing;

with rel as (
  select r.id,r.component_code
  from private.exam_prep_content_runway_releases r
  join private.exam_prep_program_versions pv on pv.id=r.program_version_id
  where pv.program_key='math_as_p1_p5'
    and pv.version_key='p1_p5_canonical_v1_0'
    and r.runway_version='annual_runway_v1'
    and r.release_key='aw05_08_core_coverage_i'
), skills(component_code,skill_code) as (values
  ('P1','P1-FUN-06'),('P1','P1-FUN-07'),('P1','P1-FUN-08'),
  ('P1','P1-COO-01'),('P1','P1-COO-02'),('P1','P1-COO-03'),
  ('P1','P1-CIR-01'),('P1','P1-TRI-01'),
  ('P5','P5-CNT-01'),('P5','P5-CNT-02'),('P5','P5-CNT-03'),('P5','P5-CNT-04'),
  ('P5','P5-PRO-01'),('P5','P5-PRO-03')
)
insert into private.exam_prep_content_runway_release_skills(release_id,skill_code,required_for_release)
select rel.id,s.skill_code,true
from rel join skills s using(component_code)
on conflict(release_id,skill_code) do update set required_for_release=excluded.required_for_release;

-- Coverage math is a planning invariant only. Content readiness is evaluated separately by the P1-02 gate.
do $$
declare
  v_p1_count int; v_p5_count int;
begin
  select count(*) into v_p1_count
  from private.exam_prep_content_runway_release_skills rs
  join private.exam_prep_content_runway_releases r on r.id=rs.release_id
  where r.release_key in ('aw01_04_foundations','aw05_08_core_coverage_i')
    and r.component_code='P1' and rs.required_for_release;

  select count(*) into v_p5_count
  from private.exam_prep_content_runway_release_skills rs
  join private.exam_prep_content_runway_releases r on r.id=rs.release_id
  where r.release_key in ('aw01_04_foundations','aw05_08_core_coverage_i')
    and r.component_code='P5' and rs.required_for_release;

  if v_p1_count<>13 then raise exception 'AW5-8 P1 cumulative runway target must be 13 skills, got %',v_p1_count; end if;
  if v_p5_count<>10 then raise exception 'AW5-8 P5 cumulative runway target must be 10 skills, got %',v_p5_count; end if;
end $$;

commit;
