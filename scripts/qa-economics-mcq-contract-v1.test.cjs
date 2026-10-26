'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const {run,auditPaper,evaluateLaunchGuard,SPECS} = require('./qa-economics-mcq-contract-v1.cjs');
function fixture(paper) {
  const spec = SPECS[paper];
  const unitSizes = paper === 'P1' ? [6,6,6,6,6,6] : [8,8,7,7,6];
  const mainSizes = paper === 'P1' ? [5,5,5,5,5,5] : [7,7,6,5,5];
  const main = {}, reserve = {}, records = [];
  let next = paper === 'P1' ? 60000 : 70000;
  spec.units.forEach((unit,i) => {
    const ids = Array.from({length:unitSizes[i]},()=>next++);
    main['unit'+unit] = ids.slice(0,mainSizes[i]);
    reserve['unit'+unit] = ids.slice(mainSizes[i]);
    for (const id of ids) records.push({id,skill:'ECON-9708-'+unit+'.'+id+'-BASE'});
  });
  const blueprint = {
    program_key:'economics_9708',version_key:'economics_2026_2028_v1',paper_code:paper,
    [paper === 'P1' ? 'example_30_question_ids_by_unit':'example_30_id_blueprint']:main,
    [paper === 'P1' ? 'reserve_question_ids_by_unit':'reserve_6_source_ids']:reserve
  };
  const dossiers = paper === 'P1' ? [{rows:records.map(r=>({legacy_question_id:r.id,skill_key:r.skill,
    decision:'ACCEPT_for_closed_P1_academic_catalog',scope:'pass',academic:'pass',language:'pass',format:'pass'}))}] : [
    {items:records.slice(0,24).map(r=>({legacy_question_id:r.id,skill_key:r.skill,academic_result:'pass',language_result:'pass',format_result:'pass'}))},
    {items:records.slice(24).map(r=>({legacy_question_id:r.id,proposed_skill_key:r.skill,internal_scope_review:'pass',internal_academic_review:'pass',internal_language_review:'pass',internal_format_review:'pass'}))}
  ];
  return {blueprint,dossiers};
}
function mock() { return {P1:fixture('P1'),P3:fixture('P3')}; }
test('36 sources for each paper, 30 main + 6 reserves, 11 units',()=>{
  const r=run({fixtures:mock()});
  assert.deepEqual(r.map(x=>[x.mainCount,x.reserveCount,x.approvedSourceCount]),[[30,6,36],[30,6,36]]);
  assert.equal(r.flatMap(x=>x.units).length,11);
});
test('duplicate question in same form rejected',()=>{
  const f=fixture('P1'); f.blueprint.example_30_question_ids_by_unit.unit1[1]=f.blueprint.example_30_question_ids_by_unit.unit1[0];
  assert.throws(()=>auditPaper('P1',f.blueprint,f.dossiers),/duplicates source IDs/);
});
test('repeat same tested skill within form rejected',()=>{
  const f=fixture('P1'); f.dossiers[0].rows[1].skill_key=f.dossiers[0].rows[0].skill_key;
  assert.throws(()=>auditPaper('P1',f.blueprint,f.dossiers),/duplicates source IDs or skills/);
});
test('non-pass language QA rejected',()=>{
  const f=fixture('P1'); f.dossiers[0].rows[0].language='pending';
  assert.throws(()=>auditPaper('P1',f.blueprint,f.dossiers),/expected exactly 36/);
});
test('unapproved source in blueprint rejected',()=>{
  const f=fixture('P3'); f.blueprint.reserve_6_source_ids.unit7[0]=999999;
  assert.throws(()=>auditPaper('P3',f.blueprint,f.dossiers),/non-reviewed source/);
});
test('mismatched version rejected',()=>{
  const f=fixture('P1'); f.blueprint.version_key='wrong_version';
  assert.throws(()=>auditPaper('P1',f.blueprint,f.dossiers),/mismatch/);
});
test('missing syllabus unit rejected',()=>{
  const f=fixture('P3'); delete f.blueprint.example_30_id_blueprint.unit10;
  assert.throws(()=>auditPaper('P3',f.blueprint,f.dossiers),/mismatched unit groups/);
});
test('public answer keys accidentally added to blueprint rejected',()=>{
  const f=mock(); f.P3.blueprint.answer_key=['A'];
  assert.throws(()=>run({fixtures:f}),/leaks a forbidden field/);
});
test('draft/off program denies session',()=>{
  assert.equal(evaluateLaunchGuard({program:{program_key:'economics_9708',version_key:'economics_2026_2028_v1',status:'draft',launch_enabled:false},paper:'P1',preflight:{state:'blocked',can_issue_learner_plan:false},catalog:{state:'closed_catalog_preview',can_issue_learner_task:false}}),false);
});
test('forged ready flags still deny because server runtime is absent',()=>{
  assert.equal(evaluateLaunchGuard({program:{program_key:'economics_9708',version_key:'economics_2026_2028_v1',status:'published',launch_enabled:true},paper:'P3',preflight:{state:'ready',can_issue_learner_plan:true},catalog:{state:'issuable',can_issue_learner_task:true}}),false);
});
test('Math cannot be routed into Economics native gate',()=>{
  assert.equal(evaluateLaunchGuard({program:{program_key:'math_as_p1_p5',version_key:'p1_p5_canonical_v1_0',status:'published',launch_enabled:true},paper:'P1',preflight:{state:'ready',can_issue_learner_plan:true},catalog:{state:'issuable',can_issue_learner_task:true}}),false);
});
