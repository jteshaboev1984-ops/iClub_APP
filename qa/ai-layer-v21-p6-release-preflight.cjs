"use strict";
// §56 isolated QA release review. This module NEVER grants beta/deploy permission.
const {fromDisk}=require("./ai-layer-v21-p6-editorial-source-packet.cjs");
const deny=reason=>Object.freeze({status:"NO_GO",reason});
function p6ReleasePreflight(){
 const packet=fromDisk();
 if(!Array.isArray(packet.packets)||packet.packets.length!==3)
  return deny("source_packet_incomplete");
 const locales=packet.packets.map(x=>x.locale).join(",");
 if(locales!=="ru,uz,en")return deny("missing_locale");
 if(packet.packets.some(x=>x.ready!==false||x.releaseAllowed!==false||
   x.rightsApproved!==false||x.contentApproved!==false||
   x.publicationState!=="draft"||x.notSqlSourceHash!==true))
  return deny("unexpected_editorial_state");
 const count=packet.packets.reduce((n,x)=>n+Object.keys(x.preparedVariants).length,0);
 if(count!==18)return deny("incomplete_copy");
 // Technical candidates ≠ rights or rollout. A future review must separately
 // prove current UI, immutable database source, JWT owner, screen revision,
 // published source in three locales, cohort and explicit architect approval.
 return Object.freeze({
  status:"NO_GO",reviewOnly:true,candidateLanguages:3,
  candidateDraftReplies:18,productionChanged:false,
  navigation:"NOT_EDITORIALLY_PUBLISHED",
  home:"NO_AUTHORITATIVE_CROSS_SUBJECT_PLANNER",
  uiBinding:"NOT_APPROVED",liveRpc:"NOT_INSTALLED_BY_QA",
  ownerCohortApproval:"NOT_GIVEN",payment:"NOT_ENABLED",
  requiredNextGate:"INDEPENDENT_OWNER_EDITORIAL_AND_TECHNICAL_REVIEW"
 });
}
module.exports={p6ReleasePreflight};
