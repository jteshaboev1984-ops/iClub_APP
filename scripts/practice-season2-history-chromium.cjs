#!/usr/bin/env node
'use strict';
// #574 · Accepted Practice standalone History + existing Topic/Tour history.
// Synthetic DOM/learner data only. No Supabase, question contents or writes.
const assert=require('node:assert/strict');
const path=require('node:path');
const fs=require('node:fs');
const {chromium}=require('playwright');
(async()=>{
 const browser=await chromium.launch({headless:true,args:['--no-sandbox']});
 const screenshots=process.env.PRACTICE_S2_SCREENSHOT_DIR||'';
 if(screenshots)fs.mkdirSync(screenshots,{recursive:true});
 try{
  for(const language of ['ru','uz','en'])for(const width of [320,375,430,1440]){
   const page=await browser.newPage({viewport:{width,height:850},hasTouch:true});
   await page.setContent('<!doctype html><html lang="'+language+'"><body class="iclub-visual-v3">'+
    '<section id="courses-practice-start" class="stack-screen is-active">'+
    '<div id="practice-tour-picker"><div class="practice-tour-chip-row">'+
    '<button class="practice-tour-chip is-selected">Tour 2</button></div></div>'+
    '<div class="practice-hero"></div><div class="practice-last"></div>'+
    '<div class="practice-start-actions"><button id="practice-resume-btn"'+
    ' style="display:none" data-action="practice-resume">Resume</button>'+
    '<button id="practice-restart-btn" data-action="practice-start">Start</button></div>'+
    '<section id="practice-topic-choice"><section class="practice-topic-history">'+
    'Previous all-time topic history</section></section></section>'+
    '<section id="courses-practice-history" class="stack-screen">'+
    '<div id="practice-history-title"></div><div id="practice-history-subtitle"></div>'+
    '<div id="practice-history-content"></div></section>'+
    '<section id="courses-my-recs"><div id="topic-history"></div><div id="tour-history"></div></section>'+
    '<section id="courses-my-rec-topic-history"><div id="my-rec-topic-history-title"></div>'+
    '<div id="my-rec-topic-history-subtitle"></div><div id="my-rec-topic-history-body"></div></section>'+
    '<section id="courses-my-rec-topic-review"><div id="my-rec-topic-review-body"></div></section>'+
    '</body></html>');
   await page.addStyleTag({content:
    'html,body{margin:0;font-family:ui-sans-serif,system-ui,-apple-system,Segoe UI,Roboto,Arial;'+
    'background:#f5f8fe;color:#142b50}*{box-sizing:border-box}'+
    '.stack-screen{display:none}.stack-screen.is-active{display:block}'});
   await page.addStyleTag({path:path.resolve('practice-results-tabs.css')});
   await page.addStyleTag({path:path.resolve('visual/iclub-academy-ux531-b04b08.css')});
   await page.addScriptTag({path:path.resolve('practice-history-screen.js')});
   await page.addScriptTag({path:path.resolve('practice-results-tabs.js')});
   const setup=await page.evaluate(locale=>{
    const mk=(id)=>({id,created_at:'2026-11-02T12:00:00+05:00',
      percent:70,score:7,time_seconds:50+id,topic:'Synthetic topic '+id,
      correct:4,total:6,finished_at:'2026-11-02T12:00:00+05:00',
      tour_no:id%7+1,answers_total:10});
    const recent=Array.from({length:20},(_,i)=>mk(i+1));
    const archived=Array.from({length:20},(_,i)=>mk(i+31));
    const early=Array.from({length:4},(_,i)=>mk(i+70));
    const period={ok:true,period_active:true,season_no:2,
      subject_key:'mathematics',period_starts_at:'2026-11-01T00:00:00+05:00',
      main:{attempts_count:80,archived_attempts_count:28+4,
        recent,archived_recent:archived},
      topic:{sessions_count:73,archived_sessions_count:20+4,
        recent,archived_recent:archived},
      archive_seasons:[
       {key:'season-1',season_no:1,
        main:{attempts_count:28,recent:archived},
        topic:{sessions_count:20,recent:archived}},
       {key:'legacy',
        main:{attempts_count:4,recent:early},
        topic:{sessions_count:4,recent:early}}]};
    const accepted=window.iClubPracticeSeason2HistoryV1.render(period,'mathematics',locale);
    const active=window.iClubPracticeCurrentTourV1.render(
      {activeTourNo:2,lastCompletedTourNo:1,selectedTourNo:2},locale);
    const legacyTopic={ok:true,subject_key:'mathematics',
      completed_sessions:99,last:recent[0],
      recent:recent.map(r=>({...r,session_id:r.id,review:[]}))};
    window.iClubPracticeTopicHistoryV1.renderHistoryPage(
      locale,'mathematics',legacyTopic,false);
    window.iClubPracticeTourHistoryV1.render(
      document.getElementById('tour-history'),
      {ok:true,last:recent,attempts_count:100},false,locale);
    window.addEventListener('iclub-practice-open-history',()=>{
      document.getElementById('courses-practice-start').classList.remove('is-active');
      document.getElementById('courses-practice-history').classList.add('is-active');
      window.iClubPracticeHistoryScreenV1.render();
    });
    return {accepted,active};
   },language);
   assert(setup.accepted&&setup.active,'S2 period and active Tour status failed');
   const practice=page.locator('#courses-practice-start');
   const focus=practice.locator('[data-practice-current-tour]');
   assert((await focus.textContent()).includes('2'),'real active Tour number missing');
   assert.equal(await focus.locator('.iclub-practice-current-tour-action').count(),0,
     'obsolete quick action breaks accepted stats → choice → action order');
   assert.equal(await practice.locator('.practice-start-actions button[data-action="practice-start"]').count(),1,
     'primary Tour Start after selection missing');
   assert.equal(await practice.locator('.iclub-practice-history-entry').count(),1,
     'one compact standalone History entry required');
   assert.equal(await practice.locator('.iclub-s2-history-block').count(),0,
     'old embedded period panels must not be duplicated');
   assert.equal(await practice.locator('.iclub-s2-history-bottom-details').count(),0,
     'old embedded archive must be removed');
   assert.equal(await page.locator('#my-rec-topic-history-body .iclub-topic-history-row').count(),3,
     'independent Topic History must show three recent');
   assert.equal(await page.locator('#tour-history .iclub-sx-tour-history-row').count(),3,
     'independent Tour History must show three recent');
   const theme=await practice.evaluate(el=>{
     const entry=el.querySelector('.iclub-practice-history-entry');
     const cs=getComputedStyle(entry),body=getComputedStyle(document.body);
     const old=el.querySelector('#practice-topic-choice .practice-topic-history');
     return {token:body.getPropertyValue('--academy-paper').trim(),
       border:cs.borderTopColor,color:cs.color,
       oldTopicHidden:getComputedStyle(old).display==='none'};
   });
   assert.equal(theme.token,'#fff','Academy OS paper token absent');
   assert.equal(theme.border,'rgb(204, 220, 244)','History entry border diverged from Academy OS');
   assert(theme.oldTopicHidden,'stale Topic History duplicates active S2 view');
   for(const mode of ['topics','tours']){
    await practice.locator('#practice-results-tab-'+mode).click();
    assert.equal(await practice.locator('#practice-results-panel-'+mode).isVisible(),true);
    assert.equal(await practice.locator('#practice-results-panel-'+
      (mode==='tours'?'topics':'tours')).isVisible(),false);
   }
   // Existing user-owned recommendation histories retain 3 + 5 disclosure.
   const topicHolder=page.locator('#my-rec-topic-history-body .iclub-s2-history-earlier');
   await topicHolder.locator('summary').click();
   await page.waitForFunction(()=>
     document.querySelectorAll('#my-rec-topic-history-body .iclub-s2-history-earlier .iclub-topic-history-row').length===5);
   await topicHolder.locator('.iclub-s2-history-more').click();
   assert.equal(await topicHolder.locator('.iclub-topic-history-row').count(),10,
     'existing Topic 3+5 must not be regressed');
   const tourHolder=page.locator('#tour-history .iclub-s2-history-earlier');
   await tourHolder.locator('summary').click();
   await page.waitForFunction(()=>
     document.querySelectorAll('#tour-history .iclub-s2-history-earlier .iclub-sx-tour-history-row').length===5);
   await tourHolder.locator('.iclub-s2-history-more').click();
   assert.equal(await tourHolder.locator('.iclub-sx-tour-history-row').count(),10,
     'existing Tour 3+5 must not be regressed');
   assert.equal(await page.locator('#my-rec-topic-history-body .iclub-s2-history-note').count(),1,
     'older server records cap note lost');
   // The accepted History screen, not Practice itself, owns season swipe.
   await practice.locator('.iclub-practice-history-entry').click();
   const history=page.locator('#courses-practice-history .iclub-ph-root');
   assert.equal(await history.count(),1,'genuine standalone History not opened');
   assert.equal(await history.getAttribute('data-history-season'),'2');
   assert.equal(await history.locator('.iclub-ph-current-badge').textContent(),
     {ru:'Текущий сезон',uz:'Joriy mavsum',en:'Current season'}[language]);
   await history.locator('.iclub-ph-arrow').last().click();
   assert.equal(await history.getAttribute('data-history-season'),'1');
   assert.equal(await history.locator('.iclub-ph-early').count(),1,
     'pre-Season1 attempt disclosure missing');
   assert.equal(await history.locator('.iclub-ph-current-badge').isVisible(),false,
     'historical season may not be labeled current');
   const overflow=await page.evaluate(()=>document.documentElement.scrollWidth-innerWidth);
   assert(overflow<=1,'horizontal overflow '+language+'/'+width+': '+overflow);
   if(screenshots && language==='ru'&&width===375)
     await page.screenshot({path:path.join(screenshots,'practice-season2-integrated-history-ru-375.png'),animations:'disabled'});
   // Draft S2 still allows the compact entry but no fictitious S2 history.
   await page.evaluate(()=>window.iClubPracticeSeason2HistoryV1.render(
     {ok:true,period_active:false,subject_key:'mathematics'},'mathematics',document.documentElement.lang));
   assert.equal(await practice.locator('.iclub-practice-history-entry').count(),1,
     'History access must remain visible for Season1 learner');
   assert.equal(await practice.locator('[data-practice-s2-active="true"]').count(),0,
     'draft S2 may not be represented as current');
   await page.close();
  }
  console.log('PRACTICE_SEASON2_ACCEPTED_HISTORY_CHROMIUM_PASS: 3 locales, 4 widths, Tour/Topic 3+5, single standalone History, no phantom Season0/duplicate action');
 }finally{await browser.close();}
})().catch(e=>{console.error('PRACTICE_SEASON2_HISTORY_CHROMIUM_FAILED:',e.stack||e.message);process.exit(1)});
