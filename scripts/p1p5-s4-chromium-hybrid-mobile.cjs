#!/usr/bin/env node
'use strict';
// Real Chromium / signed owner JWT / actual PostgREST / disposable PG17 S4.
// This is a UX and source-API test, NOT a student score or an AI/mentor review.
const assert=require('node:assert/strict');
const crypto=require('node:crypto');
const path=require('node:path');
const {chromium}=require('playwright');
const HOST='http://127.0.0.1:3000';
assert(process.env.CI==='true'&&process.env.P1P5_E2E_ISOLATED==='true'&&
  process.env.PGHOST==='127.0.0.1'&&process.env.PGDATABASE==='postgres',
 'S4 Chromium REFUSED outside disposable GitHub PG17');
const SECRET=process.env.P1P5_E2E_JWT_SECRET;
assert(SECRET&&SECRET.length>=32);
const enc=x=>Buffer.from(JSON.stringify(x)).toString('base64url');
const part=enc({alg:'HS256',typ:'JWT'})+'.'+enc({aud:'authenticated',role:'authenticated',
 sub:'11111111-1111-4111-8111-111111111191',
 iat:Math.floor(Date.now()/1000),exp:Math.floor(Date.now()/1000)+1800});
const token=part+'.'+crypto.createHmac('sha256',SECRET).update(part).digest('base64url');
async function run(){
 const browser=await chromium.launch({headless:true});
 try{
  for(const [lang,component,width] of [['ru','P1',390],['uz','P5',375],['en','P1',1280]]){
   const page=await browser.newPage({viewport:{width,height:850},timezoneId:'Asia/Tashkent'});
   const errors=[],trace=[];page.on('pageerror',e=>errors.push(e.message));
   page.on('dialog',d=>d.accept());
   try{
    await page.route(HOST+'/',route=>route.fulfill({status:200,contentType:'text/html',
     body:'<!doctype html><html lang="'+lang+'"><head><meta name="viewport" content="width=device-width,initial-scale=1"></head><body><section id="courses-subject-hub"><div id="subject-hub-exam-prep-entry" hidden aria-hidden="true"><span id="subject-hub-exam-prep-title"></span><span id="subject-hub-exam-prep-sub"></span></div><div id="exam-prep-host-root" hidden aria-hidden="true"></div></section></body></html>'
    }));
    await page.goto(HOST+'/');
    await page.addStyleTag({path:path.resolve('exam-prep/exam-prep-host.css')});
    await page.evaluate(({token,lang})=>{
     window.iClubExamPrepHybridPaperS4Enabled=true;
     window.__hybridTrace=[];
     window.sb={rpc:async(name,args={})=>{
       const res=await fetch('/rpc/'+name,{method:'POST',headers:{
         'Content-Type':'application/json','Authorization':'Bearer '+token
       },body:JSON.stringify(args)});
       let value=null;try{value=await res.json()}catch{}
       window.__hybridTrace.push({name,ok:res.ok,status:res.status});
       return res.ok?{data:value,error:null}:{data:null,error:{
         code:value?.code||String(res.status),message:value?.message||'error'
       }};
     }};
     window.i18n={getLang:()=>lang};
    },{token,lang});
    for(const file of ['exam-prep/exam-prep-api.js',
      'exam-prep/exam-prep-host.js','exam-prep/exam-prep-live.js',
      'exam-prep/exam-prep-written-understanding-ui.js'])
      await page.addScriptTag({path:path.resolve(file)});
    const opened=await page.evaluate(async lang=>{
      const sync=await window.iClubExamPrep.syncSubjectHub({subjectKey:'mathematics',language:lang});
      const open=await window.iClubExamPrep.open({subjectKey:'mathematics',language:lang});
      return{sync,open};
    },lang);
    assert(opened.sync&&opened.open,'Math host did not start');
    await page.locator('[data-ep-live-component="'+component+'"]').click();
    const timedLink=page.locator('[data-ep-component-link="timed"]');
    try {await timedLink.waitFor({timeout:7000,state:'visible'});}
    catch(err) {
      const probe=await page.evaluate(()=>({
        text:(document.querySelector('#exam-prep-host-root')?.innerText||'').slice(0,2400),
        route:(document.querySelector('#exam-prep-host-root')?.innerHTML||'').slice(0,1400),
        rpc:window.__hybridTrace||[]
      }));
      console.error('S4 COMPONENT NAV DIAGNOSTIC',lang,component,JSON.stringify(probe));
      throw err;
    }
    await timedLink.click();
    const catalog=page.locator('[data-ep-hybrid-s4-catalog]');
    await catalog.waitFor({timeout:20000});
    const tt=await catalog.textContent();
    const localTitle=lang==='ru'?'Тренировочный Paper':
                     lang==='uz'?'Sinov Paper':'Practice Paper';
    assert(tt.includes(localTitle),'localized Paper title missing '+lang);
    assert.equal(await catalog.locator('[data-ep-hybrid-s4-start]').count()>=1,true);
    await catalog.locator('[data-ep-hybrid-s4-start]').first().click();
    const paper=page.locator('[data-ep-hybrid-s4-paper]');
    await paper.waitFor({timeout:20000});
    const questionCount=await paper.locator('[data-ep-hybrid-s4-item]').count();
    assert.equal(questionCount,component==='P1'?10:7,'full Paper question count '+lang);
    assert.equal(await paper.locator('textarea[name="ep_live_written_answer"]').count(),0,
       'student must never type a long mathematical solution');
    assert.equal(await paper.locator('[data-ep-written-self-mark],input[type=number]').count(),0,
      'no self-awarded exam mark input');
    assert(await paper.locator('[data-ep-hybrid-s4-clock]').textContent(),
      'real server-based deadline should display countdown');
    assert(!(await paper.textContent()).includes('0 / 75'),'do not present fake Paper mark');
    const layout=await page.evaluate(()=>({
     screen:document.documentElement.clientWidth,
     body:document.documentElement.scrollWidth
    }));
    assert(layout.body<=layout.screen+3,'horizontal page overflow '+lang+' '+JSON.stringify(layout));
    await paper.locator('[data-ep-hybrid-s4-finish]').click();
    const checks=page.locator('[data-ep-hybrid-s4-checks]');
    await checks.waitFor({timeout:20000});
    const resultText=await checks.textContent();
    assert(resultText.includes(lang==='ru'?'Баллы за Paper не определены':
      lang==='uz'?'Paper uchun baho aniqlanmagan':'Full Paper mark is unknown'),
      'after full Paper user must see honest unmarked writing '+lang);
    if(component==='P1'){
      const btn=checks.locator('[data-ep-hybrid-s4-check]').first();
      assert(await btn.count(),'synthetic disposable-only numeric checkpoint absent');
      await checks.locator('[data-ep-hybrid-s4-answer]').first().fill('1/2');
      await btn.click();
      await page.waitForFunction(()=>[...(window.__hybridTrace||[])].some(x=>
        x.name==='check_exam_prep_hybrid_s4_final_safe_v1'&&x.ok),null,{timeout:20000});
      assert((await checks.textContent()).includes(lang==='ru'?'Совпало':'Matches'));
    }else{
      assert.equal(await checks.locator('[data-ep-hybrid-s4-check]').count(),0,
        'P5 has no academically approved numeric checks; skip must work');
    }
    await checks.locator('[data-ep-hybrid-s4-reveal]').click();
    const review=page.locator('[data-ep-hybrid-s4-review]');
    await review.waitFor({timeout:20000});
    assert.equal(await review.locator('.ep-live-question-card').count(),component==='P1'?10:7);
    assert.equal(await review.locator('[data-ep-hybrid-s4-answer]').count(),0,
     'after criteria reveal no new independent answer check');
    const reviewText=await review.textContent();
    assert(reviewText.includes(lang==='ru'?'Письменные решения не проверены':
      lang==='uz'?'Yozma yechim tekshirilmagan':'Written methods have not been checked'));
    assert(reviewText.includes(lang==='ru'?'Критерии':lang==='uz'?'Mezonlar':'Criteria'));
    assert(!reviewText.includes('58/75')&&!reviewText.includes('M1 / A1'),
     'no invented written marks, self-marking or examiner');
    assert.equal(errors.length,0,'browser JavaScript errors '+lang+': '+errors.join(';'));
    const http=await page.evaluate(()=>window.__hybridTrace);
    for(const name of ['get_exam_prep_hybrid_s4_papers_safe_v1',
      'start_exam_prep_hybrid_s4_paper_safe_v1',
      'finish_exam_prep_hybrid_s4_paper_safe_v1',
      'reveal_exam_prep_hybrid_s4_review_safe_v1'])
     assert(http.some(x=>x.name===name&&x.ok),'missing signed real '+name+' '+lang);
    console.log('S4 Chromium hybrid '+lang+' '+component+' PASS: full paper on notebook, '+
       'honest unknown marks, optional pre-reveal-only check, source review, responsive width '+width);
   }finally{await page.close()}
  }
 }finally{await browser.close()}
}
run().catch(e=>{console.error('S4 CHROMIUM FAIL:',e.stack||e);process.exitCode=1});
