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
  eligible:false,requests:[],active:false,authListeners:[],
  activateOnConsent:false,panelRefreshCalls:0};
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
       if(state.activateOnConsent)state.eligible=true;
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
   i18n:{getLang:()=>"en"},
   iClubGlobalAiShell:{refresh:async()=>{state.panelRefreshCalls++;}}
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
 assert.doesNotMatch(source,/localStorage|auth\.signUp|\/auth\/v1\/signup|api\.openai\.com|SUPABASE_SERVICE_ROLE_KEY|serviceRoleKey/i);
 assert.match(source,/getUser/);
 assert.match(source,/iclub-ai-v21-prepared/);
});

test("Six first-party navigation routes support exact RU/UZ/EN questions",async()=>{
 const samples=[
  ["ru","Как открыть Главную?","nav_home"],
  ["ru","Где Учёба?","nav_courses"],
  ["uz","Reyting qayerda?","nav_ratings"],
  ["uz","Profil qayerda?","nav_profile"],
  ["en","Where is About?","nav_about"],
  ["en","Where is Support?","nav_support"]
 ];
 for(const [locale,question,expected] of samples){
  const x=rig();x.state.eligible=true;x.state.consented=true;
  const r=await x.api.askPrepared({promptKey:"",locale,userText:question});
  assert.equal(r.ok,true,question);
  const sent=x.state.requests.filter(y=>y.intent==="ask");
  assert.equal(sent.length,1);
  assert.equal(sent[0].prompt_key,expected);
 }
});
test("No unapproved or academic question is mapped to navigation",async()=>{
 const x=rig();x.state.eligible=true;x.state.consented=true;
 for(const question of [
  "Explain derivatives",
  "What are my exam scores?",
  "Which subject should I study next?",
  "Where is Support and what is the exam solution?"
 ]){
  const r=await x.api.askPrepared({promptKey:"",locale:"en",userText:question});
  assert.equal(r.ok,false);
 }
 assert.equal(x.state.requests.filter(y=>y.intent==="ask").length,0);
});
test("Separate opt-in immediately reveals prepared AI with no provider call",async()=>{
 const x=rig();x.state.activateOnConsent=true;
 assert.equal((await x.api.status()).eligible,false);
 assert.equal(x.state.panelRefreshCalls,0);
 assert.equal((await x.api.consentFromExplicitUserAction(false)).ok,false);
 assert.equal(x.state.panelRefreshCalls,0);
 const result=await x.api.consentFromExplicitUserAction(true);
 assert.equal(result.ok,true);assert.equal(result.recorded,true);
 assert.equal(result.ready,true);
 assert.equal(x.state.panelRefreshCalls,1);
 assert.equal((await x.api.status()).eligible,true);
 const approved=await x.api.askPrepared({promptKey:"nav_support",locale:"en"});
 assert.equal(approved.ok,true);
 assert.equal(approved.provider_called,false);
});

test("Every visible premium quick question has both client and server authority",()=>{
 const fs=require("node:fs"),path=require("node:path");
 const panel=fs.readFileSync(path.join(__dirname,"../ai-v21-real-preview-ui-snapshot.js"),"utf8");
 const edge=fs.readFileSync(path.join(__dirname,"iclub-ai-v21-prepared/index.ts"),"utf8");
 const uiBegin=panel.indexOf("const labels = {",panel.indexOf("function quickPrompts("));
 const uiEnd=panel.indexOf("const context=ctx?.screenCode",uiBegin);
 assert.ok(uiBegin>0&&uiEnd>uiBegin,"Current premium prompt definition");
 const ui=new Set([...panel.slice(uiBegin,uiEnd).matchAll(/([a-z]+(?:_[a-z]+)*):"/g)].map(x=>x[1]));
 const clientStart=source.indexOf("const ALLOWED=new Set([");
 const clientEnd=source.indexOf("]);",clientStart);
 const serverStart=edge.indexOf("const KEYS = new Set([");
 const serverEnd=edge.indexOf("]);",serverStart);
 assert.ok(clientStart>0&&clientEnd>clientStart&&serverStart>0&&serverEnd>serverStart);
 const client=new Set([...source.slice(clientStart,clientEnd).matchAll(/"([a-z_]+)"/g)].map(x=>x[1]));
 const server=new Set([...edge.slice(serverStart,serverEnd).matchAll(/"([a-z_]+)"/g)].map(x=>x[1]));
 assert.equal(ui.size,7);
 for(const key of ui){
  assert.equal(client.has(key),true,key+" is missing in the installed client");
  assert.equal(server.has(key),true,key+" is missing in the prepared server");
 }
});
