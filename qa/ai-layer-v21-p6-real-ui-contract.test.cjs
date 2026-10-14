"use strict";
// §59 independent source-of-truth contract against unchanged production UI.
const {test}=require("node:test"),assert=require("node:assert/strict");
const {readFileSync}=require("node:fs");
const app=readFileSync("app.js","utf8");
const html=readFileSync("index.html","utf8");
const script=readFileSync("qa/ai-layer-v21-p6-app-screen-binding.cjs","utf8");
const supported=["home","courses","ratings","profile","about","support"];
const forbidden=["splash","registration","notifications","community",
 "support-topic","certificates","certificate-verify","archive","resources","news"];
const nested=["courses-video","courses-practice-start","courses-practice-result",
 "courses-practice-review","courses-practice-recs","courses-tour-rules",
 "courses-tour-result","courses-tour-review","courses-my-rec-detail"];
test("§59 candidate selectors match app's real route registry and unchanged DOM",()=>{
 assert.ok(app.includes('function showView(viewName)'));
 assert.ok(app.includes('el.classList.toggle("is-active", v === viewName)'));
 assert.ok(html.includes('id="main"'));
 for(const view of supported){
  assert.ok(app.includes('"'+view+'"'),"missing router view "+view);
  assert.ok(html.includes('id="view-'+view+'"'),"missing actual DOM "+view);
  assert.ok(script.includes('"'+view+'"'),"QA binder forgot "+view);
 }
 for(const view of forbidden){
  assert.equal(script.includes('"' + view + '"'),false,
   "Potential unsupported page became a user-facing allowlisted view: "+view);
 }
});
test("§59 every active nested educational result is excluded from global Help",()=>{
 for(const screen of nested){
  assert.ok(html.includes('id="'+screen+'"'),"real source changed: "+screen);
  assert.ok(script.includes('"'+screen+'"'),"dangerous nested view not blocked "+screen);
 }
 for(const active of ["courses-practice-quiz","courses-tour-quiz","exam-prep-host-root"])
  assert.ok(script.includes('"'+active+'"'));
 assert.ok(script.includes('querySelectorAll?.(".view.is-active")'),
  "cannot detect second hidden active global view");
});
test("§59 no detached integration source is loaded or auto-enabled in production",()=>{
 for(const file of ["ai-layer-v21-p6-app-screen-binding.cjs",
  "ai-layer-v21-ui-transport.cjs","ai-layer-v21-p6-editorial-source-packet.cjs"]){
  assert.equal(html.includes(file),false,file);
  assert.equal(app.includes(file),false,file);
 }
 assert.ok(!script.includes("localStorage.setItem"));
 assert.ok(!script.includes("fetch("));
 assert.ok(!script.includes("supabase."));
});
