#!/usr/bin/env node
'use strict';
// Issue #450 Stage C: real signed HTTP/JWT/PostgREST -> disposable PG17 security,
// idempotent two-paper parallel-tabs, expired-auth and emergency kill-switch proof.
// Runs AFTER the complete Stage B Math written browser suite on the same
// disposable database. NEVER points to hosted Supabase or real users.
// No simulated academic progress, correct-answer logging or human sign-offs.
const assert=require('node:assert/strict');
const crypto=require('node:crypto');
const {execFileSync}=require('node:child_process');
const HOST='http://127.0.0.1:3000';
const OWNER='11111111-1111-4111-8111-111111111191';
const OTHER='22222222-2222-4222-8222-222222222292';
const UNKNOWN='33333333-3333-4333-8333-333333333393';
const SECRET=process.env.P1P5_E2E_JWT_SECRET;

assert(process.env.CI==='true' && process.env.P1P5_E2E_ISOLATED==='true',
 'REFUSED: not an isolated CI job');
assert(process.env.PGHOST==='127.0.0.1' && process.env.PGPORT==='5432' &&
 process.env.PGDATABASE==='postgres' && process.env.PGUSER==='postgres',
 'REFUSED: non-disposable database endpoint');
assert(process.env.PGOPTIONS==='-c iclub.e2e_isolated=true',
 'REFUSED: local-only explicit SQL write guard missing');
assert(SECRET && SECRET.length>=32,'REFUSED: no ephemeral test JWT signing key');

const b64=x=>Buffer.from(JSON.stringify(x)).toString('base64url');
function token(sub,options={}){
 const now=Math.floor(Date.now()/1000);
 const claims={role:options.role||'authenticated',aud:'authenticated',sub,
   iat:options.expired?now-7200:now-10,exp:options.expired?now-3600:now+1800};
 const prefix=b64({alg:'HS256',typ:'JWT'})+'.'+b64(claims);
 return prefix+'.'+crypto.createHmac('sha256',SECRET).update(prefix).digest('base64url');
}
async function rpc(name,args={},jwt=null){
 assert(/^[a-z][a-z_0-9]+$/.test(name),'Bad RPC name');
 const url=HOST+'/rpc/'+name;
 const response=await fetch(url,{method:'POST',headers:{
  'Content-Type':'application/json','Accept':'application/json',
  ...(jwt?{Authorization:'Bearer '+jwt}:{})
 },body:JSON.stringify(args)});
 let data=null;
 const raw=await response.text();
 try{data=raw?JSON.parse(raw):null;}catch{}
 return {ok:response.ok,status:response.status,data};
}
function scalar(sql) {
 assert(/^\s*SELECT\b/i.test(sql),'REFUSED: only local read statements allowed');
 return execFileSync('psql',['-X','-At','-v','ON_ERROR_STOP=1','-c',sql],
  {encoding:'utf8'}).trim();
}
function json(sql){
 const v=scalar("SELECT coalesce(json_agg(row_to_json(r)),'[]'::json)::text FROM ("+sql+") AS r");
 return JSON.parse(v);
}
function safeMutation(enable){
 // ONLY toggles the emergency kill switch in a disposable, verified 2-user
 // ephemeral PG17. This script never changes production or normal configs.
 const statement="DO $$ BEGIN " +
 "IF current_database() <> 'postgres' " +
 "OR current_setting('iclub.e2e_isolated',true) IS DISTINCT FROM 'true' " +
 "OR (SELECT count(*) FROM public.users)<>2 " +
 "OR (SELECT count(*) FROM auth.users)<>2 " +
 "OR EXISTS(SELECT 1 FROM public.users WHERE id NOT IN (" +
 "'"+OWNER+"'::uuid,'"+OTHER+"'::uuid)) " +
 "OR EXISTS(SELECT 1 FROM private.exam_prep_beta_weekly_reviews) " +
 "OR EXISTS(SELECT 1 FROM public.practice_attempts) " +
 "OR EXISTS(SELECT 1 FROM public.tour_attempts) " +
 "OR EXISTS(SELECT 1 FROM public.certificates) " +
 "THEN RAISE EXCEPTION 'REFUSED: non-isolated or contaminated fault sandbox'; END IF; " +
 "IF (SELECT count(*) FROM private.exam_prep_feature_config WHERE id=1 " +
 "AND rollout_state='controlled_beta' AND core_enabled=true " +
 "AND qa_open_all_core=false AND qa_open_all_weekly=false " +
 "AND ai_enabled=false AND mentor_enabled=false AND kill_switch="+(enable?'false':'true')+
 ")<>1 THEN RAISE EXCEPTION 'REFUSED: unexpected kill-switch baseline'; END IF; " +
 "UPDATE private.exam_prep_feature_config SET kill_switch="+(enable?'true':'false')+
 " WHERE id=1; END $$;";
 execFileSync('psql',['-X','-q','-v','ON_ERROR_STOP=1','-c',statement],{encoding:'utf8'});
}
const count=(table,id,column='session_id')=>{
 assert(/^[0-9a-f-]{36}$/.test(id));
 return Number(scalar("SELECT count(*) FROM private."+table+
  " WHERE "+column+"='"+id+"'::uuid"));
};
function ownedWritten(){
 const sql="SELECT DISTINCT ON (s.component_code) s.id::text AS session_id,"+
 "s.component_code, s.status AS session_status, a.item_order,"+
 "a.client_idempotency_key AS key "+
 "FROM private.exam_prep_sessions s "+
 "JOIN private.exam_prep_written_step_advances_v1 a ON a.session_id=s.id "+
 "WHERE s.user_id='"+OWNER+"'::uuid AND s.session_type='learning' "+
 "AND s.component_code IN ('P1','P5') "+
 "ORDER BY s.component_code,s.started_at DESC,a.item_order DESC";
 return json(sql);
}
function counts(){
 return json("SELECT 'sessions' AS metric,count(*)::bigint n FROM private.exam_prep_sessions "+
 "UNION ALL SELECT 'responses',count(*) FROM private.exam_prep_responses "+
 "UNION ALL SELECT 'written_advances',count(*) FROM private.exam_prep_written_step_advances_v1 "+
 "UNION ALL SELECT 'skill_states',count(*) FROM private.exam_prep_skill_states "+
 "UNION ALL SELECT 'retest_events',count(*) FROM private.exam_prep_retest_events "+
 "UNION ALL SELECT 'beta_reviews',count(*) FROM private.exam_prep_beta_weekly_reviews "+
 "UNION ALL SELECT 'legacy_practice',count(*) FROM public.practice_attempts "+
 "UNION ALL SELECT 'legacy_tours',count(*) FROM public.tour_attempts "+
 "UNION ALL SELECT 'legacy_certificates',count(*) FROM public.certificates "+
 "ORDER BY metric");
}
const denied=(r,label)=>{
 assert(!r.ok && r.status>=400,label+' unexpectedly authorized HTTP '+r.status);
};
async function main(){
 const a=token(OWNER),b=token(OTHER),badSub=token(UNKNOWN),expired=token(OWNER,{expired:true});
 const invalidSignature=a.slice(0,-1)+(a.at(-1)==='A'?'B':'A');
 const paper=ownedWritten();
 assert(paper.length===2&&paper.map(r=>r.component_code).join(',')==='P1,P5',
  'Stage B did not leave exactly two component-owned committed written steps');
 assert(paper.every(r=>r.key&&r.key.length>=8),'Missing server-generated written idempotency evidence');
 const original=counts();
 const initial=await rpc('get_exam_prep_capabilities_v1',{},a);
 assert(initial.ok,'owner core access missing before negative tests');
 const cap=Array.isArray(initial.data)?initial.data[0]:initial.data;
 assert(cap?.core_access===true&&cap.ai_assist===false&&cap.mentor_care_entitled===false,
  'test must start from Core-only capabilities');

 let authAssertions=0,languageChecks=0,parallelReplays=0,foreignDenied=0;
 for(const row of paper){
  const session=row.session_id,order=row.item_order;
  const args={p_session_id:session,p_item_order:order};
  const status=await rpc('get_exam_prep_written_step_status_safe_v1',args,a);
  assert(status.ok && status.data?.status==='advanced' &&
   status.data?.component_code===row.component_code,
   'real owner write confirmation mismatched paper '+row.component_code);
  assert.equal(count('exam_prep_written_step_advances_v1',session),1,
   'Expected exactly one persisted written advancement for this session');
  assert.equal(count('exam_prep_responses',session),0+
   Number(scalar("SELECT count(*) FROM private.exam_prep_responses WHERE session_id='"+
    session+"'::uuid AND item_order<>"+order)),
   'Written Next fabricated a scored response');

  for(const lang of ['en','ru','uz']){
   const r=await rpc('get_exam_prep_session_written_v1',
    {p_session_id:session,p_language:lang},a);
   assert(r.ok&&r.data?.component_code===row.component_code,
    'owner language read failed for '+row.component_code+'/'+lang);
   assert(Array.isArray(r.data.items)&&r.data.items.some(v=>
     v.item_kind==='written'&&v.item_order===order&&v.completion_status==='advanced_in_plan_only'),
     'localized written re-open lost noncredit advancement '+row.component_code+'/'+lang);
   languageChecks++;
  }

  const negatives=[
   ['no JWT',null],['invalid signature',invalidSignature],
   ['expired JWT',expired],['unregistered subject',badSub],
   ['foreign user',b],['anon role',token(OWNER,{role:'anon'})]
  ];
  for(const [label,creds] of negatives){
   const r=await rpc('get_exam_prep_written_step_status_safe_v1',args,creds);
   denied(r,label+' '+row.component_code);
   authAssertions++;
   if(label==='foreign user')foreignDenied++;
  }
  const forbidden=await rpc('advance_exam_prep_written_step_safe_v1',
   {...args,p_idempotency_key:'stage-c-foreign-next-deny'},b);
  denied(forbidden,'foreign written mutation '+row.component_code);foreignDenied++;

  // Real concurrency from 6 separate signed HTTP connections, intentionally
  // reusing an ALREADY COMMITTED owner key. The server must lock/replay,
  // neither create a new written row nor award a response.
  const concurrent=await Promise.all(Array.from({length:6},()=>rpc(
   'advance_exam_prep_written_step_safe_v1',
   {...args,p_idempotency_key:row.key},a
  )));
  assert(concurrent.every(x=>x.ok&&x.data?.status==='advanced'&&x.data?.replayed===true),
   'same-key simultaneous HTTP retries were not replay-safe '+row.component_code);
  parallelReplays+=concurrent.length;

  const uniqueKey=await rpc('advance_exam_prep_written_step_safe_v1',
   {...args,p_idempotency_key:'stage-c-second-tab-'+row.component_code},a);
  assert(uniqueKey.ok&&uniqueKey.data?.replayed===true,
   'parallel tab distinct-key replay should not create a second written step');
  parallelReplays++;

  const conflicting=await rpc('advance_exam_prep_written_step_safe_v1',
   {...args,p_item_order:order+1,p_idempotency_key:row.key},a);
  denied(conflicting,'same idempotency key used for different item '+row.component_code);
  assert.equal(count('exam_prep_written_step_advances_v1',session),1,
   'parallel retry created another academic advancement');
  assert.equal(Number(scalar(
   "SELECT count(*) FROM private.exam_prep_responses WHERE session_id='"+
   session+"'::uuid AND item_order="+order)),0,
   'parallel Next manufactured a written answer');
 }
 assert.deepEqual(counts(),original,'Auth, concurrent retries mutated existing academic evidence');

 // Prove emergency lock in ACTUAL PostgREST + Core RPC, not just a static
 // flag query. Local SQL toggles are protected by PGOPTIONS, exact IDs,
 // clean legacy tables and verified active Core-only configuration.
 let activated=false;
 try {
  safeMutation(true);activated=true;
  const off=await rpc('get_exam_prep_capabilities_v1',{},a);
  assert(off.ok,'signed capability query failed during kill switch');
  const oc=Array.isArray(off.data)?off.data[0]:off.data;
  assert(oc?.core_access===false&&oc.kill_switch===true,
   'real kill switch did not fail closed');
  for(const row of paper){
   const deniedRead=await rpc('get_exam_prep_session_written_v1',
    {p_session_id:row.session_id,p_language:'en'},a);
   denied(deniedRead,'Core protected session read while kill switch ON');
   const deniedWrite=await rpc('advance_exam_prep_written_step_safe_v1',
    {p_session_id:row.session_id,p_item_order:row.item_order,
     p_idempotency_key:row.key},a);
   denied(deniedWrite,'Core write while kill switch ON');
  }
  assert.deepEqual(counts(),original,'Denied kill-switch traffic changed academic evidence');
 }finally{
  if(activated)safeMutation(false);
 }
 const back=await rpc('get_exam_prep_capabilities_v1',{},a);
 const restored=Array.isArray(back.data)?back.data[0]:back.data;
 assert(back.ok&&restored?.core_access===true&&restored.kill_switch===false,
  'Core-only capability did not recover after isolated emergency drill');
 assert.deepEqual(counts(),original,
  'Emergency on/off changed academic state, legacy or beta evidence');

 const matrix=json("SELECT scenario_type,count(*) AS n FROM private.exam_prep_synthetic_scenarios "+
 "WHERE scenario_set_version='p2_67_canonical_v2_0' GROUP BY scenario_type ORDER BY scenario_type");
 assert(matrix.reduce((n,r)=>n+Number(r.n),0)===33,'P2-67 15+18 definitions missing');
 console.log('STAGE C REAL HTTP AUTH RACE KILL SWITCH PASS',JSON.stringify({
  components:paper.map(r=>r.component_code),threeLocalesRead:languageChecks,
  signedJwtNegativeCases:authAssertions,foreignAccessDenied:foreignDenied,
  parallelRealHttpReplays:parallelReplays,keyCollisionDenied:true,
  killSwitchFailClosed:true,killSwitchRestored:true,
  academicEvidenceUnchanged:true,scenarioRegistryOnly:matrix,
  simulatedFullYearLearnerRuns:0,realTelegramDeviceRuns:0,
  hostedGoTrueAuthRuns:0
 }));
}
main().catch(error=>{
 console.error('STAGE C AUTH/RACE/FAULT HTTP FAILED:',error.message);
 process.exitCode=1;
});
