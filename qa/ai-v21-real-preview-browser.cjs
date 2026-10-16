"use strict";
// Offline CDP test on the actual iClub APP and QA-only synthetic network.
const {spawn,spawnSync}=require("node:child_process");
const {readFileSync,mkdtempSync,existsSync,rmSync}=require("node:fs");
const {tmpdir}=require("node:os");
const {join}=require("node:path");
const assert=require("node:assert/strict");
const delay=ms=>new Promise(r=>setTimeout(r,ms));
const base="http://127.0.0.1:4175/";
function exe(){
  for(const name of ["google-chrome","chromium","chromium-browser"]){
    const r=spawnSync("which",[name],{encoding:"utf8"});
    if(r.status===0)return r.stdout.trim();
  }
  throw Error("Headless Chrome required");
}
async function chromePort(dir,child){
  for(let i=0;i<320;i++){
    if(child.exitCode!==null)throw Error("Chrome exited "+child.exitCode);
    const p=join(dir,"DevToolsActivePort");
    if(existsSync(p)){
      const n=Number(readFileSync(p,"utf8").split("\n")[0]);
      if(n>0)return n;
    }
    await delay(80);
  }
  throw Error("Chrome debugging port unavailable");
}
async function connect(port){
  const target=await fetch("http://127.0.0.1:"+port+"/json/new?about:blank",{method:"PUT"});
  assert.equal(target.status,200);
  const ws=new WebSocket((await target.json()).webSocketDebuggerUrl);
  await new Promise((resolve,reject)=>{
    ws.addEventListener("open",resolve,{once:true});
    ws.addEventListener("error",reject,{once:true});
  });
  let seq=0;
  const pending=new Map(),network=[],exceptions=[];
  ws.addEventListener("message",event=>{
    const msg=JSON.parse(event.data);
    if(msg.method==="Network.responseReceived"){
      const r=msg.params.response;network.push({url:r.url,status:r.status});
    }
    if(msg.method==="Runtime.exceptionThrown"){
      exceptions.push(String(msg.params.exceptionDetails?.text||"JS exception"));
    }
    if(!msg.id||!pending.has(msg.id))return;
    const job=pending.get(msg.id);pending.delete(msg.id);
    msg.error?job.reject(Error(JSON.stringify(msg.error))):job.resolve(msg.result||{});
  });
  const send=(method,params={})=>new Promise((resolve,reject)=>{
    const id=++seq;pending.set(id,{resolve,reject});
    ws.send(JSON.stringify({id,method,params}));
  });
  const evaluate=async expression=>{
    const r=await send("Runtime.evaluate",{expression,returnByValue:true,awaitPromise:true,userGesture:true});
    if(r.exceptionDetails)throw Error("Browser JS exception "+JSON.stringify(r.exceptionDetails).slice(0,500));
    return r.result?.value;
  };
  const until=async(expression,description,timeout=10000)=>{
    for(let i=0;i<Math.ceil(timeout/120);i++){
      if(await evaluate(expression))return;
      await delay(120);
    }
    throw Error("Timed out: "+description);
  };
  return {send,evaluate,until,network,exceptions,close:()=>ws.close()};
}
async function main(){
  const dir=mkdtempSync(join(tmpdir(),"iclub-ai-real-qa-"));
  const child=spawn(exe(),[
    "--headless=new","--no-sandbox","--disable-gpu","--disable-dev-shm-usage",
    "--disable-background-networking","--disable-extensions",
    "--no-first-run","--no-default-browser-check",
    "--remote-debugging-port=0","--user-data-dir="+dir,"about:blank"
  ],{stdio:["ignore","ignore","pipe"]});
  let chromeStderr="";
  child.stderr?.on("data",data=>{chromeStderr=(chromeStderr+String(data)).slice(-5000);});
  let client;
  try{
    let port;
    try{port=await chromePort(dir,child);}catch(error){
      throw Error(String(error.message)+"; Chrome output: "+chromeStderr);
    }
    client=await connect(port);
    await client.send("Page.enable");
    await client.send("Runtime.enable");
    await client.send("Network.enable");
    await client.send("Emulation.setDeviceMetricsOverride",{
      width:390,height:844,deviceScaleFactor:1,mobile:true
    });
    await client.send("Page.navigate",{url:base});
    await client.until("document.querySelector('#view-home')?.classList.contains('is-active')",
      "real app Home from synthetic profile",20000);
    await client.until("!!document.getElementById('iclub-global-ai-mark')",
      "AI floating mark",15000);
    const identity=await client.evaluate("({"+
      "qa:window.__ICLUB_AI_QA_PREVIEW__?.noProductionWrites===true,"+
      "screen:document.querySelector('.view.is-active')?.dataset.view,"+
      "engine:!!document.querySelector('#courses-practice-start'),"+
      "iconSrc:document.querySelector('#iclub-global-ai-mark img')?.getAttribute('src'),"+
      "profile:JSON.parse(localStorage.getItem('iclub_profile_v1')||'{}')?.full_name"+
      "})");
    assert.equal(await client.evaluate(
      "document.querySelector('meta[http-equiv=\"Content-Security-Policy\"]')?.getAttribute('content')?.includes(\"connect-src 'none'\")"),
      true,"No-network CSP must be active even on local static servers");
    assert.equal(identity.qa,true,JSON.stringify(identity));
    assert.equal(identity.screen,"home");
    assert.equal(identity.engine,true);
    assert.equal(identity.iconSrc,"iclub-ai-tutor-a.webp");
    await client.until("document.querySelector('#iclub-global-ai-mark img')?.naturalWidth===96",
      "approved Option A AI icon loads");
    const aiImage=await client.evaluate("(()=>{const i=document.querySelector('#iclub-global-ai-mark img');return {ok:i.complete&&i.naturalWidth===96,width:i.getBoundingClientRect().width,height:i.getBoundingClientRect().height}})()");
    assert.ok(aiImage.ok&&aiImage.width===40&&aiImage.height===40,
      "approved AI icon fit incorrect "+JSON.stringify(aiImage));
    assert.equal(identity.profile,"Демонстрационный профиль");
    await client.evaluate("document.getElementById('iclub-global-ai-mark').click();true");
    await client.until("!document.querySelector('#iclub-global-ai-panel')?.hidden",
      "Home AI open");
    await client.until("document.querySelector('.iclub-global-ai-head-logo')?.naturalWidth===96",
      "approved Option A appears in Tutor sheet");
    assert.equal(await client.evaluate(
      "document.querySelector('[data-global-ai-quick]')?.textContent.includes('Что делать дальше?')"),
      true,"Home needs specific prompts");
    // Genuine app router via its existing Study tab.
    await client.evaluate("document.querySelector('#tabbar [data-tab=\"courses\"]').click();true");
    await client.until("document.querySelector('#view-courses')?.classList.contains('is-active')",
      "real Study tab navigation");
    await client.until("document.querySelector('#iclub-global-ai-panel')?.hidden",
      "AI closes during route change");
    await client.evaluate("document.getElementById('iclub-global-ai-mark').click();true");
    await client.until("document.querySelector('[data-global-ai-quick]')?.textContent.includes('Как открыть предмет?')",
      "subject catalogue context");
    // Only classes change below: do NOT start, answer or finalize an actual assessment.
    const route=screen=>"(()=>{document.querySelectorAll('#view-courses .stack-screen').forEach(e=>"+
      "e.classList.toggle('is-active',e.id==='courses-"+screen+"'));return true})()";
    await client.evaluate(route("practice-start"));
    await client.until("document.querySelector('#iclub-global-ai-panel')?.hidden",
      "Practice start closes old context");
    await client.evaluate("document.getElementById('iclub-global-ai-mark').click();true");
    await client.until("document.querySelector('[data-global-ai-quick]')?.textContent.includes('Как работает Practice?')",
      "Practice-specific guidance");
    await client.evaluate(route("practice-quiz"));
    await client.until("(()=>{const m=document.querySelector('#iclub-global-ai-mark');"+
      "return m?.hidden===true&&getComputedStyle(m).display==='none'"+
      "&&document.querySelector('#iclub-global-ai-panel')?.hidden===true;})()",
      "Practice question blackout");
    await client.evaluate(route("practice-result"));
    await client.until("document.querySelector('#iclub-global-ai-mark')?.hidden===false",
      "AI returns on result screen");
    await client.evaluate("document.getElementById('iclub-global-ai-mark').click();true");
    await client.until("document.querySelector('[data-global-ai-quick]')?.textContent.includes('Объяснить результат')",
      "Practice result quick action");
    await client.evaluate("(()=>{const btn=[...document.querySelectorAll('[data-global-ai-quick] button')]"+
      ".find(e=>e.textContent.includes('Объяснить результат'));"+
      "if(!btn)throw Error('Result prompt missing');btn.click();return true;})()");
    await client.until("document.querySelector('[data-global-ai-messages]')?.textContent.includes('нет подтверждённого результата')",
      "no invented scores");
    await client.evaluate(route("tour-quiz"));
    await client.until("document.querySelector('#iclub-global-ai-mark')?.hidden===true",
      "Tour blackout");
    await client.evaluate(route("tour-review"));
    await client.until("document.querySelector('#iclub-global-ai-mark')?.hidden===false",
      "Archive surface allows general help");
    for(const [width,height] of [[320,740],[390,844],[1280,800]]){
      await client.send("Emulation.setDeviceMetricsOverride",{
        width,height,deviceScaleFactor:1,mobile:width<600
      });
      // Reset panel consistently between breakpoint changes, including pending UI timers.
      await client.evaluate("window.iClubGlobalAiShell.close();true");
      await delay(160);
      const openPanel=async()=>client.evaluate(
        "document.getElementById('iclub-global-ai-mark').click();true");
      await openPanel();
      let opened=false;
      for(let retry=0;retry<3;retry++){
        await delay(180);
        opened=await client.evaluate("!document.querySelector('#iclub-global-ai-panel')?.hidden");
        if(opened)break;
        await openPanel();
      }
      if(!opened){
        const diag=await client.evaluate("({view:document.querySelector('.view.is-active')?.dataset.view,"+
          "panelHidden:document.querySelector('#iclub-global-ai-panel')?.hidden,"+
          "markHidden:document.querySelector('#iclub-global-ai-mark')?.hidden,"+
          "context:window.iClubGlobalAiShell?.context?.()})");
        throw Error(width+"px Preview panel failed: "+JSON.stringify(diag));
      }
      const rect=await client.evaluate("(()=>{const r=document.getElementById('iclub-global-ai-panel').getBoundingClientRect();"+
        "return {left:r.left,right:r.right,top:r.top,bottom:r.bottom}})()");
      assert.ok(rect.left>=-1&&rect.right<=width+1,"horizontal clip "+JSON.stringify(rect));
      assert.ok(rect.top>=-1&&rect.bottom<=height+1,"vertical clip "+JSON.stringify(rect));
      await client.evaluate("document.querySelector('[data-global-ai-close]')?.click();true");
    }
    // Full architect-facing walkthrough on the REAL application screens.
    // No actual quiz submission and no real learner data is generated.
    await client.evaluate("document.querySelector('#tabbar [data-tab=\"home\"]').click();true");
    await client.until("document.querySelector('#view-home')?.classList.contains('is-active')",
      "real Home for AI demo");
    await client.until("!!document.getElementById('iclub-qa-demo-home-entry')",
      "original Practice walkthrough entry");
    await client.evaluate("document.getElementById('iclub-qa-demo-home-entry').click();true");
    await client.until("document.querySelector('#courses-practice-review')?.classList.contains('is-active')",
      "demo opens existing Practice review");
    const sample=await client.evaluate("({active:window.__ICLUB_AI_QA_DEMO__?.active,question:document.querySelector('.iclub-qa-demo-question')?.textContent,answer:document.querySelector('.iclub-qa-demo-answer.correct strong')?.textContent,notice:document.querySelector('.iclub-qa-demo-note')?.textContent})");
    assert.equal(sample.active,true);
    assert.match(sample.question,/x² \+ 2x/);
    assert.equal(sample.answer,"8");
    assert.match(sample.notice,/не результат ученика/);
    await client.evaluate("document.querySelector('.iclub-qa-demo-main-btn').click();true");
    await client.until("!document.querySelector('#iclub-global-ai-panel')?.hidden",
      "AI opens on selected illustrative question");
    await client.until("document.querySelector('[data-global-ai-quick]')?.textContent.includes('Объяснить ошибку')",
      "real Practice review AI action");
    await client.evaluate("(()=>{const b=[...document.querySelectorAll('[data-global-ai-quick] button')].find(e=>e.textContent.includes('Объяснить ошибку'));if(!b)throw Error('Demo action absent');b.click();return true;})()");
    await client.until("document.querySelector('[data-global-ai-messages]')?.textContent.includes('f′(3) = 2·3 + 2')",
      "AI explains original sample answer");
    const answer=await client.evaluate("document.querySelector('[data-global-ai-messages]')?.textContent");
    assert.match(answer,/не реальный результат ученика/);
    assert.match(answer,/8/);
    await client.evaluate("document.querySelector('.iclub-qa-demo-back').click();true");
    await client.until("!window.__ICLUB_AI_QA_DEMO__?.active",
      "demo exited without user data writes");
    await client.until("document.querySelector('#iclub-global-ai-panel')?.hidden",
      "old demo AI context is closed");

    const outside=client.network.filter(r=>/^https?:\/\//.test(r.url)&&!r.url.startsWith(base));
    assert.deepEqual(outside,[],"No external network responses in Preview: "+
      JSON.stringify(outside));
    process.stdout.write("ICLUB_REAL_APP_PREVIEW_BROWSER_GREEN "+
      JSON.stringify({viewports:3,realTab:true,blackouts:2,
        externalResponses:outside.length,exceptionsObserved:client.exceptions.length})+"\n");
  }finally{
    try{client?.close();}catch{}
    child.kill("SIGTERM");
    await delay(300);
    try{rmSync(dir,{recursive:true,force:true,maxRetries:3,retryDelay:250});}
    catch(cleanupError){console.warn("Chrome cleanup deferred:",cleanupError.code);}
  }
}
main().catch(e=>{console.error("ICLUB_REAL_APP_PREVIEW_BROWSER_FAIL",e);process.exitCode=1});
