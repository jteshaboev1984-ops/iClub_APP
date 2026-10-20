-- Reusable academic source intake: future subjects/questions require DATA, not code.
-- ZERO approved/published sources after first import. Existing student tables read only.
DO $before$
BEGIN
 IF (SELECT count(*) FROM private.iclub_ai_v21_academic_sources)<>0
 OR (SELECT count(*) FROM private.iclub_ai_v21_academic_deliveries)<>0
 OR (SELECT count(*) FROM private.iclub_ai_v21_academic_policy
  WHERE singleton=1 AND NOT enabled AND NOT provider_enabled)<>1
 OR to_regprocedure('private.iclub_ai_v21_target_fingerprint_v1(text,bigint)') IS NOT NULL
 OR to_regprocedure('private.iclub_ai_v21_stage_legacy_exact_questions_v1()') IS NOT NULL
 THEN RAISE EXCEPTION 'Academic source catalog changed: abort intake'; END IF;
END $before$;
ALTER TABLE private.iclub_ai_v21_academic_sources
 ADD COLUMN target_hash text NOT NULL CHECK (target_hash ~ '^[a-f0-9]{64}$');

CREATE FUNCTION private.iclub_ai_v21_target_fingerprint_v1(p_surface text,p_id bigint)
RETURNS text LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path=''
AS $fp$
DECLARE payload jsonb;
BEGIN
 IF p_id IS NULL OR p_id<=0 THEN RETURN NULL; END IF;
 IF p_surface='practice_error' THEN
 SELECT jsonb_build_array(q.id,q.subject_id,q.is_active,q.qtype,q.topic,
  q.subtopic,q.difficulty,q.correct_answer,q.question_text,
  q.question_text_ru,q.question_text_uz,q.question_text_en,
  q.options_text,q.options_text_ru,q.options_text_uz,q.options_text_en,
  q.explanation,q.explanation_ru,q.explanation_uz,q.explanation_en,
  q.quality_flag,q.quality_status,q.book_ref)
 INTO payload FROM public.questions q WHERE q.id=p_id;
 ELSIF p_surface='lesson_topic' THEN
 SELECT jsonb_build_array(l.id,l.subject_id,l.title,l.topic,l.order_no,
   (SELECT coalesce(jsonb_agg(jsonb_build_array(v.id,v.video_url,
      v.duration_seconds) ORDER BY v.id),'[]'::jsonb)
    FROM public.videos v WHERE v.lesson_id=l.id))
 INTO payload FROM public.lessons l WHERE l.id=p_id;
 ELSIF p_surface='tour_archive' THEN
 SELECT jsonb_build_array(t.id,t.subject_id,t.tour_no,t.season_id,
   t.start_date,t.end_date,t.is_active,
   (SELECT coalesce(jsonb_agg(jsonb_build_array(tq.id,tq.question_id,
     tq.order_no,tq.is_active,q.subject_id,q.is_active,q.qtype,q.topic,
     q.subtopic,q.correct_answer,q.question_text,
     q.question_text_ru,q.question_text_uz,q.question_text_en,
     q.options_text,q.options_text_ru,q.options_text_uz,q.options_text_en)
     ORDER BY tq.order_no,tq.id),'[]'::jsonb)
    FROM public.tour_questions tq JOIN public.questions q ON q.id=tq.question_id
    WHERE tq.tour_id=t.id))
 INTO payload FROM public.tours t WHERE t.id=p_id;
 END IF;
 IF payload IS NULL THEN RETURN NULL; END IF;
 RETURN encode(extensions.digest(convert_to(payload::text,'UTF8'),'sha256'),'hex');
END $fp$;
REVOKE ALL ON FUNCTION private.iclub_ai_v21_target_fingerprint_v1(text,bigint)
 FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION private.iclub_ai_v21_target_fingerprint_v1(text,bigint) TO service_role;

-- The same function stages the next subject later, without a new migration.
-- Legacy metadata is candidate evidence, not Global AI publication approval.
CREATE FUNCTION private.iclub_ai_v21_stage_legacy_exact_questions_v1()
RETURNS integer LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path=''
AS $stage$
DECLARE staged integer;
BEGIN
 IF NOT EXISTS(SELECT 1 FROM private.iclub_ai_v21_academic_policy
   WHERE singleton=1 AND NOT provider_enabled)
 THEN RAISE EXCEPTION 'Source intake blocked by policy'; END IF;
 WITH candidates AS (
 SELECT c.*
 FROM private.practice_ai_source_cards c
 JOIN public.questions q ON q.id=c.question_id AND q.is_active
 JOIN public.subjects s ON s.id=q.subject_id AND s.subject_key=c.subject_key AND s.is_active
 WHERE c.card_type='answer_explanation' AND c.question_id IS NOT NULL
  AND c.approval_status='approved' AND c.rights_status='original_iclub'
  AND c.is_runtime_allowed AND c.locale IN ('ru','uz','en')
  AND length(btrim(c.body_text)) BETWEEN 30 AND 6000
  AND length(c.source_version) BETWEEN 1 AND 120
  AND c.content_hash=encode(extensions.digest(
    convert_to(c.body_text,'UTF8'),'sha256'),'hex')
 ), complete_sets AS (
  SELECT subject_key,question_id FROM candidates GROUP BY 1,2
  HAVING count(*)=3 AND count(DISTINCT locale)=3
     AND count(DISTINCT source_version)=1
 )
 INSERT INTO private.iclub_ai_v21_academic_sources(
  surface_code,subject_key,context_key,locale,source_card_key,
  source_version,publication_revision,body_text,content_hash,target_hash,
  content_reviewed,rights_reviewed,locale_reviewed,academic_qa_passed,
  published,revoked,approved_at
 )
 SELECT 'practice_error',c.subject_key,'question_'||c.question_id::text,
  c.locale,c.source_card_key,c.source_version,1,c.body_text,
  encode(extensions.digest(convert_to(c.body_text,'UTF8'),'sha256'),'hex'),
  private.iclub_ai_v21_target_fingerprint_v1('practice_error',c.question_id),
  false,false,false,false,false,true,NULL
 FROM candidates c JOIN complete_sets g USING(subject_key,question_id)
 WHERE private.iclub_ai_v21_target_fingerprint_v1('practice_error',c.question_id)
  IS NOT NULL
 ON CONFLICT(surface_code,subject_key,context_key,locale) DO NOTHING;
 GET DIAGNOSTICS staged=ROW_COUNT;
 RETURN staged;
END $stage$;
REVOKE ALL ON FUNCTION private.iclub_ai_v21_stage_legacy_exact_questions_v1()
 FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION private.iclub_ai_v21_stage_legacy_exact_questions_v1()
 TO service_role;

DO $verify$
DECLARE n integer;
BEGIN
 SELECT private.iclub_ai_v21_stage_legacy_exact_questions_v1() INTO n;
 IF n<>111 THEN RAISE EXCEPTION 'Expected 111 exact tri-language candidates, got %',n; END IF;
 IF (SELECT count(*) FROM private.iclub_ai_v21_academic_sources)<>111
 OR (SELECT count(DISTINCT context_key) FROM private.iclub_ai_v21_academic_sources)<>37
 OR EXISTS(SELECT 1 FROM private.iclub_ai_v21_academic_sources
   WHERE published OR NOT revoked OR content_reviewed OR rights_reviewed
     OR locale_reviewed OR academic_qa_passed OR approved_at IS NOT NULL
     OR content_hash<>encode(extensions.digest(convert_to(body_text,'UTF8'),'sha256'),'hex')
     OR target_hash IS DISTINCT FROM private.iclub_ai_v21_target_fingerprint_v1(
        'practice_error',substring(context_key FROM 10)::bigint))
 OR (SELECT count(*) FROM private.iclub_ai_v21_academic_policy
    WHERE singleton=1 AND NOT enabled AND NOT provider_enabled)<>1
 THEN RAISE EXCEPTION 'Staging not safe or fingerprint mismatch'; END IF;
END $verify$;
