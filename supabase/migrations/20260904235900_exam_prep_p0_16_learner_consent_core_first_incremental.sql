-- P0-16 controlled-beta convergence: Core-first start + incremental enrollment up to capacity.
--
-- Operational law after this overlay:
-- * planned_size remains CAPACITY (3..12), not an exact fill target;
-- * the initial governed cohort may start Core-only with at least 3 consented learners;
-- * AI Assist and Mentor Care representation is deferred to the waves that actually test those capabilities;
-- * once a canary is live, new learners may be added as future-wave candidates up to remaining capacity;
-- * every newly added learner still needs explicit consent before approval;
-- * AI and Mentor activation gates remain unchanged and fail-closed;
-- * no learner is activated by this migration.

begin;

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
  v_existing private.exam_prep_beta_members%rowtype;
  v_id bigint;
  v_occupied int;
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
  if v_c.cohort_status not in ('draft','approved','canary','active') then
    raise exception 'exam_prep_beta_members_locked_for_status=%',v_c.cohort_status;
  end if;
  if v_c.current_wave>0 and p_activation_wave<=v_c.current_wave then
    raise exception 'exam_prep_beta_new_member_requires_future_wave: current %, requested %',v_c.current_wave,p_activation_wave;
  end if;

  select * into v_existing
  from private.exam_prep_beta_members
  where cohort_id=v_c.id and user_id=p_user_id;

  if v_existing.id is not null and v_existing.member_status in ('approved','active','paused') then
    raise exception 'exam_prep_beta_existing_member_locked_status=%',v_existing.member_status;
  end if;

  select count(*) into v_occupied
  from private.exam_prep_beta_members m
  where m.cohort_id=v_c.id
    and m.member_status<>'removed'
    and (v_existing.id is null or m.id<>v_existing.id);

  if v_occupied>=v_c.planned_size then
    raise exception 'exam_prep_beta_capacity_reached: capacity %, occupied %',v_c.planned_size,v_occupied;
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
    activated_at=null,
    paused_at=null,
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
    'capacity',v_c.planned_size,
    'current_wave',v_c.current_wave
  );
end;
$$;
revoke all on function public.set_exam_prep_beta_member_v1(text,uuid,text,smallint)
from public,anon,authenticated;
grant execute on function public.set_exam_prep_beta_member_v1(text,uuid,text,smallint)
to service_role;

create or replace function public.approve_exam_prep_controlled_beta_v1(p_cohort_key text)
returns jsonb
language plpgsql
security definer
set search_path=''
as $$
declare
  v_c private.exam_prep_beta_cohorts%rowtype;
  v_candidates int;
  v_total int;
  v_core int;
  v_ai int;
  v_mentor int;
  v_missing_consent int;
  v_bad_wave int;
  v_bad_assignment int;
  v_cfg private.exam_prep_feature_config%rowtype;
  v_initial boolean;
begin
  select * into v_c
  from private.exam_prep_beta_cohorts
  where cohort_key=p_cohort_key
  for update;

  if v_c.id is null then
    raise exception 'exam_prep_beta_cohort_not_found' using errcode='P0002';
  end if;
  if v_c.cohort_status not in ('draft','approved','canary','active') then
    raise exception 'exam_prep_beta_cohort_not_approvable_status=%',v_c.cohort_status;
  end if;

  v_initial:=(v_c.cohort_status='draft');

  select count(*),
         count(*) filter(where service_mode='core'),
         count(*) filter(where service_mode='ai_assist'),
         count(*) filter(where service_mode='mentor_care')
    into v_candidates,v_core,v_ai,v_mentor
  from private.exam_prep_beta_members
  where cohort_id=v_c.id and member_status='candidate';

  if v_candidates=0 then
    raise exception 'exam_prep_beta_no_candidates_to_approve';
  end if;

  select count(*) into v_total
  from private.exam_prep_beta_members
  where cohort_id=v_c.id and member_status<>'removed';

  if v_total>v_c.planned_size or v_total>12 then
    raise exception 'exam_prep_beta_member_count_outside_capacity: got %, capacity %',v_total,v_c.planned_size;
  end if;

  if v_initial then
    if v_total<3 then
      raise exception 'exam_prep_beta_initial_core_first_requires_at_least_3: got %',v_total;
    end if;
    if not exists(
      select 1 from private.exam_prep_beta_members
      where cohort_id=v_c.id and member_status<>'removed' and service_mode='core'
    ) then
      raise exception 'exam_prep_beta_initial_cohort_requires_core';
    end if;

    select * into v_cfg from private.exam_prep_feature_config where id=1;
    if v_cfg.rollout_state<>'off'
       or v_cfg.core_enabled
       or v_cfg.ai_enabled
       or v_cfg.mentor_enabled
       or not v_cfg.kill_switch then
      raise exception 'exam_prep_beta_initial_approval_requires_fail_closed_config';
    end if;
  else
    select count(*) into v_bad_wave
    from private.exam_prep_beta_members
    where cohort_id=v_c.id
      and member_status='candidate'
      and activation_wave<=v_c.current_wave;
    if v_bad_wave<>0 then
      raise exception 'exam_prep_beta_incremental_candidates_must_be_future_wave=%',v_bad_wave;
    end if;
  end if;

  select count(*) into v_missing_consent
  from private.exam_prep_beta_members m
  where m.cohort_id=v_c.id
    and m.member_status='candidate'
    and not private.exam_prep_beta_consent_granted_v1(m.cohort_id,m.user_id);
  if v_missing_consent<>0 then
    raise exception 'exam_prep_beta_consent_required_for_candidates=%',v_missing_consent;
  end if;

  -- Core/AI candidates must not leak into an active Mentor relationship.
  select count(*) into v_bad_assignment
  from private.exam_prep_beta_members m
  where m.cohort_id=v_c.id
    and m.member_status='candidate'
    and m.service_mode<>'mentor_care'
    and (
      exists(
        select 1 from private.exam_prep_mentor_service_status s
        where s.learner_user_id=m.user_id
          and s.service_status='assigned_active'
      )
      or exists(
        select 1 from private.exam_prep_mentor_assignments a
        where a.learner_user_id=m.user_id
          and a.assignment_status='active'
          and a.valid_from<=now()
          and (a.valid_until is null or a.valid_until>now())
      )
    );
  if v_bad_assignment<>0 then
    raise exception 'exam_prep_beta_nonmentor_assignment_leakage=%',v_bad_assignment;
  end if;

  update private.exam_prep_beta_members
  set member_status='approved',updated_at=now(),updated_by=auth.uid()
  where cohort_id=v_c.id and member_status='candidate';

  if v_initial then
    update private.exam_prep_beta_cohorts
    set cohort_status='approved',approved_at=now(),updated_at=now(),updated_by=auth.uid()
    where id=v_c.id;
  end if;

  return jsonb_build_object(
    'cohort_key',p_cohort_key,
    'status',case when v_initial then 'approved' else v_c.cohort_status end,
    'approval_mode',case when v_initial then 'initial_core_first' else 'incremental' end,
    'approved_now',v_candidates,
    'occupied_size',v_total,
    'capacity',v_c.planned_size,
    'remaining_capacity',v_c.planned_size-v_total,
    'candidate_service_mix',jsonb_build_object('core',v_core,'ai_assist',v_ai,'mentor_care',v_mentor),
    'feature_state','unchanged',
    'ai_activation_gate','unchanged',
    'mentor_activation_gate','unchanged'
  );
end;
$$;
revoke all on function public.approve_exam_prep_controlled_beta_v1(text)
from public,anon,authenticated;
grant execute on function public.approve_exam_prep_controlled_beta_v1(text)
to service_role;

create or replace function public.revoke_exam_prep_beta_consent_v1(
  p_cohort_key text,
  p_user_id uuid,
  p_evidence_ref text
)
returns jsonb
language plpgsql
security definer
set search_path=''
as $$
declare
  v_c private.exam_prep_beta_cohorts%rowtype;
  v_m private.exam_prep_beta_members%rowtype;
  v_pause jsonb;
begin
  if p_evidence_ref is null or char_length(trim(p_evidence_ref)) not between 5 and 500 then
    raise exception 'exam_prep_beta_revocation_evidence_required';
  end if;

  select * into v_c
  from private.exam_prep_beta_cohorts
  where cohort_key=p_cohort_key
  for update;
  if v_c.id is null then
    raise exception 'exam_prep_beta_cohort_not_found' using errcode='P0002';
  end if;

  select * into v_m
  from private.exam_prep_beta_members
  where cohort_id=v_c.id and user_id=p_user_id
  for update;
  if v_m.id is null then
    raise exception 'exam_prep_beta_member_not_found' using errcode='P0002';
  end if;

  if not exists(
    select 1 from private.exam_prep_beta_consents c
    where c.cohort_id=v_c.id and c.user_id=p_user_id and c.consent_status='granted'
  ) then
    raise exception 'exam_prep_beta_consent_not_granted';
  end if;

  update private.exam_prep_beta_consents
  set consent_status='revoked',revoked_at=now(),revocation_evidence_ref=trim(p_evidence_ref),
      updated_at=now(),updated_by=auth.uid()
  where cohort_id=v_c.id and user_id=p_user_id;

  if v_m.member_status='active' then
    -- Revocation by a live learner remains a global fail-closed event.
    v_pause:=public.pause_exam_prep_controlled_beta_v1(
      p_cohort_key,
      'active learner consent revoked; controlled beta paused fail-closed'
    );
  elsif v_c.cohort_status='approved' and v_c.current_wave=0 then
    -- Before the first live wave, reopen the roster exactly as before.
    update private.exam_prep_feature_config
    set rollout_state='off',core_enabled=false,ai_enabled=false,mentor_enabled=false,
        kill_switch=true,updated_at=now(),updated_by=auth.uid()
    where id=1;

    update private.exam_prep_beta_members
    set member_status='candidate',activated_at=null,paused_at=null,
        updated_at=now(),updated_by=auth.uid()
    where cohort_id=v_c.id and member_status='approved';

    update private.exam_prep_beta_cohorts
    set cohort_status='draft',approved_at=null,updated_at=now(),updated_by=auth.uid()
    where id=v_c.id;
  elsif v_c.cohort_status in ('canary','active') then
    -- A future-wave learner may leave without interrupting already-live Core users.
    update private.exam_prep_beta_members
    set member_status='removed',paused_at=null,updated_at=now(),updated_by=auth.uid()
    where id=v_m.id and member_status in ('candidate','approved');
  elsif v_c.cohort_status='draft' then
    update private.exam_prep_beta_members
    set member_status='removed',updated_at=now(),updated_by=auth.uid()
    where id=v_m.id and member_status='candidate';
  end if;

  return jsonb_build_object(
    'cohort_key',p_cohort_key,
    'user_id',p_user_id,
    'consent_status','revoked',
    'member_status',(select member_status from private.exam_prep_beta_members where id=v_m.id),
    'cohort_status',(select cohort_status from private.exam_prep_beta_cohorts where id=v_c.id),
    'feature_state',(select rollout_state from private.exam_prep_feature_config where id=1),
    'kill_switch',(select kill_switch from private.exam_prep_feature_config where id=1),
    'pause_result',v_pause
  );
end;
$$;
revoke all on function public.revoke_exam_prep_beta_consent_v1(text,uuid,text)
from public,anon,authenticated;
grant execute on function public.revoke_exam_prep_beta_consent_v1(text,uuid,text)
to service_role;

-- Deployment invariants: this governance change must not activate anyone.
do $$
declare
  v_cfg private.exam_prep_feature_config%rowtype;
  v_active int;
begin
  select * into v_cfg from private.exam_prep_feature_config where id=1;
  if v_cfg.rollout_state<>'off'
     or v_cfg.core_enabled
     or v_cfg.ai_enabled
     or v_cfg.mentor_enabled
     or not v_cfg.kill_switch then
    raise exception 'P0-16 Core-first convergence requires fail-closed feature state at deployment';
  end if;

  select count(*) into v_active
  from private.exam_prep_feature_entitlements
  where entitlement_status='active';
  if v_active<>0 then
    raise exception 'P0-16 Core-first convergence found active entitlements=%',v_active;
  end if;
end
$$;

commit;
