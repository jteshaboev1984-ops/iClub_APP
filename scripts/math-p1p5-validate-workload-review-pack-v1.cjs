'use strict';
// Pure source/academic release guard. No DB, external services, production credentials or learner state.
const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const file = path.join(__dirname, '../docs/math-p1p5-package2-81-skill-review-pack-v1.json');
const pack = JSON.parse(fs.readFileSync(file, 'utf8'));
const expected = {'P1': [6,8,6,3,5,5,7,5], 'P5': [10,5,6,9,6]};
function validate(p) {
  assert.equal(p.schema_version, 'math-p1p5-skill-workload-review-pack-v1');
  assert.equal(p.program_version_id, 1);
  assert.equal(p.status, 'source_verified_duration_unmeasured');
  assert.equal(p.skills.length, 81);
  const seen = new Set();
  for (const component of ['P1','P5']) {
    const rows = p.skills.filter(s => s.component_code === component);
    assert.equal(rows.length, component === 'P1' ? 45 : 36);
    const sections = [];
    for (const s of rows) {
      assert.equal(s.program_version_id, 1);
      assert.equal(typeof s.sequence_no, 'number');
      assert(s.skill_code.startsWith(component+'-') && !seen.has(s.skill_code));
      seen.add(s.skill_code);
      for (const k of ['official_syllabus_section','canonical_description','book_chapter','book_pages','required_mastery_evidence','app_can_verify','mentor_must_verify','official_source_url']) assert(typeof s[k] === 'string' && s[k].trim(), s.skill_code+' missing '+k);
      assert(s.official_source_url.startsWith('https://www.cambridgeinternational.org/'));
      let slot=sections.find(v=>v.section===s.official_syllabus_section);
      if(!slot){slot={section:s.official_syllabus_section,count:0};sections.push(slot);}
      slot.count++;
      const r = s.review;
      assert.equal(r.status, 'awaiting_observations');
      assert.equal(r.approved_for_recommendation, false);
      for (const k of ['estimated_core_min_minutes','estimated_core_max_minutes','estimated_revision_min_minutes','estimated_revision_max_minutes','primary_reviewer','independent_approver','reviewed_at','approved_at','baseline_prerequisite_competence','target_learner_definition','independent_method_description']) assert.equal(r[k],null,s.skill_code+': premature review or value '+k);
      for (const v of Object.values(r.learning_phase_minutes)) assert.equal(v,null,s.skill_code+': unsupported learning phase');
      for (const v of Object.values(r.revision_phase_minutes)) assert.equal(v,null,s.skill_code+': unsupported revision phase');
      assert.deepEqual(r.observation_evidence_ids,[]);
      assert.deepEqual(r.source_provenance_ids,[]);
    }
    assert.deepEqual(sections.map(x=>x.count),expected[component],component+' syllabus distribution drift');
  }
  assert.equal(seen.size,81);
  const json = JSON.stringify(p).toLowerCase();
  for (const secret of ['correct_answer','answer_key','service_role','reserve_question_id','learner_token']) assert(!json.includes(secret), 'Forbidden source marker '+secret);
}
validate(pack);
for (const [property,value] of [['status','approved'],['estimated_core_min_minutes',25]]) {
  const broken = structuredClone(pack);
  broken.skills[0].review[property] = value;
  assert.throws(()=>validate(broken),'Negative safety assertion did not fail: '+property);
}
console.log('PASS P2-07: 81 source-linked skills (P1 45/P5 36), 13 groups, no unapproved durations or leaked answers; negative cases rejected');
