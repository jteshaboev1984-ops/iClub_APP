-- P1-06 security hardening discovered by the expanded-beta current-schema gate.
-- Additive only: these five private governance/control tables already have no
-- anon/authenticated grants. Enabling RLS makes the private-table contract
-- consistent without changing learner academic state, evidence, or rollout.

begin;

alter table private.exam_prep_operational_stage_rules enable row level security;
alter table private.exam_prep_stage3_exit_rules enable row level security;
alter table private.exam_prep_stage3_key_skills enable row level security;
alter table private.exam_prep_stage4_release_controls enable row level security;
alter table private.exam_prep_stage5_release_controls enable row level security;

revoke all on private.exam_prep_operational_stage_rules from public,anon,authenticated;
revoke all on private.exam_prep_stage3_exit_rules from public,anon,authenticated;
revoke all on private.exam_prep_stage3_key_skills from public,anon,authenticated;
revoke all on private.exam_prep_stage4_release_controls from public,anon,authenticated;
revoke all on private.exam_prep_stage5_release_controls from public,anon,authenticated;

do $$
declare v_bad int;
begin
  select count(*) into v_bad
  from pg_tables
  where schemaname='private'
    and tablename in (
      'exam_prep_operational_stage_rules',
      'exam_prep_stage3_exit_rules',
      'exam_prep_stage3_key_skills',
      'exam_prep_stage4_release_controls',
      'exam_prep_stage5_release_controls'
    )
    and not rowsecurity;
  if v_bad<>0 then
    raise exception 'P1-06 stage-governance RLS hardening failed rows=%',v_bad;
  end if;

  select count(*) into v_bad
  from information_schema.role_table_grants
  where table_schema='private'
    and table_name in (
      'exam_prep_operational_stage_rules',
      'exam_prep_stage3_exit_rules',
      'exam_prep_stage3_key_skills',
      'exam_prep_stage4_release_controls',
      'exam_prep_stage5_release_controls'
    )
    and grantee in ('PUBLIC','anon','authenticated');
  if v_bad<>0 then
    raise exception 'P1-06 stage-governance learner grants survived rows=%',v_bad;
  end if;
end
$$;

commit;
