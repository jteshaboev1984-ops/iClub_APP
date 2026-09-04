-- P1-02 opening runway content versions. Draft/private only.
-- Original iClub-authored content will be attached in later P1-02 migrations; no legacy question is modified.

begin;

insert into private.exam_prep_content_versions(program_version_id,content_version,component_code,release_label,status,source_policy)
select pv.id,'p1_foundations_runway_v1','P1','P1 Quadratics + Functions AW1-4 governed runway','draft',
       'Original iClub content only; Cambridge 9709 official syllabus defines scope; Complete Pure Mathematics 1 is used only for teaching/source mapping; no Cambridge/coursebook question, diagram, answer or mark-scheme wording copied.'
from private.exam_prep_program_versions pv
where pv.program_key='math_as_p1_p5' and pv.version_key='p1_p5_canonical_v1_0'
on conflict(program_version_id,content_version) do nothing;

insert into private.exam_prep_content_versions(program_version_id,content_version,component_code,release_label,status,source_policy)
select pv.id,'p5_dat02_runway_v1','P5','P5 Stem-and-leaf AW1-4 runway extension','draft',
       'Original iClub content only; Cambridge 9709 official syllabus defines scope; Complete Probability & Statistics 1 is used only for teaching/source mapping; no Cambridge/coursebook question, diagram, answer or mark-scheme wording copied.'
from private.exam_prep_program_versions pv
where pv.program_key='math_as_p1_p5' and pv.version_key='p1_p5_canonical_v1_0'
on conflict(program_version_id,content_version) do nothing;

-- Still no feature or learner activation.
do $$ begin
  if exists(select 1 from private.exam_prep_feature_config where program_key='math_as_p1_p5' and (rollout_state<>'off' or core_enabled or ai_enabled or mentor_enabled or not kill_switch)) then
    raise exception 'P1-02 content version creation must remain fail-closed';
  end if;
end $$;

commit;
