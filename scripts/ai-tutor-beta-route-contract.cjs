#!/usr/bin/env node
"use strict";
// Execute the REAL existing Tutor route selector and quick-prompt selection
// in an isolated VM with inert adapters. No browser login, model, or DB calls.
// Run: node scripts/ai-tutor-beta-route-contract.cjs
const assert=require("node:assert/strict");
const fs=require("node:fs");
const path=require("node:path");
const vm=require("node:vm");
const ui=fs.readFileSync(path.resolve(__dirname,"../iclub-ai-v21-ui.js"),"utf8");

function between(start,end){
 const at=ui.indexOf(start);
 assert(at!==-1,"Missing marker: "+start);
 const last=ui.indexOf(end,at+start.length);
 assert(last>at,"Missing end marker: "+end);
 return ui.slice(at+start.length,last);
}
function literal(start){
 return vm.runInNewContext("({"+
   between(start,"\n  });")+
   "})",Object.create(null),{timeout:200});
}
const PUBLISHED_PREPARED_ACTIONS=new Set(
 between("const PUBLISHED_PREPARED_ACTIONS = new Set([","]);")
 .match(/"[^"]+"/g).map(key=>key.slice(1,-1)));
const PREPARED_SCREEN_ACTIONS=literal("const PREPARED_SCREEN_ACTIONS = Object.freeze({");
const PREPARED_ACTION_LABELS=literal("const PREPARED_ACTION_LABELS = Object.freeze({");

const quickSource=between("  function quickPrompts(ctx) {",
  "\n  // Render only paired **bold** spans as emphasis");
const quickFunction="function quickPrompts(ctx) {"+quickSource;
const routeSource=between("  async function invokeGlobalAi(body) {",
  "\n  async function sendMessage(");
const routeFunction="async function invokeGlobalAi(body) {"+routeSource;

const calls=[];
const adapter={
 askPrepared:async args=>{calls.push(["prepared",args]);return {ok:true,mode:"prepared",message:"synthetic local response",academic_state_changed:false};},
 askGenerated:async args=>{calls.push(["generated",args]);return {ok:false,reason:"local_paid_dispatch_blocked",academic_state_changed:false};},
 askAcademic:async args=>{calls.push(["academic",args]);return {ok:false,reason:"no_source",academic_state_changed:false};},
 askPracticePrepared:async args=>{calls.push(["practice_prepared",args]);return {ok:false,reason:"no_context",academic_state_changed:false};},
 askPracticeFreeform:async args=>{calls.push(["practice_freeform",args]);return {ok:false,reason:"local_paid_dispatch_blocked",academic_state_changed:false};}
};
let lang="ru",active="home",scope=null,gate={allowed:false,key:""};
const window={iClubAiV21BetaClient:adapter};
const sandbox={
 PUBLISHED_PREPARED_ACTIONS,PREPARED_SCREEN_ACTIONS,PREPARED_ACTION_LABELS,window,
 copy:()=>({practiceResult:"Explain verified result",practiceNext:"Next verified step"}),
 practiceScope:()=>scope,practiceGate:gate,practiceScopeKey:s=>s.key,
 locale:()=>lang,activeViewName:()=>active
};
const quick=vm.runInNewContext("("+quickFunction+")",sandbox,{timeout:300});
const invoke=vm.runInNewContext("("+routeFunction+")",sandbox,{timeout:300});
let checks=0;
function same(a,b,message){
 // Both sides may originate in distinct Node VM realms; compare plain data.
 assert.deepEqual(JSON.parse(JSON.stringify(a)),JSON.parse(JSON.stringify(b)),message);
 checks++;
}
for(const screen of Object.keys(PREPARED_SCREEN_ACTIONS)){
 for(const locale of ["ru","uz","en"]){
  lang=locale;active=screen;scope=null;gate.allowed=false;gate.key="";
  const actual=quick({screenCode:screen,scopeCode:"global",subjectKey:"general"});
  const expected=PREPARED_SCREEN_ACTIONS[screen].map(key=>({
   key,label:PREPARED_ACTION_LABELS[locale][key]
  }));
  same(actual,expected,"wrong current-screen actions for "+screen+"/"+locale);
  assert(actual.length>=1&&actual.length<=3,"violates per-screen max-3");
  assert(actual.every(x=>PUBLISHED_PREPARED_ACTIONS.has(x.key)),
    "unpublished item visible: "+screen+"/"+locale);
 }
}
lang="en";scope=null;
same(quick({screenCode:"unknown-screen",subjectKey:"general",scopeCode:"global"}),
  [{key:"catalog_help",label:PREPARED_ACTION_LABELS.en.catalog_help},
   {key:"support_help",label:PREPARED_ACTION_LABELS.en.support_help}],
  "unknown global screen must get reviewed fallback");
same(quick({screenCode:"unknown-screen",subjectKey:"mathematics",scopeCode:"global"}),
  [{key:"catalog_help",label:PREPARED_ACTION_LABELS.en.catalog_help},
   {key:"books_help",label:PREPARED_ACTION_LABELS.en.books_help}],
  "unknown subject screen must not improvise an academic answer");
same(quick({screenCode:"exam-prep-skill",subjectKey:"mathematics",
  scopeCode:"exam_prep",skillCode:"P1-X",componentCode:"P1"}),
  [{key:"books_help",label:PREPARED_ACTION_LABELS.en.books_help},
   {key:"practice_rules",label:PREPARED_ACTION_LABELS.en.practice_rules}],
  "unreleased P1/P5 skill must not advertise an academic explanation");
scope={key:"own-finalized-attempt"};gate.allowed=true;gate.key=scope.key;
const personal=quick({screenCode:"practice-result",scopeCode:"global",subjectKey:"mathematics"});
same(personal.map(a=>({key:a.key,purpose:a.practicePurpose})),[
  {key:"",purpose:"practice_result"},
  {key:"",purpose:"practice_next_step"},
  {key:"",purpose:"practice_history_comparison"}
],"verified Practice attempt should show only three server-bound intents");
scope=null;gate.allowed=false;gate.key="";

const request={
 request_id:"00000000-0000-4000-8000-000000000001",
 locale:"en",subject_key:"general",scope_code:"global",
 prompt_key:"catalog_help",user_text:""
};
async function routed(label,body,expect){
 calls.length=0;
 const result=await invoke(body);
 assert.equal(calls.length,1,label+" must invoke exactly one transport");
 assert.equal(calls[0][0],expect,label+" routed to wrong transport");
 assert.equal(result.error,null,label+" must retain response envelope");
 checks++;
}
(async()=>{
 await routed("published Home button",request,"prepared");
 await routed("published subject button",{...request,subject_key:"economics",
   prompt_key:"books_help"},"prepared");
 await routed("published key with extra user text",{...request,
   user_text:"Tell me about this section"},"prepared");
 await routed("subject-written question",{...request,subject_key:"chemistry",
   prompt_key:"",user_text:"Please solve the current chemistry problem"},"prepared");
 await routed("explicit general help only",{...request,prompt_key:"",
   user_text:"How should I navigate the app?"},"generated");
 await routed("academic source route",{...request,intent:"academic",
   surface:"tour_archive",record_id:12,question_id:null},"academic");
 await routed("Practice finalized result",{...request,intent:"practice_context",
   practice_purpose:"practice_result",attempt_ref:123},"practice_prepared");
 await routed("Practice typed follow-up",{...request,intent:"practice_freeform",
   practice_purpose:"practice_result",attempt_ref:123},"practice_freeform");
 console.log("PASS existing Tutor: "+checks+
   " runtime prompt/route assertions, 25 mapped screens x 3 languages; zero provider calls");
 console.log("SAFETY: mock transports only; no signed HTTP, browser or learner data.");
})().catch(error=>{console.error(error);process.exitCode=1;});
