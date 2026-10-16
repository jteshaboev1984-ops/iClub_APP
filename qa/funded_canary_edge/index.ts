import {MODEL,MAX_OUTPUT_TOKENS,MAX_REQUEST_MICROUSD,MAX_REQUEST_INPUT_BYTES,
  QUESTION,INSTRUCTIONS,upperCost,extractAnswer} from "./policy.ts";

// The dedicated operator pilot is independent of Global AI UI, Core and Tutor.
// It has no learner endpoint and accepts no user-provided prompt/source/model.
type Data = Record<string,unknown>;
const deny=(status:number,reason:string)=>new Response(JSON.stringify({ok:false,reason}),{
  status,headers:{"content-type":"application/json","cache-control":"no-store"}
});
const ok=(data:Data)=>new Response(JSON.stringify({ok:true,...data}),{
  status:200,headers:{"content-type":"application/json","cache-control":"no-store"}
});
const enabled=()=>Deno.env.get("ICLUB_AI_PAID_CANARY_ENABLED")==="true";
const config=()=>({url:Deno.env.get("SUPABASE_URL")||"",
  key:Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")||"",
  openai:Deno.env.get("OPENAI_API_KEY")||""});
async function rpc(name:string,args:Data,url:string,key:string):Promise<Data>{
  const resp=await fetch(url+"/rest/v1/rpc/"+name,{
    method:"POST",headers:{"content-type":"application/json","apikey":key,
      "authorization":"Bearer "+key},
    body:JSON.stringify(args),signal:AbortSignal.timeout(5000)
  });
  if(!resp.ok)throw Error("rpc_unavailable");
  const data=await resp.json();
  if(!data||typeof data!=="object"||Array.isArray(data))throw Error("rpc_invalid");
  return data as Data;
}
const UUID=/^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
Deno.serve(async request=>{
  if(request.method!=="POST")return deny(405,"method_not_allowed");
  const c=config();
  // Supabase verifies the request JWT before this handler runs.
  // Read-only status is safe for the Dashboard's normal test identity;
  // only the paid "run" action below requires exact service-role identity.
  if(!c.url||!c.key)return deny(503,"backend_unconfigured");
  let body:Data;
  try{
    const text=await request.text();
    if(text.length>400)return deny(400,"invalid_request");
    const raw=JSON.parse(text);
    if(!raw||typeof raw!=="object"||Array.isArray(raw))return deny(400,"invalid_request");
    body=raw as Data;
  }catch{return deny(400,"invalid_request");}
  if(body.intent==="status"&&Object.keys(body).length===1){
    // Dashboard may use anon/session JWT. Non-operator status is a
    // minimally informative, strictly zero-spend health probe.
    if(request.headers.get("authorization")!=="Bearer "+c.key)
      return ok({pilot:"operator_only",modelConfigured:c.openai.length>12,
        canRun:false});
    try{
      const s=await rpc("status_iclub_ai_paid_canary_v1",{},c.url,c.key);
      return ok({edgeEnabled:enabled(),modelConfigured:c.openai.length>12,
        moneyEnabled:s.enabled===true,liabilityMicroUsd:s.lifetime_microusd||0,
        maxLifetimeMicroUsd:s.max_lifetime_microusd||0,
        activeRequests:s.inflight||0});
    }catch{return deny(503,"money_status_unavailable");}
  }
  // Neither student sessions nor the Dashboard's normal test token can
  // dispatch a paid request. No privileged secrets are returned by status.
  if(!c.key||request.headers.get("authorization")!=="Bearer "+c.key)
    return deny(403,"operator_only");
  if(body.intent!=="run"||Object.keys(body).sort().join(",")!=="intent,request_id"||
     typeof body.request_id!=="string"||!UUID.test(body.request_id))
    return deny(400,"invalid_request");
  if(!enabled()||c.openai.length<12)return deny(503,"operator_canary_disabled");
  const requestId=body.request_id;
  const sourceBytes=new TextEncoder().encode(INSTRUCTIONS+QUESTION).length;
  if(sourceBytes>MAX_REQUEST_INPUT_BYTES ||
      upperCost(sourceBytes+4096,MAX_OUTPUT_TOKENS)===null)
    return deny(503,"worst_case_token_cap");
  let reserve:Data;
  try{reserve=await rpc("reserve_iclub_ai_paid_canary_v1",
    {p_request_id:requestId},c.url,c.key);}
  catch{return deny(503,"money_unavailable");}
  if(reserve.allowed!==true||reserve.hold_microusd!==MAX_REQUEST_MICROUSD)
    return deny(409,String(reserve.reason||"budget_denied"));
  if(!enabled()){
    try{await rpc("finish_iclub_ai_paid_canary_v1",
      {p_request_id:requestId,p_outcome:"no_charge",p_actual_microusd:null},c.url,c.key);}
    catch{/* Full hold retained until verified settlement */ }
    return deny(409,"canary_disabled_after_reserve");
  }
  let dispatched:Data;
  try{dispatched=await rpc("dispatch_iclub_ai_paid_canary_v1",
    {p_request_id:requestId},c.url,c.key);}
  catch{return deny(503,"dispatch_uncertain");}
  if(dispatched.allowed!==true)return deny(409,"dispatch_denied");
  // Paid HTTP is attempted exactly once. Even a timeout can incur costs.
  let provider:Data|null=null;
  try{
    const response=await fetch("https://api.openai.com/v1/responses",{
      method:"POST",
      headers:{"authorization":"Bearer "+c.openai,"content-type":"application/json"},
      body:JSON.stringify({model:MODEL,instructions:INSTRUCTIONS,input:QUESTION,
        max_output_tokens:MAX_OUTPUT_TOKENS,reasoning:{effort:"none"},
        store:false,tools:[],truncation:"disabled"}),
      signal:AbortSignal.timeout(12000)
    });
    if(response.ok){
      const data=await response.json();
      if(data&&typeof data==="object"&&!Array.isArray(data))provider=data as Data;
    }
  }catch{/* Unknown provider bill remains fully reserved. */}
  const usage=provider?.usage as Data|undefined;
  const charge=provider?.model===MODEL&&provider?.status==="completed"&&usage?
    upperCost(Number(usage.input_tokens),Number(usage.output_tokens)):null;
  const answer=provider?extractAnswer(provider):null;
  let settled:Data;
  try{settled=await rpc("finish_iclub_ai_paid_canary_v1",{
    p_request_id:requestId,p_outcome:charge===null?"unknown":"charged",
    p_actual_microusd:charge},c.url,c.key);}
  catch{return deny(503,"financial_reconciliation_unknown");}
  if(settled.ok!==true)return deny(503,"financial_reconciliation_unknown");
  if(charge===null||!answer)return deny(503,"model_answer_not_verified");
  return ok({answer,pilotOnly:true,inputTokens:usage?.input_tokens,
    outputTokens:usage?.output_tokens,billedCeilingMicroUsd:charge});
});
