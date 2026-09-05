-- P1-03 post-DDL performance hardening.
-- Cover the canonical syllabus FK on the Stage-3 key-skill registry.
-- No stage/feature/runtime semantics change.
begin;

create index if not exists exam_prep_stage3_key_skills_program_skill_idx
  on private.exam_prep_stage3_key_skills(program_version_id,skill_code);

do $$
begin
  if not exists (
    select 1
    from pg_indexes
    where schemaname='private'
      and tablename='exam_prep_stage3_key_skills'
      and indexname='exam_prep_stage3_key_skills_program_skill_idx'
  ) then
    raise exception 'P1-03 Stage-3 key-skill FK covering index missing';
  end if;

  if not exists (
    select 1 from private.exam_prep_operational_stage_rules
    where status='active' and max_automatic_stage=3
  ) then
    raise exception 'P1-03 Stage-3 key-skill index hardening requires Stage 4 to remain locked';
  end if;

  if exists (
    select 1 from private.exam_prep_stage3_key_skills
    where rule_version='stage3_exit_v1_2026_09_05'
  ) then
    raise exception 'P1-03 Stage-3 key-skill registry unexpectedly populated';
  end if;
end $$;

commit;