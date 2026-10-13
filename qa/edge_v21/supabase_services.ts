// iClub AI v2.1 — Deno-native Supabase backend adapter. QA branch ONLY.
// This is NOT a deployed Edge Function and is intentionally not referenced
// by any active app, Edge entrypoint, Vercel config or existing Math Tutor.
// NO new-content publishing, provider calls, student writes or migrations.
// Missing v2 RPCs must fail CLOSED. No legacy Math RPC fallback permitted.

export type BackendConfig = {
  supabaseUrl: string;
  anonKey: string;
  serviceRoleKey: string;
  fetcher?: typeof fetch;
};
type Json = Record<string, unknown>;
type FeatureRef = {surface:string;subject:string;feature:string;topic:string;locale:string};
type Context = Json & {ownerId?:string;subject?:string};
type SourceBinding = {sourceId:string;sourceVersion:string;sourceHash:string;revision:number};
const VALID_SUBJECT = /^[a-z][a-z0-9_]{1,79}$/;
const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
const asObject=(v:unknown):Json|null=>
  v!==null&&typeof v==="object"&&!Array.isArray(v)?v as Json:null;
const str=(v:unknown)=>typeof v==="string"?v:"";
const TRUE=(v:unknown)=>v===true;
const toInt=(v:unknown)=>Number.isSafeInteger(v)?v as number:null;

// Trust boundary: secrets are supplied ONLY by Deno's trusted environment,
// never from the user's JSON payload. Reject credentialed non-HTTPS URLs.
export function validBackendConfig(cfg:BackendConfig):boolean{
 try{
  const u=new URL(cfg.supabaseUrl);
  const local=(u.hostname==="localhost"||u.hostname==="127.0.0.1");
  const official=/^[a-z0-9-]+\.supabase\.co$/i.test(u.hostname);
  return (u.protocol==="https:"&&official||u.protocol==="http:"&&local)
   &&u.username===""&&u.password===""&&u.search===""&&u.hash===""
   &&cfg.anonKey.length>=8&&cfg.serviceRoleKey.length>=8;
 }catch{return false;}
}
export class ServerRpcError extends Error{
 constructor(){super("trusted_backend_unavailable");this.name="ServerRpcError";}
}
export function createSupabaseServices(config:BackendConfig){
 if(!validBackendConfig(config))throw new ServerRpcError();
 const runFetch=config.fetcher??fetch;
 const root=config.supabaseUrl.replace(/\/$/,"");
 const key=config.serviceRoleKey;
 const call=async(path:string,options:RequestInit,privileged=true):Promise<unknown>=>{
  let reply:Response;
  try{
   reply=await runFetch(root+path,{
    ...options,
    headers:{
     "apikey":privileged?key:config.anonKey,
     ...(privileged?{"Authorization":"Bearer "+key}:{}),
     "Content-Type":"application/json",
     ...(options.headers||{})
    },
    redirect:"error",
    signal:AbortSignal.timeout(8000)
   });
  }catch{throw new ServerRpcError();}
  if(!reply.ok)throw new ServerRpcError();
  try{return await reply.json();}catch{throw new ServerRpcError();}
 };
 const rpc=async(name:string,args:Json):Promise<Json>=>{
  if(!/^[a-z][a-z0-9_]{3,120}$/.test(name))throw new ServerRpcError();
  const data=asObject(await call("/rest/v1/rpc/"+name,{
   method:"POST",body:JSON.stringify(args)}));
  if(!data)throw new ServerRpcError();
  return data;
 };
 const deny=()=>({ready:false,allowed:false});
 const safe=async<T>(fn:()=>Promise<T>,fallback:T):Promise<T>=>{
  try{return await fn();}catch{return fallback;}
 };
 return {
  // Actual Supabase Auth verification: the learner JWT, not admin credentials.
  authenticate:async(authorization:string)=>{
   if(!/^Bearer [A-Za-z0-9._-]{8,2048}$/.test(authorization))
    return null;
   const d=await safe(async()=>asObject(await call("/auth/v1/user",{
    method:"GET",headers:{Authorization:authorization}
   },false)),null);
   return d&&UUID.test(str(d.id))?{authenticated:true,userId:str(d.id)}:null;
  },
  getServerTimeMs:async()=>Date.now(),
  // These four read endpoints are proposed NEW v2 RPC contracts. They do not
  // exist in production. Their absence MUST hide/unavailable, not authorize.
  getGlobalState:async()=>{
   const d=await safe(()=>rpc("get_iclub_ai_v21_runtime_service",{}),deny());
   return{uiEnabled:TRUE(d.ui_enabled),gatewayEnabled:TRUE(d.gateway_enabled),
    killSwitch:d.kill_switch!==false,releaseApproved:TRUE(d.release_approved)};
  },
  isProtected:async(userId:string)=>{
   const d=await safe(()=>rpc("get_iclub_ai_v21_protected_service",{
    p_user_id:userId}),{protected:true});
   return d.protected!==false;
  },
  getScopedContext:async(userId:string,contextHandle:string):Promise<Context|null>=>{
   const d=await safe(()=>rpc("get_iclub_ai_v21_scoped_context_service",{
    p_user_id:userId,p_context_handle:contextHandle}),deny());
   if(d.allowed!==true)return null;
   const c=asObject(d.context);
   if(!c||str(c.owner_id)!==userId||c.active!==true)return null;
   return{
    ownerId:userId,routeAuthority:c.route_authority,
    active:c.active,protectedAssessment:c.protected_assessment,
    expiresAtMs:toInt(c.expires_at_ms),contextRevision:c.context_revision,
    surface:str(c.surface),subject:str(c.subject),feature:str(c.feature),topic:str(c.topic)
   };
  },
  // Scoped Practice context: only the server-verified learner ID is passed.
  // Session/question IDs are selectors, never sufficient proof; the service
  // validates ownership, finalization, answered question and enrollment.
  mintScopedContext:async(args:{userId:string;sessionId:number;questionId:number})=>{
   if(!UUID.test(args.userId)||!Number.isSafeInteger(args.sessionId)||
      !Number.isSafeInteger(args.questionId)||args.sessionId<=0||
      args.questionId<=0)return{allowed:false};
   return safe(()=>rpc("mint_iclub_ai_v21_practice_context_service",{
    p_user_id:args.userId,p_session_id:args.sessionId,p_question_id:args.questionId
   }),{allowed:false});
  },
  revokeScopedContext:async(args:{userId:string;contextHandle:string})=>{
   if(!UUID.test(args.userId)||!UUID.test(args.contextHandle))return{ok:false};
   return safe(()=>rpc("revoke_iclub_ai_v21_scoped_context_service",{
    p_user_id:args.userId,p_context_handle:args.contextHandle
   }),{ok:false});
  },
  // Existing verified public.subjects schema: this is READ-ONLY, never a
  // release grant. The release and source gates are independent and stricter.
  getSubjectActive:async(subject:string)=>{
   if(!VALID_SUBJECT.test(subject))return false;
   return safe(async()=>{
    const q="?select=subject_key,is_active&subject_key=eq."+encodeURIComponent(subject)+"&limit=2";
    const list=await call("/rest/v1/subjects"+q,{method:"GET"});
    return Array.isArray(list)&&list.length===1&&
      asObject(list[0])?.subject_key===subject&&asObject(list[0])?.is_active===true;
   },false);
  },
  isRolloutAuthorized:async({userId,context}:{userId:string;context:Context})=>{
   const d=await safe(()=>rpc("get_iclub_ai_v21_rollout_service",{
    p_user_id:userId,p_surface:context.surface,
    p_subject:context.subject,p_feature:context.feature,p_topic:context.topic
   }),deny());
   return d.allowed===true;
  },
  // This RPC is present in UNAPPLIED qa/sql_drafts ONLY. Production 404 =
  // in development, not "ready" or fallback to generic material.
  getPublishedRelease:async(ref:FeatureRef)=>{
   const d=await safe(()=>rpc("get_iclub_ai_topic_release_service_v21",{
    p_surface:ref.surface,p_subject:ref.subject,p_feature:ref.feature,
    p_topic:ref.topic,p_locale:ref.locale
   }),deny());
   return d.ready===true?{
    ready:true,...ref,source_id:d.source_id,source_version:d.source_version,
    source_hash:d.source_hash,revision:d.revision
   }:null;
  },
  // These are PROPOSED read service contracts; there is intentionally NO
  // direct card-table access or trusting client "ready" fields.
  getLiveSourceProof:async(ref:FeatureRef)=>{
   const d=await safe(()=>rpc("get_iclub_ai_v21_source_proof_service",{
    p_surface:ref.surface,p_subject:ref.subject,p_feature:ref.feature,
    p_topic:ref.topic,p_locale:ref.locale
   }),deny());
   return {
    ...ref,approved:d.approved===true,rightsApproved:d.rights_approved===true,
    runtimeAllowed:d.runtime_allowed===true,sourceConflict:d.source_conflict!==false,
    source_id:d.source_id,source_version:d.source_version,source_hash:d.source_hash
   };
  },
  getSourceBundle:async(args:SourceBinding & {
    userId:string;contextHandle:string;locale:string;route:string;promptKey:string
   })=>{
   const d=await safe(()=>rpc("get_iclub_ai_v21_source_bundle_service",{
    p_user_id:args.userId,p_context_handle:args.contextHandle,
    p_source_id:args.sourceId,p_source_version:args.sourceVersion,
    p_source_hash:args.sourceHash,p_publication_revision:args.revision,
    p_locale:args.locale,p_route_class:args.route,p_prompt_key:args.promptKey
   }),deny());
   if(d.approved!==true)return null;
   return {
    approved:true,rightsApproved:d.rights_approved===true,
    integrityVerified:d.integrity_verified===true,
    qaPassed:d.qa_passed===true,runtimeAllowed:d.runtime_allowed===true,
    conflict:d.source_conflict!==false,sourceId:d.source_id,
    sourceVersion:d.source_version,sourceHash:d.source_hash,
    revision:d.publication_revision,generationAllowed:d.generation_allowed===true,
    sourceText:d.source_text,variants:d.prepared_variants
   };
  },
  getPolicy:async({userId}:{userId:string})=>{
   const d=await safe(()=>rpc("get_iclub_ai_v21_entitlement_service",{
    p_user_id:userId}),deny());
   return d.allowed===true?d.usage_policy_code:null;
  },
  providerBudgetAllows:async(args:{userId:string;sourceId:string;route:string})=>{
   const d=await safe(()=>rpc("get_iclub_ai_v21_provider_budget_service",{
    p_user_id:args.userId,p_source_id:args.sourceId,p_route_class:args.route
   }),deny());
   return d.allowed===true;
  },
  // Intentionally no real provider adapter or academic generation. Even if
  // v2 release metadata were accidentally seeded, this rejects paid model use.
  generateSynthetic:async(_args:Json):Promise<never>=>{
   throw new ServerRpcError();
  },
  reserveUsage:async(args:{requestId:string;userId:string;policy:string;route:string;requestFingerprint:string})=>
   safe(()=>rpc("reserve_iclub_ai_usage_service_v2",{
    p_request_id:args.requestId,p_user_id:args.userId,
    p_usage_policy_code:args.policy,p_route_class:args.route,
    p_request_fingerprint:args.requestFingerprint
   }),deny()),
  claimDelivery:async(args:{requestId:string;userId:string;sessionFingerprint:string;requestFingerprint:string;route:string})=>
   safe(()=>rpc("claim_iclub_ai_delivery_service_v21",{
    p_request_id:args.requestId,p_user_id:args.userId,
    p_session_fingerprint:args.sessionFingerprint,
    p_request_fingerprint:args.requestFingerprint,p_route_class:args.route
   }),deny()),
  finishDelivery:async(args:{requestId:string;userId:string;sessionFingerprint:string;requestFingerprint:string;route:string;outcome:string})=>
   safe(()=>rpc("finish_iclub_ai_delivery_service_v21",{
    p_request_id:args.requestId,p_user_id:args.userId,
    p_session_fingerprint:args.sessionFingerprint,
    p_request_fingerprint:args.requestFingerprint,p_route_class:args.route,
    p_outcome:args.outcome
   }),{ok:false})
 };
}
