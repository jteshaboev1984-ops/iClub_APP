'use strict';
// Mathematics P1/P5 Stage D: fail-closed exact-SHA multi-workflow gate.
// Pure inspection of external GitHub Actions evidence. Never calls Supabase,
// changes access flags, authorizes a rollout, or fabricates real beta results.

const REQUIRED = Object.freeze({
 'Mathematics P1 P5 disposable real HTTP Auth diagnostic E2E': [
  'Run ACTUAL authenticated HTTP P1 and P5 browser diagnostic, owned resume, security denial',
  'Reconcile lost ACK and resume Math P5 in NEW browser over real signed HTTP',
  'Complete genuine post-due retest using signed HTTP and P2-68 governed clock',
  'Run real signed HTTP governed mixed and full-paper attempt with noncredit written self-marks',
  'True Chromium P1/P5 written criteria, three languages, Next, lost ACK and browser reopen',
  'Stage C signed HTTP JWT expiry, two-paper parallel retries, owner security and kill-switch safety',
  'Stage C run 33 source-mapped synthetic actors through real P1/P5 server-graded Stage0 and atomic rollback',
  'Stage C earn independent P1/P5 objective levels and real wrong-learning corrections, then atomic rollback',
  'Stage C consolidated 16 recovery cases, governed noncredit revalidation, stale plan and profile revision with atomic rollback',
  'Stage C real signed learner HTTP stale content, expired authorization, feedback and exactly-once retry'
 ],
 'P2-78 600-10 Concurrency and Service Transitions': [
  'Run 600-client concurrency and service transitions',
  'Recheck AI outage/fallback with fake provider only',
  'Governed completion cleanup and zero-residue proof',
  'Verify post-cleanup production-shaped boundary'
 ],
 'P2-79 Recovery Rollback Disaster Rehearsal': [
  'Run isolated recovery rollback disaster matrix',
  'Rehearse previous known-good commit rollback',
  'Recheck current Core browser journey after disaster recovery',
  'Verify final zero-residue production-shaped boundary'
 ]
});

const SHA=/^[a-f0-9]{40}$/;
function evaluate(candidateSha, workflowRuns, jobsByRunId) {
 if(typeof candidateSha!=='string'||!SHA.test(candidateSha))throw Error('Invalid 40-hex candidate SHA');
 if(!Array.isArray(workflowRuns)||!jobsByRunId||typeof jobsByRunId!=='object')
  throw Error('Missing live Actions evidence');
 const findings=[],accepted=[],pending=[],failures=[];
 for(const [name,requiredSteps] of Object.entries(REQUIRED)){
  const matching=workflowRuns.filter(r=>r&&r.name===name&&
   r.head_sha===candidateSha&&r.event==='pull_request'&&
   Number.isSafeInteger(r.id)&&r.id>0);
  matching.sort((a,b)=>(String(b.created_at||'').localeCompare(String(a.created_at||'')))||
   Number(b.run_attempt||1)-Number(a.run_attempt||1)||b.id-a.id);
  const latest=matching[0];
  if(!latest){
   pending.push(name);
   findings.push({workflow:name,verdict:'MISSING',reason:'No pull_request run at exact candidate SHA'});
   continue;
  }
  const entry={workflow:name,run_id:latest.id,run_attempt:latest.run_attempt||1,
   url:latest.html_url||null,head_sha:latest.head_sha,
   status:latest.status,conclusion:latest.conclusion};
  if(latest.status!=='completed'){
   pending.push(name);
   findings.push({...entry,verdict:'PENDING',reason:'Latest run not completed'});
   continue;
  }
  if(latest.conclusion!=='success'){
   failures.push(name);
   findings.push({...entry,verdict:'FAIL',reason:'Latest run is not successful'});
   continue;
  }
  const jobs=jobsByRunId[String(latest.id)];
  if(!Array.isArray(jobs)||jobs.length===0){
   pending.push(name);
   findings.push({...entry,verdict:'PENDING',reason:'Workflow job details unavailable'});
   continue;
  }
  if(jobs.some(j=>j.status!=='completed'||j.conclusion!=='success')){
   failures.push(name);
   findings.push({...entry,verdict:'FAIL',reason:'At least one job did not finish successfully'});
   continue;
  }
  const steps=jobs.flatMap(j=>Array.isArray(j.steps)?j.steps:[]);
  const missing=requiredSteps.filter(step=>!steps.some(s=>s.name===step&&
   s.status==='completed'&&s.conclusion==='success'));
  if(missing.length){
   failures.push(name);
   findings.push({...entry,verdict:'FAIL',reason:'Required real execution steps missing or non-green',
    missing_steps:missing});
   continue;
  }
  accepted.push(name);
  findings.push({...entry,verdict:'PASS',required_steps_verified:requiredSteps.length});
 }
 const engineering=failures.length?'FAIL':pending.length?'PENDING':'PASS';
 return {
  schema:'iclub.math_p1p5.stage_d.evidence.v1',
  candidate_sha:candidateSha,
  evidence_source:'GitHub Actions exact-SHA run + completed job steps',
  engine_verdict:engineering,
  findings,
  accepted_workflows:accepted.length,
  expected_workflows:Object.keys(REQUIRED).length,
  required_steps_total:Object.values(REQUIRED).reduce((n,x)=>n+x.length,0),
  pending,failures,
  verdicts:{
   content_published:{status:'NOT_ATTESTED',reason:'No production publish verification performed by this CI gate. The isolated academic published packs are exercised in Math E2E.'},
   engineering_e2e:{status:engineering,reason:'Only the exact-SHA required Actions and specific genuine run steps establish this result'},
   real_user_beta:{status:'UNVERIFIED',reason:'Hosted GoTrue, genuine consenting Telegram device, four authorized human reviews and 72-hour real-wave evidence must be observed separately'},
   mass_release:{status:'NO_GO',reason:'Automated technical CI cannot approve server-side expansion gates or replace architect approval'}
  },
  production_readonly_snapshot:'NOT_FETCHED_BY_GITHUB_CI',
  safe_unchanged_in_ci:['production_supabase','real_learner_progress','real_entitlements','legacy_practice_tours_certificates','production_local_storage'],
  approval_granted:false
 };
}
function markdown(report){
 const rows=report.findings.map(f=>
  '| '+f.workflow+' | '+f.verdict+' | '+(f.url?('[run]('+f.url+')'):'—')+
  ' | '+(f.required_steps_verified||0)+' |').join('\n');
 return '# Mathematics P1/P5 — Stage D evidence gate\n\n'+
  '**Candidate:** \x60'+report.candidate_sha+'\x60  \n'+
  '**Engineering E2E:** **'+report.engine_verdict+'** ('+report.accepted_workflows+'/'+
  report.expected_workflows+' independent exact-SHA workflows)\n\n'+
  '| Required workflow | Evidence | Link | Verified critical steps |\n'+
  '| --- | --- | --- | ---: |\n'+rows+'\n\n'+
  '| Separate verdict | State |\n| --- | --- |\n'+
  '| Production content publication | NOT ATTESTED by this CI |\n'+
  '| Isolated engineering E2E | '+report.engine_verdict+' |\n'+
  '| Real-user beta acceptance | UNVERIFIED |\n'+
  '| Mass rollout | **NO_GO** |\n\n'+
  '**No activation, release or production Supabase write was performed.** '+
  'Local JWT/PostgREST and simulated learners cannot substitute for hosted GoTrue, consenting Telegram phones, verified human reviews and a real monitored wave.\n';
}
module.exports={REQUIRED,evaluate,markdown};
