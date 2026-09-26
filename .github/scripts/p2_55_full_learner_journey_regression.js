const { chromium } = require('playwright');
const path = require('path');

(async () => {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();
  const assert = (ok, message) => { if (!ok) throw new Error(message); };

  await page.route('http://iclub.test/', route => route.fulfill({
    status: 200,
    contentType: 'text/html',
    body: '<!doctype html><html lang="en"><head></head><body><section id="courses-subject-hub"><div id="subject-hub-exam-prep-entry" hidden aria-hidden="true"><span id="subject-hub-exam-prep-title"></span><span id="subject-hub-exam-prep-sub"></span></div><div id="exam-prep-host-root" hidden aria-hidden="true"></div></section></body></html>'
  }));
  await page.goto('http://iclub.test/');

  await page.evaluate(() => {
    localStorage.setItem('iclub_state_v1', JSON.stringify({ legacy: 'preserve-me', progress: 73 }));
    window.__legacyBefore = localStorage.getItem('iclub_state_v1');
    window.__calls = [];
    window.__seenLearnerText = [];
    window.__profile = null;
    window.__plan = null;
    window.__session = null;
    window.__selfMarks = {};
    window.__timedSessionId = '00000000-0000-4000-8000-000000055501';
    window.__caps = { program_key:'math_as_p1_p5',rollout_state:'controlled_beta',core_access:true,ai_assist:false,mentor_care_entitled:false,mentor_assignment_active:false,mentor_authority:false,kill_switch:false };
    window.__progress = {
      P1:{component_code:'P1',placement_status:'screening_incomplete',route:'pending_evidence',profile_complete:true,content_ready:true,stage0_complete:false,screening:{required_items:2,required_areas:2,answered_items:0,answered_areas:0},active_session:null,max_unlocked_stage:0,foundation_learning_access:false},
      P5:{component_code:'P5',placement_status:'screening_incomplete',route:'pending_evidence',profile_complete:true,content_ready:true,stage0_complete:false,screening:{required_items:2,required_areas:2,answered_items:0,answered_areas:0},active_session:null,max_unlocked_stage:0,foundation_learning_access:false}
    };
    window.__state = {
      P1:{engine_version:'objective_state_v1',components:[{component_code:'P1',operational_stage:0,coverage_pct:0,levels:{L0:45,L1:0,L2:0,L3:0}}],skills:[]},
      P5:{engine_version:'objective_state_v1',components:[{component_code:'P5',operational_stage:0,coverage_pct:0,levels:{L0:36,L1:0,L2:0,L3:0}}],skills:[]}
    };
    window.__p5Before = JSON.stringify({progress:window.__progress.P5,state:window.__state.P5});
    window.__timedResult = {session_id:window.__timedSessionId,component_code:'P1',attempt_kind:'full_paper',marks_available:10,marks_in_time:0,marks_after_time:0,unattempted_marks:0,score_comparable:false,score_status:'pending_self_review'};
    window.__capture = () => {
      const text = String(document.querySelector('#exam-prep-host-root')?.textContent || '');
      window.__seenLearnerText.push(text);
      return text;
    };
    window.__setStage = stage => {
      const row = window.__state.P1.components[0];
      row.operational_stage = stage;
      row.coverage_pct = ({1:0,2:35,3:100,4:100,5:100,6:100})[stage] ?? row.coverage_pct;
      window.__progress.P1.max_unlocked_stage = stage;
    };
    const makePlan = () => ({plan_id:'00000000-0000-4000-8000-000000055401',component_code:'P1',active_week_no:1,plan_version:1,recovery_mode:'normal',items:[{priority_order:1,item_type:'learning',skill_code:'P1-INTERNAL-JOURNEY-SKILL',correction_case_id:null,due_at:null,action_code:'BUILD_FIRST_COVERAGE',action_payload:{},status:'pending'}]});
    const reviewItems = () => [
      {item_order:1,primary_skill_code:'P1-INTERNAL-PAPER-1',prompt:'Solve x + 2 = 6.',learner_artifact:{text:'x = 4'},max_marks:4,rubric:{max_marks:4,criteria:[{marks:1,rule:'Rearranges correctly.'},{marks:3,rule:'Gets and checks x = 4.'}]},self_review:'Check the rearrangement and final value.',submitted_in_time:true,self_marked:Object.prototype.hasOwnProperty.call(window.__selfMarks,1),self_marks_awarded:window.__selfMarks[1]??null},
      {item_order:2,primary_skill_code:'P1-INTERNAL-PAPER-2',prompt:'Explain the transformation.',learner_artifact:{text:'Translate right by 2.'},max_marks:6,rubric:{max_marks:6,criteria:[{marks:2,rule:'Identifies the translation.'},{marks:4,rule:'Explains the mapping correctly.'}]},self_review:'Check direction and scale.',submitted_in_time:true,self_marked:Object.prototype.hasOwnProperty.call(window.__selfMarks,2),self_marks_awarded:window.__selfMarks[2]??null}
    ];

    window.sb = { rpc: async (name,args={}) => {
      window.__calls.push({name,args});
      if (name==='get_exam_prep_capabilities_v1') return {data:[window.__caps],error:null};
      if (name==='get_my_exam_prep_beta_invitation_v1') return {data:{invited:false,invitations:[]},error:null};
      if (name==='get_exam_prep_exam_profile_v1') return {data:window.__profile?[window.__profile]:[],error:null};
      if (name==='save_exam_prep_exam_profile_v2') {
        window.__profile={exam_series:args.p_exam_series,target_grade:args.p_target_grade,total_student_hours_available:args.p_total_student_hours_available,mathematics_hours_budget:args.p_mathematics_hours_budget,active_week_no:1};
        return {data:{...window.__profile,profile_revision:1,paper_comparability_epoch:1,series_changed:false,target_changed:false,hours_changed:false,progress_retained:true,plan_rebuild_required:false},error:null};
      }
      if (name==='get_exam_prep_diagnostic_progress_safe_v1') return {data:window.__progress[args.p_component_code],error:null};
      if (name==='get_exam_prep_state_safe_v1') return {data:window.__state[args.p_component_code],error:null};
      if (name==='start_exam_prep_next_diagnostic_safe_v1') {
        window.__session={session_id:'00000000-0000-4000-8000-000000055301',status:'active',component_code:args.p_component_code,session_type:'diagnostic',total_items:2,items:[
          {item_order:1,item_kind:'question',primary_skill_code:'P1-INTERNAL-DIAG-1',reserve_role:'diagnostic',answered:false,qtype:'mcq',text:'What is 2 + 2?',options:['2','4','6','8']},
          {item_order:2,item_kind:'question',primary_skill_code:'P1-INTERNAL-DIAG-2',reserve_role:'diagnostic',answered:false,qtype:'mcq',text:'What is 3 + 3?',options:['4','5','6','7']}
        ]};
        return {data:{session_id:window.__session.session_id},error:null};
      }
      if (name==='get_exam_prep_weekly_plan_safe_v2') return {data:window.__plan||{component_code:args.p_component_code,plan:null,items:[]},error:null};
      if (name==='generate_exam_prep_weekly_plan_safe_v3') {
        if (!window.__plan) window.__plan=makePlan();
        return {data:{plan_id:window.__plan.plan_id,component_code:args.p_component_code,priority_count:window.__plan.items.filter(x=>x.status==='pending').length,progress_retained:true},error:null};
      }
      if (name==='authorize_exam_prep_plan_item_safe_v1') return {data:{authorization_id:'00000000-0000-4000-8000-000000055402',plan_id:args.p_plan_id,priority_order:args.p_priority_order,item_type:'learning',purpose:'learning'},error:null};
      if (name==='get_exam_prep_timed_catalog_safe_v1') return {data:{component_code:'P1',assessments:[{assessment_id:5501,title_en:'Full paper practice',title_ru:'Полная работа',title_uz:'To‘liq ish',assessment_type:'paper',attempt_kind:'full_paper',marks_available:10,time_limit_sec:120,strict_timing:true,current_operational_stage:5,min_operational_stage:5}]},error:null};
      if (name==='authorize_exam_prep_timed_safe_v1') return {data:{authorization_id:'00000000-0000-4000-8000-000000055500',assessment_id:args.p_assessment_id,component_code:'P1',purpose:'paper',attempt_kind:'full_paper',marks_available:10,time_limit_sec:120},error:null};
      if (name==='start_exam_prep_session_safe_v1') {
        if (args.p_authorization_id==='00000000-0000-4000-8000-000000055402') {
          window.__session={session_id:'00000000-0000-4000-8000-000000055403',status:'active',component_code:'P1',session_type:'learning',total_items:1,items:[{item_order:1,item_kind:'question',primary_skill_code:'P1-INTERNAL-JOURNEY-SKILL',answered:false,qtype:'mcq',text:'Choose 4.',options:['2','4','6']}]};
        } else {
          window.__session={session_id:window.__timedSessionId,status:'active',component_code:'P1',session_type:'paper',total_items:2,timing_contract:{deadline_at:new Date(Date.now()+120000).toISOString(),time_limit_sec:120,marks_available:10,attempt_kind:'full_paper'},items:[
            {item_order:1,item_kind:'written',primary_skill_code:'P1-INTERNAL-PAPER-1',reserve_role:'timed',answered:false,written_prompt:'Solve x + 2 = 6.',written_max_marks:4},
            {item_order:2,item_kind:'written',primary_skill_code:'P1-INTERNAL-PAPER-2',reserve_role:'timed',answered:false,written_prompt:'Explain the transformation.',written_max_marks:6}
          ]};
        }
        return {data:{session_id:window.__session.session_id,status:'active'},error:null};
      }
      if (name==='get_exam_prep_session_safe_v1') return {data:window.__session,error:null};
      if (name==='submit_exam_prep_response_safe_v1') {
        const item=window.__session.items.find(x=>x.item_order===args.p_item_order);
        item.answered=true;
        if (window.__session.session_type==='diagnostic') {
          item.feedback_deferred=true;
          return {data:{item_order:item.item_order,selected_answer:String(args.p_payload.picked_index),verification_status:'app_verified',feedback_deferred:true,replayed:false},error:null};
        }
        if (window.__session.session_type==='learning') return {data:{item_order:item.item_order,is_correct:true,verification_status:'app_verified',explanation:'Correct.'},error:null};
        item.learner_artifact=args.p_payload.artifact;
        return {data:{item_order:item.item_order,verification_status:'self_reviewed'},error:null};
      }
      if (name==='finalize_exam_prep_session_safe_v1') {
        const type=window.__session.session_type;
        window.__session.status='finalized';
        if (type==='diagnostic') {
          Object.assign(window.__progress.P1,{stage0_complete:true,placement_status:'conservative_foundation',route:'foundation',foundation_learning_access:true});
          window.__progress.P1.screening.answered_items=2;
          window.__progress.P1.screening.answered_areas=2;
          window.__setStage(1);
        }
        if (type==='learning'&&window.__plan?.items?.[0]) window.__plan.items[0].status='completed';
        return {data:{session_id:window.__session.session_id,status:'finalized',answered:window.__session.total_items,total_items:window.__session.total_items},error:null};
      }
      if (name==='get_exam_prep_session_review_safe_v1') {
        const items=window.__session.items.map(item=>item.item_kind==='question'
          ? {...item,text:item.text||'Question',selected_answer:'A',correct_answer:'A',is_correct:true,explanation:'Review explanation.'}
          : {...item,text:item.written_prompt||'Written task',learner_artifact:item.learner_artifact||{text:'Saved solution'},verification_status:'self_reviewed',written_self_review:'Check your method.'});
        const machine=items.filter(x=>x.item_kind==='question');
        const written=items.filter(x=>x.item_kind==='written');
        return {data:{session_id:window.__session.session_id,component_code:window.__session.component_code,session_type:window.__session.session_type,status:'finalized',summary:{machine_total:machine.length,machine_correct:machine.length,machine_incorrect:0,machine_accuracy_pct:100,written_total:written.length,written_completed:written.length},items},error:null};
      }
      if (name==='get_exam_prep_recent_results_safe_v1') return {data:{component_code:args.p_component_code,results:[]},error:null};
      if (name==='finalize_exam_prep_timed_safe_v1') {
        window.__session.status='finalized';
        return {data:{...window.__timedResult,completion_reason:args.p_completion_reason},error:null};
      }
      if (name==='get_exam_prep_timed_review_pack_safe_v1') return {data:{session_id:window.__timedSessionId,status:'finalized',items:reviewItems()},error:null};
      if (name==='get_exam_prep_timed_result_safe_v1') {
        const total=Object.values(window.__selfMarks).reduce((sum,v)=>sum+Number(v||0),0);
        const done=Object.keys(window.__selfMarks).length===2;
        window.__timedResult={...window.__timedResult,marks_in_time:total,score_comparable:done,score_status:done?'provisional_comparable':'pending_self_review'};
        return {data:window.__timedResult,error:null};
      }
      if (name==='submit_exam_prep_timed_written_self_mark_safe_v1') {
        window.__selfMarks[args.p_item_order]=args.p_marks_awarded;
        return {data:{...window.__timedResult,replayed:false},error:null};
      }
      if (name==='get_exam_prep_readiness_safe_v1') return {data:{ready:true,app_readiness_estimate:'STRONG_OBJECTIVE_EVIDENCE',reason_code:'ready',component_code:'P1',last_three_count:3,below_l3_count:0,unresolved_correction_case_count:0},error:null};
      if (name==='get_exam_prep_final_calibration_safe_v1') return {data:{available:true,component_code:'P1',operational_stage:6,actions:[{action_code:'short_targeted_work',priority:1},{action_code:'timing_and_logistics',priority:2},{action_code:'taper',priority:3}],new_mastery_allowed:false,mentor_verified_readiness:false},error:null};
      return {data:null,error:{message:`unexpected rpc ${name}`}};
    }};
  });

  await page.addScriptTag({path:path.resolve('exam-prep/exam-prep-api.js')});
  await page.addScriptTag({path:path.resolve('exam-prep/exam-prep-host.js')});
  await page.addScriptTag({path:path.resolve('exam-prep/exam-prep-live.js')});
  const capture = () => page.evaluate(() => window.__capture());

  const opened = await page.evaluate(async () => {
    const synced=await window.iClubExamPrep.syncSubjectHub({subjectKey:'mathematics',language:'en'});
    const open=await window.iClubExamPrep.open({subjectKey:'mathematics',language:'en'});
    return {synced,open,version:window.iClubExamPrep.liveFlowVersion};
  });
  assert(opened.synced&&opened.open,'Exam Prep must open');
  assert(opened.version==='p260signal1','unexpected live-flow version');
  await page.waitForSelector('[data-ep-live-profile-form]');
  await capture();

  await page.fill('input[name="exam_series"]','May/June 2027');
  await page.fill('input[name="target_grade"]','A');
  await page.fill('input[name="total_hours"]','12');
  await page.fill('input[name="math_hours"]','6');
  await page.click('[data-ep-live-save-profile]');
  await page.waitForSelector('[data-ep-live-open-component="P1"]');
  await page.waitForSelector('[data-ep-live-open-component="P5"]');
  let stage0 = await page.evaluate(() => ({cards:document.querySelectorAll('[data-ep-live-open-component]').length,p1Done:window.__progress.P1.stage0_complete,p5Done:window.__progress.P5.stage0_complete}));
  assert(stage0.cards===2&&!stage0.p1Done&&!stage0.p5Done,'both P1 and P5 must begin independently in Stage 0');
  await capture();

  await page.click('[data-ep-live-open-component="P1"]');
  await page.waitForSelector('[data-ep-component-home="P1"]');
  await page.click('[data-ep-component-primary="diagnostic"]');
  await page.waitForSelector('input[name="ep_live_answer"]');
  await page.check('input[name="ep_live_answer"][value="1"]');
  await page.click('[data-ep-live-submit]');
  await page.waitForFunction(()=>document.querySelector('#exam-prep-host-root')?.textContent.includes('Question 2 / 2'));
  const protectedState = await page.evaluate(() => ({text:window.__capture(),session:window.__session,finalizeCalls:window.__calls.filter(x=>x.name==='finalize_exam_prep_session_safe_v1').length}));
  assert(protectedState.session.status==='active','diagnostic must remain active after first answer');
  assert(protectedState.session.items[0].feedback_deferred===true&&!('is_correct' in protectedState.session.items[0]),'protected Stage 0 answer must defer correctness');
  assert(protectedState.finalizeCalls===0,'diagnostic must not finalize early');
  assert(!/\bCorrect\b|Review this mistake/i.test(protectedState.text),'protected Stage 0 UI revealed immediate correctness');

  await page.check('input[name="ep_live_answer"][value="2"]');
  await page.click('[data-ep-live-submit]');
  await page.waitForSelector('[data-ep-session-result]');
  let diagnosticResult=await capture();
  assert(diagnosticResult.includes('Task result')&&diagnosticResult.includes('Auto-checked questions'),'completed diagnostic must show persistent result');
  await page.click('[data-ep-result-continue]');
  await page.waitForSelector('[data-ep-component-home="P1"]');
  let dashboard=await capture();
  assert(dashboard.includes('Foundation'),'P1 must enter Stage 1 after entry check');
  const p5AfterDiagnostic=await page.evaluate(()=>({complete:window.__progress.P5.stage0_complete,stage:window.__state.P5.components[0].operational_stage}));
  assert(!p5AfterDiagnostic.complete&&p5AfterDiagnostic.stage===0,'P5 must remain independently in Stage 0');

  await page.click('[data-ep-component-primary="prepare"]');
  await page.waitForSelector('input[name="ep_live_answer"]');
  await page.check('input[name="ep_live_answer"][value="1"]');
  await page.click('[data-ep-live-submit]');
  await page.waitForSelector('[data-ep-session-result]');
  const learningResult=await capture();
  assert(learningResult.includes('Task result')&&learningResult.includes('1 / 1 correct'),'learning task must show completed result without per-item interruption');
  await page.click('[data-ep-result-continue]');
  await page.waitForSelector('[data-ep-component-home="P1"]');
  await capture();

  for (const [stage,label] of [[2,'Syllabus learning'],[3,'Syllabus closure'],[4,'Timed consolidation'],[5,'Exam readiness']]) {
    await page.evaluate(async s=>{window.__setStage(s);await window.iClubExamPrep.open({subjectKey:'mathematics',language:'en'});},stage);
    await page.waitForFunction(expected=>document.querySelector('#exam-prep-host-root')?.textContent.includes(expected),label);
    const text=await capture();
    assert(text.includes(label),`P1 Stage ${stage} missing`);
    const p5=await page.evaluate(()=>({complete:window.__progress.P5.stage0_complete,stage:window.__state.P5.components[0].operational_stage}));
    assert(!p5.complete&&p5.stage===0,`P5 changed while P1 advanced to Stage ${stage}`);
  }

  await page.click('[data-ep-live-open-component="P1"]');
  await page.waitForSelector('[data-ep-component-home="P1"]');
  await page.click('[data-ep-component-link="timed"]');
  await page.waitForSelector('[data-ep-live-timed-start="5501"]');
  await page.click('[data-ep-live-timed-start="5501"]');
  await page.waitForSelector('textarea[name="ep_live_written_answer"]');
  assert((await capture()).includes('Time left'),'Stage 5 full paper must show countdown');
  await page.fill('textarea[name="ep_live_written_answer"]','x = 4');
  await page.click('[data-ep-live-submit]');
  await page.waitForSelector('textarea[name="ep_live_written_answer"]');
  await page.fill('textarea[name="ep_live_written_answer"]','Translate right by 2.');
  await page.click('[data-ep-live-submit]');
  await page.waitForSelector('input[name="ep_live_self_mark"]');
  let text=await capture();
  assert(text.includes('Review your work')&&text.includes('Marking criteria'),'post-paper self review missing');
  await page.fill('input[name="ep_live_self_mark"]','4');
  await page.click('[data-ep-live-save-self]');
  await page.waitForSelector('input[name="ep_live_self_mark"]');
  await page.fill('input[name="ep_live_self_mark"]','5');
  await page.click('[data-ep-live-save-self]');
  await page.waitForFunction(()=>document.querySelector('#exam-prep-host-root')?.textContent.includes('9 / 10'));
  text=await capture();
  assert(text.includes('Comparable result')&&text.includes('Yes'),'9/10 comparable result missing');

  await page.click('[data-ep-live-readiness="P1"]');
  await page.waitForFunction(()=>document.querySelector('#exam-prep-host-root')?.textContent.includes('Objective evidence is ready'));
  await capture();
  await page.click('[data-ep-live-calibration="P1"]');
  await page.waitForFunction(()=>document.querySelector('#exam-prep-host-root')?.textContent.includes('Short targeted practice'));
  text=await capture();
  assert(text.includes('Final calibration')&&text.includes('Check timing and exam logistics'),'Stage 6 final calibration missing');

  const finalState=await page.evaluate(()=>({calls:window.__calls,allText:window.__seenLearnerText.join('\n'),legacyBefore:window.__legacyBefore,legacyAfter:localStorage.getItem('iclub_state_v1'),p5Before:window.__p5Before,p5After:JSON.stringify({progress:window.__progress.P5,state:window.__state.P5})}));
  assert(finalState.legacyAfter===finalState.legacyBefore,'Exam Prep journey must not mutate legacy localStorage state');
  assert(finalState.p5After===finalState.p5Before,'P1 journey must not mutate independent P5 progress/state');
  assert(!/objective_state_v1|P1-INTERNAL-|controlled_beta|academic_credit|feedback_deferred|correct_answer/i.test(finalState.allText),'learner DOM exposed internal or protected terms');

  const names=finalState.calls.map(x=>x.name);
  for (const name of ['save_exam_prep_exam_profile_v2','start_exam_prep_next_diagnostic_safe_v1','submit_exam_prep_response_safe_v1','finalize_exam_prep_session_safe_v1','get_exam_prep_weekly_plan_safe_v2','generate_exam_prep_weekly_plan_safe_v3','authorize_exam_prep_plan_item_safe_v1','get_exam_prep_timed_catalog_safe_v1','authorize_exam_prep_timed_safe_v1','finalize_exam_prep_timed_safe_v1','get_exam_prep_timed_review_pack_safe_v1','submit_exam_prep_timed_written_self_mark_safe_v1','get_exam_prep_timed_result_safe_v1','get_exam_prep_readiness_safe_v1','get_exam_prep_final_calibration_safe_v1']) assert(names.includes(name),`${name} missing from full learner journey`);
  const timedFinalize=finalState.calls.find(x=>x.name==='finalize_exam_prep_timed_safe_v1');
  assert(timedFinalize?.args?.p_completion_reason==='submitted','full paper must finalize as submitted');

  await browser.close();
  console.log('P2-55 full Stage 0 to 6 learner journey: PASS');
})().catch(error=>{console.error(error);process.exit(1);});
