"use strict";
// §103: deterministic fail-closed real function SOURCE drift gate.
// Does not connect to Supabase. Caller must obtain rows via audited
// read-only pg_proc metadata query, never from browser or learner data.
const manifest=require("./ai-layer-v21-p6-live-commercial-catalog-snapshot.json");
const deny=reason=>Object.freeze({matched:false,releaseAllowed:false,reason});
function verifyCommercialCatalog(rows){
 if(!Array.isArray(rows)||rows.length!==2)return deny("function_set_changed");
 const seen=new Set(),expected=new Map(manifest.functions.map(x=>[x.name,x]));
 if(manifest.guardOnDrift!=="NO_GO_REVIEW_REQUIRED"||
  manifest.liveReleaseAllowed!==false||expected.size!==2)
  return deny("manifest_untrusted");
 for(const row of rows){
  if(!row||typeof row!=="object"||Array.isArray(row))
   return deny("malformed_catalog");
  if(row.schema!=="public"||!expected.has(row.name)||seen.has(row.name))
   return deny("function_set_changed");
  seen.add(row.name);
  const exact=expected.get(row.name);
  if(row.identity_args!==exact.identityArgs||
    row.definition_md5!==exact.definitionMd5)
   return deny("source_definition_changed");
 }
 return Object.freeze({matched:true,metadataOnly:true,
  revisionDate:manifest.capturedOn,releaseAllowed:false,
  requiresIndependentAuthorization:true});
}
module.exports={verifyCommercialCatalog};
