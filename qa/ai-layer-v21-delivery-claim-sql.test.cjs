// node --test qa/ai-layer-v21-delivery-claim-sql.test.cjs
// Static contract review only. Real PG behavior is checked by CI scratch suite.
'use strict';
const {test}=require('node:test'),assert=require('node:assert/strict'),fs=require('node:fs');
const sql=fs.readFileSync('qa/sql_drafts/iclub_ai_delivery_claim_v21_UNAPPLIED.sql','utf8');
const fixture=fs.readFileSync('qa/sql_drafts/iclub_ai_delivery_claim_local_pg.psql','utf8');
const race=fs.readFileSync('qa/run-ai-layer-v21-claim-race.sh','utf8');
const runner=fs.readFileSync('qa/run-ai-layer-v21-postgres-local.sh','utf8');
test('Draft has a scratch DB and local Docker safety guard',()=>{
 assert.match(sql,/current_database\(\) !~ '\^iclub_ai_v21_scratch_/);
 assert.match(sql,/inet_server_addr\(\)/);
 assert.match(sql,/iclub_ai_v21_local_scratch/);
 assert.match(sql,/BLOCKED: AI delivery claim is scratch-only/);
});
test('A durable request ID is unique across server workers',()=>{
 assert.match(sql,/request_id uuid PRIMARY KEY/);
 assert.match(sql,/ON CONFLICT\(request_id\) DO NOTHING/);
 assert.match(sql,/FOR UPDATE/);
});
test('Only identity hashes and status are stored, never chat or prompt',()=>{
 for(const token of ['session_fingerprint text','request_fingerprint text',
 'route_class text','user_id uuid','status text'])assert.ok(sql.includes(token),token);
 for(const token of ['reply text','prompt text','user_answer text','message text',
 'content_body text','raw_context text'])assert.equal(sql.includes(token),false,token);
});
test('Claim cannot precede verified atomic tariff reservation',()=>{
 const segment=sql.slice(sql.indexOf('CREATE OR REPLACE FUNCTION public.claim_iclub_ai_delivery_service_v21('),
   sql.indexOf('-- Mark complete ONLY AFTER'));
 for(const marker of ['private.iclub_ai_usage_reservations','r.status=\'reserved\'',
   'r.expires_at>now()','r.request_fingerprint=p_request_fingerprint',
   'r.route_class=p_route_class'])assert.ok(segment.includes(marker),marker);
});
test('Same request cannot launch another model across retries or restarts',()=>{
 assert.ok(sql.includes("'request_in_progress'"));
 assert.ok(sql.includes("'already_processed_no_receipt'"));
 assert.ok(sql.includes("'request_already_released'"));
 assert.match(sql,/Never reclaim an expired request ID/);
});
test('Completion requires quota finalized in same request identity',()=>{
 assert.match(sql,/v_quota_status IS DISTINCT FROM p_outcome/);
 assert.match(sql,/request_identity_mismatch/);
 assert.match(sql,/quota_not_finalized/);
 assert.match(sql,/claim_expires_at<=now\(\)/);
});
test('No public/authenticated ability to run delivery RPCs or read tombstones',()=>{
 assert.match(sql,/REVOKE ALL ON TABLE private.iclub_ai_request_tombstones_v21 FROM public,anon,authenticated/);
 assert.match(sql,/GRANT SELECT ON TABLE private.iclub_ai_request_tombstones_v21 TO service_role/);
 assert.match(sql,/REVOKE ALL ON FUNCTION public.claim_iclub_ai_delivery_service_v21\(uuid,uuid,text,text,text\)\s+FROM public,anon,authenticated/);
 assert.match(sql,/REVOKE ALL ON FUNCTION public.finish_iclub_ai_delivery_service_v21\(uuid,uuid,text,text,text,text\)\s+FROM public,anon,authenticated/);
});
test('No unapproved cleanup can remove completed request tombstones',()=>{
 assert.equal(/delete\s+from\s+private\.iclub_ai_request_tombstones_v21/i.test(sql),false);
 assert.equal(/truncate\s+table\s+private\.iclub_ai_request_tombstones_v21/i.test(sql),false);
});
test('Full PostgreSQL suite checks foreign user, retry, expiry, and quota',()=>{
 for(const marker of ['quota_reservation_unverified','request_in_progress',
 'request_identity_mismatch','quota_not_finalized','outcome_conflict',
 'claim_expired','no reply','Transcript column leaked'])assert.ok(fixture.toLowerCase().includes(marker.toLowerCase()),marker);
 assert.match(fixture,/^BEGIN;/m);
 assert.match(fixture,/^ROLLBACK;/m);
});
test('Race test uses two real separate SQL sessions',()=>{
 assert.match(race,/pid1=\$!/);
 assert.match(race,/pid2=\$!/);
 assert.match(race,/pg_sleep\(0\.6\)/);
 assert.ok(race.includes('wait "$pid1"'));
 assert.ok(race.includes('wait "$pid2"'));
 assert.ok(race.includes('success_count'));
 assert.ok(race.includes('failure_count'));
});
test('All test DBs are restricted to new named local scratch databases',()=>{
 for(const script of [race,runner]){
  assert.match(script,/iclub_ai_v21_scratch_/);
  assert.ok(script.includes('127.0.0.1'));
  assert.ok(script.includes('SUPABASE_SERVICE_ROLE_KEY'));
 }
});
