'use strict';
const assert = require('node:assert/strict');
const path = require('node:path');
const { chromium } = require('playwright');

const EXPECT = {
  ru: ['Недельный план пока не составлен.', 'История занятий сохранена.'],
  uz: ['Haftalik reja hali tuzilmagan.', 'Mashg‘ulotlar tarixi saqlangan.'],
  en: ['Your weekly plan has not been created yet.', 'Your session history is preserved.']
};
const plan = count => ({
  contract_version:'progress_ux_v1',component_code:'P5',active_week_no:1,
  plan_available:false,completed_goals:0,finalized_study_sessions:count,
  open_corrections:0,confirmed_skills:0,coverage_pct:0,goals:[]
});
(async () => {
  const browser = await chromium.launch({headless:true});
  try {
    for (const [lang,[noPlan,history]] of Object.entries(EXPECT)) {
      const page = await browser.newPage();
      const errors = [];
      page.on('pageerror',e=>errors.push(e.message));
      await page.setContent(`<!doctype html><html lang="${lang}"><body><div id="exam-prep-host-root" aria-hidden="false"><article class="ep-live-component-card" data-ep-live-component="P5"><div class="ep-live-actions"></div></article></div></body></html>`);
      await page.evaluate(fixture=>{
        window.iClubExamPrepProgressUxEnabled=true;
        window.__progressFixture=fixture;
        window.iClubExamPrepHostInternal={
          lastCapabilities:{coreAccess:true,killSwitch:false,rolloutState:'controlled_beta'},
          progressUxApi:{progress:async()=>({ok:true,data:structuredClone(window.__progressFixture)})}
        };
      },plan(0));
      await page.addScriptTag({path:path.resolve('exam-prep/exam-prep-progress-ux-model.js')});
      await page.addScriptTag({path:path.resolve('exam-prep/exam-prep-progress-ux-ui.js')});
      await page.waitForSelector('.ep-pux-overview');
      const empty = await page.locator('.ep-pux-overview').innerText();
      assert.ok(empty.includes(noPlan),`${lang}: empty plan must have an honest message`);
      assert.ok(!empty.includes(history),`${lang}: empty account must not claim prior history`);
      assert.ok(!/0 из 3|0 of 3|3 tadan 0/.test(empty),`${lang}: no fabricated denominator`);
      await page.evaluate(fixture=>{
        window.__progressFixture=fixture;
        document.querySelector('#exam-prep-host-root').innerHTML='<article class="ep-live-component-card" data-ep-live-component="P5"><div class="ep-live-actions"></div></article>';
      },plan(4));
      await page.waitForFunction(()=>document.querySelector('.ep-pux-overview')?.textContent.includes('4'));
      const previous = await page.locator('.ep-pux-overview').innerText();
      assert.ok(previous.includes(history),`${lang}: actual historical activity must be acknowledged`);
      assert.ok(previous.includes(noPlan),`${lang}: absent plan must remain absent`);
      assert.deepEqual(errors,[],`${lang}: must have no page errors`);
      await page.close();
    }
    console.log('Progress UX learner copy: PASS (RU/UZ/EN no-plan vs historical sessions, no invented weekly denominator)');
  } finally { await browser.close(); }
})().catch(e=>{console.error(e);process.exit(1);});
