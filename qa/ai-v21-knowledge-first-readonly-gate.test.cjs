"use strict";
const {test}=require("node:test"),a=require("node:assert/strict");
const {createKnowledgeFirstReadOnlyGate}=require("./ai-v21-knowledge-first-readonly-gate.cjs");
const OWNER="11111111-1111-4111-8111-111111111111";
const OTHER="22222222-2222-4222-8222-222222222222";
const HANDLE="33333333-3333-4333-8333-333333333333";
const VERSION="v1",SHA="a".repeat(64),MD5="b".repeat(32);
const BASE={authorization:"Bearer syntheticQaVerifiedAuthentication",contextHandle:HANDLE,
 locale:"ru",intent:"app_help",promptKey:"support_help",userId:OTHER};
function rig(){
 const x={now:100000,readCount:0,protectedReads:0,deniedRights:false,sourceRevoked:false,
  protected:false,protectedLate:false,deliberatelyStale:false,
  screen:{proof:"server_owner_current_screen_v1",ownerId:OWNER,
   contextHandle:HANDLE,revision:5,expiresAtMs:120000,locale:"ru",
   screenCode:"support",scopeCode:"global",subjectKey:"general",
   assessmentActive:false},
  card:{locale:"ru",help_key:"support_help",subject_key:"general",
   message:"Open Profile then Support and select the topic.",
   content_hash:SHA,source_version:VERSION}};
 const services={
  nowMs:()=>x.now,
  authenticate:async()=>({authenticated:true,proof:"verified_supabase_auth_v1",userId:OWNER}),
  readCurrentScope:async()=>{
   x.readCount++;return {...x.screen,
    revision:x.deliberatelyStale&&x.readCount>1?6:x.screen.revision};
  },
  readProtected:async()=>{
   x.protectedReads++;
   const active=x.protected||(x.protectedLate&&x.protectedReads>1);
   return{proof:"owner_bound_assessment_guard_v1",ownerId:OWNER,
    contextRevision:x.screen.revision,protected:active};
  },
  verifySubjectRights:async()=>
   ({allowed:!x.deniedRights,proof:"server_entitlement_v1",
     ownerId:OWNER,contextRevision:x.screen.revision,
     subjectKey:x.screen.subjectKey,feature:x.requestIntent||"app_help"}),
  readApprovedSource:async(_route,card)=>({
   approved:!x.sourceRevoked,rightsApproved:true,runtimeAllowed:true,
   contentApproved:true,conflict:false,qaPassed:true,
   locale:"ru",subjectKey:x.screen.subjectKey,
   sourceKey:card.source_card_key||card.help_key,
   cardHash:card.content_hash,contentVersion:card.content_version||card.source_version,
   publicationRevision:1
  }),
  readPreparedHelp:async()=>({...x.card}),
  readMathTutorCard:async()=>({...x.card}),
  readPracticeSourceCard:async()=>({...x.card}),
  chooseApprovedHome:async()=>({ready:true,releaseAllowed:false,status:"candidate_only"})
 };
 const run=async(input={})=>{
  const req={...BASE,...input};x.requestIntent=req.intent;
  return new Promise(resolve=>resolve(
   createKnowledgeFirstReadOnlyGate(services).resolve(req)));
 };
 return{x,services,run};
}
test("accepted public guidance requires signed owner screen, rights and published source",async()=>{
 const z=rig(),r=await z.run();
 a.equal(r.ok,true);a.equal(r.reason,"qa_source_verified");
 a.equal(r.releaseAllowed,false);a.equal(r.learnerVisibleText,null);
 a.equal(r.providerCalled,false);a.equal(r.billed,false);
 a.equal(r.academicStateChanged,false);
 a.equal(z.x.readCount,2);
});
test("client-supplied owner identity never influences trusted Auth",async()=>{
 const z=rig();a.equal((await z.run({userId:OTHER})).ok,true);
 z.services.authenticate=async()=>({authenticated:true,proof:"verified_supabase_auth_v1",userId:OTHER});
 a.equal((await z.run()).ok,false);
 for(const token of ["",null,"Bearer forged"])a.equal((await z.run({authorization:token})).ok,false);
});
test("active assessment fully denies, including exact FAQ and prepared cards",async()=>{
 const codes=["practice-quiz","tour-quiz","exam-prep","exam_prep_assessment",
  "exam_prep_diagnostic","exam_prep_retest","exam_prep_mixed",
  "exam_prep_timed","exam_prep_paper"];
 for(const code of codes){
  const z=rig();z.x.screen.screenCode=code;
  const r=await z.run();a.equal(r.ok,false);a.equal(r.reason,"active_assessment",code);
 }
 const x=rig();x.x.protected=true;
 a.equal((await x.run()).reason,"active_assessment");
});
test("Math approved P1/P5 cards are isolated by exact skill and existing Tutor retained",async()=>{
 for(const [component,skill] of [["P1","P1-ALG-01"],["P5","P5-STAT-01"]]){
  const z=rig();z.x.screen={
   ...z.x.screen,screenCode:"exam_prep_skill",scopeCode:"exam_prep",
   subjectKey:"mathematics",componentCode:component,skillCode:skill};
  z.x.card={locale:"ru",component_code:component,skill_code:skill,
   tutor_card_key:"p1:P1-ALG-01:tutor:ru:v3",source_card_key:"p1:P1-ALG-01:theory:ru:v2",
   content_version:"v1",content_hash:MD5,
   main_explanation:"Detailed source-backed explanation for the verified skill.",
   simple_explanation:"Simpler source-backed explanation for this exact skill.",
   alternative_explanation:"Another explanation using the approved curriculum.",
   focus_explanation:"A focused explanation of the approved core principle."};
  const r=await z.run({intent:"math_card",promptKey:"simple"});
  a.equal(r.ok,true,JSON.stringify(r));a.equal(r.existingExamPrepTutorPreserved,true);
  a.equal(r.learnerVisibleText,null);a.equal(r.releaseAllowed,false);
  z.x.card.skill_code=component==="P1"?"P5-STAT-01":"P1-ALG-01";
  a.equal((await z.run({intent:"math_card",promptKey:"main"})).ok,false);
 }
});
test("Exact finalized and owned Practice mistake only; generic question fallback denied",async()=>{
 const z=rig();z.x.screen={...z.x.screen,screenCode:"practice-review",
  scopeCode:"global",subjectKey:"biology",finalized:true,
  ownsAnsweredQuestion:true,confirmedIncorrectAnswer:true,questionId:42};
 z.x.card={locale:"ru",subject_key:"biology",question_id:42,
  card_type:"answer_explanation",source_card_key:"practice:chemistry:p1:q42:ru:v1",
  content_hash:SHA,source_version:VERSION,
  body_text:"An approved explanation of the confirmed answered question."};
 const approved=await z.run({intent:"practice_card",promptKey:"explain_error"});
 a.equal(approved.ok,true);
 a.equal(approved.confirmedIncorrectAnswer,true);
 a.equal(approved.sourceVersion,VERSION);
 a.equal(approved.sourceHash,SHA);
 a.equal(approved.publicationRevision,1);
 z.x.screen.confirmedIncorrectAnswer=false;
 a.equal((await z.run({intent:"practice_card",promptKey:"explain_error"})).ok,false);
 z.x.screen.confirmedIncorrectAnswer=true;
 z.x.card.question_id=null;
 a.equal((await z.run({intent:"practice_card",promptKey:"explain_error"})).ok,false);
 z.x.card.question_id=42;z.x.screen.finalized=false;
 a.equal((await z.run({intent:"practice_card",promptKey:"explain_error"})).ok,false);
});
test("Home uses only approved deterministic priority, never publishes unapproved personalization",async()=>{
 const z=rig();z.x.screen.screenCode="home";
 a.equal((await z.run({intent:"home_next",promptKey:"home_next"})).reason,
  "qa_home_candidate_only");
 z.services.chooseApprovedHome=async()=>({ready:true,releaseAllowed:true,status:"candidate_only"});
 a.equal((await z.run({intent:"home_next",promptKey:"home_next"})).ok,false);
 z.services.chooseApprovedHome=async()=>({ready:true,releaseAllowed:false,status:"selection_required"});
 a.equal((await z.run({intent:"home_next",promptKey:"home_next"})).candidateStatus,
  "selection_required");
});
test("Cross-locale, subject forged fields, absent exact source, wrong hash or release deny",async()=>{
 const z=rig();
 a.equal((await z.run({locale:"en"})).ok,false);
 a.equal((await z.run({promptKey:"reveal_future_tour"})).ok,false);
 a.equal((await z.run({contextHandle:OTHER})).ok,false);
 z.x.card.content_hash="not-a-real-hash";
 a.equal((await z.run()).ok,false);
 z.x.card.content_hash=SHA;z.x.sourceRevoked=true;
 a.equal((await z.run()).ok,false);
 const o=rig();o.x.deniedRights=true;
 a.equal((await o.run()).ok,false);
});
test("Revocation or navigation while loading cancels source delivery and costs zero",async()=>{
 const z=rig();z.x.deliberatelyStale=true;
 a.equal((await z.run()).ok,false);
 const w=rig();w.x.protectedLate=true;
 a.equal((await w.run()).ok,false);
 const p=rig();let hits=0;
 p.services.readApprovedSource=async(_route,card)=>{
  hits++;return{approved:hits===1,rightsApproved:true,runtimeAllowed:true,
   contentApproved:true,conflict:false,qaPassed:true,locale:"ru",
   subjectKey:"general",sourceKey:"support_help",cardHash:SHA,contentVersion:VERSION};
 };
 a.equal((await p.run()).ok,false);
});
test("Missing trusted backend, thrown reader or expired owner scope always fail closed",async()=>{
 const z=rig();delete z.services.authenticate;
 a.throws(()=>createKnowledgeFirstReadOnlyGate(z.services),/missing_trusted_server_service/);
 const a1=rig();a1.services.readApprovedSource=async()=>{throw Error("database_down")};
 a.equal((await a1.run()).ok,false);
 const ex=rig();ex.x.now=120000;
 a.equal((await ex.run()).ok,false);
});

test("Real service card-key syntax is accepted; mismatched source typing remains denied",async()=>{
 const z=rig();z.x.screen={...z.x.screen,screenCode:"practice-review",
  scopeCode:"global",subjectKey:"economics",finalized:true,
  ownsAnsweredQuestion:true,confirmedIncorrectAnswer:true,questionId:1188};
 z.x.card={locale:"ru",subject_key:"economics",question_id:1188,
  card_type:"answer_explanation",source_card_key:"practice:economics:t1:q1188:ru:v1",
  content_hash:SHA,source_version:VERSION,
  body_text:"A verified prepared explanation for the finalized Economics answer."};
 a.equal((await z.run({intent:"practice_card",promptKey:"explain_error"})).ok,true);
 z.x.card.card_type="result_context";
 a.equal((await z.run({intent:"practice_card",promptKey:"explain_error"})).ok,false);
 z.x.card.card_type="answer_explanation";
 z.x.card.source_card_key="practice/economics/..";
 a.equal((await z.run({intent:"practice_card",promptKey:"explain_error"})).ok,false);
});
test("Practice requires positive independently approved publication revision",async()=>{
 const z=rig();Object.assign(z.x.screen,{
  screenCode:"practice-review",scopeCode:"global",subjectKey:"economics",
  finalized:true,ownsAnsweredQuestion:true,confirmedIncorrectAnswer:true,
  questionId:19
 });
 z.x.card={locale:"ru",subject_key:"economics",question_id:19,
  card_type:"answer_explanation",source_card_key:"practice:economics:19:ru:v1",
  content_hash:SHA,source_version:VERSION,
  body_text:"Precisely scoped and reviewed synthetic answer for this question."};
 const original=z.services.readApprovedSource;
 z.services.readApprovedSource=async(...args)=>({
  ...await original(...args),publicationRevision:0
 });
 a.equal((await z.run({intent:"practice_card",promptKey:"explain_error"})).ok,false);
});
