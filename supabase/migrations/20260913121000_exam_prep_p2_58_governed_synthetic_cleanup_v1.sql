begin;

-- P2-58: narrowly governed cleanup of learner-scoped synthetic Exam Prep data.
-- This does not arm real monitoring and does not touch beta membership, consent,
-- entitlements, legacy Practice/Tours, ratings, certificates or public users.

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
    'feature_entitlements',(select count(*) from private.exam_prep_feature_entitlements e where e.user_id=any(v_users))
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

  -- Timed, correction and planning graphs.
  delete from private.exam_prep_timed_written_self_marks where user_id=any(v_users);
  delete from private.exam_prep_timed_attempt_results where user_id=any(v_users);
  delete from private.exam_prep_correction_actions where user_id=any(v_users);
  delete from private.exam_prep_retest_events where user_id=any(v_users);
  delete from private.exam_prep_weekly_plans where user_id=any(v_users);
  delete from private.exam_prep_correction_cases where user_id=any(v_users);

  -- Immutable assessment facts before session parents.
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
    'feature_entitlements',(select count(*) from private.exam_prep_feature_entitlements e where e.user_id=any(v_users))
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
