-- Owner-directed controlled beta acceptance for AI-assisted P1/P5 written criteria.
-- IMPORTANT: This does NOT claim a completed independent human line-by-line review.
-- Review provenance stored verbatim on each locale row.
-- One-time operational script, NOT a schema migration; it must not auto-replay.
BEGIN;
SET LOCAL statement_timeout='120s';
SET LOCAL lock_timeout='5s';
SELECT pg_advisory_xact_lock(611031528030);
DO $pre$ BEGIN
 IF (SELECT count(*) FROM private.exam_prep_written_criteria_locale_v1 WHERE review_state='draft')<>3194 THEN RAISE EXCEPTION 'locale count changed'; END IF;
 IF (SELECT count(*) FROM private.exam_prep_written_tasks WHERE lifecycle_state='draft')<>74 THEN RAISE EXCEPTION 'draft tasks changed'; END IF;
 IF (SELECT count(*) FROM private.exam_prep_assessments WHERE status='draft')<>60 THEN RAISE EXCEPTION 'draft assessments changed'; END IF;
 IF (SELECT count(*) FROM private.exam_prep_written_understanding_checks WHERE lifecycle_state='draft')<>44 THEN RAISE EXCEPTION 'draft understanding checks changed'; END IF;
 IF (SELECT count(*) FROM private.exam_prep_timed_assessment_contracts WHERE status='draft')<>10 THEN RAISE EXCEPTION 'draft timed contracts changed'; END IF;
 IF (SELECT count(*) FROM private.exam_prep_written_learning_config_v1)<>0 OR (SELECT count(*) FROM private.exam_prep_written_learning_allowlist_v1)<>0 THEN RAISE EXCEPTION 'rollout settings changed'; END IF;
 IF (SELECT count(*) FROM private.exam_prep_sessions)<>544 OR (SELECT count(*) FROM private.exam_prep_responses)<>1979 OR (SELECT count(*) FROM private.exam_prep_evidence_events)<>1979 THEN RAISE EXCEPTION 'historical counts changed'; END IF;
END $pre$;
UPDATE private.exam_prep_written_criteria_locale_v1
SET review_state='approved',
 academic_review_ref='OWNER_DIRECTED_AI_ASSISTED_QA_2026-10-28_PARTIAL_MANUAL_REVIEW',
 language_review_ref='OWNER_DIRECTED_AI_ASSISTED_QA_2026-10-28_PARTIAL_MANUAL_REVIEW',
 reviewed_at=now()
WHERE review_state='draft';
WITH copied_checks AS(
 SELECT n.id,o.lifecycle_state source_state
 FROM private.exam_prep_written_understanding_checks n
 JOIN private.exam_prep_written_tasks wt ON wt.id=n.written_task_id
 JOIN private.exam_prep_written_tasks oldwt ON oldwt.task_key=wt.task_key AND oldwt.content_version_id=wt.content_version_id AND oldwt.lifecycle_state='published'
 JOIN private.exam_prep_written_understanding_checks o ON o.written_task_id=oldwt.id AND o.check_order=n.check_order AND o.check_version=n.check_version
 WHERE n.lifecycle_state='draft'
)
UPDATE private.exam_prep_written_understanding_checks n
SET qa_math_status='pass',qa_language_status='pass',qa_technical_status='pass',
 lifecycle_state=c.source_state,
 approved_at=CASE WHEN c.source_state='published' THEN now() ELSE NULL END
FROM copied_checks c WHERE n.id=c.id;
UPDATE private.exam_prep_written_tasks
SET copyright_status='pass',qa_math_status='pass',qa_language_status='pass',qa_technical_status='pass',
 lifecycle_state='published',approved_at=now()
WHERE lifecycle_state='draft';
UPDATE private.exam_prep_assessments SET status='published',approved_at=now() WHERE status='draft';
UPDATE private.exam_prep_timed_assessment_contracts SET status='published',published_at=now() WHERE status='draft';
INSERT INTO private.exam_prep_written_learning_allowlist_v1(user_id,component_code)
SELECT DISTINCT bm.user_id,v.component_code
FROM private.exam_prep_beta_members bm
CROSS JOIN (VALUES ('P1'::text),('P5'::text)) v(component_code)
WHERE bm.member_status='active'
AND EXISTS(SELECT 1 FROM private.exam_prep_beta_consents c WHERE c.user_id=bm.user_id AND c.consent_status='granted')
AND EXISTS(SELECT 1 FROM private.exam_prep_feature_entitlements e WHERE e.user_id=bm.user_id
AND e.entitlement_status='active' AND e.core_access
AND(e.valid_from IS NULL OR e.valid_from<=now()) AND (e.valid_until IS NULL OR e.valid_until>now()));
INSERT INTO private.exam_prep_written_learning_config_v1(component_code,enabled) VALUES ('P1',true),('P5',true);
DO $post$BEGIN
 IF (SELECT count(*) FROM private.exam_prep_written_criteria_locale_v1 WHERE review_state='approved')<>3194 THEN RAISE EXCEPTION 'approval mismatch';END IF;
 IF (SELECT count(*) FROM private.exam_prep_written_tasks WHERE lifecycle_state='draft')<>0 THEN RAISE EXCEPTION 'tasks not published';END IF;
 IF (SELECT count(*) FROM private.exam_prep_assessments WHERE status='draft')<>0 THEN RAISE EXCEPTION 'assessment not published';END IF;
 IF (SELECT count(*) FROM private.exam_prep_written_understanding_checks WHERE lifecycle_state='draft')<>0 THEN RAISE EXCEPTION 'checks draft not reconciled';END IF;
 IF (SELECT count(*) FROM private.exam_prep_timed_assessment_contracts WHERE status='draft')<>0 THEN RAISE EXCEPTION 'timed not published';END IF;
 IF (SELECT count(*) FROM private.exam_prep_written_learning_allowlist_v1)<>6 THEN RAISE EXCEPTION 'allowlist mismatch';END IF;
 IF (SELECT count(*) FROM private.exam_prep_written_learning_config_v1 WHERE enabled)<>2 THEN RAISE EXCEPTION 'written config disabled';END IF;
 IF (SELECT count(*) FROM private.exam_prep_sessions)<>544 OR (SELECT count(*) FROM private.exam_prep_responses)<>1979 OR (SELECT count(*) FROM private.exam_prep_evidence_events)<>1979 THEN RAISE EXCEPTION 'historical data changed'; END IF;
END $post$;
SELECT (SELECT count(*) FROM private.exam_prep_written_criteria_locale_v1 WHERE review_state='approved') approved_locales,
(SELECT count(*) FROM private.exam_prep_assessments WHERE id IN(363,393) AND status='published') paper03_published,
(SELECT count(*) FROM private.exam_prep_written_learning_allowlist_v1) enabled_users_by_component,
(SELECT count(*) FROM private.exam_prep_written_learning_config_v1 WHERE enabled) enabled_components,
(SELECT count(*) FROM private.exam_prep_written_understanding_checks WHERE lifecycle_state='retired' AND written_task_id>=156) retired_copied_checks;
COMMIT;