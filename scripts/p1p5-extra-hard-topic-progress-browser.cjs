#!/usr/bin/env node
'use strict';
// Synthetic-only Mathematics Extra Hard UI. No protected bank, no live DB.
const assert=require('node:assert/strict');
const path=require('node:path');
const {chromium}=require('playwright');
assert(process.env.CI==='true'&&process.env.P1P5_E2E_ISOLATED==='true',
 'REFUSED: disposable UI regression only');
(async()=>{
 const browser=await chromium.launch({headless:true,args:['--no-sandbox']});
 try {
  for(const language of ['en','ru','uz'])for(const width of [390,1280]){
   const page=await browser.newPage({viewport:{width,height:760}});
   await page.setContent('<div id="exam-prep-host-root"></div>');
   await page.addStyleTag({path:path.resolve('exam-prep/exam-prep-host.css')});
   await page.evaluate(()=>{
    const items=[
     {task_key:'CI-A',title:'Synthetic trigonometry',official_section:'1.5 Trigonometry',attempt_status:'submitted'},
     {task_key:'CI-B',title:'Synthetic integration',official_section:'1.8 Integration',attempt_status:'started'},
     {task_key:'CI-C',title:'Synthetic integral',official_section:'1.8 Integration',attempt_status:'not_started'}
    ];
    window.__extraHardSubmitted=false;
    window.__extraHardSubmits=0;
    window.__extraHardComponent="P1";
    window.iClubExamPrepHostInternal={api:{
      extraHardCatalog:async(component)=>({ok:true,data:{component_code:component,available:true,noncredit:true,
        items:items.map(x=>({...x,attempt_status:window.__extraHardSubmitted&&x.task_key==='CI-B'?'submitted':x.attempt_status}))}}),
      extraHardStart:async(task_key)=>({ok:true,data:{attempt_id:'ci-only',component_code:window.__extraHardComponent,
        prompt:'Synthetic 1 + 1? Task '+task_key,title:task_key,noncredit:true,status:'started',solution:null}}),
      extraHardSubmit:async(attemptId,response_text)=>{
        window.__extraHardSubmits++;
        return {ok:true,data:{attempt_id:attemptId,saved:true,
          response_text,solution:'Synthetic model: 1 + 1 = 2.',noncredit:true}};
      }
    }};
   });
   await page.addScriptTag({path:path.resolve('exam-prep/exam-prep-extra-hard-ui.js')});
   assert(await page.evaluate(lang=>window.iClubExamPrepHostInternal.extraHardView.open('P1',lang,()=>{}),language));
   await page.waitForSelector('[data-ep-extra-hard-list]');
   assert.equal(await page.locator('.ep-extra-topic').count(),2);
   assert.equal(await page.locator('[data-ep-extra-hard-task]').count(),3);
   const progress=await page.locator('.ep-extra-progress').innerText();
   assert(progress.includes('1 / 3'));
   assert(progress.includes(language==='ru'?'Отправлено':language==='uz'?'Yuborilgan':'Submitted'));
   assert((await page.locator('.ep-extra-topic[open] summary').innerText()).includes('1.8'));
   assert((await page.evaluate(()=>document.documentElement.scrollWidth))<=width+2,'Horizontal overflow');
   await page.locator('[data-ep-extra-hard-task="CI-B"]').click();
   await page.waitForSelector('[data-ep-extra-hard-next]');
   assert(!(await page.locator('#exam-prep-host-root').innerText()).includes('Synthetic model: 1 + 1 = 2.'));
   const criteria=page.locator('[data-ep-extra-hard-criteria]');
   assert.equal(await criteria.count(),1,'Optional task checking points missing');
   assert(!await criteria.evaluate(el=>el.open),'Criteria must start closed');
   // P4-08: Next without viewing criteria, typing or submitting is legal.
   await page.locator('[data-ep-extra-hard-next]').click();
   await page.waitForFunction(()=>document.querySelector('.ep-live-qtext')?.textContent?.includes('CI-C'));
   assert.equal(await page.evaluate(()=>window.__extraHardSubmits),0,'Next submitted an answer');
   assert.equal(await page.locator('[data-ep-extra-hard-criteria]').evaluate(el=>el.open),false,
     'Next opened criteria without consent');
   await page.locator('[data-ep-extra-hard-next]').click();
   await page.waitForSelector('[data-ep-extra-hard-list]');
   assert((await page.locator('.ep-extra-progress').innerText()).includes('1 / 3'),
     'Navigation without writing fabricated completion');
   // Criteria are optional, local and answer-free; typed comparison stays optional.
   await page.locator('[data-ep-extra-hard-task="CI-B"]').click();
   await page.waitForSelector('[data-ep-extra-hard-criteria]');
   await page.locator('[data-ep-extra-hard-criteria] summary').click();
   assert(await page.locator('[data-ep-extra-hard-criteria]').evaluate(el=>el.open));
   assert(!(await page.locator('#exam-prep-host-root').innerText()).includes('Synthetic model: 1 + 1 = 2.'));
   await page.locator('[data-ep-extra-hard-criteria] summary').click();
   assert(!await page.locator('[data-ep-extra-hard-criteria]').evaluate(el=>el.open));
   await page.locator('[data-ep-extra-hard-optional-input] summary').click();
   await page.locator('[name="ep_extra_hard_answer"]').fill('My own solution');
   await page.locator('[data-ep-extra-hard-submit]').click();
   await page.waitForSelector('[data-ep-extra-hard-other]');
   assert((await page.locator('#exam-prep-host-root').innerText()).includes('Synthetic model: 1 + 1 = 2.'));
   assert.equal(await page.evaluate(()=>window.__extraHardSubmits),1,
     'Optional typed solution not saved exactly once');
   await page.evaluate(()=>window.__extraHardSubmitted=true);
   await page.locator('[data-ep-extra-hard-other]').click();
   await page.waitForSelector('[data-ep-extra-hard-list]');
   assert((await page.locator('.ep-extra-progress').innerText()).includes('2 / 3'));
   // The P5 official syllabus has a shared 5.4 prefix: protect the two
   // independent iClub challenge tracks (geometric vs binomial).
   await page.evaluate(()=>{
     const p5=[
       {task_key:"CI-P5-GEO",title:"Synthetic geometric",official_section:"5.4 Discrete random variables",
         primary_skill_code:"P5-GEO-01",attempt_status:"not_started"},
       {task_key:"CI-P5-BIN",title:"Synthetic binomial",official_section:"5.4 Discrete random variables",
         primary_skill_code:"P5-BIN-02",attempt_status:"submitted"}
     ];
     window.__extraHardComponent="P5";
     window.iClubExamPrepHostInternal.api.extraHardCatalog=async()=>({
       ok:true,data:{component_code:"P5",available:true,noncredit:true,items:p5}
     });
   });
   assert(await page.evaluate(lang=>window.iClubExamPrepHostInternal.extraHardView.open('P5',lang,()=>{}),language));
   await page.waitForSelector('[data-ep-extra-hard-list]');
   assert.equal(await page.locator('.ep-extra-topic').count(),2,
     "P5 geometric and binomial must stay separate within syllabus 5.4");
   const heading=await page.locator('.ep-extra-topic summary').allInnerTexts();
   assert(heading.some(x=>x.includes(language==="ru"?"Геометрическое":language==="uz"?"Geometrik":"Geometric")));
   assert(heading.some(x=>x.includes(language==="ru"?"Биномиальное":language==="uz"?"Binomial":"Binomial")));
   assert((await page.evaluate(()=>document.documentElement.scrollWidth))<=width+2,
     "P5 grouping must not overflow mobile screen");
   await page.locator('[data-ep-extra-hard-task="CI-P5-GEO"]').click();
   await page.waitForSelector('[data-ep-extra-hard-next]');
   assert.equal(await page.locator('[data-ep-extra-hard-criteria]').evaluate(el=>el.open),false);
   await page.locator('[data-ep-extra-hard-next]').click();
   await page.waitForFunction(()=>document.querySelector('.ep-live-qtext')?.textContent?.includes('CI-P5-BIN'));
   assert.equal(await page.evaluate(()=>window.__extraHardSubmits),1,
     'P5 paper-first Next submitted an answer or changed verified marks');
   assert((await page.evaluate(()=>document.documentElement.scrollWidth))<=width+2,
     "P5 question/card must not overflow mobile screen");
   await page.close();
  }
  console.log('EXTRA HARD TOPIC PROGRESS BROWSER PASS: EN RU UZ, 390/1280, P1/P5 optional criteria+untyped Next, zero fake marks, optional save, geometric/binomial topics');
 } finally{await browser.close();}
})().catch(e=>{console.error('EXTRA HARD TOPIC PROGRESS FAILED:',e.message);process.exitCode=1});
