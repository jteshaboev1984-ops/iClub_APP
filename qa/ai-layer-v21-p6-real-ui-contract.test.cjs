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
const ALL_NESTED=["all-subjects","subject-hub","lessons","video",
 "practice-start","practice-quiz","practice-result","practice-review",
 "practice-recs","tours","tour-rules","tour-quiz","tour-result",
 "tour-review","books","my-recs","my-rec-detail"];
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
test("§61 ALL real nested Courses routes are isolated from General Help",()=>{
 const routes=/const COURSES_SCREENS = \[([\s\S]*?)\];/.exec(app);
 assert.ok(routes,"actual Courses route registry changed");
 const actual=[...routes[1].matchAll(/"([a-z-]+)"/g)].map(m=>m[1]);
 assert.deepEqual(actual,ALL_NESTED,"new or rearranged Courses routes need QA review");
 assert.equal(actual.length,17);
 for(const name of actual){
  assert.ok(html.includes('id="courses-'+name+'"'),
   "missing Courses stack screen "+name);
 }
 assert.ok(script.includes('#view-courses .stack-screen.is-active'),
  "global helper no longer checks the entire nested academic stack");
 assert.ok(script.includes('stack.length!==1'),
  "global helper fails to reject two active nested pages");
 assert.ok(script.includes('stack[0]?.id!=="courses-all-subjects"'),
  "Global Help must be restricted to the non-academic subject list");
 assert.ok(script.includes('querySelectorAll?.(".view.is-active")'),
  "unknown global overlay must be rejected");
 assert.ok(script.includes('"exam-prep-host-root"'),"Exam Prep protected host drift");
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
