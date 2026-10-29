BEGIN;SET LOCAL lock_timeout='4s';
DO $g$ BEGIN
IF EXISTS(SELECT 1 FROM private.iclub_exam_chemistry_j23_as_canonical_candidate_v1 WHERE candidate_version='chemistry9701_j23_20261029_as_91_sixfield_candidate_v2')
THEN RAISE EXCEPTION 'J23 candidate v2 exists'; END IF;
IF (SELECT count(*) FROM private.iclub_exam_chemistry_j23_as_tutor_candidate_v1 u
 JOIN private.iclub_exam_chemistry_j23_as_canonical_candidate_v1 t
 ON t.candidate_version=u.candidate_version AND t.skill_key=u.skill_key
 WHERE u.candidate_version='chemistry9701_j23_20261029_as_91_sixfield_candidate_v1' AND u.title IS DISTINCT FROM t.locales->u.locale->>'title')<>7
THEN RAISE EXCEPTION 'Tutor title defect count not exactly 7'; END IF;
END $g$;
INSERT INTO private.iclub_exam_chemistry_j23_as_canonical_candidate_v1
(candidate_version,skill_key,tour_no,syllabus_point,enrichment_only,base_version,base_content_hash,
editorial_corrections_applied,locales,canonical_json_compact,content_hash,authoring_status)
SELECT 'chemistry9701_j23_20261029_as_91_sixfield_candidate_v2',skill_key,tour_no,syllabus_point,enrichment_only,base_version,base_content_hash,
editorial_corrections_applied,locales,canonical_json_compact,content_hash,authoring_status
FROM private.iclub_exam_chemistry_j23_as_canonical_candidate_v1 WHERE candidate_version='chemistry9701_j23_20261029_as_91_sixfield_candidate_v1';
WITH c AS (
SELECT u.*,coalesce(t.locales->u.locale->>'title',u.title) new_title
FROM private.iclub_exam_chemistry_j23_as_tutor_candidate_v1 u
JOIN private.iclub_exam_chemistry_j23_as_canonical_candidate_v1 t
ON t.candidate_version=u.candidate_version AND t.skill_key=u.skill_key
WHERE u.candidate_version='chemistry9701_j23_20261029_as_91_sixfield_candidate_v1'
)
INSERT INTO private.iclub_exam_chemistry_j23_as_tutor_candidate_v1
(candidate_version,skill_key,locale,tutor_card_key,base_tutor_content_version,title,
main_explanation,simple_explanation,alternative_explanation,focus_explanation,
base_tutor_source_hash,source_card_hash,tutor_candidate_digest,review_status)
SELECT 'chemistry9701_j23_20261029_as_91_sixfield_candidate_v2',skill_key,locale,tutor_card_key,base_tutor_content_version,new_title,
main_explanation,simple_explanation,alternative_explanation,focus_explanation,
base_tutor_source_hash,source_card_hash,
'sha256:'||encode(extensions.digest(convert_to(jsonb_build_object(
'skill_key',skill_key,'locale',locale,'title',new_title,'main',main_explanation,
'simple',simple_explanation,'alternative',alternative_explanation,'focus',focus_explanation)::text,'UTF8'),'sha256'),'hex'),
review_status FROM c;
DO $v$ BEGIN
IF (SELECT count(*) FROM private.iclub_exam_chemistry_j23_as_tutor_candidate_v1
WHERE candidate_version='chemistry9701_j23_20261029_as_91_sixfield_candidate_v2')<>273 THEN RAISE EXCEPTION 'J23 tutor v2 count mismatch'; END IF;
END $v$;COMMIT;
