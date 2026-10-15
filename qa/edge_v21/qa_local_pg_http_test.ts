// §120-123: REAL localhost HTTP and real disposable PostgreSQL RPC.
// Tokens are synthetic string identities verified by the local Auth shim,
// NOT genuine signed JWTs. No production Supabase or provider calls.
import {createSupabaseServices} from "./supabase_services.ts";
import {makeContextCore} from "./context_core.ts";
import {makeHttpHandler} from "./http.ts";
const base=Deno.env.get("ICLUB_QA_BACKEND_URL")||"";
const anon=Deno.env.get("ICLUB_QA_ANON")||"";
const key=Deno.env.get("ICLUB_QA_ROLE")||"";
const origin=Deno.env.get("ICLUB_QA_ORIGIN")||"";
const A="11111111-1111-4111-8111-111111111111";
const B="22222222-2222-4222-8222-222222222222";
const TA="Bearer qa-local-user-a",TB="Bearer qa-local-user-b";
const assert=(v:unknown,msg:string)=>{if(!v)throw Error(msg);};
const svc=createSupabaseServices({supabaseUrl:base,anonKey:anon,serviceRoleKey:key});
const handler=makeHttpHandler(makeContextCore(svc),[origin]);
const send=async(token:string,input:Record<string,unknown>,site=origin)=>{
 const response=await handler(new Request(origin+"/context",{
  method:"POST",headers:{origin:site,authorization:token,"content-type":"application/json"},
  body:JSON.stringify(input)
 }));
 return {status:response.status,data:await response.json() as Record<string,unknown>,
  headers:response.headers};
};
const control=async(action:string)=>{
 const response=await fetch(base+"/__qa/control",{method:"POST",
  headers:{"content-type":"application/json","x-qa-local-control":"synthetic-control-secret"},
  body:JSON.stringify({action})});
 assert(response.ok,"Synthetic control failed: "+action);
};
let ha="",hb="";
Deno.test("§120 actual local HTTP Auth -> real PG mint and independent owners",async()=>{
 const one=await send(TA,{action:"mint",sessionId:900,questionId:901});
 const two=await send(TB,{action:"mint",sessionId:910,questionId:911});
 assert(one.status===200&&one.data.ok===true,"A own failed "+JSON.stringify(one.data));
 assert(two.status===200&&two.data.ok===true,"B own failed "+JSON.stringify(two.data));
 ha=String(one.data.contextHandle);hb=String(two.data.contextHandle);
 assert(ha.length===36&&hb.length===36&&ha!==hb,"handles not distinct");
 assert((await send(TA,{action:"mint",sessionId:910,questionId:911})).data.ok===false,"A foreign Practice");
 assert((await send(TB,{action:"mint",sessionId:900,questionId:901})).data.ok===false,"B foreign Practice");
 assert((await svc.getScopedContext(A,ha))?.ownerId===A,"A live context failed");
 assert((await svc.getScopedContext(B,hb))?.ownerId===B,"B live context failed");
 assert((await svc.getScopedContext(B,ha))===null,"B stole A context");
 assert((await svc.getScopedContext(A,hb))===null,"A stole B context");
});
Deno.test("§121 actual Tour SQL and no separate release/provider spending",async()=>{
 const tour=await send(TA,{action:"mintTourArchive",tourAttemptId:401});
 assert(tour.data.ok===true,"A own tour denied "+JSON.stringify(tour.data));
 assert((await send(TB,{action:"mintTourArchive",tourAttemptId:401})).data.ok===false,
 "B borrowed A tour");
 const live=await svc.getGlobalState();
 assert(live.releaseApproved===false,"synthetic release became approved");
 assert(await svc.providerBudgetAllows({userId:A,sourceId:"synthetic",route:"practice"})===false,
 "provider budget incorrectly authorized");
 assert((await send(TA,{action:"mint",sessionId:900,questionId:901,userId:B})).status===400,
 "client forged owner");
 const invalid=await send("Bearer invalid-user",{action:"mint",sessionId:900,questionId:901});
 assert(invalid.status===401,"fake identity bypassed Auth");
 assert((await send(TA,{action:"mint",sessionId:900,questionId:901},"https://foreign.invalid")).status===403,
 "foreign origin bypassed");
});
Deno.test("§122 direct client invocation of PostgreSQL RPC denied and user revocation is fresh",async()=>{
 const direct=await fetch(base+"/rest/v1/rpc/mint_iclub_ai_v21_practice_context_service",{
  method:"POST",headers:{"apikey":anon,"authorization":TA,"content-type":"application/json"},
  body:JSON.stringify({p_user_id:A,p_session_id:900,p_question_id:901})
 });
 assert(direct.status===401,"learner directly reached privileged SQL");
 await control("unenroll_a");
 assert((await svc.getScopedContext(A,ha))===null,"revoked enrolment didn't block A");
 assert((await svc.getScopedContext(B,hb))?.ownerId===B,
 "A enrollment revocation must not remove B context");
});
Deno.test("§123 protected exam, JWT revocation and kill switch block new access",async()=>{
 await control("exam_b");
 const blocked=await send(TB,{action:"mint",sessionId:910,questionId:911});
 assert(blocked.data.ok===false,"protected B practice permitted");
 await control("revoke_a");
 assert((await send(TA,{action:"mint",sessionId:900,questionId:901})).status===401,
  "revoked A token accepted");
 await control("kill");
 const dead=await send(TB,{action:"mint",sessionId:910,questionId:911});
 assert(dead.data.ok===false,"global kill failed");
 assert((await svc.getGlobalState()).killSwitch===true,"runtime did not report kill");
 assert((await svc.providerBudgetAllows({userId:B,sourceId:"synthetic",route:"practice"}))===false,
  "provider available after kill");
});
