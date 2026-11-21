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
       const ui=({
         ru:{page:'Практика',tour:'Тур',best:'Лучший результат',time:'Лучшее время',
           stage:'Практика 2 тура',start:'Начать практику тура 2',recent:'Последние попытки'},
         uz:{page:'Amaliyot',tour:'Tur',best:'Eng yaxshi natija',time:'Eng yaxshi vaqt',
           stage:'2-tur amaliyoti',start:'2-tur amaliyotini boshlash',recent:'So‘nggi urinishlar'},
         en:{page:'Practice',tour:'Tour',best:'Best result',time:'Best time',
           stage:'Practice for Tour 2',start:'Start practice for Tour 2',recent:'Recent attempts'}
       })[locale];
       // Real component markup & stylesheet order, but only synthetic scores.
       await page.setContent('<!doctype html><html lang="'+locale+'">'+
         '<body class="iclub-visual-v3">'+
         '<section id="courses-practice-start" class="stack-screen is-active">'+
         '<div class="section"><div class="h1">'+ui.page+'</div></div>'+
         '<div id="practice-tour-picker" class="practice-tour-picker">'+
         '<div class="practice-tour-picker-head"><div class="practice-tour-picker-title">'+
         (locale==='ru'?'Выбор тура':locale==='uz'?'Tur tanlash':'Tour selection')+'</div></div>'+
         '<div class="practice-tour-scroll-hint">'+
         (locale==='ru'?'← Листайте, чтобы увидеть все туры →':
          locale==='uz'?'← Barcha turlarni ko‘rish uchun suring →':'← Swipe to see all tours →')+
         '</div><div class="practice-tour-chip-row">'+
         '<button class="practice-tour-chip is-completed" type="button" data-tour-no="1">'+ui.tour+' 1</button>'+
         '<button class="practice-tour-chip is-selected is-active" type="button" data-tour-no="2">'+ui.tour+' 2</button>'+
         '<button class="practice-tour-chip is-not-started" type="button" data-tour-no="3">'+ui.tour+' 3</button>'+
         [4,5,6,7].map(n=>'<button class="practice-tour-chip is-locked" type="button" disabled aria-disabled="true" data-tour-no="'+n+'"><span class="practice-tour-chip-label"><span class="practice-tour-chip-lock">🔒</span>'+ui.tour+' '+n+'</span></button>').join('')+
         '</div></div>'+
         '<div class="practice-hero"><div class="practice-hero-top"><div class="practice-hero-left">'+
         '<div class="practice-hero-kicker">'+(locale==='ru'?'Предмет':locale==='uz'?'Fan':'Subject')+'</div>'+
         '<div class="practice-hero-title" id="practice-subject-title">Mathematics</div>'+
         '<div class="practice-hero-stage" id="practice-stage-meta">'+ui.stage+'</div>'+
         '</div></div></div>'+
         '<div class="practice-last card"><div class="card-title">'+ui.recent+
         '</div><div class="practice-table-wrap">1 / 1</div></div>'+
         '<div class="practice-start-actions"><button id="practice-resume-btn" style="display:none" data-action="practice-resume">Resume</button>'+
         '<button id="practice-restart-btn" class="btn primary" data-action="practice-start">'+ui.start+'</button></div>'+
         '<section id="practice-topic-choice" class="practice-topic-choice"></section>'+
         '</section></body>');
       // Build the metric DOM exactly as the published iClub Practice hero.
       await page.evaluate(ui=>{
         const hero=document.querySelector('#courses-practice-start .practice-hero');
         const m=document.createElement('div');m.className='practice-hero-metrics';
         for(const [label,value] of [[ui.best,'8/10'],[ui.time,'4:35']]){
           const card=document.createElement('div');card.className='practice-metric';
           const lab=document.createElement('div');lab.className='practice-metric-label';lab.textContent=label;
           const v=document.createElement('div');v.className='practice-metric-value';v.textContent=value;
           card.append(lab,v);m.append(card);
         }
         hero.append(m);
       },ui);
       // Keep the synthetic fixture data, but render with the actual bundled
       // Practice/AOS styles in production stylesheet order. Screenshots with
       // only two CSS files falsely looked like unstyled text/cards.
       await page.addStyleTag({content:'html,body{margin:0;font-family:ui-sans-serif,system-ui,-apple-system,Segoe UI,Arial}*{box-sizing:border-box}#courses-practice-start{padding:14px}body{background:#f6f9fd;color:#142b50}'});
       for (const file of [
         'style.css',
         'visual/iclub-visual-v3.css',
         'visual/iclub-premium-v3.css',
         'visual/iclub-academy-v55-shell-b01.css',
         'visual/iclub-academy-ux531-b02b03.css',
         'practice-topic-choice.css',
         'practice-results-tabs.css',
         'visual/iclub-academy-ux531-b04b08.css'
       ]) await page.addStyleTag({path:path.resolve(file)});
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
         window.iClubPracticeCurrentTourV1.render({
           subjectKey:'mathematics',activeTourNo:2,
           lastCompletedTourNo:1,selectedTourNo:2,
           season2Period:{ok:true,subject_key:'mathematics',period_active:false,
             practice_access:{open_season_no:1,season1_new_attempts_open:true,
               season2_new_attempts_open:false}}
         },language);
         window.iClubPracticeSeason2HistoryV1.render(
           {ok:true,period_active:false},'mathematics',language);
       },locale);
       const root=page.locator('#courses-practice-start');
       const order=await root.evaluate(el=>{
         const before=(a,b)=>!!(a.compareDocumentPosition(b)&Node.DOCUMENT_POSITION_FOLLOWING);
         const overview=el.querySelector('.iclub-practice-overview');
         const tabs=el.querySelector('.practice-results-tabs');
         const tourStats=el.querySelector('.iclub-practice-tour-overview');
         const topicStats=el.querySelector('#practice-topic-overview');
         const tour=el.querySelector('#practice-results-panel-tours');
         const topic=el.querySelector('#practice-results-panel-topics');
         const picker=tour.querySelector('#practice-tour-picker');
         const action=tour.querySelector('.practice-start-actions');
         const last=tour.querySelector('.practice-last');
         const topicChooser=topic.querySelector('#practice-topic-choice');
         const topicAction=topic.querySelector('.practice-topic-start-actions');
         const topicHistory=topic.querySelector('.practice-topic-history-placement');
         return {
           global:before(tabs,overview)&&before(overview,tour)&&before(tour,topic),
           tour:before(picker,action)&&before(action,last),
           topic:before(topicChooser,topicAction)&&before(topicAction,topicHistory),
           tourStatsInside:tourStats.parentElement===overview,
           topicStatsInside:topicStats.parentElement===overview,
           topicStatsBeforeChoice:before(topicStats,topicChooser),
           topicOverviewOnce:el.querySelectorAll('#practice-topic-overview').length,
           statsOnce:el.querySelectorAll('.practice-hero').length,
           historyEntryOnce:el.querySelectorAll('.iclub-practice-history-entry').length,
           currentTourOnce:el.querySelectorAll('[data-practice-current-tour]').length
         };
       });
       assert(order.global&&order.tour&&order.topic&&order.tourStatsInside&&
         order.topicStatsInside&&order.topicStatsBeforeChoice,
         'unified Practice block order changed: '+JSON.stringify(order));
       assert.equal(order.topicOverviewOnce,1,'one contextual Topic stats slot');
       // Seven real-shaped Tour tiles: a selected available Tour, a completed
       // Practice Tour, an eligible sibling, and future disabled Tours.
       const rail=await root.evaluate(el=>{
         const list=el.querySelector('.practice-tour-chip-row');
         const tiles=[...list.querySelectorAll('.practice-tour-chip')];
         const chosen=tiles.find(x=>x.classList.contains('is-selected'));
         const done=tiles.find(x=>x.classList.contains('is-completed'));
         const locked=tiles.filter(x=>x.classList.contains('is-locked'));
         const bg=getComputedStyle(chosen).backgroundImage;
         return {count:tiles.length,selected:chosen?.dataset.tourNo,
           minHeight:Math.min(...tiles.map(x=>x.getBoundingClientRect().height)),
           rounded:getComputedStyle(chosen).borderTopLeftRadius,
           hasBlueSelection:bg.includes('gradient'),
           unlockedCompleted:done?.disabled===false,
           mutedCompleted:getComputedStyle(done).color!==getComputedStyle(chosen).color,
           lockedDisabled:locked.every(x=>x.disabled),
           horizontalOverflow:list.scrollWidth>list.clientWidth,
           scrollWidth:list.scrollWidth,clientWidth:list.clientWidth};
       });
       assert.equal(rail.count,7,'seven Tour buttons must remain rendered in a single rail');
       assert.equal(rail.selected,'2','selected Tour is still determined by the existing selector');
       assert(rail.minHeight>=44,'Tour tiles must meet minimum touch target: '+JSON.stringify(rail));
       assert(rail.hasBlueSelection&&rail.mutedCompleted&&rail.unlockedCompleted,
         'selected/completed Practice states lack distinct premium appearance: '+JSON.stringify(rail));
       assert(rail.lockedDisabled,'future Tour must never be made selectable by styling');
       if(width<=430)assert(rail.horizontalOverflow,'Tour rail must be horizontally swipeable on phones');
       assert.equal(order.statsOnce,2,'one identical blue hero for each mode');
       assert.equal(order.historyEntryOnce,1,'single standalone History link');
       assert.equal(order.currentTourOnce,1,'genuine Tour state must remain');
       const access=root.locator('.iclub-practice-current-tour');
       assert.equal(await access.getAttribute('data-practice-open-season'),'1',
         'S1 Practice remains open while S2 is dormant');
       assert((await access.locator('.iclub-practice-season-access').textContent()).length>=10,
         'S1 availability caption missing');
       // Official S2 per-subject state flips only the current Practice period.
       await page.evaluate(language=>window.iClubPracticeCurrentTourV1.render({
         subjectKey:'mathematics',activeTourNo:2,lastCompletedTourNo:null,
         season2Period:{ok:true,subject_key:'mathematics',period_active:true,
           practice_access:{open_season_no:2,season1_new_attempts_open:false,
             season2_new_attempts_open:true}}
       },language),locale);
       assert.equal(await access.getAttribute('data-practice-open-season'),'2',
         'S1 not closed when subject S2 opens');
       // A cross-subject or invalid RPC is never permitted to claim access.
       await page.evaluate(language=>window.iClubPracticeCurrentTourV1.render({
         subjectKey:'mathematics',activeTourNo:2,
         season2Period:{ok:true,subject_key:'chemistry',period_active:true,
           practice_access:{open_season_no:2,season1_new_attempts_open:false,
             season2_new_attempts_open:true}}
       },language),locale);
       assert.equal(await access.locator('.iclub-practice-season-access').count(),0,
         'foreign subject season status must not be rendered');
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
       await page.waitForFunction(()=>document.querySelectorAll(
         '#practice-topic-overview .practice-hero-metrics .practice-metric').length===2);
       assert.equal(await root.locator('.iclub-practice-tour-overview').isVisible(),false,
         'Tour statistics must not be shown in Topic mode');
       assert.equal(await root.locator('#practice-topic-overview').isVisible(),true,
         'Topic stats must be shown above the chooser');
       const topicMetrics=await root.locator('#practice-topic-overview .practice-metric').allTextContents();
       assert(topicMetrics.some(x=>x.includes('5/5')&&x.includes('Synthetic geometry'))&&
         topicMetrics.some(x=>x.includes('4/5')&&x.includes('Synthetic algebra')),
         'owner-scoped best and latest must be labeled with source topics: '+JSON.stringify(topicMetrics));
       const footer=await root.locator('#practice-topic-overview-footer').textContent();
       assert(footer.includes('2')&&footer.includes('9/10'),
         'verified completed sessions and correct/answered absent from summary footer: '+footer);
       assert.equal(await root.locator('#practice-topic-overview .practice-hero').count(),1,
         'Topic must reuse one original iClub hero card');
       assert.equal(await root.locator('#practice-topic-overview .practice-hero-metrics').count(),1,
         'Topic metrics must share Tour two-column component');
       const visual=await root.evaluate(el=>{
         const tour=getComputedStyle(el.querySelector('.iclub-practice-tour-overview .practice-hero'));
         const topic=getComputedStyle(el.querySelector('#practice-topic-overview .practice-hero'));
         return {background:tour.backgroundImage===topic.backgroundImage,
           border:tour.borderTopColor===topic.borderTopColor,
           radius:tour.borderTopLeftRadius===topic.borderTopLeftRadius};
       });
       assert(visual.background&&visual.border&&visual.radius,
         'Tour and Topic result cards are visually inconsistent: '+JSON.stringify(visual));
       assert.equal(await root.locator('#practice-topic-overview .practice-topic-history-latest').count(),0,
         'obsolete third mini-card must not duplicate the latest result');
       assert.equal(await root.locator('#practice-topic-overview svg').count(),0,
         'do not add academic cap or decorative status arrows');
       assert.equal(await root.locator('#practice-topic-history-placement .practice-topic-history').count(),0,
         'Topic summary must not be duplicated below selection');
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
         const stats=el.querySelector('#practice-topic-overview .practice-topic-history');
         const choice=el.querySelector('#practice-topic-choice');
         return !!(stats.compareDocumentPosition(choice)&Node.DOCUMENT_POSITION_FOLLOWING);
       });
       assert(orderTopicHistory,'Topic summary must precede Topic choice');
       assert.equal(await root.locator('#practice-topic-overview .practice-topic-history').count(),1);
       assert.equal(await root.locator('.practice-topic-choice-item[aria-pressed]').count(),0,
         'one-tap mode must not expose a separate selection state');
       const capture=out&&locale==='ru'&&width===375;
       if(capture){
         await root.screenshot({
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
       // Existing S1 aggregate must not masquerade as current S2 results.
       await page.evaluate(language=>window.iClubPracticeSeason2HistoryV1.render(
         {ok:true,period_active:true,subject_key:'mathematics',season_no:2},
         'mathematics',language),locale);
       assert.equal(await root.locator('#practice-topic-overview .practice-topic-history').isVisible(),false,
         'S1-only aggregate must be hidden during active S2');
       assert.equal(await root.locator('.iclub-practice-topic-s2-note').isVisible(),true,
         'truthful season-scoped History direction must remain visible');
       await page.evaluate(language=>window.iClubPracticeSeason2HistoryV1.render(
         {ok:true,period_active:false},'mathematics',language),locale);
       assert.equal(await root.locator('#practice-topic-overview .practice-topic-history').isVisible(),true,
         'S1 aggregate must return when S2 is dormant');
       await root.locator('#practice-results-tab-tours').click();
       assert.equal(await root.locator('#practice-results-panel-topics').isVisible(),false);
       assert.equal(await root.locator('#practice-topic-overview').isVisible(),false,
         'Topic results must not be shown in Tour mode');
       assert.equal(await root.locator('.iclub-practice-tour-overview').isVisible(),true,
         'original Tour score/time must return in Tour mode');
       assert.equal(await root.locator('#practice-restart-btn').isVisible(),true);
       const over=await page.evaluate(()=>document.documentElement.scrollWidth-innerWidth);
       assert(over<=1,'horizontal overflow '+locale+' '+width+'='+over);
       if(out&&locale==='ru'&&width===375){
         await root.screenshot({path:path.join(out,'practice-reordered-tours-ru-375.png'),animations:'disabled'});
       }
       await page.close();
     }
   }
   console.log('PRACTICE_UNIFIED_RESULTS_CHROMIUM_PASS: RU UZ EN / 320 375 430 1440, mode-aware Tour vs Topic stats, topic source, no duplicates, S2 guard, Start/Resume, catalog error+retry');
 }finally{await browser.close();}
})().catch(e=>{console.error(e.stack||e.message);process.exit(1)});
