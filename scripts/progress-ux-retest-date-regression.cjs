'use strict';
const assert = require('node:assert/strict');
const path = require('node:path');
const { chromium } = require('playwright');
const EXPECT = {ru:'20 сентября 2026',uz:'2026-yil 20-sentabr',en:'20 September 2026'};
const payload = {
  contract_version:'progress_ux_v1',component_code:'P1',active_week_no:1,
  plan_available:true,completed_goals:1,finalized_study_sessions:1,
  open_corrections:1,confirmed_skills:0,coverage_pct:0,
  goals:[{goal_id:'date-fixture',component_code:'P1',priority_order:1,item_type:'correction',
    skill_code:'P1-CIR-01',status:'waiting_retest',weekly_commitment_complete:true,
    correction_open:true,finalized_sessions:1,action_priority_order:null,
    retest_due_at:'2026-09-20T08:00:00Z',plan_changed:false}]
};
(async()=>{
  const browser=await chromium.launch({headless:true});
  try {
    for(const [lang,expected] of Object.entries(EXPECT)){
      const page=await browser.newPage({timezoneId:'Asia/Tashkent'});
      const errors=[];
      page.on('pageerror',error=>errors.push(error.message));
      await page.setContent(`<!doctype html><html lang="${lang}"><body><div id="exam-prep-host-root" aria-hidden="false"><article class="ep-live-card"><div class="ep-live-head"><strong>P1 · Weekly plan</strong></div><div class="ep-live-plan-item"><button data-ep-live-plan-item="1">Start</button></div></article></div></body></html>`);
      await page.evaluate(fixture=>{
        window.iClubExamPrepProgressUxEnabled=true;
        window.iClubExamPrepHostInternal={
          lastCapabilities:{coreAccess:true,killSwitch:false,rolloutState:'controlled_beta'},
          progressUxApi:{progress:async()=>({ok:true,data:structuredClone(fixture)})}
        };
      },payload);
      await page.addScriptTag({path:path.resolve('exam-prep/exam-prep-progress-ux-model.js')});
      await page.addScriptTag({path:path.resolve('exam-prep/exam-prep-progress-ux-ui.js')});
      await page.waitForSelector('.ep-pux-week .ep-pux-goal');
      const text=await page.locator('.ep-pux-week').innerText();
      assert.ok(text.includes(expected),`${lang}: expected readable date ${expected}; received ${text}`);
      assert.ok(!/\bM0?[1-9]\b|\bM1[012]\b/.test(text),`${lang}: ICU numerical month must never reach students`);
      assert.deepEqual(errors,[],`${lang}: no script errors`);
      await page.close();
    }
    console.log('Progress UX delayed-check dates: PASS (RU/UZ/EN explicit readable dates)');
  } finally {await browser.close();}
})().catch(error=>{console.error(error);process.exit(1);});