const { chromium } = require('playwright');
const path = require('path');
const fs = require('fs');

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

const aiSource = fs.readFileSync('exam-prep/exam-prep-ai-ui.js', 'utf8');
const apiSource = fs.readFileSync('exam-prep/exam-prep-api.js', 'utf8');

assert(apiSource.includes('emit("iclub:exam-prep-capabilities"'), 'Capability refresh event contract missing from Exam Prep API');
assert(aiSource.includes('REQUEST_TIMEOUT_MS'), 'AI learner request timeout contract missing');
assert(aiSource.includes('academic_state_changed !== false'), 'AI learner UI no longer rejects authoritative provider payloads');
assert(aiSource.includes('languageObserver.observe(document.documentElement'), 'AI learner UI live language observer missing');
assert(!aiSource.includes('data-ep-ai-panel'), 'Standalone AI panel returned');
assert(!aiSource.includes('data-ep-ai-open-component'), 'Duplicate AI component navigation returned');

(async () => {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage({ viewport: { width: 390, height: 844 } });
  try {
    await page.setContent(`<!doctype html><html lang="en"><head></head><body>
      <div id="exam-prep-host-root" aria-hidden="false">
        <section class="ep-component-home" data-ep-component-home="P1" data-ep-ai-plan-available="true" data-ep-ai-repeated-available="true">
          <header class="ep-component-hero">Pure Mathematics 1</header>
          <section class="ep-component-next"><button id="core-continue" type="button">Continue core preparation</button></section>
          <section class="ep-component-progress-card">Progress</section>
          <section class="ep-component-links"><button type="button" data-ep-component-link="corrections">Needs attention</button></section>
        </section>
      </div>
    </body></html>`);

    await page.addStyleTag({ path: path.resolve('exam-prep/exam-prep-host.css') });

    await page.evaluate(() => {
      window.__lang = 'en';
      window.__aiCalls = [];
      window.__aiMode = 'success';
      window.__delayedResolvers = [];
      window.i18n = { getLang: () => window.__lang };
      window.iClubExamPrepHostInternal = {
        aiUiRequestTimeoutMs: 60,
        lastCapabilities: {
          rolloutState: 'controlled_beta',
          coreAccess: true,
          aiAssist: false,
          killSwitch: false
        },
        learnerCopy: { skillTitle: () => '' }
      };
      window.sb = {
        functions: {
          invoke: async (name, options) => {
            window.__aiCalls.push({ name, body: options?.body || null, mode: window.__aiMode });
            const mode = window.__aiMode;
            if (mode === 'error') return { data: null, error: { message: 'provider unavailable' } };
            if (mode === 'no_source') return {
              data: {
                request_id: '00000000-0000-4000-8000-000000000010',
                mode: 'no_source',
                generated: false,
                academic_state_changed: false,
                message: 'AI explanation is unavailable right now. Your core exam preparation continues normally.'
              },
              error: null
            };
            if (mode === 'unsafe_authority') return {
              data: {
                request_id: '00000000-0000-4000-8000-000000000011',
                mode: 'generated',
                generated: true,
                academic_state_changed: true,
                message: 'UNSAFE AUTHORITATIVE MESSAGE'
              },
              error: null
            };
            if (mode === 'hang') return new Promise(() => {});
            if (mode === 'delayed') return new Promise(resolve => window.__delayedResolvers.push(resolve));
            return {
              data: {
                request_id: '00000000-0000-4000-8000-000000000012',
                mode: 'generated',
                generated: true,
                academic_state_changed: false,
                message: 'Safe explanation'
              },
              error: null
            };
          }
        }
      };
    });

    await page.addScriptTag({ path: path.resolve('exam-prep/exam-prep-ai-ui.js') });
    await page.waitForTimeout(80);

    let state = await page.evaluate(() => ({
      contextual: document.querySelectorAll('[data-ep-ai-context-action]').length,
      core: document.querySelector('#core-continue')?.textContent || '',
      calls: window.__aiCalls.length
    }));
    assert(state.contextual === 0, 'Core-only state exposed AI learner UI');
    assert(state.core === 'Continue core preparation', 'Core learner action changed while AI was OFF');
    assert(state.calls === 0, 'AI endpoint called while capability was OFF');

    await page.evaluate(() => {
      window.iClubExamPrepHostInternal.lastCapabilities = {
        ...window.iClubExamPrepHostInternal.lastCapabilities,
        aiAssist: true
      };
      window.dispatchEvent(new CustomEvent('iclub:exam-prep-capabilities', {
        detail: { capabilities: window.iClubExamPrepHostInternal.lastCapabilities }
      }));
    });
    await page.waitForSelector('.ep-component-progress-card [data-ep-ai-action="progress_summary"]');
    await page.waitForSelector('.ep-component-next [data-ep-ai-action="weekly_plan_narration"]');
    await page.waitForSelector('.ep-component-links [data-ep-ai-action="repeated_error_summary"]');

    for (const width of [360, 390, 430, 1280]) {
      await page.setViewportSize({ width, height: width < 600 ? 844 : 900 });
      const metrics = await page.evaluate(() => {
        const buttons = Array.from(document.querySelectorAll('[data-ep-ai-context-action] [data-ep-ai-action]'));
        return {
          scrollWidth: document.documentElement.scrollWidth,
          innerWidth: window.innerWidth,
          buttonsInside: buttons.every(button => {
            const b = button.getBoundingClientRect();
            const parent = button.parentElement.getBoundingClientRect();
            return b.left >= parent.left - 1 && b.right <= parent.right + 1;
          })
        };
      });
      assert(metrics.scrollWidth <= metrics.innerWidth, 'AI contextual UX overflow at width ' + width + ': ' + JSON.stringify(metrics));
      assert(metrics.buttonsInside, 'AI contextual action escaped its Core surface at width ' + width);
    }

    await page.setViewportSize({ width: 390, height: 844 });
    for (const row of [
      { lang: 'ru', label: 'Объяснить мой прогресс' },
      { lang: 'uz', label: 'Progressimni tushuntirish' },
      { lang: 'en', label: 'Explain my progress' }
    ]) {
      await page.evaluate(({ lang }) => {
        window.__lang = lang;
        document.documentElement.lang = lang;
      }, row);
      await page.waitForFunction(expected => {
        return document.querySelector('.ep-component-progress-card [data-ep-ai-context-label]')?.textContent === expected;
      }, row.label);
    }

    const callsBeforeFailures = await page.evaluate(() => window.__aiCalls.length);

    await page.evaluate(() => { window.__lang = 'en'; document.documentElement.lang = 'en'; window.__aiMode = 'error'; });
    await page.click('.ep-component-progress-card [data-ep-ai-action="progress_summary"]');
    await page.waitForFunction(() => document.querySelector('.ep-component-progress-card [data-ep-ai-output-text]')?.textContent === 'The AI explanation could not be loaded. Try again later.');
    assert(await page.locator('#core-continue').isVisible(), 'Provider failure removed Core learner action');

    await page.evaluate(() => { window.__aiMode = 'no_source'; });
    await page.click('.ep-component-next [data-ep-ai-action="weekly_plan_narration"]');
    await page.waitForFunction(() => (document.querySelector('.ep-component-next [data-ep-ai-output-text]')?.textContent || '').includes('core exam preparation continues normally'));
    assert(await page.locator('#core-continue').isVisible(), 'No-source fallback removed Core learner action');

    await page.evaluate(() => { window.__aiMode = 'hang'; });
    await page.click('.ep-component-links [data-ep-ai-action="repeated_error_summary"]');
    await page.waitForFunction(() => document.querySelector('.ep-component-links [data-ep-ai-output-text]')?.textContent === 'AI explanation is unavailable right now. Your core exam preparation continues normally.');
    assert(await page.locator('#core-continue').isVisible(), 'AI timeout removed Core learner action');

    await page.evaluate(() => { window.__aiMode = 'unsafe_authority'; });
    await page.click('.ep-component-progress-card [data-ep-ai-action="progress_summary"]');
    await page.waitForFunction(() => {
      const t = document.querySelector('.ep-component-progress-card [data-ep-ai-output-text]')?.textContent || '';
      return t === 'AI explanation is unavailable right now. Your core exam preparation continues normally.';
    });
    const unsafeVisible = await page.locator('body').textContent();
    assert(!unsafeVisible.includes('UNSAFE AUTHORITATIVE MESSAGE'), 'Authoritative AI payload reached learner UI');

    await page.evaluate(() => { window.__aiMode = 'delayed'; });
    await page.click('.ep-component-progress-card [data-ep-ai-action="progress_summary"]');
    await page.waitForFunction(() => (window.__delayedResolvers || []).length === 1);
    await page.evaluate(() => {
      window.iClubExamPrepHostInternal.lastCapabilities = {
        ...window.iClubExamPrepHostInternal.lastCapabilities,
        aiAssist: false
      };
      window.dispatchEvent(new CustomEvent('iclub:exam-prep-capabilities', {
        detail: { capabilities: window.iClubExamPrepHostInternal.lastCapabilities }
      }));
    });
    await page.waitForFunction(() => document.querySelectorAll('[data-ep-ai-context-action]').length === 0);
    await page.evaluate(() => {
      const resolve = window.__delayedResolvers.shift();
      resolve?.({
        data: {
          academic_state_changed: false,
          generated: true,
          mode: 'generated',
          message: 'Late explanation that must stay hidden'
        },
        error: null
      });
    });
    await page.waitForTimeout(100);
    state = await page.evaluate(() => ({
      contextual: document.querySelectorAll('[data-ep-ai-context-action]').length,
      lateVisible: document.body.textContent.includes('Late explanation that must stay hidden'),
      coreVisible: Boolean(document.querySelector('#core-continue'))
    }));
    assert(state.contextual === 0 && !state.lateVisible, 'Late provider response resurfaced after AI capability was removed');
    assert(state.coreVisible, 'Core learner action disappeared during AI downgrade');

    await page.evaluate(() => {
      window.__aiMode = 'success';
      window.iClubExamPrepHostInternal.lastCapabilities = {
        ...window.iClubExamPrepHostInternal.lastCapabilities,
        aiAssist: true,
        killSwitch: false
      };
      window.dispatchEvent(new CustomEvent('iclub:exam-prep-capabilities', {
        detail: { capabilities: window.iClubExamPrepHostInternal.lastCapabilities }
      }));
    });
    await page.waitForSelector('[data-ep-ai-context-action]');

    await page.evaluate(() => {
      window.iClubExamPrepHostInternal.lastCapabilities = {
        ...window.iClubExamPrepHostInternal.lastCapabilities,
        killSwitch: true
      };
      window.dispatchEvent(new CustomEvent('iclub:exam-prep-capabilities', {
        detail: { capabilities: window.iClubExamPrepHostInternal.lastCapabilities }
      }));
    });
    await page.waitForFunction(() => document.querySelectorAll('[data-ep-ai-context-action]').length === 0);
    assert(await page.locator('#core-continue').isVisible(), 'AI kill switch removed Core learner action');

    await page.evaluate(() => {
      window.iClubExamPrepHostInternal.lastCapabilities = {
        ...window.iClubExamPrepHostInternal.lastCapabilities,
        killSwitch: false
      };
      window.dispatchEvent(new CustomEvent('iclub:exam-prep-capabilities', {
        detail: { capabilities: window.iClubExamPrepHostInternal.lastCapabilities }
      }));
    });
    await page.waitForSelector('[data-ep-ai-context-action]');

    await page.evaluate(() => {
      document.querySelector('#exam-prep-host-root').innerHTML =
        '<button id="core-assessment-next" type="button">Next core question</button>' +
        '<section data-ep-live-active-assessment><div>Question</div></section>';
    });
    await page.waitForTimeout(80);
    state = await page.evaluate(() => ({
      dashboardStatus: document.querySelectorAll('[data-ep-ai-dashboard-status]').length,
      contextual: document.querySelectorAll('[data-ep-ai-context-action]').length,
      errorActions: document.querySelectorAll('[data-ep-ai-error-action-wrap]').length,
      topicActions: document.querySelectorAll('[data-ep-ai-topic-action-wrap]').length,
      core: document.querySelector('#core-assessment-next')?.textContent || ''
    }));
    assert(state.dashboardStatus === 0 && state.contextual === 0 && state.errorActions === 0 && state.topicActions === 0, 'AI UI leaked into active assessment');
    assert(state.core === 'Next core question', 'Active Core assessment changed during AI transition testing');

    const totalCalls = await page.evaluate(() => window.__aiCalls.length);
    assert(totalCalls === callsBeforeFailures + 5, 'Capability transitions triggered unexpected AI requests: before=' + callsBeforeFailures + ' after=' + totalCalls);

    console.log('P3-02 AI learner UX/service-transition regression: GREEN');
  } finally {
    await browser.close();
  }
})().catch(error => {
  console.error(error);
  process.exit(1);
});
