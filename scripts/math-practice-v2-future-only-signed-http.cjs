#!/usr/bin/env node
'use strict';
// Issue #574. REAL signed HS256 JWT -> localhost PostgREST -> disposable PG17
// with installed v5 scorer/selector, version swap and rollback.
// NEVER connects to hosted Supabase. All users/questions are CI synthetics.
const assert=require('node:assert/strict'),crypto=require('node:crypto');
const {execFileSync}=require('node:child_process');
assert(process.env.CI==='true' &&
       process.env.PRACTICE_FUTURE_ONLY_ISOLATED==='true' &&
       process.env.PGHOST==='127.0.0.1' &&
       process.env.PGDATABASE==='practice_http' &&
       process.env.PGUSER==='postgres' &&
       process.env.PGPORT==='5432',
       'REFUSED: signed test requires CI disposable PG17 practice_http');
const secret=process.env.PRACTICE_FUTURE_ONLY_JWT_SECRET;
assert(secret?.length>=48,'ephemeral signing secret missing');
const BASE='http://127.0.0.1:3000',A='11111111-1111-4111-8111-111111111191';
const B='22222222-2222-4222-8222-222222222292';
const encode=x=>Buffer.from(JSON.stringify(x)).toString('base64url');
function token(uid,ttl=1200){
 const now=Math.floor(Date.now()/1000);
 const str=[encode({alg:'HS256',typ:'JWT'}),
            encode({role:'authenticated',sub:uid,aud:'authenticated',iat:now,exp:now+ttl})].join('.');
 return str+'.'+crypto.createHmac('sha256',secret).update(str).digest('base64url');
}
async function post(route,body,authorization){
 const r=await fetch(BASE+'/rpc/'+route,{method:'POST',headers:{
  'Content-Type':'application/json','Accept':'application/json',
  ...(authorization?{Authorization:'Bearer '+authorization}:{}),
 },body:JSON.stringify(body)});
 const text=await r.text();let parsed;
 try{parsed=JSON.parse(text)}catch{parsed=null}
 return {ok:r.ok,status:r.status,body:parsed};
}
const submit=(id,q,authorization)=>post('submit_practice_session_answer_safe_v5',
 {p_session_id:id,p_question_id:q,p_user_answer:'A',p_picked_index:0,p_time_spent:2},
 authorization);
const start=(client,authorization)=>post('start_practice_session_auto_safe_v5',
 {p_pool_id:501,p_client_session_id:client},authorization);
function sql(q){
 return execFileSync('psql',['-X','-At','-v','ON_ERROR_STOP=1','-c',q],{
  encoding:'utf8',env:process.env}).trim();
}
function qs(sessionId){
 const s=sql('select array_to_json(question_ids)::text from public.practice_sessions_v4 where id='+Number(sessionId));
 return JSON.parse(s);
}
const pair='[{"old_id":2001,"new_id":3001,"old_hash":"'+
 'a'.repeat(64)+'","new_hash":"'+ 'c'.repeat(64)+'"}]';
(async()=>{
 const aa=token(A),bb=token(B);
 const anon=await submit(995201,2001,null);
 assert(!anon.ok && anon.status>=400,'anon could submit');
 const expired=await submit(995201,2001,token(A,-3600));
 assert(!expired.ok,'expired token admitted');
 const stolen=await submit(995201,2001,bb);
 assert(!stolen.ok,'other learner wrote old session');

 // Old session was issued before the swap; old q.is_active stays true even
 // though its active pool membership was removed.
 const old=await submit(995201,2001,aa);
 assert(old.ok,'old issued answer denied '+old.status+' '+JSON.stringify(old.body).slice(0,150));
 assert.equal(old.body.is_correct,true,'old keyed evaluation changed');
 assert.equal(old.body.explanation,'Explanation 1','old explanation overwritten');

 const created=await start('future-only-published-v5-main-001',aa);
 assert(created.ok,'v5 start denied after cutover '+created.status+' '+JSON.stringify(created.body).slice(0,150));
 const newSid=Number(created.body.session_id);
 const issued=qs(newSid);
 assert.equal(issued.length,10,'selector failed canonical 10-question distribution');
 assert(issued.includes(3001),'newly versioned question not selected');
 assert(!issued.includes(2001),'retired old membership selected into future session');
 const noPeer=await submit(newSid,3001,bb);
 assert(!noPeer.ok,'cross-user signed HTTP accepted post-cutover answer');
 const newer=await submit(newSid,3001,aa);
 assert(newer.ok && newer.body.is_correct===true,'new version v5 evaluator failed');
 assert.equal(newer.body.explanation,'New synthetic explanation','new version explanation not used');
 const repeat=await submit(newSid,3001,aa);
 assert(repeat.ok && repeat.body.idempotent===true,'new version answer retry mutated history');

 // Private owner/operator SQL never becomes an exposed public PostgREST RPC.
 const unauthorized=await post('math_practice_future_only_activate_v1',
  {p_release:'math_p1_practice_v2_fix_20261120',p_pairs:[]},aa);
 assert(!unauthorized.ok && unauthorized.status>=400,'private switch RPC exposed to learner');

 // Operator rollback inside the disposable PostgreSQL, not via learner HTTP.
 const rolled=sql("select private.math_practice_future_only_rollback_v1("+
  "'math_p1_practice_v2_fix_20261120',"+JSON.stringify(pair)+"::jsonb)::text");
 assert(rolled.includes('restored_old_memberships'),'rollback failed');

 // Already issued NEW question ID still scores after future selection reverts.
 const issuedNewBeforeRollback=await submit(995202,3001,aa);
 assert(issuedNewBeforeRollback.ok&&issuedNewBeforeRollback.body.is_correct===true,
  'in-progress new-version session failed after rollback');
 assert.equal(issuedNewBeforeRollback.body.explanation,'New synthetic explanation');

 const after=await start('future-only-postrollback-v5-main-002',aa);
 assert(after.ok,'v5 start denied after rollback');
 const restored=qs(Number(after.body.session_id));
 assert.equal(restored.length,10,'post-rollback selector size drift');
 assert(restored.includes(2001),'restored older version not eligible');
 assert(!restored.includes(3001),'withdrawn new membership still selected');
 const oldAgain=await submit(Number(after.body.session_id),2001,aa);
 assert(oldAgain.ok&&oldAgain.body.is_correct===true,'old version failed after rollback');
 assert.equal(oldAgain.body.explanation,'Explanation 1','post-rollback old explanation changed');

 const history=Number(sql("select count(*) from public.practice_session_answers_v4"+
  " where question_id in (2001,3001) and session_id in (995201,995202,"+
  newSid+","+Number(after.body.session_id)+")"));
 assert.equal(history,4,'four distinct issued-version answers not retained');
 const links=Number(sql('select count(*) from public.question_version_links where old_question_id=2001 and new_question_id=3001'));
 assert.equal(links,1,'provenance link missing after rollback');
 console.log('PRACTICE_FUTURE_ONLY_SIGNED_HTTP_PG17_PASS: auth/owner firewall, v5 old/new scoring, exact selector cutover, idempotency, rollback and historical answer retention');
})().catch(e=>{console.error('PRACTICE_FUTURE_ONLY_SIGNED_HTTP_FAILED:',String(e.message||e));process.exit(1)});
