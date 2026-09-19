'use strict';
// Isolated genuine Chromium DOM, synthetic API only; external network blocked.
// Covers lost acknowledgement AFTER commit and BEFORE commit, never an auto replay.
const assert=require('node:assert/strict');
const path=require('node:path');
const {chromium}=require('playwright');
const file=p=>path.resolve(p);
const PLAN='11111111-1111-4111-8111-111111111111';
const GOAL='33333333-3333-4333-8333-333333333333';
const AUTH='55555555-5555-4555-8555-555555555555';
const SESSION='66666666-6666-4666-8666-666666666666';
async function scenario(browser,language,width,kind,mode) {
  const page=await browser.newPage({viewport:{width,height:850}}),errors=[];
  page.on('pageerror',e=>errors.push(e.message));
  await page.route(/^https?:\/\//,route=>route.abort());
  try {
    await page.setContent(`<!doctype html><html lang="${language}"><head><meta name="viewport" content="width=device-width,initial-scale=1"></head><body><div id="exam-prep-host-root" aria-hidden="false"></div></body></html>`);
    await page.addStyleTag({path:file('exam-prep/exam-prep-host.css')});
    await page.evaluate(([lang,kind,mode,planId,goalId,authId,sessionId])=>{
      window.iClubExamPrepWeeklyFlowEnabled=true;
      window.iClubExamPrepProgressUxEnabled=false;
      window.i18n={getLang:()=>lang};
      const s=window.__answerTest={kind,mode,planId,goalId,authId,sessionId,
        answered:false,finalized:false,sendCount:0,readCount:0,keys:[],payloads:[],generatorCount:0};
      const item=()=>({item_order:1,item_kind:kind==='written'?'written':'question',
        qtype:kind==='written'?null:'mcq',text:kind==='written'?null:'Convert 90° to radians.',
        written_prompt:kind==='written'?'Explain the radians conversion.':null,
        options:kind==='written'?null:['π/2','π'],answered:s.answered,
        understanding_checks:kind==='written'?[{check_order:1,check_version:'fixture-v1',
          prompt:'Which unit?',options:['radians','kilograms']}]:[]});
      const ok=data=>({ok:true,data:structuredClone(data)});
      const internal=window.iClubExamPrepHostInternal={lastCapabilities:
        {coreAccess:true,killSwitch:false,rolloutState:'controlled_beta'}};
      internal.api={
        examProfile:async()=>ok({exam_series:'May/June 2027',target_grade:'A',
          total_student_hours_available:10,mathematics_hours_budget:5}),
        diagnosticProgress:async()=>ok({stage0_complete:true,
          screening:{required_items:1,answered_items:1,required_areas:1,answered_areas:1}}),
        getState:async comp=>ok({components:[{component_code:comp,operational_stage:2,coverage_pct:0}]}),
        weeklyPlan:async()=>ok({plan_id:s.planId,active_week_no:1,items:
          [{priority_order:1,item_type:'learning',status:s.finalized?'completed':'pending'}]}),
        getSession:async id=>{s.readCount++;if(id!==s.sessionId)throw Error('Wrong session');
          return ok({session_id:id,component_code:'P1',session_type:'learning',
            status:s.finalized?'finalized':'active',items:[item()]});},
        submitResponse:async(id,order,payload,key)=>{
          assert.strictEqual(id,s.sessionId);assert.strictEqual(order,1);
          s.sendCount++;s.keys.push(key);s.payloads.push(structuredClone(payload));
          if(s.sendCount===1&&s.mode==='after_commit') {s.answered=true;throw Error('Lost acknowledgment after commit');}
          if(s.sendCount===1&&s.mode==='before_commit') throw Error('Lost connection before commit');
          s.answered=true;return ok({is_correct:kind==='written'?null:true});
        },
        finalizeSession:async()=>{assert(s.answered);s.finalized=true;return ok({status:'finalized'});}
      };
      internal.progressUxApi={progress:async()=>ok({goals:[{goal_id:s.goalId,component_code:'P1',action_priority_order:1}]})};
      internal.weeklyFlowApi={version:'weekly_flow_adapter_v1',allowed:()=>null,
        plan:async()=>ok({status:'existing',plan_id:s.planId}),
        authorize:async(comp,goal,plan)=>{
          assert.strictEqual(comp,'P1');assert.strictEqual(goal,s.goalId);
          assert.strictEqual(plan,s.planId);return ok({status:'authorized',authorization_id:s.authId});},
        start:async()=>ok({status:'started',session_id:s.sessionId})};
      window.iClubExamPrep={open:async()=>true,isOpen:()=>true,back:()=>true,close:()=>true,
        syncSubjectHub:async()=>true,refreshCapabilities:async()=>true};
    },[language,kind,mode,PLAN,GOAL,AUTH,SESSION]);
    await page.addScriptTag({path:file('exam-prep/exam-prep-live.js')});
    if(kind==='written') await page.addScriptTag({path:file('exam-prep/exam-prep-written-understanding-ui.js')});
    await page.evaluate(lang=>window.iClubExamPrep.open({language:lang}),language);
    await page.click('[data-ep-live-plan="P1"]');
    await page.click('[data-ep-live-plan-item="1"]');
    await page.waitForSelector('[data-ep-live-submit]');
    if(kind==='written') {
      await page.fill('textarea[name="ep_live_written_answer"]','My original detailed solution; keep this exact draft.');
      await page.waitForSelector('[data-ep-written-understanding-check]');
      await page.check('input[name="ep_written_understanding_1"][value="0"]');
    } else await page.check('input[name="ep_live_answer"][value="0"]');
    await page.click('[data-ep-live-submit]');
    if(mode==='after_commit') {
      await page.waitForFunction(()=>window.__answerTest.finalized);
      const s=await page.evaluate(()=>window.__answerTest);
      assert.strictEqual(s.sendCount,1,`${language}/${kind}: no second write after committed answer`);
      assert(s.readCount>=2,`${language}/${kind}: server checked saved item`);
      assert.strictEqual(s.generatorCount,0);
    } else {
      await page.waitForSelector('[data-ep-answer-recovery] [data-ep-answer-retry]');
      assert.strictEqual(await page.locator('[data-ep-live-submit]').isHidden(),true);
      assert.strictEqual(await page.locator('[data-ep-live-exit]').isDisabled(),true);
      if(kind==='written') {
        assert.strictEqual(await page.locator('textarea[name="ep_live_written_answer"]').inputValue(),
          'My original detailed solution; keep this exact draft.');
        assert.strictEqual(await page.locator('input[name="ep_written_understanding_1"][value="0"]').isChecked(),true);
      } else assert.strictEqual(await page.locator('input[name="ep_live_answer"][value="0"]').isChecked(),true);
      assert.strictEqual(await page.evaluate(()=>window.__answerTest.sendCount),1,'No automatic second submit');
      await page.click('[data-ep-answer-check]');
      await page.waitForSelector('[data-ep-answer-retry]');
      assert.strictEqual(await page.evaluate(()=>window.__answerTest.sendCount),1,'Read-only verification must not write');
      await page.click('[data-ep-answer-retry]');
      await page.waitForFunction(()=>window.__answerTest.finalized);
      const s=await page.evaluate(()=>window.__answerTest);
      assert.strictEqual(s.sendCount,2,'Exactly one explicit resend');
      assert.strictEqual(s.keys[0],s.keys[1],'Must preserve original idempotency key');
      assert.deepEqual(s.payloads[0],s.payloads[1],'Must preserve exact original answer');
      assert.strictEqual(s.generatorCount,0);
    }
    assert.deepEqual(errors,[],`${language}/${width}/${kind}/${mode}: no browser errors`);
    console.log(`PASS ${language} ${width}px ${kind} ${mode}`);
  } finally {await page.close();}
}
(async()=>{
  const browser=await chromium.launch({headless:true});
  try {
    for(const language of ['ru','uz','en'])
      for(const width of [390,1280])
        for(const kind of ['mcq','written'])
          for(const mode of ['before_commit','after_commit'])
            await scenario(browser,language,width,kind,mode);
    console.log('GREEN 24 lost-acknowledgment real-DOM scenarios; synthetic only, no network.');
  } finally {await browser.close();}
})().catch(e=>{console.error(e);process.exitCode=1;});
