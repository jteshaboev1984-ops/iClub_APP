#!/usr/bin/env node
'use strict';
// P1/P2 calendar & 81-skill SOURCE acceptance. Only temporary GitHub PG17/JWT/PostgREST.
const assert=require('node:assert/strict');
const crypto=require('node:crypto');
const HOST='http://127.0.0.1:3000',SECRET=process.env.P1P5_E2E_JWT_SECRET;
assert(process.env.CI==='true'&&process.env.P1P5_E2E_ISOLATED==='true'&&
  process.env.PGHOST==='127.0.0.1'&&process.env.PGDATABASE==='postgres',
  'S2 REFUSED: requires disposable local signed stack');
assert(SECRET?.length>=32,'S2 missing disposable signing key');
const A='11111111-1111-4111-8111-111111111191';
const e=x=>Buffer.from(JSON.stringify(x)).toString('base64url');
const p=e({alg:'HS256',typ:'JWT'})+'.'+e({role:'authenticated',aud:'authenticated',sub:A,
 iat:Math.floor(Date.now()/1000),exp:Math.floor(Date.now()/1000)+1800});
const token=p+'.'+crypto.createHmac('sha256',SECRET).update(p).digest('base64url');
async function rpc(name,args={}){
 const res=await fetch(HOST+'/rpc/'+name,{method:'POST',
 headers:{'Content-Type':'application/json','Accept':'application/json',
 Authorization:'Bearer '+token},body:JSON.stringify(args)});
 let data=null;try{data=await res.json()}catch{}
 return {ok:res.ok,status:res.status,data};
}
function accept(x,label){assert(x.ok,label+' HTTP '+x.status+' '+JSON.stringify(x.data).slice(0,600));return x.data}
(async()=>{
 // The preceding D03 P1/P5 browser job seeded the same fake owner and completed
 // at least one genuine diagnostic. This test never uses a real owner.
 const before=accept(await rpc('get_exam_prep_study_schedule_safe_v1'),'schedule owner');
 assert(before,'missing owner schedule');
 const save=accept(await rpc('save_exam_prep_study_schedule_safe_v1',
 {p_minutes_per_day:30,p_days_per_week:5}),'30min x 5day schedule');
 assert(save,'schedule did not persist');
 const after=accept(await rpc('get_exam_prep_study_schedule_safe_v1'),'owner schedule reload');
 assert.equal(Number(after.study_minutes_per_day),30,'daily minutes not persisted');
 assert.equal(Number(after.study_days_per_week),5,'study-day count not persisted');
 // Never round 30 min x 5 days into a seven-day 3.5-hour budget.
 assert.notEqual(Number(after.study_minutes_per_day)*7/60,30*5/60);
 const date1='2027-05-15T08:00:00+05:00',date5='2027-06-04T08:00:00+05:00';
 const denied=await rpc('save_my_exam_prep_exam_appointment_v2',
 {p_component_code:'P1',p_scheduled_start_at:date1,p_school_confirmed:false});
 assert(!denied.ok,'unconfirmed centre date unexpectedly accepted');
 accept(await rpc('save_my_exam_prep_exam_appointment_v2',
 {p_component_code:'P1',p_scheduled_start_at:date1,p_school_confirmed:true}),
 'owner P1 school-checked date');
 accept(await rpc('save_my_exam_prep_exam_appointment_v2',
 {p_component_code:'P5',p_scheduled_start_at:date5,p_school_confirmed:true}),
 'owner P5 school-checked date');
 const horizon=accept(await rpc('get_exam_prep_personal_horizon_safe_v1'),'separate P1/P5 horizon');
 assert(horizon.P1&&horizon.P5,'both components must be present');
 assert.notEqual(horizon.P1.exam_start_at,horizon.P5.exam_start_at,
  'P1 and P5 exam dates unexpectedly merged');
 const norms=accept(await rpc('get_exam_prep_workload_norm_status_safe_v1'),'81 skill source registry');
 assert.equal(Number(norms.norm_rows),81,'no full 45+36 syllabus mapping');
 assert.equal(Number(norms.approved_norms),0,'unreviewed minutes were falsely approved');
 const actions=accept(await rpc('get_exam_prep_action_time_calibration_status_safe_v1'),'time calibration source');
 assert(actions.recommended_weekly_hours==null,
  'unapproved source unexpectedly displayed a personal Cambridge weekly hour target');
 console.log('S2 signed real JWT→PostgREST→PG17: PASS; owner schedule 30min x 5, two centre-checked P1/P5 dates, 81 UNREVIEWED norms, 0 invented recommended hours');
})().catch(e=>{console.error('S2 acceptance FAILED:',e.message);process.exitCode=1});
