#!/usr/bin/env node
'use strict';
// Issue #450 P4-06 fail-closed source-only audit of the corrective PR scope.
// No network, no database connection, no human grades, no production secrets.
const assert=require('node:assert/strict');
const fs=require('node:fs');
const path=require('node:path');
const root=path.resolve(__dirname,'..');
const source=p=>fs.readFileSync(path.join(root,p),'utf8');
const paths=[
 'supabase/migrations/20261105153000_exam_prep_p1p5_timed_execution_comparable_v1.sql',
 'supabase/migrations/20261105154000_exam_prep_p1p5_stage3_stage4_execution_evidence_v1.sql',
 'supabase/migrations/20261105155000_exam_prep_p1p5_stage5_operational_calibration_v1.sql',
 'supabase/migrations/20261105160000_exam_prep_p1p5_timed_finalization_state_sync_v1.sql'
];
const [execution,stage34,calibration,sync]=paths.map(source);
const selfMark=source('supabase/migrations/20261104110000_exam_prep_p1p5_disable_written_self_marks_v1.sql');
const signed=source('scripts/p1p5-isolated-http-positive-mixed-timed.cjs');
const triple=source('scripts/p1p5-isolated-http-three-full-papers.cjs');
const blank=source('scripts/p1p5-isolated-http-skipped-paper-denial.cjs');
const sqlThree=source('supabase/tests/p1p5_p4_05_three_full_papers_disposable.sql');
const sqlBlank=source('supabase/tests/p1p5_p4_05_blank_paper_negative_disposable.sql');
const runtime=source('supabase/tests/p1p5_p4_06_runtime_writer_acl_disposable.sql');
const workflow=source('.github/workflows/exam-prep-p1p5-isolated-http-e2e.yml');
const roadmap=source('docs/math-p1p5-v2-1-stage3-6-written-evidence-recovery-plan-20261105.md');
const release=source('docs/math-p1p5-p4-06-release-integration-checkpoint-20261105.md');
function requireAll(src,tokens,label){
 for(const t of tokens)assert(src.includes(t),label+' missing '+t);
}
requireAll(selfMark,['exam_prep_written_self_marks_disabled','exam_prep_timed_score_comparable_v1'],
 'No student self-awarded written marks rule');
requireAll(execution,['private.exam_prep_timed_execution_comparable_v1',
 't.answered_items>0','private.exam_prep_responses',
 "t.attempt_kind<>'diagnostic_full'",'exam_prep_integrity_allows_timed_comparability_v1',
 'REVOKE ALL','FROM PUBLIC,anon,authenticated','service_role'],
 'P4-02 strict execution comparator');
requireAll(stage34,['exam_prep_stage3_exit_status_v1','exam_prep_stage4_raw_evidence_v1',
 'exam_prep_stage4_timed_section_gate_v1','v_replacements<>1',
 'exam_prep_timed_execution_comparable_v1','search_path','REVOKE ALL'],
 'P4-03 scoped stage reader rewrite');
requireAll(calibration,['exam_prep_stage5_operational_completion_v1',
 'operational_calibration_access','v_rule.min_comparable_full_attempts',
 'require_all_skills_l3','require_all_corrections_closed',
 'exam_readiness_claim','false','mentor_required','REVOKE ALL'],
 'P4-04 Core graduation independent from verified grades');
requireAll(sync,['finalize_exam_prep_timed_safe_v1','insert into private.exam_prep_timed_attempt_results',
 'v_answered>0','perform private.rebuild_exam_prep_state_v1(v_uid,v_s.component_code)',
 'v_hits<>1','SECURITY DEFINER','search_path TO','REVOKE ALL','FROM PUBLIC,anon'],
 'P4-05 post-ledger state rebuild');
requireAll(triple,['stage4_full_paper_02','stage4_full_paper_03',
 'stage2_timed_block_02','proveSignedTimedClock','scoreComparable===false',
 'signedReplaysChecked','assert.equal(used.size,3','get_exam_prep_timed_catalog_safe_v1'],
 'P4-05 real signed full Paper ladder');
requireAll(blank,['EMPTY SIGNED PAPER NEGATIVE PASS','replay.replayed===true',
 'latest.answered_items===0','evidence?.executed===false',
 'get_exam_prep_timed_catalog_safe_v1','operationalStagesPreserved'],
 'P4-05 fully skipped Paper negative');
requireAll(sqlThree,['v_total<>3','v_exec<>3','v_scored<>0','v_stage<>6',
 'INSUFFICIENT_EVIDENCE','v_mentor','exam_readiness_claim'],
 'P4-05 positive gate');
requireAll(sqlBlank,['v_total<>4','v_exec<>3','v_blank<>1',
 'INSUFFICIENT_EVIDENCE','v_stage<>6','v_saved<>'],
 'P4-05 blank gate');
const steps=[
 'P4-05 complete Stage 3 with actual server-verified objective mastery',
 'P4-05 THREE unique signed full Papers for each P1 and P5',
 'P4-05 strict source-backed three-Paper score firewall in isolated PG17',
 'P4-05 fully skipped official Paper must not count as a completed work',
 'P4-05 saved blank Paper remains outside all three execution-grade counts',
 'Complete and cleanup canonical mixed/full-paper synthetic learner'
];
let last=-1;
for(const s of steps){const i=workflow.indexOf('      - name: '+s);
 assert(i>last,'Workflow out-of-order or missing Stage3–6/cleanup proof: '+s);
 last=i;
}
assert(workflow.includes("test \"$PGHOST\" = \"127.0.0.1\""),
 'P4-05 POSTGRES cannot point at a nonisolated host');
assert(!/\b(?:CREATE\s+TABLE|ALTER\s+TABLE|DROP\s+TABLE|TRUNCATE\s+TABLE)\b/i.test(
 paths.map(source).join('\n').replace(/--[^\n]*/g,'')),
 'P4 corrective migration unexpectedly alters shared table schema');
requireAll(runtime,[
 'current_setting(\'iclub.e2e_isolated\'',
 'has_function_privilege',
 'authenticated',
 'anon',
 'SECURITY DEFINER',
 'private.exam_prep_timed_score_comparable_v1',
 'exam_prep_stage5_operational_completion_v1',
 'INSUFFICIENT_EVIDENCE',
 'P4-06 PASS: five private ACLs',
 'P0-16B'
],'P4-06 independent real runtime ACL/grade/source writer proof');
assert(workflow.includes('supabase/tests/p1p5_p4_06_runtime_writer_acl_disposable.sql') && workflow.includes('P4-06 exact runtime service-role'),
 'P4-06 runtime writer guard not scheduled before synthetic cleanup');
requireAll(roadmap,['P4-05','P4-06','NO_GO','P0-16B'],
 'Canonical roadmap');
requireAll(release,['P4-05','P4-06','NO_GO','P0-16B',
 'not a release','96b974241518bac7c74594734e409c80b9ef5f24'],
 'Release checkpoint');
assert.throws(()=>requireAll(triple.replaceAll('scoreComparable===false',''),
 ['scoreComparable===false'],'negative regression'),'missing');
assert.throws(()=>requireAll(blank.replace('latest.answered_items===0',''),
 ['latest.answered_items===0'],'negative regression'),'missing');
assert.throws(()=>requireAll(sync.replace('v_hits<>1',''),
 ['v_hits<>1'],'negative regression'),'missing');
console.log('P4-06 PASS: scoped migrations, score firewall, full signed Paper ladder, blank negatives, source guards, ordered cleanup; NO RELEASE GO');
