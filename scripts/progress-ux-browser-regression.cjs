'use strict';
const assert = require('node:assert/strict');
const path = require('node:path');
const { chromium } = require('playwright');

const P1 = () => ({
  contract_version:'progress_ux_v1', component_code:'P1', active_week_no:1,
  plan_available:true, completed_goals:0, finalized_study_sessions:5,
  open_corrections:3, confirmed_skills:0, coverage_pct:0,
  goals:[
    {goal_id:'g-cir',component_code:'P1',priority_order:1,item_type:'correction',skill_code:'P1-CIR-01',
      status:'in_progress',weekly_commitment_complete:false,correction_open:true,finalized_sessions:5,
      action_priority_order:1,retest_due_at:null,plan_changed:false},
    {goal_id:'g-coo',component_code:'P1',priority_order:2,item_type:'learning',skill_code:'P1-COO-02',
      status:'paused',weekly_commitment_complete:false,correction_open:false,finalized_sessions:0,
      action_priority_order:null,retest_due_at:null,plan_changed:true},
    {goal_id:'g-tri',component_code:'P1',priority_order:3,item_type:'learning',skill_code:'P1-TRI-01',
      status:'not_started',weekly_commitment_complete:false,correction_open:false,finalized_sessions:0,
      action_priority_order:3,retest_due_at:null,plan_changed:false}
  ]
});
const P5 = () => ({
  contract_version:'progress_ux_v1',component_code:'P5',active_week_no:1,
  plan_available:false,completed_goals:0,finalized_study_sessions:0,
  open_corrections:0,confirmed_skills:0,coverage_pct:0,goals:[]
});
const baseHtml = '<!doctype html><html lang="ru"><head><meta name="viewport" content="width=device-width, initial-scale=1"></head><body><div id="exam-prep-host-root" aria-hidden="false"></div></body></html>';
const dashboard = `<section class="ep-host-shell ep-live"><div class="ep-live-dashboard-intro">Обзор</div><div class="ep-live-grid">
<article class="ep-live-component-card" data-ep-live-component="P1"><strong>Pure Mathematics 1</strong><div class="ep-live-actions"></div></article>
<article class="ep-live-component-card" data-ep-live-component="P5"><strong>Probability & Statistics 1</strong><div class="ep-live-actions"></div></article>
</div></section>`;
const plan = `<section class="ep-host-shell ep-live"><div class="ep-live-card"><div class="ep-live-head"><strong>P1 · Недельный план</strong></div>
<div class="ep-live-plan-item"><div><strong>Разобрать ошибку</strong></div><button data-ep-live-plan-item="1">Начать</button></div>
<div class="ep-live-plan-item"><div><strong>Изучить тему</strong></div><button data-ep-live-plan-item="3">Начать</button></div>
</div></section>`;
const completion = `<section class="ep-host-shell ep-live ep-flow-completion-screen"><h2>Занятие завершено</h2>
<div class="ep-flow-completion-card">Ответы сохранены</div>
<div class="ep-flow-next-card">Следующий шаг</div><button data-ep-live-dashboard>К подготовке</button></section>`;

(async () => {
  const browser = await chromium.launch({headless:true});
  try {
    const off = await browser.newPage();
    await off.setContent(baseHtml.replace('</body>',dashboard+'</body>'));
    await off.evaluate(() => { window.iClubExamPrepProgressUxEnabled = false; });
    await off.addScriptTag({path:path.resolve('exam-prep/exam-prep-progress-ux-model.js')});
    await off.addScriptTag({path:path.resolve('exam-prep/exam-prep-progress-ux-ui.js')});
    assert.equal(await off.locator('.ep-pux-panel').count(),0,'Default OFF must not change application');
    await off.close();

    const page = await browser.newPage({viewport:{width:390,height:844}});
    const errors = [];
    page.on('pageerror',error=>errors.push(error.message));
    await page.setContent(baseHtml);
    await page.evaluate(({dashboard}) => {
      window.iClubExamPrepProgressUxEnabled = true;
      window.iClubExamPrepHostInternal = {
        lastCapabilities:{coreAccess:true,killSwitch:false,rolloutState:'controlled_beta'},
        progressUxApi:{progress:async component=>({ok:true,data:JSON.parse(JSON.stringify(window.__fixture[component]))})},
        api:{syllabusTracker:async()=>({ok:true,data:{areas:[
          {official_syllabus_section:'1.4 Circular measure',skills:[{skill_code:'P1-CIR-01',description:'Радианная мера'}]},
          {official_syllabus_section:'1.3 Coordinate geometry',skills:[{skill_code:'P1-COO-02',description:'Координатная геометрия'}]},
          {official_syllabus_section:'1.5 Trigonometry',skills:[{skill_code:'P1-TRI-01',description:'Тригонометрия'}]}
        ]}})}
      };
      window.__fixture={P1:null,P5:null};
      document.querySelector('#exam-prep-host-root').innerHTML=dashboard;
    },{dashboard});
    await page.evaluate(fixtures=>{window.__fixture=fixtures;},{P1:P1(),P5:P5()});
    await page.addScriptTag({path:path.resolve('exam-prep/exam-prep-progress-ux-model.js')});
    await page.addStyleTag({path:path.resolve('exam-prep/exam-prep-progress-ux.css')});
    await page.addScriptTag({path:path.resolve('exam-prep/exam-prep-progress-ux-ui.js')});
    await page.waitForFunction(()=>document.querySelectorAll('.ep-pux-overview').length===2);
    assert.match(await page.locator('[data-ep-live-component="P1"] .ep-pux-overview').innerText(),/5/);
    assert.doesNotMatch(await page.locator('[data-ep-live-component="P5"] .ep-pux-overview').innerText(),/0 из 3/,'No plan cannot invent progress denominator');
    assert.equal(await page.locator('.ep-pux-panel').count(),2);
    await page.evaluate(html=>document.querySelector('#exam-prep-host-root').innerHTML=html,plan);
    await page.waitForSelector('.ep-pux-week .ep-pux-goal');
    assert.equal(await page.locator('.ep-pux-goal').count(),3,'Frozen original goals must remain three');
    assert.match(await page.locator('.ep-pux-week').innerText(),/0 из 3/);
    assert.match(await page.locator('.ep-pux-week').innerText(),/Координатная геометрия/);
    assert.match(await page.locator('.ep-pux-week').innerText(),/изменил/i);
    assert.equal(await page.locator('[data-ep-live-plan-item]').count(),2,'Existing actionable buttons must be preserved');

    await page.evaluate(() => window.dispatchEvent(new CustomEvent('iclub:exam-prep-session',{
      detail:{session:{session_id:'session-1',session_type:'learning',component_code:'P1'}}
    })));
    await page.click('[data-ep-live-plan-item="1"]');
    await page.evaluate(html=>{
      const fixture=window.__fixture.P1;
      fixture.finalized_study_sessions=6;
      fixture.completed_goals=1;
      fixture.goals[0].weekly_commitment_complete=true;
      fixture.goals[0].status='waiting_retest';
      fixture.goals[0].finalized_sessions=6;
      fixture.goals[0].retest_due_at='2026-09-20T08:00:00Z';
      window.dispatchEvent(new CustomEvent('iclub:exam-prep-session-ended',{detail:{sessionId:'session-1'}}));
      document.querySelector('#exam-prep-host-root').innerHTML=html;
    },completion);
    await page.waitForSelector('.ep-pux-finish');
    const finished=await page.locator('.ep-pux-finish').innerText();
    assert.match(finished,/\+1/,'Completion should show verified delta from previous plan view');
    assert.match(finished,/1 из 3/,'Finished goal should remain part of stable denominator');
    assert.match(finished,/3/,'Open corrections should remain visible');
    assert.equal(await page.locator('.ep-flow-completion-card').count(),1,'Original completion screen preserved');

    await page.evaluate(html=>document.querySelector('#exam-prep-host-root').innerHTML=html,plan);
    await page.waitForSelector('.ep-pux-week .ep-pux-goal');
    assert.match(await page.locator('.ep-pux-week').innerText(),/20 сентября 2026/);
    const width=await page.evaluate(()=>document.documentElement.scrollWidth <= document.documentElement.clientWidth);
    assert.equal(width,true,'Mobile layout must not overflow');
    await page.evaluate(()=>{
      const root=document.querySelector('#exam-prep-host-root');
      root.hidden=true; root.setAttribute('aria-hidden','true');
      root.appendChild(document.createElement('span'));
    });
    await page.waitForTimeout(140);
    assert.equal(await page.locator('.ep-pux-panel').count(),0,'Hidden module must not retain extra progress panel');
    assert.deepEqual(errors,[],'No JS uncaught errors');
    await page.close();
    console.log('Progress UX isolated browser: PASS (OFF, P1/P5, stable goals, replan, completion, retest, 390px, close)');
  } finally { await browser.close(); }
})().catch(error=>{console.error(error);process.exit(1);});
