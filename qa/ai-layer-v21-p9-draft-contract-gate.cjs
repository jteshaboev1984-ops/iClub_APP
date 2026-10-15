"use strict";
const {readFileSync}=require("node:fs");
const {join}=require("node:path");
const root=join(__dirname,"..");
const manifest=require("./ai-layer-v21-p9-rpc-draft-manifest.json");
const snapshot=require("./ai-layer-v21-p9-live-metadata-readonly-snapshot.json");
const policyBaseline=require("./ai-layer-v21-p9-policy-fingerprint-snapshot.json");
const load=path=>readFileSync(join(root,path),"utf8");
function verifyDraftContracts({drafts=manifest,live=snapshot,policies=policyBaseline,
 adapter=load("qa/edge_v21/supabase_services.ts"),
 evidence=load("qa/edge_v21/screen_proof_services.ts"),overrides={}}={}){
 const errors=[];
 const issue=(code,name)=>errors.push({code,name});
 if(drafts?.schema!=="iclub_ai_v21_p9_draft_contract_bundle_v1"||
  drafts.status!=="UNAPPLIED_QA_CANDIDATE"||drafts.releaseAllowed!==false||
  drafts.noProductionDatabaseWrites!==true||
  drafts.requiresIndependentOwnerApproval!==true||
  drafts.requiresProductionCompatibilityReview!==true||
  !Array.isArray(drafts.stages)||!Array.isArray(drafts.contracts))
  return {matched:false,status:"NO_GO",releaseAllowed:false,errors:[{code:"UNTRUSTED_MANIFEST"}]};
 const rpcCalls=[...adapter.matchAll(/\brpc\("([a-z][a-z0-9_]+)"/g)].map(x=>x[1]);
 const indirect=[...evidence.matchAll(/\bconst\s+KIND\s*=\s*"(get_iclub_ai_v21_[a-z0-9_]+)"/g)].map(x=>x[1]);
 if(indirect.length!==1)issue("INDIRECT_RPC_DRIFT","screen proof");
 rpcCalls.push(...indirect);rpcCalls.sort();
 const catalog=drafts.contracts.map(x=>x.name);
 if(rpcCalls.length!==24||new Set(rpcCalls).size!==24||
  JSON.stringify(rpcCalls)!==JSON.stringify(catalog)||
  JSON.stringify(catalog)!==JSON.stringify(live.expectedRpcContracts))
  issue("RPC_INVENTORY_DRIFT","Edge adapter");
 const locations=new Map();
 for(const [i,s] of drafts.stages.entries()){
  if(!/^qa\/sql_drafts\/[a-z0-9_]+_UNAPPLIED\.sql$/.test(s.path)||
   locations.has(s.path))issue("BAD_DRAFT_LOCATION",s.path);
  locations.set(s.path,i);
 }
 if(locations.size!==10)issue("DRAFT_COUNT_DRIFT","expected ten files");
 const declarations=new Map(),sqlFiles=new Map();
 for(const stage of drafts.stages){
  if(!locations.has(stage.path))continue;
  if(!Array.isArray(stage.dependsOn)||
   new Set(stage.dependsOn).size!==stage.dependsOn.length||
   stage.dependsOn.some(p=>!locations.has(p)||locations.get(p)>=locations.get(stage.path)))
   issue("DEPENDENCY_DRIFT",stage.path);
  let sql;
  try{sql=Object.prototype.hasOwnProperty.call(overrides,stage.path)?
   overrides[stage.path]:load(stage.path);}
  catch{issue("DRAFT_MISSING",stage.path);continue;}
  sqlFiles.set(stage.path,sql);
  const guard=sql.search(/current_database\s*\(\s*\)\s*!~\s*'\^iclub_ai_v21_scratch_/i);
  const write=sql.search(/\b(?:create\s+(?:or\s+replace\s+)?(?:schema|table|function)|alter\s+table|insert\s+into)\b/i);
  if(guard<0||write<0||guard>write)issue("SCRATCH_BOUNDARY_DRIFT",stage.path);
  const pattern=/\bcreate\s+(?:or\s+replace\s+)?function\s+public\.([a-z0-9_]+)\s*\(([^)]*)\)\s*returns/gi;
  for(const m of sql.matchAll(pattern)){
   if(declarations.has(m[1]))issue("DUPLICATE_DECLARATION",m[1]);
   const args=m[2].trim()===""?[]:m[2].split(",").map(raw=>{
    const a=/^\s*(p_[a-z0-9_]+)\s+(uuid|text|bigint)(?:\s+default\s+null)?\s*$/i.exec(raw);
    return a?{name:a[1],type:a[2]}:null;
   });
   declarations.set(m[1],{path:stage.path,args,start:m.index});
  }
 }
 for(const c of drafts.contracts){
  if(!c||c.caller!=="trusted_service_role_only"||
   !/^qa\/sql_drafts\/[a-z0-9_]+_UNAPPLIED\.sql$/.test(c.draft)||
   !Array.isArray(c.args)){issue("BAD_CONTRACT",String(c?.name));continue;}
  const row=declarations.get(c.name);
  if(!row||row.path!==c.draft){issue("RPC_DRAFT_MISSING",c.name);continue;}
  if(JSON.stringify(row.args)!==JSON.stringify(c.args))issue("RPC_SIGNATURE_DRIFT",c.name);
  const sql=sqlFiles.get(c.draft);
  if(!sql)continue;
  const tail=sql.slice(row.start);
  // Never scan through a malformed function into a later function's safe
  // search_path: the AS delimiter must occur in THIS declaration header.
  const opening=/\bas\s+\$[a-z0-9_]*\$/i.exec(tail.slice(0,550));
  const header=opening?tail.slice(0,opening.index):"";
  if(!/\bsecurity\s+definer\b/i.test(header)||!/\bset\s+search_path\s*=\s*''/i.test(header))
   issue("UNSAFE_DEFINER_CONTEXT",c.name);
  const rev=[...sql.matchAll(/\brevoke\s+all\s+on\s+function\s+public\.([a-z0-9_]+)\s*\(([^)]*)\)\s+from\s+([^;]+);/gi)].filter(m=>m[1]===c.name);
  const grant=[...sql.matchAll(/\bgrant\s+execute\s+on\s+function\s+public\.([a-z0-9_]+)\s*\(([^)]*)\)\s+to\s+([^;]+);/gi)].filter(m=>m[1]===c.name);
  const signature=c.args.map(a=>a.type).join(",");
  const matchTypes=m=>m[2].replace(/\s+/g,"").toLowerCase()===signature;
  const revOk=rev.length===1&&matchTypes(rev[0])&&
   ["public","anon","authenticated"].every(role=>
    rev[0][3].toLowerCase().split(",").map(s=>s.trim()).includes(role));
  const grantOk=grant.length===1&&matchTypes(grant[0])&&
   grant[0][3].trim().toLowerCase()==="service_role";
  if(!revOk||!grantOk)issue("RPC_EXECUTION_GRANTS_DRIFT",c.name);
  if(c.name==="get_iclub_ai_v21_screen_evidence_service"){
   if(!indirect.includes(c.name)||c.args.some(arg=>!evidence.includes(arg.name+":")))
    issue("INDIRECT_RPC_ARGUMENT_DRIFT",c.name);
   continue;
  }
  const needle='rpc("'+c.name+'",';
  const at=adapter.indexOf(needle);
  if(at<0){issue("RPC_EDGE_MISSING",c.name);continue;}
  const tailCall=adapter.slice(at+needle.length,at+needle.length+1100);
  const end=tailCall.indexOf("})");
  const payload=end<0?tailCall:tailCall.slice(0,end);
  if(c.args.some(arg=>!payload.includes(arg.name+":")))
   issue("RPC_ARGUMENT_NAME_DRIFT",c.name);
 }
 if(policies?.schema!=="iclub_ai_v21_live_rls_expression_metadata_v1"||
  policies.releaseAllowed!==false||policies.metadataOnly!==true||
  !Array.isArray(policies.policies)||policies.policies.length!==7||
  new Set(policies.policies.map(p=>p.table+"."+p.policy)).size!==7||
  policies.policies.some(p=>p.schema!=="public"||
   !/^[a-f0-9]{32}$/.test(p.expressionMd5)||
   !["owner_auth_uid","public_catalog"].includes(p.semantic)))
  issue("RLS_METADATA_DRIFT","Recheck pg_policy without user rows");
 return {matched:errors.length===0,status:"NO_GO",releaseAllowed:false,
  localDraftCount:drafts.stages.length,rpcContractCount:drafts.contracts.length,
  requiresLiveSecurityReview:true,errors};
}
module.exports={verifyDraftContracts};
if(require.main===module){
 const result=verifyDraftContracts();
 process.stdout.write(JSON.stringify(result,null,2)+"\n");
 if(!result.matched)process.exitCode=1;
}
