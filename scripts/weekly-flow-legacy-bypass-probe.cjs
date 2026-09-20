'use strict';
// All candidate installation/rollback checks run ONLY on disposable CI PG17.
const assert=require('node:assert/strict');
const {spawnSync}=require('node:child_process');
const env=process.env;
if(env.GITHUB_ACTIONS!=='true'||env.PGHOST!=='127.0.0.1'||env.PGDATABASE!=='postgres'||
   !env.PGOPTIONS?.includes('weekly_goal.isolated_db=true')){
 console.error('REFUSED: disposable CI PostgreSQL only');process.exit(1);
}
function run(input){return spawnSync('psql',['-X','-q','-A','-t','-v','ON_ERROR_STOP=1'],{
 env,encoding:'utf8',input,timeout:30000});}
function sql(input){const result=run(input);
 assert.equal(result.status,0,`Isolated SQL failed: ${(result.stderr||'').slice(-1000)}`);
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

// Exact seven-function backup must be independently committed BEFORE mutation.
// It refuses any of the four live-source hashes/grants changing since review.
script('docs/patch-proposals/20260920_weekly_flow_preinstall_rpc_backup_v1.sql');
console.log('BACKUP GREEN: exact prepatch bodies, ownership and grants captured privately.');
script('docs/patch-proposals/20260919_exam_prep_atomic_legacy_rpc_dispatch_v1.sql');
script('docs/patch-proposals/20260920_weekly_flow_postinstall_attestation_v1.sql');
console.log('CANDIDATE SEALED: exact seven installed body hashes, zero enrollments at installation.');
for(const file of ['scripts/weekly-flow-atomic-dispatch-smoke.cjs',
 'scripts/weekly-flow-atomic-dispatch-race.cjs',
 'scripts/weekly-flow-atomic-dispatch-nonplan.cjs']) nodeTest(file);
console.log('ATOMIC COMPATIBILITY GREEN: original Core/nonplan behavior, genuine two-backend races.');
for(const file of ['docs/patch-proposals/20260920_exam_prep_previous_week_adherence_readonly_v1.sql',
 'supabase/tests/exam_prep_previous_week_adherence_isolated_matrix.sql']){
 const result=script(file);
 if(result.stdout)process.stdout.write(result.stdout.slice(-700));
}
assert.equal(named(sql(counts),'COUNTS'),before,'Academic fixture changed after candidate');
nodeTest('scripts/weekly-flow-rollback-package-drill.cjs');
assert.equal(named(sql(counts),'COUNTS'),before,'Academic fixture changed after rollback rehearsal');
console.log('ISOLATED BACKUP / INSTALL / SEALED ROLLBACK TESTS GREEN.');
console.log('Production bypass remains until independently authorized release; no live SQL executed.');
