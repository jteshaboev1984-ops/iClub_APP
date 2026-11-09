#!/usr/bin/env node
'use strict';
// True Math dashboard + owner JWT/PostgREST/PG17. No production, mock RPC success, grades or manual scores.
const assert=require('node:assert/strict'),crypto=require('node:crypto'),
 path=require('node:path'),{chromium}=require('playwright');
const HOST='http://127.0.0.1:3000';
assert(process.env.CI==='true' && process.env.P1P5_E2E_ISOLATED==='true'
 && process.env.PGHOST==='127.0.0.1' && process.env.PGDATABASE==='postgres',
 'S3 browser refused outside disposable PostgreSQL 17');
const secret=process.env.P1P5_E2E_JWT_SECRET; assert(secret?.length>=32);
const b=x=>Buffer.from(JSON.stringify(x)).toString('base64url');
const part=b({alg:'HS256',typ:'JWT'})+'.'+b({aud:'authenticated',
 role:'authenticated',sub:'11111111-1111-4111-8111-111111111191',
 iat:Math.floor(Date.now()/1000),exp:Math.floor(Date.now()/1000)+1800});
const token=part+'.'+crypto.createHmac('sha256',secret).update(part).digest('base64url');
async function main(){
 const browser=await chromium.launch({headless:true});
 try {
 for(const [language,title,width] of [
   ['ru','Недельный план',390],
   ['uz','Haftalik reja',375],
   ['en','Weekly plan',1280]
 ]) {
  const page=await browser.newPage({viewport:{width,height:850},timezoneId:'Asia/Tashkent'});
  const errors=[];page.on('pageerror',e=>errors.push(e.message));
  try {
   await page.route(HOST+'/',route=>route.fulfill({status:200,contentType:'text/html',
    body:'<!doctype html><html><head><meta name="viewport" content="width=device-width,initial-scale=1"></head><body><section id="courses-subject-hub"><div id="subject-hub-exam-prep-entry" hidden aria-hidden="true"><span id="subject-hub-exam-prep-title"></span><span id="subject-hub-exam-prep-sub"></span></div><div id="exam-prep-host-root" hidden aria-hidden="true"></div></section></body></html>'}));
   await page.goto(HOST+'/');
   await page.addStyleTag({path:path.resolve('exam-prep/exam-prep-host.css')});
   await page.evaluate(({token,language})=>{
    window.__s3Requests=[];
    window.sb={rpc:async(name,args={})=>{
      const response=await fetch('/rpc/'+name,{method:'POST',
        headers:{'Content-Type':'application/json',Authorization:'Bearer '+token},
        body:JSON.stringify(args)});
      let body=null;try{body=await response.json()}catch{}
      window.__s3Requests.push({name,status:response.status,ok:response.ok});
      return response.ok?{data:body,error:null}:
       {data:null,error:{code:body?.code||String(response.status),message:body?.message||'rejected'}};
    }};
    window.i18n={getLang:()=>language};
   },{token,language});
   for(const file of ['exam-prep/exam-prep-api.js','exam-prep/exam-prep-host.js',
     'exam-prep/exam-prep-live.js','exam-prep/exam-prep-written-understanding-ui.js']){
    await page.addScriptTag({path:path.resolve(file)});
   }
   const opened=await page.evaluate(async language=>{
    await window.iClubExamPrep.syncSubjectHub({subjectKey:'mathematics',language});
    return window.iClubExamPrep.open({subjectKey:'mathematics',language});
   },language);
   assert(opened,'owner Mathematics S3 host did not open');
   const panel=page.locator('[data-ep-s3]');
   await panel.waitFor({timeout:20000});
   assert((await panel.textContent()).includes(title),'missing translated S3 '+language);
   assert.equal(await panel.locator('input[type=radio]').count(),3,'must expose exactly three voluntary choices');
   assert(!(await panel.textContent()).includes('Cambridge grade'),'do not promise official marks');
   // Responsive: the panel must fit horizontally on both narrow phones.
   const dims=await page.evaluate(()=>({
    panel:document.querySelector('[data-ep-s3]').getBoundingClientRect().width,
    screen:document.documentElement.clientWidth,
    overflow:document.documentElement.scrollWidth
   }));
   assert(dims.panel<=dims.screen && dims.overflow<=dims.screen+2,
    'S3 creates horizontal overflow '+language+' '+JSON.stringify(dims));
   if(language==='ru'){
     await panel.locator('input[value=redistribute]').check();
     await panel.locator('[data-ep-s3-p1]').fill('100');
     await panel.locator('[data-ep-s3-p5]').fill('75');
     await panel.locator('[data-ep-s3-save]').click();
     await page.locator('[data-ep-s3]').waitFor({timeout:20000});
     const events=await page.evaluate(()=>window.__s3Requests);
     assert(events.some(x=>x.name==='save_my_exam_prep_weekly_choice_s3_safe_v1'&&x.ok),
      'real HTTP did not save P1/P5 redistribution');
     assert((await page.locator('[data-ep-s3]').textContent()).includes('175'),
      'real selected schedule changed unexpectedly');
   }
   const http=await page.evaluate(()=>window.__s3Requests);
   assert(http.some(x=>x.name==='get_my_exam_prep_weekly_choice_s3_safe_v1'&&x.ok),
    'signed S3 read missing '+language);
   assert.equal(errors.length,0,'browser JavaScript errors '+language+': '+errors.join(';'));
   console.log('S3 mobile/desktop '+language+' PASS: 3 voluntary controls, real owner JWT and no horizontal overflow');
  }finally{await page.close()}
 }
 }finally{await browser.close()}
}
main().catch(e=>{console.error('S3 CHROMIUM FAILED:',e.stack||e);process.exitCode=1;});
