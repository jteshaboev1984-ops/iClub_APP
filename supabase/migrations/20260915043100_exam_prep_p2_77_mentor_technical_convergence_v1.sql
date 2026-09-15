begin;

-- P2-77 convergence hardening.
-- Keeps the backward-compatible isolation-report key while distinguishing
-- synthetic staff actors from total role grants, and removes transaction-time
-- edges from assignment handover.

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
        select count(distinct s.user_id)
        from private.exam_prep_synthetic_identities s
        join private.exam_prep_staff_roles sr on sr.user_id=s.user_id
      )::int as synthetic_staff_actor_count,
      (
        select count(*)
        from private.exam_prep_synthetic_identities s
        join private.exam_prep_staff_roles sr on sr.user_id=s.user_id
      )::int as synthetic_staff_role_grants,
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
    -- Backward-compatible key: from P2-77 this represents distinct governed
    -- synthetic staff actors. The exact grant count is exposed separately.
    'synthetic_staff_role_rows',synthetic_staff_actor_count,
    'synthetic_staff_actor_count',synthetic_staff_actor_count,
    'synthetic_staff_role_grants',synthetic_staff_role_grants,
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
  v_effective_at timestamptz:=now();
  v_handover_at timestamptz:=clock_timestamp();
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

  -- The old row must close strictly after its valid_from to satisfy the row
  -- constraint, even when create+handover happen in one transaction. The new
  -- active row uses transaction-stable now() so active-assignment readers in the
  -- same transaction can see the replacement immediately. Status='ended' on the
  -- old row prevents any active-authority overlap.
  v_handover_at:=greatest(v_handover_at,v_old.valid_from + interval '1 microsecond');

  update private.exam_prep_mentor_assignments
  set assignment_status='ended',
      valid_until=case when valid_until is null then v_handover_at else greatest(valid_until,v_handover_at) end,
      updated_at=v_handover_at,updated_by=v_uid
  where id=v_old.id;

  insert into private.exam_prep_mentor_assignments(
    learner_user_id,mentor_user_id,component_code,assignment_status,valid_from,created_by,updated_by
  ) values(
    v_old.learner_user_id,p_new_mentor_user_id,v_old.component_code,'active',v_effective_at,v_uid,v_uid
  ) returning id into v_new_assignment;

  update private.exam_prep_mentor_queue_items
  set assignment_id=v_new_assignment,
      mentor_user_id=p_new_mentor_user_id,
      status='open',
      updated_at=v_handover_at
  where assignment_id=v_old.id
    and status in ('open','in_review');
  get diagnostics v_moved=row_count;

  insert into private.exam_prep_mentor_service_status(
    learner_user_id,service_status,status_reason,status_changed_at,created_by,updated_at,updated_by
  ) values(
    v_old.learner_user_id,'assigned_active',trim(p_reason_text),v_handover_at,v_uid,v_handover_at,v_uid
  )
  on conflict(learner_user_id) do update
  set service_status='assigned_active',status_reason=excluded.status_reason,status_changed_at=v_handover_at,updated_at=v_handover_at,updated_by=v_uid;

  insert into private.exam_prep_audit_events(
    program_key,actor_user_id,actor_role,event_type,object_type,object_id,target_user_id,component_code,before_state,after_state,metadata
  ) values(
    'math_as_p1_p5',v_uid,'mentor_ops','mentor_assignment_handover','private.exam_prep_mentor_assignments',v_new_assignment::text,
    v_old.learner_user_id,v_old.component_code,to_jsonb(v_old),
    (select to_jsonb(a) from private.exam_prep_mentor_assignments a where a.id=v_new_assignment),
    jsonb_build_object('reason',trim(p_reason_text),'old_assignment_id',v_old.id,'new_assignment_id',v_new_assignment,
                       'old_mentor_user_id',v_old.mentor_user_id,'new_mentor_user_id',p_new_mentor_user_id,
                       'moved_open_queue_items',v_moved,'effective_at',v_effective_at,'handover_at',v_handover_at)
  );

  return jsonb_build_object(
    'old_assignment_id',v_old.id,'new_assignment_id',v_new_assignment,
    'learner_user_id',v_old.learner_user_id,'component_code',v_old.component_code,
    'old_mentor_user_id',v_old.mentor_user_id,'new_mentor_user_id',p_new_mentor_user_id,
    'moved_open_queue_items',v_moved,'assignment_status','active',
    'effective_at',v_effective_at,'handover_at',v_handover_at
  );
end;
$$;
revoke all on function public.handover_exam_prep_mentor_assignment_safe_v1(bigint,uuid,text) from public,anon;
grant execute on function public.handover_exam_prep_mentor_assignment_safe_v1(bigint,uuid,text) to authenticated,service_role;

commit;
