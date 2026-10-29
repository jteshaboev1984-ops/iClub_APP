#!/usr/bin/env node
'use strict';
// All content in these tests is fictional synthetic text. No learner data.
const {test}=require('node:test');
const assert=require('node:assert/strict');
const fs=require('node:fs');
const os=require('node:os');
const path=require('node:path');
const crypto=require('node:crypto');
const {canonical}=require('./qa-economics-private-originals-v1.cjs');
const {validate}=require('./qa-economics-private-retest-71-v1.cjs');
const digest=b=>crypto.createHash('sha256').update(b).digest('hex');
const closed={program_key:'economics_9708',version_key:'economics_2026_2028_v1',
  release_enabled:false,ready_for_public_exam:false,
  ready_for_server_authorization:false,private_server_import_status:'not_imported',
  retest_authorization_status:'hold'};
function fixture(){
  const dir=fs.mkdtempSync(path.join(os.tmpdir(),'econ-private-retest-'));
  const paths=['all.json','old.json','new.json'].map(x=>path.join(dir,x));
  const items=[];
  for(let i=0;i<71;i++){
    const paper=i<35?'P1':'P3';
    const unit=paper==='P1'?(1+i%6):(7+i%5);
    const point=unit+'.1.'+(i+1);
    const key='ABCD'[i%4];
    const item={item_key:'SYNTH-'+i,paper_code:paper,
      syllabus_point:point,skill_key:'ECON-9708-'+point+'-SYNTH-'+i,
      assessment_role:'independent_skill_retest_candidate',
      book_ref:'Synthetic mock chapter for private release-gate unit tests',
      academic_status:'internal_synthetic_draft',release_enabled:false,
      correct_answer:key,distractor_notes_en:Object.fromEntries('ABCD'.split('')
        .filter(k=>k!==key).map(k=>[k,'Synthetic note for unselected distractor.']))};
    for(const loc of ['en','ru','uz'])item[loc]={
      question:'Synthetic fictional economics private offline QA test question number '+i+' in '+loc+'?',
      explanation:'This synthetic explanation is only a test fixture and contains no protected course material.',
      options:['Synthetic option 1','Synthetic option 2','Synthetic option 3','Synthetic option 4']};
    item.content_sha256=canonical(item);
    items.push(item);
  }
  // Combined order freezes 36 prior and 35 new; paper quotas must be 35/36.
  const old={...closed,items:items.slice(0,36)};
  const batch={...closed,items:items.slice(36),items_canonical_sha256:canonical(items.slice(36))};
  const all={...closed,contract:'econ_original_mcq_targeted_same_skill_retest_candidates_v1',
    papers:{P1:35,P3:36},items,items_canonical_sha256:canonical(items),source_files:[]};
  const saveSource=()=>{fs.writeFileSync(paths[1],JSON.stringify(old));fs.writeFileSync(paths[2],JSON.stringify(batch));};
  const saveFull=()=>fs.writeFileSync(paths[0],JSON.stringify(all));
  const pin=()=>{
    all.items_canonical_sha256=canonical(all.items);
    batch.items_canonical_sha256=canonical(batch.items);
    saveSource();
    all.source_files=[{name:'old.json',sha256:digest(fs.readFileSync(paths[1]))},
      {name:'new.json',sha256:digest(fs.readFileSync(paths[2]))}];
    saveFull();
  };
  pin();
  return {dir,paths,all,old,batch,pin,saveFull,saveSource};
}
function withCase(f){const x=fixture();try{f(x)}finally{fs.rmSync(x.dir,{recursive:true,force:true})}}
function fails(x,regex){assert.throws(()=>validate(...x.paths),regex)}
test('synthetic 71 source candidates pass integrity; release stays blocked',()=>withCase(x=>{
  const y=validate(...x.paths);
  assert.equal(y.items,71);assert.equal(y.release_authorized,false);
}));
test('reject future-public release switch',()=>withCase(x=>{
  x.all.ready_for_public_exam=true;x.saveFull();fails(x,/release gate/);
}));
test('reject source import state',()=>withCase(x=>{
  x.all.private_server_import_status='imported';x.saveFull();fails(x,/server import/);
}));
test('reject live retest authorization switch',()=>withCase(x=>{
  x.all.retest_authorization_status='open';x.saveFull();fails(x,/retest must stay held/);
}));
test('reject tampered frozen original 36',()=>withCase(x=>{
  x.all.items[0].en.question+=' tampered';x.saveFull();fails(x,/historic content changed/);
}));
test('reject tampered new source bytes',()=>withCase(x=>{
  fs.appendFileSync(x.paths[2],' ');fails(x,/source bytes changed/);
}));
test('reject duplicated skill across candidate papers',()=>withCase(x=>{
  x.all.items[70].skill_key=x.all.items[65].skill_key;
  x.all.items[70].syllabus_point=x.all.items[65].syllabus_point;
  x.pin();fails(x,/duplicate live skill/);
}));
test('reject invalid unit in Paper 3',()=>withCase(x=>{
  x.all.items[70].syllabus_point='2.1.1';
  x.batch.items[34]=x.all.items[70];x.pin();fails(x,/wrong syllabus unit/);
}));
test('reject wrong answer key',()=>withCase(x=>{
  x.all.items[70].correct_answer='E';x.batch.items[34]=x.all.items[70];x.pin();
  fails(x,/wrong A-D key/);
}));
test('reject missing RU stem',()=>withCase(x=>{
  x.all.items[70].ru.question='';
  x.all.items[70].content_sha256=canonical(Object.fromEntries(Object.entries(x.all.items[70]).filter(([k])=>k!=='content_sha256')));
  x.pin();
  fails(x,/missing localized stem/);
}));
test('reject repeated UZ options',()=>withCase(x=>{
  x.all.items[70].uz.options[1]=x.all.items[70].uz.options[0];
  x.all.items[70].content_sha256=canonical(Object.fromEntries(Object.entries(x.all.items[70]).filter(([k])=>k!=='content_sha256')));
  x.pin();fails(x,/duplicate options/);
}));
test('reject content tampering without individual SHA renewal',()=>withCase(x=>{
  x.all.items[70].en.question+=' adversarial edit';x.batch.items[34]=x.all.items[70];x.pin();
  fails(x,/tampered item/);
}));