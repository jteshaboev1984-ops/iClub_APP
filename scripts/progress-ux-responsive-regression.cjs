'use strict';
const assert = require('node:assert/strict');
const path = require('node:path');
const { chromium } = require('playwright');

const fixture={
  contract_version:'progress_ux_v1',component_code:'P1',active_week_no:1,
  plan_available:true,completed_goals:1,finalized_study_sessions:12,
  open_corrections:3,confirmed_skills:7,coverage_pct:18,
  goals:[
    {goal_id:'g1',component_code:'P1',priority_order:1,item_type:'correction',skill_code:'P1-CIR-01',status:'waiting_retest',weekly_commitment_complete:true,correction_open:true,finalized_sessions:6,action_priority_order:1,retest_due_at:'2026-09-20T08:00:00Z',plan_changed:false},
    {goal_id:'g2',component_code:'P1',priority_order:2,item_type:'learning',skill_code:'P1-COO-02',status:'in_progress',weekly_commitment_complete:false,correction_open:false,finalized_sessions:2,action_priority_order:2,retest_due_at:null,plan_changed:false},
    {goal_id:'g3',component_code:'P1',priority_order:3,item_type:'learning',skill_code:'P1-TRI-01',status:'not_started',weekly_commitment_complete:false,correction_open:false,finalized_sessions:0,action_priority_order:3,retest_due_at:null,plan_changed:false}
  ]
};
const html=`<!doctype html><html lang="uz"><head><meta name="viewport" content="width=device-width,initial-scale=1"></head><body>
<div id="exam-prep-host-root" aria-hidden="false"><section class="ep-host-shell ep-live"><div class="ep-live-card">
<div class="ep-live-head"><strong>P1 · Haftalik reja</strong></div>
<div class="ep-live-plan-item"><button data-ep-live-plan-item="1">Davom etish</button></div>
<div class="ep-live-plan-item"><button data-ep-live-plan-item="2">Davom etish</button></div>
<div class="ep-live-plan-item"><button data-ep-live-plan-item="3">Boshlash</button></div>
</div></section></div></body></html>`;

(async()=>{
  const browser=await chromium.launch({headless:true});
  try{
    for(const width of [320,390,768,1440]){
      const page=await browser.newPage({viewport:{width,height:900}});
      const errors=[]; page.on('pageerror',e=>errors.push(e.message));
      await page.setContent(html);
      await page.evaluate(f=>{
        window.iClubExamPrepProgressUxEnabled=true;
        window.iClubExamPrepHostInternal={
          lastCapabilities:{coreAccess:true,killSwitch:false,rolloutState:'controlled_beta'},
          progressUxApi:{progress:async()=>({ok:true,data:structuredClone(f)})},
          api:{syllabusTracker:async()=>({ok:true,data:{areas:[
            {official_syllabus_section:'1.4 Circular measure',skills:[{skill_code:'P1-CIR-01',description:'Aylana o‘lchovi bo‘yicha xatoni mustahkamlash va keyingi tekshiruvga tayyorlanish'}]},
            {official_syllabus_section:'1.3 Coordinate geometry',skills:[{skill_code:'P1-COO-02',description:'Koordinata geometriyasida uzunroq tushuntirishli o‘quv maqsadi'}]},
            {official_syllabus_section:'1.5 Trigonometry',skills:[{skill_code:'P1-TRI-01',description:'Trigonometriya'}]}
          ]}})}
        };
      },fixture);
      await page.addScriptTag({path:path.resolve('exam-prep/exam-prep-progress-ux-model.js')});
      await page.addStyleTag({path:path.resolve('exam-prep/exam-prep-progress-ux.css')});
      await page.addScriptTag({path:path.resolve('exam-prep/exam-prep-progress-ux-ui.js')});
      await page.waitForSelector('.ep-pux-week');
      const fits=await page.evaluate(()=>document.documentElement.scrollWidth<=document.documentElement.clientWidth);
      assert.equal(fits,true,`${width}px must not horizontally overflow`);
      const boxes=await page.locator('.ep-pux-panel').evaluateAll(nodes=>nodes.map(n=>({w:n.getBoundingClientRect().width,left:n.getBoundingClientRect().left,right:n.getBoundingClientRect().right})));
      assert.ok(boxes.every(b=>b.w>0 && b.left>=-0.5 && b.right<=window.innerWidth+0.5),`${width}px panels must stay within viewport`);
      assert.deepEqual(errors,[],`${width}px must have no uncaught errors`);
      await page.close();
    }
    console.log('Progress UX responsive layout: PASS (320, 390, 768, 1440; long Uzbek copy; no horizontal overflow)');
  }finally{await browser.close();}
})().catch(e=>{console.error(e);process.exit(1);});
