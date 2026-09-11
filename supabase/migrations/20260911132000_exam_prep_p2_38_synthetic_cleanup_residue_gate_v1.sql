begin;

-- P2-38: real monitoring may start only after every learner-scoped synthetic
-- Exam Prep row is gone. Cohort membership, consent and entitlement are control
-- records and intentionally survive the cleanup boundary.

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
    'legacy_evidence_references',(select count(*) from private.exam_prep_legacy_evidence_references x join private.exam_prep_beta_members bm on bm.user_id=x.user_id and bm.cohort_id=p_cohort_id where bm.member_status='active'),
    'mentor_assignments',(select count(*) from private.exam_prep_mentor_assignments x join private.exam_prep_beta_members bm on bm.user_id=x.learner_user_id and bm.cohort_id=p_cohort_id where bm.member_status='active'),
    'mentor_queue_items',(select count(*) from private.exam_prep_mentor_queue_items x join private.exam_prep_beta_members bm on bm.user_id=x.learner_user_id and bm.cohort_id=p_cohort_id where bm.member_status='active'),
    'mentor_reviews',(select count(*) from private.exam_prep_mentor_reviews x join private.exam_prep_beta_members bm on bm.user_id=x.learner_user_id and bm.cohort_id=p_cohort_id where bm.member_status='active'),
    'mentor_service_status',(select count(*) from private.exam_prep_mentor_service_status x join private.exam_prep_beta_members bm on bm.user_id=x.learner_user_id and bm.cohort_id=p_cohort_id where bm.member_status='active'),
    'prerequisite_states',(select count(*) from private.exam_prep_prerequisite_states x join private.exam_prep_beta_members bm on bm.user_id=x.user_id and bm.cohort_id=p_cohort_id where bm.member_status='active'),
    'progress_revalidation_cases',(select count(*) from private.exam_prep_progress_revalidation_cases x join private.exam_prep_beta_members bm on bm.user_id=x.user_id and bm.cohort_id=p_cohort_id where bm.member_status='active'),
    'readiness_signoffs',(select count(*) from private.exam_prep_readiness_signoffs x join private.exam_prep_beta_members bm on bm.user_id=x.learner_user_id and bm.cohort_id=p_cohort_id where bm.member_status='active'),
    'recovery_cases',(select count(*) from private.exam_prep_recovery_cases x join private.exam_prep_beta_members bm on bm.user_id=x.user_id and bm.cohort_id=p_cohort_id where bm.member_status='active'),
    'responses',(select count(*) from private.exam_prep_responses x join private.exam_prep_beta_members bm on bm.user_id=x.user_id and bm.cohort_id=p_cohort_id where bm.member_status='active'),
    'retest_events',(select count(*) from private.exam_prep_retest_events x join private.exam_prep_beta_members bm on bm.user_id=x.user_id and bm.cohort_id=p_cohort_id where bm.member_status='active'),
    'safeguarding_events',(select count(*) from private.exam_prep_safeguarding_events x join private.exam_prep_beta_members bm on bm.user_id=x.learner_user_id and bm.cohort_id=p_cohort_id where bm.member_status='active'),
    'session_authorizations',(select count(*) from private.exam_prep_session_authorizations x join private.exam_prep_beta_members bm on bm.user_id=x.user_id and bm.cohort_id=p_cohort_id where bm.member_status='active'),
    'sessions',(select count(*) from private.exam_prep_sessions x join private.exam_prep_beta_members bm on bm.user_id=x.user_id and bm.cohort_id=p_cohort_id where bm.member_status='active'),
    'skill_states',(select count(*) from private.exam_prep_skill_states x join private.exam_prep_beta_members bm on bm.user_id=x.user_id and bm.cohort_id=p_cohort_id where bm.member_status='active'),
    'stage_states',(select count(*) from private.exam_prep_stage_states x join private.exam_prep_beta_members bm on bm.user_id=x.user_id and bm.cohort_id=p_cohort_id where bm.member_status='active'),
    'timed_attempt_results',(select count(*) from private.exam_prep_timed_attempt_results x join private.exam_prep_beta_members bm on bm.user_id=x.user_id and bm.cohort_id=p_cohort_id where bm.member_status='active'),
    'timed_written_self_marks',(select count(*) from private.exam_prep_timed_written_self_marks x join private.exam_prep_beta_members bm on bm.user_id=x.user_id and bm.cohort_id=p_cohort_id where bm.member_status='active'),
    'weekly_plans',(select count(*) from private.exam_prep_weekly_plans x join private.exam_prep_beta_members bm on bm.user_id=x.user_id and bm.cohort_id=p_cohort_id where bm.member_status='active')
  ) into v_counts;

  select coalesce(sum(value::int),0)::int into v_total from jsonb_each_text(v_counts);
  return jsonb_build_object('total_rows',v_total,'counts',v_counts);
end;
$$;
revoke all on function private.exam_prep_beta_synthetic_residue_v2(bigint) from public,anon,authenticated;
grant execute on function private.exam_prep_beta_synthetic_residue_v2(bigint) to service_role;

create or replace function public.get_exam_prep_beta_cleanup_readiness_v1(p_cohort_key text)
returns jsonb
language plpgsql
stable security definer
set search_path=''
as $$
declare
  v_c private.exam_prep_beta_cohorts%rowtype;
  v_r jsonb;
begin
  select * into v_c from private.exam_prep_beta_cohorts where cohort_key=p_cohort_key;
  if v_c.id is null then raise exception 'exam_prep_beta_cohort_not_found' using errcode='P0002'; end if;
  v_r:=private.exam_prep_beta_synthetic_residue_v2(v_c.id);
  return jsonb_build_object(
    'cohort_key',p_cohort_key,
    'ready_to_arm',coalesce((v_r->>'total_rows')::int,0)=0,
    'blocking_rows',coalesce((v_r->>'total_rows')::int,0),
    'blocking_counts',coalesce(v_r->'counts','{}'::jsonb),
    'preserved_controls',jsonb_build_object(
      'active_beta_members',(select count(*) from private.exam_prep_beta_members bm where bm.cohort_id=v_c.id and bm.member_status='active'),
      'consents',(select count(*) from private.exam_prep_beta_consents x where x.cohort_id=v_c.id),
      'feature_entitlements',(select count(*) from private.exam_prep_feature_entitlements e join private.exam_prep_beta_members bm on bm.user_id=e.user_id and bm.cohort_id=v_c.id where bm.member_status='active')
    )
  );
end;
$$;
revoke all on function public.get_exam_prep_beta_cleanup_readiness_v1(text) from public,anon,authenticated;
grant execute on function public.get_exam_prep_beta_cleanup_readiness_v1(text) to service_role;

create or replace function public.arm_exam_prep_beta_real_monitoring_v1(p_cohort_key text,p_cleanup_evidence_ref text)
returns jsonb
language plpgsql
security definer
set search_path=''
as $$
declare
  v_c private.exam_prep_beta_cohorts%rowtype;
  v_ctl private.exam_prep_beta_expansion_controls%rowtype;
  v_residue jsonb;
  v_residue_total int:=0;
  v_now timestamptz:=now();
begin
  if p_cleanup_evidence_ref is null or char_length(trim(p_cleanup_evidence_ref))<8 then raise exception 'exam_prep_cleanup_evidence_ref_required'; end if;
  select * into v_c from private.exam_prep_beta_cohorts where cohort_key=p_cohort_key for update;
  if v_c.id is null then raise exception 'exam_prep_beta_cohort_not_found' using errcode='P0002'; end if;

  select * into v_ctl from private.exam_prep_beta_expansion_controls where cohort_id=v_c.id for update;
  if v_ctl.cohort_id is null then raise exception 'exam_prep_expansion_control_missing'; end if;
  if v_ctl.development_data_state='real_monitoring' or v_ctl.real_review_epoch_started_at is not null then
    raise exception 'exam_prep_real_monitoring_already_armed';
  end if;
  if v_ctl.development_data_state not in ('synthetic_present','clean') then
    raise exception 'exam_prep_real_monitoring_bad_development_state=%',v_ctl.development_data_state;
  end if;
  if exists(select 1 from private.exam_prep_beta_weekly_reviews r where r.cohort_id=v_c.id) then
    raise exception 'exam_prep_real_monitoring_requires_zero_prior_weekly_reviews';
  end if;

  v_residue:=private.exam_prep_beta_synthetic_residue_v2(v_c.id);
  v_residue_total:=coalesce((v_residue->>'total_rows')::int,0);
  if v_residue_total<>0 then
    raise exception 'exam_prep_synthetic_progress_cleanup_incomplete rows=%',v_residue_total;
  end if;

  update private.exam_prep_beta_expansion_controls
  set development_data_state='real_monitoring',
      real_review_epoch_started_at=v_now,
      cleanup_evidence_ref=trim(p_cleanup_evidence_ref),
      updated_at=v_now
  where cohort_id=v_c.id;

  insert into private.exam_prep_audit_events(
    program_key,actor_user_id,actor_role,event_type,object_type,object_id,metadata
  ) values(
    'math_as_p1_p5',auth.uid(),'service_role','beta_real_monitoring_armed',
    'private.exam_prep_beta_expansion_controls',v_c.id::text,
    jsonb_build_object(
      'cohort_key',p_cohort_key,
      'cleanup_evidence_ref',trim(p_cleanup_evidence_ref),
      'synthetic_progress_rows',v_residue_total,
      'blocking_counts',coalesce(v_residue->'counts','{}'::jsonb)
    )
  );

  return jsonb_build_object(
    'cohort_key',p_cohort_key,
    'development_data_state','real_monitoring',
    'real_review_epoch_started_at',v_now,
    'synthetic_progress_rows',v_residue_total
  );
end;
$$;
revoke all on function public.arm_exam_prep_beta_real_monitoring_v1(text,text) from public,anon,authenticated;
grant execute on function public.arm_exam_prep_beta_real_monitoring_v1(text,text) to service_role;

commit;
