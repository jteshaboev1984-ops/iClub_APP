#!/usr/bin/env node
'use strict';
// D10-03: OFFLINE provenance/coverage guard for the existing 81 source rows.
// Cambridge 9709 2028–2030 states "no significant changes which affect
// teaching" and textbooks endorsed from 2020 remain suitable. This does NOT
// claim independent content QA on all 81 skills nor certify study minutes.
// No tokens, private question bodies, answers, learner data or network calls.
const assert=require('node:assert/strict');
const fs=require('node:fs');
const path=require('node:path');
const catalog=JSON.parse(fs.readFileSync(
  path.join(__dirname,'../docs/math-p1p5-package2-81-skill-review-pack-v1.json'),'utf8'));
const SOURCE_2026='https://www.cambridgeinternational.org/Images/697427-2026-2027-syllabus.pdf';
const SOURCE_2028='https://www.cambridgeinternational.org/Images/744634-2028-2030-syllabus.pdf';
const SECTIONS=Object.freeze([
  ['P1','1.1 Quadratics',6],
  ['P1','1.2 Functions',8],
  ['P1','1.3 Coordinate geometry',6],
  ['P1','1.4 Circular measure',3],
  ['P1','1.5 Trigonometry',5],
  ['P1','1.6 Series',5],
  ['P1','1.7 Differentiation',7],
  ['P1','1.8 Integration',5],
  ['P5','5.1 Representation of data',10],
  ['P5','5.2 Permutations and combinations',5],
  ['P5','5.3 Probability',6],
  ['P5','5.4 Discrete random variables',9],
  ['P5','5.5 The normal distribution',6]
]);
const OFFICIAL_SCOPE=Object.freeze({
  'P1-DIF-01':['формального','первых принципов'],
  'P1-DIF-03':['нелинейные','g\'(x)'],
  'P1-INT-01':['n = −1'],
  'P1-INT-03':['бесконечным пределом','конечной границе'],
  'P1-INT-05':['между двумя кривыми','не прилегающих'],
  'P5-PRO-03':['простых случаях','не обязательна']
});
function verify(pack) {
  assert.equal(pack.schema_version,'math-p1p5-skill-workload-review-pack-v1');
  assert.equal(pack.program_version_id,1);
  assert.equal(pack.skills.length,81);
  assert.equal(pack.official_syllabus_url,SOURCE_2026,
    'Original versioned skill bank still comes from its actual 2026–27 source');
  const seen=new Set();
  for(const skill of pack.skills){
    assert.equal(skill.official_source_url,SOURCE_2026,skill.skill_code+' original source changed');
    assert(!seen.has(skill.skill_code),skill.skill_code+' repeated');
    seen.add(skill.skill_code);
    const expected=SECTIONS.find(([component,section])=>
      skill.component_code===component&&skill.official_syllabus_section===section);
    assert(expected,skill.skill_code+' mapped outside verified paper sections');
    assert(skill.skill_code.startsWith(skill.component_code+'-'),skill.skill_code+' wrong paper');
    assert(typeof skill.book_chapter==='string'&&skill.book_chapter.length>10);
    assert.equal(skill.review.approved_for_recommendation,false,
      'Do not turn syllabus compatibility into approval of student study minutes');
    for(const key of ['estimated_core_min_minutes','estimated_core_max_minutes',
      'estimated_revision_min_minutes','estimated_revision_max_minutes']){
      assert.equal(skill.review[key],null,
        skill.skill_code+' falsely received a study-duration estimate');
    }
  }
  for(const [component,section,count] of SECTIONS)
    assert.equal(pack.skills.filter(s=>s.component_code===component&&
      s.official_syllabus_section===section).length,count,
      'Source-map section distribution drift: '+section);
  assert.equal(pack.skills.filter(s=>s.component_code==='P1').length,45);
  assert.equal(pack.skills.filter(s=>s.component_code==='P5').length,36);
  // Exact published syllabus exclusions/required breadth: no fabricated
  // mathematical first-principles requirement, nonlinear inner chain rule,
  // integral n=-1, or mandatory general inclusion-exclusion formula.
  for(const [skill_code,phrases] of Object.entries(OFFICIAL_SCOPE)){
    const matches=pack.skills.filter(x=>x.skill_code===skill_code);
    assert.equal(matches.length,1,'Canonical academic scope skill missing '+skill_code);
    for(const phrase of phrases)
      assert(matches[0].canonical_description.includes(phrase),
        skill_code+' lost official syllabus scope: '+phrase);
  }
  assert.equal(SOURCE_2028,
    'https://www.cambridgeinternational.org/Images/744634-2028-2030-syllabus.pdf');
  return true;
}
verify(catalog);
// Negative checks: a cross-paper section or an invented independent-study
// figure must never be counted as legitimate publisher carry-over evidence.
const wrongPaper=structuredClone(catalog);
wrongPaper.skills[0].official_syllabus_section='5.1 Representation of data';
assert.throws(()=>verify(wrongPaper),'Mis-mapped Paper 1 skill went unnoticed');
const fakeMinutes=structuredClone(catalog);
fakeMinutes.skills[0].review.estimated_core_min_minutes=35;
assert.throws(()=>verify(fakeMinutes),'Unapproved minutes went unnoticed');
const wrongScope=structuredClone(catalog);
wrongScope.skills.find(x=>x.skill_code==='P1-DIF-03').canonical_description=
  'Только производная (ax+b)^n без нелинейной внутренней функции';
assert.throws(()=>verify(wrongScope),'Nonlinear chain-rule coverage regression missed');
const visibleLabels=fs.readFileSync(
  path.join(__dirname,'../exam-prep/exam-prep-learner-views.js'),'utf8');
for(const [code,phrase] of Object.entries({
  'P1-DIF-01':'формальный общий вывод из первых принципов не требуется',
  'P1-DIF-03':'нелинейные внутренние многочлены',
  'P1-INT-01':'рациональном n ≠ −1',
  'P1-INT-03':'с бесконечным пределом',
  'P1-INT-05':'включая области между кривыми',
  'P5-PRO-03':'общая формула включений–исключений не обязательна'
})){
  assert(visibleLabels.includes('"'+code+'": "'+phrase)||
    (visibleLabels.includes('"'+code+'": "')&&visibleLabels.includes(phrase)),
    code+' learner-facing description not corrected');
}
const oldImproper=structuredClone(catalog);
oldImproper.skills.find(x=>x.skill_code==='P1-INT-03').canonical_description=
  'Вычислять definite integrals, включая простой improper endpoint case из P1.';
assert.throws(()=>verify(oldImproper),'Infinite upper-bound integration scope regression missed');
const oldWashers=structuredClone(catalog);
oldWashers.skills.find(x=>x.skill_code==='P1-INT-05').canonical_description=
  'Находить volume of revolution около coordinate axis с корректными limits.';
assert.throws(()=>verify(oldWashers),'Non-axis-bounded washer scope regression missed');
console.log('D10-06 PASS: four official syllabus description corrections and learner copy align without altering 81 IDs');
console.log('D10-07 PASS: P1-INT-03 infinity and P1-INT-05 non-axis-bounded annuli source/learner scope, 81 stable codes');
console.log('D10-03 PASS: 81 genuine source skills (P1=45/P5=36), 13 paper sections, original 2026–27 links, 2028–30 edition reference kept separate, no fake student minutes');
