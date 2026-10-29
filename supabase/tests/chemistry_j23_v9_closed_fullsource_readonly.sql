-- CLOSED Chemistry J23 v9. READ-ONLY private exact-source QA.
-- Expected output: all *_errors=0, changed_theory=3, package_integrity=true,
-- J24=false, J25=closed. No rights/release/backup approval implied.
WITH
c AS (SELECT * FROM private.iclub_exam_chemistry_j23_as_canonical_candidate_v1
 WHERE candidate_version='chemistry9701_j23_20261029_as_91_sixfield_candidate_v9'),
u AS (SELECT * FROM private.iclub_exam_chemistry_j23_as_tutor_candidate_v1
 WHERE candidate_version='chemistry9701_j23_20261029_as_91_sixfield_candidate_v9'),
source AS (SELECT * FROM private.iclub_exam_chemistry_j23_as_source_bundle_v1
 WHERE candidate_version='chemistry9701_j23_20261029_as_91_sixfield_candidate_v9'),
ct AS (SELECT card FROM source s CROSS JOIN LATERAL
 jsonb_array_elements(s.theory_source_text::jsonb->'cards') x(card)),
tu AS (SELECT card FROM source s CROSS JOIN LATERAL
 jsonb_array_elements(s.tutor_source_text::jsonb->'data') x(card))
SELECT
(SELECT count(*) FROM c) canonical_theory_expected_91,
(SELECT count(*) FROM u) canonical_tutor_expected_273,
(SELECT count(*) FROM ct) source_theory_expected_91,
(SELECT count(*) FROM tu) source_tutor_expected_273,
(SELECT count(*) FROM c WHERE canonical_json_compact::jsonb IS DISTINCT FROM
 jsonb_build_object('skill_key',skill_key,'locales',locales) OR
 content_hash<>'sha256:'||encode(extensions.digest(convert_to(canonical_json_compact,'UTF8'),'sha256'),'hex')) card_hash_or_locale_errors,
(SELECT count(*) FROM ct x LEFT JOIN c ON c.skill_key=x.card->>'skill_key'
 WHERE c.skill_key IS NULL OR c.locales IS DISTINCT FROM x.card->'locales'
 OR c.content_hash IS DISTINCT FROM x.card->>'content_hash'
 OR c.syllabus_point IS DISTINCT FROM x.card->>'official_syllabus_point') source_theory_errors,
(SELECT count(*) FROM tu x LEFT JOIN u
 ON u.skill_key=x.card->>'skill_key' AND u.locale=x.card->>'locale'
 WHERE u.skill_key IS NULL OR u.title IS DISTINCT FROM x.card->>'title'
 OR u.main_explanation IS DISTINCT FROM x.card->>'main_explanation'
 OR u.simple_explanation IS DISTINCT FROM x.card->>'simple_explanation'
 OR u.alternative_explanation IS DISTINCT FROM x.card->>'alternative_explanation'
 OR u.focus_explanation IS DISTINCT FROM x.card->>'focus_explanation'
 OR u.source_card_hash IS DISTINCT FROM x.card->>'source_card_hash') source_tutor_errors,
(SELECT count(*) FROM u LEFT JOIN c ON c.skill_key=u.skill_key
 WHERE c.skill_key IS NULL OR u.source_card_hash IS DISTINCT FROM c.content_hash) tutor_pointer_errors,
(SELECT count(*) FROM u
 WHERE tutor_candidate_digest<>'sha256:'||encode(extensions.digest(
 convert_to(jsonb_build_object('skill_key',skill_key,'locale',locale,'title',title,
 'main',main_explanation,'simple',simple_explanation,
 'alternative',alternative_explanation,'focus',focus_explanation)::text,'UTF8'),
 'sha256'),'hex')) tutor_digest_errors,
(SELECT count(*) FROM c JOIN private.iclub_exam_chemistry_j23_as_canonical_candidate_v1 old USING(skill_key)
 WHERE old.candidate_version='chemistry9701_j23_20261029_as_91_sixfield_candidate_v7'
 AND c.content_hash<>old.content_hash) changed_theory_expected_3,
(SELECT count(*) FROM u JOIN private.iclub_exam_chemistry_j23_as_tutor_candidate_v1 old USING(skill_key,locale)
 WHERE old.candidate_version='chemistry9701_j23_20261029_as_91_sixfield_candidate_v7'
 AND (u.main_explanation,u.simple_explanation,u.alternative_explanation,u.focus_explanation)
 IS DISTINCT FROM (old.main_explanation,old.simple_explanation,old.alternative_explanation,old.focus_explanation)) changed_tutor_text_expected_48,
(SELECT theory_sha256='3389e6a77d0347ab34fcfb9ad01b50bfceaa916552f8da197dad7c856954d302'
 AND tutor_sha256='28e7dfe84e36136daed48635f44c32cb7a670d9243c9425785032f1ea9c2ed93'
 AND package_sha256='c17a1b193d4f713d44e77b9b1a1ce3e42427c2fdce7a99599b56dcb6da1f64eb'
 AND theory_sha256=encode(extensions.digest(convert_to(theory_source_text,'UTF8'),'sha256'),'hex')
 AND tutor_sha256=encode(extensions.digest(convert_to(tutor_source_text,'UTF8'),'sha256'),'hex')
 AND package_sha256=encode(extensions.digest(convert_to(theory_source_text,'UTF8')||decode('00','hex')||convert_to(tutor_source_text,'UTF8'),'sha256'),'hex')
 AND tutor_source_text::jsonb->>'source_theory_sha256'=theory_sha256 FROM source) package_integrity,
(SELECT count(*) FROM c WHERE skill_key='CHEM9701-13-03'
 AND locales->'en'->>'check_question' LIKE '%cis/trans%'
 AND locales->'ru'->>'check_question' LIKE '%цис/транс%'
 AND locales->'uz'->>'check_question' LIKE '%cis/trans%') cis_trans_all_languages_expected_1,
(SELECT count(*) FROM c WHERE skill_key='CHEM9701-20-03'
 AND locales->'en'->>'check_question' NOT ILIKE '%PET%'
 AND locales->'ru'->>'check_question' NOT ILIKE '%ПЭТ%'
 AND locales->'uz'->>'check_question' NOT ILIKE '%PET%') disposal_scope_all_languages_expected_1,
(SELECT count(*) FROM c WHERE skill_key='CHEM9701-20-03' AND (locales->'ru'->>'explanation' ILIKE '%ester linkages that%' OR locales->'uz'->>'explanation' ILIKE '%ester linkages that%')) ru_uz_untranslated_tail_expected_0,
(SELECT count(*) FROM private.iclub_exam_chemistry_j23_authored_checks_v1 a
 WHERE edition_key='chemistry9701_j23_20261029_academic_13_4_20_1_v9') authored_qa_rows_expected_6,
(SELECT count(*) FROM private.iclub_exam_chemistry_j23_authored_checks_v1 a
 JOIN c ON c.skill_key=a.skill_key WHERE a.edition_key='chemistry9701_j23_20261029_academic_13_4_20_1_v9'
 AND (a.question_text IS DISTINCT FROM c.locales->a.locale->>'check_question'
 OR a.answer_text IS DISTINCT FROM c.locales->a.locale->>'check_answer')) authored_qa_mismatches_expected_0,
(SELECT enabled FROM private.iclub_exam_chemistry_j24_as_theory_control_v1 WHERE id=1) j24_must_stay_false,
(SELECT audience_mode FROM private.iclub_exam_chemistry_j25_theory_rollout_control_v1 WHERE id=1) j25_must_stay_closed;
