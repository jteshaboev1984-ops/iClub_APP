"use strict";
// §74 isolated native Chrome accessibility-tree QA: actual tabbar markup,
// original i18n.js, reversible preview transformation, no app/live resources.
const {readFileSync,mkdtempSync,rmSync,existsSync}=require("node:fs");
const {spawn,spawnSync}=require("node:child_process");
const {join,resolve}=require("node:path");
const {tmpdir}=require("node:os");
const {setTimeout:delay}=require("node:timers/promises");
const assert=require("node:assert/strict");
const {makeAccessibleNavPreview}=require("./ai-layer-v21-p6-nav-a11y-preview.cjs");
const root=resolve(__dirname,"..");
const read=file=>readFileSync(join(root,file),"utf8");
const original=read("index.html"),candidate=makeAccessibleNavPreview(original).html;
const i18n=read("i18n.js"),app=read("app.js");
assert.match(app,/function applyStaticI18n\(\)\s*\{/);
assert.match(app,/document\.querySelectorAll\("\[data-i18n\]"\)\.forEach/);
const start=candidate.indexOf('<nav id="tabbar"');
const end=candidate.indexOf("</nav>",start);
assert(start>0&&end>start);
const nav=candidate.slice(start,end+6);
const documentHtml='<!doctype html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><style>'+
 'body{margin:0;font-family:Arial,sans-serif}.tabbar{display:grid;grid-template-columns:repeat(4,1fr);height:64px}'+
 '.tab{border:0;background:white;display:flex;flex-direction:column;align-items:center;justify-content:center;gap:4px}'+
 '.tab-ico{height:24px;width:24px}.tab-ico svg{height:24px;width:24px}.tab-txt{font-size:11px}'+
 '</style></head><body>'+nav+'</body></html>';
function chromeExe(){
 if(process.env.ICLUB_AI_CHROME)return process.env.ICLUB_AI_CHROME;
 for(const exe of ["google-chrome","google-chrome-stable","chromium","chromium-browser"]){
  const r=spawnSync("which",[exe],{encoding:"utf8"});
  if(r.status===0&&r.stdout.trim())return r.stdout.trim();
 }throw Error("Chromium required for native accessibility verification");
}
async function portFor(dir,child){
 for(let i=0;i<150;i++){
  if(child.exitCode!==null)throw Error("Chromium closed early");
  const p=join(dir,"DevToolsActivePort");
  if(existsSync(p)){
   const n=Number(readFileSync(p,"utf8").split("\n")[0]);
   if(n>0)return n;
  }
  await delay(75);
 }throw Error("Chromium CDP timed out");
}
async function connect(port){
 const q=await fetch("http://127.0.0.1:"+port+"/json/new?about:blank",{method:"PUT"});
 assert.equal(q.status,200);
 const ws=new WebSocket((await q.json()).webSocketDebuggerUrl);
 await new Promise((yes,no)=>{
  ws.addEventListener("open",yes,{once:true});
  ws.addEventListener("error",no,{once:true});
 });
 let next=0;const pending=new Map(),network=[];
 ws.addEventListener("message",evt=>{
  const obj=JSON.parse(evt.data);
  if(obj.method==="Network.requestWillBeSent")network.push(obj.params.request.url);
  if(!obj.id||!pending.has(obj.id))return;
  const p=pending.get(obj.id);pending.delete(obj.id);
  obj.error?p.reject(Error(JSON.stringify(obj.error))):p.resolve(obj.result||{});
 });
 return{network,send:(method,params={})=>new Promise((yes,no)=>{
  const id=++next;pending.set(id,{resolve:yes,reject:no});
  ws.send(JSON.stringify({id,method,params}));
 }),close:()=>ws.close()};
}
const tabs=["home","courses","ratings","profile"];
async function run(){
 const dir=mkdtempSync(join(tmpdir(),"iclub-nav-a11y-qa-"));
 const child=spawn(chromeExe(),["--headless=new","--no-sandbox","--disable-gpu",
  "--disable-dev-shm-usage","--disable-extensions","--disable-background-networking",
  "--no-first-run","--remote-debugging-port=0","--user-data-dir="+dir,"about:blank"],
  {stdio:"ignore"});
 let browser;
 try{
  browser=await connect(await portFor(dir,child));
  await browser.send("Page.enable");await browser.send("Runtime.enable");
  await browser.send("Accessibility.enable");await browser.send("Network.enable");
  for(const cfg of [{lang:"ru",w:320,h:568},{lang:"uz",w:390,h:844},
   {lang:"en",w:1366,h:768}]){
   await browser.send("Emulation.setDeviceMetricsOverride",{width:cfg.w,
    height:cfg.h,deviceScaleFactor:1,mobile:cfg.w<600});
   await browser.send("Page.navigate",{url:"data:text/html;charset=utf-8,"+
    encodeURIComponent(documentHtml)});
   // CDP Page.navigate signals navigation acceptance, not DOM completion.
   let settled=false;
   for(let attempt=0;attempt<50;attempt++){
    const state=await browser.send("Runtime.evaluate",{expression:
     'document.readyState==="complete" && !!document.querySelector("#tabbar button")',
     returnByValue:true});
    if(state.result?.value===true){settled=true;break;}
    await delay(20);
   }
   assert(settled,"Isolated accessible-nav DOM did not finish loading");
   // Original i18n code is executed against an isolated static data document,
   // not against the real app or a production Supabase session.
   let result=await browser.send("Runtime.evaluate",{expression:i18n,
    awaitPromise:true,returnByValue:true});
   if(result.exceptionDetails)throw Error("Original i18n failed to initialize");
   result=await browser.send("Runtime.evaluate",{
    expression:"(()=>{window.i18n.setLang("+JSON.stringify(cfg.lang)+");"+
     "for(const e of document.querySelectorAll('[data-i18n]'))"+
     "{e.textContent=window.i18n.t(e.dataset.i18n);}"+
     "const b=[...document.querySelectorAll('button[data-tab]')];"+
     "b[0].focus();"+
     "return {labels:b.map(x=>x.querySelector('.tab-txt').textContent),"+
     "focused:b[0]===document.activeElement,overrides:b.filter(x=>x.hasAttribute('aria-label')).length,"+
     "buttons:b.length,htmlLang:document.documentElement.lang,bodyText:document.body.innerText};"+
     "})()",awaitPromise:true,returnByValue:true});
   if(result.exceptionDetails)throw Error(JSON.stringify(result.exceptionDetails));
   const visible=result.result.value;
   assert.equal(visible.buttons,4);assert.equal(visible.focused,true);
   assert.equal(visible.htmlLang,cfg.lang);assert.equal(visible.overrides,0);
   const tree=await browser.send("Accessibility.getFullAXTree");
   const accessible=(tree.nodes||[]).filter(x=>x.role?.value==="button"&&
    !x.ignored).map(x=>x.name?.value).filter(x=>typeof x==="string");
   assert.deepEqual(accessible,visible.labels,
    "Accessibility tree must exactly match visible "+cfg.lang+" button captions");
   const bounds=await browser.send("Runtime.evaluate",{expression:
    "[...document.querySelectorAll('button[data-tab]')].map(x=>"+ 
    "{const r=x.getBoundingClientRect();return {left:r.left,width:r.width,right:r.right};})",
    returnByValue:true});
   const widths=bounds.result.value;
   assert.equal(widths.length,4);
   assert(widths.every(x=>x.width>0&&x.left>=0&&x.right<=cfg.w+1),
    "No preview bottom tab should clip outside viewport");
   console.log("P6_NAV_A11Y_BROWSER_GREEN "+
    JSON.stringify({locale:cfg.lang,viewport:cfg.w+"x"+cfg.h,
     accessibleNames:accessible,tabButtons:4,focus:true}));
  }
  for(const url of browser.network)
   assert(url.startsWith("data:"),"Unexpected outbound request: "+url);
  console.log("GREEN: accessible iClub tab name candidate, 3 locales, 3 viewports, zero external requests");
 }finally{
  try{browser?.close()}catch{}
  child.kill("SIGKILL");
  await Promise.race([new Promise(r=>child.once("exit",r)),delay(1000)]);
  rmSync(dir,{recursive:true,force:true,maxRetries:3});
 }
}
run().catch(err=>{console.error(err);process.exitCode=1;});
