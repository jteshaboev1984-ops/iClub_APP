#!/usr/bin/env node
'use strict';
/*
 * iClub Economics Exam Prep — independent, OFFLINE academic source/blueprint gate.
 * NO database operations, network, user data, UI access, or content edits.
 * Running this is NOT permission to enable learner assessment.
 */
const fs = require('node:fs');
const path = require('node:path');

const ROOT = path.resolve(__dirname, '..');
const DIR = 'exam-prep/academic/economics-9708-mcq';
const ECONOMICS_PROGRAM = 'economics_9708';
const ECONOMICS_VERSION = 'economics_2026_2028_v1';
const SPECS = Object.freeze({
  P1: Object.freeze({level: 'AS', units: [1,2,3,4,5,6], mcq: 30, minutes: 60}),
  P3: Object.freeze({level: 'A', units: [7,8,9,10,11], mcq: 30, minutes: 75})
});

function fail(message) { throw new Error('Economics source gate: ' + message); }
function isObject(value) { return value !== null && typeof value === 'object' && !Array.isArray(value); }
function loadJson(relative) {
  const location = path.join(ROOT, relative);
  if (!fs.existsSync(location)) fail('missing ' + relative);
  return JSON.parse(fs.readFileSync(location, 'utf8'));
}
function asIntegerId(value, label) {
  if (!Number.isSafeInteger(value) || value <= 0) fail(label + ' invalid source ID');
  return value;
}
function unique(ids, label) {
  if (new Set(ids).size !== ids.length) fail(label + ' duplicates source IDs or skills');
}
function flattenByUnit(obj, spec, label) {
  if (!isObject(obj)) fail(label + ' missing unit groups');
  const actual = Object.keys(obj).sort();
  const expected = spec.units.map(unit => 'unit' + unit).sort();
  if (JSON.stringify(actual) !== JSON.stringify(expected)) fail(label + ' mismatched unit groups');
  return spec.units.flatMap(unit => {
    const records = obj['unit' + unit];
    if (!Array.isArray(records)) fail(label + ' unit' + unit + ' not an array');
    return records.map(id => asIntegerId(id, label));
  });
}
function sourceApprovedItems(paper, dossiers) {
  if (paper === 'P1') {
    const rows = dossiers[0].rows;
    if (!Array.isArray(rows)) fail('P1 QA items missing');
    return rows.filter(row => row.decision === 'ACCEPT_for_closed_P1_academic_catalog' &&
       row.scope === 'pass' && row.academic === 'pass' && row.language === 'pass' && row.format === 'pass')
       .map(row => ({id: row.legacy_question_id, skill: row.skill_key}));
  }
  const first = dossiers[0].items.filter(row => row.academic_result === 'pass' &&
     row.language_result === 'pass' && row.format_result === 'pass');
  const second = dossiers[1].items.filter(row => row.internal_scope_review === 'pass' &&
     row.internal_academic_review === 'pass' && row.internal_language_review === 'pass' &&
     row.internal_format_review === 'pass');
  return [...first, ...second].map(row => ({id: row.legacy_question_id,
    skill: row.skill_key || row.proposed_skill_key}));
}
function auditPaper(paper, blueprint, dossiers) {
  const spec = SPECS[paper];
  if (!spec) fail('unsupported paper ' + paper);
  if (blueprint.program_key !== ECONOMICS_PROGRAM || blueprint.version_key !== ECONOMICS_VERSION ||
      blueprint.paper_code !== paper) fail(paper + ' program/version/paper mismatch');
  const mainGroups = paper === 'P1' ? blueprint.example_30_question_ids_by_unit : blueprint.example_30_id_blueprint;
  const main = flattenByUnit(mainGroups, spec, paper + ' main');
  const reserve = flattenByUnit(paper === 'P1' ? blueprint.reserve_question_ids_by_unit : blueprint.reserve_6_source_ids, spec, paper + ' reserves');
  if (main.length !== spec.mcq || reserve.length !== 6) fail(paper + ' expected 30 main and 6 reserve');
  if (spec.units.some(unit => mainGroups['unit' + unit].length === 0)) fail(paper + ' missing a syllabus unit');
  unique([...main, ...reserve], paper + ' blueprint');
  const approved = sourceApprovedItems(paper, dossiers);
  if (approved.length !== 36) fail(paper + ' expected exactly 36 reviewed source items');
  unique(approved.map(row => asIntegerId(row.id, paper + ' QA')), paper + ' QA');
  const covered = new Map(approved.map(row => [row.id, row.skill]));
  if (main.concat(reserve).some(id => !covered.has(id))) fail(paper + ' blueprint includes non-reviewed source');
  if (covered.size !== main.length + reserve.length) fail(paper + ' blueprint omits an approved source');
  if ([8751, 9044, 9732].some(id => covered.has(id))) fail(paper + ' includes held/wrong-key source');
  if (approved.some(row => typeof row.skill !== 'string' || !row.skill.startsWith('ECON-9708-'))) fail(paper + ' missing canonical skill mapping');
  unique(main.map(id => covered.get(id)), paper + ' main skill targets');
  return Object.freeze({paper, mainCount: main.length, reserveCount: reserve.length,
    approvedSourceCount: approved.length, uniqueSkillCount: new Set(approved.map(row => row.skill)).size,
    durationMinutes: spec.minutes, units: [...spec.units]});
}
function evaluateLaunchGuard({program, paper, preflight, catalog}) {
  // OFFLINE preview/QA assertion only, NEVER browser permission or server authorization.
  if (!SPECS[paper] || !isObject(program) || !isObject(preflight) || !isObject(catalog)) return false;
  if (program.program_key !== ECONOMICS_PROGRAM || program.version_key !== ECONOMICS_VERSION) return false;
  if (program.status !== 'published' || program.launch_enabled !== true) return false;
  if (preflight.state !== 'ready' || preflight.can_issue_learner_plan !== true) return false;
  if (catalog.state !== 'issuable' || catalog.can_issue_learner_task !== true) return false;
  // No authenticated native session runtime exists. Cannot issue even with forged ready flags.
  return false;
}
function assertNoSecretsInBlueprint(blueprint, paper) {
  const forbidden = /\"(?:correct_answer|answer_key|right_answer|solution_text|service_role_key|access_token|user_id)\"\s*:/i;
  if (forbidden.test(JSON.stringify(blueprint))) fail(paper + ' public blueprint leaks a forbidden field');
}
function run({fixtures} = {}) {
  const names = {
    P1: [DIR + '/P1-36-approved-academic-bank-30-item-blueprint-v0.1.json',
      [DIR + '/P1-AS-37-item-full-QA-36-pass-1-hold-v0.1.json']],
    P3: [DIR + '/P3-36-approved-academic-bank-and-30-item-blueprint-v0.1.json',
      [DIR + '/A-reinforcement-25-trilingual-QA-results-v0.1.json', DIR + '/A-P3-Units8-10-12-trilingual-QA-and-exposure-v0.1.json']]
  };
  const results = [];
  for (const paper of Object.keys(SPECS)) {
    const [blueprintPath, dossierPaths] = names[paper];
    const b = fixtures?.[paper]?.blueprint || loadJson(blueprintPath);
    const d = fixtures?.[paper]?.dossiers || dossierPaths.map(loadJson);
    assertNoSecretsInBlueprint(b, paper);
    results.push(auditPaper(paper, b, d));
  }
  return results;
}

module.exports = {SPECS, run, auditPaper, evaluateLaunchGuard};
if (require.main === module) {
  try {
    const records = run();
    console.log(JSON.stringify({ok: true, records, learnerRuntimeEnabled: false}, null, 2));
  } catch (error) {
    console.error(error.message);
    process.exitCode = 1;
  }
}
