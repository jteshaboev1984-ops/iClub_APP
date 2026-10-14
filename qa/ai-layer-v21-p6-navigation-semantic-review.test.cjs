"use strict";
const {test}=require("node:test");
const assert=require("node:assert/strict");
const {readFileSync}=require("node:fs");
const {checkNavigationEditorial}=require("./ai-layer-v21-p6-navigation-semantic-review.cjs");
const read=p=>readFileSync(p,"utf8");
const base={
 draft:JSON.parse(read("qa/ai-layer-v21-p6-navigation-editorial-drafts.snapshot.json")),
 inventory:JSON.parse(read("qa/ai-layer-v21-p6-navigation-candidates.snapshot.json")),
 html:read("index.html"),app:read("app.js"),i18n:read("i18n.js")
};
const fixture=()=>structuredClone(base);
test("§73 the six real navigation routes and all 18 trilingual candidate directions match UI captions",()=>{
 const report=checkNavigationEditorial(fixture());
 assert.equal(report.copyIntegrity,true);
 assert.equal(report.checkedRoutes,6);
 assert.equal(report.checkedReplies,18);
 assert.deepEqual(report.locales,["ru","uz","en"]);
 assert.equal(report.status,"NO_GO");
 assert.equal(report.contentApproval,false);
 assert.equal(report.sourcePublication,false);
 assert.equal(report.rightsApproval,false);
 assert.equal(report.betaPermission,false);
});
test("§73 English-only aria-labels cannot be mistaken for translated screen-reader captions",()=>{
 const report=checkNavigationEditorial(fixture());
 assert.equal(report.accessibilityIssueCount,9);
 assert.equal(report.accessibilityIssues.filter(x=>x.locale==="ru").length,4);
 assert.equal(report.accessibilityIssues.filter(x=>x.locale==="uz").length,4);
 assert.deepEqual(report.accessibilityIssues.filter(x=>x.locale==="en").map(x=>x.view),
  ["courses"]);
 assert.deepEqual(report.accessibilityIssues.find(x=>x.view==="courses"&&x.locale==="en"),
  {view:"courses",locale:"en",visibleLabel:"Study",accessibleName:"Courses"});
 assert.equal(report.tabbarAccessibleName,"Bottom navigation");
 assert.equal(report.independentLanguageAndAccessibilityReview,"REQUIRED");
});
test("§73 mistaken label, wrong-language copy, and absent route instructions are rejected",()=>{
 const mutations=[
  data=>{data.draft.entrypoints.find(e=>e.id==="nav_about").replies.en=
   "On Home, choose “About”.";},
  data=>{data.draft.entrypoints[0].replies.uz=
   data.draft.entrypoints[0].replies.ru;},
  data=>{data.draft.entrypoints.find(e=>e.id==="nav_support").replies.en=
   "Open Profile and choose the support page.";},
  data=>{data.draft.entrypoints[3].replies.ru=
   "В нижнем меню выберите «Профиль»";},
  data=>{data.draft.entrypoints[5].replies.uz="";},
  data=>{data.html=data.html.replace('data-i18n="tab_study"',
   'data-i18n="tab_home"');},
  data=>{data.app=data.app.replace('action === "open-support"',
   'action === "other-route"');}
 ];
 for(const mutate of mutations){
  const data=fixture();mutate(data);
  const report=checkNavigationEditorial(data);
  assert.equal(report.copyIntegrity,false,mutate.toString().slice(0,75));
  assert.equal(report.status,"NO_GO");
 }
});
test("§73 approving flags in a QA draft never grants a source or rights publication",()=>{
 for(const field of ["contentCorrectnessVerified","languageReviewVerified",
  "accessibilityVerified","rightsApproved","releaseApproved"]){
  const data=fixture();data.draft.editorialControls[field]=true;
  assert.equal(checkNavigationEditorial(data).copyIntegrity,false,field);
 }
 const f=fixture();f.draft.releaseAllowed=true;
 assert.equal(checkNavigationEditorial(f).copyIntegrity,false);
});

test("§74 candidate native captions clear tab label mismatches but NEVER auto-approve AI",()=>{
 const {makeAccessibleNavPreview}=require("./ai-layer-v21-p6-nav-a11y-preview.cjs");
 const data=fixture();
 const before=checkNavigationEditorial(data);
 assert.equal(before.accessibilityIssueCount,9);
 data.html=makeAccessibleNavPreview(data.html).html;
 const after=checkNavigationEditorial(data);
 assert.equal(after.copyIntegrity,true);
 assert.equal(after.accessibilityIssueCount,0);
 assert.equal(after.tabbarAccessibleName,"Bottom navigation",
  "The nav landmark still needs independent locale review");
 assert.equal(after.independentLanguageAndAccessibilityReview,"REQUIRED");
 assert.equal(after.status,"NO_GO");
 assert.equal(after.contentApproval,false);
 assert.equal(after.sourcePublication,false);
 assert.equal(after.betaPermission,false);
});
