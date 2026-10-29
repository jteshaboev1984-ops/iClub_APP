-- J23 private exact-byte source bundle for existing subject-release-packager.py.
-- Generated from prior closed 91-card candidate, never a publication or signoff.
BEGIN;
SET LOCAL lock_timeout='4s';
SET LOCAL statement_timeout='120s';
DO $guard$ BEGIN
 IF EXISTS(SELECT 1 FROM information_schema.tables WHERE table_schema='private' AND table_name='iclub_exam_chemistry_j23_as_source_bundle_v1') THEN
  RAISE EXCEPTION 'J23 source bundle exists, no overwrite'; END IF;
 IF (SELECT count(*) FROM private.iclub_exam_chemistry_j23_as_canonical_candidate_v1
  WHERE candidate_version='chemistry9701_j23_20261029_as_91_sixfield_candidate_v1')<>91 OR
 (SELECT count(*) FROM private.iclub_exam_chemistry_j23_as_tutor_candidate_v1
  WHERE candidate_version='chemistry9701_j23_20261029_as_91_sixfield_candidate_v1')<>273 THEN
  RAISE EXCEPTION 'J23 source/tutor candidate counts missing'; END IF;
 IF (SELECT enabled FROM private.iclub_exam_chemistry_j24_as_theory_control_v1 WHERE id=1) OR
 (SELECT audience_mode FROM private.iclub_exam_chemistry_j25_theory_rollout_control_v1 WHERE id=1)<>'closed'
 THEN RAISE EXCEPTION 'J23 chemistry rollout not closed'; END IF;
END $guard$;
CREATE TABLE private.iclub_exam_chemistry_j23_as_source_bundle_v1(
 candidate_version text PRIMARY KEY,
 theory_source_text text NOT NULL,
 tutor_source_text text NOT NULL,
 theory_sha256 text NOT NULL CHECK(theory_sha256 ~ '^[a-f0-9]{64}$'),
 tutor_sha256 text NOT NULL CHECK(tutor_sha256 ~ '^[a-f0-9]{64}$'),
 package_sha256 text NOT NULL CHECK(package_sha256 ~ '^[a-f0-9]{64}$'),
 skill_count int NOT NULL CHECK(skill_count=91),
 tutor_locale_count int NOT NULL CHECK(tutor_locale_count=273),
 release_status text NOT NULL DEFAULT 'CLOSED_PENDING_ACADEMIC_RIGHTS_TUTOR_SIGNOFF'
 CHECK(release_status='CLOSED_PENDING_ACADEMIC_RIGHTS_TUTOR_SIGNOFF'),
 created_at timestamptz NOT NULL DEFAULT clock_timestamp()
);
ALTER TABLE private.iclub_exam_chemistry_j23_as_source_bundle_v1 ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON private.iclub_exam_chemistry_j23_as_source_bundle_v1 FROM PUBLIC, anon, authenticated;
WITH theory AS(
 SELECT '{"syllabus":"Cambridge International AS & A Level Chemistry 9701 syllabus 2025-2027","cards":' ||
 jsonb_agg(jsonb_build_object('skill_key',skill_key,'tour_no',tour_no,
 'official_syllabus_point',syllabus_point,'content_hash',content_hash,'locales',locales)
 ORDER BY skill_key)::text || '}' AS source_text,
 count(*) AS n
 FROM private.iclub_exam_chemistry_j23_as_canonical_candidate_v1
 WHERE candidate_version='chemistry9701_j23_20261029_as_91_sixfield_candidate_v1'
),
tutor AS(
 SELECT jsonb_agg(jsonb_build_object('subject_key','chemistry','skill_key',skill_key,
 'locale',locale,'tutor_card_key',tutor_card_key,
 'content_version','chemistry9701_j23_20261029_as_91_sixfield_candidate_v1',
 'title',title,'main_explanation',main_explanation,
 'simple_explanation',simple_explanation,
 'alternative_explanation',alternative_explanation,'focus_explanation',focus_explanation,
 'source_card_hash',source_card_hash)
 ORDER BY skill_key,locale) AS jsonrows,count(*) AS n
 FROM private.iclub_exam_chemistry_j23_as_tutor_candidate_v1
 WHERE candidate_version='chemistry9701_j23_20261029_as_91_sixfield_candidate_v1'
),
assembled AS(
 SELECT theory.source_text AS theory_bytes,
 '{"source_theory_sha256":"'||
 encode(extensions.digest(convert_to(theory.source_text,'UTF8'),'sha256'),'hex')||
 '","data":'||tutor.jsonrows::text||'}' AS tutor_bytes,
 theory.n AS skills, tutor.n AS tutors FROM theory CROSS JOIN tutor
)
INSERT INTO private.iclub_exam_chemistry_j23_as_source_bundle_v1
(candidate_version,theory_source_text,tutor_source_text,theory_sha256,tutor_sha256,package_sha256,skill_count,tutor_locale_count)
SELECT 'chemistry9701_j23_20261029_as_91_sixfield_candidate_v1',theory_bytes,tutor_bytes,
encode(extensions.digest(convert_to(theory_bytes,'UTF8'),'sha256'),'hex'),
encode(extensions.digest(convert_to(tutor_bytes,'UTF8'),'sha256'),'hex'),
encode(extensions.digest(convert_to(theory_bytes,'UTF8')||decode('00','hex')||convert_to(tutor_bytes,'UTF8'),'sha256'),'hex'),
skills,tutors FROM assembled;
DO $verify$
DECLARE b private.iclub_exam_chemistry_j23_as_source_bundle_v1%ROWTYPE;
BEGIN
 SELECT * INTO b FROM private.iclub_exam_chemistry_j23_as_source_bundle_v1
 WHERE candidate_version='chemistry9701_j23_20261029_as_91_sixfield_candidate_v1';
 IF NOT FOUND THEN RAISE EXCEPTION 'Missing bundle'; END IF;
 IF b.skill_count<>91 OR b.tutor_locale_count<>273 OR
 jsonb_array_length(b.theory_source_text::jsonb->'cards')<>91 OR
 jsonb_array_length(b.tutor_source_text::jsonb->'data')<>273 OR
 b.tutor_source_text::jsonb->>'source_theory_sha256'<>b.theory_sha256 OR
 b.theory_sha256<>encode(extensions.digest(convert_to(b.theory_source_text,'UTF8'),'sha256'),'hex') OR
 b.tutor_sha256<>encode(extensions.digest(convert_to(b.tutor_source_text,'UTF8'),'sha256'),'hex') OR
 b.package_sha256<>encode(extensions.digest(convert_to(b.theory_source_text,'UTF8')||decode('00','hex')||convert_to(b.tutor_source_text,'UTF8'),'sha256'),'hex')
 THEN RAISE EXCEPTION 'J23 packed source SHA or cardinality mismatch'; END IF;
END $verify$;
COMMIT;
