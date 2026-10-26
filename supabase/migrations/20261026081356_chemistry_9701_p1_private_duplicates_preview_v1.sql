-- Exact private view definition restored from the live database after safe-branch rewind.
-- This migration is already registered/applied in production: archival source for new environments.
-- NO question bodies or answer keys are embedded here.
DO $pre$ BEGIN
 IF to_regclass('private.iclub_exam_core_chemistry_p1_duplicates_preview_v1') IS NOT NULL
 THEN RAISE EXCEPTION 'Refuse to overwrite pre-existing Chemistry preview'; END IF;
 IF NOT EXISTS(SELECT 1 FROM private.iclub_exam_core_programs_v1
 WHERE program_key='chemistry_9701' AND status='draft' AND launch_enabled=false)
 THEN RAISE EXCEPTION 'Chemistry draft/OFF requirement failed'; END IF;
END $pre$;
CREATE VIEW private.iclub_exam_core_chemistry_p1_duplicates_preview_v1
WITH (security_invoker=true,security_barrier=true) AS
 WITH source_questions AS (
         SELECT q.id,
            q.correct_answer,
            q.options_text_en,
            lower(regexp_replace(btrim(q.question_text_en), '\s+'::text, ' '::text, 'g'::text)) AS normalized_stem
           FROM private.iclub_exam_core_question_review_v1 r
             JOIN public.questions q ON q.id = r.legacy_question_id
          WHERE r.program_key = 'chemistry_9701'::text AND r.version_key = 'chemistry_2025_2027_v1'::text AND r.review_state = 'unmapped'::text AND r.question_kind = 'mcq'::text
        ), grouped AS (
         SELECT source_questions.normalized_stem,
            count(*) AS n,
            array_agg(source_questions.id ORDER BY source_questions.id) AS legacy_question_ids,
            min(source_questions.id) AS lowest_legacy_id,
            count(DISTINCT source_questions.correct_answer) AS answer_letters_count,
            count(DISTINCT source_questions.options_text_en) AS option_sets_count
           FROM source_questions
          GROUP BY source_questions.normalized_stem
         HAVING count(*) > 1
        )
 SELECT normalized_stem,
    n AS occurrence_count,
    legacy_question_ids,
    lowest_legacy_id,
    answer_letters_count > 1 AS different_answer_letters,
    option_sets_count > 1 AS different_option_sets,
    ( SELECT array_agg(DISTINCT c.legacy_question_id ORDER BY c.legacy_question_id) AS array_agg
           FROM private.iclub_exam_core_question_candidates_v1 c
          WHERE c.program_key = 'chemistry_9701'::text AND c.version_key = 'chemistry_2025_2027_v1'::text AND c.status = 'candidate'::text AND (c.legacy_question_id = ANY (g.legacy_question_ids))) AS staged_candidate_ids,
    false AS academically_deduplicated,
    false AS authorized_for_learner_selection
   FROM grouped g;
REVOKE ALL ON private.iclub_exam_core_chemistry_p1_duplicates_preview_v1 FROM PUBLIC,anon,authenticated;
GRANT SELECT ON private.iclub_exam_core_chemistry_p1_duplicates_preview_v1 TO service_role;
COMMENT ON VIEW private.iclub_exam_core_chemistry_p1_duplicates_preview_v1 IS
'Chemistry academic preview only; never a learner task/grade/mastery authority.';
DO $post$ BEGIN
 IF (SELECT count(*) FROM private.iclub_exam_core_chemistry_p1_duplicates_preview_v1)<>37
 THEN RAISE EXCEPTION 'Unexpected Chemistry preview view counts'; END IF;
 IF has_table_privilege('anon','private.iclub_exam_core_chemistry_p1_duplicates_preview_v1','SELECT')
 OR has_table_privilege('authenticated','private.iclub_exam_core_chemistry_p1_duplicates_preview_v1','SELECT')
 THEN RAISE EXCEPTION 'Private preview has unsafe reader privileges'; END IF;
END $post$;
