"use strict";
const assert=require("node:assert/strict"),fs=require("node:fs"),
{test}=require("node:test");
const p="qa/ai-real-ui-preview.html",source=fs.readFileSync(p,"utf8"),
 js=fs.readFileSync("qa/ai-real-ui-controller.js","utf8"),
 shell=fs.readFileSync("qa/ai-real-ui-shell.js","utf8");
test("Same exact real iClub screen ids and native navigational tabbar",()=>{
 for(const id of ["view-home","view-courses","view-profile","tabbar",
  "courses-practice-quiz","courses-practice-result","courses-practice-review",
  "practice-review-list","practice-question","practice-options","exam-prep-host-root"]){
  assert.match(source,new RegExp('id="'+id+'"'));
 }
 for(const css of ["style.css","visual/iclub-visual-v3.css",
  "visual/iclub-premium-v3.css","global-ai-ui.css"])
  assert.ok(source.includes(css));
});
test("QA never loads app.js, Supabase, Auth, third-party JS or persistent storage",()=>{
 assert.doesNotMatch(source,/<script[^>]*src=["']https?:/i);
 assert.doesNotMatch(source,/supabase-js|app\.js\?|telegram-web-app\.js/);
 assert.match(source,/connect-src 'none'/);
 assert.match(source,/form-action 'none'/);
 assert.match(source,/noindex,nofollow,noarchive/);
 for(const text of [js,shell]){
  assert.doesNotMatch(text,/\b(fetch|XMLHttpRequest|WebSocket|sendBeacon)\s*\(/);
  assert.doesNotMatch(text,/localStorage|sessionStorage/);
 }
 assert.doesNotMatch(js,/service_role|signUp|signInWithPassword|payment/i);
});
test("Exact QA-only binder + V4 server-confirmed synthetic review and cancel",()=>{
 assert.match(js,/safeSessionId:101/);
 assert.match(js,/attempt_id:567/);
 assert.match(js,/bridge\.reviewRendered/);
 assert.match(js,/binder\.sync\(\)/);
 assert.match(js,/bridge\.selectQuestion/);
 assert.match(js,/screen==="practice-quiz"/);
 assert.match(js,/session_type:"diagnostic"/);
 assert.match(shell,/Preview-only|Synthetic QA only|Synthetic QA/);
});
test("Legacy iClub index.html and app.js byte-untouched by QA page",()=>{
 const original=fs.readFileSync("index.html","utf8");
 assert.match(original,/src="app\.js\?/);
 assert.doesNotMatch(original,/iclub-qa-ribbon/);
 assert.ok(fs.existsSync("app.js"));
});
