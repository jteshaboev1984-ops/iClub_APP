const { chromium } = require('playwright');
const path = require('path');

(async () => {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();
  await page.setContent('<!doctype html><html><body><div id="exam-prep-host-root"></div></body></html>');

  await page.evaluate(() => {
    window.__variant = 'single';
    const singleChecks = [{ check_order:1, check_kind:'mcq', prompt:'Sample short question?', options:['A','B'] }];
    const multiChecks = [
      { check_order:1, check_kind:'mcq', prompt:'First short question?', options:['A','B'] },
      { check_order:2, check_kind:'mcq', prompt:'Second short question?', options:['A','B'] }
    ];
    window.iClubExamPrepHostInternal = {
      api: {
        getSession: async () => ({ ok:true, data:{
          session_id:'00000000-0000-4000-8000-000000009201',
          items:[{
            item_order:1,
            item_kind:'written',
            answered:false,
            understanding_checks: window.__variant === 'single' ? singleChecks : multiChecks
          }]
        }}),
        submitResponse: async () => ({ ok:true, data:{} })
      }
    };
  });

  await page.addScriptTag({ path:path.resolve('exam-prep/exam-prep-written-understanding-ui.js') });

  const cases = [
    {
      lang:'ru',
      help:'Ответьте на короткий вопрос, затем объясните решение своими словами.',
      incomplete:'Сначала ответьте на короткий вопрос.',
      forbidden:'Пункт 1'
    },
    {
      lang:'uz',
      help:'Qisqa savolga javob bering, keyin yechimingizni o‘z so‘zlaringiz bilan tushuntiring.',
      incomplete:'Avval qisqa savolga javob bering.',
      forbidden:'Savol 1'
    },
    {
      lang:'en',
      help:'Answer the short question, then explain your solution in your own words.',
      incomplete:'Answer the short question first.',
      forbidden:'Check 1'
    }
  ];

  for (const tc of cases) {
    await page.evaluate(() => {
      document.querySelector('#exam-prep-host-root').innerHTML = '';
      window.__variant = 'single';
    });
    await page.evaluate(async lang => {
      await window.iClubExamPrepHostInternal.api.getSession('00000000-0000-4000-8000-000000009201', lang);
    }, tc.lang);
    await page.evaluate(() => {
      document.querySelector('#exam-prep-host-root').innerHTML = '<label><textarea name="ep_live_written_answer"></textarea></label><button data-ep-live-submit>Submit</button>';
    });
    await page.waitForSelector('[data-ep-written-understanding="true"]');
    let text = await page.locator('#exam-prep-host-root').textContent();
    if (!text.includes(tc.help)) throw new Error(`singular help missing for ${tc.lang}`);
    if (text.includes(tc.forbidden)) throw new Error(`single check should not show numbered label for ${tc.lang}`);
    await page.click('[data-ep-live-submit]');
    await page.waitForSelector('[data-ep-written-understanding-error]:not([hidden])');
    text = await page.locator('#exam-prep-host-root').textContent();
    if (!text.includes(tc.incomplete)) throw new Error(`singular incomplete copy missing for ${tc.lang}`);
  }

  await page.evaluate(() => {
    document.querySelector('#exam-prep-host-root').innerHTML = '';
    window.__variant = 'multi';
  });
  await page.evaluate(async () => {
    await window.iClubExamPrepHostInternal.api.getSession('00000000-0000-4000-8000-000000009201', 'en');
  });
  await page.evaluate(() => {
    document.querySelector('#exam-prep-host-root').innerHTML = '<label><textarea name="ep_live_written_answer"></textarea></label><button data-ep-live-submit>Submit</button>';
  });
  await page.waitForSelector('[data-ep-written-understanding="true"]');
  let multiText = await page.locator('#exam-prep-host-root').textContent();
  if (!multiText.includes('Answer the short questions, then explain your solution in your own words.')) throw new Error('plural help changed');
  if (!multiText.includes('Check 1') || !multiText.includes('Check 2')) throw new Error('multi-check numbering missing');
  await page.click('[data-ep-live-submit]');
  await page.waitForSelector('[data-ep-written-understanding-error]:not([hidden])');
  multiText = await page.locator('#exam-prep-host-root').textContent();
  if (!multiText.includes('Answer all short questions first.')) throw new Error('plural incomplete copy changed');

  await browser.close();
  console.log('Written understanding single/plural copy regression: PASS');
})().catch(error => { console.error(error); process.exit(1); });
