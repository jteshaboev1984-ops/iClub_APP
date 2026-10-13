'use strict';
const {test}=require('node:test'),a=require('node:assert/strict'),fs=require('node:fs');
const sql=fs.readFileSync('qa/sql_drafts/iclub_ai_scoped_context_v21_UNAPPLIED.sql','utf8');
const pg=fs.readFileSync('qa/sql_drafts/iclub_ai_scoped_context_local_pg.psql','utf8');
const sh=fs.readFileSync('qa/run-ai-layer-v21-postgres-local.sh','utf8');
test('Context SQL is intrinsically scratch-only and cannot edit production',()=>{
 a.match(sql,/current_database\(\) !~ '\^iclub_ai_v21_scratch_/);
 a.match(sql,/BLOCKED: scoped context contract is scratch-only/);
 a.match(sql,/inet_server_addr\(\)/);
});
test('Server mint derives subject only from owned finalized answered Practice',()=>{
 for(const k of ["s.user_id=p_user_id","s.status='finalized'","s.finalized_at IS NOT NULL",
 "p_question_id=ANY(s.question_ids)","public.practice_session_answers_v4",
 "public.user_subjects","subj.is_active=true"])
 a.ok(sql.includes(k),k);
 a.equal(sql.includes('p_subject_key text'),false);
});
test('New AI is disabled by both emergency switch and active exam',()=>{
 a.ok(sql.includes('cfg.kill_switch=false'));
 a.ok(sql.includes('cfg.ui_enabled=true'));
 a.ok(sql.includes('private.iclub_ai_has_active_protected_assessment_v1(p_user_id)'));
});
test('One active server-owned screen, expiring opaque UUID and revisions',()=>{
 a.ok(sql.includes('context_handle uuid PRIMARY KEY DEFAULT gen_random_uuid()'));
 a.ok(sql.includes('expires_at timestamptz NOT NULL DEFAULT'));
 a.ok(sql.includes('current_handle uuid'));
 a.ok(sql.includes('context_revision bigint'));
 a.ok(sql.includes('current_handle=excluded.current_handle'));
});
test('Double-open idempotent and server rate limit prevent handle flooding',()=>{
 a.ok(sql.includes("'duplicate',true"));
 a.ok(sql.includes("'context_rate_limited'"));
 a.ok(sql.includes("created_at>now()-interval '1 minute'"));
 a.ok(sql.includes("pg_advisory_xact_lock"));
});
test('Resolving requires same owner, active screen revision and current live attempt',()=>{
 a.ok(sql.includes('WHERE context_handle=p_context_handle::uuid AND user_id=p_user_id'));
 a.ok(sql.includes('current_handle=v.context_handle'));
 a.ok(sql.includes('revision=v.context_revision'));
 a.ok(sql.includes('v.practice_question_id=ANY(s.question_ids)'));
 a.ok(sql.includes('v.revoked_at IS NULL')||sql.includes('revoked_at IS NULL'));
});
test('Revoke is confined to currently selected user screen and is irreversible',()=>{
 a.ok(sql.includes('current_handle=NULL,revision=revision+1'));
 a.ok(sql.includes('WHERE user_id=p_user_id AND current_handle=v_id'));
 a.ok(sql.includes('revoked_at=now()'));
});
test('All 3 context RPCs are service-role-only',()=>{
 for(const fn of ['mint_iclub_ai_v21_practice_context_service',
 'get_iclub_ai_v21_scoped_context_service',
 'revoke_iclub_ai_v21_scoped_context_service']){
  a.ok(sql.includes('REVOKE ALL ON FUNCTION public.'+fn),fn);
  a.ok(sql.includes('GRANT EXECUTE ON FUNCTION public.'+fn),fn);
 }
});
test('No academic reply or progress is stored in private context',()=>{
 for(const k of ['user_answer text','correct_answer','reply text','grade integer',
  'completion_percent','prompt_text','message_text'])a.equal(sql.includes(k),false,k);
});
test('Local SQL case coverage includes switching, ownership, expiring and exam',()=>{
 for(const k of ['Foreign session minted','Unanswered item minted',
 'Unfinalized exam minted','Old Biology context remained valid',
 'Deactivated subject retained AI','Expired AI context reopened',
 'Protected exam failed to close AI','Browser could mass mint'])
 a.ok(pg.includes(k),k);
 a.match(pg,/^BEGIN;/m);a.match(pg,/^ROLLBACK;/m);
 a.ok(sh.includes('context) TEST_FILE="qa/sql_drafts/iclub_ai_scoped_context_local_pg.psql"'));
});
