#!/usr/bin/env node
'use strict';
// Real Math P1/P5 Chromium UI -> signed HTTP/JWT -> local PostgREST/PG17.
// On-paper written Core: criteria optional, Next noncredit, lost-ACK handling,
// full browser context reload, RU/UZ/EN, no fabricated essay marks.
const assert=require('node:assert/strict');
const crypto=require('node:crypto');
const path=require('node:path');
const {execFileSync}=require('node:child_process');
const {chromium}=require('playwright');
const HOST='http://127.0.0.1:3000';
const UID='11111111-1111-4111-8111-111111111191';
const SECRET=process.env.P1P5_E2E_JWT_SECRET;
assert(process.env.CI==='true' && process.env.P1P5_E2E_ISOLATED==='true'
 && process.env.PGHOST==='127.0.0.1' && process.env.PGPORT==='5432'
 && process.env.PGDATABASE==='postgres','REFUSED outside isolated CI');
assert(SECRET && SECRET.length>=32,'REFUSED missing local JWT key');
const enc=x=>Buffer.from(JSON.stringify(x)).toString('base64url');
const h=enc({alg:'HS256',typ:'JWT'})+'.'+enc({role:'authenticated',aud:'authenticated',sub:UID,iat:Math.floor(Date.now()/1000),exp:Math.floor(Date.now()/1000)+3600});
const token=h+'.'+crypto.createHmac('sha256',SECRET).update(h).digest('base64url');
const text={
 en:{criteria:'Criteria',next:'Next',unmarked:'not marked automatically'},
 ru:{criteria:'Критерии',next:'Далее',unmarked:'не оценивается автоматически'},
 uz:{criteria:'Baholash mezonlari',next:'Keyingi',unmarked:'avtomatik tekshirilmaydi'}
};
function db(sql){
 assert(/^\s*select\s/i.test(sql),'REFUSED non-SELECT SQL');
 return execFileSync('psql',['-X','-At','-v','ON_ERROR_STOP=1','-c',sql],{encoding:'utf8'}).trim();
}
const count=(table,id,extra='')=>{
 assert(/^[a-f0-9-]{36}$/.test(id));
 return Number(db("select count(*) from private."+table+" where session_id='"+id+"'::uuid"+extra));
};
async function rpc(name,args={},subject=token){
 const response=await fetch(HOST+'/rpc/'+name,{method:'POST',headers:{
  'Content-Type':'application/json',Authorization:'Bearer '+subject
 },body:JSON.stringify(args)});
 let data=null;try{data=await response.json()}catch{}
 return {ok:response.ok,status:response.status,data};
}
async function pageOpen(browser,lang,dropAck=false,viewportWidth=385) {
 const context=await browser.newContext({viewport:{width:viewportWidth,height:viewportWidth>=1000?900:812},timezoneId:'Asia/Tashkent',locale:lang==='uz'?'uz-UZ':lang==='ru'?'ru-RU':'en-GB'});
 const page=await context.newPage();const errors=[];page.on('pageerror',error=>errors.push(error.message));
 await page.route(HOST+'/',route=>route.fulfill({status:200,contentType:'text/html',body:'<!doctype html><html lang="'+lang+'"><head><meta name="viewport" content="width=device-width,initial-scale=1"></head><body><section id="courses-subject-hub"><div id="subject-hub-exam-prep-entry" hidden aria-hidden="true"><span id="subject-hub-exam-prep-title"></span><span id="subject-hub-exam-prep-sub"></span></div><div id="exam-prep-host-root" hidden aria-hidden="true"></div></section></body></html>'}));
 await page.goto(HOST+'/');
 await page.addStyleTag({path:path.resolve('exam-prep/exam-prep-host.css')});
 await page.evaluate(({token,lang,dropAck})=>{
  window.__realWrittenTrace=[];
  window.__lostWrittenAck=false;
  window.i18n={getLang:()=>lang};
  window.sb={rpc:async(name,args={})=>{
   const res=await fetch('/rpc/'+name,{method:'POST',headers:{
    'Content-Type':'application/json',Authorization:'Bearer '+token
   },body:JSON.stringify(args)});
   const raw=await res.text();let data=null;try{data=raw?JSON.parse(raw):null}catch{}
   window.__realWrittenTrace.push({name,ok:res.ok,status:res.status,session_id:data?.session_id||null,item_order:data?.item_order||null});
   if(dropAck && name==='advance_exam_prep_written_step_safe_v1' && res.ok && !window.__lostWrittenAck){
    window.__lostWrittenAck=true;
    return {data:null,error:{code:'NETWORK_ACK_LOST',message:'real SQL committed, client ACK lost'}};
   }
   return res.ok?{data,error:null}:{data:null,error:{code:data?.code||String(res.status),message:data?.message||'server_error'}};
  }};
 },{token,lang,dropAck});
 for(const file of ['exam-prep/exam-prep-api.js','exam-prep/exam-prep-host.js','exam-prep/exam-prep-live.js','exam-prep/exam-prep-written-understanding-ui.js']){
  await page.addScriptTag({path:path.resolve(file)});
 }
 const result=await page.evaluate(async()=>{
  const a=await window.iClubExamPrep.syncSubjectHub({subjectKey:'mathematics',language:window.i18n.getLang()});
  const b=await window.iClubExamPrep.open({subjectKey:'mathematics',language:window.i18n.getLang()});
  return [a,b];
 });
 assert(result.every(Boolean),'real Math Exam Prep UI did not load');
 return {page,context,errors};
}
async function navigateToPlan(page,component,expectedSession) {
 await page.locator('[data-ep-live-component="'+component+'"]').waitFor({timeout:25000});
 await page.locator('[data-ep-live-component="'+component+'"]').click();
 const action=page.locator('[data-ep-component-primary]');
 await action.waitFor({timeout:25000});
 const type=await action.getAttribute('data-ep-component-primary');
 if(expectedSession)assert(type==='resume','refresh did not offer resume for '+component+' got='+type);
 else assert(['task','prepare','resume'].includes(type),'no real learning next action '+component+' type='+type);
 await action.click();
 await page.locator('[data-ep-live-active-assessment="true"]').waitFor({timeout:25000});
 const session=(await page.evaluate(()=>window.__realWrittenTrace.filter(x=>x.ok&&x.name==='get_exam_prep_session_safe_v1').at(-1)))?.session_id;
 if(expectedSession)assert.equal(session,expectedSession,'context reload opened wrong session');
 return {session,type};
}
async function reachWritten(page,sessionId) {
 for(let i=0;i<16;i++){
  if(await page.locator('[data-ep-written-external="true"]').count())return;
  const before=await page.locator('.ep-focus-head').textContent();
  const radio=page.locator('input[name="ep_live_answer"]');
  const textInput=page.locator('input[name="ep_live_text_answer"]');
  const textArea=page.locator('textarea[name="ep_live_written_answer"]');
  if(await textArea.count())throw Error('paper-based written route did not activate for '+sessionId);
  if(await radio.count())await radio.first().check();
  else if(await textInput.count())await textInput.fill('1');
  else throw Error('unexpected academic control before external written step');
  await page.locator('[data-ep-live-submit]').click();
  await page.waitForFunction(({before})=>{
   const heading=document.querySelector('.ep-focus-head')?.textContent||'';
   return (heading && heading!==before) || Boolean(document.querySelector('[data-ep-written-external="true"]'));
  },{before},{timeout:25000});
 }
 throw Error('did not reach a written external step before 16 questions');
}
async function criteriaFor(page,id,component,lang,openCriteria=true) {
 const next=page.locator('[data-ep-written-next]');
 assert(await next.count()===1,'Next action not shown '+component+'/'+lang);
 assert(await page.locator('textarea[name="ep_live_written_answer"]').count()===0,
  'external written solution incorrectly requires typing');
 const toggle=page.locator('[data-ep-written-criteria-toggle]');
 assert(await toggle.count()===1,'criteria toggle missing');
 assert((await toggle.textContent()).includes(text[lang].criteria),'criteria label translation wrong '+component+'/'+lang);
 assert((await next.textContent()).includes(text[lang].next),'Next button translation wrong '+component+'/'+lang);
 const firstText=await page.locator('.ep-written-instruction').textContent();
 assert(firstText?.trim(),'paper-based learner instruction missing');
 // Confirm optional reading DOES NOT write academic evidence.
 const before=count('exam_prep_written_step_advances_v1',id);
 const recorded=await rpc('get_exam_prep_session_written_v1',{p_session_id:id,p_language:lang});
 assert(recorded.ok,'owner lost current written session');
 const item=recorded.data.items.find(x=>x.item_kind==='written'&&x.is_complete!==true);
 assert(item?.written_external===true,'real RPC has no external written flag');
 if (!openCriteria) {
  // P4-08: optional criteria are never needed for independently solved work.
  const hidden=page.locator('[data-ep-written-criteria-panel]');
  assert(await hidden.count()===1 && await hidden.isHidden(),'criteria must start collapsed');
  assert.equal(await toggle.getAttribute('aria-expanded'),'false');
  const reads=await page.evaluate(()=>(window.__realWrittenTrace||[])
    .filter(x=>x.name==='get_exam_prep_written_criteria_safe_v1').length);
  assert.equal(reads,0,'criteria fetched before learner requested them');
  assert.equal(count('exam_prep_written_step_advances_v1',id),before,
    'unopened criteria changed academic progress');
  return {itemOrder:item.item_order,available:null,lang,criteriaOpened:false};
 }
 await toggle.click();
 const panel=page.locator('[data-ep-written-criteria-panel]');
 await panel.waitFor({state:'visible',timeout:15000});
 await page.waitForFunction(()=>document.querySelector('[data-ep-written-criteria-panel]')?.dataset.loading!=='true',null,{timeout:25000});
 const result=await rpc('get_exam_prep_written_criteria_safe_v1',{p_session_id:id,p_item_order:item.item_order,p_language:lang});
 assert(result.ok,'criteria owner request failed '+component+'/'+lang);
 const panelText=(await panel.textContent())?.trim()||'';
 assert(panelText.length>0,'no accessible criteria or pending-localization explanation');
 if(result.data.available===true){
  assert(await panel.locator('li').count()>0,'server approved criteria not rendered');
 }else{
  assert(['localization_pending','unavailable'].includes(result.data?.reason)||result.data?.available===false,
   'unexpected criteria response');
 }
 assert.equal(count('exam_prep_written_step_advances_v1',id),before,
  'reading criteria silently advanced academic progress');
 return {itemOrder:item.item_order,available:result.data.available===true,lang};
}
// Stage C: fail the browser's FIRST Next request *before* it reaches the DB.
 // The real app must reconcile status=open and offer a safe retry.
 // Then race that same on-screen retry against eight independently signed real
 // HTTP/PostgREST calls while the first committed written row does NOT yet exist.
 // All clients must converge on exactly one server advance without written marks.
async function firstCommitOfflineRace(page,sessionId,itemOrder,component) {
 const onlyItem=' AND item_order='+itemOrder;
 assert.equal(count('exam_prep_written_step_advances_v1',sessionId,onlyItem),0,
  'Stage C requires a genuinely uncommitted written step');
 let blockedFirst=false;
 const routeName='**/rpc/advance_exam_prep_written_step_safe_v1';
 await page.route(routeName,async route=>{
  if(!blockedFirst){
   blockedFirst=true;
   await route.abort('internetdisconnected');
  }else await route.continue();
 });
 await page.locator('[data-ep-written-next]').click();
 // A failed BEFORE-COMMIT request may never be treated as saved. The
 // existing production UI must read actual server status before retry.
 const retry=page.locator('[data-ep-written-recovery] button').last();
 await retry.waitFor({state:'visible',timeout:30000});
 await page.waitForFunction(
  ()=>document.querySelectorAll('[data-ep-written-recovery] button').length===2,
  null,{timeout:30000});
 assert(blockedFirst,'offline-before-commit injection did not occur');
 const pre=await rpc('get_exam_prep_written_step_status_safe_v1',
  {p_session_id:sessionId,p_item_order:itemOrder});
 assert(pre.ok&&pre.data?.status==='open'&&pre.data?.can_advance===true,
  'server incorrectly persisted an offline BEFORE-COMMIT Next');
 assert.equal(count('exam_prep_written_step_advances_v1',sessionId,onlyItem),0,
  'offline-before-commit changed durable written evidence');
 assert.equal(count('exam_prep_responses',sessionId,onlyItem),0,
  'offline-before-commit manufactured an answer');

 // Eight HTTP requests begin independently, one UI retry is a ninth writer.
 // All use genuine owner JWT and actual PostgREST/PG17; no RPC mocks.
 const keys=Array.from({length:8},(_,n)=>
  'stage-c-first-commit-'+component.toLowerCase()+'-'+n);
 const requests=keys.map(p_idempotency_key=>rpc(
  'advance_exam_prep_written_step_safe_v1',
  {p_session_id:sessionId,p_item_order:itemOrder,p_idempotency_key}));
 const click=retry.click();
 const responses=await Promise.all(requests);
 await click;
 assert(responses.every(r=>r.ok&&r.data?.status==='advanced'),
  'concurrent genuine first-commit HTTP callers did not all resolve');
 const nonReplay=responses.filter(r=>r.data?.replayed===false).length;
 assert(nonReplay<=1,'more than one HTTP caller inserted the first written row');
 await page.waitForFunction(()=>window.__lostWrittenAck===true,null,{timeout:30000});
 await page.waitForFunction(
  ()=>(window.__realWrittenTrace||[]).some(x=>
   x.name==='get_exam_prep_written_step_status_safe_v1'&&x.ok),
  null,{timeout:30000});
 const confirmed=await rpc('get_exam_prep_written_step_status_safe_v1',
  {p_session_id:sessionId,p_item_order:itemOrder});
 assert(confirmed.ok&&confirmed.data?.status==='advanced',
  'lost ACK after the concurrent first commit was not reconciled');
 assert.equal(count('exam_prep_written_step_advances_v1',sessionId,onlyItem),1,
  'concurrent first writes generated duplicate/missing durable Next');
 assert.equal(count('exam_prep_responses',sessionId,onlyItem),0,
  'concurrent first writes fabricated a written answer/score');
 const winner=db("select client_idempotency_key from private.exam_prep_written_step_advances_v1"+
  " where session_id='"+sessionId+"'::uuid and item_order="+itemOrder);
 if(keys.includes(winner))assert.equal(nonReplay,1,
  'winning HTTP request missing first-commit evidence');
 else assert.equal(nonReplay,0,
  'UI won first commit but a parallel HTTP caller also inserted');
 await page.unroute(routeName);
 return {component,offlineBeforeCommitDenied:true,serverStatusBeforeRetry:'open',
  simultaneousHttpFirstWriters:8,realUiRetry:true,firstWrittenInserts:1,
  ackLostAfterCommit:true,serverReconciliation:true,writtenGradingCredit:0};
}
async function main(){
 const browser=await chromium.launch({headless:true});
 const result=[];
 try{
  for(const component of ['P1','P5']){
   let id=null,lastItem=null;
   const preAdvanceAnswers=[];
   // Every fresh context uses the same real JWT, with no localStorage carryover.
   for(const {lang,width} of ['en','ru','uz'].flatMap(lang=>[385,1280].map(width=>({lang,width})))){
    const opening=await pageOpen(browser,lang,lang==='uz'&&width===1280,width);
    try{
     const located=await navigateToPlan(opening.page,component,id);
     if(!id){
      // Session read is directly from the server, even for browser auto-start.
      const all=await opening.page.evaluate(()=>window.__realWrittenTrace.filter(x=>x.name==='start_exam_prep_session_safe_v1'&&x.ok));
      id=all.at(-1)?.session_id||located.session;
     }
     assert(/^[a-f0-9-]{36}$/.test(id||''),'server did not issue/resolve learner session');
     await reachWritten(opening.page,id);
     // Final locale/viewport proves signed Next without ever opening criteria.
     const skipCriteria=lang==='uz'&&width===1280;
     const snapshot=await criteriaFor(opening.page,id,component,lang,!skipCriteria);
     if(lastItem!=null)assert.equal(snapshot.itemOrder,lastItem,'reopened a different written step');
     lastItem=snapshot.itemOrder;
     const horizontalOverflow=await opening.page.evaluate(()=>document.documentElement.scrollWidth>window.innerWidth+2);
     assert(!horizontalOverflow,'horizontal viewport overflow '+component+'/'+lang+'/'+width);
     preAdvanceAnswers.push({lang,width,available:snapshot.available});
     if(lang==='uz'&&width===1280){
      const before=count('exam_prep_responses',id,' AND item_order='+lastItem);
      assert(before===0,'written Core received stored essay/answer before Next');
      const stageC=await firstCommitOfflineRace(opening.page,id,lastItem,component);
      const criteriaReads=await opening.page.evaluate(()=>
       (window.__realWrittenTrace||[]).filter(x=>
         x.name==='get_exam_prep_written_criteria_safe_v1').length);
      assert.equal(criteriaReads,0,
        'P4-08 Core must continue without opening marking criteria');
      const advanced=await rpc('get_exam_prep_written_step_status_safe_v1',{p_session_id:id,p_item_order:lastItem});
      assert(advanced.ok&&advanced.data.status==='advanced','real Next not persisted after lost ACK');
      assert.equal(count('exam_prep_written_step_advances_v1',id,' AND item_order='+lastItem),1,
       'lost ACK caused duplicate or missing Next');
      assert.equal(count('exam_prep_responses',id,' AND item_order='+lastItem),0,
       'Next manufactured a written answer or grade');
      const badUser=await rpc('get_exam_prep_written_step_status_safe_v1',
       {p_session_id:id,p_item_order:lastItem},
       // Different authenticated synthetic user, not a forged real account.
       (()=>{const h2=enc({alg:'HS256',typ:'JWT'})+'.'+enc({role:'authenticated',aud:'authenticated',sub:'22222222-2222-4222-8222-222222222292',iat:Math.floor(Date.now()/1000),exp:Math.floor(Date.now()/1000)+600});return h2+'.'+crypto.createHmac('sha256',SECRET).update(h2).digest('base64url')})()
      );
      assert(!badUser.ok,'foreign user read written Next status');
      result.push({component,languages:preAdvanceAnswers,oneRealNext:true,criteriaOptionalNext:true,duplicateWrittenResponses:false,
       unreadWrittenMarkNotAwarded:true,foreignDenied:true,firstCommitRace:stageC});
     }
     assert.equal(opening.errors.length,0,'browser JS errors '+component+'/'+lang+': '+opening.errors.join('|'));
    }finally{await opening.context.close();}
   }
  }
  assert(result.length===2,'written e2e did not cover both P1/P5');
  console.log('STAGE B TRUE MATH UI HTTP WRITTEN CRITERIA NEXT RELOAD PASS',JSON.stringify(result));
  console.log('P4-08 OPTIONAL CRITERIA REAL HTTP NEXT PASS',
   JSON.stringify(result.map(r=>({component:r.component,
    criteriaOptionalNext:r.criteriaOptionalNext,writtenGradingCredit:0}))));
  console.log('STAGE C FIRST-COMMIT OFFLINE + CONCURRENT UI HTTP PASS',
   JSON.stringify(result.map(r=>r.firstCommitRace)));
 }finally{await browser.close()}
}
main().catch(e=>{console.error('STAGE B REAL WRITTEN BROWSER FAILED:',e.message);process.exitCode=1});
