#!/usr/bin/env node
"use strict";
// Signed PostgREST JWT -> disposable PG17 P0-16B cutover: NO hosted resources.
const assert=require("node:assert/strict");
const crypto=require("node:crypto");
const {execFileSync}=require("node:child_process");
const HOST="http://127.0.0.1:3000";
const ID="11111111-1111-4111-8111-111111111191";
const KEY=process.env.P1P5_E2E_JWT_SECRET;
const VERSION="math-p1p5-p016b-v1";
assert(process.env.CI==="true" && process.env.P1P5_E2E_ISOLATED==="true" &&
  process.env.PGHOST==="127.0.0.1" && process.env.PGPORT==="5432" &&
  process.env.PGDATABASE==="postgres" && KEY?.length>=32,
  "REFUSED: this test must run in an ephemeral signed PG17 GitHub Actions job");
function sql(query){
  return execFileSync("psql",["-X","-At","-v","ON_ERROR_STOP=1","-c",query],
    {encoding:"utf8",env:{...process.env,PGOPTIONS:"-c iclub.e2e_isolated=true"}}).trim();
}
function setGate({iat=null,build=null}={}){
  assert(iat===null||Number.isInteger(iat));
  assert(build===null||build===VERSION);
  // Always fail closed if this is not the exact synthetic identity sandbox.
  const time=iat===null?"NULL":String(iat),label=build===null?"NULL":"'"+build+"'";
  sql("DO $guard$ BEGIN IF current_database()<>'postgres' "+
    "OR current_setting('iclub.e2e_isolated',true)<>'true' "+
    "OR NOT EXISTS(SELECT 1 FROM auth.users WHERE id='"+ID+"'::uuid) "+
    "OR (SELECT count(*) FROM auth.users)<>2 "+
    "THEN RAISE EXCEPTION 'P0-16B not disposable two-user PG17'; END IF; "+
    "UPDATE private.exam_prep_feature_config SET writer_min_jwt_iat="+time+
    ",writer_client_contract="+label+" WHERE program_key='math_as_p1_p5'; END $guard$;");
}
const e=obj=>Buffer.from(JSON.stringify(obj)).toString("base64url");
function token(iat){
  const part=e({alg:"HS256",typ:"JWT"})+"."+e({role:"authenticated",aud:"authenticated",
    sub:ID,iat,exp:Math.floor(Date.now()/1000)+1800});
  return part+"."+crypto.createHmac("sha256",KEY).update(part).digest("base64url");
}
async function rpc(name,args,access,build){
  const headers={"content-type":"application/json","accept":"application/json",
    Authorization:"Bearer "+access};
  if(build)headers["x-iclub-math-writer-build"]=build;
  const res=await fetch(HOST+"/rpc/"+name,{method:"POST",headers,body:JSON.stringify(args||{})});
  const body=await res.text();
  let data;try{data=JSON.parse(body);}catch{data=null;}
  return {status:res.status,ok:res.ok,data};
}
const profile={p_exam_series:"June 2027",p_target_grade:"A",
  p_total_student_hours_available:null,p_mathematics_hours_budget:null};
const fingerprint=()=>sql("SELECT md5((SELECT coalesce(string_agg(id::text||':'||xmin::text,'|' "+
  "ORDER BY id::text),'') FROM private.exam_prep_sessions WHERE user_id='"+ID+"'::uuid)||'/'||"+
  "(SELECT coalesce(string_agg(user_id::text||':'||xmin::text,'|' ORDER BY user_id::text),'') "+
  "FROM private.exam_prep_exam_profiles WHERE user_id='"+ID+"'::uuid))");
async function blocked(name,args,auth,build,reason){
  const result=await rpc(name,args,auth,build);
  assert(!result.ok && result.data?.code==="42501" &&
    /exam_prep_writer_contract_stale/.test(result.data?.message||""),
    reason+" should be refused before any mutation (HTTP "+result.status+")");
}
(async()=>{
  // Fail closed preflight: require the exact two synthetic users and DISABLED
  // guard before touching even the disposable config row.
  assert.equal(sql("SELECT count(*) FROM auth.users"),"2");
  assert.equal(sql("SELECT writer_min_jwt_iat IS NULL AND writer_client_contract IS NULL "+
    "FROM private.exam_prep_feature_config WHERE program_key='math_as_p1_p5'"),"t");
  const now=Math.floor(Date.now()/1000);
  const old=token(now-360),fresh=token(now);
  let activated=false;
  try{
    setGate({iat:now-120,build:VERSION});activated=true;
    const before=fingerprint();
    await blocked("save_exam_prep_exam_profile_v2",profile,old,VERSION,"signed older JWT");
    await blocked("save_exam_prep_exam_profile_v2",profile,fresh,null,"refreshed JWT with cached old JS");
    await blocked("submit_exam_prep_response_safe_v1",{
      p_session_id:"00000000-0000-4000-8000-000000000001",p_item_order:1,
      p_payload:{answer:"NO WRITE"},p_idempotency_key:"p016b-stale",
      p_elapsed_ms:0,p_language:"en"},fresh,null,"old JS direct Paper response");
    assert.equal(fingerprint(),before,"Rejected old tabs must leave sessions/profile unchanged");
    // Stale getters can read persisted projections, but MUST NOT rebuild them.
    const stateFingerprint=sql("SELECT md5(coalesce(string_agg(component_code||':'||xmin::text,'|' "+
      "ORDER BY component_code),'')) FROM private.exam_prep_stage_states "+
      "WHERE user_id='"+ID+"'::uuid");
    await rpc("get_exam_prep_state_safe_v1",{p_component_code:"P1"},old,null);
    await rpc("get_exam_prep_placement_safe_v1",{p_component_code:"P1"},fresh,null);
    await rpc("get_exam_prep_diagnostic_progress_safe_v1",{p_component_code:"P5"},fresh,null);
    assert.equal(sql("SELECT md5(coalesce(string_agg(component_code||':'||xmin::text,'|' "+
      "ORDER BY component_code),'')) FROM private.exam_prep_stage_states "+
      "WHERE user_id='"+ID+"'::uuid"),stateFingerprint,
      "stale token/build getters must not rewrite Stage projections");
    assert.equal(fingerprint(),before,"Stale getter must not modify owned history");
    const accepted=await rpc("save_exam_prep_exam_profile_v2",profile,fresh,VERSION);
    assert(accepted.ok,"Fresh signed JWT + matching Math build must resume saved profile: "+
      JSON.stringify({status:accepted.status,error:accepted.data?.message}));
  }finally{
    if(activated)setGate();
  }
  assert.equal(sql("SELECT writer_min_jwt_iat IS NULL AND writer_client_contract IS NULL "+
    "FROM private.exam_prep_feature_config WHERE program_key='math_as_p1_p5'"),"t");
  console.log("P0-16B PASS: signed old JWT denied; refreshed JWT with cached old build denied; unchanged P1/P5 history; safe stale getters; fresh compatible client resumes; opt-in OFF");
})().catch(err=>{console.error(err);process.exitCode=1;});
