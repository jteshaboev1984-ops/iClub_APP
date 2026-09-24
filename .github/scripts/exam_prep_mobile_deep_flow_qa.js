const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

const BASE_URL = process.env.ICLUB_BASE_URL || 'https://i-club-app.vercel.app/';
const OUT = process.env.ICLUB_DEEP_QA_OUT || 'mobile-deep-flow-artifacts';
fs.mkdirSync(OUT, { recursive: true });

const report = {
  baseUrl: BASE_URL,
  startedAt: new Date().toISOString(),
  qaUser: null,
  stage0: {},
  weeklyPlan: null,
  correction: null,
  delayedRetest: null,
  consoleErrors: [],
  pageErrors: [],
  networkErrors: [],
  notes: []
};

const sleep = ms => new Promise(r => setTimeout(r, ms));
const safeName = s => String(s).replace(/[^a-z0-9_-]+/gi, '-').replace(/^-|-$/g, '').toLowerCase();

async function shot(page, name, fullPage = false) {
  const file = path.join(OUT, safeName(name) + '.png');
  await page.screenshot({ path: file, fullPage });
  return file;
}

async function audit(page, label) {
  const data = await page.evaluate(() => {
    const root = document.documentElement;
    const body = document.body;
    const all = Array.from(document.querySelectorAll('button,a,input,select,textarea,[role="button"]'))
      .filter(el => {
        const cs = getComputedStyle(el);
        const r = el.getBoundingClientRect();
        return cs.display !== 'none' && cs.visibility !== 'hidden' && r.width > 0 && r.height > 0;
      })
      .map(el => {
        const r = el.getBoundingClientRect();
        return {
          tag: el.tagName.toLowerCase(),
          text: String(el.innerText || el.getAttribute('aria-label') || '').trim().slice(0, 100),
          width: Math.round(r.width), height: Math.round(r.height),
          left: Math.round(r.left), right: Math.round(r.right)
        };
      });
    return {
      width: innerWidth,
      height: innerHeight,
      scrollWidth: Math.max(root.scrollWidth, body?.scrollWidth || 0),
      horizontalOverflow: Math.max(root.scrollWidth, body?.scrollWidth || 0) > innerWidth + 1,
      offscreen: all.filter(x => x.left < -1 || x.right > innerWidth + 1),
      smallButtons: all.filter(x => x.tag === 'button' && (x.width < 40 || x.height < 40))
    };
  });
  if (data.horizontalOverflow) throw new Error(label + ' has horizontal overflow');
  if (data.offscreen.length) throw new Error(label + ' has offscreen interactive controls: ' + JSON.stringify(data.offscreen.slice(0, 5)));
  return data;
}

async function ensureRegistration(page, qaName) {
  await page.goto(BASE_URL, { waitUntil: 'domcontentloaded', timeout: 45000 });
  await page.waitForFunction(() => {
    const reg = document.querySelector('#view-registration');
    const home = document.querySelector('#view-home');
    return reg?.classList.contains('is-active') || home?.classList.contains('is-active');
  }, null, { timeout: 45000 });

  if (await page.locator('#view-home.is-active').count()) return;

  await page.selectOption('#reg-language', 'ru');
  await page.fill('#reg-fullname', qaName);
  await page.waitForFunction(() => document.querySelectorAll('#reg-region option').length > 1, null, { timeout: 30000 });
  const regionValue = await page.$eval('#reg-region', el => Array.from(el.options).find(o => o.value)?.value || '');
  if (!regionValue) throw new Error('No registration region option');
  await page.selectOption('#reg-region', regionValue);
  await page.waitForFunction(() => {
    const d = document.querySelector('#reg-district');
    return d && !d.disabled && d.options.length > 1;
  }, null, { timeout: 30000 });
  const districtValue = await page.$eval('#reg-district', el => Array.from(el.options).find(o => o.value)?.value || '');
  if (!districtValue) throw new Error('No registration district option');
  await page.selectOption('#reg-district', districtValue);
  await page.fill('#reg-school', 'QA Mobile Deep Flow');
  await page.selectOption('#reg-class', '11');
  const mathChip = page.locator('#reg-subject-chips [data-subject-key="mathematics"]');
  await mathChip.waitFor({ state: 'visible', timeout: 15000 });
  await mathChip.click();
  await page.check('#reg-consent');
  await page.click('#reg-submit');
  await page.waitForFunction(() => document.querySelector('#view-home')?.classList.contains('is-active'), null, { timeout: 45000 });
  await sleep(900);
}

async function getUid(page) {
  return page.evaluate(async () => {
    try {
      const { data } = await window.sb?.auth?.getUser?.();
      return data?.user?.id || null;
    } catch (_) { return null; }
  });
}

async function openExamPrep(page) {
  await page.click('[data-tab="courses"]');
  await page.waitForFunction(() => document.querySelector('#view-courses')?.classList.contains('is-active'), null, { timeout: 15000 });
  await page.waitForFunction(() => document.querySelectorAll('#subjects-grid .catalog-card').length > 0, null, { timeout: 20000 });
  const competitive = page.locator('[data-main-filter="competitive"]');
  if (await competitive.count()) { await competitive.click(); await page.waitForTimeout(300); }
  const mathCard = page.locator('#subjects-grid .catalog-card').filter({ hasText: /Математика|Mathematics|Matematika/i }).first();
  await mathCard.waitFor({ state: 'visible', timeout: 15000 });
  await mathCard.locator('.catalog-head').click();
  await page.waitForFunction(() => document.querySelector('#courses-subject-hub')?.classList.contains('is-active'), null, { timeout: 15000 });
  await page.waitForFunction(() => {
    const e = document.querySelector('#subject-hub-exam-prep-entry');
    return e && !e.hidden && e.getAttribute('aria-hidden') !== 'true';
  }, null, { timeout: 20000 });
  await page.waitForFunction(() => window.iClubExamPrep?.liveFlowVersion === 'p251live1', null, { timeout: 20000 });
  await page.click('[data-action="open-exam-prep"]');
  await page.waitForFunction(() =>
    Boolean(document.querySelector('[data-ep-live-profile-form]')) ||
    Boolean(document.querySelector('[data-ep-live-component="P1"]')),
    null, { timeout: 30000 }
  );
  const profile = page.locator('[data-ep-live-profile-form]');
  if (await profile.count()) {
    const series = profile.locator('[name="exam_series"]');
    const grade = profile.locator('[name="target_grade"]');
    if ((await series.evaluate(el => el.tagName)) === 'SELECT') await series.selectOption({ label: 'May/June 2027' });
    else await series.fill('May/June 2027');
    if ((await grade.evaluate(el => el.tagName)) === 'SELECT') await grade.selectOption('A');
    else await grade.fill('A');
    await profile.locator('[name="total_hours"]').fill('10');
    await profile.locator('[name="math_hours"]').fill('5');
    await page.click('[data-ep-live-save-profile]');
  }
  await page.waitForSelector('[data-ep-live-component="P1"]', { state: 'visible', timeout: 30000 });
}

async function openP1Home(page) {
  if (!(await page.locator('[data-ep-component-home="P1"]:visible').count())) {
    await page.waitForFunction(() => {
      return Array.from(document.querySelectorAll('[data-ep-live-component="P1"]')).some(el => {
        const cs = getComputedStyle(el);
        const r = el.getBoundingClientRect();
        return !el.disabled && cs.display !== 'none' && cs.visibility !== 'hidden' &&
          r.width > 0 && r.height > 0;
      });
    }, null, { timeout: 30000 });
    await page.locator('[data-ep-live-component="P1"]:visible:not([disabled])').first().click();
  }
  await page.waitForSelector('[data-ep-component-home="P1"]', { state: 'visible', timeout: 30000 });
}

async function readDiagnostic(page) {
  return page.evaluate(async () => {
    const api = window.iClubExamPrepHostInternal?.api;
    if (!api?.diagnosticProgress) return null;
    const r = await api.diagnosticProgress('P1');
    return r?.ok ? r.data : { error: r?.reason || 'diagnostic_progress_failed' };
  });
}

async function readQueue(page) {
  return page.evaluate(async () => {
    const api = window.iClubExamPrepHostInternal?.api;
    if (!api?.correctionQueue) return null;
    const r = await api.correctionQueue('P1');
    return r?.ok ? r.data : { error: r?.reason || 'queue_failed' };
  });
}

async function readPlan(page) {
  return page.evaluate(async () => {
    const api = window.iClubExamPrepHostInternal?.api;
    if (!api?.weeklyPlan) return null;
    const r = await api.weeklyPlan('P1');
    return r?.ok ? r.data : { error: r?.reason || 'plan_failed' };
  });
}

async function waitForReadySubmitOrRoute(page, timeout = 30000) {
  await page.waitForFunction(() => {
    const visible = selector => Array.from(document.querySelectorAll(selector)).some(el => {
      const cs = getComputedStyle(el);
      const r = el.getBoundingClientRect();
      return !el.hidden && cs.display !== 'none' && cs.visibility !== 'hidden' &&
        r.width > 0 && r.height > 0;
    });
    const submit = document.querySelector('[data-ep-live-submit]');
    const submitReady = submit && !submit.disabled && visible('[data-ep-live-submit]');
    return Boolean(submitReady) ||
      visible('[data-ep-component-home="P1"]') ||
      visible('[data-ep-placement-screen]') ||
      visible('[data-ep-flow-completion]') ||
      visible('.ep-live-plan-item') ||
      Array.from(document.querySelectorAll('[data-ep-live-component="P1"]')).some(el => {
        const cs = getComputedStyle(el);
        const r = el.getBoundingClientRect();
        return !el.disabled && cs.display !== 'none' && cs.visibility !== 'hidden' &&
          r.width > 0 && r.height > 0;
      });
  }, null, { timeout });
}

async function answerCurrent(page, strategy = 'diagnostic') {
  await waitForReadySubmitOrRoute(page);
  const result = await page.evaluate((mode) => {
    const visible = el => {
      if (!el) return false;
      const cs = getComputedStyle(el);
      const r = el.getBoundingClientRect();
      return !el.hidden && cs.display !== 'none' && cs.visibility !== 'hidden' &&
        r.width > 0 && r.height > 0;
    };
    const submit = Array.from(document.querySelectorAll('[data-ep-live-submit]'))
      .find(el => visible(el) && !el.disabled);
    if (!submit) return { acted: false, reason: 'submit_not_ready' };

    const radios = Array.from(document.querySelectorAll('input[name="ep_live_answer"]')).filter(visible);
    const text = Array.from(document.querySelectorAll('input[name="ep_live_text_answer"]')).find(visible);
    const written = Array.from(document.querySelectorAll('textarea[name="ep_live_written_answer"]')).find(visible);

    let kind = '';
    if (radios.length) {
      const input = radios[0];
      input.checked = true;
      input.dispatchEvent(new Event('input', { bubbles: true }));
      input.dispatchEvent(new Event('change', { bubbles: true }));
      kind = 'mcq';
    } else if (text) {
      text.value = mode === 'force-error' ? 'QA_WRONG_987654321' : '0';
      text.dispatchEvent(new Event('input', { bubbles: true }));
      text.dispatchEvent(new Event('change', { bubbles: true }));
      kind = 'input';
    } else if (written) {
      written.value = mode === 'force-error'
        ? 'QA deliberate incorrect response for isolated mobile flow verification.'
        : 'QA mobile diagnostic response.';
      written.dispatchEvent(new Event('input', { bubbles: true }));
      written.dispatchEvent(new Event('change', { bubbles: true }));
      kind = 'written';
    } else {
      return { acted: false, reason: 'answer_control_missing' };
    }

    submit.click();
    return { acted: true, kind };
  }, strategy);

  if (!result?.acted) {
    if (result?.reason === 'submit_not_ready') return false;
    throw new Error('No answer control on visible question: ' + String(result?.reason || 'unknown'));
  }
  await page.waitForTimeout(160);
  return true;
}

async function completeVisibleSession(page, strategy, maxItems = 30) {
  let answered = 0;
  while (answered < maxItems) {
    await waitForReadySubmitOrRoute(page);
    const submit = page.locator('[data-ep-live-submit]').first();
    if (!(await submit.count()) || !(await submit.isVisible()) || !(await submit.isEnabled())) break;
    const didAnswer = await answerCurrent(page, strategy);
    if (!didAnswer) break;
    answered += 1;
  }
  return answered;
}

async function finishStage0(page) {
  let totalAnswers = 0;
  let sessions = 0;
  for (let guard = 0; guard < 40; guard += 1) {
    const progress = await readDiagnostic(page);
    if (progress?.stage0_complete === true) {
      return { complete: true, sessions, totalAnswers, progress };
    }

    if (await page.locator('[data-ep-live-submit]').count()) {
      totalAnswers += await completeVisibleSession(page, 'diagnostic', 30);
      sessions += 1;
      continue;
    }

    if (await page.locator('[data-ep-placement-screen]').count()) {
      const next = page.locator('[data-ep-placement-next]');
      if (await next.count()) {
        await next.click();
        await page.waitForTimeout(500);
        continue;
      }
    }

    if (await page.locator('[data-ep-component-home="P1"]').count()) {
      const primary = page.locator('[data-ep-component-primary]');
      const kind = await primary.getAttribute('data-ep-component-primary');
      if (kind !== 'diagnostic') {
        const refreshed = await readDiagnostic(page);
        if (refreshed?.stage0_complete === true) return { complete: true, sessions, totalAnswers, progress: refreshed };
        throw new Error('Stage0 incomplete but component primary is ' + kind);
      }
      await primary.click();
      await page.waitForSelector('[data-ep-live-submit]', { state: 'visible', timeout: 30000 });
      continue;
    }

    if (await page.locator('[data-ep-live-component="P1"]:visible:not([disabled])').count()) {
      await openP1Home(page);
      continue;
    }

    await page.waitForTimeout(500);
  }
  throw new Error('P1 Stage0 did not converge in mobile deep QA');
}

async function settleAfterStage0(page) {
  await page.waitForFunction(() => {
    const root = document.querySelector('#exam-prep-host-root');
    if (!root || root.hidden) return false;
    if (document.querySelector('[data-ep-live-submit]')) return false;
    if (document.querySelector('[data-ep-placement-screen]')) {
      return Boolean(document.querySelector('[data-ep-placement-back]')) &&
        !document.querySelector('.ep-placement-card[role="status"]');
    }
    return Boolean(document.querySelector('[data-ep-component-home="P1"]')) ||
      Boolean(document.querySelector('[data-ep-live-component="P1"]')) ||
      Boolean(document.querySelector('[data-ep-flow-completion]'));
  }, null, { timeout: 45000 });

  if (await page.locator('[data-ep-placement-screen]').count()) {
    await page.waitForSelector('[data-ep-placement-back]', { state: 'visible', timeout: 30000 });
    await page.locator('[data-ep-placement-back]').click();
    await page.waitForSelector('[data-ep-live-component="P1"]', { state: 'visible', timeout: 30000 });
  } else if (await page.locator('[data-ep-flow-completion]').count()) {
    const back = page.locator('[data-ep-live-dashboard]').first();
    if (await back.count()) await back.click();
    else await page.evaluate(async () => {
      if (window.iClubExamPrep?.open) await window.iClubExamPrep.open({ subjectKey: 'mathematics', language: 'ru' });
    });
    await page.waitForSelector('[data-ep-live-component="P1"]', { state: 'visible', timeout: 30000 });
  } else if (await page.locator('[data-ep-component-home="P1"]').count()) {
    await page.locator('[data-ep-component-back]').click();
    await page.waitForSelector('[data-ep-live-component="P1"]', { state: 'visible', timeout: 30000 });
  }
}

async function probeWeeklyFlow(page) {
  return page.evaluate(async () => {
    const internal = window.iClubExamPrepHostInternal || {};
    const flow = internal.weeklyFlowApi;
    const api = internal.api;
    const simplify = value => {
      if (!value || typeof value !== 'object') return value;
      const out = { ok: value.ok === true, reason: value.reason || null };
      if ('data' in value) out.data = value.data;
      if (value.error) out.error = {
        message: value.error.message || null,
        details: value.error.details || null,
        hint: value.error.hint || null,
        code: value.error.code || null
      };
      return out;
    };
    const result = {
      weeklyEnabled: window.iClubExamPrepWeeklyFlowEnabled === true,
      capabilities: internal.lastCapabilities || null,
      adapterVersion: flow?.version || null,
      recovery: null,
      ensure: null,
      weeklyPlan: null
    };
    if (flow?.recover) result.recovery = simplify(await flow.recover('P1'));
    if (flow?.plan) result.ensure = simplify(await flow.plan('P1'));
    if (api?.weeklyPlan) result.weeklyPlan = simplify(await api.weeklyPlan('P1'));
    return result;
  });
}

async function weeklyPlanPresentation(page) {
  return page.evaluate(() => {
    const visible = el => {
      if (!el) return false;
      const cs = getComputedStyle(el);
      const r = el.getBoundingClientRect();
      return !el.hidden && cs.display !== 'none' && cs.visibility !== 'hidden' &&
        r.width > 0 && r.height > 0;
    };
    const panel = document.querySelector('.ep-pux-week');
    const originals = Array.from(document.querySelectorAll('.ep-live-plan-item'));
    const originalButtons = originals.map(row => row.querySelector('[data-ep-live-plan-item]')).filter(Boolean);
    const goalActions = Array.from(document.querySelectorAll('.ep-pux-goal-action'));
    const waitingGoals = Array.from(document.querySelectorAll('.ep-pux-goal-waiting'));
    return {
      progressUxEnabled: window.iClubExamPrepProgressUxEnabled === true,
      panelVisible: visible(panel),
      verified: panel?.dataset.epPuxPrimaryGoals === 'verified',
      originalRows: originals.length,
      boundOriginalRows: originals.filter(row => row.dataset.epFlowPlan === 'flowux4').length,
      visibleOriginalRows: originals.filter(visible).length,
      enabledOriginalButtons: originalButtons.filter(button => !button.disabled).length,
      visibleEnabledOriginalButtons: originalButtons.filter(button => visible(button) && !button.disabled).length,
      disabledOriginalButtons: originalButtons.filter(button => button.disabled).length,
      visibleGoalActions: goalActions.filter(button => visible(button) && !button.disabled).length,
      waitingGoals: waitingGoals.filter(visible).length,
      panelText: String(panel?.textContent || '').trim().slice(0, 1800)
    };
  });
}

async function openWeeklyPlan(page) {
  const opened = await page.evaluate(async () => {
    const flow = window.iClubExamPrepHostInternal?.learnerFlowUx;
    if (flow?.openWeeklyPlan) return await flow.openWeeklyPlan('P1');
    return false;
  });
  if (!opened) {
    await page.evaluate(() => {
      const b = document.querySelector('[data-ep-live-plan="P1"]');
      if (b) b.click();
    });
  }

  await page.waitForFunction(() => {
    const root = document.querySelector('#exam-prep-host-root');
    if (!root || root.hidden) return false;
    if (root.querySelector('.ep-live-error[role="alert"]')) return true;
    if (root.querySelector('.ep-pux-week')) return true;
    return Array.from(root.querySelectorAll('.ep-live-plan-item')).some(row => {
      const cs = getComputedStyle(row);
      const r = row.getBoundingClientRect();
      return !row.hidden && cs.display !== 'none' && cs.visibility !== 'hidden' &&
        r.width > 0 && r.height > 0;
    });
  }, null, { timeout: 30000 });

  const errorText = await page.locator('.ep-live-error[role="alert"]').first().textContent().catch(() => null);
  if (errorText) throw new Error('Weekly plan rendered learner error: ' + String(errorText).trim());

  // Progress UX validates the exact server goal -> plan -> action binding
  // asynchronously and then intentionally hides the native rows. Let that
  // promotion settle before deciding which learner-facing CTA is authoritative.
  await page.waitForTimeout(900);
  const state = await weeklyPlanPresentation(page);

  if (state.progressUxEnabled && state.panelVisible && state.verified) {
    if (state.originalRows < 1 || state.boundOriginalRows !== state.originalRows) {
      throw new Error('Verified Progress UX plan lost its guarded native bindings: ' + JSON.stringify(state));
    }
    if (state.visibleOriginalRows !== 0) {
      throw new Error('Verified Progress UX plan still exposes duplicate native rows: ' + JSON.stringify(state));
    }
  } else if (state.visibleOriginalRows < 1) {
    throw new Error('Weekly plan has no visible learner route: ' + JSON.stringify(state));
  }
  return state;
}

async function clickWeeklyAction(page) {
  const state = await weeklyPlanPresentation(page);
  if (state.panelVisible && state.verified) {
    const action = page.locator('.ep-pux-goal-action:visible:not([disabled])').first();
    if (!(await action.count())) return { clicked: false, route: 'progress-ux', state };
    const label = String(await action.innerText()).trim();
    await action.click();
    return { clicked: true, route: 'progress-ux', label, state };
  }
  const action = page.locator('[data-ep-live-plan-item]:visible:not([disabled])').first();
  if (!(await action.count())) return { clicked: false, route: 'native', state };
  const label = String(await action.innerText()).trim();
  await action.click();
  return { clicked: true, route: 'native', label, state };
}

async function assertLearnerSafeCopy(page, label) {
  const state = await page.evaluate(() => {
    const text = String(document.querySelector('#exam-prep-host-root')?.textContent || '');
    const forbiddenTokens = [
      'completed-square form',
      'vertex/shape information',
      'degrees ↔ radians',
      'subject of a formula'
    ];
    return {
      forbidden: forbiddenTokens.filter(x => text.toLowerCase().includes(x.toLowerCase())),
      sample: text.trim().slice(0, 1800)
    };
  });
  if (state.forbidden.length) throw new Error(label + ' exposes mixed-language canonical copy: ' + state.forbidden.join(', ') + ' | sample=' + state.sample);
  return state;
}

async function goDashboardThenP1(page) {
  const dashboardButton = page.locator('[data-ep-live-dashboard]').first();
  if (await dashboardButton.count()) {
    await dashboardButton.click();
  } else {
    await page.evaluate(async () => {
      if (window.iClubExamPrep?.open) await window.iClubExamPrep.open({ subjectKey: 'mathematics', language: 'ru' });
    });
  }
  await page.waitForSelector('[data-ep-live-component="P1"]', { state: 'visible', timeout: 30000 });
  await openP1Home(page);
}

async function makeCorrection(page) {
  const initialQueue = await readQueue(page);
  if (Number(initialQueue?.active_count || 0) > 0) {
    report.notes.push({ correctionAlreadyOpenAfterDiagnostic: true, queue: initialQueue });
    return initialQueue;
  }

  for (let attempt = 1; attempt <= 3; attempt += 1) {
    const presentation = await openWeeklyPlan(page);
    const action = await clickWeeklyAction(page);
    report.notes.push({ correctionAttempt: attempt, presentation, action });
    if (!action.clicked) break;

    await page.waitForSelector('[data-ep-live-submit]', { state: 'visible', timeout: 30000 });
    await completeVisibleSession(page, 'force-error', 30);
    await page.waitForTimeout(800);

    const queue = await readQueue(page);
    report.notes.push({ correctionAttempt: attempt, queueAfterAttempt: queue });
    if (Number(queue?.active_count || 0) > 0) return queue;

    await goDashboardThenP1(page);
  }
  return await readQueue(page);
}

async function openCorrections(page) {
  if (!(await page.locator('[data-ep-component-home="P1"]').count())) await goDashboardThenP1(page);
  const link = page.locator('[data-ep-component-link="corrections"]');
  if (!(await link.count())) throw new Error('Correction queue exists but learner correction link is not visible');
  await link.click();
  await page.waitForSelector('[data-ep-views-screen]', { state: 'visible', timeout: 30000 });
  await page.waitForTimeout(500);
}

async function attemptCorrectionFlow(page) {
  const action = page.locator('[data-ep-flow-correction-action]').first();
  if (!(await action.count()) || await action.isDisabled()) {
    return { started: false, reason: 'no_enabled_correction_action', queue: await readQueue(page) };
  }
  const label = String(await action.innerText()).trim();
  await action.click();
  await page.waitForSelector('[data-ep-live-submit]', { state: 'visible', timeout: 30000 });
  const answered = await completeVisibleSession(page, 'diagnostic', 30);
  await page.waitForTimeout(900);
  const queue = await readQueue(page);
  const plan = await readPlan(page);
  return { started: true, label, answered, queue, plan };
}

(async () => {
  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext({
    viewport: { width: 390, height: 844 },
    isMobile: true,
    hasTouch: true,
    deviceScaleFactor: 2
  });
  const page = await context.newPage();
  page.setDefaultTimeout(25000);
  page.on('console', msg => { if (msg.type() === 'error') report.consoleErrors.push(msg.text()); });
  page.on('pageerror', err => report.pageErrors.push(String(err)));
  page.on('response', async response => {
    if (response.status() < 400 || !/\/rest\/v1\/rpc\//.test(response.url())) return;
    let body = '';
    try { body = String(await response.text()).slice(0, 2500); } catch (_) {}
    report.networkErrors.push({
      status: response.status(),
      rpc: response.url().split('/rest/v1/rpc/')[1]?.split('?')[0] || response.url(),
      body
    });
  });

  const qaName = 'QA Mobile Deep Flow 20260924';
  await ensureRegistration(page, qaName);
  report.qaUser = { name: qaName, uid: await getUid(page) };
  await openExamPrep(page);
  await openP1Home(page);

  report.stage0 = await finishStage0(page);
  if (!report.stage0.complete) throw new Error('Stage0 did not complete');
  await settleAfterStage0(page);
  report.stage0.screenshot = await shot(page, '01-stage0-complete', true).catch(() => null);

  report.weeklyFlowProbe = await probeWeeklyFlow(page);
  report.notes.push({ weeklyFlowProbe: report.weeklyFlowProbe });
  if (!report.weeklyFlowProbe?.ensure?.ok || !report.weeklyFlowProbe?.weeklyPlan?.ok) {
    throw new Error('Weekly flow probe failed: ' + JSON.stringify(report.weeklyFlowProbe));
  }

  const weeklyPresentation = await openWeeklyPlan(page);
  report.weeklyPlan = {
    data: await readPlan(page),
    presentation: weeklyPresentation,
    audit: await audit(page, 'weekly plan'),
    screenshot: await shot(page, '02-weekly-plan', true)
  };
  report.weeklyPlan.copy = await assertLearnerSafeCopy(page, 'weekly plan');

  await goDashboardThenP1(page);
  const queue = await makeCorrection(page);
  if (Number(queue?.active_count || 0) < 1) {
    throw new Error('Could not create a real correction through learner UI after three weekly tasks');
  }

  await goDashboardThenP1(page);
  await openCorrections(page);
  report.correction = {
    queue,
    audit: await audit(page, 'correction queue'),
    copy: await assertLearnerSafeCopy(page, 'correction queue'),
    screenshot: await shot(page, '03-correction-queue', true)
  };

  const correctionFlow = await attemptCorrectionFlow(page);
  report.correction.flow = correctionFlow;

  const queueAfter = correctionFlow.queue || await readQueue(page);
  const cases = Array.isArray(queueAfter?.cases) ? queueAfter.cases : [];
  const waiting = cases.find(x => ['wait_delayed_retest','retest_content_wait'].includes(String(x?.process_step || '')));
  const retestReady = cases.find(x => String(x?.process_step || '') === 'delayed_retest');
  const planAfter = correctionFlow.plan || await readPlan(page);
  const planItems = Array.isArray(planAfter?.items) ? planAfter.items : [];
  const futureRetest = planItems.find(x => x?.item_type === 'retest' && x?.status === 'pending' && x?.due_at && Date.parse(x.due_at) > Date.now());

  if (waiting || futureRetest) {
    const waitingPresentation = await openWeeklyPlan(page);
    const retestPriority = Number(futureRetest?.priority_order || 0);
    const retestUi = await page.evaluate((priority) => {
      const visible = el => {
        if (!el) return false;
        const cs = getComputedStyle(el);
        const r = el.getBoundingClientRect();
        return !el.hidden && cs.display !== 'none' && cs.visibility !== 'hidden' &&
          r.width > 0 && r.height > 0;
      };
      const nativeButton = priority > 0
        ? document.querySelector(`[data-ep-live-plan-item="${priority}"]`)
        : Array.from(document.querySelectorAll('[data-ep-live-plan-item]')).find(button => button.disabled);
      const waitingGoals = Array.from(document.querySelectorAll('.ep-pux-goal-waiting')).filter(visible);
      return {
        nativeExists: Boolean(nativeButton),
        nativeDisabled: Boolean(nativeButton?.disabled),
        nativeVisible: visible(nativeButton),
        verifiedProgressUx: document.querySelector('.ep-pux-week')?.dataset.epPuxPrimaryGoals === 'verified',
        visibleWaitingGoals: waitingGoals.length,
        visibleGoalActions: Array.from(document.querySelectorAll('.ep-pux-goal-action')).filter(visible).length,
        waitingText: waitingGoals.map(x => String(x.textContent || '').trim()).join(' | ').slice(0, 1800)
      };
    }, retestPriority);

    report.delayedRetest = {
      state: 'waiting',
      case: waiting || null,
      futureRetest: futureRetest || null,
      presentation: waitingPresentation,
      ui: retestUi,
      audit: await audit(page, 'delayed retest waiting plan'),
      copy: await assertLearnerSafeCopy(page, 'delayed retest waiting plan'),
      screenshot: await shot(page, '04-delayed-retest-waiting', true)
    };

    if (futureRetest && (!retestUi.nativeExists || !retestUi.nativeDisabled)) {
      throw new Error('Future delayed retest is not guarded by a disabled native action: ' + JSON.stringify(retestUi));
    }
    if (retestUi.verifiedProgressUx && retestUi.visibleWaitingGoals < 1) {
      throw new Error('Delayed retest is guarded internally but the learner-facing waiting state is missing: ' + JSON.stringify(retestUi));
    }
  } else if (retestReady) {
    report.delayedRetest = { state: 'ready', case: retestReady };
  } else {
    report.delayedRetest = {
      state: 'not_reached',
      queueAfter,
      planAfter,
      note: 'Correction mobile screen is verified; remediation did not yet reach the delayed-retention wait in this black-box UI run.'
    };
  }

  report.finishedAt = new Date().toISOString();
  fs.writeFileSync(path.join(OUT, 'report.json'), JSON.stringify(report, null, 2));
  console.log(JSON.stringify({
    status: 'MOBILE_DEEP_FLOW_CAPTURED',
    stage0Complete: report.stage0.complete,
    weeklyPlan: Boolean(report.weeklyPlan),
    correctionActive: Number(queue?.active_count || 0),
    delayedRetest: report.delayedRetest?.state,
    consoleErrors: report.consoleErrors.length,
    pageErrors: report.pageErrors.length,
    networkErrors: report.networkErrors.length
  }, null, 2));

  if (report.consoleErrors.length || report.pageErrors.length) {
    throw new Error('Browser errors detected during deep mobile flow');
  }

  await context.close();
  await browser.close();
})().catch(err => {
  report.finishedAt = new Date().toISOString();
  report.fatal = String(err && err.stack || err);
  fs.writeFileSync(path.join(OUT, 'report.json'), JSON.stringify(report, null, 2));
  console.error(err);
  process.exit(1);
});
