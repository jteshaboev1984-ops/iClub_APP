-- Chemistry J23 v7 exact-source reconstruction dry-run. READ ONLY, production safe.
-- This checks that both private UTF-8 blobs can reconstruct the 91 Theory and 273 Tutor
-- records, fully and without referring to the authoring staging editions.
-- NOT an offsite backup, not an actual database disaster restore, not a publication.
WITH source AS (
 SELECT theory_source_text,tutor_source_text,theory_sha256,tutor_sha256,package_sha256
 FROM private.iclub_exam_chemistry_j23_as_source_bundle_v1
 WHERE candidate_version='chemistry9701_j23_20261029_as_91_sixfield_candidate_v7'
), restored_theory AS (
 SELECT entry AS card
 FROM source CROSS JOIN LATERAL jsonb_array_elements(theory_source_text::jsonb->'cards') AS x(entry)
), restored_tutor AS (
 SELECT entry AS card
 FROM source CROSS JOIN LATERAL jsonb_array_elements(tutor_source_text::jsonb->'data') AS x(entry)
), theory_mismatch AS (
 SELECT r.card->>'skill_key' skill_key
 FROM restored_theory r
 LEFT JOIN private.iclub_exam_chemistry_j23_as_canonical_candidate_v1 c
 ON c.candidate_version='chemistry9701_j23_20261029_as_91_sixfield_candidate_v7'
 AND c.skill_key=r.card->>'skill_key'
 WHERE c.skill_key IS NULL
 OR r.card->>'content_hash'<>c.content_hash
 OR r.card->'locales' IS DISTINCT FROM c.locales
 OR r.card->>'official_syllabus_point' IS DISTINCT FROM c.syllabus_point
 OR (r.card->>'tour_no')::integer IS DISTINCT FROM c.tour_no
), tutor_mismatch AS (
 SELECT r.card->>'skill_key' skill_key
 FROM restored_tutor r
 LEFT JOIN private.iclub_exam_chemistry_j23_as_tutor_candidate_v1 u
 ON u.candidate_version='chemistry9701_j23_20261029_as_91_sixfield_candidate_v7'
 AND u.skill_key=r.card->>'skill_key' AND u.locale=r.card->>'locale'
 WHERE u.skill_key IS NULL
 OR r.card->>'source_card_hash' IS DISTINCT FROM u.source_card_hash
 OR r.card->>'title' IS DISTINCT FROM u.title
 OR r.card->>'main_explanation' IS DISTINCT FROM u.main_explanation
 OR r.card->>'simple_explanation' IS DISTINCT FROM u.simple_explanation
 OR r.card->>'alternative_explanation' IS DISTINCT FROM u.alternative_explanation
 OR r.card->>'focus_explanation' IS DISTINCT FROM u.focus_explanation
 OR r.card->>'tutor_card_key' IS DISTINCT FROM u.tutor_card_key
), restored_locale AS (
 SELECT rt.card->>'skill_key' skill_key,l.locale,l.fields
 FROM restored_theory rt CROSS JOIN LATERAL jsonb_each(rt.card->'locales') l(locale,fields)
)
SELECT (SELECT count(*) FROM restored_theory) recovered_theory_expected_91,
 (SELECT count(DISTINCT card->>'skill_key') FROM restored_theory) unique_theory_expected_91,
 (SELECT count(*) FROM restored_tutor) recovered_tutor_expected_273,
 (SELECT count(DISTINCT (card->>'skill_key')||'/'||(card->>'locale')) FROM restored_tutor) unique_tutor_expected_273,
 (SELECT count(*) FROM restored_locale) locale_entries_expected_273,
 (SELECT count(*) FROM restored_locale WHERE NOT(fields ?& ARRAY['title','explanation','original_example','common_trap','check_question','check_answer'])) incomplete_six_fields_expected_0,
 (SELECT count(*) FROM theory_mismatch) theory_reconstruction_mismatches_expected_0,
 (SELECT count(*) FROM tutor_mismatch) tutor_reconstruction_mismatches_expected_0,
 (SELECT count(*) FROM restored_tutor u WHERE NOT EXISTS(SELECT 1 FROM restored_theory t WHERE t.card->>'skill_key'=u.card->>'skill_key'
 AND t.card->>'content_hash'=u.card->>'source_card_hash')) dangling_tutor_after_restore_expected_0,
 (SELECT count(*) FROM restored_theory WHERE card->>'official_syllabus_point' LIKE '%NO_EXPLICIT%') non_exam_enrichment_expected_1,
 (SELECT theory_sha256=encode(extensions.digest(convert_to(theory_source_text,'UTF8'),'sha256'),'hex') FROM source) exact_theory_bytes_valid,
 (SELECT tutor_sha256=encode(extensions.digest(convert_to(tutor_source_text,'UTF8'),'sha256'),'hex') FROM source) exact_tutor_bytes_valid,
 (SELECT package_sha256=encode(extensions.digest(convert_to(theory_source_text,'UTF8')||decode('00','hex')||convert_to(tutor_source_text,'UTF8'),'sha256'),'hex') FROM source) exact_package_bytes_valid,
 (SELECT enabled FROM private.iclub_exam_chemistry_j24_as_theory_control_v1 WHERE id=1) j24_must_stay_false,
 (SELECT audience_mode FROM private.iclub_exam_chemistry_j25_theory_rollout_control_v1 WHERE id=1) j25_must_stay_closed;
