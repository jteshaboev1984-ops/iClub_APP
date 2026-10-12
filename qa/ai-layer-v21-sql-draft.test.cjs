// Local source-only review; NOT SQL execution. node --test qa/ai-layer-v21-sql-draft.test.cjs
'use strict';
const {test}=require('node:test'),assert=require('node:assert/strict');
const fs=require('node:fs');
const draft=fs.readFileSync('qa/sql_drafts/iclub_ai_v21_meter_v2_UNAPPLIED.sql','utf8');
const old=fs.readFileSync('supabase/migrations/20261006102000_iclub_global_ai_tariff_foundation_v1.sql','utf8');
test('QA SQL remains outside autoloaded migration path',()=>{
 assert.match(draft,/UNAPPLIED draft|NEVER APPLY IN PRODUCTION/);
 assert.ok(!draft.includes('drop table private.'));
});
test('v2 names are separate and existing v1 source is still present',()=>{
 assert.match(draft,/function public\.reserve_iclub_ai_usage_service_v2\(/);
 assert.match(draft,/function public\.finalize_iclub_ai_usage_service_v2\(/);
 assert.match(old,/function public\.reserve_iclub_ai_usage_service_v1\(/);
});
test('V2 uses brand-new QA policy codes with approved temporary 1:3 mix',()=>{
 for(const code of ['free_qa_v2','plus_qa_v2','pro_qa_v2'])assert.ok(draft.includes(code));
 assert.ok(draft.includes("18000,3,1,3,false"));
 assert.ok(draft.includes("18000,9,1,3,true"));
 assert.ok(draft.includes("18000,14,1,3,true"));
 assert.ok(!draft.includes("update private.iclub_ai_usage_policies"));
});
test('Shortfall is route-specific and does not write exhausted',()=>{
 const code=draft.slice(draft.indexOf('create or replace function public.reserve_iclub_ai_usage_service_v2('),
   draft.indexOf('revoke all on function public.reserve_iclub_ai_usage_service_v2('));
 assert.ok(code.includes("'reason','route_insufficient'"));
 assert.ok(!code.includes('set exhausted=true'));
 assert.ok(code.includes('v_policy.allowance_units-v_period.committed_units-v_period.reserved_units'));
});
test('SQL request identity binds user, route, fingerprint and policy',()=>{
 for(const part of ['v_existing.user_id<>p_user_id','v_existing.route_class<>p_route_class',
 'v_existing.request_fingerprint is distinct from p_request_fingerprint',
 'p.usage_policy_code=p_usage_policy_code'])assert.ok(draft.includes(part));
});
test('Duplicated request does not issue another generated reply',()=>{
 assert.ok(draft.includes("'allowed',false,"));
 assert.ok(draft.includes("'request_in_progress'"));
 assert.ok(draft.includes("'request_already_completed'"));
});
test('Serializable per-user reservation guard and TTL exist',()=>{
 assert.ok(draft.includes('pg_advisory_xact_lock('));
 assert.ok(draft.includes('for update'));
 assert.ok(draft.includes('reservation_expired'));
 assert.ok(draft.includes('p_request_fingerprint'));
});
test('Only service_role may execute versioned RPC',()=>{
 assert.match(draft,/revoke all on function public\.reserve_iclub_ai_usage_service_v2[\s\S]*?from public,anon,authenticated;/);
 assert.match(draft,/grant execute on function public\.reserve_iclub_ai_usage_service_v2[\s\S]*?to service_role;/);
});
