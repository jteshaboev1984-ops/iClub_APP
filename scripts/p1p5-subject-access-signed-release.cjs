#!/usr/bin/env node
'use strict';
// #450 / #526. Genuine HS256 JWT -> local PostgREST -> disposable PG17 only.
// Test both existing routes. NEVER send requests to production Supabase.
const assert = require('node:assert/strict');
const crypto = require('node:crypto');
const { execFileSync } = require('node:child_process');

assert(process.env.CI === 'true' &&
  process.env.P1P5_E2E_ISOLATED === 'true' &&
  process.env.PGHOST === '127.0.0.1' &&
  process.env.PGDATABASE === 'postgres' &&
  process.env.PGUSER === 'postgres',
  'REFUSED: signed subject-access test requires disposable GitHub PostgreSQL17');
const secret = process.env.P1P5_E2E_JWT_SECRET;
assert(secret && secret.length > 32, 'ephemeral JWT signing secret required');

const A = '11111111-1111-4111-8111-111111111191';
const B = '22222222-2222-4222-8222-222222222292';
const b64 = x => Buffer.from(JSON.stringify(x)).toString('base64url');
function jwt(uid) {
  const now = Math.floor(Date.now() / 1000);
  const data = b64({ alg:'HS256',typ:'JWT' }) + '.' +
    b64({ aud:'authenticated',sub:uid,role:'authenticated',iat:now,exp:now+1200 });
  return data + '.' + crypto.createHmac('sha256',secret).update(data).digest('base64url');
}
async function rpc(name, args={}, token=jwt(A)) {
  const resp = await fetch('http://127.0.0.1:3000/rpc/'+name, {
    method:'POST',
    headers:{ 'Content-Type':'application/json',Accept:'application/json',
      ...(token?{Authorization:'Bearer '+token}:{}) },
    body:JSON.stringify(args)
  });
  let data=null;try{data=await resp.json()}catch{}
  return {ok:resp.ok,status:resp.status,data};
}
function sql(query) {
  return execFileSync('psql',['-X','-At','-v','ON_ERROR_STOP=1','-c',query],
    {encoding:'utf8',env:process.env}).trim();
}
function ok(result,label) {
  assert(result.ok,label+' HTTP '+result.status+' '+JSON.stringify(result.data).slice(0,240));
  return result.data;
}
function deny(result,label) {
  assert(!result.ok && result.status>=400,label+' unexpectedly succeeded '+JSON.stringify(result.data));
}
async function core(uid) {
  const r=ok(await rpc('get_exam_prep_capabilities_v1',{},jwt(uid)),'capabilities');
  const data=Array.isArray(r)?r[0]:r;
  assert(data && typeof data.core_access==='boolean','capabilities contract');
  return data;
}
function legacyCounts() {
  return sql("SELECT (SELECT count(*) FROM public.practice_attempts)::text||'/'||"+
    "(SELECT count(*) FROM public.tour_attempts)::text||'/'||"+
    "(SELECT count(*) FROM public.certificates)::text");
}
async function run() {
  const start=legacyCounts();
  assert.equal(sql("SELECT rollout_state||'/'||qa_open_all_core::text FROM private.exam_prep_feature_config WHERE id=1"),
    'controlled_beta/false','initial beta fixture unchanged');
  assert.equal(sql("SELECT count(*) FROM public.user_subjects"),'0','initial no selected subjects');
  assert.equal((await core(A)).core_access,true,'existing beta A entitled');
  assert.equal((await core(B)).core_access,true,'existing beta B entitled');

  // Expanded beta and mass must use the EXISTING Mathematics subject selection,
  // regardless of temporary QA override or direct JWT possession.
  for(const rollout of ['expanded_beta','mass']) {
    sql("UPDATE private.exam_prep_feature_config SET rollout_state='"+rollout+
      "',qa_open_all_core=true WHERE id=1");
    assert.equal((await core(A)).core_access,false,rollout+' A without Math');
    assert.equal((await core(B)).core_access,false,rollout+' B without Math');
    deny(await rpc('get_exam_prep_hybrid_s4_papers_safe_v1',
      {p_component_code:'P1'},jwt(B)),rollout+' direct Paper access without Math');
    deny(await rpc('save_exam_prep_exam_profile_v2',{
      p_exam_series:'May/June 2027',p_target_grade:'A',
      p_total_student_hours_available:12,p_mathematics_hours_budget:6
    },jwt(B)),rollout+' direct profile write without Math');
    if(rollout==='expanded_beta') {
      sql("INSERT INTO public.user_subjects(user_id,subject_id,mode) VALUES('"+A+
        "',5,'study') ON CONFLICT(user_id,subject_id) DO NOTHING");
    }
    assert.equal((await core(A)).core_access,true,rollout+' A with selected Math');
    assert.equal((await core(B)).core_access,false,rollout+' B without Math');
    const catalog=ok(await rpc('get_exam_prep_hybrid_s4_papers_safe_v1',
      {p_component_code:'P1'},jwt(A)),rollout+' Mathematics user Paper catalog');
    assert.equal(catalog.enabled,false,'existing S4 Paper switch remains OFF');
  }
  // Both pre-existing study and competitive choices qualify; removing a
  // subject is immediately respected. No user-subject writes in production.
  sql("INSERT INTO public.user_subjects(user_id,subject_id,mode) VALUES('"+B+
    "',5,'competitive') ON CONFLICT(user_id,subject_id) DO NOTHING");
  assert.equal((await core(B)).core_access,true,'competitive Math choice also qualifies');
  sql("DELETE FROM public.user_subjects WHERE user_id='"+B+"' AND subject_id=5");
  assert.equal((await core(B)).core_access,false,'deselection closes mass access');

  // Existing controlled beta must behave exactly as before (explicit grants).
  sql("UPDATE private.exam_prep_feature_config SET rollout_state='controlled_beta',"+
    "qa_open_all_core=false WHERE id=1");
  assert.equal((await core(A)).core_access,true,'selected beta owner unchanged');
  assert.equal((await core(B)).core_access,true,'nonselected beta entitlement unchanged');
  assert.equal(legacyCounts(),start,'legacy Practice/Tours/certificates unchanged');
  console.log('P1/P5 SUBJECT ACCESS PASS: beta unchanged; expanded/mass selected-only; direct RPC denied; no legacy writes');
}
run().catch(error => {console.error(error);process.exitCode=1;});
