// iClub AI v2.1 — ONE contextual help entry in the existing app screens.
// QA-preview ONLY. Never imported by production, never uses learner records.
(() => {
  "use strict";
  if (window.__ICLUB_AI_QA_PREVIEW__?.noProductionWrites !== true) return;

  const screens = Object.freeze({
    "home":"view-home",
    "all-subjects":"courses-all-subjects",
    "subject-hub":"courses-subject-hub",
    "video":"courses-video",
    "practice-start":"courses-practice-start",
    "practice-result":"courses-practice-result",
    "practice-recs":"courses-practice-recs",
    "tours":"courses-tours",
    "tour-rules":"courses-tour-rules",
    "tour-result":"courses-tour-result",
    "tour-review":"courses-tour-review",
    "books":"courses-books",
    "my-recs":"courses-my-recs",
    "my-rec-detail":"courses-my-rec-detail",
    "ratings":"view-ratings",
    "profile":"view-profile",
    "notifications":"view-notifications",
    "community":"view-community",
    "certificates":"view-certificates",
    "archive":"view-archive",
    "support":"view-support",
    "support-topic":"view-support-topic",
    "about":"view-about"
  });
  const labels = Object.freeze({
    ru: {
      "home":"Что делать дальше?","all-subjects":"Помочь выбрать раздел",
      "subject-hub":"Как начать изучать предмет?","video":"Как открыть видеоуроки?",
      "practice-start":"Как работает Practice?","practice-result":"Что делать после Practice?",
      "practice-recs":"Как использовать рекомендации?","tours":"Как работают Tours?",
      "tour-rules":"Объяснить правила тура","tour-result":"Когда откроется разбор?",
      "tour-review":"Как пользоваться архивом?","books":"Как пользоваться книгами?",
      "my-recs":"Как устроены рекомендации?","my-rec-detail":"Как использовать рекомендацию?",
      "ratings":"Как работает рейтинг?","profile":"Что означают показатели?",
      "notifications":"Как устроены уведомления?","community":"Как пользоваться сообществом?",
      "certificates":"Как получить сертификат?","archive":"Когда доступен архив?",
      "support":"Как обратиться за помощью?","support-topic":"Как обратиться за помощью?",
      "about":"Что такое iClub?"
    },
    uz: {
      "home":"Keyingi qadam nima?","all-subjects":"Bo‘limni tanlashda yordam",
      "subject-hub":"Fanni qanday o‘rganaman?","video":"Video darslarni qanday ochaman?",
      "practice-start":"Practice qanday ishlaydi?","practice-result":"Practice'dan keyin nima qilaman?",
      "practice-recs":"Tavsiyalardan qanday foydalanaman?","tours":"Tours qanday ishlaydi?",
      "tour-rules":"Tur qoidalarini tushuntir","tour-result":"Tahlil qachon ochiladi?",
      "tour-review":"Arxivdan qanday foydalanaman?","books":"Kitoblardan qanday foydalanaman?",
      "my-recs":"Tavsiyalar qanday ishlaydi?","my-rec-detail":"Tavsiyadan qanday foydalanaman?",
      "ratings":"Reyting qanday ishlaydi?","profile":"Ko‘rsatkichlar nimani anglatadi?",
      "notifications":"Bildirishnomalar qanday ishlaydi?","community":"Hamjamiyatdan qanday foydalanaman?",
      "certificates":"Sertifikatni qanday olaman?","archive":"Arxiv qachon ochiladi?",
      "support":"Qanday yordam so‘rayman?","support-topic":"Qanday yordam so‘rayman?",
      "about":"iClub nima?"
    },
    en: {
      "home":"What should I do next?","all-subjects":"Help me choose a section",
      "subject-hub":"How do I study this subject?","video":"How do I open video lessons?",
      "practice-start":"How does Practice work?","practice-result":"What comes after Practice?",
      "practice-recs":"How do I use recommendations?","tours":"How do Tours work?",
      "tour-rules":"Explain Tour rules","tour-result":"When will review open?",
      "tour-review":"How do I use the archive?","books":"How do I use Books?",
      "my-recs":"How do recommendations work?","my-rec-detail":"How do I use a recommendation?",
      "ratings":"How do leaderboards work?","profile":"What do the indicators mean?",
      "notifications":"How do notifications work?","community":"How do I use Community?",
      "certificates":"How do I earn certificates?","archive":"When does the archive open?",
      "support":"How can I get support?","support-topic":"How can I get support?",
      "about":"What is iClub?"
    }
  });
  const locale=()=>{
    const raw=String(window.i18n?.getLang?.() || "ru").toLowerCase();
    return Object.hasOwn(labels,raw)?raw:"ru";
  };
  function activeScreen(){
    const view=document.querySelector(".view.is-active");
    if(!view)return "";
    if(view.id!=="view-courses")return String(view.dataset.view||"");
    const el=view.querySelector(".stack-screen.is-active");
    return String(el?.id||"").replace(/^courses-/,"");
  }
  function blocked(){
    if(["practice-quiz","tour-quiz"].includes(activeScreen()))return true;
    const exam=document.getElementById("exam-prep-host-root");
    if(exam && !exam.hidden && exam.getAttribute("aria-hidden")!=="true")return true;
    return document.getElementById("iclub-global-ai-mark")?.hidden!==false;
  }
  function createHelp(key,id){
    const target=document.getElementById(id);
    if(!target||target.querySelector(":scope > .iclub-qa-appwide-help"))return;
    const button=document.createElement("button");
    button.type="button";
    button.className="iclub-qa-appwide-help";
    button.setAttribute("data-qa-app-help",key);
    const img=document.createElement("img");
    img.src="iclub-ai-tutor-a.webp";img.alt="";
    img.setAttribute("aria-hidden","true");img.width=26;img.height=26;img.decoding="async";
    const label=document.createElement("span");
    label.className="iclub-qa-appwide-help-label";
    label.textContent=labels[locale()][key];
    const arrow=document.createElement("span");
    arrow.className="iclub-qa-appwide-help-arrow";
    arrow.textContent="›";arrow.setAttribute("aria-hidden","true");
    button.append(img,label,arrow);
    let pending=false;
    button.addEventListener("click",async()=>{
      if(pending||blocked()||activeScreen()!==key)return;
      const shell=window.iClubGlobalAiShell;
      if(typeof shell?.runQaContextHelp!=="function")return;
      pending=true;button.disabled=true;
      try { await shell.runQaContextHelp(key); }
      finally{pending=false;button.disabled=false;}
    });
    const top=target.firstElementChild;
    if(top?.classList.contains("section")||
       top?.classList.contains("subject-hub-head")||
       top?.classList.contains("lb-header")){
      top.insertAdjacentElement("afterend",button);
    }else{
      const content=target.querySelector(":scope > .content");
      if(content){
        const header=content.querySelector(":scope > .lb-header");
        if(header)header.insertAdjacentElement("afterend",button);
        else content.prepend(button);
      }else{
        target.prepend(button);
      }
    }
  }
  function update(){
    const lang=locale();
    for(const button of document.querySelectorAll(".iclub-qa-appwide-help")){
      const key=button.getAttribute("data-qa-app-help");
      if(!Object.hasOwn(screens,key))continue;
      const title=labels[lang][key];
      button.querySelector(".iclub-qa-appwide-help-label").textContent=title;
      button.setAttribute("aria-label","iClub AI · "+title);
      button.hidden=blocked() || activeScreen()!==key;
    }
  }
  let scheduled=false;
  function schedule(){
    if(scheduled)return;scheduled=true;
    setTimeout(()=>{scheduled=false;update();},55);
  }
  function attach(){
    for(const [key,id] of Object.entries(screens))createHelp(key,id);
    const root=document.querySelector("main");
    if(root)new MutationObserver(schedule).observe(root,{
      attributes:true,subtree:true,attributeFilter:["class","hidden","aria-hidden"]
    });
    document.addEventListener("click",schedule,true);
    document.addEventListener("iclub:language-change",schedule);
    update();
  }
  if(document.readyState==="loading")
    document.addEventListener("DOMContentLoaded",attach,{once:true});
  else attach();
  // Exposed for read-only synthetic QA diagnostics only.
  window.__ICLUB_AI_QA_APPWIDE__=Object.freeze({activeScreen});
})();
