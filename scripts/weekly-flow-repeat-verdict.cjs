'use strict';
// Disposable GitHub Actions PostgreSQL 17 fixture ONLY. No production contact.
const assert=require('node:assert/strict');
const {spawnSync}=require('node:child_process');
const env=process.env;
if(env.GITHUB_ACTIONS!=='true'||env.PGHOST!=='127.0.0.1'||env.PGDATABASE!=='postgres'||
 !env.PGOPTIONS?.includes('weekly_goal.isolated_db=true')){
 console.error('REFUSED: repeat verdict test requires isolated CI database.');process.exit(1);
}
function psql(text){const p=spawnSync('psql',['-X','-q','-A','-t','-v','ON_ERROR_STOP=1'],{
 input:text,encoding:'utf8',timeout:30000,env});
 assert.equal(p.status,0,`Isolated SQL failed: ${(p.stderr||'').slice(-1400)}`);
 return p.stdout.trim();}
const before=psql(`SELECT count(*)::text||':'||
 (SELECT count(*) FROM private.exam_prep_session_authorizations)::text||':'||
 (SELECT count(*) FROM private.exam_prep_sessions)::text
 FROM private.exam_prep_evidence_events;`);
const fixture=`WITH f AS (
 SELECT user_id, (SELECT program_version_id FROM private.exam_prep_exam_profiles p WHERE p.user_id=f.user_id) AS program
 FROM weekly_goal_ci.fixture f),
 first_pack AS (
 SELECT a.id FROM private.exam_prep_assessments a
 WHERE a.component_code='P1' AND a.assessment_type='learning' AND a.status='published'
 AND EXISTS(SELECT 1 FROM private.exam_prep_assessment_items ai WHERE ai.assessment_id=a.id AND ai.primary_skill_code='P1-CIR-01')
 ORDER BY a.id LIMIT 1),
 seen_pack AS (
 SELECT s.assessment_id FROM private.exam_prep_sessions s
 JOIN f ON f.user_id=s.user_id WHERE s.component_code='P1' AND s.status='finalized' LIMIT 1)
 SELECT
 (private.exam_prep_learning_review_verdict_v1(f.user_id,f.program,'P1','P1-QUA-01',(SELECT assessment_id FROM seen_pack))->>'status')||':'||
 (private.exam_prep_learning_review_verdict_v1(f.user_id,f.program,'P1','P1-CIR-01',(SELECT id FROM first_pack))->>'status')||':'||
 (private.exam_prep_learning_review_verdict_v1(f.user_id,f.program,'P5','P1-QUA-01',(SELECT assessment_id FROM seen_pack))->>'status')||':'||
 (private.exam_prep_learning_review_verdict_v1(gen_random_uuid(),f.program,'P1','P1-QUA-01',(SELECT assessment_id FROM seen_pack))->>'status')
 FROM f;`;
const statuses=psql(fixture);
assert.equal(statuses,'repeat_learning:first_learning:unverifiable:unverifiable',
 `Unexpected first/repeat/component/owner verdict: ${statuses}`);
assert.equal(psql(`SELECT has_function_privilege('authenticated',
 'private.exam_prep_learning_review_verdict_v1(uuid,bigint,text,text,bigint)','EXECUTE')::text||':'||
 has_function_privilege('anon',
 'private.exam_prep_learning_review_verdict_v1(uuid,bigint,text,text,bigint)','EXECUTE')::text;`),'false:false');
const after=psql(`SELECT count(*)::text||':'||
 (SELECT count(*) FROM private.exam_prep_session_authorizations)::text||':'||
 (SELECT count(*) FROM private.exam_prep_sessions)::text
 FROM private.exam_prep_evidence_events;`);
assert.equal(after,before,'Read-only verdict changed learning history.');
console.log('PASS private repeat-learning verdict: prior incorrect QUA→review, unseen CIR→first, P5/cross-owner denied, academic history unchanged.');
console.log('Classification only: no repeat authorization, credit, correction or UI integration is claimed.');
