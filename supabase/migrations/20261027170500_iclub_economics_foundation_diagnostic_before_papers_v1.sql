-- Cambridge Economics beta: AS foundations check before choosing a new full Paper.
-- The standard Mathematics Exam Prep learner progression is the blueprint.
-- Existing answered/finalized and in-progress Paper attempts remain unchanged.
BEGIN;
SET LOCAL lock_timeout='4s';
SET LOCAL statement_timeout='70s';
DO $preflight$
BEGIN
 IF (SELECT count(*) FROM private.exam_prep_program_versions WHERE program_key='math_as_p1_p5' AND status='active')<>1
 OR (SELECT count(*) FROM public.users u WHERE private.iclub_exam_native_economics_beta_allowed_v1(u.id))<>3
 OR (SELECT count(*) FROM private.iclub_exam_native_mcq_attempts_v1 WHERE session_kind='paper')<>1
 THEN RAISE EXCEPTION 'Economics beta or Mathematics baseline differs from audited state'; END IF;
END;$preflight$;
CREATE OR REPLACE FUNCTION public.iclub_exam_native_mcq_start_v1(p_paper_code text, p_client_key text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
  v_user uuid:=auth.uid();
  v_version text:='economics_2026_2028_v1';
  v_id uuid:=gen_random_uuid();
  v_existing private.iclub_exam_native_mcq_attempts_v1%ROWTYPE;
  v_items jsonb;
  v_limit int;
  v_count int;
BEGIN
  IF v_user IS NULL OR p_paper_code NOT IN ('P1','P3') OR
     length(coalesce(p_client_key,'')) NOT BETWEEN 12 AND 128 THEN
     RETURN jsonb_build_object('ok',false,'code','invalid_request');
  END IF;
  IF NOT private.iclub_exam_native_mcq_enrolled_v1(v_user) THEN
     RETURN jsonb_build_object('ok',false,'code','not_enrolled');
  END IF;
  -- Gating on existing Math controlled-beta authorization; no QA open-all shortcut.
  IF NOT private.iclub_exam_native_economics_beta_allowed_v1(v_user) THEN
     RETURN jsonb_build_object('ok',false,'code','beta_not_authorized');
  END IF;
  -- Require both program and specific MCQ paper to be deliberately published.
  SELECT pa.duration_seconds INTO v_limit
  FROM private.iclub_exam_core_programs_v1 p
  JOIN private.iclub_exam_core_papers_v1 pa
    ON pa.program_key=p.program_key AND pa.version_key=p.version_key
  WHERE p.program_key='economics_9708' AND p.version_key=v_version
    AND p.integration_mode='native' AND p.status='published'
    AND p.launch_enabled=true AND pa.paper_code=p_paper_code
    AND pa.status='published' AND pa.assessment_kind='mcq'
    AND pa.mcq_count=30
    AND ((p_paper_code='P1' AND pa.level_code='AS' AND pa.duration_seconds=3600)
      OR (p_paper_code='P3' AND pa.level_code='A' AND pa.duration_seconds=4500));
  IF v_limit IS NULL THEN
     RETURN jsonb_build_object('ok',false,'code','not_available');
  END IF;
  -- Idempotency: return same attempt, never generate another one for a retry.
  SELECT * INTO v_existing FROM private.iclub_exam_native_mcq_attempts_v1
  WHERE user_id=v_user AND program_key='economics_9708'
    AND version_key=v_version AND paper_code=p_paper_code
    AND client_key=p_client_key AND session_kind='paper';
  IF FOUND THEN RETURN jsonb_build_object('ok',true,'session_id',v_existing.id,
    'status',v_existing.status,'resumed',true); END IF;
  -- One unfinished attempt per learner+paper. Expired attempt must be finalized first.
  SELECT * INTO v_existing FROM private.iclub_exam_native_mcq_attempts_v1
  WHERE user_id=v_user AND program_key='economics_9708'
    AND version_key=v_version AND paper_code=p_paper_code AND status='active' AND session_kind='paper';
  IF FOUND THEN RETURN jsonb_build_object('ok',true,'session_id',v_existing.id,
    'status','active','resumed',true); END IF;

  -- Mathematics-style progression: one subject-wide AS foundations diagnostic
  -- must be completed before issuing a NEW full Economics Paper.
  -- Resume requests for prior live Papers above remain valid.
  IF NOT EXISTS (
    SELECT 1 FROM private.iclub_exam_native_mcq_attempts_v1 baseline
    WHERE baseline.user_id=v_user
      AND baseline.program_key='economics_9708'
      AND baseline.version_key=v_version
      AND baseline.paper_code='P1'
      AND baseline.session_kind='diagnostic'
      AND baseline.status='finalized'
  ) THEN
    RETURN jsonb_build_object('ok',false,'code','foundation_diagnostic_required');
  END IF;

  WITH quotas(unit_no,n) AS (
    SELECT * FROM (VALUES (1,4),(2,12),(3,3),(4,3),(5,3),(6,5)) a
    WHERE p_paper_code='P1'
    UNION ALL
    SELECT * FROM (VALUES (7,8),(8,7),(9,4),(10,3),(11,8)) a
    WHERE p_paper_code='P3'
  ), valid_sources AS (
    SELECT q.id, qc.skill_key,sk.syllabus_unit, qc.source_snapshot_md5,
      q.question_text_en,q.question_text_ru,q.question_text_uz,
      q.options_text_en::jsonb opt_en,q.options_text_ru::jsonb opt_ru,
      q.options_text_uz::jsonb opt_uz,
      q.explanation_en,q.explanation_ru,q.explanation_uz,q.correct_answer,
      row_number() OVER(PARTITION BY qc.skill_key
        ORDER BY md5(v_id::text||q.id::text)) unique_skill_rank
    FROM private.iclub_exam_core_question_candidates_v1 qc
    JOIN private.iclub_exam_core_skills_v1 sk
      ON sk.program_key=qc.program_key AND sk.version_key=qc.version_key
      AND sk.skill_key=qc.skill_key
    JOIN private.iclub_exam_core_paper_skills_v1 ps
      ON ps.program_key=qc.program_key AND ps.version_key=qc.version_key
      AND ps.paper_code=qc.paper_code AND ps.skill_key=qc.skill_key
      AND ps.link_role=qc.link_role
    JOIN private.iclub_exam_core_question_review_v1 qr
      ON qr.program_key=qc.program_key AND qr.version_key=qc.version_key
      AND qr.legacy_question_id=qc.legacy_question_id
    JOIN public.questions q ON q.id=qc.legacy_question_id
    WHERE qc.program_key='economics_9708' AND qc.version_key=v_version
      AND qc.paper_code=p_paper_code AND qc.status='approved'
      AND qc.qa_scope_status='pass' AND qc.qa_academic_status='pass'
      AND qc.qa_language_status='pass' AND qc.qa_format_status='pass'
      AND sk.status='reviewed' AND ps.status='approved' AND sk.level_code=
        CASE WHEN p_paper_code='P1' THEN 'AS' ELSE 'A' END
      AND qc.link_role='direct'
      AND qr.source_snapshot_md5=qc.source_snapshot_md5
      AND q.subject_id=7 AND q.is_active AND q.quality_status='published'
      AND q.qtype='mcq' AND q.correct_answer ~ '^[A-D]$'
      AND jsonb_array_length(q.options_text_en::jsonb)=4
      AND jsonb_array_length(q.options_text_ru::jsonb)=4
      AND jsonb_array_length(q.options_text_uz::jsonb)=4
      AND qc.source_snapshot_md5=md5(jsonb_build_object(
        'topic',q.topic,'subtopic',q.subtopic,'difficulty',q.difficulty,'qtype',q.qtype,
        'q_en',q.question_text_en,'q_ru',q.question_text_ru,'q_uz',q.question_text_uz,
        'options_en',q.options_text_en,'options_ru',q.options_text_ru,'options_uz',q.options_text_uz,
        'correct_answer',q.correct_answer,'explanation_en',q.explanation_en,
        'explanation_ru',q.explanation_ru,'explanation_uz',q.explanation_uz,
        'image_url',q.image_url,'book_ref',q.book_ref,'quality_status',q.quality_status,
        'is_active',q.is_active
      )::text)
      AND q.id NOT IN (8751,9044,9732)
  ), unique_skills AS(
    SELECT * FROM valid_sources WHERE unique_skill_rank=1
  ), ranked AS(
    SELECT *,row_number() OVER(PARTITION BY syllabus_unit
      ORDER BY md5(v_id::text||'item'||id::text)) unit_rank
    FROM unique_skills
  ), chosen AS(
    SELECT r.* FROM ranked r JOIN quotas qu ON qu.unit_no=r.syllabus_unit
    WHERE r.unit_rank<=qu.n
  )
  SELECT jsonb_agg(jsonb_build_object(
    'source_id',id,'skill_key',skill_key,'unit',syllabus_unit,
    'snapshot_md5',source_snapshot_md5,'key',correct_answer,
    'locales',jsonb_build_object(
      'en',jsonb_build_object('question',question_text_en,'options',opt_en,'explanation',explanation_en),
      'ru',jsonb_build_object('question',question_text_ru,'options',opt_ru,'explanation',explanation_ru),
      'uz',jsonb_build_object('question',question_text_uz,'options',opt_uz,'explanation',explanation_uz)
    ),
    'display_order',(SELECT jsonb_agg(g.i ORDER BY md5(v_id::text||id::text||g.i::text))
      FROM generate_series(0,3) g(i))
  ) ORDER BY md5(v_id::text||'display'||id::text)),count(*)
  INTO v_items,v_count FROM chosen;
  IF v_count<>30 OR jsonb_array_length(v_items)<>30 THEN
    RETURN jsonb_build_object('ok',false,'code','insufficient_approved_questions');
  END IF;
  INSERT INTO private.iclub_exam_native_mcq_attempts_v1
    (id,user_id,program_key,version_key,paper_code,client_key,items,deadline_at)
  VALUES (v_id,v_user,'economics_9708',v_version,p_paper_code,p_client_key,
    v_items,clock_timestamp()+make_interval(secs=>v_limit));
  RETURN jsonb_build_object('ok',true,'session_id',v_id,'status','active',
    'resumed',false,'total_items',30,'duration_seconds',v_limit,'session_kind','paper');
EXCEPTION WHEN unique_violation THEN
  -- Concurrent retries fail closed; caller can resume through its authenticated status query.
  RETURN jsonb_build_object('ok',false,'code','concurrent_start_retry');
END;
$function$

REVOKE ALL ON FUNCTION public.iclub_exam_native_mcq_start_v1(text,text)
 FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.iclub_exam_native_mcq_start_v1(text,text) TO authenticated;
DO $check$
BEGIN
 IF has_function_privilege('anon','public.iclub_exam_native_mcq_start_v1(text,text)','EXECUTE')
 OR has_table_privilege('authenticated','private.iclub_exam_native_mcq_attempts_v1','SELECT')
 OR NOT EXISTS(SELECT 1 FROM private.iclub_exam_core_programs_v1
   WHERE program_key='economics_9708' AND version_key='economics_2026_2028_v1'
   AND status='published' AND launch_enabled=true)
 THEN RAISE EXCEPTION 'Exam Prep beta access contract changed'; END IF;
END;$check$;
COMMIT;