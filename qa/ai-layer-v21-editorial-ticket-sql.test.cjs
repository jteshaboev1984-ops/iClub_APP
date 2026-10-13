'use strict';
const {test}=require('node:test');
const assert=require('node:assert/strict');
const fs=require('node:fs');
const sql=fs.readFileSync('qa/sql_drafts/iclub_ai_editorial_ticket_publisher_v21_UNAPPLIED.sql','utf8');
const pg=fs.readFileSync('qa/sql_drafts/iclub_ai_editorial_ticket_local_pg.psql','utf8');
const learnerEdge=fs.readFileSync('qa/edge_v21/supabase_services.ts','utf8');
test('Publisher SQL cannot be installed outside dedicated scratch DB',()=>{
 assert.match(sql,/current_database\(\) !~ '\^iclub_ai_v21_scratch_/);
 assert.match(sql,/BLOCKED: editorial publisher only in local scratch/);
 assert.match(sql,/inet_server_addr/);
});
test('Publishing uses separate NOLOGIN editor role, never learner Edge service_role',()=>{
 assert.match(sql,/CREATE ROLE iclub_ai_v21_editorial_publisher NOLOGIN/);
 assert.match(sql,/GRANT EXECUTE ON FUNCTION public.publish_iclub_ai_v21_ticket/);
 assert.match(sql,/TO iclub_ai_v21_editorial_publisher/);
 assert.match(sql,/REVOKE ALL ON FUNCTION public.publish_iclub_ai_v21_ticket\(uuid,bigint\)\s+FROM public,anon,authenticated,service_role/);
 assert.match(sql,/REVOKE ALL ON FUNCTION public.revoke_iclub_ai_v21_ticket\(uuid,bigint\)\s+FROM public,anon,authenticated,service_role/);
});
test('Governance ticket and signoffs are not writable through learner APIs',()=>{
 assert.match(sql,/REVOKE ALL ON private.iclub_ai_v21_editorial_tickets FROM public,anon,authenticated,service_role/);
 assert.match(sql,/REVOKE ALL ON private.iclub_ai_v21_ticket_signoffs FROM public,anon,authenticated,service_role/);
 assert.equal(/CREATE OR REPLACE FUNCTION public.create_iclub_ai_v21_ticket/i.test(sql),false);
});
test('Exactly three distinct review domains and signed checklist needed for publication',()=>{
 for(const name of ['content','rights','technical','accessibility_passed',
 'source_version_verified','correctness_passed','negative_tests_passed',
 'exam_security_passed','locale_verified'])assert.ok(sql.includes(name),name);
 assert.ok(sql.includes('UNIQUE(ticket_id,reviewer_id)'));
 assert.ok(sql.includes("t.qa_evidence->k IS DISTINCT FROM 'true'::jsonb"));
});
test('Tickets are one-use, expires, and approval cannot silently replay',()=>{
 assert.match(sql,/t\.used_at IS NOT NULL/);
 assert.match(sql,/t\.expires_at<=now\(\)/);
 assert.match(sql,/WHERE ticket_id=p_ticket_id FOR UPDATE/);
 assert.match(sql,/UPDATE private.iclub_ai_v21_editorial_tickets SET used_at=now\(\)/);
});
test('Publication checks exact digest, source version, locale and immutable scope',()=>{
 for(const part of ["s.source_hash IS DISTINCT FROM t.source_hash",
 "encode(sha256(convert_to(","s.prepared_variants::text,'UTF8'",
 "t.surface_code","t.subject_key","t.feature_code","t.topic_key","t.locale",
 "source_id=t.source_id","source_version=t.source_version"])
  assert.ok(sql.includes(part),part);
});
test('Publisher only updates the chosen source and topic metadata in one transaction',()=>{
 assert.match(sql,/pg_advisory_xact_lock\(hashtextextended/);
 assert.match(sql,/WHERE surface_code=t.surface_code AND subject_key=t.subject_key/);
 assert.ok(sql.includes("r.publication_revision IS DISTINCT FROM p_expected_revision"));
 assert.ok(sql.includes("r.publication_state='approved'"));
 assert.ok(sql.includes("'revision_or_state_conflict'"));
});
test('Approved editorial topic is not automatically global beta, billing or provider permission',()=>{
 for(const banned of [/UPDATE private\.iclub_global_ai_runtime_config/i,
 /UPDATE private\.iclub_ai_usage_/i,
 /INSERT INTO public\.practice_session_/i,/UPDATE public\.lessons/i,
 /UPDATE public\.user_subjects/i,/UPDATE private\.iclub_ai_v21_current_screen/i])
  assert.equal(banned.test(sql),false,String(banned));
});
test('Emergency revoke requires separate safety ticket and changes revision immediately',()=>{
 assert.match(sql,/x\.review_domain='safety'/);
 assert.match(sql,/publication_state='suspended',feature_enabled=false/);
 assert.match(sql,/SET record_state='suspended',runtime_allowed=false/);
 assert.match(sql,/publication_revision=n/);
});
test('Native scratch PG covers missing approvals, replay, foreign locale and revocation',()=>{
 for(const caseName of [
 'Unsigned editorial ticket was accepted','Insufficient editorial evidence got published',
 'Wrong initial revision published','Publication ticket replayed',
 'RU publication silently enabled UZ','Already-live topic was overwritten',
 'Unsigned emergency revocation accepted','Wrong revocation revision was accepted',
 'Suspended topic still approved','Old session still reads revoked content',
 'Quarantined source republished'])assert.ok(pg.includes(caseName),caseName);
 assert.match(pg,/^BEGIN;/m);assert.match(pg,/^ROLLBACK;/m);
});

test('Real PostgreSQL regression injects failure between source and release then checks atomic rollback',()=>{
 for(const needle of ['synthetic_editorial_publication_failure',
 'Half-published source/release or used ticket after injected failure',
 'DROP TRIGGER synthetic_editorial_publish_fail',
 'Published source bypassed runtime OFF switch'])
  assert.ok(pg.includes(needle),needle);
});

test('Learner-serving Supabase Edge adapter has no editorial publishing/revoke endpoint',()=>{
 for(const rpcName of ['publish_iclub_ai_v21_ticket','revoke_iclub_ai_v21_ticket',
 'iclub_ai_v21_ticket_signoffs','iclub_ai_v21_editorial_tickets'])
  assert.equal(learnerEdge.includes(rpcName),false,rpcName);
});
