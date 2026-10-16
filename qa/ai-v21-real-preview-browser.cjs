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
    // Two rapid taps must still make ONE request; no chat-side second tap.
    await client.evaluate("(()=>{const b=document.querySelector('.iclub-qa-demo-main-btn');b.click();b.click();return true;})()");
    await client.until("!document.querySelector('#iclub-global-ai-panel')?.hidden",
      "single-tap AI panel open");
    await client.until("document.querySelector('[data-qa-practice-context]')?.textContent.includes('f′(3)')",
      "question context appears immediately in the same Tutor sheet");
    await client.until("document.querySelector('[data-global-ai-messages] .is-user')?.textContent.includes('ответ 6 неверный')",
      "question sent automatically, without a staged keyboard animation");
    const inFlight=await client.evaluate("({draft:document.querySelector('[data-global-ai-input]')?.value,quick:document.querySelector('[data-global-ai-quick]')?.hidden})");
    assert.deepEqual(inFlight,{draft:"",quick:true},
      "no fake typing and no duplicate Explain button");
    await client.until("document.querySelectorAll('.iclub-qa-explain-steps li').length===3",
      "three formatted explanation steps automatically appear",12000);
    const once=await client.evaluate("({users:document.querySelectorAll('[data-global-ai-messages] .is-user').length,replies:document.querySelectorAll('[data-global-ai-messages] .is-assistant:not(.is-typing)').length,steps:document.querySelectorAll('.iclub-qa-explain-steps li').length})");
    assert.deepEqual(once,{users:1,replies:1,steps:3},
      "rapid double tap must show just one request and three steps");
    const answer=await client.evaluate("document.querySelector('[data-global-ai-messages]')?.textContent");
    assert.match(answer,/Производная x² равна 2x/);
    assert.match(answer,/2 × 3 \+ 2 = 8/);
    assert.match(answer,/Демонстрационный пример/);
    const item=await client.evaluate("(()=>{const p=document.querySelector('#iclub-global-ai-panel');const scroll=p?.querySelector('[data-global-ai-scroll]');const title=p?.querySelector('.iclub-qa-explain-title');return {panel:!p?.hidden,visible:!!title,top:title?.getBoundingClientRect().top,scrollTop:scroll?.getBoundingClientRect().top}})()");
    assert.equal(item.panel,true);
    assert.ok(item.visible&&item.top>=(item.scrollTop-8),
      "after response, reader should see the START of the explanation");
    await client.evaluate("document.querySelector('.iclub-qa-demo-back').click();true");
    await client.until("!window.__ICLUB_AI_QA_DEMO__?.active",
      "demo exited without user data writes");
    await client.until("document.querySelector('#iclub-global-ai-panel')?.hidden",
      "old demo AI context is closed");

    // One global iClub AI across real Home / Study / Subject / Lessons /
    // Tours / Leaderboard / Profile / Community / Support without fake scores.
    // Each CTA opens the SAME Tutor and sends its section-specific request.
    const appScreens=[
      ["courses","all-subjects","Откройте Study","general"],
      ["courses","subject-hub","В выбранном предмете","biology"],
      ["courses","video","Видео-уроки","biology"],
      ["courses","tours","Во время активного тура","biology"],
      ["courses","books","Книги","biology"],
      ["ratings","ratings","В Рейтинге","general"],
      ["profile","profile","не подтверждены сервером","general"],
      ["community","community","официальный канал iClub","general"],
      ["support","support","В «Поддержке»","general"],
      ["certificates","certificates","Сертификаты появляются","general"],
      ["notifications","notifications","Уведомления показывают","general"]
    ];
    for(const [view,screen,expectedText,expectedSubject] of appScreens){
      await client.evaluate("(()=>{document.querySelectorAll('.view').forEach(v=>"+
        "v.classList.toggle('is-active',v.id==='view-"+view+"'));"+
        "document.querySelectorAll('#view-courses .stack-screen').forEach(v=>"+
        "v.classList.toggle('is-active',v.id==='courses-"+screen+"'));"+
        "document.getElementById('subject-hub-title').textContent='Биология';"+
        "return true})()");
      await client.until("window.iClubGlobalAiShell?.context?.()?.screenCode==='"+screen+"'",
        "active real app section "+screen);
      await client.until("(()=>{const b=document.querySelector('[data-qa-app-help=\""+screen+"\"]');"+
        "return !!b&&!b.hidden&&getComputedStyle(b).display!=='none'})()",
        "section-specific contextual AI action "+screen);
      const before=await client.evaluate("({route:window.iClubGlobalAiShell.context(),"+
        "panel:document.querySelector('#iclub-global-ai-panel')?.hidden})");
      assert.equal(before.route.subjectKey,expectedSubject,
        "App-wide subject context crossed boundaries: "+screen);
      await client.evaluate("document.querySelector('[data-qa-app-help=\""+screen+"\"]').click();true");
      await client.until("!document.querySelector('#iclub-global-ai-panel')?.hidden",
        "one-tap global Tutor opens in "+screen);
      try {
        await client.until("document.querySelector('[data-global-ai-messages] .is-assistant')?."+
          "textContent.includes("+JSON.stringify(expectedText)+")",
          "readable, section-aware answer for "+screen);
      } catch (error) {
        const diag=await client.evaluate("({route:window.iClubGlobalAiShell?.context?.(),"+
          "title:document.querySelector('[data-global-ai-title]')?.textContent,"+
          "body:document.querySelector('[data-global-ai-messages]')?.textContent,"+
          "hidden:document.querySelector('#iclub-global-ai-panel')?.hidden,"+
          "mark:document.querySelector('#iclub-global-ai-mark')?.hidden,"+
          "button:document.querySelector('[data-qa-app-help]')?.textContent})");
        throw Error(screen+": "+JSON.stringify(diag)+" / "+String(error));
      }
      const result=await client.evaluate("({thread:window.iClubGlobalAiShell.context().threadKey,"+
        "users:document.querySelectorAll('[data-global-ai-messages] .is-user').length,"+
        "replies:document.querySelectorAll('[data-global-ai-messages] .is-assistant').length})");
      assert.ok(result.users===1&&result.replies===1,
        "duplicate or mixed context in "+screen+": "+JSON.stringify(result));
      await client.evaluate("window.iClubGlobalAiShell.close();true");
    }
    // The original controlled Mathematics Tutor is not modified by these
    // cross-app CTA routes; hidden active quizzes were already tested above.

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
