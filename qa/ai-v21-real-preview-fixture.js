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
    const lang=["ru","uz","en"].includes(body?.locale)?body.locale:"ru";
    const key=String(body?.prompt_key||"");
    const subject=String(body?.subject_key||"general");
    const academic=subject!=="general";
    const copies={
      ru:{
        subject:"Я вижу раздел выбранного предмета. Здесь можно открыть доступные уроки, Practice и Tours. Объяснение конкретной темы появится после подтверждения учебного материала и языка. В этом Preview данные и результаты не сохраняются.",
        practice:"Practice предназначена для закрепления изученного материала. Во время выполнения заданий AI полностью скрывается. После завершённой проверки можно разобрать подтверждённые ошибки.",
        tours:"Tours — соревновательный формат iClub. Во время тура AI недоступен. Обсуждение заданий возможно только после официального открытия архива.",
        results:"Результаты находятся в соответствующих разделах Practice, Tours и профиле. В этом Preview нет настоящих оценок ученика.",
        default:"Я могу помочь с навигацией по iClub: найти предмет, открыть доступный урок, объяснить правила Practice и Tours. Подтверждённых учебных результатов в этом тестовом просмотре нет."
      },
      uz:{
        subject:"Men tanlangan fan bo‘limini ko‘ryapman. Bu yerdan mavjud darslar, Practice va Tours bo‘limlariga o‘tish mumkin. Muayyan mavzuni tushuntirish o‘quv manbasi va til tasdiqlangandan keyin mavjud bo‘ladi. Bu Preview natijalarni saqlamaydi.",
        practice:"Practice o‘rganilgan mavzularni mustahkamlash uchun. Savollarni yechish paytida AI butunlay yashiriladi. Mashg‘ulot tugagach, tasdiqlangan xatolarni tahlil qilish mumkin.",
        tours:"Tours — iClub musobaqalari. Tur davomida AI mavjud emas. Savollarni faqat arxiv rasmiy ochilgach muhokama qilish mumkin.",
        results:"Natijalar Practice, Tours va profil bo‘limlarida ko‘rsatiladi. Bu Previewda haqiqiy o‘quvchi baholari yo‘q.",
        default:"Men iClub bo‘limlari bo‘yicha yordam bera olaman: fan tanlash, darsga o‘tish, Practice va Tours qoidalarini tushuntirish. Bu sinovda tasdiqlangan shaxsiy natijalar yo‘q."
      },
      en:{
        subject:"I can see the selected subject area. You can explore available lessons, Practice and Tours. Explanation of a specific topic requires an approved source and language. This Preview never saves academic results.",
        practice:"Practice helps reinforce learning. AI is completely hidden while questions are active. Verified errors can be discussed after the full practice is finalized.",
        tours:"Tours are iClub competitions. AI is unavailable during a Tour. Questions may only be discussed after the archive is officially released.",
        results:"Results appear in the relevant Practice, Tours and profile sections. This Preview contains no genuine student scores.",
        default:"I can help you navigate iClub, find subjects, open lessons and understand Practice and Tours. No verified personal academic results exist in this test Preview."
      }
    };
    const c=copies[lang];
    const message=academic?c.subject:/practice/i.test(key)?c.practice:/tour/i.test(key)?c.tours:/result/i.test(key)?c.results:c.default;
    return {ok:true,message,academic_state_changed:false,usage_exhausted:false,mode:"qa_prepared"};
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