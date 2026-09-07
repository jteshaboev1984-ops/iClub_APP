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
    window.__caps={program_key:'math_as_p1_p5',rollout_state:'controlled_beta',core_access:true,ai_assist:false,mentor_care_entitled:false,mentor_assignment_active:false,mentor_authority:false,kill_switch:false};
    window.__progress={
      P1:{component_code:'P1',placement_status:'complete',route:'foundation',profile_complete:true,content_ready:true,stage0_complete:true,screening:{required_items:24,required_areas:8,answered_items:24,answered_areas:8},active_session:null,max_unlocked_stage:5,foundation_learning_access:true},
      P5:{component_code:'P5',placement_status:'screening_incomplete',route:'pending_evidence',profile_complete:true,content_ready:true,stage0_complete:false,screening:{required_items:15,required_areas:5,answered_items:0,answered_areas:0},active_session:null,max_unlocked_stage:0,foundation_learning_access:false}
    };
    window.__state={
      P1:{engine_version:'objective_state_v1',components:[{component_code:'P1',operational_stage:5,coverage_pct:100,levels:{L0:0,L1:0,L2:0,L3:45}}],skills:[]},
      P5:{engine_version:'objective_state_v1',components:[{component_code:'P5',operational_stage:0,coverage_pct:0,levels:{L0:36,L1:0,L2:0,L3:0}}],skills:[]}
    };
    window.__session=null;
    window.__selfMarks={};
    window.__result={session_id:'00000000-0000-4000-8000-000000007701',component_code:'P1',attempt_kind:'full_paper',marks_available:10,marks_in_time:0,marks_after_time:0,unattempted_marks:0,score_comparable:false,score_status:'pending_self_review'};
    const reviewItems=()=>[
      {item_order:1,primary_skill_code:'P1-QUA-01',prompt:'Solve x + 2 = 6.',learner_artifact:{text:'x = 4'},max_marks:4,rubric:{max_marks:4,criteria:[{marks:1,rule:'Rearranges correctly.'},{marks:3,rule:'Gets and checks x = 4.'}]},self_review:'Check the rearrangement and final value.',submitted_in_time:true,self_marked:Object.prototype.hasOwnProperty.call(window.__selfMarks,1),self_marks_awarded:window.__selfMarks[1]??null},
      {item_order:2,primary_skill_code:'P1-FUN-01',prompt:'Explain the transformation.',learner_artifact:{text:'Translate right by 2.'},max_marks:6,rubric:{max_marks:6,criteria:[{marks:2,rule:'Identifies the translation.'},{marks:4,rule:'Explains the mapping correctly.'}]},self_review:'Check direction and scale.',submitted_in_time:true,self_marked:Object.prototype.hasOwnProperty.call(window.__selfMarks,2),self_marks_awarded:window.__selfMarks[2]??null}
    ];
    window.sb={rpc:async(name,args={})=>{
      window.__calls.push({name,args});
      if(name==='get_exam_prep_capabilities_v1')return{data:[window.__caps],error:null};
      if(name==='get_my_exam_prep_beta_invitation_v1')return{data:{invited:false,invitations:[]},error:null};
      if(name==='get_exam_prep_exam_profile_v1')return{data:[window.__profile],error:null};
      if(name==='get_exam_prep_diagnostic_progress_safe_v1')return{data:window.__progress[args.p_component_code],error:null};
      if(name==='get_exam_prep_state_safe_v1')return{data:window.__state[args.p_component_code],error:null};
      if(name==='get_exam_prep_timed_catalog_safe_v1')return{data:{component_code:'P1',assessments:[{assessment_id:501,title_en:'Full paper practice',title_ru:'Полная работа',title_uz:'To‘liq ish',assessment_type:'paper',attempt_kind:'full_paper',marks_available:10,time_limit_sec:120,strict_timing:true,current_operational_stage:5,min_operational_stage:5}]},error:null};
      if(name==='authorize_exam_prep_timed_safe_v1')return{data:{authorization_id:'00000000-0000-4000-8000-000000007700',assessment_id:args.p_assessment_id,component_code:'P1',purpose:'paper',attempt_kind:'full_paper',marks_available:10,time_limit_sec:120},error:null};
      if(name==='start_exam_prep_session_safe_v1'){
        window.__session={session_id:window.__result.session_id,status:'active',component_code:'P1',session_type:'paper',total_items:2,timing_contract:{deadline_at:new Date(Date.now()+120000).toISOString(),time_limit_sec:120,marks_available:10,attempt_kind:'full_paper'},items:[
          {item_order:1,item_kind:'written',primary_skill_code:'P1-QUA-01',answered:false,written_prompt:'Solve x + 2 = 6.',written_max_marks:4},
          {item_order:2,item_kind:'written',primary_skill_code:'P1-FUN-01',answered:false,written_prompt:'Explain the transformation.',written_max_marks:6}
        ]}; return{data:{session_id:window.__session.session_id,status:'active'},error:null};
      }
      if(name==='get_exam_prep_session_safe_v1')return{data:window.__session,error:null};
      if(name==='submit_exam_prep_response_safe_v1'){
        const item=window.__session.items.find(x=>x.item_order===args.p_item_order); item.answered=true; item.artifact=args.p_payload.artifact; return{data:{item_order:item.item_order,recorded:true},error:null};
      }
      if(name==='finalize_exam_prep_timed_safe_v1'){window.__session.status='finalized';return{data:{...window.__result,completion_reason:args.p_completion_reason},error:null};}
      if(name==='get_exam_prep_timed_review_pack_safe_v1')return{data:{session_id:window.__result.session_id,status:'finalized',items:reviewItems()},error:null};
      if(name==='get_exam_prep_timed_result_safe_v1'){
        const total=Object.values(window.__selfMarks).reduce((a,b)=>a+Number(b||0),0); const done=Object.keys(window.__selfMarks).length===2;
        window.__result={...window.__result,marks_in_time:total,score_comparable:done,score_status:done?'provisional_comparable':'pending_self_review'};
        return{data:window.__result,error:null};
      }
      if(name==='submit_exam_prep_timed_written_self_mark_safe_v1'){window.__selfMarks[args.p_item_order]=args.p_marks_awarded;return{data:{...window.__result,replayed:false},error:null};}
      if(name==='get_exam_prep_readiness_safe_v1')return{data:{ready:true,app_readiness_estimate:'STRONG_OBJECTIVE_EVIDENCE',reason_code:'ready',component_code:'P1',last_three_count:3,below_l3_count:0,unresolved_correction_case_count:0},error:null};
      if(name==='get_exam_prep_final_calibration_safe_v1')return{data:{available:true,component_code:'P1',operational_stage:6,actions:[{action_code:'short_targeted_work',priority:1},{action_code:'timing_and_logistics',priority:2},{action_code:'taper',priority:3}],new_mastery_allowed:false,mentor_verified_readiness:false},error:null};
      return{data:null,error:{message:`unexpected rpc ${name}`}};
    }};
  });

  await page.addScriptTag({path:path.resolve('exam-prep/exam-prep-api.js')});
  await page.addScriptTag({path:path.resolve('exam-prep/exam-prep-host.js')});
  await page.addScriptTag({path:path.resolve('exam-prep/exam-prep-live.js')});
  const assert=(x,m)=>{if(!x)throw new Error(m);};

  await page.evaluate(async()=>{await window.iClubExamPrep.syncSubjectHub({subjectKey:'mathematics',language:'en'});await window.iClubExamPrep.open({subjectKey:'mathematics',language:'en'});});
  await page.waitForSelector('[data-ep-live-timed="P1"]');
  await page.click('[data-ep-live-timed="P1"]');
  await page.waitForSelector('[data-ep-live-timed-start="501"]');
  await page.click('[data-ep-live-timed-start="501"]');
  await page.waitForSelector('textarea[name="ep_live_written_answer"]');
  let text=await page.locator('#exam-prep-host-root').textContent(); assert(text.includes('Time left'),'timed attempt must show countdown');

  await page.fill('textarea[name="ep_live_written_answer"]','x = 4'); await page.click('[data-ep-live-submit]');
  await page.waitForSelector('textarea[name="ep_live_written_answer"]');
  await page.fill('textarea[name="ep_live_written_answer"]','Translate right by 2.'); await page.click('[data-ep-live-submit]');
  await page.waitForSelector('input[name="ep_live_self_mark"]');
  text=await page.locator('#exam-prep-host-root').textContent(); assert(text.includes('Review your work')&&text.includes('Marking criteria'),'post-attempt rubric review must render');

  await page.fill('input[name="ep_live_self_mark"]','4'); await page.click('[data-ep-live-save-self]');
  await page.waitForSelector('input[name="ep_live_self_mark"]');
  await page.fill('input[name="ep_live_self_mark"]','5'); await page.click('[data-ep-live-save-self]');
  await page.waitForFunction(()=>document.querySelector('#exam-prep-host-root')?.textContent.includes('9 / 10'));
  text=await page.locator('#exam-prep-host-root').textContent(); assert(text.includes('Comparable result')&&text.includes('Yes'),'completed self review must make result comparable in the UI');

  await page.click('[data-ep-live-readiness="P1"]');
  await page.waitForFunction(()=>document.querySelector('#exam-prep-host-root')?.textContent.includes('Objective evidence is ready'));
  await page.click('[data-ep-live-calibration="P1"]');
  await page.waitForFunction(()=>document.querySelector('#exam-prep-host-root')?.textContent.includes('Short targeted practice'));

  const result=await page.evaluate(()=>({calls:window.__calls,text:document.querySelector('#exam-prep-host-root').textContent}));
  const names=result.calls.map(x=>x.name);
  for(const n of ['get_exam_prep_timed_catalog_safe_v1','authorize_exam_prep_timed_safe_v1','finalize_exam_prep_timed_safe_v1','get_exam_prep_timed_review_pack_safe_v1','submit_exam_prep_timed_written_self_mark_safe_v1','get_exam_prep_timed_result_safe_v1','get_exam_prep_readiness_safe_v1','get_exam_prep_final_calibration_safe_v1'])assert(names.includes(n),`${n} missing`);
  const timedFinalize=result.calls.find(x=>x.name==='finalize_exam_prep_timed_safe_v1'); assert(timedFinalize.args.p_completion_reason==='submitted','completed paper must use submitted finalization');
  assert(!/Core beta|Synthetic learner data|P1-QUA-01|P1-FUN-01/.test(result.text),'learner UI must not expose rollout or internal skill terminology');
  await browser.close(); console.log('P0-19 live timed/readiness/final-calibration flow: PASS');
})().catch(e=>{console.error(e);process.exit(1);});