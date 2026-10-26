-- iClub Economics P1/P3: reuse EXACT existing consented Math beta members.
-- Fail-closed even if Economics program is enabled. No copying personal memberships.
BEGIN;
SET LOCAL lock_timeout='4s';
SET LOCAL statement_timeout='60s';

CREATE OR REPLACE FUNCTION private.iclub_exam_native_economics_beta_allowed_v1(p_user uuid)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path=''
AS $f$
 SELECT p_user IS NOT NULL AND EXISTS (
   SELECT 1
   FROM private.exam_prep_beta_cohorts c
   JOIN private.exam_prep_beta_members m
     ON m.cohort_id=c.id AND m.user_id=p_user
   JOIN private.exam_prep_beta_consents co
     ON co.cohort_id=c.id AND co.user_id=m.user_id
   JOIN private.exam_prep_feature_entitlements ent
     ON ent.user_id=m.user_id
   JOIN private.exam_prep_feature_config cfg ON cfg.id=1
   WHERE c.cohort_key='math_as_p1_p5_beta_2026_09_01'
     AND c.program_key='math_as_p1_p5'
     AND c.cohort_status IN ('canary','active')
     AND m.member_status='active'
     AND m.service_mode IN ('core','ai_assist')
     AND m.activation_wave<=c.current_wave
     AND co.consent_scope='exam_prep_controlled_beta_v1'
     AND co.consent_status='granted'
     AND co.revoked_at IS NULL
     AND ent.entitlement_status='active'
     AND ent.core_access=true
     AND (ent.valid_from IS NULL OR ent.valid_from<=now())
     AND (ent.valid_until IS NULL OR ent.valid_until>now())
     AND cfg.program_key='math_as_p1_p5'
     AND cfg.core_enabled=true
     AND cfg.kill_switch=false
     AND cfg.rollout_state<>'off'
     AND EXISTS (
       SELECT 1 FROM public.users profile WHERE profile.id=p_user
     )
     AND EXISTS (
       SELECT 1 FROM public.user_subjects us
       JOIN public.subjects subj ON subj.id=us.subject_id
       WHERE us.user_id=p_user AND subj.subject_key='economics'
         AND subj.is_active=true
     )
 );
$f$;
REVOKE ALL ON FUNCTION private.iclub_exam_native_economics_beta_allowed_v1(uuid)
 FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION private.iclub_exam_native_economics_beta_allowed_v1(uuid) TO service_role;

-- The existing multisubject shell remains unchanged for other programs.
CREATE OR REPLACE FUNCTION public.get_my_exam_prep_program_shell_v1(
 p_program_key text,p_language text DEFAULT 'ru'
) RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path=''
AS $f$
DECLARE v_user uuid; v_program record; v_papers jsonb;
BEGIN
 v_user:=auth.uid();
 IF v_user IS NULL OR p_language NOT IN ('ru','uz','en') OR p_program_key IS NULL THEN
  RETURN '{}'::jsonb;
 END IF;
 SELECT p.* INTO v_program FROM private.iclub_exam_core_programs_v1 p
 WHERE p.program_key=p_program_key AND p.integration_mode='native'
  AND p.status='published' AND p.launch_enabled=true
 ORDER BY p.created_at DESC LIMIT 1;
 IF NOT FOUND THEN RETURN '{}'::jsonb; END IF;
 -- Economics beta is restricted to the exact actively consented Math beta cohort.
 IF v_program.program_key='economics_9708' AND
    NOT private.iclub_exam_native_economics_beta_allowed_v1(v_user) THEN
  RETURN '{}'::jsonb;
 END IF;
 IF NOT EXISTS (
  SELECT 1 FROM public.user_subjects us JOIN public.subjects subj ON subj.id=us.subject_id
  WHERE us.user_id=v_user AND subj.subject_key=v_program.subject_key AND subj.is_active=true
 ) THEN RETURN '{}'::jsonb; END IF;
 SELECT jsonb_agg(jsonb_build_object(
  'code',pa.paper_code,'number',pa.paper_no,'level',pa.level_code,
  'assessment_kind',pa.assessment_kind,'duration_seconds',pa.duration_seconds,
  'total_marks',pa.total_marks,'mcq_count',pa.mcq_count,
  'sections',pa.sections
 ) ORDER BY pa.paper_no) INTO v_papers
 FROM private.iclub_exam_core_papers_v1 pa
 WHERE pa.program_key=v_program.program_key AND pa.version_key=v_program.version_key
  AND pa.status='published';
 IF v_papers IS NULL THEN RETURN '{}'::jsonb; END IF;
 RETURN jsonb_build_object(
   'contract_version','exam_prep_shared_host_v1',
   'program_key',v_program.program_key,
   'version_key',v_program.version_key,
   'subject_key',v_program.subject_key,
   'title',v_program.titles->>p_language,
   'papers',v_papers,
   'enabled',true);
END;
$f$;

-- The server's actual question issuance has the SAME beta gate. URL and
-- browser manipulations cannot bypass this per-user check.
CREATE OR REPLACE FUNCTION public.iclub_exam_native_mcq_start_v1(
  p_paper_code text,p_client_key text
) RETURNS jsonb LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path=''
AS $f$
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
    AND client_key=p_client_key;
  IF FOUND THEN RETURN jsonb_build_object('ok',true,'session_id',v_existing.id,
    'status',v_existing.status,'resumed',true); END IF;
  -- One unfinished attempt per learner+paper. Expired attempt must be finalized first.
  SELECT * INTO v_existing FROM private.iclub_exam_native_mcq_attempts_v1
  WHERE user_id=v_user AND program_key='economics_9708'
    AND version_key=v_version AND paper_code=p_paper_code AND status='active';
  IF FOUND THEN RETURN jsonb_build_object('ok',true,'session_id',v_existing.id,
    'status','active','resumed',true); END IF;

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
    'resumed',false,'total_items',30,'duration_seconds',v_limit);
EXCEPTION WHEN unique_violation THEN
  -- Concurrent retries fail closed; caller can resume through its authenticated status query.
  RETURN jsonb_build_object('ok',false,'code','concurrent_start_retry');
END;
$f$;

REVOKE ALL ON FUNCTION public.get_my_exam_prep_program_shell_v1(text,text)
 FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.get_my_exam_prep_program_shell_v1(text,text)
 TO authenticated;
REVOKE ALL ON FUNCTION public.iclub_exam_native_mcq_start_v1(text,text)
 FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.iclub_exam_native_mcq_start_v1(text,text)
 TO authenticated;

DO $assert$
DECLARE allowed_count int; outsider_count int;
BEGIN
 SELECT count(*) INTO allowed_count FROM public.users u
 WHERE private.iclub_exam_native_economics_beta_allowed_v1(u.id);
 IF allowed_count<>3 THEN
   RAISE EXCEPTION 'Expected EXACTLY three current consenting Math beta learners, found %',allowed_count;
 END IF;
 SELECT count(*) INTO outsider_count FROM public.user_subjects us
 WHERE us.subject_id=7 AND NOT private.iclub_exam_native_economics_beta_allowed_v1(us.user_id);
 IF outsider_count<1 THEN
   RAISE EXCEPTION 'Outsider rejection fixture is missing';
 END IF;
 IF NOT EXISTS (SELECT 1 FROM private.iclub_exam_core_programs_v1 p
 WHERE p.program_key='economics_9708' AND p.version_key='economics_2026_2028_v1'
   AND p.status='draft' AND p.launch_enabled=false) THEN
   RAISE EXCEPTION 'Expected dormant Economics before controlled beta release';
 END IF;
 IF has_function_privilege('anon','public.get_my_exam_prep_program_shell_v1(text,text)','EXECUTE')
 OR has_function_privilege('anon','public.iclub_exam_native_mcq_start_v1(text,text)','EXECUTE')
 OR has_function_privilege('authenticated','private.iclub_exam_native_economics_beta_allowed_v1(uuid)','EXECUTE')
 THEN RAISE EXCEPTION 'Beta access privileges are too broad'; END IF;
 IF (SELECT count(*) FROM private.exam_prep_program_versions
 WHERE program_key='math_as_p1_p5' AND status='active')<>1 THEN
   RAISE EXCEPTION 'Existing Mathematics beta version changed';
 END IF;
END $assert$;
COMMIT;
