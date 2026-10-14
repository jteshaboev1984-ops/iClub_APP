"use strict";
const {test}=require("node:test");
const assert=require("node:assert/strict");
const {readFileSync}=require("node:fs");
const read=p=>readFileSync(p,"utf8");
const draft=JSON.parse(read("qa/ai-layer-v21-p6-navigation-editorial-drafts.snapshot.json"));
const candidate=JSON.parse(read("qa/ai-layer-v21-p6-navigation-candidates.snapshot.json"));
const app=read("app.js"),html=read("index.html"),i18n=read("i18n.js");
const languages=["ru","uz","en"];
const paths=["home","courses","ratings","profile","about","support"];
function label(locale,key){
 const start=i18n.indexOf(locale+": {");
 const stop=locale==="ru"?i18n.indexOf("uz: {",start+1):
  locale==="uz"?i18n.indexOf("en: {",start+1):i18n.length;
 assert(start>=0&&stop>start,"i18n source missing "+locale);
 assert.match(key,/^[a-z][a-z0-9_]{2,60}$/);
 const match=new RegExp("(?:^|\\n)\\s*"+key+":\\s*\"([^\"\\n]+)\"").exec(i18n.slice(start,stop));
 assert(match,"label missing from i18n "+locale+":"+key);
 return match[1];
}
test("Editorial navigation drafts remain non-publication and require separate reviewers",()=>{
 assert.equal(draft.status,"EDITORIAL_DRAFT_NOT_APPROVED");
 assert.equal(draft.releaseAllowed,false);
 assert.equal(draft.localePolicy,"all_three_required_no_auto_translation");
 assert.deepEqual(draft.sourceFiles,["app.js","index.html","i18n.js"]);
 assert.deepEqual(draft.editorialControls,{
 approvedBy:null,approvedAt:null,contentCorrectnessVerified:false,
 languageReviewVerified:false,accessibilityVerified:false,
 releaseApproved:false,rightsApproved:false
 });
 assert.deepEqual(draft.entrypoints.map(e=>e.targetView),paths);
});
test("All eighteen draft directions point to precisely existing iClub routes",()=>{
 assert.match(app,/function setTab\(tabName\)/);
 for(const e of draft.entrypoints){
  assert.equal(e.id,"nav_"+e.targetView);
  assert.deepEqual(Object.keys(e.replies).sort(),languages.slice().sort());
  const found=candidate.views.find(v=>v.view===e.targetView);
  assert(found,"not in verified navigation inventory: "+e.targetView);
  if(e.kind==="tab"){
   assert.equal(e.entryView,null);
   assert.equal(e.selector,'[data-tab="'+e.targetView+'"]');
   assert(html.includes('data-tab="'+e.targetView+'"'));
   assert.equal(e.labelKey,found.labelKey);
  }else{
   assert(["about","support"].includes(e.targetView));
   const action=e.targetView==="about"?"open-about":"open-support";
   assert.equal(e.selector,'[data-action="'+action+'"]');
   assert(html.includes('data-action="'+action+'"'));
   assert(html.includes('data-view="'+e.targetView+'"'));
   assert(app.includes('action === "'+action+'"'),"missing handler: "+action);
   assert.equal(e.entryView,e.targetView==="about"?"home":"profile");
   assert.equal(e.labelKey,e.targetView==="about"?"profile_settings_about":"profile_support_title");
   const parentStart=html.indexOf('id="view-'+e.entryView+'"');
   const parentEnd=html.indexOf('id="view-',parentStart+10);
   const parent=html.slice(parentStart,parentEnd);
   assert(parent.includes('data-action="'+action+'"'),
    "action no longer reachable from documented entry view: "+action);
  }
 }
});
test("No untranslated or wrong-language label in RU UZ EN learner draft",()=>{
 for(const e of draft.entrypoints){
  for(const locale of languages){
   const text=e.replies[locale];
   assert.equal(typeof text,"string");
   assert(text.length>12&&text.length<=180);
   assert(!/\\[|\\]|<script|\\{\{|\\}\}/.test(text));
   const targetLabel=label(locale,e.labelKey);
   assert(text.includes(targetLabel),
    "draft must use exactly actual UI label: "+locale+":"+e.id+":"+targetLabel);
   const navigationTab=e.entryView==="home"?"tab_home":"tab_profile";
   if(e.entryView!==null)
    assert(text.includes(label(locale,navigationTab)),
     "missing real entry tab label "+locale+":"+e.id);
  }
 }
});
test("Prepared draft cannot invent private academic next steps or release itself",()=>{
 const serialized=JSON.stringify(draft).toLowerCase();
 for(const term of ['percentage', 'question_id','mastery', 'exam_score',
  'student_name','model_response','api_key','llm_prompt','auto_approve',
  'next_actions','source_hash','ready_to_release'])
  assert.equal(serialized.includes('"'+term+'"'),false,term);
 for(const e of draft.entrypoints){
  assert.deepEqual(Object.keys(e).sort(),
   ["id","targetView","kind","entryView","selector","labelKey","replies"].sort());
 }
});

test('§69 review sheet copy matches the editorial draft',()=>{
 const sheet=read('docs/iclub-ai-layer-p6-editorial-review-sheet-v2.1.md');
 for(const entry of draft.entrypoints){
  for(const locale of languages)assert.ok(sheet.includes(entry.replies[locale]));
 }
 assert.equal(draft.releaseAllowed,false);
});
