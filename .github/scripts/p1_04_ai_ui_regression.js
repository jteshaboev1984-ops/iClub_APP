const { chromium } = require('playwright');
const path = require('path');
const fs = require('fs');
const aiSource = fs.readFileSync('exam-prep/exam-prep-ai-ui.js', 'utf8');
const hostCss = fs.readFileSync('exam-prep/exam-prep-host.css', 'utf8');
const liveSource = fs.readFileSync('exam-prep/exam-prep-live.js', 'utf8');
if (aiSource.includes('ensureStyle(') || aiSource.includes('ep-ai-ui-style') || aiSource.includes('document.createElement("style")')) throw new Error('runtime AI UI style injection returned');
if (!hostCss.includes('EXAM PREP AI TUTOR UX v2') || !hostCss.includes('.ep-ai-panel{')) throw new Error('centralized AI Tutor CSS contract missing');
if (!liveSource.includes('data-ep-live-active-assessment="true"')) throw new Error('real active-assessment AI blackout marker missing');


function assert(condition, message) {
  if (!condition) throw new Error(message);
}

(async () => {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();
  try {
    await page.setContent(`<!doctype html><html lang="en"><head></head><body>
      <div id="exam-prep-host-root" aria-hidden="false">
        <div class="ep-live-card"><div data-ep-overview-strip="P1"></div></div>
        <div class="ep-live-card"><div data-ep-overview-strip="P5"></div></div>
      </div>
    </body></html>`);

    await page.evaluate(() => {
      window.__aiCalls = [];
      window.i18n = { getLang: () => 'en' };
      window.iClubExamPrepHostInternal = {
        lastCapabilities: {
          rolloutState: 'controlled_beta',
          coreAccess: true,
          aiAssist: false,
          killSwitch: false
        },
        learnerCopy: {
          skillTitle: (code) => ({
            'P1-QUA-02': 'Discriminant and roots',
            'P1-QUA-01': 'Completing the square',
            'P1-INT-05': 'Volume of revolution',
            'P5-GEO-01': 'Geometric model'
          })[code] || ''
        }
      };
      window.sb = {
        functions: {
          invoke: async (name, options) => {
            window.__aiCalls.push({ name, body: options?.body || null });
            return {
              data: {
                request_id: '00000000-0000-4000-8000-000000000001',
                mode: 'fallback',
                message: `${options?.body?.component_code || ''} explanation`,
                academic_state_changed: false
              },
              error: null
            };
          }
        }
      };
    });

    await page.addScriptTag({ path: path.resolve('exam-prep/exam-prep-ai-ui.js') });
    await page.waitForTimeout(60);

    let state = await page.evaluate(() => ({
      panels: document.querySelectorAll('[data-ep-ai-panel]').length,
      calls: window.__aiCalls.length
    }));
    assert(state.panels === 0, 'Core-only learner must not see AI UI');
    assert(state.calls === 0, 'Dormant AI UI must not call endpoint');

    await page.evaluate(() => {
      window.iClubExamPrepHostInternal.lastCapabilities.aiAssist = true;
      document.querySelector('#exam-prep-host-root').setAttribute('data-ai-test-refresh', '1');
      document.querySelector('#exam-prep-host-root').appendChild(document.createComment('refresh'));
    });
    await page.waitForSelector('[data-ep-ai-panel="P1"]');
    await page.waitForSelector('[data-ep-ai-panel="P5"]');

    const text = await page.locator('#exam-prep-host-root').textContent();
    assert(text.includes('iClub AI Tutor'), 'Learner-facing AI Tutor title missing');
    for (const forbidden of ['AI Assist', 'controlled_beta', 'policy_version', 'runtime_status', 'source_card']) {
      assert(!text.includes(forbidden), `Internal AI term leaked to learner UI: ${forbidden}`);
    }

    await page.click('[data-ep-ai-panel="P1"] [data-ep-ai-action="progress_summary"]');
    await page.waitForFunction(() => document.querySelector('[data-ep-ai-panel="P1"] [data-ep-ai-output-text]')?.textContent === 'P1 explanation');

    await page.click('[data-ep-ai-panel="P5"] [data-ep-ai-action="weekly_plan_narration"]');
    await page.waitForFunction(() => document.querySelector('[data-ep-ai-panel="P5"] [data-ep-ai-output-text]')?.textContent === 'P5 explanation');

    await page.click('[data-ep-ai-panel="P1"] [data-ep-ai-action="repeated_error_summary"]');
    await page.waitForFunction(() => document.querySelector('[data-ep-ai-panel="P1"] [data-ep-ai-output-text]')?.textContent === 'P1 explanation');

    const calls = await page.evaluate(() => window.__aiCalls);
    assert(calls.length === 3, `Expected exactly 3 AI endpoint calls, got ${calls.length}`);
    assert(calls[0].name === 'exam-prep-ai', 'AI UI must call only the governed Edge Function');
    assert(calls[0].body.component_code === 'P1', 'P1 action crossed component boundary');
    assert(calls[0].body.interaction_type === 'progress_summary', 'P1 progress action type drifted');
    assert(calls[0].body.locale === 'en', 'UI language was not preserved');
    assert(calls[0].body.user_text === '', 'Context action must not collect unnecessary learner text');
    assert(calls[1].body.component_code === 'P5', 'P5 action crossed component boundary');
    assert(calls[1].body.interaction_type === 'weekly_plan_narration', 'P5 plan action type drifted');
    assert(calls[2].body.component_code === 'P1', 'Repeated-difficulty action crossed component boundary');
    assert(calls[2].body.interaction_type === 'repeated_error_summary', 'Repeated-difficulty action type drifted');
    assert(calls[2].body.user_text === '', 'Repeated-difficulty action must not collect free-form learner text');

    // Production-shaped dashboard: AI must be visible without relying on the retired overview-strip anchor.
    await page.evaluate(() => {
      window.__openedFromAi = '';
      document.querySelector('#exam-prep-host-root').innerHTML = `
        <section class="ep-live-dashboard-intro">
          <div><h3>Preparation by P1 and P5</h3></div>
        </section>
        <div class="ep-live-grid">
          <button type="button" data-ep-live-open-component="P1">Pure Mathematics 1</button>
          <button type="button" data-ep-live-open-component="P5">Probability & Statistics 1</button>
        </div>`;
      document.querySelectorAll('[data-ep-live-open-component]').forEach(button => {
        button.addEventListener('click', () => { window.__openedFromAi = button.dataset.epLiveOpenComponent; });
      });
    });
    await page.waitForSelector('[data-ep-ai-home-banner]');
    const homeBanner = await page.locator('[data-ep-ai-home-banner]').textContent();
    assert(homeBanner.includes('iClub AI Tutor is active'), 'Current dashboard did not expose visible AI Tutor entry');
    const callsBeforeDashboardOpen = await page.evaluate(() => window.__aiCalls.length);
    await page.click('[data-ep-ai-home-banner] [data-ep-ai-open-component="P1"]');
    assert(await page.evaluate(() => window.__openedFromAi) === 'P1', 'Dashboard AI Tutor entry did not route through the existing P1 card');
    assert(await page.evaluate(() => window.__aiCalls.length) === callsBeforeDashboardOpen, 'Dashboard AI Tutor entry caused an unexpected provider call');

    // Production-shaped component home: the paid AI capability must be visible beside the learner's next step.
    await page.evaluate(() => {
      document.querySelector('#exam-prep-host-root').innerHTML = `
        <section class="ep-component-home" data-ep-component-home="P1" data-ep-ai-plan-available="true" data-ep-ai-repeated-available="false">
          <header class="ep-component-hero">Pure Mathematics 1</header>
          <section class="ep-component-next"><button id="current-core-action" type="button">Start task</button></section>
          <section class="ep-component-progress-card">Progress</section>
        </section>`;
    });
    await page.waitForSelector('[data-ep-ai-panel="P1"].ep-ai-panel-featured');
    const featured = await page.evaluate(() => {
      const panel = document.querySelector('[data-ep-ai-panel="P1"]');
      const next = document.querySelector('.ep-component-next');
      return {
        visible: Boolean(panel),
        afterNext: next?.nextElementSibling === panel,
        coreVisible: Boolean(document.querySelector('#current-core-action'))
      };
    });
    assert(featured.visible && featured.afterNext, 'Current component home did not mount AI Tutor after the next-step card');
    assert(featured.coreVisible, 'Current component home AI Tutor displaced the Core next action');
    const actionVisibility = await page.evaluate(() => ({
      progressHidden: document.querySelector('[data-ep-ai-panel="P1"] [data-ep-ai-action="progress_summary"]')?.hidden,
      planHidden: document.querySelector('[data-ep-ai-panel="P1"] [data-ep-ai-action="weekly_plan_narration"]')?.hidden,
      repeatedHidden: document.querySelector('[data-ep-ai-panel="P1"] [data-ep-ai-action="repeated_error_summary"]')?.hidden
    }));
    assert(actionVisibility.progressHidden === false, 'AI Tutor progress action should remain available on component home');
    assert(actionVisibility.planHidden === false, 'AI Tutor hid a current-plan action despite an active plan');
    assert(actionVisibility.repeatedHidden === true, 'AI Tutor exposed repeated-difficulty action without repeated-gap context');
    assert(await page.evaluate(() => window.__aiCalls.length) === callsBeforeDashboardOpen, 'Component-home AI Tutor auto-called the provider');

    await page.evaluate(() => {
      document.querySelector('#exam-prep-host-root').innerHTML = `
        <section class="ep-result-screen"
          data-ep-session-result="11111111-1111-4111-8111-111111111111"
          data-ep-result-component="P1"
          data-ep-result-session-type="diagnostic">
          <article class="ep-result-item is-wrong" data-ep-result-kind="wrong" data-ep-result-item-order="3">
            <div class="ep-result-subblock">Recorded diagnostic feedback</div>
          </article>
        </section>`;
    });
    await page.waitForSelector('[data-ep-ai-error-action-wrap] [data-ep-ai-action="established_error_explanation"]');
    const mistakeText = await page.locator('[data-ep-ai-error-action-wrap]').textContent();
    assert(mistakeText.includes('Help me understand this mistake'), 'Finalized diagnostic AI Tutor action text missing');

    await page.click('[data-ep-ai-error-action-wrap] [data-ep-ai-action="established_error_explanation"]');
    await page.waitForFunction(() => document.querySelector('[data-ep-ai-error-action-wrap] [data-ep-ai-output-text]')?.textContent === 'P1 explanation');

    const errorCalls = await page.evaluate(() => window.__aiCalls);
    assert(errorCalls.length === 4, `Expected exactly 4 AI endpoint calls, got ${errorCalls.length}`);
    assert(errorCalls[3].name === 'exam-prep-ai', 'Diagnostic error action bypassed governed Edge Function');
    assert(errorCalls[3].body.component_code === 'P1', 'Diagnostic error action crossed component boundary');
    assert(errorCalls[3].body.interaction_type === 'established_error_explanation', 'Diagnostic error action type drifted');
    assert(errorCalls[3].body.session_id === '11111111-1111-4111-8111-111111111111', 'Diagnostic error action lost finalized session reference');
    assert(errorCalls[3].body.item_order === 3, 'Diagnostic error action lost item order');
    assert(errorCalls[3].body.locale === 'en', 'Diagnostic error action lost UI locale');
    assert(errorCalls[3].body.user_text === '', 'Diagnostic error action must not collect free-form learner text');

    const localizedMistakes = [
      { lang: 'ru', label: 'Помочь понять эту ошибку', width: 360 },
      { lang: 'uz', label: 'Bu xatoni tushunishga yordam ber', width: 390 },
      { lang: 'en', label: 'Help me understand this mistake', width: 430 }
    ];
    for (const row of localizedMistakes) {
      await page.setViewportSize({ width: row.width, height: 844 });
      await page.evaluate(({ lang }) => {
        window.i18n.getLang = () => lang;
        document.documentElement.lang = lang;
        document.querySelector('#exam-prep-host-root').innerHTML = `
          <section class="ep-result-screen"
            data-ep-session-result="22222222-2222-4222-8222-222222222222"
            data-ep-result-component="P5"
            data-ep-result-session-type="diagnostic">
            <article class="ep-result-item is-wrong" data-ep-result-kind="wrong" data-ep-result-item-order="2">
              <div class="ep-result-subblock">Recorded diagnostic feedback</div>
            </article>
          </section>`;
      }, row);
      await page.waitForSelector('[data-ep-ai-error-action-wrap] [data-ep-ai-action="established_error_explanation"]');
      const localized = await page.evaluate(() => {
        const button = document.querySelector('[data-ep-ai-error-action-wrap] [data-ep-ai-action="established_error_explanation"]');
        const item = document.querySelector('.ep-result-item.is-wrong');
        return {
          text: button?.textContent || '',
          documentWidth: document.documentElement.scrollWidth,
          innerWidth: window.innerWidth,
          buttonWidth: button?.getBoundingClientRect().width || 0,
          itemWidth: item?.getBoundingClientRect().width || 0
        };
      });
      assert(localized.text === row.label, `${row.lang.toUpperCase()} diagnostic AI action copy drifted: ${localized.text}`);
      assert(localized.documentWidth <= localized.innerWidth, `${row.lang.toUpperCase()} diagnostic AI action caused horizontal overflow: ${JSON.stringify(localized)}`);
      assert(localized.buttonWidth <= localized.itemWidth + 1, `${row.lang.toUpperCase()} diagnostic AI action exceeds result card: ${JSON.stringify(localized)}`);
    }

    await page.setViewportSize({ width: 390, height: 844 });
    await page.evaluate(() => {
      window.i18n.getLang = () => 'en';
      document.documentElement.lang = 'en';
      document.querySelector('#exam-prep-host-root').innerHTML = `
        <section data-ep-views-screen data-ep-ai-skill-detail="P1-QUA-02" data-ep-ai-skill-component="P1">
          <div class="ep-views-title">Quadratic equations</div>
          <div class="ep-views-summary"></div>
        </section>`;
    });
    await page.waitForSelector('[data-ep-ai-topic-action-wrap] [data-ep-ai-action="theory_explanation"]');
    const topicText = await page.locator('[data-ep-ai-topic-action-wrap]').textContent();
    assert(topicText.includes('Explain this topic to me'), 'Governed theory AI action text missing');

    await page.click('[data-ep-ai-topic-action-wrap] [data-ep-ai-action="theory_explanation"]');
    await page.waitForFunction(() => document.querySelector('[data-ep-ai-topic-action-wrap] [data-ep-ai-output-text]')?.textContent === 'P1 explanation');
    const topicCalls = await page.evaluate(() => window.__aiCalls);
    assert(topicCalls.length === 5, `Expected exactly 5 AI endpoint calls, got ${topicCalls.length}`);
    assert(topicCalls[4].body.component_code === 'P1', 'Theory action crossed component boundary');
    assert(topicCalls[4].body.interaction_type === 'theory_explanation', 'Theory action type drifted');
    assert(topicCalls[4].body.skill_code === 'P1-QUA-02', 'Theory action lost canonical skill code');
    assert(topicCalls[4].body.locale === 'en', 'Theory action lost UI locale');
    assert(topicCalls[4].body.user_text === '', 'Theory action must not collect free-form learner text');

    await page.evaluate(() => {
      document.querySelector('#exam-prep-host-root').innerHTML = `
        <section data-ep-views-screen data-ep-ai-skill-detail="P1-INT-05" data-ep-ai-skill-component="P1">
          <div class="ep-views-summary"></div>
        </section>`;
    });
    await page.waitForSelector('[data-ep-ai-topic-action-wrap] [data-ep-ai-action="theory_explanation"]');
    await page.click('[data-ep-ai-topic-action-wrap] [data-ep-ai-action="theory_explanation"]');
    await page.waitForFunction(() => document.querySelector('[data-ep-ai-topic-action-wrap] [data-ep-ai-output-text]')?.textContent === 'P1 explanation');
    let expandedTheoryCalls = await page.evaluate(() => window.__aiCalls);
    assert(expandedTheoryCalls.length === 6, `Expected exactly 6 AI endpoint calls after expanded P1 theory, got ${expandedTheoryCalls.length}`);
    assert(expandedTheoryCalls[5].body.skill_code === 'P1-INT-05', 'Expanded P1 theory action lost canonical integration skill');

    await page.evaluate(() => {
      document.querySelector('#exam-prep-host-root').innerHTML = `
        <section data-ep-views-screen data-ep-ai-skill-detail="P5-GEO-01" data-ep-ai-skill-component="P5">
          <div class="ep-views-summary"></div>
        </section>`;
    });
    await page.waitForSelector('[data-ep-ai-topic-action-wrap] [data-ep-ai-action="theory_explanation"]');
    await page.click('[data-ep-ai-topic-action-wrap] [data-ep-ai-action="theory_explanation"]');
    await page.waitForFunction(() => document.querySelector('[data-ep-ai-topic-action-wrap] [data-ep-ai-output-text]')?.textContent === 'P5 explanation');
    expandedTheoryCalls = await page.evaluate(() => window.__aiCalls);
    assert(expandedTheoryCalls.length === 7, `Expected exactly 7 AI endpoint calls after expanded P5 theory, got ${expandedTheoryCalls.length}`);
    assert(expandedTheoryCalls[6].body.component_code === 'P5' && expandedTheoryCalls[6].body.skill_code === 'P5-GEO-01', 'Expanded P5 geometric theory action crossed scope');

    await page.evaluate(() => {
      document.querySelector('#exam-prep-host-root').innerHTML = `
        <section data-ep-views-screen data-ep-ai-skill-detail="P1-NOT-A-SKILL" data-ep-ai-skill-component="P1">
          <div class="ep-views-summary"></div>
        </section>`;
    });
    await page.waitForTimeout(50);
    const unsupportedTheoryActions = await page.evaluate(() => document.querySelectorAll('[data-ep-ai-topic-action-wrap]').length);
    assert(unsupportedTheoryActions === 0, 'Theory action appeared for a non-canonical skill');

    await page.evaluate(() => {
      document.querySelector('#exam-prep-host-root').innerHTML = '<section data-ep-live-active-assessment><div>Question</div></section>';
    });
    await page.waitForTimeout(50);
    state = await page.evaluate(() => ({
      panels: document.querySelectorAll('[data-ep-ai-panel]').length,
      errorActions: document.querySelectorAll('[data-ep-ai-error-action-wrap]').length,
      topicActions: document.querySelectorAll('[data-ep-ai-topic-action-wrap]').length,
      calls: window.__aiCalls.length
    }));
    assert(state.panels === 0, 'AI panel must disappear outside safe overview surface');
    assert(state.errorActions === 0, 'Diagnostic AI action must never remain in an active assessment');
    assert(state.topicActions === 0, 'Theory AI action must never remain in an active assessment');
    assert(state.calls === 7, 'Screen transition must not trigger an AI request');

    await page.evaluate(() => {
      window.iClubExamPrepHostInternal.lastCapabilities.killSwitch = true;
      document.querySelector('#exam-prep-host-root').innerHTML = '<div><div data-ep-overview-strip="P1"></div></div>';
    });
    await page.waitForTimeout(50);
    state = await page.evaluate(() => document.querySelectorAll('[data-ep-ai-panel]').length);
    assert(state === 0, 'Kill switch must keep learner AI UI hidden');

    console.log('P1-04 learner AI UI regression: GREEN');
  } finally {
    await browser.close();
  }
})().catch(error => {
  console.error(error);
  process.exit(1);
});
