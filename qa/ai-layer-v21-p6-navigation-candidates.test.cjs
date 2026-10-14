"use strict";
// QA navigation draft validation: actual DOM + router + i18n keys, not AI approval.
const {test}=require("node:test"),a=require("node:assert/strict");
const {readFileSync}=require("node:fs");
const root=p=>readFileSync(p,"utf8");
const h=root("index.html"),app=root("app.js"),lang=root("i18n.js");
const manifest=JSON.parse(root("qa/ai-layer-v21-p6-navigation-candidates.snapshot.json"));
const langs=["ru","uz","en"];
const routes=["home","courses","ratings","profile","about","support"];
function dictionary(locale){
 const start=lang.indexOf(locale+": {");
 const end=locale==="ru"?lang.indexOf("uz: {",start+5):
  locale==="uz"?lang.indexOf("en: {",start+5):lang.length;
 a.ok(start>=0&&end>start,"Missing i18n dictionary "+locale);
 return lang.slice(start,end);
}
function literal(dict,key){
 a.match(key,/^[a-z][a-z0-9_]{2,70}$/);
 const match=new RegExp("(?:^|\\n)\\s*"+key+":\\s*([\"'\\x60])([^\"'\\x60\\n]+)\\1").exec(dict);
 a.ok(match,"Missing literal app locale key "+key);
 return match[2];
}
test("P6 help candidate is unpublished metadata, NOT a source release or app readiness",()=>{
 a.equal(manifest.status,"DRAFT_ONLY_NOT_EDITORIALLY_APPROVED");
 a.equal(manifest.releaseAllowed,false);
 a.ok(Array.isArray(manifest.requiresIndependentReview));
 a.ok(manifest.requiresIndependentReview.includes("locale_editorial"));
 a.ok(manifest.requiresIndependentReview.includes("screen_proof"));
 a.deepEqual(manifest.sourceFiles,["app.js","index.html","i18n.js"]);
 a.deepEqual(manifest.views.map(v=>v.view),routes);
 for(const v of manifest.views)a.equal(v.readiness,"IN_DEVELOPMENT");
});
test("Every candidate navigation target exists and its label is from the actual iClub UI",()=>{
 a.ok(app.includes('["home", "courses", "ratings", "profile"].includes(tabName)'),
  "Live tab router was changed: re-review draft");
 const expectedKeys={
  home:"tab_home",courses:"tab_study",ratings:"tab_ratings",
  profile:"tab_profile",about:"about_title",support:"support_title"
 };
 for(const v of manifest.views){
  a.equal(v.labelKey,expectedKeys[v.view],"Unknown/unreviewed route");
  const expectedSelector=v.route==="tab"?
   'data-tab="'+v.view+'"':'data-view="'+v.view+'"';
  a.equal(v.target,v.route==="tab"?'[data-tab="'+v.view+'"]':'[data-view="'+v.view+'"]');
  a.ok(h.includes(expectedSelector),"Target not in live HTML: "+expectedSelector);
  if(v.route==="global")a.ok(h.includes('id="view-'+v.view+'"'),
   "Global view does not exist: "+v.view);
  else a.ok(h.includes('data-i18n="'+v.labelKey+'"'),
   "Missing tab translation binding: "+v.labelKey);
 }
});
test("RU UZ EN navigation labels match codepoint-exact current translation literals",()=>{
 for(const v of manifest.views){
  a.deepEqual(Object.keys(v.labels).sort(),langs.slice().sort());
  for(const locale of langs){
   const actual=literal(dictionary(locale),v.labelKey);
   a.equal(v.labels[locale],actual,locale+":"+v.labelKey+
    " changed; source must be re-reviewed, not silently translated");
   a.ok(actual.length>0&&actual.length<=90,"Missing/oversized locale label");
  }
 }
});
test("No personalized Home action, Profile readiness or unrelated academic copy is published",()=>{
 const s=JSON.stringify(manifest);
 for(const forbidden of ['next_actions','progress_percentage','mastery',
  'ai_answer','course_recommendation','source_text','approved_at',
  'source_hash','answers','score','private_key','llm_prompt'])
  a.equal(s.includes('"'+forbidden+'"'),false,"Unauthorized new content: "+forbidden);
 for(const v of manifest.views)a.deepEqual(Object.keys(v).sort(),
  ['labelKey','labels','readiness','route','target','view'].sort());
});
