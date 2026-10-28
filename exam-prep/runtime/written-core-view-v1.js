/* iClub Exam Prep — governed written practice, no automatic marks.
 * Reuses the existing Mathematics ep-live UI and approved Core v1.3 controller.
 * Mount only after server-approved written_available_v1 === true.
 */
(function(){
 "use strict";
 const copy={
   ru:{title:"Письменная практика",criteria:"Критерии оценивания",hideCriteria:"Скрыть критерии",next:"Далее",source:"Источник",data:"Таблица данных",
     back:"Назад",loading:"Загружаем задание…",offline:"Не удалось подтвердить действие. Повторите попытку.",
     complete:"Письменные задания по текущему плану пройдены.",
     instruction:"Выполните задание самостоятельно. Загрузка работы и самооценка не требуются.",
     criteriaTitle:"Критерии оценивания",marks:"баллов",ao12:"AO1 + AO2 · Знания и анализ",ao3:"AO3 · Оценка и аргументация",markContent:"Что оценивает экзаменатор",levelsTitle:"Уровни оценивания",levelLabel:"Уровень",levelHigh:"Развёрнутый и точный ответ",levelMiddle:"В целом верный, но неполный анализ",levelLow:"Ограниченный, преимущественно описательный ответ",levelsInfo:"Эссе оценивается по уровням качества анализа и аргументации. Перечисленные критерии не являются готовым ответом.",pointInfo:"Баллы выставляются за качество ответа в рамках указанных критериев, а не за количество перечисленных пунктов.",notOfficial:"Учебная схема iClub по принципам Cambridge 9708. Это не официальный mark scheme для данного задания.",openError:"Задание сейчас недоступно."},
   uz:{title:"Yozma mashqlar",criteria:"Baholash mezonlari",hideCriteria:"Mezonlarni yashirish",next:"Keyingi",source:"Manba",data:"Ma’lumotlar jadvali",
     back:"Orqaga",loading:"Topshiriq yuklanmoqda…",offline:"Amal tasdiqlanmadi. Qaytadan urinib ko‘ring.",
     complete:"Joriy rejadagi yozma topshiriqlar yakunlandi.",
     instruction:"Topshiriqni mustaqil bajaring. Ishni yuklash yoki o‘zingizga baho qo‘yish shart emas.",
     criteriaTitle:"Baholash mezonlari",marks:"ball",ao12:"AO1 + AO2 · Bilim va tahlil",ao3:"AO3 · Baholash va dalillar",markContent:"Imtihonchi nimani baholaydi",levelsTitle:"Baholash darajalari",levelLabel:"Daraja",levelHigh:"To‘liq va aniq izohlangan javob",levelMiddle:"Asosan to‘g‘ri, biroq tahlili to‘liq bo‘lmagan javob",levelLow:"Cheklangan, ko‘proq tasviriy javob",levelsInfo:"Esse tahlil va dalillarning sifati bo‘yicha darajalarda baholanadi. Mezonlarda tayyor javob berilmaydi.",pointInfo:"Ball mezonlar bo‘yicha javob sifati uchun beriladi, sanab o‘tilgan bandlar soni uchun emas.",notOfficial:"Cambridge 9708 tamoyillariga mos iClub o‘quv mezonlari. Bu savol uchun rasmiy Cambridge mark scheme emas.",openError:"Topshiriq hozir mavjud emas."},
   en:{title:"Written practice",criteria:"Assessment criteria",hideCriteria:"Hide criteria",next:"Next",source:"Source",data:"Data table",
     back:"Back",loading:"Loading task…",offline:"Action not confirmed. Please retry.",
     complete:"Written tasks in this study plan have been completed.",
     instruction:"Complete the task independently. No essay upload or self-grading is required.",
     criteriaTitle:"Assessment criteria",marks:"marks",ao12:"AO1 + AO2 · Knowledge and analysis",ao3:"AO3 · Evaluation and judgement",markContent:"What the examiner assesses",levelsTitle:"Marking levels",levelLabel:"Level",levelHigh:"Accurate, fully developed economic reasoning",levelMiddle:"Mostly accurate but partially developed analysis",levelLow:"Limited, mainly descriptive response",levelsInfo:"Essay marks reflect levels of analysis and reasoned evaluation. These criteria do not give away a model answer.",pointInfo:"Marks reflect the quality of the answer against these criteria, not the number of listed points.",notOfficial:"iClub practice marking guide aligned to Cambridge 9708 principles; not an official Cambridge mark scheme for this question.",openError:"Task is currently unavailable."}
 };
 const el=(tag,cls,str)=>{const x=document.createElement(tag);if(cls)x.className=cls;if(str!=null)x.textContent=String(str);return x;};
 function mount({root,planId,language="ru",onBack,api,createActionKey}={}){
   if(!root||!planId||!api||!window.iClubWrittenCoreControllerV1||
      !["available","next","open","criteria","advance","status"].every(k=>typeof api[k]==="function"))
      return null;
   const t=copy[language]||copy.ru;
   let closed=false,working=false,sequence=0,ctl=null;
   const actionKey=typeof createActionKey==="function"?createActionKey:
      ()=>window.crypto?.randomUUID?.()||"";
   function btn(label,handler,secondary=false){
      const x=el("button",secondary?"ep-live-btn secondary":"ep-live-btn",label);
      x.type="button";x.addEventListener("click",handler);return x;
   }
   function page(){
      const base=el("section","ep-host-shell ep-live");
      const top=el("div","ep-live-head ep-written-screen-head");
      const title=el("h2","ep-host-title ep-written-screen-title",t.title);
      const back=btn("‹",()=>{dispose();onBack?.();},true);
      back.className+=" ep-written-screen-back";
      back.setAttribute("aria-label",t.back);
      back.setAttribute("title",t.back);
      top.append(back,title);
      base.append(top);root.replaceChildren(base);return base;
   }
   function message(str){
      const body=page();body.append(el("p","ep-live-card",str));return body;
   }
   async function loadNext(){
      if(closed||working)return;
      working=true;const token=++sequence;
      message(t.loading);
      try{
         const result=await api.next({p_plan_id:planId});
         if(closed||token!==sequence)return;
         if(!result||result.ok===false)throw Error("written_not_available");
         if(result.status==="completed"){
            message(t.complete);return;
         }
         if(result.status!=="ready"||!result.plan_item_id)
            throw Error("written_item_not_ready");
         let openedTask=null;
         ctl=window.iClubWrittenCoreControllerV1.create({
            api:{
              open:async({plan_item_id})=>{
                openedTask=await api.open({p_item_id:plan_item_id,p_language:language});
                return openedTask;
              },
              criteria:({plan_item_id,task_key,task_version,task_token})=>
                api.criteria({p_item_id:plan_item_id,p_task_key:task_key,
                  p_task_version:task_version,p_task_token:task_token,p_language:language}),
              advance:({plan_item_id,task_key,task_version,task_token,idempotency_key})=>
                api.advance({p_item_id:plan_item_id,p_task_key:task_key,
                  p_task_version:task_version,p_task_token:task_token,p_idempotency_key:idempotency_key}),
              status:({plan_item_id,task_key,task_version,task_token})=>
                api.status({p_item_id:plan_item_id,p_task_key:task_key,
                  p_task_version:task_version,p_task_token:task_token})
            },createActionKey:actionKey
         });
         await ctl.open(result.plan_item_id);
         if(closed||token!==sequence)return;
         const answer=openedTask;
         if(closed||token!==sequence)return;
         // Task wording is returned by the approved, learner-owned Core service only.
         if(!answer||answer.task_kind!=="written_external"||typeof answer.question!=="string")
            throw Error("written_question_not_approved");
         renderTask(answer,token);
      }catch(_){
         if(!closed&&token===sequence){
            const box=message(t.openError);
            box.append(btn(t.next,()=>{working=false;loadNext();}));
         }
      }finally{if(token===sequence)working=false;}
   }
   // Sources are rendered ONLY from the guarded task-open server response.
   // A Section A question without its approved locale-matched source is not shown.
   function sourcePanel(item){
     if(item.program_key!=="economics_9708"||!["P2","P4"].includes(item.paper_code)||String(item.task_key||"").split(".")[1]!=="A")return null;
     const s=item.source;
     if(!s||s.language!==language||typeof s.title!=="string"||!s.title.trim()
       ||!Array.isArray(s.paragraphs)||!s.paragraphs.length
       ||s.paragraphs.some(p=>typeof p!=="string"||!p.trim()))
       throw Error("written_source_unavailable");
     const panel=el("section","ep-live-card ep-written-source");
     panel.setAttribute("aria-label",t.source);
     panel.append(el("div","ep-live-meta",t.source),
       el("h3","ep-written-source-title",s.title));
     for(const p of s.paragraphs)panel.append(el("p","ep-written-source-paragraph",p));
     if(s.table!==undefined&&s.table!==null){
       const x=s.table;
       if(!Array.isArray(x.columns)||x.columns.length<2
         ||!x.columns.every(h=>typeof h==="string"&&h.trim())
         ||!Array.isArray(x.rows)||!x.rows.length
         ||x.rows.some(row=>!Array.isArray(row)||row.length!==x.columns.length
           ||row.some(cell=>!["string","number"].includes(typeof cell))))
         throw Error("written_source_table_invalid");
       const scroll=el("div","ep-written-source-scroll");
       const table=el("table","ep-written-source-table");
       const caption=el("caption","",t.data+(typeof x.unit==="string"&&x.unit.trim()?" · "+x.unit:""));
       const thead=el("thead"),tr=el("tr");
       x.columns.forEach(h=>{const th=el("th","",h);th.scope="col";tr.append(th);});
       thead.append(tr);table.append(caption,thead);
       const tbody=el("tbody");
       for(const row of x.rows){
         const line=el("tr");
         row.forEach((cell,i)=>{
           const node=el(i===0?"th":"td","",String(cell));
           if(i===0)node.scope="row";
           line.append(node);
         });
         tbody.append(line);
       }
       table.append(tbody);scroll.append(table);panel.append(scroll);
     }
     return panel;
   }
   function renderTask(item,token){
      const body=page();
      const card=el("section","ep-live-card ep-written-question");
      const meta=el("div","ep-written-task-meta");
      meta.append(el("span","ep-written-task-paper",item.paper_code||""));
      card.append(meta,el("p","ep-live-qtext ep-written-task-text",item.question),
        el("p","ep-written-instruction",t.instruction));
      body.append(card);
      const source=sourcePanel(item);
      if(source)body.append(source);
      const work=el("section","ep-live-card ep-written-workflow");
      const criteriaBox=el("div","ep-written-marking");criteriaBox.hidden=true;
      const err=el("p","ep-live-meta");err.setAttribute("role","alert");
      const actions=el("div","ep-live-actions ep-written-actions");
      const criteriaButton=btn(t.criteria,async()=>{
        if(closed||working||token!==sequence)return;
        if(!criteriaBox.hidden){
          criteriaBox.hidden=true;
          criteriaButton.textContent=t.criteria;
          return;
        }
        working=true;criteriaButton.disabled=true;
        try{
          const details=await ctl.criteria();
          if(closed||token!==sequence)return;
          const title=el("div","ep-written-marking-head");
          const scheme=details.marking;
          title.append(el("h3","ep-written-marking-title",t.criteriaTitle));
          if(scheme)title.append(el("span","ep-written-mark-total",
            scheme.max_marks+" "+t.marks));
          criteriaBox.replaceChildren(title);
          if(scheme){
            const breakdown=el("div","ep-written-mark-breakdown"+
              (scheme.ao3_marks===0?" ep-written-mark-single":""));
            const ao12=el("div","ep-written-mark-part");
            ao12.append(el("span","",t.ao12),
              el("strong","",scheme.ao12_marks+" "+t.marks));
            breakdown.append(ao12);
            if(scheme.ao3_marks>0){
              const ao3=el("div","ep-written-mark-part");
              ao3.append(el("span","",t.ao3),
                el("strong","",scheme.ao3_marks+" "+t.marks));
              breakdown.append(ao3);
            }
            criteriaBox.append(breakdown,el("p","ep-written-mark-help",
              scheme.style==="levels"?t.levelsInfo:t.pointInfo));
            if(scheme.style==="levels"){
              const levels=el("section","ep-written-levels");
              levels.append(el("h4","ep-written-mark-subtitle",t.levelsTitle));
              const ranges=count=>count===14?["11–14","6–10","1–5"]:
                count===8?["6–8","3–5","1–2"]:
                count===6?["5–6","3–4","1–2"]:
                count===4?["3–4","2","1"]:null;
              for(const [label,count] of [[t.ao12,scheme.ao12_marks],
                [t.ao3,scheme.ao3_marks]]){
                if(count<1)continue;
                const marks=ranges(count);
                if(!marks)continue;
                levels.append(el("div","ep-written-level-group",label));
                for(let index=0;index<3;index++){
                  const level=el("div","ep-written-level-row");
                  level.append(el("span","",t.levelLabel+" "+(3-index)),
                    el("strong","",marks[index]),
                    el("span","ep-written-level-description",
                      index===0?t.levelHigh:index===1?t.levelMiddle:t.levelLow));
                  levels.append(level);
                }
              }
              criteriaBox.append(levels);
            }
            criteriaBox.append(el("h4","ep-written-mark-subtitle",t.markContent));
          }else{
            criteriaBox.append(el("h4","ep-written-mark-subtitle",t.markContent));
          }
          const list=el("ul","ep-live-list ep-written-mark-points");
          // The Economics learner sees assessment standards, never expected
          // calculations, market effects or illustrative model answers.
          for(const requirement of (scheme?.assessment_criteria||details.requirements))
            list.append(el("li","",requirement));
          criteriaBox.append(list);
          if(scheme)criteriaBox.append(el("p","ep-written-mark-disclaimer",t.notOfficial));
          criteriaBox.hidden=false;criteriaButton.textContent=t.hideCriteria;
          err.textContent="";
        }catch(_){if(!closed&&token===sequence)err.textContent=t.offline;}
        finally{working=false;criteriaButton.disabled=false;}
      },true);
      const nextButton=btn(t.next,async()=>{
        if(closed||working||token!==sequence)return;
        working=true;nextButton.disabled=true;criteriaButton.disabled=true;
        try{
          await ctl.next();
          if(closed||token!==sequence)return;
          working=false;await loadNext();
        }catch(_){
          if(!closed&&token===sequence){err.textContent=t.offline;working=false;
            nextButton.disabled=false;criteriaButton.disabled=false;}
        }
      });
      actions.append(criteriaButton,nextButton);
      work.append(actions,err,criteriaBox);body.append(work);
   }
   function dispose(){closed=true;sequence++;ctl=null;root=null;}
   loadNext();
   return Object.freeze({dispose});
 }
 window.iClubWrittenCoreViewV1=Object.freeze({mount});
})();