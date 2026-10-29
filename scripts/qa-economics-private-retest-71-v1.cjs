#!/usr/bin/env node
'use strict';
// OFFLINE ONLY: private candidate files are provided by the owner, never
// committed to the public repo, printed, uploaded to CI or sent to a browser.
// This gate does not approve academic content or authorize production release.
const fs=require('node:fs');
const path=require('node:path');
const crypto=require('node:crypto');
const assert=require('node:assert/strict');
const {canonical}=require('./qa-economics-private-originals-v1.cjs');
const hash=bytes=>crypto.createHash('sha256').update(bytes).digest('hex');
function validate(fullFile,oldFile,newFile){
  const files=[fullFile,oldFile,newFile];
  const [all,old,batch]=files.map(f=>JSON.parse(fs.readFileSync(f,'utf8')));
  for(const bank of [all,old,batch]){
    assert.equal(bank.program_key,'economics_9708','invalid program');
    assert.equal(bank.version_key,'economics_2026_2028_v1','invalid version');
    for(const gate of ['release_enabled','ready_for_public_exam','ready_for_server_authorization'])
      assert.equal(bank[gate],false,'release gate must stay closed');
    assert.equal(bank.private_server_import_status,'not_imported','server import must stay closed');
    assert.equal(bank.retest_authorization_status,'hold','retest must stay held');
  }
  assert.equal(all.contract,'econ_original_mcq_targeted_same_skill_retest_candidates_v1');
  assert.equal(all.items?.length,71,'wrong combined count');
  assert.equal(old.items?.length,36,'wrong historic count');
  assert.equal(batch.items?.length,35,'wrong new count');
  assert.deepEqual(all.papers,{P1:35,P3:36},'wrong paper quotas');
  assert.deepEqual(all.items.slice(0,36),old.items,'historic content changed');
  assert.deepEqual(all.items.slice(36),batch.items,'new items changed');
  assert.equal(all.items_canonical_sha256,canonical(all.items),'combined canonical hash drift');
  assert.equal(batch.items_canonical_sha256,canonical(batch.items),'new canonical hash drift');
  assert.equal(all.source_files?.length,2,'expected two frozen sources');
  for(let i=0;i<2;i++){
    assert.equal(all.source_files[i].name,path.basename(files[i+1]),'source path mismatch');
    assert.equal(all.source_files[i].sha256,hash(fs.readFileSync(files[i+1])),'source bytes changed');
  }
  const ids=new Set(),skills=new Set(),stems=new Set();
  const counts={P1:0,P3:0},keys={A:0,B:0,C:0,D:0};
  for(const item of all.items){
    assert(item.paper_code==='P1'||item.paper_code==='P3','invalid paper');
    const unit=Number(item.syllabus_point?.split('.')[0]);
    assert(item.paper_code==='P1'?(unit>=1&&unit<=6):(unit>=7&&unit<=11),'wrong syllabus unit');
    assert(/^(\d+)\.(\d+)\.(\d+)$/.test(item.syllabus_point),'invalid syllabus point');
    assert(item.skill_key?.startsWith('ECON-9708-'+item.syllabus_point+'-'),'wrong skill mapping');
    assert(item.assessment_role==='independent_skill_retest_candidate','wrong assessment role');
    assert(item.release_enabled===false,'released item');
    assert(item.academic_status?.startsWith('internal'),'not a draft');
    assert(item.correct_answer in keys,'wrong A-D key');
    assert(!ids.has(item.item_key),'duplicate item ID');
    assert(!skills.has(item.skill_key),'duplicate live skill');
    ids.add(item.item_key);skills.add(item.skill_key);counts[item.paper_code]++;keys[item.correct_answer]++;
    const {content_sha256,...body}=item;
    assert.equal(content_sha256,canonical(body),'tampered item');
    assert(typeof item.book_ref==='string'&&item.book_ref.length>20,'missing book reference');
    const notes=item.distractor_notes_en;
    assert(notes&&Object.keys(notes).length===3,'missing distractor notes');
    assert.deepEqual(Object.keys(notes).sort(),'ABCD'.split('').filter(k=>k!==item.correct_answer),'wrong distractor mapping');
    for(const loc of ['en','ru','uz']){
      const l=item[loc];
      assert(l&&typeof l.question==='string'&&l.question.trim().length>=60,'missing localized stem');
      assert(typeof l.explanation==='string'&&l.explanation.trim().length>=40,'missing localized explanation');
      assert(Array.isArray(l.options)&&l.options.length===4,'missing four options');
      assert(l.options.every(s=>typeof s==='string'&&s.trim().length>=2),'empty option');
      assert(new Set(l.options.map(s=>s.trim())).size===4,'duplicate options');
    }
    const stem=item.en.question.trim().toLowerCase();
    assert(!stems.has(stem),'duplicate stem');stems.add(stem);
  }
  assert.deepEqual(counts,{P1:35,P3:36});
  const vs=Object.values(keys);
  assert(Math.max(...vs)-Math.min(...vs)<=1,'answer key imbalance');
  return {status:'PASS_CANDIDATE_INTEGRITY_ONLY_RELEASE_BLOCKED',
    items:71,distinct_skills:71,locales:213,options:852,papers:counts,
    answer_distribution:keys,sha256:hash(fs.readFileSync(fullFile)),
    release_authorized:false};
}
if(require.main===module){
  try{
    const a=process.argv.slice(2);
    if(a.length!==3)throw Error('Usage: node qa-economics-private-retest-71-v1.cjs PRIVATE_71.json PRIVATE_36.json PRIVATE_35.json');
    console.log(JSON.stringify(validate(...a),null,2));
  }catch(e){
    // Never show text/options/key data from protected content.
    console.error('PRIVATE ECONOMICS RETEST QA BLOCKED: '+String(e.message).slice(0,110));
    process.exitCode=1;
  }
}
module.exports={validate};