"use strict";
const {test}=require("node:test");
const a=require("node:assert/strict");
const {makeGateway,scratchSql,HANDLE}=require("./ai-layer-v21-p6-home-pg-http-gateway.cjs");
test("§96 real PostgreSQL -> localhost HTTP -> HMAC -> Home choice, including revocation",async()=>{
 const g=makeGateway();
 await new Promise(done=>g.server.listen(0,"127.0.0.1",done));
 const origin="http://127.0.0.1:"+g.server.address().port;
 const send=async({token=g.ownerToken,locale="ru",handle=HANDLE,
    newOrigin=origin,body}={})=>{
  const response=await fetch(origin+"/qa/home/next",{
   method:"POST",headers:{"origin":newOrigin,"content-type":"application/json",
    "authorization":token?"Bearer "+token:""},
   body:JSON.stringify(body||{contextHandle:handle,locale})});
  return{status:response.status,body:await response.json(),
   headers:response.headers};
 };
 const confirm=async(token,actionCode,subjectKey,{
  locale="ru",auth=g.ownerToken,contextHandle=HANDLE,extra={}
 }={})=>{
  const response=await fetch(origin+"/qa/home/confirm",{
   method:"POST",
   headers:{"origin":origin,"content-type":"application/json",
    "authorization":"Bearer "+auth},
   body:JSON.stringify({contextHandle,locale,handoffToken:token,
    actionCode,subjectKey,...extra})});
  return {status:response.status,body:await response.json(),
   cache:response.headers.get("cache-control")};
 };
 try{
  a.equal(Number(scratchSql(
   "SELECT count(DISTINCT source_hash) FROM "+
   "private.iclub_ai_v21_home_source_test_releases")),12,
   "Each locale and action has an independently versioned source digest");
  // Three locales go through the REAL scratch PostgreSQL function, independent
  // academic SQL checks, signed proof, and approved category priority.
  for(const locale of ["ru","uz","en"]){
   const result=await send({locale});
   a.equal(result.status,200,locale+" "+JSON.stringify(result.body));
   a.equal(result.body.actionCode,"review_finalized_practice");
   a.equal(result.body.subjectKey,"economics");
   a.equal(result.body.reviewOnly,true);
   a.equal(result.body.releaseAllowed,false);
   a.equal(result.headers.get("cache-control"),"no-store");
   a.equal(result.headers.get("set-cookie"),null);
   a.equal(JSON.stringify(result.body).includes("signingKey"),false);
   for(const prohibited of ["question_ids","is_correct","finalized_at",
    "userId","score","correctAnswer","sourceHash","jwt","authorityHash"])
    a.equal(Object.hasOwn(result.body,prohibited),false,prohibited);
  }
  // §108 one-use action confirmation deliberately changes NO user progress.
  // The opaque token does not reveal owner/evidence/academic identifiers.
  const issued=await send();
  const token=issued.body.handoffToken;
  a.match(token,/^[A-Za-z0-9_-]{32}$/);
  a.equal(token.includes("901"),false);
  a.equal(token.includes("11111111"),false);
  a.equal(issued.body.releaseAllowed,false);
  a.equal((await confirm(token,"review_finalized_practice","economics",
   {auth:g.otherToken})).status,403,"Foreign user cannot consume token");
  a.equal((await confirm(token,"review_finalized_practice","biology")).status,403,
   "Correct action with wrong subject is rejected");
  a.equal((await confirm(token,"review_open_tour_archive","economics")).status,403,
   "Cannot change action under an issued Home token");
  a.equal((await confirm(token,"review_finalized_practice","economics",
   {locale:"en"})).status,403,"Cross-locale one-use token denied");
  a.equal((await confirm(token,"review_finalized_practice","economics",
   {contextHandle:"44444444-4444-4444-8444-444444444444"})).status,403);
  a.equal((await confirm(token,"review_finalized_practice","economics",
   {extra:{userId:"22222222-2222-4222-8222-222222222222"}})).status,400);
  const accepted=await confirm(token,"review_finalized_practice","economics");
  a.equal(accepted.status,200,JSON.stringify(accepted));
  a.equal(accepted.body.status,"qa_handoff_confirmed");
  a.equal(accepted.body.progressChanged,false);
  a.equal(accepted.body.navigationExecuted,false);
  a.equal(accepted.body.releaseAllowed,false);
  a.equal(accepted.cache,"no-store");
  a.equal((await confirm(token,"review_finalized_practice","economics")).status,403,
   "Token must be one-use even with same authorization");
  const raced=(await send()).body.handoffToken;
  const race=await Promise.all([
   confirm(raced,"review_finalized_practice","economics"),
   confirm(raced,"review_finalized_practice","economics")
  ]);
  a.deepEqual(race.map(v=>v.status).sort(),[200,403],
   "Only one claimant may consume a durable scratch token");
  a.equal(scratchSql("SELECT count(*) FROM "+
   "private.iclub_ai_v21_home_action_handoffs_scratch "+
   "WHERE consumed_at IS NOT NULL"),"2");
  // Real-shaped scratch PG commercial guard + subscription capabilities:
  // shadow/passthrough and a disabled AI entitlement NEVER authorize Home.
  scratchSql("UPDATE private.iclub_commercial_access_config "+
   "SET subject_limits_mode='shadow' WHERE id=1");
  a.equal((await send()).status,403,"Shadow allowed=true is NOT AI rights");
  scratchSql("UPDATE private.iclub_commercial_access_config "+
   "SET subject_limits_mode='off' WHERE id=1");
  a.equal((await send()).status,403,"Legacy passthrough is NOT AI rights");
  scratchSql("UPDATE private.iclub_commercial_access_config "+
   "SET subject_limits_mode='enforced' WHERE id=1");
  scratchSql("UPDATE private.iclub_ai_qa_capabilities_fixture "+
   "SET ai_generation_entitled=false");
  a.equal((await send()).status,403,"AI product entitlement is mandatory");
  scratchSql("UPDATE private.iclub_ai_qa_capabilities_fixture "+
   "SET ai_generation_entitled=true");
  scratchSql("UPDATE private.iclub_ai_qa_home_feature_gate "+
   "SET approved=false");
  a.equal((await send()).status,403,"Separate AI rollout gate mandatory");
  scratchSql("UPDATE private.iclub_ai_qa_home_feature_gate "+
   "SET approved=true");
  scratchSql("UPDATE private.iclub_subject_slot_selections "+
   "SET study_selected=false WHERE subject_key='economics'");
  const unselected=await send();
  a.equal(unselected.status,200,"Another authorized subject should remain");
  a.equal(unselected.body.actionCode,"continue_enrolled_subject");
  a.equal(unselected.body.subjectKey,"biology");
  scratchSql("UPDATE private.iclub_subject_slot_selections "+
   "SET study_selected=true WHERE subject_key='economics'");
  a.equal((await send()).body.actionCode,"review_finalized_practice",
   "Restored verified slot must restore original priority");
  a.equal((await send({token:g.otherToken})).status,403,
   "Foreign owner must not inherit Home context");
  a.equal((await send({token:"synthetic-forged"})).status,401);
  a.equal((await send({token:null})).status,401);
  a.equal((await send({handle:"44444444-4444-4444-8444-444444444444"})).status,403);
  a.equal((await send({newOrigin:"https://untrusted.example"})).status,403);
  const spoof=await send({body:{contextHandle:HANDLE,locale:"ru",
   userId:"22222222-2222-4222-8222-222222222222"}});
  a.equal(spoof.status,400,"Owner is derived from synthetic auth, not request body");
  // Finished mistakes gone: both enrolled study subjects are equally eligible
  // for continuing, and local code must NOT invent an arbitrary ranking.
  scratchSql("UPDATE public.practice_session_answers_v4 SET is_correct=true WHERE session_id=901");
  const tie=await send();
  a.equal(tie.status,200,JSON.stringify(tie.body));
  a.equal(tie.body.status,"selection_required");
  a.equal(tie.body.choices.length,2);
  a.deepEqual(tie.body.choices.map(x=>Object.keys(x).sort()),
   [["actionCode","subjectKey"],["actionCode","subjectKey"]]);
  a.deepEqual(tie.body.choices.map(x=>x.subjectKey),["biology","economics"]);
  a.equal(JSON.stringify(tie.body).includes("next_continue_"),false);
  a.equal(Object.hasOwn(tie.body,"candidateActionIds"),false);
  const tiedToken=tie.body.handoffToken;
  a.equal((await confirm(tiedToken,"continue_enrolled_subject","chemistry")).status,403,
   "Unlisted subject cannot be used with a valid tie token");
  const chosen=await confirm(tiedToken,"continue_enrolled_subject","biology");
  a.equal(chosen.status,200,JSON.stringify(chosen));
  a.equal(chosen.body.navigationExecuted,false);
  a.equal((await confirm(tiedToken,"continue_enrolled_subject","economics")).status,403,
   "Different tied subject cannot reuse consumed token");
  a.equal(Object.hasOwn(tie.body,"subjectKey"),false);
  // Same owner chooses competitive study mode. Only then is the ended Tour eligible.
  scratchSql("UPDATE public.user_subjects SET mode='competitive' "+
   "WHERE user_id='11111111-1111-4111-8111-111111111111' AND subject_id=10");
  const tour=await send();
  a.equal(tour.status,200,JSON.stringify(tour.body));
  a.equal(tour.body.actionCode,"review_open_tour_archive");
  a.equal(tour.body.subjectKey,"economics");
  scratchSql("UPDATE private.iclub_subject_slot_selections "+
   "SET competitive_selected=false WHERE subject_key='economics'");
  const notChosen=await send();
  a.equal(notChosen.status,200,
   "Without Tour selection another confirmed study subject remains eligible");
  a.equal(notChosen.body.actionCode,"continue_enrolled_subject");
  a.equal(notChosen.body.subjectKey,"biology");
  a.notEqual(notChosen.body.actionCode,"review_open_tour_archive");
  scratchSql("UPDATE private.iclub_subject_slot_selections "+
   "SET competitive_selected=true WHERE subject_key='economics'");
  a.equal((await send()).body.actionCode,"review_open_tour_archive");

  // Revoked rights for this subject must reveal another entitled study subject.
  scratchSql("UPDATE private.iclub_ai_v21_home_synthetic_access SET allowed=false "+
   "WHERE subject_key='economics' AND intent='competitive'");
  const fallback=await send();
  a.equal(fallback.status,200,JSON.stringify(fallback.body));
  a.equal(fallback.body.actionCode,"continue_enrolled_subject");
  a.equal(fallback.body.subjectKey,"biology");
  const tokenBeforeRightsRevoke=fallback.body.handoffToken;
  scratchSql("UPDATE private.iclub_ai_v21_home_source_test_releases "+
   "SET rights_approved=false WHERE locale='ru' "+
   "AND action_code='continue_enrolled_subject' AND subject_key='biology'");
  a.equal((await confirm(tokenBeforeRightsRevoke,
   "continue_enrolled_subject","biology")).status,403,
   "Revoked rights block previously offered token at action time");
  scratchSql("UPDATE private.iclub_ai_v21_home_source_test_releases "+
   "SET rights_approved=true WHERE locale='ru' "+
   "AND action_code='continue_enrolled_subject' AND subject_key='biology'");
  // Unlike the old hardcoded publication mock, this verifies real scratch
  // PostgreSQL release rows. A revoked RU source MUST block the signed plan.
  scratchSql("UPDATE private.iclub_ai_v21_home_source_test_releases "+
   "SET revoked_at=now() WHERE locale='ru' "+
   "AND action_code='continue_enrolled_subject' AND subject_key='biology'");
  const sourceRevoked=await send();
  a.equal(sourceRevoked.status,403,"Revoked source must block new Home plan");
  scratchSql("UPDATE private.iclub_ai_v21_home_source_test_releases "+
   "SET revoked_at=NULL,rights_approved=false WHERE locale='ru' "+
   "AND action_code='continue_enrolled_subject' AND subject_key='biology'");
  a.equal((await send()).status,403,"Independent rights flag must still block");
  scratchSql("UPDATE private.iclub_ai_v21_home_source_test_releases "+
   "SET rights_approved=true WHERE locale='ru' "+
   "AND action_code='continue_enrolled_subject' AND subject_key='biology'");
  a.equal((await send()).status,200,"Synthetic source restored in scratch only");
  // Deterministic TOCTOU: revoke AFTER the signed planner and approved
  // category have already completed, but BEFORE HTTP response. Only the
  // fresh pre-delivery gate can catch these updates in disposable PG.
  async function revokeBetweenChoiceAndDelivery(updateSql,restoreSql,reason,
   hook="beforeDelivery"){
   const injected=makeGateway({[hook]:async()=>{scratchSql(updateSql);}});
   await new Promise(done=>injected.server.listen(0,"127.0.0.1",done));
   const temporaryOrigin="http://127.0.0.1:"+injected.server.address().port;
   try{
    const response=await fetch(temporaryOrigin+"/qa/home/next",{
     method:"POST",headers:{"origin":temporaryOrigin,
      "content-type":"application/json",
      "authorization":"Bearer "+injected.ownerToken},
     body:JSON.stringify({contextHandle:HANDLE,locale:"ru"})});
    const body=await response.json();
    a.equal(response.status,403,reason+" "+JSON.stringify(body));
    a.equal(body.ok,false);
    a.equal(body.reason,"in_development");
   }finally{
    scratchSql(restoreSql);
    await new Promise(done=>injected.server.close(done));
   }
  }
  await revokeBetweenChoiceAndDelivery(
   "UPDATE private.iclub_ai_v21_home_source_test_releases "+
    "SET rights_approved=false WHERE locale='ru' "+
    "AND action_code='continue_enrolled_subject' AND subject_key='biology'",
   "UPDATE private.iclub_ai_v21_home_source_test_releases "+
    "SET rights_approved=true WHERE locale='ru' "+
    "AND action_code='continue_enrolled_subject' AND subject_key='biology'",
   "source revoked before HTTP delivery");
  await revokeBetweenChoiceAndDelivery(
   "UPDATE private.iclub_ai_qa_capabilities_fixture "+
    "SET ai_generation_entitled=false",
   "UPDATE private.iclub_ai_qa_capabilities_fixture "+
    "SET ai_generation_entitled=true",
   "AI tariff permission revoked before HTTP delivery");
  await revokeBetweenChoiceAndDelivery(
   "UPDATE private.iclub_ai_v21_current_screen SET revision=13 "+
    "WHERE user_id='11111111-1111-4111-8111-111111111111'",
   "UPDATE private.iclub_ai_v21_current_screen SET revision=12 "+
    "WHERE user_id='11111111-1111-4111-8111-111111111111'",
   "screen revision changed before HTTP delivery");
  // §107: revoke only at the last single-statement MVCC read. Earlier
  // independent validation has already passed. The SQL statement must
  // observe the *new* state across owner, commercial, and locale source.
  await revokeBetweenChoiceAndDelivery(
   "UPDATE private.iclub_ai_v21_home_source_test_releases "+
    "SET rights_approved=false WHERE locale='ru' "+
    "AND action_code='continue_enrolled_subject' AND subject_key='biology'",
   "UPDATE private.iclub_ai_v21_home_source_test_releases "+
    "SET rights_approved=true WHERE locale='ru' "+
    "AND action_code='continue_enrolled_subject' AND subject_key='biology'",
   "last SQL statement detects revoked source", "beforeAtomicRead");
  await revokeBetweenChoiceAndDelivery(
   "UPDATE private.iclub_ai_qa_capabilities_fixture "+
    "SET ai_generation_entitled=false",
   "UPDATE private.iclub_ai_qa_capabilities_fixture "+
    "SET ai_generation_entitled=true",
   "last SQL statement detects revoked AI plan entitlement", "beforeAtomicRead");
  await revokeBetweenChoiceAndDelivery(
   "UPDATE private.iclub_ai_v21_current_screen SET revision=13 "+
    "WHERE user_id='11111111-1111-4111-8111-111111111111'",
   "UPDATE private.iclub_ai_v21_current_screen SET revision=12 "+
    "WHERE user_id='11111111-1111-4111-8111-111111111111'",
   "last SQL statement detects stale current Home revision", "beforeAtomicRead");
  a.equal((await send()).status,200,
   "After synthetic test restores, authorized Home still works");
  // Server revocation makes even a previously valid token/handle unusable.
  scratchSql("UPDATE private.iclub_ai_v21_scoped_contexts SET revoked_at=now() "+
   "WHERE context_handle='33333333-3333-4333-8333-333333333333'");
  const revoked=await send();
  a.equal(revoked.status,403);
  a.equal(revoked.body.reason,"in_development");
  a.equal(g.state.requests>=24,true);
  console.log("HOME_PG_HTTP_GREEN: owner auth, RU/UZ/EN, Practice, tie, Tour, fallback, revoke");
 }finally{
  await new Promise(resolve=>g.server.close(resolve));
 }
});
