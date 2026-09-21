'use strict';
// Full compatibility, rollback and bypass checks only on disposable CI PG17.
const assert=require('node:assert/strict');
const fs=require('node:fs');
const {spawnSync}=require('node:child_process');
const env=process.env;
if(env.GITHUB_ACTIONS!=='true'||env.PGHOST!=='127.0.0.1'||env.PGDATABASE!=='postgres'||
 !env.PGOPTIONS?.includes('weekly_goal.isolated_db=true')){
 console.error('REFUSED: disposable CI PostgreSQL only');process.exit(1);
}
function run(input){return spawnSync('psql',['-X','-q','-A','-t','-v','ON_ERROR_STOP=1'],{
 env,encoding:'utf8',input,timeout:30000});}
function sql(input){const result=run(input);
 assert.equal(result.status,0,`Isolated SQL failed: ${(result.stderr||'').slice(-2000)}`);
 return result.stdout;}
function named(output,key){const rows=output.split(/\r?\n/).filter(row=>row.startsWith(key+'='));
 assert.equal(rows.length,1,`Expected one ${key}`);return rows[0].slice(key.length+1);}
function script(file){const result=spawnSync('psql',['-X','-v','ON_ERROR_STOP=1','-f',file],{
 env,encoding:'utf8',timeout:30000});
 assert.equal(result.status,0,`Isolated file ${file} failed: ${(result.stderr||'').slice(-2000)}`);
 return result;}
function nodeTest(file){const check=spawnSync(process.execPath,['--check',file],{
 env,encoding:'utf8',timeout:10000});
 assert.equal(check.status,0,`Syntax failed ${file}: ${(check.stderr||'').slice(-700)}`);
 const result=spawnSync(process.execPath,[file],{env,encoding:'utf8',timeout:90000});
 if(result.stdout)process.stdout.write(result.stdout);
 assert.equal(result.status,0,`Isolated test ${file} failed: ${(result.stderr||'').slice(-2200)}`);}
const counts=`SELECT 'COUNTS='||
 (SELECT count(*) FROM private.exam_prep_weekly_plans WHERE user_id=f.user_id)::text||':'||
 (SELECT count(*) FROM private.exam_prep_session_authorizations WHERE user_id=f.user_id)::text||':'||
 (SELECT count(*) FROM private.exam_prep_sessions WHERE user_id=f.user_id)::text
 FROM weekly_goal_ci.fixture f;`;
const before=named(sql(counts),'COUNTS');
assert.equal(before,'1:1:1','Expected completed synthetic two-connection fixture');
const replay=sql(`BEGIN;
SELECT set_config('request.jwt.claim.sub',(SELECT user_id::text FROM weekly_goal_ci.fixture LIMIT 1),true);
SELECT set_config('request.jwt.claim.role','authenticated',true);
SELECT 'LEGACY='||public.start_exam_prep_session_safe_v1(
 (SELECT a.id FROM private.exam_prep_session_authorizations a
 JOIN weekly_goal_ci.fixture f ON f.user_id=a.user_id),
 'isolated-legacy-finalized-replay')::text;
SELECT 'GUARDED='||public.start_exam_prep_plan_session_once_safe_v1(
 (SELECT a.id FROM private.exam_prep_session_authorizations a
 JOIN weekly_goal_ci.fixture f ON f.user_id=a.user_id),
 'isolated-guarded-finalized-replay')::text;
ROLLBACK;`);
const legacy=JSON.parse(named(replay,'LEGACY'));
const guarded=JSON.parse(named(replay,'GUARDED'));
assert.equal(legacy.status,'finalized','Old replay contract changed: audit first');
assert.match(legacy.session_id||'',/^[0-9a-f]{8}-[0-9a-f-]{27,}$/i);
assert.equal(guarded.status,'attempt_already_saved');
assert.equal(Object.hasOwn(guarded,'session_id'),false);
const shape=sql(`SELECT 'DIRECT='||
 (position('public.generate_exam_prep_weekly_plan_safe_v2' in
  pg_get_functiondef('public.generate_exam_prep_weekly_plan_safe_v3(text)'::regprocedure))>0)::text||':'||
 (position('set status=''superseded''' in
  pg_get_functiondef('public.generate_exam_prep_weekly_plan_safe_v2(text)'::regprocedure))>0)::text;`);
assert.equal(named(shape,'DIRECT'),'true:true','Old generator changed: audit first');
assert.equal(named(sql(counts),'COUNTS'),before);
console.log('REPRODUCED prepatch direct legacy bypass in synthetic DB.');

// Production SQL strictly requires its independently observed LIVE v1 body hash.
// The historical migration replay in disposable CI has a distinct old v1 body;
// test only that isolated variant by substituting the expected hash in MEMORY.
// Never write a relaxed hash to the reviewed proposal or production database.
const backupPath='docs/patch-proposals/20260920_weekly_flow_preinstall_rpc_backup_v1.sql';
const backup=fs.readFileSync(backupPath,'utf8');
const liveV1Hash='58247a59c0967848d21c5ab93cc9d647';
const isolatedV1Hash='0a2ab5a50e7f086b035960ccaccbc8eb';
assert.equal(backup.split(liveV1Hash).length-1,1,'Strict live v1 MD5 missing or duplicated');
assert.equal(named(sql("SELECT 'V1HASH='||md5(pg_get_functiondef('public.generate_exam_prep_weekly_plan_safe_v1(text,text)'::regprocedure));"),'V1HASH'),
 isolatedV1Hash,'Unexpected CI migration source drift; do not change live pin');
sql(backup.replace(liveV1Hash,isolatedV1Hash));
console.log('BACKUP GREEN: 11 immutable original bodies; CI-only v1 variant verified without changing pinned live proposal.');
script('docs/patch-proposals/20260919_exam_prep_atomic_legacy_rpc_dispatch_v1.sql');
script('docs/patch-proposals/20260920_weekly_flow_postinstall_attestation_v1.sql');
console.log('CANDIDATE SEALED: eleven installed body hashes, zero enrollments at installation.');
for(const file of ['scripts/weekly-flow-atomic-dispatch-smoke.cjs',
 'scripts/weekly-flow-atomic-dispatch-race.cjs',
 'scripts/weekly-flow-atomic-dispatch-nonplan.cjs',
 'scripts/weekly-flow-atomic-dispatch-full-surface.cjs']) nodeTest(file);
console.log('FULL-SURFACE CANDIDATE: direct bypasses, original Core and two-backend races exercised.');
// Separate additive selector DRAFT. It does NOT yet replace the Core authorizers.
// Prove the first completed pack cannot be called fresh, P5 isolation, privacy,
// and that reusing original question IDs is not a valid alternative.
script('docs/patch-proposals/20260921_exam_prep_fresh_learning_selector_v1.sql');
script('supabase/tests/exam_prep_fresh_learning_selector_isolated_matrix.sql');
console.log('PRIVATE FRESH SELECTOR GREEN ONLY; Core integration and new authored packs remain blocked.');
for(const file of ['docs/patch-proposals/20260920_exam_prep_previous_week_adherence_readonly_v1.sql',
 'supabase/tests/exam_prep_previous_week_adherence_isolated_matrix.sql']){
 const result=script(file);if(result.stdout)process.stdout.write(result.stdout.slice(-700));
}
assert.equal(named(sql(counts),'COUNTS'),before,'Academic fixture changed after candidate');
nodeTest('scripts/weekly-flow-rollback-package-drill.cjs');
assert.equal(named(sql(counts),'COUNTS'),before,'Academic fixture changed after rollback rehearsal');
console.log('ISOLATED FULL-SURFACE BACKUP / INSTALL / SEALED ROLLBACK TESTS GREEN.');
console.log('Production bypass remains until independently authorized release; no live SQL executed.');
