#!/usr/bin/env node
'use strict';
// S4 OFF beta guard: signed owner, real local PostgREST and Chromium.
// Disposable PostgreSQL17 ONLY. No sessions created or student scores changed.
const assert=require('node:assert/strict');
const crypto=require('node:crypto');
const path=require('node:path');
const {chromium}=require('playwright');
assert(process.env.CI==='true'&&process.env.P1P5_E2E_ISOLATED==='true'&&
  process.env.PGHOST==='127.0.0.1'&&process.env.PGDATABASE==='postgres',
  'S4 OFF browser REFUSED outside isolated PostgreSQL17');
const SECRET=process.env.P1P5_E2E_JWT_SECRET;assert(SECRET&&SECRET.length>=32);
const enc=x=>Buffer.from(JSON.stringify(x)).toString('base64url');
const payload=enc({alg:'HS256',typ:'JWT'})+'.'+enc({aud:'authenticated',
  role:'authenticated',sub:'11111111-1111-4111-8111-111111111191',
  iat:Math.floor(Date.now()/1000),exp:Math.floor(Date.now()/1000)+1800});
const token=payload+'.'+crypto.createHmac('sha256',SECRET).update(payload).digest('base64url');
const HOST='http://127.0.0.1:3000';
(async()=>{
 const browser=await chromium.launch({headless:true});
 try{
  const page=await browser.newPage({viewport:{width:390,height:844}});
  const errors=[];page.on('pageerror',e=>errors.push(e.message));
  await page.route(HOST+'/',route=>route.fulfill({status:200,contentType:'text/html',
    body:'<!doctype html><html lang="ru"><head><meta name="viewport" content="width=device-width,initial-scale=1"></head><body><section id="courses-subject-hub"><div id="subject-hub-exam-prep-entry" hidden aria-hidden="true"><span id="subject-hub-exam-prep-title"></span><span id="subject-hub-exam-prep-sub"></span></div><div id="exam-prep-host-root" hidden aria-hidden="true"></div></section></body></html>'}));
  await page.goto(HOST+'/');
  await page.addStyleTag({path:path.resolve('exam-prep/exam-prep-host.css')});
  await page.evaluate(({token})=>{
    delete window.iClubExamPrepHybridPaperS4Enabled;
    window.__offTrace=[];
    window.sb={rpc:async(name,args={})=>{
      const res=await fetch('/rpc/'+name,{method:'POST',headers:{
        'Content-Type':'application/json',Authorization:'Bearer '+token
      },body:JSON.stringify(args)});
      let data=null;try{data=await res.json()}catch{}
      window.__offTrace.push({name,ok:res.ok,enabled:data?.enabled});
      return res.ok?{data,error:null}:{data:null,error:{code:data?.code||String(res.status),message:data?.message||'error'}};
    }};
    window.i18n={getLang:()=> 'ru'};
  },{token});
  for(const file of ['exam-prep/exam-prep-api.js','exam-prep/exam-prep-host.js',
   'exam-prep/exam-prep-live.js','exam-prep/exam-prep-written-understanding-ui.js'])
   await page.addScriptTag({path:path.resolve(file)});
  const opened=await page.evaluate(async()=>{
   const sync=await window.iClubExamPrep.syncSubjectHub({subjectKey:'mathematics',language:'ru'});
   const open=await window.iClubExamPrep.open({subjectKey:'mathematics',language:'ru'});
   return {sync,open};
  });
  assert(opened.sync&&opened.open,'existing beta Mathematics Core must open when S4 OFF');
  await page.locator('[data-ep-live-open-component]').first().waitFor({timeout:20000});
  assert.equal(await page.locator('[data-ep-hybrid-s4-dashboard]').count(),0,
    'global S4 OFF must hide all optional Paper dashboard entry');
  assert.equal(await page.locator('[data-ep-hybrid-s4-dashboard-open]').count(),0,
    'no hidden start buttons when S4 is disabled');
  const trace=await page.evaluate(()=>window.__offTrace);
  for(const component of ['P1','P5']){
    const hits=trace.filter(x=>x.name==='get_exam_prep_hybrid_s4_papers_safe_v1');
    assert(hits.length>=2,'both P1 and P5 server-checked before hiding Paper');
    assert(hits.every(x=>x.ok&&x.enabled===false),'no client override of server-OFF S4');
  }
  const profile=await page.locator('#exam-prep-host-root').textContent();
  assert(profile.includes('P1')&&profile.includes('P5'),'normal Core cards remain visible');
  assert.deepEqual(errors,[],'no browser runtime errors while Paper OFF');
  console.log('S4 beta OFF Chromium/JWT/PG17 PASS: Core P1/P5 visible, server-disabled Paper hidden, no browser flag, no data writes.');
  await page.close();
 }finally{await browser.close();}
})().catch(e=>{console.error(e.stack||e);process.exitCode=1});
