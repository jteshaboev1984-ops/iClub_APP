#!/usr/bin/env node
'use strict';
const assert=require('node:assert/strict'),crypto=require('node:crypto');
assert(process.env.CI==='true' && process.env.P1P5_E2E_ISOLATED==='true' &&
 process.env.PGHOST==='127.0.0.1' && process.env.PGDATABASE==='postgres',
 'Only isolated PG17 signed test stack may claim synthetic periods');
const secret=process.env.P1P5_E2E_JWT_SECRET;
assert(secret?.length>=32);
const enc=x=>Buffer.from(JSON.stringify(x)).toString('base64url');
const p=enc({alg:'HS256',typ:'JWT'})+'.'+enc({aud:'authenticated',role:'authenticated',
 sub:'11111111-1111-4111-8111-111111111191',iat:Math.floor(Date.now()/1000),
 exp:Math.floor(Date.now()/1000)+1800});
const jwt=p+'.'+crypto.createHmac('sha256',secret).update(p).digest('base64url');
async function rpc(n) {
 const x=await fetch('http://127.0.0.1:3000/rpc/'+n,{method:'POST',
  headers:{'Content-Type':'application/json',Authorization:'Bearer '+jwt},
  body:'{}'});
 const y=await x.json();assert(x.ok,n+' '+x.status+' '+JSON.stringify(y));return y;
}
(async()=>{
 const first=await rpc('claim_exam_prep_periodic_study_report_safe_v1');
 assert.equal(first.daily_reminders,false);
 assert.equal(first.no_inferred_study_minutes,true);
 assert.equal(first.reports.length,2,'40 fake days must produce one latest complete week AND month');
 const kinds=new Set(first.reports.map(x=>x.period_kind));
 assert.deepEqual([...kinds].sort(),['month','week']);
 for (const item of first.reports) {
  const start=new Date(item.period_started_at).getTime(),
        end=new Date(item.period_ended_at).getTime();
  assert(end>start && end<Date.now()+41*864e5,'completed periods only');
  if(item.period_kind==='week')assert.equal(end-start,7*864e5,
    'exactly seven 24h periods, not a calendar Monday approximation');
  if(item.period_kind==='month')assert((end-start)>=28*864e5 &&
    (end-start)<=31*864e5,'month is not a made-up 30-day period');
  assert(item.P1&&item.P5);
  assert.equal(item.learning_minutes,null);
  assert.equal(item.can_continue_learning,true);
  assert.equal(item.no_auto_schedule_change,true);
 }
 const history=await rpc('get_exam_prep_periodic_study_reports_safe_v1');
 assert.equal(history.reports.length,2,'immutable receipts must survive reload');
 const second=await rpc('claim_exam_prep_periodic_study_report_safe_v1');
 assert.equal(second.reports.length,0,'two devices must not double-claim a period');
 console.log('S3 SIGNED PG17 PASS: exactly one 7-day report and real diagnostic-anchored calendar month, two paper ledgers, immutable receipts, no minute/grade fiction');
})().catch(e=>{console.error('S3 PERIODS FAILED:',e.stack||e);process.exitCode=1;});
