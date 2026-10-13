// Real Chrome DevTools layout QA, no extra npm dependencies or network.
// The opened file uses the original global-ai-ui.js/.css with synthetic bootstrap.
"use strict";
const {spawn,spawnSync}=require("node:child_process");
const {mkdtempSync,rmSync,readFileSync,existsSync}=require("node:fs");
const {tmpdir}=require("node:os");
const {join,resolve}=require("node:path");
const {pathToFileURL}=require("node:url");
const {setTimeout:delay}=require("node:timers/promises");
const assert=require("node:assert/strict");
const html=join(resolve(__dirname,".."),"qa","ai-layer-v21-visual-harness.html");
const viewports=[
 {width:320,height:568,lang:"ru"},
 {width:390,height:844,lang:"uz"},
 {width:1366,height:768,lang:"en"},
 {width:390,height:480,lang:"ru"}
];
async function browserCheck(){
 const sleep=ms=>new Promise(r=>setTimeout(r,ms));
 const check=(v,msg)=>{if(!v)throw Error(msg);};
 const round=n=>Math.round(n*10)/10;
 await sleep(130);
 const mark=document.getElementById("iclub-global-ai-mark");
 check(mark&&!mark.hidden,"floating AI mark absent");
 const markRect=mark.getBoundingClientRect();
 const nav=document.querySelector(".fake-navbar").getBoundingClientRect();
 check(markRect.left>=-1&&markRect.right<=innerWidth+1,"floating icon outside viewport");
 check(markRect.bottom<nav.top,"floating icon collides with bottom navigation");
 mark.click();
 const panel=document.getElementById("iclub-global-ai-panel");
 check(panel&&!panel.hidden,"panel failed to open");
 // The real panel uses a 170ms entrance animation. Measure after it settles.
 await sleep(250);
 const rect=panel.getBoundingClientRect();
 check(rect.left>=-1&&rect.right<=innerWidth+1,"panel horizontal overflow");
 check(rect.top>=-1&&rect.bottom<=innerHeight+1,"panel vertical overflow");
 check(rect.width>=200&&rect.height>=200,"panel unexpectedly small");
 const title=panel.querySelector(".iclub-global-ai-head-copy").getBoundingClientRect();
 const actions=panel.querySelector(".iclub-global-ai-head-actions").getBoundingClientRect();
 check(title.right<=actions.left+2,"header copy overlaps buttons");
 const input=panel.querySelector("[data-global-ai-input]").getBoundingClientRect();
 const send=panel.querySelector("[data-global-ai-send]").getBoundingClientRect();
 check(input.left>=rect.left-1&&input.right<=rect.right+1,"composer clips horizontally");
 check(send.right<=rect.right+1,"send button clips horizontally");
 check(document.documentElement.scrollWidth<=innerWidth+1,"page horizontal overflow");
 if(innerWidth<=600&&innerHeight>=520){
  const ratio=rect.height/innerHeight;
  check(ratio>=0.69&&ratio<=0.82,"mobile panel expected ~70-80%, actual "+ratio);
 }
 const expand=panel.querySelector("[data-global-ai-expand]");
 check(!!expand,"expand action missing");
 const label=expand.getAttribute("aria-label");
 check(label&&label.length>7,"expand action has no accessible label");
 expand.click();
 check(panel.getAttribute("data-expanded")==="true","expand failed");
 check(expand.getAttribute("aria-pressed")==="true","expand accessibility failed");
 const full=panel.getBoundingClientRect();
 check(Math.abs(full.left)<=1&&Math.abs(full.top)<=1,"fullscreen not pinned to origin x="+full.left+" y="+full.top+
  " transform="+getComputedStyle(panel).transform);
 check(Math.abs(full.width-innerWidth)<=1&&Math.abs(full.height-innerHeight)<=1,
  "full screen exceeds/underfills viewport");
 check(document.documentElement.scrollWidth<=innerWidth+1,"fullscreen caused overflow");
 expand.click();
 check(panel.getAttribute("data-expanded")==="false","restore failed");
 document.querySelector('[data-view="home"]').classList.remove("is-active");
 document.querySelector('[data-view="courses"]').classList.add("is-active");
 await sleep(145);
 check(panel.hidden,"old subject conversation remains visible after navigation");
 mark.click();
 check(!panel.hidden,"new subject conversation failed to open");
 window.dispatchEvent(new CustomEvent("iclub:exam-prep-session",{
  detail:{session:{session_type:"diagnostic",status:"active"}}
 }));
 check(mark.hidden,"AI icon not hidden for protected exam");
 check(panel.hidden,"panel not hidden for protected exam");
 check(getComputedStyle(mark).display==="none","AI icon still rendered during exam");
 window.dispatchEvent(new Event("iclub:exam-prep-session-ended"));
 await sleep(145);
 check(!mark.hidden,"icon did not recover after exam");
 // An ACTIVE ordinary Practice question (not finalized result/review) must
 // black out AI, and a late previous-screen answer must be discarded.
 const quiz=document.getElementById("courses-practice-quiz");
 const finish=document.getElementById("courses-practice-result");
 mark.click();
 check(!panel.hidden,"panel not available before ordinary Practice");
 let resolveQuizReply;
 window.__qaReplyHandler=()=>new Promise(resolve=>{resolveQuizReply=resolve;});
 panel.querySelector(".iclub-global-ai-quick-btn").click();
 for(let i=0;i<20&&!resolveQuizReply;i++)await sleep(10);
 check(!!resolveQuizReply,"synthetic pre-quiz AI request not started");
 quiz.classList.add("is-active");
 await sleep(110);
 check(mark.hidden,"AI icon leaked onto active Practice Quiz");
 check(panel.hidden,"AI panel leaked onto active Practice Quiz");
 check(getComputedStyle(mark).display==="none","CSS shows icon on Practice Quiz");
 resolveQuizReply({data:{ok:true,message:"PRIVATE_ACTIVE_QUIZ_OLD_RESPONSE",
  academic_state_changed:false},error:null});
 await sleep(210);
 quiz.classList.remove("is-active");
 finish.classList.add("is-active");
 await sleep(105);
 check(!mark.hidden,"finished Practice result incorrectly blocked AI mark");
 mark.click();
 const resultPanel=document.getElementById("iclub-global-ai-panel");
 check(!resultPanel.hidden,"result screen could not open panel");
 check(!resultPanel.querySelector("[data-global-ai-messages]").textContent.includes(
  "PRIVATE_ACTIVE_QUIZ_OLD_RESPONSE"),"stale AI answer visible after Practice");
 resultPanel.querySelector("[data-global-ai-close]").click();
 window.__qaReplyHandler=null;
 // Real async-response/account boundary: preserve same-user refresh, never
 // show the prior learner's messages after switching accounts.
 const uid1="11111111-1111-4111-8111-111111111111";
 const uid2="22222222-2222-4222-8222-222222222222";
 window.__qaEmitAuth("SIGNED_IN",uid1);
 await sleep(120);
 const accountOneMark=document.getElementById("iclub-global-ai-mark");
 check(accountOneMark&&!accountOneMark.hidden,"account A panel not ready");
 accountOneMark.click();
 const oldPanel=document.getElementById("iclub-global-ai-panel");
 check(oldPanel&&!oldPanel.hidden,"account A cannot open chat");
 let resolveOld;
 window.__qaReplyHandler=()=>new Promise(resolve=>{resolveOld=resolve;});
 oldPanel.querySelector(".iclub-global-ai-quick-btn").click();
 for(let i=0;i<20&&!resolveOld;i++)await sleep(10);
 check(!!resolveOld,"pending old-user synthetic response was not invoked");
 check(oldPanel.querySelector("[data-global-ai-messages]").textContent.length>0,
  "synthetic old user prompt not shown");
 window.__qaEmitAuth("SIGNED_IN",uid2);
 await sleep(120);
 resolveOld({data:{ok:true,message:"PRIVATE_OLD_USER_REPLY",
  academic_state_changed:false},error:null});
 await sleep(220);
 const accountTwoMark=document.getElementById("iclub-global-ai-mark");
 check(accountTwoMark&&!accountTwoMark.hidden,"account B panel not ready");
 accountTwoMark.click();
 const newPanel=document.getElementById("iclub-global-ai-panel");
 check(!newPanel.hidden,"account B panel did not open");
 check(!newPanel.querySelector("[data-global-ai-messages]").textContent.includes("PRIVATE_OLD_USER_REPLY"),
  "account B saw the old account's async reply");
 check(newPanel.querySelectorAll(".iclub-global-ai-message").length===0,
  "account B inherited account A conversation");
 window.__qaReplyHandler=async()=>({data:{ok:true,message:"SAFE_SECOND_ACCOUNT_REPLY",
  academic_state_changed:false},error:null});
 newPanel.querySelector(".iclub-global-ai-quick-btn").click();
 await sleep(250);
 check(newPanel.querySelector("[data-global-ai-messages]").textContent.includes("SAFE_SECOND_ACCOUNT_REPLY"),
  "account B answer missing");
 window.__qaEmitAuth("TOKEN_REFRESHED",uid2);
 await sleep(100);
 check(newPanel.querySelector("[data-global-ai-messages]").textContent.includes("SAFE_SECOND_ACCOUNT_REPLY"),
  "same-user token refresh unexpectedly cleared session chat");
 window.__qaEmitAuth("SIGNED_OUT",null);
 await sleep(100);
 const signedOutPanel=document.getElementById("iclub-global-ai-panel");
 if(signedOutPanel)check(!signedOutPanel.querySelector("[data-global-ai-messages]").textContent.includes("SAFE_SECOND_ACCOUNT_REPLY"),
  "signed-out account chat still visible");
 // QA-only V2 screen-binding contract. Original iClub app lacks these
 // markers: only this synthetic fixture attaches selectors for browser QA.
 const Binder=window.iClubQaV21ScreenBinder;
 check(typeof Binder==="function","QA-only binder was not injected");
 const screenCalls=[];
 const fakeClient={
  leave:async()=>{screenCalls.push(["revoke"]);return{ok:true};},
  openLesson:async id=>{screenCalls.push(["lesson",id]);return{ok:true};},
  openPractice:async(s,q)=>{screenCalls.push(["practice",s,q]);return{ok:true};},
  status:async()=>({ok:false,state:"in_development"}),
  askPrepared:async()=>({ok:false,state:"in_development"})
 };
 const binder=new Binder({client:fakeClient,document});
 const video=document.getElementById("courses-video");
 const review=document.getElementById("courses-practice-review");
 video.classList.add("is-active");
 check((await binder.sync()).reason==="screen_not_verified",
  "Real app without numeric V2 selector was incorrectly admitted");
 check(!screenCalls.some(x=>x[0]==="lesson"),"untrusted Lesson admitted");
 video.setAttribute("data-iclub-ai-v21-lesson-id","101");
 check((await binder.sync()).ok===true,"verified synthetic Lesson selector refused");
 check(screenCalls.some(x=>x[0]==="lesson"&&x[1]===101),
  "Lesson exact server-owned mint selector missing");
 video.classList.remove("is-active");
 review.classList.add("is-active");
 review.setAttribute("data-practice-ai-attempt-id","11");
 const question=document.createElement("span");
 question.setAttribute("data-iclub-ai-v21-question-id","202");
 question.setAttribute("data-iclub-ai-v21-selected","true");
 review.appendChild(question);
 check((await binder.sync()).reason==="screen_not_verified",
  "legacy Practice attempt ID was misused as V4 session");
 check(!screenCalls.some(x=>x[0]==="practice"),"legacy Practice was admitted");
 review.setAttribute("data-iclub-ai-v21-session-id","11");
 check((await binder.sync()).ok===true,"synthetic complete V4 Practice selector refused");
 check(screenCalls.some(x=>x[0]==="practice"&&x[1]===11&&x[2]===202),
  "V4 Practice exact pair missing");
 quiz.classList.add("is-active");
 check((await binder.sync()).reason==="screen_not_verified",
  "active quiz allowed V2 answer");
 quiz.classList.remove("is-active");
 await binder.disconnect();
 review.classList.remove("is-active");
 video.removeAttribute("data-iclub-ai-v21-lesson-id");
 review.removeAttribute("data-iclub-ai-v21-session-id");
 return {width:innerWidth,height:innerHeight,lang:new URL(location.href).searchParams.get("lang"),
  panelWidth:round(rect.width),panelHeight:round(rect.height),fullscreenWidth:round(full.width),
  fullscreenHeight:round(full.height),markNavigationGap:round(nav.top-markRect.bottom),
  headerGap:round(actions.left-title.right),expandLabel:label,examBlackout:true};
}
function chrome(){
 if(process.env.ICLUB_AI_CHROME){
  assert.ok(existsSync(process.env.ICLUB_AI_CHROME),"Explicit Chrome missing");
  return process.env.ICLUB_AI_CHROME;
 }
 for(const binary of ["google-chrome","google-chrome-stable","chromium","chromium-browser"]){
  const p=spawnSync("which",[binary],{encoding:"utf8"});
  if(p.status===0&&p.stdout.trim())return p.stdout.trim();
 }
 throw Error("No actual Chrome/Chromium binary: cannot claim browser GREEN");
}
async function activePort(directory,proc,getStderr){
 for(let attempt=0;attempt<200;attempt++){
  if(proc.exitCode!==null||proc.signalCode!==null)
   throw Error("Chrome exited before CDP: "+proc.exitCode+"/"+proc.signalCode+
    " stderr="+getStderr());
  const file=join(directory,"DevToolsActivePort");
  if(existsSync(file)){
   const port=Number(readFileSync(file,"utf8").split("\n")[0]);
   if(port>0)return port;
  }
  await delay(100);
 }
 throw Error("Chrome CDP port missing after 20s, running="+(proc.exitCode===null)+
  ", stderr="+getStderr());
}
async function connect(port){
 const r=await fetch("http://127.0.0.1:"+port+"/json/new?about:blank",{method:"PUT"});
 assert.equal(r.status,200);
 const descriptor=await r.json();
 const ws=new WebSocket(descriptor.webSocketDebuggerUrl);
 await new Promise((resolve,reject)=>{
  ws.addEventListener("open",resolve,{once:true});
  ws.addEventListener("error",reject,{once:true});
 });
 let id=0;const pending=new Map();
 ws.addEventListener("message",message=>{
  const payload=JSON.parse(message.data);
  if(!payload.id||!pending.has(payload.id))return;
  const next=pending.get(payload.id);pending.delete(payload.id);
  payload.error?next.reject(Error(JSON.stringify(payload.error))):
   next.resolve(payload.result||{});
 });
 return {
  call:(method,params={})=>new Promise((resolve,reject)=>{
   const next=++id;pending.set(next,{resolve,reject});
   ws.send(JSON.stringify({id:next,method,params}));
  }),close:()=>ws.close()
 };
}
async function run(){
 assert.ok(existsSync(html),"QA HTML fixture missing");
 const dir=mkdtempSync(join(tmpdir(),"iclub-ai-chrome-"));
 const processChrome=spawn(chrome(),[
  "--headless=new","--no-sandbox","--disable-gpu","--disable-dev-shm-usage",
  "--no-first-run","--disable-background-networking","--disable-extensions",
  "--allow-file-access-from-files","--remote-debugging-port=0",
  "--user-data-dir="+dir,"about:blank"
 ],{stdio:["ignore","ignore","pipe"],env:{...process.env,HOME:dir}});
 let stderr="";
 processChrome.stderr.on("data",chunk=>{
  stderr=(stderr+String(chunk)).slice(-4800);
 });
 let cdp=null;
 try{
  cdp=await connect(await activePort(dir,processChrome,()=>stderr));
  await cdp.call("Page.enable");
  await cdp.call("Runtime.enable");
  for(const size of viewports){
   await cdp.call("Emulation.setDeviceMetricsOverride",{
    width:size.width,height:size.height,deviceScaleFactor:1,mobile:size.width<=600
   });
   await cdp.call("Page.navigate",{url:pathToFileURL(html).href+"?lang="+size.lang});
   let initialized=false;
   for(let attempt=0;attempt<70;attempt++){
    const x=await cdp.call("Runtime.evaluate",{
     expression:"Boolean(window.iClubGlobalAiShell&&document.getElementById('iclub-global-ai-mark'))",
     returnByValue:true
    });
    if(x.result?.value===true){initialized=true;break;}
    await delay(70);
   }
   assert.ok(initialized,"QA UI did not bootstrap for "+size.width+"x"+size.height);
   const output=await cdp.call("Runtime.evaluate",{
    expression:"("+browserCheck.toString()+")()",awaitPromise:true,returnByValue:true
   });
   if(output.exceptionDetails)throw Error("Browser assertion failed for "+
    size.width+"x"+size.height+": "+JSON.stringify(output.exceptionDetails).slice(0,1200));
   const data=output.result?.value;
   assert.equal(data?.width,size.width,"Viewport width emulation mismatch");
   assert.equal(data?.height,size.height,"Viewport height emulation mismatch");
   console.log("BROWSER_GREEN "+JSON.stringify(data));
  }
 }finally{
  try{cdp?.close()}catch{}
  processChrome.kill("SIGKILL");
  rmSync(dir,{recursive:true,force:true});
 }
 console.log("GREEN: genuine Chrome CSS/layout/interaction smoke, no remote services");
}
run().catch(e=>{console.error("BROWSER_FAIL "+String(e.stack||e));process.exitCode=1;});
