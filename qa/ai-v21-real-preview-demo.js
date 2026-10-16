// iClub AI — original, offline demonstration in the REAL Study / Practice review.
// QA output only. No student sessions, database writes, network or LMS grading.
(() => {
  "use strict";
  if (window.__ICLUB_AI_QA_PREVIEW__?.noProductionWrites !== true) return;
  const text = {
    ru: {
      entry:"Посмотреть пример разбора ошибки AI",
      label:"ДЕМО · iClub AI Tutor",
      title:"Разбор завершённой Practice",
      notice:"Учебный пример для проверки интерфейса. Это не результат ученика, не вопрос из действующей Practice и не опубликованный учебный источник.",
      subject:"Математика · производная",
      problem:"Найдите значение f′(3), если f(x) = x² + 2x.",
      yours:"Ответ в учебном примере",
      wrong:"6 · неверно",
      rightLabel:"Верное значение",
      right:"8",
      analyze:"Объяснить эту ошибку",
      back:"Вернуться в Study",
      footer:"Ответ подготовлен специально для демонстрации. Оценки и учебный прогресс не меняются."
    },
    uz: {
      entry:"AI xato tahlili namunasini ko‘rish",
      label:"NAMUNA · iClub AI Tutor",
      title:"Yakunlangan Practice tahlili",
      notice:"Interfeysni tekshirish uchun o‘quv namunasi. Bu haqiqiy o‘quvchi natijasi, amaldagi Practice savoli yoki tasdiqlangan manba emas.",
      subject:"Matematika · hosila",
      problem:"Agar f(x) = x² + 2x bo‘lsa, f′(3) ni toping.",
      yours:"Namuna javobi",
      wrong:"6 · noto‘g‘ri",
      rightLabel:"To‘g‘ri javob",
      right:"8",
      analyze:"Bu xatoni tushuntir",
      back:"Study bo‘limiga qaytish",
      footer:"Bu javob faqat namuna uchun yozilgan. Ballar va o‘quv jarayoni o‘zgarmaydi."
    },
    en: {
      entry:"See an AI mistake-review example",
      label:"DEMO · iClub AI Tutor",
      title:"Completed Practice review",
      notice:"An illustrative example for interface review. Not a student's result, an actual Practice question, or a published academic source.",
      subject:"Mathematics · differentiation",
      problem:"Find f′(3) if f(x) = x² + 2x.",
      yours:"Illustrative submitted answer",
      wrong:"6 · incorrect",
      rightLabel:"Correct value",
      right:"8",
      analyze:"Explain this mistake",
      back:"Back to Study",
      footer:"This answer was written for demonstration only. No grades or learning progress change."
    }
  };
  const explanation = Object.freeze({
    ru:"**Демонстрационный разбор — не реальный результат ученика.**\n\nУ функции f(x) = x² + 2x производная равна f′(x) = 2x + 2. Подставляем x = 3: f′(3) = 2·3 + 2 = **8**.\n\nВ учебном примере получен ответ 6 — так бывает, если найти производную x², но забыть слагаемое 2x. Его производная равна 2, а не 0.\n\n**Похожая проверка:** если g(x) = x² + 4x, чему равна g′(2)? Ответ: 8.\n\nЭто авторский пример для проверки интерфейса iClub AI. Настоящие данные Practice не используются.",
    uz:"**Namuna tahlili — haqiqiy o‘quvchi natijasi emas.**\n\nf(x) = x² + 2x funksiyaning hosilasi f′(x) = 2x + 2. x = 3 qo‘ysak: f′(3) = 2·3 + 2 = **8**.\n\nNamunadagi 6 javobi x² hosilasini topib, +2x ning hosilasini unutish natijasida kelib chiqadi. Uning hosilasi 2, 0 emas.\n\n**O‘xshash tekshiruv:** g(x) = x² + 4x bo‘lsa, g′(2) nechaga teng? Javob: 8.\n\nBu iClub AI interfeysini tekshirish uchun mualliflik namunasi. Haqiqiy Practice ma’lumotlari ishlatilmaydi.",
    en:"**Illustrative review — not a real learner result.**\n\nFor f(x) = x² + 2x, the derivative is f′(x) = 2x + 2. Substitute x = 3: f′(3) = 2·3 + 2 = **8**.\n\nThe illustrative answer 6 results from differentiating x² but forgetting the term +2x. Its derivative is 2, not 0.\n\n**Similar check:** If g(x) = x² + 4x, what is g′(2)? Answer: 8.\n\nThis is an original example solely for reviewing the iClub AI interface. No actual Practice records are used."
  });
  let active = false, selected = false;
  const locale=()=>{
    const lang=String(window.i18n?.getLang?.()||"ru").toLowerCase();
    return text[lang] ? lang : "ru";
  };
  const isReview=()=>document.getElementById("view-courses")?.classList.contains("is-active") &&
    document.getElementById("courses-practice-review")?.classList.contains("is-active");
  function clear() {
    active=false; selected=false;
    document.body.classList.remove("iclub-qa-demo-active");
    document.getElementById("iclub-qa-demo-review")?.remove();
    window.iClubGlobalAiShell?.close?.();
  }
  function toStudy() {
    clear();
    document.querySelector('#tabbar [data-tab="courses"]')?.click();
    document.querySelectorAll("#view-courses .stack-screen").forEach(el=>{
      el.classList.toggle("is-active",el.id==="courses-all-subjects");
    });
  }
  async function enter() {
    if (document.getElementById("courses-practice-quiz")?.classList.contains("is-active") ||
        document.getElementById("courses-tour-quiz")?.classList.contains("is-active")) return;
    clear();
    document.querySelector('#tabbar [data-tab="courses"]')?.click();
    const scope=document.getElementById("view-courses");
    // The real iClub tab transition is async; do not assume click is complete.
    for(let i=0;i<30&&!scope?.classList.contains("is-active");i++){
      await new Promise(resolve=>setTimeout(resolve,80));
    }
    if(!scope?.classList.contains("is-active"))return;
    active=true;
    document.querySelectorAll("#view-courses .stack-screen").forEach(el=>{
      el.classList.toggle("is-active",el.id==="courses-practice-review");
    });
    document.body.classList.add("iclub-qa-demo-active");
    renderReview();
  }
  function renderReview(){
    if(!active||!isReview())return;
    const wrap=document.getElementById("practice-review-list");
    if(!wrap)return;
    const existing=document.getElementById("iclub-qa-demo-review");
    if(existing)existing.remove();
    const c=text[locale()];
    const card=document.createElement("div");
    card.id="iclub-qa-demo-review";
    card.className="iclub-qa-demo-card";
    // Author-authored local-only content, never copied from a Cambridge assessment.
    const kicker=document.createElement("div");
    kicker.className="iclub-qa-demo-kicker"; kicker.textContent=c.label;
    const h=document.createElement("h3");h.textContent=c.title;
    const notice=document.createElement("p");notice.className="iclub-qa-demo-note";notice.textContent=c.notice;
    const topic=document.createElement("div");topic.className="iclub-qa-demo-subject";topic.textContent=c.subject;
    const question=document.createElement("p");question.className="iclub-qa-demo-question";question.textContent=c.problem;
    const answers=document.createElement("div");answers.className="iclub-qa-demo-answer-grid";
    for(const [label,value,type] of [
      [c.yours,c.wrong,"wrong"],[c.rightLabel,c.right,"correct"]
    ]){
      const div=document.createElement("div");div.className="iclub-qa-demo-answer "+type;
      const small=document.createElement("span");small.textContent=label;
      const bold=document.createElement("strong");bold.textContent=value;
      div.append(small,bold);answers.append(div);
    }
    const action=document.createElement("button");action.type="button";
    action.className="iclub-qa-demo-main-btn";action.textContent=c.analyze;
    action.addEventListener("click",()=>{
      if(!active||!isReview() ||
         document.getElementById("courses-practice-quiz")?.classList.contains("is-active") ||
         document.getElementById("courses-tour-quiz")?.classList.contains("is-active"))return;
      selected=true;
      // One click -> Tutor opens, types and sends through the shared AI
      // conversation. No second "Explain mistake" click is required.
      void window.iClubGlobalAiShell?.runQaPracticeDemo?.();
    });
    const footer=document.createElement("p");footer.className="iclub-qa-demo-footer";footer.textContent=c.footer;
    const exit=document.createElement("button");exit.type="button";exit.className="iclub-qa-demo-back";
    exit.textContent=c.back;exit.addEventListener("click",toStudy);
    card.append(kicker,h,notice,topic,question,answers,action,footer,exit);
    // The unchanged product review DOM is preserved; append the demo only.
    wrap.append(card);
    card.scrollIntoView?.({block:"nearest",behavior:"instant"});
  }
  function createEntry(container,id){
    if(!container || container.querySelector("#"+id))return;
    const btn=document.createElement("button");
    btn.id=id;btn.type="button";btn.className="iclub-qa-demo-entry";
    btn.textContent=text[locale()].entry;
    btn.addEventListener("click",enter);
    container.prepend(btn);
  }
  function attach(){
    createEntry(document.getElementById("view-home"),"iclub-qa-demo-home-entry");
    createEntry(document.getElementById("courses-practice-start"),"iclub-qa-demo-practice-entry");
    createEntry(document.getElementById("courses-subject-hub"),"iclub-qa-demo-subject-entry");
    // A synthetic question must never survive navigation to another screen.
    const observer=new MutationObserver(()=>{
      if(active&&!isReview())clear();
    });
    const el=document.getElementById("view-courses");
    if(el)observer.observe(el,{attributes:true,subtree:true,attributeFilter:["class"]});
    document.querySelectorAll(".view").forEach(v=>observer.observe(v,{attributes:true,attributeFilter:["class"]}));
  }
  window.__ICLUB_AI_QA_DEMO__=Object.freeze({
    ready:()=>active&&selected&&isReview()&&
      !document.getElementById("courses-practice-quiz")?.classList.contains("is-active") &&
      !document.getElementById("courses-tour-quiz")?.classList.contains("is-active"),
    // The existing chat renders plain text, not Markdown; remove typography
    // markers instead of showing literal ** characters to the reviewer.
    reply:(lang)=>explanation[lang]?.replace(/\*\*/g,"")||null,
    enter, exit:toStudy,
    get selected(){return selected;},
    get active(){return active;}
  });
  if(document.readyState==="loading")document.addEventListener("DOMContentLoaded",attach,{once:true});
  else attach();
})();
