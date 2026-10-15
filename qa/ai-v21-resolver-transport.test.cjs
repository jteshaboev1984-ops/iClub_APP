"use strict";
const {test}=require("node:test");
const assert=require("node:assert/strict");
const {QaV21ScreenClient}=require("./ai-layer-v21-ui-transport.cjs");
const H="33333333-3333-4333-8333-333333333333";
const R="44444444-4444-4444-8444-444444444444";
function deferred(){let resolve;const promise=new Promise(r=>resolve=r);return{promise,resolve};}
function clientFor({post,readJwt=async()=>"synthetic-token-verified"}={}){
 const calls=[];
 const fn=async req=>{
  calls.push(req);
  if(post)return await post(req);
  return req.body.action==="resolvePracticeV4"?
   {ok:true,kind:"server_resolved_practice_v4",attemptReference:99,
    questionId:901,sessionId:900}:
   {ok:true,contextHandle:H,expiresInSeconds:90};
 };
 const client=new QaV21ScreenClient({post:fn,readJwt,
  newRequestId:()=>R});
 return{client,calls};
}
test("QA transport sends two numeric selectors only; never sends user/profile/source",async()=>{
 const {client,calls}=clientFor();
 const r=await client.resolvePracticeV4({attemptReference:99,questionId:901});
 assert.deepEqual(r,{ok:true,kind:"server_resolved_practice_v4",
  attemptReference:99,questionId:901,sessionId:900});
 assert.equal(calls.length,1);
 assert.deepEqual(calls[0].body,{action:"resolvePracticeV4",
  attemptReference:99,questionId:901});
 assert.equal(calls[0].authorization,"Bearer synthetic-token-verified");
 assert.equal(calls[0].path,"/context");
});
test("Invalid browser numbers cannot call server at all",async()=>{
 const f=clientFor();
 for(const input of [
  {attemptReference:0,questionId:1},{attemptReference:"99",questionId:901},
  {attemptReference:99,questionId:0},{attemptReference:99,questionId:1.1},
  {attemptReference:Number.MAX_SAFE_INTEGER+1,questionId:1},
  undefined
 ]){
  assert.equal((await f.client.resolvePracticeV4(input)).ok,false);
 }
 assert.equal(f.calls.length,0);
});
test("Missing token or rejected token promise never leaves browser",async()=>{
 for(const readJwt of [
  async()=>null,
  async()=>{throw Error("auth unavailable");}
 ]){
  const f=clientFor({readJwt});
  const r=await f.client.resolvePracticeV4({attemptReference:99,questionId:901});
  assert.equal(r.ok,false);assert.equal(f.calls.length,0);
 }
});
test("Forged raw response score, key, userId is discarded by client transport",async()=>{
 const f=clientFor({post:async()=>({
  ok:true,kind:"server_resolved_practice_v4",
  attemptReference:99,questionId:901,sessionId:900,
  userId:"OTHER_ACCOUNT",correctAnswer:"TOP_SECRET",score:100
 })});
 const result=await f.client.resolvePracticeV4({attemptReference:99,questionId:901});
 assert.equal(result.ok,true);
 assert.equal(Object.keys(result).length,5);
 assert.ok(!JSON.stringify(result).includes("TOP_SECRET"));
});
test("Mismatched response or absent server proof does not mint",async()=>{
 for(const bad of [
  {ok:false},
  {ok:true,kind:"server_resolved_practice_v4",attemptReference:100,questionId:901,sessionId:900},
  {ok:true,kind:"server_resolved_practice_v4",attemptReference:99,questionId:902,sessionId:900},
  {ok:true,kind:"server_resolved_practice_v4",attemptReference:99,questionId:901,sessionId:0},
  {ok:true,kind:"server_resolved_practice_v4",attemptReference:99,questionId:901,sessionId:"900"}
 ]){
  const f=clientFor({post:async()=>bad});
  assert.equal((await f.client.resolvePracticeV4({attemptReference:99,questionId:901})).ok,false);
 }
});
test("Concurrent logout/navigate cancels a pending JWT before HTTP",async()=>{
 const gate=deferred();
 const f=clientFor({readJwt:async()=>gate.promise});
 const task=f.client.resolvePracticeV4({attemptReference:99,questionId:901});
 await Promise.resolve();
 await f.client.leave();
 gate.resolve("synthetic-token-verified");
 const answer=await task;
 assert.equal(answer.ok,false);
 assert.equal(f.calls.length,0);
});
test("Switch during in-flight resolver refuses the late response",async()=>{
 const gate=deferred();
 const f=clientFor({post:async()=>gate.promise});
 const task=f.client.resolvePracticeV4({attemptReference:99,questionId:901});
 await new Promise(r=>setImmediate(r));
 await f.client.leave();
 gate.resolve({ok:true,kind:"server_resolved_practice_v4",
  attemptReference:99,questionId:901,sessionId:900});
 const result=await task;
 assert.equal(result.ok,false);
 assert.equal(f.calls.length,1);
});
test("Server lookup never grants a reusable context or answer by itself",async()=>{
 const f=clientFor();
 assert.equal((await f.client.resolvePracticeV4({attemptReference:99,questionId:901})).ok,true);
 assert.equal(f.client.isCurrent(),false);
 assert.equal((await f.client.status("ru")).ok,false);
 assert.equal((await f.client.askPrepared("practice_error","ru")).ok,false);
 assert.equal(f.calls.length,1,"No extra requests without separately minted context");
});
