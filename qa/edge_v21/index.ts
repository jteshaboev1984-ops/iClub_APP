// QA preview candidate ONLY, never deployed or imported by production.
// Manual Deno start must supply ICLUB_AI_V21_EXPLICIT_QA=isolated-preview-only.
// No provider is connected; unavailable v2 RPCs fail closed.
import {makeHttpHandler} from "./http.ts";
import {createQaEdgeCandidate} from "./runtime.ts";
import {createSupabaseServices} from "./supabase_services.ts";
import {makeContextCore} from "./context_core.ts";

const enabled=Deno.env.get("ICLUB_AI_V21_EXPLICIT_QA")==="isolated-preview-only";
const origin=Deno.env.get("ICLUB_AI_V21_QA_ORIGIN")||"";
let handler:((req:Request)=>Promise<Response>)|null=null;
if(enabled){
 try{
  if(!/^https:\/\/[^/]+$/.test(origin))throw Error("qa_origin_required");
  const services=createSupabaseServices({
   supabaseUrl:Deno.env.get("SUPABASE_URL")||"",
   anonKey:Deno.env.get("SUPABASE_ANON_KEY")||"",
   serviceRoleKey:Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")||""
  });
  const candidate=createQaEdgeCandidate(services as unknown as Record<string,unknown>,[origin]);
  const answerHandler=makeHttpHandler(candidate,[origin]);
  const contextHandler=makeHttpHandler(makeContextCore(services),[origin]);
  handler=(req:Request)=>{
   const url=new URL(req.url);
   if(url.pathname.endsWith("/context"))return contextHandler(req);
   if(url.pathname.endsWith("/answer"))return answerHandler(req);
   return Promise.resolve(new Response(JSON.stringify({
    ok:false,reason:"route_not_found"
   }),{status:404,headers:{"Content-Type":"application/json; charset=utf-8",
     "Cache-Control":"no-store"}}));
  };
 }catch{
  // Misconfigured preview MUST NOT launch an alternate unguarded route.
  handler=null;
 }
}
Deno.serve(async request=>{
 if(!handler)return new Response(JSON.stringify({
  ok:false,reason:"unavailable"
 }),{status:503,headers:{
  "Content-Type":"application/json; charset=utf-8","Cache-Control":"no-store"
 }});
 return handler(request);
});
