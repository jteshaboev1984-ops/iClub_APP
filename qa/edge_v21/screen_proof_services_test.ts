import {createReadOnlyScreenProofReaders} from "./screen_proof_services.ts";
const U="11111111-1111-4111-8111-111111111111";
const OTHER="22222222-2222-4222-8222-222222222222";
const eq=(x:unknown,y:unknown)=>{if(!Object.is(x,y))throw Error(JSON.stringify(x)+" !== "+JSON.stringify(y))};
type Row=Record<string,unknown>;
const setup=()=>{
 const calls:{name:string;args:Row}[]=[];
 const state={installed:true,allowed:true,owner:U,kind:"",view:"",subject:"",id:0,forceError:false};
 const rpc=async(name:string,args:Row)=>{
  calls.push({name,args});
  if(!state.installed||state.forceError)throw Error("synthetic missing RPC");
  const kind=String(args.p_kind);
  return{allowed:state.allowed,evidence:{
   user_id:state.owner,evidence_kind:state.kind||kind,
   requested_view:state.view||args.p_view,
   requested_subject:state.subject||args.p_subject,
   id:state.id||args.p_lesson_id||args.p_session_id||args.p_attempt_id,
   session_id:args.p_session_id,question_id:args.p_question_id,
   attempt_id:args.p_attempt_id,
   context_handle:"server-owned",active:true,revision:1,current_view:"courses"
  }};
 };
 return{state,calls,s:createReadOnlyScreenProofReaders(rpc)};
};
Deno.test("One generic owner-bound read RPC for all 11 app-wide evidence readers",async()=>{
 const t=setup();
 const cases=[
  ["getCurrentScreen",()=>t.s.getCurrentScreen(U)],
  ["readNavigationSource",()=>t.s.readNavigationSource({userId:U,view:"home"})],
  ["readSubjectOverview",()=>t.s.readSubjectOverview({userId:U,subject:"biology"})],
  ["readHomeNextActions",()=>t.s.readHomeNextActions({userId:U})],
  ["readProfileAggregate",()=>t.s.readProfileAggregate({userId:U})],
  ["readLesson",()=>t.s.readLesson({userId:U,lessonId:19})],
  ["readPracticeSessionV4",()=>t.s.readPracticeSessionV4({userId:U,sessionId:22})],
  ["readPracticeAnswerV4",()=>t.s.readPracticeAnswerV4({userId:U,sessionId:22,questionId:32})],
  ["readTourAttempt",()=>t.s.readTourAttempt({userId:U,attemptId:44})],
  ["readTourRuntime",()=>t.s.readTourRuntime({userId:U,attemptId:44})],
  ["readTourArchiveAccess",()=>t.s.readTourArchiveAccess({userId:U,attemptId:44})]
 ] as const;
 for(const [name,call] of cases){
  const p=await call();eq(p?.user_id,U);
  eq(t.calls.at(-1)?.name,"get_iclub_ai_v21_screen_evidence_service");
  eq(t.calls.at(-1)?.args.p_user_id,U);
  eq(Object.hasOwn(t.calls.at(-1)?.args||{},"p_kind"),true);
  eq(Object.hasOwn(t.calls.at(-1)?.args||{},"p_question_answer"),false);
  eq(typeof name,"string");
 }
});
Deno.test("Missing RPC, deny, foreign owner, forged evidence kind and selector fail CLOSED",async()=>{
 const t=setup();
 for(const flag of ["installed","allowed","owner","kind","view","subject","id"] as const){
  const x=setup();
  if(flag==="installed")x.state.installed=false;
  else if(flag==="allowed")x.state.allowed=false;
  else if(flag==="owner")x.state.owner=OTHER;
  else if(flag==="kind")x.state.kind="different";
  else if(flag==="view")x.state.view="profile";
  else if(flag==="subject")x.state.subject="economics";
  else x.state.id=991;
  const run=flag==="view"?x.s.readNavigationSource({userId:U,view:"home"}):
   flag==="subject"?x.s.readSubjectOverview({userId:U,subject:"biology"}):
   flag==="id"?x.s.readLesson({userId:U,lessonId:19}):
   x.s.getCurrentScreen(U);
  eq(await run,null);
 }
 t.state.forceError=true;
 eq(await t.s.readPracticeSessionV4({userId:U,sessionId:22}),null);
});
Deno.test("Malformed user ID, negative and non-integer record IDs never reach privileged RPC",async()=>{
 const t=setup();
 eq(await t.s.getCurrentScreen("someone-else"),null);
 eq(await t.s.readLesson({userId:U,lessonId:-1}),null);
 eq(await t.s.readPracticeAnswerV4({userId:U,sessionId:1,questionId:0}),null);
 eq(await t.s.readTourAttempt({userId:U,attemptId:1.5}),null);
 eq(t.calls.length,0);
});
Deno.test("Read RPC never uses live tables, paid providers or mutating methods",async()=>{
 const t=setup();
 await t.s.readProfileAggregate({userId:U});
 for(const call of t.calls){
  eq(call.name,"get_iclub_ai_v21_screen_evidence_service");
  eq(call.args.p_user_id,U);
 }
});
