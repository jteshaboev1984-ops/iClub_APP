#!/usr/bin/env node
"use strict";
/*
 * Issue #450 / owner 2026-11-16: P1/P5 handwritten Papers remain ungraded.
 * Positive Stage3 -> Stage6 operational reader AND trigger acceptance.
 * Signed JWT -> real HTTP PostgREST -> isolated PostgreSQL17 only.
 * The artificial skill/placement ledger below is an explicit CI-only fixture,
 * NOT proof of real student mastery or Cambridge method marking.
 *
 * Use a THIRD disposable identity so existing S4/S3/S2 tests remain untouched.
 */
const assert=require("node:assert/strict");
const crypto=require("node:crypto");
const {execFileSync}=require("node:child_process");
assert(process.env.CI==="true" && process.env.P1P5_E2E_ISOLATED==="true" &&
  process.env.PGHOST==="127.0.0.1" && process.env.PGDATABASE==="postgres" &&
  process.env.PGUSER==="postgres",
  "REFUSED: signed positive stage test requires disposable GitHub PG17");
const secret=process.env.P1P5_E2E_JWT_SECRET;
assert(secret && secret.length>32,"isolated ephemeral signing secret required");
const C="33333333-3333-4333-8333-333333333393";
const b64=(x)=>Buffer.from(JSON.stringify(x)).toString("base64url");
const t=Math.floor(Date.now()/1000);
const raw=b64({alg:"HS256",typ:"JWT"})+"."+b64({
  aud:"authenticated",sub:C,role:"authenticated",iat:t,exp:t+1200});
const jwt=raw+"."+crypto.createHmac("sha256",secret).update(raw).digest("base64url");
function sql(q){
  return execFileSync("psql",["-X","-At","-v","ON_ERROR_STOP=1","-c",q],{
    encoding:"utf8",env:process.env}).trim();
}
async function rpc(name,args={},token=jwt){
  const response=await fetch("http://127.0.0.1:3000/rpc/"+name,{
    method:"POST",headers:{"Content-Type":"application/json",Accept:"application/json",
      ...(token?{Authorization:"Bearer "+token}:{})},body:JSON.stringify(args)});
  let data=null;
  try{data=await response.json()}catch{}
  return {ok:response.ok,status:response.status,data};
}
function ok(response,context){
  assert(response.ok,context+" HTTP "+response.status+" "+JSON.stringify(response.data).slice(0,240));
  return response.data;
}
function expectStage(stage,expected,context){
  assert.equal(stage.ready,expected,context+": "+JSON.stringify(stage));
}
function stageSql(code){
  return sql("SELECT operational_stage::text FROM private.exam_prep_stage_states "+
    "WHERE user_id='"+C+"'::uuid AND component_code='"+code+"'");
}
async function status(component){
  return ok(await rpc("get_exam_prep_hybrid_s4_stage_status_safe_v1",
    {p_component_code:component}),component+" signed stage status");
}
function assertNoGrade(stage){
  assert.equal(stage.stage5_to_6.app_readiness_estimate,"INSUFFICIENT_EVIDENCE");
  assert.equal(stage.stage5_to_6.full_paper_grade,null);
  assert.equal(stage.stage5_to_6.verified_written_method_marks,null);
  assert.equal(stage.stage5_to_6.mentor_required,false);
  assert.equal(stage.stage5_to_6.ai_required,false);
  assert.equal(stage.full_papers_recommended_not_required,true);
  assert.equal(stage.self_scoring,false);
  assert.equal(stage.stage3_to_4.paper_rehearsal_is_academic_evidence,false);
  assert.equal(stage.stage4_to_5.full_papers_required_for_access,false);
  assert.equal(stage.stage5_to_6.full_papers_required_for_access,false);
}
async function main(){
  const originalFlags=sql("SELECT paper_enabled::text||'/'||stage_gates_enabled::text "+
    "FROM private.exam_prep_hybrid_s4_config_v1 WHERE singleton");
  assert(originalFlags==="true/false"||originalFlags==="false/false",
    "existing isolated S4 stage gates must be OFF before this test: "+originalFlags);
  const legacyBefore=sql("SELECT (SELECT count(*) FROM private.exam_prep_timed_attempt_results)::text||'/'||"+
    "(SELECT count(*) FROM public.practice_attempts)::text||'/'||"+
    "(SELECT count(*) FROM public.tour_attempts)::text||'/'||"+
    "(SELECT count(*) FROM public.certificates)::text");
  // This identity never exists in production or in the two-learner signed tests.
  assert.equal(sql("SELECT count(*) FROM auth.users WHERE id='"+C+"'::uuid"),"0");
  sql("INSERT INTO auth.users(id,aud,role,email) VALUES('"+C+
    "','authenticated','authenticated','math-stage-positive@localhost.invalid')");
  sql("INSERT INTO public.users(id,first_name,last_name,language_code) VALUES('"+
    C+"','Synthetic','Stage Evidence','en')");
  sql("INSERT INTO private.exam_prep_feature_entitlements "+
    "(user_id,entitlement_status,core_access,ai_assist,mentor_care_entitled,valid_from) "+
    "VALUES('"+C+"','active',true,false,false,now()-interval '1 minute')");
  // Beta entitlements are still the source of authorization; never introduce
  // a new subject-access bypass or a global QA-open flag.
  if(sql("SELECT to_regclass('public.user_subjects') IS NOT NULL")==="t"){
    sql("INSERT INTO public.user_subjects(user_id,subject_id,mode) "+
      "SELECT '"+C+"'::uuid,5,'study' WHERE EXISTS "+
      "(SELECT 1 FROM public.subjects WHERE id=5 AND subject_key='mathematics') "+
      "ON CONFLICT DO NOTHING");
  }
  ok(await rpc("save_exam_prep_exam_profile_v2",{
    p_exam_series:"May/June 2027",p_target_grade:"A",
    p_total_student_hours_available:12,p_mathematics_hours_budget:6
  }),"third learner's signed exam profile");
  const program=sql("SELECT program_version_id FROM private.exam_prep_exam_profiles "+
    "WHERE user_id='"+C+"'");
  const engine=sql("SELECT engine_version FROM private.exam_prep_state_engine_versions "+
    "WHERE status='active' ORDER BY activated_at DESC NULLS LAST,created_at DESC LIMIT 1");
  const keyRule=sql("SELECT rule_version FROM private.exam_prep_stage3_exit_rules "+
    "WHERE status='active' LIMIT 1");
  const placement=sql("SELECT rule_version FROM private.exam_prep_placement_rule_versions "+
    "WHERE status='active' LIMIT 1");
  assert(/^\d+$/.test(program) && engine && keyRule && placement,
    "real active governed program/engine/rule versions required");
  assert.equal(sql("SELECT count(*) FROM private.exam_prep_timed_attempt_results "+
    "WHERE user_id='"+C+"'"),"0","no Paper score rows before synthetic evidence");
  const disabled=await status("P1");
  assert.equal(disabled.enabled,false);
  assert.equal(disabled.no_stage_change,true);
  // No stage credit from an empty learner, even when stage reader is enabled.
  sql("UPDATE private.exam_prep_hybrid_s4_config_v1 SET stage_gates_enabled=true "+
    "WHERE singleton");
  let empty=await status("P1");
  expectStage(empty.stage3_to_4,false,"empty learner Stage3");
  expectStage(empty.stage4_to_5,false,"empty learner Stage4");
  expectStage(empty.stage5_to_6,false,"empty learner Stage5");
  // Build only synthetic objective levels: P1 all L3; P5 all covered L2
  // with its explicitly governed key skills L3. No Paper session or mark.
  sql("INSERT INTO private.exam_prep_skill_states "+
    "(user_id,program_version_id,component_code,skill_code,engine_version,"+
    "objective_level,coverage_confirmed) "+
    "SELECT '"+C+"'::uuid,n.program_version_id,n.component_code,n.skill_code,'"+
    engine+"', CASE WHEN n.component_code='P1' OR EXISTS ("+
    "SELECT 1 FROM private.exam_prep_stage3_key_skills k "+
    "WHERE k.rule_version='"+keyRule+"' AND k.program_version_id=n.program_version_id "+
    "AND k.component_code=n.component_code AND k.skill_code=n.skill_code) "+
    "THEN 3 ELSE 2 END,true "+
    "FROM private.exam_prep_syllabus_nodes n WHERE n.program_version_id="+program+
    " AND n.component_code IN ('P1','P5')");
  assert.equal(sql("SELECT count(*) FROM private.exam_prep_skill_states "+
    "WHERE user_id='"+C+"'"),"81","exact 45 P1 + 36 P5 objective state fixture");
  for(const code of ["P1","P5"]){
    const legacy=sql("SELECT private.exam_prep_stage3_exit_status_v1('"+
      C+"'::uuid,"+program+",'"+code+"')->>'reason_code'");
    assert.equal(legacy,"full_baseline_missing",
      "old stage comparator must remain intact (no Paper marks) "+code);
  }
  let p1=await status("P1");
  let p5=await status("P5");
  expectStage(p1.stage3_to_4,true,"P1 completed objective Stage3");
  expectStage(p1.stage4_to_5,true,"P1 all L3 means corrections satisfied");
  expectStage(p1.stage5_to_6,true,"P1 full objective L3 + closed corrections");
  expectStage(p5.stage3_to_4,true,"P5 separate complete coverage/key L3");
  expectStage(p5.stage4_to_5,false,"P5 below-L3 skills require governed corrections");
  expectStage(p5.stage5_to_6,false,"P5 cannot borrow P1 all-L3 result");
  assertNoGrade(p1);
  assertNoGrade(p5);
  // Adversarial negative: deliberately lower one governed P1 key-skill.
  const p1Key=sql("SELECT skill_code FROM private.exam_prep_stage3_key_skills "+
    "WHERE program_version_id="+program+" AND rule_version='"+keyRule+
    "' AND component_code='P1' ORDER BY skill_code LIMIT 1");
  assert(p1Key,"governed P1 key registry must be nonempty");
  sql("UPDATE private.exam_prep_skill_states SET objective_level=2 WHERE user_id='"+
    C+"' AND component_code='P1' AND skill_code='"+p1Key+"'");
  let wrong=await status("P1");
  expectStage(wrong.stage3_to_4,false,"P1 key L3 removed");
  assert.equal(wrong.stage3_to_4.reason_code,"key_l3_incomplete");
  expectStage(wrong.stage4_to_5,false,"unearned Stage4 must stay locked");
  expectStage(wrong.stage5_to_6,false,"unearned Stage5 must stay locked");
  sql("UPDATE private.exam_prep_skill_states SET objective_level=3 WHERE user_id='"+
    C+"' AND component_code='P1' AND skill_code='"+p1Key+"'");
  // A covered-syllabus hole must also fail, independently of method marks.
  sql("UPDATE private.exam_prep_skill_states SET coverage_confirmed=false "+
    "WHERE user_id='"+C+"' AND component_code='P1' AND skill_code='"+p1Key+"'");
  wrong=await status("P1");
  expectStage(wrong.stage3_to_4,false,"P1 missing coverage");
  assert.equal(wrong.stage3_to_4.reason_code,"coverage_incomplete");
  sql("UPDATE private.exam_prep_skill_states SET coverage_confirmed=true "+
    "WHERE user_id='"+C+"' AND component_code='P1' AND skill_code='"+p1Key+"'");
  // Actual PostgreSQL stage trigger: a synthetic, completed Stage0
  // dependency is explicitly seeded; WITHOUT this it must stay locked.
  for(const [component,required,areas] of [["P1",24,8],["P5",15,5]]){
    sql("INSERT INTO private.exam_prep_component_placements "+
      "(user_id,program_version_id,component_code,rule_version,placement_status,route,"+
      "profile_complete,content_ready,screening_required_items,screening_required_areas,"+
      "screening_answered_items,screening_answered_areas,prerequisite_blocker_count,"+
      "stage0_complete,route_reason) VALUES('"+C+"',"+program+",'"+component+"','"+
      placement+"','confirmed','foundation',true,true,"+required+","+areas+","+
      required+","+areas+",0,true,'synthetic isolated Stage0 test fixture') "+
      "ON CONFLICT(user_id,program_version_id,component_code,rule_version) DO UPDATE "+
      "SET stage0_complete=true,prerequisite_blocker_count=0");
    sql("INSERT INTO private.exam_prep_component_access_gates "+
      "(user_id,program_version_id,component_code,rule_version,"+
      "current_operational_stage,max_unlocked_stage,placement_access,"+
      "foundation_learning_access,advanced_route_access,gate_status,gate_reason) "+
      "VALUES('"+C+"',"+program+",'"+component+"','"+placement+
      "',0,1,true,true,false,'stage0_complete','synthetic Stage0') "+
      "ON CONFLICT(user_id,program_version_id,component_code,rule_version) DO UPDATE "+
      "SET current_operational_stage=0,max_unlocked_stage=1,gate_status='stage0_complete'");
    const total=component==="P1"?45:36;
    const l3=component==="P1"?45:7;
    const l2=total-l3;
    const note="'Synthetic objective evidence in disposable PG17; no Cambridge Paper marks'";
    sql("INSERT INTO private.exam_prep_stage_states "+
      "(user_id,program_version_id,component_code,engine_version,denominator_count,"+
      "l0_count,l1_count,l2_count,l3_count,coverage_count,coverage_pct,app_readiness_reason) "+
      "VALUES('"+C+"',"+program+",'"+component+"','"+engine+"',"+total+
      ",0,0,"+l2+","+l3+","+total+",100,"+note+") "+
      "ON CONFLICT(user_id,program_version_id,component_code,engine_version) "+
      "DO UPDATE SET l0_count=0,l1_count=0,l2_count=EXCLUDED.l2_count,"+
      "l3_count=EXCLUDED.l3_count,coverage_count=EXCLUDED.coverage_count,"+
      "coverage_pct=100");
  }
  assert.equal(stageSql("P1"),"6","actual S4 hybrid stage projector unlocks P1 Final Calibration");
  assert.equal(stageSql("P5"),"4","P5 stops at Stage4 with unresolved objective L3");
  const p1Cal=ok(await rpc("get_exam_prep_final_calibration_safe_v1",
    {p_component_code:"P1"}),"P1 signed operational calibration");
  const p5Blocked=ok(await rpc("get_exam_prep_final_calibration_safe_v1",
    {p_component_code:"P5"}),"P5 signed calibration still blocked");
  assert.equal(p1Cal.available,true,
    "Stage6 objective progression must unlock Final Calibration without Paper marks");
  assert.equal(p1Cal.stage6_operational_access,true);
  assert.equal(p1Cal.hybrid_stage_gate_enabled,true);
  assert.equal(p1Cal.exam_operations?.component_code,"P1",
    "P2-06 exam operations must survive objective Stage6 reader replacement");
  assert(Array.isArray(p1Cal.exam_operations?.checklist_items),
    "exam logistics checklist must remain on Final Calibration");
  assert.equal(p1Cal.paper_marks_awarded,false);
  assert.equal(p1Cal.readiness.app_readiness_estimate,"INSUFFICIENT_EVIDENCE");
  assert.equal(p1Cal.readiness.ready,false,
    "operational access is not examiner/Cambridge grade readiness");
  assert.equal(p5Blocked.available,false,
    "P5 cannot use P1's objective Stage6 or marks");
  // The P5 remedy is objectively reaching L3, not a Paper score or mentor.
  sql("UPDATE private.exam_prep_skill_states SET objective_level=3 "+
    "WHERE user_id='"+C+"' AND component_code='P5'");
  p5=await status("P5");
  expectStage(p5.stage3_to_4,true,"P5 syllabus remains valid");
  expectStage(p5.stage4_to_5,true,"P5 objective corrections pass when all L3");
  expectStage(p5.stage5_to_6,true,"P5 all L3 + closed corrections");
  assertNoGrade(p5);
  sql("UPDATE private.exam_prep_stage_states SET l2_count=0,l3_count=36 "+
    "WHERE user_id='"+C+"' AND component_code='P5'");
  assert.equal(stageSql("P5"),"6","P5 independently reaches Stage6 without Paper marks");
  const p5Cal=ok(await rpc("get_exam_prep_final_calibration_safe_v1",
    {p_component_code:"P5"}),"P5 signed Stage6 calibration");
  assert.equal(p5Cal.available,true);
  assert.equal(p5Cal.stage6_operational_access,true);
  assert.equal(p5Cal.paper_marks_awarded,false);
  assert.equal(p5Cal.readiness.ready,false);
  const gateP1=sql("SELECT max_unlocked_stage FROM private.exam_prep_component_access_gates "+
    "WHERE user_id='"+C+"' AND component_code='P1'");
  const gateP5=sql("SELECT max_unlocked_stage FROM private.exam_prep_component_access_gates "+
    "WHERE user_id='"+C+"' AND component_code='P5'");
  assert.equal(gateP1,"6");assert.equal(gateP5,"6");
  const withoutRole=await rpc("get_exam_prep_hybrid_s4_stage_status_safe_v1",
    {p_component_code:"P1"},null);
  assert.equal(withoutRole.ok,false,"anonymous cannot read personalized stage evidence");
  const invalid=await rpc("get_exam_prep_hybrid_s4_stage_status_safe_v1",
    {p_component_code:"not-a-component"});
  assert.equal(invalid.ok,false,"invalid component must fail closed");
  assert.equal(sql("SELECT count(*) FROM private.exam_prep_timed_attempt_results "+
    "WHERE user_id='"+C+"'"),"0","not one graded Paper was needed for Stage6");
  const legacyAfter=sql("SELECT (SELECT count(*) FROM private.exam_prep_timed_attempt_results)::text||'/'||"+
    "(SELECT count(*) FROM public.practice_attempts)::text||'/'||"+
    "(SELECT count(*) FROM public.tour_attempts)::text||'/'||"+
    "(SELECT count(*) FROM public.certificates)::text");
  assert.equal(legacyAfter,legacyBefore,"no legacy score/Practice/Tour/certificate changes");
  sql("UPDATE private.exam_prep_hybrid_s4_config_v1 SET stage_gates_enabled=false "+
    "WHERE singleton");
  const offAgain=await status("P1");
  assert.equal(offAgain.enabled,false,"feature OFF must block stage-reader API");
  const offCal=ok(await rpc("get_exam_prep_final_calibration_safe_v1",
    {p_component_code:"P1"}),"Stage6 legacy OFF calibration preserved");
  assert.equal(offCal.hybrid_stage_gate_enabled,false);
  assert.equal(offCal.stage6_operational_access,false);
  assert.equal(offCal.exam_operations?.component_code,"P1",
    "legacy calibration must preserve exam operations when hybrid flag OFF");
  assert.equal(offCal.available,false,
    "existing legacy comparator still requires independent marks when hybrid is OFF");
  console.log("PASS signed PG17/PostgREST objective stage 3->6 P1/P5: "+
    "empty/no coverage/key L3/corrective gates; real isolated stage projector and "+
    "owner-bound readback; zero Paper marks or mandatory mentor. "+
    "CI-only synthetic objective ledger, not genuine learner achievement.");
}
main().catch(e=>{
  console.error("S4 POSITIVE OBJECTIVE STAGE SIGNED E2E FAIL:",e.stack||e);
  process.exitCode=1;
});
