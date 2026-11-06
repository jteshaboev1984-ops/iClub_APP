/* Mathematics P1/P5 — optional original Extra Hard; no grade or mastery.
 * Private server authorizes list/start/submission; answers unlock after commit.
 * Never stores a student solution in localStorage or invents a scored result.
 */
(() => {
  "use strict";
  const internal = window.iClubExamPrepHostInternal;
  if (!internal) return;
  const copy = {
    en: {
      title:"Extra Hard",back:"Back to my learning",loading:"Opening extra challenges…",
      preparing:"These challenges are being prepared. You can continue your regular learning.",
      intro:"Optional challenge. Your method is not graded, and no exam or mastery marks are awarded.",
      start:"Try challenge",your:"Your written solution",submit:"Submit and compare",
      textRequired:"Write your solution before submitting.",
      saved:"Your solution was saved. Compare it with the worked example. It is not a grade.",
      model:"Worked example",review:"My saved solution",returnList:"Other challenges",
      error:"The request was not confirmed. Your text is still on this screen; please retry.",
      noScore:"Written correctness has not been independently verified."
    },
    ru: {
      title:"Задачи повышенной сложности",back:"К моему обучению",loading:"Открываем задания…",
      preparing:"Задания ещё готовятся. Основное обучение доступно без ограничений.",
      intro:"Необязательное задание. Метод решения не оценивается, баллы экзамена и мастерства не начисляются.",
      start:"Попробовать",your:"Ваше письменное решение",submit:"Сохранить и сверить",
      textRequired:"Сначала запишите решение.",
      saved:"Решение сохранено. Сверьтесь с примером — это не оценка.",
      model:"Пример решения",review:"Ваше сохранённое решение",returnList:"Другие задания",
      error:"Сервер не подтвердил действие. Ваш текст остался на экране. Повторите отправку.",
      noScore:"Правильность письменного решения независимо не проверялась."
    },
    uz: {
      title:"Qo‘shimcha murakkab masalalar",back:"O‘qishga qaytish",loading:"Masalalar ochilmoqda…",
      preparing:"Masalalar tayyorlanmoqda. Asosiy o‘qishni odatdagidek davom ettirishingiz mumkin.",
      intro:"Ixtiyoriy masala. Yozma yechim baholanmaydi, imtihon yoki o‘zlashtirish bali berilmaydi.",
      start:"Masalani yechish",your:"Yozma yechimingiz",submit:"Saqlash va solishtirish",
      textRequired:"Avval yechimingizni yozing.",
      saved:"Yechim saqlandi. Uni namuna bilan solishtiring. Bu baho emas.",
      model:"Yechim namunasi",review:"Saqlangan yechimingiz",returnList:"Boshqa masalalar",
      error:"Server tasdiqlamadi. Matningiz shu ekranda saqlandi; qayta yuboring.",
      noScore:"Yozma yechimning to‘g‘riligi mustaqil tekshirilmagan."
    }
  };
  const esc = value => String(value ?? "").replace(/[&<>"']/g, c => ({
    "&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;","'":"&#39;"
  }[c]));
  const topics = Object.freeze({
    "1.1":{en:"Quadratics",ru:"Квадратные выражения",uz:"Kvadrat ifodalar"},
    "1.2":{en:"Functions",ru:"Функции",uz:"Funksiyalar"},
    "1.3":{en:"Coordinate geometry",ru:"Координатная геометрия",uz:"Koordinata geometriyasi"},
    "1.4":{en:"Circular measure",ru:"Радианная мера",uz:"Radian o‘lchov"},
    "1.5":{en:"Trigonometry",ru:"Тригонометрия",uz:"Trigonometriya"},
    "1.6":{en:"Series",ru:"Последовательности и ряды",uz:"Ketma-ketlik va qatorlar"},
    "1.7":{en:"Differentiation",ru:"Дифференцирование",uz:"Differensiallash"},
    "1.8":{en:"Integration",ru:"Интегрирование",uz:"Integrallash"},
    "5.1":{en:"Data representation",ru:"Данные и статистика",uz:"Ma’lumotlar va statistika"},
    "5.2":{en:"Permutations and combinations",ru:"Перестановки и сочетания",uz:"O‘rin almashtirish va kombinatsiyalar"},
    "5.3":{en:"Probability",ru:"Вероятность",uz:"Ehtimollik"},
    "5.4":{en:"Discrete distributions",ru:"Дискретные распределения",uz:"Diskret taqsimotlar"},
    "5.5":{en:"Normal distribution",ru:"Нормальное распределение",uz:"Normal taqsimot"}
  });
  const progressText=Object.freeze({
    en:{done:"Submitted",submitted:"Submitted",started:"In progress",not_started:"New",other:"Other topics"},
    ru:{done:"Отправлено",submitted:"Отправлено",started:"Начато",not_started:"Новое",other:"Другие темы"},
    uz:{done:"Yuborilgan",submitted:"Yuborilgan",started:"Boshlangan",not_started:"Yangi",other:"Boshqa mavzular"}
  });
  function catalogMarkup(items,language){
    const g=new Map(),t=progressText[language];
    for(const item of items){
      const k=String(item.official_section||"").match(/^([15]\.\d)\b/)?.[1]||"other";
      if(!g.has(k))g.set(k,[]);
      g.get(k).push(item);
    }
    const keys=[...g.keys()].sort((a,b)=>a.localeCompare(b,"en",{numeric:true}));
    const first=keys.find(k=>g.get(k).some(x=>x.attempt_status!=="submitted"))||keys[0];
    const done=items.filter(x=>x.attempt_status==="submitted").length;
    const groups=keys.map(k=>{
      const itemsInTopic=g.get(k);
      const groupDone=itemsInTopic.filter(x=>x.attempt_status==="submitted").length;
      const name=topics[k]?.[language]||t.other;
      const rows=itemsInTopic.map(item=>{
        const status=["submitted","started"].includes(item.attempt_status)?item.attempt_status:"not_started";
        return '<button class="ep-component-link ep-extra-task" type="button" data-ep-extra-hard-task="'
          +esc(item.task_key)+'"><span><strong>'+esc(item.title)+'</strong><small>'
          +esc(t[status])+'</small></span><span aria-hidden="true">›</span></button>';
      }).join("");
      return '<details class="ep-extra-topic" '+(k===first?"open":"")
        +'><summary><span>'+esc(k==="other"?"":k+" · ")+esc(name)
        +'</span><span class="ep-extra-topic-count">'+groupDone+' / '+itemsInTopic.length+'</span></summary>'
        +'<div class="ep-component-links ep-extra-topic-list">'+rows+'</div></details>';
    }).join("");
    return '<div class="ep-extra-catalog" data-ep-extra-hard-list>'
      +'<p class="ep-extra-progress" role="status">'+esc(t.done)+": "+done+" / "+items.length+"</p>"+groups+'</div>';
  }

  const pickLanguage = language => ["uz","en","ru"].includes(String(language).toLowerCase())
    ? String(language).toLowerCase() : "en";
  let context = null;
  const root = () => document.getElementById("exam-prep-host-root");
  function frame(inner) {
    const el = root();
    if (!el || !context) return null;
    const c = copy[context.language];
    el.innerHTML = '<section class="ep-live-card" data-ep-extra-hard-root>'
      +'<div class="ep-live-head"><strong>'+esc(c.title)+'</strong></div>'
      +'<div class="ep-live-meta">'+esc(c.intro)+'</div>'
      +inner
      +'<div class="ep-live-actions"><button class="ep-live-btn secondary" type="button" data-ep-extra-hard-back>'+esc(c.back)+'</button></div>'
      +'</section>';
    el.querySelector('[data-ep-extra-hard-back]')?.addEventListener("click", () => {
      const back=context?.onBack;
      if(typeof back==="function") back();
    });
    return el;
  }
  function waiting() {
    if(!context) return;
    frame('<div class="ep-live-notice" role="status" aria-live="polite">'+esc(copy[context.language].loading)+'</div>');
  }
  function error() {
    if(!context) return;
    frame('<div class="ep-live-notice" role="alert">'+esc(copy[context.language].error)+'</div>'
      +'<div class="ep-live-actions"><button class="ep-live-btn" type="button" data-ep-extra-hard-retry>↻</button></div>');
    root()?.querySelector('[data-ep-extra-hard-retry]')?.addEventListener("click", loadCatalog);
  }
  async function loadCatalog() {
    if(!context || context.busy) return;
    context.busy=true;waiting();
    const seq=context.sequence;
    try {
      const r=await internal.api.extraHardCatalog(context.component,context.language);
      if(!context || context.sequence!==seq) return;
      if(!r?.ok || r.data?.component_code!==context.component) {context.busy=false;error();return;}
      context.items=Array.isArray(r.data?.items) ? r.data.items : [];
      context.busy=false;
      const c=copy[context.language];
      if(r.data?.available!==true || !context.items.length){
        frame('<div class="ep-live-notice" role="status">'+esc(c.preparing)+'</div>');
        return;
      }
      frame(catalogMarkup(context.items,context.language));
      root()?.querySelectorAll('[data-ep-extra-hard-task]').forEach(btn=>
        btn.addEventListener("click",()=>openTask(btn.dataset.epExtraHardTask)));
    } catch (_) {
      if(context?.sequence===seq){context.busy=false;error();}
    }
  }
  async function openTask(taskKey) {
    if(!context || context.busy || !context.items.some(x=>x.task_key===taskKey)) return;
    context.busy=true;waiting();
    const seq=context.sequence;
    try {
      const r=await internal.api.extraHardStart(taskKey,context.language);
      if(!context || context.sequence!==seq) return;
      context.busy=false;
      if(!r?.ok || !r.data?.attempt_id || r.data.component_code!==context.component
         || r.data.noncredit!==true) {error();return;}
      context.attempt=r.data;
      renderTask();
    }catch(_){if(context?.sequence===seq){context.busy=false;error();}}
  }
  function renderTask() {
    if(!context?.attempt) return;
    const a=context.attempt,c=copy[context.language];
    if(a.status==="submitted"){
      const submitted='<div class="ep-live-notice" role="status">'+esc(c.saved)+'</div>'
       +'<div class="ep-live-meta">'+esc(c.review)+'</div><div class="ep-live-answer">'+esc(a.response_text)+'</div>'
       +'<div class="ep-live-meta">'+esc(c.model)+'</div><div class="ep-live-answer">'+esc(a.solution || "")+'</div>'
       +'<div class="ep-live-notice">'+esc(c.noScore)+'</div>'
       +'<div class="ep-live-actions"><button class="ep-live-btn" type="button" data-ep-extra-hard-other>'+esc(c.returnList)+'</button></div>';
      frame('<div class="ep-live-qtext">'+esc(a.prompt)+'</div>'+submitted);
      root()?.querySelector('[data-ep-extra-hard-other]')?.addEventListener("click",loadCatalog);
      return;
    }
    frame('<div class="ep-live-qtext">'+esc(a.prompt)+'</div>'
      +'<label class="ep-live-field"><span>'+esc(c.your)+'</span>'
      +'<textarea name="ep_extra_hard_answer" rows="7" maxlength="10000" placeholder="'+esc(c.your)+'"></textarea></label>'
      +'<div class="ep-live-notice">'+esc(c.noScore)+'</div>'
      +'<div class="ep-live-notice" role="status" data-ep-extra-hard-message hidden></div>'
      +'<div class="ep-live-actions"><button class="ep-live-btn" type="button" data-ep-extra-hard-submit>'+esc(c.submit)+'</button></div>');
    root()?.querySelector('[data-ep-extra-hard-submit]')?.addEventListener("click",submit);
  }
  async function submit() {
    if(!context?.attempt || context.busy || context.attempt.status==="submitted")return;
    const el=root();
    const input=el?.querySelector('[name="ep_extra_hard_answer"]');
    const message=el?.querySelector('[data-ep-extra-hard-message]');
    const button=el?.querySelector('[data-ep-extra-hard-submit]');
    const c=copy[context.language];
    const answer=String(input?.value||"").trim();
    if(!answer){if(message){message.hidden=false;message.textContent=c.textRequired;}return;}
    if(answer.length>10000){if(message){message.hidden=false;message.textContent=c.error;}return;}
    context.busy=true;
    if(button)button.disabled=true;
    const seq=context.sequence;
    const key="extra_hard_v1_"+context.attempt.attempt_id;
    try {
      const res=await internal.api.extraHardSubmit(context.attempt.attempt_id,answer,key,context.language);
      if(!context || context.sequence!==seq)return;
      context.busy=false;
      if(!res?.ok || res.data?.saved!==true || res.data?.noncredit!==true
         || !res.data?.solution){if(button)button.disabled=false;if(message){message.hidden=false;message.textContent=c.error;}return;}
      context.attempt={...context.attempt,...res.data,status:"submitted"};
      renderTask();
    }catch(_){
      if(context?.sequence!==seq)return;
      context.busy=false;
      if(button)button.disabled=false;
      if(message){message.hidden=false;message.textContent=c.error;}
    }
  }
  function open(component,language,onBack) {
    if(!["P1","P5"].includes(component) || typeof onBack!=="function"
       || typeof internal.api?.extraHardCatalog!=="function") return false;
    context={component,language:pickLanguage(language),onBack,items:[],attempt:null,busy:false,sequence:(context?.sequence||0)+1};
    loadCatalog();
    return true;
  }
  internal.extraHardView=Object.freeze({open});
})();
