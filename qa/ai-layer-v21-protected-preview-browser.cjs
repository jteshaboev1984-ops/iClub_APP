// One genuine browser E2E for the exact STATIC Preview files.
// All requests are bound to ephemeral loopback only. No Supabase/provider.
"use strict";
const {readFileSync,existsSync,mkdtempSync,rmSync}=require("node:fs");
const {spawn,spawnSync}=require("node:child_process");
const {tmpdir}=require("node:os"),{join,resolve}=require("node:path");
const {setTimeout:delay}=require("node:timers/promises");
const {createServer}=require("node:http"),assert=require("node:assert/strict");
const root=resolve(__dirname,"..");
const ASSETS={
 "/":["qa/ai-layer-v21-protected-preview/index.html","text/html"],
 "/preview.css":["qa/ai-layer-v21-protected-preview/preview.css","text/css"],
 "/preview-controller.js":["qa/ai-layer-v21-protected-preview/preview-controller.js","text/javascript"],
 "/global-ai-ui.js":["global-ai-ui.js","text/javascript"],
 "/global-ai-ui.css":["global-ai-ui.css","text/css"],
 "/transport.js":["qa/ai-layer-v21-ui-transport.cjs","text/javascript"],
 "/screen-binder.js":["qa/ai-layer-v21-screen-binding.cjs","text/javascript"],
 "/evidence-publisher.js":["qa/ai-layer-v21-evidence-publisher.cjs","text/javascript"],
 "/preview-glue.js":["qa/ai-layer-v21-preview-glue.cjs","text/javascript"]
};
async function checkPreview(lang){
 const pause=ms=>new Promise(resolve=>setTimeout(resolve,ms));
 const check=(v,why)=>{if(!v)throw Error(why);};
 for(let n=0;n<70&&!window.__iclubPreviewInspect;n++)await pause(40);
 check(!!window.__iclubPreviewInspect,"synthetic controller did not initialize");
 const sel=document.getElementById("language");sel.value=lang;
 sel.dispatchEvent(new Event("change"));await pause(100);
 const mark=document.getElementById("iclub-global-ai-mark");
 check(mark&&!mark.hidden,"no global AI icon on Home");
 document.getElementById("home-start").click();
 await pause(150);
 check(document.getElementById("courses-practice-quiz").classList.contains("is-active"),
  "Practice quiz not opened");
 check(mark.hidden&&getComputedStyle(mark).display==="none",
  "AI leaked into active Practice quiz");
 const choose=()=>{
  const option=document.querySelector('input[name="choice"][value="0"]');
  check(option,"synthetic option absent");option.click();
  document.getElementById("submit-answer").click();
 };
 choose();await pause(60);choose();await pause(160);
 check(document.getElementById("courses-practice-result").classList.contains("is-active"),
  "completed result screen missing");
 check(document.getElementById("score-count").textContent==="1 / 2",
  "synthetic score inconsistent");
 check(!mark.hidden,"AI icon did not recover after completion");
 document.getElementById("open-review").click();await pause(115);
 const cards=document.querySelectorAll("#review-questions .review-item");
 check(cards.length===2,"exact reviewed question rows missing");
 cards[0].querySelector("button").click();await pause(190);
 const panel=document.getElementById("iclub-global-ai-panel");
 check(panel&&!panel.hidden,"shared original AI panel not opened");
 const quick=panel.querySelector(".iclub-global-ai-quick-btn");
 check(quick,"academic prepared action missing");
 quick.click();await pause(430);
 const reply=panel.querySelector("[data-global-ai-messages]").textContent;
 const expected={ru:"При прочих равных",uz:"Boshqa sharoitlar",en:"All else equal"}[lang];
 check(reply.includes(expected),"V2 synthetic prepared reply not rendered: "+reply.slice(-140));
 check(document.documentElement.scrollWidth<=innerWidth+1,"horizontal overflow");
 document.querySelector('[data-view-target="home"]').click();await pause(110);
 check(panel.hidden,"context panel remained open after navigation");
 check(window.__iclubPreviewInspect().ready===false,
  "V2 context was not revoked on navigation");
 return{width:innerWidth,height:innerHeight,locale:lang,blackout:true,
  score:"1/2",reviewQuestions:2,syntheticV2:true};
}
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
 const server=createServer((req,res)=>{
  const pathname=new URL(req.url||"/","http://127.0.0.1").pathname;
  const asset=ASSETS[pathname];
  if(!asset){res.writeHead(404);res.end();return;}
  res.writeHead(200,{"content-type":asset[1]+"; charset=utf-8",
   "cache-control":"no-store","x-content-type-options":"nosniff"});
  res.end(readFileSync(resolve(root,asset[0])));
 });
 await new Promise(done=>server.listen(0,"127.0.0.1",done));
 const port=server.address().port,dir=mkdtempSync(join(tmpdir(),"iclub-static-qa-"));
 const child=spawn(chromeExe(),["--headless=new","--no-sandbox",
  "--disable-gpu","--disable-dev-shm-usage","--disable-background-networking",
  "--disable-extensions","--no-first-run","--remote-debugging-port=0",
  "--user-data-dir="+dir,"about:blank"],{stdio:"ignore"});
 let cdp=null;
 try{
  cdp=await connect(await portFor(dir,child));
  await cdp.send("Page.enable");await cdp.send("Runtime.enable");
  await cdp.send("Network.enable");
  for(const size of [{w:320,h:568,lang:"ru"},{w:390,h:844,lang:"uz"},
   {w:1366,h:768,lang:"en"}]){
   await cdp.send("Emulation.setDeviceMetricsOverride",{
    width:size.w,height:size.h,deviceScaleFactor:1,mobile:size.w<600
   });
   await cdp.send("Page.navigate",{url:"http://127.0.0.1:"+port+"/"});
   const r=await cdp.send("Runtime.evaluate",{
    expression:"("+checkPreview.toString()+")("+JSON.stringify(size.lang)+")",
    awaitPromise:true,returnByValue:true
   });
   if(r.exceptionDetails)throw Error("Preview Chromium "+size.w+"x"+size.h+
    " failed: "+JSON.stringify(r.exceptionDetails).slice(0,1600));
   assert.equal(r.result?.value?.width,size.w);
   assert.equal(r.result?.value?.height,size.h);
   console.log("PREVIEW_BROWSER_GREEN "+JSON.stringify(r.result.value));
  }
  for(const url of cdp.requests)
   assert.ok(url.startsWith("http://127.0.0.1:"+port+"/")||url.startsWith("data:"),
    "Forbidden external request: "+url);
  console.log("GREEN: synthetic Home→Practice→Result→Review→iClub AI, outbound requests 0");
 }finally{
  try{cdp?.close()}catch{}
  child.kill("SIGKILL");
  if(child.exitCode===null&&child.signalCode===null)
   await Promise.race([new Promise(done=>child.once("exit",done)),delay(1700)]);
  try{rmSync(dir,{recursive:true,force:true,maxRetries:9,retryDelay:120});}catch{}
  await new Promise(done=>server.close(done));
 }
}
run().catch(error=>{console.error("PREVIEW_BROWSER_FAIL "+String(error.stack||error));process.exitCode=1;});
