#!/usr/bin/env node
'use strict';
const fs=require('node:fs');
const path=require('node:path');
const assert=require('node:assert/strict');
const {chromium}=require('playwright');
(async()=>{
  const browser=await chromium.launch({headless:true,args:['--no-sandbox']});
  const screens=process.env.PRACTICE_HISTORY_SCREEN_DIR||'';
  if(screens)fs.mkdirSync(screens,{recursive:true});
  try{
    for(const locale of ['ru','uz','en']){
      for(const width of [320,375,430,1440]){
        const page=await browser.newPage({viewport:{width,height:850},hasTouch:true});
        await page.setContent('<!doctype html><html lang="'+locale+'"><meta charset="utf-8">'+
          '<body class="iclub-visual-v3">'+
          '<header class="test-head"><b>‹</b><strong>iClub</strong><span>Smarter together</span></header>'+
          '<section id="courses-practice-start" class="stack-screen is-active">'+
          '<div class="section"><div class="h1">Практика</div><div class="muted">Практика по выбранному предмету</div></div>'+
          '<div id="practice-tour-picker"></div><div class="practice-hero"></div>'+
          '<div class="practice-last"></div><div class="practice-start-actions"></div>'+
          '<div id="practice-topic-choice"></div></section>'+
          '<section id="courses-practice-history" class="stack-screen">'+
          '<div class="section iclub-ph-page-head"><div id="practice-history-title" class="h1"></div>'+
          '<div id="practice-history-subtitle" class="muted"></div></div>'+
          '<div id="practice-history-content"></div></section></body>');
        await page.addStyleTag({content:'*{box-sizing:border-box}body{margin:0;font-family:ui-sans-serif,system-ui,-apple-system,Segoe UI,Roboto,Arial;background:#f5f8fe;color:#142b50}.stack-screen{display:none}.stack-screen.is-active{display:block}.section{padding:16px}.h1{font-size:22px;font-weight:820}.muted{color:#5a759b;font-size:13px}.test-head{height:68px;background:#174aab;color:white;display:flex;align-items:center;gap:10px;padding:0 20px}.test-head b{font-size:26px}.test-head strong{font-size:21px}.test-head span{font-size:11px;opacity:.75}.practice-hero,.practice-last{min-height:55px;background:white;border:1px solid #ccdcf4;border-radius:17px;margin:10px 14px}.practice-start-actions{min-height:15px}#practice-tour-picker,#practice-topic-choice{min-height:14px}#courses-practice-start{min-height:740px}#courses-practice-history{min-height:740px}'}); 
        await page.addStyleTag({path:path.resolve('practice-results-tabs.css')});
        await page.addStyleTag({path:path.resolve('visual/iclub-academy-ux531-b04b08.css')});
        await page.addScriptTag({path:path.resolve('practice-history-screen.js')});
        await page.addScriptTag({path:path.resolve('practice-results-tabs.js')});
        const payload=await page.evaluate(lang=>{
          const mk=(i,kind)=>({id:i,created_at:'2026-11-01T13:35:00+05:00',
             percent:76+i,score:7,time_seconds:120+i,topic:'Алгебра '+i,correct:4,total:6});
          const recent=Array.from({length:13},(_,i)=>mk(i+1));
          const old=Array.from({length:11},(_,i)=>mk(i+21));
          const early=Array.from({length:4},(_,i)=>mk(i+60));
          const data={ok:true,period_active:true,subject_key:'mathematics',season_no:2,
            period_starts_at:'2026-11-01T00:00:00+05:00',
            main:{attempts_count:17,archived_attempts_count:13,recent,archived_recent:old},
            topic:{sessions_count:15,archived_sessions_count:12,recent,archived_recent:old},
            archive_seasons:[
              {key:'season-1',season_no:1,main:{attempts_count:9,recent:old},
                topic:{sessions_count:8,recent:old}},
              {key:'legacy',main:{attempts_count:4,recent:early},
                topic:{sessions_count:4,recent:early}}
            ]};
          window.iClubPracticeSeason2HistoryV1.render(data,'mathematics',lang);
          window.iClubPracticeCurrentTourV1.render({activeTourNo:2,lastCompletedTourNo:1,selectedTourNo:2},lang);
          window.addEventListener('iclub-practice-open-history',()=>{
            document.getElementById('courses-practice-start').classList.remove('is-active');
            document.getElementById('courses-practice-history').classList.add('is-active');
            window.iClubPracticeHistoryScreenV1.render();
          });
          return data;
        },locale);
        const entry=page.locator('.iclub-practice-history-entry');
        assert.equal(await entry.count(),1,'main screen must have only one compact entry');
        assert.equal(await page.locator('#courses-practice-start .iclub-s2-history-block').count(),0,
          'main screen contains a large old period history panel');
        const screenshot=(locale==='ru'&&width===375)||(locale==='uz'&&width===320)||(locale==='en'&&width===1440);
        if(screenshot&&screens)await page.screenshot({path:path.join(screens,'practice-entry-'+locale+'-'+width+'.png'),animations:'disabled'});
        await entry.click();
        assert.equal(await page.locator('#courses-practice-history.is-active').count(),1);
        assert.equal(await page.locator('#courses-practice-history .iclub-ph-root').count(),1);
        const root=page.locator('.iclub-ph-root');
        assert.equal(await root.getAttribute('data-history-season'),'2');
        assert.equal(await root.getAttribute('data-history-type'),'tours');
        assert.equal(await root.locator('.iclub-ph-results .iclub-ph-row').count(),3);
        if(screenshot&&screens)await page.screenshot({path:path.join(screens,'practice-history-season2-'+locale+'-'+width+'.png'),animations:'disabled'});
        const previous=root.locator('.iclub-ph-arrow').first();
        const older=root.locator('.iclub-ph-arrow').last();
        assert.equal(await previous.isDisabled(),true);
        await older.click();
        assert.equal(await root.getAttribute('data-history-season'),'1');
        await root.locator('#iclub-ph-tab-topics').click();
        assert.equal(await root.getAttribute('data-history-type'),'topics');
        assert.equal(await root.locator('#iclub-ph-tab-topics').getAttribute('aria-selected'),'true');
        assert.equal(await root.locator('.iclub-ph-results > .iclub-ph-early').count(),1,
          'pre-Season1 records must be retained under oldest season');
        assert.equal(await root.locator('.iclub-ph-row').count(),3,
          'older legacy rows are collapsed by default');
        if(screenshot&&screens)await page.screenshot({path:path.join(screens,'practice-history-season1-topics-'+locale+'-'+width+'.png'),animations:'disabled'});
        // No fictitious Season 0 / "before first season" swipe choice.
        assert.equal(await older.isDisabled(),true);
        assert.equal(await root.locator('.iclub-ph-dot').count(),2);
        await page.evaluate(()=>{
          const target=document.querySelector('.iclub-ph-root');
          const emit=(eventName,x,y)=>{
            const e=new Event(eventName,{bubbles:true});
            Object.defineProperty(e,eventName==='touchstart'?'touches':'changedTouches',{value:[{clientX:x,clientY:y}]});
            target.dispatchEvent(e);
          };
          emit('touchstart',250,420);emit('touchend',145,426);
        });
        assert.equal(await root.getAttribute('data-history-season'),'1','no wrap past oldest');
        await page.evaluate(()=>{
          const target=document.querySelector('.iclub-ph-root');
          const emit=(eventName,x,y)=>{
            const e=new Event(eventName,{bubbles:true});
            Object.defineProperty(e,eventName==='touchstart'?'touches':'changedTouches',{value:[{clientX:x,clientY:y}]});
            target.dispatchEvent(e);
          };
          emit('touchstart',140,420);emit('touchend',245,425);
        });
        assert.equal(await root.getAttribute('data-history-season'),'2','swipe right should show newer season');
        assert.equal(await root.getAttribute('data-history-type'),'topics','swipe should not flip history type');
        assert((await root.locator('.iclub-ph-more').count())>0,'3+5 control missing');
        await root.locator('.iclub-ph-more').first().click();
        assert.equal(await root.locator('.iclub-ph-results .iclub-ph-row').count(),8);
        const overflow=await page.evaluate(()=>document.documentElement.scrollWidth-innerWidth);
        assert(overflow<=1,'horizontal overflow on '+locale+' '+width+': '+overflow);
        assert.equal(await page.locator('#courses-practice-history button[aria-label="Back"]').count(),0,
          'independent in-page Back must not duplicate host back');
        // Draft/undated Season 2 must not be rendered as published.
        await page.evaluate(()=>window.iClubPracticeHistoryScreenV1.setData(
          {ok:true,period_active:false,subject_key:'mathematics'},'mathematics',document.documentElement.lang));
        assert.equal(await page.locator('.iclub-ph-root').count(),0,'draft Season2 was falsely presented');
        await page.close();
      }
    }
    console.log('PRACTICE_HISTORY_STANDALONE_CHROMIUM_PASS: 3 locales, 4 widths, single entry, exclusive categories, season swipe, oldest legacy disclosure');
  }finally{await browser.close();}
})().catch(error=>{console.error(error.stack||error.message);process.exit(1)});
