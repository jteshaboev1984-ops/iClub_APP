-- READ-ONLY Stage5B acceptance checks for private native preflight.
-- Copy of the verified, additive implementation does NOT mutate users.
WITH s AS (
 SELECT private.iclub_exam_core_native_plan_preflight_v1(
 'economics_9708','economics_2026_2028_v1') AS data
), p AS (
 SELECT data, jsonb_array_length(data->'papers') AS paper_count
 FROM s
)
SELECT
 data->>'contract_version'='native_plan_preflight_v1' AS contract_pass,
 data->>'state'='blocked' AS blocked_pass,
 data->>'program_status'='draft' AS program_draft_pass,
 (data->>'launch_enabled')::boolean=false AS launch_off_pass,
 (data->>'can_issue_learner_plan')::boolean=false AS no_plan_authority_pass,
 (data->>'is_learner_specific')::boolean=false AS no_learner_evidence_pass,
 paper_count=4 AS four_papers_pass,
 NOT jsonb_path_exists(data,'$.papers[*].blockers[*] ? (@ == null)') AS paper_blockers_clean_pass,
 NOT jsonb_path_exists(data,'$.program_blockers[*] ? (@ == null)') AS program_blockers_clean_pass,
 (SELECT count(*) FROM jsonb_array_elements(data->'papers') x WHERE x->>'can_issue_tasks'='false')=4 AS all_papers_blocked_pass,
 (SELECT (x->>'mcq_candidate_links')::int FROM jsonb_array_elements(data->'papers') x WHERE x->>'paper_code'='P1')=16 AS p1_pilot_pass,
 (SELECT (x->>'mcq_candidate_links')::int FROM jsonb_array_elements(data->'papers') x WHERE x->>'paper_code'='P3')=0 AS p3_pool_missing_pass,
 (SELECT (x->>'written_drafts')::int FROM jsonb_array_elements(data->'papers') x WHERE x->>'paper_code'='P2')=14 AS p2_drafts_pass,
 (SELECT (x->>'written_drafts')::int FROM jsonb_array_elements(data->'papers') x WHERE x->>'paper_code'='P4')=8 AS p4_drafts_pass,
 NOT has_function_privilege('anon','private.iclub_exam_core_native_plan_preflight_v1(text,text)','EXECUTE') AS anon_denied_pass,
 NOT has_function_privilege('authenticated','private.iclub_exam_core_native_plan_preflight_v1(text,text)','EXECUTE') AS auth_denied_pass,
 has_function_privilege('service_role','private.iclub_exam_core_native_plan_preflight_v1(text,text)','EXECUTE') AS service_allowed_pass,
 (private.iclub_exam_core_native_plan_preflight_v1('math_as_p1_p5','p1_p5_canonical_v1_0')->>'state'='program_unavailable') AS math_legacy_not_migrated_pass,
 (private.iclub_exam_core_native_plan_preflight_v1('chemistry_9701','chemistry_2025_2027_v1')->>'state'='blocked') AS chemistry_draft_stays_off_pass,
 (private.iclub_exam_core_native_plan_preflight_v1('chemistry_9701','chemistry_2025_2027_v1')->>'launch_enabled'='false') AS chemistry_no_enable_pass,
 (private.iclub_exam_core_native_plan_preflight_v1('economics_9708','wrong_version')->>'state'='program_unavailable') AS no_version_fallback_pass,
 NOT (data ? 'learner_id' OR data ? 'grade' OR data ? 'mastery' OR data ? 'response_text' OR data ? 'answer_key') AS no_personal_grading_fields_pass,
 (SELECT count(*) FROM private.iclub_exam_core_written_plans_v1)=0 AS no_written_plans_pass,
 (SELECT count(*) FROM private.iclub_exam_core_written_plan_items_v1)=0 AS no_written_plan_items_pass,
 (SELECT count(*) FROM private.iclub_exam_core_written_access_v1)=0 AS no_written_assignments_pass
FROM p;
