"use strict";
const assert=require("node:assert/strict");
const fs=require("node:fs");
const vm=require("node:vm");
const source=fs.readFileSync("exam-prep/exam-prep-chemistry-theory-native.js","utf8");
const host=fs.readFileSync("exam-prep/exam-prep-host.js","utf8");
const html=fs.readFileSync("index.html","utf8");
const css=fs.readFileSync("exam-prep/exam-prep-host.css","utf8");
let assertions=0;
function check(value,message){assert.ok(value,message);assertions++;}
class Node {
 constructor(tag){this.tag=tag;this.children=[];this.listeners={};this.className="";this.textContent="";this.attrs={};this.open=false;}
 setAttribute(k,v){this.attrs[k]=v;}
 addEventListener(k,fn){this.listeners[k]=fn;}
 append(...items){this.children.push(...items);}
 replaceChildren(...items){this.children=items;}
}
const context={window:{iClubExamPrepHostInternal:{},sb:{rpc:async()=>({data:{ok:false,code:"not_available"}})}},document:{createElement:tag=>new Node(tag)}};
vm.runInNewContext(source,context,{filename:"j24_theory_native.js"});
const m=context.window.iClubExamPrepHostInternal.chemistryTheoryNative;
check(typeof m?.mount==="function"&&typeof m?.unmount==="function","Native AS module methods exist");
function catalog(lang="en"){
 const items=Array.from({length:91},(_,i)=>{
 const n=i+1;
 return {skill_key:"CHEM9701-"+String(n).padStart(2,"0")+"-01",
   title:"Synthetic Chemistry theory "+n,tour_number:Math.floor(i/19)+1,
   syllabus_point:n===10?"NO_EXPLICIT_9701_OUTCOME":"SYNTHETIC",
   is_syllabus_outcome:n!==10};
 });
 return {ok:true,scope:"AS_theory_only",locale:lang,count:91,
  can_credit_mastery:false,ai_tutor_included:false,items};
}
const c=catalog();
check(m.validCatalog(c),"Exact 91-card catalog accepted");
check(!m.validCatalog({...c,count:90}),"Wrong count rejected");
check(!m.validCatalog({...c,ai_tutor_included:true}),"Tutor leak rejected");
check(!m.validCatalog({...c,can_credit_mastery:true}),"Mastery credit rejected");
check(!m.validCatalog({...c,items:c.items.map((x,i)=>i===90?{...x,skill_key:c.items[0].skill_key}:x)}),"Duplicate skill rejected");
check(!m.validCatalog({...c,items:c.items.map((x,i)=>i===90?{...x,tour_number:6}:x)}),"A-level tour rejected");
check(!m.validCatalog({...c,items:c.items.map((x,i)=>i===9?{...x,is_syllabus_outcome:true}:x)}),"Unscored enrichment must remain explicit");
const root=new Node("div");let closed=0;
check(m.mount({root,catalog:c,language:"en",onBack:()=>closed++}),"Authorized catalog mount accepted");
check(root.children.length===1,"Single mounted root");
const sections=root.children[0].children.find(x=>x.className==="ep-chem-theory-sections");
check(sections&&sections.children.length===5,"Exactly five AS teaching sections");
const topicButtons=sections.children.flatMap(x=>x.children[1].children);
check(topicButtons.length===91,"Exactly 91 topic buttons, no A Level");
check(!source.includes("innerHTML")&&!source.includes("localStorage")&&!source.includes("eval("),"No unsafe HTML or browser-persistent writes");
check(html.split("exam-prep/exam-prep-chemistry-theory-native.js?").length===2,"Exactly one cache-pinned Theory script");
check(html.indexOf("exam-prep-chemistry-labs-native.js?")<html.indexOf("exam-prep-chemistry-theory-native.js?"),"Chemistry modules loaded in order");
check(!host.includes("CHEMISTRY_PRELAUNCH_INVITATIONS_ENABLED")&&!host.includes("get_my_exam_prep_chemistry_beta_status_v1"),"No Chemistry invitations or consent UI");
check(host.includes('internal.chemistryTheoryNative?.validCatalog?.(catalog) === true'),"Host independently validates backend catalog");
check(host.includes("chemistryTheoryNative?.unmount?.()"),"Host closes Theory context");
check(css.includes("@media(max-width: 660px)")&&css.includes(".ep-chem-theory-grid"),"Mobile symmetric layout provided");
check(!m.mount({root,catalog:{...c,locale:"ru"},language:"en",onBack:()=>{}}),"Wrong language catalog rejected");
m.unmount();
console.log("J24 AS-only Theory UI synthetic safety: "+assertions+"/"+assertions+" PASS");
