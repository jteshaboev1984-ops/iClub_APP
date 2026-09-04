-- P0-15: capability/mentor-assignment authority hardening.
--
-- P0-05 exposed mentor_assignment_active / mentor_authority from assignment rows
-- alone. P0-13 later made the operational Mentor Care path stricter: an active
-- assignment is valid only when its mentor also holds an active governed staff
-- role. Keep the public capability contract aligned with that authoritative
-- P0-13 rule before any learner beta is enabled.
--
-- This migration is additive in deployment history: it does not rewrite prior
-- migrations or legacy data, and it does not enable Exam Prep.

begin;

create or replace function public.get_exam_prep_capabilities_v1()
returns table (
  program_key text,
  rollout_state text,
  core_access boolean,
  ai_assist boolean,
  mentor_care_entitled boolean,
  mentor_assignment_active boolean,
  mentor_authority boolean,
  kill_switch boolean
)
language sql
stable
security definer
set search_path = ''
as $$
  with caller as (
    select auth.uid() as user_id
  ), cfg as (
    select c.program_key, c.rollout_state, c.core_enabled, c.ai_enabled, c.mentor_enabled, c.kill_switch
    from private.exam_prep_feature_config c
    where c.id = 1
  ), ent as (
    select e.user_id, e.core_access, e.ai_assist, e.mentor_care_entitled
    from private.exam_prep_feature_entitlements e, caller u
    where e.user_id = u.user_id
      and e.entitlement_status = 'active'
      and (e.valid_from is null or e.valid_from <= now())
      and (e.valid_until is null or e.valid_until > now())
  ), svc as (
    select s.learner_user_id, s.service_status
    from private.exam_prep_mentor_service_status s, caller u
    where s.learner_user_id = u.user_id
  ), governed_assignment as (
    select
      u.user_id,
      (
        exists(select 1 from private.exam_prep_active_mentor_assignment_v1(u.user_id,'P1'))
        or exists(select 1 from private.exam_prep_active_mentor_assignment_v1(u.user_id,'P5'))
      ) as has_active_assignment
    from caller u
  ), effective as (
    select
      caller.user_id,
      cfg.program_key,
      cfg.rollout_state,
      cfg.core_enabled,
      cfg.ai_enabled,
      cfg.mentor_enabled,
      cfg.kill_switch,
      coalesce(ent.core_access,false) as ent_core,
      coalesce(ent.ai_assist,false) as ent_ai,
      coalesce(ent.mentor_care_entitled,false) as ent_mentor,
      coalesce(svc.service_status='assigned_active',false) as service_assigned_active,
      coalesce(governed_assignment.has_active_assignment,false) as has_governed_assignment
    from caller
    left join cfg on true
    left join ent on ent.user_id=caller.user_id
    left join svc on svc.learner_user_id=caller.user_id
    left join governed_assignment on governed_assignment.user_id=caller.user_id
  )
  select
    coalesce(e.program_key,'math_as_p1_p5'::text),
    coalesce(e.rollout_state,'off'::text),
    coalesce(e.user_id is not null and not e.kill_switch and e.core_enabled and e.rollout_state<>'off' and e.ent_core,false),
    coalesce(e.user_id is not null and not e.kill_switch and e.core_enabled and e.ai_enabled and e.rollout_state<>'off' and e.ent_core and e.ent_ai,false),
    coalesce(e.user_id is not null and not e.kill_switch and e.core_enabled and e.mentor_enabled and e.rollout_state<>'off' and e.ent_core and e.ent_mentor,false),
    coalesce(e.user_id is not null and not e.kill_switch and e.core_enabled and e.mentor_enabled and e.rollout_state<>'off' and e.ent_core and e.ent_mentor and e.service_assigned_active and e.has_governed_assignment,false),
    coalesce(e.user_id is not null and not e.kill_switch and e.core_enabled and e.mentor_enabled and e.rollout_state<>'off' and e.ent_core and e.ent_mentor and e.service_assigned_active and e.has_governed_assignment,false),
    coalesce(e.kill_switch,true)
  from effective e;
$$;

revoke all on function public.get_exam_prep_capabilities_v1() from public,anon;
grant execute on function public.get_exam_prep_capabilities_v1() to authenticated,service_role;

-- Migration-time contract assertions. Behavioral staff-role scenarios are
-- exercised by the isolated P0-15 15-profile matrix.
do $$
declare
  v_oid oid;
  v_bad int;
begin
  select p.oid into v_oid
  from pg_proc p
  join pg_namespace n on n.oid=p.pronamespace
  where n.nspname='public' and p.proname='get_exam_prep_capabilities_v1'
    and pg_get_function_identity_arguments(p.oid)='';

  if v_oid is null then
    raise exception 'P0-15 capability hardening: function not found';
  end if;

  if not (select p.prosecdef from pg_proc p where p.oid=v_oid) then
    raise exception 'P0-15 capability hardening: capability RPC must be SECURITY DEFINER to evaluate private governed staff authority without exposing staff tables';
  end if;

  if not exists(
    select 1 from pg_proc p
    where p.oid=v_oid and 'search_path=""'=any(coalesce(p.proconfig,array[]::text[]))
  ) then
    raise exception 'P0-15 capability hardening: fixed empty search_path required';
  end if;

  if has_function_privilege('anon',v_oid,'EXECUTE') then
    raise exception 'P0-15 capability hardening: anon execute must remain denied';
  end if;

  select count(*) into v_bad
  from private.exam_prep_feature_config
  where id=1 and (rollout_state<>'off' or core_enabled or ai_enabled or mentor_enabled or not kill_switch);
  if v_bad<>0 then
    raise exception 'P0-15 capability hardening: deployment must remain fail-closed';
  end if;
end;
$$;

commit;
