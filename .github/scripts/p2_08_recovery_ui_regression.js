const { chromium } = require('playwright');
const path = require('path');

(async () => {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();

  await page.route('http://iclub.test/', route => route.fulfill({
    status: 200,
    contentType: 'text/html',
    body: '<!doctype html><html lang="en"><head></head><body><section id="courses-subject-hub"><div id="subject-hub-exam-prep-entry" hidden aria-hidden="true"><span id="subject-hub-exam-prep-title"></span><span id="subject-hub-exam-prep-sub"></span></div><div id="exam-prep-host-root" hidden aria-hidden="true"></div></section></body></html>'
  }));
  await page.goto('http://iclub.test/');

  await page.evaluate(() => {
    window.i18n = { getLang: () => 'en' };
    window.__calls = [];
    window.__profile = { exam_series:'June 2027', target_grade:'A', total_student_hours_available:12, mathematics_hours_budget:6, active_week_no:20 };
    window.__caps = { program_key:'math_as_p1_p5', rollout_state:'controlled_beta', core_access:true, ai_assist:false, mentor_care_entitled:false, mentor_assignment_active:false, mentor_authority:false, kill_switch:false };
    window.__progress = {
      P1:{ component_code:'P1', placement_status:'conservative_foundation', route:'foundation', profile_complete:true, content_ready:true, stage0_complete:true, screening:{required_items:24,required_areas:8,answered_items:24,answered_areas:8,accuracy_pct:75}, active_session:null, max_unlocked_stage:2, foundation_learning_access:true },
      P5:{ component_code:'P5', placement_status:'conservative_foundation', route:'foundation', profile_complete:true, content_ready:true, stage0_complete:true, screening:{required_items:15,required_areas:5,answered_items:15,answered_areas:5,accuracy_pct:75}, active_session:null, max_unlocked_stage:2, foundation_learning_access:true }
    };
    window.__state = {
      P1:{ engine_version:'objective_state_v1', components:[{component_code:'P1',operational_stage:2,coverage_pct:45,levels:{L0:20,L1:5,L2:15,L3:5}}], skills:[] },
      P5:{ engine_version:'objective_state_v1', components:[{component_code:'P5',operational_stage:2,coverage_pct:42,levels:{L0:16,L1:5,L2:11,L3:4}}], skills:[] }
    };
    window.__recovery = {
      P1:{
        component_code:'P1', active:true, missed_days:25, recovery_mode:'source_gap_review', progress_retained:true,
        revalidation_recommended:true, revalidation_required_for_readiness:false,
        revalidation:{ available:true, case_id:'00000000-0000-4000-8000-000000020801', status:'recommended', prior_stage:2, prior_coverage_pct:45, selected_skill_count:1, passed_skill_count:0, failed_skill_count:0, notice_required:true, academic_state_mutation_allowed:false, items:[{item_order:1,prior_level:2,status:'pending',passed:null}] }
      },
      P5:{ component_code:'P5', active:true, missed_days:25, recovery_mode:'source_gap_review', progress_retained:true, revalidation_recommended:false, revalidation:{available:false} }
    };
    window.__session = null;

    window.sb = { rpc: async (name,args={}) => {
      window.__calls.push({name,args});
      if (name === 'get_exam_prep_capabilities_v1') return {data:[window.__caps],error:null};
      if (name === 'get_my_exam_prep_beta_invitation_v1') return {data:{invited:false,invitations:[]},error:null};
      if (name === 'get_exam_prep_exam_profile_v1') return {data:[window.__profile],error:null};
      if (name === 'get_exam_prep_diagnostic_progress_safe_v1') return {data:window.__progress[args.p_component_code],error:null};
      if (name === 'get_exam_prep_state_safe_v1') return {data:window.__state[args.p_component_code],error:null};
      if (name === 'get_exam_prep_recovery_safe_v2') return {data:JSON.parse(JSON.stringify(window.__recovery[args.p_component_code])),error:null};
      if (name === 'authorize_exam_prep_revalidation_item_safe_v1') return {data:{authorization_id:'00000000-0000-4000-8000-000000020802',session_id:null,case_id:args.p_case_id,item_order:args.p_item_order,component_code:'P1',academic_credit:false,resumed:false},error:null};
      if (name === 'start_exam_prep_session_safe_v1') {
        window.__session = {session_id:'00000000-0000-4000-8000-000000020803',status:'active',component_code:'P1',session_type:'retest',total_items:1,items:[{item_order:1,item_kind:'question',primary_skill_code:'P1-INTERNAL-DO-NOT-SHOW',answered:false,qtype:'mcq',text:'Which value is equal to 2 + 2?',options:['3','4','5']}]};
        return {data:{session_id:window.__session.session_id,status:'active',component_code:'P1',session_type:'retest',total_items:1,resumed:false},error:null};
      }
      if (name === 'get_exam_prep_session_safe_v1') return {data:JSON.parse(JSON.stringify(window.__session)),error:null};
      if (name === 'submit_exam_prep_response_safe_v1') {
        window.__session.items[0].answered = true;
        return {data:{item_order:1,is_correct:false,verification_status:'app_checked_noncredit'},error:null};
      }
      if (name === 'finalize_exam_prep_session_safe_v1') {
        window.__session.status = 'finalized';
        window.__recovery.P1.revalidation.status = 'refresh_recommended';
        window.__recovery.P1.revalidation.failed_skill_count = 1;
        window.__recovery.P1.revalidation.items[0] = {item_order:1,prior_level:2,status:'completed',passed:false};
        return {data:{session_id:window.__session.session_id,status:'finalized',answered:1,total_items:1,machine_correct:0,machine_total:1,replayed:false},error:null};
      }
      if (name === 'generate_exam_prep_weekly_plan_safe_v3') return {data:{plan_id:'00000000-0000-4000-8000-000000020804',component_code:'P1',progress_retained:true,revalidation_refresh_applied:true,revalidation_refresh_count:1,academic_stage_changed_by_recovery:false},error:null};
      return {data:null,error:{message:`unexpected rpc ${name}`}};
    }};
  });

  await page.addScriptTag({path:path.resolve('exam-prep/exam-prep-api.js')});
  await page.addScriptTag({path:path.resolve('exam-prep/exam-prep-host.js')});
  await page.addScriptTag({path:path.resolve('exam-prep/exam-prep-live.js')});
  await page.addScriptTag({path:path.resolve('exam-prep/exam-prep-recovery.js')});

  const assert = (condition,message) => { if (!condition) throw new Error(message); };

  await page.evaluate(async () => {
    await window.iClubExamPrep.syncSubjectHub({subjectKey:'mathematics',language:'en'});
    await window.iClubExamPrep.open({subjectKey:'mathematics',language:'en'});
  });

  await page.waitForSelector('[data-ep-recovery-check="P1"]');
  let text = await page.locator('#exam-prep-host-root').textContent();
  assert(text.includes('A study break does not cancel your previous results.'),'progress-preservation notice missing');
  assert(text.includes('Check retained knowledge'),'retained-knowledge action missing');
  assert(!text.includes('source_gap_review'),'internal recovery mode leaked');
  assert(!text.includes('P1-INTERNAL-DO-NOT-SHOW'),'internal skill code leaked before check');

  await page.click('[data-ep-recovery-check="P1"]');
  await page.waitForSelector('[data-ep-recovery-submit]');
  text = await page.locator('#exam-prep-host-root').textContent();
  assert(text.includes('Short check of retained knowledge'),'knowledge-check screen missing');
  assert(text.includes('This short check cannot erase previous results.'),'non-destructive explanation missing');
  assert(!text.includes('P1-INTERNAL-DO-NOT-SHOW'),'internal skill code leaked on question screen');

  await page.check('input[name="ep_recovery_answer"][value="0"]');
  await page.click('[data-ep-recovery-submit]');
  await page.waitForFunction(() => document.querySelector('#exam-prep-host-root')?.textContent?.includes('A brief refresh is recommended for some topics.'));

  text = await page.locator('#exam-prep-host-root').textContent();
  assert(text.includes('Previous progress and history are not deleted'),'failed confirmation must explicitly preserve prior progress');
  assert(!text.includes('app_checked_noncredit'),'internal verification status leaked');
  assert(!text.includes('RECOVERY_REFRESH_RETAINED_SKILL'),'internal planner action leaked');

  const result = await page.evaluate(() => ({calls:window.__calls,text:document.querySelector('#exam-prep-host-root').textContent}));
  const names = result.calls.map(x => x.name);
  for (const name of [
    'get_exam_prep_recovery_safe_v2','authorize_exam_prep_revalidation_item_safe_v1','start_exam_prep_session_safe_v1',
    'get_exam_prep_session_safe_v1','submit_exam_prep_response_safe_v1','finalize_exam_prep_session_safe_v1','generate_exam_prep_weekly_plan_safe_v3'
  ]) assert(names.includes(name),`${name} missing from retained-knowledge flow`);

  const auth = result.calls.find(x => x.name === 'authorize_exam_prep_revalidation_item_safe_v1');
  assert(auth.args.p_item_order === 1,'wrong revalidation item authorized');
  const submit = result.calls.find(x => x.name === 'submit_exam_prep_response_safe_v1');
  assert(submit && submit.args.p_payload && !('mastery' in submit.args.p_payload) && !('skill_state' in submit.args.p_payload),'learner payload must not write academic state');
  const plan = result.calls.find(x => x.name === 'generate_exam_prep_weekly_plan_safe_v3');
  assert(plan.args.p_component_code === 'P1','failed P1 check must not regenerate P5 plan');

  await browser.close();
  console.log('P2-08 retained-knowledge learner flow: PASS');
})().catch(error => { console.error(error); process.exit(1); });
