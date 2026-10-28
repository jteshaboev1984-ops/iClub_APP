-- J07 Chemistry 9701: read-only closed entry-check QA.
-- No question stems/keys are returned; no write, no synthetic session persists.
SELECT
(SELECT COUNT(*)=22 FROM private.iclub_exam_chemistry_entry_items_v1) AS entry_originals_22,
(SELECT COUNT(DISTINCT syllabus_unit)=22 FROM private.iclub_exam_chemistry_entry_items_v1) AS all_22_AS_units,
(SELECT COUNT(*)=22 FROM private.iclub_exam_chemistry_entry_items_v1
 WHERE review_status='internal_ai_reviewed' AND reviewer_type='internal_ai'
 AND can_issue_learner=false AND can_grade_mastery=false AND can_be_p1_paper=false)
 AS entire_entry_bank_is_AI_only_and_unreleased,
(SELECT COUNT(*)=154 FROM private.iclub_exam_chemistry_entry_review_v1) AS review_gates_154,
(SELECT COUNT(*)=154 FROM private.iclub_exam_chemistry_entry_review_v1
 WHERE verdict='internal_ai_pass' AND reviewer_type='internal_ai'
 AND reviewed_at IS NOT NULL) AS reviewed_gates_AI_only,
(SELECT COUNT(*)=0 FROM private.iclub_exam_chemistry_entry_review_v1 q
 JOIN private.iclub_exam_chemistry_entry_items_v1 d ON d.id=q.item_id
 WHERE q.snapshot_md5<>d.item_md5) AS snapshots_all_current,
(SELECT COUNT(*)=22 FROM private.iclub_exam_chemistry_entry_preflight_v1
 WHERE seven_AI_gates AND different_from_P1_selected_skill
 AND different_from_P1_english_stem AND strictly_unreleased) AS preflight_22_22,
(SELECT COUNT(*)=22 FROM private.iclub_exam_chemistry_entry_study_links_v1
 WHERE syllabus_skill_link AND seven_review_gates
 AND trilingual_theory_link AND trilingual_tutor_link AND unreleased
 AND distinct_from_exam_blueprint) AS all_skills_have_trilingual_theory_and_tutor,
(SELECT COUNT(*)=0 FROM private.iclub_exam_chemistry_entry_shadow_v1)
 AS zero_persisted_synthetic_entry_attempts,
(SELECT COUNT(*)=0 FROM private.iclub_exam_chemistry_p1_live_attempts_v1)
 AS zero_real_Chemistry_P1_attempts,
(SELECT COUNT(*)=0 FROM private.iclub_exam_chemistry_p1_shadow_sessions_v1)
 AS zero_synthetic_P1_attempts,
(SELECT COUNT(*)=0 FROM private.iclub_exam_chemistry_p1_beta_members_v1)
 AS zero_Chemistry_student_optins,
(SELECT COUNT(*)=0 FROM private.iclub_exam_chemistry_p1_owner_release_items_v1)
 AS zero_content_release_approvals,
(SELECT status='draft' AND launch_enabled=false FROM private.iclub_exam_core_programs_v1
 WHERE program_key='chemistry_9701') AS Chemistry_draft_OFF,
(SELECT enabled=false FROM private.iclub_exam_chemistry_p1_beta_control_v1 WHERE id=1)
 AS Chemistry_beta_OFF,
(SELECT visible_to_learners=false FROM private.iclub_subject_library WHERE subject_key='chemistry')
 AS Chemistry_library_hidden,
(SELECT COUNT(*)=40 FROM private.iclub_exam_core_chemistry_p1_mock_blueprint_preview_v1
 WHERE planning_role='proposed_form') AS Paper_1_original_40_untouched,
(SELECT COUNT(*)=4 FROM private.iclub_exam_core_chemistry_p1_mock_blueprint_preview_v1
 WHERE planning_role='proposed_reserve') AS Paper_1_reserve_4_untouched,
(SELECT COUNT(*)=45 FROM private.iclub_exam_core_chemistry_p1_secure_drafts_v1) AS original_P1_bank_45_untouched,
(SELECT COUNT(*)=26 FROM private.iclub_exam_core_chemistry_p1_quarantine_v1) AS prior_26_originals_retained,
(SELECT COUNT(*)>=544 FROM private.exam_prep_sessions) AS math_sessions_preserved,
(SELECT COUNT(*)>=1979 FROM private.exam_prep_responses) AS math_answers_preserved,
(SELECT COUNT(*)>=1 FROM private.iclub_exam_native_mcq_attempts_v1) AS Economics_history_preserved,
(SELECT COUNT(*)>=502 FROM public.practice_attempts) AS practice_attempts_preserved,
(SELECT COUNT(*)>=4816 FROM public.practice_answers) AS practice_answers_preserved,
(SELECT COUNT(*)>=2098 FROM public.user_subjects) AS subject_choices_preserved,
(SELECT relrowsecurity AND relforcerowsecurity FROM pg_class
 WHERE oid='private.iclub_exam_chemistry_entry_items_v1'::regclass)
 AND (SELECT relrowsecurity AND relforcerowsecurity FROM pg_class
 WHERE oid='private.iclub_exam_chemistry_entry_review_v1'::regclass)
 AND (SELECT relrowsecurity AND relforcerowsecurity FROM pg_class
 WHERE oid='private.iclub_exam_chemistry_entry_shadow_v1'::regclass)
 AS forced_RLS_for_all_three_entry_tables,
NOT has_table_privilege('anon','private.iclub_exam_chemistry_entry_items_v1','SELECT')
 AND NOT has_table_privilege('authenticated','private.iclub_exam_chemistry_entry_items_v1','SELECT')
 AND NOT has_table_privilege('authenticated','private.iclub_exam_chemistry_entry_study_links_v1','SELECT')
 AND NOT has_table_privilege('authenticated','private.iclub_exam_chemistry_entry_shadow_v1','SELECT')
 AS no_browser_access_to_entry_qa_or_keys,
NOT has_function_privilege('anon','private.iclub_exam_chemistry_entry_shadow_start_v1(text)','EXECUTE')
 AND NOT has_function_privilege('authenticated','private.iclub_exam_chemistry_entry_shadow_start_v1(text)','EXECUTE')
 AND NOT has_function_privilege('anon','private.iclub_exam_chemistry_entry_shadow_get_v1(uuid,text)','EXECUTE')
 AND NOT has_function_privilege('authenticated','private.iclub_exam_chemistry_entry_shadow_get_v1(uuid,text)','EXECUTE')
 AND NOT has_function_privilege('authenticated','private.iclub_exam_chemistry_entry_shadow_answer_v1(uuid,integer,integer)','EXECUTE')
 AND NOT has_function_privilege('authenticated','private.iclub_exam_chemistry_entry_shadow_finish_v1(uuid)','EXECUTE')
 AS all_entry_QA_RPCS_service_only,
has_function_privilege('service_role','private.iclub_exam_chemistry_entry_shadow_start_v1(text)','EXECUTE')
 AND has_function_privilege('service_role','private.iclub_exam_chemistry_entry_shadow_get_v1(uuid,text)','EXECUTE')
 AND has_function_privilege('service_role','private.iclub_exam_chemistry_entry_shadow_answer_v1(uuid,integer,integer)','EXECUTE')
 AND has_function_privilege('service_role','private.iclub_exam_chemistry_entry_shadow_finish_v1(uuid)','EXECUTE')
 AS QA_transport_service_role_ready,
(private.iclub_exam_core_native_plan_preflight_v1(
 'chemistry_9701','chemistry_2025_2027_v1')->>'state')='blocked'
 AS chemistry_native_exam_access_blocked;
