-- Chemistry 9701 J23 v7: exact field equality against protected private v7 source.
-- READ ONLY. Intended to run AFTER private staging, BEFORE any release decision.
-- Public repository contains this SQL only, never the protected source values.
-- A false stage_matches_protected_v7 is a hard STOP; true is still NOT a learner release.
WITH
 expected_theory AS (
  SELECT skill_key,tour_no,syllabus_point,content_hash,locales
  FROM private.iclub_exam_chemistry_j23_as_canonical_candidate_v1
  WHERE candidate_version='chemistry9701_j23_20261029_as_91_sixfield_candidate_v7'
 ), expected_tutor AS (
  SELECT skill_key,locale,tutor_card_key,title,main_explanation,
         simple_explanation,alternative_explanation,focus_explanation,source_card_hash
  FROM private.iclub_exam_chemistry_j23_as_tutor_candidate_v1
  WHERE candidate_version='chemistry9701_j23_20261029_as_91_sixfield_candidate_v7'
 ),actual_theory AS (
  SELECT skill_key,tour_no,syllabus_point,content_hash,locales
  FROM private.iclub_subject_library_theory
  WHERE subject_key='chemistry'
    AND version_key='chemistry9701_j23_20261029_as_91_sixfield_candidate_v7'
 ),actual_tutor AS (
  SELECT skill_key,locale,tutor_card_key,title,main_explanation,
         simple_explanation,alternative_explanation,focus_explanation,source_card_hash
  FROM private.iclub_subject_library_tutor
  WHERE subject_key='chemistry'
    AND version_key='chemistry9701_j23_20261029_as_91_sixfield_candidate_v7'
 ),snapshot AS (
  SELECT
   (SELECT count(*) FROM expected_theory) source_theory,
   (SELECT count(*) FROM expected_tutor) source_tutor,
   (SELECT count(*) FROM actual_theory) staged_theory,
   (SELECT count(*) FROM actual_tutor) staged_tutor,
   (SELECT count(*) FROM expected_theory src LEFT JOIN actual_theory dst USING(skill_key)
    WHERE dst.skill_key IS NULL OR src.content_hash IS DISTINCT FROM dst.content_hash
       OR src.tour_no IS DISTINCT FROM dst.tour_no
       OR src.syllabus_point IS DISTINCT FROM dst.syllabus_point
       OR src.locales IS DISTINCT FROM dst.locales) theory_missing_or_changed,
   (SELECT count(*) FROM actual_theory dst LEFT JOIN expected_theory src USING(skill_key)
    WHERE src.skill_key IS NULL) unexpected_theory,
   (SELECT count(*) FROM expected_tutor src LEFT JOIN actual_tutor dst USING(skill_key,locale)
    WHERE dst.skill_key IS NULL OR src.tutor_card_key IS DISTINCT FROM dst.tutor_card_key
       OR src.title IS DISTINCT FROM dst.title
       OR src.main_explanation IS DISTINCT FROM dst.main_explanation
       OR src.simple_explanation IS DISTINCT FROM dst.simple_explanation
       OR src.alternative_explanation IS DISTINCT FROM dst.alternative_explanation
       OR src.focus_explanation IS DISTINCT FROM dst.focus_explanation
       OR src.source_card_hash IS DISTINCT FROM dst.source_card_hash) tutor_missing_or_changed,
   (SELECT count(*) FROM actual_tutor dst LEFT JOIN expected_tutor src USING(skill_key,locale)
    WHERE src.skill_key IS NULL) unexpected_tutor,
   (SELECT package_sha256 FROM private.iclub_subject_library_releases
    WHERE subject_key='chemistry'
      AND version_key='chemistry9701_j23_20261029_as_91_sixfield_candidate_v7') staged_package_sha,
   (SELECT enabled FROM private.iclub_exam_chemistry_j24_as_theory_control_v1 WHERE id=1) j24_enabled,
   (SELECT audience_mode FROM private.iclub_exam_chemistry_j25_theory_rollout_control_v1 WHERE id=1) j25_mode
 )
SELECT *,
 (source_theory=91 AND source_tutor=273
  AND staged_theory=91 AND staged_tutor=273
  AND theory_missing_or_changed=0 AND unexpected_theory=0
  AND tutor_missing_or_changed=0 AND unexpected_tutor=0
  AND staged_package_sha='197400f1701b424d541bb55c001bfe62eb27a45a1204b3730512a618e7179e27'
  AND j24_enabled=false AND j25_mode='closed') AS stage_matches_protected_v7
FROM snapshot;
