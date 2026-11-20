#!/usr/bin/env node
"use strict";
// Provider-free source contract for the existing single AI Tutor screen map.
// Run: node scripts/ai-tutor-beta-screen-contract.cjs
// Static contract only: not a logged-in browser or authenticated HTTP E2E.
const assert=require("node:assert/strict");
const fs=require("node:fs");
const path=require("node:path");
const vm=require("node:vm");
const root=path.resolve(__dirname,"..");
const ui=fs.readFileSync(path.join(root,"iclub-ai-v21-ui.js"),"utf8");
const client=fs.readFileSync(path.join(root,"iclub-ai-v21-beta-client.js"),"utf8");
const shell=fs.readFileSync(path.join(root,"index.html"),"utf8");
const source=(start,end,name)=>{
 const at=ui.indexOf(start);
 assert(at>=0,"Missing "+name+" start marker");
 const finish=ui.indexOf(end,at+start.length);
 assert(finish>at,"Missing "+name+" end marker");
 return ui.slice(at+start.length,finish);
};
const approved=source(
 "const PUBLISHED_PREPARED_ACTIONS = new Set([","]);","approved keys"
).match(/"[^"]+"/g)?.map(s=>s.slice(1,-1))||[];
const expected=[
 "books_help","catalog_help","practice_after","practice_rules",
 "recs_help","support_help","tour_rules"
];
assert.deepEqual([...approved].sort(),[...expected].sort(),
 "Only independently approved public-help keys may be suggested");
const readLiteral=(start,name)=>{
 const body=source(start,"\n  });",name);
 return vm.runInNewContext("({"+body+"})",Object.create(null),{timeout:100});
};
const screenMap=readLiteral("const PREPARED_SCREEN_ACTIONS = Object.freeze({","screen map");
const labels=readLiteral("const PREPARED_ACTION_LABELS = Object.freeze({","locale labels");
const permitted=new Set(approved);
const requiredScreens=[
 "home","all-subjects","subject-hub","practice-start","practice-result",
 "practice-review","practice-recs","tours","tour-rules","tour-result",
 "tour-review","lessons","video","books","my-recs","my-rec-detail",
 "ratings","profile","notifications","community","certificates",
 "archive","support","support-topic","about"
];
assert.deepEqual(Object.keys(screenMap).sort(),requiredScreens.slice().sort(),
 "Beta screen map changed: revisit the release contract before expanding");
let actions=0;
for(const [screen,keys] of Object.entries(screenMap)){
 assert(Array.isArray(keys)&&keys.length>=1&&keys.length<=3,
   "Unexpected prompt count on "+screen);
 assert.equal(new Set(keys).size,keys.length,"Duplicate prompt on "+screen);
 for(const key of keys){
  assert(permitted.has(key),"Unpublished key on "+screen+": "+key);
  for(const locale of ["ru","uz","en"]){
   assert(typeof labels[locale]?.[key]==="string"&&
     labels[locale][key].trim().length>5,
     "Missing localized approved label "+locale+"/"+key);
  }
  actions++;
 }
}
// Active assessment screens cannot have a generic prepared-help menu.
for(const blocked of ["practice-quiz","tour-quiz","exam-prep"]){
 assert(!Object.prototype.hasOwnProperty.call(screenMap,blocked),
   "Protected assessment has an AI action map: "+blocked);
}
// Verify structural fail-closed hooks remain present in both client and Tutor.
// Source presence is necessary, NOT sufficient to assert browser/runtime safety.
assert(ui.includes('screen==="practice-quiz"||screen==="tour-quiz"'),
 "Tutor lost active Practice/Tour blackout");
assert(ui.includes("m.hidden = blocked;"),
 "Tutor icon must be hidden while assessment is active");
assert(ui.includes("if (blocked) { closePanel(); hideIntro(); }"),
 "Existing chat must close at assessment start");
assert(client.includes('visible("courses-practice-quiz")||visible("courses-tour-quiz")'),
 "Client lost independent quiz blackout");
assert(client.includes("protectedNow()"),
 "Client request paths must check active assessment");
assert(ui.includes("PUBLISHED_PREPARED_ACTIONS.has(key)"),
 "Prompts must filter against published keys");
// There is exactly one shell and prepared transport in the loaded app.
// This test never invokes a model or requests a live learner's beta status.
assert(shell.includes('src="iclub-ai-v21-ui.js?'),
 "Missing existing AI Tutor UI script");
assert(shell.includes('src="iclub-ai-v21-beta-client.js?'),
 "Missing prepared beta transport");
assert(!shell.includes('src="global-ai-ui.js?'),
 "Unexpected second/legacy floating AI shell");
assert(client.includes('const EDGE="iclub-ai-v21-prepared"'),
 "Prepared buttons must retain the current governed Edge endpoint");
// Typed free-form questions are a distinct budgeted route: not a free preview.
// The script only guards this separation; it must not enable or invoke it.
assert(client.includes('"/functions/v1/iclub-ai-v21-freeform-beta"'),
 "Freeform route change requires a separate cost/security review");
console.log("PASS AI Tutor beta source contract:",Object.keys(screenMap).length,
  "screens,",actions,"approved screen actions,",approved.length,
  "reviewed product keys, RU/UZ/EN labels; protected quiz hooks present.");
console.log("NOTE: static code check only. No paid calls, Supabase writes or beta entitlements tested.");
