-- J-06 Chemistry post-P1 study-plan read-only QA.
-- Caller without auth.uid() returns invalid_request. Authenticated user without GO gets not_available.
SELECT
 to_regprocedure('public.iclub_exam_chemistry_p1_review_plan_v1(uuid,text)') IS NOT NULL AS plan_rpc_present,
 (SELECT prosecdef AND provolatile='s' FROM pg_proc WHERE
 oid='public.iclub_exam_chemistry_p1_review_plan_v1(uuid,text)'::regprocedure::oid) AS plan_stable_read_only,
 (SELECT array_to_string(proconfig,',') LIKE '%search_path=%' FROM pg_proc WHERE
 oid='public.iclub_exam_chemistry_p1_review_plan_v1(uuid,text)'::regprocedure::oid) AS plan_fixed_search_path,
 NOT has_function_privilege('anon',
 'public.iclub_exam_chemistry_p1_review_plan_v1(uuid,text)','EXECUTE') AS plan_denies_anon,
 has_function_privilege('authenticated',
 'public.iclub_exam_chemistry_p1_review_plan_v1(uuid,text)','EXECUTE') AS plan_auth_rpc_present,
 (public.iclub_exam_chemistry_p1_review_plan_v1(
 '00000000-0000-4000-8000-000000000001'::uuid,'ru')->>'code')='invalid_request'
 AS no_auth_user_denied_ru,
 (public.iclub_exam_chemistry_p1_review_plan_v1(
 '00000000-0000-4000-8000-000000000001'::uuid,'uz')->>'code')='invalid_request'
 AS no_auth_user_denied_uz,
 (public.iclub_exam_chemistry_p1_review_plan_v1(
 '00000000-0000-4000-8000-000000000001'::uuid,'en')->>'code')='invalid_request'
 AS no_auth_user_denied_en,
 (SELECT count(*)=0 FROM private.iclub_exam_chemistry_p1_live_attempts_v1) AS real_chemistry_attempts_zero,
 (SELECT count(*)=0 FROM private.iclub_exam_chemistry_p1_shadow_sessions_v1) AS qa_chemistry_attempts_zero,
 (SELECT count(*)=0 FROM private.iclub_exam_chemistry_p1_beta_members_v1) AS chemistry_optins_zero,
 (SELECT count(*)=0 FROM private.iclub_exam_chemistry_p1_owner_release_items_v1) AS owner_release_items_zero,
 (SELECT enabled=false AND owner_go_at IS NULL FROM private.iclub_exam_chemistry_p1_beta_control_v1 WHERE id=1) AS beta_off,
 (SELECT status='draft' AND launch_enabled=false FROM private.iclub_exam_core_programs_v1
 WHERE program_key='chemistry_9701') AS core_draft_off,
 (private.iclub_exam_core_native_plan_preflight_v1('chemistry_9701','chemistry_2025_2027_v1')->>'state')='blocked'
 AS native_preflight_blocked,
 (SELECT count(*)=40 FROM private.iclub_exam_core_chemistry_p1_mock_blueprint_preview_v1
 WHERE planning_role='proposed_form') AS forty_originals_in_editor_mock,
 (SELECT count(DISTINCT syllabus_unit)=22 FROM private.iclub_exam_core_chemistry_p1_mock_blueprint_preview_v1
 WHERE planning_role='proposed_form') AS all_twenty_two_AS_topics,
 (SELECT count(*)=4 FROM private.iclub_exam_core_chemistry_p1_mock_blueprint_preview_v1
 WHERE planning_role='proposed_reserve') AS four_private_reserves,
 (SELECT count(*)=26 FROM private.iclub_exam_core_chemistry_p1_quarantine_v1) AS old_twenty_six_preserved,
 (SELECT count(*)=45 FROM private.iclub_exam_core_chemistry_p1_secure_drafts_v1) AS private_originals_preserved,
 (SELECT count(*)=0 FROM private.iclub_exam_core_chemistry_p1_secure_drafts_v1
 WHERE release_enabled OR exam_candidate_eligible OR credit_mastery) AS no_mastery_or_content_release,
 (SELECT count(*)>=544 FROM private.exam_prep_sessions) AS Mathematics_attempts_safe,
 (SELECT count(*)>=1979 FROM private.exam_prep_responses) AS Mathematics_responses_safe,
 (SELECT count(*)>=502 FROM public.practice_attempts) AS Practice_attempts_safe,
 (SELECT count(*)>=4816 FROM public.practice_answers) AS Practice_responses_safe,
 (SELECT count(*)>=1 FROM private.iclub_exam_native_mcq_attempts_v1) AS Economics_attempts_safe;
