begin;

-- P2-44: browser/private-schema boundary closure.
-- The learner browser uses public RPCs only. No anon/authenticated role should
-- need direct table, sequence, function, or schema access inside private.
-- This migration is additive in behavior: it changes privileges and the
-- execution context of one existing read RPC; it does not rewrite learner data.

create or replace function public.get_exam_prep_exam_profile_v1()
returns table(
  user_id uuid,
  program_version_id bigint,
  exam_series text,
  target_grade text,
  total_student_hours_available numeric,
  mathematics_hours_budget numeric,
  active_week_no smallint,
  updated_at timestamptz
)
language sql
stable
security definer
set search_path=''
as $$
  select p.user_id,p.program_version_id,p.exam_series,p.target_grade,
         p.total_student_hours_available,p.mathematics_hours_budget,
         private.exam_prep_effective_active_week_v1(p.user_id),p.updated_at
  from private.exam_prep_exam_profiles p
  where p.user_id=auth.uid();
$$;
revoke execute on function public.get_exam_prep_exam_profile_v1() from public,anon;
grant execute on function public.get_exam_prep_exam_profile_v1() to authenticated,service_role;

-- These five SELECT grants were historical implementation grants. Current
-- learner reads already go through governed public RPCs, so direct browser
-- access is unnecessary and widens the attack surface.
revoke all on private.exam_prep_exam_profiles from anon,authenticated;
revoke all on private.exam_prep_feature_config from anon,authenticated;
revoke all on private.exam_prep_feature_entitlements from anon,authenticated;
revoke all on private.exam_prep_mentor_assignments from anon,authenticated;
revoke all on private.exam_prep_mentor_service_status from anon,authenticated;

-- All current learner-facing Exam Prep RPCs that touch private state are
-- SECURITY DEFINER. Remove the browser role's schema visibility as a final
-- boundary. Service code keeps its existing service_role access.
revoke all on schema private from anon,authenticated;
grant usage on schema private to service_role;

commit;
