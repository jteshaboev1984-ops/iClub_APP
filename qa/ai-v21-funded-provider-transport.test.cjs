"use strict";
// Entire suite is synthetic. Never calls a provider or any live learner API.
const {test}=require("node:test");
const assert=require("node:assert/strict");
const {createHash}=require("node:crypto");
const {quote,actualInvoice,readText,fundedCanary,MODEL,
 PER_REQUEST_CEILING_MICROUSD,MAX_OUTPUT_TOKENS}=
 require("./ai-v21-funded-provider-transport.cjs");
const RID="11111111-1111-4111-8111-111111111111";
const UID="33333333-3333-4333-8333-333333333333";
const SOURCE="iClub public help (approved synthetic source only). Support questions are directed to the Support screen; select a topic and choose the request option. Student grades are not accessible.";
const sha=t=>createHash("sha256").update(t).digest("hex");
const reply=()=>({
 model:MODEL,status:"completed",
 usage:{input_tokens:400,input_tokens_details:{cached_tokens:0,cache_write_tokens:0},
   output_tokens:75},
 output:[{type:"message",role:"assistant",content:[
   {type:"output_text",text:"Open Support, choose a topic and follow the request instructions."}
 ]}]
});
function fixture(overrides={}){
 const record={steps:[],requests:0,money:new Set(),used:new Set(),finished:[]};
 const auth={
  authorized:true,scope:"approved_public_app_help",releaseApproved:true,
  activeProtectedAssessment:false,sourceApproved:true,approvedSourceText:SOURCE,
  sourceSha256:sha(SOURCE),locale:"en",userId:UID
 };
 const services={
  authorize:async()=>{record.steps.push("authorize");return {...auth,...overrides.auth};},
  reserveAndClaim:async({requestId})=>{
   record.steps.push("claim");
   if(record.used.has(requestId))return {ok:false};
   record.used.add(requestId);return {ok:true};
  },
  reserveMoney:async o=>{
   record.steps.push("reserve");
   assert.equal(o.holdMicroUsd,10000);
   if(overrides.reserve===false)return {allowed:false};
   record.money.add(o.requestId);return {allowed:true};
  },
  recheck:async()=>{record.steps.push("recheck");return overrides.recheck!==false;},
  dispatchMoney:async()=>{record.steps.push("dispatch");
   if(overrides.dispatch===false)return {allowed:false};
   return {allowed:true};
  },
  finishMoney:async o=>{
   record.steps.push("money:"+o.outcome);record.finished.push(o);
   return {ok:overrides.finish!==false};
  },
  finishLearner:async o=>{record.steps.push("learner:"+o.outcome);return {ok:true};}
 };
 const httpRequest=async(url,opts)=>{
  record.steps.push("http");record.requests++;
  assert.equal(url,"https://api.openai.com/v1/responses");
  assert.equal(opts.method,"POST");
  const b=JSON.parse(opts.body);
  assert.equal(b.model,MODEL);
  assert.deepEqual(b.tools,[]);
  assert.equal(b.store,false);
  assert.equal(b.max_output_tokens,MAX_OUTPUT_TOKENS);
  assert.deepEqual(b.reasoning,{effort:"none"});
  assert.ok(b.instructions.includes(SOURCE));
  assert.ok(!b.instructions.includes("33333333-3333-4333"));
  assert.ok(!opts.body.includes("Bearer synthetic"));
  if(overrides.throwHttp)throw Error("simulated network outage");
  return {status:200,data:overrides.reply||reply()};
 };
 const call=(params={})=>fundedCanary({
  requestId:RID,auth:"Bearer synthetic-local-only-key",
  allowedOrigin:"qa_funded_canary_controlled",
  locale:"en",question:"How can I contact support?",
  apiKey:"test-provider-key-is-not-secret",services,httpRequest,...params
 });
 return {call,record,services,httpRequest};
}
test("pre-request USD 0.01 hold covers approved short source and max 220 output tokens",()=>{
 const q=quote({locale:"en",sourceText:SOURCE,question:"How can I contact support?"});
 assert.equal(q.ok,true);
 assert.equal(q.model,MODEL);
 assert.equal(q.reserveMicroUsd,PER_REQUEST_CEILING_MICROUSD);
 assert.ok(q.upperBoundMicroUsd>0&&q.upperBoundMicroUsd<=10000);
 assert.equal(quote({locale:"en",sourceText:"X".repeat(8500),question:"Hi"}).reason,
  "input_too_large");
 assert.equal(quote({locale:"fr",sourceText:SOURCE,question:"hello"}).ok,false);
 assert.equal(quote({locale:"en",sourceText:SOURCE,question:"x".repeat(401)}).ok,false);
});
test("successful funded canary reserves money BEFORE one HTTP call; settles actual tokens",async()=>{
 const x=fixture();
 const r=await x.call();
 assert.equal(r.ok,true);
 assert.equal(r.providerCalled,true);
 assert.match(r.message,/Support/);
 assert.equal(x.record.requests,1);
 assert.deepEqual(x.record.steps,[
  "authorize","claim","reserve","recheck","dispatch","http",
  "money:charged","recheck","learner:completed"
 ]);
 assert.equal(x.record.finished.length,1);
 assert.equal(x.record.finished[0].actualMicroUsd,170);
 assert.equal(r.invoiceUpperMicroUsd,170);
});
test("source is server-derived and SHA256-verified; forged text is rejected before money",async()=>{
 for(const auth of [
  {sourceApproved:false},{sourceSha256:"f".repeat(64)},
  {approvedSourceText:SOURCE+"unapproved addendum"},
  {releaseApproved:false},{activeProtectedAssessment:true},
  {scope:"exam_prep_skill"},{locale:"ru"},
  {userId:"not-a-uuid"},{authorized:false}
 ]){
  const x=fixture({auth});
  const r=await x.call({sourceText:"user supplied unapproved source"});
  assert.equal(r.ok,false);
  assert.equal(x.record.requests,0);
  assert.ok(!x.record.steps.includes("reserve"));
 }
});
test("missing key, wrong command origin, no auth and unapproved language cost $0",async()=>{
 for(const params of [{apiKey:""},{allowedOrigin:"production"},
   {requestId:"bad-id"},{auth:""},{locale:"es"}]){
  const x=fixture();
  const r=await x.call(params);
  assert.equal(r.ok,false);
  assert.equal(x.record.requests,0);
 }
});
test("denied or ambiguous money reservation never invokes the provider",async()=>{
 const x=fixture({reserve:false});
 const r=await x.call();
 assert.equal(r.providerCalled,false);
 assert.equal(x.record.requests,0);
 assert.deepEqual(x.record.steps,[
  "authorize","claim","reserve","learner:released"
 ]);
 const y=fixture({dispatch:false});
 const uncertain=await y.call();
 assert.equal(uncertain.providerCalled,false);
 assert.equal(y.record.requests,0);
 assert.equal(y.record.steps.includes("money:no_charge"),false,
  "Ambiguous dispatch ACK cannot refund spent-provider liability");
});
test("revoked context between reserve and dispatch can release DEFINITELY unused money",async()=>{
 const x=fixture({recheck:false});
 const result=await x.call();
 assert.equal(result.ok,false);
 assert.equal(x.record.requests,0);
 assert.deepEqual(x.record.steps,[
  "authorize","claim","reserve","recheck","money:no_charge","learner:released"
 ]);
});
test("HTTP failure retains unknown invoice liability and releases learner quota",async()=>{
 const x=fixture({throwHttp:true});
 const result=await x.call();
 assert.equal(result.ok,false);
 assert.equal(result.providerCalled,true);
 assert.equal(x.record.requests,1);
 assert.ok(x.record.steps.includes("money:unknown"));
 assert.ok(x.record.steps.includes("learner:released"));
 assert.equal(x.record.steps.includes("money:no_charge"),false);
});
test("unknown usage and rejected outputs NEVER count as a free provider call",async()=>{
 for(const response of [
  {...reply(),usage:null},
  {...reply(),usage:{input_tokens:1000,output_tokens:300}},
  {...reply(),model:"unapproved-new-model"},
  {...reply(),output:[]},
  {...reply(),output:[{type:"message",role:"assistant",
   content:[{type:"output_text",text:"NO_APPROVED_SOURCE"}]}]}
 ]){
  const x=fixture({reply:response});
  const r=await x.call();
  assert.equal(r.ok,false);
  assert.equal(r.providerCalled,true);
  assert.ok(x.record.steps.includes("learner:released"));
  assert.equal(x.record.steps.includes("money:no_charge"),false);
 }
});
test("missing accounting confirmation prevents learner delivery, no automated retry",async()=>{
 const x=fixture({finish:false});
 const r=await x.call();
 assert.equal(r.ok,false);
 assert.equal(r.reason,"accounting_unconfirmed");
 assert.equal(x.record.requests,1);
 assert.ok(!x.record.steps.includes("learner:completed"));
});
test("request replay cannot double-dispatch paid generation",async()=>{
 const x=fixture();
 assert.equal((await x.call()).ok,true);
 const second=await x.call();
 assert.equal(second.ok,false);
 assert.equal(second.reason,"learner_claim_denied");
 assert.equal(x.record.requests,1);
});
test("usage reconciliation does not count text chars, excludes unapproved models",()=>{
 const fine=actualInvoice(reply());
 assert.deepEqual(fine,{inputTokens:400,outputTokens:75,upperBillMicroUsd:170});
 const cached=actualInvoice({...reply(),usage:{
   input_tokens:400,input_tokens_details:{cached_tokens:200,cache_write_tokens:0},
   output_tokens:75}});
 assert.equal(cached.upperBillMicroUsd,134);
 assert.equal(actualInvoice({...reply(),usage:{input_tokens:1,output_tokens:221}}),null);
 assert.equal(readText({...reply(),status:"incomplete"}),null);
});
