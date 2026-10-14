"use strict";
// §71. QA-only regression of the existing Home source boundary.
// These checks deliberately CONFIRM that legacy Home display data is NOT
// a signed AI planning source; passing must never authorize publication.
const {test}=require("node:test");
const assert=require("node:assert/strict");
const fs=require("node:fs");
const path=require("node:path");
const root=path.join(__dirname,"..");
const read=p=>fs.readFileSync(path.join(root,p),"utf8");
const app=read("app.js");
const html=read("index.html");
function sliceBetween(src,start,end){
 const a=src.indexOf(start),b=src.indexOf(end,a+start.length);
 assert(a>=0&&b>a,"Home implementation drift; re-audit source before accepting AI claims: "+start);
 return src.slice(a,b);
}
function legacyBoundary(src){
 const home=sliceBetween(src,"function renderHome(","async function computeHomeCompetitiveStats(");
 const comp=sliceBetween(src,"async function computeHomeCompetitiveStats(","async function updateHomeCompetitiveCard(");
 const study=sliceBetween(src,"async function computeHomeStudyPracticeStats(","async function updateHomePinnedTile(");
 const hub=sliceBetween(src,"function renderSubjectHub(","async function renderLessons(");
 assert(home.includes("loadProfile()"),"Home profile source changed; re-audit");
 assert(home.includes("filterActiveUserSubjects(profile.subjects || [])"),"Home enrollment source changed; re-audit");
 assert(home.includes("pinned.slice(0, 4)"),"Home pinned-subject cap changed; re-audit");
 assert(comp.includes('.in("status", ["submitted", "time_expired", "anti_cheat"])'),
  "Legacy Home Tour status semantics changed; independently re-audit");
 assert(comp.includes("const d0 = new Date();"),"Home device-clock semantics changed; re-audit");
 assert(comp.includes("progressPct: 0")&&comp.includes("return fallback;"),
  "Home fallback semantics changed; re-audit");
 assert(!comp.includes("tour_session_runtime_v4"),"Home appears to have new runtime proof; independently verify");
 assert(study.includes("computePracticeStageStats(subjectKey)"),
  "Home Study display stats changed; re-audit");
 assert(study.includes("masteredCount: 0")&&study.includes("totalCount: 0"),
  "Home Study fallback changed; re-audit");
 assert(hub.includes("guardStudy?.(subjectKey)")&&hub.includes("isSubjectActive(subjectKey)"),
  "Subject Hub checks changed; entitlement impact review required");
 return true;
}
test("§71 Home current UI data are display-only, not signed AI recommendations",()=>{
 assert.equal(legacyBoundary(app),true);
 assert(!html.includes("ai-layer-v21-p6-home-next-action-proof"),
  "QA planner validator unexpectedly loaded by live shell");
 assert(!app.includes("QAHomeNextActionProof"),
  "Unapproved Home planning validator unexpectedly embedded in app");
});
test("§71 a changed status/calendar/fallback triggers an explicit new source audit",()=>{
 const cases=[
  app.replace('.in("status", ["submitted", "time_expired", "anti_cheat"])',
   '.in("status", ["submitted", "time_expired"])'),
  app.replace("const d0 = new Date();","const d0 = getServerDate();"),
  app.replace("progressPct: 0,","progressPct: null,")
 ];
 for(const modified of cases){
  assert.notEqual(modified,app,"test must actually change the source");
  assert.throws(()=>legacyBoundary(modified),/re-audit|semantics changed/);
 }
});
test("§71 only owner-scoped server proof could later enable Home; no silent editorial release",()=>{
 const proof=read("qa/ai-layer-v21-p6-home-next-action-proof.cjs");
 const preflight=read("qa/ai-layer-v21-p6-release-preflight.cjs");
 const editorial=JSON.parse(read("qa/ai-layer-v21-p6-navigation-editorial-drafts.snapshot.json"));
 assert.match(proof,/verifyPlanAuthority/);
 assert.match(proof,/verifyAcademicEvidence/);
 assert.match(proof,/verifyEditorialRelease/);
 assert.match(proof,/readCurrentScreen/);
 assert.match(preflight,/NO_GO/);
 assert.equal(editorial.releaseAllowed,false);
 assert.equal(editorial.editorialControls.releaseApproved,false);
});
