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

test('Scratch PostgreSQL runner refuses anything but an empty localhost scratch DB',()=>{
 const runner=fs.readFileSync('qa/run-ai-layer-v21-postgres-local.sh','utf8');
 assert.match(runner,/ICLUB_PGTEST_DB/);
 assert.match(runner,/^\s*DB="\$\{ICLUB_PGTEST_DB:-\}"/m);
 assert.match(runner,/^\s*if \[\[ ! "\$DB" =~ \^iclub_ai_v21_scratch_/m);
 assert.match(runner,/127\.0\.0\.1/);
 assert.match(runner,/NOT_EMPTY_OR_UNSAFE/);
 assert.match(runner,/pg_tables/);
 assert.match(runner,/unset DATABASE_URL SUPABASE_DB_URL SUPABASE_URL SUPABASE_SERVICE_ROLE_KEY/);
 assert.ok(!runner.includes('createdb '),'Test runner must not create arbitrary DB');
});
test('PostgreSQL script independently refuses populated or non-scratch DB',()=>{
 const sql=fs.readFileSync('qa/sql_drafts/iclub_ai_v21_local_pg_regression.psql','utf8');
 assert.match(sql,/current_database\(\) !~ '\^iclub_ai_v21_scratch_/);
 assert.match(sql,/inet_server_addr\(\)/);
 assert.match(sql,/to_regclass\('public\.users'\)/);
 assert.match(sql,/get_iclub_ai_usage_service_v2|reserve_iclub_ai_usage_service_v2/);
 assert.match(sql,/ROLLBACK;/);
});
test('SQL integration assertions cover cheap remainder and one-charge replay',()=>{
 const sql=fs.readFileSync('qa/sql_drafts/iclub_ai_v21_local_pg_regression.psql','utf8');
 for(const assertion of ['route_insufficient','request_already_completed','generation_not_entitled',
    'request_identity_mismatch','period','plus_qa_v2','pro_qa_v2']){
   assert.ok(sql.includes(assertion),assertion);
 }
});

test('Finalizing v2 request requires the same user and 64-char fingerprint',()=>{
 const fn=draft.slice(draft.indexOf('create or replace function public.finalize_iclub_ai_usage_service_v2('));
 assert.match(fn,/p_request_id uuid,\s*p_user_id uuid,\s*p_request_fingerprint text,\s*p_outcome text/);
 assert.ok(fn.includes('v_res.user_id<>p_user_id'));
 assert.ok(fn.includes('v_res.request_fingerprint is distinct from p_request_fingerprint'));
 assert.ok(fn.includes("request_identity_mismatch"));
});
test('Expired reservation cannot be committed by late model response',()=>{
 const fn=draft.slice(draft.indexOf('create or replace function public.finalize_iclub_ai_usage_service_v2('));
 assert.ok(fn.includes('v_res.expires_at<=now()'));
 assert.ok(fn.includes("p_request_id,'released','reservation_expired'"));
 assert.ok(fn.includes("'reason','reservation_expired'"));
 const sql=fs.readFileSync('qa/sql_drafts/iclub_ai_v21_local_pg_regression.psql','utf8');
 assert.ok(sql.includes("expires_at=now()-interval '1 minute'"));
 assert.ok(sql.includes("expired reservation was committed"));
});
test('v2 finalize preserves advisory lock, row lock and service-only permission',()=>{
 const fn=draft.slice(draft.indexOf('create or replace function public.finalize_iclub_ai_usage_service_v2('));
 assert.ok(fn.includes('pg_advisory_xact_lock(hashtextextended(p_user_id::text,0))'));
 assert.match(fn,/where request_id=p_request_id for update;/);
 assert.match(fn,/revoke all on function public\.finalize_iclub_ai_usage_service_v2\(uuid,uuid,text,text,text\)/);
 assert.match(fn,/grant execute on function public\.finalize_iclub_ai_usage_service_v2\(uuid,uuid,text,text,text\)/);
});
