#!/usr/bin/env node
'use strict';
// Offline, private-only semantic revision gate. Never publish protected sources,
// answer keys, learner data or question text to public GitHub/CI.
const fs=require('node:fs');
const crypto=require('node:crypto');
const assert=require('node:assert/strict');
const {canonical}=require('./qa-economics-private-originals-v1.cjs');
const sha=x=>crypto.createHash('sha256').update(x).digest('hex');
const allowedChangeKeys=new Set(['en','ru','uz','distractor_notes_en','content_sha256']);
const safeModes={release_enabled:false,ready_for_public_exam:false,
  ready_for_server_authorization:false,private_server_import_status:'not_imported',
  retest_authorization_status:'hold'};
function examine(original,revised,originalBytes,options={}){
  const expected=options.expectedCount??71;
  const changedCount=options.expectedChanges??6;
  assert.equal(original.items?.length,expected,'base count');
  assert.equal(revised.items?.length,expected,'revised count');
  assert.equal(revised.parent_combined_file_sha256,sha(originalBytes),'wrong revision ancestry');
  assert.equal(revised.items_canonical_sha256,canonical(revised.items),'revised bank hash mismatch');
  assert.deepEqual(revised.papers,original.papers,'changed paper quotas');
  for(const bank of [original,revised]){
    assert.equal(bank.program_key,'economics_9708');
    assert.equal(bank.version_key,'economics_2026_2028_v1');
    for(const [k,v] of Object.entries(safeModes))
      assert.equal(bank[k],v,'release control is not closed');
  }
  assert.equal(revised.revision_changes?.length,changedCount,'unexpected revision count');
  const changeRows=new Map(revised.revision_changes.map(row=>[row.item_key,row]));
  assert.equal(changeRows.size,changedCount,'duplicate revision manifest');
  let changed=0,untouched=0;
  const skillSet=new Set(),idSet=new Set(),paperCounts={P1:0,P3:0};
  for(let i=0;i<expected;i++){
    const before=original.items[i],after=revised.items[i];
    assert.equal(before.item_key,after.item_key,'item moved/renamed');
    assert.equal(before.skill_key,after.skill_key,'skill reassigned');
    assert.equal(before.paper_code,after.paper_code,'paper reassigned');
    assert.equal(before.correct_answer,after.correct_answer,'key altered');
    assert.equal(before.syllabus_point,after.syllabus_point,'syllabus remapped');
    assert(!idSet.has(after.item_key),'duplicate item id');idSet.add(after.item_key);
    assert(!skillSet.has(after.skill_key),'duplicate skill id');skillSet.add(after.skill_key);
    assert(after.paper_code==='P1'||after.paper_code==='P3','paper invalid');
    paperCounts[after.paper_code]++;
    assert.equal(after.release_enabled,false,'released item');
    assert(after.academic_status?.startsWith('internal'),'academic release without review');
    const {content_sha256,...body}=after;
    assert.equal(content_sha256,canonical(body),'item digest invalid');
    for(const loc of ['en','ru','uz']){
      const x=after[loc];
      assert(typeof x?.question==='string'&&x.question.trim().length>=60,'short stem');
      assert(typeof x?.explanation==='string'&&x.explanation.trim().length>=40,'short explanation');
      assert(Array.isArray(x?.options)&&x.options.length===4,'missing options');
      assert(new Set(x.options.map(y=>y.trim())).size===4,'repeated options');
    }
    const keys=Object.keys(after.distractor_notes_en||{}).sort();
    assert.deepEqual(keys,'ABCD'.split('').filter(x=>x!==after.correct_answer),'wrong distractor notes');
    const manifest=changeRows.get(after.item_key);
    if(JSON.stringify(before)===JSON.stringify(after)){
      assert(!manifest,'unnecessary manifest change');
      untouched++;
    } else {
      changed++;
      assert(manifest,'missing manifest change');
      assert.equal(manifest.paper_code,after.paper_code,'manifest paper mismatch');
      assert.equal(manifest.skill_key,after.skill_key,'manifest skill mismatch');
      assert.equal(manifest.previous_item_sha256,before.content_sha256,'old digest mismatch');
      assert.equal(manifest.updated_item_sha256,after.content_sha256,'new digest mismatch');
      assert.equal(manifest.key_unchanged,true,'answer key untrusted');
      const diff=new Set([...Object.keys(before),...Object.keys(after)]
        .filter(k=>JSON.stringify(before[k])!==JSON.stringify(after[k])));
      assert([...diff].every(k=>allowedChangeKeys.has(k)),'unauthorized metadata change');
      // Every revised language must actually be updated, not only EN.
      assert(['en','ru','uz'].every(k=>diff.has(k)),'unrevised locale');
    }
  }
  assert.equal(changed,changedCount,'changed count mismatch');
  assert.equal(untouched,expected-changedCount,'unexpected unaffected mutation');
  assert.deepEqual(paperCounts,revised.papers,'paper counts mismatch');
  return {status:'PRIVATE_SEMANTIC_REVISION_INTEGRITY_PASS_RELEASE_HOLD',
    items:expected,changed,unchanged:untouched,release_authorized:false};
}
function checkFiles(originalPath,revisionPath){
  const originalBytes=fs.readFileSync(originalPath);
  const original=JSON.parse(originalBytes.toString('utf8'));
  const revised=JSON.parse(fs.readFileSync(revisionPath,'utf8'));
  const audit=examine(original,revised,originalBytes);
  return {...audit,original_sha256:sha(originalBytes),
    revised_sha256:sha(fs.readFileSync(revisionPath))};
}
if(require.main===module){
  try{
    if(process.argv.length!==4)throw Error('Expected PRIVATE_ORIGINAL.json PRIVATE_REVISED.json');
    console.log(JSON.stringify(checkFiles(process.argv[2],process.argv[3]),null,2));
  }catch(e){
    console.error('PRIVATE REVISION HOLD: '+String(e.message).slice(0,100));
    process.exitCode=1;
  }
}
module.exports={examine,checkFiles};
