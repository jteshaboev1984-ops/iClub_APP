// No Deno permissions required: all HTTP is in-memory and all principals synthetic.
import {makeContextCore} from "./context_core.ts";
import {makeHttpHandler} from "./http.ts";
import {createQaLocalPracticeResolver} from "./practice_resolver_service.ts";
const A="11111111-1111-4111-8111-111111111111";
const B="22222222-2222-4222-8222-222222222222";
const O="https://preview.synthetic.invalid";
const assert=(x:unknown,msg:string)=>{if(!x)throw Error(msg);};
function fixture(){
 const calls:{userId:string;attemptReference:number;questionId:number}[]=[];
 let record:Record<string,unknown>|null=null;
 let throwRpc=false;
 let user=A;
 const services={
  authenticate:async (token:string)=>
   token==="Bearer qa-test-identity-a"?{authenticated:true,userId:user}:null,
  mintScopedContext:async()=>({allowed:false}),
  mintLessonContext:async()=>({allowed:false}),
  mintTourArchiveContext:async()=>({allowed:false}),
  mintAppViewContext:async()=>({allowed:false}),
  revokeScopedContext:async()=>({ok:false}),
  resolvePracticeV4:async(args:{userId:string;attemptReference:number;questionId:number})=>{
   calls.push(args);
   if(throwRpc)throw Error("DB private SQL exception with secret keys");
   return args.userId===A?(record??{ok:false,reason:"server_verification_required"}):{ok:false,reason:"server_verification_required"};
  }
 };
 const http=makeHttpHandler(makeContextCore(services),[O]);
 const send=async(data:unknown,opts:{origin?:string;authorization?:string}={})=>{
  const response=await http(new Request(O+"/context",{
   method:"POST",
   headers:{
    origin:opts.origin??O,
    authorization:opts.authorization??"Bearer qa-test-identity-a",
    "content-type":"application/json"
   },
   body:JSON.stringify(data)
  }));
  return {status:response.status,
   body:await response.json() as Record<string,unknown>};
 };
 return{calls,send,allow:()=>{record={
   ok:true,kind:"server_resolved_practice_v4",
   attemptReference:99,questionId:901,sessionId:900,
   user_id:A,correctAnswer:"DO_NOT_LEAK",score:100,source:"UNRELEASED"
 };},fail:()=>{throwRpc=true;},setUser:(u:string)=>{user=u;}};
}
Deno.test("Authenticated /context resolves only verified canonical V4 selectors",async()=>{
 const x=fixture();x.allow();
 const response=await x.send({
  action:"resolvePracticeV4",attemptReference:99,questionId:901
 });
 assert(response.status===200&&response.body.ok===true,"Verified resolver must succeed");
 assert(JSON.stringify(response.body)===JSON.stringify({
  ok:true,kind:"server_resolved_practice_v4",
  attemptReference:99,questionId:901,sessionId:900
 }),"Only exact non-sensitive selector fields allowed");
 assert(x.calls.length===1&&x.calls[0].userId===A,"Must use Auth-derived owner");
});
Deno.test("Wrong JWT, origin, foreign owner never reaches a successful resolution",async()=>{
 const x=fixture();x.allow();
 assert((await x.send({action:"resolvePracticeV4",attemptReference:99,questionId:901},
  {authorization:"Bearer bad-credential"})).status===401,"Invalid bearer");
 assert((await x.send({action:"resolvePracticeV4",attemptReference:99,questionId:901},
  {origin:"https://another.invalid"})).status===403,"Origin spoof");
 assert(x.calls.length===0,"No privileged call before origin + Auth");
 x.setUser(B);
 const r=await x.send({action:"resolvePracticeV4",attemptReference:99,questionId:901});
 assert(x.calls[0].userId===B,"Browser must not override JWT owner");
 assert(r.body.ok===false,"Foreign learner cannot receive another owner's mapping");
});
Deno.test("Extra client-provided ownership, subject, score or session blocked before RPC",async()=>{
 const x=fixture();x.allow();
 const data={action:"resolvePracticeV4",attemptReference:99,questionId:901};
 for(const add of [
  {userId:A},{owner_id:A},{isFinal:true},{answer:"yes"},{correctAnswer:"yes"},
  {sessionId:900},{sourceHash:"a".repeat(64)},{subject:"biology"},
  {topic:"cell_division"},{verified:true},{plan:"plus"},{action:"mint"},
  {view:"courses"},{locale:"ru"},{protected:false}
 ]){
  const r=await x.send({...data,...add});
  assert(r.status===400,"Unexpected forged field accepted: "+JSON.stringify(add));
 }
 assert(x.calls.length===0,"Rejected requests must never reach service-role RPC");
});
Deno.test("Invalid numeric IDs and wrong input types fail closed",async()=>{
 const x=fixture();x.allow();
 for(const input of [
  {attemptReference:0,questionId:901},
  {attemptReference:-1,questionId:901},
  {attemptReference:"99",questionId:901},
  {attemptReference:99,questionId:"901"},
  {attemptReference:99,questionId:0},
  {attemptReference:99,questionId:3.2},
  {attemptReference:99,questionId:Number.MAX_SAFE_INTEGER+1}
 ]){
  const r=await x.send({action:"resolvePracticeV4",...input});
  assert(r.status===400,"Unsafe selectors: "+JSON.stringify(input));
 }
 assert(x.calls.length===0,"Invalid selectors cannot reach service role");
});
Deno.test("Unavailable function and private DB exception fail closed without secret leakage",async()=>{
 const x=fixture();
 const empty=await x.send({action:"resolvePracticeV4",attemptReference:99,questionId:901});
 assert(empty.body.ok===false,"Absent RPC fails closed");
 x.fail();
 const broken=await x.send({action:"resolvePracticeV4",attemptReference:99,questionId:901});
 assert(broken.status===503&&broken.body.ok===false,"Broken backend should be unavailable");
 assert(!JSON.stringify(broken).includes("private SQL"),"Private exception text must not leak");
});
Deno.test("Local-only resolver refuses all hosted URLs and wrong key configurations",()=>{
 for(const endpoint of [
   "https://foo.supabase.co","https://another.invalid",
   "http://outside.invalid","http://127.0.0.1:54321/other"
 ]){
  let denied=false;
  try{createQaLocalPracticeResolver({
   supabaseUrl:endpoint,anonKey:"qa-synthetic-anon",
   serviceRoleKey:"qa-synthetic-service"
  });}catch{denied=true;}
  assert(denied,"Resolver accepted remote or non-root backend: "+endpoint);
 }
});
Deno.test("Service role is used only server side; outputs cannot leak sensitive RPC fields",async()=>{
 const history:{uri:string;init:RequestInit}[]=[];
 const fetcher=(async(uri:URL|string|Request,init?:RequestInit)=>{
  history.push({uri:String(uri),init:init||{}});
  return Response.json({ok:true,kind:"server_resolved_practice_v4",
    attemptReference:99,questionId:901,sessionId:900,
    user_answer:"PRIVATE",correct_answer:"DO_NOT_RETURN",score:100,
    actual_user_id:B});
 }) as typeof fetch;
 const r=createQaLocalPracticeResolver({
  supabaseUrl:"http://127.0.0.1:54321/",
  anonKey:"qa-anon-only-test",serviceRoleKey:"qa-role-only-test",fetcher
 });
 const answer=await r.resolvePracticeV4({userId:A,attemptReference:99,questionId:901});
 assert(answer.ok===true&&answer.sessionId===900,"Checked exact canonical ID");
 assert(!JSON.stringify(answer).includes("PRIVATE"),"No key leakage");
 assert(Object.keys(answer).length===5,"Strict whitelist");
 assert(history.length===1&&history[0].uri.endsWith(
  "/rest/v1/rpc/resolve_iclub_ai_v21_practice_attempt_service"),"Exact endpoint");
 const headers=new Headers(history[0].init.headers);
 assert(headers.get("authorization")==="Bearer qa-role-only-test","Trusted service role only");
 const body=JSON.parse(String(history[0].init.body));
 assert(JSON.stringify(body)===JSON.stringify({
  p_user_id:A,p_attempt_reference:99,p_question_id:901
 }),"Only whitelisted selector RPC body");
 assert(history[0].init.redirect==="error","No redirects with keys");
});
Deno.test("Unrecognized metadata or failed PostgREST never authorizes",async()=>{
 for(const result of [
  {ok:true,kind:"server_resolved_practice_v4",attemptReference:100,questionId:901,sessionId:900},
  {ok:true,kind:"server_resolved_practice_v4",attemptReference:99,questionId:902,sessionId:900},
  {ok:true,kind:"server_resolved_practice_v4",attemptReference:99,questionId:901,sessionId:"900"},
  {ok:true,kind:"wrong",attemptReference:99,questionId:901,sessionId:900},
  {ok:false,attemptReference:99,questionId:901,sessionId:900}
 ]){
  const fetcher=(async()=>Response.json(result)) as typeof fetch;
  const r=createQaLocalPracticeResolver({
   supabaseUrl:"http://localhost:54321/",
   anonKey:"qa-anon-only-test",serviceRoleKey:"qa-role-only-test",fetcher
  });
  assert((await r.resolvePracticeV4({userId:A,attemptReference:99,questionId:901})).ok===false,
   "Invalid RPC proof accepted "+JSON.stringify(result));
 }
});
