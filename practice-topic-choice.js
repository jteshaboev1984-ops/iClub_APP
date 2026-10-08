/* iClub Practice — learner topic choice v1.
   Presentation + read-only catalog only; existing server-side drill remains authoritative.
   Never reads protected question text, answers, or local progress. */
(function () {
  "use strict";
  const COPY = {
    ru: { title:"Выберите тему", desc:"Тренируйте конкретную тему отдельно от практики тура.",
      open:"Выбрать тему", close:"Скрыть темы", search:"Поиск темы",
      searchPlaceholder:"Найти тему…", loading:"Загружаем доступные темы…",
      empty:"Сейчас нет доступных тематических тренировок.",
      filtered:"Темы не найдены", error:"Не удалось загрузить темы. Попробуйте ещё раз.",
      retry:"Повторить", items:"заданий", start:"Начать", note:"Засчитывается отдельно от результата практики тура.",
      more:"Показать ещё" },
    uz: { title:"Mavzuni tanlang", desc:"Tur amaliyotidan alohida bir mavzu bo‘yicha mashq qiling.",
      open:"Mavzuni tanlash", close:"Mavzularni yashirish", search:"Mavzuni qidirish",
      searchPlaceholder:"Mavzuni topish…", loading:"Mavzular yuklanmoqda…",
      empty:"Hozircha mavjud mavzuli mashqlar yo‘q.",
      filtered:"Mavzu topilmadi", error:"Mavzularni yuklab bo‘lmadi. Qayta urinib ko‘ring.",
      retry:"Qayta urinish", items:"savol", start:"Boshlash", note:"Natija tur amaliyotining natijasidan alohida saqlanadi.",
      more:"Yana ko‘rsatish" },
    en: { title:"Choose a topic", desc:"Practise a specific topic independently from your Tour practice.",
      open:"Choose topic", close:"Hide topics", search:"Search topics",
      searchPlaceholder:"Find a topic…", loading:"Loading available topics…",
      empty:"No topic practice is currently available.",
      filtered:"No matching topics", error:"Could not load topics. Please try again.",
      retry:"Try again", items:"questions", start:"Start", note:"Topic drills are separate from your Tour practice result.",
      more:"Show more" }
  };
  let mountSerial=0;

  function itemCountLabel(n,lang,c) {
    if(lang==="ru") {
      const last=n%10, hundred=n%100;
      const noun=last===1 && hundred!==11 ? "задание"
        : last>=2 && last<=4 && (hundred<12 || hundred>14) ? "задания"
        : "заданий";
      return n+" "+noun;
    }
    if(lang==="en") return n+" "+(n===1?"question":"questions");
    return n+" "+c.items;
  }

  function element(tag, cls, text) {
    const node=document.createElement(tag);
    if(cls) node.className=cls;
    if(text!==undefined) node.textContent=String(text);
    return node;
  }
  function mount({subjectKey,language,onStart}) {
    const host=document.getElementById("practice-topic-choice");
    if(!host || !subjectKey || typeof onStart!=="function") return;
    const ownSerial=++mountSerial;
    const lang=String(language||"ru").slice(0,2).toLowerCase();
    const c=COPY[lang]||COPY.ru;
    host.replaceChildren();
    const header=element("div","practice-topic-choice-head");
    const heading=element("div","practice-topic-choice-heading");
    heading.append(element("strong","",c.title),element("small","",c.desc));
    const toggle=element("button","practice-topic-choice-toggle",c.open);
    toggle.type="button";
    toggle.setAttribute("aria-expanded","false");
    const panel=element("div","practice-topic-choice-panel");
    panel.hidden=true;
    panel.id="practice-topic-choice-panel";
    toggle.setAttribute("aria-controls",panel.id);
    header.append(heading,toggle);
    const note=element("p","practice-topic-choice-note",c.note);
    host.append(header,panel,note);

    let topics=null;
    let loading=false;
    let limit=10;
    let busy=false;
    const status=element("p","practice-topic-choice-status","");
    const search=element("input","practice-topic-choice-search");
    search.type="search";
    search.setAttribute("aria-label",c.search);
    search.placeholder=c.searchPlaceholder;
    search.autocomplete="off";
    const list=element("div","practice-topic-choice-list");
    const more=element("button","practice-topic-choice-more",c.more);
    more.type="button";more.hidden=true;
    panel.append(status,search,list,more);

    function render() {
      if(!panel.isConnected || ownSerial!==mountSerial) return;
      list.replaceChildren();
      const term=search.value.trim().toLocaleLowerCase();
      const filtered=(topics||[]).filter(row=>row.topic.toLocaleLowerCase().includes(term));
      if(topics && !filtered.length) {
        status.textContent=term?c.filtered:c.empty;
      } else if(topics) {
        status.textContent="";
      }
      for(const row of filtered.slice(0,limit)) {
        const button=element("button","practice-topic-choice-item");
        button.type="button";
        button.disabled=busy;
        const info=element("span","practice-topic-choice-item-info");
        info.append(element("strong","",row.topic),
                    element("small","",itemCountLabel(row.question_count,lang,c)));
        const action=element("span","practice-topic-choice-item-action",c.start);
        button.append(info,action);
        button.addEventListener("click",async()=>{
          if(busy || ownSerial!==mountSerial) return;
          busy=true;
          panel.querySelectorAll("button,input").forEach(el=>{el.disabled=true;});
          try { await onStart(row.topic); }
          finally {
            busy=false;
            if(panel.isConnected && ownSerial===mountSerial)
              panel.querySelectorAll("button,input").forEach(el=>{el.disabled=false;});
          }
        });
        list.append(button);
      }
      more.hidden=filtered.length<=limit;
    }

    async function load() {
      if(loading || topics!==null) return;
      loading=true;
      status.textContent=c.loading;
      search.hidden=true;
      try {
        if(!window.sb || typeof window.sb.rpc!=="function") throw new Error("offline");
        const {data,error}=await window.sb.rpc("get_practice_available_topics_safe_v1",
                                                  {p_subject_key:String(subjectKey)});
        if(error || data?.ok!==true || !Array.isArray(data.topics)) throw new Error("catalog_unavailable");
        if(ownSerial!==mountSerial) return;
        topics=data.topics.filter(x=>
          x && typeof x.topic==="string" && x.topic.length>0 &&
          x.topic.length<=200 && Number.isInteger(Number(x.question_count)) &&
          Number(x.question_count)>0
        ).map(x=>({topic:x.topic,question_count:Number(x.question_count)}));
        search.hidden=topics.length===0;
        render();
      } catch {
        if(ownSerial!==mountSerial) return;
        status.textContent=c.error;
        const retry=element("button","practice-topic-choice-retry",c.retry);
        retry.type="button";
        retry.addEventListener("click",()=>{ retry.remove(); load(); });
        list.replaceChildren(retry);
      } finally { loading=false; }
    }
    search.addEventListener("input",()=>{limit=10;render();});
    more.addEventListener("click",()=>{limit+=10;render();});
    toggle.addEventListener("click",()=>{
      const next=panel.hidden;
      panel.hidden=!next;
      toggle.textContent=next?c.close:c.open;
      toggle.setAttribute("aria-expanded",String(next));
      if(next) load();
    });
  }
  window.iClubPracticeTopicChoice=Object.freeze({mount});
})();