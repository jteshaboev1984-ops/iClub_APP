const fs = require('fs');
const { chromium } = require('playwright');

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

const html = fs.readFileSync('index.html', 'utf8');
const app = fs.readFileSync('app.js', 'utf8');
const css = fs.readFileSync('visual/iclub-premium-v3.css', 'utf8');

for (const token of [
  'PREMIUM TRANSIENT SURFACES v3.6',
  '#modal-root .modal-backdrop',
  '#modal-root .modal',
  '#toast.is-show',
  '#view-transition-overlay .view-transition-card',
  '#ratings-loading .lb-loading-card',
  '#tours-loading .tours-loading-card',
  '#view-notifications .notification-card',
  '#question-image-modal .question-image-modal-content'
]) {
  assert(css.includes(token), `Transient premium CSS missing ${token}`);
}

for (const contract of [
  'id="toast" class="toast"',
  'id="modal-root" class="modal-root"',
  'id="view-transition-overlay"',
  'id="ratings-loading"',
  'id="question-image-modal"'
]) {
  assert(html.includes(contract), `Transient UI host contract missing ${contract}`);
}

assert(app.includes('classList.add("is-show")'), 'Toast behavior contract changed');
assert(app.includes('class="modal-backdrop"'), 'Modal behavior contract changed');
assert(app.includes('class="modal"'), 'Modal surface contract changed');

for (const forbidden of [/localStorage/i, /sessionStorage/i, /supabase/i, /\.rpc\s*\(/, /\.from\s*\(/, /operational_stage\s*=/, /innerHTML\s*=/]) {
  assert(!forbidden.test(css), `Transient premium layer must stay presentation-only: ${forbidden}`);
}

(async () => {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage({ viewport: { width: 390, height: 844 }, javaScriptEnabled: false });
  const url = process.env.VISUAL_V3_PREMIUM_URL || 'http://127.0.0.1:4173/index.html';
  await page.goto(url, { waitUntil: 'domcontentloaded' });

  await page.evaluate(() => {
    const root = document.getElementById('modal-root');
    root.setAttribute('aria-hidden', 'false');
    root.innerHTML = `<div class="modal-backdrop"><div class="modal" role="dialog"><div class="modal-title">Очистить уведомления?</div><div class="modal-text">Все сообщения в колокольчике будут скрыты для вас.</div><div class="modal-actions"><button class="btn">Отмена</button><button class="btn danger">Очистить все</button></div></div></div>`;
  });

  let state = await page.evaluate(() => {
    const modal = document.querySelector('#modal-root .modal');
    const title = modal.querySelector('.modal-title');
    const actions = modal.querySelector('.modal-actions');
    return {
      radius: getComputedStyle(modal).borderRadius,
      shadow: getComputedStyle(modal).boxShadow,
      maxWidth: modal.getBoundingClientRect().width,
      titleSize: parseFloat(getComputedStyle(title).fontSize),
      actionCols: getComputedStyle(actions).gridTemplateColumns.split(' ').length,
      width: document.documentElement.scrollWidth,
      innerWidth
    };
  });
  assert(state.radius === '12px', `Modal radius drift: ${state.radius}`);
  assert(state.shadow !== 'none', 'Modal premium shadow missing');
  assert(state.maxWidth <= 360, `Modal too wide on mobile: ${state.maxWidth}`);
  assert(state.titleSize >= 16, `Modal title hierarchy too weak: ${state.titleSize}`);
  assert(state.actionCols >= 1 && state.actionCols <= 2, `Modal action layout invalid: ${state.actionCols}`);
  assert(state.width <= state.innerWidth, `Modal overflow: ${JSON.stringify(state)}`);

  await page.evaluate(() => {
    const root = document.getElementById('modal-root');
    root.innerHTML = '';
    root.setAttribute('aria-hidden', 'true');
    const toast = document.getElementById('toast');
    toast.textContent = 'Сохранено';
    toast.classList.add('is-show');
  });

  state = await page.evaluate(() => {
    const toast = document.getElementById('toast');
    return {
      radius: getComputedStyle(toast).borderRadius,
      shadow: getComputedStyle(toast).boxShadow,
      maxWidth: toast.getBoundingClientRect().width,
      fontSize: parseFloat(getComputedStyle(toast).fontSize),
      width: document.documentElement.scrollWidth,
      innerWidth
    };
  });
  assert(state.radius === '10px', `Toast radius drift: ${state.radius}`);
  assert(state.shadow !== 'none', 'Toast premium shadow missing');
  assert(state.maxWidth <= 350, `Toast too wide: ${state.maxWidth}`);
  assert(state.fontSize >= 11, `Toast text too small: ${state.fontSize}`);
  assert(state.width <= state.innerWidth, `Toast overflow: ${JSON.stringify(state)}`);

  await page.evaluate(() => {
    document.getElementById('toast').classList.remove('is-show');
    const overlay = document.getElementById('view-transition-overlay');
    overlay.classList.remove('hidden');
    const ratings = document.getElementById('ratings-loading');
    ratings.style.display = 'grid';
  });

  state = await page.evaluate(() => {
    const transitionCard = document.querySelector('#view-transition-overlay .view-transition-card');
    const ratingsCard = document.querySelector('#ratings-loading .lb-loading-card');
    return {
      transitionRadius: getComputedStyle(transitionCard).borderRadius,
      transitionShadow: getComputedStyle(transitionCard).boxShadow,
      ratingsRadius: getComputedStyle(ratingsCard).borderRadius,
      ratingsShadow: getComputedStyle(ratingsCard).boxShadow,
      width: document.documentElement.scrollWidth,
      innerWidth
    };
  });
  assert(state.transitionRadius === '12px', `Transition card radius drift: ${state.transitionRadius}`);
  assert(state.transitionShadow !== 'none', 'Transition card premium shadow missing');
  assert(state.ratingsRadius === '12px', `Ratings loading card radius drift: ${state.ratingsRadius}`);
  assert(state.ratingsShadow !== 'none', 'Ratings loading card premium shadow missing');
  assert(state.width <= state.innerWidth, `Loading overlay overflow: ${JSON.stringify(state)}`);

  await page.evaluate(() => {
    document.getElementById('view-transition-overlay').classList.add('hidden');
    document.getElementById('ratings-loading').style.display = 'none';
    document.querySelectorAll('.view').forEach(node => node.classList.remove('is-active'));
    const notifications = document.getElementById('view-notifications');
    notifications.classList.add('is-active');
    document.getElementById('notifications-list').innerHTML = `<article class="notification-card is-unread"><div class="notification-main"><div class="notification-head"><div class="notification-title">Новый тур открыт</div><div class="notification-date">09.09.2026</div></div><div class="notification-body">Тур по Mathematics доступен до конца недели.</div></div><button class="notification-delete-btn" type="button">×</button></article>`;
  });

  state = await page.evaluate(() => {
    const card = document.querySelector('#view-notifications .notification-card');
    const deleteBtn = card.querySelector('.notification-delete-btn');
    return {
      radius: getComputedStyle(card).borderRadius,
      shadow: getComputedStyle(card).boxShadow,
      deleteRadius: getComputedStyle(deleteBtn).borderRadius,
      deleteSize: deleteBtn.getBoundingClientRect().width,
      width: document.documentElement.scrollWidth,
      innerWidth
    };
  });
  assert(state.radius === '12px', `Notification card radius drift: ${state.radius}`);
  assert(state.shadow !== 'none', 'Notification premium surface missing');
  assert(state.deleteRadius === '8px', `Notification delete control radius drift: ${state.deleteRadius}`);
  assert(state.deleteSize >= 30, `Notification delete control too small: ${state.deleteSize}`);
  assert(state.width <= state.innerWidth, `Notification overflow: ${JSON.stringify(state)}`);

  await page.setViewportSize({ width: 320, height: 780 });
  const small = await page.evaluate(() => ({ width: document.documentElement.scrollWidth, innerWidth }));
  assert(small.width <= small.innerWidth, `Transient surfaces 320px overflow: ${JSON.stringify(small)}`);

  const routes = await page.locator('#tabbar .tab').evaluateAll(nodes => nodes.map(node => node.getAttribute('data-tab')));
  assert(JSON.stringify(routes) === JSON.stringify(['home', 'courses', 'ratings', 'profile']), `Transient pass changed global routes: ${JSON.stringify(routes)}`);

  await browser.close();
  console.log('Visual v3 transient surfaces regression: GREEN');
})().catch(error => {
  console.error(error);
  process.exit(1);
});
