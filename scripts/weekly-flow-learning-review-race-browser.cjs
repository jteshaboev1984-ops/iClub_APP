'use strict';
// Isolated Chromium regression of the REAL optional review bridge. All responses
// are synthetic; no network, account, database, or persisted student state.
const assert = require('node:assert/strict');
const path = require('node:path');
const { chromium } = require('playwright');
const SESSION = '11111111-1111-4111-8111-111111111111';
const OTHER = '22222222-2222-4222-8222-222222222222';
const GOAL = '33333333-3333-4333-8333-333333333333';
const PLAN = '44444444-4444-4444-8444-444444444444';
const phrases = {
  ru: 'Это учебное повторение, а не новая независимая проверка знаний.',
  uz: 'Bu o‘quv takrori, yangi mustaqil bilim tekshiruvi emas.',
  en: 'This is learning review, not a new independent knowledge check.'
};
async function scenario(browser, language, width) {
  const page = await browser.newPage({viewport:{width,height:850}});
  const errors = [];
  page.on('pageerror', error => errors.push(error.message));
  await page.route(/^https?:\/\//, route => route.abort());
  try {
    await page.setContent(`<!doctype html><html lang="${language}"><body><div id="exam-prep-host-root" aria-hidden="false"></div></body></html>`);
    await page.evaluate(([lang,session,other,goal,plan]) => {
      window.iClubExamPrepWeeklyFlowEnabled = true;
      window.i18n = {getLang:()=>lang};
      const s = window.__race = {
        component:'P5', session, other, goal, plan, recovered:0, reviewed:0,
        proof:{status:'resume',session_id:session,learning_review:true},
        decision:{status:'review_ready',reason:'same_pack_learning_review',
          component_code:'P5',goal_id:goal,plan_id:plan,item_type:'learning',
          fresh_assessment:false},
        reviewReply:{status:'resume_existing_session_first',session_id:session},
        planReply:{status:'resume_first',recovery:{status:'resume',session_id:session,
          learning_review:true}}
      };
      const ok = data => ({ok:true,data:structuredClone(data)});
      window.iClubExamPrepHostInternal = {
        lastCapabilities:{coreAccess:true,killSwitch:false,rolloutState:'controlled_beta'},
        weeklyFlowApi:Object.freeze({
          version:'weekly_flow_adapter_v1',allowed:()=>null,
          recover:async()=>{s.recovered++;return ok(s.proof);},
          plan:async()=>ok(s.planReply),
          authorize:async()=>ok(s.decision),
          review:async()=>{s.reviewed++;return ok(s.reviewReply);},
          goal:async()=>ok({status:'review_ready',component_code:'P5',goal_id:goal,
            plan_id:plan,priority_order:1,reason:'same_pack_learning_review',fresh_assessment:false})
        })
      };
    },[language,SESSION,OTHER,GOAL,PLAN]);
    await page.addScriptTag({path:path.resolve('exam-prep/exam-prep-weekly-review-ui.js')});
    const hasNote = async () => page.locator('[data-ep-learning-review-note]').count();
    const renderQuestion = async kind => page.evaluate(kind => {
      document.querySelector('#exam-prep-host-root').innerHTML =
        `<div class="ep-live-card"><div class="ep-live-qtext">One question</div>${kind==='timed'?'<button data-ep-live-end>End</button><span data-ep-live-timer></span>':''}</div>`;
    },kind);
    // Concurrent review start returned ONLY a bare session ID; prove it with
    // fresh recovery before presenting the known-question learning disclaimer.
    let result = await page.evaluate(async () => {
      const s=window.__race;
      return window.iClubExamPrepHostInternal.weeklyFlowApi.authorize('P5',s.goal,s.plan);
    });
    assert.equal(result.ok,true);
    assert.equal(result.data.status,'resume');
    assert.equal(result.data.session_id,SESSION);
    assert.equal(await page.evaluate(()=>window.__race.recovered),1);
    await renderQuestion('learning');
    await page.waitForSelector('[data-ep-learning-review-note]');
    assert.ok((await page.locator('[data-ep-learning-review-note]').innerText()).includes(phrases[language]));
    await renderQuestion('timed');
    assert.equal(await hasNote(),0,'Timed examination must never be labelled learning review');
    // Next normal P1 task replaces P5 screen; no P5 review notice can leak.
    result = await page.evaluate(async () => {
      const s=window.__race;
      s.decision={status:'authorized',authorization_id:s.other};
      return window.iClubExamPrepHostInternal.weeklyFlowApi.authorize('P1',s.goal,s.plan);
    });
    assert.equal(result.data.status,'authorized');
    await renderQuestion('learning');
    assert.equal(await hasNote(),0,'Review marker must not leak to P1');
    // A cold verified review recovery (no new write) restores the marker.
    result = await page.evaluate(async () => {
      const s=window.__race;
      s.planReply={status:'resume_first',recovery:{status:'resume',session_id:s.session,
        learning_review:true}};
      return window.iClubExamPrepHostInternal.weeklyFlowApi.plan('P5');
    });
    assert.equal(result.data.status,'resume_first');
    await renderQuestion('learning');
    await page.waitForSelector('[data-ep-learning-review-note]');
    // A normal verified recovery must remove the marker and existing notice.
    await page.evaluate(async () => {
      const s=window.__race;
      s.proof={status:'resume',session_id:s.other,learning_review:false};
      return window.iClubExamPrepHostInternal.weeklyFlowApi.recover('P1');
    });
    assert.equal(await hasNote(),0,'Non-review recovery removes stale notice');
    // Identity mismatch after a race: FAIL CLOSED instead of navigating to
    // a guessed session or showing a false review marker.
    result = await page.evaluate(async () => {
      const s=window.__race;
      s.decision={status:'review_ready',reason:'same_pack_learning_review',
        component_code:'P5',goal_id:s.goal,plan_id:s.plan,item_type:'learning',fresh_assessment:false};
      s.reviewReply={status:'resume_existing_session_first',session_id:s.session};
      s.proof={status:'resume',session_id:s.other,learning_review:true};
      return window.iClubExamPrepHostInternal.weeklyFlowApi.authorize('P5',s.goal,s.plan);
    });
    assert.equal(result.ok,false);
    assert.equal(result.reason,'review_resume_unverified');
    assert.equal(await hasNote(),0);
    assert.deepEqual(errors,[]);
    console.log(`PASS race notice identity, cold resume and cross-component isolation: ${language} ${width}px`);
  } finally {await page.close();}
}
(async()=>{
  const browser=await chromium.launch({headless:true});
  try {
    for(const language of ['ru','uz','en']) for(const width of [390,1280])
      await scenario(browser,language,width);
    console.log('GREEN: 6 synthetic race / cold-resume / notice-isolation browser scenarios; external network blocked.');
  } finally {await browser.close();}
})().catch(error=>{console.error(error);process.exitCode=1;});