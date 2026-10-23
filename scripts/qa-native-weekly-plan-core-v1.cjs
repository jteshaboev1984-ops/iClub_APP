#!/usr/bin/env node
"use strict";
const {buildPlan}=require("../exam-prep/runtime/native-weekly-plan-core-v1.js");
function runTests(buildPlan) {
  let count=0;
  const equal=(a,b,msg)=>{if(a!==b)throw Error(msg+" expected "+JSON.stringify(b)+" got "+JSON.stringify(a));};
  const ok=(v,msg)=>{if(!v)throw Error(msg);};
  const rejects=(fn,code)=>{let e="";try{fn()}catch(x){e=x.message}equal(e,code,"expected rejection");};
  const PASS=(title,fn)=>{fn();count++;};
  const base=()=>({
    program_key:"economics_9708",program_version:"economics_2026_2028_v1",route:"AS",
    target_papers:["P1","P2"],locale:"en",
    budget:{total_student_minutes:540,economics_minutes:180},max_items:10,
    paper_state:{P1:{stage:2,diagnostic_verified:false},P2:{stage:2,diagnostic_verified:false}},
    focus:[],corrections:[],retests:[],catalog:[]
  });
  const item=(kind,paper,skill=null,overrides={})=>({
    program_key:"economics_9708",program_version:"economics_2026_2028_v1",
    paper_code:paper,kind,skill_key:skill,task_key:[paper,kind,skill||"all"].join("_"),
    task_version:"v1",estimated_minutes:15,status:"approved",mapping_status:"approved",
    release_enabled:true,source_ready:true,security_ready:true,
    checking_contract:(kind==="written"||kind==="theory")?"no_automatic_score":"server_objective",
    locales:{en:true,ru:true,uz:true},link_role:"direct",priority:1,...overrides
  });
  PASS("unreleased never schedules",()=>{const x=base();x.catalog=[item("diagnostic","P1",null,{release_enabled:false})];const v=buildPlan(x);equal(v.state,"no_approved_study_steps","unreleased");equal(v.steps.length,0,"unreleased steps");});
  PASS("diagnostic only until verified",()=>{const x=base();x.focus=[{paper_code:"P1",skill_key:"AS1"}];x.catalog=[item("diagnostic","P1"),item("theory","P1","AS1")];const v=buildPlan(x);equal(v.steps.length,1,"diagnostic gate");equal(v.steps[0].kind,"diagnostic","diag priority");});
  PASS("stage 2 mix theory MCQ written",()=>{const x=base();x.paper_state.P1.diagnostic_verified=true;x.paper_state.P2.diagnostic_verified=true;x.focus=[{paper_code:"P1",skill_key:"AS1"},{paper_code:"P2",skill_key:"AS2"}];x.catalog=[item("theory","P1","AS1"),item("mcq","P1","AS1"),item("theory","P2","AS2"),item("written","P2","AS2")];const v=buildPlan(x);equal(v.steps.map(y=>y.kind).join(","),"theory,theory,mcq,written","mixed subjects");equal(v.steps[3].evidence_rule,"no_mastery_from_navigation","written noncredit");});
  PASS("balanced paper scheduling without arbitrary ratios",()=>{const x=base();x.paper_state.P1.diagnostic_verified=true;x.paper_state.P2.diagnostic_verified=true;x.budget.economics_minutes=30;x.focus=[{paper_code:"P1",skill_key:"S1"},{paper_code:"P2",skill_key:"S2"}];x.catalog=[item("theory","P1","S1"),item("mcq","P1","S1"),item("theory","P2","S2"),item("written","P2","S2")];const v=buildPlan(x);equal(v.steps.map(y=>y.paper_code).join(","),"P1,P2","paper balance");equal(v.planned_minutes,30,"budget exact");});
  PASS("no MCQ for written Paper",()=>{const x=base();x.paper_state.P2.diagnostic_verified=true;x.focus=[{paper_code:"P2",skill_key:"A"}];x.catalog=[item("mcq","P2","A")];ok(buildPlan(x).steps.every(y=>y.paper_code!=="P2"),"unscoped P2 MCQ");});
  PASS("candidate mapping blocked",()=>{const x=base();x.catalog=[item("diagnostic","P1",null,{mapping_status:"candidate"})];equal(buildPlan(x).steps.length,0,"candidate");});
  PASS("must have RU UZ EN",()=>{const x=base();x.catalog=[item("diagnostic","P1",null,{locales:{en:true,ru:false,uz:true}})];equal(buildPlan(x).steps.length,0,"language QA");});
  PASS("staged route keeps explicit AS resit eligibility",()=>{const x=base();x.route="staged";x.target_papers=["P1"];x.catalog=[item("diagnostic","P1")];equal(buildPlan(x).steps.length,1,"staged AS component");});
  PASS("written task cannot claim automatic marking contract",()=>{const x=base();x.paper_state.P2.diagnostic_verified=true;x.focus=[{paper_code:"P2",skill_key:"S"}];x.catalog=[item("written","P2","S",{checking_contract:"server_objective"})];equal(buildPlan(x).steps.length,0,"written score guard");});
  PASS("AS route excludes A papers",()=>{const x=base();x.target_papers=["P3"];rejects(()=>buildPlan(x),"invalid_paper_selection");});
  PASS("staged route allows A without transferring AS score",()=>{const x=base();x.route="staged";x.target_papers=["P3"];x.paper_state={P3:{stage:2,diagnostic_verified:true}};x.focus=[{paper_code:"P3",skill_key:"AS_BASE"}];x.catalog=[item("theory","P3","AS_BASE",{link_role:"prerequisite"}),item("mcq","P3","AS_BASE",{link_role:"prerequisite"})];const v=buildPlan(x);equal(v.steps.length,1,"prereq-only theory");equal(v.steps[0].evidence_rule,"no_mastery_from_navigation","not credited");});
  PASS("stage 0 is not stage 5",()=>{const x=base();x.paper_state.P1={stage:0,diagnostic_verified:true};x.focus=[{paper_code:"P1",skill_key:"AS1"}];x.catalog=[item("mcq","P1","AS1")];equal(buildPlan(x).steps.length,0,"stage 0");});
  PASS("retest correction prioritized",()=>{const x=base();x.paper_state.P1.diagnostic_verified=true;x.retests=[{paper_code:"P1",skill_key:"S1"}];x.corrections=[{paper_code:"P1",skill_key:"S2"}];x.catalog=[item("retest","P1","S1"),item("correction","P1","S2")];equal(buildPlan(x).steps.map(y=>y.kind).join(","),"retest,correction","priority");});
  PASS("paper mode cannot count unmarked written",()=>{const x=base();x.paper_state.P2={stage:5,diagnostic_verified:true};x.catalog=[item("paper","P2",null,{checking_contract:"server_objective"})];ok(buildPlan(x).steps.every(y=>y.paper_code!=="P2"),"written paper must be unscored");});
  PASS("time not silently overallocated",()=>{const x=base();x.budget.economics_minutes=10;x.catalog=[item("diagnostic","P1",null,{estimated_minutes:15})];const v=buildPlan(x);equal(v.planned_minutes,0,"no excess");ok(v.blockers.some(y=>y.reason==="weekly_capacity_reached"),"capacity blocker");});
  PASS("prohibit impossible time budgets",()=>{const x=base();x.budget.economics_minutes=600;rejects(()=>buildPlan(x),"invalid_time_budget");});
  PASS("no fake readiness / grade",()=>{const x=base();x.catalog=[item("diagnostic","P1")];const v=buildPlan(x);ok(v.readiness===undefined&&v.grade===undefined&&v.mastery===undefined&&!v.release_authorized,"no fake result");});
  PASS("deterministic and no mutation",()=>{const x=base();x.catalog=[item("diagnostic","P2"),item("diagnostic","P1")];const prior=JSON.stringify(x);const a=buildPlan(x),b=buildPlan(x);equal(JSON.stringify(a),JSON.stringify(b),"determinism");equal(JSON.stringify(x),prior,"input immutable");});
  PASS("not completion on empty plan",()=>{const x=base();const v=buildPlan(x);equal(v.state,"no_approved_study_steps","empty state");ok(!JSON.stringify(v).includes("complete"),"no fabricated completion");});
  PASS("stage 3/4/5 add exam practice by paper",()=>{const x=base();x.paper_state.P1={stage:5,diagnostic_verified:true};x.catalog=["mixed","timed","paper"].map(k=>item(k,"P1"));const v=buildPlan(x);equal(v.steps.map(y=>y.kind).join(","),"mixed,timed,paper","staged");});
  return count;
}
const count=runTests(buildPlan);
console.log("RESULT "+count+" PASS (fixture-only, no production E2E)");
