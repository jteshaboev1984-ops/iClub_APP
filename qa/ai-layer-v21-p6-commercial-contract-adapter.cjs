"use strict";
// §100 Real commercial contract compatibility, QA ONLY.
// Input snapshots MUST be read by a trusted server. It never calls Supabase,
// never trusts browser allowances, and cannot grant Global AI in production.
// Grounding: public.get_iclub_subject_access_guard_service_v1(uuid,text,text),
// public.get_iclub_subscription_capabilities_service_v1(uuid), private
// slot selections/config and public user_subjects/subj (metadata-only audit).
const INTENTS=Object.freeze(["study","competitive"]);
const owner=x=>typeof x==="string"&&/^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(x);
const subject=x=>typeof x==="string"&&/^[a-z][a-z0-9_]{1,79}$/.test(x);
const record=x=>x!==null&&typeof x==="object"&&!Array.isArray(x);
const positive=x=>Number.isSafeInteger(x)&&x>0;
const denied=()=>Object.freeze({allowed:false,verified:false,reason:"in_development"});
const validMode=x=>x==="study"||x==="competitive";
function checkContractProof(userId,subjectKey,intent,snapshot){
 if(!owner(userId)||!subject(subjectKey)||!INTENTS.includes(intent)||
    !record(snapshot))return denied();
 const {guard,capabilities,config,enrollment,slot,subjectRecord,featureGate}=snapshot;
 if(![guard,capabilities,config,enrollment,subjectRecord,featureGate].every(record))
  return denied();
 // Guard service returns {allowed:true} even in shadow / passthrough.
 // ONLY enforced commercial mode + reason explicitly proving "open".
 if(guard.allowed!==true||guard.mode!=="commercial"||
  !["subject_selected","plan_all_subjects"].includes(guard.reason))
  return denied();
 if(config.subjectLimitsMode!=="enforced"||
   config.grandfatherSnapshotCompleted!==true||
   !positive(config.revision))return denied();
 // Main product capability is distinct from a feature rollout approval.
 if(capabilities.resolved!==true||
   capabilities.ai_generation_entitled!==true||
   !["explicit_entitlement","default_free","canary_override"].includes(
     capabilities.plan_source)||typeof capabilities.plan_code!=="string"||
   capabilities.plan_code.length<1)return denied();
 // Even an entitled product MUST NOT authorize AI unless an independent,
 // trusted QA-only gate explicitly grants the feature. Never output GO.
 if(featureGate.origin!=="trusted_qa_server_only"||
   featureGate.scope!=="isolated_qa_only"||
   featureGate.feature!=="home_next_actions"||
   featureGate.approved!==true||
   featureGate.productionAllowed!==false||
   !positive(featureGate.revision))return denied();
 if(enrollment.userId!==userId||enrollment.subjectKey!==subjectKey||
   !validMode(enrollment.mode)||enrollment.mode!==intent||
   enrollment.active!==true||!positive(enrollment.revision))
  return denied();
 if(subjectRecord.subjectKey!==subjectKey||
   subjectRecord.isActive!==true)return denied();
 const selected=record(slot)&&slot.userId===userId&&
   slot.subjectKey===subjectKey&&positive(slot.revision);
 const studySelected=selected&&slot.studySelected===true;
 const allSubjects=capabilities.all_available_subjects===true;
 if(!allSubjects&&!studySelected)return denied();
 if(guard.reason==="plan_all_subjects"&&!allSubjects)return denied();
 if(guard.reason==="subject_selected"&&!studySelected)return denied();
 if(intent==="competitive"){
  // 'select_competitive' from the existing guard merely checks capacity;
  // it cannot substitute an existing competitive-selected record.
  if(subjectRecord.type!=="main"||!selected||
   slot.competitiveSelected!==true||slot.studySelected!==true)
   return denied();
 }else if(subjectRecord.type!=="main"&&subjectRecord.type!=="supplementary"
   &&subjectRecord.type!=="language"&&subjectRecord.type!=="sat"){
  // Unknown subject categories cannot gain new AI rights by default.
  return denied();
 }
 const revision=Math.max(config.revision,enrollment.revision,
  featureGate.revision,selected?slot.revision:0);
 if(!positive(revision))return denied();
 return Object.freeze({allowed:true,verified:true,userId,subjectKey,intent,
  revision,source:"server_enforced_subject_access_v1",mode:"commercial",
  competitiveSelectionVerified:intent==="competitive",
  qaOnly:true,productionAllowed:false,providerAllowed:false});
}
function makeCommercialProofAdapter(services){
 if(!services||typeof services.readCommercialSnapshot!=="function")
  throw Error("trusted server commercial reader required");
 return Object.freeze({
  verifySubjectAccess:async(userId,subjectKey,intent)=>{
   if(!owner(userId)||!subject(subjectKey)||!INTENTS.includes(intent))
    return denied();
   try{
    const snap=await services.readCommercialSnapshot(userId,subjectKey,intent);
    return checkContractProof(userId,subjectKey,intent,snap);
   }catch{return denied();}
  }
 });
}
module.exports={makeCommercialProofAdapter,checkContractProof};
