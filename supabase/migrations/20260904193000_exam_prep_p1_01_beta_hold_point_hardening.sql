-- P1-01 controlled-beta hold-point hardening.
--
-- Beta Release Plan v1.1 permits GO WITH HOLD POINT when Mentor Care capacity is red:
-- Core can start while Mentor Care remains waiting/off. Mentor readiness is already enforced
-- again at the exact Mentor Care activation wave by
-- private.activate_exam_prep_controlled_beta_wave_p0_16_internal_v1().
--
-- This migration therefore removes premature cohort-approval dependency on active mentor
-- assignments while preserving:
--   * 12-20 total learner floor;
--   * representation of Core / AI Assist / Mentor Care in the controlled-beta cohort;
--   * fail-closed global feature config at approval;
--   * non-Mentor assignment leakage guard;
--   * service_role-only execution;
--   * zero entitlement creation during approval.

begin;

create or replace function public.approve_exam_prep_controlled_beta_v1(p_cohort_key text)
returns jsonb
language plpgsql
security definer
set search_path=''
as $$
declare
  v_c private.exam_prep_beta_cohorts%rowtype;
  v_total int;
  v_core int;
  v_ai int;
  v_mentor int;
  v_bad int;
  v_cfg private.exam_prep_feature_config%rowtype;
begin
  select * into v_c
  from private.exam_prep_beta_cohorts
  where cohort_key=p_cohort_key
  for update;

  if v_c.id is null then
    raise exception 'exam_prep_beta_cohort_not_found' using errcode='P0002';
  end if;
  if v_c.cohort_status<>'draft' then
    raise exception 'exam_prep_beta_cohort_not_draft';
  end if;

  select count(*),
         count(*) filter(where service_mode='core'),
         count(*) filter(where service_mode='ai_assist'),
         count(*) filter(where service_mode='mentor_care')
    into v_total,v_core,v_ai,v_mentor
  from private.exam_prep_beta_members
  where cohort_id=v_c.id and member_status='candidate';

  if v_total<>v_c.planned_size or v_total not between 12 and 20 then
    raise exception 'exam_prep_beta_member_count_mismatch: got %, planned %',v_total,v_c.planned_size;
  end if;

  -- P0-16 still requires stratified controlled-beta representation.
  -- A mode may be held dark operationally, but it must remain represented in the cohort.
  if v_core=0 or v_ai=0 or v_mentor=0 then
    raise exception 'exam_prep_beta_requires_mixed_core_ai_mentor_modes';
  end if;

  select * into v_cfg from private.exam_prep_feature_config where id=1;
  if v_cfg.rollout_state<>'off'
     or v_cfg.core_enabled
     or v_cfg.ai_enabled
     or v_cfg.mentor_enabled
     or not v_cfg.kill_switch then
    raise exception 'exam_prep_beta_approval_requires_fail_closed_config';
  end if;

  -- Important: do NOT require Mentor Care staffing at cohort approval time.
  -- Mentor candidates remain approved/waiting without an entitlement. The activation RPC
  -- enforces assigned_active mentor service + valid active mentor assignment exactly when
  -- a Mentor Care wave is requested. This is the GO WITH HOLD POINT behavior.

  -- Core/AI candidates must not already be attached to an active Mentor Care relationship.
  select count(*) into v_bad
  from private.exam_prep_beta_members m
  where m.cohort_id=v_c.id
    and m.member_status='candidate'
    and m.service_mode<>'mentor_care'
    and (
      exists(
        select 1
        from private.exam_prep_mentor_service_status s
        where s.learner_user_id=m.user_id
          and s.service_status='assigned_active'
      )
      or exists(
        select 1
        from private.exam_prep_mentor_assignments a
        where a.learner_user_id=m.user_id
          and a.assignment_status='active'
          and a.valid_from<=now()
          and (a.valid_until is null or a.valid_until>now())
      )
    );
  if v_bad<>0 then
    raise exception 'exam_prep_beta_nonmentor_assignment_leakage=%',v_bad;
  end if;

  -- Approval is allowlist/governance only. No learner entitlement is created here.
  update private.exam_prep_beta_members
  set member_status='approved',
      updated_at=now(),
      updated_by=auth.uid()
  where cohort_id=v_c.id and member_status='candidate';

  update private.exam_prep_beta_cohorts
  set cohort_status='approved',
      approved_at=now(),
      updated_at=now(),
      updated_by=auth.uid()
  where id=v_c.id;

  return jsonb_build_object(
    'cohort_key',p_cohort_key,
    'status','approved',
    'planned_size',v_total,
    'service_mix',jsonb_build_object(
      'core',v_core,
      'ai_assist',v_ai,
      'mentor_care',v_mentor
    ),
    'feature_state','off',
    'mentor_readiness','deferred_to_activation_wave'
  );
end;
$$;

revoke all on function public.approve_exam_prep_controlled_beta_v1(text) from public,anon,authenticated;
grant execute on function public.approve_exam_prep_controlled_beta_v1(text) to service_role;

-- Deployment invariant: this hardening itself must not activate anything.
do $$
declare v_cfg private.exam_prep_feature_config%rowtype;
begin
  select * into v_cfg from private.exam_prep_feature_config where id=1;
  if v_cfg.rollout_state<>'off'
     or v_cfg.core_enabled
     or v_cfg.ai_enabled
     or v_cfg.mentor_enabled
     or not v_cfg.kill_switch then
    raise exception 'P1-01 hold-point hardening requires fail-closed feature state';
  end if;
end
$$;

commit;
