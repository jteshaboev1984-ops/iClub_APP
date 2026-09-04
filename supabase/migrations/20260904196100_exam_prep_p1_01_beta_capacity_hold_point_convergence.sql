-- P1-01 convergence hardening for controlled-beta capacity semantics.
--
-- Historical P1-01 hold-point migration redefines the cohort approval RPC after
-- P0-16. Keep its Mentor Care hold-point behavior, but preserve the newer P0-16
-- semantics where planned_size is CAPACITY (up to 12), not an exact fill target.
-- This additive migration is required so fresh P0 -> P1 builds converge with
-- production after the capacity migration is applied.

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

  if v_total<3 or v_total>v_c.planned_size or v_total>12 then
    raise exception 'exam_prep_beta_member_count_outside_capacity: got %, capacity %',v_total,v_c.planned_size;
  end if;

  -- Keep stratified representation. A service may remain operationally dark,
  -- but the governed controlled-beta cohort must represent all three modes.
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

  -- Mentor Care staffing remains a hold point at the exact Mentor Care wave.
  -- Core/AI candidates must not already leak into an active Mentor relationship.
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

  -- Approval is governance only. No entitlement or global feature switch here.
  update private.exam_prep_beta_members
  set member_status='approved',updated_at=now(),updated_by=auth.uid()
  where cohort_id=v_c.id and member_status='candidate';

  update private.exam_prep_beta_cohorts
  set cohort_status='approved',approved_at=now(),updated_at=now(),updated_by=auth.uid()
  where id=v_c.id;

  return jsonb_build_object(
    'cohort_key',p_cohort_key,
    'status','approved',
    'approved_size',v_total,
    'capacity',v_c.planned_size,
    'remaining_capacity',v_c.planned_size-v_total,
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

-- Convergence invariant: changing approval semantics must never activate beta.
do $$
declare v_cfg private.exam_prep_feature_config%rowtype;
begin
  select * into v_cfg from private.exam_prep_feature_config where id=1;
  if v_cfg.rollout_state<>'off'
     or v_cfg.core_enabled
     or v_cfg.ai_enabled
     or v_cfg.mentor_enabled
     or not v_cfg.kill_switch then
    raise exception 'P1-01 beta capacity convergence requires fail-closed feature state';
  end if;
end
$$;

commit;
