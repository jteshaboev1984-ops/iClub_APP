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
 const [owner,personal,capacity,anon]=await Promise.all([
  rpc('get_exam_prep_diagnostic_periods_safe_v1',tA),
  rpc('get_exam_prep_personal_horizon_safe_v1',tA),
  rpc('get_exam_prep_shared_study_capacity_safe_v1',tA),
  rpc('get_exam_prep_diagnostic_periods_safe_v1')
 ]);
 assert(owner.ok,'Owner read-only diagnostic period RPC unavailable HTTP '+owner.status);
 assert(personal.ok,'Existing independent actual diagnostic horizon unavailable');
 assert(capacity.ok,'Existing shared P1/P5 available-study-time projection unavailable');
 assert.equal(capacity.data.shared_across_both_papers,true);
 assert.equal(capacity.data.horizon_hours_additive_across_p1_p5,false);
 assert.equal(capacity.data.capacity_is_access_limit,false);
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
  assert.equal(typeof p.anchor_immutable,'boolean','D09 anchor provenance must be explicit');
  assert.equal(p.anchor_source,
    p.anchor_immutable ? 'first_verified_stage0_transition' :
    'current_horizon_latest_finalized_diagnostic');
  // New first transitions are frozen. Legacy students continue to display
  // explicitly derived anchors, never fake a historical immutable T0.
  assert.equal(p.calendar_promotes_stage,false);
  assert(p.diagnostic_completed_at && h.diagnostic_completed_at,'Actual diagnostic completion anchor missing');
  const c=capacity.data[component];
  assert.equal(Date.parse(p.diagnostic_completed_at),Date.parse(h.diagnostic_completed_at),
    'D09-03 actual personal horizon must use single P1/P5 T0 source');
  assert.equal(Date.parse(p.diagnostic_completed_at),Date.parse(c.diagnostic_completed_at),
    'D09-03 shared selected-time horizon must use same source, never latest retest');
  assert.equal(h.diagnostic_anchor_immutable,p.anchor_immutable);
  assert.equal(c.diagnostic_anchor_immutable,p.anchor_immutable);
  assert.equal(c.paper_minutes,component==='P1'?110:75);
  assert.equal(c.paper_minutes_are_daily_study_quota,false);
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
   if(other.data[paper]?.anchor_immutable) {
    assert(t&&h&&Date.parse(t)<=Date.parse(h),
      'B immutable T0 must come from B actual completed diagnostic');
   }else{
    assert.equal(t?Date.parse(t):null,h?Date.parse(h):null,
      'B received derived anchor not supported by own horizon '+paper);
   }
  }
 }
 console.log('PASS D09 real signed owner HTTP: immutable new Stage0 T0, matching per-paper horizon and one shared Math capacity, anonymous denial, no progress writes');
})().catch(err=>{console.error(err);process.exitCode=1});
