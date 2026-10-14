// §64: actual headless Chromium + native DOM/MutationObserver, no live requests.
// Uses route IDs extracted from unchanged production app.js/index.html.
"use strict";
const {readFileSync,mkdtempSync,rmSync,existsSync}=require("node:fs");
const {spawn,spawnSync}=require("node:child_process");
const {join,resolve}=require("node:path"),{tmpdir}=require("node:os");
const {setTimeout:delay}=require("node:timers/promises");
const assert=require("node:assert/strict");
const root=resolve(__dirname,".."),read=p=>readFileSync(join(root,p),"utf8");
const app=read("app.js"),index=read("index.html");
const views=["home","courses","ratings","profile","about","support","certificates"];
const match=/const COURSES_SCREENS = \[([\s\S]*?)\];/.exec(app);
assert.ok(match,"Course router changed");
const nested=[...match[1].matchAll(/"([a-z-]+)"/g)].map(x=>x[1]);
assert.equal(nested.length,17,"Courses route inventory changed; review");
for(const view of views)assert.ok(index.includes('id="view-'+view+'"'),"Missing real view "+view);
for(const name of nested)assert.ok(index.includes('id="courses-'+name+'"'),"Missing actual stack "+name);
const esc=s=>s.replace(/[&<>"]/g,x=>({"&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;"}[x]));
const html='<!doctype html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">'+
 '<style>.view:not(.is-active){display:none}.stack-screen:not(.is-active){display:none}</style></head><body>'+
 '<main id="main"><div id="exam-prep-host-root" hidden aria-hidden="true"></div>'+
 views.map(v=>'<section id="view-'+esc(v)+'" class="view'+(v==="home"?' is-active':'')+
 '" data-view="'+esc(v)+'">'+(v==="courses"?nested.map(n=>
 '<section id="courses-'+esc(n)+'" class="stack-screen'+(n==="all-subjects"?' is-active':'')+
 '"></section>').join(""):"")+'</section>').join("")+
 '</main></body></html>';
function chromeExe(){
 if(process.env.ICLUB_AI_CHROME)return process.env.ICLUB_AI_CHROME;
 for(const e of ["google-chrome","google-chrome-stable","chromium","chromium-browser"]){
  const x=spawnSync("which",[e],{encoding:"utf8"});
  if(x.status===0&&x.stdout.trim())return x.stdout.trim();
 }throw Error("Headless Chromium required");
}
async function portFor(dir,child){
 for(let i=0;i<150;i++){
  if(child.exitCode!==null)throw Error("Chrome unexpectedly exited");
  const p=join(dir,"DevToolsActivePort");
  if(existsSync(p)){const port=Number(readFileSync(p,"utf8").split("\n")[0]);
   if(port>0)return port;}
  await delay(75);
 }throw Error("Chrome CDP unavailable");
}
async function connect(port){
 const d=await fetch("http://127.0.0.1:"+port+"/json/new?about:blank",{method:"PUT"});
 assert.equal(d.status,200);
 const ws=new WebSocket((await d.json()).webSocketDebuggerUrl);
 await new Promise((yes,no)=>{
  ws.addEventListener("open",yes,{once:true});
  ws.addEventListener("error",no,{once:true});
 });
 let seq=0;const pending=new Map(),network=[];
 ws.addEventListener("message",e=>{
  const m=JSON.parse(e.data);
  if(m.method==="Network.requestWillBeSent")network.push(m.params.request.url);
  if(!m.id||!pending.has(m.id))return;
  const x=pending.get(m.id);pending.delete(m.id);
  m.error?x.reject(Error(JSON.stringify(m.error))):x.resolve(m.result||{});
 });
 return{network,send:(method,params={})=>new Promise((yes,no)=>{
  const id=++seq;pending.set(id,{resolve:yes,reject:no});
  ws.send(JSON.stringify({id,method,params}));
 }),close:()=>ws.close()};
}
function browserSource(file,exportsName){
 const s=read(file);
 const exportLine="module.exports={"+exportsName+"};";
 assert.ok(s.includes(exportLine),"Detached candidate export changed: "+file);
 return "(()=>{"+s.replace(exportLine,"window."+exportsName+"="+exportsName+";")+"})()";
}
async function browserTest(){
 const ok=(a,why)=>{if(!a)throw Error(why);};
 const pause=ms=>new Promise(r=>setTimeout(r,ms));
 const el=id=>document.getElementById(id);
 const calls=[];
 let n=0,clock=200000;
 const uuid=()=>("00000000-0000-4000-8000-"+(++n).toString(16).padStart(12,"0"));
 const client=new window.QaV21ScreenClient({
  post:async req=>{
   calls.push({path:req.path,body:req.body,authorization:req.authorization});
   if(req.path==="/context"){
    if(req.body.action==="revoke")return{ok:true};
    return{ok:true,contextHandle:uuid(),expiresInSeconds:90};
   }
   return{ok:false,reason:"source_in_development"};
  },
  readJwt:async()=>"synthetic-only-jwt-token",
  newRequestId:()=>uuid(),nowMs:()=>clock
 });
 const binder=new window.QaV21AppScreenBinder({client,document});
 const activate=view=>{
  for(const e of document.querySelectorAll(".view"))
   e.classList.toggle("is-active",e.dataset.view===view);
 };
 const course=name=>{
  for(const e of document.querySelectorAll("#view-courses .stack-screen"))
   e.classList.toggle("is-active",e.id==="courses-"+name);
 };
 const count=action=>calls.filter(x=>x.body.action===action).length;
 const credentials=()=>calls.every(x=>x.authorization==="Bearer synthetic-only-jwt-token"&&
  !("userId" in x.body)&&!("progress" in x.body)&&!("plan" in x.body));
 await binder.authChanged("SIGNED_IN",{user:{id:"synthetic-user"}});
 ok((await binder.sync()).ok,"Home did not mint on native DOM");
 ok(count("mintAppView")===1,"Home mint count");
 activate("courses");
 ok((await binder.sync()).ok,"Study root did not mint");
 ok(count("mintAppView")===2&&count("revoke")===1,"Home→Study lifecycle");
 course("subject-hub");
 ok((await binder.sync()).reason==="screen_not_verified","Subject hub stole General Help");
 ok(count("mintAppView")===2&&count("revoke")===2,"Study hub wrong access");
 course("all-subjects");activate("profile");
 ok((await binder.sync()).ok,"Profile did not mint");
 activate("home");el("view-certificates").classList.add("is-active");
 ok((await binder.sync()).reason==="screen_not_verified","Unknown overlay accepted");
 ok(count("revoke")===3,"Overlay failed to revoke");
 el("view-certificates").classList.remove("is-active");
 ok((await binder.sync()).ok,"Restored Home failed to mint");
 clock=290000;
 ok((await binder.askPrepared("nav_about","ru")).reason==="context_expired",
  "Expired context attempted paid Help");
 ok((await binder.sync()).reason==="context_expired","Expired context remained ready");
 const minted=count("mintAppView");ok(minted===4,"Unexpected automatic mint");
 await binder.authChanged("SIGNED_OUT",null);
 ok((await binder.sync()).reason==="screen_not_verified","Signed-out account reminted");
 ok(count("mintAppView")===minted,"Signout produced mint");
 ok(credentials(),"Client supplied untrusted owner/plan/progress");
 await binder.disconnect();
 await pause(10);
 // Observe the NATIVE MutationObserver path, not a mocked observer:
 // a screen switch must revoke without a manual sync() caller.
 activate("home");clock=500000;
 const client2=new window.QaV21ScreenClient({
  post:async req=>{
   calls.push({path:req.path,body:req.body,authorization:req.authorization});
   if(req.path==="/context")
    return req.body.action==="revoke"?{ok:true}:
      {ok:true,contextHandle:uuid(),expiresInSeconds:90};
   return{ok:false,reason:"source_in_development"};
  },readJwt:async()=>"synthetic-only-jwt-token",
  newRequestId:()=>uuid(),nowMs:()=>clock
 });
 const observerBinder=new window.QaV21AppScreenBinder({client:client2,document});
 observerBinder.attach();await pause(50);
 ok(observerBinder.ready&&observerBinder.key==="home",
  "Native MutationObserver did not acquire initial Home context");
 activate("support");await pause(70);
 ok(observerBinder.ready&&observerBinder.key==="support",
  "Native MutationObserver failed to rebind on navigation");
 const revokedBefore=count("revoke");
 el("view-certificates").classList.add("is-active");await pause(70);
 ok(observerBinder.ready===false&&count("revoke")>revokedBefore,
  "Native MutationObserver did not revoke an unsupported overlay");
 await observerBinder.disconnect();
 // Real browser promise scheduling + identity loss: a pending prepared reply
 // must never become visible after auth sign-out or a second user's login.
 el("view-certificates").classList.remove("is-active");
 activate("support");clock=700000;
 let answerFinish=null;const delayedCalls=[];
 const client3=new window.QaV21ScreenClient({
  post:async req=>{
   delayedCalls.push(req);
   if(req.path==="/answer")
    return await new Promise(resolve=>{answerFinish=resolve;});
   if(req.body.action==="revoke")return{ok:true};
   return{ok:true,contextHandle:uuid(),expiresInSeconds:90};
  },
  readJwt:async()=>"synthetic-only-jwt-token",newRequestId:()=>uuid(),
  nowMs:()=>clock
 });
 const authBinder=new window.QaV21AppScreenBinder({client:client3,document});
 await authBinder.authChanged("SIGNED_IN",{user:{id:"account-1"}});
 ok((await authBinder.sync()).ok,"Fresh account failed to bind Help");
 const pending=authBinder.askPrepared("nav_about","ru");
 for(let i=0;i<20&&!answerFinish;i++)await pause(1);
 ok(typeof answerFinish==="function","Synthetic old-account request did not start");
 await authBinder.authChanged("SIGNED_OUT",null);
 answerFinish({ok:true,reply:"PRIVATE_PREVIOUS_ACCOUNT"});
 const old=await pending;
 ok(old.reason==="context_changed","Stale account reply surfaced");
 ok((await authBinder.sync()).reason==="screen_not_verified",
  "Logged-out account reopened context");
 await authBinder.authChanged("SIGNED_IN",{user:{id:"account-2"}});
 ok((await authBinder.sync()).ok,"New account failed to bind independently");
 await authBinder.disconnect();
 return{viewport:innerWidth+"x"+innerHeight,nativeDom:true,
  routes:7,nestedScreens:17,issued:minted,revoked:count("revoke"),
  noPaidAnswers:calls.filter(x=>x.path==="/answer").length===0,
  signoutBlocked:true};
}
async function run(){
 const dir=mkdtempSync(join(tmpdir(),"iclub-p6-qa-chrome-"));
 const child=spawn(chromeExe(),["--headless=new","--no-sandbox",
  "--disable-gpu","--disable-dev-shm-usage","--disable-extensions",
  "--disable-background-networking","--no-first-run",
  "--remote-debugging-port=0","--user-data-dir="+dir,"about:blank"],
  {stdio:"ignore"});
 let browser=null;
 try{
  browser=await connect(await portFor(dir,child));
  await browser.send("Page.enable");await browser.send("Runtime.enable");
  await browser.send("Network.enable");
  const transport=browserSource("qa/ai-layer-v21-ui-transport.cjs","QaV21ScreenClient");
  const binding=browserSource("qa/ai-layer-v21-p6-app-screen-binding.cjs","QaV21AppScreenBinder");
  for(const size of [{w:320,h:568},{w:390,h:844},{w:1366,h:768}]){
   await browser.send("Emulation.setDeviceMetricsOverride",{
    width:size.w,height:size.h,deviceScaleFactor:1,mobile:size.w<600
   });
   await browser.send("Page.navigate",{
    url:"data:text/html;charset=utf-8,"+encodeURIComponent(html)
   });
   for(const expression of [transport,binding]){
    const result=await browser.send("Runtime.evaluate",{expression,
      awaitPromise:true,returnByValue:true});
    if(result.exceptionDetails)throw Error("Failed to install synthetic QA script: "+
      JSON.stringify(result.exceptionDetails).slice(0,900));
   }
   const test=await browser.send("Runtime.evaluate",{
    expression:"("+browserTest.toString()+")()",awaitPromise:true,
    returnByValue:true
   });
   if(test.exceptionDetails)throw Error("P6 Chromium "+size.w+"x"+size.h+
     ": "+JSON.stringify(test.exceptionDetails).slice(0,1500));
   const value=test.result?.value;assert.equal(value?.noPaidAnswers,true);
   assert.equal(value.signoutBlocked,true);
   console.log("P6_NATIVE_BROWSER_GREEN "+JSON.stringify(value));
  }
  for(const url of browser.network)
   assert.ok(url.startsWith("data:"),"Real browser attempted external request: "+url);
  console.log("GREEN: P6 native browser 320/390/1366, 17 stack views, 0 outbound");
 }finally{
  try{browser?.close()}catch{}
  child.kill("SIGKILL");
  await Promise.race([new Promise(done=>child.once("exit",done)),delay(1000)]);
  rmSync(dir,{recursive:true,force:true,maxRetries:3});
 }
}
run().catch(e=>{console.error(e);process.exitCode=1;});
