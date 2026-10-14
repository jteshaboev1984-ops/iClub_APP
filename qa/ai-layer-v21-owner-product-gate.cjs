"use strict";
// Architect's product decisions are NOT source rights or deployment approvals.
// Pin the exact six x three human-approved copy lines to the Git blob digest.
const {createHash}=require("node:crypto");
const {readFileSync}=require("node:fs");
const decisions=require("./ai-layer-v21-owner-product-decisions-20261014.json");
const {productPolicyValid}=require("./ai-layer-v21-p6-home-approved-priority.cjs");
const NO=()=>Object.freeze({status:"NO_GO",ownerProductState:"REVIEW_REQUIRED"});
function ownerProductDecisionGate(){
 try{
  if(!productPolicyValid(decisions)||decisions.navigationCopy.productApproved!==true||
   decisions.accessibility.productApproved!==true||
   decisions.navigationCopy.entries!==6||
   JSON.stringify(decisions.navigationCopy.localeSet)!=='["ru","uz","en"]')
   return NO();
  const raw=readFileSync("qa/ai-layer-v21-p6-navigation-editorial-drafts.snapshot.json");
  const sha=createHash("sha1").update(Buffer.from("blob "+raw.length+"\0"))
   .update(raw).digest("hex");
  if(sha!==decisions.navigationCopy.exactDraftGitBlobSha)return NO();
  const copy=JSON.parse(raw.toString("utf8"));
  if(copy.releaseAllowed!==false||copy.status!=="EDITORIAL_DRAFT_NOT_APPROVED"||
   copy.entrypoints?.length!==6||
   Object.values(copy.editorialControls||{}).some(x=>x===true))return NO();
  return Object.freeze({status:"NO_GO",ownerProductState:"THREE_CHOICES_APPROVED_FOR_QA_ONLY",
   exactCopySourcePinned:true,approvedProductReplies:18,
   homePriorityVersion:decisions.homeNextActions.policyVersion,
   accessibilityLocaleCandidate:true,independentEditorialSignoff:false,
   rightsSignoff:false,sourcePublication:false,realCohort:false,
   providerSpend:false,productionDeploy:false});
 }catch{return NO();}
}
module.exports={ownerProductDecisionGate};
