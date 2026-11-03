#!/usr/bin/env node
'use strict';
// Real learner flow: signed JWT -> local PostgREST -> actual PG17 migration,
// plus genuine Mathematics host/date inputs in Chromium. Only 2 isolated users.
const assert=require('node:assert/strict');
const crypto=require('node:crypto');
const path=require('node:path');
const {chromium}=require('playwright');
const A='11111111-1111-4111-8111-111111111191';
const B='22222222-2222-4222-8222-222222222292';
const BASE='http://127.0.0.1:3000';
const SECRET=process.env.P1P5_E2E_JWT_SECRET;
assert(process.env.P1P5_E2E_ISOLATED==='true','No permission outside isolated CI');
assert(SECRET&&SECRET.length>=32,'Isolated signing secret missing');
const encoded=x=>Buffer.from(JSON.stringify(x)).toString('base64url');
function jwt(uid){
  const head=encoded({alg:'HS256',typ:'JWT'});
  const now=Math.floor(Date.now()/1000);
  const payload=encoded({role:'authenticated',aud:'authenticated',sub:uid,iat:now,exp:now+900});
  const plain=head+'.'+payload;
  return plain+'.'+crypto.createHmac('sha256',SECRET).update(plain).digest('base64url');
}
async function rpc(name,args,token){
  const result=await fetch(BASE+'/rpc/'+name,{
    method:'POST',headers:{
      'Content-Type':'application/json','Accept':'application/json',
      ...(token?{Authorization:'Bearer '+token}:{})
    },body:JSON.stringify(args||{})
  });
  let data=null;try{data=await result.json();}catch{}
  return {ok:result.ok,status:result.status,data};
}
function centreInput(iso){
  return new Date(new Date(iso).getTime()+5*60*60*1000).toISOString().slice(0,16);
}
(async()=>{
 const tA=jwt(A),tB=jwt(B);
 const before=await rpc('get_exam_prep_personal_horizon_safe_v1',{},tA);
 assert(before.ok,'Owned new horizon RPC failed HTTP '+before.status);
 assert.equal(before.data?.P1?.status,'date_not_confirmed','missing P1 date must be explicit');
 assert.equal(before.data?.P5?.status,'date_not_confirmed','missing P5 date must be explicit');
 assert.equal(before.data?.P1?.grade_prediction_available,undefined,'no grade forecast in component');
 assert.equal(before.data?.grade_prediction_available,false,'no overall grade prediction');
 const anon=await rpc('get_exam_prep_personal_horizon_safe_v1',{});
 assert(!anon.ok,'Anonymous horizon cannot open');
 const foreign=await rpc('get_exam_prep_personal_horizon_safe_v1',{},tB);
 assert(!foreign.ok||foreign.data?.P1?.exam_start_at==null,
   'Different user must not see own/foreign active P1 date');
 const baseline=await rpc('get_exam_prep_exam_profile_v1',{},tA);
 assert(baseline.ok,'Learner profile not accessible');

 // Dates are deliberately test data, not a claim about a Cambridge timetable.
 // They must belong to the REAL stored exam-series label used by this fake learner.
 const baseRow=Array.isArray(baseline.data)?baseline.data[0]:baseline.data;
 const chosenSeries=String(baseRow?.exam_series||'');
 const chosenYear=Number(chosenSeries.match(/20\d{2}/)?.[0]||0);
 const june=/may\/june/i.test(chosenSeries);
 const p1Month=june?'04':'10'; // June-series 9709 P1 can occur in April
 const p5Month=june?'05':'10';
 assert(chosenYear>=2026,'Missing real profile exam-series year');
 const p1Date=new Date(String(chosenYear)+'-'+p1Month+'-10T09:00:00+05:00').toISOString();
 const p5Date=new Date(String(chosenYear)+'-'+p5Month+'-13T09:00:00+05:00').toISOString();
 assert(new Date(p1Date).getTime()>Date.now()+86400000,'Selected future test series has already expired');
 const wrongSeriesDate=new Date(String(chosenYear)+'-01-10T09:00:00+05:00').toISOString();
 const wrong=await rpc('save_my_exam_prep_exam_appointment_v2',{
   p_component_code:'P1',p_scheduled_start_at:wrongSeriesDate,p_school_confirmed:true
 },tA);
 assert(!wrong.ok,'Server saved a date in a month outside selected exam series');
 const denied=await rpc('save_my_exam_prep_exam_appointment_v2',{
   p_component_code:'P1',p_scheduled_start_at:p1Date,p_school_confirmed:false
 },tA);
 assert(!denied.ok,'Unconfirmed exam date accepted');
 const expired=await rpc('save_my_exam_prep_exam_appointment_v2',{
   p_component_code:'P1',p_scheduled_start_at:new Date(Date.now()-86400000).toISOString(),p_school_confirmed:true
 },tA);
 assert(!expired.ok,'Past exam date accepted');

 const browser=await chromium.launch({headless:true});
 const page=await browser.newPage({viewport:{width:390,height:844},timezoneId:'Europe/London'});
 const errors=[];page.on('pageerror',e=>errors.push(e.message));
 try{
  await page.route(BASE+'/',route=>route.fulfill({status:200,contentType:'text/html',
    body:'<!doctype html><html lang="ru"><head><meta name="viewport" content="width=device-width,initial-scale=1"></head><body><section id="courses-subject-hub"><div id="subject-hub-exam-prep-entry" hidden aria-hidden="true"><span id="subject-hub-exam-prep-title"></span><span id="subject-hub-exam-prep-sub"></span></div><div id="exam-prep-host-root" hidden aria-hidden="true"></div></section></body></html>'}));
  await page.goto(BASE+'/');
  await page.addStyleTag({path:path.resolve('exam-prep/exam-prep-host.css')});
  await page.evaluate(token=>{
   window.__dateRpcTrace=[];
   window.sb={rpc:async(name,args={})=>{
    const response=await fetch('/rpc/'+name,{method:'POST',headers:{
     'Content-Type':'application/json',Authorization:'Bearer '+token
    },body:JSON.stringify(args)});
    let data=null;try{data=await response.json();}catch{}
    window.__dateRpcTrace.push({name,status:response.status,ok:response.ok,component:args?.p_component_code||null});
    return response.ok?{data,error:null}:{data:null,error:{code:data?.code||String(response.status),message:data?.message||'server_rejected'}};
   }};
   window.i18n={getLang:()=> 'ru'};
  },tA);
  for(const file of ['exam-prep/exam-prep-api.js','exam-prep/exam-prep-host.js','exam-prep/exam-prep-live.js']){
    await page.addScriptTag({path:path.resolve(file)});
  }
  const opened=await page.evaluate(async()=>{
    const synced=await window.iClubExamPrep.syncSubjectHub({subjectKey:'mathematics',language:'ru'});
    const open=await window.iClubExamPrep.open({subjectKey:'mathematics',language:'ru'});
    return {synced,open};
  });
  assert(opened.synced&&opened.open,'Real Maths host did not open');
  await page.locator('[data-ep-exam-date-panel]').waitFor({timeout:25000});
  for(const [component,date] of [['P1',p1Date],['P5',p5Date]]){
   const selector='[data-ep-exam-date-input="'+component+'"]';
   await page.locator(selector).fill(centreInput(date));
   await page.locator('[data-ep-exam-date-confirm="'+component+'"]').check();
   await page.locator('[data-ep-exam-date-save="'+component+'"]').click();
   await page.waitForFunction(comp=>(window.__dateRpcTrace||[]).some(x=>
      x.name==='save_my_exam_prep_exam_appointment_v2'&&x.ok&&x.component===comp) &&
      document.querySelector('[data-ep-exam-date-input="'+comp+'"]'),
     component,{timeout:25000});
   // The save ACK is earlier than the asynchronous dashboard rerender.
   // Wait for the actual learner-visible updated component summary before
   // interacting with the next paper's form.
   await page.waitForFunction(comp=>{
     const row=document.querySelector('[data-ep-exam-date-component="'+comp+'"]');
     const summary=row?.querySelector('.ep-live-exam-date-summary')?.textContent||'';
     return summary.includes('Дней до экзамена') &&
       (window.__dateRpcTrace||[]).some(x=>x.name==='save_my_exam_prep_exam_appointment_v2'&&x.ok&&x.component===comp);
   },component,{timeout:25000});
   const refresh=await rpc('get_exam_prep_personal_horizon_safe_v1',{},tA);
   assert(refresh.ok&&refresh.data?.[component]?.exam_start_at,'Date persisted for '+component);
   assert.equal(refresh.data[component].official_timetable_verified,false,
      'Empty official Cambridge calendar must not appear verified');
  }
  const trace=await page.evaluate(()=>window.__dateRpcTrace);
  assert.equal(trace.filter(x=>x.name==='save_my_exam_prep_exam_appointment_v2'&&x.ok).length,2,
   'Both P1 and P5 centre-confirmed dates must save from actual UI');
  // Real daily study schedule: 30 minutes x 5 days = 2.5 hours/week,
  // switching to seven days gives 3.5. No invented per-skill forecast.
  const invalid=await rpc('save_exam_prep_study_schedule_safe_v1',{
    p_minutes_per_day:30,p_days_per_week:0
  },tA);
  assert(!invalid.ok,'0 study days accepted');
  const excessive=await rpc('save_exam_prep_study_schedule_safe_v1',{
    p_minutes_per_day:240,p_days_per_week:7
  },tA);
  assert(!excessive.ok,'28 hours/week accepted beyond total budget');
  for(const [days,hours] of [[5,2.5],[7,3.5]]){
    const button=page.locator('[data-ep-study-save]');
    await page.locator('[data-ep-study-minutes]').fill('30');
    await page.locator('[data-ep-study-days]').selectOption(String(days));
    await button.evaluate(el=>{el.dataset.staleScheduleDom='yes';});
    await button.click();
    // Do NOT interpret the transient loading view (no button) as completed
    // dashboard render. Verify BOTH real cards and the new schedule input.
    await page.waitForFunction(()=> {
      const b=document.querySelector('[data-ep-study-save]');
      return Boolean(b && b.dataset.staleScheduleDom!=='yes' &&
        document.querySelector('[data-ep-live-open-component="P1"]') &&
        document.querySelector('[data-ep-live-open-component="P5"]'));
    },null,{timeout:25000});
    const got=await rpc('get_exam_prep_study_schedule_safe_v1',{},tA);
    assert(got.ok,'Study schedule readback failed');
    assert.equal(Number(got.data.study_minutes_per_day),30);
    assert.equal(Number(got.data.study_days_per_week),days);
    assert.equal(Number(got.data.mathematics_hours_per_week),hours,
      '30 minutes x '+days+' days must yield '+hours+' h/week');
    assert.equal(got.data.forecast_available,false,'No unapproved Cambridge personal forecast');
    const orig=Array.isArray(baseline.data)?baseline.data[0]:baseline.data;
    assert.equal(Number(got.data.total_student_hours_per_week),Number(orig.total_student_hours_available),
      'Daily schedule cannot silently change total study hours');
  }

  // Saving or exceeding an elected study budget never gates the course:
  // the learner can still start/continue Mathematics after a week is planned.
  const p1HomeAction=page.locator('[data-ep-live-open-component="P1"]');
  assert(await p1HomeAction.count()>0,'P1 learner entry disappeared after saving study schedule');
  assert(await p1HomeAction.isEnabled(),'P1 entry was incorrectly disabled by a voluntary study budget');
  const p5HomeAction=page.locator('[data-ep-live-open-component="P5"]');
  assert(await p5HomeAction.count()>0,'P5 learner entry disappeared after saving study schedule');
  assert(await p5HomeAction.isEnabled(),'P5 entry was incorrectly disabled by a voluntary study budget');
  const scheduleInfo=await page.locator('[data-ep-study-schedule]').innerText();
  assert(scheduleInfo.includes('iClub не остановит занятия'),
    'Study schedule must explicitly say that extra study does not lock access');
  // Weekly and monthly summaries are emitted only after a completed period.
  // The authenticated, owner-only RPC records a one-time delivery receipt.
  const periodicFirst=await rpc('claim_exam_prep_periodic_study_report_safe_v1',{},tA);
  assert(periodicFirst.ok,'Periodic report RPC failed via signed HTTP '+periodicFirst.status);
  assert.equal(periodicFirst.data.contract_version,'periodic_study_report_v1');
  assert.equal(periodicFirst.data.daily_reminders,false,'Daily study notifications must be disabled');
  const periodicAgain=await rpc('claim_exam_prep_periodic_study_report_safe_v1',{},tA);
  assert(periodicAgain.ok,'Repeating claimed report must be safe');
  assert.deepEqual(periodicAgain.data.reports,[],
    'A weekly or monthly report must not be sent again on a second page visit');
  const earlyReport=page.locator('[data-ep-periodic-report]');
  const prior=periodicFirst.data.reports.length;
  assert(prior<=2,'At most one completed week and one completed month may be delivered');
  for(const digest of periodicFirst.data.reports){
    assert(['week','month'].includes(digest.period_kind),'No daily reports allowed');
    assert.equal(digest.learning_minutes,null,'Cannot invent student study minutes from task/session counts');
    assert.equal(digest.can_continue_learning,true,'Time budgets must not block additional learning');
    assert.equal(digest.access_limit_changed,false,'Monthly/weekly summaries cannot change access rights');
  }
  const noLogin=await rpc('claim_exam_prep_periodic_study_report_safe_v1',{});
  assert(!noLogin.ok,'Anonymous student progress reports must not be accessible');
  assert((await earlyReport.count())<=2,'Never render more than weekly+monthly summary cards');
  assert.equal(errors.length,0,'JavaScript errors: '+errors.join(', '));
 }finally{await page.close();await browser.close();}
 const after=await rpc('get_exam_prep_personal_horizon_safe_v1',{},tA);
 assert(after.ok,'Horizon after date saves unavailable');
 for(const component of ['P1','P5']){
  assert.equal(after.data[component].status,'horizon_ready',
    'Completed real diagnostic must anchor '+component+' horizon');
  assert(after.data[component].days_diagnostic_to_exam>0,
    'No positive horizon from diagnostic to exam '+component);
  assert(after.data[component].diagnostic_completed_at,
    'Diagnostic completion anchor absent '+component);
  assert.equal(after.data[component].forecast_status,'not_calculated',
    'Workload recommendation must not be fabricated');
  assert.equal(after.data[component].estimated_study_hours,null,'Cambridge study-hour estimate not approved');
 }
 assert.notEqual(after.data.P1.exam_start_at,after.data.P5.exam_start_at,
   'P1/P5 exam dates were incorrectly coupled');
 const finalProfile=await rpc('get_exam_prep_exam_profile_v1',{},tA);
 assert(finalProfile.ok,'Existing original profile lost');
 const b=Array.isArray(baseline.data)?baseline.data[0]:baseline.data;
 const n=Array.isArray(finalProfile.data)?finalProfile.data[0]:finalProfile.data;
 assert.equal(Number(n.mathematics_hours_budget),3.5,
   'Last explicit 30-minute x 7-day choice must be 3.5 Mathematics hours/week');
 assert.equal(String(n.total_student_hours_available),String(b.total_student_hours_available),
   'The total study hours must not change on saving the Mathematics daily schedule');
 assert.equal(String(n.target_grade),String(b.target_grade),'Saving a date must not change target');
 console.log('PASS real Math P1/P5 centre-confirmed exam dates, diagnostic-to-exam calendar, independent components, no fake grade/workload and preserved budget');
})().catch(e=>{console.error(e);process.exitCode=1});
