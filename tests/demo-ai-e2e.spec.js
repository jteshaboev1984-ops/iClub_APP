'use strict';

const { test, expect } = require('@playwright/test');

const runs = [
  { name: 'ru-360', lang: 'ru', width: 360, height: 740 },
  { name: 'ru-390', lang: 'ru', width: 390, height: 844 },
  { name: 'ru-430', lang: 'ru', width: 430, height: 900 },
  { name: 'uz-360', lang: 'uz', width: 360, height: 740 },
  { name: 'uz-390', lang: 'uz', width: 390, height: 844 },
  { name: 'uz-430', lang: 'uz', width: 430, height: 900 },
  { name: 'en-360', lang: 'en', width: 360, height: 740 },
  { name: 'en-390', lang: 'en', width: 390, height: 844 },
  { name: 'en-430', lang: 'en', width: 430, height: 900 },
  { name: 'desktop-centered', lang: 'ru', width: 1280, height: 900 }
];

const verifiedQuestion = {
  ru: 'что такое полезность',
  uz: 'naflilik nima',
  en: 'what is utility'
};

const generatedQuestion = {
  ru: 'Почему фирма может работать при минимуме средних издержек, но цена остаётся выше предельных издержек?',
  uz: 'Nega firma minimum o‘rtacha xarajatda ishlab, narxni chegaraviy xarajatdan yuqori belgilashi mumkin?',
  en: 'Why can a firm produce at minimum average cost while price remains above marginal cost?'
};

async function waitForDemo(page) {
  await page.waitForFunction(() => Boolean(
    window.ICLUB_DEMO_MAIN_LOCAL &&
    window.ICLUB_DEMO_GATE3 &&
    window.ICLUB_DEMO_GATE4 &&
    window.ICLUB_DEMO_GATE5 &&
    window.ICLUB_DEMO_GATE6 &&
    window.ICLUB_DEMO_GATE7 &&
    window.ICLUB_DEMO_GATE8_FINAL &&
    window.ICLUB_DEMO_CONTEXT
  ), null, { timeout: 20_000 });
}

async function chooseLanguage(page, language) {
  await page.locator('#demo-scenario-button').click();
  await expect(page.locator('#modal-root')).toHaveAttribute('aria-hidden', 'false');
  await page.locator(`[data-lang="${language}"]`).click();
  await page.locator('#demo-close').click();
  await expect(page.locator('html')).toHaveAttribute('lang', language);
}

async function completeDiagnosis(page) {
  await page.locator('[data-hub-tab="practice"]').click();
  await expect(page.locator('#courses-practice-start')).toBeVisible();
  await page.locator('#practice-restart-btn').click();
  await expect(page.locator('#courses-practice-quiz')).toBeVisible();
  for (let index = 0; index < 7; index += 1) {
    await page.evaluate(() => window.ICLUB_DEMO_GATE3.selectDemoAnswer());
    await expect(page.locator('#practice-submit-btn')).toBeEnabled();
    await page.locator('#practice-submit-btn').click();
  }
  await expect(page.locator('#courses-practice-result')).toBeVisible();
  await expect(page.locator('#practice-result-meta')).not.toHaveText('—');
}

async function sendQuestion(page, question) {
  await page.locator('#demo-ai-input').fill(question);
  await page.locator('#demo-ai-send').click();
}

async function waitTechnicalMode(page, mode) {
  await page.waitForFunction(expected => {
    try {
      return JSON.parse(sessionStorage.getItem('iclub_demo_v12.technical') || '{}').ai?.mode === expected;
    } catch { return false; }
  }, mode, { timeout: 20_000 });
}

async function openScenario(page) {
  const modal = page.locator('#modal-root');
  if (await modal.getAttribute('aria-hidden') !== 'false') await page.locator('#demo-scenario-button').click();
  await expect(modal).toHaveAttribute('aria-hidden', 'false');
}

async function fullRehearsal(page, scenario) {
  const pageErrors = [];
  const failedRequests = [];
  const forbiddenRequests = [];
  page.on('pageerror', error => pageErrors.push(String(error?.message || error)));
  page.on('requestfailed', request => failedRequests.push(`${request.method()} ${request.url()} ${request.failure()?.errorText || ''}`));
  page.on('request', request => { if (/supabase/i.test(request.url())) forbiddenRequests.push(request.url()); });
  page.on('dialog', dialog => dialog.accept());

  await page.setViewportSize({ width: scenario.width, height: scenario.height });
  await page.goto(`/diagnostic-demo.html?e2e=${encodeURIComponent(scenario.name)}`, { waitUntil: 'networkidle' });
  await waitForDemo(page);
  await chooseLanguage(page, scenario.lang);

  // 1-2. Free Subject Hub and inactive Tour 5.
  await expect(page.locator('#courses-subject-hub')).toBeVisible();
  await expect(page.locator('[data-plan="free"]')).toHaveClass(/is-active/);
  expect(await page.evaluate(() => window.ICLUB_DEMO_GATE7.isActive())).toBe(false);
  expect(await page.evaluate(() => document.documentElement.dataset.demoProfile)).toBe('demo-sardor');
  const shell = await page.locator('#app').boundingBox();
  expect(shell).not.toBeNull();
  expect(shell.width).toBeLessThanOrEqual(431);
  if (scenario.width > 430) expect(Math.abs((scenario.width - shell.width) / 2 - shell.x)).toBeLessThanOrEqual(2);
  expect(await page.evaluate(() => document.documentElement.scrollWidth <= window.innerWidth + 1)).toBe(true);

  // 3-4. Complete diagnosis and open normal Free review.
  await completeDiagnosis(page);
  const firstAttempt = await page.evaluate(() => JSON.parse(localStorage.getItem('iclub_demo_v12.history')).diagnostics.at(-1));
  expect(firstAttempt.answers).toHaveLength(7);
  expect(firstAttempt.score).toBe(firstAttempt.answers.filter(item => item.correct).length);
  await page.locator('#practice-review-open').click();
  await expect(page.locator('#courses-practice-review')).toBeVisible();
  await expect(page.locator('.demo-review-card').first()).toBeVisible();
  await page.locator('#practice-review-back-btn').click();

  // 5-6. Plus on the same result and contextual review.
  await page.locator('[data-plan="plus"]').click();
  await expect(page.locator('[data-plan="plus"]')).toHaveClass(/is-active/);
  await expect(page.locator('#demo-plan-result')).toBeVisible();
  await expect(page.locator('.demo-result-ai-action')).toBeVisible();
  await page.locator('.demo-result-ai-action').click();
  await expect(page.locator('#courses-ai-chat')).toBeVisible();
  await expect(page.locator('#demo-ai-chat-body .demo-ai-message.is-assistant').last()).toBeVisible();
  await page.locator('#topbar-back').click();
  await expect(page.locator('#courses-practice-result')).toBeVisible();

  // 11-13. Pro trajectory and dynamic evidence update from the same attempt.
  await page.locator('[data-plan="pro"]').click();
  await page.waitForFunction(() => Boolean(document.querySelector('.demo-open-trajectory')));
  await page.locator('.demo-open-trajectory').click();
  await expect(page.locator('#courses-pro-trajectory')).toBeVisible();
  await expect(page.locator('#courses-pro-trajectory .demo-student-context')).toContainText('Sardor');
  const dynamic = await page.evaluate(() => {
    const history = JSON.parse(localStorage.getItem('iclub_demo_v12.history') || '{}');
    const attempt = structuredClone(history.diagnostics.at(-1));
    const before = window.ICLUB_DEMO_DIAGNOSTIC_ENGINE.compute({ currentAttempt: attempt });
    const q5 = window.ICLUB_DEMO_V12_DATA.questions.find(item => item.id === 'd5');
    const answer = attempt.answers.find(item => item.questionId === 'd5');
    answer.selected = q5.a;
    answer.correct = true;
    attempt.score = attempt.answers.filter(item => item.correct).length;
    const after = window.ICLUB_DEMO_DIAGNOSTIC_ENGINE.compute({ currentAttempt: attempt });
    return {
      profileBefore: before.profileId,
      profileAfter: after.profileId,
      beforeRepeated: before.repeatedErrors,
      afterRepeated: after.repeatedErrors,
      afterPositive: after.positiveSignals,
      valid: before.valid && after.valid
    };
  });
  expect(dynamic.valid).toBe(true);
  expect(dynamic.profileBefore).toBe('demo-sardor');
  expect(dynamic.profileAfter).toBe('demo-sardor');
  expect(dynamic.afterRepeated).not.toEqual(dynamic.beforeRepeated);
  expect(dynamic.afterPositive).toContain('allocative_efficiency_condition');
  await page.locator('#topbar-back').click();
  await expect(page.locator('#courses-practice-result')).toBeVisible();

  // 7-10. Plus tutor: verified, generated, then cache.
  await page.locator('#practice-to-subject-btn').click();
  await page.locator('[data-plan="plus"]').click();
  await expect(page.locator('#demo-ai-hub-card')).toBeVisible();
  await page.locator('#demo-ai-hub-card').click();
  await expect(page.locator('#courses-ai-chat')).toBeVisible();

  await sendQuestion(page, verifiedQuestion[scenario.lang]);
  await waitTechnicalMode(page, 'verified');
  let technical = await page.evaluate(() => JSON.parse(sessionStorage.getItem('iclub_demo_v12.technical') || '{}').ai);
  expect(technical.model_call).toBe(false);
  expect(technical.quota_charged).toBe(false);

  await sendQuestion(page, generatedQuestion[scenario.lang]);
  await waitTechnicalMode(page, 'generated');
  technical = await page.evaluate(() => JSON.parse(sessionStorage.getItem('iclub_demo_v12.technical') || '{}').ai);
  expect(technical.model_call).toBe(true);
  expect(technical.quota_charged).toBe(true);

  await sendQuestion(page, generatedQuestion[scenario.lang]);
  await waitTechnicalMode(page, 'cached');
  technical = await page.evaluate(() => JSON.parse(sessionStorage.getItem('iclub_demo_v12.technical') || '{}').ai);
  expect(technical.model_call).toBe(false);
  expect(technical.cache_hit).toBe(true);

  // 17. Honest fallback.
  await page.locator('[data-gate6-demo="fallback"]').click();
  await page.locator('#demo-ai-send').click();
  await waitTechnicalMode(page, 'fallback');
  await expect(page.locator('#demo-ai-chat-body .is-live-fallback').last()).toBeVisible();

  // 14-16. Active Tour 5: protected task, allowed theory and technical evidence.
  await openScenario(page);
  await expect(page.locator('#demo-active-tour-button')).toBeVisible();
  await page.locator('#demo-active-tour-button').click();
  await page.waitForFunction(() => window.ICLUB_DEMO_GATE7.isActive() === true);
  await expect(page.locator('#modal-root')).toHaveAttribute('aria-hidden', 'true');

  await page.locator('[data-gate7-fill="exact"]').click();
  await page.locator('#demo-ai-send').click();
  await page.waitForFunction(() => {
    try {
      const tech = JSON.parse(sessionStorage.getItem('iclub_demo_v12.technical') || '{}');
      return tech.guard?.decision === 'blocked' && tech.guard?.active_tour === true;
    } catch { return false; }
  });
  await expect(page.locator('#demo-ai-chat-body .demo-ai-message.is-assistant').last()).toContainText(/не могу|cannot|bera olmayman|qila olmayman/i);

  await page.locator('[data-gate7-fill="theory"]').click();
  await page.locator('#demo-ai-send').click();
  await waitTechnicalMode(page, 'theory_only');
  await expect(page.locator('#demo-ai-chat-body .is-theory-only-answer').last()).toBeVisible();

  await openScenario(page);
  await page.locator('#demo-technical').click();
  await expect(page.locator('#demo-technical-card')).toBeVisible();
  await expect(page.locator('#demo-technical-card')).toContainText(/allowed_theory|Защита|Guard|Himoya|Theory/i);

  // 18. Language change keeps one learner, plan, attempt and custom chat screen.
  const nextLanguage = scenario.lang === 'ru' ? 'en' : 'ru';
  await page.locator(`[data-lang="${nextLanguage}"]`).click();
  await page.waitForTimeout(220);
  expect(await page.evaluate(() => document.documentElement.lang)).toBe(nextLanguage);
  expect(await page.evaluate(() => window.ICLUB_DEMO_MAIN_LOCAL.getState().plan)).toBe('plus');
  expect(await page.evaluate(() => JSON.parse(localStorage.getItem('iclub_demo_v12.history')).diagnostics.length)).toBeGreaterThan(0);
  await expect(page.locator('#courses-ai-chat')).toBeVisible();
  await page.locator('#demo-close').click();

  // Runtime readiness: allow the intentional reserve-video warning, but no technical failures.
  await openScenario(page);
  await page.locator('#demo-stage-readiness').click();
  await expect(page.locator('#demo-gate8-root')).toHaveAttribute('aria-hidden', 'false');
  await page.waitForFunction(() => {
    const provider = document.querySelector('[data-gate8-final="provider"] .demo-gate8-status');
    const guard = document.querySelector('[data-gate8-final="server-guard"] .demo-gate8-status');
    return provider?.classList.contains('is-pass') && guard?.classList.contains('is-pass');
  }, null, { timeout: 20_000 });
  expect(await page.locator('#demo-gate8-list .demo-gate8-status.is-fail').count()).toBe(0);
  const warningKeys = await page.locator('#demo-gate8-list .demo-gate8-status.is-warn').evaluateAll(nodes => nodes.map(node => node.closest('[data-gate8-final]')?.dataset.gate8Final).filter(Boolean));
  expect(warningKeys.every(key => key === 'video')).toBe(true);
  await page.locator('[data-gate8-close]').last().click();

  // 19. Reset deletes only demo data; unrelated app storage remains.
  await page.evaluate(() => localStorage.setItem('main_app_e2e_sentinel', 'keep'));
  await openScenario(page);
  await page.locator('#demo-reset').click();
  await page.waitForTimeout(150);
  expect(await page.evaluate(() => localStorage.getItem('main_app_e2e_sentinel'))).toBe('keep');
  expect(await page.evaluate(() => window.ICLUB_DEMO_MAIN_LOCAL.getState().plan)).toBe('free');
  expect(await page.evaluate(() => window.ICLUB_DEMO_MAIN_LOCAL.getState().productionCalls)).toBe(0);

  expect(forbiddenRequests).toEqual([]);
  expect(pageErrors).toEqual([]);
  expect(failedRequests).toEqual([]);
  expect(await page.evaluate(() => document.documentElement.scrollWidth <= window.innerWidth + 1)).toBe(true);
}

for (const scenario of runs) {
  test(`full rehearsal ${scenario.name}`, async ({ page }) => {
    await fullRehearsal(page, scenario);
  });
}
