"use strict";
/**
 * AI v2.1 QA-only compatibility and release boundary.
 * Offline checks only: cannot call Supabase or modify any learner data.
 * Running Mathematics Exam Prep remains the authoritative Tutor.
 */
const fs = require("node:fs");
const crypto = require("node:crypto");
const {execFileSync} = require("node:child_process");
const path = require("node:path");
const ROOT = path.resolve(__dirname, "..");
const FROZEN = Object.freeze({
  "exam-prep/exam-prep-live.js":"4827d5d0aa101cabe88395403769c89017e892a9",
  "exam-prep/exam-prep-ai-ui.js":"23feb4322840c94eea32c85f07891e78855bf0d3",
  "exam-prep/exam-prep.css":"264d31a33ba34b926acd88265995e4b5fa5e8ae7",
  "exam-prep/exam-prep-api.js":"09b05a7b81e680d021e6604eb44d8e672249ff31",
  "supabase/functions/exam-prep-ai/index.ts":"7484bc1ec4dae842c559e3c63c4b84935e5cf312",
  "scripts/exam-prep-subject-isolation-regression.cjs":"8cd7b5aad83b6e7a52c28b1e5f8090a76a5f1514"
});
const FROZEN_HOST = Object.freeze({
  "index.html":"bd48c6f3ecaca02aeef64b4d9237ffa2102de2cd",
  "app.js":"be25cda7a0a0ce674ff9ddae1b312b7c6fb3d002"
});
const HOST_REVIEW = Object.freeze(["index.html","app.js","i18n.js","style.css"]);
const EXPECTED_PROOFS = Object.freeze([
  "auth_owner_bound","current_screen_server_owned","assessment_guard",
  "subject_rollout","independent_editorial_release","exact_source_locale",
  "post_await_revalidation","approved_learner_delivery"
]);
function gitBlob(value) {
  if(value == null) return null;
  const bytes=Buffer.isBuffer(value)?value:Buffer.from(String(value),"utf8");
  return crypto.createHash("sha1")
    .update(Buffer.from("blob "+bytes.length+"\0","utf8"))
    .update(bytes).digest("hex");
}
function compareSnapshots({qaRead,mainRead,proofs={}}={}) {
  if(typeof qaRead!=="function"||typeof mainRead!=="function")
    throw Error("read_only_sources_required");
  const broken=[];
  for(const [file,expected] of Object.entries({...FROZEN,...FROZEN_HOST})) {
    if(gitBlob(qaRead(file))!==expected)broken.push(file);
  }
  const mathProductionDrift=[];
  for(const file of Object.keys(FROZEN)) {
    if(gitBlob(mainRead(file))!==FROZEN[file])mathProductionDrift.push(file);
  }
  const missingMain=[],hostDrift=[];
  for(const file of HOST_REVIEW) {
    const current=mainRead(file),draft=qaRead(file);
    if(current==null||draft==null)missingMain.push(file);
    else if(gitBlob(current)!==gitBlob(draft))hostDrift.push(file);
  }
  const missingProofs=EXPECTED_PROOFS.filter(p=>proofs[p]!==true);
  return Object.freeze({
    mathFrozen:broken.filter(p=>Object.hasOwn(FROZEN,p)).length===0 &&
      mathProductionDrift.length===0,
    protectedFileFailures:Object.freeze(broken),
    mathProductionDrift:Object.freeze(mathProductionDrift),
    currentMainUnavailable:Object.freeze(missingMain),
    hostChangesNeedReview:Object.freeze(hostDrift),
    missingServerReleaseProofs:Object.freeze(missingProofs),
    existingMathTutorRetained:true,
    newAiLearnerDeliveryAuthorized:false,
    sourcePublishedByThisGate:false,
    providerCalled:false,academicStateChanged:false,billed:false,
    productionPromotion:"NO_GO",
    qaIntegrityOk:broken.length===0&&mathProductionDrift.length===0
  });
}
function readQa(file) {
  try{return fs.readFileSync(path.join(ROOT,file));}catch{return null;}
}
function readMain(file) {
  try{return execFileSync("git",["show","refs/remotes/origin/main:"+file],
    {cwd:ROOT,encoding:"buffer",stdio:["ignore","pipe","ignore"],timeout:5000});}
  catch{return null;}
}
if(require.main===module) {
  const outcome=compareSnapshots({qaRead:readQa,mainRead:readMain});
  console.log("AI_V21_KNOWLEDGE_FIRST_RELEASE_BOUNDARY",JSON.stringify(outcome));
  // Drift prevents release but is not a technical CI failure.
  // Frozen Mathematics edits ARE a hard CI failure.
  if(!outcome.qaIntegrityOk)process.exitCode=2;
}
module.exports={FROZEN,FROZEN_HOST,HOST_REVIEW,EXPECTED_PROOFS,gitBlob,
  compareSnapshots,readQa,readMain};
