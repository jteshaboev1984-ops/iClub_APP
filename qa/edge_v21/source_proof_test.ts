import {createSupabaseServices} from "./supabase_services.ts";
const user="11111111-1111-4111-8111-111111111111";
const hash="a".repeat(64),origin="http://127.0.0.1:54321";
const eq=(a:unknown,b:unknown)=>{if(!Object.is(a,b))throw Error(JSON.stringify(a)+" != "+JSON.stringify(b))};
const ref={surface:"lesson",subject:"biology",feature:"topic_explanation",
 topic:"lesson_101",locale:"ru"};
function fixture(){
 let ready=true;
 const logs:Array<{url:string;body:Record<string,unknown>}>=[],
 payload={source_id:"synthetic-review-1",source_version:"v1",source_hash:hash};
 const fetcher=(async(url:string|URL|Request,init?:RequestInit)=>{
  const target=String(url),body=JSON.parse(String(init?.body||"{}"));
  logs.push({url:target,body});
  if(target.includes("get_iclub_ai_topic_release_service_v21"))
   return Response.json(ready?{ready:true,...ref,...payload,revision:4}:{ready:false});
  if(target.includes("get_iclub_ai_v21_source_proof_service"))
   return Response.json(ready?{approved:true,rights_approved:true,
    runtime_allowed:true,source_conflict:false,...payload}:{approved:false});
  if(target.includes("get_iclub_ai_v21_source_bundle_service"))
   return Response.json(ready?{
    approved:true,rights_approved:true,qa_passed:true,
    integrity_verified:true,runtime_allowed:true,source_conflict:false,
    ...payload,publication_revision:4,generation_allowed:false,source_text:"",
    prepared_variants:{explain_error:"Synthetic technical test response"}
   }:{approved:false});
  return Response.json({message:"unavailable"},{status:404});
 }) as typeof fetch;
 const s=createSupabaseServices({supabaseUrl:origin,anonKey:"synthetic-anon",
  serviceRoleKey:"synthetic-service",fetcher});
 return{s,logs,stop:()=>{ready=false}};
}
Deno.test("Source proof service RPC is based on exact topic/subject/locale",async()=>{
 const x=fixture(),p=await x.s.getLiveSourceProof(ref);
 eq(p.approved,true);eq(p.rightsApproved,true);eq(p.sourceConflict,false);
 eq(p.source_hash,hash);
 const call=x.logs.find(c=>c.url.includes("get_iclub_ai_v21_source_proof_service"));
 eq(call?.body?.p_subject,"biology");eq(call?.body?.p_topic,"lesson_101");
 eq(call?.body?.p_locale,"ru");
});
Deno.test("Approved source bundle returns only the requested prepared variant",async()=>{
 const x=fixture(),d=await x.s.getSourceBundle({userId:user,
  contextHandle:"synthetic-opaque-handle",locale:"ru",route:"prepared",
  promptKey:"explain_error",sourceId:"synthetic-review-1",sourceVersion:"v1",
  sourceHash:hash,revision:4});
 eq(d?.approved,true);eq(d?.integrityVerified,true);eq(d?.qaPassed,true);
 eq(d?.variants?.explain_error,"Synthetic technical test response");
 eq(d?.sourceText,"");
 const call=x.logs.find(c=>c.url.includes("get_iclub_ai_v21_source_bundle_service"));
 eq(call?.body?.p_user_id,user);eq(call?.body?.p_source_hash,hash);
 eq(call?.body?.p_publication_revision,4);
});
Deno.test("Revoking editorial publication closes readiness and bundle",async()=>{
 const x=fixture();x.stop();
 eq(await x.s.getPublishedRelease(ref),null);
 eq((await x.s.getLiveSourceProof(ref)).approved,false);
 eq(await x.s.getSourceBundle({userId:user,contextHandle:"opaque-handle",
  locale:"ru",route:"prepared",promptKey:"explain_error",
  sourceId:"synthetic-review-1",sourceVersion:"v1",sourceHash:hash,
  revision:4}),null);
});
Deno.test("No publisher/academic write RPC is called by technical source adapter",async()=>{
 const x=fixture();await x.s.getPublishedRelease(ref);
 await x.s.getLiveSourceProof(ref);
 const paths=x.logs.map(x=>x.url).join(" ");
 for(const illegal of ["publish_iclub","update_iclub","lesson_content_write",
 "practice_session_answers","tour_answers"])eq(paths.includes(illegal),false);
});
