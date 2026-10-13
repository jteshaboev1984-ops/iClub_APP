// QA-only Deno integration of exact proposed P8 RPC response shapes.
// Synthetic HTTP server only: no network access, credentials or live Supabase.
import {createSupabaseServices} from "./supabase_services.ts";
const id="11111111-1111-4111-8111-111111111111";
const requested:{name:string;payload:Record<string,unknown>}[]=[];
const cfg={supabaseUrl:"http://127.0.0.1:54321",
 anonKey:"synthetic-anon-only",serviceRoleKey:"synthetic-private-only",
 fetcher:(async(url:URL|string|Request,init?:RequestInit)=>{
  const name=String(url).split("/").at(-1)||"";
  const payload=init?.body?JSON.parse(String(init.body)):{};
  requested.push({name,payload});
  if(name==="get_iclub_ai_v21_runtime_service")
   return Response.json({ui_enabled:true,gateway_enabled:true,kill_switch:false,release_approved:true});
  if(name==="get_iclub_ai_v21_protected_service")return Response.json({protected:false});
  if(name==="get_iclub_ai_v21_rollout_service")return Response.json({allowed:true});
  if(name==="get_iclub_ai_v21_entitlement_service")
   return Response.json({allowed:true,usage_policy_code:"plus_qa_v2"});
  if(name==="get_iclub_ai_v21_provider_budget_service")
   return Response.json({allowed:false,reason:"provider_budget_not_authorized"});
  return Response.json({error:"not installed"},{status:404});
 }) as typeof fetch};
Deno.test("v2 read-only RPC wiring preserves independent runtime/cohort/policy/budget checks",async()=>{
 const s=createSupabaseServices(cfg);
 const r=await s.getGlobalState();
 if(!r.releaseApproved||!r.uiEnabled||!r.gatewayEnabled||r.killSwitch)
  throw Error("release flags incorrectly mapped");
 if(await s.isProtected(id))throw Error("clean learner marked protected");
 const context={surface:"lesson",subject:"biology",feature:"topic_explanation",topic:"lesson_12"};
 if(!await s.isRolloutAuthorized({userId:id,context}))throw Error("rollout denied");
 if(await s.getPolicy({userId:id})!=="plus_qa_v2")throw Error("wrong policy");
 if(await s.providerBudgetAllows({userId:id,sourceId:"approved-test-source",route:"generated"}))
  throw Error("unapproved provider budget bypassed");
 for(const n of ["get_iclub_ai_v21_runtime_service",
  "get_iclub_ai_v21_protected_service","get_iclub_ai_v21_rollout_service",
  "get_iclub_ai_v21_entitlement_service","get_iclub_ai_v21_provider_budget_service"])
  if(!requested.some(r=>r.name===n))throw Error("Missing RPC "+n);
 const rollout=requested.find(r=>r.name==="get_iclub_ai_v21_rollout_service");
 if(rollout?.payload.p_subject!=="biology"||rollout?.payload.p_topic!=="lesson_12")
  throw Error("Server-owned topic mapping lost");
});
