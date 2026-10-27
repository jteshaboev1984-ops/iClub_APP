-- J09 internal-only original recheck QA. Subject expert externally absent:
-- "internal_ai_pass" explicitly must NOT imply a human referee or learner release.
DO $pre$
BEGIN
 IF (SELECT count(*) FROM private.iclub_exam_chemistry_recheck_items_v1)<>22
 OR (SELECT count(DISTINCT syllabus_unit) FROM private.iclub_exam_chemistry_recheck_items_v1)<>22
 OR (SELECT count(*) FROM private.iclub_exam_chemistry_recheck_review_v1)<>154
 OR (SELECT count(*) FROM private.iclub_exam_chemistry_recheck_revisions_v1)<>10
 THEN RAISE EXCEPTION '22 topic sources / 154 slots / private revision history required'; END IF;
 IF EXISTS(SELECT 1 FROM private.iclub_exam_chemistry_recheck_items_v1 r
 LEFT JOIN private.iclub_exam_core_skills_v1 s
 ON s.program_key=r.program_key AND s.version_key=r.version_key AND s.skill_key=r.skill_key
 WHERE s.skill_key IS NULL OR s.level_code<>'AS' OR s.syllabus_unit<>r.syllabus_unit
 OR s.syllabus_point IS DISTINCT FROM r.syllabus_point
 OR s.syllabus_point='NO_EXPLICIT_9701_OUTCOME'
 OR r.review_status<>'pending' OR r.reviewer_type<>'none'
 OR r.can_issue_learner OR r.can_credit_mastery OR r.can_be_entry_question OR r.can_be_P1_paper
 OR r.item_md5<>md5(r.item_json::text)
 OR r.item_json->>'answer_key' NOT IN ('A','B','C','D')
 OR NOT (r.item_json->'locales' ?& ARRAY['en','ru','uz'])
 OR EXISTS(SELECT 1 FROM (VALUES('en'::text),('ru'),('uz')) langs(lang)
 WHERE length(r.item_json->'locales'->langs.lang->>'stem')<30
 OR length(r.item_json->'locales'->langs.lang->>'explanation')<30
 OR (SELECT count(DISTINCT lower(trim(o.value)))
 FROM jsonb_array_elements_text(r.item_json->'locales'->langs.lang->'options')o(value))<>4)
 OR EXISTS(SELECT 1 FROM private.iclub_exam_chemistry_entry_items_v1 e
 WHERE lower(trim(e.item_json->'locales'->'en'->>'stem'))=
 lower(trim(r.item_json->'locales'->'en'->>'stem')))
 OR EXISTS(SELECT 1 FROM private.iclub_exam_core_chemistry_p1_secure_drafts_v1 p
 WHERE lower(trim(p.item_json->'locales'->'en'->>'stem'))=
 lower(trim(r.item_json->'locales'->'en'->>'stem')))
 ) THEN RAISE EXCEPTION 'Recheck academic/translation structural source QA failed'; END IF;
 IF EXISTS(SELECT 1 FROM private.iclub_exam_chemistry_recheck_review_v1 q
 JOIN private.iclub_exam_chemistry_recheck_items_v1 r ON q.item_id=r.id
 WHERE q.snapshot_md5<>r.item_md5 OR q.verdict<>'pending' OR q.reviewer_type<>'none')
 THEN RAISE EXCEPTION 'Gate snapshots not current'; END IF;
 IF (SELECT enabled FROM private.iclub_exam_chemistry_entry_release_v1 WHERE id=1)
 OR (SELECT count(*) FROM private.iclub_exam_chemistry_entry_attempts_v1)<>0
 THEN RAISE EXCEPTION 'J09 review must be closed beta'; END IF;
END $pre$;
UPDATE private.iclub_exam_chemistry_recheck_items_v1
 SET review_status='internal_ai_reviewed',reviewer_type='internal_ai'
 WHERE review_status='pending' AND reviewer_type='none';
UPDATE private.iclub_exam_chemistry_recheck_review_v1
 SET verdict='internal_ai_pass',reviewer_type='internal_ai',reviewed_at=clock_timestamp()
 WHERE verdict='pending' AND reviewer_type='none';
CREATE VIEW private.iclub_exam_chemistry_recheck_preflight_v1
WITH(security_invoker=true) AS
SELECT r.syllabus_unit,r.id,r.skill_key,r.syllabus_point,r.item_md5,r.review_status,
 (SELECT count(*) FROM private.iclub_exam_chemistry_recheck_review_v1 g
 WHERE g.item_id=r.id AND g.snapshot_md5=r.item_md5
 AND g.verdict='internal_ai_pass' AND g.reviewer_type='internal_ai')=7
 AS seven_internal_AI_reviews,
 NOT EXISTS(SELECT 1 FROM private.iclub_exam_chemistry_entry_items_v1 e
 WHERE lower(trim(e.item_json->'locales'->'en'->>'stem'))=
 lower(trim(r.item_json->'locales'->'en'->>'stem'))) AS different_from_entry_stem,
 NOT EXISTS(SELECT 1 FROM private.iclub_exam_core_chemistry_p1_secure_drafts_v1 p
 WHERE lower(trim(p.item_json->'locales'->'en'->>'stem'))=
 lower(trim(r.item_json->'locales'->'en'->>'stem'))) AS different_from_P1_stem,
 NOT(r.can_issue_learner OR r.can_credit_mastery
 OR r.can_be_entry_question OR r.can_be_P1_paper) AS unreleased_no_mastery
FROM private.iclub_exam_chemistry_recheck_items_v1 r;
REVOKE ALL ON private.iclub_exam_chemistry_recheck_preflight_v1 FROM PUBLIC,anon,authenticated;
GRANT SELECT ON private.iclub_exam_chemistry_recheck_preflight_v1 TO service_role;
DO $post$ BEGIN
 IF (SELECT count(*) FROM private.iclub_exam_chemistry_recheck_preflight_v1
 WHERE seven_internal_AI_reviews AND different_from_entry_stem
 AND different_from_P1_stem AND unreleased_no_mastery)<>22
 OR (SELECT count(*) FROM private.iclub_exam_chemistry_recheck_review_v1 WHERE verdict='internal_ai_pass')<>154
 OR has_table_privilege('authenticated','private.iclub_exam_chemistry_recheck_preflight_v1','SELECT')
 THEN RAISE EXCEPTION 'Postreview privacy or source checks failed'; END IF;
END $post$;