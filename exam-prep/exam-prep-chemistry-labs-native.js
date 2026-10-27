(() => {
  "use strict";
  // Independent Chemistry practical-skills learning cards. Server owns all access decisions.
  // A reading card is NOT a substitute for a supervised practical examination.
  const internal=window.iClubExamPrepHostInternal=window.iClubExamPrepHostInternal||{};
  const state={root:null,lang:"ru",paper:"P3",items:[],selected:null,onBack:null,seq:0};
  const labels={
    ru:{title:"Практические навыки",p3:"Paper 3 · AS Level",p5:"Paper 5 · A Level",
      note:"Учебные материалы помогают разбирать методы, но не заменяют лабораторную работу и практический экзамен.",
      back:"К входной проверке",list:"К списку материалов",learn:"Открыть материал",
      load:"Загрузка…",unavailable:"Материал недоступен. Проверьте доступ или соединение.",
      notMastery:"Чтение не подтверждает освоение навыка и не влияет на результат экзамена."},
    uz:{title:"Amaliy ko‘nikmalar",p3:"Paper 3 · AS Level",p5:"Paper 5 · A Level",
      note:"O‘quv materiallari usullarni tushunishga yordam beradi, ammo laboratoriya mashg‘uloti yoki amaliy imtihon o‘rnini bosmaydi.",
      back:"Kirish tekshiruviga",list:"Materiallar ro‘yxatiga",learn:"Materialni ochish",
      load:"Yuklanmoqda…",unavailable:"Material mavjud emas. Ruxsatni yoki internetni tekshiring.",
      notMastery:"O‘qish ko‘nikma o‘zlashtirilganini tasdiqlamaydi va imtihon natijasini o‘zgartirmaydi."},
    en:{title:"Practical skills",p3:"Paper 3 · AS Level",p5:"Paper 5 · A Level",
      note:"These study cards explain methods but do not replace laboratory work or the practical examination.",
      back:"Back to entry check",list:"Back to materials",learn:"Open material",
      load:"Loading…",unavailable:"This material is not available. Check access or your connection.",
      notMastery:"Reading does not verify practical competence or affect exam results."}
  };
  const t=()=>labels[state.lang]||labels.ru;
  const active=()=>state.root!==null;
  const node=(tag,text,cls)=>{
    const n=document.createElement(tag);if(text!=null)n.textContent=String(text);
    if(cls)n.className=cls;return n;
  };
  const button=(title,fn,secondary=true)=>{
    const b=node("button",title,"ep-host-btn "+(secondary?"ep-host-btn-secondary":"ep-host-btn-primary"));
    b.type="button";b.addEventListener("click",fn);return b;
  };
  async function api(name,args){
    try{
      if(typeof window.sb?.rpc!=="function")return {ok:false};
      const r=await window.sb.rpc(name,args);
      return r?.error?{ok:false}:r?.data||{ok:false};
    }catch(_){return {ok:false};}
  }
  function canvas(){
    if(!active())return null;
    const p=node("section",null,"ep-host-shell ep-native-chemistry ep-chem-labs");
    p.append(node("div","Cambridge · Chemistry 9701","ep-host-kicker"),
      node("h2",t().title,"ep-host-title"),
      node("p",state.paper==="P3"?t().p3:t().p5,"ep-host-subtitle"));
    state.root.replaceChildren(p);return p;
  }
  function foot(p,backLabel,backAction){
    const row=node("div",null,"ep-host-actions");
    row.append(button(backLabel,backAction));
    p.append(row);
  }
  function error(){
    const p=canvas();if(!p)return;
    const message=node("p",t().unavailable,"ep-host-note");
    message.setAttribute("role","alert");p.append(message);
    foot(p,t().back,()=>state.onBack?.());
  }
  function unmount(){
    state.seq++;state.root=null;state.onBack=null;state.items=[];state.selected=null;
  }
  async function catalog(){
    if(!active())return;
    state.selected=null;const token=++state.seq;
    const p=canvas();p.append(node("p",t().load,"ep-host-note"));
    const r=await api("iclub_exam_chemistry_lab_catalog_v1",{
      p_paper:state.paper,p_language:state.lang
    });
    if(!active()||token!==state.seq)return;
    const expectedLevel=state.paper==="P3"?"AS":"A";
    if(r?.ok!==true||r.paper_code!==state.paper||r.level_code!==expectedLevel||
       r.locale!==state.lang||r.can_credit_mastery!==false||
       r.count!==6||!Array.isArray(r.items)||r.items.length!==6||
       r.items.some(x=>x.paper_code!==state.paper||x.level_code!==expectedLevel||
        !/^CHEM9701-LAB-(0[1-9]|1[0-2])$/.test(x.skill_key))){
      error();return;
    }
    state.items=r.items;
    const view=canvas();
    view.append(node("p",t().note,"ep-host-note"));
    const list=node("div",null,"ep-chem-lab-list");
    r.items.forEach(x=>{
      const row=node("article",null,"ep-chem-lab-item");
      row.append(node("strong",x.title,"ep-chem-lab-title"),
        node("span",state.paper+" · "+x.skill_key.replace("CHEM9701-LAB-",""),"ep-chem-lab-meta"));
      row.append(button(t().learn,()=>lesson(x.skill_key)));
      list.append(row);
    });
    view.append(list);foot(view,t().back,()=>state.onBack?.());
  }
  async function lesson(skill){
    if(!active()||!state.items.some(x=>x.skill_key===skill))return;
    state.selected=skill;const token=++state.seq;
    canvas()?.append(node("p",t().load,"ep-host-note"));
    const r=await api("iclub_exam_chemistry_lab_lesson_v1",{
      p_paper:state.paper,p_skill_key:skill,p_language:state.lang
    });
    if(!active()||token!==state.seq)return;
    if(r?.ok!==true||r.skill_key!==skill||r.paper_code!==state.paper||
       r.level_code!==(state.paper==="P3"?"AS":"A")||r.locale!==state.lang||
       r.tutor_included!==false||r.can_credit_mastery!==false||
       r.practical_exam_replacement!==false||typeof r.explanation!=="string"||
       r.explanation.length<100){error();return;}
    const view=canvas();
    view.append(node("h3",r.title,"ep-native-section-title"),
      node("p",r.explanation,"ep-chem-entry-theory"),
      node("p",t().note,"ep-host-note"),node("p",t().notMastery,"ep-host-note"));
    foot(view,t().list,catalog);
  }
  function mount({root,language,paper,onBack}={}){
    unmount();
    if(!root||!["P3","P5"].includes(paper)||typeof onBack!=="function")return false;
    state.root=root;state.paper=paper;
    state.lang=["en","ru","uz"].includes(language)?language:"ru";state.onBack=onBack;
    catalog();return true;
  }
  function setLanguage(language){
    if(!active()||!["en","ru","uz"].includes(language)||language===state.lang)return;
    state.lang=language;
    const selected=state.selected;
    if(selected)lesson(selected);else catalog();
  }
  internal.chemistryLabsNative=Object.freeze({mount,unmount,setLanguage,getLanguage:()=>state.lang,isMounted:active});
})();
