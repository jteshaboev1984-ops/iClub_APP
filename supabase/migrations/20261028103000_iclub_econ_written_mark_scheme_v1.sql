-- iClub Economics written mark scheme aligned to Cambridge Economics 9708 (2026–2028).
-- IMPORTANT: Original iClub practice tasks, original allocated Section A part marks.
-- AO1/AO2 vs AO3 split for essay uses Cambridge 2025 published levels-based approach;
-- this is not an official Cambridge mark scheme for these bespoke questions.
-- Additive only: DO NOT edit task texts, historical plan items, access or releases.
BEGIN;
SET LOCAL lock_timeout='4s';
SET LOCAL statement_timeout='55s';
CREATE TABLE private.iclub_exam_written_mark_scheme_v1 (
 program_key text NOT NULL,
 version_key text NOT NULL,
 task_key text NOT NULL,
 task_version text NOT NULL,
 max_marks integer NOT NULL CHECK (max_marks BETWEEN 1 AND 20),
 ao12_marks integer NOT NULL CHECK (ao12_marks BETWEEN 0 AND 20),
 ao3_marks integer NOT NULL CHECK (ao3_marks BETWEEN 0 AND 20),
 marking_style text NOT NULL CHECK (marking_style IN ('point','levels')),
 task_sha256 text NOT NULL CHECK (task_sha256 ~ '^[0-9a-f]{64}$'),
 scheme_basis text NOT NULL,
 created_at timestamptz NOT NULL DEFAULT now(),
 PRIMARY KEY (program_key,version_key,task_key,task_version),
 CHECK (ao12_marks+ao3_marks=max_marks)
);
ALTER TABLE private.iclub_exam_written_mark_scheme_v1 ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON private.iclub_exam_written_mark_scheme_v1 FROM PUBLIC,anon,authenticated;
DO $pre$ BEGIN
 IF (SELECT count(*) FROM private.iclub_exam_core_written_tasks_v1
 WHERE program_key='economics_9708'
 AND task_version='economics_9708_written_editorial_candidate_v3_20261027'
 AND status='approved' AND academic_review='approved'
 AND language_review='approved' AND source_review='approved')<>22
 THEN RAISE EXCEPTION 'approved_editorial_bank_changed'; END IF;
 IF (SELECT count(*) FROM private.iclub_exam_core_written_tasks_v1
 WHERE program_key='economics_9708' AND release_enabled)<>12
 THEN RAISE EXCEPTION 'beta_release_baseline_changed'; END IF;
END;$pre$;
WITH allocation(task_key,max_marks,ao12_marks,ao3_marks) AS (
 VALUES ('P2.A.a',2,2,0),
('P2.A.b',2,2,0),
('P2.A.c',4,4,0),
('P2.A.d',4,4,0),
('P2.A.e',3,3,0),
('P2.A.f',5,3,2),
('P2.B1.a',8,8,0),
('P2.B1.b',12,8,4),
('P2.B2.a',8,8,0),
('P2.B2.b',12,8,4),
('P2.C1.a',8,8,0),
('P2.C1.b',12,8,4),
('P2.C2.a',8,8,0),
('P2.C2.b',12,8,4),
('P4.A.a',5,4,1),
('P4.A.b',4,4,0),
('P4.A.c',5,4,1),
('P4.A.d',6,4,2),
('P4.B1',20,14,6),
('P4.B2',20,14,6),
('P4.C1',20,14,6),
('P4.C2',20,14,6)
)
INSERT INTO private.iclub_exam_written_mark_scheme_v1(
 program_key,version_key,task_key,task_version,max_marks,ao12_marks,
 ao3_marks,marking_style,task_sha256,scheme_basis)
SELECT t.program_key,t.version_key,t.task_key,t.task_version,
 a.max_marks,a.ao12_marks,a.ao3_marks,
 CASE WHEN t.task_key LIKE '%.A.%' THEN 'point' ELSE 'levels' END,
 encode(pg_catalog.sha256(pg_catalog.convert_to(
 t.questions::text||'|'||t.answer_requirements::text,'UTF8')),'hex'),
 'iclub_original_9708_2026_2028_cambridge_aligned_v1'
FROM allocation a JOIN private.iclub_exam_core_written_tasks_v1 t
 ON t.task_key=a.task_key AND t.program_key='economics_9708'
 AND t.task_version='economics_9708_written_editorial_candidate_v3_20261027';

-- Override only the protected criterion-return gateway. All content remains
-- behind the existing owner/plan/source/version checks. No new public table SELECT.
CREATE OR REPLACE FUNCTION public.iclub_exam_written_criteria_v1(
 p_item_id uuid,p_task_key text,p_task_version text,p_task_token uuid,
 p_language text DEFAULT 'en'
) RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path=''
AS $function$
DECLARE v_result jsonb;v_scheme jsonb;v_lang text;
BEGIN
 IF auth.uid() IS NULL THEN
   RETURN jsonb_build_object('ok',false,'code','not_authorized');
 END IF;
 v_result:=private.iclub_exam_core_written_criteria_v1(
   p_item_id,p_task_key,p_task_version,p_task_token,p_language);
 IF NOT EXISTS (
   SELECT 1 FROM private.iclub_exam_core_written_plan_items_v1 i
   WHERE i.id=p_item_id AND i.learner_user_id=auth.uid()
     AND i.task_key=p_task_key AND i.task_version=p_task_version
     AND i.task_token=p_task_token
     AND private.iclub_exam_written_source_ready_v1(
       i.program_key,i.version_key,i.task_key,i.task_version)
 ) THEN RETURN jsonb_build_object('available',false); END IF;
 IF v_result->>'available'<>'true' THEN RETURN v_result; END IF;
 v_lang:=CASE WHEN p_language IN ('en','ru','uz') THEN p_language ELSE 'en' END;
 SELECT jsonb_build_object(
   'max_marks',m.max_marks,'ao12_marks',m.ao12_marks,
   'ao3_marks',m.ao3_marks,'marking_style',m.marking_style,
   'indicative_points',t.answer_requirements->v_lang,
   'basis',m.scheme_basis,'official_cambridge',false)
 INTO v_scheme
 FROM private.iclub_exam_core_written_plan_items_v1 i
 JOIN private.iclub_exam_core_written_tasks_v1 t
 ON t.program_key=i.program_key AND t.version_key=i.version_key
 AND t.task_key=i.task_key AND t.task_version=i.task_version
 JOIN private.iclub_exam_written_mark_scheme_v1 m
 ON m.program_key=t.program_key AND m.version_key=t.version_key
 AND m.task_key=t.task_key AND m.task_version=t.task_version
 WHERE i.id=p_item_id AND i.learner_user_id=auth.uid()
 AND i.task_key=p_task_key AND i.task_version=p_task_version
 AND i.task_token=p_task_token
 AND m.task_sha256=encode(pg_catalog.sha256(pg_catalog.convert_to(
 t.questions::text||'|'||t.answer_requirements::text,'UTF8')),'hex');
 IF v_scheme IS NULL THEN RETURN v_result; END IF;
 RETURN v_result||jsonb_build_object('mark_scheme',v_scheme);
END;
$function$;
REVOKE ALL ON FUNCTION public.iclub_exam_written_criteria_v1(uuid,text,text,uuid,text)
  FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.iclub_exam_written_criteria_v1(uuid,text,text,uuid,text)
  TO authenticated;
DO $post$ BEGIN
 IF (SELECT count(*) FROM private.iclub_exam_written_mark_scheme_v1)<>22
 THEN RAISE EXCEPTION 'marking_scheme_count'; END IF;
 IF (SELECT sum(max_marks) FROM private.iclub_exam_written_mark_scheme_v1 WHERE task_key LIKE 'P2.A.%')<>20
 OR (SELECT sum(max_marks) FROM private.iclub_exam_written_mark_scheme_v1 WHERE task_key LIKE 'P4.A.%')<>20
 THEN RAISE EXCEPTION 'section_a_total_not_20'; END IF;
 IF (SELECT count(*) FROM private.iclub_exam_written_mark_scheme_v1
 WHERE marking_style='levels' AND ao12_marks NOT IN (8,14))<>0
 THEN RAISE EXCEPTION 'essay_levels_invalid'; END IF;
 IF has_table_privilege('authenticated','private.iclub_exam_written_mark_scheme_v1','SELECT')
 OR has_function_privilege('anon','public.iclub_exam_written_criteria_v1(uuid,text,text,uuid,text)','EXECUTE')
 THEN RAISE EXCEPTION 'rubric_privilege_leak'; END IF;
END;$post$;
COMMIT;