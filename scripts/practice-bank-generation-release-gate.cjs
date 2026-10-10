#!/usr/bin/env node
'use strict';
const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict');
const root=path.resolve(__dirname,'..');
const read=p=>fs.readFileSync(path.join(root,p),'utf8');
const schema=read('supabase/migrations/20261010130000_practice_bank_generations_all_subjects_v1.sql');
const rpc=read('supabase/migrations/20261010131000_practice_bank_recommendations_safe_v1.sql');
const app=read('app.js');
const checks=[
 ['sql-no-escaped-newline',!schema.includes('\\n')],
 ['per-subject-registry',schema.includes('from public.subjects')],
 ['audited-math-publication',schema.includes("release_version='math_p1_practice_v2_2026_10_07'")],
 ['immutable-main-session',schema.includes('practice_bank_generation_immutable')],
 ['immutable-drill-session',schema.includes('practice_drill_stamp_bank_generation_v1')],
 ['legacy-classification',schema.includes('update public.recommendations r set bank_generation=')],
 ['source-linked-recommendations',schema.includes('practice_recommendation_origin_mismatch')],
 ['finalized-only-rpc',rpc.includes("status='finalized'")],
 ['server-verified-mistakes',rpc.includes('a.is_correct=false')],
 ['idempotent-retries',rpc.includes('on conflict do nothing')],
 ['current-generation-read',rpc.includes('bank_generation=v_generation')],
 ['client-safe-write',app.includes('sync_practice_recommendations_safe_v1')],
 ['client-safe-read',app.includes('get_current_practice_recommendations_safe_v1')],
 ['no-local-legacy-revival',app.includes('dbRows.practiceBankScoped !== true')],
 ['single-practice-history',!app.includes('data-my-practice-mode="topics"')],
 ['practice-result-links-my-recs',app.includes('pushCourses("my-recs");')],
 ['tour-tab-preserved',app.includes('data-myrecs-tab')],
 ['no-user-progress-delete',!schema.includes('delete from public.practice_attempts')&&!schema.includes('truncate public.')]
];
for(const [name,pass] of checks){console.log((pass?'PASS':'FAIL')+' '+name);assert(pass,name);}
console.log('PRACTICE_GENERATION_RELEASE_STATIC_GATE_OK '+checks.length);
