// DORMANT PC3 + PC4 gateway. NOT deployed, no production changes.
// Single existing iClub AI Tutor; restricted to verified result/history facts.
// Source-backed explanations of individual wrong answers are NOT on this route.
import {MODEL,TOKEN_CAP,PURPOSES,sha256,isObject,validateQuestion,
 verifiedSummary,makeProviderBody,verifiedProviderResponse,
 type Purpose,type Locale} from "./practice_freeform_pc3_core.ts";
const BASE="https://mmmduffgpvwjdpruzikw.supabase.co";
const URL=(Deno.env.get("SUPABASE_URL")||"").replace(/\/+$/,"");
const ANON=Deno.env.get("SUPABASE_ANON_KEY")||"";
const SERVICE=Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")||"";
const PROVIDER_KEY=Deno.env.get("OPENAI_API_KEY")||"";
const ORIGIN=/^https:\/\/(?:i-club-app\.vercel\.app|i-club-[a-z0-9-]+-jasurbeks-projects-c5451f97\.vercel\.app)$/i;
const UUID=/^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
type Data=Record<string,unknown>;
const fail=(reason:string)=>({ok:false,reason,academic_state_changed:false,provider_called:false});
const reply=(status:number,body:Data,origin:string|null)=>{
 const h=new Headers({"content-type":"application/json; charset=utf-8",
   "cache-control":"no-store, private","vary":"Origin",
   "x-content-type-options":"nosniff","referrer-policy":"no-referrer"});
 if(origin&&ORIGIN.test(origin)){
  h.set("access-control-allow-origin",origin);
  h.set("access-control-allow-methods","POST, OPTIONS");
  h.set("access-control-allow-headers","authorization, apikey, content-type, x-client-info");
 }
 return new Response(status===204?null:JSON.stringify(body),{status,headers:h});
};
async function readJson(response:Promise<Response>):Promise<Data|null>{
 try{const x=await response;if(!x.ok)return null;
  const value=await x.json();return isObject(value)?value:null;}catch{return null;}
}
const rpc=(fn:string,params:Data)=>readJson(fetch(URL+"/rest/v1/rpc/"+fn,{
 method:"POST",headers:{"apikey":SERVICE,"authorization":"Bearer "+SERVICE,
 "content-type":"application/json"},body:JSON.stringify(params),
 signal:AbortSignal.timeout(7000)
}));
async function user(bearer:string){
 const value=await readJson(fetch(URL+"/auth/v1/user",{
  headers:{"apikey":ANON,"authorization":bearer},
  signal:AbortSignal.timeout(5000)}));
 return value?.role==="authenticated"&&typeof value.id==="string"&&
   UUID.test(value.id)?value.id:null;
}
const contextRpc="get_iclub_ai_practice_context_v1_service";
const receiptRpc="iclub_ai_practice_receipt_pc4_service";
const gateRpc="iclub_ai_practice_freeform_pc3_gate_service";
const recoveryRpc="iclub_ai_practice_recover_pc4_service";
const sourceVersion="practice_result_numbers_v1";
const snapshot=(uid:string,purpose:Purpose,attempt:number,lang:Locale)=>
 rpc(contextRpc,{p_user_id:uid,p_attempt_id:attempt,p_intent:purpose,
  p_question_id:null,p_locale:lang});
type Prepared={
 uid:string;requestId:string;attempt:number;lang:Locale;purpose:Purpose;
 fp:string;contextFp:string;sourceFp:string;sessionFp:string;
 question:string;verified:Data;modelBody:Data;
};
async function prepare(uid:string,data:Data):Promise<Prepared|null>{
 const purpose=data.purpose as Purpose,lang=data.locale as Locale;
 const attempt=data.attempt_ref as number;
 const context=await snapshot(uid,purpose,attempt,lang);
 const verified=verifiedSummary(context,purpose,lang);
 if(!verified || (context?.context as Data)?.attempt_ref!==attempt)return null;
 const modelBody=makeProviderBody(data.question as string,verified,lang);
 if(!modelBody)return null;
 const sourceFp=await sha256(JSON.stringify(["pc1_verified_result_only",
  verified,sourceVersion]));
 const contextFp=await sha256(JSON.stringify([purpose,attempt,lang,verified,sourceFp]));
 const fp=await sha256(JSON.stringify([uid,data.request_id,purpose,attempt,lang,
  (data.question as string).trim(),contextFp,sourceFp]));
 const sessionFp=await sha256(JSON.stringify([uid,"practice_context_v1_freeform"]));
 return{uid,requestId:data.request_id as string,attempt,lang,purpose,fp,
   contextFp,sourceFp,sessionFp,question:data.question as string,verified,modelBody};
}
const receipt=(p:Prepared,action:string,answer:string|null=null,cost:number|null=null)=>
 rpc(receiptRpc,{p_action:action,p_request_id:p.requestId,p_user_id:p.uid,
  p_attempt_ref:p.attempt,p_request_fingerprint:p.fp,
  p_context_fingerprint:p.contextFp,p_source_fingerprint:p.sourceFp,
  p_locale:p.lang,p_answer:answer,p_actual_microusd:cost});
const quotaParams=(p:Prepared)=>({p_request_id:p.requestId,
 p_user_id:p.uid,p_request_fingerprint:p.fp});
const budgetParams=(p:Prepared)=>({...quotaParams(p),
 p_session_fingerprint:p.sessionFp,p_source_fingerprint:p.sourceFp,
 p_source_version:sourceVersion,p_locale:p.lang});
const reserveQuota=(p:Prepared)=>rpc("reserve_iclub_ai_v21_freeform_quota_v1",quotaParams(p));
const releaseQuota=(p:Prepared)=>rpc("finish_iclub_ai_v21_freeform_quota_v1",
 {...quotaParams(p),p_outcome:"released"});
const completeQuota=(p:Prepared)=>rpc("finish_iclub_ai_v21_freeform_quota_v1",
 {...quotaParams(p),p_outcome:"completed"});
const reserveMoney=(p:Prepared)=>rpc("reserve_iclub_ai_v21_freeform_budget_v1",budgetParams(p));
const dispatchMoney=(p:Prepared)=>rpc("dispatch_iclub_ai_v21_freeform_budget_v1",
 {p_request_id:p.requestId,p_user_id:p.uid,
  p_session_fingerprint:p.sessionFp,p_request_fingerprint:p.fp});
const settleMoney=(p:Prepared,outcome:"no_charge"|"unknown"|"charged",cost:number|null)=>
 rpc("settle_iclub_ai_v21_freeform_budget_v1",{
  p_request_id:p.requestId,p_user_id:p.uid,
  p_session_fingerprint:p.sessionFp,p_request_fingerprint:p.fp,
  p_outcome:outcome,p_actual_microusd:cost});
async function authorizedFreeformRelease(){
 const release=await rpc(gateRpc,{});
 return release?.ok===true && release.released===true &&
   release.model===MODEL && release.output_token_cap===TOKEN_CAP &&
   release.maximum_per_request_microusd===50000 &&
   release.generated_weight===3;
}
async function confirmedNewContext(p:Prepared){
 // The administrator may disable PC3 mid-flight without changing PC1
 // attempt authorization. Check both, before AND after provider dispatch.
 if(!await authorizedFreeformRelease())return false;
 const raw=await snapshot(p.uid,p.purpose,p.attempt,p.lang);
 const verified=verifiedSummary(raw,p.purpose,p.lang);
 if(!verified)return false;
 const sourceFp=await sha256(JSON.stringify(["pc1_verified_result_only",
  verified,sourceVersion]));
 const fp=await sha256(JSON.stringify([p.purpose,p.attempt,p.lang,verified,sourceFp]));
 return fp===p.contextFp&&sourceFp===p.sourceFp;
}
async function replay(p:Prepared,called=false){
 let saved=await receipt(p,"replay");
 if(saved?.ok!==true && saved?.reason==="budget_settlement_pending"){
  const inspect=await receipt(p,"inspect");
  const cost=inspect?.actual_microusd;
  if(inspect?.ok!==true||inspect.state!=="ready"||
     typeof cost!=="number"||!Number.isSafeInteger(cost)||
     cost<0||cost>50000)return fail("accounting_pending");
  await settleMoney(p,"charged",cost);
  saved=await receipt(p,"replay");
 }
 if(saved?.ok!==true || typeof saved.message!=="string"||
    saved.message.length<20 || saved.message.length>2400)
  return fail("response_not_replayable");
 return {ok:true,mode:"generated",delivery_state:"pending_ack",
  request_id:p.requestId,message:saved.message,
  provider_called:called,academic_state_changed:false};
}
async function ack(p:Prepared){
 const state=await receipt(p,"ack");
 if(state?.ok!==true||state.action!=="acknowledged")
   return fail("ack_unavailable");
 const quota=await completeQuota(p);
 // The existing quota finisher is not idempotent. If a previous finish
 // committed but its HTTP reply was lost, PC4's 'accounted' independently
 // verifies BOTH canonical quota and money ledgers.
 const accounted=await receipt(p,"accounted");
 if(accounted?.ok!==true)
  return fail(quota?.ok===true?"accounting_pending":"quota_confirmation_pending");
 return {ok:true,mode:"acknowledged",request_id:p.requestId,
  provider_called:false,academic_state_changed:false};
}
// Restore without browser persistence or a client-supplied source hash.
 // The latest unacknowledged answer belongs to this authenticated learner,
 // current finalized attempt and exactly matching source/context revision.
async function restore(uid:string,data:Data,shouldAck:boolean){
 const attempt=data.attempt_ref as number,lang=data.locale as Locale;
 const raw=await snapshot(uid,"practice_result",attempt,lang);
 const verified=verifiedSummary(raw,"practice_result",lang);
 if(!verified || raw?.context && (raw.context as Data).attempt_ref!==attempt)
  return fail("context_or_source_not_ready");
 const sourceFp=await sha256(JSON.stringify(["pc1_verified_result_only",
  verified,sourceVersion]));
 const contextFp=await sha256(JSON.stringify([
  "practice_result",attempt,lang,verified,sourceFp]));
 const recovered=await rpc(recoveryRpc,{p_user_id:uid,
  p_attempt_ref:attempt,p_locale:lang,
  p_request_id:shouldAck?data.request_id:null});
 if(recovered?.ok!==true)return fail(String(recovered?.reason||"no_pending_answer"));
 const id=String(recovered.request_id||"");
 if(!UUID.test(id)||recovered.context_fingerprint!==contextFp||
    recovered.source_fingerprint!==sourceFp||
    typeof recovered.request_fingerprint!=="string"||
    !/^[a-f0-9]{64}$/.test(recovered.request_fingerprint))
   return fail("stale_saved_context");
 const p:Prepared={uid,requestId:id,attempt,lang,
  purpose:"practice_result",fp:recovered.request_fingerprint,
  contextFp,sourceFp,
  sessionFp:await sha256(JSON.stringify([uid,"practice_context_v1_freeform"])),
  question:"",verified,modelBody:{}};
 if(shouldAck)return await ack(p);
 const recoveredAnswer=await replay(p);
 return recoveredAnswer.ok===true
  ? {...recoveredAnswer,recovered:true}
  : recoveredAnswer;
}
async function ask(p:Prepared,key:string){
 const initial=await receipt(p,"begin");
 if(initial?.ok!==true)return fail(String(initial?.reason||"receipt_unavailable"));
 if(initial.action!=="registered"){
  const state=await receipt(p,"inspect");
  if(state?.ok!==true)return fail("receipt_unavailable");
  if(["ready","acknowledged"].includes(String(state.state)))return replay(p);
  return fail("request_already_in_progress");
 }
 const quota=await reserveQuota(p);
 if(quota?.allowed!==true){
  // Quota may already have committed before the HTTP response was lost.
  // Compensate before closing the receipt: no new provider call occurs.
  await releaseQuota(p);
  await receipt(p,"void");
  // Only explicit admission exhaustion returns a learner-visible reset time.
  // A network failure, revocation or unknown denial must stay generic.
  if(quota?.reason==="usage_exhausted" &&
     typeof quota.reset_at==="string" &&
     /^\\d{4}-\\d\\d-\\d\\d[T ]\\d\\d:\\d\\d:/.test(quota.reset_at))
    return {...fail("practice_quota_exhausted"),reset_at:quota.reset_at};
  return fail("usage_or_access_unavailable");
 }
 const money=await reserveMoney(p);
 if(money?.allowed!==true||money.held_microusd!==50000){
  await releaseQuota(p);await receipt(p,"void");
  return fail("pilot_budget_unavailable");
 }
 if(!await confirmedNewContext(p)){
  await settleMoney(p,"no_charge",null);await releaseQuota(p);
  await receipt(p,"void");
  return fail("context_changed");
 }
 const dispatchedBudget=await dispatchMoney(p);
 if(dispatchedBudget?.allowed!==true){
  // Dispatch acknowledgement might have been lost: don't risk a 2nd call.
  await settleMoney(p,"unknown",null);await releaseQuota(p);
  await receipt(p,"void");
  return fail("provider_dispatch_uncertain");
 }
 const dispatchedReceipt=await receipt(p,"dispatch");
 if(dispatchedReceipt?.action!=="dispatch_once"){
  await settleMoney(p,"unknown",null);await releaseQuota(p);
  await receipt(p,"void");
  return fail("provider_dispatch_uncertain");
 }
 let provider:unknown=null;
 try{
  const up=await fetch("https://api.openai.com/v1/responses",{
   method:"POST",headers:{"authorization":"Bearer "+key,
    "content-type":"application/json"},
   body:JSON.stringify(p.modelBody),signal:AbortSignal.timeout(12000)
  });
  if(up.ok)provider=await up.json();
 }catch{/* network outcome may have cost money; do not retry */}
 const verified=verifiedProviderResponse(provider);
 if(!verified){
  await settleMoney(p,"unknown",null);await releaseQuota(p);
  await receipt(p,"unknown");
  return fail("provider_outcome_unverified");
 }
 if(!await confirmedNewContext(p)){
  await settleMoney(p,"charged",verified.actual_microusd);
  await releaseQuota(p);await receipt(p,"unknown");
  return fail("context_changed_after_provider");
 }
 const stored=await receipt(p,"store",verified.answer,verified.actual_microusd);
 if(stored?.action!=="stored"){
  await settleMoney(p,"charged",verified.actual_microusd);
  await releaseQuota(p);await receipt(p,"unknown");
  return fail("provider_result_not_stored");
 }
 // Money cost is incurred at provider completion, not at client ACK.
 const charged=await settleMoney(p,"charged",verified.actual_microusd);
 if(charged?.ok!==true)return fail("accounting_pending");
 return replay(p,true);
}
Deno.serve(async(req:Request):Promise<Response>=>{
 const origin=req.headers.get("origin");
 if(!origin||!ORIGIN.test(origin))
  return reply(403,fail("origin_not_authorized"),null);
 const send=(status:number,data:Data)=>reply(status,data,origin);
 if(req.method==="OPTIONS")return send(204,{});
 if(req.method!=="POST")return send(405,fail("method_not_allowed"));
 if(URL!==BASE||ANON.length<24||SERVICE.length<24||
    PROVIDER_KEY.length<16||ANON===SERVICE)
  return send(503,fail("not_released"));
 const bearer=req.headers.get("authorization")||"";
 if(!/^Bearer [a-zA-Z0-9._-]{24,4000}$/.test(bearer))
  return send(401,fail("not_authorized"));
 let data:Data;
 try{
  const raw=await req.text();
  if(new TextEncoder().encode(raw).length>4500)
   return send(413,fail("invalid_request"));
  const input=JSON.parse(raw);
  if(!isObject(input))throw Error("bad_input");
  data=input;
 }catch{return send(400,fail("invalid_request"));}
 const keys=Object.keys(data);
 if(keys.length!==8||
    keys.some(k=>!["intent","operation","request_id","purpose","attempt_ref",
      "question_ref","locale","question"].includes(k))||
    data.intent!=="practice_freeform"||
    !["ask","ack","resume","resume_ack"].includes(String(data.operation))||
    typeof data.request_id!=="string"||!UUID.test(data.request_id)||
    !PURPOSES.includes(data.purpose as Purpose)||
    !["ru","uz","en"].includes(String(data.locale))||
    !Number.isSafeInteger(data.attempt_ref)||Number(data.attempt_ref)<=0||
    data.question_ref!==null||
    (["resume","resume_ack"].includes(String(data.operation))
       ? (data.question!==null||data.purpose!=="practice_result")
       : !validateQuestion(data.question)))
  return send(400,fail("invalid_request"));
 const uid=await user(bearer);
 if(!uid)return send(401,fail("not_authorized"));
 if(!await authorizedFreeformRelease())
  return send(403,fail("not_released"));
 // Recovery uses only server-stored request metadata, never localStorage.
 // No model dispatch or new budget reservation is possible on this branch.
 if(data.operation==="resume"||data.operation==="resume_ack"){
  const out=await restore(uid,data,data.operation==="resume_ack");
  return send(out.ok===true?200:409,out);
 }
 // Server derives verified learner facts. A pointer or text never grants authority.
 const p=await prepare(uid,data);
 if(!p)return send(403,fail("context_or_source_not_ready"));
 const out=data.operation==="ack"?await ack(p):await ask(p,PROVIDER_KEY);
 return send(out.ok===true?200:409,out);
});
