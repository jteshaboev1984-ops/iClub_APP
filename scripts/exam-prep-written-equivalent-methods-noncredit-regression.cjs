#!/usr/bin/env node
"use strict";
// Same source question, multiple mathematically valid expression forms.
// This is an AUTHORITY test: written prose is NEVER silently upgraded
// to app-verified marks, even where an answer is equivalent to another form.
const assert=require("node:assert/strict"),fs=require("node:fs"),path=require("node:path");
const {create}=require("../exam-prep/runtime/written-core-controller-v1.js");
const src=fs.readFileSync(path.resolve(__dirname,"..","exam-prep/runtime/written-core-controller-v1.js"),"utf8");
const policy=JSON.parse(fs.readFileSync(path.resolve(__dirname,"..","exam-prep/contracts/written-learning-contract-v1.json"),"utf8"));
const sql=fs.readFileSync(path.resolve(__dirname,"fixtures/exam-prep-written-companion-180-acceptance-readonly.sql"),"utf8");
const equalMathematicalSolutions=[
 ["1/2","0.5","2/4","50%"],
 ["x²−4","(x−2)(x+2)","(x+2)(x−2)"],
 ["y=2x+3","2x−y+3=0","y−3=2x"],
 ["√2","2/√2","sqrt(8)/2"],
 ["sin(π/6)","1/2","sin(5π/6)"]
];
for(const group of equalMathematicalSolutions) {
 assert(group.length>=3);
 assert.equal(new Set(group).size,group.length);
}
assert.equal(policy.written_core.next_event_semantics,"advanced_in_plan_only");
assert.equal(policy.progress_disclosure.advanced_is_score,false);
assert.equal(policy.progress_disclosure.advanced_is_mastery,false);
assert.equal(policy.progress_disclosure.human_review_separate,true);
assert(!src.includes("eval("),"No code evaluator may run arbitrary learner written text");
assert.match(sql,/private\.exam_prep_evaluate_written_understanding_v1/);
assert.match(sql,/all_correct/);assert.match(sql,/all_wrong/);assert.match(sql,/omitted_result/);
assert.doesNotMatch(sql,/\b(?:UPDATE|DELETE\s+FROM|INSERT\s+INTO|TRUNCATE|ALTER|DROP)\s+(?:private|public)\./i);
(async()=>{
 let verified=0;
 for(const group of equalMathematicalSolutions) for(const submittedText of group) {
  let writes=0,last=null;
  const task={task_kind:"written_external",task_token:"synthetic-token",task_key:"Q",
    task_version:"v1",plan_item_id:"synthetic-plan-item",program_key:"math_as_p1_p5",
    program_version:"v1",runtime_enabled:true,can_advance:true,status:"active"};
  const c=create({api:{
   open:async()=>({...task}),
   criteria:async()=>({available:true,task_key:task.task_key,task_version:task.task_version,
      requirements:["Explain the reasoning and show the correct method."]}),
   advance:async args=>{
      writes++;last=args;
      return {status:"advanced",task_key:task.task_key,task_version:task.task_version,
        plan_item_id:task.plan_item_id};
   },
   status:async()=>({status:"active",task_key:task.task_key,task_version:task.task_version,
      program_version:task.program_version,plan_item_id:task.plan_item_id})
  },createActionKey:()=> "test-nonce-123456"});
  // Writing variant exists only in test's independent work, not in Core's
  // permitted submission payload; invalid writing would also be non-crediting.
  assert(submittedText.length>0);
  await c.open(task.plan_item_id);
  const result=await c.next();
  assert.equal(result.status,"advanced");
  assert.equal(writes,1);
  assert.deepEqual(Object.keys(last).sort(),["idempotency_key","plan_item_id","task_key","task_token","task_version"].sort());
  assert.equal(c.snapshot().score,undefined);
  assert.equal(c.snapshot().mastery,undefined);
  assert.equal(c.snapshot().status,"advanced");
  verified++;
 }
 console.log("PASS:",verified,"equivalent-form acceptance contract cases; all remain ungraded written steps; no text upload, fake score or mastery change.");
})().catch(e=>{console.error(e);process.exitCode=1});
