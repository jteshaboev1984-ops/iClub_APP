-- P0-16: governed controlled-beta cohort, canary waves, rollback and monitoring.
--
-- Safety principles:
-- * additive only; no legacy table mutation;
-- * no learner is enrolled by this migration;
-- * no feature is enabled by this migration;
-- * all cohort mutation RPCs are service_role-only;
-- * activation is allowlist-based and atomic;
-- * rollback pauses entitlements but preserves Exam Prep evidence/state;
-- * Mentor Care requires a real active staff role + assignment before approval.

begin;

create table if not exists private.exam_prep_beta_cohorts (
  id bigint generated always as identity primary key,
  cohort_key text not null unique check (cohort_key ~ '^[a-z0-9][a-z0-9_-]{2,79}$'),
  program_key text not null default 'math_as_p1_p5',
  cohort_status text not null default 'draft'
    check (cohort_status in ('draft','approved','canary','active','paused','completed','cancelled')),
  planned_size smallint not null check (planned_size between 12 and 20),
  current_wave smallint not null default 0 check (current_wave between 0 and 20),
  monitoring_hours smallint not null default 72 check (monitoring_hours between 24 and 168),
  notes text,
  created_at timestamptz not null default now(),
  created_by uuid,
  approved_at timestamptz,
  started_at timestamptz,
  monitoring_until timestamptz,
  paused_at timestamptz,
  completed_at timestamptz,
  updated_at timestamptz not null default now(),
  updated_by uuid
);

create unique index if not exists exam_prep_beta_one_live_cohort_uq
on private.exam_prep_beta_cohorts(program_key)
where cohort_status in ('approved','canary','active','paused');

create table if not exists private.exam_prep_beta_members (
  id bigint generated always as identity primary key,
  cohort_id bigint not null references private.exam_prep_beta_cohorts(id) on delete cascade,
  user_id uuid not null references public.users(id) on delete cascade,
  service_mode text not null check (service_mode in ('core','ai_assist','mentor_care')),
  activation_wave smallint not null default 1 check (activation_wave between 1 and 20),
  member_status text not null default 'candidate'
    check (member_status in ('candidate','approved','active','paused','removed','completed')),
  created_at timestamptz not null default now(),
  created_by uuid,
  activated_at timestamptz,
  paused_at timestamptz,
  updated_at timestamptz not null default now(),
  updated_by uuid,
  unique(cohort_id,user_id)
);

create unique index if not exists exam_prep_beta_one_live_membership_uq
on private.exam_prep_beta_members(user_id)
where member_status in ('approved','active','paused');

create index if not exists exam_prep_beta_members_cohort_status_idx
on private.exam_prep_beta_members(cohort_id,member_status,activation_wave,service_mode);

alter table private.exam_prep_beta_cohorts enable row level security;
alter table private.exam_prep_beta_members enable row level security;

revoke all on private.exam_prep_beta_cohorts from public,anon,authenticated;
revoke all on private.exam_prep_beta_members from public,anon,authenticated;
grant select,insert,update,delete on private.exam_prep_beta_cohorts to service_role;
grant select,insert,update,delete on private.exam_prep_beta_members to service_role;
grant usage,select on all sequences in schema private to service_role;

drop trigger if exists exam_prep_beta_cohorts_audit_v1 on private.exam_prep_beta_cohorts;
create trigger exam_prep_beta_cohorts_audit_v1
after insert or update or delete on private.exam_prep_beta_cohorts
for each row execute function private.exam_prep_audit_row_change_v1();

drop trigger if exists exam_prep_beta_members_audit_v1 on private.exam_prep_beta_members;
create trigger exam_prep_beta_members_audit_v1
after insert or update or delete on private.exam_prep_beta_members
for each row execute function private.exam_prep_audit_row_change_v1();

-- Create a DRAFT cohort only. This never changes feature flags or entitlements.
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
  if p_planned_size not between 12 and 20 then
    raise exception 'exam_prep_beta_size_must_be_12_to_20';
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
    'cohort_id',v_id,'cohort_key',p_cohort_key,'status','draft',
    'planned_size',p_planned_size,'feature_state','off'
  );
end;
$$;
revoke all on function public.stage_exam_prep_controlled_beta_v1(text,smallint,text) from public,anon,authenticated;
grant execute on function public.stage_exam_prep_controlled_beta_v1(text,smallint,text) to service_role;

-- Add/update a DRAFT allowlist member. Membership alone never grants access.
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
  if v_c.id is null then raise exception 'exam_prep_beta_cohort_not_found' using errcode='P0002'; end if;
  if v_c.cohort_status<>'draft' then raise exception 'exam_prep_beta_members_locked_after_approval'; end if;

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
    'member_id',v_id,'cohort_key',p_cohort_key,'user_id',p_user_id,
    'service_mode',p_service_mode,'activation_wave',p_activation_wave,'status','candidate'
  );
end;
$$;
revoke all on function public.set_exam_prep_beta_member_v1(text,uuid,text,smallint) from public,anon,authenticated;
grant execute on function public.set_exam_prep_beta_member_v1(text,uuid,text,smallint) to service_role;

-- Approve the full 12-20 learner allowlist while keeping the global feature OFF.
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
  select * into v_c from private.exam_prep_beta_cohorts where cohort_key=p_cohort_key for update;
  if v_c.id is null then raise exception 'exam_prep_beta_cohort_not_found' using errcode='P0002'; end if;
  if v_c.cohort_status<>'draft' then raise exception 'exam_prep_beta_cohort_not_draft'; end if;

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
  if v_core=0 or v_ai=0 or v_mentor=0 then
    raise exception 'exam_prep_beta_requires_mixed_core_ai_mentor_modes';
  end if;

  select * into v_cfg from private.exam_prep_feature_config where id=1;
  if v_cfg.rollout_state<>'off' or v_cfg.core_enabled or v_cfg.ai_enabled or v_cfg.mentor_enabled or not v_cfg.kill_switch then
    raise exception 'exam_prep_beta_approval_requires_fail_closed_config';
  end if;

  -- Every Mentor Care learner must already have a governed operational assignment
  -- and assigned_active service state; flags alone are never sufficient.
  select count(*) into v_bad
  from private.exam_prep_beta_members m
  where m.cohort_id=v_c.id and m.member_status='candidate' and m.service_mode='mentor_care'
    and (
      not exists(
        select 1 from private.exam_prep_mentor_service_status s
        where s.learner_user_id=m.user_id and s.service_status='assigned_active'
      )
      or not exists(
        select 1
        from private.exam_prep_mentor_assignments a
        where a.learner_user_id=m.user_id
          and a.component_code in ('P1','P5')
          and a.assignment_status='active'
          and a.valid_from<=now() and (a.valid_until is null or a.valid_until>now())
          and exists(
            select 1 from private.exam_prep_staff_roles r
            where r.user_id=a.mentor_user_id
              and r.role_code in ('mentor','lead_mentor','academic_moderator')
              and r.role_status='active'
              and r.valid_from<=now() and (r.valid_until is null or r.valid_until>now())
          )
      )
    );
  if v_bad<>0 then
    raise exception 'exam_prep_beta_mentor_readiness_violations=%',v_bad;
  end if;

  -- Non-Mentor modes must not be operationally assigned to Mentor Care.
  select count(*) into v_bad
  from private.exam_prep_beta_members m
  where m.cohort_id=v_c.id and m.member_status='candidate' and m.service_mode<>'mentor_care'
    and (
      exists(
        select 1 from private.exam_prep_mentor_service_status s
        where s.learner_user_id=m.user_id and s.service_status='assigned_active'
      )
      or exists(
        select 1 from private.exam_prep_mentor_assignments a
        where a.learner_user_id=m.user_id and a.assignment_status='active'
          and a.valid_from<=now() and (a.valid_until is null or a.valid_until>now())
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
    'cohort_key',p_cohort_key,'status','approved','planned_size',v_total,
    'service_mix',jsonb_build_object('core',v_core,'ai_assist',v_ai,'mentor_care',v_mentor),
    'feature_state','off'
  );
end;
$$;
revoke all on function public.approve_exam_prep_controlled_beta_v1(text) from public,anon,authenticated;
grant execute on function public.approve_exam_prep_controlled_beta_v1(text) to service_role;

-- Activate exactly the next canary wave. Only members in activated waves receive
-- active entitlements. Full-cohort approval remains a prerequisite.
create or replace function public.activate_exam_prep_controlled_beta_wave_v1(
  p_cohort_key text,
  p_wave smallint
)
returns jsonb
language plpgsql
security definer
set search_path=''
as $$
declare
  v_c private.exam_prep_beta_cohorts%rowtype;
  v_wave_count int;
  v_active_count int;
  v_bad int;
  v_status text;
  v_cfg private.exam_prep_feature_config%rowtype;
begin
  select * into v_c from private.exam_prep_beta_cohorts where cohort_key=p_cohort_key for update;
  if v_c.id is null then raise exception 'exam_prep_beta_cohort_not_found' using errcode='P0002'; end if;
  if v_c.cohort_status not in ('approved','canary') then raise exception 'exam_prep_beta_cohort_not_activatable'; end if;
  if p_wave<>v_c.current_wave+1 then
    raise exception 'exam_prep_beta_wave_must_be_next: current %, requested %',v_c.current_wave,p_wave;
  end if;

  select count(*) into v_wave_count
  from private.exam_prep_beta_members
  where cohort_id=v_c.id and member_status='approved' and activation_wave=p_wave;
  if v_wave_count=0 then raise exception 'exam_prep_beta_wave_empty'; end if;

  select * into v_cfg from private.exam_prep_feature_config where id=1 for update;
  if v_c.current_wave=0 then
    if v_cfg.rollout_state<>'off' or v_cfg.core_enabled or v_cfg.ai_enabled or v_cfg.mentor_enabled or not v_cfg.kill_switch then
      raise exception 'exam_prep_beta_first_wave_requires_fail_closed_config';
    end if;
  else
    if v_cfg.rollout_state<>'controlled_beta' or v_cfg.kill_switch or not v_cfg.core_enabled then
      raise exception 'exam_prep_beta_subsequent_wave_requires_live_controlled_beta';
    end if;
  end if;

  -- Revalidate Mentor Care operational authority immediately before activation.
  select count(*) into v_bad
  from private.exam_prep_beta_members m
  where m.cohort_id=v_c.id and m.member_status='approved' and m.activation_wave=p_wave and m.service_mode='mentor_care'
    and (
      not exists(
        select 1 from private.exam_prep_mentor_service_status s
        where s.learner_user_id=m.user_id and s.service_status='assigned_active'
      )
      or not exists(
        select 1 from private.exam_prep_mentor_assignments a
        where a.learner_user_id=m.user_id and a.component_code in ('P1','P5')
          and a.assignment_status='active'
          and a.valid_from<=now() and (a.valid_until is null or a.valid_until>now())
          and exists(
            select 1 from private.exam_prep_staff_roles r
            where r.user_id=a.mentor_user_id
              and r.role_code in ('mentor','lead_mentor','academic_moderator')
              and r.role_status='active'
              and r.valid_from<=now() and (r.valid_until is null or r.valid_until>now())
          )
      )
    );
  if v_bad<>0 then raise exception 'exam_prep_beta_wave_mentor_readiness_violations=%',v_bad; end if;

  -- A member may not carry a live entitlement from another cohort/experiment.
  select count(*) into v_bad
  from private.exam_prep_beta_members m
  join private.exam_prep_feature_entitlements e on e.user_id=m.user_id
  where m.cohort_id=v_c.id and m.member_status='approved' and m.activation_wave=p_wave
    and e.entitlement_status='active'
    and coalesce(e.cohort_key,'')<>p_cohort_key;
  if v_bad<>0 then raise exception 'exam_prep_beta_conflicting_live_entitlements=%',v_bad; end if;

  insert into private.exam_prep_feature_entitlements(
    user_id,entitlement_status,core_access,ai_assist,mentor_care_entitled,
    cohort_key,valid_from,valid_until,updated_at,updated_by
  )
  select m.user_id,'active',true,
         (m.service_mode='ai_assist'),
         (m.service_mode='mentor_care'),
         p_cohort_key,now(),null,now(),auth.uid()
  from private.exam_prep_beta_members m
  where m.cohort_id=v_c.id and m.member_status='approved' and m.activation_wave=p_wave
  on conflict(user_id) do update set
    entitlement_status='active',
    core_access=true,
    ai_assist=excluded.ai_assist,
    mentor_care_entitled=excluded.mentor_care_entitled,
    cohort_key=excluded.cohort_key,
    valid_from=now(),
    valid_until=null,
    updated_at=now(),
    updated_by=auth.uid();

  update private.exam_prep_beta_members
  set member_status='active',activated_at=coalesce(activated_at,now()),updated_at=now(),updated_by=auth.uid()
  where cohort_id=v_c.id and member_status='approved' and activation_wave=p_wave;

  select count(*) into v_active_count
  from private.exam_prep_beta_members
  where cohort_id=v_c.id and member_status='active';

  v_status:=case when v_active_count=v_c.planned_size then 'active' else 'canary' end;

  update private.exam_prep_beta_cohorts
  set cohort_status=v_status,
      current_wave=p_wave,
      started_at=coalesce(started_at,now()),
      monitoring_until=coalesce(monitoring_until,now()+(monitoring_hours||' hours')::interval),
      updated_at=now(),updated_by=auth.uid()
  where id=v_c.id;

  update private.exam_prep_feature_config
  set rollout_state='controlled_beta',
      core_enabled=true,
      ai_enabled=exists(
        select 1 from private.exam_prep_beta_members m
        where m.cohort_id=v_c.id and m.member_status='active' and m.service_mode='ai_assist'
      ),
      mentor_enabled=exists(
        select 1 from private.exam_prep_beta_members m
        where m.cohort_id=v_c.id and m.member_status='active' and m.service_mode='mentor_care'
      ),
      kill_switch=false,
      updated_at=now(),updated_by=auth.uid()
  where id=1;

  return jsonb_build_object(
    'cohort_key',p_cohort_key,'status',v_status,'activated_wave',p_wave,
    'wave_members',v_wave_count,'active_members',v_active_count,'planned_size',v_c.planned_size,
    'monitoring_hours',v_c.monitoring_hours
  );
end;
$$;
revoke all on function public.activate_exam_prep_controlled_beta_wave_v1(text,smallint) from public,anon,authenticated;
grant execute on function public.activate_exam_prep_controlled_beta_wave_v1(text,smallint) to service_role;

-- Read-only 72h monitoring snapshot for operations. It never changes cohort state.
create or replace function public.get_exam_prep_controlled_beta_monitor_v1(p_cohort_key text)
returns jsonb
language plpgsql
stable
security definer
set search_path=''
as $$
declare
  v_c private.exam_prep_beta_cohorts%rowtype;
  v_cfg private.exam_prep_feature_config%rowtype;
  v_planned int;
  v_approved int;
  v_active int;
  v_paused int;
  v_core int;
  v_ai int;
  v_mentor int;
  v_sessions bigint;
  v_evidence bigint;
  v_entitlement_mismatch int;
  v_mentor_violations int;
  v_queue_leakage int;
  v_open_queue int;
  v_max_queue int;
  v_green boolean;
begin
  select * into v_c from private.exam_prep_beta_cohorts where cohort_key=p_cohort_key;
  if v_c.id is null then raise exception 'exam_prep_beta_cohort_not_found' using errcode='P0002'; end if;
  select * into v_cfg from private.exam_prep_feature_config where id=1;

  select count(*),
         count(*) filter(where member_status='approved'),
         count(*) filter(where member_status='active'),
         count(*) filter(where member_status='paused'),
         count(*) filter(where member_status='active' and service_mode='core'),
         count(*) filter(where member_status='active' and service_mode='ai_assist'),
         count(*) filter(where member_status='active' and service_mode='mentor_care')
    into v_planned,v_approved,v_active,v_paused,v_core,v_ai,v_mentor
  from private.exam_prep_beta_members where cohort_id=v_c.id and member_status<>'removed';

  select count(*) into v_entitlement_mismatch
  from private.exam_prep_beta_members m
  left join private.exam_prep_feature_entitlements e on e.user_id=m.user_id
  where m.cohort_id=v_c.id and (
    (m.member_status='active' and (
      e.user_id is null or e.entitlement_status<>'active' or not e.core_access
      or coalesce(e.cohort_key,'')<>p_cohort_key
      or e.ai_assist is distinct from (m.service_mode='ai_assist')
      or e.mentor_care_entitled is distinct from (m.service_mode='mentor_care')
    ))
    or (m.member_status<>'active' and e.entitlement_status='active' and e.cohort_key=p_cohort_key)
  );

  select count(*) into v_mentor_violations
  from private.exam_prep_beta_members m
  where m.cohort_id=v_c.id and m.member_status='active' and m.service_mode='mentor_care'
    and (
      not exists(
        select 1 from private.exam_prep_mentor_service_status s
        where s.learner_user_id=m.user_id and s.service_status='assigned_active'
      )
      or not exists(
        select 1 from private.exam_prep_mentor_assignments a
        where a.learner_user_id=m.user_id and a.component_code in ('P1','P5')
          and a.assignment_status='active' and a.valid_from<=now()
          and (a.valid_until is null or a.valid_until>now())
          and exists(
            select 1 from private.exam_prep_staff_roles r
            where r.user_id=a.mentor_user_id
              and r.role_code in ('mentor','lead_mentor','academic_moderator')
              and r.role_status='active' and r.valid_from<=now()
              and (r.valid_until is null or r.valid_until>now())
          )
      )
    );

  select count(*) into v_queue_leakage
  from private.exam_prep_mentor_queue_items q
  join private.exam_prep_beta_members m on m.user_id=q.learner_user_id and m.cohort_id=v_c.id
  where q.status in ('open','in_review','pending_second_check') and (
    m.member_status<>'active' or m.service_mode<>'mentor_care'
    or not exists(
      select 1
      from private.exam_prep_mentor_assignments a
      where a.id=q.assignment_id and a.learner_user_id=q.learner_user_id
        and a.mentor_user_id=q.mentor_user_id and a.component_code=q.component_code
        and a.assignment_status='active' and a.valid_from<=now()
        and (a.valid_until is null or a.valid_until>now())
        and exists(
          select 1 from private.exam_prep_staff_roles r
          where r.user_id=a.mentor_user_id
            and r.role_code in ('mentor','lead_mentor','academic_moderator')
            and r.role_status='active' and r.valid_from<=now()
            and (r.valid_until is null or r.valid_until>now())
        )
    )
  );

  select count(*) into v_open_queue
  from private.exam_prep_mentor_queue_items q
  join private.exam_prep_beta_members m on m.user_id=q.learner_user_id and m.cohort_id=v_c.id
  where q.status in ('open','in_review','pending_second_check');

  select coalesce(max(c),0)::int into v_max_queue
  from (
    select count(*) c
    from private.exam_prep_mentor_queue_items q
    join private.exam_prep_beta_members m on m.user_id=q.learner_user_id and m.cohort_id=v_c.id
    where q.status in ('open','in_review','pending_second_check')
    group by q.mentor_user_id
  ) z;

  select count(*) into v_sessions
  from private.exam_prep_sessions s
  join private.exam_prep_beta_members m on m.user_id=s.user_id and m.cohort_id=v_c.id
  where v_c.started_at is not null and s.started_at>=v_c.started_at;

  select count(*) into v_evidence
  from private.exam_prep_evidence_events e
  join private.exam_prep_beta_members m on m.user_id=e.user_id and m.cohort_id=v_c.id
  where v_c.started_at is not null and e.created_at>=v_c.started_at;

  v_green := v_c.cohort_status in ('canary','active')
    and v_cfg.rollout_state='controlled_beta'
    and not v_cfg.kill_switch and v_cfg.core_enabled
    and v_active between 1 and v_c.planned_size
    and v_entitlement_mismatch=0
    and v_mentor_violations=0
    and v_queue_leakage=0;

  return jsonb_build_object(
    'cohort_key',v_c.cohort_key,
    'cohort_status',v_c.cohort_status,
    'current_wave',v_c.current_wave,
    'planned_size',v_c.planned_size,
    'member_counts',jsonb_build_object(
      'total',v_planned,'approved_waiting',v_approved,'active',v_active,'paused',v_paused
    ),
    'active_service_mix',jsonb_build_object('core',v_core,'ai_assist',v_ai,'mentor_care',v_mentor),
    'feature_config',jsonb_build_object(
      'rollout_state',v_cfg.rollout_state,'core_enabled',v_cfg.core_enabled,
      'ai_enabled',v_cfg.ai_enabled,'mentor_enabled',v_cfg.mentor_enabled,'kill_switch',v_cfg.kill_switch
    ),
    'activity_since_start',jsonb_build_object('sessions',v_sessions,'evidence_events',v_evidence),
    'integrity',jsonb_build_object(
      'entitlement_mismatches',v_entitlement_mismatch,
      'mentor_readiness_violations',v_mentor_violations,
      'queue_leakage',v_queue_leakage
    ),
    'mentor_queue',jsonb_build_object('open_items',v_open_queue,'max_open_per_mentor',v_max_queue),
    'started_at',v_c.started_at,
    'monitoring_until',v_c.monitoring_until,
    'monitoring_remaining_seconds',case when v_c.monitoring_until is null then null else greatest(0,extract(epoch from (v_c.monitoring_until-now()))::bigint) end,
    'runway_green',v_green
  );
end;
$$;
revoke all on function public.get_exam_prep_controlled_beta_monitor_v1(text) from public,anon,authenticated;
grant execute on function public.get_exam_prep_controlled_beta_monitor_v1(text) to service_role;

-- Emergency/global rollback for the controlled beta. Evidence/state is preserved;
-- only access/service state is paused and the global feature is fail-closed.
create or replace function public.pause_exam_prep_controlled_beta_v1(
  p_cohort_key text,
  p_reason text
)
returns jsonb
language plpgsql
security definer
set search_path=''
as $$
declare
  v_c private.exam_prep_beta_cohorts%rowtype;
  v_paused int;
begin
  if p_reason is null or char_length(trim(p_reason)) not between 5 and 1000 then
    raise exception 'exam_prep_beta_pause_reason_required';
  end if;
  select * into v_c from private.exam_prep_beta_cohorts where cohort_key=p_cohort_key for update;
  if v_c.id is null then raise exception 'exam_prep_beta_cohort_not_found' using errcode='P0002'; end if;
  if v_c.cohort_status not in ('canary','active') then raise exception 'exam_prep_beta_cohort_not_live'; end if;

  -- Fail closed first.
  update private.exam_prep_feature_config
  set rollout_state='off',core_enabled=false,ai_enabled=false,mentor_enabled=false,
      kill_switch=true,updated_at=now(),updated_by=auth.uid()
  where id=1;

  update private.exam_prep_feature_entitlements e
  set entitlement_status='paused',updated_at=now(),updated_by=auth.uid()
  from private.exam_prep_beta_members m
  where m.cohort_id=v_c.id and m.user_id=e.user_id
    and m.member_status='active' and e.entitlement_status='active' and e.cohort_key=p_cohort_key;

  update private.exam_prep_mentor_service_status s
  set service_status='assigned_paused',status_reason='controlled_beta_paused: '||left(trim(p_reason),500),
      status_changed_at=now(),updated_at=now(),updated_by=auth.uid()
  from private.exam_prep_beta_members m
  where m.cohort_id=v_c.id and m.user_id=s.learner_user_id
    and m.member_status='active' and m.service_mode='mentor_care' and s.service_status='assigned_active';

  update private.exam_prep_beta_members
  set member_status='paused',paused_at=now(),updated_at=now(),updated_by=auth.uid()
  where cohort_id=v_c.id and member_status='active';
  get diagnostics v_paused = row_count;

  update private.exam_prep_beta_cohorts
  set cohort_status='paused',paused_at=now(),notes=concat_ws(E'\n',notes,'PAUSE: '||trim(p_reason)),
      updated_at=now(),updated_by=auth.uid()
  where id=v_c.id;

  return jsonb_build_object(
    'cohort_key',p_cohort_key,'status','paused','paused_members',v_paused,
    'feature_state','off','kill_switch',true,'evidence_preserved',true
  );
end;
$$;
revoke all on function public.pause_exam_prep_controlled_beta_v1(text,text) from public,anon,authenticated;
grant execute on function public.pause_exam_prep_controlled_beta_v1(text,text) to service_role;

-- Deployment gate: schema/RPCs may exist, but no beta may be pre-created or enabled.
do $$
declare
  v_bad int;
begin
  select count(*) into v_bad from private.exam_prep_beta_cohorts;
  if v_bad<>0 then raise exception 'P0-16 migration must not pre-enroll a beta cohort'; end if;

  select count(*) into v_bad from private.exam_prep_feature_config
  where id=1 and (rollout_state<>'off' or core_enabled or ai_enabled or mentor_enabled or not kill_switch);
  if v_bad<>0 then raise exception 'P0-16 deployment must remain fail-closed'; end if;

  select count(*) into v_bad
  from pg_proc p join pg_namespace n on n.oid=p.pronamespace
  where n.nspname='public'
    and p.proname in (
      'stage_exam_prep_controlled_beta_v1','set_exam_prep_beta_member_v1',
      'approve_exam_prep_controlled_beta_v1','activate_exam_prep_controlled_beta_wave_v1',
      'get_exam_prep_controlled_beta_monitor_v1','pause_exam_prep_controlled_beta_v1'
    )
    and (has_function_privilege('anon',p.oid,'EXECUTE') or has_function_privilege('authenticated',p.oid,'EXECUTE'));
  if v_bad<>0 then raise exception 'P0-16 beta RPC privilege leak count=%',v_bad; end if;
end;
$$;

commit;
