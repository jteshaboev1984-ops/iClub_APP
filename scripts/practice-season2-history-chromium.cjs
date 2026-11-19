#!/usr/bin/env node
'use strict';
// #574: real synthetic Chromium DOM for the accepted Exam Prep 3+5 history
// pattern and new Season2 period. No real learners, questions or DB calls.
const assert=require('node:assert/strict');
const path=require('node:path');
const fs=require('node:fs');
const {chromium}=require('playwright');
(async()=>{
 const browser=await chromium.launch({headless:true,args:['--no-sandbox']});
 const screenshotDir=process.env.PRACTICE_S2_SCREENSHOT_DIR||'';
 if(screenshotDir)fs.mkdirSync(screenshotDir,{recursive:true});
 try{
  for(const language of ['ru','uz','en']){
   for(const width of [320,375,430,1440]){
    const page=await browser.newPage({viewport:{width,height:850}});
    await page.setContent('<!doctype html><html lang="'+language+'"><body class="iclub-visual-v3">'+
      '<section id="courses-practice-start"><div id="practice-tour-picker"></div>'+
      '<div class="practice-hero"></div><div class="practice-last"></div>'+
      '<div class="practice-start-actions"></div><div id="practice-topic-choice">'+
      '<section class="practice-topic-history">Previous all-time topic history</section></div></section>'+
      '<section id="courses-my-recs"><div id="topic-history"></div><div id="tour-history"></div></section>'+
      '<section id="courses-my-rec-topic-history"><div id="my-rec-topic-history-title"></div>'+
      '<div id="my-rec-topic-history-subtitle"></div><div id="my-rec-topic-history-body"></div></section>'+
      '<section id="courses-my-rec-topic-review"><div id="my-rec-topic-review-body"></div></section></body></html>');
    // Match the actual released style.css font stack (CI fixture has no app shell).
    await page.addStyleTag({content:
      'html,body{font-family:ui-sans-serif,system-ui,-apple-system,Segoe UI,Roboto,Helvetica,Arial,"Apple Color Emoji","Segoe UI Emoji";}*{box-sizing:border-box;}'});
    await page.addStyleTag({path:path.resolve('practice-results-tabs.css')});
    // Load the actually released Academy OS visual source, NOT invented test colors.
    await page.addStyleTag({path:path.resolve('visual/iclub-academy-ux531-b04b08.css')});
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
       },topic:{sessions_count:73,archived_sessions_count:30,recent,archived_recent:archived},
       archive_seasons:[
        {key:'season-1',season_no:1,main:{attempts_count:28,recent:archived},
          topic:{sessions_count:20,recent:archived}},
        {key:'legacy',season_no:null,main:{attempts_count:12,recent:archived.slice(0,12)},
          topic:{sessions_count:10,recent:archived.slice(0,10)}}
       ]};
     const rendered=window.iClubPracticeSeason2HistoryV1?.render(period,'mathematics',locale);
     const currentTour=window.iClubPracticeCurrentTourV1?.render({
       activeTourNo:2,lastCompletedTourNo:1,selectedTourNo:2
     },locale);
     if(!currentTour)throw Error('active Tour presentation missing');
     const topic={ok:true,subject_key:'mathematics',completed_sessions:99,
       recent:recent.map(r=>({...r,session_id:r.id,review:[]})),last:recent[0]};
     window.iClubPracticeTopicHistoryV1.renderHistoryPage(locale,'mathematics',topic,false);
     window.iClubPracticeTourHistoryV1.render(
       document.getElementById('tour-history'),{ok:true,last:recent,attempts_count:100},false,locale);
     return {rendered,topicRows:document.querySelectorAll('#my-rec-topic-history-body .iclub-topic-history-row').length,
       tourRows:document.querySelectorAll('#tour-history .iclub-sx-tour-history-row').length};
    },language);
    assert(out.rendered,'period render failed');
    const focus=page.locator('[data-practice-current-tour]');
    assert((await focus.textContent()).includes('2'),'active Tour number missing');
    assert.equal(await focus.locator('[data-action="practice-select-tour"][data-tour-no="2"]').count(),1,
      'active Tour Practice quick action absent');
    const lowArchive=page.locator('[data-practice-s2-archive]');
    assert.equal(await lowArchive.locator('details.iclub-s2-history-bottom-details').count(),1,
      'one low-noise previous-season archive required');
    assert.equal(await lowArchive.locator('details.iclub-s2-history-bottom-details').getAttribute('open'),null,
      'previous seasons must be collapsed by default');
    const placement=await page.evaluate(()=>{
      const root=document.getElementById('courses-practice-start');
      const archive=root.querySelector('[data-practice-s2-archive]');
      const panels=root.querySelector('#practice-results-panel-topics');
      return !!(panels.compareDocumentPosition(archive)&Node.DOCUMENT_POSITION_FOLLOWING);
    });
    assert(placement,'archive not after the Practice learning panels');
    // Locale date punctuation differs between Node's ICU and Chromium's ICU.
    // Compare using Chromium's formatter (the same runtime that renders the UI).
    const intendedDay=await page.evaluate(lang=>
      new Date('2026-11-01T00:00:00+05:00').toLocaleDateString(
        lang==='en'?'en-GB':lang==='uz'?'uz-UZ':'ru-RU',
        {timeZone:'Asia/Tashkent'}),language);
    const actualDay=await page.locator(
      '[data-practice-s2-history="tours"] .iclub-s2-history-block > .iclub-s2-history-note'
    ).first().textContent();
    assert(actualDay.includes(intendedDay),
      'Season2 start date shifted away from local Asia/Tashkent: '+actualDay);
    assert.equal(out.topicRows,3,'topic history must initially show latest 3');
    assert.equal(out.tourRows,3,'previous Tour history initially shows 3');
    const academy=await page.evaluate(()=>{
      const body=getComputedStyle(document.body);
      const card=document.querySelector('[data-practice-s2-history="tours"] .iclub-s2-history-block');
      const cs=getComputedStyle(card);
      const legacy=document.querySelector('#practice-topic-choice .practice-topic-history');
      return {
        rootTheme:body.getPropertyValue('--academy-paper').trim(),
        background:cs.backgroundColor,
        border:cs.borderTopColor,
        radius:cs.borderTopLeftRadius,
        ink:cs.color,
        shadow:cs.boxShadow,
        oldTopicHidden:getComputedStyle(legacy).display==='none',
        duplicateSeasonDate:card.textContent?.includes('Новые результаты · Новые результаты')||false
      };
    });
    assert.equal(academy.rootTheme,'#fff','accepted Academy OS tokens did not load');
    assert.equal(academy.background,'rgb(255, 255, 255)','History has different paper than Academy OS');
    assert.equal(academy.border,'rgb(204, 220, 244)','History does not use accepted Academy OS border');
    assert.equal(academy.radius,'20px','History does not use accepted Academy OS card radius');
    assert.equal(academy.ink,'rgb(20, 43, 80)','History has noncanonical Academy OS text');
    assert(academy.shadow!=='none','History lacks quiet Academy OS elevation');
    assert(academy.oldTopicHidden,'outdated lifetime Topic history duplicates fresh Season 2 view');
    assert(!academy.duplicateSeasonDate,'duplicate period/heading copy');
    for(const mode of ['tours','topics']){
     await page.locator('#practice-results-tab-'+mode).click();
     const selector='[data-practice-s2-history="'+mode+'"]';
     assert.equal(await page.locator(selector+' .iclub-s2-history-current .iclub-s2-history-row').count(),3);
     const current=page.locator(selector+' .iclub-s2-history-current');
     if(screenshotDir && ((language==='ru'&&width===375&&mode==='tours')||
        (language==='uz'&&width===320&&mode==='topics')||
        (language==='en'&&width===1440&&mode==='topics'))){
       await page.locator(selector+' .iclub-s2-history-block').screenshot({
         path:path.join(screenshotDir,'practice-season2-'+language+'-'+width+'-'+mode+'-recent.png'),
         animations:'disabled',timeout:15000});
     }
     await current.locator('.iclub-s2-history-earlier summary').click();
     await page.waitForFunction(sel=>document.querySelectorAll(sel).length===5,
       selector+' .iclub-s2-history-current .iclub-s2-history-earlier .iclub-s2-history-row');
     await current.locator('.iclub-s2-history-more').click();
     assert.equal(await current.locator('.iclub-s2-history-earlier .iclub-s2-history-row').count(),10);
     const archive=page.locator('[data-practice-s2-archive] .iclub-s2-history-bottom-details');
     if(await archive.getAttribute('open')===null)await archive.locator('summary').first().click();
     assert.equal(await archive.locator('.iclub-s2-archive-navigator').count(),1,
       'missing compact premium season navigator');
     assert.equal(await archive.locator('.iclub-s2-archive-tab').count(),2,
       'Tours and Topics must remain two distinct accessible archive categories');
     await archive.locator('#practice-archive-mode-'+mode).click();
     assert.equal(await archive.getAttribute('data-archive-type'),mode,
       'archive segmented mode did not switch');
     assert.equal(await archive.locator('.iclub-s2-archive-panel > .iclub-s2-history-current').count(),1,
       'long stacked history: archive must show only one category');
     assert.equal(await archive.locator('.iclub-s2-archive-panel .iclub-s2-history-rows > .iclub-s2-history-row').count(),3,
       'archived season initial history must show 3');
     const selected=archive.locator('#practice-archive-mode-'+mode);
     assert.equal(await selected.getAttribute('aria-selected'),'true',
       'archive category mode not accessible to keyboard/screen readers');
     assert.equal(await archive.getAttribute('data-archive-season'),'season-1');
     assert.equal(await archive.locator('.iclub-s2-archive-dot').count(),2,
       'verified archived season and pre-season legacy require two indicators');
     if(mode==='topics'){
       const nav=archive.locator('.iclub-s2-archive-direction').last();
       await nav.click();
       assert.equal(await archive.getAttribute('data-archive-season'),'legacy',
         'arrow must advance to verified old pre-season records');
       assert.equal(await archive.getAttribute('data-archive-type'),'topics',
         'season swipe must NOT change Tour/Topic category');
       assert.equal(await nav.isDisabled(),true,'last season must not wrap or show further years');
       // Real Chromium touch-event handling: swipe right returns to Season 1.
       await page.evaluate(()=>{
         const target=document.querySelector('.iclub-s2-history-bottom-content');
         const evt=(type,x)=>{const event=new Event(type,{bubbles:true});
           Object.defineProperty(event,type==='touchstart'?'touches':'changedTouches',
             {value:[{clientX:x,clientY:250}]});
           target.dispatchEvent(event);};
         evt('touchstart',75);evt('touchend',170);
       });
       assert.equal(await archive.getAttribute('data-archive-season'),'season-1',
         'horizontal gesture must switch verified seasons without altering category');
       assert.equal(await archive.getAttribute('data-archive-type'),'topics');
       // A vertical gesture must keep the current period.
       await page.evaluate(()=>{
         const target=document.querySelector('.iclub-s2-history-bottom-content');
         const evt=(type,x,y)=>{const event=new Event(type,{bubbles:true});
           Object.defineProperty(event,type==='touchstart'?'touches':'changedTouches',
             {value:[{clientX:x,clientY:y}]});
           target.dispatchEvent(event);};
         evt('touchstart',220,150);evt('touchend',180,260);
       });
       assert.equal(await archive.getAttribute('data-archive-season'),'season-1',
         'vertical page scroll may not change the season');
     }
     assert((await page.locator(selector+' .iclub-s2-history-note').count())>=1,
       'partial server cap disclosure absent');
     if(screenshotDir && ((language==='ru'&&width===375&&mode==='tours')||
        (language==='uz'&&width===320&&mode==='topics')||
        (language==='en'&&width===1440&&mode==='topics'))){
       await page.locator('[data-practice-s2-archive]').screenshot({
         path:path.join(screenshotDir,'practice-season2-'+language+'-'+width+'-'+mode+'-archive.png'),
         animations:'disabled',timeout:15000});
     }
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
      return [...document.querySelectorAll('[data-practice-s2-history]')].every(x=>x.hidden) &&
        document.querySelector('[data-practice-s2-archive]').hidden;
    });
    assert(hidden,'draft/unknown Season2 must not show new period');
    const oldRestored=await page.evaluate(()=>
      getComputedStyle(document.querySelector('#practice-topic-choice .practice-topic-history')).display!=='none'
    );
    assert(oldRestored,'legacy Practice history not restored before Season 2');
    await page.close();
   }
  }
  console.log('PRACTICE_SEASON2_HISTORY_CHROMIUM_3_5_PASS: RU/UZ/EN, 320/375/430/1440, archive, no write');
 }finally{await browser.close()}
})().catch(e=>{console.error('PRACTICE_SEASON2_HISTORY_CHROMIUM_FAILED:',e.message);process.exit(1)});
