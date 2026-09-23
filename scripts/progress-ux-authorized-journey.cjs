'use strict';
// Isolated browser acceptance. Real project API, learner renderers and Progress UX;
// a deterministic in-page RPC fake replaces Supabase. No live accounts or network.
const assert = require('node:assert/strict');
const path = require('node:path');
const { chromium } = require('playwright');
const file = name => path.resolve(name);
const html = lang => `<!doctype html><html lang="${lang}"><head><meta name="viewport" content="width=device-width,initial-scale=1"></head><body><main id="courses-subject-hub" class="exam-prep-host-open"><div id="exam-prep-host-root" aria-hidden="false"></div></main></body></html>`;

(async () => {
  const browser = await chromium.launch({headless:true});
  try {
    for (const language of ['ru','uz','en']) {
      const page = await browser.newPage({viewport:{width:390,height:844}});
      const errors=[];
      page.on('pageerror',error=>errors.push(error.message));
      await page.route(/^https?:\/\//, route=>route.abort());
      await page.setContent(html(language));
      for (const css of ['style.css','exam-prep/exam-prep-host.css','exam-prep/exam-prep-wave1-ux.css','exam-prep/exam-prep-progress-ux.css'])
        await page.addStyleTag({path:file(css)});
      await page.evaluate(lang=>{
        window.iClubExamPrepProgressUxEnabled=true;
        window.i18n={getLang:()=>lang};
        window.__journey={answered:false,finalized:false,version:1,authorizations:[],started:[],finalizations:[],snapshots:[],calls:[],p5Count:2};
        const state=window.__journey;
        const goal=(index,component='P1')=>({
          goal_id:`synthetic-${component}-${index}`,component_code:component,priority_order:index,
          item_type:'learning',skill_code:component==='P1'?(index===1?'P1-CIR-01':index===2?'P1-COO-02':'P1-TRI-01'):'P5-DAT-01',
          status:component==='P1'&&index===1&&state.finalized?'completed':'not_started',
          weekly_commitment_complete:component==='P1'&&index===1&&state.finalized,
          correction_open:false,finalized_sessions:component==='P1'&&index===1&&state.finalized?1:0,
          action_priority_order:component==='P1'?(state.finalized?(index===2?1:null):(index===1?1:null)):1,
          retest_due_at:null,plan_changed:false
        });
        const plan=component=>component==='P5'?{
          plan_id:'synthetic-p5-v1',active_week_no:1,
          items:[{priority_order:1,item_type:'learning',skill_code:'P5-DAT-01',status:'pending'}]
        }:{
          plan_id:`synthetic-p1-v${state.version}`,active_week_no:1,
          items:[{priority_order:1,item_type:'learning',skill_code:state.finalized?'P1-COO-02':'P1-CIR-01',status:'pending'}]
        };
        const progress=component=>({
          contract_version:'progress_ux_v1',component_code:component,active_week_no:1,plan_available:true,
          completed_goals:component==='P1'&&state.finalized?1:0,
          finalized_study_sessions:component==='P1'?(state.finalized?6:5):state.p5Count,
          open_corrections:0,confirmed_skills:component==='P1'?(state.finalized?3:2):1,
          coverage_pct:component==='P1'?(state.finalized?7:5):3,
          goals:component==='P1'?[goal(1),goal(2),goal(3)]:[goal(1,'P5')]
        });
        const tracker=component=>({component_code:component,areas:(component==='P1'?
          [['1.4 Circular measure','P1-CIR-01','Переводить degrees ↔ radians и использовать radians как естественную угловую меру.'],
           ['1.3 Coordinate geometry','P1-COO-02','Использовать формы уравнения прямой, distance, midpoint, gradient и intersection.'],
           ['1.5 Trigonometry','P1-TRI-01','Строить и использовать graphs of sin, cos и tan, включая simple transformations.']]:
          [['5.1 Representation of data','P5-DAT-01','Выбирать и критиковать подходящее data representation с учётом типа данных и цели.']]
        ).map(([section,code,description],i)=>({official_syllabus_section:section,
          skills:[{skill_code:code,description,sequence_no:i+1}]}))});
        window.iClubExamPrepHostInternal={lastCapabilities:{coreAccess:true,killSwitch:false,rolloutState:'controlled_beta'}};
        window.iClubExamPrep={open:async()=>true,isOpen:()=>true,back:()=>true,close:()=>true,
          syncSubjectHub:async()=>true,refreshCapabilities:async()=>true};
        window.sb={rpc:async(name,args={})=>{
          state.calls.push({name,args});
          const component=args.p_component_code;
          const ok=data=>({data:structuredClone(data),error:null});
          switch(name){
          case 'get_exam_prep_exam_profile_v1':return ok({exam_series:'May/June 2027',target_grade:'A',total_student_hours_available:10,mathematics_hours_budget:5});
          case 'get_exam_prep_diagnostic_progress_safe_v1':return ok({stage0_complete:true,screening:{required_items:2,answered_items:2,required_areas:1,answered_areas:1}});
          case 'get_exam_prep_state_safe_v1':return ok({components:[{component_code:component,operational_stage:2,coverage_pct:component==='P1'?7:3}]});
          case 'get_exam_prep_weekly_plan_safe_v2':return ok(plan(component));
          case 'get_exam_prep_syllabus_tracker_safe_v1':return ok(tracker(component));
          case 'ensure_exam_prep_weekly_goals_safe_v1':state.snapshots.push(component);return ok({contract_version:'progress_ux_v1',component_code:component,active_week_no:1,plan_available:true,created:0});
          case 'get_exam_prep_weekly_progress_safe_v1':return ok(progress(component));
          case 'authorize_exam_prep_plan_item_safe_v1':{
            state.authorizations.push({planId:args.p_plan_id,priority:args.p_priority_order});
            if(args.p_plan_id!=='synthetic-p1-v1'||args.p_priority_order!==1||state.finalized)
              return {data:null,error:{message:'stale plan denied'}};
            return ok({authorization_id:'synthetic-auth-p1'});
          }
          case 'start_exam_prep_session_safe_v1':
            if(args.p_authorization_id!=='synthetic-auth-p1')return {data:null,error:{message:'unauthorized'}};
            state.started.push(args.p_authorization_id);return ok({session_id:'synthetic-session-1'});
          case 'get_exam_prep_session_safe_v1':return ok({session_id:'synthetic-session-1',session_type:'learning',component_code:'P1',status:state.finalized?'finalized':'active',items:[{item_order:1,item_kind:'objective',qtype:'mcq',options:['π / 2','π'],text:'Convert 90° to radians.',answered:state.answered}]});
          case 'submit_exam_prep_response_safe_v1':
            if(args.p_session_id!=='synthetic-session-1'||args.p_item_order!==1||args.p_payload?.picked_index!==0)
              return {data:null,error:{message:'incorrect test payload'}};
            state.answered=true;return ok({is_correct:true});
          case 'finalize_exam_prep_session_safe_v1':
            if(!state.answered)return {data:null,error:{message:'unanswered session'}};
            state.finalizations.push(args.p_session_id);state.finalized=true;return ok({status:'finalized'});
          case 'generate_exam_prep_weekly_plan_safe_v3':
            if(component!=='P1'||!state.finalized)return {data:null,error:{message:'invalid generator order'}};
            state.version=2;return ok({plan_id:'synthetic-p1-v2'});
          case 'get_exam_prep_correction_queue_safe_v1':return ok({cases:[],recent_resolved:[]});
          default:return {data:null,error:{message:`unexpected RPC: ${name}`}};
          }
        }};
      },language);
      // Load actual RPC adapter before real renderer and its existing learner-flow UX.
      for(const script of ['exam-prep/exam-prep-api.js','exam-prep/exam-prep-live.js',
        'exam-prep/exam-prep-learner-flow-ux.js','exam-prep/exam-prep-progress-ux-model.js',
        'exam-prep/exam-prep-progress-ux-api.js','exam-prep/exam-prep-progress-ux-ui.js'])
        await page.addScriptTag({path:file(script)});
      await page.evaluate(lang=>window.iClubExamPrep.open({language:lang}),language);
      await page.waitForFunction(()=>document.querySelectorAll('.ep-pux-overview').length===2);
      assert.equal(await page.locator('.ep-pux-overview').count(),2,`${language}: separate component summaries`);
      await page.evaluate(() => document.querySelector('[data-ep-live-plan="P1"]').click());
      await page.waitForFunction(()=>document.querySelectorAll('.ep-pux-goal').length===3);
      await page.waitForFunction(()=>document.querySelector('.ep-live-plan-item')?.dataset.epFlowPlan==='flowux3');
      await page.click('[data-ep-live-plan-item="1"]');
      await page.waitForSelector('.ep-live-qtext');
      assert.equal(await page.locator('.ep-live-qtext').innerText(),'Convert 90° to radians.');
      await page.check('input[name="ep_live_answer"][value="0"]');
      await page.click('[data-ep-live-submit]');
      await page.waitForFunction(()=>window.__journey.finalized===true);
      await page.waitForSelector('.ep-flow-completion-screen');
      await page.waitForSelector('.ep-pux-finish');
      const finish=await page.locator('.ep-pux-finish').innerText();
      assert.ok(finish.includes('+1'),`${language}: completed goal and session deltas must be displayed`);
      const expectedCounter=language==='ru'?'1 из 3':language==='uz'?'3 tadan 1 tasi':'1 of 3';
      assert.ok(finish.includes(expectedCounter),`${language}: original weekly denominator must survive replan`);
      assert.equal(await page.locator('.ep-pux-finish').count(),1,`${language}: one completion panel`);
      const result=await page.evaluate(()=>window.__journey);
      assert.deepEqual(result.authorizations,[{planId:'synthetic-p1-v1',priority:1}],`${language}: authorization uses original clicked plan`);
      assert.deepEqual(result.started,['synthetic-auth-p1'],`${language}: one authorized session`);
      assert.deepEqual(result.finalizations,['synthetic-session-1'],`${language}: exactly one finalized session`);
      assert.equal(result.version,2,`${language}: existing planner generated the next plan`);
      assert.equal(result.p5Count,2,`${language}: P5 never receives P1 session credit`);
      assert.ok(!result.calls.some(row=>row.name.startsWith('save_')||row.name.includes('legacy')),
        `${language}: no unrelated or legacy mutations`);
      assert.deepEqual(errors,[],`${language}: no browser errors`);
      await page.close();
    }
    console.log('Progress UX authorized journey: PASS (real API/renderer/learner completion, synthetic authorized session, immutable goals and P1/P5 firewall in RU/UZ/EN)');
  } finally { await browser.close(); }
})().catch(error=>{console.error(error);process.exit(1);});