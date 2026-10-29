-- J23 CLOSED canonical six-field candidate, exactly 91 Theory + 273 Tutor locale links.
-- Protect live Chemistry source 154, historic hashes, all learners, and rollout switches.
-- Only a staged authoring candidate; no student publication and no academic signoff.
BEGIN;
SET LOCAL lock_timeout='4s';
SET LOCAL statement_timeout='120s';
DO $guard$ BEGIN
 IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='private'
   AND table_name IN('iclub_exam_chemistry_j23_as_canonical_candidate_v1','iclub_exam_chemistry_j23_as_tutor_candidate_v1'))
 THEN RAISE EXCEPTION 'J23 canonical candidate table exists: never reinstall or overwrite'; END IF;
 IF (SELECT enabled FROM private.iclub_exam_chemistry_j24_as_theory_control_v1 WHERE id=1) IS DISTINCT FROM false
 OR (SELECT audience_mode FROM private.iclub_exam_chemistry_j25_theory_rollout_control_v1 WHERE id=1) IS DISTINCT FROM 'closed'
 THEN RAISE EXCEPTION 'J23 must remain CLOSED'; END IF;
 IF (SELECT count(*) FROM private.iclub_exam_chemistry_j23_as_authoring_recovery_v1
   WHERE candidate_version='chemistry9701_j23_20261029_sixfield_recovery_v2')<>273
 THEN RAISE EXCEPTION 'Recovery v2 not exactly 273 locale source rows'; END IF;
END $guard$;
CREATE TABLE private.iclub_exam_chemistry_j23_as_canonical_candidate_v1(
 candidate_version text NOT NULL,
 skill_key text NOT NULL,
 tour_no int NOT NULL,
 syllabus_point text NOT NULL,
 enrichment_only boolean NOT NULL,
 base_version text NOT NULL,
 base_content_hash text NOT NULL CHECK(base_content_hash ~ '^sha256:[a-f0-9]{64}$'),
 editorial_corrections_applied boolean NOT NULL,
 locales jsonb NOT NULL CHECK(jsonb_typeof(locales)='object' AND locales ?& ARRAY['en','ru','uz']),
 canonical_json_compact text NOT NULL,
 content_hash text NOT NULL CHECK(content_hash ~ '^sha256:[a-f0-9]{64}$'),
 authoring_status text NOT NULL DEFAULT 'candidate_pending_independent_science_trilingual_rights_tutor_signoff'
  CHECK(authoring_status='candidate_pending_independent_science_trilingual_rights_tutor_signoff'),
 created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 PRIMARY KEY(candidate_version,skill_key)
);
CREATE TABLE private.iclub_exam_chemistry_j23_as_tutor_candidate_v1(
 candidate_version text NOT NULL,
 skill_key text NOT NULL,
 locale text NOT NULL CHECK(locale IN('en','ru','uz')),
 tutor_card_key text NOT NULL,
 base_tutor_content_version text NOT NULL,
 title text NOT NULL,
 main_explanation text NOT NULL,
 simple_explanation text NOT NULL,
 alternative_explanation text NOT NULL,
 focus_explanation text NOT NULL,
 base_tutor_source_hash text NOT NULL,
 source_card_hash text NOT NULL CHECK(source_card_hash ~ '^sha256:[a-f0-9]{64}$'),
 tutor_candidate_digest text NOT NULL CHECK(tutor_candidate_digest ~ '^sha256:[a-f0-9]{64}$'),
 review_status text NOT NULL DEFAULT 'pending_independent_tutor_source_alignment'
  CHECK(review_status='pending_independent_tutor_source_alignment'),
 created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 PRIMARY KEY(candidate_version,skill_key,locale),
 FOREIGN KEY(candidate_version,skill_key)
 REFERENCES private.iclub_exam_chemistry_j23_as_canonical_candidate_v1(candidate_version,skill_key) ON DELETE RESTRICT
);
ALTER TABLE private.iclub_exam_chemistry_j23_as_canonical_candidate_v1 ENABLE ROW LEVEL SECURITY;
ALTER TABLE private.iclub_exam_chemistry_j23_as_tutor_candidate_v1 ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON private.iclub_exam_chemistry_j23_as_canonical_candidate_v1 FROM PUBLIC,anon,authenticated;
REVOKE ALL ON private.iclub_exam_chemistry_j23_as_tutor_candidate_v1 FROM PUBLIC,anon,authenticated;

WITH ranked AS (
 SELECT a.*,row_number() OVER(PARTITION BY skill_key,locale ORDER BY
 CASE edition_key
 WHEN 'chemistry9701_j23_20261029_existing_answers_c_ru_corrections_v2' THEN 0
 WHEN 'chemistry9701_j23_20261029_rephrased_a_v1' THEN 1
 WHEN 'chemistry9701_j23_20261029_rephrased_b_v1' THEN 1
 WHEN 'chemistry9701_j23_20261029_checks_29_v1' THEN 2
 ELSE 5 END, edition_key) AS priority
 FROM private.iclub_exam_chemistry_j23_authored_checks_v1 a
 WHERE edition_key IN(
 'chemistry9701_j23_20261029_existing_answers_c_ru_corrections_v2',
 'chemistry9701_j23_20261029_rephrased_a_v1','chemistry9701_j23_20261029_rephrased_b_v1',
 'chemistry9701_j23_20261029_checks_29_v1',
 'chemistry9701_j23_20261029_existing_answers_a_v1',
 'chemistry9701_j23_20261029_existing_answers_b_v1',
 'chemistry9701_j23_20261029_existing_answers_c_v1',
 'chemistry9701_j23_20261029_existing_answers_d_v1')
),
localized AS(
 SELECT r.skill_key,r.locale,r.tour_no,r.syllabus_point,r.is_enrichment_only,
 r.base_version,r.base_content_hash,r.source_revision_sha256,
 r.title,r.explanation,r.original_example,r.common_trap,
 a.question_text,a.answer_text
 FROM private.iclub_exam_chemistry_j23_as_authoring_recovery_v1 r
 JOIN ranked a ON a.skill_key=r.skill_key AND a.locale=r.locale AND a.priority=1
 AND a.source_candidate_version=r.candidate_version AND a.base_content_hash=r.base_content_hash
 WHERE r.candidate_version='chemistry9701_j23_20261029_sixfield_recovery_v2'
),
packed AS(
 SELECT skill_key,min(tour_no) tour_no,min(syllabus_point) syllabus_point,
 bool_or(is_enrichment_only) enrichment_only,min(base_version) base_version,
 min(base_content_hash) base_content_hash,
 bool_or(source_revision_sha256 IS NOT NULL) has_correction,
 jsonb_object_agg(locale,jsonb_build_object(
 'title',title,'explanation',explanation,'original_example',original_example,
 'common_trap',common_trap,'check_question',question_text,'check_answer',answer_text)) AS locales,
 string_agg(
 to_jsonb(locale)::text||':{'||
 '"check_answer":'||to_jsonb(answer_text)::text||','||
 '"check_question":'||to_jsonb(question_text)::text||','||
 '"common_trap":'||to_jsonb(common_trap)::text||','||
 '"explanation":'||to_jsonb(explanation)::text||','||
 '"original_example":'||to_jsonb(original_example)::text||','||
 '"title":'||to_jsonb(title)::text||'}'
 ,',' ORDER BY locale COLLATE "C") AS locales_compact,
 count(*) AS language_count
 FROM localized GROUP BY skill_key
),
canonical AS(
 SELECT p.*,
 '{"locales":{'||p.locales_compact||'},"skill_key":'||to_jsonb(p.skill_key)::text||'}' AS serialized
 FROM packed p
)
INSERT INTO private.iclub_exam_chemistry_j23_as_canonical_candidate_v1(
 candidate_version,skill_key,tour_no,syllabus_point,enrichment_only,
 base_version,base_content_hash,editorial_corrections_applied,
 locales,canonical_json_compact,content_hash)
SELECT 'chemistry9701_j23_20261029_as_91_sixfield_candidate_v1',skill_key,tour_no,syllabus_point,enrichment_only,
 base_version,base_content_hash,has_correction,
 locales,serialized,
 'sha256:'||encode(extensions.digest(convert_to(serialized,'UTF8'),'sha256'),'hex')
FROM canonical WHERE language_count=3
 AND serialized::jsonb=jsonb_build_object('locales',locales,'skill_key',skill_key);

INSERT INTO private.iclub_exam_chemistry_j23_as_tutor_candidate_v1(
candidate_version,skill_key,locale,tutor_card_key,base_tutor_content_version,
title,main_explanation,simple_explanation,alternative_explanation,focus_explanation,
base_tutor_source_hash,source_card_hash,tutor_candidate_digest)
SELECT c.candidate_version,c.skill_key,u.locale,u.tutor_card_key,u.content_version,
u.title,u.main_explanation,u.simple_explanation,u.alternative_explanation,u.focus_explanation,
u.source_card_hash,c.content_hash,
'sha256:'||encode(extensions.digest(convert_to(jsonb_build_object('skill_key',c.skill_key,'locale',u.locale,
'title',u.title,'main',u.main_explanation,'simple',u.simple_explanation,
'alternative',u.alternative_explanation,'focus',u.focus_explanation)::text,'UTF8'),'sha256'),'hex')
FROM private.iclub_exam_chemistry_j23_as_canonical_candidate_v1 c
JOIN private.iclub_subject_library_tutor u
 ON u.subject_key='chemistry' AND u.version_key=c.base_version AND u.skill_key=c.skill_key
 AND u.source_card_hash=c.base_content_hash
WHERE c.candidate_version='chemistry9701_j23_20261029_as_91_sixfield_candidate_v1';
DO $verify$
DECLARE skills int; tutors int; corrected int; enrich int; bad_hash int; bad_content int;
BEGIN
 SELECT count(*),count(*) FILTER(WHERE editorial_corrections_applied),
 count(*) FILTER(WHERE enrichment_only),
 count(*) FILTER(WHERE content_hash<>'sha256:'||encode(extensions.digest(convert_to(canonical_json_compact,'UTF8'),'sha256'),'hex')),
 count(*) FILTER(WHERE (locales->'en'->>'check_answer') IS NULL OR
 (locales->'ru'->>'check_answer') IS NULL OR (locales->'uz'->>'check_answer') IS NULL OR
 (locales->'en'->>'check_question') IS NULL OR
 (locales->'ru'->>'check_question') IS NULL OR (locales->'uz'->>'check_question') IS NULL)
 INTO skills,corrected,enrich,bad_hash,bad_content
 FROM private.iclub_exam_chemistry_j23_as_canonical_candidate_v1 WHERE candidate_version='chemistry9701_j23_20261029_as_91_sixfield_candidate_v1';
 SELECT count(*) INTO tutors FROM private.iclub_exam_chemistry_j23_as_tutor_candidate_v1
 WHERE candidate_version='chemistry9701_j23_20261029_as_91_sixfield_candidate_v1';
 IF skills<>91 OR tutors<>273 OR corrected<>12 OR enrich<>1 OR bad_hash<>0 OR bad_content<>0
 THEN RAISE EXCEPTION 'J23 canonical candidate mismatch skills %, tutors %, corrections %, enrich %, hash %, empty %',
 skills,tutors,corrected,enrich,bad_hash,bad_content; END IF;
 IF EXISTS(
 SELECT 1 FROM private.iclub_exam_chemistry_j23_as_tutor_candidate_v1 u
 JOIN private.iclub_exam_chemistry_j23_as_canonical_candidate_v1 t
 ON t.candidate_version=u.candidate_version AND t.skill_key=u.skill_key
 WHERE u.source_card_hash<>t.content_hash OR u.base_tutor_source_hash<>t.base_content_hash
 ) THEN RAISE EXCEPTION 'J23 Tutor candidate canonical linkage mismatch'; END IF;
END $verify$;
COMMIT;
