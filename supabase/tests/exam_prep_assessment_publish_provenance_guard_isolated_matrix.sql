-- DISPOSABLE PostgreSQL 17 CI ONLY. Run AFTER draft governance proposal installation.
-- No real learner records, source edits, backdates, or published-content changes.
\set ON_ERROR_STOP on
DO $$BEGIN
 IF current_setting('weekly_goal.isolated_db',true) IS DISTINCT FROM 'true'
 OR to_regclass('private.exam_prep_assessment_composition_reviews_v1') IS NULL THEN
  RAISE EXCEPTION 'governance_fixture_requires_disposable_installed_guard';
 END IF;
END$$;
BEGIN;
DO $matrix$
DECLARE
 v_source record; v_a bigint; v_b bigint; v_date timestamptz;
 v_hash text; v_original_hash text; v_rejected boolean;
BEGIN
 IF (SELECT count(*) FROM private.exam_prep_assessments
  WHERE id BETWEEN 1 AND 8 AND component_code='P5' AND status='published' AND approved_at IS NULL)<>8 THEN
  RAISE EXCEPTION 'original eight P5 rows unexpectedly changed before fixture';
 END IF;
 SELECT a.content_version_id,ai.question_id,ai.primary_skill_code,ai.reserve_role
 INTO STRICT v_source FROM private.exam_prep_assessments a
 JOIN private.exam_prep_assessment_items ai ON ai.assessment_id=a.id
 WHERE a.id IN (2,3,4) AND a.component_code='P5' AND ai.question_id IS NOT NULL
 ORDER BY a.id,ai.item_order LIMIT 1;
 -- The real historic migration inserted an approved row directly. Future guard
 -- must disallow that bypass without creating a new phantom sign-off.
 v_rejected:=false;
 BEGIN
  INSERT INTO private.exam_prep_assessments(content_version_id,assessment_key,assessment_version,
   component_code,assessment_type,status,title_en,title_ru,title_uz)
  VALUES(v_source.content_version_id,'ci_direct_approved','v1','P5','learning','approved',
   'Isolated only','Изолированный тест','Faqat sinov');
 EXCEPTION WHEN OTHERS THEN
  IF SQLERRM NOT LIKE 'assessment_must_start_draft_before_composition_review%' THEN RAISE; END IF;
  v_rejected:=true;
 END;
 IF NOT v_rejected THEN RAISE EXCEPTION 'new approved INSERT bypassed governance'; END IF;
 INSERT INTO private.exam_prep_assessments(content_version_id,assessment_key,assessment_version,
  component_code,assessment_type,status,title_en,title_ru,title_uz)
 VALUES(v_source.content_version_id,'ci_provenance_positive','v1','P5','learning','draft',
  'Isolated only','Изолированный тест','Faqat sinov') RETURNING id INTO v_a;
 INSERT INTO private.exam_prep_assessment_items
  (assessment_id,item_order,question_id,primary_skill_code,reserve_role,is_holdout)
 VALUES(v_a,1,v_source.question_id,v_source.primary_skill_code,v_source.reserve_role,false);
 -- A non-NULL timestamp alone is NOT evidence of actual composition review.
 v_rejected:=false;
 BEGIN
  UPDATE private.exam_prep_assessments SET status='published',approved_at=clock_timestamp() WHERE id=v_a;
 EXCEPTION WHEN OTHERS THEN
  IF SQLERRM NOT LIKE 'assessment_composition_independent_review_missing%' THEN RAISE; END IF;
  v_rejected:=true;
 END;
 IF NOT v_rejected OR (SELECT status FROM private.exam_prep_assessments WHERE id=v_a)<>'draft' THEN
  RAISE EXCEPTION 'timestamp-only publish was not rejected atomically'; END IF;
 SELECT md5(string_agg(md5(to_jsonb(i)::text),'' ORDER BY i.item_order)) INTO v_hash
 FROM private.exam_prep_assessment_items i WHERE i.assessment_id=v_a;
 v_date:=clock_timestamp();
 INSERT INTO private.exam_prep_assessment_composition_reviews_v1
 (assessment_id,assessment_version,composition_md5,reviewer_ref,evidence_ref,reviewed_at,verdict)
 VALUES(v_a,'v1',v_hash,'isolated-fixture-operator','synthetic-not-a-real-human-signoff',v_date,'approved');
 UPDATE private.exam_prep_assessments SET status='approved',approved_at=v_date WHERE id=v_a;
 UPDATE private.exam_prep_assessments SET status='published' WHERE id=v_a;
 IF (SELECT status FROM private.exam_prep_assessments WHERE id=v_a)<>'published' THEN
  RAISE EXCEPTION 'reviewed composition could not be published'; END IF;
 v_rejected:=false;
 BEGIN
  UPDATE private.exam_prep_assessment_items SET is_holdout=true WHERE assessment_id=v_a;
 EXCEPTION WHEN OTHERS THEN
  IF SQLERRM NOT LIKE 'assessment_approved_composition_is_frozen%' THEN RAISE; END IF;
  v_rejected:=true;
 END;
 IF NOT v_rejected THEN RAISE EXCEPTION 'published composition was mutated after sign-off'; END IF;
 SELECT md5(string_agg(md5(to_jsonb(i)::text),'' ORDER BY i.item_order)) INTO v_original_hash
 FROM private.exam_prep_assessment_items i WHERE i.assessment_id=v_a;
 IF v_original_hash IS DISTINCT FROM v_hash THEN RAISE EXCEPTION 'published composition drifted'; END IF;
 -- A truthful review of version A must never silently approve changed B.
 INSERT INTO private.exam_prep_assessments(content_version_id,assessment_key,assessment_version,
  component_code,assessment_type,status,title_en,title_ru,title_uz)
 VALUES(v_source.content_version_id,'ci_provenance_stale','v1','P5','learning','draft',
  'Isolated stale','Изолированный тест','Faqat sinov') RETURNING id INTO v_b;
 INSERT INTO private.exam_prep_assessment_items
 (assessment_id,item_order,question_id,primary_skill_code,reserve_role,is_holdout)
 VALUES(v_b,1,v_source.question_id,v_source.primary_skill_code,v_source.reserve_role,false);
 SELECT md5(string_agg(md5(to_jsonb(i)::text),'' ORDER BY i.item_order)) INTO v_hash
 FROM private.exam_prep_assessment_items i WHERE i.assessment_id=v_b;
 v_date:=clock_timestamp();
 INSERT INTO private.exam_prep_assessment_composition_reviews_v1
 (assessment_id,assessment_version,composition_md5,reviewer_ref,evidence_ref,reviewed_at,verdict)
 VALUES(v_b,'v1',v_hash,'isolated-fixture-operator','synthetic-stale-review-only',v_date,'approved');
 INSERT INTO private.exam_prep_assessment_items
 (assessment_id,item_order,question_id,primary_skill_code,reserve_role,is_holdout)
 VALUES(v_b,2,v_source.question_id,v_source.primary_skill_code,v_source.reserve_role,false);
 v_rejected:=false;
 BEGIN
  UPDATE private.exam_prep_assessments SET status='approved',approved_at=v_date WHERE id=v_b;
 EXCEPTION WHEN OTHERS THEN
  IF SQLERRM NOT LIKE 'assessment_composition_independent_review_missing%' THEN RAISE; END IF;
  v_rejected:=true;
 END;
 IF NOT v_rejected THEN RAISE EXCEPTION 'stale review approved changed item composition'; END IF;
 IF (SELECT count(*) FROM private.exam_prep_assessments
  WHERE id BETWEEN 1 AND 8 AND component_code='P5' AND status='published' AND approved_at IS NULL)<>8 THEN
  RAISE EXCEPTION 'pre-existing P5 rows changed during future-only governance fixture'; END IF;
 RAISE NOTICE 'GOVERNANCE TEST GREEN: direct approved insert, timestamp-only publish, stale fingerprint and published edits denied; genuine synthetic attested path allowed';
END;$matrix$;
ROLLBACK;
DO $$BEGIN
 IF EXISTS(SELECT 1 FROM private.exam_prep_assessments WHERE assessment_key LIKE 'ci_provenance_%')
 OR EXISTS(SELECT 1 FROM private.exam_prep_assessments WHERE assessment_key='ci_direct_approved')
 OR EXISTS(SELECT 1 FROM private.exam_prep_assessment_composition_reviews_v1) THEN
  RAISE EXCEPTION 'governance fixture leaked artificial rows';
 END IF;
 RAISE NOTICE 'GOVERNANCE SYNTHETIC DATA ROLLBACK GREEN';
END$$;
