#!/usr/bin/env node
'use strict';
// Isolated live-source browser contract only. No real users, secrets, network,
// Supabase writes, topic answers, or automatic retries.
const assert=require('node:assert/strict');
const path=require('node:path');
const fs=require('node:fs');
const {chromium}=require('playwright');
const out=process.env.PRACTICE_TOPIC_DIAG_SCREEN_DIR||'';
if(out)fs.mkdirSync(out,{recursive:true});

(async()=>{
 const browser=await chromium.launch({headless:true,args:['--no-sandbox']});
 try {
  for(const language of ['ru','uz','en']){
   for(const width of [320,375,430,1440]){
    const page=await browser.newPage({viewport:{width,height:850}});
    try{
     await page.setContent('<!doctype html><html lang="'+language+'"><body class="iclub-visual-v3"><main id="courses-practice-start"><section id="practice-topic-choice"></section></main></body></html>');
     await page.addStyleTag({path:path.resolve('practice-topic-choice.css')});
     await page.addScriptTag({path:path.resolve('practice-topic-choice.js')});
     const mount=async()=>page.evaluate(lang=>{
       window.__launches=[];
       window.iClubPracticeTopicChoice.mount({
         subjectKey:'mathematics',language:lang,
         onStart:topic=>{window.__launches.push(topic);}
       });
     },language);
     const beforeMount=async()=>page.evaluate(()=>{
       window.__catalogCalls=0;
       window.__scenario='good';
       window.__rpc={rpc:async(name,args)=>{
         if(name==='get_practice_topic_history_safe_v1')
           return {data:{ok:true,subject_key:args.p_subject_key,
             completed_sessions:0,last:null,best:null,total_correct_answers:0,
             total_answered:0,recent:[]},error:null,status:200};
         window.__catalogCalls++;
         switch(window.__scenario){
          case 'auth':return {data:null,error:{code:'42501',message:'private raw info MUST NOT LEAK'},status:401};
          case 'route':return {data:null,error:{code:'PGRST202',message:'internal URL MUST NOT LEAK'},status:404};
          case 'wrong':return {data:{ok:true,subject_key:'economics',
             topics:[{topic:'Foreign subject',question_count:5}]},error:null,status:200};
          case 'shape':return {data:{ok:true,subject_key:args.p_subject_key,topics:{}},error:null,status:200};
          case 'throw':throw new Error('internal bearer token placeholder MUST NOT LEAK');
          default:return {data:{ok:true,subject_key:args.p_subject_key,topics:[
            {topic:'Synthetic algebra',question_count:3},
            {topic:'Synthetic geometry',question_count:4}]},error:null,status:200};
         }
       }};
     });
     await beforeMount();await mount();
     // Initial client-not-ready requires an explicit retry; must not create
     // anonymous auth or silently query in a loop.
     await page.locator('.practice-topic-choice-toggle').click();
     const code=page.locator('.practice-topic-choice-status');
     await page.waitForFunction(()=>document.querySelector('.practice-topic-choice-status')?.dataset.catalogFailure==='CLIENT_NOT_READY');
     assert.equal(await page.locator('.practice-topic-choice-item').count(),0);
     assert.equal(await page.evaluate(()=>window.__catalogCalls),0);
     assert((await code.innerText()).includes('CLIENT_NOT_READY'));
     await page.evaluate(()=>window.sb=window.__rpc);
     await page.locator('.practice-topic-choice-retry').click();
     await page.waitForFunction(()=>document.querySelectorAll('.practice-topic-choice-item').length===2);
     assert.equal(await code.getAttribute('data-catalog-failure'),null,'stale error marker retained after success');

     const scenarios=[
       ['auth','HTTP_401'],['route','HTTP_404'],
       ['wrong','SUBJECT_MISMATCH'],['shape','INVALID_RESPONSE'],
       ['throw','UNAVAILABLE']
     ];
     for(const [scenario,expected] of scenarios){
       await page.evaluate(s=>{window.__scenario=s;},scenario);
       await mount();
       await page.locator('.practice-topic-choice-toggle').click();
       await page.waitForFunction(expected=>document.querySelector('.practice-topic-choice-status')?.dataset.catalogFailure===expected,expected);
       assert.equal(await page.locator('.practice-topic-choice-item').count(),0,'failed catalog exposed a launch tile');
       assert((await code.innerText()).includes(expected),'missing safe support code '+expected);
       const display=await page.locator('#practice-topic-choice').innerText();
       for(const phrase of ['private raw info','internal URL','bearer token'])
         assert(!display.includes(phrase),'leaked raw RPC failure content');
       assert.equal((await page.evaluate(()=>window.__launches)).length,0,
         'failed catalog/retry started a Practice attempt');
       await page.evaluate(()=>window.__scenario='good');
       await page.locator('.practice-topic-choice-retry').click();
       await page.waitForFunction(()=>document.querySelectorAll('.practice-topic-choice-item').length===2);
       assert.equal(await code.getAttribute('data-catalog-failure'),null);
       assert.equal(await page.locator('.practice-topic-choice-retry').count(),0,
         'retry did not clear error action');
     }
     // Delayed old Mathematics RPC must not render its results in a new
     // Chemistry catalog after navigating to another subject.
     await page.evaluate(lang=>{
       window.__resolveOld=null;
       window.sb={rpc:(name,args)=>{
        if(name==='get_practice_topic_history_safe_v1')return Promise.resolve({
          data:{ok:true,subject_key:args.p_subject_key,
            completed_sessions:0,last:null,best:null,total_correct_answers:0,
            total_answered:0,recent:[]},error:null});
        if(args.p_subject_key==='mathematics')return new Promise(resolve=>{window.__resolveOld=resolve;});
        return Promise.resolve({data:{ok:true,subject_key:'chemistry',topics:[
          {topic:'Chemistry synthetic',question_count:2}]},error:null});
       }};
       window.iClubPracticeTopicChoice.mount({subjectKey:'mathematics',language:lang,
         onStart:topic=>{window.__launches.push(topic);}});
     },language);
     await page.locator('.practice-topic-choice-toggle').click();
     await page.waitForFunction(()=>typeof window.__resolveOld==='function');
     await page.evaluate(lang=>{
       window.iClubPracticeTopicChoice.mount({subjectKey:'chemistry',language:lang,
         onStart:topic=>{window.__launches.push(topic);}});
     },language);
     await page.locator('.practice-topic-choice-toggle').click();
     await page.waitForFunction(()=>document.querySelector('.practice-topic-choice-item')?.textContent.includes('Chemistry synthetic'));
     await page.evaluate(()=>window.__resolveOld({
       data:{ok:true,subject_key:'mathematics',topics:[
         {topic:'Stale math leaked',question_count:99}]},error:null,status:200
     }));
     await page.waitForTimeout(30);
     assert.equal(await page.locator('.practice-topic-choice-item').count(),1);
     assert(!(await page.locator('.practice-topic-choice-item').innerText()).includes('Stale math'));
     assert.equal((await page.evaluate(()=>window.__launches)).length,0);
     const overflow=await page.evaluate(()=>document.documentElement.scrollWidth-innerWidth);
     assert(overflow<=1,'overflow '+language+'/'+width+': '+overflow);
     if(out&&language==='ru'&&width===375){
       await page.screenshot({path:path.join(out,'practice-topic-catalog-safe-retry-ru-375.png')});
     }
    }finally{await page.close();}
   }
  }
  console.log('PRACTICE_TOPIC_CATALOG_CLIENT_DIAGNOSTICS_PASS: RU/UZ/EN 4 widths, 401/404/foreign/malformed/offline, safe retry and cross-subject stale-response guard');
 }finally{await browser.close();}
})().catch(e=>{console.error('PRACTICE_TOPIC_CATALOG_CLIENT_DIAGNOSTICS_FAILED:',e.stack||e);process.exit(1)});
