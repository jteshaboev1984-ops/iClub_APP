'use strict';
// Runs the REAL proposed rollback body with its COMMIT replaced by ROLLBACK
// in a disposable database only. Never connects to Supabase or production.
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
function sql(source){const r=execute(source);assert.equal(r.status,0,`Disposable SQL failed: ${(r.stderr||'').slice(-900)}`);return r.stdout;}
function named(source,key){const hits=source.split(/\r?\n/).filter(line=>line.startsWith(key+'='));
 assert.equal(hits.length,1,`Expected one ${key}`);return hits[0].slice(key.length+1);}
const baseline=sql(`SELECT 'SEALED='||count(*) FROM private.exam_prep_weekly_flow_rpc_backup_v1 b
 WHERE installed_md5 IS NOT NULL AND installed_md5<>original_md5
 AND md5(pg_get_functiondef(b.function_oid))=installed_md5;`);
assert.equal(named(baseline,'SEALED'),'7','Exact candidate seal missing');
const enrolled=Number(named(sql(`SELECT 'ENROLLED='||count(*) FROM private.exam_prep_weekly_flow_enrollment_v1
 WHERE enabled IS TRUE;`),'ENROLLED'));
assert.ok(enrolled>0,'Need real synthetic enrollment to prove rollback refusal');
const on=execute(artifact);
assert.notEqual(on.status,0,'Rollback with Core ON must be blocked');
assert.match(on.stderr||'',/weekly_rollback_requires_core_off/);
const off=`UPDATE private.exam_prep_feature_config SET rollout_state='off',core_enabled=false,
 ai_enabled=false,mentor_enabled=false,kill_switch=true WHERE program_key='math_as_p1_p5';`;
const inject=statement=>artifact.replace(/^BEGIN;/,`BEGIN;\n${statement}\n`);
const whileEnrolled=execute(inject(off));
assert.notEqual(whileEnrolled.status,0,'Rollback with a learner enabled must be blocked');
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
const restored=named(sql(inTransaction),'RESTORED');
assert.equal(restored,'7','Seven original bodies must match within the rollback transaction');
assert.equal(named(sql(fixture),'FIXTURE'),before,'Rollback rehearsal touched learner records');
assert.equal(Number(named(sql(`SELECT 'ENROLLED='||count(*)
 FROM private.exam_prep_weekly_flow_enrollment_v1 WHERE enabled IS TRUE;`),'ENROLLED')),
 enrolled,'Rollback rehearsal changed enrollment state');
assert.equal(named(sql(`SELECT 'CANDIDATE='||count(*) FROM private.exam_prep_weekly_flow_rpc_backup_v1 b
 WHERE md5(pg_get_functiondef(b.function_oid))=b.installed_md5;`),'CANDIDATE'),'7',
 'Rollback rehearsal did not leave candidate in place');
console.log('EXACT ROLLBACK PACKAGE GREEN: refused Core ON and enabled users, restored seven functions inside transaction, rolled back the rehearsal.');
console.log('All prior synthetic evidence and the sealed candidate remain unchanged; live SQL never accessed.');
