#!/usr/bin/env node
'use strict';
// OFFLINE ONLY. Reads protected candidate files from local disk.
// Do not commit the files, print item text/keys or treat this as release approval.
const fs=require('node:fs');
const crypto=require('node:crypto');
const assert=require('node:assert/strict');
const {canonical}=require('./qa-economics-private-originals-v1.cjs');
const sha=bytes=>crypto.createHash('sha256').update(bytes).digest('hex');
const SOURCE_SHA='d5534d23bbc5a849ee550912f03dfb552db0de8713ac48de65f747e3e99907c5';
const CANDIDATE_SHA='8774a2616ff76ca68c12aad93bdcca40541c4c7848426e6fa578c3c2401fb200';
const held={release_enabled:false,ready_for_public_exam:false,
  ready_for_server_authorization:false,private_server_import_status:'not_imported',
  retest_authorization_status:'hold'};
const diffKeys=new Set(['en','ru','uz','distractor_notes_en','content_sha256',
  'correct_answer','book_ref','book_pdf_page_start']);
function verify(base,bank,audit,ledger,baseBytes,bankBytes,settings={}){
  const count=settings.count??71,changesExpected=settings.changes??18;
  const baseDigest=sha(baseBytes),bankDigest=sha(bankBytes);
  if(settings.pinned!==false){
    assert.equal(baseDigest,SOURCE_SHA,'base private source checksum differs from pinned release');
    assert.equal(bankDigest,CANDIDATE_SHA,'candidate private source checksum differs from pinned release');
  }
  for(const b of [base,bank]){
    assert.equal(b.program_key,'economics_9708','wrong program');
    assert.equal(b.version_key,'economics_2026_2028_v1','wrong syllabus version');
    for(const [k,v] of Object.entries(held)) assert.deepEqual(b[k],v,'release state is not held');
    assert.equal(b.items?.length,count,'wrong candidate count');
  }
  assert.deepEqual(bank.papers,base.papers,'paper quota changed');
  assert.equal(bank.revision_v9?.source_version_sha256,baseDigest,'lineage mismatch');
  assert.equal(audit.baseline?.sha256,baseDigest,'audit base digest mismatch');
  assert.equal(audit.result?.sha256,bankDigest,'audit output digest mismatch');
  assert.equal(ledger.input_version_sha256,baseDigest,'ledger base digest mismatch');
  assert.equal(ledger.output_version_sha256,bankDigest,'ledger output digest mismatch');
  assert.equal(bank.items_canonical_sha256,canonical(bank.items),'candidate list checksum mismatch');
  assert.equal(audit.result?.canonical_items_sha256,bank.items_canonical_sha256,'audit list mismatch');
  assert.equal(ledger.output_items_canonical_sha256,bank.items_canonical_sha256,'ledger list mismatch');
  assert.equal(audit.release_blocked,true,'audit lost hold');
  assert.equal(bank.revision_v9?.release_blocked,true,'revision lost hold');
  assert.equal(ledger.items?.length,count,'ledger entry count mismatch');
  assert.equal(audit.changes?.length,changesExpected,'correction entry count mismatch');
  assert.equal(bank.revision_v9?.counts?.unique_changed_items,changesExpected,'revision changed count mismatch');
  assert.equal(audit.unchanged_items_count,count-changesExpected,'unchanged count mismatch');
  const changesByKey=new Map(audit.changes.map(x=>[x.item_key,x]));
  assert.equal(changesByKey.size,changesExpected,'duplicate corrections');
  const edits=bank.revision_v9?.edited_item_keys||[];
  assert.equal(new Set(edits).size,changesExpected,'duplicated revision keys');
  const keySet=new Set(),skillSet=new Set(),changed=new Set(),counts={P1:0,P3:0};
  let semanticCount=0,sourceCount=0,untouchedCount=0;
  for(let i=0;i<count;i++){
    const prior=base.items[i],item=bank.items[i],review=ledger.items[i];
    assert.equal(prior.item_key,item.item_key,'item moved or replaced');
    assert.equal(prior.paper_code,item.paper_code,'paper mapping altered');
    assert.equal(prior.skill_key,item.skill_key,'skill mapping altered');
    assert.equal(prior.syllabus_point,item.syllabus_point,'syllabus point altered');
    assert.equal(prior.ao,item.ao,'assessment objective altered');
    assert.equal(item.release_enabled,false,'item released');
    assert(item.academic_status?.startsWith('internal'),'item approval state invalid');
    assert(!keySet.has(item.item_key)&&!skillSet.has(item.skill_key),'duplicate key or skill');
    keySet.add(item.item_key);skillSet.add(item.skill_key);
    assert(item.paper_code in counts,'invalid paper');
    const unit=Number(item.syllabus_point?.split('.')[0]);
    assert(item.paper_code==='P1'?(unit>=1&&unit<=6):(unit>=7&&unit<=11),'paper/unit mismatch');
    assert(item.skill_key?.startsWith('ECON-9708-'+item.syllabus_point+'-'),'invalid skill mapping');
    counts[item.paper_code]++;
    const {content_sha256,...body}=item;
    assert.equal(item.content_sha256,canonical(body),'item checksum mismatch');
    assert('ABCD'.includes(item.correct_answer)&&item.correct_answer.length===1,'invalid answer key');
    const distractors=Object.keys(item.distractor_notes_en||{}).sort();
    assert.deepEqual(distractors,['A','B','C','D'].filter(x=>x!==item.correct_answer),
      'wrong distractor map');
    for(const language of ['en','ru','uz']){
      const locale=item[language];
      assert(typeof locale?.question==='string'&&locale.question.trim().length>=12,'missing question');
      assert(typeof locale?.explanation==='string'&&locale.explanation.trim().length>=15,'missing explanation');
      assert(Array.isArray(locale?.options)&&locale.options.length===4,'missing four options');
      assert(locale.options.every(x=>typeof x==='string'&&x.trim().length>1),'empty option');
      assert.equal(new Set(locale.options.map(x=>x.trim())).size,4,'duplicate options');
    }
    assert.equal(review.item_key,item.item_key,'ledger item mismatch');
    assert.equal(review.ordinal,i+1,'ledger order mismatch');
    assert.equal(review.paper,item.paper_code,'ledger paper mismatch');
    assert.equal(review.skill_key,item.skill_key,'ledger skill mismatch');
    assert.equal(review.syllabus_point,item.syllabus_point,'ledger syllabus mismatch');
    assert.equal(review.assessment_objective,item.ao,'ledger AO mismatch');
    assert.equal(review.item_canonical_sha256,item.content_sha256,'ledger item checksum mismatch');
    assert.equal(review.production_status,'RELEASE_BLOCKED','ledger release changed');
    assert.equal(review.pass_A_blind_answer_challenge?.independent_answer,item.correct_answer,
      'ledger blind answer inconsistent');
    assert.equal(review.pass_B_four_distractors?.correct_answer_unique,true,'unresolved ambiguity');
    for(const language of ['en','ru','uz']){
      assert.equal(review.pass_D_locales?.[language]?.answer,item.correct_answer,
        'ledger locale answer mismatch');
      assert.equal(review.pass_D_locales?.[language]?.result,'pass','locale QA not passed');
    }
    const modified=JSON.stringify(prior)!==JSON.stringify(item);
    const entry=changesByKey.get(item.item_key);
    if(!modified){
      assert(!entry,'unchanged question listed as corrected');
      assert.equal(review.final_internal_status,'INTERNAL_ACADEMIC_QA_PASS','unchanged ledger status');
      untouchedCount++;
      continue;
    }
    changed.add(item.item_key);
    assert(entry,'changed question not recorded');
    assert.equal(entry.position,i+1,'correction moved');
    assert.equal(entry.paper_code,item.paper_code,'correction paper mismatch');
    assert.equal(entry.skill_key,item.skill_key,'correction skill mismatch');
    assert.equal(entry.prior_embedded_sha256,prior.content_sha256,'old item hash missing');
    assert.equal(entry.revised_embedded_sha256,item.content_sha256,'new item hash missing');
    assert.equal(entry.prior_item_canonical_sha256,
      canonical(Object.fromEntries(Object.entries(prior).filter(([k])=>k!=='content_sha256'))),
      'old item body mismatch');
    assert.equal(entry.revised_item_canonical_sha256,canonical(body),'new item body mismatch');
    assert.equal(review.final_internal_status,'CORRECTED_AND_RECHECKED','changed ledger status');
    assert.equal(review.modification_from_v8,entry.kind,'ledger correction type mismatch');
    const differing=[...new Set([...Object.keys(prior),...Object.keys(item)])]
      .filter(k=>JSON.stringify(prior[k])!==JSON.stringify(item[k]));
    assert(differing.every(k=>diffKeys.has(k)),'unreviewed field modified');
    if(entry.kind==='SEMANTIC_RETEST_REDESIGN'){
      semanticCount++;
      assert(['en','ru','uz'].every(k=>differing.includes(k)),
        'semantic correction missing one language');
    }else if(entry.kind==='BOOK_SOURCE_REFERENCE_CORRECTION' ||
             entry.kind==='BOOK_SOURCE_REFERENCE_AND_WORDING_CORRECTION'){
      sourceCount++;
      assert(differing.includes('book_ref')||differing.includes('book_pdf_page_start'),
        'source change did not correct citation');
    }else throw Error('unexpected correction kind');
    if(prior.correct_answer!==item.correct_answer){
      assert.equal(entry.kind,'SEMANTIC_RETEST_REDESIGN','unreviewed answer change');
      assert(['en','ru','uz','distractor_notes_en'].every(k=>differing.includes(k)),
        'answer remap must update every locale and distractors');
    }
  }
  assert.deepEqual(counts,bank.papers,'paper count mismatch');
  assert.equal(changed.size,changesExpected,'revision change count invalid');
  assert.equal(untouchedCount,count-changesExpected,'immutable count invalid');
  assert.equal(semanticCount,bank.revision_v9.counts.semantic_rewrites,'semantic quota mismatch');
  assert.equal(sourceCount,bank.revision_v9.counts.source_reference_corrections,
    'source reference quota mismatch');
  assert.deepEqual(new Set(edits),changed,'edited set does not match actual changes');
  return {status:'OFFLINE_V9_INTEGRITY_PASS_RELEASE_BLOCKED',
    items:count,semantic_rewrites:semanticCount,reference_corrections:sourceCount,
    unchanged:untouchedCount,source_sha256:baseDigest,candidate_sha256:bankDigest,
    publication_authorized:false};
}
function verifyFiles(args){
  assert.equal(args.length,4,'four local private paths required: v8 v9 corrections ledger');
  const bytes=args.map(path=>fs.readFileSync(path));
  const data=bytes.map(x=>JSON.parse(x.toString('utf8')));
  return verify(...data,bytes[0],bytes[1]);
}
if(require.main===module){
  try{
    const r=verifyFiles(process.argv.slice(2));
    console.log(JSON.stringify(r,null,2));
  }catch(e){
    // Do not echo protected paths or question text from untrusted files.
    console.error('PRIVATE ECONOMICS V9 GATE BLOCKED: '+e.name);
    process.exitCode=1;
  }
}
module.exports={verify,verifyFiles};
