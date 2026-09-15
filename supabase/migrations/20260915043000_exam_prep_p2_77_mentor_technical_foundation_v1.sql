begin;

-- P2-77: Mentor Technical Simulation foundation.
-- Additive only. This does not enable Mentor Care, create assignments, or grant
-- any real learner/mentor access. It permits synthetic staff authority only for
-- an explicitly registered mentor_technical synthetic run and adds governed
-- pause/handover operations for already-authorized Mentor Care assignments.

-- Synthetic mentor identities were intentionally blocked at P2-65 until this
-- stage. From P2-77 onward they may receive staff roles only when every
-- provenance/lifecycle condition below is true.
create or replace function private.enforce_exam_prep_synthetic_staff_role_firewall_v1()
returns trigger
language plpgsql
security definer
set search_path=''
as $$
declare
  v_identity private.exam_prep_synthetic_identities%rowtype;
  v_run private.exam_prep_synthetic_validation_runs%rowtype;
begin
  select * into v_identity
  from private.exam_prep_synthetic_identities s
  where s.user_id=new.user_id;

  if v_identity.user_id is null then
    return new;
  end if;

  select * into v_run
  from private.exam_prep_synthetic_validation_runs r
  where r.run_id=v_identity.run_id;

  if v_identity.identity_kind<>'mentor'
     or v_identity.identity_status<>'active'
     or v_run.run_id is null
     or v_run.capability_mode<>'mentor_technical'
     or v_run.run_status not in ('registered','running')
     or v_run.cleanup_status<>'not_started'
     or new.role_code not in ('mentor','lead_mentor','academic_moderator','mentor_ops','safeguarding_lead') then
    raise exception 'exam_prep_synthetic_staff_role_requires_open_mentor_technical_run';
  end if;

  return new;
end;
$$;
revoke all on function private.enforce_exam_prep_synthetic_staff_role_firewall_v1() from public,anon,authenticated;

-- Update the isolation report so governed mentor_technical staff roles are
-- distinguishable from invalid synthetic human authority.
create or replace function private.exam_prep_synthetic_identity_isolation_report_v1()
returns jsonb
language sql
stable security definer
set search_path=''
as $$
  with counts as (
    select
      (select count(*) from private.exam_prep_synthetic_identities)::int as synthetic_identities,
      (
        select count(*)
        from private.exam_prep_synthetic_identities s
        join private.exam_prep_staff_roles sr on sr.user_id=s.user_id
      )::int as synthetic_staff_role_rows,
      (
        select count(*)
        from private.exam_prep_synthetic_identities s
        join private.exam_prep_staff_roles sr on sr.user_id=s.user_id
        left join private.exam_prep_synthetic_validation_runs r on r.run_id=s.run_id
        where s.identity_kind<>'mentor'
           or s.identity_status<>'active'
           or r.run_id is null
           or r.capability_mode<>'mentor_technical'
           or r.run_status not in ('registered','running')
           or r.cleanup_status<>'not_started'
           or sr.role_code not in ('mentor','lead_mentor','academic_moderator','mentor_ops','safeguarding_lead')
      )::int as invalid_synthetic_staff_role_rows,
      (
        select count(*)
        from private.exam_prep_mentor_assignments a
        left join private.exam_prep_synthetic_identities l on l.user_id=a.learner_user_id
        left join private.exam_prep_synthetic_identities m on m.user_id=a.mentor_user_id
        where (l.user_id is null) is distinct from (m.user_id is null)
      )::int as real_synthetic_assignment_crossings,
      (
        select count(*)
        from private.exam_prep_mentor_assignments a
        join private.exam_prep_synthetic_identities l on l.user_id=a.learner_user_id
        join private.exam_prep_synthetic_identities m on m.user_id=a.mentor_user_id
        where l.run_id is distinct from m.run_id
      )::int as cross_run_assignments,
      (
        select count(*)
        from private.exam_prep_mentor_assignments a
        join private.exam_prep_synthetic_identities l on l.user_id=a.learner_user_id
        join private.exam_prep_synthetic_identities m on m.user_id=a.mentor_user_id
        where l.identity_kind<>'learner' or m.identity_kind<>'mentor'
      )::int as identity_kind_assignment_mismatches
  )
  select jsonb_build_object(
    'synthetic_identities',synthetic_identities,
    'synthetic_staff_role_rows',synthetic_staff_role_rows,
    'invalid_synthetic_staff_role_rows',invalid_synthetic_staff_role_rows,
    'real_synthetic_assignment_crossings',real_synthetic_assignment_crossings,
    'cross_run_assignments',cross_run_assignments,
    'identity_kind_assignment_mismatches',identity_kind_assignment_mismatches,
    'eligible',
      invalid_synthetic_staff_role_rows=0
      and real_synthetic_assignment_crossings=0
      and cross_run_assignments=0
      and identity_kind_assignment_mismatches=0
  )
  from counts;
$$;
revoke all on function private.exam_prep_synthetic_identity_isolation_report_v1() from public,anon,authenticated;
grant execute on function private.exam_prep_synthetic_identity_isolation_report_v1() to service_role;

-- Pause an assignment for mentor absence/capacity without touching deterministic
-- academic evidence. Existing queue/history is preserved; routine queue access
-- disappears because the active-assignment gate fails closed.
create or replace function public.pause_exam_prep_mentor_assignment_safe_v1(
  p_assignment_id bigint,
  p_reason_text text
)
returns jsonb
language plpgsql
security definer
set search_path=''
as $$
declare
  v_uid uuid:=auth.uid();
  v_a private.exam_prep_mentor_assignments%rowtype;
  v_other_active int:=0;
begin
  if v_uid is null then raise exception 'exam_prep_auth_required'; end if;
  if not private.exam_prep_has_staff_role_v1(v_uid,array['lead_mentor','academic_moderator','mentor_ops']) then
    raise exception 'exam_prep_mentor_ops_role_required' using errcode='42501';
  end if;
  if p_reason_text is null or char_length(trim(p_reason_text)) not between 10 and 1000 then
    raise exception 'exam_prep_mentor_pause_reason_required';
  end if;

  select * into v_a
  from private.exam_prep_mentor_assignments
  where id=p_assignment_id
  for update;
  if v_a.id is null then raise exception 'exam_prep_assignment_not_found' using errcode='P0002'; end if;
  if v_a.assignment_status<>'active' then raise exception 'exam_prep_assignment_not_active'; end if;

  update private.exam_prep_mentor_assignments
  set assignment_status='paused',updated_at=now(),updated_by=v_uid
  where id=v_a.id;

  select count(*) into v_other_active
  from private.exam_prep_mentor_assignments a
  where a.learner_user_id=v_a.learner_user_id
    and a.id<>v_a.id
    and a.assignment_status='active'
    and a.valid_from<=now()
    and (a.valid_until is null or a.valid_until>now());

  if v_other_active=0 then
    update private.exam_prep_mentor_service_status
    set service_status='assigned_paused',
        status_reason=trim(p_reason_text),
        status_changed_at=now(),updated_at=now(),updated_by=v_uid
    where learner_user_id=v_a.learner_user_id
      and service_status='assigned_active';
  end if;

  insert into private.exam_prep_audit_events(
    program_key,actor_user_id,actor_role,event_type,object_type,object_id,target_user_id,component_code,before_state,after_state,metadata
  ) values(
    'math_as_p1_p5',v_uid,'mentor_ops','mentor_assignment_paused','private.exam_prep_mentor_assignments',v_a.id::text,
    v_a.learner_user_id,v_a.component_code,to_jsonb(v_a),
    (select to_jsonb(a) from private.exam_prep_mentor_assignments a where a.id=v_a.id),
    jsonb_build_object('reason',trim(p_reason_text),'other_active_assignments',v_other_active)
  );

  return jsonb_build_object(
    'assignment_id',v_a.id,'assignment_status','paused','learner_user_id',v_a.learner_user_id,
    'component_code',v_a.component_code,'other_active_assignments',v_other_active
  );
end;
$$;
revoke all on function public.pause_exam_prep_mentor_assignment_safe_v1(bigint,text) from public,anon;
grant execute on function public.pause_exam_prep_mentor_assignment_safe_v1(bigint,text) to authenticated,service_role;

-- Governed handover. Open/in-review operational work moves to the replacement
-- mentor while completed reviews and pending second-check history remain tied to
-- the original reviewer. opened_at is preserved so SLA age cannot be reset by a
-- handover.
create or replace function public.handover_exam_prep_mentor_assignment_safe_v1(
  p_assignment_id bigint,
  p_new_mentor_user_id uuid,
  p_reason_text text
)
returns jsonb
language plpgsql
security definer
set search_path=''
as $$
declare
  v_uid uuid:=auth.uid();
  v_old private.exam_prep_mentor_assignments%rowtype;
  v_new_assignment bigint;
  v_moved int:=0;
  v_cfg private.exam_prep_feature_config%rowtype;
begin
  if v_uid is null then raise exception 'exam_prep_auth_required'; end if;
  if not private.exam_prep_has_staff_role_v1(v_uid,array['lead_mentor','academic_moderator','mentor_ops']) then
    raise exception 'exam_prep_mentor_ops_role_required' using errcode='42501';
  end if;
  if p_new_mentor_user_id is null then raise exception 'exam_prep_new_mentor_required'; end if;
  if p_reason_text is null or char_length(trim(p_reason_text)) not between 10 and 1000 then
    raise exception 'exam_prep_mentor_handover_reason_required';
  end if;

  select * into v_cfg from private.exam_prep_feature_config where id=1;
  if v_cfg.id is null or v_cfg.kill_switch or not v_cfg.core_enabled or not v_cfg.mentor_enabled or v_cfg.rollout_state='off' then
    raise exception 'exam_prep_mentor_service_not_enabled';
  end if;

  select * into v_old
  from private.exam_prep_mentor_assignments
  where id=p_assignment_id
  for update;
  if v_old.id is null then raise exception 'exam_prep_assignment_not_found' using errcode='P0002'; end if;
  if v_old.assignment_status not in ('active','paused') then raise exception 'exam_prep_assignment_not_handover_eligible'; end if;
  if p_new_mentor_user_id=v_old.mentor_user_id then raise exception 'exam_prep_handover_requires_different_mentor'; end if;
  if p_new_mentor_user_id=v_old.learner_user_id then raise exception 'exam_prep_handover_mentor_cannot_be_learner'; end if;
  if not private.exam_prep_has_staff_role_v1(p_new_mentor_user_id,array['mentor','lead_mentor','academic_moderator']) then
    raise exception 'exam_prep_new_mentor_not_active_staff' using errcode='42501';
  end if;
  if not exists(
    select 1 from private.exam_prep_feature_entitlements e
    where e.user_id=v_old.learner_user_id and e.entitlement_status='active'
      and e.core_access and e.mentor_care_entitled
      and (e.valid_from is null or e.valid_from<=now())
      and (e.valid_until is null or e.valid_until>now())
  ) then raise exception 'exam_prep_mentor_entitlement_not_active' using errcode='42501'; end if;

  update private.exam_prep_mentor_assignments
  set assignment_status='ended',valid_until=coalesce(valid_until,now()),updated_at=now(),updated_by=v_uid
  where id=v_old.id;

  insert into private.exam_prep_mentor_assignments(
    learner_user_id,mentor_user_id,component_code,assignment_status,valid_from,created_by,updated_by
  ) values(
    v_old.learner_user_id,p_new_mentor_user_id,v_old.component_code,'active',now(),v_uid,v_uid
  ) returning id into v_new_assignment;

  update private.exam_prep_mentor_queue_items
  set assignment_id=v_new_assignment,
      mentor_user_id=p_new_mentor_user_id,
      status='open',
      updated_at=now()
  where assignment_id=v_old.id
    and status in ('open','in_review');
  get diagnostics v_moved=row_count;

  insert into private.exam_prep_mentor_service_status(
    learner_user_id,service_status,status_reason,status_changed_at,created_by,updated_at,updated_by
  ) values(
    v_old.learner_user_id,'assigned_active',trim(p_reason_text),now(),v_uid,now(),v_uid
  )
  on conflict(learner_user_id) do update
  set service_status='assigned_active',status_reason=excluded.status_reason,status_changed_at=now(),updated_at=now(),updated_by=v_uid;

  insert into private.exam_prep_audit_events(
    program_key,actor_user_id,actor_role,event_type,object_type,object_id,target_user_id,component_code,before_state,after_state,metadata
  ) values(
    'math_as_p1_p5',v_uid,'mentor_ops','mentor_assignment_handover','private.exam_prep_mentor_assignments',v_new_assignment::text,
    v_old.learner_user_id,v_old.component_code,to_jsonb(v_old),
    (select to_jsonb(a) from private.exam_prep_mentor_assignments a where a.id=v_new_assignment),
    jsonb_build_object('reason',trim(p_reason_text),'old_assignment_id',v_old.id,'new_assignment_id',v_new_assignment,
                       'old_mentor_user_id',v_old.mentor_user_id,'new_mentor_user_id',p_new_mentor_user_id,
                       'moved_open_queue_items',v_moved)
  );

  return jsonb_build_object(
    'old_assignment_id',v_old.id,'new_assignment_id',v_new_assignment,
    'learner_user_id',v_old.learner_user_id,'component_code',v_old.component_code,
    'old_mentor_user_id',v_old.mentor_user_id,'new_mentor_user_id',p_new_mentor_user_id,
    'moved_open_queue_items',v_moved,'assignment_status','active'
  );
end;
$$;
revoke all on function public.handover_exam_prep_mentor_assignment_safe_v1(bigint,uuid,text) from public,anon;
grant execute on function public.handover_exam_prep_mentor_assignment_safe_v1(bigint,uuid,text) to authenticated,service_role;

-- Browser learners cannot call operational mentor-management functions unless
-- their authenticated identity actually holds an active governed staff role.
-- Direct private-table writes remain revoked as before.
do $$
begin
  if has_function_privilege('anon','public.pause_exam_prep_mentor_assignment_safe_v1(bigint,text)','EXECUTE')
     or has_function_privilege('anon','public.handover_exam_prep_mentor_assignment_safe_v1(bigint,uuid,text)','EXECUTE') then
    raise exception 'exam_prep_p2_77_anon_mentor_ops_exposed';
  end if;
end;
$$;

commit;
