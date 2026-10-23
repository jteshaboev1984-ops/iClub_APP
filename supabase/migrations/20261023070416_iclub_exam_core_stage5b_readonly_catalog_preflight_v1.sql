-- iClub Stage 5B: CLOSED read-only server-sourced academic preflight.
-- No public API, no user plans, no graded evidence, no flags enabled.
-- This function NEVER authorizes a learner plan or grade.
CREATE FUNCTION private.iclub_exam_core_native_plan_preflight_v1(
  p_program_key text,
  p_version_key text
) RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY INVOKER SET search_path = ''
AS $func$
DECLARE
  v_program record;
  v_papers jsonb;
BEGIN
  IF p_program_key IS NULL OR p_version_key IS NULL
     OR btrim(p_program_key)='' OR btrim(p_version_key)='' THEN
    RAISE EXCEPTION 'native_plan_preflight_invalid_request'
      USING ERRCODE='22023';
  END IF;

  SELECT p.program_key, p.version_key, p.integration_mode,
         p.status, p.launch_enabled, p.library_subject_key,
         p.library_version_key, r.state AS library_state
  INTO v_program
  FROM private.iclub_exam_core_programs_v1 p
  LEFT JOIN private.iclub_subject_library_releases r
    ON r.subject_key=p.library_subject_key
    AND r.version_key=p.library_version_key
  WHERE p.program_key=p_program_key
    AND p.version_key=p_version_key;

  IF NOT FOUND OR v_program.integration_mode <> 'native' THEN
    RETURN jsonb_build_object(
      'contract_version','native_plan_preflight_v1',
      'state','program_unavailable',
      'can_issue_learner_plan',false,
      'papers','[]'::jsonb
    );
  END IF;

  SELECT COALESCE(jsonb_agg(
    jsonb_build_object(
      'paper_code',pa.paper_code,
      'level_code',pa.level_code,
      'assessment_kind',pa.assessment_kind,
      'paper_status',pa.status,
      'mapped_direct_skills',coalesce(s.direct_mapped,0),
      'reviewed_direct_skills',coalesce(s.direct_reviewed,0),
      'reviewed_prerequisites',coalesce(s.prerequisites_reviewed,0),
      'mcq_candidate_links',coalesce(m.candidate_links,0),
      'mcq_qa_pass_links',coalesce(m.qa_pass_links,0),
      'written_drafts',coalesce(w.total_written,0),
      'written_qa_released',coalesce(w.released_written,0),
      'planned_assessment_runtime',false,
      'can_issue_tasks',false,
      'blockers',jsonb_build_array(
        CASE WHEN pa.status<>'published' THEN 'paper_not_published' END,
        CASE WHEN coalesce(s.direct_reviewed,0)=0
          THEN 'reviewed_direct_skill_mapping_missing' END,
        CASE WHEN pa.assessment_kind='mcq' AND
                coalesce(m.qa_pass_links,0)<pa.mcq_count
          THEN 'verified_mcq_pool_insufficient' END,
        CASE WHEN pa.assessment_kind='data_response_essays' AND
                coalesce(w.released_written,0)=0
          THEN 'approved_written_content_missing' END,
        'assessment_runtime_not_verified',
        'learner_diagnostic_and_plan_evidence_missing'
      ) - 'null'
    ) ORDER BY pa.paper_no
  ),'[]'::jsonb)
  INTO v_papers
  FROM private.iclub_exam_core_papers_v1 pa
  LEFT JOIN LATERAL (
    SELECT
      count(*) FILTER (WHERE ps.link_role='direct') AS direct_mapped,
      count(*) FILTER (
        WHERE ps.link_role='direct' AND ps.status='approved'
          AND sk.status='reviewed'
          AND ((pa.level_code='AS' AND sk.level_code='AS')
            OR (pa.level_code='A' AND sk.level_code='A'))
      ) AS direct_reviewed,
      count(*) FILTER (
        WHERE ps.link_role='assumed_prerequisite' AND ps.status='approved'
          AND sk.status='reviewed' AND sk.level_code='AS'
      ) AS prerequisites_reviewed
    FROM private.iclub_exam_core_paper_skills_v1 ps
    JOIN private.iclub_exam_core_skills_v1 sk
      ON sk.program_key=ps.program_key
      AND sk.version_key=ps.version_key AND sk.skill_key=ps.skill_key
    WHERE ps.program_key=pa.program_key
      AND ps.version_key=pa.version_key AND ps.paper_code=pa.paper_code
  ) s ON true
  LEFT JOIN LATERAL (
    SELECT
      count(DISTINCT qc.legacy_question_id) AS candidate_links,
      count(DISTINCT qc.legacy_question_id) FILTER (
        WHERE qc.status='approved'
          AND qc.qa_scope_status='pass'
          AND qc.qa_academic_status='pass'
          AND qc.qa_language_status='pass'
          AND qc.qa_format_status='pass'
          AND ps.status='approved'
          AND sk.status='reviewed'
          AND sk.level_code=pa.level_code
          AND qc.link_role='direct'
          AND q.qtype='mcq'
          AND q.quality_status='published' AND q.is_active=true
      ) AS qa_pass_links
    FROM private.iclub_exam_core_question_candidates_v1 qc
    JOIN private.iclub_exam_core_paper_skills_v1 ps
      ON ps.program_key=qc.program_key
      AND ps.version_key=qc.version_key
      AND ps.paper_code=qc.paper_code
      AND ps.skill_key=qc.skill_key AND ps.link_role=qc.link_role
    JOIN private.iclub_exam_core_skills_v1 sk
      ON sk.program_key=qc.program_key AND sk.version_key=qc.version_key
      AND sk.skill_key=qc.skill_key
    JOIN public.questions q ON q.id=qc.legacy_question_id
    WHERE qc.program_key=pa.program_key
      AND qc.version_key=pa.version_key AND qc.paper_code=pa.paper_code
  ) m ON true
  LEFT JOIN LATERAL (
    SELECT count(*) AS total_written,
      count(*) FILTER (
        WHERE wt.status='approved' AND wt.release_enabled=true
          AND wt.academic_review='approved'
          AND wt.language_review='approved'
          AND wt.source_review='approved'
          AND wt.questions ?& ARRAY['ru','uz','en']
          AND wt.answer_requirements ?& ARRAY['ru','uz','en']
      ) AS released_written
    FROM private.iclub_exam_core_written_tasks_v1 wt
    WHERE wt.program_key=pa.program_key
      AND wt.version_key=pa.version_key AND wt.paper_code=pa.paper_code
  ) w ON true
  WHERE pa.program_key=v_program.program_key
    AND pa.version_key=v_program.version_key;

  RETURN jsonb_build_object(
    'contract_version','native_plan_preflight_v1',
    'program_key',v_program.program_key,
    'program_version',v_program.version_key,
    'program_status',v_program.status,
    'launch_enabled',v_program.launch_enabled,
    'library_release_state',v_program.library_state,
    'state','blocked',
    'can_issue_learner_plan',false,
    'is_learner_specific',false,
    'has_auth_evidence',false,
    'source_authority','private_database_catalog_read_only',
    'program_blockers',jsonb_build_array(
      CASE WHEN v_program.status<>'published' THEN 'program_not_published' END,
      CASE WHEN NOT v_program.launch_enabled THEN 'program_launch_off' END,
      CASE WHEN v_program.library_state IS DISTINCT FROM 'validated'
        THEN 'library_release_not_validated' END,
      'learner_access_and_diagnostic_evidence_unavailable'
    ) - 'null',
    'papers',v_papers
  );
END;
$func$;

REVOKE ALL ON FUNCTION private.iclub_exam_core_native_plan_preflight_v1(text,text)
  FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION private.iclub_exam_core_native_plan_preflight_v1(text,text)
  TO service_role;
