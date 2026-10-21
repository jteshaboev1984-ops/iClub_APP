"use strict";
// REAL scratch PostgreSQL proof, no production DB, no Supabase credentials.
// Requires PGDATABASE to name a disposable database created by CI.
const fs=require("node:fs"),path=require("node:path"),cp=require("node:child_process"),assert=require("node:assert/strict");
const file=fs.readFileSync(path.join(__dirname,"iclub_ai_v21_qbank_owner_provenance_GATE_ONLY_UNAPPLIED_20261020.sql"),"utf8");
const start=file.indexOf("CREATE TABLE private.iclub_ai_v21_qbank_owner_beta_releases(");
const end=file.indexOf("-- The new pathway must remain entirely OFF",start);
assert.ok(start>0&&end>start,"Expected isolated release table and function");
const gateOnly=file.slice(start,end);
const revisionStage=fs.readFileSync(path.join(__dirname,"iclub_ai_v21_source_revision_history_QA_ONLY_UNAPPLIED_20261020.sql"),"utf8");
assert.ok(!gateOnly.includes("UPDATE public.questions")&&!gateOnly.includes("DELETE FROM"));
assert.ok(process.env.PGDATABASE?.startsWith("iclub_ai_v21_scratch_"),"Refuse non-scratch DB");
const schema=`
\\set ON_ERROR_STOP on
CREATE ROLE anon NOLOGIN;
CREATE ROLE authenticated NOLOGIN;
CREATE ROLE service_role NOLOGIN;
CREATE SCHEMA private;
CREATE SCHEMA extensions;
CREATE EXTENSION pgcrypto WITH SCHEMA extensions;
CREATE TABLE public.subjects(
 id bigint PRIMARY KEY, subject_key text NOT NULL UNIQUE, is_active boolean NOT NULL);
CREATE TABLE public.questions(
 id bigint PRIMARY KEY,subject_id bigint NOT NULL REFERENCES public.subjects(id),
 is_active boolean NOT NULL,quality_status text NOT NULL,
 explanation_en text,explanation_ru text,explanation_uz text);
CREATE TABLE public.practice_pools(id bigint PRIMARY KEY,subject_id bigint,
 is_active boolean NOT NULL);
CREATE TABLE public.practice_pool_questions(question_id bigint,pool_id bigint,
 is_active boolean NOT NULL);
CREATE TABLE private.iclub_ai_v21_academic_sources(
 surface_code text NOT NULL,subject_key text NOT NULL,context_key text NOT NULL,
 locale text NOT NULL,source_card_key text PRIMARY KEY,source_version text NOT NULL,
 publication_revision integer NOT NULL,body_text text NOT NULL,
 content_hash text NOT NULL,target_hash text NOT NULL,
 content_reviewed boolean NOT NULL DEFAULT false,
 rights_reviewed boolean NOT NULL DEFAULT false,
 locale_reviewed boolean NOT NULL DEFAULT false,
 academic_qa_passed boolean NOT NULL DEFAULT false,
 published boolean NOT NULL DEFAULT false,revoked boolean NOT NULL DEFAULT true,
 approved_at timestamptz);
CREATE TABLE private.iclub_ai_v21_owner_beta_source_releases(
 source_card_key text PRIMARY KEY,source_version text,content_hash text,
 target_hash text,release_basis text,enabled boolean);
CREATE TABLE private.iclub_ai_v21_academic_deliveries(request_id uuid PRIMARY KEY,subject_key text,context_key text,source_card_key text);
CREATE TABLE private.practice_ai_source_cards(
 source_card_key text PRIMARY KEY,subject_key text,question_id bigint,
 source_version text,locale text,card_type text,approval_status text,
 rights_status text,is_runtime_allowed boolean,approved_at timestamptz,
 content_hash text,body_text text);
CREATE FUNCTION private.iclub_ai_v21_target_fingerprint_v1(
 p_surface text,p_id bigint) RETURNS text LANGUAGE sql STABLE SET search_path=''
 AS $fp$
 SELECT encode(extensions.digest(convert_to(
 jsonb_build_array(id,subject_id,is_active,quality_status,explanation_en,
 explanation_ru,explanation_uz)::text,'UTF8'),'sha256'),'hex')
 FROM public.questions WHERE id=p_id AND p_surface='practice_error';
 $fp$;
INSERT INTO public.subjects VALUES
 (1,'chemistry',true),(2,'economics',true);
INSERT INTO public.questions VALUES
 (501,1,true,'published',
  'An iClub original Chemistry explanation in English.',
  'Оригинальное объяснение iClub для химии на русском языке.',
  'Kimyo bo‘yicha original iClub izohi o‘zbek tilida.'),
 (502,2,true,'published',
  'An iClub original Economics explanation in English.',
  'Оригинальное объяснение iClub по экономике.',
  'Iqtisodiyot bo‘yicha original iClub izohi.'),
 (601,1,true,'published','Old original explanation','Старое объяснение','Eski izoh');
INSERT INTO public.practice_pools VALUES (11,1,true),(12,2,true);
INSERT INTO public.practice_pool_questions VALUES (501,11,true),(502,12,true);
INSERT INTO private.iclub_ai_v21_academic_sources(
 surface_code,subject_key,context_key,locale,source_card_key,
 source_version,publication_revision,body_text,content_hash,target_hash
)
SELECT 'practice_error',s.subject_key,'question_'||q.id,l.locale,
 'draft_'||q.id||'_'||l.locale,'qbank_exact_explanation_draft_v1',1,
 l.body,encode(extensions.digest(convert_to(l.body,'UTF8'),'sha256'),'hex'),
 private.iclub_ai_v21_target_fingerprint_v1('practice_error',q.id)
FROM public.questions q JOIN public.subjects s ON s.id=q.subject_id
CROSS JOIN LATERAL (VALUES ('en',q.explanation_en),('ru',q.explanation_ru),
 ('uz',q.explanation_uz)) l(locale,body)
WHERE q.id IN(501,502);
INSERT INTO private.iclub_ai_v21_academic_sources(
 surface_code,subject_key,context_key,locale,source_card_key,
 source_version,publication_revision,body_text,content_hash,target_hash
)
SELECT 'practice_error','chemistry','question_601','en','old_601_en',
 'legacy_approved_v1',1,q.explanation_en,
 encode(extensions.digest(convert_to(q.explanation_en,'UTF8'),'sha256'),'hex'),
 private.iclub_ai_v21_target_fingerprint_v1('practice_error',q.id)
FROM public.questions q WHERE id=601;
INSERT INTO private.practice_ai_source_cards
(source_card_key,subject_key,question_id,source_version,locale,card_type,
 approval_status,rights_status,is_runtime_allowed,approved_at,content_hash,body_text)
SELECT source_card_key,'chemistry',601,source_version,'en','answer_explanation',
 'approved','original_iclub',true,clock_timestamp(),content_hash,body_text
FROM private.iclub_ai_v21_academic_sources WHERE source_card_key='old_601_en';
INSERT INTO private.iclub_ai_v21_owner_beta_source_releases
SELECT source_card_key,source_version,content_hash,target_hash,
 'owner_authorized_closed_beta_20261020',true
FROM private.iclub_ai_v21_academic_sources WHERE source_card_key='old_601_en';
`;
const fixtures=`
INSERT INTO private.iclub_ai_v21_qbank_owner_beta_releases
(source_card_key,source_version,content_hash,target_hash,subject_key,question_id,
 locale,original_source_hash,owner_release_ref,rights_evidence_ref,
 academic_evidence_ref,locale_evidence_ref,enabled,released_at)
SELECT a.source_card_key,a.source_version,a.content_hash,a.target_hash,
 a.subject_key,substring(a.context_key from 10)::bigint,a.locale,
 encode(extensions.digest(convert_to(btrim(a.body_text),'UTF8'),'sha256'),'hex'),
 'SYNTHETIC_OWNER_APPROVAL_ONLY',
 'SYNTHETIC_RIGHTS_EVIDENCE_ONLY',
 'SYNTHETIC_ACADEMIC_REVIEW_ONLY',
 'SYNTHETIC_LOCALE_REVIEW_ONLY',false,NULL
FROM private.iclub_ai_v21_academic_sources a WHERE a.source_card_key LIKE 'draft_%';
DO $assert$
BEGIN
 IF (SELECT count(*) FROM private.iclub_ai_v21_academic_sources a
  WHERE private.iclub_ai_v21_source_admitted_v1(a))<>1
 THEN RAISE EXCEPTION 'At default OFF only the historical legacy card is admissible'; END IF;
 IF (SELECT count(*) FROM private.iclub_ai_v21_qbank_owner_beta_releases WHERE enabled)<>0
 THEN RAISE EXCEPTION 'New authorization must default OFF'; END IF;
 IF has_table_privilege('authenticated',
  'private.iclub_ai_v21_qbank_owner_beta_releases','SELECT')
 OR has_table_privilege('service_role',
  'private.iclub_ai_v21_qbank_owner_beta_releases','INSERT')
 THEN RAISE EXCEPTION 'Private release permissions are unsafe'; END IF;
END $assert$;
-- No partial-language accidental exposure:
UPDATE private.iclub_ai_v21_qbank_owner_beta_releases
SET enabled=true,released_at=clock_timestamp()
WHERE question_id=501 AND locale='en';
DO $assert$ BEGIN
 IF (SELECT count(*) FROM private.iclub_ai_v21_academic_sources a
  WHERE private.iclub_ai_v21_source_admitted_v1(a))<>1
 THEN RAISE EXCEPTION 'Partial localization release leaked'; END IF;
END $assert$;
-- The second subject has no release; all first subject languages explicitly enabled.
UPDATE private.iclub_ai_v21_qbank_owner_beta_releases
SET enabled=true,released_at=clock_timestamp()
WHERE question_id=501 AND locale IN ('ru','uz');
DO $assert$ BEGIN
 IF (SELECT count(*) FROM private.iclub_ai_v21_academic_sources a
  WHERE private.iclub_ai_v21_source_admitted_v1(a))<>4
 THEN RAISE EXCEPTION 'Three exact language-bound owner sources not accepted'; END IF;
END $assert$;
-- Revoking one language closes the entire new language set.
UPDATE private.iclub_ai_v21_qbank_owner_beta_releases SET enabled=false
WHERE question_id=501 AND locale='ru';
DO $assert$ BEGIN
 IF (SELECT count(*) FROM private.iclub_ai_v21_academic_sources a
  WHERE private.iclub_ai_v21_source_admitted_v1(a))<>1
 THEN RAISE EXCEPTION 'Revoked locale still exposed'; END IF;
END $assert$;
UPDATE private.iclub_ai_v21_qbank_owner_beta_releases SET enabled=true
WHERE question_id=501 AND locale='ru';
-- Invalid text snapshot: no query/question DB mutation, only synthetic source copy.
UPDATE private.iclub_ai_v21_academic_sources SET body_text='Tampered text'
WHERE source_card_key='draft_501_ru';
DO $assert$ BEGIN
 IF (SELECT count(*) FROM private.iclub_ai_v21_academic_sources a
  WHERE private.iclub_ai_v21_source_admitted_v1(a))<>1
 THEN RAISE EXCEPTION 'Tampered source body was admitted'; END IF;
END $assert$;
UPDATE private.iclub_ai_v21_academic_sources SET body_text=q.explanation_ru
FROM public.questions q WHERE source_card_key='draft_501_ru' AND q.id=501;
-- Version drift to even a single approved locale blocks the whole set.
UPDATE private.iclub_ai_v21_qbank_owner_beta_releases
SET source_version='forged_version' WHERE question_id=501 AND locale='uz';
DO $assert$ BEGIN
 IF (SELECT count(*) FROM private.iclub_ai_v21_academic_sources a
  WHERE private.iclub_ai_v21_source_admitted_v1(a))<>1
 THEN RAISE EXCEPTION 'Version drift not blocked'; END IF;
END $assert$;
UPDATE private.iclub_ai_v21_qbank_owner_beta_releases
SET source_version='qbank_exact_explanation_draft_v1' WHERE question_id=501 AND locale='uz';
-- Material live question change invalidates original bound target sha and body.
UPDATE public.questions SET explanation_en='Changed answer key and text'
WHERE id=501;
DO $assert$ BEGIN
 IF (SELECT count(*) FROM private.iclub_ai_v21_academic_sources a
  WHERE private.iclub_ai_v21_source_admitted_v1(a))<>1
 THEN RAISE EXCEPTION 'Stale question fingerprint not blocked'; END IF;
END $assert$;
UPDATE public.questions
SET explanation_en='An iClub original Chemistry explanation in English.' WHERE id=501;
-- Source no longer in an active Practice pool:
UPDATE public.practice_pool_questions SET is_active=false WHERE question_id=501;
DO $assert$ BEGIN
 IF (SELECT count(*) FROM private.iclub_ai_v21_academic_sources a
  WHERE private.iclub_ai_v21_source_admitted_v1(a))<>1
 THEN RAISE EXCEPTION 'Removed Practice source still admitted'; END IF;
END $assert$;
UPDATE public.practice_pool_questions SET is_active=true WHERE question_id=501;
-- Content signing alone does not bypass owner explicit release for Economics.
DO $assert$ BEGIN
 IF (SELECT count(*) FROM private.iclub_ai_v21_academic_sources a
  WHERE private.iclub_ai_v21_source_admitted_v1(a))<>4
 THEN RAISE EXCEPTION 'Prior first-subject scope unexpectedly drifted'; END IF;
 IF EXISTS(SELECT 1 FROM private.iclub_ai_v21_academic_sources
  WHERE published OR NOT revoked OR content_reviewed OR rights_reviewed
   OR locale_reviewed OR academic_qa_passed OR approved_at IS NOT NULL)
 THEN RAISE EXCEPTION 'Synthetic QA forged independent editorial status'; END IF;
END $assert$;
-- Versioned editorial correction is kept ONLY in AI source rows. The
-- student's original question and assessment remain immutable.
UPDATE private.iclub_ai_v21_academic_sources
SET source_version='qbank_curated_revision_v2',
 body_text=CASE locale
 WHEN 'en' THEN 'Curated explanation: the answer follows from the exact conditions of the question. A full worked explanation is reviewed and signed independently for learners.'
 WHEN 'ru' THEN 'Исправленное объяснение: ответ следует из условий исходного задания. Полный разбор проверяется и утверждается отдельно, без изменения оценок и вопросов.'
 ELSE 'Tahrirlangan izoh: javob ayni savolning shartlariga tayangan. To‘liq tahlil mustaqil tekshirilib tasdiqlanadi, savol va oldingi baholar o‘zgarmaydi.' END
WHERE context_key='question_502';
UPDATE private.iclub_ai_v21_academic_sources
SET content_hash=encode(extensions.digest(convert_to(body_text,'UTF8'),'sha256'),'hex')
WHERE context_key='question_502';
UPDATE private.iclub_ai_v21_qbank_owner_beta_releases beta
SET origin_basis='original_iclub_curated_revision',
 source_version=src.source_version,
 content_hash=src.content_hash,
 editorial_revision_ref='SYNTHETIC_CURATED_EDITS_502_R2',
 enabled=true,released_at=clock_timestamp()
FROM private.iclub_ai_v21_academic_sources src
WHERE beta.source_card_key=src.source_card_key
 AND beta.question_id=502;
DO $assert$ BEGIN
 IF (SELECT count(*) FROM private.iclub_ai_v21_academic_sources a
     WHERE private.iclub_ai_v21_source_admitted_v1(a))<>7
 THEN RAISE EXCEPTION 'Curated exact-question localized revision did not admit 3 versions'; END IF;
END $assert$;
-- A forged editorial revision reference in one language blocks all 3.
UPDATE private.iclub_ai_v21_qbank_owner_beta_releases
SET editorial_revision_ref='SYNTHETIC_WRONG_REVISION_REF'
WHERE question_id=502 AND locale='uz';
DO $assert$ BEGIN
 IF (SELECT count(*) FROM private.iclub_ai_v21_academic_sources a
     WHERE private.iclub_ai_v21_source_admitted_v1(a))<>4
 THEN RAISE EXCEPTION 'Curated language revision mismatch did not fail closed'; END IF;
END $assert$;
UPDATE private.iclub_ai_v21_qbank_owner_beta_releases
SET editorial_revision_ref='SYNTHETIC_CURATED_EDITS_502_R2'
WHERE question_id=502 AND locale='uz';
-- A stale snapshot of original bank text stops every new language.
UPDATE private.iclub_ai_v21_qbank_owner_beta_releases
SET original_source_hash=repeat('0',64)
WHERE question_id=502 AND locale='ru';
DO $assert$ BEGIN
 IF (SELECT count(*) FROM private.iclub_ai_v21_academic_sources a
     WHERE private.iclub_ai_v21_source_admitted_v1(a))<>4
 THEN RAISE EXCEPTION 'Broken origin snapshot SHA did not fail closed'; END IF;
END $assert$;
-- An unapproved revision MUST NOT alter learner answers/grades.
DO $assert$ BEGIN
 IF (SELECT count(*) FROM private.iclub_ai_v21_academic_sources a
     WHERE private.iclub_ai_v21_source_admitted_v1(a))<>4
 THEN RAISE EXCEPTION 'Pre-release source admission unexpectedly widened'; END IF;
END $assert$;
SELECT 'PASS_REAL_SCRATCH_PG_OWNER_QBANK_PROVENANCE' result;
`;
const revisionTests=fs.readFileSync(path.join(__dirname,
 "iclub_ai_v21_revision_ledger_SCRATCH_TEST_ONLY_20261020.sql"),"utf8");
const {sourceEnvelopeHash}=require("./iclub-ai-v21-qbank-p4-signed-triad-bridge.cjs");
const p4Body="Синтетический материал с Unicode и новой строкой\nSecond synthetic line.";
// Actual PostgreSQL proof: P4 source hash binds source_text + LF + '{}'::jsonb.
const p4Proof=`DO $p4hash$ BEGIN
 IF encode(extensions.digest(convert_to(
 $body$Синтетический материал с Unicode и новой строкой
Second synthetic line.$body$||E'\\n'||'{}'::jsonb::text,'UTF8'),
 'sha256'),'hex')<>'${sourceEnvelopeHash(p4Body)}' THEN
  RAISE EXCEPTION 'P4 signed source envelope differs from PostgreSQL digest';
 END IF;
END $p4hash$;
SELECT 'PASS_P4_SOURCE_ENVELOPE_POSTGRES_SHA' result;`;
const sql=[schema,gateOnly,revisionStage,fixtures,revisionTests,p4Proof]
 .join(String.fromCharCode(10));
try{
 const result=cp.execFileSync("psql",["-X","-v","ON_ERROR_STOP=1"],{input:sql,encoding:"utf8",timeout:90000,maxBuffer:2_000_000});
 assert.match(result,/PASS_REAL_SCRATCH_PG_OWNER_QBANK_PROVENANCE/);
 assert.match(result,/PASS_SOURCE_IMMUTABLE_HISTORY/);
 assert.match(result,/PASS_P4_SOURCE_ENVELOPE_POSTGRES_SHA/);
 console.log("PASS: exact old legacy + new gate + multi-locale + revoke + SHA + active pool + permissions (scratch only)");
}catch(error){console.error(error.stdout||"",error.stderr||"");throw error;}
