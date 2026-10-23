-- Stage 5B.2 content allowlist: READ-ONLY verification against today's closed catalog.
WITH x AS (
 SELECT
 private.iclub_exam_core_native_content_allowlist_v1('economics_9708','economics_2026_2028_v1','P1',100) p1,
 private.iclub_exam_core_native_content_allowlist_v1('economics_9708','economics_2026_2028_v1','P2',100) p2,
 private.iclub_exam_core_native_content_allowlist_v1('economics_9708','economics_2026_2028_v1','P3',100) p3,
 private.iclub_exam_core_native_content_allowlist_v1('economics_9708','economics_2026_2028_v1','P4',100) p4,
 private.iclub_exam_core_native_content_allowlist_v1('math_as_p1_p5','p1_p5_canonical_v1_0','P1',100) math,
 private.iclub_exam_core_native_content_allowlist_v1('chemistry_9701','chemistry_2025_2027_v1','P1',100) chem,
 private.iclub_exam_core_native_content_allowlist_v1('economics_9708','invalid_version','P1',100) invalid_version,
 private.iclub_exam_core_native_content_allowlist_v1('economics_9708','economics_2026_2028_v1','P9',100) invalid_paper
)
SELECT
 p1->>'contract_version'='native_academic_allowlist_v1' contract_pass,
 p1->>'state'='closed_catalog_preview' closed_state_pass,
 p1->>'can_issue_learner_task'='false' no_issuance_pass,
 p1->>'is_learner_specific'='false' no_learner_pass,
 p1->>'program_launch_enabled'='false' no_launch_pass,
 jsonb_array_length(p1->'theory')=0 p1_theory_closed_pass,
 jsonb_array_length(p1->'mcq')=0 p1_mcq_closed_pass,
 jsonb_array_length(p2->'theory')=0 p2_theory_closed_pass,
 jsonb_array_length(p2->'written')=0 p2_written_closed_pass,
 jsonb_array_length(p3->'mcq')=0 p3_mcq_closed_pass,
 jsonb_array_length(p4->'written')=0 p4_written_closed_pass,
 p2->>'written_blocker'='approved_task_skill_source_mapping_missing' written_mapping_gate_pass,
 math->>'state'='program_unavailable_or_library_not_validated' math_legacy_isolated_pass,
 chem->>'state'='program_unavailable_or_library_not_validated' chemistry_unvalidated_isolated_pass,
 invalid_version->>'state'='program_unavailable_or_library_not_validated' version_denied_pass,
 invalid_paper->>'state'='paper_unavailable' paper_denied_pass,
 NOT has_function_privilege('anon','private.iclub_exam_core_native_content_allowlist_v1(text,text,text,integer)','EXECUTE') anon_denied_pass,
 NOT has_function_privilege('authenticated','private.iclub_exam_core_native_content_allowlist_v1(text,text,text,integer)','EXECUTE') authenticated_denied_pass,
 has_function_privilege('service_role','private.iclub_exam_core_native_content_allowlist_v1(text,text,text,integer)','EXECUTE') service_allowed_pass,
 p1::text NOT LIKE '%correct_answer%' AND p1::text NOT LIKE '%answer_key%'
    AND p1::text NOT LIKE '%learner_id%' no_secret_fields_pass,
 (SELECT count(*) FROM private.iclub_exam_core_written_plans_v1)=0 no_written_plans_pass,
 (SELECT count(*) FROM private.iclub_exam_core_written_plan_items_v1)=0 no_written_steps_pass,
 (SELECT count(*) FROM private.exam_prep_sessions)>=543 math_history_present_pass,
 (SELECT count(*) FROM private.exam_prep_responses)>=1976 math_responses_present_pass,
 (SELECT count(*) FROM public.practice_attempts)>=502 practice_history_present_pass,
 (SELECT count(*) FROM public.practice_answers)>=4816 practice_answers_present_pass,
 (SELECT count(*) FROM public.user_subjects)>=2098 user_subjects_present_pass
FROM x;
