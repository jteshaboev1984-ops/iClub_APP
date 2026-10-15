// QA ONLY. Separate additional proposed Practice resolver RPC contract.
// This module is never imported by production, Vercel Preview or Math Tutor.
// Runs ONLY against isolated localhost backend; no remote Supabase accepted.
import type {BackendConfig} from "./supabase_services.ts";
import {validBackendConfig} from "./supabase_services.ts";
type Json=Record<string,unknown>;
const UUID=/^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
const positive=(n:unknown):n is number=>typeof n==="number"&&Number.isSafeInteger(n)&&n>0;
const deny=()=>({ok:false,reason:"server_verification_required"});
export const PRACTICE_V4_RESOLVER_RPC=
  "resolve_iclub_ai_v21_practice_attempt_service" as const;
export function createQaLocalPracticeResolver(config:BackendConfig){
 if(!validBackendConfig(config))throw Error("unsafe_resolver_backend");
 const url=new URL(config.supabaseUrl);
 if(url.protocol!=="http:"||
   !["localhost","127.0.0.1"].includes(url.hostname))
   throw Error("QA resolver only accepts a local scratch backend");
 const root=url.origin;
 const fetcher=config.fetcher??fetch;
 const serviceRoleKey=config.serviceRoleKey;
 return {
  async resolvePracticeV4({userId,attemptReference,questionId}:{
   userId:string;attemptReference:number;questionId:number
  }):Promise<Json>{
   if(!UUID.test(userId||"")||!positive(attemptReference)||!positive(questionId))
    return deny();
   let response:Response;
   try{
    response=await fetcher(root+"/rest/v1/rpc/"+PRACTICE_V4_RESOLVER_RPC,{
     method:"POST",
     redirect:"error",
     signal:AbortSignal.timeout(8000),
     headers:{
      "Content-Type":"application/json",
      apikey:serviceRoleKey,
      Authorization:"Bearer "+serviceRoleKey
     },
     body:JSON.stringify({
      p_user_id:userId,
      p_attempt_reference:attemptReference,
      p_question_id:questionId
     })
    });
   }catch{return deny();}
   if(!response.ok)return deny();
   let result:unknown;
   try{result=await response.json();}
   catch{return deny();}
   const raw=(result!==null&&typeof result==="object"&&!Array.isArray(result))
    ?result as Json:null;
   if(!raw||raw.ok!==true||raw.kind!=="server_resolved_practice_v4"||
      raw.attemptReference!==attemptReference||raw.questionId!==questionId||
      !positive(raw.sessionId))return deny();
   // Strict response whitelist, no academic answers/ownership/score leak.
   return {
    ok:true,kind:"server_resolved_practice_v4",
    attemptReference,questionId,sessionId:raw.sessionId
   };
  }
 };
}
