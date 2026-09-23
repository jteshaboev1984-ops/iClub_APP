'use strict';
// Runs REAL proposed rollback SQL with COMMIT replaced by ROLLBACK.
// Only in disposable CI PG17; no access to production.
const assert=require('node:assert/strict');
const fs=require('node:fs');
const {spawnSync}=require('node:child_process');
const env=process.env;
if(env.GITHUB_ACTIONS!=='true'||env.PGHOST!=='127.0.0.1'||env.PGDATABASE!=='postgres'||
 !env.PGOPTIONS?.includes('weekly_goal.isolated_db=true')){
 console.error('REFUSED: disposable CI PostgreSQL ONLY');process.exit(1);
}
const path='docs/patch-proposals/20260920_weekly_flow_exact_rpc_rollback_v1.sql';
const original=fs.readFileSync(path,'utf8');
const begin=original.indexOf('\nBEGIN;');
assert.ok(begin>=0 && /\nCOMMIT;\s*$/.test(original),'Rollback transaction boundaries changed');
const artifact=original.slice(begin+1);
function execute(source){return spawnSync('psql',['-X','-q','-A','-t','-v','ON_ERROR_STOP=1'],{
 env,encoding:'utf8',input:source,timeout:30000});}
function sql(source){const r=execute(source);
 assert.equal(r.status,0,`Disposable SQL failed: ${(r.stderr||'').slice(-900)}`);return r.stdout;}
function named(source,key){const hits=source.split(/\r?\n/).filter(line=>line.startsWith(key+'='));
 assert.equal(hits.length,1,`Expected one ${key}`);return hits[0].slice(key.length+1);}
const baseline=sql(`SELECT 'SEALED='||count(*) FROM private.exam_prep_weekly_flow_rpc_backup_v1 b
 WHERE installed_md5 IS NOT NULL AND installed_md5<>original_md5
 AND md5(pg_get_functiondef(b.function_oid))=installed_md5;`);
assert.equal(named(baseline,'SEALED'),'11','Exact full-surface candidate seal missing');
const enrolled=Number(named(sql(`SELECT 'ENROLLED='||count(*) FROM private.exam_prep_weekly_flow_enrollment_v1
 WHERE enabled IS TRUE;`),'ENROLLED'));
assert.ok(enrolled>0,'Need synthetic enrollment to prove rollback refusal');
const on=execute(artifact);
assert.notEqual(on.status,0,'Rollback with Core ON must be blocked');
assert.match(on.stderr||'',/weekly_rollback_requires_core_off/);
const off=`UPDATE private.exam_prep_feature_config SET rollout_state='off',core_enabled=false,
 ai_enabled=false,mentor_enabled=false,kill_switch=true WHERE program_key='math_as_p1_p5';`;
const inject=statement=>artifact.replace(/^BEGIN;/,`BEGIN;\n${statement}\n`);
const whileEnrolled=execute(inject(off));
assert.notEqual(whileEnrolled.status,0,'Rollback with enrolled learner must be blocked');
assert.match(whileEnrolled.stderr||'',/weekly_rollback_requires_zero_enrolled_learners/);
const fixture=`SELECT 'FIXTURE='||
 (SELECT count(*) FROM private.exam_prep_weekly_plans WHERE user_id=f.user_id)::text||':'||
 (SELECT count(*) FROM private.exam_prep_session_authorizations WHERE user_id=f.user_id)::text||':'||
 (SELECT count(*) FROM private.exam_prep_sessions WHERE user_id=f.user_id)::text
 FROM weekly_goal_ci.fixture f;`;
const before=named(sql(fixture),'FIXTURE');
const inTransaction=inject(`${off}\nUPDATE private.exam_prep_weekly_flow_enrollment_v1
 SET enabled=false WHERE enabled IS TRUE;`).replace(/\nCOMMIT;\s*$/,
 `\nSELECT 'RESTORED='||count(*) FROM private.exam_prep_weekly_flow_rpc_backup_v1 b
 WHERE md5(pg_get_functiondef(b.function_oid))=b.original_md5;\nROLLBACK;`);
assert.equal(named(sql(inTransaction),'RESTORED'),'11','Every original body must match in rollback transaction');
assert.equal(named(sql(fixture),'FIXTURE'),before,'Rollback rehearsal touched academic records');
assert.equal(Number(named(sql(`SELECT 'ENROLLED='||count(*) FROM private.exam_prep_weekly_flow_enrollment_v1
 WHERE enabled IS TRUE;`),'ENROLLED')),enrolled,'Rollback rehearsal changed enrollment');
assert.equal(named(sql(`SELECT 'CANDIDATE='||count(*) FROM private.exam_prep_weekly_flow_rpc_backup_v1 b
 WHERE md5(pg_get_functiondef(b.function_oid))=b.installed_md5;`),'CANDIDATE'),'11',
 'Rollback rehearsal did not leave candidate installed');
console.log('EXACT ROLLBACK PACKAGE GREEN: 11 functions, Core ON/enrollment refused, original bodies restored in rolled-back rehearsal.');
console.log('Synthetic academic records and sealed candidate remain untouched; no production SQL.');
