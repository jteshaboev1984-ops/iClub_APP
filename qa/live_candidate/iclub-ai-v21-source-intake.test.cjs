"use strict";
const {test}=require("node:test");
const assert=require("node:assert/strict");
const fs=require("node:fs");
const path=require("node:path");
const staging=fs.readFileSync(path.join(__dirname,
  "iclub_ai_v21_reusable_staging_candidates_20261020.sql"),"utf8");
const guard=fs.readFileSync(path.join(__dirname,
  "iclub_ai_v21_generic_delivery_target_fingerprint_20261020.sql"),"utf8");
test("One universal importer covers all future subjects without subject-specific code",()=>{
 assert.match(staging,/CREATE FUNCTION private\.iclub_ai_v21_stage_legacy_exact_questions_v1\(\)/);
 assert.match(staging,/c\.card_type='answer_explanation'/);
 assert.match(staging,/count\(DISTINCT locale\)=3/);
 assert.match(staging,/count\(DISTINCT source_version\)=1/);
 assert.match(staging,/c\.rights_status='original_iclub'/);
 assert.match(staging,/c\.content_hash=encode\(extensions\.digest/);
 assert.match(staging,/ON CONFLICT\(surface_code,subject_key,context_key,locale\) DO NOTHING/);
 assert.doesNotMatch(staging,/WHERE c\.subject_key\s+IN\s*\(/);
 assert.doesNotMatch(staging,/WHERE c\.subject_key\s*=\s*'(chemistry|economics|mathematics)'/);
});
test("111 copies are unpublished, revoked and have NO inherited approval",()=>{
 assert.match(staging,/false,false,false,false,false,true,NULL/);
 assert.match(staging,/IF n<>111 THEN/);
 assert.match(staging,/count\(DISTINCT context_key\).*<>37/);
 assert.match(staging,/OR src\.published/);
 assert.doesNotMatch(staging,/UPDATE (?:public\.questions|public\.practice_sessions_v4|public\.practice_attempts|private\.practice_ai_source_cards)/);
 assert.doesNotMatch(staging,/DELETE FROM|TRUNCATE TABLE|DROP TABLE/);
});
test("Source fingerprint pin includes changed answer, options, 3 languages, lesson video and Tour questions",()=>{
 for(const value of [
 "q.correct_answer","q.question_text_ru","q.question_text_uz",
 "q.question_text_en","q.options_text_ru","q.options_text_en",
 "q.explanation_ru","q.quality_status","v.video_url",
 "v.duration_seconds","public.tour_questions","q.subject_id"
 ])assert.ok(staging.includes(value),"Missing source fingerprint component: "+value);
 assert.match(staging,/ADD COLUMN target_hash text NOT NULL/);
 assert.match(staging,/source\.target_hash IS DISTINCT FROM private\.iclub_ai_v21_target_fingerprint_v1/);
});
test("Both independent service surfaces re-check current target content",()=>{
 assert.match(guard,/source\.target_hash IS DISTINCT FROM private\.iclub_ai_v21_target_fingerprint_v1/);
 assert.equal((guard.match(/src\.target_hash=private\.iclub_ai_v21_target_fingerprint_v1/g)||[]).length,3);
 assert.match(guard,/p_surface,answer\.question_id/);
 assert.match(guard,/p_surface,p_record_id/);
 assert.match(guard,/p_surface,v_tour/);
 assert.match(guard,/CREATE OR REPLACE FUNCTION public\.deliver_iclub_ai_v21_academic_service/);
 assert.match(guard,/CREATE OR REPLACE FUNCTION public\.get_iclub_ai_v21_academic_capabilities_service/);
 assert.match(guard,/TO service_role/);
 assert.doesNotMatch(guard,/GRANT EXECUTE ON FUNCTION .*TO authenticated/);
});
test("Academic feature and money stay OFF until an explicit separate GO",()=>{
 assert.match(staging,/NOT enabled AND NOT provider_enabled/);
 assert.match(staging,/published,revoked,approved_at/);
 assert.match(guard,/NOT enabled AND NOT provider_enabled/);
 assert.doesNotMatch(staging+guard,/OPENAI_API_KEY|provider\.generate|api\.openai\.com/);
});
