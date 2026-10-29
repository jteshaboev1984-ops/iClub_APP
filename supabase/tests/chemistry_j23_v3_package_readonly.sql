-- J23 read-only source-bundle contract. No answers, pupils or writes.
-- Run only from an authorised Supabase SQL editor. Never publish the result as approval.
WITH bundle AS (
  SELECT * FROM private.iclub_exam_chemistry_j23_as_source_bundle_v1
  WHERE candidate_version='chemistry9701_j23_20261029_as_91_sixfield_candidate_v3'
),
theory AS (
  SELECT card FROM bundle CROSS JOIN LATERAL
  jsonb_array_elements(theory_source_text::jsonb->'cards') AS card
),
tutors AS (
  SELECT tutor FROM bundle CROSS JOIN LATERAL
  jsonb_array_elements(tutor_source_text::jsonb->'data') AS tutor
)
SELECT
 (SELECT count(*) FROM theory) AS theory_cards_expected_91,
 (SELECT count(DISTINCT card->>'skill_key') FROM theory) AS unique_theory_expected_91,
 (SELECT count(*) FROM tutors) AS tutor_rows_expected_273,
 (SELECT count(DISTINCT (tutor->>'skill_key')||'/'||(tutor->>'locale')) FROM tutors) AS unique_tutors_expected_273,
 (SELECT count(*) FROM theory WHERE NOT (card ?& ARRAY[
   'skill_key','tour_no','official_syllabus_point','content_hash','locales'])) AS theory_missing_fields_expected_0,
 (SELECT count(*) FROM tutors WHERE NOT (tutor ?& ARRAY[
   'subject_key','skill_key','locale','tutor_card_key','content_version',
   'title','main_explanation','simple_explanation','alternative_explanation',
   'focus_explanation','source_card_hash'])) AS tutor_missing_fields_expected_0,
 (SELECT theory_sha256=encode(extensions.digest(
   convert_to(theory_source_text,'UTF8'),'sha256'),'hex') FROM bundle) AS exact_theory_sha_valid,
 (SELECT tutor_sha256=encode(extensions.digest(
   convert_to(tutor_source_text,'UTF8'),'sha256'),'hex') FROM bundle) AS exact_tutor_sha_valid,
 (SELECT package_sha256=encode(extensions.digest(
   convert_to(theory_source_text,'UTF8')||decode('00','hex')||
   convert_to(tutor_source_text,'UTF8'),'sha256'),'hex') FROM bundle) AS exact_package_sha_valid,
 (SELECT tutor_source_text::jsonb->>'source_theory_sha256'=theory_sha256
   FROM bundle) AS tutor_parent_sha_valid,
 (SELECT enabled FROM private.iclub_exam_chemistry_j24_as_theory_control_v1
   WHERE id=1) AS j24_expected_false,
 (SELECT audience_mode FROM private.iclub_exam_chemistry_j25_theory_rollout_control_v1
   WHERE id=1) AS j25_expected_closed;
