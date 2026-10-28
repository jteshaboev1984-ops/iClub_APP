#!/usr/bin/env node
'use strict';
const assert=require('node:assert/strict');
const fs=require('node:fs');
const vm=require('node:vm');
const path=require('node:path');
const root=path.resolve(__dirname,'..');
const native=fs.readFileSync(path.join(root,'exam-prep/exam-prep-economics-native.js'),'utf8');
const html=fs.readFileSync(path.join(root,'index.html'),'utf8');
new Function(native);

class Node {
 constructor(tag){
  this.tagName=tag;this.className='';this.textContent='';this.children=[];
  this.events={};this.disabled=false;this.isConnected=false;this.hidden=false;
  this.classList={add:()=>{},remove:()=>{}};
 }
 append(...items){this.children.push(...items);return this;}
 replaceChildren(...items){this.children=[...items];}
 get firstElementChild(){return this.children[0]||null;}
 addEventListener(name,fn){this.events[name]=fn;}
 setAttribute(k,v){this[k]=v;}
 querySelectorAll(){return [];}
}
const tree=n=>[n,...n.children.flatMap(tree)];
const texts=n=>tree(n).map(x=>x.textContent).filter(Boolean);
const buttons=n=>tree(n).filter(x=>x.tagName==='button');
const paperCards=n=>tree(n).filter(x=>x.tagName==='button'&&x.className.includes('ep-live-component-entry'));
const cardCode=c=>tree(c).find(x=>x.className==='ep-live-component-code')?.textContent;
const tick=async()=>{for(let i=0;i<20;i++)await Promise.resolve()};
const langs=['ru','uz','en'];
const SCENARIOS=['uninvited','invited','joined','withdrawn','no-check'];

async function run(lang,scenario) {
 let joined=scenario==='joined',writes=0,leaves=0,mounts=0,opens=0;
 const hasEntry=scenario!=='no-check';
 const host=new Node('main');
 const sb={rpc:async(name,args)=>{
  if(name==='iclub_exam_native_mcq_history_v1')return {data:{ok:true,sessions:hasEntry?[{
    paper_code:'P1',session_kind:'diagnostic',status:'finalized',score:10,
    answered:12,total_items:12,session_id:'diag-test-id'}]:[]}};
  if(name==='iclub_exam_native_economics_profile_v1')return {data:{ok:true,profile:null}};
  if(name==='iclub_exam_written_available_v1')return {data:{
    ok:true,available:joined,plan_id:joined?'owned-plan':null}};
  if(name==='iclub_econ_written_beta_status_v1')return {data:{
    ok:true,eligible:scenario==='invited'&&!joined,joined}};
  if(name==='iclub_econ_written_beta_join_v1'){
   assert.equal(args.p_confirm,true,'An explicit affirmative action is required');
   writes++;joined=true;return {data:{ok:true,joined:true}};
  }
  if(name==='iclub_econ_written_beta_leave_v1'){leaves++;joined=false;return {data:{ok:true,left:true}};}
  throw Error('Unexpected RPC '+name);
 }};
 const sandbox={window:{sb,crypto:{randomUUID:()=> 'safe-id'},
   iClubWrittenCoreViewV1:{mount:()=>{mounts++;return {dispose:()=>{}}}}},
   document:{createElement:t=>new Node(t)},
   clearInterval:()=>{},setInterval:()=>0,Date,Intl,console};
 sandbox.window.window=sandbox.window;
 sandbox.window.document=sandbox.document;
 sandbox.clearInterval=()=>{};
 sandbox.setInterval=()=>0;
 vm.runInNewContext(native,sandbox);
 const api=sandbox.window.iClubExamPrepHostInternal.economicsNative;
 assert.equal(api.mount({root:host,shell:{program_key:'economics_9708',
  enabled:true,papers:[{code:'P1',assessment_kind:'mcq'},{code:'P3',assessment_kind:'mcq'}]},
  language:lang}),true);
 await tick();
 if(!hasEntry){
  assert.equal(paperCards(host).length,0,'Preserve entry-check prerequisite');
  assert.equal(writes,0,'No background consent');
  api.unmount();return;
 }
 const codes=paperCards(host).map(cardCode);
 assert.deepEqual(codes,['P1','P2','P3','P4'],lang+' '+scenario+' wrong paper ordering');
 assert.equal(writes,0,'Must not auto-enrol while loading');
 const writtenCards=paperCards(host).filter(c=>['P2','P4'].includes(cardCode(c)));
 for(const c of writtenCards){
  assert(texts(c).some(x=>x.includes(lang==='ru'?'Письменная':lang==='uz'?'Yozma':'Written')),
    'Written type missing from card');
 }
 // Paper 4 click MUST only show a truthful information view, not silently
 // jump to an unstarted task or start any server-side session.
 paperCards(host)[3].events.click();
 let ts=texts(host);
 assert(ts.some(x=>x.includes('Paper 4')),'P4 info missing');
 assert.equal(mounts,0,'P4 card cannot skip to written plan');
 assert.equal(writes,0,'P4 card must not silently give consent');
 if(scenario==='uninvited'||scenario==='withdrawn'){
   assert(!buttons(host).some(b=>['Начать письменную практику','Yozma mashqlarni boshlash','Start written practice'].includes(b.textContent)),
     'No invitation should be offered to noneligible learners');
 }
 if(scenario==='invited'){
  const label=lang==='ru'?'Начать письменную практику':lang==='uz'?'Yozma mashqlarni boshlash':'Start written practice';
  const consent=buttons(host).find(b=>b.textContent===label);
  assert(consent,'Invited learner needs explicit opt-in button from P4');
  consent.events.click();
  await tick();
  assert.equal(writes,1,'Exactly one confirmed opt-in');
  assert.deepEqual(paperCards(host).map(cardCode),['P1','P2','P3','P4'],
   'Four papers remain after joining');
  paperCards(host)[1].events.click();
  const open=buttons(host).find(b=>b.textContent===
   (lang==='ru'?'Открыть письменный план':lang==='uz'?'Yozma rejamni ochish':'Open written study plan'));
  assert(open,'P2 info missing owned-plan entry');
  open.events.click();
  assert.equal(mounts,1,'Owner navigates into governed common plan');
 }
 if(scenario==='joined'){
  const msg=lang==='ru'?'По общему плану':lang==='uz'?'bitta reja':'one plan';
  assert(texts(host).some(t=>t.includes('Paper 2')&&t.includes('Paper 4')),
    'Explain shared sequential practice rather than P4 direct jump');
  assert.equal(writes,0,'Existing learner must not re-join');
  const back=buttons(host).find(b=>b.textContent.startsWith('← '));
  assert(back,'Written Paper 4 info back navigation required');
  back.events.click();await tick();
  const leaveLabel=lang==='ru'?'Отключить письменную практику':
   lang==='uz'?'Yozma mashqlarni o‘chirish':'Turn off written practice';
  const leave=buttons(host).find(b=>b.textContent===leaveLabel);
  assert(leave,'Joined learner needs a leave option');
  leave.events.click();
  assert.equal(leaves,0,'First leave click must not revoke access');
  assert(texts(host).some(x=>x.includes(lang==='ru'?'Повторное подключение':
    lang==='uz'?'Qayta ulanish':'Rejoining')),
    'In-app confirmation must explain rejoining limitation');
  leave.events.click();await tick();
  assert.equal(leaves,1,'Second intentional leave click revokes access once');
 }
 if(scenario==='withdrawn')assert.equal(mounts,0,'Withdrawn learner has no practice access');
 api.unmount();
}
(async()=>{
 let n=0;
 for(const lang of langs)for(const scenario of SCENARIOS){await run(lang,scenario);n++}
 assert(html.includes('exam-prep-economics-native.js?v=econ-mark-scheme-premium-safeleave-20261028'),'App must load updated paper grid, not cached P1/P3-only JS');
 console.log('ECONOMICS FOUR PAPERS UI PASS',n,'scenarios × 3 locales; no automatic joining / no P4 bypass');
})().catch(e=>{console.error(e);process.exitCode=1});
