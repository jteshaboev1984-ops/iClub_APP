-- P1-02 AW9-12 P1 Quadratics content version. Draft/private only.
-- No legacy question is modified and no learner access is enabled.

begin;

insert into private.exam_prep_content_versions(
  program_version_id,content_version,component_code,release_label,status,source_policy
)
select pv.id,'p1_aw09_12_quadratics_v1','P1','P1 Quadratics QUA-04/05/06 AW9-12 governed runway','draft',
       'Original iClub content only; Cambridge 9709 official syllabus defines scope; Complete Pure Mathematics 1 is used only for teaching/source mapping; no Cambridge/coursebook question, diagram, answer or mark-scheme wording copied.'
from private.exam_prep_program_versions pv
where pv.program_key='math_as_p1_p5' and pv.version_key='p1_p5_canonical_v1_0'
on conflict(program_version_id,content_version) do nothing;

-- This is content scaffolding only. It must remain fail-closed.
do $$
declare v_cfg private.exam_prep_feature_config%rowtype; v_active int; begin
  select * into v_cfg from private.exam_prep_feature_config where id=1;
  if v_cfg.rollout_state<>'off' or v_cfg.core_enabled or v_cfg.ai_enabled or v_cfg.mentor_enabled or not v_cfg.kill_switch then
    raise exception 'P1-02 AW9-12 quadratics version creation must remain fail-closed';
  end if;
  select count(*) into v_active from private.exam_prep_feature_entitlements where entitlement_status='active';
  if v_active<>0 then raise exception 'P1-02 AW9-12 quadratics version found active entitlements=%',v_active; end if;
end $$;

commit;