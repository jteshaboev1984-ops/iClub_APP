// QA-only shell assistant metadata. No duplicate in-content AI buttons.
(() => {
  "use strict";
  if (window.__ICLUB_AI_QA_PREVIEW__?.noProductionWrites !== true) return;
  const labels=Object.freeze({
    ru:{
      home:"Главная", "all-subjects":"Обучение", "subject-hub":"Предмет",
      video:"Видеоуроки","practice-start":"Practice",
      "practice-result":"Результат Practice","practice-review":"Разбор ошибок",
      "practice-recs":"Рекомендации",tours:"Туры",
      "tour-rules":"Правила тура","tour-result":"Результат тура",
      "tour-review":"Архив тура",books:"Книги","my-recs":"Мои рекомендации",
      "my-rec-detail":"Рекомендация",ratings:"Рейтинг",profile:"Профиль",
      notifications:"Уведомления",community:"Сообщество",
      certificates:"Сертификаты",archive:"Архив",support:"Поддержка",
      "support-topic":"Поддержка",about:"О проекте"
    },
    uz:{
      home:"Bosh sahifa","all-subjects":"O‘qish","subject-hub":"Fan",
      video:"Video darslar","practice-start":"Practice",
      "practice-result":"Practice natijasi","practice-review":"Xatolar tahlili",
      "practice-recs":"Tavsiyalar",tours:"Turlar",
      "tour-rules":"Tur qoidalari","tour-result":"Tur natijasi",
      "tour-review":"Tur arxivi",books:"Kitoblar","my-recs":"Tavsiyalarim",
      "my-rec-detail":"Tavsiya",ratings:"Reyting",profile:"Profil",
      notifications:"Bildirishnomalar",community:"Hamjamiyat",
      certificates:"Sertifikatlar",archive:"Arxiv",support:"Yordam",
      "support-topic":"Yordam",about:"Loyiha haqida"
    },
    en:{
      home:"Home","all-subjects":"Study","subject-hub":"Subject",
      video:"Video lessons","practice-start":"Practice",
      "practice-result":"Practice result","practice-review":"Mistake review",
      "practice-recs":"Recommendations",tours:"Tours",
      "tour-rules":"Tour rules","tour-result":"Tour result",
      "tour-review":"Tour archive",books:"Books","my-recs":"My recommendations",
      "my-rec-detail":"Recommendation",ratings:"Leaderboard",profile:"Profile",
      notifications:"Notifications",community:"Community",
      certificates:"Certificates",archive:"Archive",support:"Support",
      "support-topic":"Support",about:"About"
    }
  });
  const locale=()=>{
    const lang=String(window.i18n?.getLang?.()||"ru").toLowerCase();
    return labels[lang]?lang:"ru";
  };
  function activeScreen(){
    const view=document.querySelector(".view.is-active");
    if(!view)return "";
    if(view.id!=="view-courses")return String(view.dataset.view||"");
    return String(view.querySelector(".stack-screen.is-active")?.id||"")
      .replace(/^courses-/,"");
  }
  function update(){
    const mark=document.getElementById("iclub-global-ai-mark");
    if(!mark)return;
    const lang=locale(),screen=activeScreen();
    const section=labels[lang][screen];
    const title=section?("iClub AI · "+section):"iClub AI";
    mark.setAttribute("aria-label",title);
    mark.title=title;
    // The mark is the sole screen-wide action. Study/review policy is
    // still enforced by the existing global AI shell.
  }
  let scheduled=false;
  function schedule(){
    if(scheduled)return;
    scheduled=true;
    setTimeout(()=>{scheduled=false;update();},60);
  }
  function attach(){
    const main=document.querySelector(".main");
    if(main)new MutationObserver(schedule).observe(main,{
      subtree:true,attributes:true,attributeFilter:["class","hidden","aria-hidden"]
    });
    document.addEventListener("click",schedule,true);
    document.addEventListener("iclub:language-change",schedule);
    window.addEventListener("focus",schedule);
    update();
    setTimeout(update,600);
  }
  window.__ICLUB_AI_QA_APPWIDE__=Object.freeze({activeScreen});
  if(document.readyState==="loading")
    document.addEventListener("DOMContentLoaded",attach,{once:true});
  else attach();
})();
