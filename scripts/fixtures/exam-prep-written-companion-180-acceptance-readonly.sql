-- Production READ-ONLY fixture. Execute with SELECT only.
-- Companion MCQ is server checked but NON-CREDITING and is NOT a free-written grader.
-- The checks reference existing published governed tasks, never real learner responses.
WITH checks AS (
 SELECT written_task_id,
   count(*) AS n,
   jsonb_agg(jsonb_build_object(
     'check_order',check_order,'picked_index',correct_index,'check_version',check_version
   ) ORDER BY check_order) AS all_correct,
   jsonb_agg(jsonb_build_object(
     'check_order',check_order,
     'picked_index',(correct_index+1)%jsonb_array_length(options_en),
     'check_version',check_version
   ) ORDER BY check_order) AS all_wrong
 FROM private.exam_prep_written_understanding_checks
 WHERE lifecycle_state='published'
 GROUP BY written_task_id
), judged AS (
 SELECT written_task_id,n,
   private.exam_prep_evaluate_written_understanding_v1(written_task_id,all_correct) right_result,
   private.exam_prep_evaluate_written_understanding_v1(written_task_id,all_wrong) wrong_result,
   private.exam_prep_evaluate_written_understanding_v1(written_task_id,NULL::jsonb) omitted_result
 FROM checks
)
SELECT count(*) AS tasks_with_companion,
 sum(n) AS published_companion_items,
 count(*) FILTER(WHERE
   (right_result->>'correct')::int IS DISTINCT FROM n OR
   (right_result->>'all_correct')::boolean IS DISTINCT FROM true OR
   (right_result->>'submitted')::boolean IS DISTINCT FROM true) AS right_false_negatives,
 count(*) FILTER(WHERE
   (wrong_result->>'correct')::int IS DISTINCT FROM 0 OR
   (wrong_result->>'all_correct')::boolean IS DISTINCT FROM false OR
   (wrong_result->>'submitted')::boolean IS DISTINCT FROM true) AS wrong_false_positives,
 count(*) FILTER(WHERE
   (omitted_result->>'correct')::int IS DISTINCT FROM 0 OR
   (omitted_result->>'submitted')::boolean IS DISTINCT FROM false) AS unanswered_false_credit,
 jsonb_agg(written_task_id) FILTER(WHERE
   (right_result->>'correct')::int IS DISTINCT FROM n OR
   (wrong_result->>'correct')::int IS DISTINCT FROM 0 OR
   (omitted_result->>'correct')::int IS DISTINCT FROM 0) AS failing_task_ids
FROM judged;
