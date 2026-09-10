const { chromium } = require('playwright');
const path = require('path');
const fs = require('fs');
const aiSource = fs.readFileSync('exam-prep/exam-prep-ai-ui.js', 'utf8');
const hostCss = fs.readFileSync('exam-prep/exam-prep-host.css', 'utf8');
if (aiSource.includes('ensureStyle(') || aiSource.includes('ep-ai-ui-style') || aiSource.includes('document.createElement("style")')) throw new Error('runtime AI UI style injection returned');
if (!hostCss.includes('EXAM PREP CENTRALIZED AI UI v1') || !hostCss.includes('.ep-ai-panel{')) throw new Error('centralized AI UI CSS contract missing');


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
    assert(text.includes('Study assistant'), 'Learner-facing AI title missing');
    for (const forbidden of ['AI Assist', 'controlled_beta', 'policy_version', 'runtime_status', 'source_card']) {
      assert(!text.includes(forbidden), `Internal AI term leaked to learner UI: ${forbidden}`);
    }

    await page.click('[data-ep-ai-panel="P1"] [data-ep-ai-action="progress_summary"]');
    await page.waitForFunction(() => document.querySelector('[data-ep-ai-panel="P1"] [data-ep-ai-output-text]')?.textContent === 'P1 explanation');

    await page.click('[data-ep-ai-panel="P5"] [data-ep-ai-action="weekly_plan_narration"]');
    await page.waitForFunction(() => document.querySelector('[data-ep-ai-panel="P5"] [data-ep-ai-output-text]')?.textContent === 'P5 explanation');

    const calls = await page.evaluate(() => window.__aiCalls);
    assert(calls.length === 2, `Expected exactly 2 AI endpoint calls, got ${calls.length}`);
    assert(calls[0].name === 'exam-prep-ai', 'AI UI must call only the governed Edge Function');
    assert(calls[0].body.component_code === 'P1', 'P1 action crossed component boundary');
    assert(calls[0].body.interaction_type === 'progress_summary', 'P1 progress action type drifted');
    assert(calls[0].body.locale === 'en', 'UI language was not preserved');
    assert(calls[0].body.user_text === '', 'Context action must not collect unnecessary learner text');
    assert(calls[1].body.component_code === 'P5', 'P5 action crossed component boundary');
    assert(calls[1].body.interaction_type === 'weekly_plan_narration', 'P5 plan action type drifted');

    await page.evaluate(() => {
      document.querySelector('#exam-prep-host-root').innerHTML = '<section data-ep-live-active-assessment><div>Question</div></section>';
    });
    await page.waitForTimeout(50);
    state = await page.evaluate(() => ({
      panels: document.querySelectorAll('[data-ep-ai-panel]').length,
      calls: window.__aiCalls.length
    }));
    assert(state.panels === 0, 'AI panel must disappear outside safe overview surface');
    assert(state.calls === 2, 'Screen transition must not trigger an AI request');

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
