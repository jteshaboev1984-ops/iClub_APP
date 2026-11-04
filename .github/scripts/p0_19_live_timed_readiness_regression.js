const { chromium } = require('playwright');
const path = require('path');

(async () => {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage({viewport:{width:390,height:844}});
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
    window.__result={session_id:'00000000-0000-4000-8000-000000007701',component_code:'P1',attempt_kind:'full_paper',marks_available:10,marks_in_time:0,marks_after_time:0,unattempted_marks:0,score_comparable:false,score_status:'written_ungraded',result_scope:'objective_only',written_correctness:'unknown',objective_marks_in_time:0,objective_marks_after_time:0,pending_review_in_time_marks:10};
    const reviewItems=()=>[
      {item_order:1,primary_skill_code:'P1-QUA-01',prompt:'Solve x + 2 = 6.',learner_artifact:{text:'x = 4'},max_marks:4,rubric:{max_marks:4,criteria:[{marks:1,rule:'Rearranges correctly.'},{marks:3,rule:'Gets and checks x = 4.'}]},self_review:'Check the rearrangement and final value.',submitted_in_time:true,written_correctness:'unknown'},
      {item_order:2,primary_skill_code:'P1-FUN-01',prompt:'Explain the transformation.',learner_artifact:{text:'Translate right by 2.'},max_marks:6,rubric:{max_marks:6,criteria:[{marks:2,rule:'Identifies the translation.'},{marks:4,rule:'Explains the mapping correctly.'}]},self_review:'Check direction and scale.',submitted_in_time:true,written_correctness:'unknown'}
    ];
    window.sb={rpc:async(name,args={})=>{
      window.__calls.push({name,args});
      if(name==='get_exam_prep_capabilities_v1')return{data:[window.__caps],error:null};
      if(name==='get_my_exam_prep_beta_invitation_v1')return{data:{invited:false,invitations:[]},error:null};
      if(name==='get_exam_prep_exam_profile_v1')return{data:[window.__profile],error:null};
      if(name==='get_exam_prep_active_plan_session_safe_v1')return{data:{contract_version:'active_plan_session_v1',component_code:args.p_component_code,status:'none',active_session_count:0},error:null};
      if(name==='get_exam_prep_diagnostic_progress_safe_v1')return{data:window.__progress[args.p_component_code],error:null};
      if(name==='get_exam_prep_state_safe_v1')return{data:window.__state[args.p_component_code],error:null};
      if(name==='get_exam_prep_timed_catalog_safe_v1')return{data:{component_code:'P1',assessments:[{assessment_id:501,title_en:'Full paper practice',title_ru:'Полная работа',title_uz:'To‘liq ish',assessment_type:'paper',attempt_kind:'full_paper',marks_available:10,time_limit_sec:120,strict_timing:true,current_operational_stage:5,min_operational_stage:5}]},error:null};
      if(name==='get_exam_prep_stage4_consolidation_safe_v1')return{data:{component_code:'P1',operational_stage:5,ready:false,reason_code:'timing_trend_incomplete',stage3_complete:true,comparable_full_attempts:2,comparable_full_required:2,timed_sections_completed:2,timed_sections_required:2,timed_section_gate_ready:true,trend_ready:false,previous_unattempted_share:0.16,latest_unattempted_share:0.08,previous_after_time_share:0.06,latest_after_time_share:0.02,skills_below_required_level:1,skills_without_qualified_plan:0,corrective_plan_ready:true,next_action_code:'improve_timed_completion',component_isolation:true,modified_or_topic_results_count_as_comparable_full:false,official_reference_series:'Cambridge International AS & A Level Mathematics 9709 · June 2026',official_reference_component:'9709/12',official_reference_url:'https://www.cambridgeinternational.org/exam-administration/cambridge-exams-officers-guide/update-a-s-level-mathematics-june-2026-exam-series/',official_reference_scope:'format_and_timing_context_only',official_reference_used_for_direct_score_calibration:false,official_reference_question_content_copied:false},error:null};
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
      if(name==='get_exam_prep_timed_result_safe_v1')return{data:window.__result,error:null};
      if(name==='get_exam_prep_readiness_safe_v1')return{data:{ready:false,app_readiness_estimate:'INSUFFICIENT_EVIDENCE',reason_code:'three_comparable_attempts_incomplete',component_code:'P1',last_three_count:0,below_l3_count:0,unresolved_correction_case_count:0},error:null};
      if(name==='get_exam_prep_readiness_summary_safe_v1')return{data:{component_code:'P1',ready:false,estimate_code:'INSUFFICIENT_EVIDENCE',reason_code:'three_comparable_attempts_incomplete',comparable_full_attempts:0,comparable_full_required:3,topics_needing_stability:0,open_corrections:0,score_window_ready:false,unattempted_ready:false,after_time_ready:false,threshold_gate_configured:false,mentor_care_active:false,mentor_verified:false,mentor_verification_state:'not_active',next_action_code:'continue_learning',not_official_cambridge_grade:true,mentor_verification_optional_for_core:true,p1_p5_separate:true},error:null};
      if(name==='get_exam_prep_final_calibration_safe_v1')return{data:{available:true,component_code:'P1',operational_stage:6,actions:[{action_code:'short_targeted_work',priority:1},{action_code:'timing_and_logistics',priority:2},{action_code:'taper',priority:3}],new_mastery_allowed:false,mentor_verified_readiness:false},error:null};
      return{data:null,error:{message:`unexpected rpc ${name}`}};
    }};
  });

  await page.addScriptTag({path:path.resolve('exam-prep/exam-prep-api.js')});
  await page.addScriptTag({path:path.resolve('exam-prep/exam-prep-host.js')});
  await page.addScriptTag({path:path.resolve('exam-prep/exam-prep-live.js')});
  const assert=(x,m)=>{if(!x)throw new Error(m);};

  await page.evaluate(async()=>{await window.iClubExamPrep.syncSubjectHub({subjectKey:'mathematics',language:'en'});await window.iClubExamPrep.open({subjectKey:'mathematics',language:'en'});});
  await page.waitForSelector('[data-ep-live-open-component="P1"]');
  await page.click('[data-ep-live-open-component="P1"]');
  await page.waitForSelector('[data-ep-component-link="timed"]');
  await page.click('[data-ep-component-link="timed"]');
  await page.waitForSelector('[data-ep-live-timed-start="501"]');
  await page.waitForSelector('[data-ep-live-stage4-consolidation]');
  let consolidationText=await page.locator('[data-ep-live-stage4-consolidation]').textContent();
  assert(consolidationText.includes('Timed consolidation'),'Stage-4 learner progress title missing');
  assert(consolidationText.includes('2 / 2'),'Stage-4 comparable/timed progress missing');
  assert(consolidationText.includes('16% → 8%'),'Stage-4 unattempted trend missing');
  assert(consolidationText.includes('6% → 2%'),'Stage-4 after-time trend missing');
  assert(consolidationText.includes('completing more of the paper within the time limit'),'Stage-4 next action copy missing');
  assert(consolidationText.includes('Format reference: official Cambridge 9709, June 2026.'),'official Cambridge June 2026 reference note missing');
  const referenceLink=page.locator('[data-ep-live-stage4-consolidation] .ep-live-reference-note a');
  assert(await referenceLink.getAttribute('href')==='https://www.cambridgeinternational.org/exam-administration/cambridge-exams-officers-guide/update-a-s-level-mathematics-june-2026-exam-series/','official Cambridge reference URL mismatch');
  const rel=await referenceLink.getAttribute('rel'); assert(rel?.includes('noopener')&&rel?.includes('noreferrer'),'official reference link isolation missing');
  assert(!/L3|rule_version|family_key|Stage-4/.test(consolidationText),'Stage-4 learner card leaked internal terminology');
  await page.click('[data-ep-live-timed-start="501"]');
  await page.waitForSelector('textarea[name="ep_live_written_answer"]');
  let text=await page.locator('#exam-prep-host-root').textContent(); assert(text.includes('Time left'),'timed attempt must show countdown');

  await page.fill('textarea[name="ep_live_written_answer"]','x = 4'); await page.click('[data-ep-live-submit]');
  await page.waitForSelector('textarea[name="ep_live_written_answer"]');
  await page.fill('textarea[name="ep_live_written_answer"]','Translate right by 2.'); await page.click('[data-ep-live-submit]');
  await page.waitForSelector('[data-ep-live-next-written]');
  text=await page.locator('#exam-prep-host-root').textContent();
  assert(text.includes('Review your work')&&text.includes('Marking criteria'),'post-attempt rubric must render');
  assert(text.includes('correctness is unverified'),'unverified written correctness was hidden');
  assert(await page.locator('input[name="ep_live_self_mark"]').count()===0,
    'written marks input is prohibited under D03');

  await page.click('[data-ep-live-next-written]');
  await page.waitForSelector('[data-ep-live-next-written]');
  await page.click('[data-ep-live-next-written]');
  await page.waitForFunction(()=>document.querySelector('#exam-prep-host-root')?.textContent.includes('Comparable result'));
  text=await page.locator('#exam-prep-host-root').textContent();
  assert(text.includes('No')&&text.includes('correctness is unverified'),
    'unverified Paper must not be a comparable full-paper grade');
  assert(!text.includes('9 / 10'),'written marks incorrectly added to full-paper result');

  await page.click('[data-ep-live-readiness="P1"]');
  await page.waitForSelector('[data-ep-live-readiness-summary]');
  const readinessText=await page.locator('#exam-prep-host-root').textContent();
  assert(readinessText.includes('iClub readiness estimate'),'learner readiness estimate label missing');
  assert(readinessText.includes('not an official Cambridge grade'),'non-grade readiness boundary missing');
  assert(readinessText.includes('0 / 3'),'unverified written Paper must not satisfy comparable-paper count');
  assert(!readinessText.includes('Mentor verification'),'Core learner must not receive a missing Mentor verification card');
  assert(await page.locator('[data-ep-live-calibration]').count()===0,
    'Stage6 must remain inaccessible without verified comparable Paper');

  const result=await page.evaluate(()=>({calls:window.__calls,text:document.querySelector('#exam-prep-host-root').textContent}));
  const names=result.calls.map(x=>x.name);
  for(const n of ['get_exam_prep_timed_catalog_safe_v1','get_exam_prep_stage4_consolidation_safe_v1','authorize_exam_prep_timed_safe_v1','finalize_exam_prep_timed_safe_v1','get_exam_prep_timed_review_pack_safe_v1','get_exam_prep_timed_result_safe_v1','get_exam_prep_readiness_summary_safe_v1','get_exam_prep_final_calibration_safe_v1'])assert(names.includes(n),`${n} missing`);
  assert(!names.includes('submit_exam_prep_timed_written_self_mark_safe_v1'),'student must not self-score via client');
  const timedFinalize=result.calls.find(x=>x.name==='finalize_exam_prep_timed_safe_v1'); assert(timedFinalize.args.p_completion_reason==='submitted','completed paper must use submitted finalization');
  assert(!/Core beta|Synthetic learner data|P1-QUA-01|P1-FUN-01/.test(result.text),'learner UI must not expose rollout or internal skill terminology');
  await browser.close(); console.log('P0-19 Timed/Paper rubric-only, unknown written and Stage6 blocked: PASS');
})().catch(e=>{console.error(e);process.exit(1);});