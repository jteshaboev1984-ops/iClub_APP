"use strict";
const {test}=require("node:test"),a=require("node:assert/strict");
const {readFileSync}=require("node:fs");
const {createHash}=require("node:crypto");
const decision=require("./ai-layer-v21-owner-product-decisions-20261014.json");
const {ownerProductDecisionGate}=require("./ai-layer-v21-owner-product-gate.cjs");
test("§77 approval matches the exact present 18-text draft and never grants release",()=>{
 const raw=readFileSync("qa/ai-layer-v21-p6-navigation-editorial-drafts.snapshot.json");
 const sha=createHash("sha1").update(Buffer.from("blob "+raw.length+"\0"))
  .update(raw).digest("hex");
 a.equal(sha,decision.navigationCopy.exactDraftGitBlobSha);
 const r=ownerProductDecisionGate();
 a.equal(r.status,"NO_GO");
 a.equal(r.ownerProductState,"THREE_CHOICES_APPROVED_FOR_QA_ONLY");
 a.equal(r.exactCopySourcePinned,true);
 a.equal(r.approvedProductReplies,18);
 a.equal(r.independentEditorialSignoff,false);
 a.equal(r.rightsSignoff,false);
 a.equal(r.sourcePublication,false);
 a.equal(r.realCohort,false);
 a.equal(r.providerSpend,false);
 a.equal(r.productionDeploy,false);
});
