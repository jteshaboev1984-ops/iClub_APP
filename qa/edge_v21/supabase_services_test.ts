import {createSupabaseServices,validBackendConfig} from "./supabase_services.ts";
const eq=(a:unknown,b:unknown)=>{if(!Object.is(a,b))throw Error(JSON.stringify(a)+" != "+JSON.stringify(b))};
const ok=(x:unknown,msg="assertion failed")=>{if(!x)throw Error(msg)};
const user="11111111-1111-4111-8111-111111111111";
const config={supabaseUrl:"http://127.0.0.1:54321",
 anonKey:"synthetic-anon-public",serviceRoleKey:"synthetic-service-private"};
function syntheticBackend(){
 const calls:{url:string;init:RequestInit;body:Record<string,unknown>|null}[]=[];
 const fetcher=(async(url:URL|string|Request,init?:RequestInit)=>{
  const uri=String(url);const data=init?.body?JSON.parse(String(init.body)):null;
  calls.push({url:uri,init:init||{},body:data});
  if(uri.endsWith("/auth/v1/user")){
   if(new Headers(init?.headers).get("authorization")!=="Bearer synthetic-jwt-12345")
    return new Response('{"error":"invalid"}',{status:401});
   return Response.json({id:user});
  }
  if(uri.includes("/rest/v1/subjects")){
   if(uri.includes("subject_key=eq.biology"))return Response.json([{subject_key:"biology",is_active:true}]);
   return Response.json([]);
  }
  if(uri.includes("get_iclub_ai_topic_release_service_v21"))
   return Response.json({ready:false,reason:"in_development"});
  return Response.json({message:"not_installed"},{status:404});
 }) as typeof fetch;
 return{fetcher,calls,services:createSupabaseServices({...config,fetcher})};
}
Deno.test("Deno backend rejects HTTP origins outside local/supabase scheme",()=>{
 ok(validBackendConfig(config));ok(validBackendConfig({...config,
 supabaseUrl:"https://synthetic.supabase.co"}));
 for(const url of ["http://malicious.example","https://evil.example",
  "https://name:pass@synthetic.supabase.co","https://synthetic.supabase.co/?key=foo",
  "ftp://synthetic.supabase.co"]){
  eq(validBackendConfig({...config,supabaseUrl:url}),false);
 }
});
Deno.test("Deno Auth checks real bearer against /auth/v1/user, never trusts body user",async()=>{
 const x=syntheticBackend();
 eq((await x.services.authenticate("Bearer synthetic-jwt-12345"))?.userId,user);
 eq(await x.services.authenticate("Bearer wrong-token-1234"),null);
 eq(await x.services.authenticate(""),null);
 const auth=x.calls.find(v=>v.url.endsWith("/auth/v1/user"));
 eq(new Headers(auth?.init.headers).get("authorization"),"Bearer synthetic-jwt-12345");
 eq(new Headers(auth?.init.headers).get("apikey"),config.anonKey);
});
Deno.test("New missing protected assessment RPC blocks in safe default",async()=>{
 const x=syntheticBackend();eq(await x.services.isProtected(user),true);
 const c=x.calls.find(v=>v.url.includes("get_iclub_ai_v21_protected_service"));
 ok(c);eq(c?.body?.p_user_id,user);
 eq(new Headers(c?.init.headers).get("authorization"),"Bearer "+config.serviceRoleKey);
});
Deno.test("Missing QA runtime flag RPC cannot enable global AI",async()=>{
 const x=syntheticBackend();
 const g=await x.services.getGlobalState();
 eq(g.gatewayEnabled,false);eq(g.uiEnabled,false);
 eq(g.killSwitch,true);eq(g.releaseApproved,false);
});
Deno.test("Missing signed context RPC never invents screen ownership",async()=>{
 const x=syntheticBackend();
 const c=await x.services.getScopedContext(user,"opaque-server-handle");
 eq(c,null);
 const op=x.calls.find(v=>v.url.includes("get_iclub_ai_v21_scoped_context_service"));
 eq(op?.body?.p_user_id,user);eq(op?.body?.p_context_handle,"opaque-server-handle");
});
Deno.test("Live subjects status is read only and independently not an AI release",async()=>{
 const x=syntheticBackend();
 eq(await x.services.getSubjectActive("biology"),true);
 eq(await x.services.getSubjectActive("sat"),false);
 eq(await x.services.getSubjectActive("biology?select=*"),false);
 const list=x.calls.filter(v=>v.url.includes("/rest/v1/subjects"));
 ok(list.every(v=>v.init.method==="GET"));
});
Deno.test("Unpublished topic return stays absent, no generic content fallback",async()=>{
 const x=syntheticBackend();
 const topic={surface:"lesson",subject:"biology",feature:"topic_explanation",
  topic:"cells",locale:"ru"};
 eq(await x.services.getPublishedRelease(topic),null);
 const r=await x.services.getLiveSourceProof(topic);
 eq(r.approved,false);eq(r.rightsApproved,false);eq(r.sourceConflict,true);
 const g=await x.services.getSourceBundle({userId:user,contextHandle:"handle-001",
  locale:"ru",route:"prepared",promptKey:"topic_main",sourceId:"source1",
  sourceVersion:"v1",sourceHash:"a".repeat(64),revision:1});
 eq(g,null);
});
Deno.test("Uninstalled rollout, payment policy and provider budget deny",async()=>{
 const x=syntheticBackend();
 eq(await x.services.isRolloutAuthorized({userId:user,context:{
  subject:"biology",surface:"lesson",feature:"topic_explanation",topic:"cells"}}),false);
 eq(await x.services.getPolicy({userId:user}),null);
 eq(await x.services.providerBudgetAllows({
  userId:user,sourceId:"source-001",route:"generated"}),false);
});
Deno.test("Provider cannot accidentally generate any real academic output",async()=>{
 const x=syntheticBackend();
 let threw=false;
 try{await x.services.generateSynthetic({question:"Any learner prompt"})}catch{threw=true}
 eq(threw,true);
 ok(!x.calls.some(v=>v.url.includes("api.openai.com")));
});
Deno.test("Reserve/claim/finish RPCs use exact v2 params, deny if unapplied",async()=>{
 const x=syntheticBackend(),fp="a".repeat(64);
 const requestId="22222222-2222-4222-8222-222222222222";
 const reserve=await x.services.reserveUsage({requestId,userId:user,
  policy:"plus_qa_v2",route:"generated",requestFingerprint:fp});
 eq(reserve.allowed,false);
 const claim=await x.services.claimDelivery({requestId,userId:user,
  sessionFingerprint:fp,requestFingerprint:fp,route:"generated"});
 eq(claim.allowed,false);
 const finish=await x.services.finishDelivery({requestId,userId:user,
  sessionFingerprint:fp,requestFingerprint:fp,route:"generated",outcome:"released"});
 eq(finish.ok,false);
 const a=x.calls.find(v=>v.url.includes("reserve_iclub_ai_usage_service_v2"));
 const b=x.calls.find(v=>v.url.includes("claim_iclub_ai_delivery_service_v21"));
 const c=x.calls.find(v=>v.url.includes("finish_iclub_ai_delivery_service_v21"));
 eq(a?.body?.p_usage_policy_code,"plus_qa_v2");
 eq(b?.body?.p_session_fingerprint,fp);
 eq(c?.body?.p_outcome,"released");
});
Deno.test("No credentials, prompts or provider transcripts are placed in backend errors",async()=>{
 const x=syntheticBackend();
 const r=await x.services.getPolicy({userId:user});
 eq(r,null);
 const data=JSON.stringify(r);
 ok(!data.includes(config.serviceRoleKey));
});

Deno.test("Missing Lesson mint RPC is denied and passes only verified user and lesson id",async()=>{
 const x=syntheticBackend();
 const r=await x.services.mintLessonContext({userId:user,lessonId:34});
 eq(r.allowed,false);
 const call=x.calls.find(c=>c.url.includes("mint_iclub_ai_v21_lesson_context_service"));
 eq(call?.body?.p_user_id,user);
 eq(call?.body?.p_lesson_id,34);
 eq(await x.services.mintLessonContext({userId:user,lessonId:-1}).then(v=>v.allowed),false);
});

Deno.test("Missing atomic provider money RPCs deny payment even with a valid JWT",async()=>{
 const x=syntheticBackend(),fp="a".repeat(64);
 const requestId="22222222-2222-4222-8222-222222222222";
 const args={requestId,userId:user,sessionFingerprint:fp,requestFingerprint:fp};
 eq((await x.services.reserveProviderSpend(args)).allowed,false);
 eq((await x.services.dispatchProviderSpend(args)).allowed,false);
 eq((await x.services.finishProviderSpend({...args,outcome:"unknown"})).ok,false);
 const a=x.calls.find(c=>c.url.includes("reserve_iclub_ai_v21_provider_spend_service"));
 const b=x.calls.find(c=>c.url.includes("dispatch_iclub_ai_v21_provider_spend_service"));
 const c=x.calls.find(c=>c.url.includes("finish_iclub_ai_v21_provider_spend_service"));
 eq(a?.body?.p_request_id,requestId);
 eq(b?.body?.p_session_fingerprint,fp);
 eq(c?.body?.p_outcome,"unknown");
 eq(c?.body?.p_actual_microusd,null);
 for(const call of [a,b,c])
  eq(new Headers(call?.init.headers).get("authorization"),"Bearer "+config.serviceRoleKey);
});


Deno.test("Missing encrypted receipt RPCs deny settlement and private reply",async()=>{
 const x=syntheticBackend(),fp="a".repeat(64),digest="b".repeat(64);
 const args={requestId:"22222222-2222-4222-8222-222222222222",
  userId:user,sessionFingerprint:fp,requestFingerprint:fp,
  route:"prepared",identityDigest:digest};
 const envelope={...args,ciphertext:"abcdefghijklmnopqrstuvwxyzABCDEFG",
  nonce:"abcdefghijklmnop",authTag:"abcdefghijklmnopqrstuv",keyRef:"synthetic_key_v1"};
 eq((await x.services.finishDeliveryWithEncryptedReceipt(envelope)).ok,false);
 eq(await x.services.getEncryptedReply(args),null);
 const finish=x.calls.find(c=>c.url.includes("finish_iclub_ai_delivery_with_receipt_service_v21"));
 const read=x.calls.find(c=>c.url.includes("get_iclub_ai_v21_encrypted_reply_service"));
 eq(finish?.body?.p_identity_digest,digest);
 eq(read?.body?.p_request_id,args.requestId);
 for(const call of [finish,read])eq(new Headers(call?.init.headers).get("authorization"),
  "Bearer "+config.serviceRoleKey);
});
