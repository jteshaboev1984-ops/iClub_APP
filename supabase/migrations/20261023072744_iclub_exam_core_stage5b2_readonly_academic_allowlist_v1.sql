-- iClub Economics 9708 / Stage 5B.2: server-only approved source preview.
-- No student issuance. No authorisation/grades. Does not change legacy or student rows.
-- Keep all source selections behind canonical program/version/paper and academic QA gates.
CREATE FUNCTION private.iclub_exam_core_native_content_allowlist_v1(
  p_program_key text,
  p_version_key text,
  p_paper_code text,
  p_limit integer DEFAULT 100
) RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY INVOKER SET search_path = ''
AS $func$
DECLARE
  v_program record;
  v_paper record;
  v_theory jsonb := '[]'::jsonb;
  v_mcq jsonb := '[]'::jsonb;
BEGIN
  IF p_program_key IS NULL OR p_version_key IS NULL OR p_paper_code IS NULL
     OR length(btrim(p_program_key))=0 OR length(btrim(p_version_key))=0
     OR length(btrim(p_paper_code))=0 OR p_limit IS NULL
     OR p_limit < 1 OR p_limit > 200 THEN
    RAISE EXCEPTION 'native_allowlist_invalid_request' USING ERRCODE='22023';
  END IF;

  SELECT p.program_key,p.version_key,p.library_subject_key,
         p.library_version_key,p.status,p.launch_enabled,
         r.state AS library_state,s.id AS source_subject_id
  INTO v_program
  FROM private.iclub_exam_core_programs_v1 p
  JOIN public.subjects s ON s.subject_key=p.subject_key
  LEFT JOIN private.iclub_subject_library_releases r
    ON r.subject_key=p.library_subject_key
   AND r.version_key=p.library_version_key
  WHERE p.program_key=p_program_key AND p.version_key=p_version_key
    AND p.integration_mode='native';

  IF NOT FOUND OR v_program.library_state IS DISTINCT FROM 'validated' THEN
    RETURN jsonb_build_object('contract_version','native_academic_allowlist_v1',
      'state','program_unavailable_or_library_not_validated',
      'is_learner_specific',false,'can_issue_learner_task',false,
      'theory','[]'::jsonb,'mcq','[]'::jsonb,'written','[]'::jsonb);
  END IF;

  SELECT pa.paper_code,pa.level_code,pa.assessment_kind,pa.status
  INTO v_paper
  FROM private.iclub_exam_core_papers_v1 pa
  WHERE pa.program_key=v_program.program_key
    AND pa.version_key=v_program.version_key
    AND pa.paper_code=p_paper_code;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('contract_version','native_academic_allowlist_v1',
      'state','paper_unavailable','is_learner_specific',false,
      'can_issue_learner_task',false,'theory','[]'::jsonb,
      'mcq','[]'::jsonb,'written','[]'::jsonb);
  END IF;

  -- Subject Theory is not exam evidence. Only reviewed skill+approved relation,
  -- exact pinned library snapshot, and complete, non-empty EN/RU/UZ cards.
  SELECT COALESCE(jsonb_agg(jsonb_build_object(
    'paper_code',p_paper_code,
    'kind','theory',
    'skill_key',candidate.skill_key,
    'syllabus_point',candidate.syllabus_point,
    'link_role',candidate.link_role,
    'source_content_hash',candidate.content_hash,
    'source_library_version',v_program.library_version_key,
    'evidence_policy','no_mastery_from_navigation',
    'can_issue_learner_task',false
  ) ORDER BY candidate.syllabus_point,candidate.skill_key),'[]'::jsonb)
  INTO v_theory
  FROM (
    SELECT DISTINCT ON (sk.skill_key,ps.link_role)
      sk.skill_key,sk.syllabus_point,sk.content_hash,ps.link_role
    FROM private.iclub_exam_core_paper_skills_v1 ps
    JOIN private.iclub_exam_core_skills_v1 sk
      ON sk.program_key=ps.program_key AND sk.version_key=ps.version_key
      AND sk.skill_key=ps.skill_key
    JOIN private.iclub_subject_library_theory t
      ON t.subject_key=sk.library_subject_key
      AND t.version_key=sk.library_version_key AND t.skill_key=sk.skill_key
    WHERE ps.program_key=v_program.program_key
      AND ps.version_key=v_program.version_key AND ps.paper_code=p_paper_code
      AND ps.status='approved' AND sk.status='reviewed'
      AND sk.content_hash=t.content_hash
      AND sk.library_subject_key=v_program.library_subject_key
      AND sk.library_version_key=v_program.library_version_key
      AND ((ps.link_role='direct' AND sk.level_code=v_paper.level_code)
       OR (ps.link_role='assumed_prerequisite'
         AND v_paper.level_code='A' AND sk.level_code='AS'))
      AND t.locales ?& ARRAY['en','ru','uz']
      AND jsonb_typeof(t.locales->'en')='object'
      AND jsonb_typeof(t.locales->'ru')='object'
      AND jsonb_typeof(t.locales->'uz')='object'
      AND btrim(coalesce(t.locales->'en'->>'title',''))<>''
      AND btrim(coalesce(t.locales->'ru'->>'title',''))<>''
      AND btrim(coalesce(t.locales->'uz'->>'title',''))<>''
      AND btrim(coalesce(t.locales->'en'->>'explanation',''))<>''
      AND btrim(coalesce(t.locales->'ru'->>'explanation',''))<>''
      AND btrim(coalesce(t.locales->'uz'->>'explanation',''))<>''
    ORDER BY sk.skill_key,ps.link_role
    LIMIT p_limit
  ) candidate;

  -- Immutable snapshots: compare legacy source to the same md5/jsonb
  -- algorithm used when the private question-review queue was imported.
  -- No question text, explanation, options, or answer key is ever returned.
  IF v_paper.assessment_kind='mcq' THEN
    SELECT COALESCE(jsonb_agg(jsonb_build_object(
      'paper_code',p_paper_code,
      'kind','mcq',
      'skill_key',candidate.skill_key,
      'question_source_id',candidate.question_id,
      'source_snapshot_md5',candidate.source_snapshot_md5,
      'source_paper',p_paper_code,
      'evidence_policy','server_verification_required',
      'can_issue_learner_task',false
    ) ORDER BY candidate.question_id,candidate.skill_key),'[]'::jsonb)
    INTO v_mcq
    FROM (
      SELECT qc.skill_key,qc.legacy_question_id AS question_id,
             qc.source_snapshot_md5
      FROM private.iclub_exam_core_question_candidates_v1 qc
      JOIN private.iclub_exam_core_paper_skills_v1 ps
        ON ps.program_key=qc.program_key AND ps.version_key=qc.version_key
       AND ps.paper_code=qc.paper_code AND ps.skill_key=qc.skill_key
       AND ps.link_role='direct' AND ps.status='approved'
      JOIN private.iclub_exam_core_skills_v1 sk
        ON sk.program_key=qc.program_key AND sk.version_key=qc.version_key
       AND sk.skill_key=qc.skill_key AND sk.status='reviewed'
       AND sk.level_code=v_paper.level_code
      JOIN public.questions q ON q.id=qc.legacy_question_id
       AND q.subject_id=v_program.source_subject_id
      JOIN private.iclub_exam_core_question_review_v1 review
        ON review.program_key=qc.program_key AND review.version_key=qc.version_key
       AND review.legacy_question_id=qc.legacy_question_id
      WHERE qc.program_key=v_program.program_key
        AND qc.version_key=v_program.version_key
        AND qc.paper_code=p_paper_code
        AND qc.link_role='direct' AND qc.status='approved'
        AND qc.qa_scope_status='pass' AND qc.qa_academic_status='pass'
        AND qc.qa_language_status='pass' AND qc.qa_format_status='pass'
        AND q.qtype='mcq' AND q.is_active=true AND q.quality_status='published'
        AND q.correct_answer ~ '^[A-D]$'
        AND btrim(coalesce(q.question_text_en,''))<>''
        AND btrim(coalesce(q.question_text_ru,''))<>''
        AND btrim(coalesce(q.question_text_uz,''))<>''
        AND btrim(coalesce(q.options_text_en,''))<>''
        AND btrim(coalesce(q.options_text_ru,''))<>''
        AND btrim(coalesce(q.options_text_uz,''))<>''
        AND btrim(coalesce(q.explanation_en,''))<>''
        AND btrim(coalesce(q.explanation_ru,''))<>''
        AND btrim(coalesce(q.explanation_uz,''))<>''
        AND qc.source_snapshot_md5=review.source_snapshot_md5
        AND qc.source_snapshot_md5=md5(jsonb_build_object(
          'topic',q.topic,'subtopic',q.subtopic,'difficulty',q.difficulty,'qtype',q.qtype,
          'q_en',q.question_text_en,'q_ru',q.question_text_ru,'q_uz',q.question_text_uz,
          'options_en',q.options_text_en,'options_ru',q.options_text_ru,'options_uz',q.options_text_uz,
          'correct_answer',q.correct_answer,'explanation_en',q.explanation_en,
          'explanation_ru',q.explanation_ru,'explanation_uz',q.explanation_uz,
          'image_url',q.image_url,'book_ref',q.book_ref,'quality_status',q.quality_status,
          'is_active',q.is_active
        )::text)
      ORDER BY qc.legacy_question_id,qc.skill_key
      LIMIT p_limit
    ) candidate;
  END IF;

  -- Written: no canonical approved written task ↔ skill mapping yet.
  -- Returning an empty collection is mandatory, even if a draft is released elsewhere.
  RETURN jsonb_build_object(
    'contract_version','native_academic_allowlist_v1',
    'state','closed_catalog_preview',
    'program_key',v_program.program_key,
    'program_version',v_program.version_key,
    'paper_code',p_paper_code,
    'library_release_state',v_program.library_state,
    'program_launch_enabled',v_program.launch_enabled,
    'is_learner_specific',false,
    'can_issue_learner_task',false,
    'theory',v_theory,
    'mcq',v_mcq,
    'written','[]'::jsonb,
    'written_blocker','approved_task_skill_source_mapping_missing',
    'assessment_runtime_verified',false
  );
END;
$func$;

REVOKE ALL ON FUNCTION private.iclub_exam_core_native_content_allowlist_v1(text,text,text,integer)
  FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION private.iclub_exam_core_native_content_allowlist_v1(text,text,text,integer)
  TO service_role;