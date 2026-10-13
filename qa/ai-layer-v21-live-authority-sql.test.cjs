'use strict';
const {test}=require('node:test');
const assert=require('node:assert/strict');
const fs=require('node:fs');
const draft=fs.readFileSync('qa/sql_drafts/iclub_ai_v21_live_authority_UNAPPLIED.sql','utf8');
const pg=fs.readFileSync('qa/sql_drafts/iclub_ai_v21_live_authority_local_pg.psql','utf8');
const edge=fs.readFileSync('qa/edge_v21/supabase_services.ts','utf8');
test('Authority SQL is scratch-only and leaves all existing v1 functions untouched',()=>{
 assert.match(draft,/current_database\(\) !~ '\^iclub_ai_v21_scratch_/);
 assert.match(draft,/local scratch/);
 assert.doesNotMatch(draft,/CREATE OR REPLACE FUNCTION (public\.get_iclub_global_ai_guard_service_v1|private\.iclub_ai_has_active_protected_assessment_v1|private\.iclub_rollout_allows_user_v1)/i);
 assert.doesNotMatch(draft,/UPDATE (public\.users|public\.user_subjects|private\.iclub_plan_policies|public\.lessons)/i);
});
test('Runtime release requires independent explicit owner-controlled approval and OFF is default',()=>{
 assert.match(draft,/release_approved boolean NOT NULL DEFAULT false/);
 assert.match(draft,/coalesce\(a\.release_approved,false\)/);
 assert.match(draft,/coalesce\(r\.kill_switch,true\)/);
 assert.match(draft,/REVOKE ALL ON TABLE private\.iclub_ai_v21_release_control/);
});
test('Rollout composes existing server guards and exact subject membership',()=>{
 for(const n of ['iclub_rollout_allows_user_v1','iclub_ai_has_active_protected_assessment_v1',
  'get_iclub_subject_access_guard_service_v1','public.user_subjects','public.subjects',
  's.is_active','lesson_','question_']) assert.ok(draft.includes(n),n);
 assert.match(draft,/p_user_id,p_subject,'open'/);
});
test('Entitlement uses current subscription capabilities; maps QA-only policies',()=>{
 assert.match(draft,/get_iclub_subscription_capabilities_service_v1/);
 for(const v of ['free_qa_v2','plus_qa_v2','pro_qa_v2','ai_generation_entitled'])
  assert.ok(draft.includes(v));
 assert.doesNotMatch(draft,/UPDATE private\.iclub_subscription_/i);
});
test('Paid provider budget is DENY until its independent atomic accounting passes',()=>{
 assert.match(draft,/provider_budget_not_authorized/);
 assert.match(draft,/SELECT jsonb_build_object\('allowed',false/);
 assert.doesNotMatch(draft,/exam_prep_ai_provider_leases/i);
});
test('All five RPCs are service_role only; none open to learner roles',()=>{
 const names=['runtime_service()','protected_service(uuid)','rollout_service(uuid,text,text,text,text)',
 'entitlement_service(uuid)','provider_budget_service(uuid,text,text)'];
 for(const n of names){assert.ok(draft.includes(n));}
 assert.match(draft,/FROM PUBLIC,anon,authenticated/g);
 assert.match(draft,/TO service_role/g);
});
test('Native PostgreSQL acceptance uses real temporary tables, v1 interface stubs and forced rollback',()=>{
 assert.match(pg,/^BEGIN;/m);assert.match(pg,/^ROLLBACK;/m);
 for(const n of ['Missing owner release was bypassed','v1 subject-access guard was bypassed',
 'Protected exam failed closed','Subject removal failed closed','Unapproved paid provider was enabled',
 'Free mapping failed','Plus subscription mapping failed','Pro subscription mapping failed'])
 assert.ok(pg.includes(n),n);
 assert.match(pg,/current_database\(\) !~ '\^iclub_ai_v21_scratch_/);
});
test('Existing Edge adapter uses these RPCs and treats 404 as DENY',()=>{
 for(const n of ['get_iclub_ai_v21_runtime_service','get_iclub_ai_v21_protected_service',
 'get_iclub_ai_v21_rollout_service','get_iclub_ai_v21_entitlement_service',
 'get_iclub_ai_v21_provider_budget_service'])assert.ok(edge.includes(n),n);
 assert.match(edge,/const safe=async/);
 assert.match(edge,/const deny=\(\)=>\(\{ready:false,allowed:false\}\)/);
});
