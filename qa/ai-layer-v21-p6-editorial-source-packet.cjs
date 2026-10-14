"use strict";
// §53: offline editorial packet builder. Not an approval/publisher API.
const {readFileSync}=require("node:fs");
const {createHash}=require("node:crypto");
const file="qa/ai-layer-v21-p6-navigation-editorial-drafts.snapshot.json";
const locales=["ru","uz","en"];
const views=["home","courses","ratings","profile","about","support"];
const allowed=Object.freeze({
 home:{kind:"tab",entryView:null,selector:'[data-tab="home"]',labelKey:"tab_home"},
 courses:{kind:"tab",entryView:null,selector:'[data-tab="courses"]',labelKey:"tab_study"},
 ratings:{kind:"tab",entryView:null,selector:'[data-tab="ratings"]',labelKey:"tab_ratings"},
 profile:{kind:"tab",entryView:null,selector:'[data-tab="profile"]',labelKey:"tab_profile"},
 about:{kind:"global",entryView:"home",selector:'[data-action="open-about"]',labelKey:"profile_settings_about"},
 support:{kind:"global",entryView:"profile",selector:'[data-action="open-support"]',labelKey:"profile_support_title"}
});
const denied=reason=>({ready:false,reason});
function candidatePacket(draft){
 if(!draft||draft.status!=="EDITORIAL_DRAFT_NOT_APPROVED"||
    draft.releaseAllowed!==false||!draft.editorialControls||
    Object.keys(draft.editorialControls).length!==7||
    Object.values(draft.editorialControls).some(x=>x!==false&&x!==null)||
    !Array.isArray(draft.entrypoints)||draft.entrypoints.length!==6||
    draft.localePolicy!=="all_three_required_no_auto_translation")
  return denied("review_required");
 const seen=new Set();
 const payload=Object.fromEntries(locales.map(locale=>[locale,{}]));
 for(const entry of draft.entrypoints){
  const expected=allowed[entry?.targetView];
  if(entry?.id!=="nav_"+entry.targetView||
     !expected||entry.kind!==expected.kind||
     entry.entryView!==expected.entryView||
     entry.selector!==expected.selector||entry.labelKey!==expected.labelKey||
     !views.includes(entry.targetView)||seen.has(entry.targetView)||
     !entry.replies||Object.keys(entry.replies).sort().join(",")!=="en,ru,uz"||
     Object.values(entry.replies).some(x=>typeof x!=="string"||
       x.trim().length<12||x.length>180))return denied("invalid_draft");
  seen.add(entry.targetView);
  for(const locale of locales)
   payload[locale][entry.id]=entry.replies[locale];
 }
 if(seen.size!==6)return denied("incomplete");
 const packets=locales.map(locale=>{
  const prepared=Object.fromEntries(views.map(view=>
   ["nav_"+view,payload[locale]["nav_"+view]]));
  const digest=createHash("sha256")
   .update(JSON.stringify({locale,prepared}),"utf8").digest("hex");
  return Object.freeze({
   locale,sourceId:"qa_candidate_navigation_"+locale,
   sourceVersion:"draft_p6_navigation_v1",sourceText:"",
   preparedVariants:Object.freeze(prepared),
   draftFingerprint:digest,notSqlSourceHash:true,
   ready:false,rightsApproved:false,contentApproved:false,
   publicationState:"draft",releaseAllowed:false
  });
 });
 return Object.freeze({ready:false,reason:"editorial_review_required",
  packets:Object.freeze(packets)});
}
function fromDisk(){
 return candidatePacket(JSON.parse(readFileSync(file,"utf8")));
}
module.exports={candidatePacket,fromDisk};
