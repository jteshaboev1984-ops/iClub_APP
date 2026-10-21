"use strict";
// ZERO-cost browser smoke: real unauthenticated Chromium POST after actual CORS.
// No learner identity, no valid JWT, no provider invocation or database writes.
const {spawn,spawnSync}=require("node:child_process");
const {mkdtempSync,readFileSync,existsSync,rmSync}=require("node:fs");
const {tmpdir}=require("node:os"),{join}=require("node:path");
const {setTimeout:delay}=require("node:timers/promises");
const assert=require("node:assert/strict");
function chromeExe(){
 for(const name of ["google-chrome","google-chrome-stable","chromium","chromium-browser"]){
  const r=spawnSync("which",[name],{encoding:"utf8"});
  if(r.status===0)return r.stdout.trim();
 }
 throw Error("Real Chrome/Chromium unavailable");
}
async function run(){
 const dir=mkdtempSync(join(tmpdir(),"iclub-ai-safe-cors-"));
 const child=spawn(chromeExe(),[
  "--headless=new","--no-sandbox","--disable-gpu","--disable-dev-shm-usage",
  "--disable-extensions","--no-first-run","--remote-debugging-port=0",
  "--user-data-dir="+dir,"about:blank"
 ],{stdio:"ignore"});
 let ws=null,seq=0;const pending=new Map(),requests=[];
 try{
  let port=0;
  for(let i=0;i<150;i++){
   const p=join(dir,"DevToolsActivePort");
   if(existsSync(p)){port=Number(readFileSync(p,"utf8").split("\n")[0]);break;}
   if(child.exitCode!==null)throw Error("Chrome closed before startup");
   await delay(90);
  }
  assert.ok(port>0,"Chrome did not allocate CDP port");
  const t=await fetch("http://127.0.0.1:"+port+"/json/new?about:blank",{method:"PUT"});
  assert.equal(t.status,200);
  ws=new WebSocket((await t.json()).webSocketDebuggerUrl);
  await new Promise((resolve,reject)=>{
   ws.addEventListener("open",resolve,{once:true});
   ws.addEventListener("error",reject,{once:true});
  });
  ws.addEventListener("message",e=>{
   const x=JSON.parse(e.data);
   if(x.method==="Network.requestWillBeSent"){
    const u=String(x.params?.request?.url||"");
    if(u.includes("/functions/v1/iclub-ai-v21-freeform-beta"))
     requests.push({method:x.params.request.method,url:u});
   }
   if(x.id&&pending.has(x.id)){
    const p=pending.get(x.id);pending.delete(x.id);
    x.error?p.reject(Error(JSON.stringify(x.error))):p.resolve(x.result||{});
   }
  });
  const send=(method,params={})=>new Promise((resolve,reject)=>{
   const id=++seq;pending.set(id,{resolve,reject});
   ws.send(JSON.stringify({id,method,params}));
  });
  await send("Page.enable");await send("Network.enable");
  await send("Network.setUserAgentOverride",{userAgent:
   "Mozilla/5.0 (Linux; Android 13; K) AppleWebKit/537.36 Chrome/155 Mobile Safari/537.36 Telegram-Android/13.0.2.0"});
  await send("Page.navigate",{url:"https://i-club-app.vercel.app/"});
  await delay(2400);
  const evalResult=await send("Runtime.evaluate",{
   awaitPromise:true,returnByValue:true,
   expression:`(async function(){
     if(location.origin!=="https://i-club-app.vercel.app")
       return {origin:location.origin,stage:"origin_not_loaded"};
     try{
       const r=await fetch("https://mmmduffgpvwjdpruzikw.supabase.co/functions/v1/iclub-ai-v21-freeform-beta",{
         method:"POST",mode:"cors",credentials:"omit",
         headers:{
           "authorization":"Bearer synthetic.invalid.signature",
           "apikey":"synthetic-noncredential",
           "content-type":"application/json",
           "x-client-info":"supabase-js-browser-synthetic",
           "x-retry-count":"0",
           "traceparent":"00-00000000000000000000000000000001-0000000000000001-01",
           "tracestate":"synthetic=1",
           "baggage":"synthetic=1"
         },
         body:JSON.stringify({intent:"ask",request_id:"aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa",
             locale:"ru",question:"Synthetic preflight only"}),
         signal:AbortSignal.timeout(10000)
       });
       return {origin:location.origin,stage:"fetch_completed",httpStatus:r.status};
     }catch(error){return {origin:location.origin,stage:"rejected_after_attempt",name:String(error?.name||"Error")};}
   })()`
  });
  const value=evalResult.result?.value;
  await delay(900);
  const posts=requests.filter(x=>x.method==="POST");
  // Security: synthetic JWT can only be rejected; this is NOT a model test.
  assert.equal(value?.origin,"https://i-club-app.vercel.app","must originate at official production site");
  assert.ok(posts.length===1,
   "Chromium did not transmit its unauthenticated POST after CORS preflight; "+
   JSON.stringify({stage:value?.stage,requests:requests.map(x=>x.method)}));
  console.log("PASS Chromium sent ONE unauthorized POST after real cross-origin preflight; no model call");
 }finally{
  try{ws?.close();}catch{}
  child.kill("SIGKILL");
  rmSync(dir,{recursive:true,force:true});
 }
}
run().catch(e=>{console.error(String(e));process.exitCode=1;});
