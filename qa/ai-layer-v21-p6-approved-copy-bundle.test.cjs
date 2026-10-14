"use strict";
const {test}=require("node:test"),a=require("node:assert/strict");
const fs=require("node:fs");
const {buildPreviewCopyBundle,fromDisk}=require("./ai-layer-v21-p6-approved-copy-bundle.cjs");
const text=fs.readFileSync("qa/ai-layer-v21-p6-navigation-editorial-drafts.snapshot.json","utf8");
test("§84 exact owner-approved 18 Help copies in RU UZ EN are preview-only",()=>{
 const v=fromDisk();a.equal(v.ready,true);
 a.equal(v.previewOnly,true);
 a.equal(v.sourceGitBlob,"ab94d7ca03bbdf521acc95dedafd0dba43c45f7e");
 a.equal(v.globalAiSourcePublished,false);a.equal(v.providerAllowed,false);
 a.equal(v.editorialRightsApproved,false);
 a.equal(Object.keys(v.texts.ru).length,6);
 for(const locale of ["ru","uz","en"]){
  a.deepEqual(Object.keys(v.texts[locale]),[
   "nav_home","nav_courses","nav_ratings","nav_profile","nav_about","nav_support"]);
  a.equal(typeof v.texts[locale].nav_about,"string");
 }
});
test("§84 even one changed character cannot inherit original product signoff",()=>{
 const changed=text.replace("В нижнем меню выберите «Главная».","Выберите «Главная».");
 a.equal(buildPreviewCopyBundle(changed).ready,false);
 a.equal(buildPreviewCopyBundle(changed).reason,"unapproved_source_change");
 a.equal(buildPreviewCopyBundle("<invalid>").ready,false);
});
test("§85 standalone Preview includes no live JS, API calls or cookies",()=>{
 const html=fs.readFileSync("qa/preview_v21/index.html","utf8");
 a.match(html,/connect-src 'none'/);
 a.match(html,/default-src 'none'/);
 a.doesNotMatch(html,/(?:supabase|fetch\(|XMLHttpRequest|WebSocket|localStorage|sessionStorage|api[_-]?key|service[_-]?role|<script src=)/i);
 a.match(html,/Personal recommendations are not available yet/);
 a.match(html,/Персональные рекомендации ещё недоступны/);
 a.match(html,/Shaxsiy tavsiyalar hozircha mavjud emas/);
 a.match(html,/Bottom navigation/);
 a.match(html,/Нижнее меню/);
 a.match(html,/Pastki menyu/);
 a.doesNotMatch(html,/target="production"/);
});
