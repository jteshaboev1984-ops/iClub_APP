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
      "symbol:document.querySelector('#iclub-global-ai-mark')?.textContent?.trim(),"+
      "profile:JSON.parse(localStorage.getItem('iclub_profile_v1')||'{}')?.full_name"+
      "})");
    assert.equal(identity.qa,true,JSON.stringify(identity));
    assert.equal(identity.screen,"home");
    assert.equal(identity.engine,true);
    assert.equal(identity.symbol,"AI");
    assert.equal(identity.profile,"Демонстрационный профиль");
    await client.evaluate("document.getElementById('iclub-global-ai-mark').click();true");
    await client.until("!document.querySelector('#iclub-global-ai-panel')?.hidden",
      "Home AI open");
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
      await client.evaluate("document.getElementById('iclub-global-ai-mark').click();true");
      await client.until("!document.querySelector('#iclub-global-ai-panel')?.hidden",
        width+" AI sheet");
      const rect=await client.evaluate("(()=>{const r=document.getElementById('iclub-global-ai-panel').getBoundingClientRect();"+
        "return {left:r.left,right:r.right,top:r.top,bottom:r.bottom}})()");
      assert.ok(rect.left>=-1&&rect.right<=width+1,"horizontal clip "+JSON.stringify(rect));
      assert.ok(rect.top>=-1&&rect.bottom<=height+1,"vertical clip "+JSON.stringify(rect));
      await client.evaluate("document.querySelector('[data-global-ai-close]')?.click();true");
    }
    const outside=client.network.filter(r=>/^https?:\/\//.test(r.url)&&!r.url.startsWith(base));
    assert.equal(outside.length,0,"No external network responses in Preview");
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
