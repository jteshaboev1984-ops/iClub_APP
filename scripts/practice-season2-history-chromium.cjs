#!/usr/bin/env node
'use strict';
// #574: real synthetic Chromium DOM for the accepted Exam Prep 3+5 history
// pattern and new Season2 period. No real learners, questions or DB calls.
const assert=require('node:assert/strict');
const path=require('node:path');
const {chromium}=require('playwright');
(async()=>{
 const browser=await chromium.launch({headless:true,args:['--no-sandbox']});
 try{
  for(const language of ['ru','uz','en']){
   for(const width of [320,375,430,1440]){
    const page=await browser.newPage({viewport:{width,height:850}});
    await page.setContent('<!doctype html><html lang="'+language+'"><body class="iclub-visual-v3">'+
      '<section id="courses-practice-start"><div id="practice-tour-picker"></div>'+
      '<div class="practice-hero"></div><div class="practice-last"></div>'+
      '<div class="practice-start-actions"></div><div id="practice-topic-choice"></div></section>'+
      '<section id="courses-my-recs"><div id="topic-history"></div><div id="tour-history"></div></section>'+
      '<section id="courses-my-rec-topic-history"><div id="my-rec-topic-history-title"></div>'+
      '<div id="my-rec-topic-history-subtitle"></div><div id="my-rec-topic-history-body"></div></section>'+
      '<section id="courses-my-rec-topic-review"><div id="my-rec-topic-review-body"></div></section></body></html>');
    await page.addStyleTag({path:path.resolve('practice-results-tabs.css')});
    await page.addScriptTag({path:path.resolve('practice-results-tabs.js')});
    const out=await page.evaluate(locale=>{
     const mk=(i,season)=>({id:i,created_at:'2026-11-0'+(i%8+1)+'T12:00:00Z',
       percent:i%101,score:i%10,time_seconds:45+i,topic:'Synthetic topic '+i,
       correct:i%6,total:6,finished_at:'2026-11-08T12:00:00Z',tour_no:i%7+1,
       answers_total:10});
     const recent=Array.from({length:20},(_,i)=>mk(i+1,2));
     const archived=Array.from({length:20},(_,i)=>mk(i+31,1));
     const period={ok:true,period_active:true,subject_key:'mathematics',
       period_starts_at:'2026-11-01T00:00:00+05:00',main:{
         attempts_count:80,archived_attempts_count:40,recent,archived_recent:archived
       },topic:{sessions_count:73,archived_sessions_count:30,recent,archived_recent:archived}};
     const rendered=window.iClubPracticeSeason2HistoryV1?.render(period,'mathematics',locale);
     const topic={ok:true,subject_key:'mathematics',completed_sessions:99,
       recent:recent.map(r=>({...r,session_id:r.id,review:[]})),last:recent[0]};
     window.iClubPracticeTopicHistoryV1.renderHistoryPage(locale,'mathematics',topic,false);
     window.iClubPracticeTourHistoryV1.render(
       document.getElementById('tour-history'),{ok:true,last:recent,attempts_count:100},false,locale);
     return {rendered,topicRows:document.querySelectorAll('#my-rec-topic-history-body .iclub-topic-history-row').length,
       tourRows:document.querySelectorAll('#tour-history .iclub-sx-tour-history-row').length};
    },language);
    assert(out.rendered,'period render failed');
    assert.equal(out.topicRows,3,'topic history must initially show latest 3');
    assert.equal(out.tourRows,3,'previous Tour history initially shows 3');
    for(const mode of ['tours','topics']){
     await page.locator('#practice-results-tab-'+mode).click();
     const selector='[data-practice-s2-history="'+mode+'"]';
     assert.equal(await page.locator(selector+' .iclub-s2-history-current .iclub-s2-history-row').count(),3);
     const current=page.locator(selector+' .iclub-s2-history-current');
     await current.locator('.iclub-s2-history-earlier summary').click();
     await page.waitForFunction(sel=>document.querySelectorAll(sel).length===5,
       selector+' .iclub-s2-history-current .iclub-s2-history-earlier .iclub-s2-history-row');
     await current.locator('.iclub-s2-history-more').click();
     assert.equal(await current.locator('.iclub-s2-history-earlier .iclub-s2-history-row').count(),10);
     const archive=page.locator(selector+' .iclub-s2-history-archive');
     await archive.locator('summary').first().click();
     await page.waitForFunction(sel=>document.querySelectorAll(sel).length===3,
       selector+' .iclub-s2-history-archive > .iclub-s2-history-rows > .iclub-s2-history-row');
     assert((await page.locator(selector+' .iclub-s2-history-note').count())>=1,
       'partial server cap disclosure absent');
    }
    const dedicated=page.locator('#my-rec-topic-history-body .iclub-s2-history-earlier');
    await dedicated.locator('summary').click();
    await page.waitForFunction(()=>document.querySelectorAll('#my-rec-topic-history-body .iclub-s2-history-earlier .iclub-topic-history-row').length===5);
    await dedicated.locator('.iclub-s2-history-more').click();
    assert.equal(await dedicated.locator('.iclub-topic-history-row').count(),10);
    const tour=page.locator('#tour-history .iclub-s2-history-earlier');
    await tour.locator('summary').click();
    await page.waitForFunction(()=>document.querySelectorAll('#tour-history .iclub-s2-history-earlier .iclub-sx-tour-history-row').length===5);
    await tour.locator('.iclub-s2-history-more').click();
    assert.equal(await tour.locator('.iclub-sx-tour-history-row').count(),10);
    assert((await page.locator('#my-rec-topic-history-body .iclub-s2-history-note').count())===1,
      'topic server cap must be described honestly');
    const w=await page.evaluate(()=>document.documentElement.scrollWidth-innerWidth);
    assert(w<=1,'horizontal overflow at '+width+': '+w);
    const hidden=await page.evaluate(()=>{
      window.iClubPracticeSeason2HistoryV1.render({ok:true,period_active:false},'mathematics',document.documentElement.lang);
      return [...document.querySelectorAll('[data-practice-s2-history]')].every(x=>x.hidden);
    });
    assert(hidden,'draft/unknown Season2 must not show new period');
    await page.close();
   }
  }
  console.log('PRACTICE_SEASON2_HISTORY_CHROMIUM_3_5_PASS: RU/UZ/EN, 320/375/430/1440, archive, no write');
 }finally{await browser.close()}
})().catch(e=>{console.error('PRACTICE_SEASON2_HISTORY_CHROMIUM_FAILED:',e.message);process.exit(1)});
