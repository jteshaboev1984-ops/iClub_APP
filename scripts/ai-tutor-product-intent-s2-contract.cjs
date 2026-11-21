#!/usr/bin/env node
"use strict";
// S2: execute the ACTUAL Tutor product-intent classifier and route selector.
// No network, model, accounts, academic data or priced provider dispatch.
const assert=require("node:assert/strict");
const fs=require("node:fs");
const path=require("node:path");
const vm=require("node:vm");
const ui=fs.readFileSync(path.resolve(__dirname,"../iclub-ai-v21-ui.js"),"utf8");

function extract(start,end){
 const a=ui.indexOf(start);
 assert(a>=0,"missing source marker "+start);
 const b=ui.indexOf(end,a+start.length);
 assert(b>a,"missing end marker "+end);
 return ui.slice(a,b);
}
const intentSrc=extract("  function verifiedProductHelpIntent(raw) {",
  "\n  async function invokeGlobalAi(body) {");
const intent=vm.runInNewContext(
 "(function(){"+intentSrc+"return verifiedProductHelpIntent;})()",
 Object.create(null),{timeout:500});

const positive=[
 ["Амалиет Нима учун кк","practice_rules"],
 ["Амалиёт нима учун керак?","practice_rules"],
 ["Amaliёт nima uchun kerak?","practice_rules"],
 ["Амалиёт nima uchun kerak?","practice_rules"],
 ["Amaliyot nima?","practice_rules"],
 ["Practice nima uchun kerak?","practice_rules"],
 ["Что такое Practice?","practice_rules"],
 ["Практика как работает?","practice_rules"],
 ["How does Practice work?","practice_rules"],
 ["How do I open Practice?","practice_rules"],
 ["Practice qoidalari qanday?","practice_rules"],
 ["iClub'da Practice qanday ishlaydi va qanday boshlash mumkin?","practice_rules"],
 ["Экзам преп Нима ва у нимага кк","exam_prep_unpublished"],
 ["Exam Prep nima uchun kerak?","exam_prep_unpublished"],
 ["What is Exam Prep?","exam_prep_unpublished"],
 ["Экзам Prep nima?","exam_prep_unpublished"],
 ["How does Exam Prep work?","exam_prep_unpublished"]
];
const negative=[
 "Practice integral javobi qaysi?",
 "What is the integral answer in Practice?",
 "How many scores did I get in Practice?",
 "Practice natijam nima?",
 "Practice xatolar nima?",
 "Can you solve my Practice equation x+3=5?",
 "Exam Prep masala javobi nima?",
 "What is chemistry?",
 "Practice nima uchun kerak? Masala yechim",
 "What is my Practice score?",
 "Practice result error",
 "Why is my Practice question wrong?",
 "How do I solve equations in Exam Prep?"
];
let cases=0;
for(const [q,expected] of positive){
 assert.equal(intent(q),expected,JSON.stringify(q));cases++;
}
for(const q of negative){assert.equal(intent(q),"",JSON.stringify(q));cases++;}
for(const bad of [null,undefined,{},42,"a".repeat(241),""]){
 assert.equal(intent(bad),"");cases++;
}

const invokes=[];
const adapter={
 askPrepared:async args=>{
  invokes.push({route:"prepared",args});
  return {ok:true,mode:"prepared",message:"Synthetic approved help",
    academic_state_changed:false,provider_called:false};
 },
 askGenerated:async args=>{
  invokes.push({route:"generated",args});
  return {ok:false,reason:"synthetic_model_not_called",
    academic_state_changed:false};
 },
 askAcademic:async args=>{
  invokes.push({route:"academic",args});
  return {ok:false,reason:"approved_source_missing",
    academic_state_changed:false};
 },
 askPracticePrepared:async args=>{
  invokes.push({route:"practice_prepared",args});
  return {ok:false,reason:"source_or_access_unavailable",
    academic_state_changed:false};
 },
 askPracticeFreeform:async args=>{
  invokes.push({route:"practice_freeform",args});
  return {ok:false,reason:"synthetic_model_not_called",
    academic_state_changed:false};
 }
};
const routeSrc=extract("  async function invokeGlobalAi(body) {",
  "\n  async function sendMessage(");
const route=vm.runInNewContext("("+routeSrc+")",{
 window:{iClubAiV21BetaClient:adapter},verifiedProductHelpIntent:intent
},{timeout:500});
const template={request_id:"00000000-0000-4000-8000-000000000001",
  locale:"uz",subject_key:"general",scope_code:"global",
  prompt_key:"",user_text:""};
async function check(q,body,expectedRoute){
 invokes.length=0;
 const result=await route({...template,...body,user_text:q});
 assert.equal(result.error,null);
 if(expectedRoute==="no_provider"){
  assert.equal(invokes.length,0,JSON.stringify(q));
  assert.deepEqual(JSON.parse(JSON.stringify(result.data)),{
   ok:false,reason:"approved_source_missing",
   academic_state_changed:false,provider_called:false
  });
 }else{
  assert.equal(invokes.length,1,JSON.stringify(q));
  assert.equal(invokes[0].route,expectedRoute,JSON.stringify(q));
  if(expectedRoute==="prepared"&&intent(q)==="practice_rules"){
   assert.equal(invokes[0].args.promptKey,"practice_rules");
   assert.equal(invokes[0].args.userText,"");
   assert.equal(result.data.provider_called,false);
  }
 }
 cases++;
}
(async()=>{
 // Product questions are screen-independent hints; server verifies content.
 for(const screen of ["home","all-subjects","subject-hub",
  "practice-entry","exam-prep-entry","profile"]){
  for(const lang of ["ru","uz","en"]){
   await check("Амалиет Нима учун кк",{
    locale:lang,subject_key:screen==="home"?"general":"mathematics",
    screen_code:screen}, "prepared");
  }
 }
 for(const lang of ["ru","uz","en"]){
  await check("Экзам преп Нима ва у нимага кк",{
   locale:lang,subject_key:"general"},"no_provider");
 }
 await check("What is Exam Prep?",{locale:"en",
  subject_key:"mathematics"},"no_provider");
 await check("How do I start Practice?",{locale:"en",
  subject_key:"chemistry"},"prepared");
 await check("Что такое Practice?",{locale:"ru",
  subject_key:"economics"},"prepared");
 await check("Where is the profile?",{locale:"en",
  subject_key:"general"},"generated");
 await check("How do I solve an integral?",{locale:"en",
  subject_key:"mathematics"},"prepared");
 await check("How does Practice work?",{locale:"en",
  subject_key:"mathematics",intent:"academic",surface:"tour_archive",
  record_id:10,question_id:null},"academic");
 await check("How does Practice work?",{locale:"en",
  subject_key:"mathematics",intent:"practice_freeform",
  practice_purpose:"practice_result",attempt_ref:42},"practice_freeform");
 await check("What is Practice?",{locale:"en",
  prompt_key:"practice_rules",subject_key:"general"},"prepared");
 console.log("PASS S2 bounded product-help: "+cases+
 " classifier/routing checks, RU/UZ/EN, 6 screens, no paid provider calls for matched source.");
})().catch(err=>{console.error(err);process.exitCode=1;});
