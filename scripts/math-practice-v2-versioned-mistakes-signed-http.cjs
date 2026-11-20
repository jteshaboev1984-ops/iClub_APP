#!/usr/bin/env node
'use strict';
// #574 · Real signed PostgREST -> disposable PG17; original SQL v5 recent
// mistakes and drill scorer. Historical answers remain immutable. NO prod.
const assert=require('node:assert/strict');
const crypto=require('node:crypto');
const {execFileSync}=require('node:child_process');
assert(process.env.CI==='true'&&process.env.PRACTICE_FUTURE_ONLY_ISOLATED==='true'&&
  process.env.PGHOST==='127.0.0.1'&&process.env.PGDATABASE==='practice_http'&&
  process.env.PGUSER==='postgres','isolated PG17 only');
const secret=process.env.PRACTICE_FUTURE_ONLY_JWT_SECRET;
assert(secret?.length>=48,'ephemeral JWT key not provided');
const phase=process.argv[2];
assert(['published','rollback'].includes(phase));
const A='11111111-1111-4111-8111-111111111191';
const B='22222222-2222-4222-8222-222222222292';
const b64=x=>Buffer.from(JSON.stringify(x)).toString('base64url');
function token(user,seconds=900){
 const now=Math.floor(Date.now()/1000);
 const unsigned=b64({alg:'HS256',typ:'JWT'})+'.'+
   b64({role:'authenticated',sub:user,aud:'authenticated',iat:now,exp:now+seconds});
 return unsigned+'.'+crypto.createHmac('sha256',secret).update(unsigned).digest('base64url');
}
async function call(name,data,jwt){
 const result=await fetch('http://127.0.0.1:3000/rpc/'+name,{
  method:'POST',headers:{'Content-Type':'application/json',
    ...(jwt?{'Authorization':'Bearer '+jwt}:{})},
  body:JSON.stringify(data)
 });
 const body=await result.json().catch(()=>null);
 return {ok:result.ok,status:result.status,body};
}
function select(sql){
 return execFileSync('psql',['-X','-At','-v','ON_ERROR_STOP=1','-c',sql],{
  encoding:'utf8',env:process.env}).trim();
}
const request={p_subject_key:'mathematics',p_topic:null,p_subtopic:null,p_limit:10};
(async()=>{
 const own=token(A),peer=token(B);
 const anon=await call('get_recent_practice_mistakes_safe_v5',request,null);
 assert(!anon.ok,'anonymous recent mistakes exposed');
 const expired=await call('get_recent_practice_mistakes_safe_v5',request,token(A,-600));
 assert(!expired.ok,'expired bearer accepted');
 const mine=await call('get_recent_practice_mistakes_safe_v5',request,own);
 assert(mine.ok&&Array.isArray(mine.body),'owner recent mistakes failed '+mine.status);
 const expected=phase==='published'?3001:2001,stale=phase==='published'?2001:3001;
 assert.deepEqual(mine.body.map(x=>+x.question_id),[expected],
   'current mistakes ignored future pool membership or returned stale version');
 const other=await call('get_recent_practice_mistakes_safe_v5',request,peer);
 assert(other.ok&&Array.isArray(other.body),'other owner read failed');
 assert.deepEqual(other.body.map(x=>+x.question_id),
   phase==='published'?[]:[2001],'cross-user mistake visibility or owned old version broken');
 const blocked=await call('start_practice_mistakes_drill_safe_v5',{
    p_subject_key:'mathematics',p_question_ids:[stale],
    p_client_session_id:'future-v5-stale-'+phase+'-001'
 },own);
 assert(!blocked.ok,'old inactive-pool mistake was re-issued for new practice');
 const allowed=await call('start_practice_mistakes_drill_safe_v5',{
    p_subject_key:'mathematics',p_question_ids:[expected],
    p_client_session_id:'future-v5-current-'+phase+'-001'
 },own);
 assert(allowed.ok&&allowed.body?.question_count===1,
   'learner could not practice owned current mistake '+allowed.status);
 const peerDenied=await call('start_practice_mistakes_drill_safe_v5',{
    p_subject_key:'mathematics',p_question_ids:[3001],
    p_client_session_id:'future-v5-peer-'+phase+'-001'
 },peer);
 assert(!peerDenied.ok,
  'other learner started a question without their own corresponding wrong answer');
 // Historical attempts, all three original records and the version ancestry
 // must still exist after either membership state.
 assert.equal(+select('select count(*) from public.practice_answers where attempt_id between 880001 and 880003'),3);
 assert.equal(+select('select count(*) from public.question_version_links where old_question_id=2001 and new_question_id=3001'),1);
 assert.equal(+select('select count(*) from public.questions where id in (2001,3001) and is_active=true'),2);
 console.log('PRACTICE_MISTAKES_VERSIONED_SIGNED_PG17_PASS '+phase+
  ': owner-scoped current mistakes, retired-version exclusion, independent history preserved, no raw private output');
})().catch(err=>{
 console.error('PRACTICE_MISTAKES_VERSIONED_SIGNED_PG17_FAILED '+phase+': '+String(err.message||err));
 process.exit(1);
});
