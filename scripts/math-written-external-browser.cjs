'use strict';
// No external network, production account, or Supabase write. Genuine Chromium UI.
// Contract: paper-based written step is progression-only (no artifact/checks/marks).
const assert=require('node:assert/strict');
const path=require('node:path');
const {chromium}=require('playwright');
const file=name=>path.resolve(name);
const PLAN='11111111-1111-4111-8111-111111111111';
const GOAL='33333333-3333-4333-8333-333333333333';
const AUTH='55555555-5555-4555-8555-555555555555';
const SESSION='66666666-6666-4666-8666-666666666666';
const ok=data=>({ok:true,data:structuredClone(data)});

async function scenario(browser,language,component,width,mode) {
  const page=await browser.newPage({viewport:{width,height:860}});
  const errors=[];page.on('pageerror',e=>errors.push(e.message));
  await page.route(/^https?:\/\//,route=>route.abort());
  try {
    await page.setContent('<!doctype html><html lang="'+language+'"><head><meta name="viewport" content="width=device-width,initial-scale=1"></head>'+
      '<body><div id="exam-prep-host-root" aria-hidden="false"></div></body></html>');
    await page.addStyleTag({path:file('exam-prep/exam-prep-host.css')});
    await page.evaluate(([lang,comp,mode,planId,goalId,authId,sessionId])=>{
      const ok=data=>({ok:true,data:structuredClone(data)});
      const assert=Object.assign(condition=>{if(!condition)throw Error('mock assertion failed');},
        {equal:(a,b)=>{if(a!==b)throw Error('mock expected '+b+' got '+a);}});
      window.iClubExamPrepWeeklyFlowEnabled=true;
      window.iClubExamPrepProgressUxEnabled=false;
      window.i18n={getLang:()=>lang};
      const s=window.__paperTest={mode,comp,lang,planId,goalId,authId,sessionId,
        advanced:false,finalized:false,rolloutOff:false,sendCount:0,readCount:0,keys:[],criteriaCount:0,gradeWrites:0};
      const item=()=>({
        item_order:4,item_kind:'written',written_external:!s.rolloutOff,
        completion_status:s.advanced?'advanced_in_plan_only':'open',
        is_complete:s.advanced,answered:false,
        written_prompt:'Find the derivative and show your method.',
        understanding_checks:[{check_order:1,prompt:'Legacy check must never mount'}]
      });
      const get=()=>({
        session_id:s.sessionId,component_code:s.comp,session_type:'learning',
        status:s.finalized?'finalized':'active',total_items:4,
        items:[
          {item_order:1,item_kind:'question',answered:true,is_complete:true},
          {item_order:2,item_kind:'question',answered:true,is_complete:true},
          {item_order:3,item_kind:'question',answered:true,is_complete:true},
          item()
        ]
      });
      const internal=window.iClubExamPrepHostInternal={
        lastCapabilities:{coreAccess:true,killSwitch:false,rolloutState:'controlled_beta'}};
      internal.api={
        examProfile:async()=>ok({exam_series:'May/June 2027',target_grade:'A',
          total_student_hours_available:10,mathematics_hours_budget:5}),
        diagnosticProgress:async()=>ok({stage0_complete:true,screening:{
          required_items:1,answered_items:1,required_areas:1,answered_areas:1}}),
        getState:async comp=>ok({components:[{component_code:comp,operational_stage:2,coverage_pct:0}]}),
        weeklyPlan:async()=>ok({plan_id:s.planId,active_week_no:1,items:[
          {priority_order:1,item_type:'learning',status:s.finalized?'completed':'pending'}]}),
        getSessionWritten:async id=>{assert.equal(id,s.sessionId);return ok(get());},
        getSession:async id=>{assert.equal(id,s.sessionId);return ok(get());},
        writtenCriteria:async(id,order)=>{
          assert.equal(id,s.sessionId);assert.equal(order,4);s.criteriaCount++;
          if(s.mode==='criteria_pending')return ok({available:false,item_order:4,reason:'localization_pending'});
          return ok({available:true,item_order:4,requirements:['Use the power rule.','Show all terms.']});
        },
        advanceWrittenStep:async(id,order,key)=>{
          assert.equal(id,s.sessionId);assert.equal(order,4);assert.equal(typeof key,'string');
          s.sendCount++;s.keys.push(key);
          if(s.sendCount===1 && s.mode==='before_commit')throw Error('Lost request before commit');
          if(s.sendCount===1 && s.mode==='off_before_commit'){
            s.rolloutOff=true;throw Error('Emergency rollout disabled before commit');
          }
          if(s.sendCount===1 && s.mode==='after_commit'){
            s.advanced=true;throw Error('Lost response after commit');
          }
          if(s.sendCount===1 && s.mode==='hung')return new Promise(()=>{});
          s.advanced=true;return ok({session_id:id,item_order:order,status:'advanced',replayed:s.sendCount>1});
        },
        writtenStepStatus:async(id,order)=>{
          assert.equal(id,s.sessionId);assert.equal(order,4);s.readCount++;
          return ok({session_id:id,item_order:order,component_code:s.comp,
            status:s.advanced?'advanced':'open',session_status:'active',can_advance:!s.rolloutOff});
        },
        finalizeSessionWritten:async()=>{
          assert(s.advanced);s.finalized=true;
          return ok({session_id:s.sessionId,status:'finalized'});
        },
        sessionReview:async()=>ok({session_id:s.sessionId,component_code:s.comp,session_type:'learning',status:'finalized',
          summary:{machine_total:3,machine_correct:2,written_total:0,written_completed:0},items:[]}),
        sessionReviewWritten:async()=>ok({session_id:s.sessionId,component_code:s.comp,
          session_type:'learning',status:'finalized',
          summary:{machine_total:3,machine_correct:2,machine_accuracy_pct:66.7,
            written_total:1,written_completed:1,written_advanced:1,written_submitted:0},
          items:[{item_order:4,item_kind:'written',text:'Find derivative',
            completion_status:'advanced_in_plan_only',learner_artifact:null}]}),
        generateWeeklyPlan:async()=>ok({})
      };
      internal.progressUxApi={progress:async()=>ok({goals:[{
        goal_id:s.goalId,component_code:s.comp,item_type:'learning',
        skill_code:s.comp+'-CALC-01',status:'not_started',
        weekly_commitment_complete:false,action_priority_order:1}]})};
      internal.weeklyFlowApi={
        version:'weekly_flow_adapter_v1',
        allowed:()=>null,
        plan:async()=>ok({status:'existing',plan_id:s.planId}),
        authorize:async(comp,goal,plan)=>{
          assert.equal(comp,s.comp);assert.equal(goal,s.goalId);assert.equal(plan,s.planId);
          return ok({status:'authorized',authorization_id:s.authId});
        },
        start:async()=>ok({status:'started',session_id:s.sessionId})
      };
      window.iClubExamPrep={open:async()=>true,isOpen:()=>true,back:()=>true,
        close:()=>true,syncSubjectHub:async()=>true,refreshCapabilities:async()=>true};
    },[language,component,mode,PLAN,GOAL,AUTH,SESSION]);
    await page.addScriptTag({path:file('exam-prep/exam-prep-live.js')});
    await page.addScriptTag({path:file('exam-prep/exam-prep-written-understanding-ui.js')});
    // Load the actual reconciled polish6 handler together with the paper flow.
    await page.addScriptTag({path:file('exam-prep/exam-prep-interaction-polish.js')});
    await page.evaluate(lang=>window.iClubExamPrep.open({language:lang}),language);
    await page.evaluate(c=>document.querySelector('[data-ep-live-plan="'+c+'"]').click(),component);
    await page.click('[data-ep-live-plan-item="1"]');
    try {
      await page.waitForSelector('[data-ep-written-next]',{timeout:5000});
    } catch(err) {
      const snap=await page.evaluate(()=>({html:document.querySelector('#exam-prep-host-root')?.innerHTML.slice(0,3200),
        mock:window.__paperTest,api:Object.keys(window.iClubExamPrepHostInternal?.api||{})}));
      console.error('WRITTEN SCREEN DIAGNOSTIC',language,component,mode,JSON.stringify(snap),errors);
      throw err;
    }
    assert.equal(await page.locator('textarea[name="ep_live_written_answer"]').count(),0,'no text input');
    assert.equal(await page.locator('[data-ep-written-understanding]').count(),0,'no understanding gate');
    assert.equal(await page.locator('[data-ep-live-submit]').count(),0,'no legacy save');
    assert.equal(await page.locator('[data-ep-written-criteria-toggle]').count(),1);
    assert.equal(await page.evaluate(()=>window.iClubExamPrepHostInternal?.interactionPolish?.version),'polish6');
    if(mode==='ok') {
      await page.click('[data-ep-written-criteria-toggle]');
      await page.waitForFunction(()=>document.querySelector('[data-ep-written-criteria-panel]')?.textContent?.includes('power rule'));
      assert.equal(await page.evaluate(()=>window.__paperTest.criteriaCount),1);
    }
    if(mode==='criteria_pending') {
      await page.click('[data-ep-written-criteria-toggle]');
      const phrase=language==='ru'?'ещё не утверждён':'hali tasdiqlanmagan';
      await page.waitForFunction(phrase=>document.querySelector('[data-ep-written-criteria-panel]')?.textContent?.includes(phrase),phrase);
      assert.equal(await page.evaluate(()=>window.__paperTest.criteriaCount),1);
      assert.equal(await page.locator('[data-ep-written-next]').isEnabled(),true);
    }
    if(mode==='hung')await page.clock.install();
    await page.click('[data-ep-written-next]');
    if(mode==='hung')await page.clock.fastForward(16000);
    if(mode==='before_commit'||mode==='hung'){
      await page.waitForSelector('[data-ep-written-recovery] button');
      assert.equal(await page.evaluate(()=>window.__paperTest.sendCount),1);
      await page.getByRole('button',{name:/Повторить переход|O‘tishni qayta yuborish|Retry transition/}).click();
    }
    if(mode==='off_before_commit'){
      await page.waitForSelector('textarea[name="ep_live_written_answer"]',{timeout:5000});
      const state=await page.evaluate(()=>window.__paperTest);
      assert.equal(state.sendCount,1,'must not retry when rollout has been disabled');
      assert.equal(state.advanced,false,'no fictitious written step on emergency OFF');
      assert.equal(state.gradeWrites,0,'no marks or mastery on emergency OFF');
      assert(state.readCount>=1,'must reconcile before fallback');
      assert(!errors.length,language+'/'+component+'/'+mode+' '+JSON.stringify(errors));
      console.log('PASS '+language+' '+component+' '+width+'px '+mode);
      return;
    }
    try {await page.waitForFunction(()=>window.__paperTest.finalized,{timeout:7000});}
    catch(err) {
      console.error('WRITTEN FINALIZE DIAGNOSTIC',language,component,mode,
        await page.evaluate(()=>({html:document.querySelector('#exam-prep-host-root')?.innerHTML.slice(0,2400),
          s:window.__paperTest})),errors);
      throw err;
    }
    await page.waitForSelector('[data-ep-session-result]');
    const s=await page.evaluate(()=>window.__paperTest);
    assert.equal(s.gradeWrites,0,'paper navigation must never grade');
    assert.equal(s.sendCount,mode==='ok'||mode==='after_commit'||mode==='criteria_pending'?1:2,'no silent replay');
    if(s.sendCount===2)assert.equal(s.keys[0],s.keys[1],'same idempotency key');
    if(mode==='after_commit')assert(s.readCount>=1,'ACK reconciliation must read status');
    assert(!errors.length,language+'/'+component+'/'+mode+' '+JSON.stringify(errors));
    console.log('PASS '+language+' '+component+' '+width+'px '+mode);
  } finally {await page.close();}
}
(async()=>{
  const browser=await chromium.launch({headless:true});
  try {
    for(const language of ['ru','uz','en'])
      for(const component of ['P1','P5'])
        for(const width of [390,1280]){
          for(const mode of ['ok','after_commit','before_commit','hung','off_before_commit'])
            await scenario(browser,language,component,width,mode);
          if(language!=='en')await scenario(browser,language,component,width,'criteria_pending');
        }
    console.log('GREEN: 68 synthetic written external DOM cases; no external network or DB.');
  } finally {await browser.close();}
})().catch(e=>{console.error(e);process.exitCode=1;});
