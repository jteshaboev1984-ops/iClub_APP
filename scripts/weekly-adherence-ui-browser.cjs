'use strict';
// Isolated Chromium DOM + real guarded adapter/notice. All HTTP requests blocked;
// synthetic RPC only, no production learner or database access.
const assert = require('node:assert/strict');
const path = require('node:path');
const { chromium } = require('playwright');
const source = name => path.resolve('exam-prep',name);
const response = (component,status,done=0,due=2) => ({
  contract_version:'previous_week_adherence_v1',component_code:component,
  active_week_no:1,status,can_alert:status==='missed',scheduled_goals:due,
  completed_by_deadline:0,completed_now:done,deferred_goals:0,
  week_ended_at:'2026-09-19T08:00:00Z',does_not_change_goals_or_grades:true
});
async function fixture(page,language,flag,modes) {
  await page.setContent(`<!doctype html><html lang="${language}"><head><meta name="viewport" content="width=device-width,initial-scale=1"></head><body><div id="exam-prep-host-root" aria-hidden="false"><div class="ep-host-shell ep-live"><div class="ep-live-card" data-ep-exam-plan-card="true"><div class="ep-live-head"><strong>Exam plan</strong><button type="button" data-ep-exam-plan-edit="true">Change exam plan</button></div></div></div></div></body></html>`);
  await page.addStyleTag({path:source('exam-prep-host.css')});
  await page.evaluate(([lang,enabled,initial])=>{
    window.iClubExamPrepProgressUxEnabled=true;
    window.iClubExamPrepWeeklyFlowEnabled=enabled;
    window.i18n={getLang:()=>lang};
    window.iClubExamPrepHostInternal={lastCapabilities:{coreAccess:true,killSwitch:false,rolloutState:'controlled_beta'}};
    window.__weekTest={calls:[],replies:initial};
    window.sb={rpc:async(name,args)=>{
      window.__weekTest.calls.push({name,args});
      if(name!=='get_exam_prep_previous_week_adherence_safe_v1') throw Error('Unexpected write or RPC '+name);
      const payload=window.__weekTest.replies[args.p_component_code];
      if(payload==='offline') throw Error('offline');
      return {data:payload,error:null};
    }};
  },[language,flag,modes]);
  await page.addScriptTag({path:source('exam-prep-weekly-flow-adapter.js')});
  await page.addScriptTag({path:source('exam-prep-weekly-adherence-ui.js')});
}
(async()=>{
  const browser=await chromium.launch({headless:true});
  try {
    let count=0;
    for(const lang of ['ru','uz','en']) for(const width of [390,1280]) {
      for(const kind of ['missed','both','caught_up','unverified','offline','flag_off']) {
        const page=await browser.newPage({viewport:{width,height:840}});
        const browserErrors=[];
        page.on('pageerror',err=>browserErrors.push(err.message));
        await page.route(/^https?:\/\//,route=>route.abort());
        let p1=response('P1','missed',1,3);
        let p5=response('P5','completed_on_time',2,2);
        if(kind==='both') p5=response('P5','missed',0,1);
        if(kind==='caught_up') p1=response('P1','caught_up',3,3);
        if(kind==='unverified') p1={...p1,component_code:'P5'};
        if(kind==='offline') p1='offline';
        await fixture(page,lang,kind!=='flag_off',{P1:p1,P5:p5});
        const expected=kind==='missed'||kind==='both'||kind==='flag_off' ? (kind==='flag_off'?0:1):0;
        if(expected) await page.waitForSelector('[data-ep-weekly-adherence-notice]');
        else await page.waitForTimeout(120);
        const notices=page.locator('[data-ep-weekly-adherence-notice]');
        assert.equal(await notices.count(),expected,`${lang}/${width}/${kind}: false warning`);
        assert.equal(await page.locator('[data-ep-exam-plan-edit]').count(),1,'Existing editor duplicated');
        assert.equal(await page.locator('button').count(),1,'Added a redundant replan button');
        if(expected) {
          const text=await notices.innerText();
          assert.ok(text.includes('P1'),`${lang}/${width}: missing independent P1`);
          assert.equal(text.includes('P5'),kind==='both',`${lang}/${width}: P5 falsely included`);
          assert.ok(text.includes(lang==='ru'?'Изменить план':lang==='uz'?'Rejani o‘zgartirish':'Change exam plan'));
          assert.ok(text.length<750,'Warning text too large for mobile');
          const geometry=await notices.boundingBox();
          assert.ok(geometry&&geometry.width>200&&geometry.width<=width,`${lang}/${width}: notice overflow`);
          // Repeated DOM additions must not create a second warning.
          await page.evaluate(()=>document.querySelector('[data-ep-exam-plan-card]').append(document.createElement('span')));
          await page.waitForTimeout(20);
          assert.equal(await notices.count(),1,'MutationObserver duplicated warning');
        }
        const calls=await page.evaluate(()=>window.__weekTest.calls);
        assert.equal(calls.some(call=>call.name!=='get_exam_prep_previous_week_adherence_safe_v1'),false);
        assert.equal(calls.length,kind==='flag_off'?0:2,`${lang}/${width}/${kind}: read-only request count`);
        assert.deepEqual(browserErrors,[],`${lang}/${width}/${kind}: browser error`);
        count++;
        await page.close();
      }
    }
    console.log(`GREEN ${count} RU/UZ/EN x mobile/desktop x missed/both/caught-up/malformed/offline/OFF; no duplicate editor, write or HTTP.`);
  }finally{await browser.close();}
})().catch(err=>{console.error(err);process.exitCode=1;});
