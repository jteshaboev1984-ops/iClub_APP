const fs = require('fs');
const { chromium } = require('playwright');

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

const html = fs.readFileSync('index.html', 'utf8');
const css = fs.readFileSync('visual/iclub-premium-v3.css', 'utf8');

for (const contract of [
  'id="profile-competitive-slots-list"',
  'id="profile-credentials-grid"',
  'id="ratings-list"',
  'id="notifications-list"',
  'id="support-topics"'
]) {
  assert(html.includes(contract), `Dynamic UI contract missing ${contract}`);
}

function requirePremiumTokens() {
  for (const token of [
    'PREMIUM DYNAMIC LOCALE SURFACES v3.7',
    '#view-profile .slot-card',
    '#view-profile .credential-card',
    '#view-ratings .lb-row',
    '#view-ratings .lb-name',
    'LANGUAGE-SAFE WRAPPING'
  ]) {
    assert(css.includes(token), `Dynamic/locale premium CSS missing ${token}`);
  }
}

for (const forbidden of [/localStorage/i, /sessionStorage/i, /supabase/i, /\.rpc\s*\(/, /\.from\s*\(/, /operational_stage\s*=/, /innerHTML\s*=/]) {
  assert(!forbidden.test(css), `Dynamic/locale premium layer must stay presentation-only: ${forbidden}`);
}

function profileMarkup() {
  return {
    slots: `<article class="slot-card"><div><div class="slot-title">Mathematics</div><div class="muted small">Соревновательный предмет · текущий сезон</div></div></article>
      <article class="slot-card is-empty"><div><div class="slot-title">Свободное место</div><div class="muted small">Можно подключить ещё один предмет</div></div></article>`,
    credentials: `<article class="credential-card"><div class="credential-item"><div class="credential-ico">✓</div><div style="min-width:0"><div class="credential-title">Стабильный результат по Mathematics</div><div class="credential-meta">Подтверждено результатами нескольких попыток</div></div></div><div class="cred-progress-item">Прогресс подтверждается после новых результатов</div></article>
      <article class="credential-card"><div class="credential-item"><div class="credential-ico">✓</div><div style="min-width:0"><div class="credential-title">Matematika bo‘yicha barqaror natija</div><div class="credential-meta">Bir nechta urinish natijalari bilan tasdiqlangan</div></div></div></article>`
  };
}

function ratingsMarkup() {
  return `<div class="lb-row"><div class="lb-rank">1</div><div class="lb-student"><div class="lb-avatar">AE</div><div class="lb-student-txt"><div class="lb-name">Abdullohbek Muhammadaliyev</div><div class="lb-meta">Toshkent shahri · Prezident maktabi · 11-sinf</div></div></div><div class="lb-score">19/20</div><div class="lb-time">11:42</div></div>
    <div class="lb-row"><div class="lb-rank">12</div><div class="lb-student"><div class="lb-avatar">МР</div><div class="lb-student-txt"><div class="lb-name">Мухаммадрасул Абдурахманов</div><div class="lb-meta">Республика Каракалпакстан · специализированная школа</div></div></div><div class="lb-score">17/20</div><div class="lb-time">13:08</div></div>`;
}

async function activateProfile(page) {
  const sample = profileMarkup();
  await page.evaluate(({ slots, credentials }) => {
    document.querySelectorAll('.view').forEach(node => node.classList.remove('is-active'));
    const profile = document.getElementById('view-profile');
    profile.classList.add('is-active');
    const main = document.getElementById('profile-main');
    main.classList.add('is-active');
    document.getElementById('profile-competitive-slots-list').innerHTML = slots;
    document.getElementById('profile-credentials-grid').innerHTML = credentials;
    const longRow = profile.querySelector('.profile-row-title');
    if (longRow) longRow.textContent = 'Мои персональные рекомендации по дальнейшей подготовке';
  }, sample);
}

async function activateRatings(page) {
  await page.evaluate((rows) => {
    document.querySelectorAll('.view').forEach(node => node.classList.remove('is-active'));
    const ratings = document.getElementById('view-ratings');
    ratings.classList.add('is-active');
    document.getElementById('ratings-list').innerHTML = rows;
    document.querySelectorAll('#view-ratings .seg-btn')[0].textContent = 'Район';
    document.querySelectorAll('#view-ratings .seg-btn')[1].textContent = 'Регион';
    document.querySelectorAll('#view-ratings .seg-btn')[2].textContent = 'Республика';
  }, ratingsMarkup());
}

async function activateSubjectHubWithLongCopy(page) {
  await page.evaluate(() => {
    document.querySelectorAll('.view').forEach(node => node.classList.remove('is-active'));
    const courses = document.getElementById('view-courses');
    courses.classList.add('is-active');
    document.querySelectorAll('#courses-stack .stack-screen').forEach(node => {
      node.classList.remove('is-active');
      node.hidden = true;
    });
    const hub = document.getElementById('courses-subject-hub');
    hub.hidden = false;
    hub.classList.add('is-active');
    const practice = hub.querySelector('.subject-mode-card-practice .subject-mode-description');
    const tours = hub.querySelector('.subject-mode-card-tours .subject-mode-description');
    const status = hub.querySelector('.subject-mode-card-tours .subject-mode-status');
    if (practice) practice.textContent = 'Темаларды өз темпіңізде машқ қилинг ва хатоларга қайта-қайта мурожаат қилинг.';
    if (tours) tours.textContent = 'Белгиланган вақтда билимингизни рақобат форматида текширинг.';
    if (status) status.textContent = 'Jadval bo‘yicha mavjud';
  });
}

(async () => {
  requirePremiumTokens();
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage({ viewport: { width: 390, height: 844 }, javaScriptEnabled: false });
  const url = process.env.VISUAL_V3_PREMIUM_URL || 'http://127.0.0.1:4173/index.html';
  await page.goto(url, { waitUntil: 'domcontentloaded' });

  await activateProfile(page);
  let state = await page.evaluate(() => {
    const slot = document.querySelector('#view-profile .slot-card');
    const credential = document.querySelector('#view-profile .credential-card');
    const progress = document.querySelector('#view-profile .cred-progress-item');
    return {
      slotRadius: getComputedStyle(slot).borderRadius,
      slotShadow: getComputedStyle(slot).boxShadow,
      credentialRadius: getComputedStyle(credential).borderRadius,
      credentialShadow: getComputedStyle(credential).boxShadow,
      progressRadius: getComputedStyle(progress).borderRadius,
      width: document.documentElement.scrollWidth,
      innerWidth
    };
  });
  assert(state.slotRadius === '12px', `Profile slot radius drift: ${state.slotRadius}`);
  assert(state.slotShadow !== 'none', 'Profile slot premium surface missing');
  assert(state.credentialRadius === '12px', `Credential radius drift: ${state.credentialRadius}`);
  assert(state.credentialShadow !== 'none', 'Credential premium surface missing');
  assert(state.progressRadius === '8px', `Credential progress radius drift: ${state.progressRadius}`);
  assert(state.width <= state.innerWidth, `Profile dynamic overflow: ${JSON.stringify(state)}`);

  await activateRatings(page);
  state = await page.evaluate(() => {
    const row = document.querySelector('#view-ratings .lb-row');
    const avatar = row.querySelector('.lb-avatar');
    const name = row.querySelector('.lb-name');
    const meta = row.querySelector('.lb-meta');
    return {
      rowHeight: row.getBoundingClientRect().height,
      avatarWidth: avatar.getBoundingClientRect().width,
      nameSize: parseFloat(getComputedStyle(name).fontSize),
      metaSize: parseFloat(getComputedStyle(meta).fontSize),
      width: document.documentElement.scrollWidth,
      innerWidth
    };
  });
  assert(state.rowHeight >= 56, `Ratings row target too small: ${state.rowHeight}`);
  assert(state.avatarWidth >= 30 && state.avatarWidth <= 36, `Ratings avatar size drift: ${state.avatarWidth}`);
  assert(state.nameSize >= 11.5, `Ratings name hierarchy too weak: ${state.nameSize}`);
  assert(state.metaSize >= 9.5, `Ratings metadata too small: ${state.metaSize}`);
  assert(state.width <= state.innerWidth, `Ratings long-copy overflow: ${JSON.stringify(state)}`);

  await activateSubjectHubWithLongCopy(page);
  state = await page.evaluate(() => ({ width: document.documentElement.scrollWidth, innerWidth }));
  assert(state.width <= state.innerWidth, `Subject Hub RU/UZ long-copy overflow: ${JSON.stringify(state)}`);

  await page.setViewportSize({ width: 320, height: 780 });
  await activateProfile(page);
  let small = await page.evaluate(() => ({ width: document.documentElement.scrollWidth, innerWidth }));
  assert(small.width <= small.innerWidth, `Profile 320px overflow: ${JSON.stringify(small)}`);
  await activateRatings(page);
  small = await page.evaluate(() => ({ width: document.documentElement.scrollWidth, innerWidth }));
  assert(small.width <= small.innerWidth, `Ratings 320px overflow: ${JSON.stringify(small)}`);
  await activateSubjectHubWithLongCopy(page);
  small = await page.evaluate(() => ({ width: document.documentElement.scrollWidth, innerWidth }));
  assert(small.width <= small.innerWidth, `RU/UZ 320px overflow: ${JSON.stringify(small)}`);

  const routes = await page.locator('#tabbar .tab').evaluateAll(nodes => nodes.map(node => node.getAttribute('data-tab')));
  assert(JSON.stringify(routes) === JSON.stringify(['home', 'courses', 'ratings', 'profile']), `Dynamic/locale pass changed global routes: ${JSON.stringify(routes)}`);

  await browser.close();
  console.log('Visual v3 dynamic/locale regression: GREEN');
})().catch(error => {
  console.error(error);
  process.exit(1);
});
