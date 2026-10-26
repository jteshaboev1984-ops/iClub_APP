-- iClub Economics 9708: enable Paper 1 + Paper 3 only for the three
-- existing, consented Mathematics beta learners.
-- The enforced cohort gate already resides in BOTH shell and MCQ start RPC.
-- Paper 2/4 remain draft. No memberships, learner data, Math settings or
-- attempt records are copied, reset, or edited.
BEGIN;
SET LOCAL lock_timeout='4s';
SET LOCAL statement_timeout='60s';

DO $preflight$
DECLARE n int; other nUMERIC;
BEGIN
 SELECT count(*) INTO n FROM public.users u
 WHERE private.iclub_exam_native_economics_beta_allowed_v1(u.id);
 IF n<>3 THEN RAISE EXCEPTION 'Expected exactly 3 active consented Math beta users; found %',n; END IF;

 IF NOT EXISTS(SELECT 1 FROM private.iclub_exam_core_programs_v1 p
 JOIN private.iclub_subject_library_releases rel
 ON rel.subject_key=p.library_subject_key AND rel.version_key=p.library_version_key
 WHERE p.program_key='economics_9708' AND p.version_key='economics_2026_2028_v1'
 AND p.integration_mode='native' AND p.status='draft' AND p.launch_enabled=false
 AND rel.state='validated') THEN
 RAISE EXCEPTION 'Economics version or source library not ready to release';
 END IF;
 IF (SELECT count(*) FROM private.iclub_exam_core_papers_v1 pa
 WHERE pa.program_key='economics_9708' AND pa.version_key='economics_2026_2028_v1'
 AND pa.paper_code IN ('P1','P3') AND pa.status='draft' AND pa.assessment_kind='mcq'
 AND pa.mcq_count=30 AND
 ((pa.paper_code='P1' AND pa.level_code='AS' AND pa.duration_seconds=3600)
  OR (pa.paper_code='P3' AND pa.level_code='A' AND pa.duration_seconds=4500))
 )<>2 THEN RAISE EXCEPTION 'P1/P3 academic paper contract differs'; END IF;
 IF (SELECT count(*) FROM private.iclub_exam_core_question_candidates_v1
  WHERE program_key='economics_9708' AND version_key='economics_2026_2028_v1'
    AND paper_code='P1' AND status='approved'
    AND qa_scope_status='pass' AND qa_academic_status='pass'
    AND qa_language_status='pass' AND qa_format_status='pass')<>36
 OR (SELECT count(*) FROM private.iclub_exam_core_question_candidates_v1
  WHERE program_key='economics_9708' AND version_key='economics_2026_2028_v1'
    AND paper_code='P3' AND status='approved'
    AND qa_scope_status='pass' AND qa_academic_status='pass'
    AND qa_language_status='pass' AND qa_format_status='pass')<>36 THEN
 RAISE EXCEPTION 'Not all 72 P1/P3 sources meet approved QA';
 END IF;
 IF EXISTS(SELECT 1 FROM private.iclub_exam_core_question_candidates_v1
  WHERE program_key='economics_9708' AND version_key='economics_2026_2028_v1'
    AND legacy_question_id IN(8751,9044,9732)) THEN
 RAISE EXCEPTION 'Source with known error was enrolled';
 END IF;
 IF (SELECT count(*) FROM private.exam_prep_program_versions
  WHERE program_key='math_as_p1_p5' AND status='active')<>1 THEN
 RAISE EXCEPTION 'Mathematics baseline differs';
 END IF;
 IF has_function_privilege('authenticated','private.iclub_exam_native_economics_beta_allowed_v1(uuid)','EXECUTE')
 OR has_table_privilege('authenticated','private.iclub_exam_native_mcq_attempts_v1','SELECT')
 OR has_table_privilege('anon','private.iclub_exam_native_mcq_attempts_v1','SELECT') THEN
 RAISE EXCEPTION 'Private auth boundary is unsafe';
 END IF;
 IF (SELECT count(*) FROM private.iclub_exam_native_mcq_attempts_v1)<>0 THEN
 RAISE EXCEPTION 'Unexpected Economics native learner session before beta activation';
 END IF;
END $preflight$;

UPDATE private.iclub_exam_core_papers_v1
 SET status='published'
 WHERE program_key='economics_9708'
 AND version_key='economics_2026_2028_v1'
 AND paper_code IN('P1','P3') AND status='draft';

DO $papers$
BEGIN
 IF (SELECT count(*) FROM private.iclub_exam_core_papers_v1
 WHERE program_key='economics_9708' AND version_key='economics_2026_2028_v1'
 AND paper_code IN('P1','P3') AND status='published')<>2 OR
 (SELECT count(*) FROM private.iclub_exam_core_papers_v1
 WHERE program_key='economics_9708' AND version_key='economics_2026_2028_v1'
 AND paper_code IN('P2','P4') AND status='draft')<>2 THEN
 RAISE EXCEPTION 'Unexpected Economics paper state';
 END IF;
END $papers$;

UPDATE private.iclub_exam_core_programs_v1
 SET status='published',launch_enabled=true
 WHERE program_key='economics_9708'
 AND version_key='economics_2026_2028_v1'
 AND status='draft' AND launch_enabled=false;

DO $post$
DECLARE c int;
BEGIN
 IF NOT EXISTS(SELECT 1 FROM private.iclub_exam_core_programs_v1
 WHERE program_key='economics_9708' AND version_key='economics_2026_2028_v1'
 AND status='published' AND launch_enabled=true) THEN
 RAISE EXCEPTION 'Economics release state not committed';
 END IF;
 SELECT count(*) INTO c FROM public.users u
 WHERE private.iclub_exam_native_economics_beta_allowed_v1(u.id);
 IF c<>3 THEN RAISE EXCEPTION 'Math beta cohort changed during activation'; END IF;
 IF (SELECT count(*) FROM private.exam_prep_program_versions
 WHERE program_key='math_as_p1_p5' AND status='active')<>1 THEN
 RAISE EXCEPTION 'Mathematics active version unexpectedly changed';
 END IF;
END $post$;
COMMIT;
