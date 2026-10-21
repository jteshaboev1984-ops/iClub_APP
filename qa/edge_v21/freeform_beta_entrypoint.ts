// iClub AI v2.1 Freeform Beta — separate additive Edge candidate only.
// This file is not imported from any production route or frontend today.
import {makeFreeformPilotHandler} from "./freeform_beta_pilot.ts";
Deno.serve(makeFreeformPilotHandler({
 url:Deno.env.get("SUPABASE_URL")||"",
 anon:Deno.env.get("SUPABASE_ANON_KEY")||"",
 service:Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")||"",
 providerKey:Deno.env.get("OPENAI_API_KEY")||"",
 // Even if an operator accidentally deploys this function, it stays OFF
 // until the separately controlled Edge flag AND database spending grant.
 enabled:Deno.env.get("ICLUB_AI_FREEFORM_BETA_EDGE_ENABLED")==="true",
 fetcher:fetch
}));
