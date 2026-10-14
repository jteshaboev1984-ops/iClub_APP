// Deno-native bridge to previously tested CommonJS core, QA-only.
// This module MUST remain outside supabase/functions until separate Edge-runtime
// compatibility review; no production or beta route imports it.
import {createRequire} from "node:module";
import type {Core} from "./http.ts";
const require=createRequire(import.meta.url);
const moduleValue=require("../ai-layer-v21-edge-request.cjs") as {
 CandidateEdgeRequest:new(args:{services:Record<string,unknown>;allowedOrigins:string[];admission?:{check(args:Record<string,unknown>):Promise<Record<string,unknown>>}})=>Core
};
const trusted=require("../ai-layer-v21-trusted-server-adapter.cjs") as {
 TrustedAppWideServerAdapter:new(services:Record<string,unknown>)=>{
  check(args:Record<string,unknown>):Promise<Record<string,unknown>>
 }
};
export function createQaEdgeCandidate(services:Record<string,unknown>,allowedOrigins:string[]):Core{
 const admission=new trusted.TrustedAppWideServerAdapter(services);
 return new moduleValue.CandidateEdgeRequest({services,allowedOrigins,admission});
}
