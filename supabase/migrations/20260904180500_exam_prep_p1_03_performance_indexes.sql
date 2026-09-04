-- P1-03 post-DDL performance hardening.
-- Covers the two P1-03 foreign keys identified by the Supabase database linter.
-- Additive only; no row mutation and no feature activation.

begin;

create index if not exists exam_prep_timed_attempt_assessment_idx
  on private.exam_prep_timed_attempt_results(assessment_id);

create index if not exists exam_prep_timed_self_marks_user_idx
  on private.exam_prep_timed_written_self_marks(user_id, created_at desc);

-- This migration is safe to apply only while P1-03 remains dormant.
do $$
begin
  if exists(
    select 1
    from private.exam_prep_feature_config
    where program_key='math_as_p1_p5'
      and (
        rollout_state<>'off'
        or core_enabled
        or ai_enabled
        or mentor_enabled
        or not kill_switch
      )
  ) then
    raise exception 'P1-03 performance hardening requires fail-closed feature state';
  end if;

  if not exists(
    select 1 from pg_indexes
    where schemaname='private'
      and tablename='exam_prep_timed_attempt_results'
      and indexname='exam_prep_timed_attempt_assessment_idx'
  ) then
    raise exception 'P1-03 assessment FK index missing after creation';
  end if;

  if not exists(
    select 1 from pg_indexes
    where schemaname='private'
      and tablename='exam_prep_timed_written_self_marks'
      and indexname='exam_prep_timed_self_marks_user_idx'
  ) then
    raise exception 'P1-03 self-mark user FK index missing after creation';
  end if;
end
$$;

commit;
