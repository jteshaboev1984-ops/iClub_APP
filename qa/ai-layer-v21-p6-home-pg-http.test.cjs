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
  a.equal(tie.body.candidateActionIds.length,2);
  a.equal(Object.hasOwn(tie.body,"subjectKey"),false);
  // Same owner chooses competitive study mode. Only then is the ended Tour eligible.
  scratchSql("UPDATE public.user_subjects SET mode='competitive' "+
   "WHERE user_id='11111111-1111-4111-8111-111111111111' AND subject_id=10");
  const tour=await send();
  a.equal(tour.status,200,JSON.stringify(tour.body));
  a.equal(tour.body.actionCode,"review_open_tour_archive");
  a.equal(tour.body.subjectKey,"economics");
  // Revoked rights for this subject must reveal another entitled study subject.
  scratchSql("UPDATE private.iclub_ai_v21_home_synthetic_access SET allowed=false "+
   "WHERE subject_key='economics' AND intent='competitive'");
  const fallback=await send();
  a.equal(fallback.status,200,JSON.stringify(fallback.body));
  a.equal(fallback.body.actionCode,"continue_enrolled_subject");
  a.equal(fallback.body.subjectKey,"biology");
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
  // Server revocation makes even a previously valid token/handle unusable.
  scratchSql("UPDATE private.iclub_ai_v21_scoped_contexts SET revoked_at=now() "+
   "WHERE context_handle='33333333-3333-4333-8333-333333333333'");
  const revoked=await send();
  a.equal(revoked.status,403);
  a.equal(revoked.body.reason,"in_development");
  a.equal(g.state.requests>=16,true);
  console.log("HOME_PG_HTTP_GREEN: owner auth, RU/UZ/EN, Practice, tie, Tour, fallback, revoke");
 }finally{
  await new Promise(resolve=>g.server.close(resolve));
 }
});
