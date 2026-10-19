"use strict";
const {test}=require("node:test"),a=require("node:assert/strict");
const fs=require("node:fs"),path=require("node:path");
const p=require("./ai-v21-knowledge-first-production-boundary.cjs");
const root=path.resolve(__dirname,"..");
const read=x=>{try{return fs.readFileSync(path.join(root,x));}catch{return null;}};
const mainSame=x=>read(x);
const check=(qaRead=read,mainRead=mainSame,proofs={})=>
  p.compareSnapshots({qaRead,mainRead,proofs});
test("six running Math assets and original app host stay byte identical",()=>{
  for(const [file,sha] of Object.entries({...p.FROZEN,...p.FROZEN_HOST}))
    a.equal(p.gitBlob(read(file)),sha,file);
  a.equal(check().mathFrozen,true);
  a.equal(check().qaIntegrityOk,true);
});
test("missing production comparison is never silently considered compatible",()=>{
  const r=check(read,()=>null);
  a.equal(r.qaIntegrityOk,false);
  a.equal(r.productionPromotion,"NO_GO");
  a.equal(r.currentMainUnavailable.length,p.HOST_REVIEW.length);
  a.ok(r.mathProductionDrift.length>0);
});
test("newer host app.js cannot be silently replaced by an older QA shell",()=>{
  const main=x=>x==="app.js"?Buffer.concat([read(x),Buffer.from("\n// newer host\n")]):read(x);
  const r=check(read,main);
  a.deepEqual(r.hostChangesNeedReview,["app.js"]);
  a.equal(r.mathFrozen,true);
  a.equal(r.productionPromotion,"NO_GO");
});
test("accidental Exam Prep or original host edit blocks the QA commit",()=>{
  const qa=x=>x==="exam-prep/exam-prep-ai-ui.js"||x==="index.html"?
    Buffer.concat([read(x),Buffer.from("\n// forbidden change\n")]):read(x);
  const r=check(qa,mainSame);
  a.ok(r.protectedFileFailures.includes("exam-prep/exam-prep-ai-ui.js"));
  a.ok(r.protectedFileFailures.includes("index.html"));
  a.equal(r.qaIntegrityOk,false);
});
test("new AI cannot reuse Math beta rights or skip independent source proof",()=>{
  const all=Object.fromEntries(p.EXPECTED_PROOFS.map(x=>[x,true]));
  const missing=p.EXPECTED_PROOFS[0];
  const partial={...all,[missing]:false};
  a.ok(check(read,mainSame,partial).missingServerReleaseProofs.includes(missing));
  const complete=check(read,mainSame,all);
  a.deepEqual(complete.missingServerReleaseProofs,[]);
  a.equal(complete.productionPromotion,"NO_GO");
  a.equal(complete.newAiLearnerDeliveryAuthorized,false);
  a.equal(complete.providerCalled,false);
  a.equal(complete.billed,false);
  a.equal(complete.academicStateChanged,false);
});
test("boundary checker cannot call network or mutate learner state",()=>{
  const code=fs.readFileSync(path.join(root,
    "qa/ai-v21-knowledge-first-production-boundary.cjs"),"utf8");
  a.doesNotMatch(code,/https:\/\/|supabase\.from\(|functions\.invoke\(|fetch\(/);
  a.doesNotMatch(code,/localStorage\.setItem\(|INSERT INTO|UPDATE private\./);
  a.equal(check().existingMathTutorRetained,true);
});
