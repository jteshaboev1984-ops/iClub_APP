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
    start_at:'2026-10-01T11:00:00+05:00',as_of:'2026-11-03T10:00:00+05:00',
    existing_chosen_math_hours_per_week:10,
    student_total_hours_per_week:12,student_budget_profile_revision:2,
    joint_paper_dates_status:'both_paper_dates_confirmed',
    estimated_joint_math_hours_per_week:8.9,estimated_remaining_math_hours:111.7,
    P1:{component_code:'P1',start_at:'2026-10-01T11:00:00+05:00',total_syllabus_skills:45,objectively_covered_skills:5,
      already_attempted_not_yet_confirmed_skills:10,not_yet_checked_skills:30,
      skills_not_yet_objectively_covered:40,estimated_remaining_study_hours:63.5,
      exam_date_status:'valid_exam_date',exam_at:'2027-05-12T09:00:00+05:00'},
    P5:{component_code:'P5',start_at:'2026-10-20T11:00:00+05:00',total_syllabus_skills:36,objectively_covered_skills:0,
      already_attempted_not_yet_confirmed_skills:3,not_yet_checked_skills:33,
      skills_not_yet_objectively_covered:36,estimated_remaining_study_hours:48.2,
      exam_date_status:'valid_exam_date',exam_at:'2027-05-20T09:00:00+05:00'}
  };
}
async function main(){
  assert(JS.includes("window.iClubExamPrepSimpleTimelineUiEnabled !== true"),
    'Module must remain opt-in and fail-closed');
  assert(INDEX.includes('exam-prep-simple-timeline-ui.js?v=d09-07-t0dates'));
  assert(INDEX.includes('exam-prep-simple-timeline-ui.css?v=d09-07-t0dates'));
  assert(CSS.includes('@media (max-width:540px)'));
  assert(CSS.includes('grid-template-columns:repeat(2,minmax(0,1fr))'));
  assert(!CSS.includes('!important'));
  let off=boot(false);
  assert.equal(off.internal.simpleTimelineUi,undefined,'OFF is truly invisible');
  assert.equal(off.state.rpcCount,0);

  const b=boot(true),ui=b.internal.simpleTimelineUi;
  assert(ui && ui.version==='p2_18_three_explicit_time_choices_v1');
  const model=ui.parsePayload(fixture());
  assert(model);
  assert.equal(model.totalHours,111.7);
  assert.equal(model.weekly,8.9);
  assert.equal(model.cards[0].confirmed,5);
  assert.equal(model.cards[1].unknown,33);
  assert.equal(model.startAt,'2026-10-01T11:00:00+05:00',
    'Timeline starts at completed Stage0, not profile signup');
  assert.equal(model.cards[0].startAt,'2026-10-01T11:00:00+05:00');
  assert.equal(model.cards[1].startAt,'2026-10-20T11:00:00+05:00');
  const differentT0=ui.viewHtml(model,'en');
  assert(differentT0.includes('01 Oct 2026')&&differentT0.includes('20 Oct 2026'),
    'P1/P5 separate diagnostic start dates must both render');
  const pendingStart=fixture();
  pendingStart.start_at=null;pendingStart.P1.start_at=null;pendingStart.P5.start_at=null;
  for(const [loc,expected] of [['ru','После диагностики'],['uz','Diagnostikadan so‘ng'],['en','After diagnostic']]){
    assert(ui.viewHtml(ui.parsePayload(pendingStart),loc).includes(expected),
      'No unverified signup date presented as the diagnostic start: '+loc);
  }
  assert.equal(model.canAdopt,false,'Already enough time does not create pointless button');
  const short=fixture();
  short.existing_chosen_math_hours_per_week=4;
  const shortModel=ui.parsePayload(short);
  assert.equal(shortModel.canAdopt,true);
  assert.equal(shortModel.profileRevision,2);
  const shortHtml=ui.viewHtml(shortModel,'ru');
  assert(shortHtml.includes('data-ep-tl-accept'));
  assert(shortHtml.includes('data-ep-tl-keep') && shortHtml.includes('data-ep-tl-other'));
  for(const [loc,keep,other,adopt] of [
    ['ru','Оставить моё время','Указать другое время','Принять рекомендуемое'],
    ['uz','O‘z rejamni qoldirish','Boshqa vaqtni tanlash','Tavsiya etilganini qabul qilish'],
    ['en','Keep my plan','Choose another time','Accept suggestion']
  ]) {
    const view=ui.viewHtml(shortModel,loc);
    assert(view.includes(keep) && view.includes(other) && view.includes(adopt),
      'Three explicit study-time choices missing: '+loc);
    assert(view.indexOf('data-ep-tl-keep')<view.indexOf('data-ep-tl-accept') &&
      view.indexOf('data-ep-tl-accept')<view.indexOf('data-ep-tl-other'),
      'Choices must have consistent visual order: '+loc);
  }
  // D10: explain source and uncertainty without gating any student choice.
  const provenance=[
    ['ru','2020 года','не норма самостоятельной подготовки','Только вы решаете'],
    ['uz','2020-yilgi','mustaqil tayyorgarlik me’yori','faqat o‘zingiz'],
    ['en','2020 materials','not a measured independent-study requirement','Only you decide']
  ];
  for(const [locale,...fragments] of provenance){
    const html=ui.viewHtml(shortModel,locale);
    for(const fragment of fragments) assert(html.includes(fragment),
      'Missing D10 estimate explanation in '+locale+': '+fragment);
    assert(html.includes('data-ep-tl-keep') &&
      html.includes('data-ep-tl-accept') &&
      html.includes('data-ep-tl-other'),
      'D10 copy must not introduce a new time-choice blocker');
  }
  const capped=fixture();
  capped.existing_chosen_math_hours_per_week=4;
  capped.student_total_hours_per_week=5;
  const cappedModel=ui.parsePayload(capped);
  assert.equal(cappedModel.canAdopt,false,'Never offer one-tap hours beyond total availability');
  assert(ui.viewHtml(cappedModel,'en').includes('total weekly study budget'));
  const cappedHtml=ui.viewHtml(cappedModel,'en');
  assert(!cappedHtml.includes('data-ep-tl-accept'));
  assert(cappedHtml.includes('data-ep-tl-keep') && cappedHtml.includes('data-ep-tl-other'),
    'Keeping current budget and editing other time must remain possible');
  const urgent=fixture();
  urgent.existing_chosen_math_hours_per_week=4;
  urgent.estimated_joint_math_hours_per_week=1250;
  urgent.P1.estimated_component_weekly_hours=800;
  urgent.P5.estimated_component_weekly_hours=550;
  const urgentModel=ui.parsePayload(urgent);
  assert(urgentModel && urgentModel.suggested===1250,
    'Very near student-selected exam must still show the real extreme estimate');
  assert.equal(urgentModel.canAdopt,false,
    'Never suggest accepting over 168 hours per week');
  const urgentHtml=ui.viewHtml(urgentModel,'ru');
  assert(urgentHtml.includes('168 часов в неделю') &&
    !urgentHtml.includes('Выберите дату хотя бы одного') &&
    !urgentHtml.includes('data-ep-tl-accept'),
    'High weekly target cannot be shown as missing exam date');
  const staleProfile=fixture();staleProfile.existing_chosen_math_hours_per_week=4;
  staleProfile.student_budget_profile_revision=null;
  assert.equal(ui.parsePayload(staleProfile).canAdopt,false,
    'One-click update requires real current owner profile revision');
  assert.equal(ui.inputDate('2027-05-12T07:00:00Z'),'2027-05-12');
  assert.equal(ui.validInputDate('2028-05-12',{min:'2027-01-01'}),true);
  assert.equal(ui.validInputDate('2024-01-01',{min:'2027-01-01'}),false);
  assert.equal(ui.validInputDate('2032-01-01',{min:'2027-01-01'}),true);
  assert.equal(ui.validInputDate('2036-05-12',{min:'2027-01-01'}),true);
  assert.equal(ui.validInputDate('2028-02-30',{min:'2027-01-01'}),false);
  for(const [lang,label] of [['ru','Мой путь к экзамену'],['uz','Imtihongacha yo‘lim'],['en','My exam timeline']]){
    const markup=ui.viewHtml(model,lang);
    assert(markup.includes(label),lang);
    assert(markup.includes('data-ep-tl-paper="P1"') &&
      markup.includes('data-ep-tl-paper="P5"'));
    assert(markup.includes('data-ep-simple-timeline'));
    assert(markup.includes('data-ep-tl-date-editor') && markup.includes('type="date"'));
    assert(!markup.includes(' max="'),'Personal exam dates must not be capped at three years');
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
  assert(noDateHtml.includes('Выберите дату хотя бы одного экзамена'));
  assert(!noDateHtml.includes('8,9'));
  assert(!noDateHtml.includes('data-ep-tl-accept') &&
    !noDateHtml.includes('data-ep-tl-keep') &&
    !noDateHtml.includes('data-ep-tl-other'),'No date, no invented time-choice actions');
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
  console.log('PASS P2-17: trilingual text, responsive two-paper timeline, exact count contract, no date fallback, fail-closed owner switch and stale response.');
}
main().catch(e=>{console.error(e);process.exitCode=1;});
