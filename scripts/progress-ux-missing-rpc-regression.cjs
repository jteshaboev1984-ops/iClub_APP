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

    // Reproduce PR #118 regression at the API boundary without live database writes.
    // The optional module must not replace/wrap the Core methods used to load P1.
    const source=fs.readFileSync(path.resolve('exam-prep/exam-prep-progress-ux-api.js'),'utf8');
    const never=()=>new Promise(()=>{});
    const caps={coreAccess:true,killSwitch:false,rolloutState:'controlled_beta'};
    function boot(api,rpc) {
      const internal={lastCapabilities:{...caps},api};
      const win={iClubExamPrepProgressUxEnabled:true,iClubExamPrepHostInternal:internal,sb:{rpc}};
      vm.runInNewContext(source,{window:win,setTimeout:fn=>setTimeout(fn,12),clearTimeout});
      return {internal,win};
    }
    let starts=0,loads=0,writes=0,optionalCalls=0;
    const core=Object.freeze({
      startNextDiagnostic:async()=>{starts++;return {ok:true,data:{session_id:'existing-P1'}};},
      getSession:async()=>{loads++;return {ok:true,data:{items:Array.from({length:5},(_,i)=>({item_order:i+1,answered:false}))}};},
      submitResponse:async()=>{writes++;return {ok:true,data:{saved:true}};},
      weeklyPlan:async()=>({ok:true,data:{plan_id:'existing-plan'}})
    });
    const intact=boot(core,async(name,args)=>{
      optionalCalls++;
      return {data:{contract_version:'progress_ux_v1',component_code:args.p_component_code},error:null};
    });
    assert.strictEqual(intact.internal.api,core,'Progress UX must not replace the Core API (PR #118 regression)');
    assert.equal((await intact.internal.api.startNextDiagnostic('P1','same-key')).data.session_id,'existing-P1');
    assert.equal((await intact.internal.api.getSession('existing-P1','ru')).data.items.length,5);
    assert.equal((await intact.internal.api.submitResponse('existing-P1',1,{picked_index:0},'same-key')).ok,true);
    assert.equal(starts,1);assert.equal(loads,1);assert.equal(writes,1,'No extra diagnostic or answer request');
    assert.equal((await intact.internal.progressUxApi.progress('P1')).ok,true);
    assert.equal(optionalCalls,2,'Healthy optional snapshot and progress');
    const stuckCore=Object.freeze({weeklyPlan:never,startNextDiagnostic:async()=>({ok:true})});
    const stuck=boot(stuckCore,never);
    assert.strictEqual(stuck.internal.api,stuckCore);
    assert.equal((await stuck.internal.progressUxApi.progress('P1')).reason,'rpc_timeout');
    assert.equal((await stuck.internal.api.startNextDiagnostic('P1')).ok,true,'Optional timeout must not block Core');
    let snapshotCalls=0;
    const unclear=boot(core,name=>{snapshotCalls++;return name==='ensure_exam_prep_weekly_goals_safe_v1'?never():null;});
    assert.equal((await unclear.internal.progressUxApi.progress('P5')).reason,'write_status_unknown');
    assert.equal(snapshotCalls,1,'Unknown optional snapshot write must not be retried');
    unclear.win.iClubExamPrepProgressUxEnabled=false;
    assert.equal((await unclear.internal.progressUxApi.progress('P1')).reason,'progress_ux_disabled');
    console.log('Progress UX: PASS (missing RPC, revocation, P1 five questions, untouched Core, scoped timeout, no replay)');
  } finally { await browser.close(); }
})().catch(e=>{console.error(e);process.exit(1);});
