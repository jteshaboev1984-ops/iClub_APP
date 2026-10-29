'use strict';
// Isolated REAL Chromium DOM, synthetic RPC and blocked external network.
// Timed and full-paper answer ACK recovery must not alter scoring or deadline.
const assert=require('node:assert/strict');
const path=require('node:path');
const {chromium}=require('playwright');
const file=p=>path.resolve(p);
const AUTH='44444444-4444-4444-8444-444444444444';
const SESSION='55555555-5555-4555-8555-555555555555';
const ok=data=>({ok:true,data});

async function scenario(browser,language,width,component,sessionType,kind,mode,expired=false) {
  const page=await browser.newPage({viewport:{width,height:850},timezoneId:'Asia/Tashkent'});
  const errors=[];
  page.on('pageerror',e=>errors.push(e.message));
  await page.route(/^https?:\/\//,route=>route.abort());
  try {
    await page.setContent('<!doctype html><html><body><div id="exam-prep-host-root" aria-hidden="false"></div></body></html>');
    await page.evaluate(([language,component,sessionType,kind,mode,expired])=>{
      window.iClubExamPrepWeeklyFlowEnabled=false;
      window.iClubExamPrepProgressUxEnabled=false;
      window.i18n={getLang:()=>language};
      const s=window.__timedTest={
        language,component,sessionType,kind,mode,expired,
        answered:false,finalized:false,sendCount:0,finalizeCount:0,readCount:0,
        keys:[],payloads:[],elapsed:[],deadline:Date.now()+(expired?4500:120000)
      };
      const answerItem=()=>({
        item_order:1,item_kind:kind==='written'?'written':'question',
        qtype:kind==='written'?null:'mcq',
        text:kind==='written'?null:'Convert 90 degrees to radians.',
        written_prompt:kind==='written'?'Show your full calculation on paper.':null,
        options:kind==='written'?null:['pi/2','pi'],answered:s.answered
      });
      const wrap=data=>({ok:true,data:structuredClone(data)});
      const internal=window.iClubExamPrepHostInternal={
        lastCapabilities:{coreAccess:true,killSwitch:false,rolloutState:'controlled_beta'}
      };
      internal.api={
        examProfile:async()=>wrap({exam_series:'May/June 2027',target_grade:'A',
          total_student_hours_available:10,mathematics_hours_budget:5}),
        diagnosticProgress:async component=>wrap({component_code:component,stage0_complete:true,
          screening:{required_items:1,answered_items:1,required_areas:1,answered_areas:1}}),
        getState:async component=>wrap({components:[{component_code:component,operational_stage:4,coverage_pct:50}]}),
        syllabusTracker:async component=>wrap({component_code:component,
          denominator_count:component==='P1'?45:36,coverage_count:2,areas:[]}),
        correctionQueue:async()=>wrap({active_count:0,cases:[]}),
        weeklyPlan:async()=>wrap({plan_id:null,items:[]}),
        recentResults:async()=>wrap({results:[]}),
        timedCatalog:async()=>wrap({assessments:[{assessment_id:91,marks_available:20,time_limit_sec:600,title:'Fixture timed test'}]}),
        authorizeTimed:async()=>wrap({authorization_id:'44444444-4444-4444-8444-444444444444'}),
        startSession:async()=>wrap({session_id:'55555555-5555-4555-8555-555555555555'}),
        getSession:async id=>{
          s.readCount++;
          if(id!=='55555555-5555-4555-8555-555555555555')throw Error('Wrong session ID');
          return wrap({session_id:id,component_code:s.component,session_type:s.sessionType,
            status:s.finalized?'finalized':'active',
            timing_contract:{deadline_at:new Date(s.deadline).toISOString()},
            items:[answerItem()]});
        },
        submitResponse:async (id,order,payload,key,elapsedMs)=>{
          if(id!=='55555555-5555-4555-8555-555555555555'||order!==1)throw Error('Wrong submission identity');
          s.sendCount++;s.keys.push(key);s.payloads.push(structuredClone(payload));s.elapsed.push(elapsedMs);
          if(s.sendCount===1&&s.mode==='hung')return new Promise(()=>{});
          if(s.sendCount===1&&s.mode==='after_commit'){
            s.answered=true;throw Error('ACK lost after server write');
          }
          if(s.sendCount===1&&s.mode==='before_commit')throw Error('Offline before server write');
          s.answered=true;return wrap({accepted:true});
        },
        finalizeTimed:async(id,key,reason)=>{
          if(id!=='55555555-5555-4555-8555-555555555555')throw Error('Wrong timed finish ID');
          if(!s.answered)throw Error('False finalize before answer reconciliation');
          s.finalizeCount++;s.finalized=true;s.finalReason=reason;
          return wrap({status:'finalized'});
        },
        timedReviewPack:async()=>wrap({items:[]}),
        timedResult:async()=>wrap({marks_available:20,marks_in_time:10,marks_after_time:0,unattempted_marks:0,score_comparable:false})
      };
      window.iClubExamPrep={open:async()=>true,isOpen:()=>true,back:()=>true,close:()=>true,
        syncSubjectHub:async()=>true,refreshCapabilities:async()=>true};
      window.confirm=()=>true;
    },[language,component,sessionType,kind,mode,expired]);
    await page.addScriptTag({path:file('exam-prep/exam-prep-live.js')});
    await page.evaluate(language=>window.iClubExamPrep.open({language,subjectKey:'mathematics'}),language);
    await page.click('[data-ep-live-open-component="'+component+'"]');
    await page.click('[data-ep-component-link="timed"]');
    await page.click('[data-ep-live-timed-start="91"]');
    await page.waitForSelector('[data-ep-live-submit]');
    if(mode==='hung'||expired)await page.clock.install();
    const originalText='Detailed handwritten reasoning: x = pi / 2';
    if(kind==='written') await page.fill('textarea[name="ep_live_written_answer"]',originalText);
    else await page.check('input[name="ep_live_answer"][value="0"]');
    await page.click('[data-ep-live-submit]');
    if(mode==='hung')await page.clock.fastForward(16000);
    if(expired)await page.clock.fastForward(6500);
    if(mode==='after_commit') {
      await page.waitForFunction(()=>window.__timedTest.finalized);
      const s=await page.evaluate(()=>window.__timedTest);
      assert.equal(s.sendCount,1,'ACK after commit must not double-send');
      assert.equal(s.finalizeCount,1,'Timed finalization exactly once');
      assert(s.readCount>=2,'Authoritative response must be re-read');
    } else {
      await page.waitForSelector('[data-ep-answer-retry]');
      assert.equal(await page.locator('[data-ep-live-end]').isDisabled(),true,
        'Cannot finalize a timed paper with unknown answer outcome');
      assert.equal(await page.locator('[data-ep-live-submit]').isHidden(),true);
      const before=await page.evaluate(()=>window.__timedTest);
      assert.equal(before.finalizeCount,0,'No false timed finalization');
      assert.equal(before.sendCount,1,'No automatic second write');
      if(kind==='written') {
        assert.equal(await page.locator('textarea[name="ep_live_written_answer"]').inputValue(),originalText,
          'Written work must remain intact');
      } else assert.equal(await page.locator('input[name="ep_live_answer"][value="0"]').isChecked(),true,
        'MCQ selection must survive');
      await page.click('[data-ep-answer-check]');
      await page.waitForSelector('[data-ep-answer-retry]');
      assert.equal(await page.evaluate(()=>window.__timedTest.sendCount),1,'Read-only reconciliation only');
      await page.click('[data-ep-answer-retry]');
      await page.waitForFunction(()=>window.__timedTest.finalized);
      const s=await page.evaluate(()=>window.__timedTest);
      assert.equal(s.sendCount,2,'Exactly one explicit retry');
      assert.equal(s.finalizeCount,1,'Exactly one finalization');
      assert.equal(s.keys[0],s.keys[1],'Retry must reuse idempotency key');
      assert.deepEqual(s.payloads[0],s.payloads[1],'Retry must preserve submitted payload');
      assert.equal(s.elapsed[0],s.elapsed[1],'Retry must preserve original time spent');
    }
    assert.deepEqual(errors,[],'No browser runtime errors');
    console.log('PASS '+[language,width,component,sessionType,kind,mode,expired?'expired':'in_time'].join('/'));
  } finally {await page.close();}
}
(async()=>{
  const browser=await chromium.launch({headless:true});
  try {
    for(const language of ['ru','uz','en'])
      for(const component of ['P1','P5'])
      for(const width of [390,1280])
        for(const sessionType of ['timed','paper'])
          for(const kind of ['mcq','written'])
            for(const mode of ['before_commit','after_commit'])
              await scenario(browser,language,width,component,sessionType,kind,mode);
    for(const language of ['ru','uz','en'])
      for(const component of ['P1','P5'])
      for(const sessionType of ['timed','paper'])
        await scenario(browser,language,390,component,sessionType,'written','hung',true);
    console.log('GREEN: 96 lost-ACK and 12 hung-after-deadline Chromium scenarios. Synthetic RPC only, no real learner data.');
  } finally {await browser.close();}
})().catch(e=>{console.error(e);process.exitCode=1;});
