#!/usr/bin/env node
'use strict';
// D3-HOURS actual Chromium DOM, isolated in-memory API; NO production network.
// Signed JWT/PostgREST/PG17 server coverage is in a separate script.
const assert=require('node:assert/strict');
const path=require('node:path');
const {chromium}=require('playwright');
const base=path.resolve(__dirname,'..');
async function scenario(browser,language,width,existing){
 const page=await browser.newPage({viewport:{width,height:840}});
 const errors=[];
 page.on('pageerror',e=>errors.push(String(e)));
 await page.route(/^https?:\/\//,route=>route.abort('blockedbyclient'));
 try{
  await page.setContent('<!doctype html><html lang="'+language+'"><body>'+
    '<section id="courses-subject-hub" data-subject-key="mathematics">'+
    '<div id="exam-prep-host-root"></div></section></body></html>');
  await page.evaluate(({language,existing})=>{
    const old=existing?{exam_series:'May/June 2027',target_grade:'A',
      total_student_hours_available:12,mathematics_hours_budget:6,profile_revision:5}:null;
    const tracker=window.__D3TEST={
      profile:old,saves:[],starts:[],weeklySaves:[],failed:false,diagnosticsComplete:false,
      choice:{contract_version:'voluntary_weekly_choice_s3_v1',
        choice_code:null,choice_recorded:false,chosen_math_minutes:old?360:null,
        p1_minutes:null,p5_minutes:null,schedule_revision:0,
        total_available_minutes:old?720:null,
        study_minutes_per_day:null,study_days_per_week:null}
    };
    const ok=data=>({ok:true,data:structuredClone(data)});
    const api={
      examProfile:async()=>ok(tracker.profile),
      saveExamProfile:async v=>{
        if(tracker.failed){tracker.failed=false;return {ok:false,error:{message:'offline'}}}
        tracker.saves.push({...v});
        const original=tracker.profile||{};
        tracker.profile={...original,exam_series:v.examSeries,target_grade:v.targetGrade,
          total_student_hours_available:v.totalHours??original.total_student_hours_available??null,
          mathematics_hours_budget:v.mathHours??original.mathematics_hours_budget??null};
        return ok({plan_rebuild_required:!!old,progress_retained:true});
      },
      diagnosticProgress:async code=>ok({component_code:code,stage0_complete:tracker.diagnosticsComplete,
        screening:{required_items:code==='P1'?7:9,answered_items:0,
          required_areas:3,answered_areas:0}}),
      personalHorizon:async()=>ok(null),
      studySchedule:async()=>ok(null),
      weeklyChoiceS3:async()=>ok(tracker.choice),
      claimPeriodReportsS3:async()=>ok({claimed:0}),
      periodReportsS3:async()=>ok({reports:[]}),
      hybridS4Catalog:async()=>ok({enabled:false,papers:[]}),
      saveWeeklyChoiceS3:async(v,k)=>{
        tracker.weeklySaves.push({...v,key:k});
        const budget=v.minutesPerDay*v.daysPerWeek;
        tracker.profile.mathematics_hours_budget=budget/60;
        tracker.choice={...tracker.choice,choice_code:'change',choice_recorded:true,
          chosen_math_minutes:budget,p1_minutes:v.p1Minutes,p5_minutes:v.p5Minutes,
          study_minutes_per_day:v.minutesPerDay,study_days_per_week:v.daysPerWeek,
          schedule_revision:tracker.choice.schedule_revision+1};
        return ok({saved:true,academic_marks_changed:false});
      },
      startNextDiagnostic:async code=>{tracker.starts.push(code);return ok({session_id:'synthetic-only-'+code})},
      getState:async()=>ok(null)
    };
    window.i18n={getLang:()=>language};
    window.iClubExamPrepWeeklyFlowEnabled=true;
    window.iClubExamPrepHostInternal={
      lastCapabilities:{coreAccess:true,killSwitch:false,rolloutState:'controlled_beta'},
      api
    };
    window.iClubExamPrep={
      open:async()=>true,isOpen:()=>true,
      syncSubjectHub:async()=>true,refreshCapabilities:async()=>true,
      back:()=>true,close:()=>true
    };
  },{language,existing});
  await page.addScriptTag({path:path.join(base,'exam-prep/exam-prep-live.js')});
  await page.evaluate(language=>window.iClubExamPrep.open({language,subjectKey:'mathematics'}),language);
  if(!existing){
    await page.waitForSelector('[data-ep-live-profile-form]');
    assert.equal(await page.locator('[data-ep-live-profile-form] input[name=exam_series]').count(),1);
    assert.equal(await page.locator('[data-ep-live-profile-form] input[name=target_grade]').count(),1);
    assert.equal(await page.locator('[data-ep-live-profile-form] input[name=total_hours]').count(),0,
      'no mandatory total-hours question for first-time learner');
    assert.equal(await page.locator('[data-ep-live-profile-form] input[name=math_hours]').count(),0,
      'no mandatory Math-hours question for first-time learner');
    await page.fill('[data-ep-live-profile-form] input[name=exam_series]','May/June 2027');
    await page.fill('[data-ep-live-profile-form] input[name=target_grade]','A');
    await page.click('[data-ep-live-save-profile]');
    await page.waitForSelector('[data-ep-v58-plan-open]');
    const saved=await page.evaluate(()=>window.__D3TEST);
    assert.equal(saved.saves.length,1);
    assert.equal(saved.saves[0].mathHours,null);
    assert.equal(saved.saves[0].totalHours,null);
    assert.deepEqual(saved.starts,[],'no diagnostic auto-start');
    await page.click('[data-ep-v58-plan-open]');
    await page.waitForSelector('[data-ep-v58-plan-page]');
    assert.equal(await page.locator('[data-ep-v58-profile-fact]').count(),0,
      'No duplicated legacy profile control');
    assert.equal(await page.locator('.ep-v58-profile-fact').count(),2,
      'no empty hour summary facts');
    await page.locator('[data-ep-v58-setting=weekly] summary').click();
    assert.equal(await page.locator('[data-ep-d3-time-pending]').count(),1,
      'no fictitious personal hours before P1 and P5 diagnostics');
    assert.equal(await page.locator('[data-ep-s3-save]').count(),0,
      'no 90-minute or 45/45 suggestion before diagnostic');
    await page.evaluate(()=>{window.__D3TEST.diagnosticsComplete=true});
    await page.evaluate(language=>window.iClubExamPrep.open({language,subjectKey:'mathematics'}),language);
    await page.waitForSelector('[data-ep-v58-plan-open]');
    await page.click('[data-ep-v58-plan-open]');
    await page.locator('[data-ep-v58-setting=weekly] summary').click();
    assert.equal(await page.locator('input[name=ep-s3-choice]:checked').inputValue(),'change',
      'without hours allow explicit voluntary time selection');
    assert.equal(await page.locator('[data-ep-s3-daily]').inputValue(),'30');
    assert.equal(await page.locator('[data-ep-s3-days]').inputValue(),'3');
    const noAuto=await page.evaluate(()=>window.__D3TEST);
    assert.equal(noAuto.weeklySaves.length,0,'90min UI example is not saved automatically');
    await page.click('[data-ep-s3-save]');
    await page.waitForFunction(()=>window.__D3TEST.weeklySaves.length===1);
    const after=await page.evaluate(()=>window.__D3TEST);
    assert.equal(after.weeklySaves[0].p1Minutes,45);
    assert.equal(after.weeklySaves[0].p5Minutes,45);
    assert.equal(after.profile.mathematics_hours_budget,1.5);
    assert.equal(after.profile.total_student_hours_available,null);
  } else {
    await page.waitForSelector('[data-ep-v58-plan-open]');
    await page.click('[data-ep-v58-plan-open]');
    await page.click('[data-ep-v58-profile-edit]');
    await page.waitForSelector('[data-ep-live-profile-form]');
    const original=await page.locator('[data-ep-live-profile-form] input[name=math_hours]').inputValue();
    assert.equal(original,'6');
    await page.fill('[data-ep-live-profile-form] input[name=math_hours]','4');
    await page.evaluate(()=>{window.__D3TEST.failed=true});
    await page.click('[data-ep-live-save-profile]');
    await page.waitForFunction(()=>document.querySelector('[data-ep-live-save-profile]')?.disabled===false);
    assert.equal(await page.locator('[data-ep-live-profile-form] input[name=math_hours]').inputValue(),'4',
      'network failure must not discard unsaved edit');
    await page.click('[data-ep-live-save-profile]');
    await page.waitForFunction(()=>window.__D3TEST.saves.length===1);
    const after=await page.evaluate(()=>window.__D3TEST);
    assert.equal(after.profile.total_student_hours_available,12);
    assert.equal(after.profile.mathematics_hours_budget,4);
    assert.equal(after.saves[0].totalHours,12);
    assert.equal(after.saves[0].mathHours,4);
    assert.equal(after.profile.profile_revision,5,'UI must not fabricate revisions');
  }
  assert.deepEqual(errors,[],language+' '+width+' '+existing+' no browser errors');
  console.log('PASS D3 Chromium '+language+' '+width+'px '+(existing?'existing':'new')+' profile');
 }finally{await page.close()}
}
(async()=>{
 const browser=await chromium.launch({headless:true});
 try{
  for(const language of ['ru','uz','en']){
   const width=language==='ru'?390:language==='uz'?375:1280;
   for(const existing of [false,true])await scenario(browser,language,width,existing);
  }
  console.log('D3-HOURS 6 real Chromium UI journeys PASS; all external HTTP blocked');
 }finally{await browser.close()}
})().catch(e=>{console.error(e);process.exitCode=1});
