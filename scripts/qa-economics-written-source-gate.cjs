#!/usr/bin/env node
'use strict';
const fs=require('node:fs');
const path=require('node:path');
const vm=require('node:vm');
const assert=require('node:assert/strict');
const root=path.resolve(__dirname,'..');
const read=p=>fs.readFileSync(path.join(root,p),'utf8');
const migration='supabase/migrations/20261027163633_iclub_exam_written_private_section_a_sources_v1.sql';
const sql=read(migration);
const view=read('exam-prep/runtime/written-core-view-v1.js');
const ctl=read('exam-prep/runtime/written-core-controller-v1.js');
const css=read('exam-prep/runtime/written-core-source-v1.css');
const html=read('index.html');
const jsPaths=['exam-prep/runtime/written-core-view-v1.js','exam-prep/runtime/written-core-controller-v1.js'];
for(const code of [view,ctl])new Function(code);
for(const k of [
 'private.iclub_exam_written_source_locale_valid_v1',
 'private.iclub_exam_written_source_ready_v1',
 'private.iclub_exam_core_written_open_with_source_v2',
 'public.iclub_exam_written_open_v1',
 'public.iclub_exam_written_available_v1',
 'public.iclub_exam_written_next_v1',
 'public.iclub_exam_written_criteria_v1',
 'public.iclub_exam_written_advance_v1',
 'REVOKE ALL ON private.iclub_exam_written_source_cards_v1',
 'REVOKE ALL ON private.iclub_exam_written_source_bindings_v1',
 's.content_sha256','s.release_enabled=true'
])assert(sql.includes(k),'Missing source gate: '+k);
assert(sql.trimEnd().endsWith('COMMIT;'),'Transactional migration required');
assert(!sql.includes('DELETE FROM private.exam_prep'),'Do not mutate legacy Math');
assert(html.includes('runtime/written-core-source-v1.css'),'CSS asset missing');
assert(html.includes('runtime/written-core-view-v1.js?v=written-source-20261027'),'JS cache pin missing');
assert(css.includes('overflow-x: auto'),'Mobile source table needs a bounded scroll container');
assert(view.includes('textContent=String(str)'),'Source must be inserted as text, not HTML');

class Element{
 constructor(tag){this.tagName=tag;this.children=[];this.events={};this.textContent='';this.hidden=false;this.className='';this.disabled=false;}
 append(...children){this.children.push(...children)}
 replaceChildren(...children){this.children=[...children]}
 setAttribute(name,value){this[name]=value}
 addEventListener(name,handler){this.events[name]=handler}
}
const flatten=element=>[element,...element.children.flatMap(flatten)];
async function check(lang,mode){
 const w={crypto:{randomUUID:()=> 'smoke-uuid-123456'}};
 w.window=w;w.document={createElement:tag=>new Element(tag)};w.globalThis=w;
 vm.runInNewContext(ctl,w);vm.runInNewContext(view,w);
 const taskKey=mode==='B'?'P4.B1':'P4.A.a';
 const otherSubject=mode==='chemistryA';
 const source={source_id:'P4-A-Nerava-v1',source_version:'v3',language:lang,
 title:'Nerava',paragraphs:['Source paragraph.'],
 table:{columns:['Indicator','A','B'],rows:[['Goods',30,34],['Services',12,14]],unit:'US$ billions'}};
 const api={
   available:async()=>({ok:true,available:true}),
   next:async()=>({status:'ready',plan_item_id:'item1'}),
   open:async()=>({task_kind:'written_external',task_token:'token1',task_key:taskKey,
      task_version:'v3',plan_item_id:'item1',program_key:otherSubject?'chemistry_9701':'economics_9708',
      program_version:'economics_2026_2028_v1',paper_code:'P4',
      question:'Analyse the case',runtime_enabled:true,can_advance:true,
      ...(mode==='A'?{source}:{})}),
   criteria:async()=>({available:true,task_key:taskKey,task_version:'v3',
      requirements:['Explain a mechanism'],title:'Answer requirements'}),
   advance:async()=>({status:'advanced',plan_item_id:'item1',task_key:taskKey,task_version:'v3'}),
   status:async()=>({status:'advanced',plan_item_id:'item1',task_key:taskKey,
      task_version:'v3',program_version:'economics_2026_2028_v1'})
 };
 const host=new Element('main');
 const mounted=w.iClubWrittenCoreViewV1.mount({root:host,planId:'plan1',language:lang,api});
 assert(mounted,'Unable to mount written view');
 for(let i=0;i<30;i++)await Promise.resolve();
 const nodes=flatten(host),tables=nodes.filter(x=>x.tagName==='table');
 const textVisible=nodes.some(x=>x.textContent==='Analyse the case');
 if(mode==='A'){assert.equal(tables.length,1,'Source A table missing');assert(textVisible,'Approved question missing')}
 if(mode==='missing'){assert.equal(tables.length,0,'Unapproved source table displayed');assert(!textVisible,'Question leaked without source')}
 if(mode==='B'){assert.equal(tables.length,0,'Non-A requires no source');assert(textVisible,'Ordinary essay question missing')}
 if(mode==='chemistryA'){assert.equal(tables.length,0,'Chemistry must remain independent');assert(textVisible,'Other subject question suppressed')}
 mounted.dispose();
}
(async()=>{
 let n=0;
 for(const lang of ['en','ru','uz'])for(const mode of ['A','missing','B','chemistryA']){await check(lang,mode);n++}
 console.log(JSON.stringify({economics_written_source_gate:'PASS',js_tests:n,js_syntax:true,sql_gates:true,no_student_scores:true}));
})().catch(err=>{console.error(err);process.exit(1)});
