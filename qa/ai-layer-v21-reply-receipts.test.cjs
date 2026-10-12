// node --test qa/ai-layer-v21-reply-receipts.test.cjs
"use strict";
const {test}=require("node:test");
const assert=require("node:assert/strict");
const {EphemeralReplyReceipts}=require("./ai-layer-v21-reply-receipts.cjs");
const input=(changes={})=>({
 requestId:"request-000001",userId:"learner-000001",sessionId:"session-000001",
 fingerprint:"fingerprint-for-question",route:"generated",reply:"The same reviewed answer.",
 nowMs:1000,...changes
});
const read=(store,changes={})=>store.retrieve({...input(),revalidate:async()=>true,...changes});
test("safe retry reuses exactly the original answer without extra model calls",async()=>{
 const store=new EphemeralReplyReceipts();assert.equal(store.store(input()).ok,true);
 const a=await read(store);const b=await read(store);
 assert.equal(a.ok,true);assert.equal(a.reply,input().reply);
 assert.deepEqual(a,b);assert.equal(store.entries.size,1);
});
test("replay always requires a server recheck, no permissive default",async()=>{
 const store=new EphemeralReplyReceipts();store.store(input());
 assert.equal((await read(store,{revalidate:undefined})).reason,"context_unverified");
 assert.equal((await read(store,{revalidate:async()=>false})).reason,"context_unverified");
 assert.equal((await read(store,{revalidate:async()=>{throw Error("backend lost");}})).reason,"context_unverified");
});
test("newly protected exam prevents previously finalized answer replay",async()=>{
 const store=new EphemeralReplyReceipts();store.store(input());
 assert.equal((await read(store,{revalidate:async()=>false})).ok,false);
 assert.equal((await read(store,{revalidate:async()=>true})).ok,true);
});
test("other user cannot retrieve the reply even with known ID",async()=>{
 const store=new EphemeralReplyReceipts();store.store(input());
 assert.equal((await read(store,{userId:"learner-999999"})).reason,"receipt_unavailable");
});
test("cross-session replay and wrong topic fingerprint cannot retrieve",async()=>{
 const store=new EphemeralReplyReceipts();store.store(input());
 assert.equal((await read(store,{sessionId:"session-999999"})).reason,"receipt_unavailable");
 assert.equal((await read(store,{fingerprint:"fingerprint-wrong-topic"})).reason,"receipt_unavailable");
 assert.equal((await read(store,{route:"prepared"})).reason,"receipt_unavailable");
});
test("id collision with a different answer/route/learner fails closed",()=>{
 const store=new EphemeralReplyReceipts();store.store(input());
 assert.equal(store.store(input({reply:"Another model answer"})).reason,"receipt_collision");
 assert.equal(store.store(input({userId:"learner-222222"})).reason,"receipt_collision");
 assert.equal(store.store(input({route:"prepared"})).reason,"receipt_collision");
});
test("identical receipt store is idempotent",()=>{
 const store=new EphemeralReplyReceipts();store.store(input());
 assert.equal(store.store(input()).duplicate,true);assert.equal(store.entries.size,1);
});
test("expired answer is erased after 2 minutes and cannot be replayed",async()=>{
 const store=new EphemeralReplyReceipts();store.store(input());
 assert.equal((await read(store,{nowMs:120999})).ok,true);
 assert.equal((await read(store,{nowMs:121000})).reason,"receipt_unavailable");
 assert.equal(store.entries.size,0);
});
test("clearing session deletes only that session's replies",async()=>{
 const store=new EphemeralReplyReceipts();
 store.store(input());store.store(input({requestId:"request-000002",sessionId:"session-000002"}));
 store.clearSession("learner-000001","session-000001");
 assert.equal((await read(store)).ok,false);
 assert.equal((await read(store,{requestId:"request-000002",sessionId:"session-000002"})).ok,true);
});
test("bounded capacity refuses new entries rather than evict undelivered answers",()=>{
 const store=new EphemeralReplyReceipts({maxEntries:1});store.store(input());
 assert.equal(store.store(input({requestId:"request-000002"})).reason,"receipt_capacity_full");
 assert.equal(store.entries.size,1);
});
test("invalid/blank reply cannot become a receipt",()=>{
 const store=new EphemeralReplyReceipts();
 assert.equal(store.store(input({reply:" "})).reason,"invalid_receipt");
 assert.equal(store.store(input({reply:"a".repeat(8001)})).reason,"invalid_receipt");
 assert.equal(store.entries.size,0);
});
test("TTL and cache size have strict caps",()=>{
 assert.throws(()=>new EphemeralReplyReceipts({ttlMs:3600000}),/invalid ttl/);
 assert.throws(()=>new EphemeralReplyReceipts({maxEntries:999999}),/invalid capacity/);
});
test("reply receipt exposes no internal units or source metadata to requester",async()=>{
 const store=new EphemeralReplyReceipts();store.store(input());const result=await read(store);
 assert.deepEqual(Object.keys(result).sort(),["alreadyProcessed","ok","reply"]);
});
