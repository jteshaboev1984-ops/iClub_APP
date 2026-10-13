'use strict';
const {test}=require('node:test'),a=require('node:assert/strict'),fs=require('node:fs');
const sql=fs.readFileSync('qa/sql_drafts/iclub_ai_source_proof_bundle_v21_UNAPPLIED.sql','utf8');
const pg=fs.readFileSync('qa/sql_drafts/iclub_ai_source_proof_bundle_local_pg.psql','utf8');
const runner=fs.readFileSync('qa/run-ai-layer-v21-postgres-local.sh','utf8');
test('Technical source bridge is scratch-only, never a migration or publisher',()=>{
 a.match(sql,/current_database\(\) !~ '\^iclub_ai_v21_scratch_/);
 a.match(sql,/BLOCKED: source proof bridge only in local scratch/);
 a.ok(!/CREATE OR REPLACE FUNCTION public\.publish_/i.test(sql));
});
test('Only exact subject + surface + feature + topic + language + source version can match',()=>{
 for(const key of ['surface_code','subject_key','feature_code','topic_key','locale',
   'source_id','source_version','source_hash'])
  a.ok(sql.includes(key),key);
 a.ok(sql.includes('PRIMARY KEY(surface_code,subject_key,feature_code,topic_key,locale,source_id,source_version)'));
});
test('Source proof recomputes SHA256 over actual versioned payload each call',()=>{
 a.ok(sql.includes("encode(sha256(convert_to("));
 a.ok(sql.includes("v.source_text||E'\\n'||v.prepared_variants::text"));
 a.ok(sql.includes('v.source_hash<>rel.source_hash'));
});
test('An editorial source and a release row are independently necessary',()=>{
 a.ok(sql.includes('private.iclub_ai_topic_release_v21'));
 a.ok(sql.includes('private.iclub_ai_v21_editorial_source_versions'));
 a.ok(sql.includes("rel.publication_state<>'approved'"));
 a.ok(sql.includes("v.record_state<>'published'"));
});
test('Explicit rights, integrity, QA and no conflict are independently required',()=>{
 for(const key of ['v.rights_approved IS DISTINCT FROM true','v.qa_passed IS DISTINCT FROM true',
 'v.integrity_verified IS DISTINCT FROM true','v.runtime_allowed IS DISTINCT FROM true',
 'v.source_conflict IS DISTINCT FROM false'])a.ok(sql.includes(key),key);
});
test('Prepared reply does not return all other answers or raw source body',()=>{
 a.ok(sql.includes('prepared:=jsonb_build_object(p_prompt_key,selected_text)'));
 a.ok(sql.includes("'source_text',CASE WHEN p_route_class='generated' THEN selected_text ELSE '' END"));
 a.ok(sql.includes("jsonb_typeof(v.prepared_variants->p_prompt_key) IS DISTINCT FROM 'string'"));
});
test('Server context resolved each source bundle request',()=>{
 a.ok(sql.includes('public.get_iclub_ai_v21_scoped_context_service(p_user_id,p_context_handle)'));
 a.ok(sql.includes("IF c->>'allowed' IS DISTINCT FROM 'true'"));
 a.ok(sql.includes("rel.topic_key=ref->>'topic'"));
 a.ok(sql.includes('r.publication_revision<>p_publication_revision'));
});
test('No service-role source RPC available to browser credentials',()=>{
 for(const name of ['get_iclub_ai_v21_source_proof_service','get_iclub_ai_v21_source_bundle_service']){
  a.ok(sql.includes('REVOKE ALL ON FUNCTION public.'+name),name);
  a.ok(sql.includes('GRANT EXECUTE ON FUNCTION public.'+name),name);
 }
 a.ok(sql.includes('REVOKE ALL ON TABLE private.iclub_ai_v21_editorial_source_versions'));
});
test('The bridge never changes academic progress, exams, grades or quota tables',()=>{
 for(const expr of [/UPDATE public\.practice_/i,/DELETE FROM public\.tour_/i,
 /INSERT INTO public\.user_subjects/i,/UPDATE public\.lessons/i,
 /UPDATE private\.iclub_ai_usage_/i])a.equal(expr.test(sql),false,String(expr));
});
test('Local PG fixture checks independent publication, hash, revocation, identity',()=>{
 for(const title of ['Unpublished source opened','Source row itself granted readiness',
  'Exact approved hash proof failed','Foreign learner obtained payload',
  'Unpublished UZ locale borrowed RU source','Source digest tamper did not revoke proof',
  'Rights revocation did not disable proof','Technical feature disable did not close source',
  'Old Biology screen still gets approved text','Economics borrowed Biology source',
  'Exam leaked AI payload'])a.ok(pg.includes(title),title);
 a.match(pg,/^BEGIN;/m);a.match(pg,/^ROLLBACK;/m);
 a.ok(runner.includes('source) TEST_FILE="qa/sql_drafts/iclub_ai_source_proof_bundle_local_pg.psql"'));
});
