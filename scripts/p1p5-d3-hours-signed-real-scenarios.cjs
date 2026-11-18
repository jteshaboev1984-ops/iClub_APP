#!/usr/bin/env node
'use strict';
// D3-HOURS #450: signed HS256 JWT -> actual HTTP/PostgREST -> disposable PG17.
// No mocking of server authorization; only synthetic learners C and D.
// Refuse any production project, database, caller, or remote HTTP endpoint.
const assert = require('node:assert/strict');
const crypto = require('node:crypto');
const { execFileSync } = require('node:child_process');
assert(process.env.CI === 'true' &&
  process.env.P1P5_E2E_ISOLATED === 'true' &&
  process.env.PGHOST === '127.0.0.1' &&
  process.env.PGDATABASE === 'postgres' &&
  process.env.PGUSER === 'postgres', 'D3: disposable PG17 only');
const secret = process.env.P1P5_E2E_JWT_SECRET;
assert(secret && secret.length > 32, 'D3: ephemeral signing secret required');
const C='33333333-3333-4333-8333-333333333393';
const D='44444444-4444-4444-8444-444444444494';
const e=x=>Buffer.from(JSON.stringify(x)).toString('base64url');
function jwt(uid) {
  const now=Math.floor(Date.now()/1000);
  const data=e({alg:'HS256',typ:'JWT'})+'.'+
    e({aud:'authenticated',sub:uid,role:'authenticated',iat:now,exp:now+1800});
  return data+'.'+crypto.createHmac('sha256',secret).update(data).digest('base64url');
}
async function rpc(uid, name, params={}) {
  const response=await fetch('http://127.0.0.1:3000/rpc/'+name, {
    method:'POST',headers:{'Content-Type':'application/json',Accept:'application/json',
      Authorization:'Bearer '+jwt(uid)},body:JSON.stringify(params)
  });
  let data=null;try{data=await response.json()}catch{}
  return {ok:response.ok,status:response.status,data};
}
const ok=(v,l)=>{assert(v.ok,l+' '+v.status+' '+JSON.stringify(v.data).slice(0,350));return v.data};
const denied=(v,l)=>assert(!v.ok&&v.status>=400,l+' unexpectedly succeeded: '+JSON.stringify(v.data));
function sql(q) {
  return execFileSync('psql',['-X','-At','-v','ON_ERROR_STOP=1','-c',q],
    {encoding:'utf8',env:process.env}).trim();
}
function cnt() {
  return sql("SELECT (SELECT count(*) FROM public.practice_attempts)||'/'||"+
    "(SELECT count(*) FROM public.tour_attempts)||'/'||"+
    "(SELECT count(*) FROM public.certificates)");
}
function profileRows(uid) {
  const q="SELECT coalesce(total_student_hours_available::text,'NULL')||'|'||"+
    "coalesce(mathematics_hours_budget::text,'NULL')||'|'||profile_revision||'|'||"+
    "paper_comparability_epoch FROM private.exam_prep_exam_profiles WHERE user_id='"+uid+"'";
  return sql(q);
}
function expectProfile(uid,total,math,revision,epoch=1) {
  const [a,b,c,d]=profileRows(uid).split('|');
  assert.equal(a==='NULL'?null:Number(a),total,'owner total hours');
  assert.equal(b==='NULL'?null:Number(b),math,'owner Mathematics hours');
  assert.equal(Number(c),revision,'owner profile revision');
  assert.equal(Number(d),epoch,'owner paper comparability epoch');
}
function key(label){return 'd3-hours-'+label+'-'+crypto.randomUUID()}
const args=(exam='May/June 2027',grade='A',total=null,math=null)=>({
  p_exam_series:exam,p_target_grade:grade,
  p_total_student_hours_available:total,p_mathematics_hours_budget:math
});
async function run() {
  const baseline=cnt();
  assert.equal(sql('SELECT count(*) FROM private.exam_prep_exam_profiles WHERE user_id IN (\''+C+'\',\''+D+'\')'),'0');
  sql("INSERT INTO auth.users(id,aud,role,email) VALUES "+
    "('"+C+"','authenticated','authenticated','d3-hours-c@localhost.invalid'),"+
    "('"+D+"','authenticated','authenticated','d3-hours-d@localhost.invalid')");
  sql("INSERT INTO public.users(id,first_name,last_name,language_code) VALUES "+
    "('"+C+"','D3','Without Time','ru'),"+
    "('"+D+"','D3','Retained Time','en')");
  sql("INSERT INTO public.user_subjects(user_id,subject_id,mode) VALUES "+
    "('"+C+"',5,'study'),('"+D+"',5,'competitive')");
  sql("INSERT INTO private.exam_prep_feature_entitlements"+
    "(user_id,entitlement_status,core_access,ai_assist,mentor_care_entitled,valid_from) VALUES "+
    "('"+C+"','active',true,false,false,now()-interval '1 minute'),"+
    "('"+D+"','active',true,false,false,now()-interval '1 minute')");
  sql("UPDATE private.exam_prep_feature_config SET rollout_state='controlled_beta',"+
    "qa_open_all_core=true,core_enabled=true,kill_switch=false WHERE id=1");

  // C: real first onboarding without any hour question. NULL must NOT become 0.
  const first=ok(await rpc(C,'save_exam_prep_exam_profile_v2',args()),
    'C blank-time profile saved with real RPC');
  assert.equal(first.total_student_hours_available,null);
  assert.equal(first.mathematics_hours_budget,null);
  assert.equal(first.profile_revision,1);
  expectProfile(C,null,null,1);
  assert.equal(sql("SELECT count(*) FROM private.exam_prep_exam_map_revisions WHERE user_id='"+C+"'"+
    " AND total_student_hours_available IS NULL AND mathematics_hours_budget IS NULL"),'1',
    'initial historical revision retains explicit unknown hours');
  const placement=sql("SELECT string_agg(component_code||'='||coalesce(status,'')||'/'||coalesce(reason,''),';' ORDER BY component_code) "+
    "FROM private.exam_prep_component_placements WHERE user_id='"+C+"'");
  assert(!placement.includes('exam_profile_or_realistic_mathematics_budget_required'),
    'C placement cannot be hour-blocked: '+placement);
  // Academic Stage0 still uses real diagnostic-content requirements.
  const checkC=await rpc(C,'start_exam_prep_next_diagnostic_safe_v1',{
    p_component_code:'P1',p_idempotency_key:key('c-p1')});
  const cDiag=ok(checkC,'C signed diagnostic P1 without hours');
  assert(cDiag.session_id&&cDiag.session_type==='diagnostic','C actual diagnostic session');
  const checkC5=await rpc(C,'start_exam_prep_next_diagnostic_safe_v1',{
    p_component_code:'P5',p_idempotency_key:key('c-p5')});
  const cDiag5=ok(checkC5,'C signed diagnostic P5 without hours');
  assert(cDiag5.session_id&&cDiag5.session_type==='diagnostic');
  const foreign=await rpc(D,'get_exam_prep_session_safe_v1',{p_session_id:cDiag.session_id});
  assert(!foreign.ok || foreign.data==null || foreign.data?.session_id!==cDiag.session_id,
    'D must not receive C academic session');

  // No schedule required: an unselected hour must be represented as null.
  const beforeChoice=ok(await rpc(C,'get_my_exam_prep_weekly_choice_s3_safe_v1'),
    'C S3 read without hours');
  assert.equal(beforeChoice.chosen_math_minutes,null);
  assert.equal(beforeChoice.total_available_minutes,null);
  expectProfile(C,null,null,1);

  // Explicit voluntary S3 change. 30 x 3 = 90 min: learner CHOSE it,
  // not a model's inferred requirement; both P1/P5 total exactly 90.
  const cChoice=ok(await rpc(C,'save_my_exam_prep_weekly_choice_s3_safe_v1',{
    p_choice_code:'change',p_p1_minutes:45,p_p5_minutes:45,
    p_minutes_per_day:30,p_days_per_week:3,p_expected_schedule_revision:0,
    p_idempotency_key:key('c-first-voluntary')
  }), 'C explicitly chooses 30min x3 days');
  assert.equal(cChoice.chosen_math_minutes,90);
  expectProfile(C,null,1.5,2);
  const next=ok(await rpc(C,'get_my_exam_prep_weekly_choice_s3_safe_v1'),
    'S3 current choice persists');
  assert.equal(next.chosen_math_minutes,90);
  assert.equal(Number(next.study_minutes_per_day),30);
  assert.equal(Number(next.study_days_per_week),3);
  assert.equal(next.total_available_minutes,null);

  const beforeRevisions=Number(sql("SELECT count(*) FROM private.exam_prep_exam_map_revisions WHERE user_id='"+C+"'"));
  const same=ok(await rpc(C,'save_exam_prep_exam_profile_v2',args()),
    'C revisits exam plan without supplying hours');
  assert.equal(same.hours_changed,false);
  assert.equal(Number(same.profile_revision),2);
  expectProfile(C,null,1.5,2);
  assert.equal(Number(sql("SELECT count(*) FROM private.exam_prep_exam_map_revisions WHERE user_id='"+C+"'")),beforeRevisions);
  denied(await rpc(C,'save_exam_prep_exam_profile_v2',args('May/June 2027','A',null,0)),
    'C explicit zero Math hours not silently accepted');

  // D: returning existing data, original hours, multiple revisions retained.
  const initialD=ok(await rpc(D,'save_exam_prep_exam_profile_v2',args('May/June 2027','A',12,6)),
    'D initial 12/6 profile');
  assert.equal(initialD.profile_revision,1);
  const unchanged=ok(await rpc(D,'save_exam_prep_exam_profile_v2',args('May/June 2027','A',null,null)),
    'D new UI omits hours but retains original budget');
  assert.equal(unchanged.hours_changed,false);
  assert.equal(unchanged.profile_revision,1);
  expectProfile(D,12,6,1);
  const altered=ok(await rpc(D,'save_exam_prep_exam_profile_v2',args('May/June 2027','A',null,4)),
    'D changes Math hours to four while preserving old total');
  assert.equal(altered.hours_changed,true);
  expectProfile(D,12,4,2);
  denied(await rpc(D,'save_exam_prep_exam_profile_v2',args('May/June 2027','A',null,13)),
    'D must not silently exceed own stored 12-hour total');
  denied(await rpc(D,'save_exam_prep_exam_profile_v2',args('May/June 2027','A',-1,2)),
    'D negative total denied');
  denied(await rpc(D,'save_exam_prep_exam_profile_v2',args('May/June 2027','A',169,2)),
    'D over 168 total denied');
  expectProfile(D,12,4,2);
  assert.equal(sql("SELECT count(*) FROM private.exam_prep_exam_map_revisions WHERE user_id='"+D+"'"),'2');

  // S3 concurrency/idempotence guard remains intact with optional total hours.
  const stale=await rpc(C,'save_my_exam_prep_weekly_choice_s3_safe_v1',{
    p_choice_code:'change',p_p1_minutes:75,p_p5_minutes:60,
    p_minutes_per_day:45,p_days_per_week:3,p_expected_schedule_revision:0,
    p_idempotency_key:key('stale-choice')
  });
  denied(stale,'C stale voluntary revision must not overwrite');
  const latest=ok(await rpc(C,'get_my_exam_prep_weekly_choice_s3_safe_v1'),
    'latest C choice unaffected');
  assert.equal(latest.chosen_math_minutes,90);
  assert.equal(cnt(),baseline,'NO legacy Practice/Tour/certificate writes');
  assert.equal(sql("SELECT count(*) FROM private.exam_prep_skill_workload_norms_v1 WHERE estimate_status='approved'"),'0',
    'No fabricated academic per-skill minutes');
  console.log('D3-HOURS signed PASS: new/no hours P1&P5; voluntary 90min and S3 read; old 12/6 preserved; revisions/invalid/cross-owner/stale/no legacy writes');
}
run().catch(e=>{console.error(e);process.exitCode=1});
