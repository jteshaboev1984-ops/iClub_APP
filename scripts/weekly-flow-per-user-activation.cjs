const fs = require('fs');
const vm = require('vm');
const assert = require('assert');

const source = fs.readFileSync('exam-prep/exam-prep-api.js','utf8');

async function run({caps,statusReply,statusError=false,capError=false,initial=true}) {
  const calls=[];
  const window={
    iClubExamPrepWeeklyFlowEnabled: initial,
    iClubExamPrepProgressUxEnabled: false,
    iClubExamPrepHostInternal: {},
    sb: {
      async rpc(name,args={}) {
        calls.push({name,args});
        if (name==='get_exam_prep_capabilities_v1') {
          return capError ? {data:null,error:{message:'cap failure'}} : {data:[caps],error:null};
        }
        if (name==='get_my_exam_prep_weekly_flow_status_v1') {
          return statusError ? {data:null,error:{message:'status failure'}} : {data:statusReply,error:null};
        }
        return {data:null,error:{message:'unexpected '+name}};
      }
    },
    dispatchEvent(){},
  };
  const document={
    currentScript:{src:'https://example.invalid/exam-prep-api.js'},
    querySelector(){return {};},
    createElement(){return {dataset:{}};},
    head:{appendChild(){}}
  };
  const context={window,document,CustomEvent:function(){},console,URL,setTimeout,clearTimeout};
  vm.createContext(context);
  vm.runInContext(source,context,{filename:'exam-prep-api.js'});
  const result=await window.iClubExamPrepHostInternal.api.capabilities();
  return {window,calls,result};
}

const goodCaps={
  program_key:'math_as_p1_p5',
  rollout_state:'controlled_beta',
  core_access:true,
  ai_assist:false,
  mentor_care_entitled:false,
  mentor_assignment_active:false,
  mentor_authority:false,
  kill_switch:false
};

(async()=>{
  let x=await run({caps:goodCaps,statusReply:{contract_version:'weekly_flow_status_v1',enabled:true},initial:false});
  assert.equal(x.result.ok,true);
  assert.equal(x.window.iClubExamPrepWeeklyFlowEnabled,true);
  assert.equal(x.calls.filter(c=>c.name==='get_my_exam_prep_weekly_flow_status_v1').length,1);

  x=await run({caps:goodCaps,statusReply:{contract_version:'weekly_flow_status_v1',enabled:false},initial:true});
  assert.equal(x.window.iClubExamPrepWeeklyFlowEnabled,false);

  x=await run({caps:goodCaps,statusReply:null,statusError:true,initial:true});
  assert.equal(x.window.iClubExamPrepWeeklyFlowEnabled,false,'status RPC failure must fail closed');

  x=await run({caps:{...goodCaps,kill_switch:true,core_access:false},statusReply:{contract_version:'weekly_flow_status_v1',enabled:true},initial:true});
  assert.equal(x.window.iClubExamPrepWeeklyFlowEnabled,false,'Core OFF/kill switch must force weekly OFF');
  assert.equal(x.calls.filter(c=>c.name==='get_my_exam_prep_weekly_flow_status_v1').length,0,'weekly status must not be queried outside Core controlled beta');

  x=await run({caps:goodCaps,statusReply:{contract_version:'weekly_flow_status_v1',enabled:true},capError:true,initial:true});
  assert.equal(x.result.ok,false);
  assert.equal(x.window.iClubExamPrepWeeklyFlowEnabled,false,'capability failure must clear stale weekly flag');

  console.log('weekly-flow per-user activation: PASS');
})().catch(err=>{console.error(err);process.exit(1);});
