const { chromium } = require('playwright');
const path = require('path');

(async () => {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();
  await page.route('http://iclub.test/', route => route.fulfill({
    status: 200,
    contentType: 'text/html',
    body: '<!doctype html><html><head></head><body><section id="courses-subject-hub"><div id="subject-hub-exam-prep-entry" hidden aria-hidden="true"><span id="subject-hub-exam-prep-title"></span><span id="subject-hub-exam-prep-sub"></span></div><div id="exam-prep-host-root" hidden aria-hidden="true"></div></section></body></html>'
  }));
  await page.goto('http://iclub.test/');

  await page.evaluate(() => {
    window.__calls = [];
    window.__profile = { exam_series:'Oct/Nov 2026', target_grade:'A', total_student_hours_available:12, mathematics_hours_budget:6, active_week_no:1 };
    window.__plan = {
      plan_id:'00000000-0000-4000-8000-000000009101', component_code:'P1', active_week_no:1, plan_version:1, recovery_mode:'normal',
      items:[{ priority_order:1, item_type:'learning', skill_code:'P1-CIR-01', correction_case_id:null, due_at:null, action_code:'BUILD_FIRST_COVERAGE', action_payload:{}, status:'pending' }]
    };
    window.__caps = { program_key:'math_as_p1_p5', rollout_state:'controlled_beta', core_access:true, ai_assist:false, mentor_care_entitled:false, mentor_assignment_active:false, mentor_authority:false, kill_switch:false };
    window.__progress = {
      P1:{ component_code:'P1', placement_status:'conservative_foundation', route:'foundation', profile_complete:true, content_ready:true, stage0_complete:true, screening:{required_items:24,required_areas:8,answered_items:24,answered_areas:8}, active_session:null },
      P5:{ component_code:'P5', placement_status:'screening_incomplete', route:'pending_evidence', profile_complete:true, content_ready:true, stage0_complete:false, screening:{required_items:15,required_areas:5,answered_items:0,answered_areas:0}, active_session:null }
    };
    window.__state = {
      P1:{ engine_version:'objective_state_v1', components:[{component_code:'P1',operational_stage:1,coverage_pct:0,levels:{L0:45,L1:0,L2:0,L3:0}}], skills:[] },
      P5:{ engine_version:'objective_state_v1', components:[{component_code:'P5',operational_stage:0,coverage_pct:0,levels:{L0:36,L1:0,L2:0,L3:0}}], skills:[] }
    };
    window.__session = null;

    const checks = [
      { check_order:1, check_kind:'mcq', prompt:'Which equality correctly links degrees and radians?', options:['90° = π rad','180° = π rad','180° = 2π rad','360° = π rad'] },
      { check_order:2, check_kind:'mcq', prompt:'What is (π/180) × (180/π)?', options:['π','180','1','π/180'] },
      { check_order:3, check_kind:'mcq', prompt:'What happens after converting degrees to radians and back?', options:['The original degree value is recovered','The value doubles','The value is divided by 180','The value becomes π times larger'] }
    ];

    window.sb = { rpc: async (name, args={}) => {
      window.__calls.push({ name, args: JSON.parse(JSON.stringify(args)) });
      if (name === 'get_exam_prep_capabilities_v1') return { data:[window.__caps], error:null };
      if (name === 'get_my_exam_prep_beta_invitation_v1') return { data:{invited:false,invitations:[]}, error:null };
      if (name === 'get_exam_prep_exam_profile_v1') return { data:[window.__profile], error:null };
      if (name === 'get_exam_prep_diagnostic_progress_safe_v1') return { data:window.__progress[args.p_component_code], error:null };
      if (name === 'get_exam_prep_state_safe_v1') return { data:window.__state[args.p_component_code], error:null };
      if (name === 'get_exam_prep_weekly_plan_safe_v2') return { data:window.__plan, error:null };
      if (name === 'generate_exam_prep_weekly_plan_safe_v3') return { data:{plan_id:window.__plan.plan_id,component_code:'P1',priority_count:1}, error:null };
      if (name === 'authorize_exam_prep_plan_item_safe_v1') return { data:{authorization_id:'00000000-0000-4000-8000-000000009102',plan_id:args.p_plan_id,priority_order:1,item_type:'learning',purpose:'learning'}, error:null };
      if (name === 'start_exam_prep_session_safe_v1') {
        window.__session = {
          session_id:'00000000-0000-4000-8000-000000009103', status:'active', component_code:'P1', session_type:'learning', total_items:2,
          items:[
            { item_order:1,item_kind:'question',primary_skill_code:'P1-CIR-01',answered:false,qtype:'mcq',text:'210° in exact radians?',options:['7π/6','6π/7','5π/6'] },
            { item_order:2,item_kind:'written',primary_skill_code:'P1-CIR-01',answered:false,written_prompt:'Explain why π/180 and 180/π are inverse conversion factors.',written_max_marks:7,understanding_checks:checks }
          ]
        };
        return { data:{session_id:window.__session.session_id,status:'active'}, error:null };
      }
      if (name === 'get_exam_prep_session_safe_v1') return { data:window.__session, error:null };
      if (name === 'submit_exam_prep_response_safe_v1') {
        const item = window.__session.items.find(x => x.item_order === args.p_item_order);
        item.answered = true;
        if (item.item_kind === 'written') {
          return { data:{
            item_order:item.item_order,
            verification_status:'self_reviewed',
            understanding_check:{
              submitted:true,total:3,correct:2,all_correct:false,
              results:[
                {check_order:1,is_correct:true,rationale:'180° and π radians represent the same half-turn.'},
                {check_order:2,is_correct:true,rationale:'π and 180 cancel, so the product is 1.'},
                {check_order:3,is_correct:false,rationale:'The second conversion reverses the first.'}
              ]
            }
          }, error:null };
        }
        return { data:{item_order:item.item_order,is_correct:true,explanation:'Correct.'}, error:null };
      }
      if (name === 'finalize_exam_prep_session_safe_v1') {
        window.__session.status = 'finalized';
        return { data:{session_id:window.__session.session_id,status:'finalized',answered:2,total_items:2}, error:null };
      }
      return { data:null, error:{message:`unexpected rpc ${name}`} };
    }};
  });

  await page.addScriptTag({ path:path.resolve('exam-prep/exam-prep-api.js') });
  await page.addScriptTag({ path:path.resolve('exam-prep/exam-prep-host.js') });
  await page.addScriptTag({ path:path.resolve('exam-prep/exam-prep-live.js') });
  await page.addScriptTag({ path:path.resolve('exam-prep/exam-prep-written-understanding-ui.js') });

  const assert = (condition, message) => { if (!condition) throw new Error(message); };
  await page.evaluate(async () => {
    await window.iClubExamPrep.syncSubjectHub({subjectKey:'mathematics',language:'en'});
    await window.iClubExamPrep.open({subjectKey:'mathematics',language:'en'});
  });

  await page.waitForSelector('[data-ep-live-plan="P1"]');
  await page.click('[data-ep-live-plan="P1"]');
  await page.waitForSelector('[data-ep-live-plan-item="1"]');
  await page.click('[data-ep-live-plan-item="1"]');

  await page.waitForSelector('input[name="ep_live_answer"]');
  await page.check('input[name="ep_live_answer"][value="0"]');
  await page.click('[data-ep-live-submit]');

  await page.waitForSelector('textarea[name="ep_live_written_answer"]');
  await page.waitForSelector('[data-ep-written-understanding="true"]');
  let text = await page.locator('#exam-prep-host-root').textContent();
  assert(text.includes('Check your understanding'), 'learner-facing understanding heading missing');
  assert(text.includes('Which equality correctly links degrees and radians?'), 'first structured check missing');
  assert(!text.includes('correct_index'), 'answer-key metadata must never be visible');
  assert(!text.includes('app_checked_noncredit'), 'internal authority term must never be learner-visible');

  await page.fill('textarea[name="ep_live_written_answer"]', 'The factors multiply to 1, so the second conversion reverses the first.');
  const before = await page.evaluate(() => window.__calls.filter(x => x.name === 'submit_exam_prep_response_safe_v1').length);
  await page.click('[data-ep-live-submit]');
  await page.waitForSelector('[data-ep-written-understanding-error]:not([hidden])');
  const afterIncomplete = await page.evaluate(() => window.__calls.filter(x => x.name === 'submit_exam_prep_response_safe_v1').length);
  assert(afterIncomplete === before, 'incomplete structured checks must not submit the written response');
  text = await page.locator('#exam-prep-host-root').textContent();
  assert(text.includes('Answer all short questions first.'), 'incomplete-check learner message missing');

  await page.check('input[name="ep_written_understanding_1"][value="1"]');
  await page.check('input[name="ep_written_understanding_2"][value="2"]');
  await page.check('input[name="ep_written_understanding_3"][value="1"]');
  await page.click('[data-ep-live-submit]');

  await page.waitForFunction(() => document.querySelector('#exam-prep-host-root')?.textContent.includes('Understanding check: 2/3'));
  const result = await page.evaluate(() => ({ calls:window.__calls, text:document.querySelector('#exam-prep-host-root').textContent }));
  const written = result.calls.find(x => x.name === 'submit_exam_prep_response_safe_v1' && x.args.p_item_order === 2);
  assert(written, 'written submit RPC missing');
  assert(written.args.p_payload.artifact.text.includes('multiply to 1'), 'written explanation artifact missing');
  assert(Array.isArray(written.args.p_payload.understanding_checks), 'structured answers not attached to written payload');
  assert(JSON.stringify(written.args.p_payload.understanding_checks) === JSON.stringify([
    {check_order:1,picked_index:1},{check_order:2,picked_index:2},{check_order:3,picked_index:1}
  ]), 'structured answer payload mismatch');
  assert(result.text.includes('The second conversion reverses the first.'), 'server rationale for missed check must remain visible after final item');
  assert(result.text.includes('Weekly plan'), 'written completion must return to weekly plan');
  assert(!result.text.includes('P1-CIR-01'), 'internal skill code must not be learner-visible');

  await browser.close();
  console.log('Written understanding checks v1 browser regression: PASS');
})().catch(error => { console.error(error); process.exit(1); });
