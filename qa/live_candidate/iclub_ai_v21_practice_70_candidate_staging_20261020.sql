-- iClub Global AI v2.1: data-only preparation of 70 EXACT active Practice questions.
-- Intentional CLOSED DRAFTS: never owner-approved, never formally published.
-- Existing releases, students, answer keys, pools, attempts, scores and quotas are untouched.
-- All three translations are copied from versioned iClub question explanations.
-- Academic, provenance, copyright and localization reviews remain PENDING.
-- This script has no per-subject runtime route or code changes.
DO $stage$
DECLARE staged integer;
BEGIN
 IF (SELECT count(*) FROM private.iclub_ai_v21_academic_sources)<>111
 OR (SELECT count(*) FROM private.iclub_ai_v21_owner_beta_source_releases WHERE enabled)<>111
 OR (SELECT count(*) FROM private.iclub_ai_v21_academic_deliveries)<>0
 OR (SELECT count(*) FROM private.iclub_ai_v21_academic_policy WHERE singleton=1 AND enabled AND NOT provider_enabled)<>1
 OR (SELECT count(*) FROM private.iclub_ai_v21_beta_control WHERE singleton=1 AND beta_enabled AND prepared_enabled AND NOT generation_enabled)<>1
 THEN RAISE EXCEPTION 'AI staging baseline drift: no changes applied'; END IF;
 WITH eligible AS (
  SELECT DISTINCT s.subject_key,p.tour_no,q.id,q.subtopic,
    q.explanation_en,q.explanation_ru,q.explanation_uz
  FROM public.questions q
  JOIN public.subjects s ON s.id=q.subject_id
  JOIN public.practice_pool_questions pp ON pp.question_id=q.id AND pp.is_active
  JOIN public.practice_pools p ON p.id=pp.pool_id AND p.is_active
  WHERE s.subject_key IN ('chemistry','economics')
    AND s.is_active AND q.is_active AND q.quality_status='published'
    AND q.qtype IN ('mcq','input')
    AND length(btrim(q.explanation_en))>=100
    AND length(btrim(q.explanation_ru))>=100
    AND length(btrim(q.explanation_uz))>=100
    AND length(btrim(q.question_text_en))>=25
    AND (s.subject_key<>'economics' OR
        (q.explanation_en NOT ILIKE '%Selected answer:%' AND
         q.explanation_en NOT ILIKE '%Selected:%'))
    AND NOT EXISTS (SELECT 1 FROM private.iclub_ai_v21_academic_sources a
      WHERE a.surface_code='practice_error'
        AND a.subject_key=s.subject_key
        AND a.context_key='question_'||q.id::text)
 ), diverse AS (
  SELECT *, row_number() OVER (
    PARTITION BY subject_key,tour_no,coalesce(nullif(btrim(subtopic),''),'none')
    ORDER BY length(explanation_en) DESC,id
  ) subtopic_rank FROM eligible
 ), ranked AS (
  SELECT *,row_number() OVER (
    PARTITION BY subject_key,tour_no
    ORDER BY subtopic_rank,length(explanation_en) DESC,id
  ) rn FROM diverse
 ), selected AS (
  SELECT * FROM ranked WHERE rn<=5
 ), localised AS (
  SELECT e.subject_key,e.tour_no,e.id,l.locale,btrim(l.body_text) AS body_text
  FROM selected e
  CROSS JOIN LATERAL (VALUES ('en',e.explanation_en),
   ('ru',e.explanation_ru),('uz',e.explanation_uz)) l(locale,body_text)
 )
 INSERT INTO private.iclub_ai_v21_academic_sources
  (surface_code,subject_key,context_key,locale,source_card_key,source_version,
   publication_revision,body_text,content_hash,target_hash,
   content_reviewed,rights_reviewed,locale_reviewed,academic_qa_passed,
   published,revoked,approved_at)
 SELECT 'practice_error',e.subject_key,'question_'||e.id::text,e.locale,
   'iclub_qbank_draft_20261020_'||e.subject_key||'_'||e.id::text||'_'||e.locale,
   'qbank_exact_explanation_draft_v1',1,e.body_text,
   encode(extensions.digest(convert_to(e.body_text,'UTF8'),'sha256'),'hex'),
   private.iclub_ai_v21_target_fingerprint_v1('practice_error',e.id),
   false,false,false,false,false,true,NULL
 FROM localised e;
 GET DIAGNOSTICS staged=ROW_COUNT;
 IF staged<>210 THEN
  RAISE EXCEPTION 'Expected 210 closed drafts (70 questions × 3), got %',staged;
 END IF;
 IF (SELECT count(*) FROM private.iclub_ai_v21_academic_sources)<>321
 OR (SELECT count(*) FROM private.iclub_ai_v21_owner_beta_source_releases WHERE enabled)<>111
 OR (SELECT count(*) FROM private.iclub_ai_v21_academic_sources
     WHERE private.iclub_ai_v21_source_admitted_v1(iclub_ai_v21_academic_sources))<>111
 OR EXISTS (
  SELECT 1 FROM private.iclub_ai_v21_academic_sources
  WHERE source_version='qbank_exact_explanation_draft_v1'
   AND (published OR NOT revoked OR content_reviewed OR rights_reviewed
    OR locale_reviewed OR academic_qa_passed OR approved_at IS NOT NULL
    OR content_hash<>encode(extensions.digest(convert_to(body_text,'UTF8'),'sha256'),'hex')
    OR target_hash IS DISTINCT FROM private.iclub_ai_v21_target_fingerprint_v1(
     'practice_error',substring(context_key FROM 10)::bigint))
 )
 THEN RAISE EXCEPTION 'Staging integrity/closed-state check failed'; END IF;
END $stage$;
