"use strict";
// Screen acceptance for the exact iClub shell markup and production CSS.
// CI only, localhost assets, no real account/data/provider.
const {readFileSync,existsSync,mkdtempSync,mkdirSync,rmSync,writeFileSync}=require("node:fs");
const {spawn,spawnSync}=require("node:child_process");
const {tmpdir}=require("node:os"),{join,resolve}=require("node:path");
const {setTimeout:delay}=require("node:timers/promises");
const {createServer}=require("node:http"),assert=require("node:assert/strict");
const root=resolve(__dirname,"..");
const OUTPUT=process.env.ICLUB_VISUAL_ARTIFACT_DIR||join(tmpdir(),"iclub-ai-v21-app-look-screenshots");
const ASSETS={
 "/":["qa/ai-layer-v21-app-look-preview/index.html","text/html"],
 "/style.css":["style.css","text/css"],
 "/visual/iclub-visual-v3.css":["visual/iclub-visual-v3.css","text/css"],
 "/visual/iclub-premium-v3.css":["visual/iclub-premium-v3.css","text/css"],
 "/global-ai-ui.css":["global-ai-ui.css","text/css"],
 "/logo.png":["logo.png","image/png"],
 "/qa/ai-layer-v21-app-look-preview/review.css":["qa/ai-layer-v21-app-look-preview/review.css","text/css"],
 "/qa/ai-layer-v21-app-look-preview/review.js":["qa/ai-layer-v21-app-look-preview/review.js","text/javascript"]
};
function chromeExe(){
 if(process.env.ICLUB_AI_CHROME)return process.env.ICLUB_AI_CHROME;
 for(const exe of ["google-chrome","google-chrome-stable","chromium","chromium-browser"]){
  const v=spawnSync("which",[exe],{encoding:"utf8"});
  if(v.status===0&&v.stdout.trim())return v.stdout.trim();
 }
 throw Error("Actual Chromium required");
}
async function portFor(dir,child){
 for(let n=0;n<150;n++){
  if(child.exitCode!==null)throw Error("Chrome exited before CDP");
  const file=join(dir,"DevToolsActivePort");
  if(existsSync(file)){
   const port=Number(readFileSync(file,"utf8").split("\n")[0]);
   if(port>0)return port;
  }
  await delay(90);
 }
 throw Error("Chromium CDP unavailable");
}
async function connect(port){
 const r=await fetch("http://127.0.0.1:"+port+"/json/new?about:blank",{method:"PUT"});
 assert.equal(r.status,200);
 const ws=new WebSocket((await r.json()).webSocketDebuggerUrl);
 await new Promise((done,fail)=>{
  ws.addEventListener("open",done,{once:true});ws.addEventListener("error",fail,{once:true});
 });
 let counter=0;const pending=new Map(),requests=[];
 ws.addEventListener("message",event=>{
  const data=JSON.parse(event.data);
  if(data.method==="Network.requestWillBeSent")requests.push(data.params.request.url);
  if(!data.id||!pending.has(data.id))return;
  const slot=pending.get(data.id);pending.delete(data.id);
  data.error?slot.reject(Error(JSON.stringify(data.error))):slot.resolve(data.result||{});
 });
 return{requests,send:(method,params={})=>new Promise((done,fail)=>{
  const id=++counter;pending.set(id,{resolve:done,reject:fail});
  ws.send(JSON.stringify({id,method,params}));
 }),close:()=>ws.close()};
}

async function run(){
 mkdirSync(OUTPUT,{recursive:true});
 const server=createServer((req,res)=>{
  const u=new URL(req.url||"/","http://127.0.0.1");
  const asset=ASSETS[u.pathname];
  if(!asset){res.writeHead(404,{"content-type":"text/plain"});res.end("not found");return;}
  const contents=readFileSync(resolve(root,asset[0]));
  res.writeHead(200,{"content-type":asset[1],"content-length":contents.length,
   "cache-control":"no-store","x-content-type-options":"nosniff"});
  res.end(contents);
 });
 await new Promise(done=>server.listen(0,"127.0.0.1",done));
 const port=server.address().port,dir=mkdtempSync(join(tmpdir(),"iclub-look-cdp-"));
 const chrome=spawn(chromeExe(),["--headless=new","--no-sandbox","--disable-gpu",
  "--disable-dev-shm-usage","--disable-background-networking","--disable-extensions",
  "--no-first-run","--remote-debugging-port=0","--user-data-dir="+dir,"about:blank"],{stdio:"ignore"});
 let cdp=null;
 async function evalJs(code){
  const result=await cdp.send("Runtime.evaluate",{
   expression:"("+code+")()",awaitPromise:true,returnByValue:true
  });
  if(result.exceptionDetails)throw Error("Chromium parity assertion: "+
   JSON.stringify(result.exceptionDetails).slice(0,1800));
  return result.result?.value;
 }
 async function shot(label){
  const out=await cdp.send("Page.captureScreenshot",{format:"png",captureBeyondViewport:false});
  assert.ok(out.data,"no screenshot");
  const filename=join(OUTPUT,label+".png");
  writeFileSync(filename,Buffer.from(out.data,"base64"));
  console.log("ICLUB_APP_LOOK_SHOT "+filename);
 }
 try{
  cdp=await connect(await portFor(dir,chrome));
  await cdp.send("Page.enable");await cdp.send("Runtime.enable");
  await cdp.send("Network.enable");
  for(const scenario of [
   {w:390,h:844,lang:"ru",key:"RU_390"},
   {w:320,h:720,lang:"uz",key:"UZ_320"},
   {w:1366,h:768,lang:"en",key:"EN_1366"}
  ]){
   await cdp.send("Emulation.setDeviceMetricsOverride",{
    width:scenario.w,height:scenario.h,deviceScaleFactor:1,mobile:scenario.w<600
   });
   await cdp.send("Page.navigate",{url:"http://127.0.0.1:"+port+"/"});
   await delay(270);
   const ready=await evalJs(`async()=>{
    await new Promise(r=>setTimeout(r,120));
    const state=window.__iClubLookReview?.();
    if(!state)throw Error("synthetic look controller did not start");
    document.getElementById("review-language").value="${scenario.lang}";
    document.getElementById("review-language").dispatchEvent(new Event("change"));
    const logo=document.getElementById("topbar-logo");
    if(!logo||!logo.complete||!logo.naturalWidth)throw Error("original iClub brand not loaded");
    if(document.querySelectorAll("#tabbar .tab").length!==4)throw Error("original 4-tab navigation missing");
    if(!document.querySelector("#view-home.is-active"))throw Error("Home not active");
    if(getComputedStyle(document.body).getPropertyValue("background-color")==="rgba(0, 0, 0, 0)")
     throw Error("missing real background");
    if(document.documentElement.scrollWidth>innerWidth+1)throw Error("Home overflow");
    return {lang:document.documentElement.lang,
     tabs:[...document.querySelectorAll("#tabbar .tab-txt")].map(x=>x.textContent),
     bg:getComputedStyle(document.body).backgroundColor};
   }`);
   assert.equal(ready.lang,scenario.lang);
   await shot("01_HOME_"+scenario.key);
   const study=await evalJs(`async()=>{
    document.querySelector('[data-tab="courses"]').click();
    if(!document.querySelector("#view-courses.is-active"))throw Error("Study not shown");
    if(!document.querySelector("#review-study-hub:not([hidden])"))throw Error("subject hub missing");
    document.getElementById("review-begin").click();
    if(document.getElementById("review-quiz").hidden)throw Error("quiz not opened");
    const ai=document.getElementById("iclub-global-ai-mark");
    if(!ai.hidden||getComputedStyle(ai).display!=="none")
     throw Error("AI mark leaked during active Practice");
    if(document.documentElement.scrollWidth>innerWidth+1)throw Error("Quiz overflow");
    return {quiz:true,aiHidden:true};
   }`);
   assert.equal(study.aiHidden,true);
   await shot("02_PRACTICE_"+scenario.key);
   const review=await evalJs(`async()=>{
    function answer(choice){
     const row=document.querySelectorAll("#review-answers [role=radio]")[choice];
     if(!row)throw Error("options missing");row.click();
     document.getElementById("review-next").click();
    }
    answer(1);answer(1);
    if(document.getElementById("review-result").hidden)throw Error("Result missing");
    if(document.getElementById("review-score-value").textContent!=="1 / 2")
     throw Error("result mismatch");
    if(document.getElementById("iclub-global-ai-mark").hidden)
     throw Error("AI did not recover after finish");
    document.getElementById("review-to-errors").click();
    if(document.getElementById("review-errors").hidden)throw Error("review did not open");
    const rows=document.querySelectorAll("#review-answer-list .review-answer-card");
    if(rows.length!==2)throw Error("review requires 2 independent questions");
    if(document.documentElement.scrollWidth>innerWidth+1)throw Error("Review overflow");
    return {rows:rows.length};
   }`);
   assert.equal(review.rows,2);
   await shot("03_REVIEW_"+scenario.key);
   const ai=await evalJs(`async()=>{
    document.querySelector("#review-answer-list .review-answer-card button").click();
    const panel=document.getElementById("iclub-global-ai-panel");
    if(panel.hidden)throw Error("AI panel not opened");
    document.getElementById("review-ai-quick").click();
    if(!document.querySelector("#review-ai-messages .iclub-global-ai-bubble"))
     throw Error("synthetic prepared text absent");
    if(document.documentElement.scrollWidth>innerWidth+1)throw Error("AI panel overflow");
    return {panel:true,reply:document.getElementById("review-ai-messages").textContent};
   }`);
   assert.ok(ai.reply.length>15);
   await shot("04_AI_"+scenario.key);
   await evalJs(`()=>{
     document.querySelector('[data-tab="home"]').click();
     if(!document.getElementById("iclub-global-ai-panel").hidden)
      throw Error("AI panel survived navigation");
     if(document.documentElement.scrollWidth>innerWidth+1)throw Error("Back Home overflow");
   }`);
   console.log("ICLUB_APP_LOOK_GREEN "+JSON.stringify({
    width:scenario.w,height:scenario.h,lang:scenario.lang,
    originalShell:true,quizBlackout:true,review:true,ai:true,screenshots:4
   }));
  }
  for(const url of cdp.requests)assert.ok(
   url.startsWith("http://127.0.0.1:"+port+"/")||url.startsWith("data:"),
   "Forbidden external request "+url);
  console.log("ICLUB_APP_LOOK_VISUAL_PARITY_GREEN: canonical shell, CSS, RU UZ EN, 12 screenshot states, no external requests");
 }finally{
  try{cdp?.close()}catch{}
  chrome.kill("SIGKILL");
  if(chrome.exitCode===null&&chrome.signalCode===null)
   await Promise.race([new Promise(done=>chrome.once("exit",done)),delay(1700)]);
  try{rmSync(dir,{recursive:true,force:true,maxRetries:8,retryDelay:120})}catch{}
  await new Promise(done=>server.close(done));
 }
}
run().catch(e=>{console.error("ICLUB_APP_LOOK_FAIL "+String(e.stack||e));process.exitCode=1;});
