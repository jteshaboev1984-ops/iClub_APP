-- J23 additive, private-only reconstruction of EXISTING authoring evidence.
-- Never touch original 154 source rows, existing hashes, Tutor, learners, or release flags.
-- This is NOT a canonical six-field package: absent check answers remain NULL for academic authoring.
BEGIN;
SET LOCAL lock_timeout='4s';
SET LOCAL statement_timeout='90s';

DO $guard$
BEGIN
  IF EXISTS(SELECT 1 FROM information_schema.tables WHERE table_schema='private' AND table_name='iclub_exam_chemistry_j23_as_authoring_recovery_v1') THEN
    RAISE EXCEPTION 'J23 authoring recovery table already exists, no second installation';
  END IF;
  IF (SELECT count(*) FROM private.iclub_exam_core_skills_v1
      WHERE program_key='chemistry_9701' AND version_key='chemistry_2025_2027_v1' AND level_code='AS')<>91
    OR (SELECT count(*) FROM private.iclub_exam_chemistry_j23_theory_revisions_v1
      WHERE revision_key='chemistry9701_j23_20261029_revision_v1')<>12 THEN
    RAISE EXCEPTION 'J23 source counts drifted, abort without writes';
  END IF;
END $guard$;

CREATE TABLE private.iclub_exam_chemistry_j23_as_authoring_recovery_v1(
 candidate_version text NOT NULL,
 skill_key text NOT NULL,
 locale text NOT NULL CHECK (locale IN('en','ru','uz')),
 tour_no int NOT NULL,
 syllabus_point text NOT NULL,
 is_enrichment_only boolean NOT NULL,
 base_version text NOT NULL,
 base_content_hash text NOT NULL CHECK(base_content_hash ~ '^sha256:[a-f0-9]{64}$'),
 source_revision_sha256 text,
 title text NOT NULL,
 explanation text NOT NULL,
 original_example text NOT NULL,
 common_trap text NOT NULL,
 check_question text,
 check_answer text,
 recovery_status text NOT NULL DEFAULT 'PENDING_QUESTION_ANSWER_AUTHORING_AND_SIGNOFF'
   CHECK(recovery_status='PENDING_QUESTION_ANSWER_AUTHORING_AND_SIGNOFF'),
 created_at timestamptz NOT NULL DEFAULT now(),
 PRIMARY KEY(candidate_version,skill_key,locale),
 CHECK(length(btrim(title))>3 AND length(btrim(explanation))>100),
 CHECK(length(btrim(original_example))>3 AND length(btrim(common_trap))>3),
 CHECK(check_answer IS NULL)
);
ALTER TABLE private.iclub_exam_chemistry_j23_as_authoring_recovery_v1 ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON private.iclub_exam_chemistry_j23_as_authoring_recovery_v1 FROM PUBLIC, anon, authenticated;

WITH source_card AS(
 SELECT s.skill_key,s.tour_no,s.syllabus_point,
 t.version_key AS base_version,t.content_hash AS base_content_hash,
 r.revision_sha256,
 coalesce(r.revised_locales,t.locales) AS locales
 FROM private.iclub_exam_core_skills_v1 s
 JOIN private.iclub_subject_library_theory t
   ON t.subject_key=s.library_subject_key AND t.version_key=s.library_version_key
   AND t.skill_key=s.skill_key AND t.content_hash=s.content_hash
 LEFT JOIN private.iclub_exam_chemistry_j23_theory_revisions_v1 r
   ON r.skill_key=s.skill_key AND r.revision_key='chemistry9701_j23_20261029_revision_v1'
   AND r.base_content_hash=t.content_hash
 WHERE s.program_key='chemistry_9701' AND s.version_key='chemistry_2025_2027_v1' AND s.level_code='AS'
),
localized AS(
 SELECT s.*,l.locale,
 s.locales->l.locale->>'title' AS title,
 s.locales->l.locale->>'explanation' AS explanation,
 CASE l.locale WHEN 'en' THEN 'Worked example:' WHEN 'ru' THEN 'Разобранный пример:' ELSE 'Yechilgan misol:' END example_label,
 CASE l.locale WHEN 'en' THEN 'Critical check:' WHEN 'ru' THEN 'Важная проверка:' ELSE 'Muhim tekshiruv:' END trap_label
 FROM source_card s CROSS JOIN LATERAL unnest(ARRAY['en','ru','uz']) l(locale)
),
headings AS(
 SELECT a.*, q.h AS question_label
 FROM localized a
 LEFT JOIN LATERAL (
  SELECT v.h FROM (
   VALUES
   (1, CASE WHEN a.locale='en' THEN 'Check your understanding:' WHEN a.locale='ru' THEN 'Проверьте понимание:' ELSE 'Tushunganingizni tekshiring:' END),
   (2, CASE WHEN a.locale='en' THEN 'Check yourself:' WHEN a.locale='ru' THEN 'Проверь понимание:' ELSE 'Bilimingizni tekshiring:' END),
   (3, CASE WHEN a.locale='ru' THEN 'Проверьте себя:' WHEN a.locale='uz' THEN 'O‘zingizni tekshiring:' ELSE '' END),
   (4, CASE WHEN a.locale='ru' THEN 'Проверь себя:' ELSE '' END)
  ) v(n,h)
  WHERE v.h<>'' AND strpos(a.explanation,v.h)>0 ORDER BY v.n LIMIT 1
 ) q ON TRUE
)
INSERT INTO private.iclub_exam_chemistry_j23_as_authoring_recovery_v1
(candidate_version,skill_key,locale,tour_no,syllabus_point,is_enrichment_only,base_version,
base_content_hash,source_revision_sha256,title,explanation,original_example,common_trap,check_question,check_answer)
SELECT 'chemistry9701_j23_20261029_sixfield_recovery_v1',skill_key,locale,tour_no,syllabus_point,
 syllabus_point LIKE '%NO_EXPLICIT%',base_version,base_content_hash,revision_sha256,title,explanation,
 btrim(split_part(split_part(explanation,example_label,2),E'\n\n',1)),
 btrim(split_part(split_part(explanation,trap_label,2),E'\n\n',1)),
 CASE WHEN question_label IS NULL THEN NULL ELSE
 nullif(btrim(split_part(split_part(explanation,question_label,2),E'\n\n',1)),'') END,
 NULL::text
FROM headings;

DO $verify$
DECLARE n int;q int;corrected int;enrich int;
BEGIN
 SELECT count(*),count(*) FILTER(WHERE check_question IS NOT NULL),
   count(*) FILTER(WHERE source_revision_sha256 IS NOT NULL),
   count(*) FILTER(WHERE is_enrichment_only)
 INTO n,q,corrected,enrich
 FROM private.iclub_exam_chemistry_j23_as_authoring_recovery_v1;
 IF n<>273 OR q<>186 OR corrected<>36 OR enrich<>3 THEN
  RAISE EXCEPTION 'J23 recovery unexpected cardinality (rows %, questions %, revised %, enrich %)',n,q,corrected,enrich;
 END IF;
 IF EXISTS(SELECT 1 FROM private.iclub_exam_chemistry_j23_as_authoring_recovery_v1
           WHERE check_answer IS NOT NULL OR length(btrim(original_example))<4 OR length(btrim(common_trap))<4)
 THEN RAISE EXCEPTION 'J23 extraction validation failed'; END IF;
END $verify$;
COMMIT;
