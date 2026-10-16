// QA ONLY. Loaded before the unchanged production application scripts.
// This Preview has no live Supabase SDK, network capability or real auth.
(() => {
  "use strict";
  const QA_UID = "00000000-0000-4000-8000-000000000125";
  const QA_SUBJECTS = [
    {key:"mathematics",mode:"competitive",pinned:false},
    {key:"biology",mode:"study",pinned:true},
    {key:"chemistry",mode:"study",pinned:false},
    {key:"economics",mode:"study",pinned:false},
    {key:"informatics",mode:"study",pinned:false}
  ];
  const CATALOG = QA_SUBJECTS.map((s,i) => ({
    id:i+1, subject_key:s.key, is_active:true,
    key:s.key, name_en:s.key, title:s.key
  }));
  const profile = {
    id:QA_UID,full_name:"Демонстрационный профиль",
    first_name:"Демонстрационный",last_name:"профиль",
    language:"ru",uiLanguage:"ru",is_school_student:false,
    region:"Ташкент",district:"",subjects:QA_SUBJECTS,
    telegram:{id:null,username:null,first_name:"Демо",last_name:""}
  };
  // This origin is an isolated immutable Vercel Preview; no real credentials are read.
  for (const key of Object.keys(localStorage)) {
    if (/^sb-.*-auth-token$/.test(key)) localStorage.removeItem(key);
  }
  if (!localStorage.getItem("iclub_profile_v1")) {
    localStorage.setItem("iclub_profile_v1", JSON.stringify(profile));
  }
  window.__ICLUB_AI_QA_PREVIEW__ = Object.freeze({
    offline:true,noProductionWrites:true,syntheticIdentity:QA_UID
  });
  const user = {id:QA_UID,role:"authenticated",app_metadata:{provider:"qa-fixture"},user_metadata:{}};
  const session = {user,access_token:"QA_ONLY_NOT_A_JWT",expires_at:4102444800};
  const plain = (data=null,error=null) => ({data,error});
  const blocked = () => plain(null,{message:"qa_preview_read_only"});
  const rowsFor = (table,filters) => {
    if (table==="users") return [{id:QA_UID,first_name:"Демо",last_name:"профиль",is_school_student:false,language_code:"ru",region:"Ташкент"}];
    if (table==="subjects") return CATALOG.slice();
    if (table==="user_subjects") return QA_SUBJECTS.map((s,i)=>({
      user_id:QA_UID,subject_id:i+1,mode:s.mode,is_pinned:s.pinned,
      subjects:{subject_key:s.key,is_active:true}
    }));
    return [];
  };
  function query(table) {
    const filters=[];
    const q={
      select:()=>q,
      eq:(k,v)=>{filters.push([k,v]);return q;},
      neq:()=>q,in:()=>q,not:()=>q,is:()=>q,
      gte:()=>q,lte:()=>q,gt:()=>q,lt:()=>q,
      order:()=>q,limit:()=>q,range:()=>q,or:()=>q,
      maybeSingle:async()=>plain(getRows()[0]||null),
      single:async()=>plain(getRows()[0]||null),
      insert:async()=>blocked(),update:()=>writeChain(),upsert:async()=>blocked(),
      delete:()=>writeChain(),
      then:(ok,fail)=>Promise.resolve(plain(getRows())).then(ok,fail)
    };
    const writeChain=()=>({
      eq:()=>writeChain(),select:()=>writeChain(),
      single:async()=>blocked(),maybeSingle:async()=>blocked(),
      then:(ok,fail)=>Promise.resolve(blocked()).then(ok,fail)
    });
    const getRows=()=>rowsFor(table,filters).filter(row=>filters.every(([k,v])=>
      String(row?.[k]??"")===String(v)));
    return q;
  }
  function answer(body) {
    const lang = ["ru","uz","en"].includes(body?.locale) ? body.locale : "ru";
    const screen = String(body?.screen_code||"");
    const key = String(body?.prompt_key||"").toLowerCase();
    const typed = String(body?.user_text||"").trim();
    const subject = String(body?.subject_key||"general");
    const copy = {
      ru: {
        rules:"Practice помогает закреплять материал. Перед началом выберите доступную практику. Во время решения вопросов AI будет полностью скрыт, чтобы не подсказывать ответы.",
        after:"Разбор ошибок возможен только после завершения всей практики и подтверждения результата сервером. Во время ответов AI не помогает.",
        result:"В этом тестовом Preview нет подтверждённого результата завершённой Practice. Я не могу назвать ваш балл, ошибки или причины. Для настоящего разбора потребуется проверенная завершённая сессия.",
        error:"В этом Preview нет подтверждённого завершённого вопроса Practice. Чтобы объяснить конкретную ошибку, нужен проверенный идентификатор вопроса, ответ ученика и итог завершённой сессии.",
        next:"После реальной Practice откройте результат, затем разбор ошибок и повторите сложную тему. Здесь это только демонстрация интерфейса: личный следующий шаг недоступен.",
        tours:"Во время активного тура AI недоступен. Он может объяснить правила, но разбор заданий разрешён лишь после официального открытия архива.",
        archive:"В Preview нет подтверждения открытия архива конкретного тура. AI не раскрывает вопросы или правильные ответы до разрешённой даты.",
        subject:"В выбранном предмете доступны разделы обучения, Practice и Tours в зависимости от доступа. Этот тестовый AI не подтверждает освоение темы и не меняет ваш прогресс.",
        catalog:"Откройте Study, выберите доступный предмет и зайдите в его уроки или Practice. Это тестовый профиль без реальных учебных результатов.",
        study:"Откройте доступный урок, изучите объяснение, затем закрепите знания в Practice. AI сможет разбирать конкретную тему только с подтверждённым учебным источником.",
        home:"Я не вижу подтверждённый прогресс настоящего ученика в этом Preview, поэтому не буду выдумывать персональную рекомендацию. Для знакомства с приложением откройте Study и выберите предмет.",
        profile:"В этом Preview показатели учебного прогресса не подтверждены сервером. Я могу объяснить назначение раздела, но не могу оценить вашу готовность или изменить результат.",
        topic:"В Preview у AI нет проверенного материала текущего урока. Откройте сам урок; объяснение точной темы станет доступно после подключения утверждённого источника.",
        general:"Это безопасный Preview интерфейса iClub AI. Я могу объяснять навигацию, правила Practice и Tours, но здесь нет генерации по учебным материалам и доступа к реальным оценкам.",
        custom:"Это тестовый AI с ограниченными готовыми ответами, а не полноценный Tutor. На произвольный учебный вопрос я не буду выдумывать объяснение без подтверждённой темы и источника."
      },
      uz: {
        rules:"Practice mavzularni mustahkamlashga yordam beradi. Savollarni yechish paytida AI butunlay yashiriladi va javobga yordam bermaydi.",
        after:"Xatolarni faqat Practice to‘liq yakunlanib, natija serverda tasdiqlangandan keyin ko‘rib chiqish mumkin.",
        result:"Bu sinov Previewda Practice bo‘yicha tasdiqlangan yakuniy natija yo‘q. Men baho yoki xatolarni to‘qib chiqarmayman.",
        error:"Bu Previewda tasdiqlangan yakuniy savol va javob yo‘q. Aniq xatoni tushuntirish uchun tekshirilgan savol va yakunlangan natija kerak.",
        next:"Haqiqiy Practice'dan keyin natija va xatolar tahlilini oching. Bu Preview shaxsiy o‘quv tavsiyasini bermaydi.",
        tours:"Tur davomida AI mavjud emas. Savollar faqat arxiv rasmiy ochilgandan keyin tahlil qilinadi.",
        archive:"Bu Previewda aniq tur arxivi ochilgani tasdiqlanmagan. AI yopiq savollarni ko‘rsatmaydi.",
        subject:"Tanlangan fan ichida darslar, Practice va Tours mavjud bo‘lishi mumkin. Bu test AI o‘zlashtirish darajasini o‘zgartirmaydi.",
        catalog:"Study bo‘limini oching, mavjud fanni tanlang va darslarga o‘ting. Bu test profilda haqiqiy natijalar yo‘q.",
        study:"Mavjud darsni o‘rganing, keyin Practice bilan mustahkamlang. AI aniq mavzuni faqat tasdiqlangan manbadan tushuntiradi.",
        home:"Bu Previewda haqiqiy o‘quvchi natijalari tasdiqlanmagan. Shaxsiy tavsiya to‘qib chiqarmayman. Study bo‘limini ochishingiz mumkin.",
        profile:"Bu Previewda shaxsiy natijalar server tomonidan tasdiqlanmagan. Ularni baholay olmayman va o‘zgartirmayman.",
        topic:"Bu Previewda joriy dars uchun tasdiqlangan manba yo‘q. Aniq tushuntirish keyinroq mavjud bo‘ladi.",
        general:"Bu iClub AI interfeysining xavfsiz sinov Previewidir. Men navigatsiya va qoidalarni tushuntiraman, haqiqiy natijalarni o‘qimayman.",
        custom:"Bu cheklangan tayyor javobli sinov AI. Tasdiqlangan manbasiz o‘quv savoliga javob to‘qib chiqarmayman."
      },
      en: {
        rules:"Practice reinforces learning. While questions are active, AI is fully hidden and cannot supply answers.",
        after:"Mistakes can be discussed only after the full Practice is finished and the result is confirmed by the server.",
        result:"This Preview has no server-confirmed completed Practice result. I cannot claim a score, mistake or reason without proof.",
        error:"This Preview has no confirmed completed Practice question and answer. Explaining a specific mistake requires verified question and finalized attempt identifiers.",
        next:"After actual Practice, open the result, review verified mistakes and revisit the relevant lesson. This Preview cannot choose a personal next step.",
        tours:"AI is unavailable during an active Tour. Question reviews are allowed only after the archive is officially opened.",
        archive:"This Preview cannot verify that a specific Tour archive is open, so it cannot disclose questions or answer keys.",
        subject:"The selected subject offers Lessons, Practice and Tours where permitted. This preview AI does not change mastery or progress.",
        catalog:"Open Study, select an available subject and navigate to lessons or Practice. This synthetic profile contains no genuine academic results.",
        study:"Study an available lesson and then reinforce it in Practice. A specific-topic explanation requires an approved source.",
        home:"I have no verified learner progress in this Preview, so I cannot invent a personal recommendation. Explore a subject under Study.",
        profile:"No personal progress indicators in this Preview are verified by the server. I cannot assess readiness or modify results.",
        topic:"There is no verified source for the current lesson in this Preview. Topic-specific explanations require approved material.",
        general:"This is a safe iClub AI interface Preview. I can describe navigation and rules, but not generate real academic explanations or access scores.",
        custom:"This test AI has a small set of prepared replies, not a full Tutor. I will not invent answers to arbitrary academic questions."
      }
    }[lang];
    if (["practice-quiz","tour-quiz"].includes(screen)) return {
      ok:false, reason:"active_assessment",academic_state_changed:false
    };
    const response=(message,ok=true,reason="")=>({
      ok,reason,message,academic_state_changed:false,
      usage_exhausted:false,mode:"qa_prepared"
    });
    if (key==="practice_rules" || key==="app_help_practice") return response(copy.rules);
    if (key==="practice_after") return response(copy.after);
    if (key==="practice_result") return response(copy.result,false,"qa_no_verified_result");
    // A distinct original QA example is allowed ONLY inside the actual review
    // screen after the reviewer selects it; never reuses real Practice evidence.
    if (key==="practice_error" && screen==="practice-review" &&
        window.__ICLUB_AI_QA_DEMO__?.ready?.()===true) {
      const prepared=window.__ICLUB_AI_QA_DEMO__.reply(lang);
      if(typeof prepared==="string"&&prepared.length>30)
        return response(prepared,true,"");
    }
    if (key==="practice_error") return response(copy.error,false,"qa_no_verified_question");
    if (key==="practice_next") return response(copy.next);
    if (key==="tour_rules" || key==="app_help_tours") return response(copy.tours);
    if (key==="tour_archive") return response(copy.archive);
    if (key==="subject_study") return response(copy.subject);
    if (key==="catalog_help") return response(copy.catalog);
    if (key==="topic_study" || key.startsWith("topic_")) return response(copy.topic,false,"qa_no_approved_topic");
    if (key==="home_next") return response(copy.home);
    if (key==="profile_meaning") return response(copy.profile);
    if (key==="app_help_results") return response(copy.profile);
    if (typed) return response(copy.custom);
    if (["practice-result","practice-review"].includes(screen))
      return response(screen==="practice-result"?copy.result:copy.error,false,"qa_no_verified_evidence");
    if (["practice-start","practice-recs"].includes(screen)) return response(copy.rules);
    if (["tours","tour-rules","tour-result","tour-review"].includes(screen)) return response(copy.tours);
    if (["lessons","video"].includes(screen)) return response(copy.topic,false,"qa_no_approved_topic");
    if (screen==="subject-hub") return response(copy.subject);
    if (screen==="home") return response(copy.home);
    if (screen==="profile") return response(copy.profile);
    if (screen==="all-subjects") return response(copy.catalog);
    return response(subject==="general"?copy.general:copy.subject);
  }
  const client={
    auth:{
      getUser:async()=>({data:{user},error:null}),
      getSession:async()=>({data:{session},error:null}),
      onAuthStateChange:(cb)=>{
        queueMicrotask(()=>cb("INITIAL_SESSION",session));
        return {data:{subscription:{unsubscribe(){}}},error:null};
      },
      signInAnonymously:async()=>blocked(),signOut:async()=>blocked(),
      refreshSession:async()=>({data:{session},error:null})
    },
    from:table=>query(table),
    rpc:async(name)=>{
      if(name==="get_iclub_ai_ui_bootstrap_v1")
        return plain({visible:true,assessment_blocked:false,usage_exhausted:false,locale:"ru"});
      return plain(null,{message:"qa_rpc_not_available"});
    },
    functions:{
      invoke:async(name,{body}={})=>
        name==="global-ai"?plain(answer(body||{})):blocked()
    },
    storage:{from:()=>({upload:blocked,download:blocked,getPublicUrl:()=>({data:{publicUrl:""}})})},
    channel:()=>({on(){return this;},subscribe(){return this;}}),
    removeChannel:async()=>true
  };
  Object.defineProperty(window,"supabase",{
    value:Object.freeze({createClient:()=>client}),
    configurable:false,writable:false
  });
  // A permanent visible QA label prevents any suggestion that these are live student results.
  const label=document.createElement("div");
  label.id="iclub-ai-qa-notice";
  label.textContent="iClub AI · защищённый тестовый Preview · данные не сохраняются";
  label.setAttribute("role","note");
  label.style.cssText="position:fixed;z-index:1000;left:12px;top:env(safe-area-inset-top,0px);max-width:calc(100% - 24px);padding:5px 10px;border-radius:0 0 12px 12px;background:#153b70;color:#fff;font:600 11px/1.4 system-ui,sans-serif;pointer-events:none;box-shadow:0 2px 8px #13284833";
  const put=()=>document.body?.appendChild(label);
  if(document.body)put();else document.addEventListener("DOMContentLoaded",put,{once:true});
})();