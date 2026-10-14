"use strict";
const {test}=require("node:test");
const a=require("node:assert/strict");
const {readFileSync}=require("node:fs");
const {makeAccessibleNavPreview}=require("./ai-layer-v21-p6-nav-a11y-preview.cjs");
const index=readFileSync("index.html","utf8");
const tabs=["home","courses","ratings","profile"];
function button(source,view){
 const r=new RegExp('<button\\b[^>]*\\bdata-tab="'+view+'"[^>]*>[\\s\\S]*?<\\/button>');
 return r.exec(source)?.[0]||null;
}
test("§74 preview removes only 4 conflicting tab aria-label overrides",()=>{
 const one=makeAccessibleNavPreview(index);
 a.equal(one.modifiedButtons,4);a.equal(one.releaseAllowed,false);
 a.equal(one.stillNeedsLandmarkReview,true);
 a.deepEqual(one.routeKeys,tabs);
 a.equal(index.includes('data-tab="courses" aria-label="Courses"'),true);
 for(const view of tabs){
  const original=button(index,view),updated=button(one.html,view);
  a.ok(original);a.ok(updated);
  a.match(original,/aria-label="/);
  a.doesNotMatch(updated,/aria-label="/);
  a.equal(updated,original.replace(/\\saria-label="[^"]*"/,""),
   "Only accessible-name override may be removed");
 }
 const navStart=index.indexOf('<nav id="tabbar"');
 const navEnd=index.indexOf("</nav>",navStart)+6;
 a.equal(one.html.slice(0,navStart),index.slice(0,navStart));
 a.equal(one.html.slice(one.html.indexOf("</nav>")+6),index.slice(navEnd));
 a.ok(one.html.includes('aria-label="Bottom navigation"'),
  "The untranslated landmark remains an explicitly open review item");
 a.equal(makeAccessibleNavPreview(index).html,one.html,
  "Preview transform must be stable and reproducible");
});
test("§74 changed DOM or duplicated tabbar must block candidate generation",()=>{
 for(const mutation of [
  index.replace('data-tab="home"','data-tab="home-old"'),
  index.replace('data-i18n="tab_study"','data-i18n="tab_courses_unknown"'),
  index.replace('data-tab="ratings" aria-label="Ratings"','data-tab="ratings"'),
  index+'<nav id="tabbar"></nav>'
 ])a.throws(()=>makeAccessibleNavPreview(mutation),/drift|name/);
});
test("§74 no QA transform gets imported by production application",()=>{
 const app=readFileSync("app.js","utf8");
 a.equal(app.includes("makeAccessibleNavPreview"),false);
 a.equal(index.includes("ai-layer-v21-p6-nav-a11y-preview.cjs"),false);
 a.equal(index.includes('data-tab="courses" aria-label="Courses"'),true);
});
