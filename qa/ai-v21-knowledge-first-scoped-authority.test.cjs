"use strict";
const {test}=require("node:test"),a=require("node:assert/strict");
const {createKnowledgeFirstScopedAuthority}=
 require("./ai-v21-knowledge-first-scoped-authority.cjs");
const {createKnowledgeFirstSupabaseAdapter}=
 require("./ai-v21-knowledge-first-supabase-adapter.cjs");
const OWNER="11111111-1111-4111-8111-111111111111";
const OTHER="22222222-2222-4222-8222-222222222222";
const HANDLE="33333333-3333-4333-8333-333333333333";
const SHA="a".repeat(64),BEARER="Bearer test_signed_qa_user_AAAAAAAAAAAAAAAA";
const CONFIG={supabaseUrl:"https://mmmduffgpvwjdpruzikw.supabase.co",
 anonKey:"public_qa_anon_key_only",
 serviceRoleKey:"private_qa_service_role_key_only"};
function rig(){
 const state={calls:[],network:[],on:true,scoped:true,revoked:false,
  protected:false,release:true,source:true,right:true,
  owner:OWNER,questionId:42,subject:"chemistry",revision:"screen_8",
  returnedQuestion:42,extraGeneric:true,lateDrift:false,scopeReads:0,
  answerState:"incorrect",
  expiry:Date.now()+45000};
 const context=()=>({
  owner_id:state.owner,route_authority:"unified_ai",
  active:!state.revoked,protected_assessment:false,
  expires_at_ms:state.expiry,context_revision:state.revision,
  current_view:"courses",surface:"practice",subject:state.subject,
  feature:"answer_explanation",topic:"question_"+state.questionId,
  practice_session_id:7801,question_id:state.questionId
 });
 const rpc=async(name,args)=>{
  state.calls.push({name,args});
  if(name==="get_iclub_ai_v21_runtime_service")
   return{ui_enabled:state.on,gateway_enabled:state.on,
    kill_switch:!state.on,release_approved:state.on};
  if(name==="get_iclub_ai_v21_scoped_context_service"){
   state.scopeReads++;
   return{allowed:state.scoped&&state.answerState==="incorrect",context:{
    ...context(),context_revision:state.lateDrift&&state.scopeReads>1?
       "screen_9":state.revision}};
  }
  if(name==="get_iclub_ai_v21_protected_service")
   return{protected:state.protected};
  if(name==="get_iclub_ai_v21_rollout_service")
   return{allowed:state.right};
  if(name==="get_iclub_ai_topic_release_service_v21")
   return{ready:state.release,surface:"practice",subject:"chemistry",
    feature:"answer_explanation",topic:"question_42",locale:"ru",
    source_id:"practice:chemistry:p1:q42:ru:v1",
    source_version:"v1",source_hash:SHA,revision:1};
  if(name==="get_iclub_ai_v21_source_proof_service")
   return{approved:state.source,rights_approved:true,
    runtime_allowed:true,source_conflict:false,
    source_id:"practice:chemistry:p1:q42:ru:v1",
    source_version:"v1",source_hash:SHA};
  return null;
 };
 const mockFetch=async(url,options)=>{
  state.network.push({url,options});
  if(url.endsWith("/auth/v1/user"))
   return{ok:true,json:async()=>({id:OWNER,role:"authenticated",aud:"authenticated"})};
  if(url.endsWith("/rest/v1/rpc/get_practice_ai_source_cards_service_v1")){
   let values=[{
    question_id:state.returnedQuestion,
    subject_key:"chemistry",locale:"ru",card_type:"answer_explanation",
    source_card_key:"practice:chemistry:p1:q42:ru:v1",
    content_hash:SHA,source_version:"v1",
    body_text:"Verified prepared answer for this finalized question."}];
   if(state.extraGeneric)values.push({
    ...values[0],question_id:null,source_card_key:"practice:generic:ru:v1"});
   return{ok:true,json:async()=>values};
  }
  return{ok:false,json:async()=>null};
 };
 const trusted=createKnowledgeFirstScopedAuthority({rpc});
 const adapter=createKnowledgeFirstSupabaseAdapter({...CONFIG,fetcher:mockFetch},trusted);
 const ask=(overrides={})=>adapter.resolve({
  authorization:BEARER,contextHandle:HANDLE,locale:"ru",
  intent:"practice_card",promptKey:"explain_error",...overrides});
 return{state,ask,adapter,trusted};
}
test("complete signed Auth → owner scoped finalized context → editorial + exact question card; no output or money",async()=>{
 const x=rig(),r=await x.ask();
 a.equal(r.ok,true,JSON.stringify(r));a.equal(r.reason,"qa_source_verified");
 a.equal(r.route,"practice_card");
 a.equal(r.confirmedIncorrectAnswer,true);
 a.equal(r.sourceVersion,"v1");
 a.equal(r.sourceHash,SHA);
 a.equal(r.publicationRevision,1);
 a.equal(r.learnerVisibleText,null);a.equal(r.releaseAllowed,false);
 a.equal(r.providerCalled,false);a.equal(r.billed,false);
 a.equal(r.academicStateChanged,false);
 a.equal(x.state.network.filter(v=>v.url.endsWith("/auth/v1/user")).length,1);
 const reads=x.state.network.filter(v=>v.url.includes("/rest/v1/rpc/"));
 a.equal(reads.length,1,"Only approved exact practice-card lookup; second proof uses metadata");
 const json=JSON.parse(reads[0].options.body);
 a.equal(json.p_question_id,42);
 a.equal(json.p_topic,null);
 a.equal(reads[0].options.headers.apikey,CONFIG.serviceRoleKey);
 a.deepEqual([...new Set(x.state.calls.map(v=>v.name))].sort(),[
  "get_iclub_ai_topic_release_service_v21",
  "get_iclub_ai_v21_protected_service",
  "get_iclub_ai_v21_rollout_service",
  "get_iclub_ai_v21_runtime_service",
  "get_iclub_ai_v21_scoped_context_service",
  "get_iclub_ai_v21_source_proof_service"
 ].sort());
});
test("approved old content without separate owner publication cannot open",async()=>{
 for(const key of ["on","scoped","release","source","right"]){
  const x=rig();x.state[key]=false;
  a.equal((await x.ask()).ok,false,key);
 }
});
test("signed context owner, UUID, exact subject/question and source are non-negotiable",async()=>{
 for(const mutate of [
  x=>{x.owner=OTHER},
  x=>{x.questionId=43},
  x=>{x.subject="economics"},
  x=>{x.revision="screen_0"},
  x=>{x.returnedQuestion=9999},
  x=>{x.revoked=true},
  x=>{x.protected=true}
 ]){
  const x=rig();mutate(x.state);
  a.equal((await x.ask()).ok,false,JSON.stringify(x.state));
 }
});
test("late context revision swap is denied even after earlier editorial/source checks",async()=>{
 const x=rig();x.state.lateDrift=true;
 a.equal((await x.ask()).ok,false);
});
test("Math Exam Prep cannot be impersonated by a Practice context",async()=>{
 const x=rig();
 const r=await x.ask({intent:"math_card",promptKey:"simple"});
 a.equal(r.ok,false);
 a.equal(x.state.network.some(v=>v.url.includes("get_exam_prep_ai_tutor_card")),false);
});
test("no RPCs with bad bearer; no automatic registration or protected answers",async()=>{
 const x=rig();const r=await x.ask({authorization:"Bearer forged"});
 a.equal(r.ok,false);
 a.equal(x.state.calls.length,0);
 a.equal(x.state.network.length,0);
 a.equal((await x.ask({promptKey:"show_future_tour"})).ok,false);
 a.equal(x.state.network.some(v=>v.url.includes("signup")),false);
 a.equal(x.state.network.some(v=>v.url.includes("openai")),false);
});
test("missing backend RPC returns unavailable, never downgrades to local guessing",async()=>{
 const trusted=createKnowledgeFirstScopedAuthority({rpc:async()=>null});
 const x=await trusted.readCurrentScope(OWNER,HANDLE,"ru");
 a.equal(x,null);
 a.throws(()=>createKnowledgeFirstScopedAuthority({rpc:null}),/trusted_rpc_required/);
});
test("Scoped SQL refuses correct, unanswered and unknown Practice answers",async()=>{
 for(const answerState of ["correct","unanswered","unknown"]){
  const x=rig();x.state.answerState=answerState;
  a.equal((await x.ask()).ok,false,answerState);
  a.equal(x.state.network.some(q=>q.url.includes("get_practice_ai_source_cards")),false);
 }
});
