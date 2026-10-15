"use strict";
const {test}=require("node:test"),a=require("node:assert/strict");
const fs=require("node:fs");
const html=fs.readFileSync("qa/preview_v21/home-pg-local.html","utf8");
const original=fs.readFileSync("i18n.js","utf8");
function names(){
 const mark="const SUBJECT_NAMES=";
 const start=html.indexOf(mark);
 a(start>=0,"QA demo must define scoped trilingual subject caption table");
 const end=html.indexOf(";\nconst h=",start);
 a(end>start,"QA-only table must be static exact JSON");
 return JSON.parse(html.slice(start+mark.length,end));
}
test("§106 every visible tied subject matches the existing iClub RU UZ EN i18n.js strings",()=>{
 const subjects=names(),keys=["informatics","economics","biology",
  "chemistry","mathematics","english_a1","english_a2","english_b1","sat","ielts"];
 a.deepEqual(Object.keys(subjects).sort(),["ru","uz","en"]);
 for(const [index,locale] of ["ru","uz","en"].entries()){
  a.deepEqual(Object.keys(subjects[locale]).sort(),[...keys].sort());
  for(const key of keys){
   const re=new RegExp("\\bsubj_"+key+"\\s*:\\s*\"([^\"]+)\"","g");
   const list=[...original.matchAll(re)].map(m=>m[1]);
   a.equal(list.length,3,"Translation completeness "+key);
   a.equal(subjects[locale][key],list[index],
    "Do not change approved iClub visible subject label "+locale+"/"+key);
  }
 }
});
test("§106 Home QA never inserts untrusted response as HTML or gives tie fake action",()=>{
 a.match(html,/item\.textContent=SUBJECT_NAMES\[locale\]\[subject\]/);
 a.match(html,/Array\.isArray\(data\.choices\)/);
 a.match(html,/new Set\(data\.choices\.map/);
 a.doesNotMatch(html,/innerHTML\s*=\s*data\./);
 a.doesNotMatch(html,/\bcandidateActionIds\b/);
 a.doesNotMatch(html,/\bevidenceId\b/);
 a.doesNotMatch(html,/https?:\/\/(?:[^\s'"<]*supabase|api\.openai)/i);
});
