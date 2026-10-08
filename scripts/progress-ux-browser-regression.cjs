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
const tracker = `<section class="ep-host-shell ep-views-shell" data-ep-views-screen>
<div class="ep-views-summary">
  <div class="ep-views-stat"><span>Подтверждено</span><strong>7 / 45</strong></div>
  <div class="ep-views-stat"><span>Покрытие</span><strong>18%</strong></div>
  <div class="ep-views-stat"><span>Требуют внимания</span><strong>3</strong></div>
</div>
<button class="ep-views-skill" type="button" data-ep-views-skill="P1-CIR-01"><span><strong>Радианная мера</strong></span><span class="ep-views-badge">Формируется</span></button>
</section>`;
const completion = `<section class="ep-host-shell ep-live ep-flow-completion-screen"><h2>Занятие завершено</h2>
<div class="ep-flow-completion-card"><div class="ep-flow-completion-skill"><span>Навык</span><strong>Радианная мера</strong></div><p>Ответы сохранены</p></div>
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
      window.__skillLevel=1;
      window.__skillCorrection=null;
      window.iClubExamPrepHostInternal = {
        lastCapabilities:{coreAccess:true,killSwitch:false,rolloutState:'controlled_beta'},
        progressUxApi:{progress:async component=>({ok:true,data:JSON.parse(JSON.stringify(window.__fixture[component]))})},
        api:{syllabusTracker:async()=>({ok:true,data:{areas:[
          {official_syllabus_section:'1.4 Circular measure',skills:[{skill_code:'P1-CIR-01',description:'Радианная мера',objective_level:window.__skillLevel,correction_case_id:window.__skillCorrection}]},
          {official_syllabus_section:'1.3 Coordinate geometry',skills:[{skill_code:'P1-COO-02',description:'Координатная геометрия',objective_level:0,correction_case_id:null}]},
          {official_syllabus_section:'1.5 Trigonometry',skills:[{skill_code:'P1-TRI-01',description:'Тригонометрия',objective_level:0,correction_case_id:null}]}
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
    assert.match(await page.locator('[data-ep-live-component="P1"] .ep-pux-progress-hero').innerText(),/0 \/ 45/,'Dashboard must show confirmed-topic denominator, not answer percentage');

    await page.evaluate(html=>document.querySelector('#exam-prep-host-root').innerHTML=html,tracker);
    await page.waitForSelector('.ep-pux-tracker-hero');
    assert.match(await page.locator('.ep-pux-tracker-hero').innerText(),/7 \/ 45/,'Tracker must foreground confirmed topics');
    assert.equal(await page.locator('.ep-views-summary .ep-views-stat:first-child').isVisible(),false,'Duplicate confirmed count must be visually suppressed');
    await page.click('[data-ep-pux-guide-toggle]');
    const guideText=await page.locator('.ep-pux-guide').innerText();
    assert.match(guideText,/один правильный ответ/i,'Progress guide must explain answer-to-progress logic');
    for (const label of ['Не проверено','Формируется','Подтверждено','Уверенно','Требует внимания'])
      assert.match(guideText,new RegExp(label),'Progress guide status missing: '+label);

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
      fixture.confirmed_skills=1;
      fixture.coverage_pct=2;
      window.__skillLevel=2;
      fixture.goals[0].weekly_commitment_complete=true;
      fixture.goals[0].status='waiting_retest';
      fixture.goals[0].finalized_sessions=6;
      fixture.goals[0].retest_due_at='2026-09-20T08:00:00Z';
      window.dispatchEvent(new CustomEvent('iclub:exam-prep-session-ended',{detail:{sessionId:'session-1'}}));
      document.querySelector('#exam-prep-host-root').innerHTML=html;
    },completion);
    await page.waitForSelector('.ep-pux-finish');
    const finished=await page.locator('.ep-pux-finish').innerText();
    assert.match(finished,/Что изменилось/,'Completion must explain the consequence of the finished task');
    assert.match(finished,/Формируется/,'Completion must show previous topic state');
    assert.match(finished,/Подтверждено/,'Completion must show new topic state');
    assert.match(finished,/0 → 1 \/ 45/,'Completion must show confirmed-topic change without inventing answer-based percent progress');
    assert.doesNotMatch(finished,/Занятий добавлено|Дополнительно выполнено целей/,'Completion must not lead with internal session/goal counters');
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
