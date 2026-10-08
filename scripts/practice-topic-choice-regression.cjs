#!/usr/bin/env node
'use strict';
const assert=require('node:assert/strict');
const fs=require('node:fs');
const path=require('node:path');
const {chromium}=require('playwright');
const root=path.resolve(__dirname,'..');
const js=fs.readFileSync(path.join(root,'practice-topic-choice.js'),'utf8');
const css=fs.readFileSync(path.join(root,'practice-topic-choice.css'),'utf8');
const app=fs.readFileSync(path.join(root,'app.js'),'utf8');
const html=fs.readFileSync(path.join(root,'index.html'),'utf8');
const sql=fs.readFileSync(path.join(root,'supabase/migrations/20261008090000_practice_topic_catalog_v1.sql'),'utf8');
const guard=fs.readFileSync(path.join(root,'supabase/migrations/20261008090100_practice_topic_choice_drill_v1.sql'),'utf8');
const api=fs.readFileSync(path.join(root,'security/legacy-assessment-safe-api.js'),'utf8');
assert.match(sql,/auth\.uid\(\)/,'Requires authenticated user');
assert.match(sql,/security definer/i);
assert.match(sql,/not public\.iclub_practice_drill_question_protected_v4\(q\.id\)/);
assert.match(sql,/m\.is_runtime_allowed is true/);
assert.match(sql,/p\.is_active is true/);
assert.doesNotMatch(sql,/v_current_tour|v_season_id|t\.start_date/);
assert.match(sql,/revoke all on function public\.get_practice_available_topics_safe_v1\(text\) from public/);
assert.match(sql,/grant execute on function public\.get_practice_available_topics_safe_v1\(text\)/);
assert.doesNotMatch(sql,/\b(?:delete|insert|update|truncate|drop|alter)\s+(?:into\s+|table\s+|from\s+)?(?:public|private)\./i,'Catalog SQL must contain no data mutation');
for(const clause of ['p.is_active is true','ppq.is_active is true',
  'm.lifecycle_state=\'published\'','m.is_runtime_allowed is true',
  'not public.iclub_practice_drill_question_protected_v4(q.id)'])
  assert(guard.includes(clause),'SQL catalog must mirror v5 drill eligibility: '+clause);
assert.match(html,/id="practice-topic-choice"/);
assert.match(html,/practice-topic-choice\.js\?v=ptopic1/);
assert.match(html,/practice-topic-choice\.css\?v=ptopic1/);
assert.match(app,/iClubPracticeTopicChoice\?\.mount/);
assert.match(app,/startPracticeByRec\(\{ topic, subtopic: null \}, "practice"\)/);
assert.match(app,/topicChoiceOrigin: origin === "practice"/);
assert.match(app,/const launch = chooseTopic \? api\.startTopicChoice : api\.startTopic/);
assert.match(api,/start_practice_topic_drill_choice_safe_v1/);
assert.doesNotMatch(guard,/p\.tour_no\s*<=\s*v_current_tour/);
assert.match(app,/state\.courses\.practiceContext = quiz\?\.topicChoiceOrigin/);
assert.match(app,/ctx === "topic"/);
assert.match(app,/practiceTopicSelection/);
assert.match(app,/quiz\?\.topicChoiceOrigin\s*\?/);
assert.match(css,/min-height:44px/);
assert.match(css,/min-height:56px/);
if(/localStorage|sessionStorage/.test(js))throw Error('UI module must not touch storage');
if(/correct_answer|answer_key|score_update|mastery/i.test(js))throw Error('UI module must never access protected answers or academic state');
(async()=>{
 const browser=await chromium.launch({headless:true});
 try{
 for(const lang of ['ru','uz','en']){
  for(const width of [360,390,430]){
   const page=await browser.newPage({viewport:{width,height:800},deviceScaleFactor:1});
   try{
    await page.setContent('<!doctype html><html><body class="iclub-visual-v3"><main><section id="courses-practice-start"><section id="practice-topic-choice" class="practice-topic-choice"></section></section></main></body></html>');
    await page.addStyleTag({content:css});
    await page.evaluate(()=>{
      window.__calls=[];
      window.sb={
        rpc:async(name,args)=>{
          window.__calls.push([name,args]);
          return {data:{ok:true,topics:Array.from({length:23},(_,i)=>({
            topic:'Topic '+String(i+1).padStart(2,'0'),question_count:i+1
          }))},error:null};
        }
      };
      window.__starts=[];
    });
    await page.addScriptTag({content:js});
    await page.evaluate(lang=>window.iClubPracticeTopicChoice.mount({
      subjectKey:'economics',language:lang,
      onStart:async topic=>{window.__starts.push(topic);await new Promise(resolve=>setTimeout(resolve,60));}
    }),lang);
    const open=page.locator('.practice-topic-choice-toggle');
    assert.equal(await open.getAttribute('aria-expanded'),'false');
    assert.equal(await page.locator('.practice-topic-choice-panel').isVisible(),false);
    await open.click();
    await page.waitForFunction(()=>document.querySelectorAll('.practice-topic-choice-item').length===10);
    assert.equal(await page.locator('.practice-topic-choice-item').count(),10);
    await page.locator('.practice-topic-choice-more').click();
    assert.equal(await page.locator('.practice-topic-choice-item').count(),20);
    await page.locator('.practice-topic-choice-search').fill('Topic 23');
    assert.equal(await page.locator('.practice-topic-choice-item').count(),1);
    await page.locator('.practice-topic-choice-item').click();
    assert.deepEqual(await page.evaluate(()=>window.__starts),['Topic 23']);
    assert.deepEqual(await page.evaluate(()=>window.__calls),[
      ['get_practice_available_topics_safe_v1',{p_subject_key:'economics'}]
    ]);
    const overflow=await page.evaluate(()=>document.documentElement.scrollWidth>window.innerWidth+1);
    assert.equal(overflow,false,'No horizontal overflow: '+lang+' / '+width);
    assert((await open.boundingBox()).height>=44,'Tap target too small');
   }finally{await page.close();}
  }
 }
 const page=await browser.newPage();
 try{
  await page.setContent('<!doctype html><html><body><div id="practice-topic-choice"></div></body></html>');
  await page.addScriptTag({content:js});
  await page.evaluate(()=>{window.sb={rpc:async()=>({data:{ok:true,topics:[]},error:null})};window.iClubPracticeTopicChoice.mount({subjectKey:'mathematics',language:'ru',onStart:async()=>{}});});
  await page.click('.practice-topic-choice-toggle');
  await page.waitForFunction(()=>document.querySelector('.practice-topic-choice-status')?.textContent.includes('нет доступных'));
  assert.equal(await page.locator('.practice-topic-choice-item').count(),0,'Unavailable Mathematics v2 must not invent topics');
 }finally{await page.close();}
 }finally{await browser.close();}
 console.log('PASS: Practice topic choice: 3 locales × 3 mobile viewports; gating, search, routing, no overflow, empty-bank');
})().catch(e=>{console.error(e);process.exit(1);});