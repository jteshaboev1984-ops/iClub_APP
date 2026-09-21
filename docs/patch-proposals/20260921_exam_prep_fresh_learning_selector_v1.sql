-- DRAFT ONLY. Not a production migration or permission to publish content.
-- Apply in disposable PG17 AFTER the full-surface atomic dispatch candidate;
-- do not run on live data. Selection is read-only and creates no credit.
-- A production cutover must separately integrate this helper into eligibility,
-- the original private plan/correction authorizers AND pre-start, then test them.
BEGIN;
CREATE OR REPLACE FUNCTION private.exam_prep_select_fresh_learning_assessment_v1(
  p_user_id uuid, p_program_version_id bigint,
  p_component_code text, p_skill_code text
) RETURNS bigint
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = '' AS $body$
 SELECT a.id
 FROM private.exam_prep_assessments a
 JOIN private.exam_prep_content_versions cv ON cv.id=a.content_version_id
 JOIN private.exam_prep_exam_profiles ep
   ON ep.user_id=p_user_id AND ep.program_version_id=p_program_version_id
 WHERE p_user_id IS NOT NULL AND p_program_version_id IS NOT NULL
   AND p_component_code IN ('P1','P5') AND p_skill_code IS NOT NULL
   AND a.component_code=p_component_code AND a.assessment_type='learning'
   AND a.status='published' AND a.approved_at IS NOT NULL
   AND cv.program_version_id=p_program_version_id
   AND cv.component_code=p_component_code AND cv.status='published'
   AND cv.approved_at IS NOT NULL
   AND nullif(trim(a.title_en),'') IS NOT NULL
   AND nullif(trim(a.title_ru),'') IS NOT NULL
   AND nullif(trim(a.title_uz),'') IS NOT NULL
   AND (SELECT count(*) FROM private.exam_prep_assessment_items ai
        WHERE ai.assessment_id=a.id AND ai.question_id IS NOT NULL) BETWEEN 3 AND 6
   AND (SELECT count(*) FROM private.exam_prep_assessment_items ai
        WHERE ai.assessment_id=a.id AND ai.written_task_id IS NOT NULL)=1
   AND (SELECT count(DISTINCT ai.question_id) FROM private.exam_prep_assessment_items ai
        WHERE ai.assessment_id=a.id AND ai.question_id IS NOT NULL)=
       (SELECT count(*) FROM private.exam_prep_assessment_items ai
        WHERE ai.assessment_id=a.id AND ai.question_id IS NOT NULL)
   -- Full membership, original released learning role, per-item QA and version.
   AND NOT EXISTS (
      SELECT 1 FROM private.exam_prep_assessment_items ai
      WHERE ai.assessment_id=a.id AND (
         ai.primary_skill_code IS DISTINCT FROM p_skill_code
         OR ai.is_holdout IS DISTINCT FROM false
         OR (ai.question_id IS NOT NULL AND (
            ai.reserve_role<>'learning' OR NOT EXISTS (
              SELECT 1 FROM private.exam_prep_question_content_meta m
              WHERE m.question_id=ai.question_id AND m.content_version_id=cv.id
                AND m.primary_skill_code=p_skill_code
                AND m.reserve_role='learning' AND m.lifecycle_state='published'
                AND m.exposure_state='released' AND m.approved_at IS NOT NULL
                AND m.published_at IS NOT NULL AND m.copyright_status='pass'
                AND m.qa_scope_status='pass' AND m.qa_math_status='pass'
                AND m.qa_language_status='pass' AND m.qa_technical_status='pass'
                AND nullif(trim(m.originality_attestation),'') IS NOT NULL
            )
         ))
         OR (ai.written_task_id IS NOT NULL AND (
            ai.reserve_role<>'written' OR NOT EXISTS (
              SELECT 1 FROM private.exam_prep_written_tasks wt
              WHERE wt.id=ai.written_task_id AND wt.content_version_id=cv.id
                AND wt.component_code=p_component_code AND wt.primary_skill_code=p_skill_code
                AND wt.lifecycle_state='published' AND wt.approved_at IS NOT NULL
                AND wt.copyright_status='pass' AND wt.qa_math_status='pass'
                AND wt.qa_language_status='pass' AND wt.qa_technical_status='pass'
                AND nullif(trim(wt.prompt_en),'') IS NOT NULL
                AND nullif(trim(wt.prompt_ru),'') IS NOT NULL
                AND nullif(trim(wt.prompt_uz),'') IS NOT NULL
            )
         ))
      )
   )
   -- New assessment must use distinct IDs from every other published learning pack;
   -- a renamed/repackaged assessment must never look like fresh content.
   AND NOT EXISTS (
      SELECT 1 FROM private.exam_prep_assessment_items ni
      JOIN private.exam_prep_assessment_items oi
        ON oi.assessment_id<>ni.assessment_id AND (
          (ni.question_id IS NOT NULL AND oi.question_id=ni.question_id)
          OR (ni.written_task_id IS NOT NULL AND oi.written_task_id=ni.written_task_id))
      JOIN private.exam_prep_assessments other_a
        ON other_a.id=oi.assessment_id AND other_a.assessment_type='learning'
         AND other_a.status='published'
      WHERE ni.assessment_id=a.id
   )
   -- Never recycle a completed or started pack, even if it has been renamed.
   AND NOT EXISTS (
      SELECT 1 FROM private.exam_prep_sessions s
      WHERE s.user_id=p_user_id AND s.component_code=p_component_code
        AND s.assessment_id=a.id
   )
   AND NOT EXISTS (
      SELECT 1 FROM private.exam_prep_assessment_items ni
      JOIN private.exam_prep_session_items si ON
        (ni.question_id IS NOT NULL AND si.question_id=ni.question_id)
        OR (ni.written_task_id IS NOT NULL AND si.written_task_id=ni.written_task_id)
      JOIN private.exam_prep_sessions s ON s.id=si.session_id
      WHERE ni.assessment_id=a.id AND s.user_id=p_user_id
        AND s.component_code=p_component_code
   )
 ORDER BY a.id LIMIT 1;
$body$;
REVOKE ALL ON FUNCTION private.exam_prep_select_fresh_learning_assessment_v1(uuid,bigint,text,text)
  FROM PUBLIC,anon,authenticated,service_role;
DO $verify$
BEGIN
 IF has_function_privilege('authenticated',
    'private.exam_prep_select_fresh_learning_assessment_v1(uuid,bigint,text,text)','EXECUTE')
   OR has_function_privilege('anon',
    'private.exam_prep_select_fresh_learning_assessment_v1(uuid,bigint,text,text)','EXECUTE')
   OR has_function_privilege('service_role',
    'private.exam_prep_select_fresh_learning_assessment_v1(uuid,bigint,text,text)','EXECUTE') THEN
   RAISE EXCEPTION 'fresh_learning_private_selector_exposed';
 END IF;
END;$verify$;
COMMIT;
