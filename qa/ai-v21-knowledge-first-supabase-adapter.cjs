"use strict";
/**
 * QA ONLY. Server-side authenticated wiring of EXISTING approved card RPCs
 * to the knowledge-first metadata gate. Not used by app, Preview or Edge.
 * No student result reads, Auth signups, writes, OpenAI calls or new RPCs.
 *
 * Explicitly NOT a publication gate: until an independent server-owned
 * release/current-screen/commercial proof is installed, resolve() fails shut.
 */
const {createKnowledgeFirstReadOnlyGate}=
 require("./ai-v21-knowledge-first-readonly-gate.cjs");
const UUID=/^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
const HASH64=/^[a-f0-9]{64}$/;
const SOURCE_KEY=/^[A-Za-z0-9][A-Za-z0-9:_-]{7,119}$/;
const LOCALES=new Set(["ru","uz","en"]);
const RPC=Object.freeze({
 math:"get_exam_prep_ai_tutor_card_service_v1",
 mathSource:"get_exam_prep_ai_source_cards_service_v1",
 practice:"get_practice_ai_source_cards_service_v1"
});
const METHODS=["readCurrentScope","readProtected","verifySubjectRights",
 "readEditorialRelease"];
const obj=x=>!!x&&typeof x==="object"&&!Array.isArray(x);
const str=x=>typeof x==="string"?x:"";
function validConfig(c){
 if(!obj(c)||!str(c.anonKey)||c.anonKey.length<8||
  !str(c.serviceRoleKey)||c.serviceRoleKey.length<16||
  c.anonKey===c.serviceRoleKey)return false;
 try{
  const u=new URL(c.supabaseUrl);
  return u.protocol==="https:"&&
    /^[a-z0-9-]+\.supabase\.co$/.test(u.hostname)&&
    u.pathname==="/"&&!u.port&&!u.username&&!u.password&&!u.search&&!u.hash;
 }catch{return false;}
}
function createKnowledgeFirstSupabaseAdapter(config,verified){
 if(!validConfig(config)||!obj(verified)||
  METHODS.some(n=>typeof verified[n]!=="function"))
  throw Error("trusted_server_readers_required");
 const fetcher=config.fetcher??fetch;
 if(typeof fetcher!=="function")throw Error("trusted_fetch_required");
 const base=config.supabaseUrl.replace(/\/$/,"");
 async function request(path,{method="POST",body,token,privileged=false}={}){
  // Path MUST be one of the fixed routes defined below.
  const ctrl=new AbortController(),timer=setTimeout(()=>ctrl.abort(),8000);
  try{
   const response=await fetcher(base+path,{
    method,redirect:"error",signal:ctrl.signal,
    headers:{
     "apikey":privileged?config.serviceRoleKey:config.anonKey,
     "authorization":"Bearer "+(privileged?config.serviceRoleKey:token),
     ...(method==="POST"?{"content-type":"application/json"}:{})
    },
    ...(method==="POST"?{body:JSON.stringify(body)}:{})
   });
   if(!response?.ok)return null;
   const data=await response.json();
   if(JSON.stringify(data).length>300000)return null;
   return data;
  }catch{return null;}finally{clearTimeout(timer);}
 }
 const call=async(name,params)=>{
  if(!Object.values(RPC).includes(name)||!obj(params))return null;
  return request("/rest/v1/rpc/"+name,{privileged:true,body:params});
 };
 async function auth(authorization){
  if(typeof authorization!=="string"||
   !/^Bearer [A-Za-z0-9._-]{16,2048}$/.test(authorization))return null;
  const a=await request("/auth/v1/user",{
   method:"GET",token:authorization.slice(7)
  });
  if(!obj(a)||!UUID.test(a.id||"")||a.role!=="authenticated"||
    (a.aud!==undefined&&a.aud!=="authenticated"))return null;
  return{authenticated:true,proof:"verified_supabase_auth_v1",userId:a.id};
 }
 function allowedRoute(route,type){
  return obj(route)&&route.type===type&&LOCALES.has(route.locale)&&
   str(route.subjectKey).length>0;
 }
 async function readMath(route){
  if(!allowedRoute(route,"math_card")||route.subjectKey!=="mathematics"||
    !["P1","P5"].includes(route.componentCode)||
    !/^P[15]-[A-Z0-9]+(?:-[A-Z0-9]+)*$/.test(route.skillCode||""))
   return null;
  const d=await call(RPC.math,{
   p_component_code:route.componentCode,p_skill_code:route.skillCode,
   p_locale:route.locale
  });
  return obj(d)&&Object.keys(d).length?d:null;
 }
 async function readPractice(route){
  if(!allowedRoute(route,"practice_card")||
   !Number.isSafeInteger(route.questionId)||route.questionId<1)
   return null;
  const data=await call(RPC.practice,{
   p_subject_key:route.subjectKey,p_locale:route.locale,
   p_card_type:"answer_explanation",p_question_id:route.questionId,
   p_topic:null,p_subtopic:null,p_limit:12
  });
  if(!Array.isArray(data)||data.length>12)return null;
  // The existing RPC intentionally returns generic topic cards as fallback.
  // These are NEVER evidence for an individual learner's finalized mistake.
  const bound=data.filter(c=>obj(c)&&
   c.question_id===route.questionId&&
   c.subject_key===route.subjectKey&&c.locale===route.locale&&
   c.card_type==="answer_explanation");
  return bound.length===1?bound[0]:null;
 }
 async function readSource(route,card){
  if(!obj(card)||!allowedRoute(route,route?.type))return null;
  const key=card.source_card_key;
  if(!SOURCE_KEY.test(key||""))return null;
  if(route.type==="math_card"){
   const data=await call(RPC.mathSource,{
    p_component_code:route.componentCode,p_locale:route.locale,
    p_card_type:null,p_skill_code:route.skillCode,p_limit:20
   });
   if(!Array.isArray(data)||data.length>20)return null;
   const exact=data.filter(x=>obj(x)&&x.source_card_key===key&&
    x.component_code===route.componentCode&&
    x.locale===route.locale&&
    // Exact skill, not a generic source which could teach the wrong method.
    x.skill_code===route.skillCode&&
    HASH64.test(x.content_hash||"")&&
    typeof x.source_version==="string"&&x.source_version.length>0);
   return exact.length===1?{
    sourceKey:key,sourceVersion:exact[0].source_version,
    sourceHash:exact[0].content_hash
   }:null;
  }
  if(route.type==="practice_card"&&
   card.question_id===route.questionId&&
   card.subject_key===route.subjectKey&&
   card.locale===route.locale&&
   card.card_type==="answer_explanation"&&
   HASH64.test(card.content_hash||"")&&
   typeof card.source_version==="string"&&card.source_version.length>0){
    return{sourceKey:key,sourceVersion:card.source_version,
     sourceHash:card.content_hash};
  }
  return null;
 }
 async function readApprovedSource(route,card){
  try{
   const source=await readSource(route,card);
   if(!source)return null;
   const contentVersion=route.type==="math_card"?
    card.content_version:card.source_version;
   // This independent publication approval is NOT present in the current
   // production v2 service set. It cannot be created from card.approval_status.
   const release=await verified.readEditorialRelease({
    type:route.type,locale:route.locale,subjectKey:route.subjectKey,
    componentCode:route.componentCode??null,skillCode:route.skillCode??null,
    questionId:route.questionId??null,sourceKey:source.sourceKey,
    sourceVersion:source.sourceVersion,sourceHash:source.sourceHash,
    cardHash:card.content_hash,contentVersion
   });
   if(!obj(release)||
      release.proof!=="independent_editorial_publication_service_v1"||
      release.type!==route.type||
      release.locale!==route.locale||
      release.subjectKey!==route.subjectKey||
      release.sourceKey!==source.sourceKey||
      release.sourceHash!==source.sourceHash||
      release.sourceVersion!==source.sourceVersion||
      release.cardHash!==card.content_hash||
      release.contentVersion!==contentVersion||
      release.componentCode!==(route.componentCode??null)||
      release.skillCode!==(route.skillCode??null)||
      release.questionId!==(route.questionId??null))return null;
   return{
    approved:release.approved===true,
    rightsApproved:release.rightsApproved===true,
    runtimeAllowed:release.runtimeAllowed===true,
    contentApproved:release.contentApproved===true,
    conflict:release.conflict!==false,
    qaPassed:release.qaPassed===true,
    locale:route.locale,subjectKey:route.subjectKey,
    sourceKey:source.sourceKey,cardHash:card.content_hash,
    contentVersion
   };
  }catch{return null;}
 }
 const readers=Object.freeze({
  authenticate:auth,
  readCurrentScope:verified.readCurrentScope,
  readProtected:verified.readProtected,
  verifySubjectRights:verified.verifySubjectRights,
  readApprovedSource,
  readMathTutorCard:readMath,
  readPracticeSourceCard:readPractice,
  // Public general help and Home are not published by this card adapter.
  // They need their own approved source, screen and Home priority authority.
  readPreparedHelp:async()=>null,
  chooseApprovedHome:async()=>null,
  nowMs:()=>Date.now()
 });
 return Object.freeze({
  resolve:createKnowledgeFirstReadOnlyGate(readers).resolve,
  // QA-only test introspection. Do not send card or JWT values to a browser.
  qaReaders:readers
 });
}
module.exports={createKnowledgeFirstSupabaseAdapter,validConfig};
