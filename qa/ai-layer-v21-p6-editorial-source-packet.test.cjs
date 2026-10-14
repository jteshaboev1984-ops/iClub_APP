"use strict";
const {test}=require("node:test"),a=require("node:assert/strict");
const {readFileSync}=require("node:fs");
const {candidatePacket,fromDisk}=require("./ai-layer-v21-p6-editorial-source-packet.cjs");
const original=JSON.parse(readFileSync("qa/ai-layer-v21-p6-navigation-editorial-drafts.snapshot.json","utf8"));
const clone=()=>structuredClone(original);
test("§53 produces exactly three deliberately unpublished prepared-only locale packets",()=>{
 const v=fromDisk();
 a.equal(v.ready,false);a.equal(v.reason,"editorial_review_required");
 a.deepEqual(v.packets.map(x=>x.locale),["ru","uz","en"]);
 for(const p of v.packets){
  a.equal(p.ready,false);a.equal(p.rightsApproved,false);
  a.equal(p.contentApproved,false);a.equal(p.releaseAllowed,false);
  a.equal(p.publicationState,"draft");a.equal(p.notSqlSourceHash,true);
  a.equal(p.sourceText,"");
  a.deepEqual(Object.keys(p.preparedVariants),
   ["nav_home","nav_courses","nav_ratings","nav_profile","nav_about","nav_support"]);
  a.match(p.draftFingerprint,/^[a-f0-9]{64}$/);
  a.ok(!("sourceHash" in p)&&!("approvedAt" in p));
  a.equal(p.preparedVariants.nav_about,
   original.entrypoints.find(e=>e.id==="nav_about").replies[p.locale]);
 }
 a.notEqual(v.packets[0].draftFingerprint,v.packets[1].draftFingerprint);
 a.notEqual(v.packets[1].draftFingerprint,v.packets[2].draftFingerprint);
});
test("Never mistake content, rights or reviewer status for publication permission",()=>{
 for(const mutate of [
  d=>{d.releaseAllowed=true},
  d=>{d.status="PUBLISHED"},
  d=>{d.editorialControls.approvedBy="fake_editor"},
  d=>{d.editorialControls.contentCorrectnessVerified=true},
  d=>{d.editorialControls.releaseApproved=true},
  d=>{delete d.editorialControls},
  d=>{d.localePolicy="auto_translate"},
  d=>{d.entrypoints.pop()},
  d=>{d.entrypoints.push(d.entrypoints[0])},
  d=>{d.entrypoints[0].id="arbitrary"}
 ]){
  const d=clone();mutate(d);const v=candidatePacket(d);a.equal(v.ready,false);
  a.equal("packets" in v,false,mutate.toString().slice(0,100));
 }
});
test("Missing locale, spoofed nav ID and cross-locale injection always fail closed",()=>{
 for(const mutate of [
  d=>{delete d.entrypoints[1].replies.en},
  d=>{d.entrypoints[1].replies.en=""}, 
  d=>{d.entrypoints[2].replies.uz=null},
  d=>{d.entrypoints[2].replies.ru="a".repeat(181)},
  d=>{d.entrypoints[3].id="nav_foo"},
  d=>{d.entrypoints[3].targetView="fake_route"},
  d=>{d.entrypoints[3].selector='[data-tab="home"]'},
  d=>{d.entrypoints[4].entryView="profile"},
  d=>{d.entrypoints[5].kind="tab"},
  d=>{d.entrypoints[4].id=d.entrypoints[3].id}
 ]){
  const d=clone();mutate(d);a.equal("packets" in candidatePacket(d),false);
 }
});
test("Packet transformation never changes the underlying editorial draft",()=>{
 const d=clone(),before=JSON.stringify(d);
 const first=candidatePacket(d),second=candidatePacket(d);
 a.deepEqual(first,second);a.equal(JSON.stringify(d),before);
});
