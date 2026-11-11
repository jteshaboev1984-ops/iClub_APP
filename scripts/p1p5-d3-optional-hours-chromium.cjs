#!/usr/bin/env node
'use strict';
// Issue #450 D3 browser: real signed disposable JWT/PostgREST/PG17.
// No mocked RPC responses, production URLs or production credentials.
const assert=require('node:assert/strict'),crypto=require('node:crypto'),
 path=require('node:path'),{chromium}=require('playwright');
assert(process.env.CI==='true' && process.env.P1P5_E2E_ISOLATED==='true'
 && process.env.PGHOST==='127.0.0.1' && process.env.PGDATABASE==='postgres',
 'D3 browser refused outside isolated PostgreSQL 17');
const secret=process.env.P1P5_E2E_JWT_SECRET;assert(secret?.length>=32);
const b=x=>Buffer.from(JSON.stringify(x)).toString('base64url');
const header=b({alg:'HS256',typ:'JWT'})+'.'+b({aud:'authenticated',
 role:'authenticated',sub:'44444444-4444-4444-8444-444444444494',
 iat:Math.floor(Date.now()/1000),exp:Math.floor(Date.now()/1000)+1800});
const token=header+'.'+crypto.createHmac('sha256',secret).update(header).digest('base64url');
const HOST='http://127.0.0.1:3000';
async function main(){
 const browser=await chromium.launch({headless:true});
 try{
 for(const [language,width] of [['ru',390],['uz',375],['en',1280]]){
   const page=await browser.newPage({viewport:{width,height:900},timezoneId:'Asia/Tashkent'});
   const errors=[];page.on('pageerror',e=>errors.push(e.message));
   try{
    await page.route(HOST+'/',route=>route.fulfill({status:200,contentType:'text/html',
     body:'<!doctype html><html><head><meta name="viewport" content="width=device-width,initial-scale=1"></head><body><section id="courses-subject-hub"><div id="subject-hub-exam-prep-entry" hidden aria-hidden="true"><span id="subject-hub-exam-prep-title"></span><span id="subject-hub-exam-prep-sub"></span></div><div id="exam-prep-host-root" hidden aria-hidden="true"></div></section></body></html>'}));
    await page.goto(HOST+'/');
    await page.addStyleTag({path:path.resolve('exam-prep/exam-prep-host.css')});
    await page.evaluate(({token,language})=>{
      window.sb={rpc:async(name,args={})=>{
        const response=await fetch('/rpc/'+name,{method:'POST',
         headers:{'Content-Type':'application/json',Authorization:'Bearer '+token},
         body:JSON.stringify(args)});
        let body=null;try{body=await response.json()}catch{}
        return response.ok?{data:body,error:null}:
         {data:null,error:{code:body?.code||String(response.status),message:body?.message||'rejected'}};
      }};
      window.i18n={getLang:()=>language};
    },{token,language});
    for(const file of ['exam-prep/exam-prep-api.js','exam-prep/exam-prep-host.js',
      'exam-prep/exam-prep-live.js','exam-prep/exam-prep-written-understanding-ui.js',
      'exam-prep/exam-prep-profile-completeness.js','exam-prep/exam-prep-exam-map.js']){
      await page.addScriptTag({path:path.resolve(file)});
    }
    const opened=await page.evaluate(async language=>{
      await window.iClubExamPrep.syncSubjectHub({subjectKey:'mathematics',language});
      return window.iClubExamPrep.open({subjectKey:'mathematics',language});
    },language);
    assert(opened,'D3 host did not open '+language);
    if(language==='ru'){
      const form=page.locator('[data-ep-live-profile-form]');
      await form.waitFor({timeout:20000});
      const total=form.locator('[name=total_hours]');
      const math=form.locator('[name=math_hours]');
      assert.equal(await total.getAttribute('required'),null,'total hours must be optional');
      assert.equal(await math.getAttribute('required'),null,'Math hours must be optional');
      assert((await form.textContent()).includes('необязательно'),'RU optional label missing');
      await form.locator('[name=exam_series]').fill('May/June 2027');
      await form.locator('[name=target_grade]').fill('A');
      assert.equal(await total.inputValue(),'');
      assert.equal(await math.inputValue(),'');
      await form.locator('[type=submit]').click();
    }
    await page.locator('[data-ep-study-schedule]').waitFor({timeout:20000});
    const planCard=page.locator('[data-ep-exam-plan-card]');
    await planCard.waitFor({timeout:20000});
    assert((await planCard.textContent()).includes(
      {ru:'Пока не выбрано',uz:'Hali tanlanmagan',en:'Not chosen yet'}[language]),
      'legacy exam-plan card cannot show null/0 hours as confirmed');
    assert.equal(await page.locator('[data-ep-profile-completion]').count(),0,
      'legacy completeness overlay must never force weekly hours');
    const daily=page.locator('[data-ep-study-minutes]');
    const days=page.locator('[data-ep-study-days]');
    assert.equal(await daily.inputValue(),'','no invented default daily minutes '+language);
    assert.equal(await days.inputValue(),'','no invented default study days '+language);
    const summary=await page.locator('[data-ep-study-schedule]').textContent();
    const unknown={ru:'Пока не выбрано',uz:'Hali tanlanmagan',en:'Not chosen yet'}[language];
    assert(summary.includes(unknown),'no-budget must show unknown, not zero '+language);
    const weekly=await page.locator('.ep-live-s3').textContent();
    const noBudget={ru:'Недельное время пока не выбрано',
      uz:'Haftalik vaqt hali tanlanmagan',en:'No weekly time has been chosen'}[language];
    assert(weekly.includes(noBudget),'S3 should not demand weekly hours '+language);
    assert.equal(await page.locator('[data-ep-s3-save]').count(),0,'no S3 RPC without chosen budget');
    const bounds=await page.evaluate(()=>({
     doc:document.documentElement.scrollWidth,client:document.documentElement.clientWidth
    }));
    assert(bounds.doc<=bounds.client+2,'D3 horizontal overflow '+language+' '+JSON.stringify(bounds));
    assert.deepEqual(errors,[],'D3 browser page errors '+language);

    if(language==='en'){
      await daily.fill('40');
      await days.selectOption('5');
      const preview=await page.locator('[data-ep-study-preview]').textContent();
      assert(preview.includes('3 h 20 min'),'weekly minutes format wrong '+preview);
      const note=await page.locator('[data-ep-study-schedule]').textContent();
      assert(note.includes('rounded to the nearest minute'),'display note missing');
      await page.locator('[data-ep-study-save]').click();
      await page.locator('[data-ep-s3-save]').waitFor({timeout:20000});
      const body=await page.locator('[data-ep-study-schedule]').textContent();
      assert(body.includes('3 h 20 min'),'saved exact 200-minute display missing');
      assert(body.includes('Not chosen yet'),'overall total must remain unknown');
      assert.equal(await page.locator('[data-ep-s3] input[type=radio]').count(),3);
      const updated=page.locator('[data-ep-exam-plan-card]');
      await updated.waitFor({timeout:20000});
      assert((await updated.textContent()).includes('3 h 20 min'),
        'legacy plan editor card should display rounded minutes, not 3.33h');
      await updated.locator('[data-ep-exam-plan-edit]').click();
      const editor=page.locator('[data-ep-exam-plan-form]');
      await editor.waitFor({timeout:10000});
      assert.equal(await editor.locator('[name=total_hours]').getAttribute('required'),null);
      assert.equal(await editor.locator('[name=math_hours]').getAttribute('required'),null);
      assert.equal(await editor.locator('[name=total_hours]').inputValue(),'');
      await page.locator('[data-ep-exam-plan-cancel]').click();
    }
   }finally{await page.close();}
 }
 console.log('D3 Chromium PG17/JWT PASS: RU/UZ/EN no mandatory weekly hours, empty remains unknown, mobile layout, later 40x5=3h20.');
 }finally{await browser.close();}
}
main().catch(e=>{console.error(e.stack||e);process.exitCode=1;});
