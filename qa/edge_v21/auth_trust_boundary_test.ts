// §119 synthetic HTTP Auth -> owner-bound service RPC. No real network/JWT.
import {createSupabaseServices} from "./supabase_services.ts";
import {makeContextCore} from "./context_core.ts";
import {makeHttpHandler} from "./http.ts";
const A="11111111-1111-4111-8111-111111111111";
const B="22222222-2222-4222-8222-222222222222";
const H_A="33333333-3333-4333-8333-333333333333";
const H_B="44444444-4444-4444-8444-444444444444";
const TA="Bearer qa-user-a-synthetic",TB="Bearer qa-user-b-synthetic";
const ORIGIN="https://preview.synthetic.invalid",ANON="qa-anon-synthetic",ROLE="qa-service-synthetic";
type Seen={path:string;method:string;authorization:string;apikey:string;body:Record<string,unknown>|null};
const ok=(v:unknown,msg:string)=>{if(!v)throw Error(msg)};
function fixture(){
 const calls:Seen[]=[],revoked=new Set<string>(),contexts=new Map<string,string>();
 let offline=false,badRole=false,badId=false;
 const fetcher=async(url:RequestInfo|URL,options?:RequestInit):Promise<Response>=>{
  const path=String(url),headers=new Headers(options?.headers);
  const auth=headers.get("Authorization")||"";
  const body=options?.body?JSON.parse(String(options.body)) as Record<string,unknown>:null;
  calls.push({path,method:options?.method||"",authorization:auth,
   apikey:headers.get("apikey")||"",body});
  if(path.endsWith("/auth/v1/user")){
   const id=auth===TA?A:auth===TB?B:null;
   if(offline)return Response.json({error:"offline"},{status:503});
   if(!id||revoked.has(auth))return Response.json({error:"invalid"},{status:401});
   return Response.json({id:badId?"bad-uuid":id,role:badRole?"service_role":"authenticated"});
  }
  if(path.endsWith("/rest/v1/rpc/mint_iclub_ai_v21_practice_context_service")){
   const uid=body?.p_user_id,session=body?.p_session_id,question=body?.p_question_id;
   const allowed=(uid===A&&session===900&&question===901)||
    (uid===B&&session===910&&question===911);
   const handle=uid===A?H_A:H_B;
   if(allowed)contexts.set(handle,String(uid));
   return Response.json({allowed,context_handle:allowed?handle:null,expires_in_seconds:90});
  }
  if(path.endsWith("/rest/v1/rpc/revoke_iclub_ai_v21_scoped_context_service")){
   const handle=String(body?.p_context_handle);
   const allowed=contexts.get(handle)===body?.p_user_id;
   if(allowed)contexts.delete(handle);
   return Response.json({ok:allowed});
  }
  return Response.json({allowed:false},{status:404});
 };
 const services=createSupabaseServices({supabaseUrl:"http://127.0.0.1:54321",
  anonKey:ANON,serviceRoleKey:ROLE,fetcher:fetcher as typeof fetch});
 const handler=makeHttpHandler(makeContextCore(services),[ORIGIN]);
 const send=async(token:string,body:Record<string,unknown>,origin=ORIGIN)=>{
  const resp=await handler(new Request(ORIGIN+"/context",{method:"POST",
   headers:{origin,"content-type":"application/json",authorization:token},
   body:JSON.stringify(body)}));
  return{status:resp.status,body:await resp.json() as Record<string,unknown>,headers:resp.headers};
 };
 return{send,calls,contexts,revoked,
  offline:(v:boolean)=>{offline=v},badRole:(v:boolean)=>{badRole=v},badId:(v:boolean)=>{badId=v}};
}
const validate=(calls:Seen[])=>{
 const auth=calls.filter(x=>x.path.endsWith("/auth/v1/user"));
 const rpc=calls.filter(x=>x.path.includes("/rest/v1/rpc/"));
 ok(auth.length>0,"no Auth validation");
 ok(auth.every(x=>x.method==="GET"&&x.apikey===ANON&&
  x.authorization!==("Bearer "+ROLE)&&x.body===null),"unsafe Auth request");
 ok(rpc.every(x=>x.method==="POST"&&x.apikey===ROLE&&
  x.authorization==="Bearer "+ROLE),"user JWT leaked into privileged RPC");
};
Deno.test("§119 two synthetic tokens isolate Practice and client cannot set owner",async()=>{
 const f=fixture();
 ok((await f.send(TA,{action:"mint",sessionId:900,questionId:901})).body.ok===true,"A");
 ok((await f.send(TB,{action:"mint",sessionId:910,questionId:911})).body.ok===true,"B");
 ok((await f.send(TA,{action:"mint",sessionId:910,questionId:911})).body.ok===false,"A foreign");
 ok((await f.send(TB,{action:"mint",sessionId:900,questionId:901})).body.ok===false,"B foreign");
 for(const extra of [{userId:B},{role:"service_role"},{plan:"plus"},{subject:"biology"}]){
  const n=f.calls.filter(x=>x.path.includes("/rest/v1/rpc/")).length;
  const r=await f.send(TA,{action:"mint",sessionId:900,questionId:901,...extra});
  ok(r.status===400,"forged browser field accepted");
  ok(f.calls.filter(x=>x.path.includes("/rest/v1/rpc/")).length===n,"forgery reached RPC");
 }
 validate(f.calls);
});
Deno.test("§119 foreign revocation and expired JWT deny before privileged RPC",async()=>{
 const f=fixture();
 ok((await f.send(TA,{action:"mint",sessionId:900,questionId:901})).body.ok===true,"mint");
 ok((await f.send(TB,{action:"revoke",contextHandle:H_A})).body.ok===false,"stolen revoke");
 ok(f.contexts.has(H_A),"foreign owner revoked");
 ok((await f.send(TA,{action:"revoke",contextHandle:H_A})).body.ok===true,"own revoke");
 f.revoked.add(TA);
 const n=f.calls.filter(x=>x.path.includes("/rest/v1/rpc/")).length;
 ok((await f.send(TA,{action:"mint",sessionId:900,questionId:901})).status===401,"revoked JWT");
 ok(f.calls.filter(x=>x.path.includes("/rest/v1/rpc/")).length===n,"revoked reached RPC");
 validate(f.calls);
});
Deno.test("§119 Auth outage, bad role/UUID, foreign Origin and invalid token deny",async()=>{
 const f=fixture();
 ok((await f.send(TA,{action:"mint",sessionId:900,questionId:901},
 "https://evil.invalid")).status===403,"foreign origin");
 ok((await f.send("Bearer wrong-synthetic",{action:"mint",sessionId:900,questionId:901})).status===401,"bad token");
 f.offline(true);
 ok((await f.send(TA,{action:"mint",sessionId:900,questionId:901})).status===401,"auth outage");
 f.offline(false);f.badRole(true);
 ok((await f.send(TA,{action:"mint",sessionId:900,questionId:901})).status===401,"privileged role");
 f.badRole(false);f.badId(true);
 ok((await f.send(TA,{action:"mint",sessionId:900,questionId:901})).status===401,"bad uuid");
 ok(!f.calls.some(x=>x.path.includes("/rest/v1/rpc/")),"invalid auth reached RPC");
});
Deno.test("§119 responses do not expose JWT, service key or anon key",async()=>{
 const f=fixture();
 for(const [token,body] of [[TA,{action:"mint",sessionId:900,questionId:901}],
 [TB,{action:"mint",sessionId:900,questionId:901}],
 ["Bearer wrong-synthetic",{action:"mint",sessionId:900,questionId:901}]] as const){
  const r=await f.send(token,body);
  const contents=JSON.stringify(r.body);
  ok(![ANON,ROLE,TA,TB].some(x=>contents.includes(x)),"secret echoed");
  ok(r.headers.get("cache-control")==="no-store, max-age=0","response cached");
 }
 validate(f.calls);
});
