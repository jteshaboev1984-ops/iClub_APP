// iClub AI v2.1 — additive prepared General Help beta, independent of Math Tutor.
// Authenticated, cohort/consent/rights-gated. No model, new users or academic writes.
const BASE = "https://mmmduffgpvwjdpruzikw.supabase.co";
const SERVICE_FN = "deliver_iclub_ai_v21_beta_prepared_service";
const ACADEMIC_FN = "deliver_iclub_ai_v21_academic_service";
const CAPABILITIES_FN = "get_iclub_ai_v21_academic_capabilities_service";
const ACADEMIC_SURFACES = new Set(["practice_error","lesson_topic","tour_archive"]);
const KEYS = new Set([
 "support_help","catalog_help","ratings_help","home_next",
 "practice_rules","practice_after","tour_rules","books_help","about_help",
 "notifications_help","community_help","certificates_help",
 "profile_meaning","video_help","recs_help","archive_help",
 "nav_home","nav_courses","nav_ratings","nav_profile","nav_about","nav_support"
]);
const ORIGIN = /^https:\/\/(?:i-club-app\.vercel\.app|i-club-[a-z0-9-]+-jasurbeks-projects-c5451f97\.vercel\.app)$/i;
const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
type Obj=Record<string,unknown>;
function send(code:number,body:Obj,origin:string|null=null){
 const h=new Headers({"content-type":"application/json; charset=utf-8",
  "cache-control":"no-store","x-content-type-options":"nosniff",
  "referrer-policy":"no-referrer","vary":"Origin"});
 if(origin&&ORIGIN.test(origin)){
  h.set("Access-Control-Allow-Origin",origin);
  h.set("Access-Control-Allow-Headers","authorization, apikey, content-type, x-client-info");
  h.set("Access-Control-Allow-Methods","POST, OPTIONS");
 }
 return new Response(code===204?null:JSON.stringify(body),{status:code,headers:h});
}
const object=(x:unknown):x is Obj=>x!==null&&typeof x==="object"&&!Array.isArray(x);
async function safeJson(response:Response):Promise<Obj|null>{
 if(!response.ok)return null;
 try{const v:unknown=await response.json();return object(v)?v:null;}catch{return null;}
}
Deno.serve(async(req:Request)=>{
 const origin=req.headers.get("origin");
 if(!origin||!ORIGIN.test(origin))return send(403,{ok:false,reason:"origin_not_authorized"});
 if(req.method==="OPTIONS")return send(204,{},origin);
 if(req.method!=="POST")return send(405,{ok:false,reason:"method_not_allowed"},origin);
 if(!/^application\/json(?:\s*;\s*charset=utf-8)?$/i.test(req.headers.get("content-type")||""))
  return send(415,{ok:false,reason:"invalid_content_type"},origin);
 if(Number(req.headers.get("content-length")||0)>1024)
  return send(413,{ok:false,reason:"payload_too_large"},origin);
 let raw:string;
 try{raw=await req.text();}catch{return send(400,{ok:false,reason:"invalid_request"},origin);}
 if(new TextEncoder().encode(raw).length>1024)
  return send(413,{ok:false,reason:"payload_too_large"},origin);
 let body:Obj;
 try{const b:unknown=JSON.parse(raw);if(!object(b))throw Error();body=b;}
 catch{return send(400,{ok:false,reason:"invalid_request"},origin);}
 if(Object.keys(body).some(k=>!["intent","request_id","prompt_key","locale","consent_version",
      "surface","record_id","question_id"].includes(k)))
  return send(400,{ok:false,reason:"invalid_request"},origin);
 if(body.intent!=="status"&&body.intent!=="ask"&&body.intent!=="consent"&&
    body.intent!=="academic"&&body.intent!=="academic_available")
  return send(400,{ok:false,reason:"invalid_request"},origin);
 const bearer=req.headers.get("authorization")||"";
 if(!/^Bearer [A-Za-z0-9._-]{24,4000}$/.test(bearer))
  return send(401,{ok:false,reason:"authentication_required"},origin);
 const anon=Deno.env.get("SUPABASE_ANON_KEY")||"";
 const service=Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")||"";
 const url=Deno.env.get("SUPABASE_URL")||"";
 if(url!==BASE||!anon||!service||anon===service)
  return send(503,{ok:false,reason:"backend_unavailable"},origin);
 // Auth verifies THIS actual app session. Never accept user_id from the browser.
 let authenticated:Obj|null=null;
 try{
  authenticated=await safeJson(await fetch(BASE+"/auth/v1/user",{
   headers:{"apikey":anon,"authorization":bearer},
   signal:AbortSignal.timeout(5000)
  }));
 }catch{return send(503,{ok:false,reason:"auth_unavailable"},origin);}
 if(!authenticated||!UUID.test(String(authenticated.id||""))||
    authenticated.role!=="authenticated")
  return send(401,{ok:false,reason:"authentication_required"},origin);
 // Generic academic contract: neither a subject list nor study content
 // belongs in the Edge binary. The server derives subject and finalized state
 // from the signed learner's actual records and independently published source.
 if(body.intent==="academic"||body.intent==="academic_available"){
  const discovery=body.intent==="academic_available";
  const allowed=discovery
   ?["intent","surface","record_id","locale"]
   :["intent","surface","record_id","question_id","request_id","locale"];
  if(Object.keys(body).some(k=>!allowed.includes(k))||
    typeof body.surface!=="string"||!ACADEMIC_SURFACES.has(body.surface)||
    !Number.isSafeInteger(body.record_id)||Number(body.record_id)<=0||
    !["ru","uz","en"].includes(String(body.locale))||
    (!discovery&&
     (typeof body.request_id!=="string"||!UUID.test(body.request_id)||
      (body.surface==="practice_error"
       ?!Number.isSafeInteger(body.question_id)||Number(body.question_id)<=0
       :body.question_id!==null))))
   return send(400,{ok:false,reason:"invalid_request"},origin);
  const rpc=discovery?CAPABILITIES_FN:ACADEMIC_FN;
  let result:Obj|null=null;
  try{
   result=await safeJson(await fetch(BASE+"/rest/v1/rpc/"+rpc,{
    method:"POST",
    headers:{"apikey":service,"authorization":"Bearer "+service,
      "content-type":"application/json"},
    body:JSON.stringify(discovery?
      {p_user_id:authenticated.id,p_surface:body.surface,
       p_record_id:body.record_id,p_locale:body.locale}:
      {p_user_id:authenticated.id,p_request_id:body.request_id,
       p_surface:body.surface,p_record_id:body.record_id,
       p_question_id:body.question_id,p_locale:body.locale}),
    signal:AbortSignal.timeout(8000)
   }));
  }catch{return send(503,{ok:false,reason:"backend_unavailable"},origin);}
  if(!result)return send(503,{ok:false,reason:"backend_unavailable"},origin);
  if(discovery){
   const available=Array.isArray(result.available)?result.available
    .filter(x=>Number.isSafeInteger(x)&&Number(x)>0).slice(0,12):[];
   return send(200,{ok:result.ok===true,available},origin);
  }
  if(result.ok===true&&typeof result.message==="string"&&
     result.message.length>=30&&result.message.length<=6000&&
     result.mode==="prepared"&&result.provider_called===false&&
     result.academic_state_changed===false)
    return send(200,{ok:true,message:result.message,mode:"prepared",
      academic_state_changed:false,provider_called:false},origin);
  return send(200,{ok:false,
    reason:["usage_exhausted","active_assessment","context_not_authorized",
      "in_development","beta_not_enabled","request_conflict"].includes(
       String(result.reason))?String(result.reason):"in_development",
    ...(result.reason==="usage_exhausted"&&result.reset_at
       ?{reset_at:result.reset_at}:{})},origin);
 }
 // Real signed-identity beta status, not a preview-only UI guess.
 if(body.intent==="status"){
  if(Object.keys(body).length!==1)return send(400,{ok:false,reason:"invalid_request"},origin);
  let status:Obj|null=null;
  try{
   status=await safeJson(await fetch(BASE+
    "/rest/v1/rpc/get_iclub_ai_v21_beta_status_service",{
    method:"POST",
    headers:{"apikey":service,"authorization":"Bearer "+service,
      "content-type":"application/json"},
    body:JSON.stringify({p_user_id:authenticated.id}),
    signal:AbortSignal.timeout(5000)
   }));
  }catch{return send(503,{ok:false,reason:"backend_unavailable"},origin);}
  if(!status||status.ok!==true)return send(503,{ok:false,reason:"backend_unavailable"},origin);
  return send(200,{ok:true,eligible:status.eligible===true,
    candidate:status.candidate===true,consented:status.consented===true,
    preparedOnly:true,providerEnabled:false},origin);
 }
 if(body.intent==="consent"){
  if(Object.keys(body).length!==2||body.consent_version!=="global_ai_beta_v21")
   return send(400,{ok:false,reason:"invalid_consent"},origin);
  let consent:Obj|null=null;
  try{
   consent=await safeJson(await fetch(BASE+
    "/rest/v1/rpc/iclub_ai_v21_beta_opt_in_service_v1",{
    method:"POST",
    headers:{"apikey":anon,"authorization":bearer,
      "content-type":"application/json"},
    body:JSON.stringify({p_consent_version:"global_ai_beta_v21"}),
    signal:AbortSignal.timeout(5000)
   }));
  }catch{return send(503,{ok:false,reason:"backend_unavailable"},origin);}
  if(!consent)return send(503,{ok:false,reason:"backend_unavailable"},origin);
  return send(200,{ok:consent.ok===true,recorded:consent.recorded===true,
    reason:consent.ok===true?"consent_recorded":"not_eligible_or_already_recorded"},origin);
 }
 if(typeof body.request_id!=="string"||!UUID.test(body.request_id)||
    typeof body.prompt_key!=="string"||!KEYS.has(body.prompt_key)||
    !["ru","uz","en"].includes(String(body.locale)))
  return send(400,{ok:false,reason:"invalid_request"},origin);
 let answer:Obj|null=null;
 try{
  answer=await safeJson(await fetch(BASE+"/rest/v1/rpc/"+SERVICE_FN,{
   method:"POST",
   headers:{"apikey":service,"authorization":"Bearer "+service,
    "content-type":"application/json"},
   body:JSON.stringify({p_user_id:authenticated.id,
    p_request_id:body.request_id,p_help_key:body.prompt_key,p_locale:body.locale}),
   signal:AbortSignal.timeout(8000)
  }));
 }catch{return send(503,{ok:false,reason:"backend_unavailable"},origin);}
 if(!answer)return send(503,{ok:false,reason:"backend_unavailable"},origin);
 if(answer.ok!==true||typeof answer.message!=="string"||
    answer.message.length<10||answer.message.length>1800||
    answer.mode!=="prepared"||answer.provider_called!==false||
    answer.academic_state_changed!==false)
  return send(200,{ok:false,reason:String(answer.reason||"in_development"),
    ...(answer.reason==="usage_exhausted"&&answer.reset_at?
      {reset_at:answer.reset_at}:{})},origin);
 return send(200,{ok:true,message:answer.message,
  mode:"prepared",academic_state_changed:false,provider_called:false},origin);
});
