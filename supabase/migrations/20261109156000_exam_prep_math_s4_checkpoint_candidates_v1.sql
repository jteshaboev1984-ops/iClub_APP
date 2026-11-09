-- Issue #450 S4: 12 real academically re-derived written final-answer CHECKPOINT CANDIDATES.
-- Source fingerprints were obtained via live READ-ONLY SELECT on 2026-11-09.
-- This migration does NOT publish any student-facing answer key.
-- All 12 rows remain review_state='candidate' with expected_numeric=NULL.
-- Default S4 flags remain OFF and no stage/legacy data are changed.
-- Exact numeric keys can be approved ONLY in a later private, owner-reviewed
-- and cryptographically version-pinned operation after 12-case signed tests.
BEGIN;

DO $candidate_import$
DECLARE v_inserted int; v_verified int;
BEGIN
  WITH source_expected(component_code,assessment_key,assessment_id,assessment_version,
                       item_order,written_task_id,task_version,source_md5,part_label) AS (
    VALUES
    ('P1','p1_stage3_full_paper_01',391,'av2',2,220,'wtv2','252ad9f25a4c3c058b70c182f0fc06d1','c'),
    ('P1','p1_stage3_full_paper_01',391,'av2',4,108,'wtv1','af6abaacff9b6a926c133567fe353457','c'),
    ('P1','p1_stage4_full_paper_02',451,'av3',4,125,'wtv1','6d53aabc4d3392e28f46897177b0e0c9','c'),
    ('P1','p1_stage4_full_paper_02',451,'av3',10,131,'wtv1','b114699056ba3134ef0f3bd8d05448e0','c'),
    ('P1','p1_stage4_full_paper_03',452,'av3',6,144,'wtv1','14a5bd6a65f98c97154bb7a9a2169470','c'),
    ('P1','p1_stage4_full_paper_03',452,'av3',8,146,'wtv1','5a3cbebf082ea371f0bd53471588573c','b'),
    ('P5','p5_stage3_full_paper_01',453,'av3',2,116,'wtv1','dacf1612202f81626bdade1dfccb47fe','c'),
    ('P5','p5_stage3_full_paper_01',453,'av3',6,228,'wtv2','e54561c106ec4fd175167b0a720304eb','e'),
    ('P5','p5_stage4_full_paper_02',455,'av3',2,133,'wtv1','1f894f7e244d563b4bfdeebf266bb889','c'),
    ('P5','p5_stage4_full_paper_02',455,'av3',6,179,'wtv2','a488b9519a40ae97145da2f6c9b04990','d'),
    ('P5','p5_stage4_full_paper_03',363,'av2',2,150,'wtv1','ba3eed3979b9c877ba3757fad694151c','c'),
    ('P5','p5_stage4_full_paper_03',363,'av2',6,234,'wtv2','e63d8ae993c32eb0ce2229e467a605a7','c')
  ),
  checked AS (
    SELECT e.*
    FROM source_expected e
    JOIN private.exam_prep_assessments a
      ON a.id=e.assessment_id AND a.component_code=e.component_code
      AND a.assessment_key=e.assessment_key
      AND a.assessment_version=e.assessment_version
      AND a.status='published'
    JOIN private.exam_prep_timed_assessment_contracts c
      ON c.assessment_id=a.id AND c.attempt_kind='full_paper'
      AND c.status='published'
    JOIN private.exam_prep_assessment_items i
      ON i.assessment_id=a.id AND i.item_order=e.item_order
      AND i.written_task_id=e.written_task_id
    JOIN private.exam_prep_written_tasks w
      ON w.id=e.written_task_id AND w.task_version=e.task_version
      AND w.qa_math_status='pass'
      AND md5(w.prompt_en || E'\n' || w.rubric_json::text)=e.source_md5
  )
  INSERT INTO private.exam_prep_hybrid_s4_checkpoint_keys_v1(
    assessment_id,item_order,part_label,written_task_id,source_task_version,
    source_content_md5,review_state,academic_review_ref
  )
  SELECT assessment_id,item_order,part_label,written_task_id,task_version,
    source_md5,'candidate','s4-source-fingerprint-audit-20261109'
  FROM checked
  ON CONFLICT(assessment_id,item_order,part_label) DO NOTHING;

  SELECT count(*) INTO v_verified
  FROM private.exam_prep_hybrid_s4_checkpoint_keys_v1 k
  JOIN (VALUES
    ('P1','p1_stage3_full_paper_01',391,'av2',2,220,'wtv2','252ad9f25a4c3c058b70c182f0fc06d1','c'),
    ('P1','p1_stage3_full_paper_01',391,'av2',4,108,'wtv1','af6abaacff9b6a926c133567fe353457','c'),
    ('P1','p1_stage4_full_paper_02',451,'av3',4,125,'wtv1','6d53aabc4d3392e28f46897177b0e0c9','c'),
    ('P1','p1_stage4_full_paper_02',451,'av3',10,131,'wtv1','b114699056ba3134ef0f3bd8d05448e0','c'),
    ('P1','p1_stage4_full_paper_03',452,'av3',6,144,'wtv1','14a5bd6a65f98c97154bb7a9a2169470','c'),
    ('P1','p1_stage4_full_paper_03',452,'av3',8,146,'wtv1','5a3cbebf082ea371f0bd53471588573c','b'),
    ('P5','p5_stage3_full_paper_01',453,'av3',2,116,'wtv1','dacf1612202f81626bdade1dfccb47fe','c'),
    ('P5','p5_stage3_full_paper_01',453,'av3',6,228,'wtv2','e54561c106ec4fd175167b0a720304eb','e'),
    ('P5','p5_stage4_full_paper_02',455,'av3',2,133,'wtv1','1f894f7e244d563b4bfdeebf266bb889','c'),
    ('P5','p5_stage4_full_paper_02',455,'av3',6,179,'wtv2','a488b9519a40ae97145da2f6c9b04990','d'),
    ('P5','p5_stage4_full_paper_03',363,'av2',2,150,'wtv1','ba3eed3979b9c877ba3757fad694151c','c'),
    ('P5','p5_stage4_full_paper_03',363,'av2',6,234,'wtv2','e63d8ae993c32eb0ce2229e467a605a7','c')
  ) AS e(component_code,assessment_key,assessment_id,assessment_version,
         item_order,written_task_id,task_version,source_md5,part_label)
    ON k.assessment_id=e.assessment_id AND k.item_order=e.item_order
      AND k.part_label=e.part_label
  JOIN private.exam_prep_assessment_items i
    ON i.assessment_id=k.assessment_id AND i.item_order=k.item_order
      AND i.written_task_id=e.written_task_id
  JOIN private.exam_prep_written_tasks w
    ON w.id=k.written_task_id AND w.task_version=e.task_version
    AND md5(w.prompt_en || E'\n' || w.rubric_json::text)=e.source_md5
  WHERE k.written_task_id=e.written_task_id
    AND k.source_task_version=e.task_version
    AND k.source_content_md5=e.source_md5
    AND k.review_state='candidate'
    AND k.expected_numeric IS NULL;
  IF v_verified<>12 THEN
    RAISE EXCEPTION 'S4 checkpoint candidate catalog drift: expected 12 pinned, found %', v_verified
      USING ERRCODE='22023';
  END IF;
END;
$candidate_import$;

COMMIT;
