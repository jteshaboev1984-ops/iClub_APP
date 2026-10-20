"use strict";
const {test}=require("node:test");
const a=require("node:assert/strict");
const fs=require("node:fs");
const path=require("node:path");
const vm=require("node:vm");
const {instrumentAcademicContext}=require("./iclub-ai-v21-app-context-instrumentation.cjs");
const read=p=>fs.readFileSync(path.join(__dirname,p),"utf8");
const adapter=read("iclub-ai-v21-browser-adapter.js");
const edge=read("iclub-ai-v21-prepared/index.ts");
const shell=read("../ai-v21-real-preview-ui-snapshot.js");
const catalog=read("iclub_ai_v21_generic_academic_sources_20261020.sql");
const capability=read("iclub_ai_v21_academic_capabilities_20261020.sql");
const USER="11111111-1111-4111-8111-111111111111";
const RID="22222222-2222-4222-8222-222222222222";
function mock(){
 const x={user:USER,active:false,eligible:true,requests:[],changing:false};
 const dom={readyState:"loading",getElementById:id=>id==="courses-practice-quiz"
   ?{classList:{contains:()=>x.active}}:null,addEventListener(){}};
 const win={
  crypto:{randomUUID:()=>RID},
  sb:{
   auth:{getUser:async()=>({data:{user:{id:x.user}},error:null}),
    onAuthStateChange(){}},
   functions:{invoke:async(slug,{body})=>{
    a.equal(slug,"iclub-ai-v21-prepared");x.requests.push(body);
    if(body.intent==="status")return{data:{ok:true,candidate:true,
      eligible:x.eligible,consented:x.eligible},error:null};
    if(body.intent==="academic_available")return{data:{ok:true,available:[17,19]},error:null};
    if(body.intent==="academic")return{data:{ok:true,provider_called:false,
      academic_state_changed:false,mode:"prepared",
      message:"This is a reviewer-approved, exact source academic explanation, not an inferred response."},error:null};
    throw Error("Unexpected call "+body.intent);
   }}
  },
  i18n:{getLang:()=>"en"}
 };
 vm.runInNewContext(adapter,{window:win,document:dom,
   console,MutationObserver:class{observe(){}},
   setTimeout,clearTimeout,queueMicrotask});
 return {x,client:win.iClubAiV21BetaClient};
}
test("Single catalog handles EVERY subject via release DATA, not code-specific branches",()=>{
 a.match(catalog,/PRIMARY KEY\(surface_code,subject_key,context_key,locale\)/);
 a.match(catalog,/source_version text NOT NULL/);
 a.match(catalog,/academic_qa_passed boolean NOT NULL DEFAULT false/);
 a.match(catalog,/published boolean NOT NULL DEFAULT false/);
 a.match(catalog,/enabled boolean NOT NULL DEFAULT false/);
 a.match(catalog,/practice_error','lesson_topic','tour_archive/);
 a.doesNotMatch(catalog,/subject_key\s*(?:=|IN)\s*['"( ]*(?:chemistry|economics|biology)/);
 a.doesNotMatch(catalog,/CREATE OR REPLACE FUNCTION/);
 a.doesNotMatch(catalog,/OPENAI_API_KEY|api\.openai\.com/);
});
test("Prepared-only service authorizes finalized INCORRECT owned answer + enrolled lesson",()=>{
 for(const term of [
  "ps.legacy_attempt_id=pa.id","answer.is_correct IS FALSE",
  "answer.answered_at IS NOT NULL","ps.status='finalized'",
  "pa.user_id=p_user_id","enrolled.user_id=p_user_id",
  "content_hash","academic_qa_passed",
  "FOR UPDATE","usage.committed_count>=3",
  "academic_state_changed',false","provider_called',false"
 ])a.ok(catalog.includes(term),"Missing hard gate: "+term);
});
test("Tour archives require separately granted embargo and completed user attempt",()=>{
 for(const term of ["private.iclub_ai_v21_tour_archive_permissions",
  "access.available_at<=v_now","tour.end_date <",
  "a.status IN ('submitted','time_expired')","a.user_id=p_user_id",
  "access.approved AND NOT access.revoked"])
  a.ok(catalog.includes(term),"Tour embargo missing "+term);
});
test("Source discovery returns only exact released, owner-scoped matching content",()=>{
 for(const term of ["source_hash","answer.is_correct IS FALSE",
   "src.published AND NOT src.revoked","src.academic_qa_passed",
   "private.iclub_ai_v21_academic_policy",
   "src.context_key='lesson_'||p_record_id::text",
   "src.context_key='tour_'||v_tour::text||'_archive'"])
  a.ok(capability.includes(term),"Missing source gate "+term);
 a.match(capability,/TO service_role/);
 a.doesNotMatch(capability,/GRANT EXECUTE ON FUNCTION .*TO authenticated/);
});
test("Edge uses verified JWT identity and generic SQL resolver, never browser subject or model",()=>{
 for(const marker of [
 "deliver_iclub_ai_v21_academic_service",
 "get_iclub_ai_v21_academic_capabilities_service",
 '"/auth/v1/user"','p_user_id:authenticated.id',
 '"practice_error","lesson_topic","tour_archive"',
 '"academic_available"','"academic"'])
  a.ok(edge.includes(marker),"Missing Edge route "+marker);
 a.doesNotMatch(edge,/OPENAI_API_KEY|api\.openai\.com|\.signUp\(/);
 a.ok(!edge.includes("p_subject_key:body.subject"));
});
test("Browser exact selectors and signed session connect all three generic surfaces",async()=>{
 const x=mock();
 const ids=await x.client.availableAcademic({
  surface:"practice_error",recordId:101,locale:"ru"});
 a.equal(JSON.stringify(ids),"[17,19]");
 const cases=[
  {surface:"practice_error",recordId:101,questionId:17,locale:"ru"},
  {surface:"lesson_topic",recordId:25,locale:"uz"},
  {surface:"tour_archive",recordId:12,locale:"en"}
 ];
 for(const t of cases){
  const response=await x.client.askAcademic(t);
  a.equal(response.ok,true);
  a.equal(response.provider_called,false);
 }
 const academic=x.x.requests.filter(x=>x.intent==="academic");
 a.equal(academic.length,3);
 a.equal(academic[0].question_id,17);
 a.equal(academic[1].question_id,null);
 a.equal(academic[2].question_id,null);
 a.ok(academic.every(x=>x.user_id===undefined&&x.subject_key===undefined));
});
test("Correct/untrusted selectors never dispatch and protected tests remain hidden",async()=>{
 const x=mock();
 for(const args of [
  {surface:"practice_error",recordId:101,questionId:null,locale:"ru"},
  {surface:"practice_error",recordId:101,questionId:0,locale:"ru"},
  {surface:"math_exam_prep",recordId:1,locale:"ru"},
  {surface:"lesson_topic",recordId:-1,locale:"ru"},
  {surface:"tour_archive",recordId:12,questionId:17,locale:"en"}
 ]){
  a.equal((await x.client.askAcademic(args)).ok,false);
 }
 a.equal(x.x.requests.filter(y=>y.intent==="academic").length,0);
 x.x.active=true;
 a.deepEqual(await x.client.availableAcademic({
  surface:"practice_error",recordId:101,locale:"en"}),[]);
 a.equal((await x.client.askAcademic({
  surface:"lesson_topic",recordId:25,locale:"en"})).ok,false);
 a.equal(x.x.requests.filter(y=>y.intent==="academic").length,0);
});
test("Approved existing AI shell is reused, no new floating academic widget",()=>{
 a.match(shell,/explainAcademic/);
 a.match(shell,/window\.iClubGlobalAiShell/);
 a.match(shell,/iclub-global-ai-mark-logo/);
 a.match(shell,/body/);
 a.doesNotMatch(adapter,/document\.body\.innerHTML\s*=/);
});
test("Actual current MAIN instrumentation is tiny and idempotent",()=>{
 const from=process.env.ICLUB_QA_MAIN_PARITY_SOURCE;
 if(!from)return;
 const original=fs.readFileSync(path.join(from,"app.js"),"utf8");
 const edited=instrumentAcademicContext(original);
 a.equal(instrumentAcademicContext(edited),edited);
 a.ok(edited.includes("dataset.iclubAiLessonId"));
 a.ok(edited.includes("dataset.iclubAiTourAttemptId"));
 a.ok(edited.includes("function syncPracticeAiDomContext()"));
 a.ok(edited.includes("window.iClubExamPrep"));
 a.ok(edited.length-original.length<1400);
 a.doesNotMatch(edited.slice(original.length),/localStorage/);
});
