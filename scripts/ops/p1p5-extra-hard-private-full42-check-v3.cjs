#!/usr/bin/env node
'use strict';
// Local-only, read-only protected source integrity and syllabus coverage.
// NO protected task text, answers or worked solutions in this public script.
const assert=require('node:assert/strict');
const fs=require('node:fs');
const path=require('node:path');
const crypto=require('node:crypto');
const EXPECTED_SHA='2283f0a35697349dac6825accd199e85fc72bb61d4ac5f8b4aca9e5adaeea77b';
const BANK='math-extra-hard-2026-11-full-v3';
const FIELDS=['task_key','bank_version','component_code','primary_skill_code',
 'official_section','book_map','title_i18n','prompt_i18n','solution_i18n','exact_answer'];
const EXCLUDE_PUBLISHED=true;
const sha=x=>crypto.createHash('sha256').update(x).digest('hex');
function stable(v){
 if(Array.isArray(v))return '['+v.map(stable).join(',')+']';
 if(v&&typeof v==='object')return '{'+Object.keys(v).sort().map(k=>JSON.stringify(k)+':'+stable(v[k])).join(',')+'}';
 return JSON.stringify(v);
}
function category(t){
 if(t.component_code==='P1')return String(t.official_section).slice(0,3);
 if(t.primary_skill_code.startsWith('P5-GEO-'))return '5.4G';
 if(t.primary_skill_code.startsWith('P5-BIN-'))return '5.4B';
 return String(t.official_section).slice(0,3);
}
const expected=['1.1','1.2','1.3','1.4','1.5','1.6','1.7','1.8','5.1','5.2','5.3','5.4G','5.4B','5.5'];
function check(filename){
 const src=path.resolve(filename);
 // Owner-private source must never be under a Git working copy.
 const repo=path.resolve(__dirname,'..','..')+path.sep;
 assert(!src.startsWith(repo),'Protected Extra Hard source must remain OUTSIDE the public repository');
 assert(fs.statSync(src).size>10000&&fs.statSync(src).size<1000000,'Private bank size outside approved limits');
 const bytes=fs.readFileSync(src),hash=sha(bytes);
 assert.equal(hash,EXPECTED_SHA,'42-task protected source SHA mismatch: refusing unreviewed file');
 const bank=JSON.parse(bytes.toString('utf8'));
 assert.equal(bank.format_version,'iclub.extra_hard.private_bank_v3');
 assert.equal(bank.program_key,'math_as_p1_p5');
 assert.equal(bank.program_version_key,'p1_p5_canonical_v1_0');
 assert.equal(bank.bank_version,BANK);
 assert.equal(bank.release_enabled,false);
 assert.equal(bank.academic_approved,false);
 assert(Array.isArray(bank.tasks)&&bank.tasks.length===42);
 const ids=new Set(),conditions=new Set(),groups=new Map();
 let p1=0,p5=0,drafts=0,approvals=0;
 for(const t of bank.tasks){
  assert(/^EH26-P[15]-[A-Z]{3}-\d{2}-\d{2}$/.test(t.task_key),'Invalid private task identifier');
  assert(!ids.has(t.task_key),'Duplicate protected ID'); ids.add(t.task_key);
  assert(['P1','P5'].includes(t.component_code),'Invalid course');
  if(t.component_code==='P1')p1++;else p5++;
  assert(t.primary_skill_code.startsWith(t.component_code+'-'),'Wrong component/skill');
  assert(t.bank_version===BANK&&t.source_kind==='iclub_original');
  const canon={};for(const k of FIELDS)canon[k]=t[k];
  assert.equal(sha(stable(canon)),t.content_sha256,'Individual protected question SHA mismatch');
  for(const f of ['title_i18n','prompt_i18n','solution_i18n']){
   assert(t[f]&&typeof t[f]==='object');
   assert.deepEqual(Object.keys(t[f]).sort(),['en','ru','uz']);
   for(const lang of ['en','ru','uz']){
    assert(typeof t[f][lang]==='string'&&t[f][lang].trim().length>10,'Incomplete language version');
   }
  }
  assert(t.qa_math==='approved','Math verification incomplete');
  assert(['approved','pending'].includes(t.qa_languages),'Invalid language QA');
  assert(['approved','pending'].includes(t.qa_technical),'Invalid technical QA');
  assert(['draft','approved'].includes(t.lifecycle_status));
  if(t.lifecycle_status==='draft'){
   drafts++;
   assert(t.qa_languages==='pending'&&t.qa_technical==='pending','Draft review flags inconsistent');
  }else{
   approvals++;
   assert(t.qa_languages==='approved'&&t.qa_technical==='approved','Approved item flags inconsistent');
  }
  if(EXCLUDE_PUBLISHED)assert(t.lifecycle_status!=='published','Protected item unexpectedly published');
  const condition=t.prompt_i18n.en.normalize('NFKC').replace(/\s+/g,' ').trim().toLowerCase();
  assert(!conditions.has(condition),'Duplicate mathematical condition');conditions.add(condition);
  const group=category(t); assert(expected.includes(group),'Unknown official syllabus strand');
  groups.set(group,(groups.get(group)||0)+1);
 }
 assert.equal(p1,24);assert.equal(p5,18);assert.equal(drafts,0);assert.equal(approvals,42);
 assert.equal(groups.size,14);
 for(const k of expected)assert.equal(groups.get(k),3,'Incorrect strand group count');
 console.log('EXTRA HARD PRIVATE FULL42 CHECK PASS: 42 unique content hashes; P1=24 P5=18; 14 strands x3; math QA approved; language/technical reviewed internally 42/42; NO external examiner; release OFF.');
 return bank;
}
if(process.argv.length!==3){
 console.error('Usage: node scripts/ops/p1p5-extra-hard-private-full42-check-v3.cjs /absolute/owner-private/full42.json');
 process.exitCode=2;
}else{
 try{check(process.argv[2]);}catch(e){console.error('Extra Hard private integrity check refused:',e.message);process.exitCode=1;}
}