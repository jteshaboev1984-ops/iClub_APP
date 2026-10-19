// §35: actual QA Deno HTTP -> auth -> Supabase RPC adapter -> CJS AI
// core integration. All RPC replies and learner identities are synthetic.
// No connection to Supabase, paid model, content, or real browser.
import {createSupabaseServices} from "./supabase_services.ts";
import {createQaEdgeCandidate} from "./runtime.ts";
import {makeContextCore} from "./context_core.ts";
import {makeHttpHandler} from "./http.ts";

const UID="11111111-1111-4111-8111-111111111111";
const FOREIGN="22222222-2222-4222-8222-222222222222";
const HANDLE="33333333-3333-4333-8333-333333333333";
const REQUEST="44444444-4444-4444-8444-444444444444";
const SOURCE_HASH="a".repeat(64);
const ORIGIN="https://preview.synthetic.invalid";
const JWT="Bearer synthetic_valid_jwt_001";
const SUBJECTS=["biology","chemistry","mathematics","informatics","economics"];
const LANGS:{[lang:string]:string}={
 ru:"В разработке",uz:"Ishlab chiqilmoqda",en:"In development"
};
const ok=(v:unknown,message:string)=>{if(!v)throw Error(message)};
const equal=(v:unknown,expected:unknown,context="assertion")=>{
 if(!Object.is(v,expected))throw Error(context+": "+JSON.stringify(v)+" != "+JSON.stringify(expected));
};
type RecordData=Record<string,unknown>;
type Screen={subject:string;surface:"lesson"|"practice";
 feature:"topic_explanation"|"answer_explanation";topic:string};
type Reservation={user:string;fingerprint:string;route:string;status:string};
function scenario({subject="biology",surface="lesson",locale="ru",ready=true}:
 {subject?:string;surface?:"lesson"|"practice";locale?:string;ready?:boolean}={}){
 const screen:Screen={subject,surface,feature:surface==="lesson"?
  "topic_explanation":"answer_explanation",
  topic:surface==="lesson"?"lesson_101":"question_202"};
 const state={
  ready,rights:true,rollout:true,kill:false,exam:false,active:true,
  user:UID,plan:"plus_qa_v2",locale,rev:4,networkDown:"",
  authOn:true,sourceChangedOnBundle:false,screenChangedOnBundle:false,
  screenRevision:1,authenticatedUser:UID,
  publishedLocales:new Set<string>([locale]),activeSubjects:new Set<string>(SUBJECTS),
  reservations:new Map<string,Reservation>(),claims:new Set<string>(),
  settled:new Map<string,string>(),logs:[] as {endpoint:string;args:RecordData}[],
  protectedMode:false
 };
 const context=()=>({
  owner_id:UID,route_authority:"unified_ai",active:state.active,
  protected_assessment:state.exam,expires_at_ms:4102444800000,
  context_revision:"synthetic-context-revision-v1",
  surface:screen.surface,subject:screen.subject,
  feature:screen.feature,topic:screen.topic,current_view:"courses",
  lesson_id:screen.surface==="lesson"?101:null,
  practice_session_id:screen.surface==="practice"?11:null,
  question_id:screen.surface==="practice"?202:null,
  tour_attempt_id:null
 });
 const exactTopic=(args:RecordData)=>args.p_surface===screen.surface&&
   args.p_subject===screen.subject&&args.p_feature===screen.feature&&
   args.p_topic===screen.topic;
 const sourceIdentity={source_id:"synthetic_source",source_version:"v1",
  source_hash:SOURCE_HASH};
 const fetcher=(async(url:string|URL|Request,init?:RequestInit)=>{
  const endpoint=String(url);
  const args:RecordData=init?.body?JSON.parse(String(init.body)):{};
  state.logs.push({endpoint,args});
  if(endpoint.endsWith("/auth/v1/user")){
   return state.authOn&&new Headers(init?.headers).get("authorization")===JWT?
     Response.json({id:state.authenticatedUser,role:"authenticated",aud:"authenticated"}):
     Response.json({error:"unavailable"},{status:401});
  }
  if(endpoint.includes("/rest/v1/subjects")){
   const match=endpoint.match(/subject_key=eq\.([a-z_]+)/);
   const selected=match?.[1]??"";
   return Response.json(state.activeSubjects.has(selected)?
    [{subject_key:selected,is_active:true}]:[]);
  }
  const name=endpoint.split("/").at(-1)||"";
  if(state.networkDown===name)return Response.json({error:"synthetic_unavailable"},{status:503});
  switch(name){
   case "mint_iclub_ai_v21_lesson_context_service":
    return Response.json({allowed:args.p_user_id===UID&&
     screen.surface==="lesson"&&args.p_lesson_id===101,
     context_handle:HANDLE,expires_in_seconds:90});
   case "mint_iclub_ai_v21_practice_context_service":
    return Response.json({allowed:args.p_user_id===UID&&
     screen.surface==="practice"&&args.p_session_id===11&&args.p_question_id===202,
     context_handle:HANDLE,expires_in_seconds:90});
   case "revoke_iclub_ai_v21_scoped_context_service":
    if(args.p_user_id===UID&&args.p_context_handle===HANDLE){state.active=false;return Response.json({ok:true});}
    return Response.json({ok:false});
   case "get_iclub_ai_v21_runtime_service":
    return Response.json({ui_enabled:!state.kill,gateway_enabled:!state.kill,
     kill_switch:state.kill,release_approved:true});
   case "get_iclub_ai_v21_protected_service":
    return Response.json({protected:state.exam});
   case "get_iclub_ai_v21_scoped_context_service":
    return Response.json({allowed:args.p_user_id===UID&&
      args.p_context_handle===HANDLE,context:context()});
   case "get_iclub_ai_v21_screen_evidence_service":{
    // Proposed RPC is simulated, never connected to real students.
    if(args.p_user_id!==UID||!state.active)return Response.json({allowed:false});
    const kind=String(args.p_kind||"");
    const base={user_id:UID,evidence_kind:kind,
     requested_view:args.p_view,requested_subject:args.p_subject};
    let evidence:RecordData|null=null;
    if(kind==="current_screen")
     evidence={...base,active:true,context_handle:HANDLE,
      context_revision:"synthetic-context-revision-v1",
      revision:state.screenRevision,current_view:"courses"};
    if(screen.surface==="lesson"&&kind==="lesson"&&args.p_lesson_id===101)
     evidence={...base,id:101,subject_key:screen.subject,topic_key:screen.topic,
      is_active:true,lesson_specific:true,is_video:false,
      access_authorized:true,source_revision:1};
    if(screen.surface==="practice"&&kind==="practice_session_v4"&&args.p_session_id===11)
     evidence={...base,id:11,session_id:11,user_id:UID,status:"finalized",
      subject_key:screen.subject,finalized_at:"2026-10-14T00:00:00Z",question_ids:[202]};
    if(screen.surface==="practice"&&kind==="practice_answer_v4"&&
       args.p_session_id===11&&args.p_question_id===202)
     evidence={...base,session_id:11,question_id:202,
      server_checked:true,is_final:true,topic_key:screen.topic,revision:1};
    return Response.json({allowed:evidence!==null,evidence});
   }
   case "get_iclub_ai_v21_rollout_service":
    return Response.json({allowed:args.p_user_id===UID&&state.rollout&&
      state.active&&state.activeSubjects.has(screen.subject)&&exactTopic(args)});
   case "get_iclub_ai_topic_release_service_v21":
    return Response.json(state.ready&&exactTopic(args)&&
      state.publishedLocales.has(String(args.p_locale))?
      {ready:true,surface:screen.surface,subject:screen.subject,
       feature:screen.feature,topic:screen.topic,locale:args.p_locale,
       ...sourceIdentity,revision:state.rev}:{ready:false});
   case "get_iclub_ai_v21_source_proof_service":
    return Response.json({approved:state.ready&&state.rights&&exactTopic(args)&&
      state.publishedLocales.has(String(args.p_locale)),rights_approved:state.rights,
      runtime_allowed:!state.kill,source_conflict:false,...sourceIdentity});
   case "get_iclub_ai_v21_entitlement_service":
    return Response.json({allowed:true,usage_policy_code:state.plan});
   case "get_iclub_ai_v21_source_bundle_service":{
    const response=Response.json({approved:state.ready&&state.rights&&state.active,
      rights_approved:state.rights,integrity_verified:true,qa_passed:true,
      runtime_allowed:!state.kill,source_conflict:false,
      ...sourceIdentity,publication_revision:state.rev,
      generation_allowed:false,source_text:"",
      prepared_variants:{topic_main:"Synthetic workflow acknowledgement — QA only"}});
    if(state.sourceChangedOnBundle){state.sourceChangedOnBundle=false;state.ready=false;}
    if(state.screenChangedOnBundle){state.screenChangedOnBundle=false;state.screenRevision++;}
    return response;
   }
   case "get_iclub_ai_v21_provider_budget_service":
    return Response.json({allowed:false,reason:"provider_budget_not_authorized"});
   case "reserve_iclub_ai_usage_service_v2":{
    const id=String(args.p_request_id);
    if(state.reservations.has(id))return Response.json({allowed:false,reason:"request_already_completed"});
    state.reservations.set(id,{user:String(args.p_user_id),
      fingerprint:String(args.p_request_fingerprint),
      route:String(args.p_route_class),status:"reserved"});
    return Response.json({allowed:true});
   }
   case "claim_iclub_ai_delivery_service_v21":{
    const id=String(args.p_request_id),hold=state.reservations.get(id);
    if(!hold||hold.user!==args.p_user_id||
       hold.fingerprint!==args.p_request_fingerprint||
       state.claims.has(id))return Response.json({allowed:false});
    state.claims.add(id);return Response.json({allowed:true});
   }
   case "finish_iclub_ai_delivery_service_v21":{
    const id=String(args.p_request_id),hold=state.reservations.get(id);
    if(!hold||!state.claims.has(id)||hold.status!=="reserved")
      return Response.json({ok:false});
    hold.status=String(args.p_outcome);
    state.settled.set(id,hold.status);
    return Response.json({ok:true});
   }
   default: return Response.json({error:"not_installed"},{status:404});
  }
 }) as typeof fetch;
 const services=createSupabaseServices({
  supabaseUrl:"http://127.0.0.1:54321",
  anonKey:"synthetic-public-key",serviceRoleKey:"synthetic-private-key",fetcher
 });
 const answer=makeHttpHandler(
  createQaEdgeCandidate(services as unknown as Record<string,unknown>,[ORIGIN]),[ORIGIN]);
 const ctx=makeHttpHandler(makeContextCore(services),[ORIGIN]);
 const send=async(endpoint:"answer"|"context",data:RecordData,options:{
  token?:string;origin?:string}={})=>{
  const h=endpoint==="answer"?answer:ctx;
  const response=await h(new Request("https://preview.synthetic.invalid/"+endpoint,{
   method:"POST",headers:{
    origin:options.origin??ORIGIN,"content-type":"application/json",
    authorization:options.token??JWT
   },body:JSON.stringify(data)
  }));
  return{status:response.status,data:await response.json() as RecordData,
   cache:response.headers.get("cache-control")};
 };
 const body=(intent:"status"|"answer",overrides:RecordData={})=>({
  intent,contextHandle:HANDLE,appLocale:state.locale,
  ...(intent==="answer"?{requestId:REQUEST,promptKey:"topic_main"}:{}),
  ...overrides
 });
 const count=(name:string)=>state.logs.filter(l=>l.endpoint.endsWith("/"+name)).length;
 return{state,screen,body,send,count};
}
Deno.test("Real QA adapter + HTTP: five subjects, Lessons and completed Practice, prepared only",async()=>{
 for(const subject of SUBJECTS){
  for(const surface of ["lesson","practice"] as const){
   const f=scenario({subject,surface});
   const mint=surface==="lesson"?{action:"mintLesson",lessonId:101}:
    {action:"mint",sessionId:11,questionId:202};
   const m=await f.send("context",mint);
   equal(m.status,200,subject+" mint");equal(m.data.ok,true,subject+" mint");
   equal(m.data.contextHandle,HANDLE,subject+" handle");
   equal((await f.send("answer",f.body("status"))).data.state,"available");
   const r=await f.send("answer",f.body("answer"));
   equal(r.status,200,subject+" response status");
   equal(r.data.ok,true,subject+" answer");
   equal(r.data.reply,"Synthetic workflow acknowledgement — QA only");
   equal(f.count("reserve_iclub_ai_usage_service_v2"),1);
   equal(f.count("claim_iclub_ai_delivery_service_v21"),1);
   equal(f.count("finish_iclub_ai_delivery_service_v21"),1);
   equal(f.count("get_iclub_ai_v21_provider_budget_service"),0);
   equal(f.count("reserve_iclub_ai_v21_provider_spend_service"),0);
   equal(f.state.settled.get(REQUEST),"completed");
   equal(r.cache,"no-store, max-age=0");
  }
 }
});
Deno.test("Unpublished release RU/UZ/EN stays localized, costs zero, no model",async()=>{
 for(const locale of ["ru","uz","en"]){
  const f=scenario({ready:false,locale});
  const r=await f.send("answer",f.body("answer"));
  equal(r.status,200);equal(r.data.title,LANGS[locale]);equal(r.data.charge,0);
  equal(f.count("reserve_iclub_ai_usage_service_v2"),0);
  equal(f.count("get_iclub_ai_v21_provider_budget_service"),0);
 }
});
Deno.test("RU-only signed source cannot silently authorize EN or UZ",async()=>{
 for(const locale of ["uz","en"]){
  const f=scenario({locale});
  f.state.publishedLocales=new Set(["ru"]);
  const r=await f.send("answer",f.body("answer"));
  equal(r.data.state,"in_development");
  equal(r.data.title,LANGS[locale]);
  equal(f.count("reserve_iclub_ai_usage_service_v2"),0);
 }
});
Deno.test("Source revocation after bundle returns no answer and releases quota",async()=>{
 const f=scenario();
 f.state.sourceChangedOnBundle=true;
 const r=await f.send("answer",f.body("answer"));
 equal(r.data.ok,false);
 equal(f.count("reserve_iclub_ai_usage_service_v2"),1);
 equal(f.state.settled.get(REQUEST),"released");
 ok(!Object.hasOwn(r.data,"reply"),"revoked reply delivered");
});
Deno.test("Changed server screen while source awaits releases hold without a reply",async()=>{
 const f=scenario();f.state.screenChangedOnBundle=true;
 const r=await f.send("answer",f.body("answer"));
 equal(r.data.ok,false);
 equal(f.count("reserve_iclub_ai_usage_service_v2"),1);
 equal(f.state.settled.get(REQUEST),"released");
 ok(!Object.hasOwn(r.data,"reply"),"stale screen response leaked");
});
Deno.test("Exam, rollout, kill switch and unenrolled subject never reserve",async()=>{
 for(const kind of ["exam","rollout","kill","subject","inactive"]){
  const f=scenario();
  if(kind==="exam")f.state.exam=true;
  if(kind==="rollout")f.state.rollout=false;
  if(kind==="kill")f.state.kill=true;
  if(kind==="subject")f.state.activeSubjects.delete("biology");
  if(kind==="inactive")f.state.active=false;
  const r=await f.send("answer",f.body("answer"));
  equal(r.data.ok,false,kind);
  equal(f.count("reserve_iclub_ai_usage_service_v2"),0,kind);
  equal(f.count("claim_iclub_ai_delivery_service_v21"),0,kind);
 }
});
Deno.test("Navigation revoke and invalid session eliminate source access",async()=>{
 const f=scenario();
 equal((await f.send("context",{action:"revoke",contextHandle:HANDLE})).data.ok,true);
 const r=await f.send("answer",f.body("answer"));
 equal(r.data.ok,false);equal(f.count("reserve_iclub_ai_usage_service_v2"),0);
});
Deno.test("Wrong JWT, stolen context, browser-forged course and foreign Origin are denied",async()=>{
 const f=scenario();
 equal((await f.send("answer",f.body("answer"),{token:"Bearer bad-token-value"})).status,401);
 f.state.authenticatedUser=FOREIGN;
 equal((await f.send("answer",f.body("answer"))).data.ok,false);
 f.state.authenticatedUser=UID;
 equal((await f.send("answer",f.body("answer",{subject:"economics"}))).status,400);
 equal((await f.send("context",{action:"mintLesson",lessonId:101,plan:"pro"})).status,400);
 equal((await f.send("answer",f.body("answer"),{origin:"https://intruder.invalid"})).status,403);
 equal(f.count("reserve_iclub_ai_usage_service_v2"),0);
});
Deno.test("Network loss and missing runtime/protected/content RPC DENY, never assume ready",async()=>{
 for(const endpoint of [
  "get_iclub_ai_v21_runtime_service","get_iclub_ai_v21_protected_service",
  "get_iclub_ai_v21_rollout_service","get_iclub_ai_topic_release_service_v21",
  "get_iclub_ai_v21_source_proof_service","get_iclub_ai_v21_scoped_context_service",
  "get_iclub_ai_v21_entitlement_service","get_iclub_ai_v21_source_bundle_service",
   "get_iclub_ai_v21_screen_evidence_service"]){
  const f=scenario();f.state.networkDown=endpoint;
  const r=await f.send("answer",f.body("answer"));
  equal(r.data.ok,false,endpoint);
  equal(f.count("reserve_iclub_ai_usage_service_v2"),0,endpoint);
 }
});
Deno.test("Free entitlement can use prepared, paid route remains blocked pre-reservation",async()=>{
 const f=scenario();f.state.plan="free_qa_v2";
 const result=await f.send("answer",f.body("answer"));
 equal(result.data.ok,true);
 const g=scenario();g.state.plan="free_qa_v2";
 const r=await g.send("answer",g.body("answer",{
  promptKey:undefined,question:"Почему это происходит?"
 }));
 equal(r.status,403);equal(r.data.reason,"generation_not_entitled");
 equal(g.count("get_iclub_ai_v21_provider_budget_service"),0);
 equal(g.count("reserve_iclub_ai_usage_service_v2"),0);
});
Deno.test("Generated route on synthetic Plus remains blocked at monetary gate",async()=>{
 const f=scenario();
 const r=await f.send("answer",f.body("answer",{
  promptKey:undefined,question:"Почему это происходит?"
 }));
 equal(r.data.ok,false);
 equal(f.count("reserve_iclub_ai_usage_service_v2"),0);
 equal(f.count("reserve_iclub_ai_v21_provider_spend_service"),0);
 // No real provider can be called by this adapter.
 equal(f.count("get_iclub_ai_v21_provider_budget_service"),0);
});
Deno.test("A replayed ID never double settles prepared source",async()=>{
 const f=scenario();
 equal((await f.send("answer",f.body("answer"))).data.ok,true);
 const second=await f.send("answer",f.body("answer"));
 equal(second.data.ok,false);equal(f.count("reserve_iclub_ai_usage_service_v2"),2);
 equal(f.count("claim_iclub_ai_delivery_service_v21"),1);
 equal(f.count("finish_iclub_ai_delivery_service_v21"),1);
});
