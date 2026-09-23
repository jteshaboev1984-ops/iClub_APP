'use strict';
// This MUST run last on GitHub Actions' disposable PostgreSQL 17 container.
// Synthetic writes here COMMIT solely so the two independent connections can
// observe each other; GitHub destroys the container immediately afterwards.
const assert = require('node:assert/strict');
const { spawn } = require('node:child_process');
const env=process.env;
if(env.GITHUB_ACTIONS!=='true'||env.PGHOST!=='127.0.0.1'||env.PGDATABASE!=='postgres'||
 !env.PGOPTIONS?.includes('weekly_goal.isolated_db=true')) {
 console.error('REFUSED: review concurrency fixture may only run in disposable GitHub CI.');
 process.exit(1);
}
function psql(text){return new Promise((resolve,reject)=>{
 const child=spawn('psql',['-X','-q','-A','-t','-v','ON_ERROR_STOP=1'],{
  env,stdio:['pipe','pipe','pipe']
 });
 let out='',err='';
 child.stdout.on('data',b=>out+=b);
 child.stderr.on('data',b=>err+=b);
 child.on('error',reject);
 child.on('close',status=>status===0?resolve(out):reject(new Error('CI PG failed: '+err.slice(-900))));
 child.stdin.end(text);
});}
function field(output,name){const matches=output.split(/\r?\n/).filter(x=>x.startsWith(name+'='));
 assert.equal(matches.length,1,'Missing '+name);return matches[0].slice(name.length+1);}
const prefix=`BEGIN;
SELECT set_config('request.jwt.claim.sub',(SELECT user_id::text FROM weekly_goal_ci.fixture LIMIT 1),true);
SELECT set_config('request.jwt.claim.role','authenticated',true);
SELECT 'BACKEND='||pg_backend_pid();`;
const request=(key)=>`${prefix}
SELECT 'REVIEW='||public.start_exam_prep_learning_review_safe_v1(
 'P1',(SELECT goal_id FROM weekly_goal_ci.fixture),(SELECT plan_id FROM weekly_goal_ci.fixture),
 '${key}')::text;
SELECT pg_sleep(0.35);
COMMIT;`;
(async()=>{
 const eligible=await psql(`SELECT 'ELIGIBLE='||count(*) FROM private.exam_prep_weekly_flow_enrollment_v1 e
 JOIN weekly_goal_ci.fixture f ON f.user_id=e.user_id WHERE e.enabled IS TRUE;`);
 assert.equal(field(eligible,'ELIGIBLE'),'1','Reviewed candidate must have one enrolled synthetic owner');
 await psql(`BEGIN;
INSERT INTO private.exam_prep_correction_cases(user_id,component_code,skill_code,status,engine_version,reason)
SELECT user_id,'P1','P1-QUA-01','open','objective_state_v1',
 '{"source":"disposable_review_two_backend_race"}'::jsonb
FROM weekly_goal_ci.fixture;
COMMIT;`);
 const [a,b]=await Promise.all([psql(request('disposable-review-race-first-01')),
  psql(request('disposable-review-race-second-02'))]);
 assert.notEqual(field(a,'BACKEND'),field(b,'BACKEND'),'Two independent PG connections required');
 const first=JSON.parse(field(a,'REVIEW')),second=JSON.parse(field(b,'REVIEW'));
 assert.deepEqual([first.status,second.status].sort(),['resume_existing_session_first','started']);
 assert.ok(first.session_id&&first.session_id===second.session_id,'Both devices must see identical session');
 const outcome=await psql(`SELECT 'COUNTS='||
 (SELECT count(*) FROM private.exam_prep_session_authorizations a JOIN weekly_goal_ci.fixture f ON f.user_id=a.user_id)::text||':'||
 (SELECT count(*) FROM private.exam_prep_sessions s JOIN weekly_goal_ci.fixture f ON f.user_id=s.user_id)::text||':'||
 (SELECT count(*) FROM private.exam_prep_learning_review_starts_v1 r JOIN weekly_goal_ci.fixture f ON f.user_id=r.user_id)::text||':'||
 (SELECT count(*) FROM private.exam_prep_weekly_plans p JOIN weekly_goal_ci.fixture f ON f.user_id=p.user_id)::text;`);
 assert.equal(field(outcome,'COUNTS'),'2:2:1:1',
  'Concurrent review duplicated auth/session or replaced stable plan');
 const credit=await psql(`SELECT 'NONCREDIT='||count(*) FROM private.exam_prep_learning_review_starts_v1 rv
 JOIN private.exam_prep_session_authorizations a ON a.id=rv.authorization_id
 JOIN weekly_goal_ci.fixture f ON f.user_id=rv.user_id
 WHERE a.academic_credit IS FALSE AND a.credit_context='learning_review'
 AND a.plan_id IS NULL AND a.consumed_session_id IS NOT NULL;`);
 assert.equal(field(credit,'NONCREDIT'),'1','Review must not get normal academic authorization');
 console.log('PASS two real PostgreSQL backends: one review authorization and session, stable original plan, no academic credit.');
 console.log('Disposable review concurrency fixture ends with CI database container destruction; production never accessed.');
})().catch(error=>{console.error(error);process.exitCode=1;});
