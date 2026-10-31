#!/usr/bin/env node
'use strict';
// Fictional payload only; NEVER commit the private v8/v9 bank.
const test=require('node:test');
const assert=require('node:assert/strict');
const crypto=require('node:crypto');
const {canonical}=require('./qa-economics-private-originals-v1.cjs');
const {verify}=require('./qa-economics-private-retest-v9-integrity.cjs');
const digest=x=>crypto.createHash('sha256').update(x).digest('hex');
const copy=x=>JSON.parse(JSON.stringify(x));
function makeItem(k,paper){
  const point=paper==='P1'?'1.1.3':'7.1.1';
  const result={item_key:k,paper_code:paper,syllabus_point:point,
    skill_key:'ECON-9708-'+point+'-FAKE',ao:'AO2',
    correct_answer:'C',book_ref:'Synthetic learning resource Chapter 1',
    book_pdf_page_start:11,assessment_role:'independent_skill_retest_candidate',
    academic_status:'internal_draft_awaiting_independent_release_review',
    release_enabled:false,distractor_notes_en:{A:'Fictional error A',B:'Fictional error B',D:'Fictional error D'}};
  for(const lang of ['en','ru','uz']){
    result[lang]={question:'Entirely fictional market scenario with imaginary producers, customers and an imaginary price.',
      options:['Answer option A','Answer option B','Answer option C','Answer option D'],
      explanation:'The fictional third answer follows from fictional assumptions about a fictional economy.'};
  }
  result.content_sha256=canonical(result);
  return result;
}
const itemDigest=x=>canonical(Object.fromEntries(Object.entries(x).filter(([k])=>k!=='content_sha256')));
function row(item,i,edited){
  return {ordinal:i+1,item_key:item.item_key,paper:item.paper_code,skill_key:item.skill_key,
    syllabus_point:item.syllabus_point,assessment_objective:item.ao,
    item_canonical_sha256:item.content_sha256,
    final_internal_status:edited?'CORRECTED_AND_RECHECKED':'INTERNAL_ACADEMIC_QA_PASS',
    modification_from_v8:edited?'SEMANTIC_RETEST_REDESIGN':'none',
    production_status:'RELEASE_BLOCKED',
    pass_A_blind_answer_challenge:{independent_answer:item.correct_answer,result:'pass'},
    pass_B_four_distractors:{correct_answer_unique:true,result:'pass'},
    pass_D_locales:Object.fromEntries(['en','ru','uz'].map(l=>[l,{answer:item.correct_answer,result:'pass'}]))};
}
function fixture(){
  const base={program_key:'economics_9708',version_key:'economics_2026_2028_v1',
    papers:{P1:1,P3:1},release_enabled:false,ready_for_public_exam:false,
    ready_for_server_authorization:false,private_server_import_status:'not_imported',
    retest_authorization_status:'hold',
    items:[makeItem('FICTION-1','P1'),makeItem('FICTION-2','P3')]};
  const bank=copy(base);
  const x=bank.items[1];
  for(const lang of ['en','ru','uz']){
    x[lang].question='Revised purely fictional scenario with changed demand and different imaginary events. '.repeat(2);
    x[lang].explanation='Revised fictional reasoning with a different causal mechanism, used only by automated tests.';
  }
  x.content_sha256=itemDigest(x);
  const prior=base.items[1];
  const correction={position:2,item_key:x.item_key,paper_code:x.paper_code,
    skill_key:x.skill_key,kind:'SEMANTIC_RETEST_REDESIGN',reason:'Fictional data mutation fixture',
    prior_item_canonical_sha256:itemDigest(prior),
    revised_item_canonical_sha256:itemDigest(x),
    prior_embedded_sha256:prior.content_sha256,
    revised_embedded_sha256:x.content_sha256};
  const baseBytes=Buffer.from(JSON.stringify(base),'utf8'),bankBytes=Buffer.from(JSON.stringify(bank),'utf8');
  const baseHash=digest(baseBytes),bankHash=digest(bankBytes);
  bank.items_canonical_sha256=canonical(bank.items);
  bank.revision_v9={source_version_sha256:baseHash,release_blocked:true,
    edited_item_keys:[x.item_key],
    counts:{unique_changed_items:1,semantic_rewrites:1,source_reference_corrections:0}};
  // Regenerate canonical bank bytes after metadata changes.
  const fullBankBytes=Buffer.from(JSON.stringify(bank),'utf8');
  const fullHash=digest(fullBankBytes);
  const audit={baseline:{sha256:baseHash},result:{sha256:fullHash,
      canonical_items_sha256:bank.items_canonical_sha256},
    release_blocked:true,unchanged_items_count:1,changes:[correction]};
  const ledger={input_version_sha256:baseHash,output_version_sha256:fullHash,
    output_items_canonical_sha256:bank.items_canonical_sha256,
    items:bank.items.map((item,i)=>row(item,i,i===1))};
  return {base,bank,audit,ledger,baseBytes,bankBytes:fullBankBytes};
}
function run(t){return verify(t.base,t.bank,t.audit,t.ledger,t.baseBytes,t.bankBytes,
  {count:2,changes:1,pinned:false});}
test('valid one semantic revision and one untouched fictional item remain on HOLD',()=>{
  const result=run(fixture());
  assert.equal(result.status,'OFFLINE_V9_INTEGRITY_PASS_RELEASE_BLOCKED');
  assert.equal(result.items,2);
  assert.equal(result.unchanged,1);
  assert.equal(result.publication_authorized,false);
});
test('blocks semantic mutation without all three language revisions',()=>{
  const f=fixture();
  f.bank.items[1].uz=copy(f.base.items[1].uz);
  assert.throws(()=>run(f));
});
test('blocks source and candidate checksum forgery',()=>{
  const f=fixture();f.audit.result.sha256='0'.repeat(64);
  assert.throws(()=>run(f));
  const g=fixture();g.bank.revision_v9.source_version_sha256='0'.repeat(64);
  assert.throws(()=>run(g));
});
test('blocks release flags at bank and item levels',()=>{
  const a=fixture();a.bank.ready_for_server_authorization=true;
  assert.throws(()=>run(a));
  const b=fixture();b.bank.items[0].release_enabled=true;
  assert.throws(()=>run(b));
});
test('blocks silent rewrite of one previously unchanged item',()=>{
  const f=fixture();f.bank.items[0].en.question+=' extra';
  assert.throws(()=>run(f));
});
test('blocks answer key or locale mismatch',()=>{
  const f=fixture();f.bank.items[1].correct_answer='D';
  assert.throws(()=>run(f));
  const g=fixture();g.ledger.items[1].pass_D_locales.uz.answer='A';
  assert.throws(()=>run(g));
});
test('blocks correction ledger mismatch and duplicated item identity',()=>{
  const f=fixture();f.audit.changes[0].item_key='SOME-OTHER-ITEM';
  assert.throws(()=>run(f));
  const g=fixture();g.bank.items[1].item_key='FICTION-1';
  assert.throws(()=>run(g));
});
test('blocks false claim of earlier-version mapping',()=>{
  const f=fixture();f.bank.items[1].skill_key='ECON-9708-1.1.3-FAKE';
  assert.throws(()=>run(f));
});
