#!/usr/bin/env node
'use strict';
// Native three-locale weekly summary presentation; all API responses here are
// synthetic visual fixtures. SQL and actual signed learner HTTP are tested
// separately in the disposable PG17 workflow. No network or production user.
const assert=require('node:assert/strict');
const path=require('node:path');
const {chromium}=require('playwright');
const labels={
 ru:['Что проверить дальше','Исправить выявленную ошибку','Проверить тему, по которой пока нет результатов','По текущим результатам'],
 uz:['Keyin nimalarni tekshirish kerak','Aniqlangan xatoni tuzatish','Hali tekshirilmagan mavzu','Hisobot tuzilgan paytdagi'],
 en:['What to check next','Correct an identified error','Check a topic with no recorded results yet','Based on verified results']
};
async function scenario(browser,language,width){
 const page=await browser.newPage({viewport:{width,height:860}});
 const errors=[];page.on('pageerror',e=>errors.push(e.message));
 await page.route(/^https?:\/\//,route=>route.abort());
 try{
  await page.setContent('<!doctype html><html lang="'+language+'"><head><meta name="viewport" content="width=device-width,initial-scale=1"></head><body><div id="exam-prep-host-root" aria-hidden="false"></div></body></html>');
  await page.addStyleTag({path:path.resolve('exam-prep/exam-prep-host.css')});
  await page.evaluate(lang=>{
   window.i18n={getLang:()=>lang};
   const s=window.__focusTest={claims:0,scheduleWrites:0,planWrites:0};
   const ok=data=>({ok:true,data});
   const week={
     period_kind:'week',
     period_started_at:'2026-10-25T09:00:00Z',
     period_ended_at:'2026-11-01T09:00:00Z',
     can_continue_learning:true,access_limit_changed:false,
     P1:{finalized_learning_sessions:2,finalized_timed_sessions:0,verified_week_goals:null},
     P5:{finalized_learning_sessions:1,finalized_timed_sessions:0,verified_week_goals:null},
     evidence_next_steps:{
       contract_version:'exam_prep_weekly_evidence_focus_v1',
       read_at:'report_claim_time_not_historical_week_end',
       not_additional_weekly_plan:true,
       student_selected_math_hours_unchanged:true,
       recommended_weekly_hours:null,
       recommendation_accept_enabled:false,
       items:[
        {component_code:'P1',syllabus_section:'1.2',next_action:'correction',evidence_status:'observed_unconfirmed'},
        {component_code:'P5',syllabus_section:'6.1',next_action:'targeted_check',evidence_status:'unobserved'}
       ]
     }
   };
   window.iClubExamPrepHostInternal={
    lastCapabilities:{coreAccess:true,killSwitch:false,rolloutState:'controlled_beta'},
    api:{
      examProfile:async()=>ok({exam_series:'May/June 2027',target_grade:'A',total_student_hours_available:12,mathematics_hours_budget:5}),
      diagnosticProgress:async()=>ok({stage0_complete:true,screening:{required_items:3,answered_items:3,required_areas:1,answered_areas:1}}),
      getState:async component=>ok({components:[{component_code:component,operational_stage:2,coverage_pct:0}]}),
      personalHorizon:async()=>ok({P1:{status:'horizon_ready'},P5:{status:'horizon_ready'}}),
      studySchedule:async()=>ok({study_minutes_per_day:30,study_days_per_week:5}),
      claimPeriodicStudyReports:async()=>{s.claims++;return ok({contract_version:'periodic_study_report_v1',reports:[week],daily_reminders:false})},
      saveStudySchedule:async()=>{s.scheduleWrites++;throw Error('Report changed learner schedule')},
      generateWeeklyPlan:async()=>{s.planWrites++;throw Error('Report generated plan')}
    }
   };
   window.iClubExamPrep={open:async()=>true,isOpen:()=>true,back:()=>true,
     close:()=>true,syncSubjectHub:async()=>true,refreshCapabilities:async()=>true};
  },language);
  await page.addScriptTag({path:path.resolve('exam-prep/exam-prep-live.js')});
  await page.evaluate(lang=>window.iClubExamPrep.open({language:lang}),language);
  await page.waitForSelector('[data-ep-weekly-focus]',{state:'attached'});
  const report=page.locator('[data-ep-periodic-report="0"]');
  const visible=await report.innerText();
  for(const expected of labels[language])
    assert(visible.includes(expected),language+'/'+width+' missing accurate action '+expected+' in '+visible);
  assert.equal(await report.locator('[data-ep-weekly-focus] > div.ep-live-meta').count(),2,
    'More or fewer than two actual evidence-led focus cards');
  assert(!/T0|legacy|epoch|academic_contract_missing|source_mapped|internal/.test(visible),
    'Technical internals exposed on learner-facing weekly report');
  assert(!/90 hours|50 hours|180 hours/.test(visible),
    'Unverified personal study-hour norms exposed');
  const state=await page.evaluate(()=>window.__focusTest);
  assert.equal(state.claims,1,'No repeated weekly notifications');
  assert.equal(state.scheduleWrites,0,'An evidence focus changed chosen hours');
  assert.equal(state.planWrites,0,'Evidence focus created another planner');
  assert.equal(errors.length,0,'Browser errors '+errors.join(';'));
  assert.equal(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth+2),
    true,'Report overflow '+language+'/'+width);
  console.log('D09-05 UX PASS '+language+' '+width+'px: source-backed two next actions, unknown not weak, no implicit hours or writes');
 }finally{await page.close()}
}
(async()=>{
 const browser=await chromium.launch({headless:true});
 try{for(const language of ['ru','uz','en'])for(const width of [390,1280])
   await scenario(browser,language,width);
 }finally{await browser.close()}
})().catch(e=>{console.error('D09-05 UX FAILED',e);process.exitCode=1});
