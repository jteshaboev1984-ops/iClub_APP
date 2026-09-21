'use strict';
// Two REAL Chromium tabs, one synthetic server state shared by Node. No live
// accounts, browser storage restoration, network calls, or Supabase writes.
const assert=require('node:assert/strict');
const path=require('node:path');
const {chromium}=require('playwright');
const PLAN='11111111-1111-4111-8111-111111111111';
const GOAL='22222222-2222-4222-8222-222222222222';
const SESSION='33333333-3333-4333-8333-333333333333';
const COPY={ru:'Это учебное повторение',uz:'Bu o‘quv takrori',en:'This is learning review'};
const texts=['Original question 1','Original question 2','Original question 3','Original written solution'];
const good=data=>({ok:true,data});
async function scenario(browser,language,width,loss) {
  const model={active:false,finalized:false,answered:[false,false,false,false],
    starts:0,normalStarts:0,generators:0,writtenSends:0,keys:[],payloads:[],finalizes:0,
    getSessionReads:0,componentWrites:[],profileWrites:0,planId:PLAN};
  const errors=[];
  const call=async(name,args={})=>{
    if(name==='profile') return good({exam_series:'May/June 2027',target_grade:'A',
      total_student_hours_available:10,mathematics_hours_budget:5});
    if(name==='diagnostic') return good({stage0_complete:true,
      screening:{required_items:1,answered_items:1,required_areas:1,answered_areas:1}});
    if(name==='state') return good({components:[{component_code:args.component,
      operational_stage:2,coverage_pct:0}]});
    if(name==='progress') return good({goals:args.component==='P5'?[{
      goal_id:GOAL,component_code:'P5',action_priority_order:model.finalized?null:1,
      status:model.finalized?'completed':'not_started'}]:[]});
    if(name==='plan') return good({plan_id:PLAN,active_week_no:1,items:args.component==='P5'?[{
      priority_order:1,item_type:'learning',status:model.finalized?'completed':'pending'}]:[]});
    if(name==='session') {
      model.getSessionReads++;
      if(args.id!==SESSION) throw Error('Wrong session identity');
      return good({session_id:SESSION,component_code:'P5',session_type:'learning',
        status:model.finalized?'finalized':'active',items:texts.map((text,index)=>({
          item_order:index+1,item_kind:index===3?'written':'objective',
          qtype:index===3?'written':'mcq',text,
          options:index===3?undefined:['Right','Wrong'],answered:model.answered[index]
        }))});
    }
    if(name==='submit') {
      assert.equal(args.id,SESSION);
      assert.equal(args.order>=1&&args.order<=4,true);
      if(args.order<4) {
        assert.equal(args.payload?.picked_index,0);
        assert.equal(model.answered[args.order-1],false);
        model.answered[args.order-1]=true;
        return good({is_correct:true});
      }
      model.writtenSends++;
      model.keys.push(args.key);
      model.payloads.push(structuredClone(args.payload));
      assert.equal(args.payload?.artifact?.text,'Original written working');
      if(model.writtenSends===1 && loss==='before_commit') throw Error('Written upload lost before commit');
      if(model.writtenSends===1 && loss==='after_commit') {
        model.answered[3]=true;
        throw Error('Written acknowledgment lost after commit');
      }
      assert.equal(model.answered[3],false);
      model.answered[3]=true;
      return good({is_correct:null});
    }
    if(name==='finalize') {
      assert.equal(args.id,SESSION);
      assert.ok(model.answered.every(Boolean));
      assert.equal(model.finalized,false,'No repeated finalization');
      model.finalized=true;model.active=false;model.finalizes++;
      return good({status:'finalized'});
    }
    if(name==='generate') {model.generators++;throw Error('Old generator prohibited');}
    if(name==='start_normal') {model.normalStarts++;throw Error('Fresh session prohibited');}
    const rpcOk=data=>({data,error:null});
    if(name==='get_exam_prep_active_plan_session_safe_v1') return rpcOk(model.active?{
      status:'resume',component_code:args.p_component_code,session_id:SESSION,
      learning_review:true,first_unanswered_item_order:model.answered.findIndex(v=>!v)+1
    }:{status:'none',component_code:args.p_component_code});
    if(name==='ensure_exam_prep_stable_weekly_plan_safe_v1') return rpcOk({
      contract_version:'stable_weekly_plan_v1',status:'existing',
      plan_id:PLAN,component_code:args.p_component_code,created:false});
    if(name==='authorize_exam_prep_goal_once_safe_v1') {
      assert.equal(args.p_component_code,'P5');assert.equal(args.p_goal_id,GOAL);
      assert.equal(args.p_plan_id,PLAN);
      return rpcOk({status:'review_ready',reason:'same_pack_learning_review',
        component_code:'P5',goal_id:GOAL,plan_id:PLAN,priority_order:1,
        item_type:'learning',fresh_assessment:false});
    }
    if(name==='start_exam_prep_learning_review_safe_v1') {
      assert.equal(args.p_component_code,'P5');assert.equal(args.p_goal_id,GOAL);
      assert.equal(args.p_plan_id,PLAN);
      if(model.active) return rpcOk({status:'resume_existing_session_first',session_id:SESSION});
      assert.equal(model.finalized,false);
      model.active=true;model.starts++;
      return rpcOk({status:'started',session_id:SESSION,component_code:'P5',goal_id:GOAL,
        plan_id:PLAN,repeat_learning:true,academic_credit:false,
        prior_progress_retained:true,not_a_new_independent_check:true});
    }
    model.normalStarts++;throw Error(`Unexpected RPC ${name}`);
  };
  async function attach() {
    const page=await browser.newPage({viewport:{width,height:850}});
    page.on('pageerror',e=>errors.push(e.message));
    await page.route(/^https?:\/\//,route=>route.abort());
    await page.exposeFunction('__fixtureCall',call);
    await page.setContent(`<!doctype html><html lang="${language}"><body><div id="exam-prep-host-root" aria-hidden="false"></div></body></html>`);
    await page.addStyleTag({path:path.resolve('exam-prep/exam-prep-host.css')});
    await page.evaluate(lang=>{
      window.iClubExamPrepWeeklyFlowEnabled=true;
      window.i18n={getLang:()=>lang};
      const request=(name,args)=>window.__fixtureCall(name,args);
      window.sb={rpc:(name,args)=>request(name,args)};
      window.iClubExamPrepHostInternal={
        lastCapabilities:{coreAccess:true,killSwitch:false,rolloutState:'controlled_beta'},
        progressUxApi:{progress:component=>request('progress',{component})},
        api:{examProfile:()=>request('profile'),diagnosticProgress:()=>request('diagnostic'),
          getState:component=>request('state',{component}),
          weeklyPlan:component=>request('plan',{component}),
          getSession:(id)=>request('session',{id}),
          submitResponse:(id,order,payload,key)=>request('submit',{id,order,payload,key}),
          finalizeSession:id=>request('finalize',{id}),
          generateWeeklyPlan:()=>request('generate'),
          authorizePlanItem:()=>request('start_normal'),startSession:()=>request('start_normal')}
      };
      window.iClubExamPrep={open:async()=>true,isOpen:()=>true,close:()=>true,
        back:()=>true,syncSubjectHub:async()=>true,refreshCapabilities:async()=>true};
    },language);
    for(const script of ['exam-prep/exam-prep-weekly-flow-adapter.js',
      'exam-prep/exam-prep-weekly-review-ui.js','exam-prep/exam-prep-live.js'])
      await page.addScriptTag({path:path.resolve(script)});
    await page.evaluate(lang=>window.iClubExamPrep.open({language:lang}),language);
    await page.waitForSelector('[data-ep-live-plan="P5"]');
    return page;
  }
  let first,second;
  try {
    first=await attach();
    await first.click('[data-ep-live-plan="P5"]');
    await first.waitForSelector('[data-ep-live-plan-item="1"]');
    await first.click('[data-ep-live-plan-item="1"]');
    await first.waitForSelector('.ep-live-qtext');
    assert.equal(await first.locator('.ep-live-qtext').innerText(),texts[0]);
    assert.equal(model.starts,1);
    second=await attach();
    await second.click('[data-ep-live-plan="P5"]');
    await second.waitForSelector('.ep-live-qtext');
    assert.equal(await second.locator('.ep-live-qtext').innerText(),texts[0]);
    assert.equal(model.starts,1,'Cold second device resumed, never started review twice');
    assert.ok((await second.locator('[data-ep-learning-review-note]').innerText()).includes(COPY[language]));
    await first.check('input[name="ep_live_answer"][value="0"]');
    await first.click('[data-ep-live-submit]');
    await first.waitForFunction(()=>document.querySelector('.ep-live-qtext')?.textContent==='Original question 2');
    // Second tab's screen is stale: its back/resume action must reload server
    // evidence rather than reopening the already answered original first item.
    await second.click('[data-ep-live-exit]');
    await second.waitForFunction(()=>document.querySelector('.ep-live-qtext')?.textContent==='Original question 2');
    for(let i=1;i<3;i++) {
      assert.equal(await second.locator('.ep-live-qtext').innerText(),texts[i]);
      assert.ok((await second.locator('[data-ep-learning-review-note]').innerText()).includes(COPY[language]));
      await second.check('input[name="ep_live_answer"][value="0"]');
      await second.click('[data-ep-live-submit]');
      await second.waitForFunction(next=>document.querySelector('.ep-live-qtext')?.textContent===next,texts[i+1]);
    }
    await second.fill('textarea[name="ep_live_written_answer"]','Original written working');
    await second.click('[data-ep-live-submit]');
    if(loss==='before_commit') {
      await second.waitForSelector('[data-ep-answer-retry]');
      assert.equal(await second.locator('textarea[name="ep_live_written_answer"]').inputValue(),'Original written working');
      assert.equal(model.writtenSends,1,'No automatic replay of uncertain write');
      await second.click('[data-ep-answer-check]');
      await second.waitForSelector('[data-ep-answer-retry]');
      assert.equal(model.writtenSends,1,'Status check must stay read-only');
      await second.click('[data-ep-answer-retry]');
    }
    await second.waitForFunction(()=>document.querySelector('[data-ep-live-plan-item]')===null);
    assert.equal(model.finalized,true);
    assert.equal(model.starts,1);
    assert.equal(model.finalizes,1);
    assert.equal(model.writtenSends,loss==='before_commit'?2:1);
    if(loss==='before_commit') {
      assert.equal(model.keys[0],model.keys[1]);
      assert.deepEqual(model.payloads[0],model.payloads[1]);
    }
    assert.equal(model.generators,0);
    assert.equal(model.normalStarts,0);
    assert.equal(model.planId,PLAN);
    assert.deepEqual(model.answered,[true,true,true,true]);
    // An old first-tab view must reconcile to the same FINALIZED server state.
    await first.click('[data-ep-live-exit]');
    await first.waitForSelector('.ep-live-card [data-ep-live-dashboard]');
    assert.equal(model.starts,1);
    assert.deepEqual(errors,[]);
    console.log(`PASS two tabs ${language} ${width}px ${loss}: one review, written recovery, unchanged plan`);
  } finally {if(first)await first.close();if(second)await second.close();}
}
(async()=>{
  const browser=await chromium.launch({headless:true});
  try {for(const language of ['ru','uz','en']) for(const width of [390,1280])
    await scenario(browser,language,width,width===390?'before_commit':'after_commit');
    console.log('GREEN: six two-tab review journeys, synthetic shared server, no external network.');
  } finally {await browser.close();}
})().catch(e=>{console.error(e);process.exitCode=1;});