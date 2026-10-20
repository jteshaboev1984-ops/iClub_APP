-- Synthetic-only test data. This file must run only after the existing
-- qbank provenance fixture in a disposable scratch PostgreSQL database.
INSERT INTO public.questions VALUES(503,1,true,'published',
 'Original explanatory text to be preserved in the immutable history.',
 'Старое объяснение для сохранения в неизменяемом архиве редакций.',
 'Oldingi o‘quv matni tahrirlar tarixida o‘zgarmas holda saqlanadi.');
INSERT INTO private.iclub_ai_v21_academic_sources(
 surface_code,subject_key,context_key,locale,source_card_key,
 source_version,publication_revision,body_text,content_hash,target_hash)
SELECT 'practice_error','chemistry','question_503',v.locale,
 'unreviewed_503_'||v.locale,'unreviewed_v1',1,v.body,
 encode(extensions.digest(convert_to(v.body,'UTF8'),'sha256'),'hex'),
 private.iclub_ai_v21_target_fingerprint_v1('practice_error',503)
FROM public.questions q CROSS JOIN LATERAL
 (VALUES ('en',q.explanation_en),('ru',q.explanation_ru),('uz',q.explanation_uz))
 v(locale,body) WHERE q.id=503;
DO $test$
DECLARE allowed boolean; i integer; BEGIN
 i:=private.iclub_ai_v21_stage_three_locale_revision_v1(
  'chemistry',503,'unreviewed_v1','curated_v2',
  jsonb_build_object(
   'en',repeat('New verified draft explanation in plain English. ',3),
   'ru',repeat('Новый подробный черновик объяснения на русском языке. ',3),
   'uz',repeat('Yangi batafsil o‘zbekcha izohning tahrirlangan matni. ',3)),
  'SYNTHETIC_UNAPPROVED_EDITORIAL_DRAFT');
 IF i<>3 THEN RAISE EXCEPTION 'Expected exact three language updates'; END IF;
 IF (SELECT count(*) FROM private.iclub_ai_v21_source_revision_archive
   WHERE context_key='question_503' AND source_version='unreviewed_v1'
     AND superseded_by_version='curated_v2'
     AND content_hash=encode(extensions.digest(
       convert_to(body_text,'UTF8'),'sha256'),'hex'))<>3
 OR (SELECT count(*) FROM private.iclub_ai_v21_academic_sources
   WHERE context_key='question_503' AND source_version='curated_v2'
     AND publication_revision=2 AND NOT published AND revoked
     AND NOT content_reviewed AND NOT rights_reviewed
     AND NOT locale_reviewed AND NOT academic_qa_passed)<>3
 OR EXISTS(SELECT 1 FROM private.iclub_ai_v21_academic_sources s
   WHERE context_key='question_503'
     AND private.iclub_ai_v21_source_admitted_v1(s))
 THEN RAISE EXCEPTION 'Revision history, locked publication or count changed'; END IF;

 allowed:=true;
 BEGIN
  PERFORM private.iclub_ai_v21_stage_three_locale_revision_v1(
   'chemistry',503,'unreviewed_v1','curated_v3',
   jsonb_build_object('en',repeat('a',150),
     'ru',repeat('b',150),'uz',repeat('c',150)),
   'SYNTHETIC_REJECT_STALE_VERSION');
 EXCEPTION WHEN others THEN allowed:=false; END;
 IF allowed THEN RAISE EXCEPTION 'Old version admitted for overwrite'; END IF;

 allowed:=true;
 BEGIN
  PERFORM private.iclub_ai_v21_stage_three_locale_revision_v1(
   'chemistry',503,'curated_v2','curated_v3',
   jsonb_build_object('en',repeat('a',150),'ru',repeat('b',150)),
   'SYNTHETIC_REJECT_PARTIAL_LOCALES');
 EXCEPTION WHEN others THEN allowed:=false; END;
 IF allowed THEN RAISE EXCEPTION 'Partial locale set admitted'; END IF;

 allowed:=true;
 BEGIN
  UPDATE private.iclub_ai_v21_source_revision_archive
   SET body_text='tampered' WHERE context_key='question_503';
 EXCEPTION WHEN others THEN allowed:=false; END;
 IF allowed THEN RAISE EXCEPTION 'Archived history was mutable'; END IF;

 allowed:=true;
 BEGIN
  PERFORM private.iclub_ai_v21_stage_three_locale_revision_v1(
   'chemistry',501,'qbank_exact_explanation_draft_v1','curated_v3',
   jsonb_build_object('en',repeat('a',150),
     'ru',repeat('b',150),'uz',repeat('c',150)),
   'SYNTHETIC_REJECT_RELEASED_SOURCE');
 EXCEPTION WHEN others THEN allowed:=false; END;
 IF allowed THEN RAISE EXCEPTION 'Old released sources changed'; END IF;

 INSERT INTO private.iclub_ai_v21_academic_deliveries
  VALUES('aaaaaaaa-aaaa-4aaa-aaaa-aaaaaaaaaaaa',
  'chemistry','question_503',(SELECT source_card_key
  FROM private.iclub_ai_v21_academic_sources
  WHERE context_key='question_503' AND locale='en'));
 allowed:=true;
 BEGIN
  PERFORM private.iclub_ai_v21_stage_three_locale_revision_v1(
   'chemistry',503,'curated_v2','curated_v3',
   jsonb_build_object('en',repeat('a',150),
     'ru',repeat('b',150),'uz',repeat('c',150)),
   'SYNTHETIC_REJECT_DELIVERED_SOURCE');
 EXCEPTION WHEN others THEN allowed:=false; END;
 IF allowed THEN RAISE EXCEPTION 'Delivered source overwritten'; END IF;

 IF (SELECT count(*) FROM private.iclub_ai_v21_source_revision_archive)<>3
 OR (SELECT count(*) FROM private.iclub_ai_v21_academic_sources
    WHERE context_key='question_503' AND source_version='curated_v2')<>3
 OR has_table_privilege('service_role',
      'private.iclub_ai_v21_source_revision_archive','SELECT')
 OR has_function_privilege('service_role',
      'private.iclub_ai_v21_stage_three_locale_revision_v1(text,bigint,text,text,jsonb,text)','EXECUTE')
 THEN RAISE EXCEPTION 'Security/atomic rollback invariant failed'; END IF;
END $test$;
SELECT 'PASS_SOURCE_IMMUTABLE_HISTORY' result;
