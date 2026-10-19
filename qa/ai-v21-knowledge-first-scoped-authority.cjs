"use strict";
/**
 * QA-only glue for ALREADY DRAFTED v21 scoped-context, rollout, protected
 * assessment and independent editorial/source-proof RPC contracts.
 * Requires a trusted service-role RPC callable injected server side.
 * There are NO new production RPCs, no source publication, no mutations,
 * no identity lookup beyond the JWT in the existing Supabase Auth adapter.
 * When any draft RPC is absent, this fails CLOSED.
 */
const UUID=/^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
const HASH=/^[a-f0-9]{64}$/;
const LOCALES=new Set(["ru","uz","en"]);
const SCOPED="get_iclub_ai_v21_scoped_context_service";
const RUNTIME="get_iclub_ai_v21_runtime_service";
const PROTECTED="get_iclub_ai_v21_protected_service";
const ROLLOUT="get_iclub_ai_v21_rollout_service";
const RELEASE="get_iclub_ai_topic_release_service_v21";
const SOURCE="get_iclub_ai_v21_source_proof_service";
const obj=x=>x!==null&&typeof x==="object"&&!Array.isArray(x);
const okInt=x=>Number.isSafeInteger(x)&&x>0;
const validUser=x=>typeof x==="string"&&UUID.test(x);
const permittedResponse=r=>obj(r)&&r.allowed===true;
function createKnowledgeFirstScopedAuthority({rpc,nowMs=Date.now}={}){
 if(typeof rpc!=="function"||typeof nowMs!=="function")
  throw Error("trusted_rpc_required");
 async function run(name,args){
  try{
   const value=await rpc(name,args);
   return obj(value)?value:null;
  }catch{return null;}
 }
 async function runtime(){
  const x=await run(RUNTIME,{});
  return x?.ui_enabled===true&&x.gateway_enabled===true&&
   x.release_approved===true&&x.kill_switch===false;
 }
 async function readCurrentScope(userId,contextHandle,locale){
  if(!validUser(userId)||!validUser(contextHandle)||
     !LOCALES.has(locale)||!await runtime())return null;
  const d=await run(SCOPED,{p_user_id:userId,p_context_handle:contextHandle});
  if(!permittedResponse(d)||!obj(d.context))return null;
  const c=d.context;
  if(c.owner_id!==userId||c.route_authority!=="unified_ai"||
   c.active!==true||c.protected_assessment!==false||
   c.surface!=="practice"||c.feature!=="answer_explanation"||
   c.current_view!=="courses"||
   typeof c.subject!=="string"||
   !/^[a-z][a-z0-9_]{1,79}$/.test(c.subject)||
   !okInt(c.practice_session_id)||!okInt(c.question_id)||
   c.topic!=="question_"+c.question_id||
   typeof c.context_revision!=="string")return null;
  const m=/^screen_([1-9][0-9]{0,9})$/.exec(c.context_revision);
  const now=nowMs(),expires=c.expires_at_ms;
  if(!m||!okInt(Number(m[1]))||!Number.isSafeInteger(now)||
   !Number.isSafeInteger(expires)||expires<=now||
   expires-now>90000)return null;
  // The trusted RPC proves finalized, owner-enrolled Practice within its
  // scoped context and currently active server-owned screen revision.
  return{
   proof:"server_owner_current_screen_v1",
   authority:"v21_scoped_finalized_practice",
   ownerId:userId,contextHandle,revision:Number(m[1]),
   expiresAtMs:expires,locale,
   screenCode:"practice-review",scopeCode:"global",
   subjectKey:c.subject,assessmentActive:false,
   practiceSessionId:c.practice_session_id,questionId:c.question_id,
   finalized:true,ownsAnsweredQuestion:true
  };
 }
 async function readProtected(userId,revision){
  if(!validUser(userId)||!okInt(revision))return null;
  const x=await run(PROTECTED,{p_user_id:userId});
  if(x?.protected!==false)return null;
  return{proof:"owner_bound_assessment_guard_v1",
   ownerId:userId,contextRevision:revision,protected:false};
 }
 async function verifySubjectRights(userId,screen,intent){
  if(!validUser(userId)||!obj(screen)||intent!=="practice_card"||
   screen.ownerId!==userId||
   screen.authority!=="v21_scoped_finalized_practice"||
   screen.screenCode!=="practice-review"||
   !okInt(screen.questionId)||
   !await runtime())return null;
  const r=await run(ROLLOUT,{p_user_id:userId,
   p_surface:"practice",p_subject:screen.subjectKey,
   p_feature:"answer_explanation",p_topic:"question_"+screen.questionId});
  if(!permittedResponse(r))return null;
  return{allowed:true,proof:"server_entitlement_v1",
   ownerId:userId,contextRevision:screen.revision,
   subjectKey:screen.subjectKey,feature:"practice_card"};
 }
 async function readEditorialRelease(p){
  if(!obj(p)||p.type!=="practice_card"||
   !LOCALES.has(p.locale)||typeof p.subjectKey!=="string"||
   !/^[a-z][a-z0-9_]{1,79}$/.test(p.subjectKey)||
   !okInt(p.questionId)||
   p.componentCode!==null||p.skillCode!==null||
   typeof p.sourceKey!=="string"||
   !/^[A-Za-z0-9][A-Za-z0-9:_-]{7,119}$/.test(p.sourceKey)||
   typeof p.sourceVersion!=="string"||!p.sourceVersion||
   typeof p.contentVersion!=="string"||
   p.contentVersion!==p.sourceVersion||
   !HASH.test(p.cardHash||"")||
   p.sourceHash!==p.cardHash||!await runtime())return null;
  const topic="question_"+p.questionId;
  const args={p_surface:"practice",p_subject:p.subjectKey,
   p_feature:"answer_explanation",p_topic:topic,p_locale:p.locale};
  const release=await run(RELEASE,args);
  if(release?.ready!==true||release.surface!=="practice"||
   release.subject!==p.subjectKey||
   release.feature!=="answer_explanation"||
   release.topic!==topic||release.locale!==p.locale||
   release.source_id!==p.sourceKey||
   release.source_version!==p.sourceVersion||
   release.source_hash!==p.sourceHash||
   !okInt(release.revision))return null;
  const source=await run(SOURCE,args);
  if(source?.approved!==true||
   source.rights_approved!==true||
   source.runtime_allowed!==true||
   source.source_conflict!==false||
   source.source_id!==p.sourceKey||
   source.source_version!==p.sourceVersion||
   source.source_hash!==p.sourceHash)return null;
  // These flags derive ONLY from the independent draft RPC definitions:
  // topic release demands eight editorial approvals; source proof separately
  // checks rights, QA, runtime and recomputed immutable SHA-256.
  return{
   proof:"independent_editorial_publication_service_v1",
   type:p.type,locale:p.locale,subjectKey:p.subjectKey,
   componentCode:null,skillCode:null,questionId:p.questionId,
   sourceKey:p.sourceKey,sourceHash:p.sourceHash,
   sourceVersion:p.sourceVersion,cardHash:p.cardHash,
   contentVersion:p.contentVersion,
   approved:true,rightsApproved:true,runtimeAllowed:true,
   contentApproved:true,qaPassed:true,conflict:false
  };
 }
 return Object.freeze({readCurrentScope,readProtected,
  verifySubjectRights,readEditorialRelease});
}
module.exports={createKnowledgeFirstScopedAuthority};
