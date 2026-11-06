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
    window.iClubExamPrepHostInternal={api:{
      extraHardCatalog:async(component)=>({ok:true,data:{component_code:component,available:true,noncredit:true,
        items:items.map(x=>({...x,attempt_status:window.__extraHardSubmitted&&x.task_key==='CI-B'?'submitted':x.attempt_status}))}}),
      extraHardStart:async(task_key)=>({ok:true,data:{attempt_id:'ci-only',component_code:'P1',
        prompt:'Synthetic 1 + 1?',title:task_key,noncredit:true,status:'started',solution:null}}),
      extraHardSubmit:async(attemptId,response_text)=>({ok:true,data:{attempt_id:attemptId,saved:true,
        response_text,solution:'Synthetic model: 1 + 1 = 2.',noncredit:true}})
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
   await page.waitForSelector('[name="ep_extra_hard_answer"]');
   assert(!(await page.locator('#exam-prep-host-root').innerText()).includes('Synthetic model: 1 + 1 = 2.'));
   await page.locator('[name="ep_extra_hard_answer"]').fill('My own solution');
   await page.locator('[data-ep-extra-hard-submit]').click();
   await page.waitForSelector('[data-ep-extra-hard-other]');
   assert((await page.locator('#exam-prep-host-root').innerText()).includes('Synthetic model: 1 + 1 = 2.'));
   await page.evaluate(()=>window.__extraHardSubmitted=true);
   await page.locator('[data-ep-extra-hard-other]').click();
   await page.waitForSelector('[data-ep-extra-hard-list]');
   assert((await page.locator('.ep-extra-progress').innerText()).includes('2 / 3'));
   await page.close();
  }
  console.log('EXTRA HARD TOPIC PROGRESS BROWSER PASS: EN RU UZ, 390/1280, grouping and owner progress');
 } finally{await browser.close();}
})().catch(e=>{console.error('EXTRA HARD TOPIC PROGRESS FAILED:',e.message);process.exitCode=1});
