const path = require('path');
const { chromium } = require('playwright');

const assert = (condition, message) => {
  if (!condition) throw new Error(message);
};

async function waitForRequest(page, predicate, message) {
  await page.waitForFunction((needle) => {
    return window.__globalAiRequests.some((item) => {
      if (needle.prompt_key !== undefined && item.prompt_key !== needle.prompt_key) return false;
      if (needle.user_text !== undefined && item.user_text !== needle.user_text) return false;
      if (needle.subject_key !== undefined && item.subject_key !== needle.subject_key) return false;
      if (needle.scope_code !== undefined && item.scope_code !== needle.scope_code) return false;
      return true;
    });
  }, predicate, { timeout: 3000 }).catch(() => {
    throw new Error(message);
  });
}

async function resolveNext(page, data) {
  await page.evaluate((payload) => {
    const next = window.__globalAiPending.shift();
    if (!next) throw new Error('no pending Global AI request');
    next({ data: payload, error: null });
  }, data);
}

async function runViewport(browser, width, height) {
  const page = await browser.newPage({ viewport: { width, height } });
  const pageErrors = [];
  page.on('pageerror', (error) => pageErrors.push(String(error?.stack || error?.message || error)));

  await page.setContent(`
    <!doctype html>
    <html lang="ru">
      <head><base href="http://127.0.0.1:4173/"></head>
      <body>
        <main id="main" class="main">
          <section id="view-home" class="view is-active" data-view="home">
            <div class="content">Home</div>
          </section>
          <section id="view-courses" class="view" data-view="courses">
            <div id="subject-hub-title">Математика</div>
            <section id="courses-tour-quiz" class="stack-screen" data-screen="tour-quiz"></section>
            <div id="exam-prep-host-root" hidden aria-hidden="true"></div>
          </section>
          <section id="view-profile" class="view" data-view="profile"><div class="content">Profile</div></section>
          <section id="view-registration" class="view" data-view="registration"><div class="content">Registration</div></section>
          <section id="view-certificate-verify" class="view" data-view="certificate-verify"><div class="content">Verify</div></section>
        </main>
        <nav id="tabbar" class="tabbar">
          <button class="tab">Home</button><button class="tab">Study</button>
          <button class="tab">Ratings</button><button class="tab">Profile</button>
        </nav>
        <div id="toast" class="toast" role="status"></div>
        <div id="modal-root" class="modal-root" aria-hidden="true">
          <div class="modal-backdrop"><div class="modal-card">Modal</div></div>
        </div>
      </body>
    </html>
  `);

  await page.addStyleTag({ path: path.resolve('style.css') });
  await page.addStyleTag({ path: path.resolve('global-ai-ui.css') });

  await page.evaluate(() => {
    window.i18n = { getLang: () => 'ru' };
    window.__globalAiBootstrap = {
      visible: true,
      assessment_blocked: false,
      usage_exhausted: false,
      reset_at: null,
      reason: null,
      locale: 'ru',
      ui_version: 'global_ai_conversations_v1'
    };
    window.__globalAiRequests = [];
    window.__globalAiPending = [];

    window.sb = {
      rpc: async (name) => {
        if (name !== 'get_iclub_ai_ui_bootstrap_v1') {
          return { data: null, error: { message: 'unexpected RPC ' + name } };
        }
        return { data: structuredClone(window.__globalAiBootstrap), error: null };
      },
      functions: {
        invoke: async (name, options) => {
          if (name !== 'global-ai') {
            return { data: null, error: { message: 'unexpected function ' + name } };
          }
          window.__globalAiRequests.push(structuredClone(options.body));
          return await new Promise((resolve) => window.__globalAiPending.push(resolve));
        }
      },
      auth: {
        onAuthStateChange: () => ({ data: { subscription: { unsubscribe() {} } } })
      }
    };
  });

  await page.addScriptTag({ path: path.resolve('global-ai-ui.js') });
  await page.waitForSelector('#iclub-global-ai-mark', { state: 'visible' });

  // General thread: quick prompt sends immediately and visibly behaves like chat.
  await page.click('#iclub-global-ai-mark');
  await page.waitForSelector('#iclub-global-ai-panel', { state: 'visible' });

  const firstQuick = page.locator('.iclub-global-ai-quick-btn').first();
  assert((await firstQuick.textContent()).includes('Что можно делать здесь'), 'general quick prompt copy mismatch');

  await firstQuick.click();
  await page.waitForSelector('.iclub-global-ai-message.is-user');
  await page.waitForSelector('.iclub-global-ai-message.is-typing');

  await waitForRequest(page, {
    prompt_key: 'app_help_here',
    subject_key: 'general',
    scope_code: 'global'
  }, 'general quick prompt request was not sent immediately');

  let request = await page.evaluate(() => window.__globalAiRequests.at(-1));
  assert(request.user_text === '', 'quick prompt should not duplicate label into user_text');
  assert(!('route_class' in request), 'client leaked route_class authority');
  assert(!('interaction_type' in request), 'client leaked interaction_type authority');

  await resolveNext(page, {
    ok: true,
    mode: 'answer',
    message: 'Здесь можно открыть учебные разделы iClub.',
    usage_exhausted: false,
    reset_at: null,
    academic_state_changed: false
  });
  await page.waitForFunction(() => !document.querySelector('.iclub-global-ai-message.is-typing'));
  assert(
    (await page.locator('.iclub-global-ai-message.is-assistant').last().textContent()).includes('учебные разделы'),
    'general answer was not rendered'
  );

  // Switch to Mathematics. Subject change must collapse and use a separate thread.
  await page.evaluate(() => {
    document.getElementById('view-home').classList.remove('is-active');
    document.getElementById('view-courses').classList.add('is-active');
  });
  await page.waitForFunction(() => document.getElementById('iclub-global-ai-panel')?.hidden === true);

  await page.click('#iclub-global-ai-mark');
  await page.waitForSelector('#iclub-global-ai-panel', { state: 'visible' });
  let visibleMessages = await page.locator('.iclub-global-ai-message').count();
  assert(visibleMessages === 0, 'General thread leaked into Mathematics thread');
  assert((await page.locator('[data-global-ai-title]').textContent()).includes('Tutor'), 'academic header did not switch to iClub AI Tutor');
  assert((await page.locator('[data-global-ai-subtitle]').textContent()).includes('Математика'), 'Mathematics subtitle missing');

  // Enter a governed Math Exam Prep skill context.
  await page.evaluate(() => {
    const root = document.getElementById('exam-prep-host-root');
    root.hidden = false;
    root.setAttribute('aria-hidden', 'false');
    root.innerHTML = `
      <section data-ep-ai-skill-detail="P1-FUN-01" data-ep-ai-skill-component="P1">
        <div data-ep-ai-context-action>legacy embedded AI action</div>
        <div data-ep-ai-topic-action-wrap>legacy topic AI action</div>
      </section>
    `;
  });
  await page.waitForFunction(() => window.iClubGlobalAiShell.context().skillCode === 'P1-FUN-01');

  const legacyHidden = await page.evaluate(() => {
    const a = document.querySelector('[data-ep-ai-context-action]');
    const b = document.querySelector('[data-ep-ai-topic-action-wrap]');
    return getComputedStyle(a).display === 'none' && getComputedStyle(b).display === 'none';
  });
  assert(legacyHidden, 'embedded Exam Prep AI was not hidden while Global AI shell is active');

  const mathQuickTexts = await page.locator('.iclub-global-ai-quick-btn').allTextContents();
  assert(mathQuickTexts.some((x) => x.includes('Объясни эту тему')), 'Math topic quick prompt missing');
  assert(mathQuickTexts.some((x) => x.includes('Объясни проще')), 'Math simple quick prompt missing');

  await page.locator('.iclub-global-ai-quick-btn', { hasText: 'Объясни эту тему' }).click();
  await waitForRequest(page, {
    prompt_key: 'topic_main',
    subject_key: 'mathematics',
    scope_code: 'exam_prep'
  }, 'Math prepared quick prompt request missing');

  request = await page.evaluate(() => window.__globalAiRequests.at(-1));
  assert(request.component_code === 'P1', 'Math component context missing');
  assert(request.skill_code === 'P1-FUN-01', 'Math skill context missing');

  await resolveNext(page, {
    ok: true,
    mode: 'answer',
    message: 'Функция связывает входное значение с определённым выходным значением.',
    usage_exhausted: false,
    reset_at: null,
    academic_state_changed: false
  });
  await page.waitForFunction(() => !document.querySelector('.iclub-global-ai-message.is-typing'));

  // Typed exact wording is sent as free text; server decides whether it can use a prepared route.
  const input = page.locator('[data-global-ai-input]');
  await input.fill('Объясни проще');
  await input.press('Enter');
  await waitForRequest(page, {
    prompt_key: '',
    user_text: 'Объясни проще',
    subject_key: 'mathematics'
  }, 'typed exact intent was not sent as user_text');
  await resolveNext(page, {
    ok: true,
    mode: 'answer',
    message: 'Проще: функция берёт вход и по правилу даёт один выход.',
    usage_exhausted: false,
    reset_at: null,
    academic_state_changed: false
  });
  await page.waitForFunction(() => !document.querySelector('.iclub-global-ai-message.is-typing'));

  // Switch to Chemistry: panel collapses and Mathematics messages remain separate.
  await page.evaluate(() => {
    const root = document.getElementById('exam-prep-host-root');
    root.hidden = true;
    root.setAttribute('aria-hidden', 'true');
    root.replaceChildren();
    document.getElementById('subject-hub-title').textContent = 'Химия';
  });
  await page.waitForFunction(() => window.iClubGlobalAiShell.context().subjectKey === 'chemistry');
  assert(await page.locator('#iclub-global-ai-panel').isHidden(), 'subject switch did not collapse the panel');

  await page.click('#iclub-global-ai-mark');
  visibleMessages = await page.locator('.iclub-global-ai-message').count();
  assert(visibleMessages === 0, 'Mathematics thread leaked into Chemistry thread');

  // Return to Mathematics: its in-session thread must still be available.
  await page.evaluate(() => {
    document.getElementById('subject-hub-title').textContent = 'Математика';
    const root = document.getElementById('exam-prep-host-root');
    root.hidden = false;
    root.setAttribute('aria-hidden', 'false');
    root.innerHTML = '<section data-ep-ai-skill-detail="P1-FUN-01" data-ep-ai-skill-component="P1"></section>';
  });
  await page.waitForFunction(() => window.iClubGlobalAiShell.context().subjectKey === 'mathematics');
  assert(await page.locator('#iclub-global-ai-panel').isHidden(), 'returning subject should remain collapsed until user opens it');

  await page.click('#iclub-global-ai-mark');
  const mathMessages = await page.locator('.iclub-global-ai-message').count();
  assert(mathMessages >= 4, 'Mathematics in-session thread was not preserved');

  // Protected assessment collapses chat and never allows a request through.
  const beforeProtected = await page.evaluate(() => window.__globalAiRequests.length);
  await page.evaluate(() => {
    window.dispatchEvent(new CustomEvent('iclub:exam-prep-session', {
      detail: {
        session: {
          session_id: 'protected-session',
          session_type: 'diagnostic',
          status: 'active'
        }
      }
    }));
  });
  await page.waitForFunction(() => {
    const panel = document.getElementById('iclub-global-ai-panel');
    return panel?.hidden === true
      && document.getElementById('iclub-global-ai-mark')?.classList.contains('is-assessment-blocked');
  });
  await page.click('#iclub-global-ai-mark');
  const afterProtected = await page.evaluate(() => window.__globalAiRequests.length);
  assert(afterProtected === beforeProtected, 'protected assessment triggered an AI request');
  assert((await page.locator('#toast').textContent()).includes('недоступен во время экзамена'), 'protected assessment explanation missing');

  await page.evaluate(() => {
    window.dispatchEvent(new CustomEvent('iclub:exam-prep-session-ended', {
      detail: { sessionId: 'protected-session' }
    }));
  });
  await page.waitForFunction(() => !document.getElementById('iclub-global-ai-mark')?.classList.contains('is-assessment-blocked'));

  // Successful final allowed answer immediately locks the composer and shows reset time.
  await page.click('#iclub-global-ai-mark');
  await page.locator('.iclub-global-ai-quick-btn', { hasText: 'Что важно запомнить' }).click();
  await waitForRequest(page, { prompt_key: 'topic_focus' }, 'final allowed quick prompt request missing');

  const resetAt = new Date(Date.now() + 60 * 60 * 1000).toISOString();
  await resolveNext(page, {
    ok: true,
    mode: 'answer',
    message: 'Сосредоточься на определении и условии применения.',
    usage_exhausted: true,
    reset_at: resetAt,
    academic_state_changed: false
  });
  await page.waitForFunction(() => {
    const box = document.querySelector('[data-global-ai-limit]');
    const input = document.querySelector('[data-global-ai-input]');
    return box && box.hidden === false && input && input.disabled === true;
  });

  const limitText = await page.locator('[data-global-ai-limit]').textContent();
  assert(limitText.includes('Лимит iClub AI достигнут'), 'limit state title missing');
  assert(!/\b(3|9|14)\s*\/|units?|единиц/i.test(limitText), 'hidden usage accounting leaked into learner UI');
  assert(await page.locator('.iclub-global-ai-quick-btn:enabled').count() === 0, 'quick prompts remain enabled after exhaustion');

  // Layout and navigation safety.
  const metrics = await page.evaluate(() => {
    const rect = (el) => {
      const r = el.getBoundingClientRect();
      return { left:r.left,right:r.right,top:r.top,bottom:r.bottom,width:r.width,height:r.height };
    };
    return {
      panel: rect(document.getElementById('iclub-global-ai-panel')),
      mark: rect(document.getElementById('iclub-global-ai-mark')),
      tab: rect(document.getElementById('tabbar')),
      rootCount: document.querySelectorAll('#iclub-global-ai-root').length
    };
  });
  assert(metrics.rootCount === 1, 'Global AI root duplicated');
  assert(metrics.mark.width >= 44 && metrics.mark.height >= 44, 'AI mark touch target below 44px');
  assert(metrics.mark.bottom <= metrics.tab.top, 'AI mark overlaps tabbar');
  assert(metrics.panel.left >= 0 && metrics.panel.right <= width, 'chat panel overflows horizontally');
  assert(metrics.panel.bottom <= metrics.tab.top, 'chat panel overlaps bottom navigation');

  await page.screenshot({ path: `artifacts/global-ai-conversations-${width}.png`, fullPage: true });
  assert(pageErrors.length === 0, `page errors at ${width}px: ${JSON.stringify(pageErrors)}`);
  await page.close();
}

(async () => {
  const browser = await chromium.launch({ headless: true });
  try {
    await runViewport(browser, 390, 844);
    await runViewport(browser, 320, 720);
    console.log('Global AI contextual conversations browser regression: GREEN');
  } finally {
    await browser.close();
  }
})().catch((error) => {
  console.error(error);
  process.exit(1);
});
