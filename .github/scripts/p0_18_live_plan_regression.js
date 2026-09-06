const { chromium } = require('playwright');
const path = require('path');

(async () => {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();
  await page.route('http://iclub.test/', route => route.fulfill({status:200,contentType:'text/html',body:`<!doctype html><html><head></head><body><section id="courses-subject-hub"><div id="subject-hub-exam-prep-entry" hidden aria-hidden="true"><span id="subject-hub-exam-prep-title"></span><span id="subject-hub-exam-prep-sub"></span></div><div id="exam-prep-host-root" hidden aria-hidden="true"></div></section></body></html>`}));
  await page.goto('http://iclub.test/');

  await page.evaluate(() => {
    window.__calls=[];
    window.__profile={exam_series:'Oct/Nov 2026',target_grade:'A',total_student_hours_available:12,mathematics_hours_budget:6,active_week_no:1};
    window.__plan=null;
    window.__session=null;
    window.__caps={program_key:'math_as_p1_p5',rollout_state:'controlled_beta',core_access:true,ai_assist:false,mentor_care_entitled:false,mentor_assignment_active:false,mentor_authority:false,kill_switch:false};
    window.__progress={
      P1:{component_code:'P1',placement_status:'conservative_foundation',route:'foundation',profile_complete:true,content_ready:true,stage0_complete:true,screening:{required_items:24,required_areas:8,answered_items:24,answered_areas:8,accuracy_pct:70},active_session:null,max_unlocked_stage:1,foundation_learning_access:true},
      P5:{component_code:'P5',placement_status:'screening_incomplete',route:'pending_evidence',profile_complete:true,content_ready:true,stage0_complete:false,screening:{required_items:15,required_areas:5,answered_items:0,answered_areas:0},active_session:null,max_unlocked_stage:0,foundation_learning_access:false}
    };
    const makePlan=()=>({plan_id:'00000000-0000-4000-8000-000000008801',component_code:'P1',active_week_no:1,plan_version:1,recovery_mode:'normal',items:[{priority_order:1,item_type:'learning',skill_code:'P1-QUA-01',correction_case_id:null,due_at:null,action_code:'BUILD_FIRST_COVERAGE',action_payload:{},status:'pending'}]});
    window.sb={rpc:async(name,args={})=>{
      window.__calls.push({name,args});
      if(name==='get_exam_prep_capabilities_v1')return{data:[window.__caps],error:null};
      if(name==='get_my_exam_prep_beta_invitation_v1')return{data:{invited:false,invitations:[]},error:null};
      if(name==='get_exam_prep_exam_profile_v1')return{data:[window.__profile],error:null};
      if(name==='get_exam_prep_diagnostic_progress_safe_v1')return{data:window.__progress[args.p_component_code],error:null};
      if(name==='get_exam_prep_weekly_plan_safe_v1')return{data:window.__plan||{component_code:args.p_component_code,plan:null,items:[]},error:null};
      if(name==='generate_exam_prep_weekly_plan_safe_v1'){window.__plan=makePlan();return{data:{plan_id:window.__plan.plan_id,component_code:'P1',priority_count:1},error:null};}
      if(name==='authorize_exam_prep_plan_item_safe_v1')return{data:{authorization_id:'00000000-0000-4000-8000-000000008802',plan_id:args.p_plan_id,priority_order:args.p_priority_order,item_type:'learning',purpose:'learning'},error:null};
      if(name==='start_exam_prep_session_safe_v1'){
        window.__session={session_id:'00000000-0000-4000-8000-000000008803',status:'active',component_code:'P1',session_type:'learning',total_items:2,items:[
          {item_order:1,item_kind:'question',primary_skill_code:'P1-QUA-01',answered:false,qtype:'mcq',text:'Choose 4.',options:['2','4','6']},
          {item_order:2,item_kind:'written',primary_skill_code:'P1-QUA-01',answered:false,written_prompt:'Explain why the answer is 4.',written_max_marks:2}
        ]}; return{data:{session_id:window.__session.session_id,status:'active'},error:null};
      }
      if(name==='get_exam_prep_session_safe_v1')return{data:window.__session,error:null};
      if(name==='submit_exam_prep_response_safe_v1'){
        const item=window.__session.items.find(x=>x.item_order===args.p_item_order); item.answered=true;
        if(item.item_kind==='written')return{data:{item_order:item.item_order,verification_status:'self_reviewed'},error:null};
        return{data:{item_order:item.item_order,is_correct:args.p_payload.picked_index===1,explanation:'Correct.'},error:null};
      }
      if(name==='finalize_exam_prep_session_safe_v1'){window.__session.status='finalized';return{data:{session_id:window.__session.session_id,status:'finalized',answered:2,total_items:2},error:null};}
      return{data:null,error:{message:`unexpected rpc ${name}`}};
    }};
  });

  await page.addScriptTag({path:path.resolve('exam-prep/exam-prep-api.js')});
  await page.addScriptTag({path:path.resolve('exam-prep/exam-prep-host.js')});
  await page.addScriptTag({path:path.resolve('exam-prep/exam-prep-live.js')});
  const assert=(x,m)=>{if(!x)throw new Error(m);};

  await page.evaluate(async()=>{await window.iClubExamPrep.syncSubjectHub({subjectKey:'mathematics',language:'en'});await window.iClubExamPrep.open({subjectKey:'mathematics',language:'en'});});
  await page.waitForSelector('[data-ep-live-plan="P1"]');
  await page.click('[data-ep-live-plan="P1"]');
  await page.waitForSelector('[data-ep-live-plan-item="1"]');
  let text=await page.locator('#exam-prep-host-root').textContent(); assert(text.includes('Build first coverage'),'weekly learning item must render');

  await page.click('[data-ep-live-plan-item="1"]');
  await page.waitForSelector('input[name="ep_live_answer"]');
  await page.check('input[name="ep_live_answer"][value="1"]'); await page.click('[data-ep-live-submit]');
  await page.waitForSelector('textarea[name="ep_live_written_answer"]');
  await page.fill('textarea[name="ep_live_written_answer"]','Because two plus two equals four.'); await page.click('[data-ep-live-submit]');
  await page.waitForFunction(()=>document.querySelector('#exam-prep-host-root')?.textContent.includes('Task complete. Plan refreshed.'));

  const result=await page.evaluate(()=>({calls:window.__calls,text:document.querySelector('#exam-prep-host-root').textContent}));
  const names=result.calls.map(x=>x.name);
  for(const n of ['get_exam_prep_weekly_plan_safe_v1','generate_exam_prep_weekly_plan_safe_v1','authorize_exam_prep_plan_item_safe_v1','start_exam_prep_session_safe_v1','submit_exam_prep_response_safe_v1','finalize_exam_prep_session_safe_v1'])assert(names.includes(n),`${n} missing`);
  const written=result.calls.find(x=>x.name==='submit_exam_prep_response_safe_v1'&&x.args.p_item_order===2); assert(written?.args?.p_payload?.artifact?.text,'written solution must be sent as artifact');
  const auth=result.calls.find(x=>x.name==='authorize_exam_prep_plan_item_safe_v1'); assert(auth.args.p_priority_order===1,'plan authorization must target exact priority');
  assert(result.text.includes('Weekly plan'),'must return to refreshed plan');
  await browser.close(); console.log('P0-18 live weekly plan flow: PASS');
})().catch(e=>{console.error(e);process.exit(1);});