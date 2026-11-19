#!/usr/bin/env node
'use strict';
const assert=require('node:assert/strict');
const path=require('node:path');
const fs=require('node:fs');
const {chromium}=require('playwright');
(async()=>{
 const browser=await chromium.launch({headless:true,args:['--no-sandbox']});
 const out=process.env.PRACTICE_ORDER_SCREEN_DIR||'';
 if(out)fs.mkdirSync(out,{recursive:true});
 try{
   for(const locale of ['ru','uz','en']){
     for(const width of [320,375,430,1440]){
       const page=await browser.newPage({viewport:{width,height:850}});
       await page.setContent('<!doctype html><html lang="'+locale+'">'+
         '<body class="iclub-visual-v3">'+
         '<section id="courses-practice-start" class="stack-screen is-active">'+
         '<div class="section"><div class="h1">Practice</div></div>'+
         '<div id="practice-tour-picker"><div class="practice-tour-chip-row">'+
         '<button class="practice-tour-chip is-selected">Tour 1</button><button class="practice-tour-chip">Tour 2</button></div></div>'+
         '<div class="practice-hero"><div class="practice-hero-top"><div class="practice-hero-title">Mathematics</div>'+
         '<div class="practice-hero-stage">Practice for Tour 1</div></div>'+
         '<div class="practice-hero-metrics"><div class="practice-metric">Best score</div><div class="practice-metric">Best time</div></div></div>'+
         '<div class="practice-last card"><div class="card-title">Recent attempts</div><div class="practice-table-wrap">1 attempt</div></div>'+
         '<div class="practice-start-actions"><button id="practice-resume-btn" style="display:none" data-action="practice-resume">Resume</button>'+
         '<button id="practice-restart-btn" data-action="practice-start">Start Practice</button></div>'+
         '<section id="practice-topic-choice"></section>'+
         '</section></body>');
       await page.addStyleTag({content:'html,body{margin:0;font-family:ui-sans-serif,system-ui,-apple-system,Segoe UI,Arial}*{box-sizing:border-box}#courses-practice-start{padding:14px}body{background:#f6f9fd;color:#142b50}'});
       await page.addStyleTag({path:path.resolve('practice-results-tabs.css')});
       await page.addStyleTag({path:path.resolve('visual/iclub-academy-ux531-b04b08.css')});
       await page.addInitScript(()=>{});
       await page.addScriptTag({path:path.resolve('practice-topic-choice.js')});
       await page.addScriptTag({path:path.resolve('practice-results-tabs.js')});
       await page.evaluate(language=>{
         window.__startTopics=[];
         window.__simulateTopicFailure=false;
         window.sb={
           rpc:async(name,args)=>{
             if(name==='get_practice_available_topics_safe_v1'){
               if(window.__simulateTopicFailure)return {error:{code:'PGRST_TEST_SIMULATED'}};
               return {data:{ok:true,subject_key:args.p_subject_key,topics:[
                 {topic:'Synthetic algebra',question_count:12},
                 {topic:'Synthetic geometry',question_count:8}]}};
             }
             if(name==='get_practice_topic_history_safe_v1'){
               return {data:{ok:true,subject_key:args.p_subject_key,completed_sessions:2,
                 last:{topic:'Synthetic algebra',correct:4,total:5},
                 best:{topic:'Synthetic geometry',correct:5,total:5},
                 total_correct_answers:9,total_answered:10,
                 recent:[{topic:'Synthetic algebra',correct:4,total:5}]}};
             }
             throw Error('unexpected RPC '+name);
           }
         };
         window.iClubPracticeTopicChoice.mount({
           subjectKey:'mathematics',language,
           onStart:topic=>{
             window.__startTopics.push(topic);
             return new Promise(resolve=>{window.__releaseTopicStart=resolve;});
           }
         });
         window.iClubPracticeCurrentTourV1.render(
           {activeTourNo:1,lastCompletedTourNo:null,selectedTourNo:1},language);
         window.iClubPracticeSeason2HistoryV1.render(
           {ok:true,period_active:false},'mathematics',language);
       },locale);
       const root=page.locator('#courses-practice-start');
       const order=await root.evaluate(el=>{
         const before=(a,b)=>!!(a.compareDocumentPosition(b)&Node.DOCUMENT_POSITION_FOLLOWING);
         const overview=el.querySelector('.iclub-practice-overview');
         const tabs=el.querySelector('.practice-results-tabs');
         const tour=el.querySelector('#practice-results-panel-tours');
         const topic=el.querySelector('#practice-results-panel-topics');
         const picker=tour.querySelector('#practice-tour-picker');
         const action=tour.querySelector('.practice-start-actions');
         const last=tour.querySelector('.practice-last');
         const topicChooser=topic.querySelector('#practice-topic-choice');
         const topicAction=topic.querySelector('.practice-topic-start-actions');
         const topicHistory=topic.querySelector('.practice-topic-history-placement');
         return {
           global:before(overview,tabs)&&before(tabs,tour)&&before(tour,topic),
           tour:before(picker,action)&&before(action,last),
           topic:before(topicChooser,topicAction)&&before(topicAction,topicHistory),
           statsOnce:el.querySelectorAll('.practice-hero').length,
           historyEntryOnce:el.querySelectorAll('.iclub-practice-history-entry').length,
           currentTourOnce:el.querySelectorAll('[data-practice-current-tour]').length
         };
       });
       assert(order.global&&order.tour&&order.topic,'owner Practice block order changed: '+JSON.stringify(order));
       assert.equal(order.statsOnce,1,'must preserve original stats');
       assert.equal(order.historyEntryOnce,1,'single standalone History link');
       assert.equal(order.currentTourOnce,1,'genuine Tour state must remain');
       assert.equal(await root.locator('.iclub-practice-current-tour-action').count(),0,
         'stats banner must not duplicate Tour Start above mode and choice');
       assert.equal(await root.locator('#practice-results-panel-tours .practice-start-actions button[data-action="practice-start"]').count(),1,
         'one Tour Start should remain below the Tour selector');
       const statText=await root.locator('.iclub-practice-overview-label').textContent();
       assert(statText.length>4,'stats heading missing');
       assert.equal(await root.locator('#practice-restart-btn').count(),1,'Tour start missing');
       assert.equal(await root.locator('#practice-resume-btn').count(),1,'existing resume missing');
       await root.locator('#practice-results-tab-topics').click();
       await page.waitForFunction(()=>document.querySelectorAll('.practice-topic-choice-item').length===2);
       assert.equal(await root.locator('#practice-start-topic-btn').count(),0,
         'no duplicate Topic Start button is allowed');
       assert.equal(await root.locator('.practice-topic-start-actions').isVisible(),false,
         'empty Resume holder must not occupy space');
       const chooseTopic=root.locator('.practice-topic-choice-item').first();
       assert.equal(await chooseTopic.locator('.practice-topic-choice-item-action').textContent(),
         {ru:'Начать',uz:'Boshlash',en:'Start'}[locale],
         'topic tile is the immediate launch control');
       assert.equal((await page.evaluate(()=>window.__startTopics)).length,0);
       await chooseTopic.click();
       assert.deepEqual(await page.evaluate(()=>window.__startTopics),['Synthetic algebra'],
         'clicking eligible topic starts that topic immediately');
       assert.equal(await chooseTopic.isDisabled(),true,
         'topic choices must lock while a start is in flight');
       await page.evaluate(()=>{
         document.querySelector('.practice-topic-choice-item').click();
       });
       assert.equal((await page.evaluate(()=>window.__startTopics)).length,1,
         'second click while start pending must not create a second launch');
       await page.evaluate(()=>window.__releaseTopicStart());
       await page.waitForFunction(()=>!document.querySelector('.practice-topic-choice-item').disabled);
       const resume=root.locator('#practice-resume-btn');
       await resume.evaluate(el=>{el.style.display='block';});
       await page.waitForFunction(()=>!document.querySelector('#practice-topic-resume-btn').hidden);
       assert.equal(await root.locator('.practice-topic-start-actions').isVisible(),true,
         'resume holder should show only for paused attempts');
       assert.equal(await root.locator('#practice-topic-resume-btn').count(),1);
       assert.equal(await root.locator('#practice-start-topic-btn').count(),0);
       await resume.evaluate(el=>{el.style.display='none';});
       await page.waitForFunction(()=>document.querySelector('.practice-topic-start-actions').hidden);
       const orderTopicHistory=await root.evaluate(el=>{
         const part=el.querySelector('#practice-results-panel-topics');
         const action=part.querySelector('.practice-topic-start-actions');
         const history=part.querySelector('.practice-topic-history');
         return !!(action.compareDocumentPosition(history)&Node.DOCUMENT_POSITION_FOLLOWING);
       });
       assert(orderTopicHistory,'topic recent history must follow Start/Resume');
       assert.equal(await root.locator('#practice-topic-history-placement .practice-topic-history').count(),1);
       assert.equal(await root.locator('.practice-topic-choice-item[aria-pressed]').count(),0,
         'one-tap mode must not expose a separate selection state');
       const capture=out&&locale==='ru'&&width===375;
       if(capture){
         await root.locator('#practice-results-panel-topics').screenshot({
           path:path.join(out,'practice-reordered-topics-ru-375.png'),animations:'disabled'
         });
       }
       // A simulated catalog RPC error must show Retry, not start a session.
       await page.evaluate(language=>{
         window.__simulateTopicFailure=true;
         window.iClubPracticeTopicChoice.mount({
           subjectKey:'mathematics',language,
           onStart:topic=>{window.__startTopics.push(topic);}
         });
       },locale);
       await page.waitForFunction(()=>!!document.querySelector('.practice-topic-choice-retry'));
       assert.equal(await root.locator('.practice-topic-choice-item').count(),0);
       assert.equal(await root.locator('#practice-start-topic-btn').count(),0);
       await page.evaluate(()=>{window.__simulateTopicFailure=false;});
       await root.locator('#practice-topic-choice .practice-topic-choice-retry').last().click();
       await page.waitForFunction(()=>document.querySelectorAll('.practice-topic-choice-item').length===2);
       assert.equal(await root.locator('#practice-start-topic-btn').count(),0,
         'Retry must not restore a redundant start button');
       assert.equal((await page.evaluate(()=>window.__startTopics)).length,1);
       await root.locator('#practice-results-tab-tours').click();
       assert.equal(await root.locator('#practice-results-panel-topics').isVisible(),false);
       assert.equal(await root.locator('#practice-restart-btn').isVisible(),true);
       const over=await page.evaluate(()=>document.documentElement.scrollWidth-innerWidth);
       assert(over<=1,'horizontal overflow '+locale+' '+width+'='+over);
       if(out&&locale==='ru'&&width===375){
         await root.screenshot({path:path.join(out,'practice-reordered-tours-ru-375.png'),animations:'disabled'});
       }
       await page.close();
     }
   }
   console.log('PRACTICE_OWNER_ORDER_TOPIC_CATALOG_CHROMIUM_PASS: RU UZ EN / 320 375 430 1440, stats-switch-choice-CTA-recent, one-tap topic start, in-flight duplicate lock, conditional Resume, RPC error+retry');
 }finally{await browser.close();}
})().catch(e=>{console.error(e.stack||e.message);process.exit(1)});
