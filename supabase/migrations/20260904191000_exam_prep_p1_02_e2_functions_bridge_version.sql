-- P1-02 E2 bridge content version: P1-FUN-06/07/08.
-- Separate version so the bridge can be QA'd, published and rolled back independently.

begin;
insert into private.exam_prep_content_versions(
  program_version_id,content_version,component_code,release_label,status,source_policy
)
select pv.id,'p1_e2_functions_bridge_v1','P1','P1 Functions transformations bridge for AW5-8','draft',
       'Original iClub content only; Cambridge 9709 official syllabus defines scope; Complete Pure Mathematics 1 is mapping/teaching reference only; no Cambridge/coursebook question, diagram, answer or mark-scheme wording copied.'
from private.exam_prep_program_versions pv
where pv.program_key='math_as_p1_p5' and pv.version_key='p1_p5_canonical_v1_0'
on conflict(program_version_id,content_version) do nothing;

-- The version starts deliberately incomplete and must not make any AW5 skill ready yet.
do $$ declare v_id bigint; begin
  select id into v_id from private.exam_prep_content_versions
  where content_version='p1_e2_functions_bridge_v1' and component_code='P1';
  if v_id is null then raise exception 'P1-02 E2 bridge content version missing'; end if;
  if (select status from private.exam_prep_content_versions where id=v_id)<>'draft' then
    raise exception 'P1-02 E2 bridge must start draft';
  end if;
end $$;
commit;
