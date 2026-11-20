#!/usr/bin/env node
'use strict';
// #574 · real renderPracticeStart source + actual Topic/Tabs, with synthetic
// Tour and catalog dependencies; no live services or protected questions.
const assert=require('node:assert/strict');
const fs=require('node:fs');
const path=require('node:path');
const {chromium}=require('playwright');
const root=path.resolve(__dirname,'..');
const app=fs.readFileSync(path.join(root,'app.js'),'utf8');
const html=fs.readFileSync(path.join(root,'index.html'),'utf8');
const a=app.indexOf('async function renderPracticeStart() {');
const b=app.indexOf('async function renderToursStart()',a+100);
assert(a>0&&b>a,'actual Practice renderer boundary missing');
const actualRenderer=app.slice(a,b).trim();
const mountAt=actualRenderer.indexOf('window.iClubPracticeTopicChoice?.mount({');
const tourAwait=actualRenderer.indexOf('await getPracticeTourCards(subjectKey)');
assert(mountAt>=0&&tourAwait>mountAt,'Topic mount must precede Tour dependency');
const begin=html.indexOf('<section id="courses-practice-start"');
const end=html.indexOf('<!-- Practice Quiz -->',begin);
assert(begin>=0&&end>begin,'original Practice HTML section missing');
const section=html.slice(begin,end);
const screenshots=process.env.PRACTICE_TOPIC_RENDER_SCREEN_DIR||'';
if(screenshots)fs.mkdirSync(screenshots,{recursive:true});
(async()=>{
 const browser=await chromium.launch({headless:true,args:['--no-sandbox']});
 try {
 for(const lang of ['ru','uz','en'])for(const width of [320,375,430,1440]){
  const page=await browser.newPage({viewport:{width,height:850}});
  try{
   await page.setContent('<!doctype html><html lang="'+lang+'"><body class="iclub-visual-v3"><main>'+section+'</main></body></html>');
   await page.addStyleTag({content:'html,body{margin:0;font:14px system-ui;background:#f4f7fd;color:#123;box-sizing:border-box}*,*::before,*::after{box-sizing:border-box}main{max-width:1440px}[hidden]{display:none!important}'});
   await page.addStyleTag({path:path.join(root,'practice-topic-choice.css')});
   await page.addStyleTag({path:path.join(root,'practice-results-tabs.css')});
   await page.addScriptTag({path:path.join(root,'practice-topic-choice.js')});
   await page.addScriptTag({path:path.join(root,'practice-results-tabs.js')});
   await page.evaluate(()=>{
     window.state={courses:{subjectKey:'mathematics'}};
     window.__practiceStartRenderSeq=0;
     window.__waiters={};window.__starts=[];window.__rpcReads=[];
     window.$=q=>document.querySelector(q);
     window.subjectByKey=key=>({title:key});
     window.subjectTitle=(key,title)=>title||key;
     window.t=k=>k;
     window.tr3=(ru,uz,en)=>
       document.documentElement.lang==='uz'?uz:document.documentElement.lang==='en'?en:ru;
     window.renderTrendBars=()=>{};
     window.beginUiLoading=()=>({active:()=>true,finish:()=>{}});
     window.uiLoadingRetry=()=>{};
     window.logClientError=()=>{};
     window.currentLang=()=>document.documentElement.lang;
     window.startPracticeByRec=(rec,origin)=>{
       window.__starts.push({topic:rec.topic,origin,subject:window.state.courses.subjectKey});
     };
     window.getPracticeTourCards=subjectKey=>new Promise((resolve,reject)=>{
       window.__waiters[subjectKey]={resolve,reject};
     });
     window.sb={rpc:async(name,args)=>{
       window.__rpcReads.push({name,subject:args.p_subject_key});
       if(name==='get_practice_topic_history_safe_v1')
         return {data:{ok:true,subject_key:args.p_subject_key,
           completed_sessions:0,last:null,best:null,
           total_correct_answers:0,total_answered:0,recent:[]},error:null};
       if(name==='get_practice_available_topics_safe_v1')
         return {data:{ok:true,subject_key:args.p_subject_key,topics:[
           {topic:args.p_subject_key+' synthetic topic',question_count:2}
         ]},error:null};
       throw new Error('unexpected RPC '+name);
     }};
   });
   await page.addScriptTag({content:actualRenderer});
   await page.evaluate(()=>{void renderPracticeStart();});
   await page.waitForFunction(()=>Boolean(window.__waiters?.mathematics));
   const tabs=page.locator('#practice-results-tab-topics');
   await tabs.click();
   await page.waitForFunction(()=>document.querySelector('.practice-topic-choice-item')?.textContent.includes('mathematics synthetic topic'));
   const before=await page.evaluate(()=>({
     reads:window.__rpcReads.filter(x=>x.name==='get_practice_available_topics_safe_v1'),
     starts:window.__starts,
     outstanding:!!window.__waiters.mathematics,
     mode:document.querySelector('#courses-practice-start')?.dataset.practiceResultsMode
   }));
   assert.equal(before.reads.length,1,'Topic catalog missing while Tour stats unresolved');
   assert.equal(before.reads[0].subject,'mathematics');
   assert.equal(before.starts.length,0,'Topic load created attempt');
   assert.equal(before.mode,'topics','Tour stats hijacked mode switch');
   await page.locator('.practice-topic-choice-item').click();
   assert.deepEqual(await page.evaluate(()=>window.__starts),
     [{topic:'mathematics synthetic topic',origin:'practice',subject:'mathematics'}],
     'actual Practice one-tap callback changed');
   await page.evaluate(()=>window.__waiters.mathematics.reject(new Error('synthetic Tour data offline')));
   await page.waitForFunction(()=>document.querySelector('#practice-stage-meta')?.textContent.includes(
     document.documentElement.lang==='uz'?'yuklab':document.documentElement.lang==='en'?'Could not':'Не удалось'));
   assert.equal(await page.locator('.practice-topic-choice-item').count(),1);
   assert.equal(await tabs.getAttribute('aria-selected'),'true');
   // Change subject while the independent Topic tab stays open.
   await page.evaluate(()=>{window.state.courses.subjectKey='chemistry';void renderPracticeStart();});
   await page.waitForFunction(()=>Boolean(window.__waiters.chemistry));
   await page.waitForFunction(()=>document.querySelector('.practice-topic-choice-item')?.textContent.includes('chemistry synthetic topic'));
   assert.equal(await page.locator('.practice-topic-choice-item').count(),1);
   assert(!(await page.locator('.practice-topic-choice-item').innerText()).includes('mathematics'));
   await page.evaluate(()=>window.__waiters.chemistry.reject(new Error('synthetic Tour data offline')));
   await page.waitForTimeout(30);
   assert.equal(await page.locator('.practice-topic-choice-item').count(),1);
   assert.equal(await page.locator('#practice-results-tab-topics').getAttribute('aria-selected'),'true');
   assert.equal(await page.evaluate(()=>window.__starts.length),1,'Tour failure auto-started another attempt');
   const overflow=await page.evaluate(()=>document.documentElement.scrollWidth-window.innerWidth);
   assert(overflow<=1,'horizontal overflow '+lang+'/'+width+': '+overflow);
   if(screenshots&&lang==='ru'&&width===375)
     await page.screenshot({path:path.join(screenshots,'practice-topic-independent-of-tour-ru-375.png'),animations:'disabled'});
  }finally{await page.close();}
 }
 console.log('PRACTICE_TOPIC_ACTUAL_RENDER_INDEPENDENCE_CHROMIUM_PASS: actual app.js Practice renderer, Topic and Tabs; 3 locales x 4 widths, Tour pending/fail, one-tap, subject remount');
 }finally{await browser.close();}
})().catch(e=>{console.error('PRACTICE_TOPIC_ACTUAL_RENDER_INDEPENDENCE_FAILED:',e.stack||e);process.exit(1)});
