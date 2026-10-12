// node --test qa/ai-layer-v21-request-delivery.test.cjs
"use strict";
const {test}=require("node:test"),assert=require("node:assert/strict");
const {SyntheticRequestDelivery}=require("./ai-layer-v21-request-delivery.cjs");
const {EphemeralReplyReceipts}=require("./ai-layer-v21-reply-receipts.cjs");
const user={userId:"learner-000001"};
const req=(changes={})=>({principal:user,sessionId:"session-000001",
 requestId:"request-000001",nowMs:100,question:"Explain P1 source card",...changes});
const mk=({approve=()=>true,route="generated",receiptStore,execute,identity,maxCompletedIds=2048}={})=>{
 const calls={execute:0,authorize:[],resolve:0};
 const delivery=new SyntheticRequestDelivery({
  authorize:async({stage,request})=>{calls.authorize.push(stage);return approve(stage,request);},
  resolveIdentity:async({request})=>{calls.resolve++;return identity?identity(request):{fingerprint:"sha256-synthetic-fingerprint-for-topic",route};},
  execute:async({request})=>{calls.execute++;return execute?execute(request):{ok:true,reply:"Verified synthetic AI answer"};},
  receipts:receiptStore,maxCompletedIds
 });
 return {delivery,calls};
};
test("same request ID returns identical generated answer and executes once",async()=>{
 const x=mk(),a=await x.delivery.submit(req()),b=await x.delivery.submit(req());
 assert.equal(a.ok,true);assert.equal(b.ok,true);assert.equal(b.alreadyProcessed,true);
 assert.equal(a.reply,b.reply);assert.equal(x.calls.execute,1);
});
test("same ID simultaneously cannot run model twice",async()=>{
 let unblock;const waiter=new Promise(resolve=>{unblock=resolve});
 const x=mk({execute:async()=>{await waiter;return {ok:true,reply:"Delayed answer"}}});
 const first=x.delivery.submit(req());
 await Promise.resolve();await Promise.resolve();await Promise.resolve();
 const second=x.delivery.submit(req());
 unblock();
 const values=await Promise.all([first,second]);
 assert.equal(x.calls.execute,1);assert.equal(values.filter(x=>x.ok).length,1);
 assert.equal(values.filter(x=>!x.ok).length,1);
});
test("other learner cannot retrieve a completed response",async()=>{
 const x=mk();await x.delivery.submit(req());
 const second=await x.delivery.submit(req({principal:{userId:"learner-000002"}}));
 assert.equal(second.reason,"request_identity_mismatch");assert.equal(x.calls.execute,1);
});
test("changing session, route or source hash under same ID fails closed",async()=>{
 const x=mk();await x.delivery.submit(req());
 assert.equal((await x.delivery.submit(req({sessionId:"session-000002"}))).reason,"request_identity_mismatch");
 const y=mk({identity:request=>({fingerprint:request?.question==="original"
 ? "fingerprint-original-source" : "fingerprint-modified-source",route:"prepared"})});
 await y.delivery.submit(req({question:"original"}));
 assert.equal((await y.delivery.submit(req({question:"different"}))).reason,"request_identity_mismatch");
});
test("user may not replay after exam protection begins",async()=>{
 let active=false;const x=mk({approve:()=>!active});
 assert.equal((await x.delivery.submit(req())).ok,true);
 active=true;
 assert.equal((await x.delivery.submit(req())).reason,"context_unverified");
 assert.equal(x.calls.execute,1);
});
test("source revoked between preflight and delivery gives no reply",async()=>{
 const x=mk({approve:stage=>stage==="preflight"});
 const r=await x.delivery.submit(req());
 assert.equal(r.reason,"context_unverified");assert.equal(x.calls.execute,0);
});
test("receipt expires without executing model again",async()=>{
 const x=mk({receiptStore:new EphemeralReplyReceipts({ttlMs:1000})});
 assert.equal((await x.delivery.submit(req())).ok,true);
 const again=await x.delivery.submit(req({nowMs:1100}));
 assert.equal(again.reason,"already_processed_receipt_expired");assert.equal(x.calls.execute,1);
});
test("closed chat removes reply but never authorizes a duplicate paid call",async()=>{
 const x=mk();await x.delivery.submit(req());
 x.delivery.clearSession(user.userId,"session-000001");
 assert.equal((await x.delivery.submit(req())).reason,"already_processed_receipt_expired");
 assert.equal(x.calls.execute,1);
});
test("unsuccessful provider response does not create completed tombstone",async()=>{
 let n=0;const x=mk({execute:()=>++n===1?{ok:false,reason:"provider_timeout"}:{ok:true,reply:"Recovered"}});
 assert.equal((await x.delivery.submit(req())).reason,"provider_timeout");
 assert.equal((await x.delivery.submit(req())).ok,true);
 assert.equal(x.calls.execute,2);
});
test("cache full may block reply but must not trigger a second model attempt",async()=>{
 const cache=new EphemeralReplyReceipts({maxEntries:1});
 const x=mk({receiptStore:cache});
 assert.equal((await x.delivery.submit(req())).ok,true);
 const changed=req({requestId:"request-000002"});
 assert.equal((await x.delivery.submit(changed)).reason,"already_processed_receipt_unavailable");
 assert.equal((await x.delivery.submit(changed)).reason,"already_processed_receipt_expired");
 assert.equal(x.calls.execute,2);
});
test("absent server identity is never accepted",async()=>{
 const x=mk({identity:()=>({route:"generated"})});
 assert.equal((await x.delivery.submit(req())).reason,"identity_unverified");assert.equal(x.calls.execute,0);
});
test("server denies unverified initial context before resolving model route",async()=>{
 const x=mk({approve:()=>false});
 assert.equal((await x.delivery.submit(req())).reason,"context_unverified");
 assert.equal(x.calls.resolve,0);assert.equal(x.calls.execute,0);
});
test("temporary receipt is not a raw conversation log",async()=>{
 const x=mk();const r=await x.delivery.submit(req());
 assert.deepEqual(Object.keys(r).sort(),["alreadyProcessed","ok","reply"].sort());
 assert.ok(!JSON.stringify(r).includes("userId"));
 assert.equal(x.delivery.receipts.entries.size,1);
});

test("bounded completed tombstones block new provider spend before execution",async()=>{
 const x=mk({maxCompletedIds:1});
 assert.equal((await x.delivery.submit(req())).ok,true);
 const extra=await x.delivery.submit(req({requestId:"request-000002"}));
 assert.equal(extra.reason,"idempotency_capacity_full");
 assert.equal(x.calls.execute,1);
 assert.equal((await x.delivery.submit(req())).alreadyProcessed,true);
});
test("active in-flight reservation also consumes bounded admission capacity",async()=>{
 let release;
 const wait=new Promise(resolve=>{release=resolve;});
 const x=mk({maxCompletedIds:1,execute:async()=>{await wait;return{ok:true,reply:"Done once"};}});
 const first=x.delivery.submit(req());
 await Promise.resolve();await Promise.resolve();await Promise.resolve();
 const second=await x.delivery.submit(req({requestId:"request-000002"}));
 assert.equal(second.reason,"idempotency_capacity_full");
 release();
 assert.equal((await first).ok,true);
 assert.equal(x.calls.execute,1);
});
test("invalid memory tombstone limits rejected before any model call",()=>{
 assert.throws(()=>mk({maxCompletedIds:0}),/invalid completed request capacity/);
 assert.throws(()=>mk({maxCompletedIds:100001}),/invalid completed request capacity/);
});
