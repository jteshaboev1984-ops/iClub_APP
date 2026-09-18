'use strict';
const assert = require('node:assert/strict');
const path = require('node:path');
const fs = require('node:fs');
const vm = require('node:vm');
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
    await page.close();

    // A missing network response must never leave a beta learner behind an endless loader.
    // Run actual production module under a fast synthetic clock, without Supabase writes.
    const source=fs.readFileSync(path.resolve('exam-prep/exam-prep-progress-ux-api.js'),'utf8');
    const never=()=>new Promise(()=>{});
    const caps={coreAccess:true,killSwitch:false,rolloutState:'controlled_beta'};
    function boot(api,rpc) {
      const internal={lastCapabilities:caps,api};
      const win={iClubExamPrepProgressUxEnabled:true,iClubExamPrepHostInternal:internal,sb:{rpc}};
      vm.runInNewContext(source,{window:win,setTimeout:fn=>setTimeout(fn,12),clearTimeout});
      return internal;
    }
    let reads=0,writes=0;
    const stuck=boot({weeklyPlan:()=>{reads++;return never();},submitResponse:()=>{writes++;return never();}},never);
    const readResult=await stuck.api.weeklyPlan('P1');
    assert.equal(readResult.ok,false);assert.equal(readResult.reason,'rpc_timeout');
    const writeResult=await stuck.api.submitResponse('session',1,{},'same-idempotency-key');
    assert.equal(writeResult.ok,false);assert.equal(writeResult.reason,'write_status_unknown');
    assert.equal(reads,1);assert.equal(writes,1,'a timed-out write must never be retried automatically');
    const planResult=await stuck.progressUxApi.progress('P1');
    assert.equal(planResult.ok,false);assert.equal(planResult.reason,'rpc_timeout');
    let rpcCalls=0;
    const success=boot({weeklyPlan:async()=>({ok:true,data:{plan_id:'real-plan'}})},async(name,args)=>{
      rpcCalls++;
      return {data:{contract_version:'progress_ux_v1',component_code:args.p_component_code},error:null};
    });
    assert.equal((await success.progressUxApi.progress('P5')).ok,true);
    assert.equal(rpcCalls,2,'healthy plan snapshot and progress still work');
    console.log('Progress UX missing RPC: PASS (neutral error, revocation, bounded requests, no write replay)');
  } finally { await browser.close(); }
})().catch(e=>{console.error(e);process.exit(1);});
