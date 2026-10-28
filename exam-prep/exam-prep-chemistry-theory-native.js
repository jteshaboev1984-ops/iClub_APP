(function(){
"use strict";
const internal=(window.iClubExamPrepHostInternal=window.iClubExamPrepHostInternal||{});
const langs=["ru","uz","en"];
const copy={
 ru:{title:"Chemistry · AS Level",intro:"Теория по темам программы. Эти материалы не заменяют экзамен и не засчитывают результат.",section:"Раздел",back:"К списку тем",close:"Закрыть",loading:"Загружаем…",unavailable:"Материал пока недоступен.",retry:"Повторить",extra:"Дополнительный материал — не отдельный экзаменационный навык."},
 uz:{title:"Chemistry · AS Level",intro:"Dastur mavzulari bo‘yicha nazariya. Bu materiallar imtihon o‘rnini bosmaydi va natijani hisoblamaydi.",section:"Bo‘lim",back:"Mavzularga qaytish",close:"Yopish",loading:"Yuklanmoqda…",unavailable:"Material hozir mavjud emas.",retry:"Qayta urinish",extra:"Qo‘shimcha material — alohida imtihon ko‘nikmasi emas."},
 en:{title:"Chemistry · AS Level",intro:"Syllabus-linked theory. These lessons are not an examination and do not count towards a score or mastery.",section:"Section",back:"Back to topics",close:"Close",loading:"Loading…",unavailable:"This lesson is currently unavailable.",retry:"Try again",extra:"Additional reading — not a separate assessed syllabus outcome."}
};
let state=null,sequence=0;
const el=(tag,cls,text)=>{const n=document.createElement(tag);if(cls)n.className=cls;if(text!==undefined)n.textContent=String(text);return n;};
const validKey=s=>typeof s==="string"&&/^CHEM9701-[0-9]{2}-[0-9]{2}$/.test(s);
function validCatalog(c){
 if(c?.ok!==true||c?.scope!=="AS_theory_only"||c?.count!==91||
 c?.can_credit_mastery!==false||c?.ai_tutor_included!==false||
 !Array.isArray(c.items)||c.items.length!==91)return false;
 const unique=new Set(),tours=new Set();let enrich=0;
 for(const x of c.items){
  if(!validKey(x?.skill_key)||unique.has(x.skill_key)||typeof x.title!=="string"||
  x.title.trim().length<4||!Number.isInteger(x.tour_number)||x.tour_number<1||
  x.tour_number>5||typeof x.syllabus_point!=="string"||
  typeof x.is_syllabus_outcome!=="boolean")return false;
  unique.add(x.skill_key);tours.add(x.tour_number);
  if(!x.is_syllabus_outcome)enrich++;
 }
 return tours.size===5&&enrich===1;
}
function unmount(){sequence++;state=null;}
function btn(label,click,secondary){
 const b=el("button",secondary?"ep-host-btn ep-host-btn-secondary":"ep-host-btn ep-host-btn-primary",label);
 b.type="button";b.addEventListener("click",click);return b;
}
function panel(){
 const p=el("section","ep-host-shell ep-native-chemistry ep-chem-theory");
 p.setAttribute("aria-label",copy[state.language].title);return p;
}
function topics(){
 if(!state)return;
 const {root,catalog,language,onBack}=state,k=copy[language],panelNode=panel();
 panelNode.append(el("h2","ep-host-title",k.title),el("p","ep-host-note",k.intro));
 const stack=el("div","ep-chem-theory-sections");
 for(let n=1;n<=5;n++){
  const details=el("details","ep-chem-theory-section"),items=catalog.items.filter(x=>x.tour_number===n);
  details.open=n===1;
  details.append(el("summary","ep-chem-theory-summary",k.section+" "+n+" · "+items.length));
  const grid=el("div","ep-chem-theory-grid");
  for(const item of items){
   const b=el("button","ep-chem-theory-topic");b.type="button";
   b.append(el("span","ep-chem-theory-topic-label",item.title));
   if(!item.is_syllabus_outcome)b.append(el("span","ep-chem-theory-enrichment",k.extra));
   b.addEventListener("click",()=>lesson(item));grid.append(b);
  }
  details.append(grid);stack.append(details);
 }
 panelNode.append(stack,btn(k.close,onBack,true));root.replaceChildren(panelNode);
}
async function lesson(item){
 if(!state||!validKey(item.skill_key))return;
 const request=++sequence,ctx=state,k=copy[ctx.language],p=panel();
 p.append(btn(k.back,topics,true),el("p","ep-host-note",k.loading));ctx.root.replaceChildren(p);
 try{
  const response=await window.sb?.rpc?.("iclub_exam_chemistry_j24_theory_lesson_v1",{
   p_skill_key:item.skill_key,p_language:ctx.language
  });
  if(sequence!==request||state!==ctx)return;
  const r=response?.data;
  if(response?.error||r?.ok!==true||r.skill_key!==item.skill_key||
   r.locale!==ctx.language||r.can_credit_mastery!==false||
   r.ai_tutor_included!==false||r.paper3_lab_included!==false||
   r.paper5_lab_included!==false||typeof r.title!=="string"||
   typeof r.explanation!=="string"||r.explanation.trim().length<100||
   r.is_syllabus_outcome!==item.is_syllabus_outcome)throw Error("lesson_denied");
  p.replaceChildren(btn(k.back,topics,true),el("h2","ep-host-title",r.title));
  if(!r.is_syllabus_outcome)p.append(el("p","ep-chem-theory-enrichment",k.extra));
  p.append(el("div","ep-chem-theory-body",r.explanation));
 }catch(_){
  if(sequence!==request||state!==ctx)return;
  p.replaceChildren(btn(k.back,topics,true),el("p","ep-host-note",k.unavailable),
   btn(k.retry,()=>lesson(item)));
 }
}
function mount({root,catalog,language="ru",onBack}={}){
 if(!root||!langs.includes(language)||typeof onBack!=="function"||
  !validCatalog(catalog)||catalog.locale!==language)return false;
 unmount();state={root,catalog,language,onBack};topics();return true;
}
internal.chemistryTheoryNative=Object.freeze({mount,unmount,validCatalog});
})();