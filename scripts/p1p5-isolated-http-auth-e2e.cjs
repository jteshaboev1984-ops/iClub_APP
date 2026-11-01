#!/usr/bin/env node
'use strict';
// STAGE B: actual Mathematics host + real PostgREST HTTP/JWT -> real isolated
// database functions. No mocked RPC success data, no production hosts, no
// actual learner accounts. This browser RPC transport uses fetch compatible
// with window.sb.rpc; it is NOT the official supabase-js/Auth service.
const assert=require('node:assert/strict');
const path=require('node:path');
const crypto=require('node:crypto');
const {chromium}=require('playwright');
const {execFileSync}=require('node:child_process');
const HOST='http://127.0.0.1:3000';
const A='11111111-1111-4111-8111-111111111191';
const B='22222222-2222-4222-8222-222222222292';
const SECRET=process.env.P1P5_E2E_JWT_SECRET;
assert(process.env.P1P5_E2E_ISOLATED==='true','REFUSED: isolated flag absent');
assert(SECRET && SECRET.length>=32,'REFUSED: disposable JWT secret absent');
assert(!/supabase.co|vercel.app|i-club.app/i.test(HOST),'REFUSED: production host');
const encode=x=>Buffer.from(JSON.stringify(x)).toString('base64url');
function jwt(uid){
 const part=encode({alg:'HS256',typ:'JWT'})+'.'+encode({role:'authenticated',aud:'authenticated',sub:uid,iat:Math.floor(Date.now()/1000),exp:Math.floor(Date.now()/1000)+1800});
 return part+'.'+crypto.createHmac('sha256',SECRET).update(part).digest('base64url');
}
async function rpc(name,args={},token=null){
 const url=HOST+'/rpc/'+name;
 assert(url.startsWith(HOST+'/rpc/'),'REFUSED: external endpoint');
 const response=await fetch(url,{method:'POST',headers:{'Content-Type':'application/json','Accept':'application/json',...(token?{Authorization:'Bearer '+token}:{})},body:JSON.stringify(args)});
 const text=await response.text();let data;
 try{data=text?JSON.parse(text):null;}catch{data=null;}
 return {status:response.status,ok:response.ok,data};
}
function dbCount(){
 const sql=`SELECT component_code||':'||status||':'||count(*) FROM private.exam_prep_sessions WHERE user_id='${A}'::uuid GROUP BY component_code,status ORDER BY component_code,status`;
 return execFileSync('psql',['-At','-v','ON_ERROR_STOP=1','-c',sql],{encoding:'utf8'}).trim();
}
async function browserScenario(browser,component,token){
 const page=await browser.newPage({viewport:{width:390,height:844},timezoneId:'Asia/Tashkent'});
 const errors=[];page.on('pageerror',e=>errors.push(e.message));
 let count=0,sessionId=null,recorded=[],profileSet=false;
 try{
   await page.route(HOST+'/',route=>route.fulfill({status:200,contentType:'text/html',body:'<!doctype html><html lang="en"><head><meta name="viewport" content="width=device-width,initial-scale=1"></head><body><section id="courses-subject-hub"><div id="subject-hub-exam-prep-entry" hidden aria-hidden="true"><span id="subject-hub-exam-prep-title"></span><span id="subject-hub-exam-prep-sub"></span></div><div id="exam-prep-host-root" hidden aria-hidden="true"></div></section></body></html>'}));
   await page.goto(HOST+'/');
   await page.addStyleTag({path:path.resolve('exam-prep/exam-prep-host.css')});
   await page.evaluate(token=>{
     window.__realRpcTrace=[];
     // Only the JavaScript client *transport* is compatible; all results come
     // from actual PostgREST HTTP + JWT + PostgreSQL, never a fixture.
     window.sb={rpc:async(name,args={})=>{
       const response=await fetch('/rpc/'+name,{method:'POST',headers:{'Content-Type':'application/json',Authorization:'Bearer '+token},body:JSON.stringify(args)});
       const text=await response.text();let data=null;
       try{data=text?JSON.parse(text):null;}catch{}
       window.__realRpcTrace.push({name,status:response.status,ok:response.ok,session_id:(data&&data.session_id)||null});
       return response.ok?{data,error:null}:{data:null,error:{code:data?.code||String(response.status),message:data?.message||'server_rejected'}};
     }};
     window.i18n={getLang:()=> 'en'};
   },token);
   for(const p of ['exam-prep/exam-prep-api.js','exam-prep/exam-prep-host.js','exam-prep/exam-prep-live.js']){
     await page.addScriptTag({path:path.resolve(p)});
   }
   const opened=await page.evaluate(async()=>{
     const synced=await window.iClubExamPrep.syncSubjectHub({subjectKey:'mathematics',language:'en'});
     const open=await window.iClubExamPrep.open({subjectKey:'mathematics',language:'en'});
     return {synced,open};
   });
   assert(opened.synced&&opened.open,'Math host did not open via real HTTP capabilities: '+JSON.stringify(opened));
   const profile=page.locator('[data-ep-live-profile-form]');
   if(await profile.count()){
     await page.fill('input[name="exam_series"]','May/June 2027');
     await page.fill('input[name="target_grade"]','A');
     await page.fill('input[name="total_hours"]','12');
     await page.fill('input[name="math_hours"]','6');
     await page.click('[data-ep-live-save-profile]');
     await page.locator('[data-ep-live-component="'+component+'"]').waitFor({timeout:25000});
     profileSet=true;
   }
   await page.locator('[data-ep-live-component="'+component+'"]').click();
   await page.locator('[data-ep-component-primary="diagnostic"]').waitFor({timeout:25000});
   await page.locator('[data-ep-component-primary="diagnostic"]').click();
   await page.locator('[data-ep-live-active-assessment="true"]').waitFor({timeout:25000});
   const trace=await page.evaluate(()=>window.__realRpcTrace);
   const start=trace.findLast(x=>x.name==='start_exam_prep_next_diagnostic_safe_v1');
   assert(start?.ok&&start.session_id,'diagnostic start had no durable HTTP session');
   sessionId=start.session_id;
   // Actual browser controls submit each question; answers are intentionally
   // arbitrary. The authoritative database evaluates them, not this script.
   for(let i=0;i<36;i++){
     const question=page.locator('[data-ep-live-active-assessment="true"]');
     if(!await question.count()) break;
     const radio=page.locator('input[name="ep_live_answer"]');
     const input=page.locator('input[name="ep_live_text_answer"]');
     const written=page.locator('textarea[name="ep_live_written_answer"]');
     const next=page.locator('[data-ep-written-next]');
     if(await next.count()){await next.click();}
     else{
       if(await radio.count()){await radio.first().check();}
       else if(await input.count()){await input.fill('1');}
       else if(await written.count()){await written.fill('Synthetic isolated answer; no verified credit');}
       else throw Error('unsupported Math diagnostic UI item control');
       await page.locator('[data-ep-live-submit]').click();
     }
     count++;
     await page.waitForFunction(expected=>{
       const t=window.__realRpcTrace||[];
       return t.filter(v=>v.name==='submit_exam_prep_response_safe_v1'||v.name==='advance_exam_prep_written_step_safe_v1').length>=expected ||
         t.some(v=>v.name==='finalize_exam_prep_session_safe_v1'&&v.ok);
     },count,{timeout:20000});
     const current=await page.evaluate(()=>window.__realRpcTrace);
     const failed=current.find(x=>!x.ok&&['submit_exam_prep_response_safe_v1','finalize_exam_prep_session_safe_v1'].includes(x.name));
     assert(!failed,'server failed diagnostic action '+failed?.name+' HTTP '+failed?.status);
     if(current.some(x=>x.name==='finalize_exam_prep_session_safe_v1'&&x.ok)) break;
   }
   recorded=await page.evaluate(()=>window.__realRpcTrace);
   assert(count>0,'no real diagnostic answers');
   assert(recorded.some(x=>x.name==='submit_exam_prep_response_safe_v1'&&x.ok),'no real HTTP committed answer');
   assert(recorded.some(x=>x.name==='finalize_exam_prep_session_safe_v1'&&x.ok),'no real HTTP finalization');
   assert.equal(errors.length,0,'browser errors: '+errors.join(';'));
   return {component,answers:count,sessionId,profileSet,httpActions:recorded.filter(x=>x.ok).length};
 }catch(e){
   const trace=await page.evaluate(()=>window.__realRpcTrace||[]).catch(()=>[]);
   console.error('FAIL '+component+': '+e.message,'recent_http_statuses:',JSON.stringify(trace.slice(-12).map(x=>({name:x.name,status:x.status}))));
   throw e;
 }finally{await page.close();}
}
(async()=>{
  const tokenA=jwt(A),tokenB=jwt(B);
  const anon=await rpc('get_exam_prep_capabilities_v1',{});
  assert(anon.status===401||anon.status===403,'anonymous RPC unexpectedly allowed: '+anon.status);
  const bad=await rpc('get_exam_prep_capabilities_v1',{},'malformed.e2e.token');
  assert(bad.status===401||bad.status===403,'invalid JWT unexpectedly accepted: '+bad.status);
  const cap=await rpc('get_exam_prep_capabilities_v1',{},tokenA);
  assert(cap.ok,'signed isolated JWT did not resolve valid capabilities HTTP='+cap.status+' code='+cap.data?.code);
  const browser=await chromium.launch({headless:true});
  try{
    const p1=await browserScenario(browser,'P1',tokenA);
    const unauthorized=await rpc('get_exam_prep_session_safe_v1',{p_session_id:p1.sessionId,p_language:'en'},tokenB);
    assert(!unauthorized.ok||!unauthorized.data?.items?.length,'User B accessed user A P1 session');
    const p5=await browserScenario(browser,'P5',tokenA);
    assert.notEqual(p1.sessionId,p5.sessionId,'P1/P5 session identity collision');
    const own1=await rpc('get_exam_prep_session_safe_v1',{p_session_id:p1.sessionId,p_language:'en'},tokenA);
    const own5=await rpc('get_exam_prep_session_safe_v1',{p_session_id:p5.sessionId,p_language:'en'},tokenA);
    assert(own1.ok&&own5.ok,'reopened owner sessions unavailable');
    assert.equal(own1.data?.component_code,'P1','P1 session replay mismatch');
    assert.equal(own5.data?.component_code,'P5','P5 session replay mismatch');
    const states=dbCount();
    assert(states.includes('P1:finalized:')&&states.includes('P5:finalized:'),'authoritative PostgreSQL did not persist P1/P5 finalization: '+states);
    console.log('ISOLATED REAL HTTP/JWT/PostgREST/PG17 + TRUE Math UI: PASS',JSON.stringify({p1,p5,anonDenied:true,foreignDenied:true,sqlStates:states}));
  }finally{await browser.close();}
})().catch(e=>{console.error('E2E FAILED:',e.message);process.exitCode=1;});
