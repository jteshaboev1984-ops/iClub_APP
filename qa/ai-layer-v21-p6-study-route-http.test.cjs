"use strict";
const {test}=require("node:test");
const a=require("node:assert/strict");
const {makeGateway,scratchSql,HANDLE}=require("./ai-layer-v21-p6-home-pg-http-gateway.cjs");
test("§§110–113 isolated Home -> independent Study -> read -> Back / revocation",async()=>{
 const gw=makeGateway();
 await new Promise(done=>gw.server.listen(0,"127.0.0.1",done));
 const url="http://127.0.0.1:"+gw.server.address().port;
 const request=async(path,body,{auth=gw.ownerToken,origin=url}={})=>{
  const response=await fetch(url+path,{method:"POST",
   headers:{"origin":origin,"content-type":"application/json",
    "authorization":"Bearer "+auth},body:JSON.stringify(body)});
  return {status:response.status,body:await response.json(),
   noStore:response.headers.get("cache-control")};
 };
 const issue=locale=>request("/qa/home/next",{contextHandle:HANDLE,locale});
 const confirm=(handoffToken,actionCode,subjectKey,locale="ru")=>
  request("/qa/home/confirm",{contextHandle:HANDLE,locale,
   handoffToken,actionCode,subjectKey});
 const open=(handoffToken,actionCode,subjectKey,locale="ru")=>
  request("/qa/study/open",{contextHandle:HANDLE,locale,
   handoffToken,actionCode,subjectKey});
 const read=(routeToken,locale="ru",options={})=>
  request("/qa/study/read",{routeToken,locale},options);
 const close=(routeToken,locale="ru")=>
  request("/qa/study/close",{routeToken,locale});
 const owner="11111111-1111-4111-8111-111111111111";
 try{
  // One use, two independent PostgreSQL sessions; academic destination is
  // derived by the server, never supplied from the browser.
  const first=await issue("ru");
  a.equal(first.status,200,JSON.stringify(first));
  const home=first.body.handoffToken;
  a.equal((await open(home,"review_finalized_practice","economics")).status,403);
  a.equal((await confirm(home,"review_finalized_practice","economics")).status,200);
  const double=await Promise.all([
   open(home,"review_finalized_practice","economics"),
   open(home,"review_finalized_practice","economics")
  ]);
  a.deepEqual(double.map(x=>x.status).sort(),[200,403],
   "Competing study navigations may enter only once");
  const entered=double.find(x=>x.status===200);
  a.equal(entered.body.status,"qa_study_scope_open");
  a.equal(entered.body.targetScreen,"practice-review");
  a.equal(entered.body.progressChanged,false);
  a.match(entered.body.routeToken,/^[A-Za-z0-9_-]{32}$/);
  for(const key of ["objectId","attemptId","sessionId","userId","sourceHash",
   "correctAnswer","grade","authorityHash"])
   a.equal(Object.hasOwn(entered.body,key),false,key);
  const ticket=entered.body.routeToken;
  a.equal((await issue("ru")).status,403,
   "Old Home context MUST stop working when Courses becomes current");
  const checked=await read(ticket);
  a.equal(checked.status,200,JSON.stringify(checked));
  a.equal(checked.noStore,"no-store");
  a.deepEqual(checked.body,{ok:true,status:"qa_study_read",
   targetScreen:"practice-review",subjectKey:"economics",
   reviewCount:1,reviewOnly:true,releaseAllowed:false,progressChanged:false});
  a.equal((await read(ticket,"en")).status,403,"Locale drift blocked");
  a.equal((await read(ticket,"ru",{auth:gw.otherToken})).status,403);
  a.equal((await read(ticket,"ru",{auth:"forged"})).status,401);
  a.equal((await read(ticket,"ru",{origin:"https://example.org"})).status,403);
  a.equal((await request("/qa/study/read",{routeToken:ticket,locale:"ru",
   objectId:903})).status,400,"No client object selection accepted");
  scratchSql("UPDATE private.iclub_ai_v21_home_source_test_releases "+
   "SET rights_approved=false WHERE locale='ru' AND subject_key='economics' "+
   "AND action_code='review_finalized_practice'");
  a.equal((await read(ticket)).status,403,"Fresh source approval required at every read");
  scratchSql("UPDATE private.iclub_ai_v21_home_source_test_releases "+
   "SET rights_approved=true WHERE locale='ru' AND subject_key='economics' "+
   "AND action_code='review_finalized_practice'");
  scratchSql("UPDATE public.practice_session_answers_v4 "+
   "SET is_correct=true WHERE session_id=901");
  a.equal((await read(ticket)).status,403,"Evidence revocation blocks already opened route");
  scratchSql("UPDATE public.practice_session_answers_v4 "+
   "SET is_correct=false WHERE session_id=901");
  a.equal((await read(ticket)).status,200);
  scratchSql("UPDATE private.iclub_subject_slot_selections "+
   "SET study_selected=false WHERE subject_key='economics'");
  a.equal((await read(ticket)).status,403,"Selected subject access cannot be bypassed");
  scratchSql("UPDATE private.iclub_subject_slot_selections "+
   "SET study_selected=true WHERE subject_key='economics'");
  a.equal((await read(ticket)).status,200);
  scratchSql("INSERT INTO private.exam_qa VALUES ('"+owner+"',true)");
  a.equal((await read(ticket)).status,403,"Protected assessment blocks AI-study scope");
  scratchSql("UPDATE private.exam_qa SET active=false");
  a.equal((await read(ticket)).status,200);
  a.equal((await close(ticket)).status,200,
   "Returning Home revokes route and refreshes original Home context");
  a.equal((await read(ticket)).status,403,"Closed ticket must not read again");
  a.equal((await close(ticket)).status,403,"Back action cannot be replayed");
  a.equal((await issue("ru")).status,200,"Home can work after returning");
  // A different subject at equal priority must create its OWN route scope.
  scratchSql("UPDATE public.practice_session_answers_v4 "+
   "SET is_correct=true WHERE session_id=901");
  const tie=await issue("uz");
  a.equal(tie.status,200,JSON.stringify(tie));
  a.equal(tie.body.status,"selection_required");
  a.equal((await confirm(tie.body.handoffToken,
   "continue_enrolled_subject","biology","uz")).status,200);
  const biology=await open(tie.body.handoffToken,
   "continue_enrolled_subject","biology","uz");
  a.equal(biology.status,200,JSON.stringify(biology));
  const bioRead=await read(biology.body.routeToken,"uz");
  a.equal(bioRead.status,200,JSON.stringify(bioRead));
  a.equal(bioRead.body.subjectKey,"biology");
  a.equal(bioRead.body.targetScreen,"subject-hub");
  a.equal(bioRead.body.reviewCount,0);
  a.equal((await close(biology.body.routeToken,"uz")).status,200);
  scratchSql("UPDATE public.practice_session_answers_v4 "+
   "SET is_correct=false WHERE session_id=901");
  // Practice and Tour routes must not share academic evidence or subject mode.
  scratchSql("UPDATE public.user_subjects SET mode='competitive' "+
   "WHERE user_id='"+owner+"' AND subject_id=10");
  const tour=await issue("en");
  a.equal(tour.status,200,JSON.stringify(tour));
  a.equal(tour.body.actionCode,"review_open_tour_archive");
  a.equal((await confirm(tour.body.handoffToken,
   "review_open_tour_archive","economics","en")).status,200);
  const tourOpen=await open(tour.body.handoffToken,
   "review_open_tour_archive","economics","en");
  a.equal(tourOpen.status,200,JSON.stringify(tourOpen));
  a.equal((await read(tourOpen.body.routeToken,"en")).body.targetScreen,"tour-review");
  scratchSql("UPDATE public.tour_attempts SET status='anti_cheat' WHERE id=100");
  a.equal((await read(tourOpen.body.routeToken,"en")).status,403,
   "Changed tournament status invalidates active route");
  scratchSql("UPDATE public.tour_attempts SET status='submitted' WHERE id=100");
  a.equal((await read(tourOpen.body.routeToken,"en")).status,200);
  a.equal((await close(tourOpen.body.routeToken,"en")).status,200);
  scratchSql("UPDATE public.user_subjects SET mode='study' "+
   "WHERE user_id='"+owner+"' AND subject_id=10");
  a.equal(Number(scratchSql("SELECT count(*) FROM "+
   "private.iclub_ai_v21_study_routes_scratch WHERE revoked_at IS NULL")),0);
  a.equal(Number(scratchSql("SELECT count(*) FROM "+
   "public.practice_session_answers_v4 WHERE session_id=901 AND is_correct=false")),1,
   "No learning result persisted by navigation");
 }finally{
  await new Promise(done=>gw.server.close(done));
 }
});
