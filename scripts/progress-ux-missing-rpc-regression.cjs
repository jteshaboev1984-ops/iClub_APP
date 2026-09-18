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
    const errors=[];
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
    assert.match(await page.locator('.ep-pux-error').innerText(),/временно недоступен/i);
    assert.equal(await page.locator('#legacy-action').count(),1);
    assert.equal(await page.locator('#legacy-action').isEnabled(),true);
    assert.deepEqual(errors,[]);
    await page.evaluate(()=>{
      window.iClubExamPrepHostInternal.lastCapabilities={coreAccess:false,killSwitch:false,rolloutState:'controlled_beta'};
      document.querySelector('#exam-prep-host-root').append(document.createElement('span'));
    });
    await page.waitForTimeout(120);
    assert.equal(await page.locator('.ep-pux-panel').count(),0);
    assert.equal(await page.locator('#legacy-action').count(),1);
    await page.close();

    // Regression introduced by PR #118: an OPTIONAL progress module must never
    // replace the authoritative API used for diagnostic reads and answer writes.
    // The accelerated fake watchdog makes PR #118 fail on the slow Core methods.
    const source=fs.readFileSync(path.resolve('exam-prep/exam-prep-progress-ux-api.js'),'utf8');
    const sleep=ms=>new Promise(resolve=>setTimeout(resolve,ms));
    let starts=0,loads=0,writes=0,optional=0;
    const original=Object.freeze({
      startNextDiagnostic:async()=>{starts++;await sleep(30);return {ok:true,data:{session_id:'p1-session'}};},
      getSession:async()=>{loads++;await sleep(30);return {ok:true,data:{items:Array.from({length:5},(_,i)=>({item_order:i+1,answered:false}))}};},
      submitResponse:async()=>{writes++;await sleep(30);return {ok:true,data:{response_id:'saved-answer'}};},
      weeklyPlan:async()=>({ok:true,data:{plan_id:'existing-plan'}})
    });
    const internal={lastCapabilities:{coreAccess:true,killSwitch:false,rolloutState:'controlled_beta'},api:original};
    const window={iClubExamPrepProgressUxEnabled:true,iClubExamPrepHostInternal:internal,
      sb:{rpc:async(_name,args)=>{optional++;return {data:{contract_version:'progress_ux_v1',component_code:args.p_component_code},error:null};}}};
    vm.runInNewContext(source,{window,setTimeout:fn=>setTimeout(fn,12),clearTimeout});
    assert.strictEqual(internal.api,original,'PR #118 regression: optional UI must preserve original Core API object');
    assert.equal((await internal.api.startNextDiagnostic('P1','same-key')).data.session_id,'p1-session');
    assert.equal((await internal.api.getSession('p1-session','ru')).data.items.length,5);
    assert.equal((await internal.api.submitResponse('p1-session',1,{picked_index:0},'same-key')).data.response_id,'saved-answer');
    assert.deepEqual([starts,loads,writes],[1,1,1],'Core writes and reads must execute exactly once');
    assert.equal((await internal.progressUxApi.progress('P1')).ok,true);
    assert.equal(optional,2,'Only optional snapshot and progress RPCs are added');
    assert.strictEqual(internal.api,original,'Optional progress request must not modify Core API later');
    window.iClubExamPrepProgressUxEnabled=false;
    assert.equal((await internal.progressUxApi.progress('P1')).reason,'progress_ux_disabled');
    console.log('PR #118 baseline comparison: PASS (original Core identity, delayed P1 load and one answer write, optional UI isolation, revocation)');
  } finally {await browser.close();}
})().catch(error=>{console.error(error);process.exit(1);});
