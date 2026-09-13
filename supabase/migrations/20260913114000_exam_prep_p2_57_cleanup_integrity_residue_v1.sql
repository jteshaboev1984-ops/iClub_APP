begin;

-- P2-57: the P2-38 synthetic-residue gate predates protected-assessment
-- integrity events. Real monitoring must also stay blocked while any synthetic
-- integrity event belongs to an active beta learner.
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
    'integrity_events',(select count(*) from private.exam_prep_integrity_events x join private.exam_prep_beta_members bm on bm.user_id=x.user_id and bm.cohort_id=p_cohort_id where bm.member_status='active'),
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

commit;
