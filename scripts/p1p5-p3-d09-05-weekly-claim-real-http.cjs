#!/usr/bin/env node
'use strict';
// Actual owner-signed JWT -> local PostgREST -> disposable PG17. A fresh
// diagnostic MUST NOT produce a 7-day digest or repeat notice on dashboard.
// Focus itself is verified against real skill evidence in adjacent PG17 SQL.
const assert=require('node:assert/strict');
const crypto=require('node:crypto');
const URL='http://127.0.0.1:3000';
const SECRET=process.env.P1P5_E2E_JWT_SECRET;
const UID='11111111-1111-4111-8111-111111111191';
assert(process.env.P1P5_E2E_ISOLATED==='true','No live projects');
assert(SECRET&&SECRET.length>=32,'Disposable signing secret missing');
const b64=obj=>Buffer.from(JSON.stringify(obj)).toString('base64url');
function token(uid){
 const now=Math.floor(Date.now()/1000);
 const val=b64({alg:'HS256',typ:'JWT'})+'.'+b64({
  role:'authenticated',aud:'authenticated',sub:uid,iat:now,exp:now+900});
 return val+'.'+crypto.createHmac('sha256',SECRET).update(val).digest('base64url');
}
async function rpc(name,t){
 const r=await fetch(URL+'/rpc/'+name,{
  method:'POST',headers:{'Content-Type':'application/json','Accept':'application/json',
    ...(t?{Authorization:'Bearer '+t}:{})},body:'{}'});
 let data=null;try{data=await r.json()}catch{}
 return {ok:r.ok,status:r.status,data};
}
(async()=>{
 const t=token(UID);
 const [remaining,anon,first,second]=await Promise.all([
  rpc('get_exam_prep_remaining_work_by_skill_safe_v1',t),
  rpc('claim_exam_prep_periodic_study_report_safe_v1'),
  rpc('claim_exam_prep_periodic_study_report_safe_v1',t),
  rpc('claim_exam_prep_periodic_study_report_safe_v1',t)
 ]);
 assert(remaining.ok&&remaining.data?.contract_version==='exam_prep_result_led_remaining_work_v1',
  'Owner cannot access actual objective 81-skill source');
 assert.equal(remaining.data.P1.skills_total,45);
 assert.equal(remaining.data.P5.skills_total,36);
 assert.equal(remaining.data.recommended_weekly_hours,null);
 assert.equal(remaining.data.recommendation_accept_enabled,false);
 assert(!anon.ok,'Anonymous weekly receipts exposed');
 for(const [i,res] of [[1,first],[2,second]]){
  assert(res.ok&&res.data?.contract_version==='periodic_study_report_v1',
   'Owner periodic API failed signed PostgREST #'+i+' HTTP '+res.status);
  assert.deepEqual(res.data.reports,[],
   'Fresh diagnostic was misrepresented as an already completed week');
  assert.equal(res.data.daily_reminders,false);
 }
 console.log('D09-05 HTTP PASS: real signed owner objective evidence, anonymous weekly deny, no first-week report, no repeated delivery or made-up hours');
})().catch(e=>{console.error('D09-05 HTTP FAILED',e);process.exitCode=1});
