'use strict';
const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const { chromium } = require('playwright');

const rootHtml = `<!doctype html><html lang="ru"><head></head><body>
<div id="exam-prep-host-root" aria-hidden="false"><section class="ep-host-shell ep-live"><div class="ep-live-grid">
<article class="ep-live-component-card" data-ep-live-component="P1"><div class="ep-live-actions"></div></article></div></section></div>
</body></html>`;
const base = 'https://iclub.test';
const boot = `${base}/exam-prep/exam-prep-progress-ux-boot.js?v=progressux2`;
const payload = {
  contract_version:'progress_ux_v1',component_code:'P1',active_week_no:1,
  plan_available:true,completed_goals:0,finalized_study_sessions:1,
  open_corrections:0,confirmed_skills:0,coverage_pct:0,
  goals:[{goal_id:'only-goal',component_code:'P1',priority_order:1,item_type:'learning',
    status:'not_started',weekly_commitment_complete:false,correction_open:false,
    finalized_sessions:0,action_priority_order:1,retest_due_at:null,plan_changed:false}]
};

(async () => {
  const browser = await chromium.launch({headless:true});
  try {
    async function makePage(enabled, holdModel = false) {
      const page = await browser.newPage();
      const loads = [];
      let releaseModel;
      await page.route(`${base}/**`,async route=>{
        const pathname = new URL(route.request().url()).pathname;
        if (pathname === '/') return route.fulfill({status:200,contentType:'text/html',body:rootHtml});
        const filename = pathname.split('/').at(-1);
        loads.push(filename);
        if (!/^exam-prep-progress-ux-(?:boot|stability|model|api|ui)\.js$/.test(filename) &&
            !/^exam-prep-progress-ux(?:-stability)?\.css$/.test(filename))
          throw new Error(`Unexpected request ${pathname}`);
        if (holdModel && filename === 'exam-prep-progress-ux-model.js') {
          await new Promise(resolve=>{ releaseModel=resolve; });
        }
        const file = path.resolve('exam-prep',filename);
        return route.fulfill({status:200,contentType:filename.endsWith('.css')?'text/css':'text/javascript',body:fs.readFileSync(file,'utf8')});
      });
      await page.goto(`${base}/`);
      await page.evaluate(({enabled,payload})=>{
        window.iClubExamPrepProgressUxEnabled=enabled;
        window.iClubExamPrepHostInternal={
          lastCapabilities:{coreAccess:true,killSwitch:false,rolloutState:'controlled_beta'},
          api:{weeklyPlan:async()=>({ok:true,data:{plan_id:'plan-1'}}),syllabusTracker:async()=>({ok:true,data:{areas:[]}})}
        };
        window.sb={rpc:async(name,args)=>({data:name==='ensure_exam_prep_weekly_goals_safe_v1'
          ? {contract_version:'progress_ux_v1',component_code:args.p_component_code,created:0}
          : structuredClone(payload),error:null})};
      },{enabled,payload});
      return {page,loads,release:()=>releaseModel?.()};
    }

    const off=await makePage(false);
    await off.page.addScriptTag({url:boot});
    await off.page.waitForTimeout(120);
    assert.deepEqual(off.loads,['exam-prep-progress-ux-boot.js'],'OFF must never request optional assets');
    assert.equal(await off.page.locator('.ep-pux-panel').count(),0);
    await off.page.close();

    const on=await makePage(true);
    await on.page.addScriptTag({url:boot});
    await on.page.waitForFunction(()=>window.iClubExamPrepHostInternal.progressUxBootstrapStatus==='ready');
    await on.page.waitForSelector('.ep-pux-overview');
    for (const asset of ['exam-prep-progress-ux-stability.js','exam-prep-progress-ux-stability.css',
      'exam-prep-progress-ux-model.js','exam-prep-progress-ux-api.js','exam-prep-progress-ux-ui.js'])
      assert.equal(on.loads.filter(name=>name===asset).length,1,`Asset ${asset} must load exactly once`);
    assert.ok(on.loads.indexOf('exam-prep-progress-ux-stability.js')<on.loads.indexOf('exam-prep-progress-ux-model.js'));
    assert.ok(on.loads.indexOf('exam-prep-progress-ux-model.js')<on.loads.indexOf('exam-prep-progress-ux-api.js'));
    assert.ok(on.loads.indexOf('exam-prep-progress-ux-api.js')<on.loads.indexOf('exam-prep-progress-ux-ui.js'));
    await on.page.addScriptTag({url:boot});
    assert.equal(on.loads.filter(name=>name==='exam-prep-progress-ux-ui.js').length,1,'Repeat bootstrap cannot duplicate observer/UI');
    await on.page.close();

    const lost=await makePage(true,true);
    const load=lost.page.addScriptTag({url:boot});
    await lost.page.waitForFunction(()=>window.iClubExamPrepHostInternal.progressUxBootstrapStatus==='loading');
    await lost.page.waitForFunction(()=>window.iClubExamPrepHostInternal.progressUxStability?.version==='progress_ux_stability_v2');
    await lost.page.evaluate(()=>{window.iClubExamPrepProgressUxEnabled=false;});
    lost.release();
    await load;
    await lost.page.waitForFunction(()=>window.iClubExamPrepHostInternal.progressUxBootstrapStatus==='unavailable');
    assert.equal(lost.loads.includes('exam-prep-progress-ux-ui.js'),false,'Revocation during loading must stop presentation');
    assert.equal(await lost.page.locator('.ep-pux-panel').count(),0);
    assert.equal(await lost.page.locator('#exam-prep-host-root').getAttribute('data-ep-pux-loading'),null,'Revocation must release loading screen');
    await lost.page.close();
    console.log('Progress UX bootstrap: PASS (OFF, stable loader, ordered assets, repeat, revocation)');
  } finally {await browser.close();}
})().catch(error=>{console.error(error);process.exit(1);});