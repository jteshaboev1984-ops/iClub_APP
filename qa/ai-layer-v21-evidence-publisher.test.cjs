"use strict";
const {test}=require("node:test"),assert=require("node:assert/strict");
const fs=require("node:fs");
const {QaV21EvidencePublisher}=require("./ai-layer-v21-evidence-publisher.cjs");
class E{
 constructor(attrs={},active=true){this.attrs={...attrs};this.nodes=[];this.active=active;
  this.classList={contains:name=>name==="is-active"&&this.active};}
 getAttribute(k){return this.attrs[k]??null}
 setAttribute(k,v){this.attrs[k]=v}
 removeAttribute(k){delete this.attrs[k]}
 querySelectorAll(selector){
  if(selector==="[data-practice-ai-question-id]")
   return this.nodes.filter(x=>x.getAttribute("data-practice-ai-question-id")!==null);
  if(selector.includes("data-iclub-ai-v21-question-id"))
   return this.nodes.filter(x=>x.getAttribute("data-iclub-ai-v21-question-id")!==null);
  return[];
 }
}
const quiz=()=>({mode:"practice",safeSessionId:101,drillType:null,
 _safeFinalizeComplete:true,questions:[{id:202},{id:203}]});
const answer=()=>({attempt_id:567,score:1});
const review=()=>[{question_id:202},{question_id:203}];
const screen=()=>{let a=new E();a.nodes=[new E({"data-practice-ai-question-id":"202"}),
 new E({"data-practice-ai-question-id":"203"})];return a};
test("Real production source confirms V4 session and legacy attempt ID are distinct paths",()=>{
 const app=fs.readFileSync("app.js","utf8");
 assert.match(app,/sessionId: Number\(quiz\.safeSessionId\)/);
 assert.match(app,/quiz\._safeFinalizeComplete = true/);
 assert.match(app,/attemptId: Number\(finalResult\?\.attempt_id/);
 assert.match(app,/const safeRows = await safeApi\.review\(dbAttemptId\)/);
 assert.match(app,/row\.dataset\.practiceAiQuestionId = String\(Number\(d\.id\)\)/);
 assert.match(app,/state\.courses\.lessonId = primaryLessonId \|\| null/);
});
test("Happy path hands exact V4 session and server-reviewed question to V2 DOM",()=>{
 const p=new QaV21EvidencePublisher(),t=p.acceptFinalization({quiz:quiz(),finalResult:answer()});
 assert.equal(t.ok,true);
 const x=screen();
 assert.equal(p.mountReview({token:t.token,screen:x,reviewRows:review()}).ok,true);
 assert.equal(x.getAttribute("data-iclub-ai-v21-session-id"),"101");
 assert.equal(p.selectQuestion({token:t.token,questionId:203}).ok,true);
 assert.equal(x.nodes[1].getAttribute("data-iclub-ai-v21-selected"),"true");
 assert.equal(x.nodes[0].getAttribute("data-iclub-ai-v21-selected"),null);
 assert.equal(JSON.stringify(x.attrs).includes("567"),false);
});
test("Unfinished/legacy/drill/invalid V4 source never publishes selector",()=>{
 for(const value of [
  {...quiz(),_safeFinalizeComplete:false},{...quiz(),safeSessionId:null},
  {...quiz(),drillType:"past_tours"},{...quiz(),mode:"tour"},
  {...quiz(),safeSessionId:"001"},{...quiz(),questions:[{id:202},{id:202}]}
 ]){
  const p=new QaV21EvidencePublisher();
  assert.equal(p.acceptFinalization({quiz:value,finalResult:answer()}).ok,false);
 }
 const p=new QaV21EvidencePublisher();
 assert.equal(p.acceptFinalization({quiz:quiz(),finalResult:{attempt_id:0}}).ok,false);
});
test("Server review missing, duplicate, extra, incomplete or contradictory DOM denies",()=>{
 for(const rows of [[],[{question_id:202}],[{question_id:202},{question_id:202}],
  [{question_id:202},{question_id:999}],null]){
  const p=new QaV21EvidencePublisher(),t=p.acceptFinalization({quiz:quiz(),finalResult:answer()});
  const x=screen();assert.equal(p.mountReview({token:t.token,screen:x,reviewRows:rows}).ok,false);
  assert.equal(x.getAttribute("data-iclub-ai-v21-session-id"),null);
 }
 const p=new QaV21EvidencePublisher(),t=p.acceptFinalization({quiz:quiz(),finalResult:answer()});
 const x=screen();x.nodes[1].attrs["data-practice-ai-question-id"]="999";
 assert.equal(p.mountReview({token:t.token,screen:x,reviewRows:review()}).ok,false);
 assert.equal(x.getAttribute("data-iclub-ai-v21-session-id"),null);
});
test("Old async server review cannot publish after navigation/new finalization",()=>{
 const p=new QaV21EvidencePublisher(),first=p.acceptFinalization({quiz:quiz(),finalResult:answer()});
 p.clear();
 const x=screen();
 assert.equal(p.mountReview({token:first.token,screen:x,reviewRows:review()}).reason,"context_changed");
 const second=p.acceptFinalization({quiz:quiz(),finalResult:answer()});
 assert.notEqual(first.token,second.token);
 assert.equal(p.mountReview({token:second.token,screen:x,reviewRows:review()}).ok,true);
 p.clear();
 assert.equal(x.getAttribute("data-iclub-ai-v21-session-id"),null);
 assert.equal(x.nodes.some(n=>n.getAttribute("data-iclub-ai-v21-question-id")),false);
});
test("Question not server confirmed, inactive review, or stale token denies selection",()=>{
 const p=new QaV21EvidencePublisher(),t=p.acceptFinalization({quiz:quiz(),finalResult:answer()});
 const x=screen();x.active=false;
 assert.equal(p.mountReview({token:t.token,screen:x,reviewRows:review()}).ok,false);
 x.active=true;assert.equal(p.mountReview({token:t.token,screen:x,reviewRows:review()}).ok,true);
 assert.equal(p.selectQuestion({token:t.token,questionId:999}).ok,false);
 assert.equal(p.selectQuestion({token:-1,questionId:202}).ok,false);
});
