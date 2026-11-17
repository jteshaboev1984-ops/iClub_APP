#!/usr/bin/env node
"use strict";
/*
 * Actual Stage-ON Chromium acceptance against genuine finalized objective
 * evidence, owner-scoped JWT and real localhost PostgREST + PG17.
 */
const assert=require("node:assert/strict");
const crypto=require("node:crypto");
const {execFileSync}=require("node:child_process");
assert(process.env.CI==="true"&&process.env.P1P5_E2E_ISOLATED==="true"&&
  process.env.PGHOST==="127.0.0.1"&&process.env.PGDATABASE==="postgres"&&
  process.env.PGUSER==="postgres"&&process.env.P1P5_E2E_JWT_SECRET?.length>32,
  "REFUSED: only signed disposable PG17 runner");
const RUN="SV-P1P5-STAGEON-UI-01";
const sql=query=>execFileSync("psql",["-X","-At","-v","ON_ERROR_STOP=1","-c",query],{
  encoding:"utf8",env:{...process.env,PGOPTIONS:"-c iclub.e2e_isolated=true"}
}).trim();
const uid=sql("SELECT user_id::text FROM private.exam_prep_synthetic_identities WHERE "+
  "run_id='"+RUN+"' AND identity_kind='learner' AND identity_status='active'");
assert(/^[a-f0-9-]{36}$/.test(uid),"Real finalized-evidence owner not found");
const b64=x=>Buffer.from(JSON.stringify(x)).toString("base64url");
const now=Math.floor(Date.now()/1000);
const raw=b64({alg:"HS256",typ:"JWT"})+"."+b64({aud:"authenticated",
  role:"authenticated",sub:uid,iat:now,exp:now+1800});
const token=raw+"."+crypto.createHmac("sha256",
  process.env.P1P5_E2E_JWT_SECRET).update(raw).digest("base64url");
async function rpc(name,component){
  const response=await fetch("http://127.0.0.1:3000/rpc/"+name,{
    method:"POST",headers:{"Content-Type":"application/json",
      Authorization:"Bearer "+token},body:JSON.stringify({p_component_code:component})});
  let data=null;try{data=await response.json()}catch{}
  assert(response.ok,"Signed "+name+" HTTP "+response.status+" ("+component+")");
  return data;
}
(async()=>{
  try{
    // These two RPCs REBUILD state from finalized immutable evidence,
    // unlike earlier invalid tests that inserted skill state directly.
    for(const component of ["P1","P5"]){
      const state=await rpc("get_exam_prep_state_safe_v1",component);
      const item=(state.components||[]).find(x=>x.component_code===component);
      assert(item,"No source-authoritative component projection "+component);
      const stage=Number(item.operational_stage||0);
      if(component==="P1")assert.equal(stage,6,
        "Actual signed projection after rebuild must still be P1 Stage6");
      else assert(stage<5,
        "P5 independently blocked before Stage5 readiness "+stage);
      const status=await rpc("get_exam_prep_hybrid_s4_stage_status_safe_v1",component);
      assert.equal(status.enabled,true,"Stage ON must come from signed server");
      assert.equal(status.stage5_to_6?.ready,component==="P1",
        "Objective readiness must remain independent "+component);
      const cal=await rpc("get_exam_prep_final_calibration_safe_v1",component);
      assert.equal(cal.available,component==="P1",
        "P1 Stage6 only must unlock final calibration");
      assert.equal(cal.paper_marks_awarded,false,"Never award Paper marks");
    }
    await require("./p1p5-s4-stage-on-finalized-browser.cjs")(token);
    console.log("PASS final Stage-ON RU/UZ/EN signed Chromium on actual finalized objective Core evidence, no Paper grading");
  }finally{
    // This affects only disposable PG17, never toggles a real learner flag.
    sql("UPDATE private.exam_prep_hybrid_s4_config_v1 SET stage_gates_enabled=false WHERE singleton");
  }
})().catch(e=>{
  console.error("STAGE-ON VERIFIED ACTUAL-UI E2E FAIL:",e.stack||e);
  process.exitCode=1;
});
