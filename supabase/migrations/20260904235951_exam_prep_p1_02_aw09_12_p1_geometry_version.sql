-- P1-02 AW9-12 P1 geometry/measure content version. Draft/private only.
begin;
insert into private.exam_prep_content_versions(program_version_id,content_version,component_code,release_label,status,source_policy)
select pv.id,'p1_aw09_12_geometry_v1','P1','P1 Coordinate Geometry + Circular Measure COO-04/CIR-02 AW9-12','draft',
       'Original iClub content only; Cambridge 9709 official syllabus defines scope; Complete Pure Mathematics 1 is used only for teaching/source mapping; no Cambridge/coursebook question, diagram, answer or mark-scheme wording copied.'
from private.exam_prep_program_versions pv
where pv.program_key='math_as_p1_p5' and pv.version_key='p1_p5_canonical_v1_0'
on conflict(program_version_id,content_version) do nothing;
do $$ declare v_cfg private.exam_prep_feature_config%rowtype; begin select * into v_cfg from private.exam_prep_feature_config where id=1; if v_cfg.rollout_state<>'off' or v_cfg.core_enabled or v_cfg.ai_enabled or v_cfg.mentor_enabled or not v_cfg.kill_switch then raise exception 'P1-02 AW9-12 P1 geometry version must remain fail-closed'; end if; end $$;
commit;