'use strict';
const assert = require('node:assert/strict');
const path = require('node:path');
const { chromium } = require('playwright');

const COPY = {
  ru: {plan:'Недельный план', wait:'Ожидается повторная проверка', unknown:'Дата уточняется', old:'Ранее выполненная работа сохранена.', done:'Работа по этой цели выполнена.'},
  uz: {plan:'Haftalik reja', wait:'Qayta tekshiruv kutilmoqda', unknown:'Sana aniqlanmoqda', old:'Avval bajarilgan ishlar saqlangan.', done:'Ushbu maqsad bo‘yicha ish bajarildi.'},
  en: {plan:'Weekly plan', wait:'Waiting for a delayed check', unknown:'Date to be confirmed', old:'Your earlier work is preserved.', done:'Work on this goal is complete.'}
};
function fixture(status, due = null) {
  return {
    contract_version:'progress_ux_v1',component_code:'P1',active_week_no:1,
    plan_available:true,completed_goals:1,finalized_study_sessions:3,
    open_corrections:1,confirmed_skills:2,coverage_pct:5,
    goals:[{goal_id:'isolated-wait',component_code:'P1',priority_order:1,
      item_type:'correction',skill_code:'P1-CIR-01',status,
      weekly_commitment_complete:true,correction_open:true,finalized_sessions:3,
      action_priority_order:null,retest_due_at:due,plan_changed:false}]
  };
}
const plan = c => `<section class="ep-host-shell ep-live"><div class="ep-live-card"><div class="ep-live-head"><strong>P1 · ${c.plan}</strong></div><p class="ep-live-notice">No available task</p></div></section>`;
const finish = '<section class="ep-host-shell ep-live ep-flow-completion-screen"><h2>Session completed</h2><div class="ep-flow-completion-card">Answers saved</div><div class="ep-flow-next-card">Next step</div></section>';

(async () => {
  const browser = await chromium.launch({headless:true});
  try {
    for (const [language,c] of Object.entries(COPY)) {
      const page = await browser.newPage({viewport:{width:320,height:780}});
      const errors=[];
      page.on('pageerror',e=>errors.push(e.message));
      await page.setContent(`<!doctype html><html lang="${language}"><head><meta name="viewport" content="width=device-width,initial-scale=1"></head><body><div id="exam-prep-host-root" aria-hidden="false">${plan(c)}</div></body></html>`);
      await page.addStyleTag({path:path.resolve('exam-prep/exam-prep-progress-ux.css')});
      await page.evaluate(data=>{
        window.iClubExamPrepProgressUxEnabled=true;
        window.__waitFixture=data;
        window.iClubExamPrepHostInternal={
          lastCapabilities:{coreAccess:true,killSwitch:false,rolloutState:'controlled_beta'},
          progressUxApi:{progress:async()=>({ok:true,data:structuredClone(window.__waitFixture)})}
        };
      },fixture('waiting_retest'));
      await page.addScriptTag({path:path.resolve('exam-prep/exam-prep-progress-ux-model.js')});
      await page.addScriptTag({path:path.resolve('exam-prep/exam-prep-progress-ux-ui.js')});
      await page.waitForSelector('.ep-pux-goal-waiting');
      const waiting=await page.locator('.ep-pux-goal-waiting').innerText();
      assert.ok(waiting.includes(c.done),`${language}: completed goal work must be scoped to one goal`);
      assert.ok(!waiting.includes(c.old),`${language}: waiting must not claim failure`);
      assert.equal(await page.locator('.ep-pux-week button').count(),0,`${language}: no invented early retest button`);

      await page.evaluate(html=>{
        window.dispatchEvent(new CustomEvent('iclub:exam-prep-session',{
          detail:{session:{session_id:'isolated-session',session_type:'learning',component_code:'P1'}}
        }));
        window.dispatchEvent(new CustomEvent('iclub:exam-prep-session-ended',{detail:{sessionId:'isolated-session'}}));
        document.querySelector('#exam-prep-host-root').innerHTML=html;
      },finish);
      await page.waitForSelector('.ep-pux-waiting');
      const completion=await page.locator('.ep-pux-waiting').innerText();
      assert.ok(completion.includes(c.wait),`${language}: completion explains delayed check`);
      assert.ok(completion.includes(c.unknown),`${language}: missing due date stays unknown`);
      assert.equal(await page.locator('.ep-pux-waiting button').count(),0,`${language}: no invented retest button`);
      assert.equal(await page.locator('.ep-flow-completion-card').count(),1,`${language}: original completion preserved`);
      assert.equal(await page.evaluate(()=>document.documentElement.scrollWidth<=document.documentElement.clientWidth),true,`${language}: waiting notice mobile overflow`);

      await page.evaluate(({data,html})=>{
        window.__waitFixture=data;
        document.querySelector('#exam-prep-host-root').innerHTML=html;
      },{data:fixture('needs_rework','2026-09-20T08:00:00Z'),html:plan(c)});
      await page.waitForSelector('.ep-pux-goal-rework');
      const reopened=await page.locator('.ep-pux-goal-rework').innerText();
      assert.ok(reopened.includes(c.old),`${language}: reopened correction preserves history and requests more work`);
      assert.ok(!reopened.includes(c.done),`${language}: reopened correction must not claim current work complete`);
      assert.equal(await page.locator('.ep-pux-goal-waiting').count(),0,`${language}: reopened is not waiting`);
      assert.equal(await page.evaluate(()=>document.documentElement.scrollWidth<=document.documentElement.clientWidth),true,`${language}: reopened mobile overflow`);
      assert.deepEqual(errors,[],`${language}: no uncaught browser errors`);
      await page.close();
    }
    console.log('Progress UX waiting/reopened browser: PASS (RU/UZ/EN, unknown date, no fake retest, 320px)');
  } finally { await browser.close(); }
})().catch(e=>{console.error(e);process.exit(1);});
