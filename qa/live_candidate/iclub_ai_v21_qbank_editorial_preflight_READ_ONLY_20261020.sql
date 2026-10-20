-- iClub Global AI v2.1 / CLOSED Qbank editorial preflight.
-- STRICTLY SELECT ONLY. No student IDs, no answers or copyrighted source text exported.
-- QA/pre-screen metadata only; all reviewers remain PENDING until real signoff.
-- Generic reusable query: no hardcoded subject/question list or publishing capability.
WITH src AS (
 SELECT a.surface_code,a.subject_key,a.context_key,a.locale,a.source_card_key,
  a.source_version,a.publication_revision,a.body_text,a.content_hash,a.target_hash,
  a.published,a.revoked,a.content_reviewed,a.rights_reviewed,
  a.locale_reviewed,a.academic_qa_passed,a.approved_at,
  substring(a.context_key FROM '^question_([0-9]+)$')::bigint AS question_id
 FROM private.iclub_ai_v21_academic_sources a
 WHERE a.surface_code='practice_error'
   AND a.source_version='qbank_exact_explanation_draft_v1'
), cases AS (
 SELECT s.subject_key,s.context_key,max(s.question_id) question_id,
  count(*) locale_rows,count(DISTINCT s.locale) distinct_locales,
  count(DISTINCT s.source_version) versions,
  count(DISTINCT s.publication_revision) revisions,
  bool_and(s.content_hash=encode(extensions.digest(
   convert_to(s.body_text,'UTF8'),'sha256'),'hex')) content_sha_ok,
  bool_and(s.target_hash=private.iclub_ai_v21_target_fingerprint_v1(
   'practice_error',s.question_id)) question_sha_ok,
  bool_and(s.body_text=btrim(CASE s.locale WHEN 'en' THEN q.explanation_en
   WHEN 'ru' THEN q.explanation_ru WHEN 'uz' THEN q.explanation_uz END)) question_text_match,
  bool_and(NOT s.published AND s.revoked AND NOT s.content_reviewed
   AND NOT s.rights_reviewed AND NOT s.locale_reviewed
   AND NOT s.academic_qa_passed AND s.approved_at IS NULL) still_unapproved,
  bool_or(private.iclub_ai_v21_source_admitted_v1(a)) admitted_unexpected,
  bool_and(q.is_active AND q.quality_status='published' AND subj.is_active) target_is_live,
  bool_and(s.subject_key=subj.subject_key) subject_matched,
  bool_or(s.locale='en') has_en,bool_or(s.locale='ru') has_ru,
  bool_or(s.locale='uz') has_uz,
  min(length(btrim(s.body_text))) shortest_locale_chars,
  bool_and(s.locale IN ('en','ru','uz')) allowed_locales,
  bool_and(length(btrim(s.body_text))>=100) basic_draft_length_ok,
  bool_and(NOT EXISTS(SELECT 1 FROM private.iclub_ai_v21_owner_beta_source_releases r
   WHERE r.source_card_key=s.source_card_key AND r.enabled)) no_legacy_beta_release,
  bool_and(q.qtype<>'mcq' OR q.correct_answer ~ '^[A-D]$') answer_key_format_ok,
  bool_and(q.qtype<>'mcq' OR q.options_text_en LIKE '[%') options_shape_basic_ok,
  bool_and(q.question_text_en IS NOT NULL
   AND q.question_text_ru IS NOT NULL AND q.question_text_uz IS NOT NULL) translated_question_present,
  bool_and(NOT (s.locale='en' AND
     (s.body_text ILIKE '%Selected answer:%' OR s.body_text ILIKE '%Selected:%'))) no_misleading_english_selection
 FROM src s
 JOIN private.iclub_ai_v21_academic_sources a ON a.source_card_key=s.source_card_key
 JOIN public.questions q ON q.id=s.question_id
 JOIN public.subjects subj ON subj.id=q.subject_id
 GROUP BY s.subject_key,s.context_key
)
SELECT c.subject_key,c.question_id,
 (SELECT count(DISTINCT pp.pool_id)
  FROM public.practice_pool_questions pp
  JOIN public.practice_pools pool ON pool.id=pp.pool_id AND pool.is_active
  JOIN public.questions q ON q.id=pp.question_id
  WHERE pp.question_id=c.question_id AND pp.is_active
   AND pool.subject_id=q.subject_id) active_practice_pools,
 c.locale_rows,c.distinct_locales,c.shortest_locale_chars,
 c.content_sha_ok,c.question_sha_ok,c.question_text_match,c.still_unapproved,
 c.admitted_unexpected,c.target_is_live,c.subject_matched,
 c.answer_key_format_ok,c.options_shape_basic_ok,c.translated_question_present,
 c.no_misleading_english_selection,c.no_legacy_beta_release,
 (c.locale_rows=3 AND c.distinct_locales=3 AND c.versions=1 AND c.revisions=1
  AND c.allowed_locales AND c.has_en AND c.has_ru AND c.has_uz
  AND c.content_sha_ok AND c.question_sha_ok
  AND c.question_text_match AND c.still_unapproved AND NOT c.admitted_unexpected
  AND c.target_is_live AND c.subject_matched AND c.basic_draft_length_ok
  AND c.answer_key_format_ok AND c.options_shape_basic_ok
  AND c.translated_question_present AND c.no_misleading_english_selection
  AND c.no_legacy_beta_release
  AND EXISTS(SELECT 1 FROM public.practice_pool_questions pp
   JOIN public.practice_pools p ON p.id=pp.pool_id AND p.is_active
   JOIN public.questions q ON q.id=pp.question_id
   WHERE pp.question_id=c.question_id AND pp.is_active
    AND p.subject_id=q.subject_id)
 ) as metadata_preflight_ok,
 'PENDING_HUMAN_ACADEMIC_RIGHTS_LOCALE_AND_OWNER_RELEASE'::text reviewer_status
FROM cases c ORDER BY c.subject_key,c.question_id;
