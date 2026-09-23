'use strict';
// Actual Exam Prep DOM, synthetic owner-scoped APIs only; every external request blocked.
const assert=require('node:assert/strict');
const path=require('node:path');
const {chromium}=require('playwright');
const file=p=>path.resolve(p);
function dashboard(){return '<section class="ep-host-shell ep-live"><div class="ep-live-dashboard-intro"></div><div class="ep-live-grid"><button type="button" data-ep-live-plan="P1">P1</button><button type="button" data-ep-live-plan="P5">P5</button></div></section>';}
async function scenario(browser,lang,width,enabled,route){
  const page=await browser.newPage({viewport:{width,height:820}});
  const errors=[];
  page.on('pageerror',e=>errors.push(e.message));
  await page.route(/^https?:\/\//,r=>r.abort());
  try{
    await page.setContent(`<!doctype html><html lang="${lang}"><body><div id="exam-prep-host-root">${dashboard()}</div></body></html>`);
    await page.evaluate(([lang,enabled,route])=>{
      window.iClubExamPrepWeeklyFlowEnabled=enabled;
      window.i18n={getLang:()=>lang};
      const profile={exam_series:'May/June 2027',target_grade:'A',total_student_hours_available:10,mathematics_hours_budget:5};
      const state=window.__profileRecovery={generator:[],saves:0,profile,route};
      const ok=data=>({ok:true,data:structuredClone(data)});
      const internal=window.iClubExamPrepHostInternal={lastCapabilities:{coreAccess:true,killSwitch:false,rolloutState:'controlled_beta'}};
      internal.api={
        examProfile:async()=>ok(state.profile),
        saveExamProfile:async v=>{state.saves++;state.profile={exam_series:v.examSeries,target_grade:v.targetGrade,total_student_hours_available:v.totalHours,mathematics_hours_budget:v.mathHours};return ok({plan_rebuild_required:true,series_changed:true,progress_retained:true});},
        recovery:async component=>ok({component_code:component,active:true,missed_days:4}),
        recordInterruption:async()=>{state.saves++;return ok({missed_days:4,active:true});},
        generateWeeklyPlan:async comp=>{state.generator.push(comp);return ok({plan_id:'synthetic-only'});}
      };
      window.iClubExamPrep={refreshCapabilities:async()=>{document.querySelector('#exam-prep-host-root').innerHTML='<section class="ep-host-shell ep-live"><div class="ep-live-dashboard-intro"></div><div class="ep-live-grid"><button type="button" data-ep-live-plan="P1">P1</button><button type="button" data-ep-live-plan="P5">P5</button></div></section>';return true;}};
    },[lang,enabled,route]);
    await page.addScriptTag({path:file(route==='recovery'?'exam-prep/exam-prep-recovery.js':'exam-prep/exam-prep-exam-map.js')});
    if(route==='recovery'){
      await page.waitForSelector('[data-ep-recovery-card]');
      await page.click('[data-ep-recovery-open]');
      await page.waitForSelector('[data-ep-recovery-form]');
      await page.fill('input[name="started_on"]','2026-09-01');
      await page.fill('input[name="resumed_on"]','2026-09-05');
      await page.click('[data-ep-recovery-form] button[type="submit"]');
      await page.waitForSelector('[data-ep-recovery-success]');
      const text=await page.locator('[data-ep-recovery-success]').innerText();
      if(enabled) assert(/not replaced|almashtirilmadi|не заменены/.test(text),`${lang}: no false replan claim`);
      else assert(/adjusted|moslashtirildi|адаптирован/.test(text),`${lang}: legacy text unchanged`);
      const state=await page.evaluate(()=>window.__profileRecovery);
      assert.strictEqual(state.saves,1);
      assert.deepEqual(state.generator,enabled?[]:['P1','P5'],`${lang}: do not generate both plans on guarded interruption`);
    }else{
      await page.waitForSelector('[data-ep-exam-plan-card]');
      await page.click('[data-ep-exam-plan-edit]');
      await page.waitForSelector('[data-ep-exam-plan-form]');
      await page.fill('input[name="exam_series"]','Oct/Nov 2027');
      const saveLabel=await page.locator('[data-ep-exam-plan-form] button[type="submit"]').innerText();
      if(enabled) assert(/changes|O‘zgarishlarni|изменения/.test(saveLabel),`${lang}: guarded save must not promise a replan`);
      await page.click('[data-ep-exam-plan-form] button[type="submit"]');
      await page.waitForSelector('[data-ep-exam-plan-notice]');
      const text=await page.locator('[data-ep-exam-plan-notice]').innerText();
      assert(/new full papers|yangi to‘liq ishlar|новым полным работам/.test(text),`${lang}: changed-series comparability must remain clear`);
      if(enabled) assert(/not replaced|almashtirilmadi|не заменены/.test(text),`${lang}: preserve old weekly tasks`);
      const state=await page.evaluate(()=>window.__profileRecovery);
      assert.strictEqual(state.saves,1);
      assert.strictEqual(state.generator.length,0,'Exam-map UI must not call generator itself');
    }
    assert.deepEqual(errors,[],`${lang}/${width}/${enabled}/${route}: no exceptions`);
    console.log(`PASS ${lang} ${width}px guarded=${enabled} route=${route}`);
  }finally{await page.close();}
}
(async()=>{
  const browser=await chromium.launch({headless:true});
  try{for(const lang of ['ru','uz','en'])for(const width of [390,1280])for(const enabled of [false,true])for(const route of ['recovery','profile'])await scenario(browser,lang,width,enabled,route);
    console.log('GREEN: 24 real-DOM profile and study-break journeys, network blocked and synthetic data only.');
  }finally{await browser.close();}
})().catch(e=>{console.error(e);process.exitCode=1;});
