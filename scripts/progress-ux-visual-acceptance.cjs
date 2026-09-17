'use strict';
// Isolated visual evidence only. Synthetic values; no production requests or student data.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { chromium } = require('playwright');

const output = path.resolve('progress-ux-visual-evidence');
fs.mkdirSync(output, { recursive: true });
const COPY = {
  ru: { overview:'Обзор подготовки', plan:'Недельный план', start:'Начать', next:'Следующее задание', p1:'Pure Mathematics 1', p5:'Probability & Statistics 1', empty:'Недельный план пока не составлен.' },
  uz: { overview:'Tayyorgarlik holati', plan:'Haftalik reja', start:'Boshlash', next:'Keyingi topshiriq', p1:'Pure Mathematics 1', p5:'Probability & Statistics 1', empty:'Haftalik reja hali tuzilmagan.' },
  en: { overview:'Preparation overview', plan:'Weekly plan', start:'Start', next:'Next task', p1:'Pure Mathematics 1', p5:'Probability & Statistics 1', empty:'Your weekly plan has not been created yet.' }
};
const one = () => ({
  contract_version:'progress_ux_v1', component_code:'P1', active_week_no:1,
  plan_available:true, completed_goals:1, finalized_study_sessions:12,
  open_corrections:3, confirmed_skills:7, coverage_pct:18,
  goals:[
    { goal_id:'synthetic-1',component_code:'P1',priority_order:1,item_type:'correction',skill_code:'P1-CIR-01',status:'waiting_retest',weekly_commitment_complete:true,correction_open:true,finalized_sessions:6,action_priority_order:1,retest_due_at:'2026-09-20T08:00:00Z',plan_changed:false },
    { goal_id:'synthetic-2',component_code:'P1',priority_order:2,item_type:'learning',skill_code:'P1-COO-02',status:'in_progress',weekly_commitment_complete:false,correction_open:false,finalized_sessions:2,action_priority_order:2,retest_due_at:null,plan_changed:false },
    { goal_id:'synthetic-3',component_code:'P1',priority_order:3,item_type:'learning',skill_code:'P1-TRI-01',status:'not_started',weekly_commitment_complete:false,correction_open:false,finalized_sessions:0,action_priority_order:3,retest_due_at:null,plan_changed:false }
  ]
});
const five = () => ({ contract_version:'progress_ux_v1',component_code:'P5',active_week_no:1,plan_available:false,completed_goals:0,finalized_study_sessions:0,open_corrections:0,confirmed_skills:0,coverage_pct:0,goals:[] });
function markup(language, view) {
  const c = COPY[language];
  const dashboard = `<section class="ep-host-shell ep-live"><div class="ep-live-dashboard-intro"><h2>${c.overview}</h2></div><div class="ep-live-grid">
    <article class="ep-live-card ep-live-component-card" data-ep-live-component="P1"><div class="ep-live-component-head"><span class="ep-live-component-code">P1</span><div class="ep-live-component-copy"><strong>${c.p1}</strong></div></div><div class="ep-live-actions"><button class="ep-live-btn">${c.plan}</button></div></article>
    <article class="ep-live-card ep-live-component-card" data-ep-live-component="P5"><div class="ep-live-component-head"><span class="ep-live-component-code">P5</span><div class="ep-live-component-copy"><strong>${c.p5}</strong></div></div><div class="ep-live-actions"><button class="ep-live-btn">${c.plan}</button></div></article>
    </div></section>`;
  const plan = `<section class="ep-host-shell ep-live"><div class="ep-live-card"><div class="ep-live-head"><strong>P1 · ${c.plan}</strong><button class="ep-live-btn secondary" type="button">${c.overview}</button></div>
    <div class="ep-live-plan-item"><div><strong>${c.next} 1</strong></div><button class="ep-live-btn" type="button" data-ep-live-plan-item="1">${c.start}</button></div>
    <div class="ep-live-plan-item"><div><strong>${c.next} 2</strong></div><button class="ep-live-btn" type="button" data-ep-live-plan-item="2">${c.start}</button></div>
    <div class="ep-live-plan-item"><div><strong>${c.next} 3</strong></div><button class="ep-live-btn" type="button" data-ep-live-plan-item="3">${c.start}</button></div>
    </div></section>`;
  return `<!doctype html><html lang="${language}"><head><meta name="viewport" content="width=device-width, initial-scale=1"></head><body class="iclub-visual-v3"><main id="courses-subject-hub" class="exam-prep-host-open"><div id="exam-prep-host-root" class="exam-prep-host-root" aria-hidden="false">${view==='overview'?dashboard:plan}</div></main></body></html>`;
}
(async () => {
  const browser = await chromium.launch({ headless:true });
  try {
    for (const language of Object.keys(COPY)) {
      for (const width of [390,1440]) {
        for (const view of ['overview','plan']) {
          const page = await browser.newPage({ viewport:{ width,height:900 },deviceScaleFactor:1 });
          const errors=[];
          page.on('pageerror',error=>errors.push(error.message));
          await page.setContent(markup(language,view));
          for (const css of ['style.css','visual/iclub-visual-v3.css','visual/iclub-premium-v3.css','exam-prep/exam-prep-host.css','exam-prep/exam-prep-wave1-ux.css','exam-prep/exam-prep-progress-ux.css']) {
            await page.addStyleTag({path:path.resolve(css)});
          }
          await page.evaluate(({p1,p5})=>{
            window.iClubExamPrepProgressUxEnabled=true;
            window.iClubExamPrepHostInternal={
              lastCapabilities:{coreAccess:true,killSwitch:false,rolloutState:'controlled_beta'},
              progressUxApi:{progress:async component=>({ok:true,data:structuredClone(component==='P1'?p1:p5)})},
              api:{syllabusTracker:async()=>({ok:true,data:{areas:[
                {official_syllabus_section:'1.4 Circular measure',skills:[{skill_code:'P1-CIR-01',description:'Circular measure'}]},
                {official_syllabus_section:'1.3 Coordinate geometry',skills:[{skill_code:'P1-COO-02',description:'Coordinate geometry'}]},
                {official_syllabus_section:'1.5 Trigonometry',skills:[{skill_code:'P1-TRI-01',description:'Trigonometry'}]}
              ]}})}
            };
          },{p1:one(),p5:five()});
          await page.addScriptTag({path:path.resolve('exam-prep/exam-prep-progress-ux-model.js')});
          await page.addScriptTag({path:path.resolve('exam-prep/exam-prep-progress-ux-ui.js')});
          if(view==='overview') {
            await page.waitForFunction(()=>document.querySelectorAll('.ep-pux-overview').length===2);
            const p1Text=await page.locator('[data-ep-live-component="P1"] .ep-pux-overview').innerText();
            const p5Text=await page.locator('[data-ep-live-component="P5"] .ep-pux-overview').innerText();
            assert.ok(p1Text.includes('7 / 45'),`${language}: confirmed skills must be explicit`);
            assert.ok(p1Text.includes('18%'),`${language}: verified coverage must be explicit`);
            assert.ok(p5Text.includes(COPY[language].empty),`${language}: absent P5 plan cannot be invented`);
            assert.ok(!p5Text.includes('0 из 3')&&!p5Text.includes('0 of 3'),`${language}: no false denominator`);
          } else {
            await page.waitForFunction(()=>document.querySelectorAll('.ep-pux-goal').length===3);
            assert.equal(await page.locator('[data-ep-live-plan-item]').count(),3,'Existing actions must survive');
            assert.ok((await page.locator('.ep-pux-week').innerText()).includes('12')===false,'Goals cannot present global session total as goal completion');
          }
          assert.equal(await page.evaluate(()=>document.documentElement.scrollWidth<=document.documentElement.clientWidth),true,`${language} ${width}px ${view}: horizontal overflow`);
          assert.deepEqual(errors,[],`${language} ${width}px ${view}: no browser errors`);
          await page.locator('#exam-prep-host-root').screenshot({path:path.join(output,`${language}-${width}-${view}.png`),animations:'disabled'});
          await page.close();
        }
      }
    }
    console.log('Progress UX visual acceptance: PASS (12 synthetic RU/UZ/EN captures, 390/1440px, original app CSS, no overflow)');
  } finally { await browser.close(); }
})().catch(error=>{console.error(error);process.exit(1);});