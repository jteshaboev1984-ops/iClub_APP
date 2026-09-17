'use strict';
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { chromium } = require('playwright');

const base = 'https://iclub.test';
const apiUrl = `${base}/exam-prep/exam-prep-api.js?v=p0loader`;
const html = '<!doctype html><html lang="ru"><head></head><body><div id="exam-prep-host-root" aria-hidden="false"><article class="ep-live-component-card" data-ep-live-component="P1"><div class="ep-live-actions"></div></article></div></body></html>';
const fixture = {
  contract_version: 'progress_ux_v1', component_code: 'P1', active_week_no: 1,
  plan_available: true, completed_goals: 0, finalized_study_sessions: 2,
  open_corrections: 1, confirmed_skills: 0, coverage_pct: 0,
  goals: [{goal_id:'g1',component_code:'P1',priority_order:1,item_type:'learning',
    status:'in_progress',weekly_commitment_complete:false,correction_open:false,
    finalized_sessions:2,action_priority_order:1,retest_due_at:null,plan_changed:false}]
};

(async () => {
  const browser = await chromium.launch({headless:true});
  try {
    async function scenario(enabled) {
      const page = await browser.newPage();
      const requests = [];
      const errors = [];
      page.on('pageerror',e=>errors.push(e.message));
      await page.route(`${base}/**`, async route => {
        const pathname = new URL(route.request().url()).pathname;
        if (pathname === '/') return route.fulfill({status:200,contentType:'text/html',body:html});
        const name = path.basename(pathname);
        requests.push(name);
        const progress = /^exam-prep-progress-ux-(?:model|api|ui|boot)\.js$/.test(name);
        if (name === 'exam-prep-api.js' || progress) {
          return route.fulfill({status:200,contentType:'text/javascript',body:fs.readFileSync(path.resolve('exam-prep',name),'utf8')});
        }
        if (name === 'exam-prep-progress-ux.css') {
          return route.fulfill({status:200,contentType:'text/css',body:fs.readFileSync(path.resolve('exam-prep',name),'utf8')});
        }
        if (/^exam-prep-[\w-]+\.js$/.test(name)) return route.fulfill({status:200,contentType:'text/javascript',body:'/* existing optional UI stub */'});
        throw new Error(`Unexpected dependency ${pathname}`);
      });
      await page.goto(`${base}/`);
      await page.evaluate(({enabled,fixture})=>{
        window.iClubExamPrepProgressUxEnabled=enabled;
        window.iClubExamPrepHostInternal={lastCapabilities:{coreAccess:true,killSwitch:false,rolloutState:'controlled_beta'}};
        window.sb={rpc:async(name,args)=>({data:name==='get_exam_prep_weekly_plan_safe_v2'
          ? {plan_id:'existing-plan',items:[]}
          : name==='ensure_exam_prep_weekly_goals_safe_v1'
            ? {contract_version:'progress_ux_v1',component_code:args.p_component_code,created:0}
            : structuredClone(fixture),error:null})};
      },{enabled,fixture});
      await page.addScriptTag({url:apiUrl});
      await page.waitForFunction(()=>typeof window.iClubExamPrepHostInternal.api?.weeklyPlan==='function');
      await page.waitForTimeout(200);
      return {page,requests,errors};
    }

    const off = await scenario(undefined);
    assert.equal(off.requests.filter(name=>name==='exam-prep-progress-ux-boot.js').length,0,'Default undefined flag cannot load bootstrap');
    assert.equal(off.requests.filter(name=>name.startsWith('exam-prep-progress-ux-')).length,0,'Default OFF cannot load progress assets');
    assert.equal(off.requests.filter(name=>name==='exam-prep-live.js').length,1,'Existing Exam Prep loader must remain active');
    assert.equal(await off.page.locator('.ep-pux-panel').count(),0,'OFF must preserve DOM');
    assert.deepEqual(off.errors,[]);
    await off.page.close();

    const on = await scenario(true);
    await on.page.waitForFunction(()=>window.iClubExamPrepHostInternal.progressUxBootstrapStatus==='ready');
    await on.page.waitForSelector('.ep-pux-overview');
    for (const name of ['exam-prep-progress-ux-boot.js','exam-prep-progress-ux-model.js',
      'exam-prep-progress-ux-api.js','exam-prep-progress-ux-ui.js','exam-prep-progress-ux.css']) {
      assert.equal(on.requests.filter(n=>n===name).length,1,`${name} must be requested once`);
    }
    assert.equal(on.requests.filter(name=>name==='exam-prep-live.js').length,1,'ON must not remove legacy loader');
    assert.deepEqual(on.errors,[]);
    await on.page.evaluate(()=>{
      window.iClubExamPrepHostInternal.lastCapabilities={coreAccess:false,killSwitch:true,rolloutState:'off'};
      document.querySelector('#exam-prep-host-root').appendChild(document.createElement('span'));
    });
    await on.page.waitForFunction(()=>document.querySelectorAll('.ep-pux-panel').length===0);
    await on.page.close();
    console.log('Progress UX real API loader: PASS (default OFF, original loader intact, opt-in boot once, revocation cleanup)');
  } finally { await browser.close(); }
})().catch(e=>{console.error(e);process.exit(1);});
