#!/usr/bin/env node
'use strict';
const assert=require('node:assert/strict');
const fs=require('node:fs');
const path=require('node:path');
const {chromium}=require('playwright');
const root=path.resolve(__dirname,'..');
const source=fs.readFileSync(path.join(root,'app.js'),'utf8');
const first=source.indexOf('async function confirmPracticeTopicReplacement()');
const last=source.indexOf('async function startPracticeByRec(',first);
assert(first>=0&&last>first,'Expected isolated Practice topic-switch helpers');
const helpers=source.slice(first,last);
const style=fs.readFileSync(path.join(root,'style.css'),'utf8');
const copy={ru:'Сменить тему?',uz:'Mavzuni almashtirasizmi?',en:'Change topic?'};
(async()=>{
 const browser=await chromium.launch({headless:true});
 try{
  for(const lang of ['ru','uz','en']){
   for(const width of [320,360,390,430]){
    const page=await browser.newPage({viewport:{width,height:844},deviceScaleFactor:1});
    try{
     await page.setContent('<!doctype html><html><body><main><div id="modal-root" aria-hidden="true"></div></main></body></html>');
     await page.addStyleTag({content:style});
     await page.evaluate(lang=>{window.__lang=lang;window.tr3=(ru,uz,en)=>({ru,uz,en})[window.__lang]},lang);
     await page.addScriptTag({content:helpers});
     await page.evaluate(()=>{window.__decision=confirmPracticeTopicReplacement()});
     await page.waitForSelector('.modal[role="dialog"]');
     assert.equal(await page.locator('.modal-title').innerText(),copy[lang]);
     assert.equal(await page.locator('.modal-actions button').count(),2);
     assert.equal(await page.locator('#modal-root').getAttribute('aria-hidden'),'false');
     const modal=await page.locator('.modal').boundingBox();
     assert(modal&&modal.x>=-1&&modal.x+modal.width<=width+1,'Modal fits screen: '+lang+' '+width);
     await page.locator('.modal-actions button').first().click();
     assert.equal(await page.evaluate(()=>window.__decision),false,'Cancel must not consent');
     assert.equal(await page.locator('#modal-root').getAttribute('aria-hidden'),'true');
     await page.evaluate(()=>{window.__decision=confirmPracticeTopicReplacement()});
     await page.locator('.modal-actions button').last().click();
     assert.equal(await page.evaluate(()=>window.__decision),true,'Affirmative consent required');
    } finally {await page.close();}
   }
  }
  const page=await browser.newPage();
  try{
   await page.setContent('<!doctype html><html><body><div id="modal-root" aria-hidden="true"></div></body></html>');
   await page.evaluate(()=>{
    window.tr3=(r,u,e)=>e;
    window.t=()=>'';window.showToast=v=>(window.__lastToast=v);
    window.showAsyncOverlay=()=>{};window.hideAsyncOverlay=()=>{};
    window.trackEvent=()=>{};
    window.__uid='qa-owner';
    window.getAuthUid=async()=>window.__uid;
    window.state={courses:{subjectKey:'mathematics'}};
    window.__saved=0;window.__cleared=0;window.__calls=[];window.__created=0;
    window.saveState=()=>{window.__saved++};
    window.pushCourses=()=>{};
    window.renderPracticeQuiz=()=>{};
    window.startPracticeQuestionTimer=()=>{};
    window.clearPracticeDraft=()=>{window.__cleared++;window.__draft=null};
    window.loadPracticeDraft=()=>window.__draft;
    window.buildPracticeSafeQuizFromRows=(base,rows)=>({...base,questions:rows});
    window.dbWriteWithRetry=fn=>fn();
    window.__draft={
      status:'paused',subjectKey:'mathematics',quiz:{
        topicChoiceOrigin:true,safeDrillSessionId:777,
        safeDrillClientSessionId:'practice_topic_choice_old'
      },
      pendingTopicSwitch:{
        userId:'qa-owner',subjectKey:'mathematics',topic:'Trigonometry',
        oldSessionId:777,oldClientSessionId:'practice_topic_choice_old',
        clientSessionId:'practice_topic_choice_stable_new'
      }
    };
    window.getPracticeSafeApi=()=>({drill:{
      replaceTopicChoice:async args=>{
        window.__calls.push(args.clientSessionId);
        if(window.__calls.length===1) {
          // The server commit succeeded, but the HTTP response disappeared.
          window.__created++;
          throw Error('response_lost_after_commit');
        }
        return {session_id:888,old_session_abandoned:true,status:'in_progress'};
      },
      questions:async()=>[{id:901,type:'mcq',question:'New topic question'}]
    }});
   });
   await page.addScriptTag({content:helpers});
   assert.equal(await page.evaluate(()=>resumePendingPracticeTopicChoice(window.__draft)),false);
   assert.equal(await page.evaluate(()=>window.__cleared),0,'Network loss must preserve local draft');
   assert.equal(await page.evaluate(()=>window.__draft.status),'paused');
   await page.evaluate(()=>{window.__uid='another-account'});
   assert.equal(await page.evaluate(()=>resumePendingPracticeTopicChoice(window.__draft)),false);
   assert.equal(await page.evaluate(()=>window.__calls.length),1,'Wrong account must never retry old session');
   await page.evaluate(()=>{window.__uid='qa-owner'});
   assert.equal(await page.evaluate(()=>resumePendingPracticeTopicChoice(window.__draft)),true);
   assert.deepEqual(await page.evaluate(()=>window.__calls),[
     'practice_topic_choice_stable_new','practice_topic_choice_stable_new'
   ],'Retry must reuse same client key');
   assert.equal(await page.evaluate(()=>window.__cleared),1,'Only verified resumed quiz clears old draft');
   assert.equal(await page.evaluate(()=>window.__saved),1,'Persist quiz before clearing draft');
   assert.equal(await page.evaluate(()=>window.state.quiz.safeDrillSessionId),888);
  }finally{await page.close();}
 }finally{await browser.close();}
 console.log('PASS: topic-switch modal RU/UZ/EN × 320/360/390/430 and network-commit retry recovery');
})().catch(e=>{console.error(e);process.exitCode=1});
