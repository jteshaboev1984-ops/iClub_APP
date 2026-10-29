#!/usr/bin/env node
'use strict';
// Synthetic fixture only: no user sessions, service keys, or academic answer content.
const {test}=require('node:test');
const assert=require('node:assert/strict');
const fs=require('node:fs');
const os=require('node:os');
const path=require('node:path');
const {validate,canonical}=require('./qa-economics-private-originals-v1.cjs');
function setup(){
  const dir=fs.mkdtempSync(path.join(os.tmpdir(),'econ-private-qa-'));
  const parts=[
    {paper:'P1',units:[1,2,3,4,5,6],counts:[6,6,6,6,3,3]},
    {paper:'P3',units:[7,8,9,10,11],counts:[3,3,2,2,2]}
  ];
  const banks=parts.map(group=>{
    let i=0;const items=[];
    for(let n=0;n<group.units.length;n++)for(let j=0;j<group.counts[n];j++){
      const point=group.units[n]+'.1.'+(j+1);
      const key='SYNTH-'+group.paper+'-'+(++i);
      const item={item_key:key,syllabus_point:point,skill_key:'ECON-9708-'+point+'-BASE',
        correct_answer:'A',ao:'AO2'};
      for(const locale of ['en','ru','uz'])item[locale]={
        question:'Synthetic '+locale+' test question '+key+' for a private QA fixture',
        options:['Synthetic option A','Synthetic option B','Synthetic option C','Synthetic option D'],
        explanation:'Synthetic offline-only explanation for a mocked question.'};
      item.review_hash_sha256=canonical(item);items.push(item);
    }
    return {paper_code:group.paper,program_key:'economics_9708',
      version_key:'economics_2026_2028_v1',release_enabled:false,
      ready_for_server_authorization:false,ready_for_public_exam:false,items,
      content_sha256:canonical(items), ...(group.paper==='P3'?{
        target_item_count:12,session_kind_target:'diagnostic'}:{})};
  });
  const paths=banks.map((bank,i)=>path.join(dir,parts[i].paper+'.json'));
  const write=()=>banks.forEach((bank,i)=>fs.writeFileSync(paths[i],JSON.stringify(bank)));
  write();return {dir,banks,paths,write};
}
function check(fn){
  const f=setup();
  try{fn(f)}finally{fs.rmSync(f.dir,{recursive:true,force:true})}
}
function reject(f,re){f.write();assert.throws(()=>validate(...f.paths),re)}
test('42 synthetic items: structural pass while release remains false',()=>check(f=>{
  const r=validate(...f.paths);
  assert.equal(r.total_items,42);
  assert.equal(r.production_release_authorized,false);
  assert.equal(r.independently_new_retest_bank_ready,false);
}));
test('deny already released source bank',()=>check(f=>{
  f.banks[1].release_enabled=true;reject(f,/released bank/)}));
test('deny unauthorized server release',()=>check(f=>{
  f.banks[0].ready_for_server_authorization=true;reject(f,/server release/)}));
test('deny wrong AS/A syllabus scope',()=>check(f=>{
  f.banks[1].items[0].syllabus_point='2.1.1';reject(f,/syllabus unit/)}));
test('deny duplicate keys across papers',()=>check(f=>{
  f.banks[1].items[0].item_key=f.banks[0].items[0].item_key;reject(f,/duplicate item key/)}));
test('deny duplicate options',()=>check(f=>{
  f.banks[0].items[0].en.options[2]='Synthetic option A';reject(f,/duplicate options/)}));
test('deny invalid answer label',()=>check(f=>{
  f.banks[0].items[0].correct_answer='E';reject(f,/answer label/)}));
test('deny missing locale explanation',()=>check(f=>{
  f.banks[0].items[0].uz.explanation='';reject(f,/missing explanation/)}));
test('deny silent question text mutation',()=>check(f=>{
  f.banks[0].items[0].en.question+=' tamper';reject(f,/historic hash/)}));
test('deny altered source digest',()=>check(f=>{
  f.banks[0].content_sha256='f'.repeat(64);reject(f,/P1 items digest drift/)}));
test('deny unaudited historic hash mismatch',()=>check(f=>{
  f.banks[0].items[0].review_hash_sha256='e'.repeat(64);reject(f,/historic hash/)}));
test('deny missing expected private source file',()=>check(f=>{
  f.banks[0].original_source_files=[{name:'missing-source.json',sha256:'f'.repeat(64)}];
  f.banks[0].new_gapfill_file={name:'gap.json',sha256:'f'.repeat(64)};
  f.banks[1].original_source_files=[];f.write();
  assert.throws(()=>validate(...f.paths,f.dir),/ENOENT/);
}));
