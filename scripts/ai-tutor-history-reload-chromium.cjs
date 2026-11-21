"use strict";
// Chromium QA for the actual Tutor UI with history OFF in checked-in source.
// This script turns it on ONLY in local injected JS with a fake authenticated
// owner-bound server. NO live JWT, Edge, DB, provider, preview or user data.
const assert=require("node:assert/strict");
const fs=require("node:fs"),path=require("node:path"),http=require("node:http");
const {chromium}=require("playwright");
const ROOT=path.resolve(__dirname,"..");
const original=fs.readFileSync(path.join(ROOT,"iclub-ai-v21-ui.js"),"utf8");
const fixture=fs.readFileSync(path.join(ROOT,
  "scripts/fixtures/practice-ai-unified-tutor-local-only.html"),"utf8");
const css=fs.readFileSync(path.join(ROOT,"iclub-ai-v21-ui.css"),"utf8");
assert(original.includes("const TUTOR_HISTORY_DRAFT_ENABLED = false;"),
  "Never enable history in a production UI source by accident");
const ui=original.replace("const TUTOR_HISTORY_DRAFT_ENABLED = false;",
  "const TUTOR_HISTORY_DRAFT_ENABLED = true;");
const A="00000000-0000-4000-8000-000000000011";
const B="00000000-0000-4000-8000-000000000022";
const ANSWER="Practice bo‘limida mavzu tanlang, mashqni bajaring, keyin xatolarni ko‘ring.";
const PROMPT="Амалиет нимага кк";
let browser,server;
const stored=new Map([[A,[]],[B,[]]]);
const usage={model:0,ask:0,append:0,read:0};
async function main(){
 const errors=[];
 try {
  server=http.createServer((req,res)=>{
   const body=new URL(req.url,"http://127.0.0.1").pathname==="/"?fixture:"Not found";
   res.writeHead(body===fixture?200:404,{"content-type":"text/html; charset=utf-8"});
   res.end(body);
  });
  await new Promise(ok=>server.listen(0,"127.0.0.1",ok));
  const origin="http://127.0.0.1:"+server.address().port;
  browser=await chromium.launch({headless:true});
  const context=await browser.newContext({viewport:{width:390,height:844}});
  await context.exposeBinding("__qaHistoryServer",async(_source,p)=>{
    const id=p.uid,action=p.args.p_action,key=p.args.p_thread_key;
    if(!stored.has(id))return {data:{ok:false,reason:"auth_required"},error:null};
    if(action==="status")return {data:{ok:true,consented:true},error:null};
    if(action==="read"){
      usage.read++;
      return {data:{ok:true,messages:stored.get(id).filter(x=>x.thread_key===key)
        .map(x=>({request_id:x.request_id,role:x.role,locale:x.locale,
          text:x.text,created_at:x.created_at}))},error:null};
    }
    if(action==="append"){
      usage.append++;
      const rows=stored.get(id);
      const exists=rows.some(x=>x.request_id===p.args.p_request_id &&
        x.role===p.args.p_speaker);
      if(!exists)rows.push({request_id:p.args.p_request_id,
        thread_key:key,role:p.args.p_speaker,
        locale:p.args.p_locale,text:p.args.p_text,
        created_at:new Date().toISOString()});
      return {data:{ok:true,inserted:!exists,
        provider_called:false,academic_state_changed:false},error:null};
    }
    return {data:{ok:false,reason:"unsupported"},error:null};
  });
  await context.addInitScript(({user,answer})=>{
    window.__qaUser=user;
    window.__historyWrites=[];
    window.i18n={getLang:()=>"uz"};
    window.sb={
      auth:{onAuthStateChange:fn=>{
        window.__qaAuthChange=fn;
        queueMicrotask(()=>fn("INITIAL_SESSION",{user:{id:window.__qaUser}}));
        return{data:{subscription:{unsubscribe(){}}}};
      }},
      rpc:async(name,args)=>{
        if(name!=="iclub_ai_tutor_history_service_v1")
          return{data:null,error:{message:"unknown RPC"}};
        const result=await window.__qaHistoryServer({uid:window.__qaUser,args});
        if(args.p_action==="append")window.__historyWrites.push(args);
        return result;
      }
    };
    window.iClubAiV21BetaClient={
      status:async()=>({ok:true,eligible:true,consented:true,candidate:false}),
      askPrepared:async({promptKey})=>{
        if(promptKey!=="practice_rules")
          return {ok:false,reason:"not_approved"};
        return {ok:true,mode:"prepared",provider_called:false,
          academic_state_changed:false,message:answer};
      },
      askGenerated:async()=>{throw Error("Paid model must never run in fixture");}
    };
    window.__qaSwitchAccount=(uid)=>{
      window.__qaUser=uid;
      window.__qaAuthChange?.("SIGNED_IN",{user:{id:uid}});
    };
  },{user:A,answer:ANSWER});
  const page=await context.newPage();
  page.on("pageerror",e=>errors.push(String(e.message)));
  async function load(){
    await page.goto(origin+"/",{waitUntil:"domcontentloaded"});
    await page.evaluate(()=>{
      const result=document.getElementById("courses-practice-result");
      result.classList.remove("is-active");result.hidden=true;
      const subject=document.createElement("section");
      subject.id="courses-practice-start";
      subject.className="stack-screen is-active";
      document.getElementById("view-courses").appendChild(subject);
    });
    await page.addStyleTag({content:css});
    await page.addScriptTag({content:ui});
    await page.waitForFunction(()=>window.iClubGlobalAiShell?.context()
      ?.threadKey==="mathematics",{timeout:10000});
    await page.waitForFunction(()=>document.getElementById("iclub-global-ai-mark")
      ?.hidden===false,{timeout:10000});
  }
  async function open(){
    await page.evaluate(()=>window.iClubGlobalAiShell.open());
    await page.waitForSelector("#iclub-global-ai-panel",{state:"visible"});
  }
  await load();
  await open();
  const input=page.locator("[data-global-ai-input]");
  await input.fill(PROMPT);
  await input.press("Enter");
  await page.waitForFunction(answer=>[...document.querySelectorAll(
    ".iclub-global-ai-message.is-assistant")].some(x=>x.textContent.includes(answer)),
    ANSWER,{timeout:10000});
  await page.waitForFunction(()=>window.__historyWrites.length===2,
    null,{timeout:10000});
  assert.deepEqual(stored.get(A).map(x=>x.role),["user","assistant"]);
  assert.equal(stored.get(A)[0].text,PROMPT);
  assert.equal(stored.get(A)[1].text,ANSWER);
  assert.equal(usage.model,0);
  // Opening same user after complete WebView destruction rehydrates local UI.
  await page.reload({waitUntil:"domcontentloaded"});
  await page.evaluate(()=>{
    const result=document.getElementById("courses-practice-result");
    result.classList.remove("is-active");result.hidden=true;
      const subject=document.createElement("section");
      subject.id="courses-practice-start";
      subject.className="stack-screen is-active";
      document.getElementById("view-courses").appendChild(subject);
  });
  await page.addStyleTag({content:css});
  await page.addScriptTag({content:ui});
  await page.waitForFunction(()=>document.getElementById("iclub-global-ai-mark")
    ?.hidden===false,{timeout:10000});
  await open();
  await page.waitForFunction(question=>[...document.querySelectorAll(
    ".iclub-global-ai-message.is-user")].some(x=>x.textContent.includes(question)),
    PROMPT,{timeout:10000});
  assert.equal(await page.locator(".iclub-global-ai-message").count(),2,
    "Reload duplicated or lost chat messages");
  assert.equal(stored.get(A).length,2,
    "Reading history must never cause a second provider call or append");
  // Switching account clears in-memory data. B cannot see A's history.
  await page.evaluate(uid=>window.__qaSwitchAccount(uid),B);
  await page.waitForFunction(()=>document.getElementById("iclub-global-ai-mark")
    ?.hidden===false,{timeout:10000});
  await open();
  await page.waitForFunction(()=>document.querySelectorAll(
    ".iclub-global-ai-message").length===0,{timeout:10000});
  assert.equal(stored.get(B).length,0);
  // Back to the original account: permitted owner history returns after gate.
  await page.evaluate(uid=>window.__qaSwitchAccount(uid),A);
  await page.waitForFunction(()=>document.getElementById("iclub-global-ai-mark")
    ?.hidden===false,{timeout:10000});
  await open();
  await page.waitForFunction(answer=>[...document.querySelectorAll(
    ".iclub-global-ai-message.is-assistant")].some(x=>x.textContent.includes(answer)),
    ANSWER,{timeout:10000});
  assert.equal(stored.get(A).length,2);
  assert.equal(usage.model,0);
  assert.deepEqual(errors,[]);
  console.log("PASS offline actual Tutor Chromium: persisted public-help pair, reloaded WebView, owner A/B isolation, read-no-paid-retry");
  console.log("SCOPED ONLY: mocked RPC + emulated auth; not real JWT/PostgREST or approved retention.");
 }finally{
  if(browser)await browser.close();
  if(server)await new Promise(resolve=>server.close(resolve));
 }
}
main().catch(err=>{console.error(err);process.exitCode=1;});
