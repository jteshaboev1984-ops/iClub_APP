-- Read-only inventory of *existing* question-bank candidates for new Exam Prep programmes.
-- No assessment mapping or approval is inferred from topic text or locale completeness.
BEGIN;
SET LOCAL lock_timeout = '3s';
SET LOCAL statement_timeout = '30s';
CREATE OR REPLACE VIEW private.iclub_exam_core_question_inventory_v1
WITH (security_invoker = true) AS
SELECT
 p.program_key, p.version_key, p.subject_key,
 q.id AS question_id,
 q.topic, q.subtopic, q.difficulty, q.qtype,
 q.quality_status, q.is_active,
 (coalesce(btrim(q.question_text_en),'')<>'' AND
  coalesce(btrim(q.question_text_ru),'')<>'' AND
  coalesce(btrim(q.question_text_uz),'')<>'') AS three_languages_present,
 (coalesce(btrim(q.correct_answer),'')<>'') AS answer_present,
 CASE
   WHEN q.topic ILIKE '%(AS Level)%' THEN 'AS_explicit_unverified'
   WHEN q.topic ILIKE '%(A Level)%' THEN 'A_explicit_unverified'
   ELSE 'unclassified_needs_review'
 END AS source_level_signal,
 'needs_academic_exam_mapping'::text AS exam_readiness
FROM private.iclub_exam_core_programs_v1 p
JOIN public.subjects s ON s.subject_key=p.subject_key
JOIN public.questions q ON q.subject_id=s.id
WHERE p.integration_mode='native';
REVOKE ALL ON private.iclub_exam_core_question_inventory_v1 FROM PUBLIC,anon,authenticated;
GRANT SELECT ON private.iclub_exam_core_question_inventory_v1 TO service_role;
DO $postcheck$
BEGIN
 IF has_table_privilege('anon','private.iclub_exam_core_question_inventory_v1','SELECT')
 OR has_table_privilege('authenticated','private.iclub_exam_core_question_inventory_v1','SELECT') THEN
  RAISE EXCEPTION 'Question inventory exposed to browser';
 END IF;
END;
$postcheck$;
COMMIT;