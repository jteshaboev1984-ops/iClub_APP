-- ONLY fake synthetic data in disposable CI PostgreSQL after base and receipt fixtures.
DO $t$
DECLARE allowed boolean; delivered_key text; v_result integer;
BEGIN
 IF (SELECT count(*) FROM private.iclub_ai_v21_qbank_content_history)<>10
 OR (SELECT count(*) FROM private.iclub_ai_v21_qbank_owner_review_reports)<>1
 OR (SELECT count(*) FROM private.iclub_ai_v21_qbank_content_history
   WHERE initially_admitted)<>7
 THEN RAISE EXCEPTION 'Version ledger synthetic baseline incorrect'; END IF;

 SELECT source_card_key INTO delivered_key
 FROM private.iclub_ai_v21_academic_deliveries
 WHERE request_id='aaaaaaaa-aaaa-4aaa-aaaa-aaaaaaaaaaaa';
 IF delivered_key IS NULL THEN RAISE EXCEPTION 'Delivery missing from earlier scratch fixture'; END IF;

 v_result:=private.iclub_ai_v21_stage_qbank_revision_v2(
  'chemistry',503,'curated_v2','curated_v3_503',
  jsonb_build_object(
   'en',repeat('Synthetic revised science English explanation for sample reasoning. ',3),
   'ru',repeat('Синтетическое исправленное русское объяснение научной задачи. ',3),
   'uz',repeat('Sintetik qayta tekshiriladigan ilmiy izoh uchun namunaviy matn. ',3)),
  'SYNTHETIC_ONLY_IMMUTABLE_REVISION_TEST');
 IF v_result<>3 THEN RAISE EXCEPTION 'Must atomically update exactly 3 locale copies'; END IF;
 IF (SELECT count(*) FROM private.iclub_ai_v21_academic_sources a
    WHERE a.context_key='question_503' AND a.source_version='curated_v3_503'
    AND a.publication_revision=3 AND a.revoked AND NOT a.published
    AND NOT a.content_reviewed AND NOT a.rights_reviewed
    AND NOT a.locale_reviewed AND NOT a.academic_qa_passed)<>3
 OR (SELECT count(*) FROM private.iclub_ai_v21_qbank_content_history)<>13
 OR (SELECT count(*) FROM private.iclub_ai_v21_qbank_content_history
  WHERE context_key='question_503' AND source_version='curated_v2')<>3
 OR (SELECT count(*) FROM private.iclub_ai_v21_qbank_content_history
  WHERE context_key='question_503' AND source_version='curated_v3_503')<>3
 OR (SELECT source_card_key FROM private.iclub_ai_v21_academic_deliveries
     WHERE request_id='aaaaaaaa-aaaa-4aaa-aaaa-aaaaaaaaaaaa')<>delivered_key
 OR (SELECT source_card_key FROM private.iclub_ai_v21_academic_sources
     WHERE context_key='question_503' AND locale='en')<>delivered_key
 THEN RAISE EXCEPTION 'Question history or delivery identity changed'; END IF;

 allowed:=true;
 BEGIN
  PERFORM private.iclub_ai_v21_stage_qbank_revision_v2(
   'chemistry',503,'curated_v2','curated_v4_503',
   jsonb_build_object('en',repeat('A',150),
    'ru',repeat('B',150),'uz',repeat('C',150)),
   'SYNTHETIC_REJECT_STALE_CONTENT');
 EXCEPTION WHEN others THEN allowed:=false; END;
 IF allowed THEN RAISE EXCEPTION 'Stale version could rewrite current text'; END IF;

 allowed:=true;
 BEGIN
  PERFORM private.iclub_ai_v21_stage_qbank_revision_v2(
   'chemistry',503,'curated_v3_503','curated_v4_503',
   jsonb_build_object('en',repeat('A',150),'ru',repeat('B',150)),
   'SYNTHETIC_REJECT_MISSING_UZ');
 EXCEPTION WHEN others THEN allowed:=false; END;
 IF allowed THEN RAISE EXCEPTION 'Missing Uzbek revision was allowed'; END IF;

 allowed:=true;
 BEGIN
  PERFORM private.iclub_ai_v21_stage_qbank_revision_v2(
   'chemistry',501,'qbank_exact_explanation_draft_v1','curated_v4_501',
   jsonb_build_object('en',repeat('A',150),'ru',repeat('B',150),
     'uz',repeat('C',150)),
   'SYNTHETIC_REJECT_STILL_GRANTED');
 EXCEPTION WHEN others THEN allowed:=false; END;
 IF allowed THEN RAISE EXCEPTION 'Existing owner-enabled content changed'; END IF;

 allowed:=true;
 BEGIN
  PERFORM private.iclub_ai_v21_stage_qbank_revision_v2(
   'chemistry',601,'legacy_approved_v1','curated_v4_601',
   jsonb_build_object('en',repeat('A',150),'ru',repeat('B',150),
     'uz',repeat('C',150)),
   'SYNTHETIC_REJECT_LEGACY_SOURCE');
 EXCEPTION WHEN others THEN allowed:=false; END;
 IF allowed THEN RAISE EXCEPTION 'Legacy owner-released content changed'; END IF;

 allowed:=true;
 BEGIN
  UPDATE private.iclub_ai_v21_qbank_content_history
   SET body_text='tamper' WHERE context_key='question_503';
 EXCEPTION WHEN others THEN allowed:=false; END;
 IF allowed THEN RAISE EXCEPTION 'Append-only history accepted update'; END IF;

 allowed:=true;
 BEGIN
  UPDATE private.iclub_ai_v21_qbank_owner_review_reports
    SET released=true WHERE question_id=501;
 EXCEPTION WHEN others THEN allowed:=false; END;
 IF allowed THEN RAISE EXCEPTION 'Owner report upgraded to approval'; END IF;

 IF (SELECT count(*) FROM private.iclub_ai_v21_academic_sources a
   WHERE private.iclub_ai_v21_source_admitted_v1(a))<>7
 OR has_table_privilege('service_role',
 'private.iclub_ai_v21_qbank_content_history','SELECT')
 OR has_function_privilege('service_role',
 'private.iclub_ai_v21_stage_qbank_revision_v2(text,bigint,text,text,jsonb,text)',
 'EXECUTE')
 THEN RAISE EXCEPTION 'Revision impacted admitted content or learner permissions'; END IF;
END $t$;
SELECT 'PASS_321_SOURCE_VERSIONED_LIFECYCLE_SYNTHETIC' result;
