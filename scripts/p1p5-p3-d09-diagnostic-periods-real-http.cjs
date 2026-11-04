#!/usr/bin/env node
'use strict';
// D09 independent diagnostic period model: REAL signed JWT -> PostgREST ->
// current isolated migrated PG17 source. No production credentials or writes.
const assert=require('node:assert/strict');
const crypto=require('node:crypto');
const URL='http://127.0.0.1:3000';
const SECRET=process.env.P1P5_E2E_JWT_SECRET;
const A='11111111-1111-4111-8111-111111111191';
const B='22222222-2222-4222-8222-222222222292';
assert(process.env.P1P5_E2E_ISOLATED==='true','D09 refuses anything but disposable CI');
assert(SECRET&&SECRET.length>=32,'Missing only-for-CI JWT secret');
const base64=o=>Buffer.from(JSON.stringify(o)).toString('base64url');
function jwt(id){
 const now=Math.floor(Date.now()/1000);
 const h=base64({alg:'HS256',typ:'JWT'});
 const p=base64({role:'authenticated',aud:'authenticated',sub:id,iat:now,exp:now+900});
 const src=h+'.'+p;
 return src+'.'+crypto.createHmac('sha256',SECRET).update(src).digest('base64url');
}
async function rpc(fn,token){
 const r=await fetch(URL+'/rpc/'+fn,{
  method:'POST',headers:{'Content-Type':'application/json','Accept':'application/json',
   ...(token?{Authorization:'Bearer '+token}:{})},body:'{}'});
 let data=null;try{data=await r.json()}catch{}
 return {ok:r.ok,status:r.status,data};
}
(async()=>{
 const tA=jwt(A),tB=jwt(B);
 const [owner,personal,anon]=await Promise.all([
  rpc('get_exam_prep_diagnostic_periods_safe_v1',tA),
  rpc('get_exam_prep_personal_horizon_safe_v1',tA),
  rpc('get_exam_prep_diagnostic_periods_safe_v1')
 ]);
 assert(owner.ok,'Owner read-only diagnostic period RPC unavailable HTTP '+owner.status);
 assert(personal.ok,'Existing independent actual diagnostic horizon unavailable');
 assert(!anon.ok,'Anonymous must not access academic timing details');
 assert.equal(owner.data.contract_version,'diagnostic_period_readonly_v1');
 assert.equal(owner.data.period_duration_days,7);
 assert.equal(owner.data.account_planner_week_unchanged,true);
 assert.equal(owner.data.no_schedule_change,true);
 assert.equal(owner.data.study_minutes_recorded,false);
 for(const component of ['P1','P5']){
  const p=owner.data[component],h=personal.data[component];
  assert.equal(p.component_code,component);
  assert.equal(p.status,'diagnostic_period_ready','Only actual completed diagnostic has a starting point');
  assert.equal(p.anchor_immutable,false,'Latest horizon session is not an immutable original T0');
  assert.equal(p.calendar_promotes_stage,false);
  assert(p.diagnostic_completed_at && h.diagnostic_completed_at,'Actual diagnostic completion anchor missing');
  assert.equal(Date.parse(p.diagnostic_completed_at),Date.parse(h.diagnostic_completed_at),
   'D09 '+component+' must read exactly the real pre-existing diagnostic horizon anchor');
  assert(Number.isInteger(p.completed_7day_periods)&&p.completed_7day_periods>=0,
   'Negative or invented completed weeks');
  assert.equal(p.current_period_no,p.completed_7day_periods+1);
  const begin=Date.parse(p.current_period_started_at),end=Date.parse(p.next_period_ends_at);
  assert.equal(end-begin,7*86400*1000,'Seven-day interval not exact');
  assert(begin<=Date.now() && end>Date.now(),'Read-only period not the current true week');
  assert.equal(begin-Date.parse(p.diagnostic_completed_at),
   p.completed_7day_periods*7*86400*1000,
   'Week start shifted from component diagnostic to account profile creation');
 }
 const repeated=await rpc('get_exam_prep_diagnostic_periods_safe_v1',tA);
 assert(repeated.ok,'Read-only repeated opening should work');
 assert.deepEqual(repeated.data,owner.data,'Read-only current period drifted without boundary');
 const other=await rpc('get_exam_prep_diagnostic_periods_safe_v1',tB);
 // User B may be unentitled. If authorized, it must remain scoped to B's real
 // diagnostic evidence; no shared hard-coded A data or synthetic week numbers.
 if(other.ok){
  assert.equal(other.data.contract_version,'diagnostic_period_readonly_v1');
  const hB=await rpc('get_exam_prep_personal_horizon_safe_v1',tB);
  assert(hB.ok,'Authorized B has no own horizon');
  for(const paper of ['P1','P5']){
   const t=other.data[paper]?.diagnostic_completed_at;
   const h=hB.data[paper]?.diagnostic_completed_at;
   assert.equal(t?Date.parse(t):null,h?Date.parse(h):null,
    'B received academic anchor not supported by own horizon '+paper);
  }
 }
 console.log('PASS D09 real signed owner HTTP: independent P1/P5 diagnostic T0 projections, exact 7-day windows, anonymous denial, no grade/budget/session writes');
})().catch(err=>{console.error(err);process.exitCode=1});
