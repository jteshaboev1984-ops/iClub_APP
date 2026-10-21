// iClub AI v2.1 Freeform Beta — separate additive Edge candidate only.
// This file is not imported from any production route or frontend today.
import {makeFreeformPilotHandler} from "./freeform_beta_pilot.ts";
Deno.serve(makeFreeformPilotHandler({
 url:Deno.env.get("SUPABASE_URL")||"",
 anon:Deno.env.get("SUPABASE_ANON_KEY")||"",
 service:Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")||"",
 providerKey:Deno.env.get("OPENAI_API_KEY")||"",
 // This isolated endpoint has NO independent payment authority. Until the
 // separate private.iclub_ai_v21_freeform_budget_control.enabled is true,
 // reserve/dispatch fail closed before ANY provider call. The DB switch is
 // the sole production activation/kill switch, rechecked at dispatch.
 enabled:true,
 fetcher:fetch
}));
