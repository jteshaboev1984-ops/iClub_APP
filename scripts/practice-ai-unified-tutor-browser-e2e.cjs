"use strict";
// Real existing iClub AI Tutor + real connected beta-client JS in Chromium.
// EVERY external request is intercepted; no real user, model, production data.
const fs=require("node:fs"),path=require("node:path"),http=require("node:http");
const assert=require("node:assert/strict");
const {chromium}=require("playwright");
const root=path.resolve(__dirname,"..");
const html=fs.readFileSync(path.join(root,"scripts/fixtures/practice-ai-unified-tutor-local-only.html"));
const jsClient=fs.readFileSync(path.join(root,"iclub-ai-v21-beta-client.js"),"utf8");
const jsTutor=fs.readFileSync(path.join(root,"iclub-ai-v21-ui.js"),"utf8");
const css=fs.readFileSync(path.join(root,"iclub-ai-v21-ui.css"),"utf8");
const BASE="https://mmmduffgpvwjdpruzikw.supabase.co";
const USER="00000000-0000-4000-8000-000000000011";
const ANSWER="Результат 70% означает 7 верных ответов из 10. Повтори материал, связанный с ошибками, затем реши похожие задания.";
let server,browser;
async function main(){
 const activity={visibility:[],asks:[],acks:[],denied:[],external:[],authInvokes:[],
   resumes:[],recoveryAcks:[],recoverable:null};
 const jsErrors=[];
 try{
  server=http.createServer((req,res)=>{
   const url=new URL(req.url,"http://127.0.0.1").pathname;
   const content=url==="/"?html:Buffer.from("Not found");
   res.writeHead(url==="/"?200:404,{"content-type":url==="/"?"text/html; charset=utf-8":"text/plain",
      "cache-control":"no-store"});
   res.end(content);
  });
  await new Promise(ok=>server.listen(0,"127.0.0.1",ok));
  const origin="http://127.0.0.1:"+server.address().port;
  browser=await chromium.launch({headless:true});
  const context=await browser.newContext({viewport:{width:1024,height:768}});
  const page=await context.newPage();
  page.on("pageerror",err=>jsErrors.push(err.message));
  await page.addInitScript(({user})=>{
    window.__isolated={
      user,permitted:true,visibilityAllowed:true,
      firstAckFails:true,authListeners:[]
    };
    window.i18n={getLang:()=>"ru"};
    window.sb={
      supabaseUrl:"https://mmmduffgpvwjdpruzikw.supabase.co",
      supabaseKey:"QA_PUBLIC_ANON_TOKEN_"+ "a".repeat(54),
      auth:{
        getUser:async()=>({data:{user:{id:window.__isolated.user}},error:null}),
        getSession:async()=>({data:{session:{access_token:"QA_DUMMY_JWT_"+"b".repeat(75),
          user:{id:window.__isolated.user}}},error:null}),
        onAuthStateChange:fn=>{
          window.__isolated.authListeners.push(fn);
          return {data:{subscription:{unsubscribe(){}}}};
        }
      },
      rpc:async()=>({data:null,error:{message:"not available in isolated QA"}}),
      functions:{invoke:async(_name,{body})=>{
        if(body.intent==="status")return{data:{ok:true,eligible:window.__isolated.permitted,
          consented:window.__isolated.permitted,candidate:false},error:null};
        return{data:{ok:false,reason:"isolated_no_other_routes"},error:null};
      }}
    };
  },{user:USER});
  await page.route("**/*",async route=>{
    const url=route.request().url();
    if(url.startsWith(origin+"/"))return route.continue();
    if(url.startsWith(BASE+"/functions/v1/")){
      const headers={"access-control-allow-origin":origin,
        "access-control-allow-methods":"POST, OPTIONS",
        "access-control-allow-headers":"authorization, apikey, content-type, x-client-info",
        "vary":"Origin","content-type":"application/json; charset=utf-8"};
      if(route.request().method()==="OPTIONS")
        return route.fulfill({status:204,headers,body:""});
      const b=route.request().postDataJSON();
      const isVisible=url.endsWith("/iclub-ai-practice-prepared");
      const isFreeform=url.endsWith("/iclub-ai-practice-freeform");
      if(isVisible){
        assert.equal(b.purpose,"practice_visibility");
        activity.visibility.push(b.attempt_ref);
        return route.fulfill({status:200,headers,body:JSON.stringify({
          ok:true,available:await page.evaluate(()=>window.__isolated.visibilityAllowed),
          mode:"availability",provider_called:false,academic_state_changed:false})});
      }
      if(isFreeform){
        assert.equal(b.intent,"practice_freeform");
        if(b.operation==="resume"){
          assert.equal(b.question,null);
          activity.resumes.push(b);
          if(!activity.recoverable)return route.fulfill({status:409,headers,
            body:JSON.stringify({ok:false,reason:"no_pending_answer"})});
          return route.fulfill({status:200,headers,body:JSON.stringify({
            ok:true,mode:"generated",recovered:true,
            delivery_state:"pending_ack",
            request_id:activity.recoverable.request_id,
            message:ANSWER,provider_called:false,academic_state_changed:false})});
        }
        if(b.operation==="resume_ack"){
          activity.recoveryAcks.push(b);
          if(!activity.recoverable ||
             activity.recoverable.request_id!==b.request_id)
            return route.fulfill({status:403,headers,
              body:JSON.stringify({ok:false,reason:"receipt_not_found"})});
          activity.recoverable=null;
          return route.fulfill({status:200,headers,body:JSON.stringify({
            ok:true,mode:"acknowledged",request_id:b.request_id,
            provider_called:false,academic_state_changed:false})});
        }
        if(b.operation==="ask"){
          activity.asks.push(b);
          return route.fulfill({status:200,headers,body:JSON.stringify({
            ok:true,mode:"generated",delivery_state:"pending_ack",
            request_id:b.request_id,message:ANSWER,provider_called:activity.asks.length===1,
            academic_state_changed:false})});
        }
        if(b.operation==="ack"){
          activity.acks.push(b);
          if(activity.acks.length===1)return route.fulfill({status:503,headers,
            body:JSON.stringify({ok:false,reason:"simulated_ack_transport_loss"})});
          return route.fulfill({status:200,headers,body:JSON.stringify({
            ok:true,mode:"acknowledged",request_id:b.request_id,
            provider_called:false,academic_state_changed:false})});
        }
      }
      activity.denied.push(url);
      return route.fulfill({status:404,headers,body:JSON.stringify({ok:false})});
    }
    activity.external.push(url);
    return route.abort("blockedbyclient");
  });
  await page.goto(origin+"/",{waitUntil:"domcontentloaded"});
  // Inject actual PR assets only in local isolated browser, never when
  // someone visits the fixture on a public Vercel Preview URL.
  await page.addStyleTag({content:css});
  await page.addScriptTag({content:jsClient});
  await page.addScriptTag({content:jsTutor});
  await page.locator("#iclub-global-ai-mark").waitFor({timeout:8000});
  await page.evaluate(()=>window.iClubGlobalAiShell.open());
  await page.getByRole("button",{name:"Объяснить результат"}).waitFor({timeout:8000});
  assert.equal((await page.locator("#iclub-global-ai-panel").count()),1,
     "There should only be ONE existing Tutor panel");
  const askInput=page.locator("[data-global-ai-input]");
  await askInput.fill("Что означает мой результат 70%?");
  await page.locator("[data-global-ai-send]").click();
  await page.waitForFunction((answer)=>{
    const el=document.querySelector("[data-global-ai-messages]");
    return !!el?.textContent?.includes(answer);
  },ANSWER,{timeout:8000});
  await page.waitForFunction(()=>document.querySelector("[data-global-ai-quick]")?.textContent?.includes("Восстановить ответ"),null,{timeout:8000});
  assert.equal(activity.asks.length,1);
  assert.equal(activity.acks.length,1);
  const initialId=activity.asks[0].request_id;
  await page.getByRole("button",{name:"Восстановить ответ"}).click();
  await page.waitForFunction(()=>!document.querySelector("[data-global-ai-quick]")?.textContent?.includes("Восстановить ответ"),null,{timeout:8000});
  assert.equal(activity.asks.length,2);
  assert.equal(activity.acks.length,2);
  assert.equal(activity.asks[1].request_id,initialId);
  assert.equal(activity.acks[0].request_id,initialId);
  assert.equal(activity.acks[1].request_id,initialId);
  const rendered=await page.locator("[data-global-ai-messages]").textContent();
  assert.equal(rendered.split(ANSWER).length-1,1,"Recovered reply duplicated in Tutor");
  assert.equal(rendered.split("Что означает мой результат 70%?").length-1,1,
    "Recovered request duplicated a learner message");

  // The REAL Tutor auth handler must clear its in-memory conversations when
  // a different synthetic learner signs in, without leaking old responses.
  await page.evaluate(()=>{
    const next="00000000-0000-4000-8000-000000000022";
    window.__isolated.user=next;
    for(const callback of [...window.__isolated.authListeners])
      callback("SIGNED_IN",{user:{id:next}});
  });
  await page.locator("#iclub-global-ai-mark").waitFor({timeout:8000});
  await page.evaluate(()=>window.iClubGlobalAiShell.open());
  await page.waitForFunction(()=>{
    const msgs=document.querySelector("[data-global-ai-messages]");
    return !!msgs && msgs.textContent?.length===0;
  },null,{timeout:8000});
  assert.equal((await page.locator("[data-global-ai-messages]").textContent()||"").includes(ANSWER),false,
    "Previous learner's answer survived account switch");

  // Same-screen switch to another attempt must not send to General Help
  // while the owner grant for the new attempt has not been verified.
  const before=activity.asks.length;
  await page.evaluate(()=>{
    window.__isolated.visibilityAllowed=false;
    document.getElementById("courses-practice-result").dataset.practiceAiAttemptId="502";
  });
  await askInput.fill("Что означает мой результат 70%?");
  await page.locator("[data-global-ai-send]").click();
  await page.waitForFunction(()=>document.querySelector("[data-global-ai-messages]")
     ?.textContent?.includes("Проверяем доступ к результату"),null,{timeout:8000});
  assert.equal(activity.asks.length,before,"An unauthorized attempt called model");
  assert.equal(activity.denied.length,0,"Unexpected backend route was invoked");
  assert.equal(activity.external.length,0,"External network escaped isolated browser");

  // A blocked exam hides the Tutor mark and prevents network calls.
  await page.evaluate(()=>{
    document.getElementById("courses-practice-result").classList.remove("is-active");
    document.getElementById("courses-practice-quiz").classList.add("is-active");
  });
  await page.waitForFunction(()=>document.getElementById("iclub-global-ai-mark")?.hidden===true,null,{timeout:8000});
  assert.equal(activity.asks.length,before);

  // Simulate an old response saved to canonical PC4 before a FULL reload.
  // Browser init scripts build a fresh empty user session, no localStorage.
  const savedRequestId="dddddddd-dddd-4ddd-8ddd-dddddddddddd";
  activity.recoverable={request_id:savedRequestId};
  const beforeReloadAsks=activity.asks.length;
  await page.reload({waitUntil:"domcontentloaded"});
  await page.addStyleTag({content:css});
  await page.addScriptTag({content:jsClient});
  await page.addScriptTag({content:jsTutor});
  await page.locator("#iclub-global-ai-mark").waitFor({timeout:8000});
  await page.evaluate(()=>window.iClubGlobalAiShell.open());
  try{
    await page.waitForFunction((answer)=>{
      const el=document.querySelector("[data-global-ai-messages]");
      return !!el?.textContent?.includes("Восстановлен ответ") &&
        el.textContent.includes(answer);
    },ANSWER,{timeout:6500});
  }catch(err){
    console.error("RELOAD RECOVERY DIAGNOSTIC",JSON.stringify({
      activity:{visibility:activity.visibility,
        resumes:activity.resumes,recoveryAcks:activity.recoveryAcks,
        denied:activity.denied,external:activity.external},
      jsErrors,
      page:await page.evaluate(()=>({
        mark:!!document.querySelector("#iclub-global-ai-mark"),
        panelHidden:document.querySelector("#iclub-global-ai-panel")?.hidden,
        quick:document.querySelector("[data-global-ai-quick]")?.textContent,
        messages:document.querySelector("[data-global-ai-messages]")?.textContent,
        attempt:document.querySelector("#courses-practice-result")
         ?.dataset?.practiceAiAttemptId,
        context:window.iClubGlobalAiShell?.context?.()
      }))
    }));
    throw err;
  }
  await page.waitForFunction(()=>document.querySelector("[data-global-ai-quick]")
    && !document.querySelector("[data-global-ai-quick]").textContent.includes("Восстановить ответ"),
    null,{timeout:10000});
  assert.equal(activity.asks.length,beforeReloadAsks,
    "Full reload must never dispatch a model");
  assert.equal(activity.recoveryAcks.length,1,
    "Saved answer must ACK in new browser session");
  assert.equal(activity.recoveryAcks[0].request_id,savedRequestId);
  const afterReload=await page.locator("[data-global-ai-messages]").textContent();
  assert.equal(afterReload.split(ANSWER).length-1,1,"Full reload delivered duplicate answer");
  assert.equal(await page.evaluate(()=>localStorage.length),0,
    "Recovery must not use localStorage");
  await page.screenshot({path:path.join(root,"artifacts/practice-ai-unified-tutor-local.png"),fullPage:true});
  assert.deepEqual(jsErrors,[],"Browser script errors");
  console.log("PASS actual unified Tutor + actual beta client on synthetic finalized main Practice");
  console.log("PASS typed question, lost ACK, same UUID replay, account switch, stale attempt fail-closed, protected quiz");
  console.log("PASS full page reload -> server saved answer -> single Tutor message -> same-ID ACK, zero localStorage");
  console.log("PASS 0 real external network, 0 production writes, 0 model calls");
  console.log(JSON.stringify({asks:activity.asks.length,acks:activity.acks.length,
    visibility:activity.visibility,recoveryProbes:activity.resumes.length,
    recoveryAcks:activity.recoveryAcks.length,foreignNetwork:activity.external.length}));
 }finally{
  if(browser)await browser.close();
  if(server)await new Promise(done=>server.close(done));
 }
}
main().catch(e=>{console.error("UNIFIED TUTOR BROWSER FAILED",e);process.exitCode=1;});
