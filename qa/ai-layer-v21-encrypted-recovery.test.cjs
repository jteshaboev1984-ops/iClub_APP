"use strict";
const {test}=require("node:test"),assert=require("node:assert/strict");
const {randomBytes}=require("node:crypto");
const {EncryptedRecoveryPrototype}=require("./ai-layer-v21-encrypted-recovery.cjs");
const identity=()=>({requestId:"11111111-1111-4111-8111-111111111111",
 userId:"22222222-2222-4222-8222-222222222222",sessionId:"current-session-00001",
 requestFingerprint:"a".repeat(64),sourceHash:"b".repeat(64),
 revision:4,locale:"ru",route:"generated"});
const gates=()=>({validateFinalized:async()=>true,revalidate:async()=>true});
function fixture(){
 const rows=new Map(),keys=new Map([["synthetic-key-v1",randomBytes(32)]]);
 const time={ms:500000};
 const create=()=>new EncryptedRecoveryPrototype({rows,keys,
  currentKeyId:"synthetic-key-v1",now:()=>time.ms});
 return{rows,keys,time,create};
}
test("Lost HTTP response can be recovered from another worker without new provider call",async()=>{
 const f=fixture(),one=f.create(),reply="Synthetic safe QA response.";
 assert.deepEqual(await one.store({identity:identity(),reply,validateFinalized:async()=>true}),{ok:true});
 const other=f.create();
 const r=await other.recover({identity:identity(),...gates()});
 assert.deepEqual(r,{ok:true,alreadyProcessed:true,reply});
 assert.equal(f.rows.size,1);
});
test("Shared storage holds only authenticated encryption, no plain text or user/session",async()=>{
 const f=fixture();await f.create().store({identity:identity(),reply:"TOP_PRIVATE_SYNTHETIC",...gates()});
 const data=JSON.stringify([...f.rows]);
 for(const word of ["TOP_PRIVATE_SYNTHETIC",identity().userId,identity().sessionId,
  identity().sourceHash,identity().requestFingerprint])
  assert.equal(data.includes(word),false,word);
 const row=f.rows.get(identity().requestId);
 for(const k of ["nonce","authTag","ciphertext","keyId","identityDigest","expiresAt"])
  assert.ok(Object.hasOwn(row,k),k);
});
test("Provider completion without confirmed quota settlement creates no recoverable receipt",async()=>{
 const f=fixture(),s=f.create(),ctx=identity();
 for(const hook of [undefined,async()=>false,async()=>{throw Error("db lost")}])
  assert.equal((await s.store({identity:ctx,reply:"not finalized",validateFinalized:hook})).ok,false);
 assert.equal(f.rows.size,0);
});
test("Playback rechecks completed transaction AND currently valid source/exam/cohort",async()=>{
 const f=fixture(),s=f.create();await s.store({identity:identity(),reply:"Ready QA",...gates()});
 for(const changes of [{revalidate:undefined},{revalidate:async()=>false},
  {validateFinalized:async()=>false},{revalidate:async()=>{throw Error("offline")}}]){
  const x=await f.create().recover({identity:identity(),...gates(),...changes});
  assert.equal(x.ok,false);
  assert.equal(x.reason,"context_unverified");
 }
});
test("Wrong owner, session, source digest, locale, revision or route never returns an answer",async()=>{
 const f=fixture();await f.create().store({identity:identity(),reply:"Ready QA",...gates()});
 for(const [key,v]of [["userId","33333333-3333-4333-8333-333333333333"],
  ["sessionId","foreign-session-00002"],["sourceHash","c".repeat(64)],
  ["requestFingerprint","d".repeat(64)],["locale","uz"],
  ["revision",5],["route","prepared"]]){
  const x=await f.create().recover({identity:{...identity(),[key]:v},...gates()});
  assert.equal(x.reason,"receipt_unavailable",key);
 }
});
test("Authenticated GCM tampering and missing cryptographic key deny",async()=>{
 const f=fixture();await f.create().store({identity:identity(),reply:"Safe QA",...gates()});
 const id=identity().requestId,old=f.rows.get(id);
 f.rows.set(id,{...old,ciphertext:(old.ciphertext[0]==="A"?"B":"A")+old.ciphertext.slice(1)});
 assert.equal((await f.create().recover({identity:identity(),...gates()})).ok,false);
 f.rows.set(id,old);
 f.keys.delete("synthetic-key-v1");
 // Construct a new handler cannot encrypt without an active key; no silent recovery.
 assert.throws(()=>f.create(),/unconfigured_recovery_storage_or_key/);
});
test("Receipt expires at 120s and cannot be recovered or retried through model",async()=>{
 const f=fixture();await f.create().store({identity:identity(),reply:"Safe QA",...gates()});
 f.time.ms+=120000;
 assert.equal((await f.create().recover({identity:identity(),...gates()})).reason,"receipt_unavailable");
 assert.equal(f.rows.size,0);
});
test("Duplicate request IDs cannot replace encrypted responses even after another worker starts",async()=>{
 const f=fixture();await f.create().store({identity:identity(),reply:"First",...gates()});
 const x=await f.create().store({identity:identity(),reply:"Second",...gates()});
 assert.equal(x.reason,"request_already_recorded");
 assert.equal((await f.create().recover({identity:identity(),...gates()})).reply,"First");
});
test("No browser, data source, actual provider or default production key",()=>{
 assert.throws(()=>new EncryptedRecoveryPrototype({rows:new Map(),keys:new Map(),
  currentKeyId:"unknown-key"}),/unconfigured_recovery_storage_or_key/);
});
