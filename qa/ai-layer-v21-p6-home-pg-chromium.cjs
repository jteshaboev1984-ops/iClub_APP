"use strict";
// §97 actual headless Chrome: rendered trilingual QA Home -> local HTTP ->
// disposable PostgreSQL -> signed permission-checked next action.
// The browser never visits production or real Supabase/Vercel.
const {spawn,spawnSync}=require("node:child_process");
const {readFileSync,existsSync,mkdtempSync,rmSync}=require("node:fs");
const {join}=require("node:path");
const {tmpdir}=require("node:os");
const {setTimeout:delay}=require("node:timers/promises");
const assert=require("node:assert/strict");
const {makeGateway}=require("./ai-layer-v21-p6-home-pg-http-gateway.cjs");
function chromeExecutable(){
 if(process.env.ICLUB_AI_CHROME)return process.env.ICLUB_AI_CHROME;
 for(const exe of ["google-chrome","chromium","chromium-browser"]){
  const found=spawnSync("which",[exe],{encoding:"utf8"});
  if(found.status===0)return found.stdout.trim();
 }
 throw Error("Native Chromium required");
}
async function browserPort(dir,child){
 for(let n=0;n<120;n++){
  if(child.exitCode!==null)throw Error("Chromium exited during startup");
  const path=join(dir,"DevToolsActivePort");
  if(existsSync(path)){
   const port=Number(readFileSync(path,"utf8").split("\n")[0]);
   if(port>0)return port;
  }
  await delay(80);
 }
 throw Error("No Chrome DevTools port");
}
async function connect(port){
 const request=await fetch("http://127.0.0.1:"+port+"/json/new?about:blank",
  {method:"PUT"});
 assert.equal(request.status,200);
 const ws=new WebSocket((await request.json()).webSocketDebuggerUrl);
 await new Promise((yes,no)=>{
  ws.addEventListener("open",yes,{once:true});
  ws.addEventListener("error",no,{once:true});
 });
 let id=0;const pending=new Map(),network=[];
 ws.addEventListener("message",evt=>{
  const response=JSON.parse(evt.data);
  if(response.method==="Network.requestWillBeSent")
   network.push(response.params.request.url);
  if(!pending.has(response.id))return;
  const job=pending.get(response.id);pending.delete(response.id);
  response.error?job.reject(Error(JSON.stringify(response.error))):
   job.resolve(response.result||{});
 });
 return{network,send:(method,params={})=>new Promise((yes,no)=>{
  const next=++id;pending.set(next,{resolve:yes,reject:no});
  ws.send(JSON.stringify({id:next,method,params}));
 }),close:()=>ws.close()};
}
async function waitForPage(cdp){
 for(let attempt=0;attempt<70;attempt++){
  const r=await cdp.send("Runtime.evaluate",{expression:
   'document.readyState==="complete" && !!window.__qaHomeState',
   returnByValue:true});
  if(r.result?.value===true)return;
  await delay(35);
 }
 throw Error("Local Home fixture did not initialize");
}
async function checkLocale(cdp,locale){
 const js='(async()=>{'+
  'const select=document.querySelector("#locale");'+
  'select.value='+JSON.stringify(locale)+';'+
  'select.dispatchEvent(new Event("change"));'+
  'document.querySelector("#check").click();'+
  'for(let i=0;i<180;i++){if(window.__qaHomeState().state==="ready")break;'+
  'if(window.__qaHomeState().state==="denied")throw Error("Unexpected denial");'+
  'await new Promise(resolve=>setTimeout(resolve,40));}'+
  'const result=window.__qaHomeState();'+
  'return {...result,visible:document.querySelector("#result").textContent,'+
  'landmark:document.querySelector("#tabs").getAttribute("aria-label"),'+
  'labels:[...document.querySelectorAll("#tabs button")].map(x=>x.textContent),'+
  'bodyOverflow:document.documentElement.scrollWidth>innerWidth+1,'+
  'height:innerHeight,width:innerWidth};'+
  '})()';
 const result=await cdp.send("Runtime.evaluate",
  {expression:js,awaitPromise:true,returnByValue:true});
 if(result.exceptionDetails)throw Error("Chrome "+locale+" failed: "+
  JSON.stringify(result.exceptionDetails).slice(0,600));
 const value=result.result?.value;
 assert.equal(value?.state,"ready","Local signed Home must render eligible result");
 assert.equal(value.action,"review_finalized_practice");
 assert.equal(value.bodyOverflow,false);
 assert.equal(value.locale,locale);
 assert.equal(value.labels.length,4);
 const labels={ru:"Нижнее меню",uz:"Pastki menyu",en:"Bottom navigation"};
 assert.equal(value.landmark,labels[locale]);
 assert(value.visible.length>12);
 return value;
}
async function run(){
 const gw=makeGateway();
 await new Promise(done=>gw.server.listen(0,"127.0.0.1",done));
 const url="http://127.0.0.1:"+gw.server.address().port;
 const dir=mkdtempSync(join(tmpdir(),"iclub-pg-home-chromium-"));
 const child=spawn(chromeExecutable(),["--headless=new","--no-sandbox",
  "--disable-dev-shm-usage","--disable-gpu","--disable-extensions",
  "--disable-background-networking","--no-first-run",
  "--remote-debugging-port=0","--user-data-dir="+dir,"about:blank"],{stdio:"ignore"});
 let cdp;
 try{
  cdp=await connect(await browserPort(dir,child));
  for(const method of ["Page.enable","Runtime.enable","Network.enable"])
   await cdp.send(method);
  for(const v of [{lang:"ru",w:320,h:568},{lang:"uz",w:390,h:844},
   {lang:"en",w:1366,h:768}]){
   await cdp.send("Emulation.setDeviceMetricsOverride",{
    width:v.w,height:v.h,deviceScaleFactor:1,mobile:v.w<600});
   await cdp.send("Page.navigate",{url:url+"/qa/home/demo"});
   await waitForPage(cdp);
   const state=await checkLocale(cdp,v.lang);
   assert.equal(state.width,v.w);
   console.log("HOME_PG_CHROME_GREEN "+JSON.stringify({
    locale:v.lang,viewport:v.w+"x"+v.h,action:state.action,
    navLandmark:state.landmark,overflow:false}));
  }
  // Browser should stop displaying a once-valid recommendation when the
  // signed server deadline passes, even with no click, navigation or network.
  const expiry=await cdp.send("Runtime.evaluate",{expression:
   '(()=>{const before=window.__qaHomeState();'+
   'const deadline=before.expiresAtMs;'+
   'if(!Number.isSafeInteger(deadline)||deadline<=Date.now()) throw Error("Missing signed TTL");'+
   'Date.now=()=>deadline+1;'+
   'document.dispatchEvent(new Event("visibilitychange"));'+
   'return {before,after:window.__qaHomeState(),text:document.querySelector("#result").textContent}})()',
   returnByValue:true});
  if(expiry.exceptionDetails)throw Error("Browser expiry validation exception");
  const exp=expiry.result?.value;
  assert.equal(exp?.before.state,"ready");
  assert.equal(exp.after.state,"expired");
  assert.equal(exp.after.action,null);
  assert.equal(exp.after.expiresAtMs,0);
  assert.equal(exp.text,"Recommendation expired. Check again");
  console.log("HOME_PG_CHROME_TTL_GREEN: expired signed Home no longer displayed");
  const leave=await cdp.send("Runtime.evaluate",{expression:
   '(()=>{document.querySelector("#leave").click();'+
   'return window.__qaHomeState()})()',returnByValue:true});
  assert.equal(leave.result?.value?.active,false);
  assert.equal(leave.result?.value?.state,"left");
  const oldCalls=gw.state.requests;
  const noClick=await cdp.send("Runtime.evaluate",{expression:
   '(()=>{document.querySelector("#check").click();return window.__qaHomeState()})()',
   returnByValue:true});
  assert.equal(noClick.result.value.active,false);
  await delay(150);
  assert.equal(gw.state.requests,oldCalls,"Signed-out user must not re-send Home");
  for(const resource of cdp.network)
   assert(resource.startsWith(url+"/"),"Unapproved outbound request: "+resource);
  console.log("GREEN: real scratch Home->HTTP->signed response->Chromium in 3 locales, zero external traffic");
 }finally{
  try{cdp?.close()}catch{}
  child.kill("SIGKILL");
  await Promise.race([new Promise(done=>child.once("exit",done)),delay(1300)]);
  try{rmSync(dir,{recursive:true,force:true,maxRetries:12,retryDelay:80});}
  catch(e){if(["ENOTEMPTY","EBUSY","EPERM"].includes(e?.code))
   console.warn("CHROME_TEMP_CLEANUP_WARNING "+e.code);else throw e;}
  await new Promise(done=>gw.server.close(done));
 }
}
run().catch(e=>{console.error("HOME_PG_CHROME_FAIL "+String(e.stack||e));process.exitCode=1;});
