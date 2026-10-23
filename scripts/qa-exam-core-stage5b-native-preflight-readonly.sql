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
 (SELECT count(*) FROM private.iclub_exam_core_written_plans_v1)=0 AS no_written_plans_pass,
 (SELECT count(*) FROM private.iclub_exam_core_written_plan_items_v1)=0 AS no_written_plan_items_pass,
 (SELECT count(*) FROM private.iclub_exam_core_written_access_v1)=0 AS no_written_assignments_pass
FROM p;
