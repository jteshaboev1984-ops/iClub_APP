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
const historySql=fs.readFileSync(path.join(root,'supabase/migrations/20261008093000_practice_topic_history_safe_v1.sql'),'utf8');
assert.match(historySql,/auth\.uid\(\)/,'Topic history must require auth');
assert.match(historySql,/s\.user_id=v_uid/,'Topic history must be scoped to owner');
assert.match(historySql,/s\.subject_id=v_subject_id/,'Topic history must be scoped to subject');
assert.match(historySql,/left\(s\.client_session_id,22\)='practice_topic_choice_'/,'Only self-chosen drills count');
assert.match(historySql,/s\.status='finalized'/,'Exclude incomplete sessions');
assert.match(historySql,/answered=total/,'Exclude unverified or partial sessions');
assert.match(historySql,/revoke all on function public\.get_practice_topic_history_safe_v1\(text\) from anon/,'Anonymous access is denied');
assert.doesNotMatch(historySql,/\b(?:delete|insert|update|truncate|drop|alter)\s+(?:into\s+|table\s+|from\s+)?(?:public|private)\./i,'Topic summary must remain read only');
const api=fs.readFileSync(path.join(root,'security/legacy-assessment-safe-api.js'),'utf8');
assert.match(sql,/auth\.uid\(\)/,'Requires authenticated user');
assert.match(sql,/security definer/i);
assert.match(sql,/not public\.iclub_practice_drill_question_protected_v4\(q\.id\)/);
assert.match(sql,/not exists \([\s\S]*?public\.tour_questions tq where tq\.question_id=q\.id/);
assert.equal((guard.match(/public\.tour_questions tq where tq\.question_id=q\.id/g)||[]).length,6,
  'Every drill candidate path must reject all Tour-linked questions');

assert.match(sql,/m\.is_runtime_allowed is true/);
assert.match(sql,/p\.is_active is true/);
assert.doesNotMatch(sql,/v_current_tour|v_season_id|t\.start_date/);
assert.match(sql,/revoke all on function public\.get_practice_available_topics_safe_v1\(text\) from public/);
assert.match(sql,/grant execute on function public\.get_practice_available_topics_safe_v1\(text\)/);
const choiceSql=fs.readFileSync(path.join(root,'supabase/migrations/20261008090100_practice_topic_choice_drill_v1.sql'),'utf8');
const lockSql=fs.readFileSync(path.join(root,'supabase/migrations/20261008090200_practice_topic_choice_anon_lock_v1.sql'),'utf8');
assert.match(choiceSql,/revoke all on function public\.start_practice_topic_drill_choice_safe_v1\(text,text,text,text\) from anon/);
assert.match(lockSql,/revoke all on function public\.start_practice_topic_drill_choice_safe_v1\(text,text,text,text\) from anon/);

assert.doesNotMatch(sql,/\b(?:delete|insert|update|truncate|drop|alter)\s+(?:into\s+|table\s+|from\s+)?(?:public|private)\./i,'Catalog SQL must contain no data mutation');
for(const clause of ['p.is_active is true','ppq.is_active is true',
  'm.lifecycle_state=\'published\'','m.is_runtime_allowed is true',
  'not public.iclub_practice_drill_question_protected_v4(q.id)'])
  assert(guard.includes(clause),'SQL catalog must mirror v5 drill eligibility: '+clause);
assert.match(html,/id="practice-topic-choice"/);
assert.match(html,/practice-topic-choice\.js\?v=ptopic2/);
assert.match(html,/practice-topic-choice\.css\?v=ptopic2/);
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
// Verified aggregate counts do not reveal answer keys or individual answers.
const privacyScan=js.replace(/total_correct_answers/g,'');
if(/correct_answer|answer_key|score_update|mastery/i.test(privacyScan))throw Error('UI module must never access protected answers or academic state');
// Draft-recovery safety: transient API failure must never delete local progress.
const resumeStart=app.indexOf('if (action === "practice-resume")');
const resumeEnd=app.indexOf('if (action === "practice-pause")',resumeStart);
assert(resumeStart>=0&&resumeEnd>resumeStart,'Resume handler must exist');
const resume=app.slice(resumeStart,resumeEnd);
const invalid=resume.indexOf('if (!restoredQuiz'),valid=resume.indexOf('state.quizLock = "practice"');
assert(invalid>=0&&valid>invalid,'Resume failure guard must precede mutation');
assert.doesNotMatch(resume.slice(invalid,valid),/clearPracticeDraft\s*\(/,'Never delete draft if restore failed');
assert.match(resume.slice(invalid,valid),/showToast\(tr3\(/,'Retry notice is trilingual');
assert(resume.indexOf('saveState()',valid)<resume.indexOf('clearPracticeDraft()',valid),
  'Persist restored quiz before clearing recovery draft');
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
          if(name==='get_practice_topic_history_safe_v1')
            return {data:{ok:true,subject_key:'economics',completed_sessions:2,
              total_correct_answers:3,total_answered:20,
              last:{topic:'Topic 23',correct:1,total:10},
              best:{topic:'Topic 01',correct:2,total:10},
              recent:[
                {topic:'Topic 23',correct:1,total:10},
                {topic:'Topic 01',correct:2,total:10}
              ]},error:null};
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
    await page.waitForSelector('.practice-topic-history:not([hidden])');
    const metrics=await page.locator('.practice-topic-history').innerText();
    assert(metrics.includes('1 / 10'),'Latest topic result must appear on Practice start');
    assert(metrics.includes('2 / 10'),'Best topic result must appear separately');
    assert(metrics.includes('3 / 20'),'Accumulative answer count must be distinct from Tour progress');
    assert.equal(await page.locator('.practice-topic-history-row').count(),2,'Recent session history must be visible');
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
    const calls=await page.evaluate(()=>window.__calls);
    assert.deepEqual(calls,[
      ['get_practice_topic_history_safe_v1',{p_subject_key:'economics'}],
      ['get_practice_available_topics_safe_v1',{p_subject_key:'economics'}]
    ]);
    const overflow=await page.evaluate(()=>document.documentElement.scrollWidth>window.innerWidth+1);
    assert.equal(overflow,false,'No horizontal overflow: '+lang+' / '+width);
    assert((await open.boundingBox()).height>=44,'Tap target too small');
   }finally{await page.close();}
  }
 }
 // A single saved result must appear once (including narrow mobile width).
 const once=await browser.newPage({viewport:{width:320,height:800}});
 try {
  await once.setContent('<!doctype html><html><body><div id="practice-topic-choice"></div></body></html>');
  await once.addStyleTag({content:css});
  await once.evaluate(()=>{window.sb={rpc:async(name)=>({
    data:name==='get_practice_topic_history_safe_v1'
      ? {ok:true,subject_key:'mathematics',completed_sessions:1,
         total_correct_answers:7,total_answered:10,
         last:{topic:'Quadratics',correct:7,total:10},
         best:{topic:'Quadratics',correct:7,total:10},
         recent:[{topic:'Quadratics',correct:7,total:10}]}
      : {ok:true,topics:[]},error:null
  })};});
  await once.addScriptTag({content:js});
  await once.evaluate(()=>window.iClubPracticeTopicChoice.mount({
    subjectKey:'mathematics',language:'ru',onStart:async()=>{}
  }));
  await once.waitForSelector('.practice-topic-history:not([hidden])');
  assert.equal(await once.locator('.practice-topic-history-metric').count(),1,
    'A single session must not appear in three metrics');
  assert.equal(await once.locator('.practice-topic-history-row').count(),0,
    'A single session must not repeat under Recent');
  assert((await once.locator('.practice-topic-history').innerText()).includes('7 / 10'));
  assert.equal(await once.evaluate(()=>document.documentElement.scrollWidth>innerWidth+1),false,
    '320px view must not overflow');
 } finally { await once.close(); }
 const page=await browser.newPage();
 try{
  await page.setContent('<!doctype html><html><body><div id="practice-topic-choice"></div></body></html>');
  await page.addScriptTag({content:js});
  await page.evaluate(()=>{window.sb={rpc:async(name)=>({
    data:name==='get_practice_topic_history_safe_v1'
      ? {ok:true,subject_key:'mathematics',completed_sessions:0,
         total_correct_answers:0,total_answered:0,last:null,best:null,recent:[]}
      : {ok:true,topics:[]},error:null
    })};window.iClubPracticeTopicChoice.mount({subjectKey:'mathematics',language:'ru',onStart:async()=>{}});});
  await page.click('.practice-topic-choice-toggle');
  await page.waitForFunction(()=>document.querySelector('.practice-topic-choice-status')?.textContent.includes('нет доступных'));
  assert.equal(await page.locator('.practice-topic-choice-item').count(),0,'Unavailable Mathematics v2 must not invent topics');
  assert.equal(await page.locator('.practice-topic-history').isVisible(),false,'No topic history must not invent progress');
 }finally{await page.close();}
 }finally{await browser.close();}
 console.log('PASS: Practice topic choice: 3 locales × 3 mobile viewports; gating, search, routing, no overflow, empty-bank');
})().catch(e=>{console.error(e);process.exit(1);});