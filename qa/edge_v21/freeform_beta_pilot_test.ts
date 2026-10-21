import {makeFreeformPilotHandler} from "./freeform_beta_pilot.ts";
const UID="11111111-1111-4111-8111-111111111111";
const REQUEST="22222222-2222-4222-8222-222222222222";
const HOST="https://mmmduffgpvwjdpruzikw.supabase.co";
const ORIGIN="https://i-club-app.vercel.app";
const TOKEN="Bearer synthetic_really_long_jwt_value_01";
const SOURCE="An iClub student can open Profile, select Support and follow the relevant guidance. The Home screen shows next recommended actions. The app includes Practice and Tours. iClub AI never changes student grades or completed progress.";
const equal=(a:unknown,b:unknown,reason:string)=>{
 if(a!==b)throw Error(reason+": "+String(a)+" != "+String(b));
};
const hash=async(s:string)=>{
 const b=await crypto.subtle.digest("SHA-256",new TextEncoder().encode(s));
 return Array.from(new Uint8Array(b)).map(n=>n.toString(16).padStart(2,"0")).join("");
};
async function fixture(changes:{blocked?:boolean;noSource?:boolean;
 budgetDenied?:boolean;providerFailure?:boolean;sentinel?:boolean;
 snapshot?:boolean;reasoningEnvelope?:boolean;rogueModel?:boolean;http400?:boolean;
 contextDrift?:boolean;enabled?:boolean}={}){
 const logs:{name:string;payload:Record<string,unknown>}[]=[];
 const originSource=await hash(SOURCE);
 let sourceReads=0;
 const fetcher:typeof fetch=async(input,init)=>{
  const url=String(input);
  const name=url.split("/").at(-1)||"";
  const payload=init?.body?JSON.parse(String(init.body)):{};
  logs.push({name,payload});
  if(url.endsWith("/auth/v1/user"))
   return Response.json({id:UID,role:"authenticated"});
  if(name==="get_iclub_ai_v21_beta_status_service")
   return Response.json({eligible:!changes.blocked,consented:true});
  if(name==="get_iclub_ai_ui_bootstrap_v1")
   return Response.json({visible:true,assessment_blocked:Boolean(changes.blocked),
    usage_exhausted:false});
  if(name==="get_iclub_ai_v21_freeform_help_bundle_v1"){
   sourceReads++;
   const content=changes.noSource?"":SOURCE;
   return Response.json({ok:!changes.noSource,locale:"en",subject:"general",
    cards:13,source_version:"approved_iclub_help_bundle_v1",
    source_text:content,source_hash:changes.contextDrift&&sourceReads>1?
       "0".repeat(64):originSource});
  }
  if(name==="reserve_iclub_ai_v21_freeform_quota_v1")return Response.json({allowed:true});
  if(name==="reserve_iclub_ai_v21_freeform_budget_v1")
   return Response.json(changes.budgetDenied?{allowed:false}:{allowed:true,held_microusd:50000});
  if(name==="dispatch_iclub_ai_v21_freeform_budget_v1")return Response.json({allowed:true});
  if(name==="settle_iclub_ai_v21_freeform_budget_v1")return Response.json({ok:true});
  if(name==="finish_iclub_ai_v21_freeform_quota_v1")return Response.json({ok:true});
  if(url==="https://api.openai.com/v1/responses"){
   if(changes.providerFailure)return new Response("provider down",{status:503});
   if(changes.http400)return Response.json({error:{code:"unsupported_parameter"}},{status:400});
   return Response.json({status:"completed",
    model:changes.rogueModel?"gpt-5.6-luna":
      changes.snapshot?"gpt-5.4-mini-2026-03-17":"gpt-5.4-mini",
    usage:{input_tokens:250,output_tokens:50},
    output:[...(changes.reasoningEnvelope?[{type:"reasoning",summary:[]}]:[]),
     {type:"message",role:"assistant",content:[{type:"output_text",
     text:changes.sentinel?"ICLUB_NO_APPROVED_SOURCE":
     "You can find Support in your Profile. The AI assistant cannot change your results."}]}]});
  }
  throw Error("Unexpected synthetic RPC "+url);
 };
 const handler=makeFreeformPilotHandler({url:HOST,
  anon:"anon-synthetic-key-very-long-00001",
  service:"service-synthetic-key-long-00002",
  providerKey:"provider-synthetic-key-long-003",
  enabled:changes.enabled!==false,fetcher});
 const send=(question="How do I find Support in my iClub profile?",requestId=REQUEST)=>{
  return handler(new Request("https://fake.test",{
   method:"POST",headers:{"origin":ORIGIN,"authorization":TOKEN,
    "content-type":"application/json"},
   body:JSON.stringify({intent:"ask",locale:"en",question,request_id:requestId})
  }));
 };
 return {send,logs};
}
Deno.test("consented Free beta question triggers a genuinely dynamic mock Responses call AFTER dollar and quota holds",async()=>{
 const f=await fixture();
 const r=await f.send();equal(r.status,200,"status");
 const data=await r.json();
 equal(data.ok,true,"model answer");
 equal(data.mode,"generated","mode");
 equal(data.academic_state_changed,false,"read-only");
 const names=f.logs.map(x=>x.name);
 for(const n of ["reserve_iclub_ai_v21_freeform_quota_v1",
  "reserve_iclub_ai_v21_freeform_budget_v1",
  "dispatch_iclub_ai_v21_freeform_budget_v1",
  "settle_iclub_ai_v21_freeform_budget_v1",
  "finish_iclub_ai_v21_freeform_quota_v1","responses"]){
  if(!names.includes(n))throw Error("Missing ordered gate "+n);
 }
 const index=(name:string)=>names.indexOf(name);
 if(index("responses")<=index("dispatch_iclub_ai_v21_freeform_budget_v1"))
  throw Error("Model contacted before atomic dispatch");
 const model=f.logs.find(x=>x.name==="responses")?.payload||{};
 equal(model.model,"gpt-5.4-mini","model");
 equal(model.store,false,"store");
 equal(model.max_output_tokens,384,"output cap");
 if(!Array.isArray(model.tools)||model.tools.length!==0)
  throw Error("Model tools should be disabled");
 const money=f.logs.find(x=>x.name==="settle_iclub_ai_v21_freeform_budget_v1")?.payload||{};
 equal(money.p_outcome,"charged","settlement");
 equal(money.p_actual_microusd,413,"calculated conservative token price");
 const quota=f.logs.find(x=>x.name==="finish_iclub_ai_v21_freeform_quota_v1")?.payload||{};
 equal(quota.p_outcome,"completed","generated quota");
});
Deno.test("active protected assessment blocks ALL paid and quota activity",async()=>{
 const f=await fixture({blocked:true});
 const r=await f.send();equal(r.status,403,"protected status");
 if(f.logs.some(x=>x.name.startsWith("reserve_")))throw Error("Assessment charged quota");
});
Deno.test("missing approved source cannot reserve model cost",async()=>{
 const f=await fixture({noSource:true});
 const r=await f.send();equal(r.status,403,"source status");
 if(f.logs.some(x=>x.name.startsWith("reserve_")))throw Error("Unpublished source charged");
});
Deno.test("monetary refusal refunds already-held learner quota with NO provider call",async()=>{
 const f=await fixture({budgetDenied:true});
 const r=await f.send();equal(r.status,409,"budget");
 if(f.logs.some(x=>x.name==="responses"))throw Error("Budget-denied model call");
 const end=f.logs.find(x=>x.name==="finish_iclub_ai_v21_freeform_quota_v1")?.payload;
 equal(end?.p_outcome,"released","refund");
});
Deno.test("source fingerprint drift before dispatch keeps NO CHARGE and returns quota",async()=>{
 const f=await fixture({contextDrift:true});
 const r=await f.send();equal(r.status,409,"drift");
 if(f.logs.some(x=>x.name==="responses"))throw Error("Drifted source invoked provider");
 equal(f.logs.find(x=>x.name==="settle_iclub_ai_v21_freeform_budget_v1")?.payload.p_outcome,
 "no_charge","source changed before dispatch");
});
Deno.test("no-source model output counts the paid response but refunds student's 3 units",async()=>{
 const f=await fixture({sentinel:true});
 const r=await f.send(),d=await r.json();
 equal(d.ok,false,"no source answer not released");
 equal(f.logs.find(x=>x.name==="settle_iclub_ai_v21_freeform_budget_v1")?.payload.p_outcome,
 "charged","real model liability");
 equal(f.logs.find(x=>x.name==="finish_iclub_ai_v21_freeform_quota_v1")?.payload.p_outcome,
 "released","no-source quota return");
});
Deno.test("ambiguous provider outage retains full possible spend instead of false no_charge",async()=>{
 const f=await fixture({providerFailure:true});
 const r=await f.send(),d=await r.json();
 equal(d.ok,false,"provider denial");
 equal(f.logs.find(x=>x.name==="settle_iclub_ai_v21_freeform_budget_v1")?.payload.p_outcome,
 "unknown","unknown liability");
 equal(f.logs.find(x=>x.name==="finish_iclub_ai_v21_freeform_quota_v1")?.payload.p_outcome,
 "released","provider-failure quota return");
});
Deno.test("pilot starts disabled and cannot even authenticate",async()=>{
 const f=await fixture({enabled:false});
 const r=await f.send();equal(r.status,503,"disabled");
 equal(f.logs.length,0,"no network calls");
});

Deno.test("Supabase browser CORS preflight includes x-client-info without requiring a paid request",async()=>{
 const f=await fixture();
 const endpoint=makeFreeformPilotHandler({
  url:HOST,anon:"anon-synthetic-key-very-long-00001",
  service:"service-synthetic-key-long-00002",
  providerKey:"provider-synthetic-key-long-003",
  enabled:true,fetcher:async()=>{throw Error("OPTIONS must not use network");}
 });
 const r=await endpoint(new Request("https://fake.test",{
  method:"OPTIONS",headers:{"origin":ORIGIN,
   "access-control-request-method":"POST",
   "access-control-request-headers":"authorization, apikey, content-type, x-client-info"}
 }));
 equal(r.status,204,"preflight success");
 if(!(r.headers.get("access-control-allow-headers")||"").includes("x-client-info"))
  throw Error("Browser x-client-info header forbidden");
 equal(r.headers.get("access-control-allow-origin"),ORIGIN,"allowed production origin");
 equal(r.headers.get("access-control-allow-methods"),"POST, OPTIONS","allowed methods");
 equal(f.logs.length,0,"no mock paid requests");
});

Deno.test("official dated GPT-5.4-mini snapshot counts as a verified generated answer and exact charge",async()=>{
 const f=await fixture({snapshot:true,reasoningEnvelope:true});
 const r=await f.send();
 equal(r.status,200,"snapshot status");
 const d=await r.json();
 equal(d.ok,true,"snapshot accepted");
 equal(d.mode,"generated","mode");
 equal(f.logs.find(x=>x.name==="settle_iclub_ai_v21_freeform_budget_v1")?.payload.p_outcome,
 "charged","snapshot cost confirmed");
 equal(f.logs.find(x=>x.name==="finish_iclub_ai_v21_freeform_quota_v1")?.payload.p_outcome,
 "completed","student can see officially snapshotted response");
});
Deno.test("an unrelated model identity is still rejected and liability is retained",async()=>{
 const f=await fixture({rogueModel:true});
 const r=await f.send(),d=await r.json();
 equal(d.ok,false,"model mismatch denied");
 equal(f.logs.find(x=>x.name==="settle_iclub_ai_v21_freeform_budget_v1")?.payload.p_outcome,
 "unknown","mismatched model monetary hold retained");
 equal(f.logs.find(x=>x.name==="finish_iclub_ai_v21_freeform_quota_v1")?.payload.p_outcome,
 "released","learner quota refunded");
});
Deno.test("provider parameter HTTP 400 fails closed with potential spending liability retained",async()=>{
 const f=await fixture({http400:true});
 const r=await f.send(),d=await r.json();
 equal(d.ok,false,"upstream provider rejection denied");
 equal(f.logs.find(x=>x.name==="settle_iclub_ai_v21_freeform_budget_v1")?.payload.p_outcome,
 "unknown","provider rejection liability retained");
});

Deno.test("full Supabase SDK v2 headers and Telegram WebView origin pass OPTIONS before any POST or charge",async()=>{
 let network=0;
 const handler=makeFreeformPilotHandler({
  url:HOST,anon:"anon-synthetic-key-very-long-00001",
  service:"service-synthetic-key-long-00002",
  providerKey:"provider-synthetic-key-long-003",
  enabled:true,fetcher:async()=>{network++;throw Error("OPTIONS has zero network calls");}
 });
 const requested=[
  "authorization","x-client-info","apikey","content-type",
  "x-retry-count","traceparent","tracestate","baggage"
 ];
 const res=await handler(new Request("https://fake.test",{
  method:"OPTIONS",headers:{
   "origin":ORIGIN,
   "access-control-request-method":"POST",
   "access-control-request-headers":requested.join(", "),
   "user-agent":"Mozilla/5.0 Telegram-Android/13.0.2.0"
  }
 }));
 equal(res.status,204,"preflight 204");
 equal(res.headers.get("access-control-allow-origin"),ORIGIN,"exact origin");
 const allowed=(res.headers.get("access-control-allow-headers")||"")
  .toLowerCase().split(",").map(x=>x.trim());
 for(const name of requested){
  if(!allowed.includes(name))throw Error("SDK browser preflight blocked by "+name);
 }
 if(allowed.includes("x-user-id")||allowed.includes("*"))
  throw Error("Unexpectedly open CORS header policy");
 equal(network,0,"preflight must not fetch provider/DB");
 const unsafe=await handler(new Request("https://fake.test",{
  method:"OPTIONS",headers:{"origin":"https://attacker.example",
   "access-control-request-method":"POST",
   "access-control-request-headers":requested.join(", ")}
 }));
 equal(unsafe.status,403,"untrusted origin denied");
 equal(unsafe.headers.get("access-control-allow-origin"),null,"untrusted origin not reflected");
 equal(network,0,"rejected preflight must not contact network");
});
