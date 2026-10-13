// Deno actually imports the same QA-request core verified by Node CI,
// without installing or deploying an Edge function.
import {createQaEdgeCandidate} from "./runtime.ts";
import {makeHttpHandler} from "./http.ts";
const U="11111111-1111-4111-8111-111111111111";
const ORIGIN="https://preview.synthetic.invalid";
const REQUEST="22222222-2222-4222-8222-222222222222";
const eq=(a:unknown,b:unknown)=>{if(!Object.is(a,b))throw Error(JSON.stringify(a)+" != "+JSON.stringify(b))};
function core(){
 let available=false,exam=false,providerCalls=0,bookings=0;
 const source={source_id:"source-a",source_version:"v1",source_hash:"a".repeat(64),revision:1};
 const services={
  authenticate:async()=>({authenticated:true,userId:U}),
  getServerTimeMs:async()=>1000,
  isProtected:async()=>exam,
  getGlobalState:async()=>({uiEnabled:true,gatewayEnabled:true,killSwitch:false,releaseApproved:true}),
  getScopedContext:async()=>({ownerId:U,routeAuthority:"unified_ai",active:true,
   protectedAssessment:false,expiresAtMs:10000,contextRevision:"rev-0001",
   surface:"lesson",subject:"biology",feature:"topic_explanation",topic:"synthetic-topic"}),
  getSubjectActive:async()=>true,
  isRolloutAuthorized:async()=>true,
  getPublishedRelease:async(ref:Record<string,unknown>)=>available?{
   ready:true,...ref,...source}:null,
  getLiveSourceProof:async(ref:Record<string,unknown>)=>({
   ...ref,approved:true,rightsApproved:true,runtimeAllowed:true,sourceConflict:false,...source}),
  getPolicy:async()=> "plus_qa_v2",
  getSourceBundle:async()=>({approved:true,rightsApproved:true,integrityVerified:true,
    qaPassed:true,runtimeAllowed:true,conflict:false,sourceId:source.source_id,
    sourceVersion:source.source_version,sourceHash:source.source_hash,
    revision:source.revision,variants:{topic_main:"Synthetic test receipt only"}}),
  providerBudgetAllows:async()=>false,
  generateSynthetic:async()=>{providerCalls++;throw Error("provider_disabled");},
  reserveUsage:async()=>{bookings++;return{allowed:true};},
  claimDelivery:async()=>({allowed:true}),
  finishDelivery:async()=>({ok:true})
 };
 const candidate=createQaEdgeCandidate(services,[ORIGIN]);
 const handle=makeHttpHandler(candidate,[ORIGIN]);
 const send=async(intent:"status"|"answer")=>{
  const r=await handle(new Request("https://preview.synthetic.invalid/",{
   method:"POST",headers:{"Origin":ORIGIN,"Content-Type":"application/json",
    "Authorization":"Bearer synthetic-jwt-token"},
   body:JSON.stringify({intent,contextHandle:"server-owned-handle",
    appLocale:"ru",...(intent==="answer"?{requestId:REQUEST,promptKey:"topic_main"}:{})})
  }));
  return{status:r.status,body:await r.json() as Record<string,unknown>};
 };
 return{send,enable:()=>{available=true},protect:()=>{exam=true},counters:()=>({providerCalls,bookings})};
}
Deno.test("Native Deno bridge: unavailable topic is visible but never charged",async()=>{
 const x=core(),r=await x.send("answer");
 eq(r.status,200);eq(r.body.state,"in_development");
 eq(r.body.title,"В разработке");
 eq(x.counters().bookings,0);eq(x.counters().providerCalls,0);
});
Deno.test("Native Deno bridge: publication flips readiness without recompiling",async()=>{
 const x=core();
 eq((await x.send("status")).body.state,"in_development");
 x.enable();eq((await x.send("status")).body.state,"available");
});
Deno.test("Native Deno bridge: an exam hides the UI",async()=>{
 const x=core();x.enable();x.protect();
 eq((await x.send("answer")).body.state,"hidden");
 eq(x.counters().bookings,0);
});
Deno.test("Native Deno bridge: approved prepared source stays within QA mock",async()=>{
 const x=core();x.enable();
 const r=await x.send("answer");
 eq(r.body.reply,"Synthetic test receipt only");
 eq(x.counters().providerCalls,0);
 eq(x.counters().bookings,1);
});
