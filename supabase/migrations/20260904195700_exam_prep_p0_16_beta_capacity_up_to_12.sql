-- P0-16 controlled-beta capacity hardening: "12 learners" becomes "up to 12".
--
-- Semantics after this migration:
-- * planned_size is the cohort capacity, not a requirement to fill every seat;
-- * capacity is 3..12 because the governed cohort still requires representation
--   of Core, AI Assist and Mentor Care (at least one candidate in each mode);
-- * approval accepts any 3..planned_size candidate roster;
-- * adding a new candidate beyond planned_size is rejected immediately;
-- * approval remains allowlist/governance only: no entitlement or feature flag is enabled.

begin;

alter table private.exam_prep_beta_cohorts
  drop constraint if exists exam_prep_beta_cohorts_planned_size_check;

alter table private.exam_prep_beta_cohorts
  add constraint exam_prep_beta_cohorts_planned_size_check
  check (planned_size between 3 and 12);

create or replace function public.stage_exam_prep_controlled_beta_v1(
  p_cohort_key text,
  p_planned_size smallint,
  p_notes text default null
)
returns jsonb
language plpgsql
security definer
set search_path=''
as $$
declare
  v_id bigint;
  v_cfg private.exam_prep_feature_config%rowtype;
begin
  if p_cohort_key is null or p_cohort_key !~ '^[a-z0-9][a-z0-9_-]{2,79}$' then
    raise exception 'exam_prep_beta_bad_cohort_key';
  end if;
  if p_planned_size not between 3 and 12 then
    raise exception 'exam_prep_beta_capacity_must_be_3_to_12';
  end if;

  select * into v_cfg from private.exam_prep_feature_config where id=1;
  if v_cfg.rollout_state<>'off' or v_cfg.core_enabled or v_cfg.ai_enabled or v_cfg.mentor_enabled or not v_cfg.kill_switch then
    raise exception 'exam_prep_beta_stage_requires_fail_closed_config';
  end if;

  insert into private.exam_prep_beta_cohorts(
    cohort_key,planned_size,notes,created_by,updated_by
  ) values (
    p_cohort_key,p_planned_size,p_notes,auth.uid(),auth.uid()
  ) returning id into v_id;

  return jsonb_build_object(
    'cohort_id',v_id,
    'cohort_key',p_cohort_key,
    'status','draft',
    'capacity',p_planned_size,
    'feature_state','off'
  );
end;
$$;
revoke all on function public.stage_exam_prep_controlled_beta_v1(text,smallint,text) from public,anon,authenticated;
grant execute on function public.stage_exam_prep_controlled_beta_v1(text,smallint,text) to service_role;

create or replace function public.set_exam_prep_beta_member_v1(
  p_cohort_key text,
  p_user_id uuid,
  p_service_mode text,
  p_activation_wave smallint default 1
)
returns jsonb
language plpgsql
security definer
set search_path=''
as $$
declare
  v_c private.exam_prep_beta_cohorts%rowtype;
  v_id bigint;
  v_existing bigint;
  v_candidate_count int;
begin
  if p_service_mode not in ('core','ai_assist','mentor_care') then
    raise exception 'exam_prep_beta_bad_service_mode';
  end if;
  if p_activation_wave not between 1 and 20 then
    raise exception 'exam_prep_beta_bad_activation_wave';
  end if;
  if not exists(select 1 from public.users where id=p_user_id) then
    raise exception 'exam_prep_beta_user_not_found' using errcode='P0002';
  end if;

  select * into v_c
  from private.exam_prep_beta_cohorts
  where cohort_key=p_cohort_key
  for update;

  if v_c.id is null then
    raise exception 'exam_prep_beta_cohort_not_found' using errcode='P0002';
  end if;
  if v_c.cohort_status<>'draft' then
    raise exception 'exam_prep_beta_members_locked_after_approval';
  end if;

  select id into v_existing
  from private.exam_prep_beta_members
  where cohort_id=v_c.id and user_id=p_user_id;

  if v_existing is null then
    select count(*) into v_candidate_count
    from private.exam_prep_beta_members
    where cohort_id=v_c.id and member_status='candidate';

    if v_candidate_count>=v_c.planned_size then
      raise exception 'exam_prep_beta_capacity_reached: capacity %, candidates %',v_c.planned_size,v_candidate_count;
    end if;
  end if;

  insert into private.exam_prep_beta_members(
    cohort_id,user_id,service_mode,activation_wave,member_status,created_by,updated_by
  ) values (
    v_c.id,p_user_id,p_service_mode,p_activation_wave,'candidate',auth.uid(),auth.uid()
  )
  on conflict(cohort_id,user_id) do update set
    service_mode=excluded.service_mode,
    activation_wave=excluded.activation_wave,
    member_status='candidate',
    updated_at=now(),
    updated_by=auth.uid()
  returning id into v_id;

  return jsonb_build_object(
    'member_id',v_id,
    'cohort_key',p_cohort_key,
    'user_id',p_user_id,
    'service_mode',p_service_mode,
    'activation_wave',p_activation_wave,
    'status','candidate',
    'capacity',v_c.planned_size
  );
end;
$$;
revoke all on function public.set_exam_prep_beta_member_v1(text,uuid,text,smallint) from public,anon,authenticated;
grant execute on function public.set_exam_prep_beta_member_v1(text,uuid,text,smallint) to service_role;

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

  -- Keep the P0-16 stratified controlled-beta representation requirement.
  -- Optional services may remain held dark operationally, but each mode is represented.
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

  -- Mentor Care staffing remains a hold point at activation, not cohort approval.
  -- Core/AI candidates still must not leak into an active Mentor Care relationship.
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
    'service_mix',jsonb_build_object('core',v_core,'ai_assist',v_ai,'mentor_care',v_mentor),
    'feature_state','off',
    'mentor_readiness','deferred_to_activation_wave'
  );
end;
$$;
revoke all on function public.approve_exam_prep_controlled_beta_v1(text) from public,anon,authenticated;
grant execute on function public.approve_exam_prep_controlled_beta_v1(text) to service_role;

-- Deployment invariant: changing cohort capacity must not activate anything.
do $$
declare v_cfg private.exam_prep_feature_config%rowtype;
begin
  select * into v_cfg from private.exam_prep_feature_config where id=1;
  if v_cfg.rollout_state<>'off'
     or v_cfg.core_enabled
     or v_cfg.ai_enabled
     or v_cfg.mentor_enabled
     or not v_cfg.kill_switch then
    raise exception 'P0-16 beta capacity hardening requires fail-closed feature state';
  end if;
end
$$;

commit;
