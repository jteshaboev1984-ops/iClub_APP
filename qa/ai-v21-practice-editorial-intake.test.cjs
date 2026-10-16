"use strict";
const {test}=require("node:test");
const assert=require("node:assert/strict");
const fs=require("node:fs");
const {canonicalPracticeRef,inspectDraft,buildSyntheticDraft,LOCALES,REVIEW_FIELDS}=
 require("./ai-v21-practice-editorial-intake.cjs");
const {ContentHandoffGate}=require("./ai-layer-v21-content-handoff-gate.cjs");
const {verifyEditorialEvidence}=require("./ai-layer-v21-editorial-evidence.cjs");
const proof=()=>({
 origin:"trusted_server",kind:"finalized_practice_question_v4",
 owned:true,finalized:true,serverChecked:true,protectedAssessment:false,
 subject:"biology",questionId:202,topic:"question_202"
});
test("one exact canonical key shared with SQL and editorial evidence, never UI route names",()=>{
 const ref=canonicalPracticeRef(proof());
 assert.deepEqual(ref,{ok:true,surface:"practice",feature:"answer_explanation",
  topic:"question_202",subject:"biology",questionId:202});
 const sql=fs.readFileSync("qa/sql_drafts/iclub_ai_scoped_context_v21_UNAPPLIED.sql","utf8");
 const exactSource=fs.readFileSync(
  "qa/sql_drafts/iclub_ai_practice_exact_source_v21_UNAPPLIED.sql","utf8");
 const evidence=fs.readFileSync("qa/ai-layer-v21-editorial-evidence.cjs","utf8");
 assert.match(sql,/surface_code='practice' AND feature_code='answer_explanation'/);
 assert.match(exactSource,/c\.card_type='answer_explanation'/);
 assert.match(evidence,/m\.surface==="practice"/);
 assert.match(evidence,/m\.feature==="answer_explanation"/);
 assert.match(evidence,/\^question_/);
 const e2e=fs.readFileSync("qa/ai-v21-practice-source-governed-error-e2e.test.cjs","utf8");
 assert.match(e2e,/surface:"practice",subject:"biology",feature:"answer_explanation",topic:"question_202"/);
 assert.doesNotMatch(e2e,/surface:"practice_result"|feature:"error_explanation"|topic:"q202"/);
});
test("local editorial draft passes intake ONLY as not approved and never publishes",()=>{
 const result=inspectDraft(buildSyntheticDraft(),proof());
 assert.equal(result.ok,true);
 assert.equal(result.ready,false);
 assert.equal(result.releaseAllowed,false);
 assert.equal(result.next,"independent_academic_rights_locale_review");
 assert.deepEqual(Object.keys(result.contentDigests).sort(),LOCALES.slice().sort());
 for(const locale of LOCALES) assert.match(result.contentDigests[locale],/^[a-f0-9]{64}$/);
});
test("cannot infer editor approval from arbitrary applicant-defined true flags",()=>{
 for(const field of REVIEW_FIELDS){
  const draft=buildSyntheticDraft();draft.review[field]=true;
  const r=inspectDraft(draft,proof());
  assert.equal(r.ok,false,field);
 }
 for(const [key,value] of [["status","APPROVED"],["releaseAllowed",true],
  ["surface","practice_result"],["feature","error_explanation"],
  ["promptKey","explain_error"],["sourceKind","cambridge_textbook"],
  ["questionId",203],["subject","mathematics"]]){
  const draft=buildSyntheticDraft();draft[key]=value;
  assert.equal(inspectDraft(draft,proof()).ok,false,key);
 }
 const x=buildSyntheticDraft();x.approved=true;
 assert.equal(inspectDraft(x,proof()).ok,false,"Extra approval field");
});
test("browser-like, incomplete, stale and protected question evidence never opens editorial intake",()=>{
 for(const patch of [
  {origin:"browser_dom"},{kind:"screen_hint"},{owned:false},
  {finalized:false},{serverChecked:false},{protectedAssessment:true},
  {questionId:203},{topic:"question_203"},{subject:"general"},{subject:"mathematics"}
 ]){
  const evidence={...proof(),...patch};
  assert.equal(canonicalPracticeRef(evidence).ok,
   patch.subject==="mathematics" || patch.questionId===203&&patch.topic==="question_203"
   ?true:false,JSON.stringify(patch));
  // Even syntactically valid but different authoritative questions cannot reuse packet.
  assert.equal(inspectDraft(buildSyntheticDraft(),evidence).ok,false,JSON.stringify(patch));
 }
});
test("exact source version/hash, full RU/UZ/EN and independent reviewed text required",()=>{
 const cases=[
  d=>delete d.prepared.en,
  d=>d.prepared.uz=d.prepared.ru,
  d=>d.prepared.ru.sha256="b".repeat(64),
  d=>d.prepared.ru.sourceHash="b".repeat(64),
  d=>d.prepared.uz.sourceVersion="v999",
  d=>d.prepared.en.reviewed=true,
  d=>d.prepared.ru.text="<script>bad</script>",
  d=>d.prepared.en.text="short",
  d=>d.sourceHash="invalid",
  d=>d.sourceVersion="INVALID VERSION!",
  d=>d.rightsEvidenceId=null
 ];
 for(const change of cases){
  const d=buildSyntheticDraft();change(d);
  assert.equal(inspectDraft(d,proof()).ok,false,change.toString().slice(0,90));
 }
});
test("review packet is not a published source; live gate keeps help unavailable",async()=>{
 const p=proof(),d=buildSyntheticDraft();
 assert.equal(inspectDraft(d,p).ready,false);
 let providerCalls=0,charges=0;
 const gate=new ContentHandoffGate({
  getServerTimeMs:async()=>1000,
  isProtected:async()=>false,
  getGlobalState:async()=>({uiEnabled:true,gatewayEnabled:true,killSwitch:false,releaseApproved:true}),
  getScopedContext:async()=>({
   ownerId:"synthetic-user",routeAuthority:"unified_ai",active:true,
   protectedAssessment:false,expiresAtMs:9000,contextRevision:"r1",
   surface:"practice",subject:"biology",feature:"answer_explanation",topic:"question_202"
  }),
  getSubjectActive:async()=>true,isRolloutAuthorized:async()=>true,
  getPublishedRelease:async()=>null,
  getLiveSourceProof:async()=>null,
  reserveUsage:async()=>{charges++;},
  generateSynthetic:async()=>{providerCalls++;}
 });
 const r=await gate.check({
  principal:{authenticated:true,userId:"synthetic-user"},
  contextHandle:"synthetic-long-context",locale:"ru"
 });
 assert.equal(r.state,"in_development");
 assert.equal(r.canAsk,false);assert.equal(r.charge,0);
 assert.equal(providerCalls,0);assert.equal(charges,0);
});
test("editorial evidence verifier refuses unsigned, fake or draft publication data",()=>{
 const d=buildSyntheticDraft();
 const manifest={
  protocol:"iclub-ai-editorial-evidence-v21",
  ticketId:"22222222-2222-4222-8222-222222222222",
  action:"publish",surface:"practice",subject:d.subject,
  feature:"answer_explanation",topic:"question_202",locale:"ru",
  sourceId:d.sourceId,sourceVersion:d.sourceVersion,sourceHash:d.sourceHash,
  expectedRevision:0,qaEvidence:Object.fromEntries(
   ["content_approved","rights_approved","source_version_verified",
    "correctness_passed","negative_tests_passed","exam_security_passed",
    "locale_verified","accessibility_passed"].map(x=>[x,false])),
  reason:"",issuedAtMs:1000,expiresAtMs:2000
 };
 const rejected=verifyEditorialEvidence({
  manifest,signatures:[],trustRegistry:{revision:"synthetic",
    reviewers:[]},nowMs:1200
 });
 assert.equal(rejected.ok,false);
 const forged={...manifest,qaEvidence:Object.fromEntries(
  Object.keys(manifest.qaEvidence).map(k=>[k,true]))};
 assert.equal(verifyEditorialEvidence({manifest:forged,
  signatures:[],trustRegistry:{revision:"synthetic",reviewers:[]},nowMs:1200}).ok,false);
});
