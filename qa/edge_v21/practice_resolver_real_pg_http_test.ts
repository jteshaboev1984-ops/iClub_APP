// Genuine loopback HTTP -> Auth shim -> real disposable PostgreSQL resolver.
// Synthetic tokens are NOT signed JWTs; never claim real-production Auth testing.
import {createSupabaseServices} from "./supabase_services.ts";
import {createQaLocalPracticeResolver} from "./practice_resolver_service.ts";
import {makeContextCore} from "./context_core.ts";
import {makeHttpHandler} from "./http.ts";
const base=Deno.env.get("ICLUB_QA_BACKEND_URL")||"";
const origin=Deno.env.get("ICLUB_QA_ORIGIN")||"";
const anon=Deno.env.get("ICLUB_QA_ANON")||"";
const key=Deno.env.get("ICLUB_QA_ROLE")||"";
const A="11111111-1111-4111-8111-111111111111";
const B="22222222-2222-4222-8222-222222222222";
const authA="Bearer qa-local-user-a",authB="Bearer qa-local-user-b";
const assert=(x:unknown,msg:string)=>{if(!x)throw Error(msg);};
if(!base.startsWith("http://127.0.0.1:")||
   origin!=="https://preview.synthetic.invalid")
 throw Error("QA resolver HTTP tests only on synthetic localhost");
const cfg={supabaseUrl:base,anonKey:anon,serviceRoleKey:key};
const appSvc=createSupabaseServices(cfg);
const serverResolver=createQaLocalPracticeResolver(cfg);
const handler=makeHttpHandler(makeContextCore({...appSvc,...serverResolver}),[origin]);
const send=async(token:string,body:Record<string,unknown>,site=origin)=>{
 const reply=await handler(new Request(origin+"/context",{
  method:"POST",
  headers:{origin:site,authorization:token,"content-type":"application/json"},
  body:JSON.stringify(body)
 }));
 return {status:reply.status,body:await reply.json() as Record<string,unknown>};
};
const resolve=(token:string,attemptReference:number,questionId:number)=>
 send(token,{action:"resolvePracticeV4",attemptReference,questionId});
const control=async(action:string)=>{
 const r=await fetch(base+"/__qa/control",{
  method:"POST",
  headers:{"content-type":"application/json","x-local-qa-test":"only-synthetic"},
  body:JSON.stringify({action})
 });
 assert(r.ok,"Local scratch control rejected "+action);
};
Deno.test("Local HTTP Auth A resolves 99/901 into canonical V4 session 900; no answer keys",async()=>{
 const ok=await resolve(authA,99,901);
 assert(ok.status===200&&ok.body.ok===true,
  "Verified own canonical V4 selector failed "+JSON.stringify(ok));
 assert(ok.body.sessionId===900&&ok.body.questionId===901,"Exact selector expected");
 const raw=JSON.stringify(ok.body);
 for(const key of ["user_id","correct_answer","user_answer","score","is_correct","source_text"]){
  assert(!raw.includes(key),"Academic/private field leaked: "+key);
 }
 assert(Object.keys(ok.body).length===5,"Only strictly whitelisted output");
});
Deno.test("Foreign Auth B, active session, missing question and forged user ID denied",async()=>{
 for(const args of [
   [authB,99,901],[authA,100,911],[authA,99,902],[authA,101,921]
 ] as const){
  const result=await resolve(...args);
  assert(result.status===200&&result.body.ok===false,
   "Unsafe selector accepted "+JSON.stringify(args));
 }
 assert((await send(authA,{action:"resolvePracticeV4",attemptReference:99,
  questionId:901,userId:B})).status===400,"Forged owner not rejected");
 assert((await resolve("Bearer invalid-user-qa",99,901)).status===401,
  "Invalid JWT substitute accepted");
 assert((await send(authA,{action:"resolvePracticeV4",attemptReference:99,
  questionId:901},"https://foreign.invalid")).status===403,
  "Wrong origin accepted");
});
Deno.test("Authenticated browser cannot call service-role SQL directly",async()=>{
 const direct=await fetch(base+
  "/rest/v1/rpc/resolve_iclub_ai_v21_practice_attempt_service",{
   method:"POST",
   headers:{"apikey":anon,authorization:authA,"content-type":"application/json"},
   body:JSON.stringify({p_user_id:A,p_attempt_reference:99,p_question_id:901})
 });
 assert(direct.status===401,"Direct PostgREST caller unexpectedly privileged");
});
Deno.test("Resolver is not an answer: mint and source release still require separate grants",async()=>{
 const match=await resolve(authA,99,901);
 assert(match.body.ok===true,"Initial verified mapping unavailable");
 const mint=await send(authA,{action:"mint",sessionId:900,questionId:901});
 assert(mint.body.ok===false,"Resolver unexpectedly granted mint");
 const source=await appSvc.getPublishedRelease({
  surface:"practice",subject:"economics",feature:"answer_explanation",
  topic:"demand",locale:"ru"
 });
 assert(source===null,"Unapproved source was marked published");
});
Deno.test("New protected assessment blocks even read-only resolution",async()=>{
 await control("protect_a");
 const r=await resolve(authA,99,901);
 assert(r.body.ok===false,"Protected assessment resolved");
 await control("unprotect_a");
});
Deno.test("Revoked enrollment and kill switch prevent lookup; no fallback",async()=>{
 await control("unenroll_a");
 assert((await resolve(authA,99,901)).body.ok===false,"Revoked subject access");
 await control("reenroll_a");
 await control("kill");
 assert((await resolve(authA,99,901)).body.ok===false,"Kill switch bypass");
});
