"use strict";
const {test}=require("node:test"),assert=require("node:assert/strict"),
 fs=require("node:fs");
const {assemble,check}=require("./ai-layer-v21-preview-assembly.cjs");
const {PreviewGlue}=require("./ai-layer-v21-preview-glue.cjs");
const {QaV21EvidencePublisher}=require("./ai-layer-v21-evidence-publisher.cjs");
const sources=()=>({app:fs.readFileSync("app.js","utf8"),
 index:fs.readFileSync("index.html","utf8")});
class E{
 constructor(attrs={},active=true){this.attrs={...attrs};this.active=active;this.nodes=[];
  this.classList={contains:x=>x==="is-active"&&this.active};}
 getAttribute(k){return this.attrs[k]??null}
 setAttribute(k,v){this.attrs[k]=v}
 removeAttribute(k){delete this.attrs[k]}
 querySelectorAll(q){return this.nodes.filter(x=>x.getAttribute(
  q==="[data-practice-ai-question-id]"?"data-practice-ai-question-id":
  "data-iclub-ai-v21-question-id")!==null)}
}
const quiz=()=>({mode:"practice",safeSessionId:101,
 _safeFinalizeComplete:true,drillType:null,questions:[{id:202},{id:203}]});
const rows=()=>[{question_id:202},{question_id:203}];
const page=()=>{const x=new E();x.nodes=[
 new E({"data-practice-ai-question-id":"202"}),
 new E({"data-practice-ai-question-id":"203"})];return x};
test("ONE coherent candidate from real original app, 3 exact lifecycle hooks",()=>{
 const out=assemble(sources());
 assert.deepEqual(out.hooks,["navigation","finalize","review"]);
 assert.match(out.app,/__iclubQaV21Bridge\?\.finalized/);
 assert.match(out.app,/__iclubQaV21Bridge\?\.reviewRendered/);
 assert.match(out.index,/qa\/ai-layer-v21-preview-glue\.cjs/);
 assert.equal(out.status,"OFFLINE_ONLY_NOT_DEPLOYABLE");
});
test("All original app files remain SHA-identical after disposable assembly",()=>{
 assert.equal(check().originalsPreserved,true);
});
test("Any changed app anchor or duplicate assembly FAILS CLOSED",()=>{
 const o=sources(),r=assemble(o);
 assert.throws(()=>assemble({app:r.app,index:o.index}),/QA_SOURCE_DRIFT/);
 assert.throws(()=>assemble({app:o.app,index:r.index}),/QA_SOURCE_DRIFT/);
 assert.throws(()=>assemble({app:o.app.replace(
  "quiz._safeFinalizeComplete = true;","quiz._safeFinalizeComplete = false;"),
  index:o.index}),/QA_SOURCE_DRIFT finalize/);
});
test("Real V4 finalized session and exact reviewed question bind; legacy attempt never sent",()=>{
 const g=new PreviewGlue(new QaV21EvidencePublisher());
 const s=page();const p={attempt_id:567};
 assert.equal(g.finalized({quiz:quiz(),finalResult:p,reviewRows:rows()}).ok,true);
 assert.equal(g.reviewRendered({attemptId:567,reviewRows:rows(),screen:s}).ok,true);
 assert.equal(s.getAttribute("data-iclub-ai-v21-session-id"),"101");
 assert.equal(g.selectQuestion(202).ok,true);
 assert.equal(s.nodes[0].getAttribute("data-iclub-ai-v21-selected"),"true");
 assert.equal(s.getAttribute("data-iclub-ai-v21-session-id")==="567",false);
});
test("Incomplete finalization, incomplete review, wrong attempt all denied",()=>{
 const g=new PreviewGlue(new QaV21EvidencePublisher()),s=page();
 assert.equal(g.finalized({quiz:{...quiz(),_safeFinalizeComplete:false},
  finalResult:{attempt_id:567},reviewRows:rows()}).ok,false);
 assert.equal(g.finalized({quiz:quiz(),finalResult:{attempt_id:567},
  reviewRows:[{question_id:202}]}).ok,false);
 assert.equal(g.finalized({quiz:quiz(),finalResult:{attempt_id:567},
  reviewRows:rows()}).ok,true);
 assert.equal(g.reviewRendered({attemptId:101,reviewRows:rows(),screen:s}).ok,false);
 assert.equal(s.getAttribute("data-iclub-ai-v21-session-id"),null);
});
test("Navigate away from Practice clears ephemeral proof, not persisted progress",()=>{
 const g=new PreviewGlue(new QaV21EvidencePublisher()),s=page();
 g.finalized({quiz:quiz(),finalResult:{attempt_id:567},reviewRows:rows()});
 g.reviewRendered({attemptId:567,reviewRows:rows(),screen:s});
 g.screenChanged("video");
 assert.equal(s.getAttribute("data-iclub-ai-v21-session-id"),null);
 assert.equal(g.selectQuestion(202).ok,false);
});
test("Lesson video is subject Telegram and CANNOT be passed as exact Lesson context",()=>{
 const original=sources(),result=assemble(original);
 assert.match(original.app,/state\.courses\.lessonId = primaryLessonId \|\| null/);
 assert.doesNotMatch(result.app,/data-iclub-ai-v21-lesson-id/);
 assert.doesNotMatch(result.index,/qa\/ai-layer-v21-ui-transport/);
});
