const { chromium } = require('playwright');
const path = require('path');

(async () => {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();

  await page.route('http://iclub.test/', route => route.fulfill({
    status: 200,
    contentType: 'text/html',
    body: '<!doctype html><html><head></head><body><div id="exam-prep-host-root"></div></body></html>'
  }));
  await page.goto('http://iclub.test/');

  await page.evaluate(() => {
    window.__calls = [];
    window.__workflowFail = false;
    const placement = component => ({
      component_code: component,
      available: true,
      placement_status: 'screening_incomplete',
      provisional_route: 'pending_evidence',
      stage0_complete: false,
      profile_complete: true,
      content_ready: true,
      ambiguity: true,
      screening: component === 'P1'
        ? { required_items: 24, required_areas: 8, answered_items: 5, answered_areas: 3 }
        : { required_items: 15, required_areas: 5, answered_items: 4, answered_areas: 2 },
      prerequisites: { unknown_count: 4, blocker_count: 0 },
      next_action_code: 'continue_entry_check'
    });
    const workflow = component => ({
      contract_version: 'p2_13_c24_v1',
      component_code: component,
      workflow_type: 'component_specific_full_placement',
      placement_model: 'multi_session',
      single_session_completion_required: false,
      time_based_stage_completion: false,
      broad_screening: {
        phase_key: 'broad_screening',
        required_items: component === 'P1' ? 24 : 15,
        required_areas: component === 'P1' ? 8 : 5,
        delivery_model: 'governed_short_packages',
        can_span_sessions: true,
        fixed_duration_minutes: null
      },
      targeted_confirmation: { usage: 'only_if_needed', min_items: 3, max_items: 5 },
      human_confirmation: { mentor_required_for_core: false, core_conservative_route_allowed: true },
      safeguards: { p1_p5_separate: true, duration_cannot_complete_placement: true }
    });
    window.sb = { rpc: async (name, args = {}) => {
      window.__calls.push({ name, args });
      if (name === 'get_exam_prep_placement_result_safe_v1') return { data: placement(args.p_component_code), error: null };
      if (name === 'get_exam_prep_stage0_workflow_safe_v1') {
        if (window.__workflowFail) return { data: null, error: { message: 'temporary workflow endpoint skew' } };
        return { data: workflow(args.p_component_code), error: null };
      }
      return { data: null, error: { message: `unexpected rpc ${name}` } };
    }};
  });

  await page.addScriptTag({ path: path.resolve('exam-prep/exam-prep-api.js') });
  await page.evaluate(() => {
    window.iClubExamPrepHostInternal.lastCapabilities = {
      rolloutState: 'controlled_beta', coreAccess: true, killSwitch: false,
      aiAssist: false, mentorCareEntitled: false, mentorAssignmentActive: false, mentorAuthority: false
    };
  });
  await page.addScriptTag({ path: path.resolve('exam-prep/exam-prep-overview-placement.js') });

  const assert = (condition, message) => { if (!condition) throw new Error(message); };

  async function open(languageMarker, component = 'P1') {
    await page.evaluate(({ languageMarker, component }) => {
      document.querySelector('#exam-prep-host-root').textContent = languageMarker;
      return window.iClubExamPrepHostInternal.overviewPlacementViews.openPlacement(component);
    }, { languageMarker, component });
    await page.waitForSelector('[data-ep-placement-screen] .ep-placement-summary');
    return page.locator('#exam-prep-host-root').textContent();
  }

  let visible = await open('Overview', 'P1');
  assert(visible.includes('How the check works'), 'English placement workflow heading missing');
  assert(visible.includes('The entry diagnostic runs in short blocks, so you do not need to finish everything at once.'), 'English short-block explanation missing');
  assert(visible.includes('Full route placement may take several sessions'), 'English multi-session explanation missing');
  assert(visible.includes('only when the result is unclear'), 'English targeted-confirmation explanation missing');
  assert(!visible.includes('multi_session') && !visible.includes('governed_short_packages') && !visible.includes('p2_13_c24_v1'), 'internal workflow terms leaked to learner UI');
  assert(!/45\s*[-–]\s*60/.test(visible) && !/155\s*[-–]\s*200/.test(visible), 'unsupported duration claim leaked to learner UI');

  visible = await open('Обзор', 'P1');
  assert(visible.includes('Как проходит проверка'), 'Russian placement workflow heading missing');
  assert(visible.includes('Входная диагностика проходит короткими блоками — не нужно выполнять всё за один раз.'), 'Russian short-block explanation missing');
  assert(visible.includes('Для полного определения маршрута может понадобиться несколько сессий'), 'Russian multi-session explanation missing');
  assert(visible.includes('только если результат неоднозначный'), 'Russian targeted-confirmation explanation missing');

  visible = await open('Umumiy ko‘rinish', 'P1');
  assert(visible.includes('Tekshiruv qanday o‘tadi'), 'Uzbek placement workflow heading missing');
  assert(visible.includes('Kirish diagnostikasi qisqa bloklarda o‘tadi — hammasini bir martada bajarish shart emas.'), 'Uzbek short-block explanation missing');
  assert(visible.includes('O‘quv yo‘nalishini to‘liq aniqlash uchun bir necha sessiya'), 'Uzbek multi-session explanation missing');
  assert(visible.includes('faqat natija noaniq bo‘lsa'), 'Uzbek targeted-confirmation explanation missing');

  await page.evaluate(() => { window.__workflowFail = true; });
  visible = await open('Overview', 'P5');
  assert(visible.includes('4 / 15') && visible.includes('2 / 5'), 'placement result must still render when the new workflow RPC is unavailable');
  assert(!visible.includes('Could not load this information'), 'workflow endpoint skew must fail soft without breaking placement');
  assert(!(await page.locator('[data-ep-placement-workflow]').count()), 'workflow note should be omitted when its contract RPC is unavailable');

  const calls = await page.evaluate(() => window.__calls);
  const workflowCalls = calls.filter(x => x.name === 'get_exam_prep_stage0_workflow_safe_v1');
  assert(workflowCalls.some(x => x.args.p_component_code === 'P1') && workflowCalls.some(x => x.args.p_component_code === 'P5'), 'C24 workflow RPC must remain component-scoped');

  await browser.close();
  console.log('P2-13 Stage-0 learner workflow / multilingual copy: PASS');
})().catch(error => { console.error(error); process.exit(1); });
