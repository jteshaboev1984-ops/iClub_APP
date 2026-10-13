// QA P1/P3: ORIGINAL iClub HTML/CSS+isolated synthetic controller browser check.
// Node 22 and a real headless Chromium; no real account/DB/provider.
"use strict";
const fs=require("node:fs"),http=require("node:http"),path=require("node:path");
const {spawn,spawnSync}=require("node:child_process"),{tmpdir}=require("node:os");
const {setTimeout:wait}=require("node:timers/promises"),assert=require("node:assert/strict");
const root=path.resolve(__dirname,".."),tmp=fs.mkdtempSync(path.join(tmpdir(),"iclub-real-ui-"));
let app,chrome,session;
function chromeExe(){
 if(process.env.ICLUB_AI_CHROME)return process.env.ICLUB_AI_CHROME;
 for(const name of ["google-chrome","chromium","chromium-browser"]){
  const x=spawnSync("which",[name],{encoding:"utf8"});
  if(x.status===0&&x.stdout.trim())return x.stdout.trim();
 }
 throw Error("Chrome required for actual UI acceptance");
}
async function debuggerPort(){
 for(let i=0;i<150;i++){
  if(chrome.exitCode!==null)throw Error("Chrome unexpectedly quit");
  const filename=path.join(tmp,"DevToolsActivePort");
  if(fs.existsSync(filename)){
   const port=Number(fs.readFileSync(filename,"utf8").split("\n")[0]);
   if(port>0)return port;
  }
  await wait(100);
 }
 throw Error("Devtools unavailable");
}
async function openClient(port){
 const response=await fetch("http://127.0.0.1:"+port+"/json/new?about:blank",{method:"PUT"});
 assert.equal(response.status,200);
 const sock=new WebSocket((await response.json()).webSocketDebuggerUrl);
 await new Promise((resolve,reject)=>{
  sock.addEventListener("open",resolve,{once:true});
  sock.addEventListener("error",reject,{once:true});
 });
 let seq=0;const pending=new Map(),urls=[];
 sock.addEventListener("message",event=>{
  const data=JSON.parse(event.data);
  if(data.method==="Network.requestWillBeSent")urls.push(data.params.request.url);
  if(data.id&&pending.has(data.id)){
   const slot=pending.get(data.id);pending.delete(data.id);
   data.error?slot.reject(Error(JSON.stringify(data.error))):slot.resolve(data.result);
  }
 });
 return{urls,send:(method,params={})=>new Promise((resolve,reject)=>{
  const id=++seq;pending.set(id,{resolve,reject});
  sock.send(JSON.stringify({id,method,params}));
 }),close:()=>sock.close()};
}
async function exercise(lang){
 const sleep=n=>new Promise(r=>setTimeout(r,n));
 const check=(v,msg)=>{if(!v)throw Error(msg)};
 for(let n=0;n<90&&!window.__iclubQaRealUiStatus;n++)await sleep(40);
 check(typeof window.__iclubQaRealUiStatus==="function","real UI controller missing");
 const select=document.getElementById("qa-lang");select.value=lang;
 select.dispatchEvent(new Event("change"));await sleep(120);
 const mark=document.getElementById("iclub-global-ai-mark");
 check(mark&&!mark.hidden,"iClub AI not visible on native Home");
 document.querySelector('#tabbar [data-tab="courses"]').click();
 await sleep(60);
 check(document.getElementById("view-courses").classList.contains("is-active"),
  "native Study tab not active");
 document.querySelector("#subjects-grid button").click();
 await sleep(35);
 check(document.getElementById("courses-subject-hub").classList.contains("is-active"),
  "native Subject Hub not opened");
 document.querySelector('[data-action="open-practice"]').click();
 document.querySelector('[data-action="practice-start"]').click();
 await sleep(150);
 check(document.getElementById("courses-practice-quiz").classList.contains("is-active"),
  "native Practice quiz missing");
 check(mark.hidden&&getComputedStyle(mark).display==="none",
  "AI mark exposed during active Practice");
 const answer=()=>{
  const option=document.querySelector("#practice-options button");
  check(option,"question choices missing");option.click();
  document.getElementById("practice-submit-btn").click();
 };
 answer();await sleep(45);answer();await sleep(120);
 check(document.getElementById("courses-practice-result").classList.contains("is-active"),
  "native result missing");
 check(document.getElementById("practice-result-meta").textContent.includes("1/2"),
  "synthetic deterministic result wrong");
 check(!mark.hidden,"AI did not return after finished Practice");
 document.querySelector('[data-action="practice-review"]').click();
 await sleep(90);
 check(document.querySelectorAll("#practice-review-list .iclub-qa-review").length===2,
  "native review list missing answered questions");
 const cards=Array.from(document.querySelectorAll("#practice-review-list .iclub-qa-review"));
 const review=cards[0],mistake=cards[1];
 const explain=review.querySelector('[data-qa-ai-action="explain"]');
 const ask=review.querySelector('[data-qa-ai-action="chat"]');
 const mistakeExplain=mistake.querySelector('[data-qa-ai-action="explain"]');
 check(explain&&ask&&mistakeExplain,"Review needs separate Explain and Ask buttons");
 check(review.querySelectorAll('img[src*="iclub-ai-mark-temp.jpg"]').length===2,
  "Working Exam Prep AI icon missing from contextual actions");
 check(explain.textContent.includes({ru:"решение",uz:"Yechimni",en:"solution"}[lang]),
  "Correct answer incorrectly described as a mistake");
 check(mistakeExplain.textContent.includes({ru:"ошибку",uz:"Xatoni",en:"mistake"}[lang]),
  "Incorrect answer not described as a mistake");
 explain.click();explain.click();
 await sleep(48);
 const panel=document.getElementById("iclub-global-ai-panel");
 check(panel&&!panel.hidden,"auto explain did not open AI panel");
 const input=panel.querySelector("[data-global-ai-input]");
 check(input.value.includes({ru:"Объясни решение",uz:"to‘g‘ri yechimini",en:"Explain the solution"}[lang]),
  "prepared input does not match correct-answer state");
 await sleep(470);
 const text=panel.querySelector("[data-global-ai-messages]").textContent;
 const expected={ru:"рост цены",uz:"narx oshishi",en:"price increase"}[lang];
 check(text.toLowerCase().includes(expected.toLowerCase()),
  "correct-answer explanation missing: "+text.slice(-160));
 const userBubbles=()=>panel.querySelectorAll(".iclub-global-ai-message.is-user");
 const assistantBubbles=()=>panel.querySelectorAll(".iclub-global-ai-message.is-assistant:not(.is-typing)");
 check(userBubbles().length===1,"double-tap dispatched repeated request");
 check(assistantBubbles().length===1,"automatic answer missing or duplicated");
 check(panel.querySelectorAll(".iclub-global-ai-quick-btn").length===0,
  "duplicate quick explanation action still visible");
 check(panel.querySelector("[data-global-ai-subtitle]").textContent.includes({
  ru:"Задание 1",uz:"Savol 1",en:"Question 1"}[lang]),
  "selected question context missing from header");
 check(panel.querySelectorAll('[data-qa-question-id="202"]').length===2,
  "question identity must label both message bubbles");

 // Revisiting the same completed question must not append/bill a second reply.
 window.iClubGlobalAiShell.close();
 explain.click();await sleep(115);
 check(!panel.hidden,"cached explanation did not reopen");
 check(userBubbles().length===1&&assistantBubbles().length===1,
  "cached explanation repeated a request or response");
 check(input.value==="","cached explanation must not repopulate composer");

 // Select a different answer; its content and label cannot be Q1's answer.
 window.iClubGlobalAiShell.close();
 mistakeExplain.click();await sleep(450);
 check(userBubbles().length===2&&assistantBubbles().length===2,
  "different question must have one new response");
 const reply2=Array.from(assistantBubbles()).at(-1).textContent;
 check(reply2.includes({ru:"Ты выбрал",uz:"Siz",en:"You chose"}[lang]),
  "wrong-answer reply ignored the selected wrong option");
 check(reply2.includes({ru:"угадать",uz:"taxmin",en:"guess"}[lang]),
  "wrong-answer reply was not specific to the student's choice");
 check(panel.querySelector("[data-global-ai-subtitle]").textContent.includes("2"),
  "Q2 header did not update");
 check(panel.querySelectorAll('[data-qa-question-id="203"]').length===2,
  "Q2 response not labeled independently from Q1");
 window.iClubGlobalAiShell.close();
 explain.click();await sleep(100);
 check(userBubbles().length===2&&assistantBubbles().length===2,
  "return to Q1 caused duplicate instead of cache hit");

 // Ask AI is a separate blank chat, with an explicit question header only.
 window.iClubGlobalAiShell.close();
 const originalCount=panel.querySelectorAll(".iclub-global-ai-message").length;
 ask.click();await sleep(90);
 check(!panel.hidden&&input.value==="",
  "Ask AI must open blank editable composer");
 check(panel.querySelectorAll(".iclub-global-ai-message").length===originalCount,
  "Ask AI must not automatically submit");
 check(panel.querySelector("[data-global-ai-subtitle]").textContent.includes("1"),
  "Ask AI lost question context");
 input.value={ru:"Почему?",uz:"Nima uchun?",en:"Why?"}[lang];
 input.dispatchEvent(new Event("input",{bubbles:true}));
 const send=panel.querySelector("[data-global-ai-send]");
 check(!send.disabled,"Manual composer did not activate");
 send.click();await sleep(360);
 const last=Array.from(assistantBubbles()).at(-1)?.textContent||"";
 check(last.includes({ru:"В разработке",uz:"ishlab",en:"In development"}[lang]),
  "Unreleased free-text route fabricated an answer");
 check(userBubbles().length===3,"Manual question submitted more than once");
 check(!panel.querySelector(".iclub-global-ai-mark-logo"),
  "No extra AI logos inside chat");

 // Expansion must render a styled (not empty square) icon and actually expand.
 const expand=panel.querySelector("[data-global-ai-expand]");
 check(!!expand,"Expand button absent");
 const symbol=expand.querySelector("svg"),bounds=expand.getBoundingClientRect();
 const ink=symbol?getComputedStyle(symbol):null;
 check(bounds.width>=32&&bounds.height>=32&&
       symbol?.getBoundingClientRect().width>=15&&
       ink?.stroke!=="none"&&Number.parseFloat(ink.strokeWidth)>=1,
  "Expand visual is missing: "+JSON.stringify({width:bounds.width,
   height:bounds.height,stroke:ink?.stroke,line:ink?.strokeWidth,
   display:getComputedStyle(expand).display}));
 expand.click();await sleep(60);
 check(panel.getAttribute("data-expanded")==="true",
  "Expand button did not expand AI panel");
 const icon=document.querySelector("#iclub-global-ai-mark .iclub-global-ai-mark-logo");
 check(icon&&icon.getAttribute("src").includes("iclub-ai-mark-temp.jpg"),
  "Global AI icon differs from Exam Prep");
 const width=document.documentElement.scrollWidth;
 check(width<=innerWidth+2,"horizontal scroll "+width+" / "+innerWidth);
 document.querySelector('#tabbar [data-tab="home"]').click();
 await sleep(90);
 check(panel.hidden,"panel persisted after switching to Home");
 check(window.__iclubQaRealUiStatus().binderReady===false,
  "screen context was not invalidated on navigation");
 const protection=document.getElementById("qa-protected");
 protection.click();await sleep(90);
 check(mark.hidden,"protected Exam Prep icon leaked");
 protection.click();await sleep(90);
 check(!mark.hidden,"icon failed to restore after protected exam");
 return{width:innerWidth,height:innerHeight,lang,realMarkup:true,
  originalCSS:true,practiceBlackout:true,completedReview:true,
  preparedExplanation:true,protectedExam:true,externalRequests:0};
}
async function main(){
 app=http.createServer((req,res)=>{
  const url=new URL(req.url||"/","http://127.0.0.1");
  let file=path.resolve(root,"."+decodeURIComponent(url.pathname));
  if(file===root)file=path.join(root,"qa/ai-real-ui-preview.html");
  if(!file.startsWith(root+path.sep)||!fs.existsSync(file)||fs.statSync(file).isDirectory()){
   res.writeHead(404);res.end();return;
  }
  const type=/\.css$/i.test(file)?"text/css":/\.js$/i.test(file)?"text/javascript":
   /\.html$/i.test(file)?"text/html":/\.svg$/i.test(file)?"image/svg+xml":
   /\.png$/i.test(file)?"image/png":"application/octet-stream";
  res.writeHead(200,{"content-type":type+"; charset=utf-8","x-robots-tag":"noindex,nofollow"});
  res.end(fs.readFileSync(file));
 });
 await new Promise(done=>app.listen(0,"127.0.0.1",done));
 const origin="http://127.0.0.1:"+app.address().port;
 chrome=spawn(chromeExe(),["--headless=new","--no-sandbox","--disable-gpu",
  "--disable-dev-shm-usage","--disable-background-networking","--no-first-run",
  "--disable-extensions","--remote-debugging-port=0","--user-data-dir="+tmp,
  "about:blank"],{stdio:"ignore"});
 try{
  session=await openClient(await debuggerPort());
  await session.send("Page.enable");await session.send("Runtime.enable");
  await session.send("Network.enable");
  for(const x of [{w:320,h:568,lang:"ru"},{w:390,h:844,lang:"uz"},
   {w:1366,h:768,lang:"en"}]){
   await session.send("Emulation.setDeviceMetricsOverride",{
    width:x.w,height:x.h,deviceScaleFactor:1,mobile:x.w<600
   });
   await session.send("Page.navigate",{url:origin+"/qa/ai-real-ui-preview.html"});
   const out=await session.send("Runtime.evaluate",{
    expression:"("+exercise.toString()+")("+JSON.stringify(x.lang)+")",
    awaitPromise:true,returnByValue:true
   });
   if(out.exceptionDetails)throw Error("Real UI "+x.w+"x"+x.h+" FAIL: "+
    JSON.stringify(out.exceptionDetails).slice(0,1550));
   assert.equal(out.result?.value?.width,x.w);
   console.log("REAL_ICLUB_AI_GREEN "+JSON.stringify(out.result.value));
  }
  const unexpected=session.urls.filter(x=>!x.startsWith(origin+"/")&&!x.startsWith("data:"));
  assert.deepEqual(unexpected,[],"No external requests, ever");
  console.log("GREEN: native iClub markup/CSS and isolated synthetic AI; external requests=0");
 }finally{
  try{session?.close()}catch{}
  chrome.kill("SIGKILL");
  if(chrome.exitCode===null&&chrome.signalCode===null)
   await Promise.race([new Promise(done=>chrome.once("exit",done)),wait(1800)]);
  try{fs.rmSync(tmp,{recursive:true,force:true,maxRetries:8,retryDelay:125});}catch{}
  await new Promise(done=>app.close(done));
 }
}
main().catch(err=>{console.error("REAL_ICLUB_AI_FAIL "+String(err.stack||err));process.exitCode=1;});
