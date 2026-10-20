-- READ ONLY. Run as privileged editorial auditor; NO user data, question
-- text or academic answers exported. Future subjects flow through this query.
-- PREPARED / PUBLISHED states are distinct; legacy approved is not authority.
WITH candidates AS (
 SELECT s.surface_code,s.subject_key,s.context_key,s.locale,s.source_version,
 s.publication_revision,s.body_text,s.content_hash,s.target_hash,
 s.content_reviewed,s.rights_reviewed,s.locale_reviewed,s.academic_qa_passed,
 s.published,s.revoked,s.approved_at,
 CASE
  WHEN s.surface_code='practice_error'
   THEN substring(s.context_key FROM '^question_([0-9]+)$')::bigint
  WHEN s.surface_code='lesson_topic'
   THEN substring(s.context_key FROM '^lesson_([0-9]+)$')::bigint
  WHEN s.surface_code='tour_archive'
   THEN substring(s.context_key FROM '^tour_([0-9]+)_archive$')::bigint
 END AS target_id
 FROM private.iclub_ai_v21_academic_sources s
),checked AS (
 SELECT c.*,
 (c.content_hash=encode(extensions.digest(convert_to(c.body_text,'UTF8'),'sha256'),'hex')) AS body_intact,
 (c.target_hash=private.iclub_ai_v21_target_fingerprint_v1(c.surface_code,c.target_id)) AS target_intact
 FROM candidates c
)
SELECT surface_code,subject_key,context_key,
 count(*) AS locale_rows,count(DISTINCT locale) AS distinct_locales,
 bool_or(locale='en') AS has_en,bool_or(locale='ru') AS has_ru,bool_or(locale='uz') AS has_uz,
 count(DISTINCT source_version)=1 AS single_source_version,
 count(DISTINCT publication_revision)=1 AS single_editorial_revision,
 bool_and(coalesce(body_intact,false)) AS content_sha_ok,
 bool_and(coalesce(target_intact,false)) AS live_target_sha_ok,
 bool_and(content_reviewed) AS content_reviewed_all,
 bool_and(rights_reviewed) AS rights_reviewed_all,
 bool_and(locale_reviewed) AS language_reviewed_all,
 bool_and(academic_qa_passed) AS academic_qa_all,
 bool_and(approved_at IS NOT NULL) AS reviewer_approval_recorded,
 bool_and(published AND NOT revoked) AS published_all,
 (count(*)=3 AND count(DISTINCT locale)=3 AND
  bool_or(locale='en') AND bool_or(locale='ru') AND bool_or(locale='uz') AND
  count(DISTINCT source_version)=1 AND count(DISTINCT publication_revision)=1 AND
  bool_and(coalesce(body_intact,false)) AND bool_and(coalesce(target_intact,false)) AND
  bool_and(content_reviewed) AND bool_and(rights_reviewed) AND
  bool_and(locale_reviewed) AND bool_and(academic_qa_passed) AND
  bool_and(approved_at IS NOT NULL)) AS editorial_ready_all_locales
FROM checked
GROUP BY surface_code,subject_key,context_key
ORDER BY subject_key,surface_code,context_key;
