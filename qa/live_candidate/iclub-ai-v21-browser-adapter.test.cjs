"use strict";
// The connected transport uses the EXISTING app session, never signs up or
// imports any service-role secret, and never routes academic text to public Help.
const {test}=require("node:test");
const assert=require("node:assert/strict");
const vm=require("node:vm");
const fs=require("node:fs");
const path=require("node:path");
const source=fs.readFileSync(path.join(__dirname,
 "iclub-ai-v21-browser-adapter.js"),"utf8");
const USER_A="11111111-1111-4111-8111-111111111111";
const USER_B="22222222-2222-4222-8222-222222222222";
function rig(){
 const state={user:USER_A,candidate:true,consented:false,
  eligible:false,requests:[],active:false,authListeners:[]};
 const root={
  window:{
   sb:{
    auth:{
     getUser:async()=>({data:{user:{id:state.user}},error:null}),
     onAuthStateChange:fn=>state.authListeners.push(fn)
    },
    functions:{
     invoke:async(slug,{body})=>{
      assert.equal(slug,"iclub-ai-v21-prepared");
      state.requests.push(body);
      if(body.intent==="status")return{data:{
       ok:true,eligible:state.eligible,candidate:state.candidate,
       consented:state.consented},error:null};
      if(body.intent==="consent"){
       state.consented=true;
       return{data:{ok:true,recorded:true},error:null};
      }
      if(body.intent==="ask")return{data:{
       ok:true,message:"Open Profile then select Support to find help.",
       mode:"prepared",academic_state_changed:false,provider_called:false
      },error:null};
      throw Error("Unexpected action");
     }
    }
   },
   crypto:{randomUUID:()=> "33333333-3333-4333-8333-333333333333"},
   i18n:{getLang:()=>"en"}
  },
  document:{
   readyState:"loading",addEventListener(){},
   getElementById:id=>id==="courses-practice-quiz"?
    {classList:{contains:()=>state.active}}:null
  },
  MutationObserver:class{observe(){}},
  setTimeout
 };
 vm.runInNewContext(source,root,{filename:"iclub-ai-v21-browser-adapter.js"});
 return{state,api:root.window.iClubAiV21BetaClient};
}
test("Real session candidate requires separate explicit consent",async()=>{
 const x=rig();
 const s=await x.api.status();
 assert.equal(s.ok,true);assert.equal(s.candidate,true);
 assert.equal(s.consented,false);assert.equal(s.eligible,false);
 assert.equal((await x.api.consentFromExplicitUserAction(false)).ok,false);
 assert.equal(x.state.requests.some(r=>r.intent==="consent"),false);
 const grant=await x.api.consentFromExplicitUserAction(true);
 assert.equal(grant.ok,true);
 assert.equal(x.state.consented,true);
 assert.equal(x.state.requests.filter(r=>r.intent==="consent").length,1);
});
test("No active beta cannot dispatch Help, even with a signed user",async()=>{
 const x=rig();
 assert.equal((await x.api.askPrepared({
  promptKey:"support_help",locale:"ru"})).ok,false);
 assert.equal(x.state.requests.some(r=>r.intent==="ask"),false);
});
test("Only exact prepared Help key can reach the authenticated Edge route",async()=>{
 const x=rig();x.state.eligible=true;x.state.consented=true;
 const known=await x.api.askPrepared({promptKey:"support_help",locale:"en"});
 assert.equal(known.ok,true);assert.equal(known.provider_called,false);
 assert.equal(x.state.requests.filter(r=>r.intent==="ask").length,1);
 assert.equal((await x.api.askPrepared({promptKey:"topic_main",locale:"en"})).ok,false);
 assert.equal((await x.api.askPrepared({promptKey:"support_help",locale:"xx"})).ok,false);
 assert.equal(x.state.requests.filter(r=>r.intent==="ask").length,1);
});
test("Identity change and a protected assessment block the browser transport",async()=>{
 const x=rig();x.state.eligible=true;x.state.consented=true;
 x.state.active=true;
 assert.equal((await x.api.askPrepared({promptKey:"about_help",locale:"en"})).ok,false);
 assert.equal(x.state.requests.some(r=>r.intent==="ask"),false);
 x.state.active=false;
 x.state.user=USER_B;x.api.resetOnIdentityChange();
 x.state.eligible=false;
 assert.equal((await x.api.askPrepared({promptKey:"about_help",locale:"en"})).ok,false);
 assert.equal(x.state.requests.some(r=>r.intent==="ask"),false);
});
test("The adapter never touches user progress, localStorage, signup or model APIs",()=>{
 assert.doesNotMatch(source,/localStorage|auth\.signUp|\/auth\/v1\/signup|api\.openai\.com|service_role/i);
 assert.match(source,/getUser/);
 assert.match(source,/iclub-ai-v21-prepared/);
});
