// Deno-native bridge to previously tested CommonJS core, QA-only.
// This module MUST remain outside supabase/functions until separate Edge-runtime
// compatibility review; no production or beta route imports it.
import {createRequire} from "node:module";
import type {Core} from "./http.ts";
const require=createRequire(import.meta.url);
const moduleValue=require("../ai-layer-v21-edge-request.cjs") as {
 CandidateEdgeRequest:new(args:{services:Record<string,unknown>;allowedOrigins:string[]})=>Core
};
export function createQaEdgeCandidate(services:Record<string,unknown>,allowedOrigins:string[]):Core{
 return new moduleValue.CandidateEdgeRequest({services,allowedOrigins});
}
