#!/usr/bin/env node
'use strict';
// Issue #450: reproduce an existing beta learner's *shape* of active P1
// diagnosis with an unrelated disposable synthetic account. DO NOT sign in
// as, impersonate, query, or write the real student's production account.
// Runs only at END of S4's isolated PG17 + signed JWT/PostgREST workflow.
const assert = require('node:assert/strict');
const crypto = require('node:crypto');
const {execFileSync} = require('node:child_process');

assert(process.env.CI==='true' && process.env.P1P5_E2E_ISOLATED==='true' &&
  process.env.PGHOST==='127.0.0.1' && process.env.PGDATABASE==='postgres' &&
  process.env.PGUSER==='postgres',
  'REFUSED: active diagnostic regression only on disposable GitHub PG17');
const secret=process.env.P1P5_E2E_JWT_SECRET;
assert(secret && secret.length>32,'disposable JWT signing key required');
const B='22222222-2222-4222-8222-222222222292';
const b64=x=>Buffer.from(JSON.stringify(x)).toString('base64url');
const now=Math.floor(Date.now()/1000);
const h=b64({alg:'HS256',typ:'JWT'})+'.'+
  b64({aud:'authenticated',sub:B,role:'authenticated',iat:now,exp:now+1200});
const token=h+'.'+crypto.createHmac('sha256',secret).update(h).digest('base64url');
function sql(q){
  return execFileSync('psql',['-X','-At','-v','ON_ERROR_STOP=1','-c',q],
    {encoding:'utf8',env:process.env}).trim();
}
async function rpc(name,args={}){
  const r=await fetch('http://127.0.0.1:3000/rpc/'+name,{
    method:'POST',
    headers:{'Content-Type':'application/json',Accept:'application/json',
      Authorization:'Bearer '+token},
    body:JSON.stringify(args)
  });
  let payload=null;
  try{payload=await r.json()}catch{}
  assert(r.ok,name+' HTTP '+r.status+' '+JSON.stringify(payload).slice(0,400));
  return payload;
}
const key=label=>'s4-stage0-coexist-'+label+'-abcdefghijklmnopqrst';
const diagSelect="SELECT id::text||'|'||status||'|'||started_at::text||'|'||"+
  "coalesce(finalized_at::text,'') FROM private.exam_prep_sessions "+
  "WHERE user_id='"+B+"' AND component_code='P1' "+
  "AND session_type='diagnostic' ORDER BY started_at";
const legacyCounts=()=>sql("SELECT (SELECT count(*) FROM public.practice_attempts)::text||'/'||"+
  "(SELECT count(*) FROM public.tour_attempts)::text||'/'||"+
  "(SELECT count(*) FROM public.certificates)::text");

async function main(){
  const legacyBefore=legacyCounts();
  // All writes in this test affect ONLY an ephemeral, disposable CI DB.
  sql("UPDATE private.exam_prep_feature_config SET rollout_state='controlled_beta',"+
    "core_enabled=true,kill_switch=false,qa_open_all_core=false WHERE id=1");
  sql("UPDATE private.exam_prep_hybrid_s4_config_v1 "+
    "SET paper_enabled=true,stage_gates_enabled=false WHERE singleton");
  assert.equal(sql("SELECT count(*) FROM private.exam_prep_feature_entitlements "+
    "WHERE user_id='"+B+"' AND entitlement_status='active' AND core_access=true"),'1',
    'synthetic cohort entitlement required');
  assert.equal(sql("SELECT count(*) FROM private.exam_prep_sessions "+
    "WHERE user_id='"+B+"' AND session_type='diagnostic' AND status='active'"),'0',
    'synthetic B must not have preexisting active diagnostic');
  // Use the same owner-authenticated profile form route as the live app.
  await rpc('save_exam_prep_exam_profile_v2',{
    p_exam_series:'May/June 2027',p_target_grade:'A',
    p_total_student_hours_available:3,p_mathematics_hours_budget:2
  });
  const d=await rpc('start_exam_prep_next_diagnostic_safe_v1',{
    p_component_code:'P1',p_idempotency_key:key('diagnostic-start')
  });
  assert(d.session_id && d.session_type==='diagnostic','real signed diagnostic started');
  const before=sql(diagSelect);
  assert(before.includes(d.session_id+'|active|'),'diagnostic must remain active');
  // Active Stage0 diagnostic must never hide or consume an independent,
  // noncredit Paper. The full Paper owner auth does NOT require Stage0 closure.
  const catalog=await rpc('get_exam_prep_hybrid_s4_papers_safe_v1',{p_component_code:'P1'});
  assert.equal(catalog.enabled,true);
  assert(Array.isArray(catalog.papers)&&catalog.papers.length>=1,'current P1 Paper catalog');
  const assessment=catalog.papers[0].assessment_id;
  const started=await rpc('start_exam_prep_hybrid_s4_paper_safe_v1',{
    p_assessment_id:assessment,p_idempotency_key:key('paper-start')
  });
  assert(started.session_id && started.session_id!==d.session_id,'separate S4 Paper session');
  assert.equal(sql(diagSelect),before,'P1 diagnostic unchanged after starting Paper');
  const opened=await rpc('get_exam_prep_hybrid_s4_session_safe_v1',{
    p_session_id:started.session_id,p_language:'ru'
  });
  assert.equal(opened.component_code,'P1');
  assert.equal(opened.awarded_paper_marks,null,'no student paper grades');
  const finish=await rpc('finish_exam_prep_hybrid_s4_paper_safe_v1',{
    p_session_id:started.session_id,p_reason:'finish',p_idempotency_key:key('paper-finish')
  });
  assert.equal(finish.paper_marks,null,'no invented paper marks');
  assert.equal(finish.method_verified,false,'no method assessment');
  const review=await rpc('reveal_exam_prep_hybrid_s4_review_safe_v1',{
    p_session_id:started.session_id,p_language:'uz'
  });
  assert.equal(review.scope,'criteria_and_short_hints_only');
  assert.equal(review.paper_marks_awarded,null);
  assert.equal(sql(diagSelect),before,'P1 diagnostic unchanged after Paper reveal');
  const resumed=await rpc('get_exam_prep_hybrid_s4_session_safe_v1',{
    p_session_id:started.session_id,p_language:'en'
  });
  assert.equal(resumed.session_id,started.session_id,'Paper reopen by owner');
  assert.equal(resumed.review_revealed,true,'reveal preserved in session');
  const hist=await rpc('get_exam_prep_hybrid_s4_history_safe_v1',{p_component_code:'P1'});
  assert(hist.sessions.some(x=>x.session_id===started.session_id && x.closed_at &&
    x.review_revealed===true),'Paper history survives re-open');
  assert.equal(sql(diagSelect),before,'P1 diagnostic remains active after history reload');
  assert.equal(legacyCounts(),legacyBefore,'legacy Practice/Tours/certificates unchanged');
  console.log('S4 ACTIVE DIAGNOSTIC COEXISTENCE PASS: P1 diagnostic unchanged; Paper owner start/finish/review/history noncredit');
}
main().catch(e=>{console.error(e);process.exitCode=1;});
