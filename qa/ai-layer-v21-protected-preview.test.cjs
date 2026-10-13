"use strict";
const {test}=require("node:test"),assert=require("node:assert/strict");
const {readFileSync}=require("node:fs");
const {resolve}=require("node:path");
const base=resolve(__dirname,"protected-preview");
const read=filename=>readFileSync(resolve(base,filename),"utf8");
const page=read("index.html"),ui=read("preview-controller.js"),css=read("preview.css");
test("Protected preview is self-contained: no Supabase, SDK, external calls or storage",()=>{
 for(const source of [page,ui,css]){
  for(const blocked of [/https?:\/\//i,/supabase\.co/i,/supabase-js/i,
   /localStorage/,/sessionStorage/,/XMLHttpRequest/,/fetch\(/, /navigator\.sendBeacon/,
   /serviceWorker/,/WebSocket\(/,/paymentIntent/]){
   assert.doesNotMatch(source,blocked,blocked.toString());
  }
 }
 assert.match(page,/connect-src 'none'/);
 assert.match(page,/noindex,nofollow,noarchive/);
 assert.match(page,/base-uri 'none'/);
 assert.match(page,/form-action 'none'/);
 assert.match(page,/script src="\/global-ai-ui\.js"/);
});
test("All UI assets are local, and preview imports REAL QA v2 binder/glue/publisher/transport",()=>{
 for(const path of ["global-ai-ui.css","global-ai-ui.js","transport.js","screen-binder.js",
  "evidence-publisher.js","preview-glue.js"]){
  assert.ok(page.includes('="/'+path+'"'),path);
 }
 for(const path of ["../../global-ai-ui.js","../../global-ai-ui.css",
  "../ai-layer-v21-ui-transport.cjs","../ai-layer-v21-screen-binding.cjs",
  "../ai-layer-v21-evidence-publisher.cjs","../ai-layer-v21-preview-glue.cjs"])
  assert.ok(readFileSync(resolve(base,path),"utf8").length>100,path);
});
test("Synthetic Practice only follows fully completed quiz -> result -> reviewed exact V4 question",()=>{
 assert.match(ui,/safeSessionId:SYNTHETIC_SESSION/);
 assert.match(ui,/finalized\(\{quiz:safeQuiz\(\),finalResult:/);
 assert.match(ui,/reviewRendered\(\{attemptId:SYNTHETIC_ATTEMPT/);
 assert.match(ui,/body\.sessionId!==SYNTHETIC_SESSION/);
 assert.match(ui,/body\.promptKey!=="topic_main"/);
 assert.match(ui,/if\(view==="courses"&&screen==="practice-quiz"\)/);
 assert.match(ui,/bridge\.selectQuestion\(q\.id\)/);
});
test("Synthetic preview cannot be mistaken for real iClub release",()=>{
 assert.match(page,/preview-banner/);
 assert.match(page,/qaBanner/);
 assert.match(page,/noRealData/);
 assert.doesNotMatch(ui,/createClient|service_role|auth\.signUp|auth\.signIn|sessionStorage/);
 assert.match(ui,/realNetwork:false/);
 assert.match(ui,/__ICLUB_AI_V21_SYNTHETIC_ONLY__/);
});
test("All 3 languages have complete readable UI translations and same question count",()=>{
 const keys=[...page.matchAll(/data-i18n="([^"]+)"/g)].map(x=>x[1]);
 for(const key of new Set(keys)){
  for(const lang of ["ru","uz","en"]){
   const label=" "+lang+":{";
   const from=ui.indexOf(label),until=ui.indexOf("\n ",from+label.length);
   assert.ok(from>=0,lang);
   assert.ok(ui.slice(from,from+5000).includes(key+":"),lang+":"+key);
  }
 }
 for(const label of ["q1","q2","q1a","q2a","ex1","ex2"])
  assert.equal((ui.match(new RegExp(label+':','g'))||[]).length,3,label);
});
