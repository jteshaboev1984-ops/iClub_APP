"use strict";
// Owner-approved Home category order. QA-only candidate: no UI, RPC or writes.
const {QAHomeNextActionProof}=require("./ai-layer-v21-p6-home-next-action-proof.cjs");
const decisions=require("./ai-layer-v21-owner-product-decisions-20261014.json");
const ORDER=Object.freeze([
 "review_finalized_practice",
 "review_open_tour_archive",
 "continue_enrolled_subject"
]);
const deny=()=>Object.freeze({ready:false,reason:"in_development"});
const validId=x=>typeof x==="string"&&/^[a-z][a-z0-9_]{2,72}$/.test(x);
function productPolicyValid(d){
 return d?.schema==="iclub_ai_owner_product_decisions_v1"&&
  d.scope==="QA_AND_PROTECTED_PREVIEW_PREPARATION_ONLY"&&
  d.homeNextActions?.productApproved===true&&
  d.homeNextActions.policyVersion==="home_next_actions_20261014_v1"&&
  Array.isArray(d.homeNextActions.order)&&
  JSON.stringify(d.homeNextActions.order)===JSON.stringify(ORDER)&&
  d.homeNextActions.evidencePolicy==="SERVER_CONFIRMED_ONLY"&&
  d.homeNextActions.samePriorityTie==="RETURN_CHOICES_WITHOUT_AUTO_RANKING"&&
  d.homeNextActions.missingEvidence==="NO_RECOMMENDATION"&&
  d.homeNextActions.changesAcademicProgress===false&&
  d.release&&Object.values(d.release).every(x=>x===false);
}
class QAHomeApprovedPriority {
 constructor(services,decision=decisions){
  this.proof=new QAHomeNextActionProof(services);
  if(!productPolicyValid(decision))throw Error("unapproved_home_policy");
 }
 async choose(params){
  const proof=await this.proof.check(params);
  if(proof?.ready!==true||proof.priorityPolicyReady!==true||
   !Array.isArray(proof.priorityCandidates)||proof.priorityCandidates.length<1||
   proof.priorityCandidates.length>3)return deny();
  const seen=new Set();
  for(const action of proof.priorityCandidates){
   if(!validId(action.actionId)||!validId(action.subjectKey)||
    !ORDER.includes(action.actionCode)||seen.has(action.actionId))
    return deny();
   seen.add(action.actionId);
  }
  const level=Math.min(...proof.priorityCandidates.map(a=>ORDER.indexOf(a.actionCode)));
  const winning=proof.priorityCandidates.filter(a=>ORDER.indexOf(a.actionCode)===level);
  if(!winning.length)return deny();
  const common={ready:true,reviewOnly:true,policyVersion:"home_next_actions_20261014_v1",
   screenRevision:proof.screenRevision,planRevision:proof.planRevision,
   expiresAtMs:proof.expiresAtMs,source:"OWNER_BOUND_SERVER_PROOF_ONLY",
   releaseAllowed:false};
  if(winning.length>1){
   // An ambiguous same-priority subject is NOT arbitrarily ranked by local
   // order, weakest grade, latest click, profile tile or display percentage.
   return Object.freeze({...common,status:"selection_required",
    candidateActionIds:Object.freeze(winning.map(a=>a.actionId).sort())});
  }
  const a=winning[0];
  return Object.freeze({...common,status:"candidate_only",
   actionId:a.actionId,actionCode:a.actionCode,subjectKey:a.subjectKey});
 }
}
module.exports={QAHomeApprovedPriority,productPolicyValid};
