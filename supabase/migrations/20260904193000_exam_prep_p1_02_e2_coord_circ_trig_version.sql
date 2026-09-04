-- P1-02 E2 core-coverage content version: COO-01/02/03, CIR-01, TRI-01.
-- Independent version for safe QA/publication/rollback.

begin;
insert into private.exam_prep_content_versions(
  program_version_id,content_version,component_code,release_label,status,source_policy
)
select pv.id,'p1_e2_coordinate_circular_trig_v1','P1','P1 E2 Coordinate/Circular/Trigonometry for AW5-8','draft',
       'Original iClub content only; Cambridge 9709 official syllabus defines scope; Complete Pure Mathematics 1 provides mapping/teaching reference only; no Cambridge/coursebook question, diagram, answer or mark-scheme wording copied.'
from private.exam_prep_program_versions pv
where pv.program_key='math_as_p1_p5' and pv.version_key='p1_p5_canonical_v1_0'
on conflict(program_version_id,content_version) do nothing;

do $$ declare v_id bigint; begin
  select id into v_id from private.exam_prep_content_versions
  where content_version='p1_e2_coordinate_circular_trig_v1' and component_code='P1';
  if v_id is null then raise exception 'P1-02 E2 coord/circ/trig version missing'; end if;
  if (select status from private.exam_prep_content_versions where id=v_id)<>'draft' then
    raise exception 'P1-02 E2 coord/circ/trig must start draft';
  end if;
end $$;
commit;
