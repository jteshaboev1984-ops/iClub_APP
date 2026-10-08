#!/usr/bin/env node
'use strict';
const assert=require('node:assert/strict');
const fs=require('node:fs');
const path=require('node:path');
const {chromium}=require('playwright');
const root=path.resolve(__dirname,'..');
const app=fs.readFileSync(path.join(root,'app.js'),'utf8');
const html=fs.readFileSync(path.join(root,'index.html'),'utf8');
function between(start,end){
 const i=app.indexOf(start), j=app.indexOf(end,i+start.length);
 assert(i>=0&&j>i,'Expected application function bounds: '+start);
 return app.slice(i,j);
}
const nav=between('function popCourses() {','function canCoursesBack() {');
const canBack=between('function canCoursesBack() {','function renderCoursesStack() {');
const topbar=between('function updateTopbarForView(viewName) {','// Ratings (Leaderboard) — UI skeleton');
const handler=between('function bindTopbar() {','function bindRegistration() {');
const review=between('function renderPracticeReview() {','function syncPracticeResultBadges(');
assert(!review.includes('const genericMistake ='),'Unmapped feedback template must not appear in review');
assert(!review.includes('const genericNextStep ='),'Unmapped next-step template must not appear in review');
assert(review.includes('d.diagnosticStatus === "mapped"'),'Only mapped verified diagnostics may show a cause');
assert(app.includes('handlePracticePause();'),'Back must preserve existing pause routine');
assert(html.includes('ptopic1-reviewback1'),'Cache pin must make fix available to learners');
(async()=>{
const browser=await chromium.launch({headless:true});
try{
for(const lang of ['ru','uz','en']){
 for(const width of [360,390,430]){
  const page=await browser.newPage({viewport:{width,height:844}});
  try{
   await page.setContent(`<!doctype html><html lang="${lang}"><head><meta name="viewport" content="width=device-width,initial-scale=1"></head><body>
     <header id="topbar"><button id="topbar-back" aria-label="Back">‹</button><img id="topbar-logo"><span id="topbar-title"></span><small id="topbar-subtitle"></small><button id="topbar-notifications"></button><button id="topbar-action"><span class="icon"></span></button></header>
     <nav id="tabbar"></nav><div id="practice-review-list"></div></body></html>`);
   await page.evaluate(lang=>{
    window.__language=lang;
    window.$=selector=>document.querySelector(selector);
    window.tr3=(ru,uz,en)=>({ru,uz,en})[window.__language];
    window.t=key=>({practice_review_empty:'Nothing to review',practice_review_loading_db:'Loading'}[key]||key);
    window.escapeHTML=s=>String(s??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'})[c]);
    window.formatAnswerForDisplay=(q,v)=>String(v??'');
    window.trackEvent=()=>null;
    window.onPracticeReviewOpened=()=>null;
    window.state={tab:'courses',quizLock:null,quiz:null,courses:{stack:['practice-result','practice-review'],practiceContext:'topic'},
       practiceLastDrillAttempt:{details:[
        {id:101,topic:'Topic A',type:'input',isCorrect:false,question:'Question A',userAnswer:'wrong A',correctAnswer:'right A',explanation:'Specific explanation A',diagnosticStatus:'unmapped',diagnosticFeedback:'Repeated generic text',diagnosticNextAction:'Repeated generic action'},
        {id:102,topic:'Topic A',type:'input',isCorrect:false,question:'Question B',userAnswer:'wrong B',correctAnswer:'right B',explanation:'Specific explanation B',diagnosticStatus:'unmapped',diagnosticFeedback:'Repeated generic text',diagnosticNextAction:'Repeated generic action'},
        {id:103,topic:'Topic A',type:'input',isCorrect:false,question:'Question C',userAnswer:'wrong C',correctAnswer:'right C',explanation:'Specific explanation C',diagnosticStatus:'mapped',diagnosticFeedback:'Verified reason C',diagnosticNextAction:'Verified action C'}
       ]}};
    window.getCoursesTopScreen=()=>window.state.courses.stack.at(-1);
    window.saveState=()=>{};
    window.showCoursesScreen=name=>{window.__shown=name;};
    window.replaceCourses=name=>{window.state.courses.stack=[name];window.__shown=name;};
    window.renderPracticeStart=()=>{window.__rendered=(window.__rendered||0)+1;};
    window.renderSubjectHub=()=>{window.__hub=(window.__hub||0)+1;};
    window.setTab=name=>{window.__tab=name;};
    window.showToast=msg=>{window.__toast=msg;};
    window.enforceActiveIdentityOrBlock=async()=>true;
    window.handlePracticePause=()=>{window.__pause=(window.__pause||0)+1;window.state.quizLock=null;};
   },lang);
   await page.addScriptTag({content:nav+'\n'+canBack+'\n'+topbar+'\n'+handler+'\n'+review});
   await page.evaluate(()=>renderPracticeReview());
   await page.waitForFunction(()=>document.querySelector('#practice-review-list')?.textContent.includes('Specific explanation C'));
   const text=await page.locator('#practice-review-list').innerText();
   assert(text.includes('Specific explanation A')&&text.includes('Specific explanation B'),'Must retain question-specific explanations');
   assert(text.includes('Verified reason C')&&text.includes('Verified action C'),'Must retain mapped diagnostic');
   assert(!text.includes('Repeated generic text')&&!text.includes('Repeated generic action'),'Unmapped diagnosis must stay hidden');
   assert(!text.includes('Ответ неверный, но')&&!text.includes('Compare your work'),'Old generic fallback must stay removed');
   const navResult=await page.evaluate(()=>{
     const out={};
     for(const top of ['practice-start','practice-result','practice-review','practice-recs']){
       state.courses.stack=[top];state.quizLock=null;
       out[top]={visible:canCoursesBack()};
       popCourses();
       out[top].destination=state.courses.stack.at(-1);
     }
     state.courses.stack=['practice-start','practice-result','practice-review'];
     popCourses();
     out.reviewInStack=state.courses.stack.join('>');
     return out;
   });
   assert.deepEqual(navResult,{
     'practice-start':{visible:true,destination:'subject-hub'},
     'practice-result':{visible:true,destination:'practice-start'},
     'practice-review':{visible:true,destination:'practice-result'},
     'practice-recs':{visible:true,destination:'practice-result'},
     reviewInStack:'practice-start>practice-result'
   });
   await page.evaluate(()=>{
     state.courses.stack=['practice-start','practice-quiz'];
     state.quizLock='practice';
     state.quiz={_submitInFlight:false,_finishing:false};
     updateTopbarForView('courses');
     bindTopbar();
   });
   assert.equal(await page.locator('#topbar-back').evaluate(el=>getComputedStyle(el).visibility),'visible','Back should be visible during active Practice');
   assert.match(await page.locator('#topbar-back').getAttribute('aria-label'),/Practice|практик|Amaliyot/,'Back must announce save/pause behavior');
   await page.locator('#topbar-back').click();
   await page.waitForFunction(()=>window.__pause===1);
   await page.evaluate(()=>{
     window.__pause=0;
     state.quizLock='practice';
     state.quiz={_submitInFlight:true};
   });
   await page.locator('#topbar-back').click();
   await page.waitForFunction(()=>Boolean(window.__toast));
   assert.equal(await page.evaluate(()=>window.__pause),0,'Back must not interrupt answer submission');
   const overflow=await page.evaluate(()=>document.documentElement.scrollWidth>window.innerWidth+1);
   assert(!overflow,'Review regression overflow '+lang+' '+width);
  }finally{await page.close();}
 }
}
console.log('PASS: Practice review uses verified-only feedback and safe Back flow; RU/UZ/EN × 360/390/430');
}finally{await browser.close();}
})().catch(e=>{console.error(e);process.exit(1);});