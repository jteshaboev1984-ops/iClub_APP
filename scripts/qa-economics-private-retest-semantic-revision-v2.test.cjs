#!/usr/bin/env node
'use strict';
const test=require('node:test');
const assert=require('node:assert/strict');
const crypto=require('node:crypto');
const {canonical}=require('./qa-economics-private-originals-v1.cjs');
const {examine}=require('./qa-economics-private-retest-semantic-revision-v2.cjs');
const sha=x=>crypto.createHash('sha256').update(x).digest('hex');
const c=question=>({question:question.repeat(4),options:['choice a','choice b','choice c','choice d'],explanation:'This purely synthetic academic explanation is unrelated to any real bank. It explains a fictional scenario.'});
const item=(key,paper,skill)=>{
  const x={item_key:key,paper_code:paper,skill_key:skill,syllabus_point:paper==='P1'?'1.1.1':'7.1.1',
    correct_answer:'A',en:c('Fictional context old one. '),ru:c('Fictional context old two. '),
    uz:c('Fictional context old three. '),
    distractor_notes_en:{B:'No',C:'No',D:'No'},academic_status:'internal_candidate',release_enabled:false};
  x.content_sha256=canonical(x);
  return x;
};
function fixture(){
  const original={program_key:'economics_9708',version_key:'economics_2026_2028_v1',
    papers:{P1:1,P3:1},release_enabled:false,ready_for_public_exam:false,
    ready_for_server_authorization:false,private_server_import_status:'not_imported',
    retest_authorization_status:'hold',items:[
      item('fiction-1','P1','fiction-skill-1'),item('fiction-2','P3','fiction-skill-2')]};
  const before=Buffer.from(JSON.stringify(original),'utf8');
  const revised=JSON.parse(JSON.stringify(original));
  const j=revised.items[1];
  for(const k of ['en','ru','uz']){
    j[k].question='Entirely new fictional topic with alternate methods and different causal reasoning. '.repeat(2);
    j[k].explanation='This is a fictional scenario. Both the event and the explanatory causal chain have been changed for this controlled test.';
  }
  j.content_sha256=canonical(Object.fromEntries(Object.entries(j).filter(([k])=>k!=='content_sha256')));
  revised.parent_combined_file_sha256=sha(before);
  revised.revision_changes=[{item_key:j.item_key,paper_code:j.paper_code,skill_key:j.skill_key,
     previous_item_sha256:original.items[1].content_sha256,
     updated_item_sha256:j.content_sha256,key_unchanged:true}];
  revised.items_canonical_sha256=canonical(revised.items);
  return {original,revised,before};
}
function run(x){return examine(x.original,x.revised,x.before,{expectedCount:2,expectedChanges:1})}
test('passes one revised and one untouched synthetic item',()=>{
  assert.deepEqual(run(fixture()),{status:'PRIVATE_SEMANTIC_REVISION_INTEGRITY_PASS_RELEASE_HOLD',items:2,changed:1,unchanged:1,release_authorized:false});
});
test('blocks unexpected modification of untouched item',()=>{
  const x=fixture();x.revised.items[0].en.question+=' altered';x.revised.items_canonical_sha256=canonical(x.revised.items);
  assert.throws(()=>run(x));
});
test('blocks forged lineage',()=>{
  const x=fixture();x.revised.parent_combined_file_sha256='0'.repeat(64);assert.throws(()=>run(x));
});
test('blocks release switch',()=>{
  const x=fixture();x.revised.release_enabled=true;assert.throws(()=>run(x));
});
test('blocks source answer key change',()=>{
  const x=fixture();x.revised.items[1].correct_answer='B';x.revised.items_canonical_sha256=canonical(x.revised.items);assert.throws(()=>run(x));
});
test('blocks untranslated revision',()=>{
  const x=fixture();x.revised.items[1].uz=x.original.items[1].uz;x.revised.items[1].content_sha256=canonical(Object.fromEntries(Object.entries(x.revised.items[1]).filter(([k])=>k!=='content_sha256')));
  x.revised.revision_changes[0].updated_item_sha256=x.revised.items[1].content_sha256;
  x.revised.items_canonical_sha256=canonical(x.revised.items);
  assert.throws(()=>run(x));
});
test('blocks unapproved skill reassignment',()=>{
  const x=fixture();x.revised.items[1].skill_key='another';x.revised.items_canonical_sha256=canonical(x.revised.items);assert.throws(()=>run(x));
});
