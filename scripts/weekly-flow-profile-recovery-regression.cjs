'use strict';
// Run only against a disposable checkout with the exact-reviewed patch applied.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const apiSource = fs.readFileSync('exam-prep/exam-prep-api.js', 'utf8');
const recoverySource = fs.readFileSync('exam-prep/exam-prep-recovery.js', 'utf8');
const mapSource = fs.readFileSync('exam-prep/exam-prep-exam-map.js', 'utf8');
async function runApi(enabled, changed) {
  const calls = [];
  const window = {
    iClubExamPrepWeeklyFlowEnabled: enabled,
    iClubExamPrepHostInternal: {lastCapabilities: {coreAccess:true,killSwitch:false,rolloutState:'controlled_beta'}},
    sb: {rpc: async (name, args = {}) => {
      calls.push({name,args});
      if(name === 'save_exam_prep_exam_profile_v2') return {data:{plan_rebuild_required:changed,progress_retained:true},error:null};
      if(name === 'generate_exam_prep_weekly_plan_safe_v3') return {data:{plan_id:'synthetic'},error:null};
      throw Error(`Unexpected RPC ${name}`);
    }}
  };
  const document = {currentScript:null,querySelector:()=>null,head:{appendChild:()=>{}}};
  vm.runInNewContext(apiSource,{window,document,CustomEvent:class {}},{filename:'exam-prep-api.js'});
  const result=await window.iClubExamPrepHostInternal.api.saveExamProfile({examSeries:'May/June 2027',targetGrade:'A',totalHours:10,mathHours:5});
  assert.strictEqual(result.ok,true);
  assert.strictEqual(result.data.progress_retained,true);
  assert.strictEqual(calls.filter(c=>c.name==='save_exam_prep_exam_profile_v2').length,1);
  const generators=calls.filter(c=>c.name==='generate_exam_prep_weekly_plan_safe_v3');
  assert.strictEqual(generators.length,enabled?0:changed?2:0,'Guarded profile must never silently replace P1/P5 plans');
  if(!enabled&&changed) assert.deepEqual(generators.map(c=>c.args.p_component_code),['P1','P5']);
  console.log(`PASS profile save: guarded=${enabled} changes=${changed} replans=${generators.length}`);
}
function staticContracts() {
  assert(recoverySource.includes('if (window.iClubExamPrepWeeklyFlowEnabled !== true) {\n        await Promise.allSettled([internal.api.generateWeeklyPlan("P1"), internal.api.generateWeeklyPlan("P5")]);'));
  assert(recoverySource.includes('data-ep-recovery-success'));
  for(const label of ['Перерыв учтён.','Tanaffus saqlandi.','Your study break is recorded.'])
    assert(recoverySource.includes(label),`Missing honest recovery status ${label}`);
  for(const label of ['Изменения сохранены.','O‘zgarishlar saqlandi.','Your changes were saved.'])
    assert(mapSource.includes(label),`Missing localized saved-profile status ${label}`);
  assert(mapSource.includes('window.iClubExamPrepWeeklyFlowEnabled === true && data.plan_rebuild_required === true'));
  assert(!/localStorage\.setItem|sessionStorage\.setItem/.test(recoverySource+mapSource+apiSource));
  console.log('PASS guarded recovery gate and honest RU/UZ/EN plan-status strings; no browser storage writes');
}
(async()=>{
  for(const enabled of [false,true]) for(const changed of [false,true]) await runApi(enabled,changed);
  staticContracts();
  console.log('GREEN profile/recovery entrypoint regression: four executable API scenarios + trilingual safety contracts');
})().catch(e=>{console.error(e);process.exitCode=1;});
