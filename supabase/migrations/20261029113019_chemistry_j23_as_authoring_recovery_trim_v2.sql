-- J23 closed authoring recovery v2: trim extracted field boundary whitespace only.
-- Append-only: preserve v1 and all original Chemistry, learners and gates.
BEGIN;
SET LOCAL lock_timeout='4s';
DO $guard$
BEGIN
 IF EXISTS(SELECT 1 FROM private.iclub_exam_chemistry_j23_as_authoring_recovery_v1
 WHERE candidate_version='chemistry9701_j23_20261029_sixfield_recovery_v2')
 THEN RAISE EXCEPTION 'J23 recovery v2 already exists'; END IF;
 IF (SELECT count(*) FROM private.iclub_exam_chemistry_j23_as_authoring_recovery_v1
     WHERE candidate_version='chemistry9701_j23_20261029_sixfield_recovery_v1')<>273
 THEN RAISE EXCEPTION 'J23 recovery v1 source count mismatch'; END IF;
END $guard$;
INSERT INTO private.iclub_exam_chemistry_j23_as_authoring_recovery_v1
(candidate_version,skill_key,locale,tour_no,syllabus_point,is_enrichment_only,base_version,
 base_content_hash,source_revision_sha256,title,explanation,original_example,common_trap,
 check_question,check_answer,recovery_status)
SELECT 'chemistry9701_j23_20261029_sixfield_recovery_v2',skill_key,locale,tour_no,syllabus_point,
 is_enrichment_only,base_version,base_content_hash,source_revision_sha256,
 btrim(title,E' \n\r\t'),explanation,
 btrim(original_example,E' \n\r\t'),
 btrim(common_trap,E' \n\r\t'),
 nullif(btrim(check_question,E' \n\r\t'),''),
 NULL,recovery_status
FROM private.iclub_exam_chemistry_j23_as_authoring_recovery_v1
WHERE candidate_version='chemistry9701_j23_20261029_sixfield_recovery_v1';
DO $verify$
DECLARE n int; bad int; q int;
BEGIN
 SELECT count(*),count(*) FILTER(WHERE check_question IS NOT NULL),
 count(*) FILTER(WHERE original_example<>btrim(original_example,E' \n\r\t')
                    OR common_trap<>btrim(common_trap,E' \n\r\t')
                    OR (check_question IS NOT NULL AND check_question<>btrim(check_question,E' \n\r\t')))
 INTO n,q,bad FROM private.iclub_exam_chemistry_j23_as_authoring_recovery_v1
 WHERE candidate_version='chemistry9701_j23_20261029_sixfield_recovery_v2';
 IF n<>273 OR q<>186 OR bad<>0 THEN
  RAISE EXCEPTION 'J23 v2 normalized recovery failed count %, questions %, padded %',n,q,bad;
 END IF;
END $verify$;
COMMIT;
