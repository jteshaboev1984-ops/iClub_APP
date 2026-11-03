#!/usr/bin/env node
'use strict';
// P2-15: pure DOM-less safety/format unit check. No live user data or API writes.
const fs=require('node:fs'),vm=require('node:vm'),assert=require('node:assert/strict'),path=require('node:path');
const JS=fs.readFileSync(path.join(__dirname,'../exam-prep/exam-prep-simple-timeline-ui.js'),'utf8');
const INDEX=fs.readFileSync(path.join(__dirname,'../index.html'),'utf8');
const CSS=fs.readFileSync(path.join(__dirname,'../exam-prep/exam-prep-simple-timeline-ui.css'),'utf8');
function boot(flag, overrides={}){
  const internal={lastCapabilities:{coreAccess:true,killSwitch:false,rolloutState:'controlled_beta'}};
  const state={rpcCount:0,injected:[],listeners:[],boundEvents:0};
  let currentIntro={nextElementSibling:null,insertAdjacentElement(position,el){
    assert.equal(position,'afterend');state.injected.push(el.html);
    // Real DOM: inserting the child into the page removes it from wrapper.
    if(el.parentWrapper) el.parentWrapper.child=null;
    this.nextElementSibling={
      matches:(selector)=>selector==='[data-ep-simple-timeline]'
    };
  }};
  const root={hidden:false,querySelector(selector){
    return selector==='.ep-live-dashboard-intro'?currentIntro:null;
  },contains(x){return x===currentIntro;}};
  const hub={dataset:{subjectKey:'mathematics'}};
  const document={
    readyState:'loading',documentElement:{lang:'ru'},addEventListener(name,cb){state.listeners.push([name,cb])},
    querySelector(selector){
      if(selector==='#exam-prep-host-root') return root;
      if(selector==='#courses-subject-hub') return hub;
      return null;
    },
    createElement(){
      const wrapper={child:null,set innerHTML(v){
        this.child={html:v,parentWrapper:this,
          addEventListener(){state.boundEvents++;},querySelector(){return null;}};
      },get firstElementChild(){return this.child;}};
      return wrapper;
    }
  };
  const window={iClubExamPrepSimpleTimelineUiEnabled:flag,iClubExamPrepHostInternal:internal,
    i18n:{getLang:()=> 'ru'},addEventListener(name,cb){state.listeners.push([name,cb])},
    sb:{async rpc(name,args){state.rpcCount++;return overrides.rpc
       ? overrides.rpc(name,args) : {data:fixture(),error:null};}}};
  class MutationObserver{constructor(cb){this.cb=cb;}observe(){}disconnect(){}}
  vm.runInNewContext(JS,{window,document,MutationObserver,Intl,Date,Promise},
     {timeout:2000,filename:'exam-prep-simple-timeline-ui.js'});
  return {window,internal,root,hub,state,document,setIntro(newIntro){currentIntro=newIntro;}};
}
function fixture(){
  return {contract_version:'exam_prep_one_line_progress_timeline_v2_estimated',
    factors_are_iclub_planning_assumptions_not_official_cambridge:true,
    source_guided_hours_are_not_private_study_hours:true,
    recommended_schedule_applied_automatically:false,learning_evidence_mutated:false,
    start_at:'2026-09-15T00:00:00+05:00',as_of:'2026-11-03T10:00:00+05:00',
    existing_chosen_math_hours_per_week:10,
    joint_paper_dates_status:'both_paper_dates_confirmed',
    estimated_joint_math_hours_per_week:8.9,estimated_remaining_math_hours:111.7,
    P1:{component_code:'P1',total_syllabus_skills:45,objectively_covered_skills:5,
      already_attempted_not_yet_confirmed_skills:10,not_yet_checked_skills:30,
      skills_not_yet_objectively_covered:40,estimated_remaining_study_hours:63.5,
      exam_date_status:'valid_exam_date',exam_at:'2027-05-12T09:00:00+05:00'},
    P5:{component_code:'P5',total_syllabus_skills:36,objectively_covered_skills:0,
      already_attempted_not_yet_confirmed_skills:3,not_yet_checked_skills:33,
      skills_not_yet_objectively_covered:36,estimated_remaining_study_hours:48.2,
      exam_date_status:'valid_exam_date',exam_at:'2027-05-20T09:00:00+05:00'}
  };
}
async function main(){
  assert(JS.includes("window.iClubExamPrepSimpleTimelineUiEnabled !== true"),
    'Module must remain opt-in and fail-closed');
  assert(INDEX.includes('exam-prep-simple-timeline-ui.js?v=p2-15'));
  assert(INDEX.includes('exam-prep-simple-timeline-ui.css?v=p2-15'));
  assert(CSS.includes('@media (max-width:540px)'));
  assert(CSS.includes('grid-template-columns:repeat(2,minmax(0,1fr))'));
  assert(!CSS.includes('!important'));
  let off=boot(false);
  assert.equal(off.internal.simpleTimelineUi,undefined,'OFF is truly invisible');
  assert.equal(off.state.rpcCount,0);

  const b=boot(true),ui=b.internal.simpleTimelineUi;
  assert(ui && ui.version==='p2_16_learner_dates_ui_v1');
  const model=ui.parsePayload(fixture());
  assert(model);
  assert.equal(model.totalHours,111.7);
  assert.equal(model.weekly,8.9);
  assert.equal(model.cards[0].confirmed,5);
  assert.equal(model.cards[1].unknown,33);
  assert.equal(ui.inputDate('2027-05-12T07:00:00Z'),'2027-05-12');
  assert.equal(ui.validInputDate('2028-05-12',{min:'2027-01-01',max:'2029-12-31'}),true);
  assert.equal(ui.validInputDate('2024-01-01',{min:'2027-01-01',max:'2029-12-31'}),false);
  assert.equal(ui.validInputDate('2032-01-01',{min:'2027-01-01',max:'2029-12-31'}),false);
  for(const [lang,label] of [['ru','Мой путь к экзамену'],['uz','Imtihongacha yo‘lim'],['en','My exam timeline']]){
    const markup=ui.viewHtml(model,lang);
    assert(markup.includes(label),lang);
    assert(markup.includes('data-ep-tl-paper="P1"') &&
      markup.includes('data-ep-tl-paper="P5"'));
    assert(markup.includes('data-ep-simple-timeline'));
    assert(markup.includes('data-ep-tl-date-editor') && markup.includes('type="date"'));
    assert(markup.includes('data-ep-tl-open-date="P1"') && markup.includes('data-ep-tl-open-date="P5"'));
    assert(markup.includes('data-ep-tl-save disabled'),'One-save control must start disabled');
    assert(!/school|школ|maktab/i.test(markup),'No school confirmation UI');
    assert(!markup.includes('NaN')&&!markup.includes('undefined'));
    assert(!markup.includes('486')&&!markup.includes('synthetic'));
  }

  const bogus=fixture();bogus.P1.objectively_covered_skills=45;
  assert.equal(ui.parsePayload(bogus),null,'No impossible overcount');
  const fake=fixture();fake.source_guided_hours_are_not_private_study_hours=false;
  assert.equal(ui.parsePayload(fake),null,'No official hour mislabel');
  const mismatched=fixture();mismatched.estimated_remaining_math_hours=42;
  assert.equal(ui.parsePayload(mismatched),null,'No inconsistent total');
  const noDates=fixture();
  noDates.P1.exam_at=null;noDates.P1.exam_date_status='exam_date_not_yet_selected';
  noDates.P5.exam_at=null;noDates.P5.exam_date_status='exam_date_not_yet_selected';
  noDates.joint_paper_dates_status='missing_at_least_one_paper_exam_date';
  noDates.estimated_joint_math_hours_per_week=null;
  assert.equal(ui.parsePayload(noDates).weekly,null);
  const singleDate=fixture();
  singleDate.P1.estimated_component_weekly_hours=4.2;
  singleDate.P5.exam_at=null;
  singleDate.P5.exam_date_status='exam_date_not_yet_selected';
  singleDate.estimated_joint_math_hours_per_week=null;
  singleDate.joint_paper_dates_status='missing_at_least_one_paper_exam_date';
  assert(ui.viewHtml(ui.parsePayload(singleDate),'ru').includes('P1 · Ориентир в неделю'),
    'One learner date already provides their individual paper weekly target');
  const noDateHtml=ui.viewHtml(ui.parsePayload(noDates),'ru');
  assert(noDateHtml.includes('Укажите даты экзаменов P1 и P5'));
  assert(!noDateHtml.includes('8,9'));
  const malicious=fixture();malicious.as_of='<img src=x onerror=alert(1)>';
  assert(!ui.viewHtml(ui.parsePayload(malicious),'en').includes('<img'));
  b.hub.dataset.subjectKey='economics';
  ui.reconcile();await Promise.resolve();
  assert.equal(b.state.rpcCount,0,'No RPC for economics');
  b.hub.dataset.subjectKey='mathematics';
  b.root.hidden=true;ui.reconcile();await Promise.resolve();
  assert.equal(b.state.rpcCount,0,'No RPC while hidden');
  b.root.hidden=false;b.internal.lastCapabilities.coreAccess=false;
  ui.reconcile();await Promise.resolve();
  assert.equal(b.state.rpcCount,0,'No RPC without core access');
  b.internal.lastCapabilities.coreAccess=true;
  ui.reconcile();await new Promise(setImmediate);
  assert.equal(b.state.rpcCount,1);
  assert.equal(b.state.injected.length,1,'One card, no duplicate');
  assert(b.state.boundEvents>0,'Native calendar click must bind to actual moved DOM node');
  assert(b.state.injected[0].includes('data-ep-simple-timeline'));
  ui.reconcile();await new Promise(setImmediate);
  assert.equal(b.state.rpcCount,1,'No duplicate request for same dashboard');
  b.hub.dataset.subjectKey='chemistry';
  ui.reconcile();assert.equal(b.state.rpcCount,1);

  let settle;
  const inFlight=boot(true,{rpc:()=>new Promise(resolve=>{settle=resolve;})});
  inFlight.internal.simpleTimelineUi.reconcile();
  inFlight.hub.dataset.subjectKey='economics';
  inFlight.internal.simpleTimelineUi.reconcile();
  settle({data:fixture(),error:null});await new Promise(setImmediate);
  assert.equal(inFlight.state.injected.length,0,'Old owner/subject response never injected');
  console.log('PASS P2-15: trilingual text, responsive two-paper timeline, exact count contract, no date fallback, fail-closed owner switch and stale response.');
}
main().catch(e=>{console.error(e);process.exitCode=1;});
