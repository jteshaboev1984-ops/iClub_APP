-- J23 append-only v2 exact-byte package after seven closed Tutor title fixes.
BEGIN;SET LOCAL lock_timeout='4s';SET LOCAL statement_timeout='120s';
DO $g$ BEGIN
IF EXISTS(SELECT 1 FROM private.iclub_exam_chemistry_j23_as_source_bundle_v1 WHERE candidate_version='chemistry9701_j23_20261029_as_91_sixfield_candidate_v2') THEN RAISE EXCEPTION 'v2 source bundle exists'; END IF;
IF (SELECT count(*) FROM private.iclub_exam_chemistry_j23_as_tutor_candidate_v1 WHERE candidate_version='chemistry9701_j23_20261029_as_91_sixfield_candidate_v2')<>273 THEN RAISE EXCEPTION 'v2 Tutor not complete';END IF;
END $g$;
WITH src AS(
SELECT theory_source_text,theory_sha256 FROM private.iclub_exam_chemistry_j23_as_source_bundle_v1 WHERE candidate_version='chemistry9701_j23_20261029_as_91_sixfield_candidate_v1'
),tutor AS(
SELECT jsonb_agg(jsonb_build_object('subject_key','chemistry','skill_key',skill_key,'locale',locale,
'tutor_card_key',tutor_card_key,'content_version','chemistry9701_j23_20261029_as_91_sixfield_candidate_v2','title',title,
'main_explanation',main_explanation,'simple_explanation',simple_explanation,
'alternative_explanation',alternative_explanation,'focus_explanation',focus_explanation,
'source_card_hash',source_card_hash) ORDER BY skill_key,locale)::text AS data
FROM private.iclub_exam_chemistry_j23_as_tutor_candidate_v1 WHERE candidate_version='chemistry9701_j23_20261029_as_91_sixfield_candidate_v2'
),merged AS(
SELECT src.theory_source_text,src.theory_sha256,
'{"source_theory_sha256":"' || src.theory_sha256 || '","data":' || tutor.data || '}' AS tutor_source_text
FROM src CROSS JOIN tutor
)
INSERT INTO private.iclub_exam_chemistry_j23_as_source_bundle_v1
(candidate_version,theory_source_text,tutor_source_text,theory_sha256,tutor_sha256,package_sha256,skill_count,tutor_locale_count)
SELECT 'chemistry9701_j23_20261029_as_91_sixfield_candidate_v2',theory_source_text,tutor_source_text,theory_sha256,
encode(extensions.digest(convert_to(tutor_source_text,'UTF8'),'sha256'),'hex'),
encode(extensions.digest(convert_to(theory_source_text,'UTF8')||decode('00','hex')||convert_to(tutor_source_text,'UTF8'),'sha256'),'hex'),91,273
FROM merged;
DO $v$ BEGIN
IF (SELECT theory_sha256 FROM private.iclub_exam_chemistry_j23_as_source_bundle_v1 WHERE candidate_version='chemistry9701_j23_20261029_as_91_sixfield_candidate_v2')
IS DISTINCT FROM (SELECT theory_sha256 FROM private.iclub_exam_chemistry_j23_as_source_bundle_v1 WHERE candidate_version='chemistry9701_j23_20261029_as_91_sixfield_candidate_v1')
OR (SELECT tutor_sha256 FROM private.iclub_exam_chemistry_j23_as_source_bundle_v1 WHERE candidate_version='chemistry9701_j23_20261029_as_91_sixfield_candidate_v2')
IS NOT DISTINCT FROM (SELECT tutor_sha256 FROM private.iclub_exam_chemistry_j23_as_source_bundle_v1 WHERE candidate_version='chemistry9701_j23_20261029_as_91_sixfield_candidate_v1')
THEN RAISE EXCEPTION 'Unexpected v2 bundle hashes';END IF;
END $v$;COMMIT;
