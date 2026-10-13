"use strict";
const {test}=require("node:test"),assert=require("node:assert/strict");
const {generateKeyPairSync,sign}=require("node:crypto");
const {verifyEditorialEvidence,signingBytes,GATES}=require("./ai-layer-v21-editorial-evidence.cjs");
const NOW=1791864000000;
const USERS=["aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa",
 "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb",
 "cccccccc-cccc-4ccc-8ccc-cccccccccccc",
 "dddddddd-dddd-4ddd-8ddd-dddddddddddd"];
function manifest(){
 return {protocol:"iclub-ai-editorial-evidence-v21",
 ticketId:"11111111-aaaa-4aaa-8aaa-111111111111",action:"publish",
 surface:"lesson",subject:"biology",feature:"topic_explanation",
 topic:"lesson_101",locale:"ru",sourceId:"synthetic_source",
 sourceVersion:"v1",sourceHash:"a".repeat(64),expectedRevision:0,
 qaEvidence:Object.fromEntries(GATES.map(k=>[k,true])),reason:"",
 issuedAtMs:NOW-1000,expiresAtMs:NOW+600000};
}
function fixture(m=manifest()){
 const trustRegistry={revision:"synthetic_qa_1",reviewers:[]},signatures=[],keys={};
 for(const [i,domain] of ["content","rights","technical","safety"].entries()){
  const kp=generateKeyPairSync("ed25519");
  keys[domain]=kp.privateKey;
  trustRegistry.reviewers.push({keyId:"qa_"+domain,reviewerId:USERS[i],domain,
   publicKeyPem:kp.publicKey.export({format:"pem",type:"spki"}),
   enabled:true,validFromMs:NOW-10000,validUntilMs:NOW+1000000});
 }
 for(const domain of m.action==="publish"?["content","rights","technical"]:["safety"]){
  const i=["content","rights","technical","safety"].indexOf(domain);
  signatures.push({domain,reviewerId:USERS[i],keyId:"qa_"+domain,
   signature:sign(null,signingBytes(m),keys[domain]).toString("base64url")});
 }
 return{manifest:m,signatures,trustRegistry,nowMs:NOW};
}
const check=f=>verifyEditorialEvidence(f);
test("three independently verified Ed25519 roles approve exact metadata, not content",()=>{
 const r=check(fixture());assert.equal(r.ok,true);
 assert.deepEqual(Object.keys(r.attestation.reviewers).sort(),["content","rights","technical"]);
 assert.match(r.attestation.manifest_sha256,/^[a-f0-9]{64}$/);
 assert.equal("publish" in r,false);
 assert.equal("answer" in r.attestation,false);
});
test("default missing trust registry denies even signatures with valid IDs",()=>{
 const x=fixture();x.trustRegistry=null;assert.equal(check(x).reason,"trust_registry_missing");
 const y=fixture();y.trustRegistry.reviewers=[];assert.equal(check(y).ok,false);
});
test("a stolen signature or duplicated reviewer cannot impersonate an independent domain",()=>{
 const x=fixture();x.signatures[1].signature=x.signatures[0].signature;
 assert.equal(check(x).reason,"invalid_signature");
 const y=fixture();y.signatures[1].reviewerId=y.signatures[0].reviewerId;
 assert.equal(check(y).ok,false);
 const z=fixture();z.signatures[1].keyId=z.signatures[0].keyId;
 assert.equal(check(z).ok,false);
});
test("all source identity and revision fields are cryptographically covered",()=>{
 for(const [k,v] of [["ticketId","22222222-bbbb-4bbb-8bbb-222222222222"],
 ["locale","uz"],["subject","chemistry"],["topic","lesson_102"],
 ["sourceId","synthetic_other"],["sourceVersion","v2"],
 ["sourceHash","b".repeat(64)],["expectedRevision",1]]){
  const x=fixture();x.manifest[k]=v;assert.equal(check(x).ok,false,k);
 }
});
test("eight checklist booleans required, not just reviewer UUIDs",()=>{
 for(const k of GATES){
  const x=fixture();x.manifest.qaEvidence[k]=false;
  assert.equal(check(x).reason,"manifest_invalid",k);
  const y=fixture();delete y.manifest.qaEvidence[k];
  assert.equal(check(y).reason,"manifest_invalid",k);
 }
});
test("expired manifest, untrusted role, expired key and removed signer deny",()=>{
 const a=fixture();a.nowMs=NOW+1000000;assert.equal(check(a).ok,false);
 const b=fixture();b.trustRegistry.reviewers[1].enabled=false;
 assert.equal(check(b).reason,"reviewer_untrusted");
 const c=fixture();c.signatures.pop();assert.equal(check(c).reason,"signatures_missing");
});
test("extra user metadata, unsupported surface and malformed signatures fail closed",()=>{
 const a=fixture();a.manifest.studentEmail="not_allowed";
 assert.equal(check(a).reason,"manifest_invalid");
 const b=fixture();b.manifest.surface="tour";assert.equal(check(b).ok,false);
 const c=fixture();c.signatures[0].signature="X";assert.equal(check(c).ok,false);
});
test("signed revocation has separate safety key, fixed reason and expected revision",()=>{
 const m=manifest();m.action="revoke";m.expectedRevision=1;
 m.ticketId="44444444-dddd-4ddd-8ddd-444444444444";
 m.qaEvidence={};m.reason="Synthetic emergency safety revocation.";
 const r=check(fixture(m));assert.equal(r.ok,true);
 assert.deepEqual(Object.keys(r.attestation.reviewers),["safety"]);
 const z=fixture(m);z.manifest.reason="Changed safety reason";
 assert.equal(check(z).reason,"invalid_signature");
 const q=fixture(m);q.manifest.expectedRevision=0;
 assert.equal(check(q).reason,"manifest_invalid");
});
