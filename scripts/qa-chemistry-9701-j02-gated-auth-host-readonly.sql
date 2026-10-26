-- Chemistry J-02 read-only production regression. Never expose stems, keys, sessions or student identifiers.
SELECT
 (SELECT count(*)=1 FROM private.iclub_exam_chemistry_p1_beta_control_v1
 WHERE id=1 AND enabled=false AND owner_go_at IS NULL) AS beta_gate_still_off,
 (SELECT count(*)=0 FROM private.iclub_exam_chemistry_p1_beta_members_v1) AS beta_members_zero,
 (SELECT count(*)=0 FROM private.iclub_exam_chemistry_p1_owner_release_items_v1) AS owner_releases_zero,
 (SELECT count(*)=0 FROM private.iclub_exam_chemistry_p1_live_attempts_v1) AS real_learner_chemistry_sessions_zero,
 (SELECT count(*)=0 FROM private.iclub_exam_chemistry_p1_shadow_sessions_v1) AS synthetic_chemistry_sessions_zero,
 (SELECT status='draft' AND launch_enabled=false
 FROM private.iclub_exam_core_programs_v1 WHERE program_key='chemistry_9701') AS chemistry_program_off,
 (SELECT status='draft' AND paper_code='P1' AND mcq_count=40 AND duration_seconds=4500
 FROM private.iclub_exam_core_papers_v1
 WHERE program_key='chemistry_9701' AND paper_code='P1') AS paper1_draft_40_questions_75_min,
 (SELECT visible_to_learners=false FROM private.iclub_subject_library
 WHERE subject_key='chemistry') AS chemistry_library_hidden,
 (private.iclub_exam_core_native_plan_preflight_v1(
 'chemistry_9701','chemistry_2025_2027_v1')->>'state')='blocked' AS learner_plan_blocked,
 (SELECT count(*)=40 FROM private.iclub_exam_core_chemistry_p1_mock_blueprint_preview_v1
 WHERE planning_role='proposed_form') AS original_40_in_closed_blueprint,
 (SELECT count(*)=4 FROM private.iclub_exam_core_chemistry_p1_mock_blueprint_preview_v1
 WHERE planning_role='proposed_reserve') AS reserve_four,
 (SELECT count(DISTINCT syllabus_unit)=22
 FROM private.iclub_exam_core_chemistry_p1_mock_blueprint_preview_v1
 WHERE planning_role='proposed_form') AS all_22_AS_topic_units,
 (SELECT count(*)=26 FROM private.iclub_exam_core_chemistry_p1_quarantine_v1) AS prior_26_versions_retained,
 (SELECT count(*)=45 FROM private.iclub_exam_core_chemistry_p1_secure_drafts_v1) AS original_private_drafts_45,
 (SELECT count(*)=308 FROM private.iclub_exam_core_chemistry_p1_qa_slots_v1
 WHERE gate_status='pass') AS internal_AI_QA_records_intact,
 (SELECT count(*)=9 FROM private.iclub_exam_core_chemistry_p1_legacy_revision_ai_reviews_v1) AS nine_legacy_revisions_retained,
 (SELECT count(*)=0 FROM private.iclub_exam_core_question_candidates_v1
 WHERE program_key='chemistry_9701' AND status='approved') AS no_old_questions_silently_approved,
 (SELECT count(*)=0 FROM private.iclub_exam_core_chemistry_p1_secure_drafts_v1
 WHERE release_enabled OR exam_candidate_eligible OR credit_mastery) AS no_source_release_flags,
 public.get_my_exam_prep_chemistry_shell_v1('ru')='{}'::jsonb AS chemistry_shell_fail_closed,
 (SELECT relrowsecurity AND relforcerowsecurity
 FROM pg_class WHERE oid='private.iclub_exam_chemistry_p1_live_attempts_v1'::regclass)
 AND (SELECT relrowsecurity AND relforcerowsecurity
 FROM pg_class WHERE oid='private.iclub_exam_chemistry_p1_beta_members_v1'::regclass)
 AND (SELECT relrowsecurity AND relforcerowsecurity
 FROM pg_class WHERE oid='private.iclub_exam_chemistry_p1_owner_release_items_v1'::regclass)
 AS new_tables_force_rls,
 NOT has_table_privilege('anon','private.iclub_exam_chemistry_p1_live_attempts_v1','SELECT')
 AND NOT has_table_privilege('authenticated','private.iclub_exam_chemistry_p1_live_attempts_v1','SELECT')
 AND NOT has_table_privilege('authenticated','private.iclub_exam_chemistry_p1_owner_release_items_v1','SELECT')
 AS learners_have_no_raw_key_access,
 NOT has_function_privilege('anon','public.get_my_exam_prep_chemistry_shell_v1(text)','EXECUTE')
 AND NOT has_function_privilege('anon','public.iclub_exam_chemistry_p1_start_v1(text)','EXECUTE')
 AND NOT has_function_privilege('anon','public.iclub_exam_chemistry_p1_get_v1(uuid,text)','EXECUTE')
 AND NOT has_function_privilege('anon','public.iclub_exam_chemistry_p1_answer_v1(uuid,integer,integer)','EXECUTE')
 AND NOT has_function_privilege('anon','public.iclub_exam_chemistry_p1_finish_v1(uuid)','EXECUTE')
 AND NOT has_function_privilege('anon','public.iclub_exam_chemistry_p1_history_v1()','EXECUTE')
 AS anonymous_cannot_call_any_beta_entrypoint,
 has_function_privilege('authenticated','public.get_my_exam_prep_chemistry_shell_v1(text)','EXECUTE')
 AND has_function_privilege('authenticated','public.iclub_exam_chemistry_p1_start_v1(text)','EXECUTE')
 AND has_function_privilege('authenticated','public.iclub_exam_chemistry_p1_get_v1(uuid,text)','EXECUTE')
 AND has_function_privilege('authenticated','public.iclub_exam_chemistry_p1_answer_v1(uuid,integer,integer)','EXECUTE')
 AND has_function_privilege('authenticated','public.iclub_exam_chemistry_p1_finish_v1(uuid)','EXECUTE')
 AND has_function_privilege('authenticated','public.iclub_exam_chemistry_p1_history_v1()','EXECUTE')
 AS authenticated_RPC_contract_present_but_gated,
 NOT has_function_privilege('authenticated','private.iclub_exam_chemistry_p1_student_authorized_v1()','EXECUTE')
 AS private_authorization_helper_not_exposed,
 (SELECT count(*)>=544 FROM private.exam_prep_sessions)
 AND (SELECT count(*)>=1979 FROM private.exam_prep_responses) AS math_history_still_present,
 (SELECT count(*)>=502 FROM public.practice_attempts)
 AND (SELECT count(*)>=4816 FROM public.practice_answers) AS practice_history_still_present,
 (SELECT count(*)>=1 FROM private.iclub_exam_native_mcq_attempts_v1)
 AS economics_history_still_present,
 (SELECT count(*)>=2098 FROM public.user_subjects) AS user_subject_selections_still_present;
