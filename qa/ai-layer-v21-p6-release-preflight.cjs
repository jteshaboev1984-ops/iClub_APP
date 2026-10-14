"use strict";
// §56 isolated QA release review. This module NEVER grants beta/deploy permission.
const {fromDisk}=require("./ai-layer-v21-p6-editorial-source-packet.cjs");
const {checkNavigationEditorial}=require("./ai-layer-v21-p6-navigation-semantic-review.cjs");
const {makeAccessibleNavPreview}=require("./ai-layer-v21-p6-nav-a11y-preview.cjs");
const {ownerProductDecisionGate}=require("./ai-layer-v21-owner-product-gate.cjs");
const {makeApprovedAccessibleNavPreview}=require("./ai-layer-v21-p6-nav-approved-locale.cjs");
const {readFileSync}=require("node:fs");
const read=p=>readFileSync(p,"utf8");
const deny=reason=>Object.freeze({status:"NO_GO",reason});
function p6ReleasePreflight(){
 const owner=ownerProductDecisionGate();
 if(owner.ownerProductState!=="THREE_CHOICES_APPROVED_FOR_QA_ONLY")
  return deny("product_copy_or_owner_policy_changed");
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
 let current,preview;
 try{
  const sources={
   draft:JSON.parse(read("qa/ai-layer-v21-p6-navigation-editorial-drafts.snapshot.json")),
   inventory:JSON.parse(read("qa/ai-layer-v21-p6-navigation-candidates.snapshot.json")),
   html:read("index.html"),app:read("app.js"),i18n:read("i18n.js")
  };
  current=checkNavigationEditorial(sources);
  preview=checkNavigationEditorial({...sources,
   html:makeAccessibleNavPreview(sources.html).html});
  // Independent product signoff permits locale-sensitive nav NAMES in QA,
  // never publication: verified against all three existing route labels.
  for(const locale of ["ru","uz","en"]){
   const candidate=makeApprovedAccessibleNavPreview(sources.html,locale);
   const review=checkNavigationEditorial({...sources,html:candidate.html});
   if(review.copyIntegrity!==true||review.accessibilityIssueCount!==0)
    return deny("approved_nav_locale_reaudit_required");
  }
 }catch{return deny("navigation_source_reaudit_required");}
 if(current?.copyIntegrity!==true||preview?.copyIntegrity!==true||
  current.checkedReplies!==18||preview.checkedReplies!==18||
  preview.accessibilityIssueCount!==0)
  return deny("navigation_candidate_review_failed");
 // A future change to the landmark requires fresh localization policy; the
 // review report may not describe an already-changed label as still English.
 if(current.tabbarAccessibleName!=="Bottom navigation"||
   preview.tabbarAccessibleName!==current.tabbarAccessibleName)
  return deny("navigation_landmark_reaudit_required");
 // Technical candidates ≠ rights or rollout. A future review must separately
 // prove current UI, immutable database source, JWT owner, screen revision,
 // published source in three locales, cohort and explicit architect approval.
 return Object.freeze({
  status:"NO_GO",reviewOnly:true,candidateLanguages:3,
  ownerProductState:owner.ownerProductState,
  ownerApprovedCopy:"18_EXACT_TEXTS_QA_ONLY",
  homePriorityPolicy:"APPROVED_QA_ONLY_SERVER_PLANNER_MISSING",
  navLandmarkPreview:"APPROVED_QA_ONLY_RU_UZ_EN",
  candidateDraftReplies:18,productionChanged:false,
  navigation:"NOT_EDITORIALLY_PUBLISHED",
  copySourceAudit:"18_DRAFT_REPLIES_VERIFIED_NOT_APPROVED",
  currentAccessibleNameMismatches:current.accessibilityIssueCount,
  candidateAccessibleNameMismatches:preview.accessibilityIssueCount,
  navigationLandmark:"UNTRANSLATED_REVIEW_REQUIRED",
  chromeAssistiveTechSignoff:"NOT_GIVEN",
  home:"NO_AUTHORITATIVE_CROSS_SUBJECT_PLANNER",
  uiBinding:"NOT_APPROVED",liveRpc:"NOT_INSTALLED_BY_QA",
  ownerCohortApproval:"NOT_GIVEN",payment:"NOT_ENABLED",
  requiredNextGate:"INDEPENDENT_OWNER_EDITORIAL_AND_TECHNICAL_REVIEW"
 });
}
module.exports={p6ReleasePreflight};
