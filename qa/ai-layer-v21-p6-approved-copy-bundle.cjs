"use strict";
// §84: product-approved navigation copy -> immutable QA preview-only bundle.
// NOT a DB source publication, NOT an editorial/rights or Global AI release.
const fs=require("node:fs");
const crypto=require("node:crypto");
const decision=require("./ai-layer-v21-owner-product-decisions-20261014.json");
const deny=reason=>Object.freeze({ready:false,reason});
function buildPreviewCopyBundle(rawText){
 if(typeof rawText!=="string")return deny("missing_source");
 const bytes=Buffer.from(rawText,"utf8");
 const gitBlob=crypto.createHash("sha1")
  .update(Buffer.from("blob "+bytes.length+"\0")).update(bytes).digest("hex");
 if(decision.navigationCopy?.productApproved!==true||
    decision.navigationCopy.exactDraftGitBlobSha!==gitBlob||
    Object.values(decision.release||{}).some(x=>x!==false))
  return deny("unapproved_source_change");
 let draft;
 try{draft=JSON.parse(rawText);}catch{return deny("invalid_draft");}
 if(draft.releaseAllowed!==false||
   draft.status!=="EDITORIAL_DRAFT_NOT_APPROVED"||
   draft.entrypoints?.length!==6||
   !draft.entrypoints.every(x=>x.replies&&
    ["ru","uz","en"].every(l=>typeof x.replies[l]==="string")))
  return deny("not_reviewed_copy");
 const texts=Object.fromEntries(["ru","uz","en"].map(l=>[l,
   Object.fromEntries(draft.entrypoints.map(x=>[x.id,x.replies[l]]))]));
 const payload=JSON.stringify({schema:"iclub_ai_qa_preview_copy_v1",
  productApproved:true,localeSet:["ru","uz","en"],texts});
 const fingerprint=crypto.createHash("sha256").update(payload,"utf8").digest("hex");
 return Object.freeze({
  ready:true,previewOnly:true,sourceFingerprint:fingerprint,
  productApproved:true,editorialRightsApproved:false,
  globalAiSourcePublished:false,providerAllowed:false,
  sourceGitBlob:gitBlob,texts:Object.freeze(texts)
 });
}
function fromDisk(){return buildPreviewCopyBundle(
 fs.readFileSync("qa/ai-layer-v21-p6-navigation-editorial-drafts.snapshot.json","utf8"));}
module.exports={buildPreviewCopyBundle,fromDisk};
