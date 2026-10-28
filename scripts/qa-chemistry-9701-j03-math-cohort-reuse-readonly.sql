WITH eligible AS (
 SELECT m.user_id,
 private.iclub_exam_chemistry_p1_math_beta_eligible_v1(m.user_id) AS chemistry_subject_eligible
 FROM private.exam_prep_beta_members m
 JOIN private.exam_prep_beta_cohorts c ON c.id=m.cohort_id
 JOIN private.exam_prep_beta_consents consent ON consent.cohort_id=m.cohort_id AND consent.user_id=m.user_id
 WHERE c.cohort_key='math_as_p1_p5_beta_2026_09_01'
 AND c.program_key='math_as_p1_p5'
 AND m.member_status='active' AND m.activated_at IS NOT NULL
 AND consent.consent_scope='exam_prep_controlled_beta_v1'
 AND consent.consent_status='granted' AND consent.revoked_at IS NULL
)
SELECT
 (SELECT count(*)=3 FROM eligible) AS math_beta_active_three,
 (SELECT count(*)=2 FROM eligible WHERE chemistry_subject_eligible) AS chemistry_subset_two,
 (SELECT count(*)=0 FROM private.iclub_exam_chemistry_p1_beta_members_v1) AS no_real_chemistry_consent_recorded,
 (SELECT count(*)=0 FROM private.iclub_exam_chemistry_p1_live_attempts_v1) AS no_real_chemistry_exam_attempts,
 (SELECT count(*)=0 FROM private.iclub_exam_chemistry_p1_owner_release_items_v1) AS no_paper_items_authorized,
 (SELECT enabled=false FROM private.iclub_exam_chemistry_p1_beta_control_v1 WHERE id=1) AS chemistry_beta_disabled,
 (SELECT status='draft' AND launch_enabled=false FROM private.iclub_exam_core_programs_v1 WHERE program_key='chemistry_9701') AS program_draft_off,
 (SELECT visible_to_learners=false FROM private.iclub_subject_library WHERE subject_key='chemistry') AS chemistry_hidden,
 (private.iclub_exam_core_native_plan_preflight_v1('chemistry_9701','chemistry_2025_2027_v1')->>'state')='blocked' AS native_core_blocked,
 public.get_my_exam_prep_chemistry_shell_v1('ru')='{}'::jsonb AS no_chemistry_shell_while_off,
 (public.get_my_exam_prep_chemistry_beta_status_v1()->>'can_start')='false' AS no_student_start_available,
 NOT has_function_privilege('anon','public.get_my_exam_prep_chemistry_beta_status_v1()','EXECUTE')
 AND NOT has_function_privilege('anon','public.grant_my_exam_prep_chemistry_consent_v1(text)','EXECUTE')
 AND NOT has_function_privilege('anon','public.revoke_my_exam_prep_chemistry_consent_v1()','EXECUTE')
 AS anonymous_cannot_access_chemistry_optin,
 has_function_privilege('authenticated','public.get_my_exam_prep_chemistry_beta_status_v1()','EXECUTE')
 AND has_function_privilege('authenticated','public.grant_my_exam_prep_chemistry_consent_v1(text)','EXECUTE')
 AND has_function_privilege('authenticated','public.revoke_my_exam_prep_chemistry_consent_v1()','EXECUTE')
 AS authenticated_self_consent_entrypoints_present,
 NOT has_function_privilege('authenticated','private.iclub_exam_chemistry_p1_math_beta_eligible_v1(uuid)','EXECUTE')
 AS internal_beta_eligibility_not_public,
 (SELECT count(*)=26 FROM private.iclub_exam_core_chemistry_p1_quarantine_v1) AS old_twenty_six_variants_intact,
 (SELECT count(*)=45 FROM private.iclub_exam_core_chemistry_p1_secure_drafts_v1) AS private_draft_bank_intact,
 (SELECT count(*)=40 FROM private.iclub_exam_core_chemistry_p1_mock_blueprint_preview_v1 WHERE planning_role='proposed_form') AS closed_p1_40_intact,
 (SELECT count(*)=4 FROM private.iclub_exam_core_chemistry_p1_mock_blueprint_preview_v1 WHERE planning_role='proposed_reserve') AS closed_p1_reserve_intact,
 (SELECT count(*)>=544 FROM private.exam_prep_sessions)
 AND (SELECT count(*)>=1979 FROM private.exam_prep_responses) AS maths_attempts_answers_intact,
 (SELECT count(*)>=502 FROM public.practice_attempts)
 AND (SELECT count(*)>=4816 FROM public.practice_answers) AS practice_attempts_answers_intact,
 (SELECT count(*)>=2098 FROM public.user_subjects) AS learner_subject_choices_intact;