const { chromium } = require('playwright');
const path = require('path');

(async () => {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();

  await page.route('http://iclub.test/', async route => {
    await route.fulfill({
      status: 200,
      contentType: 'text/html',
      body: `<!doctype html><html><head></head><body>
        <section id="courses-subject-hub">
          <div id="subject-hub-exam-prep-entry" hidden aria-hidden="true"><span id="subject-hub-exam-prep-title"></span><span id="subject-hub-exam-prep-sub"></span></div>
          <div id="exam-prep-host-root" hidden aria-hidden="true"></div>
        </section>
      </body></html>`
    });
  });
  await page.goto('http://iclub.test/');

  await page.evaluate(() => {
    window.__calls = [];
    window.__profile = null;
    window.__progress = {
      P1: {
        component_code: 'P1', placement_status: 'screening_incomplete', route: 'pending_evidence', profile_complete: true, content_ready: true, stage0_complete: false,
        screening: { required_items: 24, required_areas: 8, answered_items: 0, answered_areas: 0, remaining_items: 24, remaining_areas: 8, accuracy_pct: null },
        active_session: null, next_assessment: { assessment_id: 33, assessment_key: 'p1_test_diag', title_en: 'P1 diagnostic', items: 1, sections: 1 }, max_unlocked_stage: 0, foundation_learning_access: false
      },
      P5: {
        component_code: 'P5', placement_status: 'screening_incomplete', route: 'pending_evidence', profile_complete: true, content_ready: true, stage0_complete: false,
        screening: { required_items: 15, required_areas: 5, answered_items: 0, answered_areas: 0, remaining_items: 15, remaining_areas: 5, accuracy_pct: null },
        active_session: null, next_assessment: { assessment_id: 45, assessment_key: 'p5_test_diag', title_en: 'P5 diagnostic', items: 1, sections: 1 }, max_unlocked_stage: 0, foundation_learning_access: false
      }
    };
    window.__session = null;
    window.__caps = {
      program_key: 'math_as_p1_p5', rollout_state: 'controlled_beta', core_access: true,
      ai_assist: false, mentor_care_entitled: false, mentor_assignment_active: false, mentor_authority: false, kill_switch: false
    };
    window.sb = {
      rpc: async (name, args = {}) => {
        window.__calls.push({ name, args });
        if (name === 'get_exam_prep_capabilities_v1') return { data: [window.__caps], error: null };
        if (name === 'get_my_exam_prep_beta_invitation_v1') return { data: { invited: false, invitations: [], consent_scope: 'exam_prep_controlled_beta_v1', consent_copy_version: 'controlled_beta_v1_2026_09_04' }, error: null };
        if (name === 'get_exam_prep_exam_profile_v1') return { data: window.__profile ? [window.__profile] : [], error: null };
        if (name === 'save_exam_prep_exam_profile_v1') {
          window.__profile = {
            exam_series: args.p_exam_series, target_grade: args.p_target_grade,
            total_student_hours_available: args.p_total_student_hours_available,
            mathematics_hours_budget: args.p_mathematics_hours_budget, active_week_no: 1
          };
          return { data: window.__profile, error: null };
        }
        if (name === 'get_exam_prep_diagnostic_progress_safe_v1') return { data: window.__progress[args.p_component_code], error: null };
        if (name === 'start_exam_prep_next_diagnostic_safe_v1') {
          const component = args.p_component_code;
          window.__session = {
            session_id: '00000000-0000-4000-8000-000000009901', status: 'active', component_code: component,
            session_type: 'diagnostic', total_items: 1,
            items: [{ item_order: 1, item_kind: 'question', primary_skill_code: component === 'P1' ? 'P1-QUA-01' : 'P5-DAT-01', reserve_role: 'diagnostic', answered: false, qtype: 'mcq', text: 'What is 2 + 2?', options: ['2','4','6','8'] }]
          };
          return { data: { session_id: window.__session.session_id, status: 'active', component_code: component, session_type: 'diagnostic', total_items: 1, resumed: false }, error: null };
        }
        if (name === 'get_exam_prep_session_safe_v1') return { data: window.__session, error: null };
        if (name === 'submit_exam_prep_response_safe_v1') {
          window.__session.items[0].answered = true;
          return { data: { response_id: '00000000-0000-4000-8000-000000009902', item_order: 1, is_correct: args.p_payload.picked_index === 1, explanation: '2 + 2 = 4.', replayed: false }, error: null };
        }
        if (name === 'finalize_exam_prep_session_safe_v1') {
          window.__session.status = 'finalized';
          window.__progress.P1.screening.answered_items = 1;
          window.__progress.P1.screening.answered_areas = 1;
          return { data: { session_id: window.__session.session_id, status: 'finalized', answered: 1, total_items: 1 }, error: null };
        }
        return { data: null, error: { message: `unexpected rpc ${name}` } };
      }
    };
    localStorage.setItem('p017_live_sentinel', 'unchanged');
  });

  await page.addScriptTag({ path: path.resolve('exam-prep/exam-prep-api.js') });
  await page.addScriptTag({ path: path.resolve('exam-prep/exam-prep-host.js') });
  await page.addScriptTag({ path: path.resolve('exam-prep/exam-prep-live.js') });

  const assert = (condition, message) => { if (!condition) throw new Error(message); };

  let result = await page.evaluate(async () => {
    const synced = await window.iClubExamPrep.syncSubjectHub({ subjectKey: 'mathematics', language: 'en' });
    const opened = await window.iClubExamPrep.open({ subjectKey: 'mathematics', language: 'en' });
    return {
      synced, opened,
      profileVisible: Boolean(document.querySelector('[data-ep-live-profile-form]')),
      version: window.iClubExamPrep.liveFlowVersion,
      rootText: document.querySelector('#exam-prep-host-root').textContent
    };
  });
  assert(result.synced && result.opened, 'controlled beta Core must open live learner flow');
  assert(result.profileVisible, 'missing profile must show profile form');
  assert(result.version === 'p017live1', 'live flow wrapper version missing');
  assert(result.rootText.includes('Set your exam plan first'), 'profile copy missing');

  await page.fill('input[name="exam_series"]', 'Oct/Nov 2026');
  await page.fill('input[name="target_grade"]', 'A');
  await page.fill('input[name="total_hours"]', '12');
  await page.fill('input[name="math_hours"]', '6');
  await page.click('[data-ep-live-save-profile]');
  await page.waitForFunction(() => document.querySelector('[data-ep-live-start="P1"]'));

  result = await page.evaluate(() => ({
    text: document.querySelector('#exam-prep-host-root').textContent,
    calls: window.__calls.map(x => x.name),
    profile: window.__profile
  }));
  assert(result.text.includes('0 / 24') && result.text.includes('0 / 15'), 'P1/P5 screening progress missing');
  assert(result.profile.mathematics_hours_budget === 6, 'profile mathematics budget not saved through RPC');
  assert(result.calls.includes('save_exam_prep_exam_profile_v1'), 'profile save RPC missing');

  await page.click('[data-ep-live-start="P1"]');
  await page.waitForFunction(() => document.querySelector('input[name="ep_live_answer"]'));
  await page.check('input[name="ep_live_answer"][value="1"]');
  await page.click('[data-ep-live-submit]');
  await page.waitForFunction(() => document.querySelector('#exam-prep-host-root')?.textContent.includes('1 / 24'));

  result = await page.evaluate(() => ({
    text: document.querySelector('#exam-prep-host-root').textContent,
    calls: window.__calls,
    sentinel: localStorage.getItem('p017_live_sentinel')
  }));
  const names = result.calls.map(x => x.name);
  assert(names.includes('start_exam_prep_next_diagnostic_safe_v1'), 'diagnostic start RPC missing');
  assert(names.includes('get_exam_prep_session_safe_v1'), 'session fetch RPC missing');
  assert(names.includes('submit_exam_prep_response_safe_v1'), 'answer submission RPC missing');
  assert(names.includes('finalize_exam_prep_session_safe_v1'), 'diagnostic finalization RPC missing');
  const submit = result.calls.find(x => x.name === 'submit_exam_prep_response_safe_v1');
  assert(submit.args.p_payload.picked_index === 1, 'MCQ must submit zero-based picked_index');
  assert(result.text.includes('1 / 24'), 'dashboard must refresh after finalized diagnostic package');
  assert(result.sentinel === 'unchanged', 'live flow must not write legacy/local storage state');

  await browser.close();
  console.log('P0-17 live diagnostic browser flow: PASS');
})().catch(error => {
  console.error(error);
  process.exit(1);
});