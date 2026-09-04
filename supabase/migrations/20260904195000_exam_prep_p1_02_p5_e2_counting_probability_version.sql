-- P1-02 E2 P5 content version: CNT-01/02/03/04, PRO-01/03.
-- Independent draft for safe QA/publication/rollback.

begin;
insert into private.exam_prep_content_versions(
  program_version_id,content_version,component_code,release_label,status,source_policy
)
select pv.id,'p5_e2_counting_probability_v1','P5','P5 E2 Counting + Probability for AW5-8','draft',
       'Original iClub content only; Cambridge 9709 official syllabus defines scope; Complete Probability & Statistics 1 provides mapping/teaching reference only; no Cambridge/coursebook question, diagram, answer or mark-scheme wording copied.'
from private.exam_prep_program_versions pv
where pv.program_key='math_as_p1_p5' and pv.version_key='p1_p5_canonical_v1_0'
on conflict(program_version_id,content_version) do nothing;

do $$ declare v_id bigint; begin
  select id into v_id from private.exam_prep_content_versions
  where content_version='p5_e2_counting_probability_v1' and component_code='P5';
  if v_id is null then raise exception 'P1-02 P5 E2 counting/probability version missing'; end if;
  if (select status from private.exam_prep_content_versions where id=v_id)<>'draft' then
    raise exception 'P1-02 P5 E2 counting/probability must start draft';
  end if;
end $$;
commit;
