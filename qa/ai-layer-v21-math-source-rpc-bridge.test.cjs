// node --test qa/ai-layer-v21-math-source-rpc-bridge.test.cjs
"use strict";
const {test}=require("node:test"),assert=require("node:assert/strict");
const {MockMathTutorRpcBridge}=require("./ai-layer-v21-math-source-rpc-bridge.cjs");
const sourceKey="p1:P1-CIR-01:theory:ru:v2";
const principal={authenticated:true,userId:"learner-00001"};
const req={principal,contextHandle:"handle-context-0001",mode:"main",nowMs:1000};
const ctx=(changes={})=>({
 ownerId:principal.userId,active:true,expiresAt:9000,protectedAssessment:false,
 subject:"mathematics",componentCode:"P1",skillCode:"P1-CIR-01",locale:"ru",
 contextVersion:"v1",...changes
});
const card=(changes={})=>({
 component_code:"P1",skill_code:"P1-CIR-01",locale:"ru",content_version:"tutor_v3_learner_first",
 source_card_key:sourceKey,main_explanation:"Проверенное объяснение",
 simple_explanation:"Просто",alternative_explanation:"Иначе",focus_explanation:"Главное",
 ...changes
});
const setup=({freshContext=()=>ctx(),allow=()=>true,cardData=card(),sourceCards=[{source_card_key:sourceKey}],onRpc}={})=>{
 const calls=[];const bridge=new MockMathTutorRpcBridge({
   getScopedContext:async(userId,handle)=>{calls.push(["context",userId,handle]);return freshContext();},
   canUseUnifiedAI:async({userId,context})=>{calls.push(["allow",userId,context?.subject]);return allow();},
   rpc:async(name,args)=>{calls.push(["rpc",name,args]);
     if(onRpc)return onRpc(name,args);
     if(name==="get_exam_prep_ai_source_cards_service_v1")return sourceCards;
     if(name==="get_exam_prep_ai_tutor_card_service_v1")return cardData;
     throw Error("unexpected RPC");
   }
 });return {bridge,calls};
};
test("exact Math source resolves prepared, no quota or provider calls",async()=>{
 const x=setup();const r=await x.bridge.prepare(req);
 assert.equal(r.ok,true);assert.equal(r.route,"prepared");assert.equal(r.message,"Проверенное объяснение");
 assert.equal(r.providerCallRequired,false);assert.equal(r.quotaHandled,false);
 assert.deepEqual(x.calls.filter(c=>c[0]==="rpc").map(c=>c[1]),[
  "get_exam_prep_ai_source_cards_service_v1","get_exam_prep_ai_tutor_card_service_v1"]);
});
test("RPC parameters are derived from server context, not user hints",async()=>{
 const x=setup();await x.bridge.prepare({...req,subject:"economics",componentCode:"P5",skillCode:"P5-PRO-06",locale:"en"});
 const rpc=x.calls.find(c=>c[0]==="rpc");
 assert.equal(rpc[2].p_component_code,"P1");assert.equal(rpc[2].p_skill_code,"P1-CIR-01");
 assert.equal(rpc[2].p_locale,"ru");assert.equal(rpc[2].p_card_type,"theory");
});
test("existing Exam Prep endpoint is never invoked by this bridge",async()=>{
 const x=setup();await x.bridge.prepare(req);
 assert.equal(x.calls.some(c=>JSON.stringify(c).includes("exam-prep-ai")),false);
});
test("wrong server-side subject blocks all source RPCs",async()=>{
 const x=setup({freshContext:()=>ctx({subject:"economics"})});
 assert.equal((await x.bridge.prepare(req)).reason,"subject_mismatch");
 assert.equal(x.calls.some(c=>c[0]==="rpc"),false);
});
test("unowned or expired subject handle fails closed",async()=>{
 for(const changes of [{ownerId:"other-user"},{expiresAt:900},{active:false}]){
  const x=setup({freshContext:()=>ctx(changes)});
  assert.equal((await x.bridge.prepare(req)).reason,"context_unverified");
 }
});
test("active exam denies BEFORE any card lookup",async()=>{
 const x=setup({freshContext:()=>ctx({protectedAssessment:true})});
 assert.equal((await x.bridge.prepare(req)).reason,"protected_assessment");
 assert.equal(x.calls.some(c=>c[0]==="rpc"),false);
});
test("unready feature blocks without student accounting or source RPC",async()=>{
 const x=setup({allow:()=>false});
 assert.equal((await x.bridge.prepare(req)).reason,"feature_not_ready");
 assert.equal(x.calls.some(c=>c[0]==="rpc"),false);
});
test("tutor version mismatch is not silently accepted",async()=>{
 const x=setup({cardData:card({content_version:"tutor_v2"})});
 assert.equal((await x.bridge.prepare(req)).reason,"source_version_mismatch");
});
test("missing approved source key denies despite a Tutor card",async()=>{
 const x=setup({sourceCards:[]});
 assert.equal((await x.bridge.prepare(req)).reason,"source_not_approved");
});
test("source mismatch denies use of unrelated card",async()=>{
 const x=setup({cardData:card({source_card_key:"p1:P1-CIR-02:theory:ru:v2"})});
 assert.equal((await x.bridge.prepare(req)).reason,"source_catalog_mismatch");
});
test("context changes to protected exam after RPC lookup refuse delivery",async()=>{
 let count=0;const x=setup({freshContext:()=>++count===1?ctx():ctx({protectedAssessment:true})});
 assert.equal((await x.bridge.prepare(req)).reason,"context_changed");
});
test("context changes subject or source version during await deny",async()=>{
 for(const changes of [{subject:"economics"},{skillCode:"P1-CIR-02"},{contextVersion:"v2"}]){
  let count=0;const x=setup({freshContext:()=>++count===1?ctx():ctx(changes)});
  assert.equal((await x.bridge.prepare(req)).reason,"context_changed");
 }
});
test("feature revocation during lookup blocks output",async()=>{
 let count=0;const x=setup({allow:()=>++count===1});
 assert.equal((await x.bridge.prepare(req)).reason,"context_changed");
});
test("source RPC outage fails closed without cached guess",async()=>{
 const x=setup({onRpc:async()=>{throw Error("backend down")}});
 assert.equal((await x.bridge.prepare(req)).reason,"approved_source_unavailable");
});
test("freeform learner prompt is not converted to any convenient prepared card",async()=>{
 const x=setup();assert.equal((await x.bridge.prepare({...req,mode:"question"})).reason,"requires_separate_governed_route");
});
