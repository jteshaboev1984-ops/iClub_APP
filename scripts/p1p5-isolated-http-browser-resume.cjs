#!/usr/bin/env node
'use strict';
// CI-only real Math UI -> HTTP/JWT -> PostgREST -> disposable PG17.
// Prove lost ACK reconciliation and browser reload resumes the SAME session.
// This suite deliberately does not modify production, skip academic gates, or
// substitute a mock successful RPC response.
const assert=require('node:assert/strict');
const crypto=require('node:crypto');
const path=require('node:path');
const {execFileSync}=require('node:child_process');
const {chromium}=require('playwright');
const HOST='http://127.0.0.1:3000', A='11111111-1111-4111-8111-111111111191';
const secret=process.env.P1P5_E2E_JWT_SECRET;
assert(process.env.CI==='true'&&process.env.P1P5_E2E_ISOLATED==='true'&&process.env.PGHOST==='127.0.0.1'&&process.env.PGPORT==='5432','REFUSED: requires disposable local CI postgres');
assert(secret&&secret.length>=32,'REFUSED: no ephemeral JWT key');
const enc=obj=>Buffer.from(JSON.stringify(obj)).toString('base64url');
function tokenFor(uid){
 const head=enc({alg:'HS256',typ:'JWT'})+'.'+enc({role:'authenticated',aud:'authenticated',sub:uid,iat:Math.floor(Date.now()/1000),exp:Math.floor(Date.now()/1000)+1800});
 return head+'.'+crypto.createHmac('sha256',secret).update(head).digest('base64url');
}
const token=tokenFor(A);
async function rpc(name,args={}){
 const res=await fetch(HOST+'/rpc/'+name,{method:'POST',headers:{'Content-Type':'application/json',Authorization:'Bearer '+token},body:JSON.stringify(args)});
 const raw=await res.text();let data=null;try{data=raw?JSON.parse(raw):null}catch{}
 return {ok:res.ok,status:res.status,data,code:res.ok?'':data?.message||data?.code};
}
function sqlScalar(sql){
 assert(/^select\s/i.test(sql),'REFUSED read-only query only');
 const val=execFileSync('psql',['-X','-At','-v','ON_ERROR_STOP=1','-c',sql],{encoding:'utf8'}).trim();
 return val;
}
function totalResponses(id){
 assert(/^[0-9a-f-]{36}$/.test(id),'invalid test id');
 return Number(sqlScalar("select count(*) from private.exam_prep_responses where user_id='"+A+"'::uuid and session_id='"+id+"'::uuid"));
}
async function bootPage(browser,simulateLostAck=false){
 const context=await browser.newContext({viewport:{width:390,height:844},timezoneId:'Asia/Tashkent'});
 const page=await context.newPage();const errors=[];page.on('pageerror',e=>errors.push(e.message));
 await page.route(HOST+'/',route=>route.fulfill({status:200,contentType:'text/html',
  body:'<!doctype html><html lang="en"><head><meta name="viewport" content="width=device-width,initial-scale=1"></head><body><section id="courses-subject-hub"><div id="subject-hub-exam-prep-entry" hidden aria-hidden="true"><span id="subject-hub-exam-prep-title"></span><span id="subject-hub-exam-prep-sub"></span></div><div id="exam-prep-host-root" hidden aria-hidden="true"></div></section></body></html>'}));
 await page.goto(HOST+'/');
 await page.addStyleTag({path:path.resolve('exam-prep/exam-prep-host.css')});
 await page.evaluate(({token,simulateLostAck})=>{
   window.__trace=[];window.__ackDropped=false;
   window.sb={rpc:async(name,args={})=>{
     const res=await fetch('/rpc/'+name,{method:'POST',headers:{'Content-Type':'application/json',Authorization:'Bearer '+token},body:JSON.stringify(args)});
     const txt=await res.text();let data=null;try{data=txt?JSON.parse(txt):null}catch{}
     const realOK=res.ok;
     window.__trace.push({name,ok:realOK,status:res.status,session_id:data?.session_id||null});
     if(simulateLostAck && name==='submit_exam_prep_response_safe_v1' && realOK && !window.__ackDropped){
       window.__ackDropped=true;
       // A genuinely committed SQL response loses ONLY its client ACK.
       // Do not forge success or make a second server request.
       return {data:null,error:{code:'NETWORK_ACK_LOST',message:'Simulated lost ACK after real commit'}};
     }
     return realOK?{data,error:null}:{data:null,error:{code:data?.code||String(res.status),message:data?.message||'server_failure'}};
   }};
   window.i18n={getLang:()=> 'en'};
 },{token,simulateLostAck});
 for(const src of ['exam-prep/exam-prep-api.js','exam-prep/exam-prep-host.js','exam-prep/exam-prep-live.js','exam-prep/exam-prep-written-understanding-ui.js']){
   await page.addScriptTag({path:path.resolve(src)});
 }
 const opened=await page.evaluate(async()=>{
   const sync=await window.iClubExamPrep.syncSubjectHub({subjectKey:'mathematics',language:'en'});
   const open=await window.iClubExamPrep.open({subjectKey:'mathematics',language:'en'});
   return {sync,open};
 });
 assert(opened.sync&&opened.open,'real math app failed to open');
 return {context,page,errors};
}
async function openComponent(page,component){
 await page.locator('[data-ep-live-component="'+component+'"]').waitFor({timeout:25000});
 await page.locator('[data-ep-live-component="'+component+'"]').click();
 await page.locator('[data-ep-component-primary]').waitFor({timeout:25000});
}
async function clickOneAnswer(page){
 const head=await page.locator('.ep-focus-head').textContent();
 const radio=page.locator('input[name="ep_live_answer"]');
 const inp=page.locator('input[name="ep_live_text_answer"]');
 const written=page.locator('textarea[name="ep_live_written_answer"]');
 const next=page.locator('[data-ep-written-next]');
 if(await next.count()){await next.click();}
 else{
   if(await radio.count())await radio.first().check();
   else if(await inp.count())await inp.fill('1');
   else if(await written.count()){
     await written.fill('Isolated synthetic written practice, no examiner mark');
     const checks=page.locator('[data-ep-written-understanding-check]');
     for(let i=0;i<await checks.count();i++)await checks.nth(i).locator('input[type="radio"]').first().check();
   }else throw Error('No answer control in actual Math UI');
   await page.locator('[data-ep-live-submit]').click();
 }
 await page.waitForFunction(({head})=>{
   const txt=document.querySelector('.ep-focus-head')?.textContent||'';
   return Boolean(txt && txt!==head) ||
     Boolean(document.querySelector('[data-ep-live-result]')) ||
     (window.__trace||[]).some(x=>/finalize_exam_prep_session.*v1/.test(x.name)&&x.ok);
 },{head},{timeout:30000});
}
(async()=>{
 const browser=await chromium.launch({headless:true});
 let before,after;
 try{
   // P5 has remaining governed learning after the earlier 7 diagnostics and
   // first published learning sessions. We must not create direct DB sessions.
   before=await bootPage(browser,true);
   await openComponent(before.page,'P5');
   const action=before.page.locator('[data-ep-component-primary]');
   const kind=await action.getAttribute('data-ep-component-primary');
   assert(['task','prepare'].includes(kind),'no authorized P5 learning entry, got '+kind);
   await action.click();
   await before.page.locator('[data-ep-live-active-assessment="true"]').waitFor({timeout:25000});
   const start=await before.page.evaluate(()=>(window.__trace||[]).findLast(t=>t.name==='start_exam_prep_session_safe_v1'&&t.ok));
   assert(start?.session_id,'real P5 UI failed to start governed plan session');
   const id=start.session_id;
   assert.equal(totalResponses(id),0,'fresh active session already has responses');
   await clickOneAnswer(before.page);
   const first=await before.page.evaluate(()=>({dropped:window.__ackDropped,trace:window.__trace}));
   assert(first.dropped,'test did not inject lost ACK after durable HTTP commit');
   assert.equal(totalResponses(id),1,'lost ACK created missing/duplicate responses in DB');
   const stateBefore=await rpc('get_exam_prep_session_safe_v1',{p_session_id:id,p_language:'en'});
   assert(stateBefore.ok&&stateBefore.data.status==='active','expected partially completed server session');
   assert.equal(stateBefore.data.items.filter(x=>x.answered===true).length,1,'server does not confirm first response');
   await before.context.close();

   // A completely new browser tab/context keeps NO localStorage/session state;
   // recover strictly by same user's authenticated server state.
   after=await bootPage(browser,false);
   await openComponent(after.page,'P5');
   const newAction=after.page.locator('[data-ep-component-primary]');
   const resumedKind=await newAction.getAttribute('data-ep-component-primary');
   assert.equal(resumedKind,'resume','Math P5 UI did not offer resume for active server-owned session');
   await newAction.click();
   await after.page.locator('[data-ep-live-active-assessment="true"]').waitFor({timeout:25000});
   const readback=await after.page.evaluate(()=>window.__trace.findLast(x=>x.name==='get_exam_prep_session_safe_v1'&&x.ok));
   assert.equal(readback?.session_id,id,'reload created or accessed a DIFFERENT session');
   const current=await rpc('get_exam_prep_session_safe_v1',{p_session_id:id,p_language:'en'});
   assert(current.ok&&current.data.items.filter(x=>x.answered===true).length===1,'reload changed academic responses');
   assert.equal(totalResponses(id),1,'reload duplicated initial answer');
   assert.equal(after.errors.length,0,'browser errors on reload: '+after.errors.join(' | '));
   console.log('STAGE B REAL HTTP LOST-ACK + FRESH-BROWSER RESUME PASS',JSON.stringify({component:'P5',lostAckReconciled:true,serverCommittedExactlyOnce:true,newBrowserContext:true,sessionPreserved:true,completedItems:1,actualUiResume:true}));
 }finally{
   await before?.context.close().catch(()=>{});
   await after?.context.close().catch(()=>{});
   await browser.close();
 }
})().catch(e=>{console.error('REAL HTTP BROWSER RESUME FAILED:',e.message);process.exitCode=1});
