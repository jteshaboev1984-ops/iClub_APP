-- iClub Universal Exam Prep Core Phase 2: DORMANT review queue and fail-closed shell contract.
-- ADDITIVE ONLY. Existing Math P1/P5, learner progress, Practice/Tours and subject library untouched.
BEGIN;
SET LOCAL lock_timeout = '3s';
SET LOCAL statement_timeout = '90s';

CREATE TABLE IF NOT EXISTS private.iclub_exam_core_question_review_v1 (
  program_key text NOT NULL,
  version_key text NOT NULL,
  legacy_question_id bigint NOT NULL REFERENCES public.questions(id) ON UPDATE RESTRICT ON DELETE RESTRICT,
  source_snapshot_md5 text NOT NULL CHECK (source_snapshot_md5 ~ '^[a-f0-9]{32}$'),
  question_kind text NOT NULL CHECK (question_kind IN ('mcq','input','other')),
  source_level_hint text NOT NULL CHECK (source_level_hint IN ('AS_unverified','A_unverified','unclassified')),
  suggested_paper text CHECK (suggested_paper IN ('P1','P3')),
  locale_presence_complete boolean NOT NULL,
  source_quality_status text NOT NULL,
  source_active boolean NOT NULL,
  review_state text NOT NULL CHECK (review_state IN ('unmapped','excluded_input','excluded_unpublished')),
  review_scope text NOT NULL DEFAULT 'pending' CHECK (review_scope='pending'),
  review_answer_key text NOT NULL DEFAULT 'pending' CHECK (review_answer_key='pending'),
  review_languages text NOT NULL DEFAULT 'pending' CHECK (review_languages='pending'),
  review_exam_format text NOT NULL DEFAULT 'pending' CHECK (review_exam_format='pending'),
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY(program_key,version_key,legacy_question_id),
  FOREIGN KEY(program_key,version_key) REFERENCES private.iclub_exam_core_programs_v1(program_key,version_key)
     ON UPDATE RESTRICT ON DELETE RESTRICT,
  CHECK (suggested_paper IS NULL OR (question_kind='mcq' AND review_state='unmapped')),
  CHECK ((review_state='excluded_input' AND question_kind='input') OR review_state<>'excluded_input'),
  CHECK ((review_state='excluded_unpublished' AND (NOT source_active OR source_quality_status<>'published'))
      OR review_state<>'excluded_unpublished')
);

ALTER TABLE private.iclub_exam_core_question_review_v1 ENABLE ROW LEVEL SECURITY;
ALTER TABLE private.iclub_exam_core_question_review_v1 FORCE ROW LEVEL SECURITY;
REVOKE ALL ON private.iclub_exam_core_question_review_v1 FROM PUBLIC,anon,authenticated;
GRANT SELECT,INSERT ON private.iclub_exam_core_question_review_v1 TO service_role;

-- Treat old question texts as immutable historical evidence. No answer keys go to the client.
-- The hint never constitutes academic approval or creates an Exam Prep session/question mapping.
INSERT INTO private.iclub_exam_core_question_review_v1 (
  program_key,version_key,legacy_question_id,source_snapshot_md5,question_kind,source_level_hint,
  suggested_paper,locale_presence_complete,source_quality_status,source_active,review_state
)
SELECT p.program_key,p.version_key,q.id,
 md5(jsonb_build_object(
   'topic',q.topic,'subtopic',q.subtopic,'difficulty',q.difficulty,'qtype',q.qtype,
   'q_en',q.question_text_en,'q_ru',q.question_text_ru,'q_uz',q.question_text_uz,
   'options_en',q.options_text_en,'options_ru',q.options_text_ru,'options_uz',q.options_text_uz,
   'correct_answer',q.correct_answer,'explanation_en',q.explanation_en,
   'explanation_ru',q.explanation_ru,'explanation_uz',q.explanation_uz,
   'image_url',q.image_url,'book_ref',q.book_ref,'quality_status',q.quality_status,
   'is_active',q.is_active
 )::text),
 CASE WHEN q.qtype IN ('mcq','input') THEN q.qtype ELSE 'other' END,
 CASE WHEN q.topic ILIKE '%(AS Level)%' THEN 'AS_unverified'
      WHEN q.topic ILIKE '%(A Level)%' THEN 'A_unverified'
      ELSE 'unclassified' END,
 CASE WHEN q.qtype='mcq' AND q.quality_status='published' AND q.is_active
          AND q.topic ILIKE '%(AS Level)%' THEN 'P1'
      WHEN q.qtype='mcq' AND q.quality_status='published' AND q.is_active
          AND q.topic ILIKE '%(A Level)%' THEN 'P3'
      ELSE NULL END,
 (coalesce(btrim(q.question_text_en),'')<>''
  AND coalesce(btrim(q.question_text_ru),'')<>''
  AND coalesce(btrim(q.question_text_uz),'')<>''
  AND (q.qtype<>'mcq' OR
       (coalesce(btrim(q.options_text_en),'')<>''
        AND coalesce(btrim(q.options_text_ru),'')<>''
        AND coalesce(btrim(q.options_text_uz),'')<>''))),
 coalesce(q.quality_status,'unknown'),coalesce(q.is_active,false),
 CASE WHEN q.quality_status<>'published' OR NOT coalesce(q.is_active,false) THEN 'excluded_unpublished'
      WHEN q.qtype='input' THEN 'excluded_input'
      ELSE 'unmapped' END
FROM private.iclub_exam_core_programs_v1 p
JOIN public.subjects subj ON subj.subject_key=p.subject_key
JOIN public.questions q ON q.subject_id=subj.id
WHERE p.program_key='economics_9708' AND p.version_key='economics_2026_2028_v1'
ON CONFLICT (program_key,version_key,legacy_question_id) DO NOTHING;

-- This is a generic app-shell DTO for ALL future native subjects.
-- Mathematics remains on its existing tested host and API; no Math routing is changed.
-- The function is entirely DORMANT while launch_enabled=false.
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
REVOKE ALL ON FUNCTION public.get_my_exam_prep_program_shell_v1(text,text) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.get_my_exam_prep_program_shell_v1(text,text) TO authenticated;

DO $assert$
DECLARE v_total int; v_unmapped int; v_inactive int; v_input int; v_enabled int; v_math int;
BEGIN
 SELECT count(*),count(*) FILTER (WHERE review_state='unmapped'),
        count(*) FILTER (WHERE review_state='excluded_unpublished'),
        count(*) FILTER (WHERE review_state='excluded_input')
 INTO v_total,v_unmapped,v_inactive,v_input
 FROM private.iclub_exam_core_question_review_v1
 WHERE program_key='economics_9708' AND version_key='economics_2026_2028_v1';
 IF v_total<>1702 OR v_unmapped<>1644 OR v_inactive<>19 OR v_input<>39 THEN
  RAISE EXCEPTION 'Unexpected inventory: %, %, %, %',v_total,v_unmapped,v_inactive,v_input;
 END IF;
 SELECT count(*) INTO v_enabled FROM private.iclub_exam_core_programs_v1 WHERE launch_enabled;
 SELECT count(*) INTO v_math FROM private.exam_prep_program_versions
   WHERE program_key='math_as_p1_p5' AND status='active';
 IF v_enabled<>0 OR v_math<>1 THEN
  RAISE EXCEPTION 'Runtime isolation failed (new enabled %, Math active %)',v_enabled,v_math;
 END IF;
 IF has_table_privilege('anon','private.iclub_exam_core_question_review_v1','SELECT')
 OR has_table_privilege('authenticated','private.iclub_exam_core_question_review_v1','SELECT')
 OR has_function_privilege('anon','public.get_my_exam_prep_program_shell_v1(text,text)','EXECUTE')
 OR NOT has_function_privilege('authenticated','public.get_my_exam_prep_program_shell_v1(text,text)','EXECUTE')
 THEN RAISE EXCEPTION 'Review queue / shell permissions invalid'; END IF;
END;
$assert$;
COMMIT;