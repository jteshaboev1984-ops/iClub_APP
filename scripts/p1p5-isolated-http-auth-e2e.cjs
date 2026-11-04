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
async function browserScenario(browser,component,token,mode='diagnostic'){
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
   for(const p of [
     'exam-prep/exam-prep-api.js',
     'exam-prep/exam-prep-host.js',
     'exam-prep/exam-prep-live.js',
     // API script dynamic loaders do not run for Playwright inline addScriptTag.
     // Explicitly load the production companion written-understanding module.
     'exam-prep/exam-prep-written-understanding-ui.js'
   ]){
     await page.addScriptTag({path:path.resolve(p)});
   }
   assert.equal(await page.evaluate(()=>window.__iclubExamPrepWrittenUnderstanding),
     'written-understanding-v1','real Math written-understanding companion not mounted');
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
   if(mode==='learning'){
     await page.locator('[data-ep-component-primary="task"],[data-ep-component-primary="prepare"]').first().waitFor({timeout:25000});
     await page.locator('[data-ep-component-primary="task"],[data-ep-component-primary="prepare"]').first().click();
   }else{
     // Current Math component card starts Stage-0 automatically; older
     // compatible releases also expose an explicit Start control.
     await page.waitForFunction(()=>Boolean(
       document.querySelector('[data-ep-live-active-assessment="true"]') ||
       document.querySelector('[data-ep-component-primary="diagnostic"]')
     ),null,{timeout:25000});
     if(await page.locator('[data-ep-component-primary="diagnostic"]').count()){
       await page.locator('[data-ep-component-primary="diagnostic"]').click();
     }
   }
   await page.locator('[data-ep-live-active-assessment="true"]').waitFor({timeout:25000});
   const trace=await page.evaluate(()=>window.__realRpcTrace);
   const start=trace.findLast(x=>x.name===(mode==='learning'
     ? 'start_exam_prep_session_safe_v1':'start_exam_prep_next_diagnostic_safe_v1'));
   assert(start?.ok&&start.session_id,mode+' start had no durable HTTP session');
   sessionId=start.session_id;
   // Assessment size is authoritative. Later diagnostic waves can contain many
   // more questions than the first wave; never assume an 8/36-item fixture.
   const frozen=await rpc('get_exam_prep_session_safe_v1',
     {p_session_id:sessionId,p_language:'en'},token);
   const expectedItems=Number(frozen.data?.total_items||frozen.data?.items?.length||0);
   assert(frozen.ok&&expectedItems>=1&&expectedItems<=240,
     'invalid server-owned assessment length '+component+'/'+mode+'/'+expectedItems);
   // Actual browser controls submit each question; answers are intentionally
   // arbitrary. The authoritative database evaluates them, not this script.
   for(let i=0;i<=expectedItems;i++){
     const question=page.locator('[data-ep-live-active-assessment="true"]');
     if(!await question.count()) break;
     // Do not count the same on-screen question twice just because the HTTP
     // submit returned before the asynchronous getSession/re-render finished.
     const previousHeader=await page.locator('.ep-focus-head').textContent();
     const radio=page.locator('input[name="ep_live_answer"]');
     const input=page.locator('input[name="ep_live_text_answer"]');
     const written=page.locator('textarea[name="ep_live_written_answer"]');
     const next=page.locator('[data-ep-written-next]');
     if(await next.count()){await next.click();}
     else{
       if(await radio.count()){await radio.first().check();}
       else if(await input.count()){await input.fill('1');}
       else if(await written.count()){
         await written.fill('Synthetic isolated answer; no verified credit');
         // A real published Math learning pack may require noncredit companion
         // understanding MCQs before the written artifact can be submitted.
         // Reproduce the production UI, not a synthetic server bypass.
         await page.waitForTimeout(30);
         const checkGroups=page.locator('[data-ep-written-understanding-check]');
         for(let n=0;n<await checkGroups.count();n++){
           await checkGroups.nth(n).locator('input[type="radio"]').first().check();
         }
       }
       else throw Error('unsupported Math assessment UI item control');
       await page.locator('[data-ep-live-submit]').click();
     }
     count++;
     // Wait for the actual learner-visible advancement (or finalization),
     // not just a submit ACK. Otherwise a slow HTTP read can lead to clicking
     // the same MCQ several times while the previous response is processing.
     await page.waitForFunction(({previousHeader})=>{
       const t=window.__realRpcTrace||[];
       const finalized=t.some(v=>
         (v.name==='finalize_exam_prep_session_safe_v1'||v.name==='finalize_exam_prep_session_written_v1')&&v.ok);
       const header=document.querySelector('.ep-focus-head')?.textContent||'';
       return finalized || (header!==previousHeader && Boolean(header));
     },{previousHeader},{timeout:25000});
     const current=await page.evaluate(()=>window.__realRpcTrace);
     const failed=current.find(x=>!x.ok&&['submit_exam_prep_response_safe_v1','finalize_exam_prep_session_safe_v1'].includes(x.name));
     assert(!failed,'server failed diagnostic action '+failed?.name+' HTTP '+failed?.status);
     if(current.some(x=>x.name==='finalize_exam_prep_session_safe_v1'&&x.ok)) break;
   }
   // The final learner response is ACKed before the client finishes its
   // additional written-state refresh and asynchronous session finalization.
   // Do not mistake a valid delayed finalizer for a failed attempt.
   const finalizerNames=['finalize_exam_prep_session_safe_v1','finalize_exam_prep_session_written_v1'];
   await page.waitForFunction(names=>(window.__realRpcTrace||[]).some(x=>names.includes(x.name)&&x.ok),
     finalizerNames,{timeout:30000});
   recorded=await page.evaluate(()=>window.__realRpcTrace);
   assert(count>0,'no real submitted answers');
   assert(recorded.some(x=>x.name==='submit_exam_prep_response_safe_v1'&&x.ok)||
          recorded.some(x=>x.name==='advance_exam_prep_written_step_safe_v1'&&x.ok),
     'no real HTTP committed response or written step');
   assert(recorded.some(x=>finalizerNames.includes(x.name)&&x.ok),
     'no real HTTP finalization after '+count+'/'+expectedItems+' items in '+component+'/'+mode);
   assert.equal(errors.length,0,'browser errors: '+errors.join(';'));
   return {component,mode,answers:count,sessionId,profileSet,httpActions:recorded.filter(x=>x.ok).length};
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
    // A first completed diagnostic is not necessarily complete Stage 0.
    // Continue only through authentic server-selected next assessments until
    // the server confirms coverage, never force a stage or fabricate evidence.
    const screenings={P1:[],P5:[]};
    for(const component of ['P1','P5']){
      let complete=false;
      for(let cycle=0;cycle<24;cycle++){
        const before=await rpc('get_exam_prep_diagnostic_progress_safe_v1',{p_component_code:component},tokenA);
        assert(before.ok,'diagnostic progress HTTP failure '+component);
        if(before.data?.stage0_complete){complete=true;break;}
        screenings[component].push(await browserScenario(browser,component,tokenA));
        const after=await rpc('get_exam_prep_diagnostic_progress_safe_v1',{p_component_code:component},tokenA);
        assert(after.ok,'diagnostic progress postflight HTTP failure '+component);
        if(after.data?.stage0_complete){complete=true;break;}
      }
      assert(complete,'governed Stage 0 did not complete through real HTTP/browser for '+component);
    }
    const p1=screenings.P1[0],p5=screenings.P5[0];
    assert(p1&&p5,'both papers require at least one actual screening session');
    const unauthorized=await rpc('get_exam_prep_session_safe_v1',{p_session_id:p1.sessionId,p_language:'en'},tokenB);
    assert(!unauthorized.ok||!unauthorized.data?.items?.length,'User B accessed user A P1 session');
    assert.notEqual(p1.sessionId,p5.sessionId,'P1/P5 session identity collision');
    // Move across the real public HTTP API into independent governed plans.
    const planIds={};
    for(const component of ['P1','P5']){
      const generated=await rpc('generate_exam_prep_weekly_plan_safe_v3',{p_component_code:component},tokenA);
      assert(generated.ok&&generated.data?.plan_id,'real HTTP plan generation failed '+component+' status='+generated.status+' code='+generated.data?.code);
      const read=await rpc('get_exam_prep_weekly_plan_safe_v2',{p_component_code:component},tokenA);
      assert(read.ok&&read.data?.plan_id===generated.data.plan_id,'real HTTP plan readback mismatch '+component);
      assert(read.data?.items?.some(i=>i.item_type==='learning'&&i.status==='pending'),'no governed learning item '+component);
      planIds[component]=generated.data.plan_id;
    }
    assert.notEqual(planIds.P1,planIds.P5,'P1/P5 plans unexpectedly share identity');
    // Plan periods now consume ONE Math hours budget across P1/P5. This
    // checks genuine authenticated RPCs, not a separate fake lesson generator.
    const shares={};
    for(const component of ['P1','P5']){
      const b=await rpc('ensure_my_exam_prep_weekly_budget_safe_v1',{
        p_component_code:component,p_plan_id:planIds[component]
      },tokenA);
      assert(b.ok && b.data?.contract_version==='exam_prep_shared_weekly_available_time_v1',
        'Owner weekly capacity failed: '+component+' '+JSON.stringify(b.data));
      const row=b.data;
      assert.equal(row.available_math_minutes,
        row.p1_reserved_minutes+row.p5_reserved_minutes,
        'P1/P5 double-counted chosen Math weekly time');
      assert.equal(row.component_available_minutes,
        component==='P1'?row.p1_reserved_minutes:row.p5_reserved_minutes,
        'Component time is inconsistent with the shared snapshot');
      assert(row.priority_slots?.length>=1 && row.priority_slots.length<=3,
        'Visible budget must attach to actual governed plan priorities');
      assert(row.priority_slots.reduce((a,x)=>a+x.available_study_minutes,0)
        <=row.component_available_minutes,
        'Priorities assigned more available time than the component budget');
      assert(row.priority_minutes_are_available_time_not_task_duration===true &&
        row.learning_access_capped===false && row.academic_results_mutated===false,
        'A planning preference became an academic grade or access quota');
      shares[component]=row;
    }
    assert.equal(shares.P1.available_math_minutes,shares.P5.available_math_minutes,
      'P1/P5 did not share the same weekly Mathematics budget');
    assert.equal(shares.P1.p1_reserved_minutes,shares.P5.p1_reserved_minutes,
      'P1/P5 produced incompatible allocations across one week');
    const repeated=await rpc('ensure_my_exam_prep_weekly_budget_safe_v1',{
      p_component_code:'P1',p_plan_id:planIds.P1
    },tokenA);
    assert(repeated.ok && repeated.data.p1_reserved_minutes===shares.P1.p1_reserved_minutes,
      'Reopening the same weekly plan silently changed its budget');
    const stolen=await rpc('ensure_my_exam_prep_weekly_budget_safe_v1',{
      p_component_code:'P1',p_plan_id:planIds.P1
    },tokenB);
    assert(!stolen.ok,'Another learner could read/record the owner weekly budget');
    const learningP1=await browserScenario(browser,'P1',tokenA,'learning');
    const learningP5=await browserScenario(browser,'P5',tokenA,'learning');
    assert.notEqual(learningP1.sessionId,learningP5.sessionId,'learning session ID collision');
    const own1=await rpc('get_exam_prep_session_safe_v1',{p_session_id:p1.sessionId,p_language:'en'},tokenA);
    const own5=await rpc('get_exam_prep_session_safe_v1',{p_session_id:p5.sessionId,p_language:'en'},tokenA);
    assert(own1.ok&&own5.ok,'reopened owner sessions unavailable');
    assert.equal(own1.data?.component_code,'P1','P1 session replay mismatch');
    assert.equal(own5.data?.component_code,'P5','P5 session replay mismatch');
    const states=dbCount();
    const counts=Object.fromEntries(states.split('\n').filter(Boolean).map(x=>{
      const [component,status,n]=x.split(':');return [component+':'+status,Number(n)];
    }));
    assert(counts['P1:finalized']>=screenings.P1.length+1 &&
           counts['P5:finalized']>=screenings.P5.length+1,
      'authoritative PostgreSQL missing screening cycles + learning: '+states);
    console.log('ISOLATED REAL HTTP/JWT/PostgREST/PG17 + TRUE Math UI: PASS',
      JSON.stringify({screeningCount:{P1:screenings.P1.length,P5:screenings.P5.length},p1,p5,
        learningP1,learningP5,plansSeparate:true,anonDenied:true,foreignDenied:true,sqlStates:states}));
  }finally{await browser.close();}
})().catch(e=>{console.error('E2E FAILED:',e.message);process.exitCode=1;});
