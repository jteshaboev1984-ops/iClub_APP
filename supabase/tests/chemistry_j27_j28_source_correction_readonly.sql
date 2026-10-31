-- J27/J28 private academic gate; READ ONLY. Never expose answer texts, answer keys,
-- source JSON, learner attempts, or private archive to the public repository.
-- J27 source correction is archived privately and has a distinct recomputed digest.
WITH
j27 AS (
 SELECT count(*) source_items, count(DISTINCT syllabus_unit) distinct_units,
        count(*) FILTER (WHERE item_md5=md5(item_json::text)) correct_source_digest
 FROM private.iclub_exam_chemistry_recheck_items_v1
),j27_review AS (
 SELECT count(*) valid_review_rows
 FROM private.iclub_exam_chemistry_recheck_review_v1 r
 JOIN private.iclub_exam_chemistry_recheck_items_v1 i ON i.id=r.item_id
 WHERE r.snapshot_md5=i.item_md5 AND r.verdict='internal_ai_pass'
),j27_arch AS (
 SELECT count(*) archived_corrections,
        count(*) FILTER (WHERE corrected_item_md5<>original_item_md5
         AND EXISTS(SELECT 1 FROM private.iclub_exam_chemistry_recheck_items_v1 i
          WHERE i.id=a.item_id AND i.item_md5=a.corrected_item_md5)) correct_archived_replacement
 FROM private.iclub_exam_chemistry_j27_key_correction_archive_v1 a
),j28 AS (
 SELECT count(*) selected_questions,
        count(DISTINCT b.proposed_question_no) unique_positions,
        count(DISTINCT b.syllabus_unit) syllabus_units,
        count(*) FILTER (WHERE b.source_snapshot_md5=d.item_md5
          AND d.item_md5=md5(d.item_json::text)) source_hash_matches
 FROM private.iclub_exam_core_chemistry_p1_mock_blueprint_preview_v1 b
 JOIN private.iclub_exam_core_chemistry_p1_secure_drafts_v1 d
   ON d.draft_key=b.draft_key AND d.authoring_version=b.authoring_version
 WHERE b.planning_role='proposed_form'
)
SELECT j27.*,j27_review.*,j27_arch.*,j28.*,
 (j27.source_items=22 AND j27.distinct_units=22
  AND j27.correct_source_digest=22 AND j27_review.valid_review_rows=154
  AND j27_arch.archived_corrections=1 AND j27_arch.correct_archived_replacement=1
  AND j28.selected_questions=40 AND j28.unique_positions=40 AND j28.syllabus_units=22
  AND j28.source_hash_matches=40
  AND NOT EXISTS(SELECT 1 FROM private.iclub_exam_chemistry_recheck_release_items_v1)
  AND NOT EXISTS(SELECT 1 FROM private.iclub_exam_chemistry_recheck_attempts_v1)
  AND NOT EXISTS(SELECT 1 FROM private.iclub_exam_chemistry_p1_owner_release_items_v1)
  AND NOT EXISTS(SELECT 1 FROM private.iclub_exam_chemistry_p1_live_attempts_v1)
 ) AS closed_academic_source_gate
FROM j27 CROSS JOIN j27_review CROSS JOIN j27_arch CROSS JOIN j28;
