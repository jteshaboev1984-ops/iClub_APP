"use strict";
const {test}=require("node:test"),a=require("node:assert/strict");
const {readFileSync}=require("node:fs");
const vm=require("node:vm");
const read=x=>readFileSync(x,"utf8");
const client=read("iclub-ai-v21-beta-client.js"),ui=read("iclub-ai-v21-ui.js");
test("real current production beta UI can be parsed and uses additive model route only",()=>{
 new vm.Script(client,{filename:"beta-client.js"});
 new vm.Script(ui,{filename:"beta-ui.js"});
 a.match(client,/const EDGE="iclub-ai-v21-prepared"/);
 a.match(client,/async function askPrepared/);
 a.match(client,/async function askAcademic/);
 a.match(client,/async function askGenerated/);
 a.match(client,/client\.auth\.getSession\(\)/);
 a.match(client,/fetch\(/);
 a.ok(client.includes('expectedOrigin+"/functions/v1/iclub-ai-v21-freeform-beta"'));
 a.match(client,/credentials:"omit"/);
 a.match(client,/signal:controller\.signal/);
 a.match(client,/clearTimeout\(timer\)/);
 a.doesNotMatch(client.slice(client.indexOf("async function askGenerated"),
   client.indexOf("// Unified learner-scoped source bridge")),/functions\.invoke/);
 a.match(client,/status,consentFromExplicitUserAction,askPrepared,askGenerated/);
 a.match(ui,/body\?\.subject_key === "general"/);
 a.match(ui,/body\?\.prompt_key === ""/);
 a.match(ui,/body\?\.intent !== "academic"/);
 a.match(ui,/typeof beta\.askGenerated === "function"/);
 a.match(ui,/const answer = await beta\.askPrepared/);
 a.match(ui,/const answer = await beta\.askAcademic/);
 a.ok(ui.indexOf("beta.askGenerated")<ui.indexOf("const answer = await beta.askPrepared"));
});
test("no student identifiers, provider keys, grade edits or tariff logic in new browser route",()=>{
 const begin=client.indexOf("async function askGenerated");
 const end=client.indexOf("// Unified learner-scoped source bridge",begin);
 a.ok(begin>0&&end>begin);
 const route=client.slice(begin,end);
 a.match(route,/current\.eligible/);
 a.match(route,/current\.consented/);
 a.match(route,/protectedNow\(\)/);
 a.match(route,/await identity\(\)/);
 a.match(route,/mode!=="generated"/);
 a.match(route,/academic_state_changed!==false/);
 a.match(route,/provider_called!==true/);
 for(const invalid of ["service_role","OPENAI_API_KEY","user_id:",
  "localStorage.setItem","assessmentMark","mastery","resetProgress"])
  a.equal(route.includes(invalid),false,invalid);
});
test("the original quick prepared and Math Tutor UI routes remain separate",()=>{
 a.match(ui,/if \(body\?\.intent === "academic"\)/);
 a.match(ui,/if \(beta && typeof beta\.askPrepared === "function"\)/);
 a.match(ui,/client\.functions\.invoke\("global-ai", \{ body \}\)/);
 a.match(client,/const EDGE="iclub-ai-v21-prepared"/);
 a.match(client,/intent:"academic",request_id:requestId/);
});
