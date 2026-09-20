'use strict';
// Genuine DOM, source UI and guarded weekday module. SYNTHETIC RPC ONLY.
// All HTTP blocked; no network, production database or real student data.
const assert=require('node:assert/strict');
const path=require('node:path');
const {chromium}=require('playwright');
const src=name=>path.resolve('exam-prep',name);
const days=['mon','tue','wed','thu','fri','sat','sun'];
const initial={mon:1,tue:1,wed:1,thu:1,fri:1,sat:0,sun:0};
const dashboard=()=>`<div class="ep-host-shell ep-live"><div class="ep-live-head">Existing Exam Prep header</div><div class="ep-live-dashboard-intro">Dashboard</div><div data-ep-live-plan="P1"></div><div data-ep-live-plan="P5"></div><div class="ep-live-grid"></div></div>`;
async function setup(page,lang,kind){
  await page.route(/^https?:\/\//,route=>route.abort());
  await page.setContent(`<!doctype html><html lang="${lang}"><head><meta name="viewport" content="width=device-width,initial-scale=1"></head><body><div id="exam-prep-host-root">${dashboard()}</div></body></html>`);
  await page.addStyleTag({path:src('exam-prep-host.css')});
  await page.addStyleTag({path:src('exam-prep-weekly-hours.css')});
  await page.evaluate(([language,variant,html])=>{
    const profile={exam_series:'May/June 2027',target_grade:'A',total_student_hours_available:12,
      mathematics_hours_budget:6,active_week_no:1};
    const days={mon:1,tue:1,wed:1,thu:1,fri:1,sat:0,sun:0};
    const t=window.__dayTest={profile,days:{...days},pRev:1,dRev:1,calls:[],legacy:[],saved:[],
      dry:variant==='offline',variant};
    window.iClubExamPrepWeeklyFlowEnabled=variant!=='off';
    window.iClubExamPrepProgressUxEnabled=true;
    window.i18n={getLang:()=>language};
    window.iClubExamPrepHostInternal={lastCapabilities:{coreAccess:true,killSwitch:false,rolloutState:'controlled_beta'},
      api:{examProfile:async()=>({ok:true,data:structuredClone(t.profile)}),
        saveExamProfile:async value=>{
          t.legacy.push(structuredClone(value));
          t.profile={exam_series:value.examSeries,target_grade:value.targetGrade,
            total_student_hours_available:value.totalHours,mathematics_hours_budget:value.mathHours,
            active_week_no:1};
          return {ok:true,data:{series_changed:false,target_changed:false,hours_changed:false,plan_rebuild_required:false}};
        }}};
    window.iClubExamPrep={refreshCapabilities:async()=>{
      document.querySelector('#exam-prep-host-root').innerHTML=html;
    }};
    window.sb={rpc:async(name,args={})=>{
      t.calls.push({name,args:structuredClone(args)});
      if(name==='get_my_exam_prep_weekday_availability_safe_v1'){
        if(t.dry) return {data:null,error:{code:'NETWORK'}};
        const shownProfile=variant==='read_stale'?{...t.profile,mathematics_hours_budget:5}:t.profile;
        return {data:{contract_version:'weekly_day_availability_v1',enabled:true,
          scope:'shared_mathematics_week',weekday_hours:structuredClone(t.days),
          confirmed:variant!=='reconfirm',needs_reconfirmation:variant==='reconfirm',
          profile_revision:t.pRev,availability_revision:t.dRev,
          exam_series:shownProfile.exam_series,target_grade:shownProfile.target_grade,
          total_student_hours_available:shownProfile.total_student_hours_available,
          mathematics_hours_budget:shownProfile.mathematics_hours_budget,
          planning_only:true,does_not_change_current_plan:true},error:null};
      }
      if(name==='save_my_exam_prep_profile_with_weekday_availability_safe_v1'){
        if(args.p_expected_profile_revision!==t.pRev||args.p_expected_availability_revision!==t.dRev)
          return {data:null,error:{code:'40001',message:'stale'}};
        if(args.p_weekday_hours!==null){
          const v=Object.values(args.p_weekday_hours);
          if(v.length!==7||v.some(x=>typeof x!=='number')||v.reduce((a,b)=>a+b,0)>args.p_mathematics_hours_budget)
            return {data:null,error:{code:'40001',message:'invalid'}};
        }
        t.days=args.p_weekday_hours===null?null:structuredClone(args.p_weekday_hours);
        t.dRev++;
        t.saved.push(structuredClone(args));
        t.profile={...t.profile,exam_series:args.p_exam_series,target_grade:args.p_target_grade,
          total_student_hours_available:args.p_total_student_hours_available,
          mathematics_hours_budget:args.p_mathematics_hours_budget};
        return {data:{day_availability_saved:true,day_availability_confirmed:t.days!==null,
          availability_revision:t.dRev,progress_retained:true,does_not_replace_current_week:true,
          plan_rebuild_required:false,series_changed:false,target_changed:false,hours_changed:false},error:null};
      }
      throw Error('Unexpected RPC: '+name);
    }};
  },[lang,kind,dashboard()]);
  await page.addScriptTag({path:src('exam-prep-weekly-hours.js')});
  await page.addScriptTag({path:src('exam-prep-exam-map.js')});
  await page.waitForSelector('[data-ep-exam-plan-card]');
  await page.click('[data-ep-exam-plan-edit]');
  await page.waitForSelector('[data-ep-exam-plan-form]');
  if(!['off','offline','read_stale'].includes(kind)) await page.waitForSelector('[data-ep-weekday-hours-fields]');
  else if(kind==='offline'||kind==='read_stale') await page.waitForFunction(()=>
    ['unavailable','stale'].includes(document.querySelector('[data-ep-exam-plan-form]')?.dataset.epWeekdayHours));
}
(async()=>{
  const browser=await chromium.launch({headless:true});let cases=0;
  try{
    const variants=['valid','partial','over_budget','clear','reconfirm','device_day_conflict',
      'read_stale','offline','off','revoked'];
    for(const lang of ['ru','uz','en']) for(const width of [390,1280]) for(const kind of variants){
      const page=await browser.newPage({viewport:{width,height:840}});
      const errors=[];page.on('pageerror',error=>errors.push(error.message));
      await setup(page,lang,kind);
      const form=page.locator('[data-ep-exam-plan-form]');
      assert.equal(await page.locator('[data-ep-exam-plan-editor]').count(),1,'Duplicate editor');
      assert.equal(await page.locator('[data-ep-exam-plan-edit]').count(),0,'Extra edit button in editor');
      const dayInputs=page.locator('.ep-day-hours input');
      if(kind==='off'||kind==='offline'||kind==='read_stale'){
        assert.equal(await dayInputs.count(),0,`${kind}: unexpected weekday fields`);
      }else{
        assert.equal(await dayInputs.count(),7,`${kind}: incorrect weekdays`);
        const box=await page.locator('.ep-day-hours').boundingBox();
        assert.ok(box&&box.x>=-1&&box.x+box.width<=width+2,`${lang}/${width}: weekday panel horizontal overflow`);
        assert.equal(await page.locator('form').count(),1,'Second settings form');
        for(const [index,day] of days.entries())
          assert.equal(await page.locator(`input[name="ep_day_${day}"]`).inputValue(),String(initial[day]),`${lang}: prefill ${index}`);
        const text=await page.locator('.ep-day-hours').innerText();
        assert.ok(text.includes('P1')&&text.includes('P5'),`${lang}: missing shared budget disclaimer`);
        if(kind==='reconfirm') assert.equal(await page.locator('.ep-day-hours-reconfirm').count(),1);
        if(kind==='partial') await page.fill('input[name="ep_day_mon"]','');
        if(kind==='over_budget') await page.fill('input[name="ep_day_sat"]','4');
        if(kind==='clear') for(const day of days) await page.fill(`input[name="ep_day_${day}"]`,'');
        if(kind==='device_day_conflict') await page.evaluate(()=>window.__dayTest.dRev++);
        if(kind==='revoked') await page.evaluate(()=>window.iClubExamPrepWeeklyFlowEnabled=false);
      }
      if(kind==='read_stale'){
        await form.locator('button[type="submit"]').click();
        assert.equal(await page.locator('[data-ep-exam-plan-form]').count(),1,'Stale read submitted');
      }else{
        await form.locator('button[type="submit"]').click();
      }
      if(['valid','clear','reconfirm','off','offline'].includes(kind))
        await page.waitForSelector('[data-ep-exam-plan-card]');
      const state=await page.evaluate(()=>structuredClone(window.__dayTest));
      const writes=state.calls.filter(x=>x.name==='save_my_exam_prep_profile_with_weekday_availability_safe_v1');
      if(['valid','clear','reconfirm'].includes(kind)){
        assert.equal(writes.length,1,`${kind}: atomic save not called exactly once`);
        assert.equal(state.saved.length,1);
        assert.equal(state.legacy.length,0,'Optional edit used old non-atomic save');
        assert.equal(state.saved[0].p_expected_profile_revision,1);
        assert.equal(state.saved[0].p_expected_availability_revision,1);
        assert.equal(state.saved[0].p_weekday_hours===null,kind==='clear');
        assert.equal(state.dRev,2);
      }else if(kind==='device_day_conflict'){
        assert.equal(writes.length,1,'Conflict must reach one guarded CAS');
        assert.equal(state.saved.length,0,'Stale day-only edit was committed');
        assert.equal(state.legacy.length,0,'Stale day-only edit fell back to old save');
        assert.equal(await page.locator('[data-ep-exam-plan-form]').count(),1,'Stale save closed editor');
      }else if(['off','offline'].includes(kind)){
        assert.equal(state.legacy.length,1,'Legacy/fallback settings path must survive');
        assert.equal(writes.length,0);
      }else{
        assert.equal(writes.length,0,`${kind}: invalid/stale input performed mutation`);
        assert.equal(state.legacy.length,0,`${kind}: invalid/stale input fell back to legacy write`);
        assert.equal(await page.locator('[data-ep-exam-plan-form]').count(),1,'Invalid form closed');
      }
      assert.deepEqual(errors,[],`${lang}/${width}/${kind} page errors`);
      assert.equal(await page.locator('[data-ep-exam-plan-editor]').count()<=1,true);
      cases++;await page.close();
    }
    console.log(`GREEN ${cases} RU/UZ/EN mobile/desktop single-editor optional day-hour cases; CAS, budget, stale, OFF, offline, revoke, no HTTP or academic writes.`);
  }finally{await browser.close();}
})().catch(error=>{console.error(error);process.exitCode=1;});
