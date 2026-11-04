#!/usr/bin/env node
// Issue #450 P0-20: genuine HTTP signed-JWT old-tab denial for three actual
// rebuild-on-read Math RPCs in DISPOSABLE PG17+PostgREST ONLY.
// This is not a production release-epoch implementation or cleanup.
'use strict';
const assert=require('node:assert/strict');
const crypto=require('node:crypto');
const {execFileSync}=require('node:child_process');
const SECRET=process.env.P1P5_E2E_JWT_SECRET;
const OLD_IAT=Number(process.env.P0_20_OLD_IAT);
const UID='11111111-1111-4111-8111-111111111191';
const HOST='http://127.0.0.1:3000';
const roots=[
  'get_exam_prep_diagnostic_progress_safe_v1',
  'get_exam_prep_placement_safe_v1',
  'get_exam_prep_state_safe_v1'
];
assert(process.env.P1P5_E2E_ISOLATED==='true','P0-20 disposable flag required');
assert(process.env.PGDATABASE==='postgres'&&process.env.PGHOST==='127.0.0.1',
  'P0-20 refuses any remote PostgreSQL host or non-isolated database');
assert(SECRET?.length>=32,'P0-20 local signing secret missing');
assert(Number.isSafeInteger(OLD_IAT)&&OLD_IAT>1700000000,
  'P0-20 requires real pre-cutover JWT issued-at');
assert(roots.length===3&&new Set(roots).size===3,'P0-20 expected three real getters');

function sqlRead(query) {
  assert(query.trimStart().toUpperCase().startsWith('SELECT'),
    'P0-20 fingerprint helper cannot mutate database');
  return execFileSync('psql',['-X','-At','-v','ON_ERROR_STOP=1','-c',query],
    {encoding:'utf8',timeout:20000}).trim();
}
const fingerprintSql = "SELECT jsonb_build_object(\n 'users',(SELECT count(*) FROM public.users),\n 'auth_users',(SELECT count(*) FROM auth.users),\n 'placements',(SELECT md5(coalesce(string_agg(to_jsonb(t)::text,'|' ORDER BY to_jsonb(t)::text),'')) FROM private.exam_prep_component_placements t),\n 'component_gates',(SELECT md5(coalesce(string_agg(to_jsonb(t)::text,'|' ORDER BY to_jsonb(t)::text),'')) FROM private.exam_prep_component_access_gates t),\n 'stage_states',(SELECT md5(coalesce(string_agg(to_jsonb(t)::text,'|' ORDER BY to_jsonb(t)::text),'')) FROM private.exam_prep_stage_states t),\n 'skill_states',(SELECT md5(coalesce(string_agg(to_jsonb(t)::text,'|' ORDER BY to_jsonb(t)::text),'')) FROM private.exam_prep_skill_states t),\n 'sessions',(SELECT md5(coalesce(string_agg(to_jsonb(t)::text,'|' ORDER BY to_jsonb(t)::text),'')) FROM private.exam_prep_sessions t),\n 'responses',(SELECT md5(coalesce(string_agg(to_jsonb(t)::text,'|' ORDER BY to_jsonb(t)::text),'')) FROM private.exam_prep_responses t),\n 'consents',(SELECT md5(coalesce(string_agg(to_jsonb(t)::text,'|' ORDER BY to_jsonb(t)::text),'')) FROM private.exam_prep_beta_consents t),\n 'entitlements',(SELECT md5(coalesce(string_agg(to_jsonb(t)::text,'|' ORDER BY to_jsonb(t)::text),'')) FROM private.exam_prep_feature_entitlements t),\n 'practice',(SELECT md5(coalesce(string_agg(to_jsonb(t)::text,'|' ORDER BY to_jsonb(t)::text),'')) FROM public.practice_attempts t),\n 'tours',(SELECT md5(coalesce(string_agg(to_jsonb(t)::text,'|' ORDER BY to_jsonb(t)::text),'')) FROM public.tour_attempts t),\n 'certificates',(SELECT md5(coalesce(string_agg(to_jsonb(t)::text,'|' ORDER BY to_jsonb(t)::text),'')) FROM public.certificates t),\n 'math_epoch',(SELECT epoch::text||':'||paused::text FROM private.p0_16_academic_epoch_gate WHERE program_key='math_as_p1_p5'),\n 'economics_epoch',(SELECT epoch::text||':'||paused::text FROM private.p0_16_academic_epoch_gate WHERE program_key='economics_as')\n)::text";
const encode=obj=>Buffer.from(JSON.stringify(obj)).toString('base64url');
function jwt(iat){
  const head=encode({alg:'HS256',typ:'JWT'});
  const payload=encode({role:'authenticated',aud:'authenticated',sub:UID,iat,exp:iat+3600});
  const body=head+'.'+payload;
  const sig=crypto.createHmac('sha256',SECRET).update(body).digest('base64url');
  return body+'.'+sig;
}
async function request(rpc,token,component='P1'){
  assert(roots.includes(rpc),'P0-20 unlisted RPC endpoint');
  const res=await fetch(HOST+'/rpc/'+rpc,{
    method:'POST',signal:AbortSignal.timeout(20000),
    headers:{
      Authorization:'Bearer '+token,
      'Content-Type':'application/json',
      Accept:'application/json'
    },
    body:JSON.stringify({p_component_code:component})
  });
  let body;
  try{body=await res.json();}catch{body={};}
  return {status:res.status,body};
}
(async()=>{
  const before=sqlRead(fingerprintSql);
  for(const rpc of roots) {
    const response=await request(rpc,jwt(OLD_IAT));
    assert.equal(response.status,409,
      'P0-20 old signed JWT reached real '+rpc+
      ' without PT409: '+JSON.stringify(response));
    assert.equal(response.body?.code,'PT409',
      'P0-20 old getter did not return nonretryable epoch conflict '+rpc);
    assert.match(response.body?.message||'',/p0_16_old_signed_jwt/,
      'P0-20 old getter failed for wrong reason '+rpc);
  }
  const after=sqlRead(fingerprintSql);
  assert.equal(after,before,
    'P0-20 stale JWT getter unexpectedly mutated placements/stages, users or protected records');
  const newIat=Math.floor(Date.now()/1000);
  assert(newIat>OLD_IAT,'P0-20 fresh JWT must be newer than prior epoch');
  const current=await request('get_exam_prep_placement_safe_v1',jwt(newIat));
  assert.equal(current.status,200,
    'P0-20 new current-epoch signed JWT could not use original placement getter: '+JSON.stringify(current));
  assert(Array.isArray(current.body?.components),
    'P0-20 current getter response must preserve real original placement contract');
  console.log('PASS P0-20: three REAL rebuild-on-read owner RPCs reject signed old JWT without any state writes; new JWT follows original getter; Chemistry/consent data untouched');
})().catch(error=>{
  console.error('P0-20 FAILED: '+error.message);
  process.exitCode=1;
});
