'use strict';
const assert = require('node:assert/strict');
const path = require('node:path');
const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({headless:true});
  try {
    const page = await browser.newPage({viewport:{width:390,height:844}});
    const errors = [];
    page.on('pageerror',e=>errors.push(e.message));
    await page.setContent(`<!doctype html><html lang="ru"><body>
      <div id="exam-prep-host-root" aria-hidden="false">
        <article class="ep-live-component-card" data-ep-live-component="P1">
          <strong>Pure Mathematics 1</strong>
          <div class="ep-live-actions"><button id="legacy-action">Открыть план</button></div>
        </article>
      </div>
    </body></html>`);
    await page.evaluate(()=>{
      window.iClubExamPrepProgressUxEnabled=true;
      window.iClubExamPrepHostInternal={
        lastCapabilities:{coreAccess:true,killSwitch:false,rolloutState:'controlled_beta'},
        api:{weeklyPlan:async()=>({ok:true,data:{plan_id:'existing-plan'}})}
      };
      window.sb={rpc:async()=>({data:null,error:{message:'function_missing'}})};
    });
    await page.addScriptTag({path:path.resolve('exam-prep/exam-prep-progress-ux-model.js')});
    await page.addScriptTag({path:path.resolve('exam-prep/exam-prep-progress-ux-api.js')});
    await page.addScriptTag({path:path.resolve('exam-prep/exam-prep-progress-ux-ui.js')});
    await page.waitForSelector('.ep-pux-error');
    const text=await page.locator('.ep-pux-error').innerText();
    assert.match(text,/временно недоступен/i,'Missing RPC must show neutral temporary-unavailable state');
    assert.equal(await page.locator('#legacy-action').count(),1,'Existing Exam Prep action must remain intact');
    assert.equal(await page.locator('#legacy-action').isEnabled(),true,'Existing Exam Prep action must remain usable');
    assert.deepEqual(errors,[],'Missing progress RPC must not throw an uncaught browser error');

    await page.evaluate(()=>{
      window.iClubExamPrepHostInternal.lastCapabilities={coreAccess:false,killSwitch:false,rolloutState:'controlled_beta'};
      document.querySelector('#exam-prep-host-root').append(document.createElement('span'));
    });
    await page.waitForTimeout(120);
    assert.equal(await page.locator('.ep-pux-panel').count(),0,'Access revocation must remove optional progress UI');
    assert.equal(await page.locator('#legacy-action').count(),1,'Legacy action must survive optional UI cleanup');

    console.log('Progress UX missing RPC: PASS (neutral error, legacy action preserved, revocation cleanup)');
  } finally { await browser.close(); }
})().catch(e=>{console.error(e);process.exit(1);});
