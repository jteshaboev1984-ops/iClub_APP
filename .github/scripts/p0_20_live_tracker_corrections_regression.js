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
    window.__profile = { exam_series: 'May/June 2027', target_grade: 'A', total_student_hours_available: 12, mathematics_hours_budget: 5, active_week_no: 1 };
    window.__caps = { program_key: 'math_as_p1_p5', rollout_state: 'controlled_beta', core_access: true, ai_assist: false, mentor_care_entitled: false, mentor_assignment_active: false, mentor_authority: false, kill_switch: false };
    window.__progress = {
      P1: { component_code: 'P1', placement_status: 'complete', route: 'foundation', profile_complete: true, content_ready: true, stage0_complete: true, screening: { required_items: 24, required_areas: 8, answered_items: 24, answered_areas: 8 }, active_session: null },
      P5: { component_code: 'P5', placement_status: 'complete', route: 'foundation', profile_complete: true, content_ready: true, stage0_complete: true, screening: { required_items: 15, required_areas: 5, answered_items: 15, answered_areas: 5 }, active_session: null }
    };
    window.__state = {
      P1: { engine_version: 'objective_state_v1', components: [{ component_code: 'P1', operational_stage: 1, coverage_pct: 0, levels: { L0: 45, L1: 0, L2: 0, L3: 0 } }], skills: [] },
      P5: { engine_version: 'objective_state_v1', components: [{ component_code: 'P5', operational_stage: 1, coverage_pct: 0, levels: { L0: 36, L1: 0, L2: 0, L3: 0 } }], skills: [] }
    };
    window.__tracker = {
      P1: {
        component_code: 'P1', denominator_count: 45, area_count: 8, coverage_count: 1, coverage_pct: 2.22, open_correction_count: 1,
        areas: [
          { official_syllabus_section: '1.1 Quadratics', skill_count: 6, coverage_count: 1, skills: [
            { sequence_no: 1, skill_code: 'P1-QUA-01', objective_level: 2, coverage_confirmed: true, evidence_total: 4, correction_case_id: null },
            { sequence_no: 2, skill_code: 'P1-QUA-02', objective_level: 1, coverage_confirmed: false, evidence_total: 2, correction_case_id: '00000000-0000-4000-8000-000000002001' }
          ]},
          { official_syllabus_section: '1.2 Functions', skill_count: 8, coverage_count: 0, skills: [
            { sequence_no: 7, skill_code: 'P1-FUN-01', objective_level: 0, coverage_confirmed: false, evidence_total: 0, correction_case_id: null }
          ]}
        ]
      },
      P5: {
        component_code: 'P5', denominator_count: 36, area_count: 5, coverage_count: 0, coverage_pct: 0, open_correction_count: 0,
        areas: [
          { official_syllabus_section: '5.1 Representation of data', skill_count: 10, coverage_count: 0, skills: [
            { sequence_no: 1, skill_code: 'P5-DAT-01', objective_level: 0, coverage_confirmed: false, evidence_total: 0, correction_case_id: null }
          ]}
        ]
      }
    };
    window.__detail = {
      component_code: 'P1', skill_code: 'P1-QUA-01', sequence_no: 1, official_syllabus_section: '1.1 Quadratics',
      description: 'Приводить квадратный трёхчлен к completed-square form и извлекать vertex/shape information.',
      state: { objective_level: 2, coverage_confirmed: true, evidence_total: 4, unresolved_correction_count: 0 },
      prerequisites: [
        { code: 'PR-ALG-03', kind: 'foundation', label: 'Раскрытие скобок и факторизация.', foundation_status: 'secure' },
        { code: 'PR-GRF-01', kind: 'foundation', label: 'Чтение графиков.', foundation_status: 'unknown' }
      ],
      evidence_history: [
        { evidence_type: 'diagnostic', verification_status: 'app_verified', is_correct: true, created_at: '2026-09-07T06:00:00Z' },
        { evidence_type: 'learning', verification_status: 'self_reviewed', is_correct: null, created_at: '2026-09-07T06:30:00Z' }
      ],
      correction_history: [],
      resources: { book_chapter: 'Complete Pure Mathematics 1, Ch1 Quadratics', book_pages: 'pp. 2–20' }
    };
    window.__queue = {
      component_code: 'P1', active_count: 1, retest_due_count: 1,
      cases: [{
        correction_case_id: '00000000-0000-4000-8000-000000002001', skill_code: 'P1-QUA-02', official_syllabus_section: '1.1 Quadratics',
        description: 'Использовать discriminant для определения числа и типа действительных корней.', status: 'retest_due', process_step: 'delayed_retest',
        retest_due_at: '2026-09-07T05:00:00Z', can_start_retest: true
      }],
      recent_resolved: []
    };

    window.sb = { rpc: async (name, args = {}) => {
      window.__calls.push({ name, args });
      if (name === 'get_exam_prep_capabilities_v1') return { data: [window.__caps], error: null };
      if (name === 'get_my_exam_prep_beta_invitation_v1') return { data: { invited: false, invitations: [] }, error: null };
      if (name === 'get_exam_prep_exam_profile_v1') return { data: [window.__profile], error: null };
      if (name === 'get_exam_prep_diagnostic_progress_safe_v1') return { data: window.__progress[args.p_component_code], error: null };
      if (name === 'get_exam_prep_state_safe_v1') return { data: window.__state[args.p_component_code], error: null };
      if (name === 'get_exam_prep_syllabus_tracker_safe_v1') return { data: window.__tracker[args.p_component_code], error: null };
      if (name === 'get_exam_prep_skill_detail_safe_v1') return { data: window.__detail, error: null };
      if (name === 'get_exam_prep_correction_queue_safe_v1') return { data: window.__queue, error: null };
      return { data: null, error: { message: `unexpected rpc ${name}` } };
    }};
  });

  await page.addScriptTag({ path: path.resolve('exam-prep/exam-prep-api.js') });
  await page.addScriptTag({ path: path.resolve('exam-prep/exam-prep-host.js') });
  await page.addScriptTag({ path: path.resolve('exam-prep/exam-prep-live.js') });
  await page.addScriptTag({ path: path.resolve('exam-prep/exam-prep-learner-views.js') });

  const assert = (condition, message) => { if (!condition) throw new Error(message); };

  await page.evaluate(async () => {
    await window.iClubExamPrep.syncSubjectHub({ subjectKey: 'mathematics', language: 'en' });
    await window.iClubExamPrep.open({ subjectKey: 'mathematics', language: 'en' });
  });

  await page.waitForSelector('[data-ep-views-tracker="P1"]');
  await page.click('[data-ep-views-tracker="P1"]');
  await page.waitForFunction(() => document.querySelector('#exam-prep-host-root')?.textContent.includes('Syllabus progress'));
  let visible = await page.locator('#exam-prep-host-root').textContent();
  assert(visible.includes('1 / 45'), 'P1 tracker must preserve the 45-skill denominator');
  assert(visible.includes('Quadratics') && visible.includes('Functions'), 'P1 tracker must group by learner-facing syllabus areas');
  assert(!visible.includes('P1-QUA-01') && !visible.includes('objective_state_v1'), 'tracker must not expose internal codes/engine terminology');

  await page.click('[data-ep-views-skill="P1-QUA-01"]');
  await page.waitForFunction(() => document.querySelector('#exam-prep-host-root')?.textContent.includes('Skill detail'));
  visible = await page.locator('#exam-prep-host-root').textContent();
  assert(visible.includes('Foundation prerequisites') && visible.includes('Check history') && visible.includes('Resources'), 'skill detail must expose prerequisites, evidence history and resources');
  assert(visible.includes('Complete Pure Mathematics 1, Ch1 Quadratics'), 'skill detail must expose approved book resource metadata');
  assert(!visible.includes('P1-QUA-01') && !visible.includes('PR-ALG-03') && !visible.includes('Раскрытие скобок'), 'English skill detail must not expose internal codes or untranslated Russian canonical labels');

  await page.click('[data-ep-views-corrections="P1"]');
  await page.waitForFunction(() => document.querySelector('#exam-prep-host-root')?.textContent.includes('Delayed check') || document.querySelector('#exam-prep-host-root')?.textContent.includes('Check again'));
  visible = await page.locator('#exam-prep-host-root').textContent();
  assert(visible.includes('Corrections') && visible.includes('Check again') && visible.includes('Open weekly plan'), 'correction queue must show learner action and route back to the weekly plan');
  assert(!visible.includes('P1-QUA-02') && !visible.includes('retest_due'), 'correction queue must not expose internal skill/status codes');

  await page.evaluate(async () => window.iClubExamPrepHostInternal.learnerViews.openTracker('P5'));
  await page.waitForFunction(() => document.querySelector('#exam-prep-host-root')?.textContent.includes('0 / 36'));
  visible = await page.locator('#exam-prep-host-root').textContent();
  assert(visible.includes('Representation of data'), 'P5 tracker must use the separate five-area syllabus map');
  assert(!visible.includes('P5-DAT-01'), 'P5 tracker must keep internal skill code hidden');

  const calls = await page.evaluate(() => window.__calls);
  const trackerCalls = calls.filter(x => x.name === 'get_exam_prep_syllabus_tracker_safe_v1');
  assert(trackerCalls.some(x => x.args.p_component_code === 'P1') && trackerCalls.some(x => x.args.p_component_code === 'P5'), 'P1/P5 tracker calls must remain component-scoped');
  assert(calls.some(x => x.name === 'get_exam_prep_skill_detail_safe_v1' && x.args.p_component_code === 'P1' && x.args.p_skill_code === 'P1-QUA-01'), 'skill detail must use the safe component+skill RPC');
  assert(calls.some(x => x.name === 'get_exam_prep_correction_queue_safe_v1' && x.args.p_component_code === 'P1'), 'correction queue must use the safe component RPC');

  await browser.close();
  console.log('P0-20 live syllabus tracker / skill detail / corrections flow: PASS');
})().catch(error => { console.error(error); process.exit(1); });