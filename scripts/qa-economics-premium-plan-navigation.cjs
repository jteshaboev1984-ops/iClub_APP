#!/usr/bin/env node
'use strict';
const fs=require('node:fs'),vm=require('node:vm'),assert=require('node:assert/strict');
const path=require('node:path'),root=path.resolve(__dirname,'..');
const read=p=>fs.readFileSync(path.join(root,p),'utf8');
const native=read('exam-prep/exam-prep-economics-native.js');
const written=read('exam-prep/runtime/written-core-view-v1.js');
const css=read('exam-prep/exam-prep-economics-native.css');
const writtenCss=read('exam-prep/runtime/written-core-source-v1.css');
const html=read('index.html');
new Function(native);new Function(written);
class Node{
 constructor(tag){this.tagName=tag;this.className='';this.textContent='';this.children=[];this.events={};this.attributes={};this.disabled=false;this.hidden=false;this.isConnected=false;this.classList={add:()=>{},remove:()=>{}};}
 append(...xs){this.children.push(...xs);return this;}
 replaceChildren(...xs){this.children=[...xs];}
 get firstElementChild(){return this.children[0]||null;}
 addEventListener(event,fn){this.events[event]=fn;}
 setAttribute(k,v){this.attributes[k]=v;}
 querySelectorAll(){return [];}
}
const flat=n=>[n,...n.children.flatMap(flat)];
const find=(n,part)=>flat(n).find(x=>x.className.includes(part));
const buttons=n=>flat(n).filter(x=>x.tagName==='button');
const tick=async()=>{for(let i=0;i<30;i++)await Promise.resolve();};
const sessions=[{session_id:'safe-session',paper_code:'P1',session_kind:'diagnostic',status:'finalized',score:9,answered:12,total_items:12}];
const items=Array.from({length:12},(_,i)=>({question:'Sample question '+i,options:['A','B','C','D'],selected_index:0,correct_index:0,answered:true}));
const plan={ok:true,session_kind:'diagnostic',weekly_economics_hours:3,score:9,out_of:12,weak_count:3,studied_count:1,retested_correct_count:1,suggested_minutes_per_topic:20,
 priorities:[{title:'Opportunity cost',suggested_day:1,skill_key:'one',lesson:'Learn the tradeoff',studied:false}],
 unit_results:[{unit:1,correct:2,total:3}]};

async function nativeCase(language){
 const host=new Node('main'),calls=[];
 const sb={rpc:async(name,args)=>{
  calls.push(name);
  if(name==='iclub_exam_native_mcq_history_v1')return {data:{ok:true,sessions}};
  if(name==='iclub_exam_native_economics_profile_v1')return {data:{ok:true,profile:null}};
  if(name==='iclub_exam_written_available_v1')return {data:{ok:true,available:false}};
  if(name==='iclub_econ_written_beta_status_v1')return {data:{ok:true,eligible:false,joined:false}};
  if(name==='iclub_exam_native_mcq_get_v1')return {data:{ok:true,status:'finalized',score:9,session_kind:'diagnostic',items}};
  if(name==='iclub_exam_native_mcq_study_plan_v1')return {data:plan};
  throw Error('Unexpected RPC '+name);
 }};
 const dom={window:{sb,crypto:{randomUUID:()=> 'safe-key'},iClubWrittenCoreViewV1:{mount:()=>null}},document:{createElement:t=>new Node(t)},console,Date,Intl,setInterval:()=>0,clearInterval:()=>{}};
 dom.window.window=dom.window;dom.window.document=dom.document;
 vm.runInNewContext(native,dom);
 const app=dom.window.iClubExamPrepHostInternal.economicsNative;
 assert.equal(app.mount({root:host,shell:{program_key:'economics_9708',enabled:true,
 papers:[{code:'P1',assessment_kind:'mcq'},{code:'P3',assessment_kind:'mcq'}]},language}),true);
 await tick();
 const p1=buttons(host).find(b=>b.className.includes('ep-live-component-entry')&&flat(b).some(x=>x.textContent==='P1'));
 assert(p1,language+' missing P1');
 p1.events.click();
 const planBtn=buttons(host).find(b=>b.textContent===({ru:'Мой учебный план',uz:'Mening o‘quv rejam',en:'My study plan'})[language]);
 assert(planBtn,language+' missing study plan action');
 planBtn.events.click();await tick();
 const stats=find(host,'ep-native-plan-stats-compact');
 assert(stats,language+' compact plan grid missing');
 assert.equal(stats.children.length,4,language+' needs exactly four summary cards');
 assert.deepEqual(stats.children.map(c=>c.children[0].textContent),['9/12','2','1','1']);
 const bar=find(host,'ep-native-screen-head');
 assert(bar,language+' screen header missing');
 const back=bar.children[0];
 assert.equal(back.tagName,'button');
 assert(back.className.includes('ep-native-screen-back'));
 assert.equal(back.textContent,'‹');
 assert.equal(back.attributes['aria-label'],({ru:'Назад',uz:'Orqaga',en:'Back'})[language]);
 assert.equal(bar.children[1].className,'ep-native-screen-title');
 assert(calls.includes('iclub_exam_native_mcq_study_plan_v1'),'Study plan must still load from server');
 back.events.click();
 assert(!find(host,'ep-native-plan-stats-compact'),'Back must return to Paper screen without mutating a plan');
 assert(!calls.includes('iclub_exam_native_mcq_mark_studied_v1'),'Visual navigation must not mark study complete');
 app.unmount();
}
function writtenCase(language){
 const host=new Node('main');
 const stub={create:()=>({
  open:async()=>({}),criteria:async()=>({}),next:async()=>({}),snapshot:()=>({})})};
 const dom={window:{iClubWrittenCoreControllerV1:stub,crypto:{randomUUID:()=> 'safe'}},
 document:{createElement:t=>new Node(t)},console};
 vm.runInNewContext(written,dom);
 const api={available:async()=>({ok:true,available:false}),next:async()=>({ok:true,status:'completed'}),
  open:async()=>({}),criteria:async()=>({}),advance:async()=>({}),status:async()=>({})};
 const component=dom.window.iClubWrittenCoreViewV1.mount({root:host,planId:'plan',language,api,onBack:()=>{}});
 assert(component);
 const bar=find(host,'ep-written-screen-head');
 assert(bar,'Written Core header missing');
 const back=bar.children[0];
 assert.equal(back.tagName,'button');
 assert.equal(back.textContent,'‹');
 assert(back.className.includes('ep-written-screen-back'));
 assert.equal(back.attributes['aria-label'],({ru:'Назад',uz:'Orqaga',en:'Back'})[language]);
 assert.equal(bar.children[1].tagName,'h2','Written title must align to the right of Back');
 component.dispose();
}
(async()=>{
 for(const lang of ['ru','uz','en']){await nativeCase(lang);writtenCase(lang);}
 assert(css.includes('#exam-prep-host-root .ep-native-plan-stats-compact'),'Scoped plan styles required');
 assert(css.includes('grid-template-columns: repeat(2,minmax(0,1fr))'),'Mobile 2x2 layout required');
 assert(css.includes('grid-template-columns: repeat(4,minmax(0,1fr))'),'Wide screen balanced grid required');
 assert(css.includes('.ep-native-screen-back:focus-visible'),'Accessible native keyboard focus required');
 assert(writtenCss.includes('.ep-written-screen-back:focus-visible'),'Accessible written keyboard focus required');
 assert(!native.includes('localStorage.clear(')&&!written.includes('localStorage.clear('),'Never reset local progress');
 for(const token of ['exam-prep-economics-native.js?v=econ-plan-no-consent-20261029',
  'exam-prep-economics-native.css?v=econ-plan-no-consent-20261029',
  'written-core-view-v1.js?v=econ-plan-no-consent-20261029',
  'written-core-source-v1.css?v=econ-plan-no-consent-20261029'])
  assert(html.includes(token),'Stale browser asset '+token);
 console.log('ECONOMICS PREMIUM NAVIGATION PASS — 3 languages, actual 4 metrics, mobile grid and both Back headers');
})().catch(err=>{console.error(err);process.exitCode=1;});
