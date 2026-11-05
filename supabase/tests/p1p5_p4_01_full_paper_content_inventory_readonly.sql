-- Mathematics P1/P5 Issue #450 P4-01: READ ONLY source-format inventory.
-- Uses published assessment CONTENT METADATA only, not learner records,
-- question texts, answers, API secrets, users, progress, or assessment writes.
-- An all-written paper is time/coverage observable, but is NOT automatically scored.
WITH paper AS (
  SELECT a.id,a.component_code,a.assessment_key,a.status,
    c.marks_available AS contract_marks,
    count(DISTINCT ai.item_order) AS item_count,
    count(DISTINCT ai.item_order)
      FILTER(WHERE ai.written_task_id IS NOT NULL) AS written_items,
    count(DISTINCT ai.item_order)
      FILTER(WHERE ai.question_id IS NOT NULL) AS objective_items,
    sum(t.max_marks) AS all_item_marks,
    coalesce(sum(t.max_marks) FILTER(
      WHERE ai.written_task_id IS NOT NULL),0) AS written_marks,
    coalesce(sum(t.max_marks) FILTER(
      WHERE ai.question_id IS NOT NULL),0) AS objective_marks
  FROM private.exam_prep_assessments a
  JOIN private.exam_prep_timed_assessment_contracts c
    ON c.assessment_id=a.id
   AND c.attempt_kind='full_paper'
  JOIN private.exam_prep_timed_assessment_items t
    ON t.assessment_id=a.id
  JOIN private.exam_prep_assessment_items ai
    ON ai.assessment_id=a.id AND ai.item_order=t.item_order
  WHERE a.component_code IN ('P1','P5') AND a.status='published'
  GROUP BY a.id,a.component_code,a.assessment_key,a.status,c.marks_available
),
summary AS (
  SELECT component_code,
    count(*) AS full_papers,
    count(*) FILTER (WHERE
       objective_items=0 AND item_count=written_items
       AND all_item_marks=contract_marks) AS written_only_papers,
    min(item_count) AS min_items,max(item_count) AS max_items,
    min(objective_marks) AS min_objective_marks,
    max(objective_marks) AS max_objective_marks,
    min(written_marks) AS min_written_marks,
    max(written_marks) AS max_written_marks,
    bool_and(all_item_marks=contract_marks) AS consistent_paper_totals
  FROM paper GROUP BY component_code
)
SELECT jsonb_build_object(
  'contract','P4_01_READ_ONLY_SOURCE_INVENTORY_NOT_A_GRADE',
  'program','Mathematics P1/P5',
  'full_paper_by_component',
    coalesce((SELECT jsonb_agg(to_jsonb(s) ORDER BY component_code)
              FROM summary s),'[]'::jsonb),
  'stage5_approved_threshold_rows',
    (SELECT count(*) FROM private.exam_prep_stage5_thresholds
     WHERE status='approved'),
  'written_score','unknown_when_ungraded',
  'objective_percent_with_zero_objective_marks','undefined_not_zero',
  'release_verdict','NO_GO_EXISTING_STATE'
) AS paper_catalogue_summary;
