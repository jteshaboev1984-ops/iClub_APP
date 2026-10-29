-- Private candidate v10. Read-only; NEVER publishes to learners.
WITH c AS (SELECT * FROM private.iclub_exam_chemistry_j23_as_canonical_candidate_v1 WHERE candidate_version='chemistry9701_j23_20261029_as_91_sixfield_candidate_v10'),
u AS (SELECT * FROM private.iclub_exam_chemistry_j23_as_tutor_candidate_v1 WHERE candidate_version='chemistry9701_j23_20261029_as_91_sixfield_candidate_v10'),
b AS (SELECT * FROM private.iclub_exam_chemistry_j23_as_source_bundle_v1 WHERE candidate_version='chemistry9701_j23_20261029_as_91_sixfield_candidate_v10'),
bt AS (SELECT x.card FROM b CROSS JOIN LATERAL jsonb_array_elements(theory_source_text::jsonb->'cards') x(card)),
bu AS (SELECT x.card FROM b CROSS JOIN LATERAL jsonb_array_elements(tutor_source_text::jsonb->'data') x(card))
SELECT
(SELECT count(*) FROM c) theory_expected_91,
(SELECT count(*) FROM u) tutor_expected_273,
(SELECT count(*) FROM bt) raw_theory_expected_91,
(SELECT count(*) FROM bu) raw_tutor_expected_273,
(SELECT count(*) FROM c WHERE canonical_json_compact::jsonb IS DISTINCT FROM jsonb_build_object('skill_key',skill_key,'locales',locales)
OR content_hash<>'sha256:'||encode(extensions.digest(convert_to(canonical_json_compact,'UTF8'),'sha256'),'hex')) bad_canonical_expected_0,
(SELECT count(*) FROM u JOIN c USING(skill_key) WHERE u.source_card_hash IS DISTINCT FROM c.content_hash) bad_pointers_expected_0,
(SELECT count(*) FROM u WHERE tutor_candidate_digest<>'sha256:'||encode(extensions.digest(convert_to(jsonb_build_object('skill_key',skill_key,'locale',locale,'title',title,'main',main_explanation,'simple',simple_explanation,'alternative',alternative_explanation,'focus',focus_explanation)::text,'UTF8'),'sha256'),'hex')) bad_tutor_digest_expected_0,
(SELECT count(*) FROM bt x JOIN c ON c.skill_key=x.card->>'skill_key' WHERE c.locales IS DISTINCT FROM x.card->'locales' OR c.content_hash IS DISTINCT FROM x.card->>'content_hash') bad_raw_theory_expected_0,
(SELECT count(*) FROM bu x JOIN u ON u.skill_key=x.card->>'skill_key' AND u.locale=x.card->>'locale' WHERE u.main_explanation IS DISTINCT FROM x.card->>'main_explanation' OR u.simple_explanation IS DISTINCT FROM x.card->>'simple_explanation' OR u.alternative_explanation IS DISTINCT FROM x.card->>'alternative_explanation' OR u.focus_explanation IS DISTINCT FROM x.card->>'focus_explanation' OR u.source_card_hash IS DISTINCT FROM x.card->>'source_card_hash') bad_raw_tutor_expected_0,
(SELECT theory_sha256='fa75c2ef0d026d0dccc52c877f952fc678c49e59a729ef5d74fac3336c824d6f'
AND tutor_sha256='dda526efb4721abe5bdb1820f53f8d5a7460c94aba4388cedff7a6362f085c29'
AND package_sha256='a9291d21f849167a04dd8855cd07d4c78104fc941f45bcbd3f30f53e4b6ea7bc'
AND theory_sha256=encode(extensions.digest(convert_to(theory_source_text,'UTF8'),'sha256'),'hex')
AND tutor_sha256=encode(extensions.digest(convert_to(tutor_source_text,'UTF8'),'sha256'),'hex')
AND package_sha256=encode(extensions.digest(convert_to(theory_source_text,'UTF8')||decode('00','hex')||convert_to(tutor_source_text,'UTF8'),'sha256'),'hex')
FROM b) package_integrity_expected_true,
(SELECT enabled FROM private.iclub_exam_chemistry_j24_as_theory_control_v1 WHERE id=1) j24_expected_false,
(SELECT audience_mode FROM private.iclub_exam_chemistry_j25_theory_rollout_control_v1 WHERE id=1) j25_expected_closed;