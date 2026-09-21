-- REVIEW-ONLY; NOT a production migration, do not auto-install.
-- This is a private read-only decision primitive. It neither authorizes nor
-- launches repeat attempts: the entire review/credit/correction path MUST be
-- joined and tested before any learner enrollment. No new question packs.
BEGIN;
CREATE OR REPLACE FUNCTION private.exam_prep_learning_review_verdict_v1(
 p_user_id uuid, p_program_version_id bigint, p_component_code text,
 p_skill_code text, p_assessment_id bigint
) RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $body$
DECLARE
 v_attempts integer;
 v_complete boolean;
 v_consistent boolean;
 v_correction text;
BEGIN
 IF p_user_id IS NULL OR p_program_version_id IS NULL OR
    p_component_code NOT IN ('P1','P5') OR p_skill_code IS NULL OR
    p_skill_code NOT LIKE p_component_code||'-%' OR p_assessment_id IS NULL OR
    NOT EXISTS (SELECT 1 FROM private.exam_prep_exam_profiles ep
      WHERE ep.user_id=p_user_id AND ep.program_version_id=p_program_version_id) OR
    NOT EXISTS (SELECT 1 FROM private.exam_prep_assessments a
      JOIN private.exam_prep_content_versions cv ON cv.id=a.content_version_id
      WHERE a.id=p_assessment_id AND a.component_code=p_component_code
        AND a.assessment_type='learning' AND a.status='published'
        AND cv.program_version_id=p_program_version_id
        AND cv.component_code=p_component_code AND cv.status='published'
        AND (SELECT COUNT(*) FROM private.exam_prep_assessment_items i
             WHERE i.assessment_id=a.id AND i.question_id IS NOT NULL
               AND i.primary_skill_code=p_skill_code AND i.reserve_role='learning'
               AND i.is_holdout IS FALSE)>=3
        AND (SELECT COUNT(*) FROM private.exam_prep_assessment_items i
             WHERE i.assessment_id=a.id AND i.written_task_id IS NOT NULL
               AND i.primary_skill_code=p_skill_code AND i.reserve_role='written'
               AND i.is_holdout IS FALSE)=1
        AND NOT EXISTS (SELECT 1 FROM private.exam_prep_assessment_items i
          WHERE i.assessment_id=a.id AND i.primary_skill_code IS DISTINCT FROM p_skill_code)) THEN
   RETURN jsonb_build_object('status','unverifiable');
 END IF;

 -- Never send a previously saved written response into a replacement attempt.
 IF EXISTS (SELECT 1 FROM private.exam_prep_sessions s
   WHERE s.user_id=p_user_id AND s.program_version_id=p_program_version_id
     AND s.component_code=p_component_code AND s.assessment_id=p_assessment_id
     AND s.status='active') THEN
   RETURN jsonb_build_object('status','resume_first');
 END IF;
 IF EXISTS (SELECT 1 FROM private.exam_prep_sessions s
   WHERE s.user_id=p_user_id AND s.program_version_id=p_program_version_id
     AND s.component_code=p_component_code AND s.assessment_id=p_assessment_id
     AND s.status NOT IN ('finalized','active')) THEN
   RETURN jsonb_build_object('status','unverifiable');
 END IF;

 -- Count genuine saved results, not just "has seen" or a browser-side flag.
 WITH scored AS (
   SELECT s.id,
     COUNT(*) FILTER (WHERE r.response_kind='machine')::integer AS objectives,
     COUNT(*) FILTER (WHERE r.response_kind='machine' AND r.is_correct IS TRUE)::integer AS correct,
     COUNT(*) FILTER (WHERE r.response_kind='written' AND r.learner_artifact IS NOT NULL)::integer AS written
   FROM private.exam_prep_sessions s
   LEFT JOIN private.exam_prep_responses r ON r.session_id=s.id AND r.user_id=p_user_id
   WHERE s.user_id=p_user_id AND s.program_version_id=p_program_version_id
     AND s.component_code=p_component_code AND s.assessment_id=p_assessment_id
     AND s.status='finalized'
   GROUP BY s.id
 ) SELECT COUNT(*)::integer,
          COALESCE(BOOL_OR(objectives>=3 AND correct=objectives AND written>=1),false),
          COALESCE(BOOL_AND(objectives>=3 AND correct<=objectives AND written>=1),false)
 INTO v_attempts,v_complete,v_consistent FROM scored;
 IF v_attempts=0 THEN RETURN jsonb_build_object('status','first_learning'); END IF;
 IF NOT v_consistent THEN RETURN jsonb_build_object('status','unverifiable'); END IF;

 -- A correction that passed remediation must WAIT for its separate fresh retest.
 SELECT c.status INTO v_correction FROM private.exam_prep_correction_cases c
 WHERE c.user_id=p_user_id AND c.component_code=p_component_code
   AND c.skill_code=p_skill_code AND c.status IN ('open','remediating','reopened','retest_due')
 ORDER BY c.updated_at DESC LIMIT 1;
 IF v_correction='retest_due' THEN
   RETURN jsonb_build_object('status','fresh_retest_pending');
 END IF;
 IF v_correction IN ('open','remediating','reopened') THEN
   RETURN jsonb_build_object('status','repeat_learning','fresh_assessment',false);
 END IF;
 IF v_complete THEN RETURN jsonb_build_object('status','learning_completed'); END IF;
 RETURN jsonb_build_object('status','repeat_learning','fresh_assessment',false);
END;$body$;
REVOKE ALL ON FUNCTION private.exam_prep_learning_review_verdict_v1(uuid,bigint,text,text,bigint)
 FROM PUBLIC,anon,authenticated,service_role;
DO $gate$
BEGIN
 IF has_function_privilege('anon',
   'private.exam_prep_learning_review_verdict_v1(uuid,bigint,text,text,bigint)','EXECUTE') OR
   has_function_privilege('authenticated',
   'private.exam_prep_learning_review_verdict_v1(uuid,bigint,text,text,bigint)','EXECUTE') OR
   has_function_privilege('service_role',
   'private.exam_prep_learning_review_verdict_v1(uuid,bigint,text,text,bigint)','EXECUTE') THEN
   RAISE EXCEPTION 'learning_review_private_verdict_exposed';
 END IF;
END;$gate$;
COMMIT;
