'use strict';
// Real application renderers and styles; isolated synthetic data only, no network or production access.
const assert = require('node:assert/strict');
const path = require('node:path');
const { chromium } = require('playwright');

const repo = relative => path.resolve(relative);
const descriptions = Object.freeze({
  'P1-CIR-01': 'Переводить degrees ↔ radians и использовать radians как естественную угловую меру.',
  'P1-COO-02': 'Использовать формы уравнения прямой, distance, midpoint, gradient и intersection.',
  'P1-TRI-01': 'Строить и использовать graphs of sin, cos и tan, включая simple transformations.',
  'P5-DAT-01': 'Выбирать и критиковать подходящее data representation с учётом типа данных и цели.'
});
function progress(component) {
  const p1 = component === 'P1';
  const codes = p1 ? ['P1-CIR-01', 'P1-COO-02', 'P1-TRI-01'] : ['P5-DAT-01'];
  return {
    contract_version:'progress_ux_v1', component_code:component, active_week_no:1,
    plan_available:true, completed_goals:p1 ? 1 : 0,
    finalized_study_sessions:p1 ? 6 : 2, open_corrections:p1 ? 1 : 0,
    confirmed_skills:p1 ? 7 : 2, coverage_pct:p1 ? 18 : 6,
    goals:codes.map((code,index)=>({
      goal_id:`synthetic-${component}-${index+1}`,component_code:component,
      priority_order:index+1,item_type:p1 && index===0 ? 'correction':'learning',
      skill_code:code,status:p1 && index===0 ? 'waiting_retest' : p1 && index===2 ? 'paused':'in_progress',
      weekly_commitment_complete:p1 && index===0,correction_open:p1 && index===0,
      finalized_sessions:p1 ? [5,1,0][index] : 2,
      action_priority_order:p1 && index===2 ? null : index+1,
      retest_due_at:p1 && index===0 ? '2026-09-20T08:00:00Z' : null,
      plan_changed:p1 && index===2
    }))
  };
}
const initialPlans = () => ({
  P1:{plan_id:'synthetic-plan-p1-v2',active_week_no:1,items:[
    {priority_order:1,item_type:'correction',skill_code:'P1-CIR-01',status:'pending',due_at:null},
    {priority_order:2,item_type:'learning',skill_code:'P1-COO-02',status:'pending',due_at:null}
  ]},
  P5:{plan_id:'synthetic-plan-p5-v1',active_week_no:1,items:[
    {priority_order:1,item_type:'learning',skill_code:'P5-DAT-01',status:'pending',due_at:null}
  ]}
});
const html = language => `<!doctype html><html lang="${language}"><head><meta name="viewport" content="width=device-width,initial-scale=1"></head><body class="iclub-visual-v3"><main id="courses-subject-hub" class="exam-prep-host-open"><div id="exam-prep-host-root" class="exam-prep-host-root" aria-hidden="false"></div></main></body></html>`;

(async () => {
  const browser = await chromium.launch({headless:true});
  try {
    for (const language of ['ru','uz','en']) for (const width of [390,1440]) {
      const page = await browser.newPage({viewport:{width,height:900}});
      const errors=[];
      page.on('pageerror',err=>errors.push(err.message));
      await page.setContent(html(language));
      for (const css of ['style.css','visual/iclub-visual-v3.css','visual/iclub-premium-v3.css',
        'exam-prep/exam-prep-host.css','exam-prep/exam-prep-wave1-ux.css','exam-prep/exam-prep-progress-ux.css'])
        await page.addStyleTag({path:repo(css)});
      await page.evaluate(({language,descriptions,plans,p1,p5}) => {
        window.iClubExamPrepProgressUxEnabled=true;
        window.i18n={getLang:()=>language};
        window.__plans=plans;
        window.__authorizations=[];
        const tracker = component => ({component_code:component,areas:(component==='P1'
          ? [['1.4 Circular measure','P1-CIR-01'],['1.3 Coordinate geometry','P1-COO-02'],['1.5 Trigonometry','P1-TRI-01']]
          : [['5.1 Representation of data','P5-DAT-01']]).map(([section,code])=>({
            official_syllabus_section:section,skills:[{skill_code:code,description:descriptions[code]}]
          }))});
        window.iClubExamPrepHostInternal={
          lastCapabilities:{coreAccess:true,killSwitch:false,rolloutState:'controlled_beta'},
          api:{
            examProfile:async()=>({ok:true,data:{exam_series:'May/June 2027',target_grade:'A',
              total_student_hours_available:12,mathematics_hours_budget:6}}),
            diagnosticProgress:async()=>({ok:true,data:{stage0_complete:true,
              screening:{required_items:2,answered_items:2,required_areas:1,answered_areas:1}}}),
            getState:async component=>({ok:true,data:{components:[{component_code:component,
              operational_stage:2,coverage_pct:component==='P1'?18:6}]}}),
            weeklyPlan:async component=>({ok:true,data:structuredClone(window.__plans[component])}),
            syllabusTracker:async component=>({ok:true,data:tracker(component)}),
            authorizePlanItem:async(planId,order)=>{
              window.__authorizations.push({planId,order});
              return {ok:false,reason:'synthetic_authorization_rejected'};
            }
          },
          progressUxApi:{progress:async component=>({ok:true,data:structuredClone(component==='P1'?p1:p5)})}
        };
        window.iClubExamPrep={open:async()=>true,back:()=>true,close:()=>true,
          isOpen:()=>true,syncSubjectHub:async()=>true,refreshCapabilities:async()=>true};
      },{language,descriptions,plans:initialPlans(),p1:progress('P1'),p5:progress('P5')});
      await page.addScriptTag({path:repo('exam-prep/exam-prep-live.js')});
      await page.addScriptTag({path:repo('exam-prep/exam-prep-progress-ux-model.js')});
      await page.addScriptTag({path:repo('exam-prep/exam-prep-progress-ux-ui.js')});
      await page.evaluate(language=>window.iClubExamPrep.open({language}),language);
      await page.waitForFunction(()=>document.querySelectorAll('[data-ep-live-open-component]').length===2);
      assert.equal(await page.locator('.ep-live-component-card').count(),2,`${language}: P1/P5 route cards`);
      assert.equal(await page.locator('.ep-pux-overview').count(),0,`${language}: route overview must stay compact and read-only`);
      assert.equal(await page.locator('[data-ep-live-open-component="P1"]').count(),1,`${language}: P1 route exists`);
      assert.equal(await page.locator('[data-ep-live-open-component="P5"]').count(),1,`${language}: P5 route exists`);
      await page.evaluate(()=>document.querySelector('[data-ep-live-plan="P1"]').click());
      await page.waitForFunction(()=>document.querySelectorAll('.ep-pux-goal').length===3);
      assert.equal(await page.locator('.ep-pux-week').count(),1,`${language}: only one progress plan`);
      assert.equal(await page.locator('[data-ep-live-plan-item]').count(),2,`${language}: keep original two actionable tasks`);
      assert.equal(await page.locator('.ep-pux-goal').count(),3,`${language}: preserve three frozen goals`);
      const firstGoal=await page.locator('.ep-pux-goal-title').first().innerText();
      if(language==='ru') assert.ok(firstGoal.includes(descriptions['P1-CIR-01']), 'Actual canonical Russian skill description');
      if(language==='uz') assert.ok(firstGoal.includes('Radian o‘lchov va aylana'), 'Uzbek localized syllabus area');
      if(language==='en') assert.ok(firstGoal.includes('Circular measure'), 'English localized syllabus area');
      assert.equal(await page.evaluate(()=>document.documentElement.scrollWidth<=document.documentElement.clientWidth),true,
        `${language} ${width}: real app plan must fit viewport`);
      // Real live renderer emits only a notice when no plan items are available.
      // Frozen goals must remain visible even when all actions have disappeared.
      await page.evaluate(()=>{window.__plans.P1.items=[];});
      await page.click('[data-ep-live-dashboard]');
      await page.waitForFunction(()=>document.querySelectorAll('[data-ep-live-open-component]').length===2);
      assert.equal(await page.locator('.ep-pux-overview').count(),0,'Compact dashboard must not hydrate duplicate goal summaries');
      await page.evaluate(()=>document.querySelector('[data-ep-live-plan="P1"]').click());
      await page.waitForFunction(()=>document.querySelector('.ep-pux-week')?.querySelectorAll('.ep-pux-goal').length===3);
      assert.equal(await page.locator('[data-ep-live-plan-item]').count(),0,'No invented actionable buttons');
      assert.equal(await page.locator('.ep-pux-week').count(),1,'No-row plan must retain one progress summary');
      assert.ok((await page.locator('.ep-pux-week').innerText()).includes(
        language==='ru'?'Сейчас нет доступного шага':language==='uz'?'Hozircha mavjud qadam yo‘q':'No available step right now'));
      // Plan regeneration must use only the new existing planner binding.
      await page.click('[data-ep-live-dashboard]');
      await page.waitForFunction(()=>document.querySelectorAll('[data-ep-live-open-component]').length===2);
      assert.equal(await page.locator('.ep-pux-overview').count(),0,'Compact dashboard must stay free of duplicate Progress UX summaries');
      await page.evaluate(()=>{
        window.__plans.P1={plan_id:'synthetic-plan-p1-v3',active_week_no:1,items:[
          {priority_order:1,item_type:'learning',skill_code:'P1-COO-02',status:'pending',due_at:null}
        ]};
      });
      await page.evaluate(()=>document.querySelector('[data-ep-live-plan="P1"]').click());
      await page.waitForFunction(()=>document.querySelectorAll('.ep-pux-goal').length===3);
      await page.click('[data-ep-live-plan-item="1"]');
      await page.waitForFunction(()=>window.__authorizations.length===1);
      const auth=await page.evaluate(()=>window.__authorizations[0]);
      assert.deepEqual(auth,{planId:'synthetic-plan-p1-v3',order:1},'Use current authorized planner identity, never frozen source plan');
      await page.waitForSelector('.ep-live-error');
      assert.equal(await page.locator('.ep-pux-panel').count(),0,'Denied authorization must not leave stale progress UI');
      assert.deepEqual(errors,[],`${language} ${width}: no uncaught browser errors`);
      await page.close();
    }
    console.log('Progress UX actual renderer acceptance: PASS (RU/UZ/EN x mobile/desktop, P1/P5 isolation, canonical skills, empty plan, current authorization binding)');
  } finally { await browser.close(); }
})().catch(err=>{console.error(err);process.exit(1);});
