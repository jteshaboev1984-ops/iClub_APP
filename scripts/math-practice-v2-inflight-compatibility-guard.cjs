#!/usr/bin/env node
'use strict';

const fs=require('fs');
const path=require('path');
const ROOT=path.resolve(__dirname,'..');

const releasePath=path.join(ROOT,'supabase','migrations','20261007007500_math_practice_v2_atomic_release_switch_v1.sql');
const auditPath=path.join(ROOT,'supabase','preflight','math_practice_v2_inflight_compatibility_audit.sql');

const release=fs.readFileSync(releasePath,'utf8');
const audit=fs.readFileSync(auditPath,'utf8');

const bridge=[
  'get_practice_session_resume_safe_v4(bigint)',
  'submit_practice_session_answer_safe_v4(bigint,bigint,text,integer,integer)',
  'finalize_practice_session_safe_v4(bigint,integer)',
  'get_practice_drill_resume_safe_v4(bigint)',
  'submit_practice_drill_answer_safe_v4(bigint,bigint,text,integer,integer)',
];

const errors=[];
for(const signature of bridge){
  if(!audit.includes(signature)) errors.push('compatibility audit missing '+signature);
  const escaped=signature.replace(/[.*+?^$()|[\]\\{}]/g,'\\$&');
  const revokePattern=new RegExp('revoke\\s+execute\\s+on\\s+function\\s+public\\.'+escaped,'i');
  if(revokePattern.test(release)) errors.push('release revokes in-flight bridge '+signature);
}

if(!/begin;\s*set transaction read only;/i.test(audit)) errors.push('compatibility audit is not read-only');
if(!/rollback;\s*$/i.test(audit.trim())) errors.push('compatibility audit does not roll back');

console.log(JSON.stringify({
  ok:errors.length===0,
  bridgeCount:bridge.length,
  releaseKeepsInflightBridge:errors.length===0,
  errors
},null,2));

for(const e of errors) console.error('ERROR:',e);
if(errors.length) process.exit(1);
