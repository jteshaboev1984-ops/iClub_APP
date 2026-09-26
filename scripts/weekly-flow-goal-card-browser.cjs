'use strict';
// Actual native + Progress UI + guarded adapter. Entire browser is isolated and
// all network requests are blocked. No production learner or database access.
const assert = require('node:assert/strict');
const path = require('node:path');
const { chromium } = require('playwright');
const source = name => path.resolve(name);
const PLAN = '11111111-1111-4111-8111-111111111111';
const GOAL_A = '33333333-3333-4333-8333-333333333333';
const GOAL_B = '44444444-4444-4444-8444-444444444444';
const AUTH = '55555555-5555-4555-8555-555555555555';
const SESSION = '66666666-6666-4666-8666-666666666666';
(async () => {
  const browser = await chromium.launch({headless:true});
  try {
    for(const language of ['ru','uz','en']) for(const width of [390,1280]) {
      const page = await browser.newPage({viewport:{width,height:840}});
      const errors=[];
      page.on('pageerror',e=>errors.push(e.message));
      await page.route(/^https?:\/\//,r=>r.abort());
      await page.setContent(`<!doctype html><html lang="${language}"><head><meta name="viewport" content="width=device-width,initial-scale=1"></head><body><div id="exam-prep-host-root" aria-hidden="false"></div></body></html>`);
      for(const css of ['exam-prep/exam-prep-host.css','exam-prep/exam-prep-progress-ux.css'])
        await page.addStyleTag({path:source(css)});
      await page.evaluate(([lang,planId,goalA,goalB,authId,sessionId])=>{
        window.iClubExamPrepWeeklyFlowEnabled=true;
        window.iClubExamPrepProgressUxEnabled=true;
        window.i18n={getLang:()=>lang};
        const s=window.__goalTest={planId,answered:false,active:false,finalized:false,auth:[],starts:0,generated:0,actions:[]};
        const ok=data=>({data:structuredClone(data),error:null});
        const fail=message=>({data:null,error:{message}});
        window.iClubExamPrepHostInternal={lastCapabilities:{coreAccess:true,killSwitch:false,rolloutState:'controlled_beta'}};
        window.iClubExamPrep={open:async()=>true,isOpen:()=>true,back:()=>true,close:()=>true,syncSubjectHub:async()=>true,refreshCapabilities:async()=>true};
        const goal=(id,ordinal,priority,skill)=>({goal_id:id,component_code:'P1',priority_order:ordinal,
          item_type:'learning',skill_code:skill,status:s.finalized&&ordinal===1?'completed':'not_started',
          weekly_commitment_complete:s.finalized&&ordinal===1,correction_open:false,
          finalized_sessions:s.finalized&&ordinal===1?1:0,action_priority_order:s.finalized&&ordinal===1?null:priority,
          retest_due_at:null,plan_changed:false});
        window.sb={rpc:async(name,args={})=>{
          const comp=args.p_component_code;
          switch(name){
            case 'get_exam_prep_exam_profile_v1':return ok({exam_series:'May/June 2027',target_grade:'A',total_student_hours_available:10,mathematics_hours_budget:5});
            case 'get_exam_prep_diagnostic_progress_safe_v1':return ok({stage0_complete:true,screening:{required_items:2,answered_items:2,required_areas:1,answered_areas:1}});
            case 'get_exam_prep_state_safe_v1':return ok({components:[{component_code:comp,operational_stage:2,coverage_pct:0}]});
            case 'get_exam_prep_active_plan_session_safe_v1':return ok(s.active?{status:'resume',session_id:sessionId,component_code:'P1'}:{status:'none',component_code:comp});
            case 'ensure_exam_prep_balanced_weekly_plan_safe_v1':return ok({contract_version:'stable_weekly_plan_v1',status:'existing',plan_id:planId,component_code:comp});
            case 'get_exam_prep_weekly_plan_safe_v2':return ok({plan_id:planId,active_week_no:1,items:[
              {priority_order:1,item_type:'learning',skill_code:'P1-COO-02',status:'pending'},
              {priority_order:2,item_type:'learning',skill_code:'P1-CIR-01',status:s.finalized?'completed':'pending'}]});
            case 'ensure_exam_prep_weekly_goals_safe_v1':return ok({contract_version:'progress_ux_v1',component_code:comp,active_week_no:1,plan_available:true,created:0});
            case 'get_exam_prep_weekly_progress_safe_v1':return ok({contract_version:'progress_ux_v1',component_code:comp,active_week_no:1,
              plan_available:true,finalized_study_sessions:s.finalized?1:0,open_corrections:0,
              confirmed_skills:0,coverage_pct:0,completed_goals:s.finalized?1:0,
              goals:[goal(goalA,1,2,'P1-CIR-01'),goal(goalB,2,1,'P1-COO-02')]});
            case 'get_exam_prep_syllabus_tracker_safe_v1':return ok({component_code:comp,areas:[
              {official_syllabus_section:'1.4 Circular measure',skills:[{skill_code:'P1-CIR-01',sequence_no:1,description:'Radians'}]},
              {official_syllabus_section:'1.3 Coordinate geometry',skills:[{skill_code:'P1-COO-02',sequence_no:2,description:'Coordinates'}]}]});
            case 'get_exam_prep_goal_action_state_safe_v1':{
              const priority=args.p_goal_id===goalA?2:1;
              s.actions.push({goalId:args.p_goal_id,priority});
              return ok({status:'ready',goal_id:args.p_goal_id,plan_id:planId,component_code:comp,priority_order:priority});
            }
            case 'authorize_exam_prep_goal_once_safe_v1':
              s.auth.push({goalId:args.p_goal_id,planId:args.p_plan_id});
              return args.p_goal_id===goalA&&!s.finalized?ok({status:'authorized',authorization_id:authId}):ok({status:'stale'});
            case 'start_exam_prep_plan_session_once_safe_v1':
              s.starts++;s.active=true;return ok({status:'started',session_id:sessionId,component_code:'P1'});
            case 'get_exam_prep_session_safe_v1':return ok({session_id:sessionId,component_code:'P1',session_type:'learning',status:s.finalized?'finalized':'active',
              items:[{item_order:1,item_kind:'objective',qtype:'mcq',text:'Convert 90° to radians.',options:['π / 2','π'],answered:s.answered}]});
            case 'submit_exam_prep_response_safe_v1':s.answered=true;return ok({is_correct:true});
            case 'finalize_exam_prep_session_safe_v1':s.finalized=true;s.active=false;return ok({status:'finalized'});
            case 'generate_exam_prep_weekly_plan_safe_v3':s.generated++;return fail('legacy generator blocked');
            case 'authorize_exam_prep_plan_item_safe_v1':return fail('legacy authorization blocked');
            case 'start_exam_prep_session_safe_v1':return fail('legacy starter blocked');
            default:return fail(`unexpected RPC: ${name}`);
          }
        }};
      },[language,PLAN,GOAL_A,GOAL_B,AUTH,SESSION]);
      for(const js of ['exam-prep/exam-prep-api.js','exam-prep/exam-prep-weekly-flow-adapter.js',
        'exam-prep/exam-prep-live.js','exam-prep/exam-prep-progress-ux-model.js',
        'exam-prep/exam-prep-progress-ux-api.js','exam-prep/exam-prep-progress-ux-ui.js'])
        await page.addScriptTag({path:source(js)});
      await page.evaluate(lang=>window.iClubExamPrep.open({language:lang}),language);
      await page.waitForSelector('[data-ep-live-plan="P1"]', { state: 'attached' });
      await page.evaluate(() => document.querySelector('[data-ep-live-plan="P1"]').click());
      await page.waitForFunction(()=>document.querySelector('.ep-pux-week')?.dataset.epPuxPrimaryGoals==='verified');
      assert.equal(await page.locator('[data-ep-pux-goal-action]').count(),2,`${language}/${width}: one CTA per available goal`);
      assert.equal(await page.locator('.ep-live-plan-item:visible').count(),0,`${language}/${width}: duplicate native tasks remain visible`);
      assert.equal(await page.locator('.ep-pux-goal').count(),2);
      await page.click(`[data-ep-pux-goal-action="${GOAL_A}"]`);
      await page.waitForSelector('.ep-live-qtext');
      assert.equal(await page.locator('.ep-live-qtext').innerText(),'Convert 90° to radians.');
      const pre=await page.evaluate(()=>window.__goalTest);
      assert.deepEqual(pre.auth,[{goalId:GOAL_A,planId:PLAN}],`${language}/${width}: frozen goal identity was confused with priority`);
      assert.equal(pre.starts,1);
      await page.check('input[name="ep_live_answer"][value="0"]');
      await page.click('[data-ep-live-submit]');
      await page.waitForFunction(()=>window.__goalTest.finalized);
      await page.waitForFunction(()=>document.querySelector('.ep-pux-week')?.dataset.epPuxPrimaryGoals==='verified');
      assert.equal(await page.locator('.ep-live-plan-item:visible').count(),0);
      assert.equal(await page.locator('[data-ep-pux-goal-action]').count(),1,`${language}/${width}: completed goal incorrectly offers restart`);
      const after=await page.evaluate(()=>window.__goalTest);
      assert.equal(after.generated,0);
      assert.equal(after.starts,1);
      assert.deepEqual(errors,[],`${language}/${width}: browser errors`);
      console.log(`PASS goal-only UI ${language}/${width}: correct identity, single CTA, no duplicates, saved completion, no replan`);
      await page.close();
    }
    console.log('GREEN genuine RU/UZ/EN mobile+desktop goal-only UI, synthetic network blocked.');
  } finally {await browser.close();}
})().catch(err=>{console.error(err);process.exitCode=1;});
