-- Chemistry 9701 Stage J-01: READ-ONLY production regression for service-only QA transport.
-- No student real attempts, no answer keys, no direct learner access.
SELECT
 (SELECT status='draft' AND launch_enabled=false AND integration_mode='native'
 FROM private.iclub_exam_core_programs_v1 WHERE program_key='chemistry_9701') AS chemistry_draft_off,
 (SELECT visible_to_learners=false FROM private.iclub_subject_library
 WHERE subject_key='chemistry') AS chemistry_library_hidden,
 (private.iclub_exam_core_native_plan_preflight_v1(
 'chemistry_9701','chemistry_2025_2027_v1')->>'state')='blocked'
 AS chemistry_native_paper_blocked,
 (SELECT COUNT(*)=0 FROM private.iclub_exam_chemistry_p1_shadow_sessions_v1)
 AS no_qa_sessions_persisted,
 (SELECT COUNT(*)=40 FROM private.iclub_exam_core_chemistry_p1_mock_blueprint_preview_v1
 WHERE planning_role='proposed_form') AS private_paper_40,
 (SELECT COUNT(*)=4 FROM private.iclub_exam_core_chemistry_p1_mock_blueprint_preview_v1
 WHERE planning_role='proposed_reserve') AS private_reserve_4,
 (SELECT COUNT(DISTINCT syllabus_unit)=22
 FROM private.iclub_exam_core_chemistry_p1_mock_blueprint_preview_v1
 WHERE planning_role='proposed_form') AS all_22_AS_topics,
 (SELECT COUNT(*)=45 FROM private.iclub_exam_core_chemistry_p1_secure_drafts_v1)
 AS private_source_drafts_45,
 (SELECT COUNT(*)=308 FROM private.iclub_exam_core_chemistry_p1_qa_slots_v1 WHERE gate_status='pass')
 AS internal_ai_review_records_intact,
 (SELECT COUNT(*)=26 FROM private.iclub_exam_core_chemistry_p1_quarantine_v1)
 AS prior_26_original_variants_preserved,
 (SELECT relrowsecurity AND relforcerowsecurity FROM pg_class
 WHERE oid='private.iclub_exam_chemistry_p1_shadow_sessions_v1'::regclass)
 AS forced_rls_for_shadow_sessions,
 NOT has_table_privilege('anon','private.iclub_exam_chemistry_p1_shadow_sessions_v1','SELECT')
 AND NOT has_table_privilege('authenticated','private.iclub_exam_chemistry_p1_shadow_sessions_v1','SELECT')
 AS ordinary_users_cannot_read_private_keys,
 NOT has_function_privilege('anon','private.iclub_exam_chemistry_p1_shadow_start_v1(uuid,text)','EXECUTE')
 AND NOT has_function_privilege('authenticated','private.iclub_exam_chemistry_p1_shadow_start_v1(uuid,text)','EXECUTE')
 AS start_is_service_only,
 NOT has_function_privilege('anon','private.iclub_exam_chemistry_p1_shadow_get_v1(uuid,uuid,text)','EXECUTE')
 AND NOT has_function_privilege('authenticated','private.iclub_exam_chemistry_p1_shadow_get_v1(uuid,uuid,text)','EXECUTE')
 AS read_is_service_only,
 NOT has_function_privilege('anon','private.iclub_exam_chemistry_p1_shadow_answer_v1(uuid,uuid,integer,integer)','EXECUTE')
 AND NOT has_function_privilege('authenticated','private.iclub_exam_chemistry_p1_shadow_answer_v1(uuid,uuid,integer,integer)','EXECUTE')
 AS answer_is_service_only,
 NOT has_function_privilege('anon','private.iclub_exam_chemistry_p1_shadow_finish_v1(uuid,uuid)','EXECUTE')
 AND NOT has_function_privilege('authenticated','private.iclub_exam_chemistry_p1_shadow_finish_v1(uuid,uuid)','EXECUTE')
 AS score_is_service_only,
 has_function_privilege('service_role','private.iclub_exam_chemistry_p1_shadow_start_v1(uuid,text)','EXECUTE')
 AND has_function_privilege('service_role','private.iclub_exam_chemistry_p1_shadow_get_v1(uuid,uuid,text)','EXECUTE')
 AND has_function_privilege('service_role','private.iclub_exam_chemistry_p1_shadow_answer_v1(uuid,uuid,integer,integer)','EXECUTE')
 AND has_function_privilege('service_role','private.iclub_exam_chemistry_p1_shadow_finish_v1(uuid,uuid)','EXECUTE')
 AS service_transport_entrypoints_ready,
 to_regprocedure('public.iclub_exam_chemistry_p1_shadow_start_v1(uuid,text)') IS NULL
 AND to_regprocedure('public.iclub_exam_chemistry_p1_shadow_get_v1(uuid,uuid,text)') IS NULL
 AS no_public_chemistry_question_endpoints,
 (SELECT COUNT(*)>=1 FROM private.iclub_exam_native_mcq_attempts_v1)
 AS economics_history_unmodified_and_readable,
 (SELECT COUNT(*)>=544 FROM private.exam_prep_sessions)
 AND (SELECT COUNT(*)>=1979 FROM private.exam_prep_responses)
 AS mathematics_history_preserved,
 (SELECT COUNT(*)>=502 FROM public.practice_attempts)
 AND (SELECT COUNT(*)>=4816 FROM public.practice_answers)
 AS practice_history_preserved;
