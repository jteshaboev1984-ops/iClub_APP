#!/usr/bin/env node
"use strict";
// Signed PostgREST JWT -> disposable PG17 P0-16B cutover: NO hosted resources.
const assert=require("node:assert/strict");
const crypto=require("node:crypto");
const path=require("node:path");
const {chromium}=require("playwright");
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
  headers["x-client-info"]="supabase-js-web/2"+(build?"; iclub.math/"+build:"");
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
// Real Chromium + real signed PostgREST and PostgreSQL 17. The request
// builder below is transport-compatible, not the official Supabase SDK.
// All backend responses and the P0-16B rejection come from actual PG17.
async function browserCutover(oldJwt,freshJwt){
  const before=fingerprint();
  const browser=await chromium.launch({headless:true});
  try{
    async function newPage(jwt,lang){
      const page=await browser.newPage({viewport:{width:390,height:844}});
      await page.route(HOST+"/",r=>r.fulfill({status:200,contentType:"text/html",
        body:'<!doctype html><html lang="'+lang+'"><body><main>Saving answer</main></body></html>'}));
      await page.goto(HOST+"/");
      await page.evaluate(({jwt,lang})=>{
        window.i18n={getLang:()=>lang};
        window.__p016bToken=jwt;
        window.__p016bSent=[];
        window.sb={rpc(name,args={}){
          const req={headers:{"x-client-info":"supabase-js-web/2"},
            then(resolve,reject){
              window.__p016bSent.push(req.headers["x-client-info"]);
              const headers={...req.headers,Authorization:"Bearer "+window.__p016bToken,
                "content-type":"application/json",Accept:"application/json"};
              return fetch("/rpc/"+name,{method:"POST",headers,body:JSON.stringify(args)})
                .then(async response=>{
                  const json=await response.json();
                  return response.ok?{data:json,error:null}:
                    {data:null,error:{code:json.code,message:json.message}};
                }).then(resolve,reject);
            }
          };
          return req;
        }};
      },{jwt,lang});
      await page.addScriptTag({path:path.resolve("exam-prep/exam-prep-api.js")});
      return page;
    }
    for(const lang of ["ru","uz","en"]){
      const page=await newPage(oldJwt,lang);
      try{
        const response=await page.evaluate(()=>window.iClubExamPrepHostInternal.api.submitResponse(
          "00000000-0000-4000-8000-000000000001",1,
          {artifact:{text:"Synthetic P1/P5 unsent written answer"}},
          "p016b-"+document.documentElement.lang,25,document.documentElement.lang));
        assert.equal(response.reason,"client_update_required","Old JWT must be denied in real Chromium");
        const ui=await page.evaluate(()=>{
          const notice=document.getElementById("math-p016b-stale-notice");
          const text=notice?.querySelector("textarea");
          return {role:notice?.getAttribute("role"),draft:text?.value,
            readonly:text?.readOnly,
            count:document.querySelectorAll("#math-p016b-stale-notice").length,
            headers:window.__p016bSent,
            url:location.href};
        });
        assert.equal(ui.role,"alertdialog");
        assert.equal(ui.draft,"Synthetic P1/P5 unsent written answer");
        assert.equal(ui.readonly,true);
        assert.equal(ui.count,1);
        assert.equal(ui.url,HOST+"/","No automatic reload on stale error");
        assert(ui.headers.length>=1&&ui.headers.every(h=>h?.includes("iclub.math/"+VERSION)),
          "Math-only marker must reach real PostgREST transport");
      } finally {await page.close();}
    }
    // Three real stale-browser refusals must not modify even the
    // synthetic owner history; only the subsequent fresh browser may write.
    assert.equal(fingerprint(),before,"Three rejected real browser writes preserved all history");
    const page=await newPage(freshJwt,"en");
    try{
      const saved=await page.evaluate(()=>window.iClubExamPrepHostInternal.api.saveExamProfile({
        examSeries:"June 2027",targetGrade:"A"
      }));
      assert.equal(saved.ok,true,"Matching fresh browser + signed JWT must save via real PG17");
      assert.equal(await page.locator("#math-p016b-stale-notice").count(),0);
      const sent=await page.evaluate(()=>window.__p016bSent);
      assert(sent.length>=1&&sent.every(h=>h?.includes("iclub.math/"+VERSION)));
    } finally {await page.close();}
  } finally {await browser.close();}
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
    await browserCutover(old,fresh);
    const accepted=await rpc("save_exam_prep_exam_profile_v2",profile,fresh,VERSION);
    assert(accepted.ok,"Fresh signed JWT + matching Math build must resume saved profile: "+
      JSON.stringify({status:accepted.status,error:accepted.data?.message}));
  }finally{
    if(activated)setGate();
  }
  assert.equal(sql("SELECT writer_min_jwt_iat IS NULL AND writer_client_contract IS NULL "+
    "FROM private.exam_prep_feature_config WHERE program_key='math_as_p1_p5'"),"t");
  console.log("P0-16B PASS: real signed old JWT and stale build denied; RU/UZ/EN Chromium copy recovery after form removal; safe projections; fresh browser writes; cutover resets OFF");
})().catch(err=>{console.error(err);process.exitCode=1;});
