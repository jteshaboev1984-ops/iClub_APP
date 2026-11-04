#!/usr/bin/env node
'use strict';
// D09-04 native UX-only browser contract; no HTTP/data/secrets or real
// student changes. Real owner-signed RPC/plan evidence is checked separately
// by p1p5-isolated-http-auth-e2e.cjs in disposable PG17.
const assert=require('node:assert/strict');
const path=require('node:path');
const {chromium}=require('playwright');
const PLAN='11111111-1111-4111-8111-111111111111';
const locales={
 ru:['Неделя учебного плана 5','Неделя с диагностики 3'],
 uz:['O‘quv rejasi haftasi 5','Diagnostikadan keyingi hafta 3'],
 en:['Study plan week 5','Week since diagnostic 3']
};
const p1={status:'diagnostic_period_ready',current_period_no:1,
 next_period_ends_at:'2026-11-12T00:00:00+05:00',anchor_immutable:true};
const p5={status:'diagnostic_period_ready',current_period_no:3,
 next_period_ends_at:'2026-11-12T00:00:00+05:00',anchor_immutable:true};
async function check(browser,language,width){
 const page=await browser.newPage({viewport:{width,height:840}});
 const errors=[];page.on('pageerror',e=>errors.push(e.message));
 await page.route(/^https?:\/\//,route=>route.abort());
 try{
  await page.setContent('<!doctype html><html lang="'+language+'"><head><meta name="viewport" content="width=device-width,initial-scale=1"></head><body><div id="exam-prep-host-root" aria-hidden="false"></div></body></html>');
  await page.addStyleTag({path:path.resolve('exam-prep/exam-prep-host.css')});
  await page.evaluate(([lang,planId,P1,P5])=>{
   window.iClubExamPrepWeeklyFlowEnabled=true;
   window.i18n={getLang:()=>lang};
   const state=window.__d09={writes:0,budgets:0,planReads:0,errors:[]};
   const ok=data=>({ok:true,data});
   window.iClubExamPrepHostInternal={
     lastCapabilities:{coreAccess:true,killSwitch:false,rolloutState:'controlled_beta'},
     api:{
       examProfile:async()=>ok({exam_series:'May/June 2027',target_grade:'A',
         total_student_hours_available:12,mathematics_hours_budget:5}),
       diagnosticProgress:async()=>ok({stage0_complete:true,
         screening:{required_items:3,answered_items:3,required_areas:1,answered_areas:1}}),
       getState:async component=>ok({components:[{component_code:component,operational_stage:2,coverage_pct:0}]}),
       weeklyPlan:async component=>{
         state.planReads++;
         return ok({plan_id:planId,active_week_no:5,component_code:component,
           items:[{priority_order:1,item_type:'learning',status:'pending'}]});
       },
       generateWeeklyPlan:async()=>{state.writes++;return {ok:false}}
     }
   };
   window.iClubExamPrep={open:async()=>true,isOpen:()=>true,back:()=>true,
     close:()=>true,syncSubjectHub:async()=>true,refreshCapabilities:async()=>true};
   window.sb={rpc:async(name,args)=>{
     const success=data=>({data,error:null});
     const fail=()=>({data:null,error:{message:'unexpected read/mutation: '+name}});
     if(name==='get_exam_prep_active_plan_session_safe_v1')return success({status:'none',component_code:args?.p_component_code});
     if(name==='ensure_exam_prep_balanced_weekly_plan_safe_v1')return success({
       contract_version:'stable_weekly_plan_v1',status:'existing',
       component_code:args.p_component_code,plan_id:planId,created:false});
     if(name==='ensure_my_exam_prep_weekly_budget_safe_v1'){
       state.budgets++;
       return success({
         contract_version:'exam_prep_shared_weekly_available_time_v1',
         plan_id:planId,component_code:args.p_component_code,active_week_no:5,
         planner_week_kind:'legacy_shared_plan_id',legacy_plan_id_preserved:true,
         diagnostic_period_never_rekeys_existing_plan:true,
         component_diagnostic_periods:{P1,P5},
         budget_status:'captured_for_week',available_math_minutes:300,
         p1_reserved_minutes:190,p5_reserved_minutes:110,
         component_available_minutes:args.p_component_code==='P5'?110:190,
         priority_slots:[{priority_order:1,item_type:'learning',status:'pending',
           available_study_minutes:args.p_component_code==='P5'?110:190}],
         priority_count:1,
         priority_minutes_are_available_time_not_task_duration:true,
         learning_access_capped:false,academic_results_mutated:false,
         current_week_snapshot_not_rewritten:true,profile_changed_after_capture:false,
         keep_choice_recorded_before_snapshot:false
       });
     }
     state.writes++;
     state.errors.push(name);
     return fail();
   }};
  },[language,PLAN,p1,p5]);
  for(const script of ['exam-prep/exam-prep-weekly-flow-adapter.js',
      'exam-prep/exam-prep-live.js'])
    await page.addScriptTag({path:path.resolve(script)});
  await page.evaluate(lang=>window.iClubExamPrep.open({language:lang}),language);
  await page.waitForSelector('[data-ep-live-plan="P5"]');
  await page.locator('[data-ep-live-plan="P5"]').click();
  await page.waitForSelector('[data-ep-plan-period-label]');
  const label=await page.locator('[data-ep-plan-period-label]').innerText();
  for(const part of locales[language])
    assert(label.includes(part),language+'/'+width+' missing independent clock '+part+' in '+label);
  assert((await page.locator('[data-ep-week-budget]').innerText()).includes('P1: 190'),
    'Shared P1 budget missing');
  assert((await page.locator('[data-ep-week-budget]').innerText()).includes('P5: 110'),
    'Shared P5 budget missing');
  assert.equal(await page.locator('[data-ep-live-plan-item="1"]').count(),1,
    'Original weekly priority disappeared from verified academic calendar');
  const state=await page.evaluate(()=>window.__d09);
  assert.equal(state.writes,0,'Week-label display triggered an academic or schedule write');
  assert.equal(state.budgets,1,'Expected one optional shared budget read');
  assert.equal(errors.length,0,'Native browser errors: '+errors.join(';'));
  assert.equal(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth+2),
    true,language+'/'+width+' horizontal overflow');
  console.log('PASS D09-04 native '+language+' '+width+'px: shared plan week 5 / P5 diagnostic week 3 / P1 diagnostic week 1; original goal and minutes preserved');
 }finally{await page.close()}
}
(async()=>{
 const browser=await chromium.launch({headless:true});
 try{for(const language of ['ru','uz','en'])for(const width of [390,1280])
   await check(browser,language,width);
 }finally{await browser.close()}
})().catch(err=>{console.error(err);process.exitCode=1});
