"use strict";
const {test}=require("node:test"),a=require("node:assert/strict");
const {readFileSync}=require("node:fs");
const {approvedLabel,makeApprovedAccessibleNavPreview,syncApprovedNavLandmark}=
 require("./ai-layer-v21-p6-nav-approved-locale.cjs");
const raw=readFileSync("index.html","utf8");
const labels={ru:"Нижнее меню",uz:"Pastki menyu",en:"Bottom navigation"};
test("§79 approved QA-only nav landmark across RU UZ EN; no app source overwrite",()=>{
 for(const [locale,label] of Object.entries(labels)){
  a.equal(approvedLabel(locale),label);
  const next=makeApprovedAccessibleNavPreview(raw,locale);
  a.equal(next.releaseAllowed,false);a.equal(next.liveAppChanged,false);
  a.equal(next.landmark,label);
  a.ok(next.html.includes('id="tabbar" class="tabbar" aria-label="'+label+'"'));
  for(const tab of ["home","courses","ratings","profile"]){
   const m=new RegExp('<button\\b[^>]*data-tab="'+tab+'"[^>]*>').exec(next.html);
   a.ok(m);a.doesNotMatch(m[0],/aria-label=/);
  }
 }
 a.equal(raw.includes('data-tab="courses" aria-label="Courses"'),true);
 a.equal(readFileSync("index.html","utf8"),raw);
});
test("§79 unsupported languages and changed production nav fail closed",()=>{
 for(const locale of ["",null,"de","RU","uz-UZ"])
  a.throws(()=>makeApprovedAccessibleNavPreview(raw,locale),/invalid_locale/);
 a.throws(()=>makeApprovedAccessibleNavPreview(
  raw.replace('aria-label="Bottom navigation"','aria-label="Different"'),"ru"),
  /source_changed/);
});
test("§79 locale changes update only landmark on mock detached document",()=>{
 const nav={
  attrs:{},setAttribute(k,v){this.attrs[k]=v;},
  querySelectorAll(selector){
   a.equal(selector,"button[data-tab]");
   return Array.from({length:4},()=>({
    hasAttribute:()=>false,
    querySelector:q=>q===".tab-txt[data-i18n]"?{}:
     q===".tab-ico"?{getAttribute:()=> "true"}:null
   }));
  }
 };
 const doc={getElementById:k=>k==="tabbar"?nav:null};
 a.equal(syncApprovedNavLandmark(doc,"ru").ok,true);
 a.equal(nav.attrs["aria-label"],labels.ru);
 a.equal(syncApprovedNavLandmark(doc,"uz").ok,true);
 a.equal(nav.attrs["aria-label"],labels.uz);
 a.equal(syncApprovedNavLandmark(doc,"en").ok,true);
 a.equal(nav.attrs["aria-label"],labels.en);
 a.throws(()=>syncApprovedNavLandmark({}, "ru"),/missing_nav/);
});
