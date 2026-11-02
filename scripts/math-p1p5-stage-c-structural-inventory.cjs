#!/usr/bin/env node
'use strict';
// Stage C source-version-aware structural/regression gate. All DB operations
// are SELECT-only and remain inside the disposable CI PostgreSQL container.
// No answers, rubrics, student records or item text are included in stdout.
const assert=require('node:assert/strict');
const fs=require('node:fs');
const {execFileSync}=require('node:child_process');
const path=require('node:path');
const file=path.resolve('scripts/fixtures/math-p1p5-stage-c-structural-integrity-readonly.sql');
const content=fs.readFileSync(file,'utf8');
const executable=content.replace(/^\s*--.*$/gm,'').trim().toLowerCase();
assert(executable.startsWith('with q as ('),'structural inventory must be one read-only query');
assert(!/\b(insert|update|delete|truncate|alter|drop|create|grant|revoke|execute|copy|do|perform)\b/.test(executable),
 'REFUSED SQL with possible mutation');
assert(process.env.CI==='true'&&process.env.P1P5_E2E_ISOLATED==='true'&&
 process.env.PGHOST==='127.0.0.1'&&process.env.PGPORT==='5432'&&
 process.env.PGDATABASE==='postgres','REFUSED non-disposable database');
const raw=execFileSync('psql',['-X','-At','-v','ON_ERROR_STOP=1','-f',file],{encoding:'utf8',maxBuffer:1024*1024});
const lines=raw.trim().split('\n').filter(Boolean);
assert(lines.length===1,'one structural source snapshot expected');
const x=JSON.parse(lines[0]);
const bad=[
 'bad_question_text_or_answer','bad_question_qa','bad_written_qa_locale',
 'incorrect_exposure','missing_question_skill','missing_written_skill',
 'missing_assessment_question','cross_paper_question','cross_paper_written',
 'withheld_in_learning','retired_in_published_assessment','invalid_assessment_item_target',
 'released_holdout_mismatch'
];
assert.equal(x.syllabus_skills,81,'P1/P5 syllabus skill count drift');
assert.equal(x.canonical_models,15,'canonical learner scenario set drift');
assert.equal(x.adversarial_models,18,'adversarial learner model drift');
assert.equal(x.all_question_versions,x.active_question_versions+x.retired_question_versions,
 'historic question version classification broken');
assert.equal(x.active_question_versions,x.released_learning_questions+x.protected_reserve_questions,
 'published vs protected/reserve/retired split invalid');
assert.equal(x.all_written_versions,x.active_written_versions,
 'untracked historic written task state; inventory must be updated explicitly');
assert(x.active_question_versions>0&&x.active_written_versions>0&&x.all_assessment_routes>0,
 'empty Exam Prep content cannot pass an inventory');
for(const key of bad)assert.equal(x[key],0,'structural integrity failure: '+key);
console.log('STAGE C P1/P5 VERSIONED STRUCTURAL ROUTING & 15+18 SCENARIO CATALOG PASS',JSON.stringify({
 actualActiveContent:x.active_question_versions+x.active_written_versions,
 publishedLearning:x.released_learning_questions,protectedReserve:x.protected_reserve_questions,
 publishedWritten:x.active_written_versions,retiredPreserved:x.retired_question_versions,
 assessmentItemRoutes:x.all_assessment_routes,skills:x.syllabus_skills,
 canonical:x.canonical_models,adversarial:x.adversarial_models,
 integrityAsserts:bad.length,allBadZero:true,migrationOnly:true
}));
