begin;

-- P2-58: narrowly governed cleanup of learner-scoped synthetic Exam Prep data.
-- This does not arm real monitoring and does not touch beta membership, consent,
-- entitlements, legacy Practice/Tours, ratings, certificates or public users.
--
-- Periodic safety re-audit found that learner-scoped audit rows and child rows
-- were not part of the original residue total. The cleanup gate now counts and
-- proves removal of those rows too, while preserving audit history for the
-- beta membership / consent / entitlement controls that survive the cleanup.

create or replace function private.exam_prep_audit_row_change_v1()
returns trigger
language plpgsql
security definer
set search_path to ''
as $$
declare
  v_before jsonb;
  v_after jsonb;
  v_actor_text text;
  v_target_text text;
  v_component text;
  v_object_id text;
  v_program_key text;
begin
  -- Row-level delete/update audit events for synthetic fixtures would themselves
  -- become synthetic residue. During the service-role-only governed cleanup we
  -- suppress those per-row events and emit one explicit cleanup summary later.
  if current_setting('iclub.exam_prep_synthetic_cleanup', true)='on' then
    return null;
  end if;

  if tg_op = 'INSERT' then v_before := null; v_after := to_jsonb(new);
  elsif tg_op = 'UPDATE' then v_before := to_jsonb(old); v_after := to_jsonb(new);
  else v_before := to_jsonb(old); v_after := null; end if;

  v_actor_text := coalesce(v_after->>'updated_by', v_after->>'created_by', v_before->>'updated_by', v_before->>'created_by');
  v_target_text := coalesce(v_after->>'user_id', v_after->>'learner_user_id', v_before->>'user_id', v_before->>'learner_user_id');
  v_component := coalesce(v_after->>'component_code', v_after->>'target_component_code', v_after->>'owner_component_code', v_before->>'component_code', v_before->>'target_component_code', v_before->>'owner_component_code');
  v_object_id := coalesce(v_after->>'id', v_after->>'program_key', v_after->>'user_id', v_after->>'learner_user_id', v_after->>'skill_code', v_after->>'prerequisite_code', v_after->>'mixed_code', v_before->>'id', v_before->>'program_key', v_before->>'user_id', v_before->>'learner_user_id', v_before->>'skill_code', v_before->>'prerequisite_code', v_before->>'mixed_code');
  v_program_key := coalesce(v_after->>'program_key', v_before->>'program_key', 'math_as_p1_p5');

  insert into private.exam_prep_audit_events(
    program_key, actor_user_id, actor_role, event_type, object_type, object_id,
    target_user_id, component_code, before_state, after_state, metadata
  )
  values(
    v_program_key,
    coalesce(nullif(v_actor_text, '')::uuid, auth.uid()),
    coalesce(auth.role(), session_user),
    lower(tg_op),
    tg_table_schema || '.' || tg_table_name,
    v_object_id,
    nullif(v_target_text, '')::uuid,
    case when v_component in ('P1','P5') then v_component else null end,
    v_before,
    v_after,
    jsonb_build_object('trigger', tg_name)
  );
  return null;
end;
$$;

create or replace function private.exam_prep_beta_synthetic_residue_v2(p_cohort_id bigint)
returns jsonb
language plpgsql
stable security definer
set search_path=''
as $$
declare
  v_counts jsonb;
  v_total int:=0;
begin
  if not exists(select 1 from private.exam_prep_beta_cohorts c where c.id=p_cohort_id) then
    raise exception 'exam_prep_beta_cohort_not_found' using errcode='P0002';
  end if;

  select jsonb_build_object(
    'ai_audit',(select count(*) from private.exam_prep_ai_audit x join private.exam_prep_beta_members bm on bm.user_id=x.user_id and bm.cohort_id=p_cohort_id where bm.member_status='active'),
    'ai_daily_usage',(select count(*) from private.exam_prep_ai_daily_usage x join private.exam_prep_beta_members bm on bm.user_id=x.user_id and bm.cohort_id=p_cohort_id where bm.member_status='active'),
    'audit_events',(
      select count(*)
      from private.exam_prep_audit_events x
      where x.object_type = any(array[
        'private.exam_prep_correction_cases',
        'private.exam_prep_exam_appointments',
        'private.exam_prep_exam_map_revisions',
        'private.exam_prep_exam_ops_confirmations',
        'private.exam_prep_exam_profiles',
        'private.exam_prep_legacy_evidence_references',
        'private.exam_prep_mentor_assignments',
        'private.exam_prep_mentor_queue_items',
        'private.exam_prep_mentor_service_status',
        'private.exam_prep_progress_revalidation_cases',
        'private.exam_prep_recovery_cases',
        'private.exam_prep_retest_events',
        'private.exam_prep_safeguarding_events',
        'private.exam_prep_session_authorizations',
        'private.exam_prep_sessions'
      ]::text[])
      and exists(
        select 1
        from private.exam_prep_beta_members bm
        where bm.cohort_id=p_cohort_id
          and bm.member_status='active'
          and (bm.user_id=x.target_user_id or bm.user_id=x.actor_user_id)
      )
    ),
    'component_access_gates',(select count(*) from private.exam_prep_component_access_gates x join private.exam_prep_beta_members bm on bm.user_id=x.user_id and bm.cohort_id=p_cohort_id where bm.member_status='active'),
    'component_placements',(select count(*) from private.exam_prep_component_placements x join private.exam_prep_beta_members bm on bm.user_id=x.user_id and bm.cohort_id=p_cohort_id where bm.member_status='active'),
    'correction_actions',(select count(*) from private.exam_prep_correction_actions x join private.exam_prep_beta_members bm on bm.user_id=x.user_id and bm.cohort_id=p_cohort_id where bm.member_status='active'),
    'correction_cases',(select count(*) from private.exam_prep_correction_cases x join private.exam_prep_beta_members bm on bm.user_id=x.user_id and bm.cohort_id=p_cohort_id where bm.member_status='active'),
    'evidence_events',(select count(*) from private.exam_prep_evidence_events x join private.exam_prep_beta_members bm on bm.user_id=x.user_id and bm.cohort_id=p_cohort_id where bm.member_status='active'),
    'exam_appointments',(select count(*) from private.exam_prep_exam_appointments x join private.exam_prep_beta_members bm on bm.user_id=x.user_id and bm.cohort_id=p_cohort_id where bm.member_status='active'),
    'exam_map_revisions',(select count(*) from private.exam_prep_exam_map_revisions x join private.exam_prep_beta_members bm on bm.user_id=x.user_id and bm.cohort_id=p_cohort_id where bm.member_status='active'),
    'exam_ops_confirmations',(select count(*) from private.exam_prep_exam_ops_confirmations x join private.exam_prep_beta_members bm on bm.user_id=x.user_id and bm.cohort_id=p_cohort_id where bm.member_status='active'),
    'exam_profiles',(select count(*) from private.exam_prep_exam_profiles x join private.exam_prep_beta_members bm on bm.user_id=x.user_id and bm.cohort_id=p_cohort_id where bm.member_status='active'),
    'human_review_recommendations',(select count(*) from private.exam_prep_human_review_recommendations x join private.exam_prep_beta_members bm on bm.user_id=x.learner_user_id and bm.cohort_id=p_cohort_id where bm.member_status='active'),
    'integrity_events',(select count(*) from private.exam_prep_integrity_events x join private.exam_prep_beta_members bm on bm.user_id=x.user_id and bm.cohort_id=p_cohort_id where bm.member_status='active'),
    'legacy_evidence_references',(select count(*) from private.exam_prep_legacy_evidence_references x join private.exam_prep_beta_members bm on bm.user_id=x.user_id and bm.cohort_id=p_cohort_id where bm.member_status='active'),
    'mentor_assignments',(select count(*) from private.exam_prep_mentor_assignments x join private.exam_prep_beta_members bm on bm.user_id=x.learner_user_id and bm.cohort_id=p_cohort_id where bm.member_status='active'),
    'mentor_queue_items',(select count(*) from private.exam_prep_mentor_queue_items x join private.exam_prep_beta_members bm on bm.user_id=x.learner_user_id and bm.cohort_id=p_cohort_id where bm.member_status='active'),
    'mentor_reviews',(select count(*) from private.exam_prep_mentor_reviews x join private.exam_prep_beta_members bm on bm.user_id=x.learner_user_id and bm.cohort_id=p_cohort_id where bm.member_status='active'),
    'mentor_second_checks',(
      select count(*) from private.exam_prep_mentor_second_checks x
      where exists(
        select 1 from private.exam_prep_mentor_reviews r
        join private.exam_prep_beta_members bm on bm.user_id=r.learner_user_id and bm.cohort_id=p_cohort_id and bm.member_status='active'
        where r.id=x.review_id
      ) or exists(
        select 1 from private.exam_prep_mentor_queue_items q
        join private.exam_prep_beta_members bm on bm.user_id=q.learner_user_id and bm.cohort_id=p_cohort_id and bm.member_status='active'
        where q.id=x.queue_item_id
      )
    ),
    'mentor_service_status',(select count(*) from private.exam_prep_mentor_service_status x join private.exam_prep_beta_members bm on bm.user_id=x.learner_user_id and bm.cohort_id=p_cohort_id where bm.member_status='active'),
    'prerequisite_states',(select count(*) from private.exam_prep_prerequisite_states x join private.exam_prep_beta_members bm on bm.user_id=x.user_id and bm.cohort_id=p_cohort_id where bm.member_status='active'),
    'progress_revalidation_cases',(select count(*) from private.exam_prep_progress_revalidation_cases x join private.exam_prep_beta_members bm on bm.user_id=x.user_id and bm.cohort_id=p_cohort_id where bm.member_status='active'),
    'progress_revalidation_items',(
      select count(*) from private.exam_prep_progress_revalidation_items x
      join private.exam_prep_progress_revalidation_cases c on c.id=x.case_id
      join private.exam_prep_beta_members bm on bm.user_id=c.user_id and bm.cohort_id=p_cohort_id
      where bm.member_status='active'
    ),
    'readiness_signoffs',(select count(*) from private.exam_prep_readiness_signoffs x join private.exam_prep_beta_members bm on bm.user_id=x.learner_user_id and bm.cohort_id=p_cohort_id where bm.member_status='active'),
    'recovery_cases',(select count(*) from private.exam_prep_recovery_cases x join private.exam_prep_beta_members bm on bm.user_id=x.user_id and bm.cohort_id=p_cohort_id where bm.member_status='active'),
    'responses',(select count(*) from private.exam_prep_responses x join private.exam_prep_beta_members bm on bm.user_id=x.user_id and bm.cohort_id=p_cohort_id where bm.member_status='active'),
    'retest_events',(select count(*) from private.exam_prep_retest_events x join private.exam_prep_beta_members bm on bm.user_id=x.user_id and bm.cohort_id=p_cohort_id where bm.member_status='active'),
    'safeguarding_events',(select count(*) from private.exam_prep_safeguarding_events x join private.exam_prep_beta_members bm on bm.user_id=x.learner_user_id and bm.cohort_id=p_cohort_id where bm.member_status='active'),
    'session_authorizations',(select count(*) from private.exam_prep_session_authorizations x join private.exam_prep_beta_members bm on bm.user_id=x.user_id and bm.cohort_id=p_cohort_id where bm.member_status='active'),
    'session_items',(
      select count(*) from private.exam_prep_session_items x
      join private.exam_prep_sessions s on s.id=x.session_id
      join private.exam_prep_beta_members bm on bm.user_id=s.user_id and bm.cohort_id=p_cohort_id
      where bm.member_status='active'
    ),
    'sessions',(select count(*) from private.exam_prep_sessions x join private.exam_prep_beta_members bm on bm.user_id=x.user_id and bm.cohort_id=p_cohort_id where bm.member_status='active'),
    'skill_states',(select count(*) from private.exam_prep_skill_states x join private.exam_prep_beta_members bm on bm.user_id=x.user_id and bm.cohort_id=p_cohort_id where bm.member_status='active'),
    'stage_states',(select count(*) from private.exam_prep_stage_states x join private.exam_prep_beta_members bm on bm.user_id=x.user_id and bm.cohort_id=p_cohort_id where bm.member_status='active'),
    'timed_attempt_results',(select count(*) from private.exam_prep_timed_attempt_results x join private.exam_prep_beta_members bm on bm.user_id=x.user_id and bm.cohort_id=p_cohort_id where bm.member_status='active'),
    'timed_written_self_marks',(select count(*) from private.exam_prep_timed_written_self_marks x join private.exam_prep_beta_members bm on bm.user_id=x.user_id and bm.cohort_id=p_cohort_id where bm.member_status='active'),
    'weekly_plan_items',(
      select count(*) from private.exam_prep_weekly_plan_items x
      join private.exam_prep_weekly_plans p on p.id=x.plan_id
      join private.exam_prep_beta_members bm on bm.user_id=p.user_id and bm.cohort_id=p_cohort_id
      where bm.member_status='active'
    ),
    'weekly_plans',(select count(*) from private.exam_prep_weekly_plans x join private.exam_prep_beta_members bm on bm.user_id=x.user_id and bm.cohort_id=p_cohort_id where bm.member_status='active')
  ) into v_counts;

  select coalesce(sum(value::int),0)::int into v_total from jsonb_each_text(v_counts);
  return jsonb_build_object('total_rows',v_total,'counts',v_counts);
end;
$$;

revoke all on function private.exam_prep_beta_synthetic_residue_v2(bigint) from public,anon,authenticated;
grant execute on function private.exam_prep_beta_synthetic_residue_v2(bigint) to service_role;

create or replace function private.exam_prep_block_immutable_mutation_v1()
returns trigger
language plpgsql
set search_path to ''
as $$
begin
  if tg_op='DELETE'
     and current_setting('iclub.exam_prep_synthetic_cleanup', true)='on'
  then
    return old;
  end if;

  if tg_op='UPDATE'
     and current_setting('iclub.exam_prep_identity_recovery', true)='on'
     and (to_jsonb(new) - array['user_id','learner_user_id','mentor_user_id','reviewer_user_id','raised_by_user_id','moderator_user_id']::text[])
       = (to_jsonb(old) - array['user_id','learner_user_id','mentor_user_id','reviewer_user_id','raised_by_user_id','moderator_user_id']::text[])
  then
    return new;
  end if;

  raise exception 'immutable_exam_prep_fact';
end;
$$;

revoke all on function private.exam_prep_block_immutable_mutation_v1() from public,anon,authenticated;

create or replace function public.cleanup_exam_prep_beta_synthetic_progress_v1(
  p_cohort_key text,
  p_expected_blocking_rows integer,
  p_cleanup_evidence_ref text,
  p_acknowledgement text
)
returns jsonb
language plpgsql
security definer
set search_path=''
as $$
declare
  v_c private.exam_prep_beta_cohorts%rowtype;
  v_ctl private.exam_prep_beta_expansion_controls%rowtype;
  v_users uuid[];
  v_before jsonb;
  v_after jsonb;
  v_before_total int:=0;
  v_after_total int:=0;
  v_before_controls jsonb;
  v_after_controls jsonb;
  v_before_legacy jsonb;
  v_after_legacy jsonb;
  v_prev_cleanup_marker text:=current_setting('iclub.exam_prep_synthetic_cleanup',true);
begin
  if p_acknowledgement is distinct from 'I_CONFIRM_SYNTHETIC_EXAM_PREP_CLEANUP_V1' then
    raise exception 'exam_prep_cleanup_acknowledgement_required';
  end if;
  if p_cleanup_evidence_ref is null or char_length(trim(p_cleanup_evidence_ref))<8 then
    raise exception 'exam_prep_cleanup_evidence_ref_required';
  end if;
  if p_expected_blocking_rows is null or p_expected_blocking_rows<1 then
    raise exception 'exam_prep_cleanup_expected_blocking_rows_required';
  end if;

  select * into v_c
  from private.exam_prep_beta_cohorts
  where cohort_key=p_cohort_key
  for update;
  if v_c.id is null then raise exception 'exam_prep_beta_cohort_not_found' using errcode='P0002'; end if;
  if v_c.cohort_status<>'canary' then
    raise exception 'exam_prep_cleanup_requires_canary_cohort status=%',v_c.cohort_status;
  end if;

  select * into v_ctl
  from private.exam_prep_beta_expansion_controls
  where cohort_id=v_c.id
  for update;
  if v_ctl.cohort_id is null then raise exception 'exam_prep_expansion_control_missing'; end if;
  if v_ctl.development_data_state<>'synthetic_present' or v_ctl.real_review_epoch_started_at is not null then
    raise exception 'exam_prep_cleanup_bad_development_state=%',v_ctl.development_data_state;
  end if;

  if exists(select 1 from private.exam_prep_beta_weekly_reviews where cohort_id=v_c.id) then
    raise exception 'exam_prep_cleanup_requires_zero_prior_weekly_reviews';
  end if;

  if not exists(
    select 1 from private.exam_prep_feature_config
    where id=1
      and rollout_state='controlled_beta'
      and core_enabled=true
      and ai_enabled=false
      and mentor_enabled=false
      and kill_switch=true
  ) then
    raise exception 'exam_prep_cleanup_requires_controlled_beta_kill_switch';
  end if;

  select array_agg(user_id order by user_id) into v_users
  from private.exam_prep_beta_members
  where cohort_id=v_c.id and member_status='active';
  if coalesce(array_length(v_users,1),0)<1 then
    raise exception 'exam_prep_cleanup_requires_active_beta_members';
  end if;

  if exists(select 1 from private.exam_prep_sessions where user_id=any(v_users) and status='active') then
    raise exception 'exam_prep_cleanup_active_session_present';
  end if;

  if exists(
    select 1 from private.exam_prep_beta_ops_incidents
    where cohort_id=v_c.id
      and status not in ('resolved','closed')
      and severity in ('SEV0','SEV1')
  ) then
    raise exception 'exam_prep_cleanup_blocking_incident_present';
  end if;

  v_before:=private.exam_prep_beta_synthetic_residue_v2(v_c.id);
  v_before_total:=coalesce((v_before->>'total_rows')::int,0);
  if v_before_total<>p_expected_blocking_rows then
    raise exception 'exam_prep_cleanup_snapshot_mismatch expected=% actual=%',p_expected_blocking_rows,v_before_total;
  end if;

  select jsonb_build_object(
    'active_beta_members',(select count(*) from private.exam_prep_beta_members where cohort_id=v_c.id and member_status='active'),
    'consents',(select count(*) from private.exam_prep_beta_consents where cohort_id=v_c.id),
    'feature_entitlements',(select count(*) from private.exam_prep_feature_entitlements e where e.user_id=any(v_users)),
    'control_audit_events',(
      select count(*) from private.exam_prep_audit_events a
      where a.object_type=any(array[
        'private.exam_prep_beta_members',
        'private.exam_prep_beta_consents',
        'private.exam_prep_feature_entitlements'
      ]::text[])
      and (a.target_user_id=any(v_users) or a.actor_user_id=any(v_users))
    )
  ) into v_before_controls;

  select jsonb_build_object(
    'practice_attempts',(select count(*) from public.practice_attempts),
    'practice_answers',(select count(*) from public.practice_answers),
    'tour_attempts',(select count(*) from public.tour_attempts),
    'tour_answers',(select count(*) from public.tour_answers),
    'certificates',(select count(*) from public.certificates),
    'public_users',(select count(*) from public.users)
  ) into v_before_legacy;

  perform set_config('iclub.exam_prep_synthetic_cleanup','on',true);

  -- Break the intentional authorization/session cycle and learner-plan/correction links.
  update private.exam_prep_session_authorizations
  set consumed_session_id=null,
      correction_case_id=null,
      plan_id=null,
      plan_priority_order=null
  where user_id=any(v_users);

  -- Mentor / review graph first.
  delete from private.exam_prep_readiness_signoffs where learner_user_id=any(v_users);
  delete from private.exam_prep_mentor_second_checks sc
  where exists(select 1 from private.exam_prep_mentor_reviews r where r.id=sc.review_id and r.learner_user_id=any(v_users))
     or exists(select 1 from private.exam_prep_mentor_queue_items q where q.id=sc.queue_item_id and q.learner_user_id=any(v_users));
  delete from private.exam_prep_mentor_reviews where learner_user_id=any(v_users);
  delete from private.exam_prep_mentor_queue_items where learner_user_id=any(v_users);
  delete from private.exam_prep_safeguarding_events where learner_user_id=any(v_users);
  delete from private.exam_prep_mentor_service_status where learner_user_id=any(v_users);
  delete from private.exam_prep_mentor_assignments where learner_user_id=any(v_users);
  delete from private.exam_prep_human_review_recommendations where learner_user_id=any(v_users);

  -- Recovery / revalidation children that can point at sessions or authorizations.
  delete from private.exam_prep_progress_revalidation_items i
  using private.exam_prep_progress_revalidation_cases c
  where i.case_id=c.id and c.user_id=any(v_users);
  delete from private.exam_prep_progress_revalidation_cases where user_id=any(v_users);

  -- Timed, correction and planning graphs. Weekly plan items cascade with plans.
  delete from private.exam_prep_timed_written_self_marks where user_id=any(v_users);
  delete from private.exam_prep_timed_attempt_results where user_id=any(v_users);
  delete from private.exam_prep_correction_actions where user_id=any(v_users);
  delete from private.exam_prep_retest_events where user_id=any(v_users);
  delete from private.exam_prep_weekly_plans where user_id=any(v_users);
  delete from private.exam_prep_correction_cases where user_id=any(v_users);

  -- Immutable assessment facts before session parents. Session items cascade with sessions.
  delete from private.exam_prep_evidence_events where user_id=any(v_users);
  delete from private.exam_prep_integrity_events where user_id=any(v_users);
  delete from private.exam_prep_responses where user_id=any(v_users);
  delete from private.exam_prep_sessions where user_id=any(v_users);
  delete from private.exam_prep_session_authorizations where user_id=any(v_users);

  -- Remaining learner-scoped state.
  delete from private.exam_prep_recovery_cases where user_id=any(v_users);
  delete from private.exam_prep_ai_audit where user_id=any(v_users);
  delete from private.exam_prep_ai_daily_usage where user_id=any(v_users);
  delete from private.exam_prep_component_access_gates where user_id=any(v_users);
  delete from private.exam_prep_component_placements where user_id=any(v_users);
  delete from private.exam_prep_exam_appointments where user_id=any(v_users);
  delete from private.exam_prep_exam_map_revisions where user_id=any(v_users);
  delete from private.exam_prep_exam_ops_confirmations where user_id=any(v_users);
  delete from private.exam_prep_exam_profiles where user_id=any(v_users);
  delete from private.exam_prep_legacy_evidence_references where user_id=any(v_users);
  delete from private.exam_prep_prerequisite_states where user_id=any(v_users);
  delete from private.exam_prep_skill_states where user_id=any(v_users);
  delete from private.exam_prep_stage_states where user_id=any(v_users);

  -- Remove only audit rows for synthetic progress objects. Control audit rows for
  -- membership, consent and entitlements are preserved and checked below.
  delete from private.exam_prep_audit_events a
  where a.object_type = any(array[
    'private.exam_prep_correction_cases',
    'private.exam_prep_exam_appointments',
    'private.exam_prep_exam_map_revisions',
    'private.exam_prep_exam_ops_confirmations',
    'private.exam_prep_exam_profiles',
    'private.exam_prep_legacy_evidence_references',
    'private.exam_prep_mentor_assignments',
    'private.exam_prep_mentor_queue_items',
    'private.exam_prep_mentor_service_status',
    'private.exam_prep_progress_revalidation_cases',
    'private.exam_prep_recovery_cases',
    'private.exam_prep_retest_events',
    'private.exam_prep_safeguarding_events',
    'private.exam_prep_session_authorizations',
    'private.exam_prep_sessions'
  ]::text[])
  and (a.target_user_id=any(v_users) or a.actor_user_id=any(v_users));

  if v_prev_cleanup_marker is null then
    perform set_config('iclub.exam_prep_synthetic_cleanup','',true);
  else
    perform set_config('iclub.exam_prep_synthetic_cleanup',v_prev_cleanup_marker,true);
  end if;

  v_after:=private.exam_prep_beta_synthetic_residue_v2(v_c.id);
  v_after_total:=coalesce((v_after->>'total_rows')::int,0);
  if v_after_total<>0 then
    raise exception 'exam_prep_cleanup_incomplete rows=% counts=%',v_after_total,v_after->'counts';
  end if;

  select jsonb_build_object(
    'active_beta_members',(select count(*) from private.exam_prep_beta_members where cohort_id=v_c.id and member_status='active'),
    'consents',(select count(*) from private.exam_prep_beta_consents where cohort_id=v_c.id),
    'feature_entitlements',(select count(*) from private.exam_prep_feature_entitlements e where e.user_id=any(v_users)),
    'control_audit_events',(
      select count(*) from private.exam_prep_audit_events a
      where a.object_type=any(array[
        'private.exam_prep_beta_members',
        'private.exam_prep_beta_consents',
        'private.exam_prep_feature_entitlements'
      ]::text[])
      and (a.target_user_id=any(v_users) or a.actor_user_id=any(v_users))
    )
  ) into v_after_controls;
  if v_after_controls<>v_before_controls then
    raise exception 'exam_prep_cleanup_control_state_changed before=% after=%',v_before_controls,v_after_controls;
  end if;

  select jsonb_build_object(
    'practice_attempts',(select count(*) from public.practice_attempts),
    'practice_answers',(select count(*) from public.practice_answers),
    'tour_attempts',(select count(*) from public.tour_attempts),
    'tour_answers',(select count(*) from public.tour_answers),
    'certificates',(select count(*) from public.certificates),
    'public_users',(select count(*) from public.users)
  ) into v_after_legacy;
  if v_after_legacy<>v_before_legacy then
    raise exception 'exam_prep_cleanup_legacy_state_changed before=% after=%',v_before_legacy,v_after_legacy;
  end if;

  update private.exam_prep_beta_expansion_controls
  set development_data_state='clean',
      cleanup_evidence_ref=trim(p_cleanup_evidence_ref),
      updated_at=now()
  where cohort_id=v_c.id;

  insert into private.exam_prep_audit_events(
    program_key,actor_user_id,actor_role,event_type,object_type,object_id,metadata
  ) values(
    'math_as_p1_p5',auth.uid(),'service_role','beta_synthetic_progress_cleaned',
    'private.exam_prep_beta_expansion_controls',v_c.id::text,
    jsonb_build_object(
      'cohort_key',p_cohort_key,
      'cleanup_evidence_ref',trim(p_cleanup_evidence_ref),
      'before_blocking_rows',v_before_total,
      'before_counts',coalesce(v_before->'counts','{}'::jsonb),
      'after_blocking_rows',v_after_total,
      'preserved_controls',v_after_controls,
      'preserved_legacy',v_after_legacy
    )
  );

  return jsonb_build_object(
    'cohort_key',p_cohort_key,
    'development_data_state','clean',
    'cleanup_evidence_ref',trim(p_cleanup_evidence_ref),
    'before_blocking_rows',v_before_total,
    'after_blocking_rows',v_after_total,
    'before_counts',coalesce(v_before->'counts','{}'::jsonb),
    'preserved_controls',v_after_controls,
    'preserved_legacy',v_after_legacy,
    'real_monitoring_armed',false
  );
exception
  when others then
    begin
      if v_prev_cleanup_marker is null then
        perform set_config('iclub.exam_prep_synthetic_cleanup','',true);
      else
        perform set_config('iclub.exam_prep_synthetic_cleanup',v_prev_cleanup_marker,true);
      end if;
    exception when others then null; end;
    raise;
end;
$$;

revoke all on function public.cleanup_exam_prep_beta_synthetic_progress_v1(text,integer,text,text) from public,anon,authenticated;
grant execute on function public.cleanup_exam_prep_beta_synthetic_progress_v1(text,integer,text,text) to service_role;

commit;
