#!/usr/bin/env node
"use strict";
// Exact extracted CURRENT browser client path, with mock network only.
// No hosted login, production writes or model/API calls.
const assert=require("node:assert/strict");
const fs=require("node:fs");
const path=require("node:path");
const vm=require("node:vm");
const root=path.resolve(__dirname,"..");
const client=fs.readFileSync(path.join(root,"iclub-ai-v21-beta-client.js"),"utf8");
const ui=fs.readFileSync(path.join(root,"iclub-ai-v21-ui.js"),"utf8");
function section(src,start,end){
 const a=src.indexOf(start);assert(a>=0,"missing start "+start);
 const b=src.indexOf(end,a+start.length);assert(b>a,"missing end "+end);
 return src.slice(a,b);
}
const copy=vm.runInNewContext("("+section(ui,"const COPY = {","\n  };").replace(/^const COPY = /,"")+
 "})",Object.create(null),{timeout:200});
for(const language of ["ru","uz","en"]){
 for(const key of ["freeformNoSource","freeformRejected"]){
  assert.equal(typeof copy[language]?.[key],"string");
  assert(copy[language][key].length>=40,"missing informative locale copy");
 }
}
// Run the actual UI no_verified_answer branch as a JS function, not a regex-only test.
const handlerText=section(ui,'      if (reason === "no_verified_answer") {',
  '\n      if (reason === "active_assessment") {');
let displayed=[];
const handler=vm.runInNewContext(
 "(function(data){const reason=String(data.reason||'');"+
 handlerText+
 "})",{threadKey:"synthetic",appendMessage:(thread,role,message,kind)=>
  displayed.push({thread,role,message,kind}),copy:()=>copy.en},{timeout:200});
for(const [category,expected] of [
 ["source_unavailable",copy.en.freeformNoSource],
 ["other",copy.en.freeformRejected],
 ["unexpected_untrusted_category",copy.en.freeformRejected]
]){
 displayed=[];
 handler({reason:"no_verified_answer",failure_category:category});
 assert.deepEqual(displayed,[{thread:"synthetic",role:"assistant",message:expected,kind:"notice"}]);
}
let calls=0, captured=[];
const text=section(client,"  async function askGenerated({requestId,locale,userText}={}){",
 "\n  // Main Practice context:");
const askFunction=vm.runInNewContext("("+text+")",{
 LOCALES:new Set(["ru","uz","en"]),status:async()=>({eligible:true,consented:true}),
 protectedNow:()=>false,lastUser:"learner-a",authEpoch:1,identity:async()=>"learner-a",
 closed:(reason="in_development")=>({ok:false,reason,academic_state_changed:false}),
 window:{sb:{
  supabaseUrl:"https://mmmduffgpvwjdpruzikw.supabase.co",
  supabaseKey:"a".repeat(40),
  auth:{getSession:async()=>({data:{session:{access_token:"t".repeat(40)}},error:null})}
 }},
 fetch:async(url,options)=>{calls++;assert.equal(options.method,"POST");
  return {ok:true,status:200,json:async()=>captured[0]}},
 AbortController:class{constructor(){this.signal={}}abort(){}},
 setTimeout:()=>0,clearTimeout:()=>{},String,Array,Object,Set
},{timeout:350});
const args={requestId:"00000000-0000-4000-8000-000000000001",
 locale:"en",userText:"How should I navigate my iClub account?"};
(async()=>{
 for(const [payload,expected] of [
  [{ok:false,reason:"no_verified_answer",failure_category:"source_unavailable"},"source_unavailable"],
  [{ok:false,reason:"no_verified_answer",failure_category:"unsafe_output"},"other"],
  [{ok:false,reason:"no_verified_answer",failure_category:"raw-unknown"},"other"]
 ]){
  captured=[payload];calls=0;
  const res=await askFunction(args);
  assert.equal(res.ok,false);
  assert.equal(res.reason,"no_verified_answer");
  assert.equal(res.failure_category,expected);
  assert.equal(calls,1,"no automatic paid retry");
 }
 captured=[{ok:true,mode:"generated",provider_called:true,
  academic_state_changed:false,message:"Approved help: use Home and Courses navigation."}];
 calls=0;
 const success=await askFunction(args);
 assert.equal(success.ok,true);
 assert.equal(success.mode,"generated");
 assert.equal(calls,1);
 console.log("PASS AI Tutor Edge v6 freeform refusal UI: RU/UZ/EN, source vs technical, fixed categories, one fetch, success preserved.");
})().catch(e=>{console.error(e);process.exitCode=1;});
