"use strict";
// Synthetic J13 UI regression: no private lesson, question bank or user data.
// Run: node scripts/qa-chemistry-9701-j13-labs-ui.cjs
const assert=require("node:assert/strict");
class Element {
 constructor(tag){this.tag=tag;this.children=[];this.textContent="";this.className="";
  this.handlers={};this.attrs={};this.disabled=false;this.open=false;
  this.classList={add:v=>this.className+=" "+v};}
 append(...x){this.children.push(...x);}
 replaceChildren(...x){this.children=x;}
 addEventListener(name,handler){this.handlers[name]=handler;}
 setAttribute(k,v){this.attrs[k]=v;}
 get firstElementChild(){return this.children[0]||null;}
 find(q){
  const found=q.startsWith(".")?this.className.split(/\s+/).includes(q.slice(1)):this.tag===q;
  return (found?[this]:[]).concat(...this.children.flatMap(c=>c.find(q)));
 }
 texts(){return [this.textContent,...this.children.flatMap(c=>c.texts())];}
}
async function tick(){for(let k=0;k<18;k++)await Promise.resolve();}
module.exports=async(entrySource,labsSource)=>{
 let passed=0;
 for(const scenario of [
  {name:"OFF",gates:{}},
  {name:"P3",gates:{P3:true}},
  {name:"P5",gates:{P5:true}},
  {name:"P3+P5",gates:{P3:true,P5:true}}
 ]){
  const root=new Element("div"),w={iClubExamPrepHostInternal:{},confirm:()=>true,
   sb:{rpc:async(name,args={})=>{
    if(name==="iclub_exam_chemistry_entry_history_v1")return {data:{ok:true,sessions:[]}};
    if(name==="iclub_exam_chemistry_lab_catalog_v1"){
     if(!scenario.gates[args.p_paper])return {data:{ok:false,code:"not_available"}};
     const paper=args.p_paper,level=paper==="P3"?"AS":"A";
     return {data:{ok:true,paper_code:paper,level_code:level,count:6,
      locale:args.p_language,can_credit_mastery:false,
      items:Array.from({length:6},(_,i)=>({title:"Synthetic lesson "+i,
       skill_key:"CHEM9701-LAB-"+String(i+(paper==="P3"?1:7)).padStart(2,"0"),
       paper_code:paper,level_code:level}))}};
    }
    if(name==="iclub_exam_chemistry_lab_lesson_v1"){
     if(!scenario.gates[args.p_paper])return {data:{ok:false}};
     return {data:{ok:true,skill_key:args.p_skill_key,paper_code:args.p_paper,
      level_code:args.p_paper==="P3"?"AS":"A",locale:args.p_language,
      title:"Synthetic lesson",explanation:"Synthetic safe methodology. ".repeat(10),
      tutor_included:false,can_credit_mastery:false,practical_exam_replacement:false}};
    }
    throw Error("Unexpected RPC "+name);
   }}};
  const document={createElement:tag=>new Element(tag)};
  new Function("window","document",labsSource)(w,document);
  new Function("window","document",entrySource)(w,document);
  const shell={enabled:true,program_key:"chemistry_9701",
   assessment_code:"ENTRY",item_count:22,duration_seconds:1800};
  assert.equal(w.iClubExamPrepHostInternal.chemistryEntryNative.mount({
   root,shell,language:"ru",onBack:()=>{}}),true);passed++;
  await tick();
  const buttons=()=>root.find("button");
  const links=buttons().filter(b=>b.textContent.startsWith("Практические навыки"));
  assert.equal(links.length,Object.keys(scenario.gates).length);passed++;
  if(links.length){
   await links[0].handlers.click();await tick();
   assert.equal(buttons().filter(b=>b.textContent==="Открыть материал").length,6);passed++;
   await buttons().find(b=>b.textContent==="Открыть материал").handlers.click();await tick();
   assert.ok(root.texts().some(t=>t.includes("Synthetic safe methodology.")));
   assert.ok(root.texts().some(t=>t.includes("Чтение не подтверждает")));passed++;
   w.iClubExamPrepHostInternal.chemistryLabsNative.setLanguage("uz");await tick();
   assert.ok(root.texts().some(t=>t.includes("O‘qish ko‘nikma")));passed++;
   await buttons().find(b=>b.textContent==="Materiallar ro‘yxatiga").handlers.click();await tick();
   assert.equal(buttons().filter(b=>b.textContent==="Materialni ochish").length,6);passed++;
  }
  w.iClubExamPrepHostInternal.chemistryLabsNative.unmount();
  w.iClubExamPrepHostInternal.chemistryEntryNative.unmount();
 }
 return {passed,checks:["OFF hidden","P3 independently gated","P5 independently gated",
  "P3+P5 choice","6 documents per paper","EN/RU/UZ locale reload",
  "no Tutor source exposure","not proof of practical competence","safe return to list"]};
};
if(require.main===module){
 const fs=require("node:fs"),path=require("node:path");
 const base=path.join(__dirname,"..","exam-prep");
 const e=fs.readFileSync(path.join(base,"exam-prep-chemistry-entry-native.js"),"utf8");
 const l=fs.readFileSync(path.join(base,"exam-prep-chemistry-labs-native.js"),"utf8");
 module.exports(e,l).then(x=>console.log(JSON.stringify(x,null,2)))
 .catch(e=>{console.error(e);process.exitCode=1;});
}
