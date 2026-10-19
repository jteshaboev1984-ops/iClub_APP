"use strict";
const {test}=require("node:test"),a=require("node:assert/strict");
const {createKnowledgeFirstSupabaseAdapter,validConfig}=
 require("./ai-v21-knowledge-first-supabase-adapter.cjs");
const OWNER="11111111-1111-4111-8111-111111111111",HANDLE="33333333-3333-4333-8333-333333333333";
const SHA="a".repeat(64),MD5="b".repeat(32),SRC="c".repeat(64);
const TOKEN="Bearer synthetic-owner-authenticated-jwt-AAAAAAA";
const config={
 supabaseUrl:"https://mmmduffgpvwjdpruzikw.supabase.co",
 anonKey:"sb_publishable_synthetic_qa_only",
 serviceRoleKey:"synthetic_service_role_do_not_use_live"
};
function rig(){
 const state={requests:[],screenReads:0,rightsReads:0,
  auth:true,release:false,revision:5,rights:true,quiz:false,
  practiceCard:"bound",duplicate:false,stale:false,sourceRevoked:false,
  protectedReads:0,lateProtected:false};
 const screen={
  proof:"server_owner_current_screen_v1",ownerId:OWNER,
  contextHandle:HANDLE,revision:5,expiresAtMs:Date.now()+50000,
  locale:"ru",screenCode:"exam_prep_skill",scopeCode:"exam_prep",
  subjectKey:"mathematics",componentCode:"P1",skillCode:"P1-CIR-01",
  assessmentActive:false};
 const card={tutor_card_key:"p1:P1-CIR-01:tutor:ru:v3",
  component_code:"P1",skill_code:"P1-CIR-01",locale:"ru",
  content_version:"v3",content_hash:MD5,
  source_card_key:"p1:P1-CIR-01:theory:ru:v2",
  main_explanation:"Approved exact curriculum math main explanation.",
  simple_explanation:"Approved exact curriculum math simpler explanation.",
  alternative_explanation:"Approved exact curriculum math alternative method.",
  focus_explanation:"Approved exact curriculum math key principle."};
 const source={source_card_key:card.source_card_key,component_code:"P1",
  skill_code:"P1-CIR-01",locale:"ru",source_version:"v2",content_hash:SRC,
  title:"Permitted source",body_text:"Should never be sent to the client"};
 const practice={source_card_key:"practice:chemistry:p1:q42:ru:v1",
  subject_key:"chemistry",question_id:42,locale:"ru",
  card_type:"answer_explanation",source_version:"v1",content_hash:SHA,
  body_text:"Exact approved explanation for the finalized Chemistry answer."};
 const fakeFetch=async(url,opts)=>{
  state.requests.push({url,method:opts.method,body:opts.body,headers:opts.headers,redirect:opts.redirect});
  let data=null,status=200;
  if(url.endsWith("/auth/v1/user")){
   data={id:OWNER,role:state.auth?"authenticated":"anon",aud:"authenticated"};
  }else if(url.endsWith("/rest/v1/rpc/get_exam_prep_ai_tutor_card_service_v1"))
   data=card;
  else if(url.endsWith("/rest/v1/rpc/get_exam_prep_ai_source_cards_service_v1"))
   data=state.sourceRevoked?[]:[source];
  else if(url.endsWith("/rest/v1/rpc/get_practice_ai_source_cards_service_v1")){
   const generic={...practice,question_id:null,source_card_key:"practice:generic:v1"};
   const bound=state.practiceCard==="bound"?practice:
    {...practice,question_id:null};
   data=state.duplicate?[bound,bound,generic]:[generic,bound];
  }else status=404;
  return{ok:status===200,json:async()=>data};
 };
 const verified={
  readCurrentScope:async()=>{
   state.screenReads++;
   return{...screen,revision:state.stale&&state.screenReads>1?6:screen.revision};
  },
  readProtected:async()=>{
   state.protectedReads++;
   return{proof:"owner_bound_assessment_guard_v1",ownerId:OWNER,
    contextRevision:screen.revision,
    protected:state.quiz||(state.lateProtected&&state.protectedReads>1)};
  },
  verifySubjectRights:async()=>{
   state.rightsReads++;
   return{allowed:state.rights,
    proof:"server_entitlement_v1",ownerId:OWNER,
    contextRevision:screen.revision,subjectKey:screen.subjectKey,
    feature:screen.screenCode==="practice-review"?"practice_card":"math_card"};
  },
  readEditorialRelease:async(p)=>{
   const release={...p,
    proof:"independent_editorial_publication_service_v1",
    approved:state.release,rightsApproved:true,runtimeAllowed:true,
    contentApproved:true,conflict:false,qaPassed:true,
    publicationRevision:1};
   return release;
  }
 };
 const adapter=createKnowledgeFirstSupabaseAdapter({...config,fetcher:fakeFetch},verified);
 const math=()=>adapter.resolve({authorization:TOKEN,contextHandle:HANDLE,
  locale:"ru",intent:"math_card",promptKey:"simple"});
 const practiceCall=()=>adapter.resolve({authorization:TOKEN,contextHandle:HANDLE,
  locale:"ru",intent:"practice_card",promptKey:"explain_error"});
 return{state,screen,card,source,practice,verified,adapter,math,practiceCall};
}
test("configuration rejects SSRF, untrusted scheme, query, credentials and identical keys",()=>{
 for(const url of [
  "http://mmmduffgpvwjdpruzikw.supabase.co",
  "https://evil.example.com","https://subdomain.supabase.co.evil.org",
  "https://admin:secret@mmmduffgpvwjdpruzikw.supabase.co",
  "https://mmmduffgpvwjdpruzikw.supabase.co/path",
  "https://mmmduffgpvwjdpruzikw.supabase.co/?x=1"
 ])a.equal(validConfig({...config,supabaseUrl:url}),false,url);
 a.equal(validConfig({...config,serviceRoleKey:config.anonKey}),false);
 a.equal(validConfig(config),true);
 a.throws(()=>createKnowledgeFirstSupabaseAdapter(config,{}),/trusted_server_readers_required/);
});
test("existing signed Auth uses ONLY public anon key, and service RPC uses service key",async()=>{
 const r=rig();r.state.release=true;
 const x=await r.math();
 a.equal(x.ok,true,JSON.stringify(x));
 a.equal(x.releaseAllowed,false);a.equal(x.providerCalled,false);
 a.equal(x.learnerVisibleText,null);a.equal(x.billed,false);
 const auth=r.state.requests.filter(q=>q.url.endsWith("/auth/v1/user"));
 a.equal(auth.length,1);a.equal(auth[0].method,"GET");
 a.equal(auth[0].headers.apikey,config.anonKey);
 a.equal(auth[0].headers.authorization,TOKEN);
 const rpc=r.state.requests.filter(q=>q.url.includes("/rest/v1/rpc/"));
 a.equal(rpc.length,3,"one approved card plus two source rechecks");
 for(const q of rpc){
  a.equal(q.method,"POST");
  a.equal(q.redirect,"error");
  a.equal(q.headers.apikey,config.serviceRoleKey);
  a.equal(q.headers.authorization,"Bearer "+config.serviceRoleKey);
  a.equal(q.body.includes("user_id"),false);
  a.equal(q.body.includes("answer_key"),false);
 }
 a.deepEqual([...new Set(rpc.map(x=>x.url.split("/").at(-1)))].sort(),
  ["get_exam_prep_ai_source_cards_service_v1","get_exam_prep_ai_tutor_card_service_v1"].sort());
 a.equal(rpc.some(x=>x.url.includes("openai")),false);
});
test("live publication is REQUIRED; legacy approved flag must not grant user delivery",async()=>{
 const r=rig();
 a.equal((await r.math()).ok,false);
 r.state.release=true;
 a.equal((await r.math()).ok,true);
 r.verified.readEditorialRelease=async p=>({...p,proof:"client_claim",
  approved:true,rightsApproved:true,runtimeAllowed:true,
  contentApproved:true,conflict:false,qaPassed:true});
 const again=createKnowledgeFirstSupabaseAdapter({...config,
  fetcher:async(url,opts)=>{
   r.state.requests.push({url,opts});
   // Generic missing data cannot be called an editorial release.
   return{ok:false,json:async()=>null};
  }},r.verified);
 a.equal((await again.resolve({authorization:TOKEN,contextHandle:HANDLE,
  locale:"ru",intent:"math_card",promptKey:"main"})).ok,false);
});
test("invalid Auth, changed screens and protected active assessments deny without cost",async()=>{
 const r=rig();r.state.release=true;r.state.auth=false;
 a.equal((await r.math()).ok,false);
 r.state.auth=true;r.state.quiz=true;
 a.equal((await r.math()).reason,"active_assessment");
 r.state.quiz=false;r.state.lateProtected=true;
 a.equal((await r.math()).ok,false);
 r.state.lateProtected=false;r.state.stale=true;
 a.equal((await r.math()).ok,false);
});
test("exact finalized Practice explanation rejects RPC generic fallbacks and duplicates",async()=>{
 const r=rig();r.state.release=true;
 Object.assign(r.screen,{screenCode:"practice-review",scopeCode:"global",
  subjectKey:"chemistry",finalized:true,ownsAnsweredQuestion:true,
  confirmedIncorrectAnswer:true,questionId:42});
 const x=await r.practiceCall();
 a.equal(x.ok,true,JSON.stringify(x));
 a.equal(x.learnerVisibleText,null);
 a.equal(x.confirmedIncorrectAnswer,true);
 a.equal(x.sourceVersion,"v1");
 a.equal(x.sourceHash,SHA);
 a.equal(x.publicationRevision,1);
 const p=r.state.requests.find(x=>x.url.includes("get_practice_ai_source_cards_service_v1"));
 a.deepEqual(JSON.parse(p.body),{
  p_subject_key:"chemistry",p_locale:"ru",p_card_type:"answer_explanation",
  p_question_id:42,p_topic:null,p_subtopic:null,p_limit:12
 });
 const original=r.state.requests.length;
 r.state.practiceCard="generic";
 a.equal((await r.practiceCall()).ok,false);
 r.state.practiceCard="bound";r.state.duplicate=true;
 a.equal((await r.practiceCall()).ok,false);
 a.ok(r.state.requests.length>original);
});
test("wrong exact syllabus source, source revoked, missing rights and language fail closed",async()=>{
 const r=rig();r.state.release=true;
 r.source.skill_code="P1-ALG-01";
 a.equal((await r.math()).ok,false);
 r.source.skill_code="P1-CIR-01";r.state.sourceRevoked=true;
 a.equal((await r.math()).ok,false);
 r.state.sourceRevoked=false;r.state.rights=false;
 a.equal((await r.math()).ok,false);
 r.state.rights=true;
 a.equal((await r.adapter.resolve({authorization:TOKEN,contextHandle:HANDLE,
 locale:"en",intent:"math_card",promptKey:"simple"})).ok,false);
});
test("no network, requests or provider when no authorized context",async()=>{
 const r=rig();
 const x=await r.adapter.resolve({authorization:"invalid",contextHandle:HANDLE,
  locale:"ru",intent:"math_card",promptKey:"main"});
 a.equal(x.ok,false);a.equal(r.state.requests.length,0);
 for(const q of [r.math,r.practiceCall]){
  const result=await q();a.equal(result.providerCalled,false);
  a.equal(result.billed,false);a.equal(result.releaseAllowed,false);
 }
});
