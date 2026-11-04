/* iClub Mathematics P1/P5: compact learner timeline.
 * OPT-IN only. Reads learner progress; can write ONLY learner-selected P1/P5
 * dates after explicit Save, and may change ONLY the Mathematics weekly
 * budget after a separate deliberate Accept tap. No automatic change to
 * progress, localStorage, content language, sessions or assessments.
 */
(() => {
  'use strict';
  if (window.iClubExamPrepSimpleTimelineUiEnabled !== true) return;
  const internal = (window.iClubExamPrepHostInternal = window.iClubExamPrepHostInternal || {});
  const VERSION = 'p2_17_weekly_choice_ui_v1';
  const ACCEPT_RPC = 'accept_my_exam_prep_timeline_weekly_target_safe_v1';
  const SAVE_RPC = 'save_my_exam_prep_timeline_dates_safe_v1';
  const RPC = 'get_exam_prep_simple_learning_timeline_with_hours_safe_v2';
  const SELECTOR = '[data-ep-simple-timeline]';
  let observer = null, pending = false, requestId = 0, currentIntro = null;
  const WORDS = Object.freeze({
    ru: {
      title: 'Мой путь к экзамену', start: 'Начало', today: 'Сегодня', exam: 'Экзамены',
      unset: 'Дата не указана', covered: 'Подтверждено', working: 'В работе',
      unchecked: 'Не проверено', remaining: 'Осталось примерно',
      total: 'Общий остаток', weekly: 'Ориентир в неделю', chosen: 'Сейчас выделено',
      hours: 'ч', perWeek: 'ч/нед', skills: 'навыков',
      noDates: 'Выберите дату хотя бы одного экзамена, чтобы увидеть недельный ориентир.',
      assumption: 'Приблизительная оценка iClub по разделам Cambridge и вашим результатам. Фактическое время может отличаться.',
      noTime: 'Время пока недоступно', noChange: 'Ваше расписание не изменено.',
      chooseDate:'Выбрать дату', changeDate:'Изменить дату',
      editTitle:'Даты моих экзаменов', saveDates:'Сохранить даты',
      saving:'Сохранение…', cancel:'Отмена', clear:'Очистить',
      dateHelp:'Выберите даты P1 и P5. Их можно изменить позже.',
      dateError:'Выберите будущую дату в пределах трёх лет.',
      saveError:'Не удалось сохранить даты. Попробуйте снова.',
      saved:'Даты сохранены. План пересчитан.',
      enough:'По текущему ориентиру выделенного времени хватает.',
      short:'Дополнительно потребуется примерно',
      impossible:'До выбранной даты расчётное время превышает 168 часов в неделю. Попробуйте выбрать более позднюю дату.',
      within:'в неделю',
      adopt:'Выделить', adoptSuffix:'ч/нед',
      tooMuch:'Рекомендуемое время больше вашего общего недельного бюджета. Его можно изменить в настройках Exam Prep.',
      onlyPaper:'Ориентир пока только для',
      updating:'Сохранение…',updated:'Недельный план обновлён.',
      acceptFailed:'Не удалось изменить время. Откройте план заново и попробуйте ещё раз.'
    },
    uz: {
      title: 'Imtihongacha yo‘lim', start: 'Boshlanishi', today: 'Bugun', exam: 'Imtihonlar',
      unset: 'Sana kiritilmagan', covered: 'Tasdiqlangan', working: 'O‘rganilmoqda',
      unchecked: 'Tekshirilmagan', remaining: 'Taxminan qoldi',
      total: 'Jami qolgan vaqt', weekly: 'Haftalik mo‘ljal', chosen: 'Hozir ajratilgan',
      hours: 'soat', perWeek: 'soat/hafta', skills: 'ko‘nikma',
      noDates: 'Haftalik mo‘ljal uchun kamida bitta imtihon sanasini tanlang.',
      assumption: 'iClub taxmini Cambridge bo‘limlari va natijalaringizga asoslangan. Haqiqiy vaqt farq qilishi mumkin.',
      noTime: 'Vaqt hozircha mavjud emas', noChange: 'Jadvalingiz o‘zgartirilmadi.',
      chooseDate:'Sanani tanlash', changeDate:'Sanani o‘zgartirish',
      editTitle:'Imtihon sanalarim', saveDates:'Sanalarni saqlash',
      saving:'Saqlanmoqda…', cancel:'Bekor qilish', clear:'Tozalash',
      dateHelp:'P1 va P5 sanalarini tanlang. Keyin o‘zgartirish mumkin.',
      dateError:'Kelgusi uch yil ichidagi sanani tanlang.',
      saveError:'Sanalarni saqlab bo‘lmadi. Qayta urinib ko‘ring.',
      saved:'Sanalar saqlandi. Reja yangilandi.',
      enough:'Hozir ajratgan vaqtingiz taxminiy mo‘ljal uchun yetadi.',
      short:'Qo‘shimcha kerak:',
      impossible:'Tanlangan sanagacha taxminiy vaqt haftasiga 168 soatdan oshadi. Keyinroq sanani tanlab ko‘ring.',
      within:'haftasiga',
      adopt:'Ajratish', adoptSuffix:'soat/hafta',
      tooMuch:'Tavsiya etilgan vaqt umumiy haftalik budjetingizdan ko‘p. Uni Exam Prep sozlamalarida o‘zgartirishingiz mumkin.',
      onlyPaper:'Hozircha faqat',updating:'Saqlanmoqda…',
      updated:'Haftalik reja yangilandi.',
      acceptFailed:'Vaqt o‘zgarmadi. Rejani yangilab, qayta urinib ko‘ring.'
    },
    en: {
      title: 'My exam timeline', start: 'Started', today: 'Today', exam: 'Exams',
      unset: 'Date not selected', covered: 'Confirmed', working: 'In progress',
      unchecked: 'Not yet checked', remaining: 'About',
      total: 'Estimated time left', weekly: 'Weekly target', chosen: 'Your current plan',
      hours: 'h', perWeek: 'h/week', skills: 'skills',
      noDates: 'Choose at least one exam date to see a weekly target.',
      assumption: 'This is an approximate iClub estimate based on Cambridge topics and your results. Actual study time may vary.',
      noTime: 'Estimate unavailable', noChange: 'Your study plan has not changed.',
      chooseDate:'Choose date', changeDate:'Change date',
      editTitle:'My exam dates', saveDates:'Save dates',
      saving:'Saving…', cancel:'Cancel', clear:'Clear',
      dateHelp:'Choose your P1 and P5 dates. You can change them later.',
      dateError:'Choose a future date within the next three years.',
      saveError:'Could not save dates. Please try again.',
      saved:'Dates saved. Study target updated.',
      enough:'Your current study time meets this approximate target.',
      short:'Additional time needed:',
      impossible:'The estimated time exceeds 168 hours per week before this exam. Consider a later date.',
      within:'per week',
      adopt:'Set', adoptSuffix:'h/week',
      tooMuch:'The suggested time exceeds your total weekly study budget. You can change it in Exam Prep settings.',
      onlyPaper:'Target currently covers only',updating:'Saving…',
      updated:'Weekly plan updated.',
      acceptFailed:'Could not update your time. Refresh the plan and try again.'
    }
  });
  function language() {
    const raw = String(window.i18n?.getLang?.() || document.documentElement?.lang || 'ru').toLowerCase();
    if (raw.startsWith('uz')) return 'uz';
    if (raw.startsWith('en')) return 'en';
    return 'ru';
  }
  function esc(x) {
    return String(x ?? '').replace(/[&<>"']/g, c =>
      ({ '&':'&amp;', '<':'&lt;', '>':'&gt;', '"':'&quot;', "'":'&#39;' })[c]);
  }
  function finite(x, min, max) {
    return typeof x === 'number' && Number.isFinite(x) && x >= min && x <= max;
  }
  function parsePayload(payload) {
    if (!payload || payload.contract_version !== 'exam_prep_one_line_progress_timeline_v2_estimated' ||
        payload.factors_are_iclub_planning_assumptions_not_official_cambridge !== true ||
        payload.source_guided_hours_are_not_private_study_hours !== true ||
        payload.recommended_schedule_applied_automatically !== false ||
        payload.learning_evidence_mutated !== false) return null;
    const cards = [];
    for (const [code, total, cap] of [['P1',45,90],['P5',36,50]]) {
      const s=payload[code];
      if (!s || s.component_code!==code || s.total_syllabus_skills!==total ||
          !Number.isInteger(s.objectively_covered_skills) ||
          !Number.isInteger(s.already_attempted_not_yet_confirmed_skills) ||
          !Number.isInteger(s.not_yet_checked_skills) ||
          !finite(s.estimated_remaining_study_hours,0,cap)) return null;
      const confirmed=s.objectively_covered_skills, attempted=s.already_attempted_not_yet_confirmed_skills,
        unknown=s.not_yet_checked_skills;
      if (confirmed<0 || attempted<0 || unknown<0 || confirmed+attempted+unknown!==total ||
          s.skills_not_yet_objectively_covered!==total-confirmed) return null;
      cards.push({ code,total,confirmed,attempted,unknown,hours:s.estimated_remaining_study_hours,
        examAt:s.exam_date_status==='valid_exam_date' ? s.exam_at : null,
        paperWeekly:finite(s.estimated_component_weekly_hours,0,100000) ? s.estimated_component_weekly_hours : null });
    }
    if (!finite(payload.estimated_remaining_math_hours,0,140) ||
        Math.abs(payload.estimated_remaining_math_hours-cards.reduce((t,c)=>t+c.hours,0))>0.12) return null;
    const weekly=payload.joint_paper_dates_status==='both_paper_dates_confirmed' &&
      finite(payload.estimated_joint_math_hours_per_week,0,100000)
      ? payload.estimated_joint_math_hours_per_week : null;
    const chosen=finite(payload.existing_chosen_math_hours_per_week,0,168)
      ? payload.existing_chosen_math_hours_per_week : null;
    const totalBudget=finite(payload.student_total_hours_per_week,0,168)
      ? payload.student_total_hours_per_week : null;
    const profileRevision=Number.isInteger(payload.student_budget_profile_revision) &&
      payload.student_budget_profile_revision>=1 ? payload.student_budget_profile_revision : null;
    const dated=cards.filter(x=>x.examAt&&x.paperWeekly!==null);
    const onePaper=weekly===null && dated.length===1 ? dated[0].code : null;
    const suggested=weekly!==null ? weekly : onePaper!==null ? dated[0].paperWeekly : null;
    const canAdopt=suggested!==null && suggested>0 && suggested<=168 &&
      chosen!==null && totalBudget!==null && profileRevision!==null &&
      suggested>chosen+0.04 && suggested<=totalBudget;
    return {startAt:payload.start_at,asOf:payload.as_of,cards,
      totalHours:payload.estimated_remaining_math_hours,weekly,chosen,
      suggested,onePaper,canAdopt,totalBudget,profileRevision};
  }
  function niceNumber(n,lang) {
    return new Intl.NumberFormat(lang==='uz'?'uz-UZ':lang==='en'?'en-GB':'ru-RU', {
      maximumFractionDigits:1
    }).format(n);
  }
  function formatDate(value,lang) {
    if (!value) return null;
    const d = new Date(value);
    if (!Number.isFinite(d.getTime())) return null;
    return new Intl.DateTimeFormat(lang==='uz'?'uz-UZ':lang==='en'?'en-GB':'ru-RU',{
      timeZone:'Asia/Tashkent',day:'numeric',month:'short',year:'numeric'
    }).format(d);
  }

  function inputDate(value) {
    if (!value) return '';
    const d=new Date(value);
    if (!Number.isFinite(d.getTime())) return '';
    const parts=new Intl.DateTimeFormat('en-GB',{
      timeZone:'Asia/Tashkent',year:'numeric',month:'2-digit',day:'2-digit'
    }).formatToParts(d);
    const p=Object.fromEntries(parts.filter(x=>['year','month','day'].includes(x.type))
      .map(x=>[x.type,x.value]));
    return p.year+'-'+p.month+'-'+p.day;
  }
  function inputBounds() {
    const day=inputDate(new Date());
    const limit=inputDate(new Date(Date.now()+Math.floor(365.0*3)*86400000));
    const tomorrow=inputDate(new Date(Date.now()+86400000));
    return {today:day,min:tomorrow,max:limit};
  }
  function validInputDate(value,bounds) {
    return value==='' || (/^\d{4}-\d{2}-\d{2}$/.test(value)
      && value>=bounds.min && value<=bounds.max);
  }
  function viewHtml(model,lang='ru') {
    const w=WORDS[lang]||WORDS.ru;
    const date=n=>esc(formatDate(n,lang)||w.unset);
    const metric=(label,value)=>'<div class="ep-tl-stat"><span>'+esc(label)+'</span><strong>'+esc(value)+'</strong></div>';
    const exams=model.cards.map(x=>'<button type="button" class="ep-tl-exam-chip"'+
      ' data-ep-tl-open-date="'+x.code+'" aria-label="'+esc(x.code+' · '+(x.examAt?w.changeDate:w.chooseDate))+'">'+
      '<strong>'+x.code+'</strong><span>'+date(x.examAt)+'</span>'+
      '<svg aria-hidden="true" viewBox="0 0 24 24" width="15" height="15" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">'+
      '<rect x="3" y="5" width="18" height="16" rx="2"/><path d="M7 3v4M17 3v4M3 10h18"/></svg></button>').join('');
    const cards=model.cards.map(x=>{
      const finished=Math.max(0,Math.min(100,100*x.confirmed/x.total));
      const attempted=Math.max(0,Math.min(100-finished,100*x.attempted/x.total));
      return '<div class="ep-tl-paper" data-ep-tl-paper="'+x.code+'">'+
        '<div class="ep-tl-paper-top"><strong>'+x.code+'</strong>'+
        '<span>'+esc(w.remaining)+' <b>'+esc(niceNumber(x.hours,lang))+' '+esc(w.hours)+'</b></span></div>'+
        '<div class="ep-tl-bars" role="img" aria-label="'+esc(w.covered)+' '+x.confirmed+'/'+x.total+'">'+
          '<span class="ep-tl-done" style="width:'+finished.toFixed(2)+'%"></span>'+
          '<span class="ep-tl-active" style="width:'+attempted.toFixed(2)+'%"></span></div>'+
        '<div class="ep-tl-paper-details">'+
        '<span>'+esc(w.covered)+' <b>'+x.confirmed+'/'+x.total+'</b></span>'+
        '<span>'+esc(w.working)+' <b>'+x.attempted+'</b></span>'+
        '<span>'+esc(w.unchecked)+' <b>'+x.unknown+'</b></span></div></div>';
    }).join('');
    const sum=metric(w.total,niceNumber(model.totalHours,lang)+' '+w.hours);
    const dated=model.cards.filter(x=>x.examAt&&x.paperWeekly!==null);
    const pace=model.weekly!==null
      ? metric(w.weekly,niceNumber(model.weekly,lang)+' '+w.perWeek)
      : dated.length===1
        ? metric(dated[0].code+' · '+w.weekly,niceNumber(dated[0].paperWeekly,lang)+' '+w.perWeek)
        : '<p class="ep-tl-guidance">'+esc(w.noDates)+'</p>';
    const current=model.chosen===null?'':metric(w.chosen,niceNumber(model.chosen,lang)+' '+w.perWeek);
    const gap=model.suggested===null||model.chosen===null ? null :
      Math.max(0,Math.round((model.suggested-model.chosen)*10)/10);
    const paperOnly=model.onePaper ? '<span class="ep-tl-scope">'+esc(w.onlyPaper+' '+model.onePaper)+'</span>' : '';
    const compare=model.suggested===null||model.chosen===null ? '' :
      '<div class="ep-tl-compare" data-ep-tl-compare>'+
        (gap<=0.04
          ? '<p class="ep-tl-enough">'+esc(w.enough)+'</p>'
          : '<p class="ep-tl-short">'+esc(w.short)+' <strong>'+
            esc(niceNumber(gap,lang))+' '+esc(w.perWeek)+'</strong></p>'+
            (model.canAdopt
              ? '<button type="button" data-ep-tl-accept class="ep-tl-accept">'+
                  esc(w.adopt)+' '+esc(niceNumber(model.suggested,lang))+' '+esc(w.adoptSuffix)+'</button>'
              : '<p class="ep-tl-total-cap">'+esc(model.suggested>168?w.impossible:w.tooMuch)+'</p>'))+
        paperOnly+
        '<p data-ep-tl-plan-feedback role="status" hidden></p>'+
      '</div>';
    const bounds=inputBounds();
    const editor='<form class="ep-tl-date-editor" data-ep-tl-date-editor hidden novalidate>'+
      '<h4>'+esc(w.editTitle)+'</h4><div class="ep-tl-date-fields">'+
      model.cards.map(x=>'<div class="ep-tl-date-field">'+
        '<label for="ep-tl-date-'+x.code+'"><strong>'+x.code+'</strong></label>'+
        '<div class="ep-tl-date-input-line"><input id="ep-tl-date-'+x.code+'" type="date"'+
        ' data-ep-tl-date="'+x.code+'" value="'+esc(inputDate(x.examAt))+'"'+
        ' min="'+bounds.min+'" max="'+bounds.max+'" autocomplete="off" />'+
        '<button class="ep-tl-clear" type="button" data-ep-tl-clear="'+x.code+'"'+
        ' aria-label="'+esc(w.clear+' '+x.code)+'">'+esc(w.clear)+'</button></div></div>').join('')+
      '</div><p class="ep-tl-date-hint">'+esc(w.dateHelp)+'</p>'+
      '<p class="ep-tl-date-error" data-ep-tl-error role="alert" hidden></p>'+
      '<div class="ep-tl-date-actions"><button type="button" data-ep-tl-cancel>'+esc(w.cancel)+'</button>'+
      '<button type="submit" class="ep-tl-date-save" data-ep-tl-save disabled>'+esc(w.saveDates)+'</button></div>'+
      '</form>';
    return '<section class="ep-tl-card" data-ep-simple-timeline aria-label="'+esc(w.title)+'">'+
      '<h3 class="ep-tl-title">'+esc(w.title)+'</h3>'+
      '<div class="ep-tl-rail" aria-hidden="true"><span></span><span></span><span></span></div>'+
      '<div class="ep-tl-milestones">'+
        '<div><span>'+esc(w.start)+'</span><strong>'+date(model.startAt)+'</strong></div>'+
        '<div><span>'+esc(w.today)+'</span><strong>'+date(model.asOf)+'</strong></div>'+
        '<div><span>'+esc(w.exam)+'</span><div class="ep-tl-exams">'+exams+'</div></div></div>'+
      '<div class="ep-tl-papers">'+cards+'</div>'+
      '<div class="ep-tl-bottom">'+sum+pace+current+'</div>'+
      compare+
      editor+
      '<p class="ep-tl-footnote">'+esc(w.assumption)+' '+esc(w.noChange)+'</p>'+
      '<p class="ep-tl-date-success" data-ep-tl-success role="status" hidden></p>'+
      '</section>';
  }


  async function acceptWeekly(section,model,button) {
    if (!section || !button || button.disabled || !model.canAdopt ||
        !canShow(root()) || !root()?.contains(section)) return;
    const gen=requestId;
    const w=WORDS[language()]||WORDS.ru;
    const status=section.querySelector('[data-ep-tl-plan-feedback]');
    const sb=window.sb;
    if(!sb || typeof sb.rpc!=='function')return;
    button.disabled=true;
    const label=button.textContent;
    button.textContent=w.updating;
    try {
      const response=await sb.rpc(ACCEPT_RPC,{
        p_expected_current_math_hours:model.chosen,
        p_expected_profile_revision:model.profileRevision,
        p_new_math_hours:model.suggested
      });
      if(response?.error) throw response.error;
      const updated=parsePayload(Array.isArray(response?.data)?response.data[0]:response?.data);
      if(!updated)throw Error('Updated plan response missing');
      if(gen!==requestId || !canShow(root()) || !root()?.contains(section))return;
      const wrapper=document.createElement('div');
      wrapper.innerHTML=viewHtml(updated,language());
      const replacement=wrapper.firstElementChild;
      if(!replacement)throw Error('Updated plan DOM missing');
      section.replaceWith(replacement);
      bindCard(replacement,updated);
      const feedback=replacement.querySelector('[data-ep-tl-plan-feedback]') ||
        replacement.querySelector('[data-ep-tl-date-success]');
      if(feedback){feedback.hidden=false;feedback.textContent=(WORDS[language()]||WORDS.ru).updated;}
    } catch (_) {
      if(gen===requestId && canShow(root()) && root()?.contains(section) && status){
        status.textContent=w.acceptFailed;status.hidden=false;
      }
    } finally {
      button.disabled=false;button.textContent=label;
    }
  }
  function bindCard(section,model) {
    if (!section || typeof section.addEventListener!=='function') return;
    const w=WORDS[language()]||WORDS.ru;
    const editor=section.querySelector('[data-ep-tl-date-editor]');
    const save=section.querySelector('[data-ep-tl-save]');
    const error=section.querySelector('[data-ep-tl-error]');
    const original=Object.fromEntries(model.cards.map(x=>[x.code,inputDate(x.examAt)]));
    const bounds=inputBounds();
    const input=paper=>section.querySelector('[data-ep-tl-date="'+paper+'"]');
    const values=()=>({P1:input('P1')?.value||'',P5:input('P5')?.value||''});
    let busy=false;
    const setError=message=>{
      if (!error) return;
      error.textContent=message||'';
      error.hidden=!message;
    };
    const refresh=()=>{
      const v=values();
      const invalid=!validInputDate(v.P1,bounds)||!validInputDate(v.P5,bounds);
      const changed=v.P1!==original.P1||v.P5!==original.P5;
      if (save) save.disabled=busy||invalid||!changed;
      if (!busy) setError(invalid?w.dateError:'');
    };
    section.addEventListener('click',event=>{
      const accept=event.target?.closest?.('[data-ep-tl-accept]');
      if(accept && section.contains(accept)) {
        void acceptWeekly(section,model,accept);
        return;
      }
      const btn=event.target?.closest?.('[data-ep-tl-open-date], [data-ep-tl-clear], [data-ep-tl-cancel]');
      if (!btn || !section.contains(btn) || busy || !canShow(root())) return;
      if (btn.hasAttribute('data-ep-tl-cancel')) {
        for(const code of ['P1','P5']) if(input(code)) input(code).value=original[code];
        if(editor) editor.hidden=true;
        setError('');
        refresh();
        return;
      }
      if (btn.hasAttribute('data-ep-tl-clear')) {
        const code=btn.dataset.epTlClear;
        if (code==='P1'||code==='P5') {
          const target=input(code);
          if(target) {target.value='';target.focus();refresh();}
        }
        return;
      }
      const code=btn.dataset.epTlOpenDate;
      if(code!=='P1'&&code!=='P5') return;
      if(editor) editor.hidden=false;
      setError('');
      refresh();
      const picker=input(code);
      if(picker) {
        picker.focus();
        // Native picker is more accessible than a custom calendar and
        // obeys the OS locale and mobile tap/keyboard behavior.
        try {picker.showPicker?.();} catch (_) {}
      }
    });
    editor?.addEventListener('input',refresh);
    editor?.addEventListener('change',refresh);
    editor?.addEventListener('submit',async event=>{
      event.preventDefault();
      if(busy || !canShow(root()) || !root()?.contains(section)) return;
      const v=values();
      if(!validInputDate(v.P1,bounds)||!validInputDate(v.P5,bounds)){
        setError(w.dateError);return;
      }
      if(v.P1===original.P1 && v.P5===original.P5) return;
      const sb=window.sb;
      if(!sb || typeof sb.rpc!=='function') {setError(w.saveError);return;}
      busy=true;refresh();
      if(save) save.textContent=w.saving;
      const generation=requestId;
      try {
        const response=await sb.rpc(SAVE_RPC,{
          p_p1_date:v.P1||null,p_p5_date:v.P5||null
        });
        if(response?.error) throw response.error;
        const updated=parsePayload(Array.isArray(response?.data)?response.data[0]:response?.data);
        if(!updated) throw Error('Timeline response missing');
        if(generation!==requestId || !canShow(root()) || !root()?.contains(section)) return;
        const container=document.createElement('div');
        container.innerHTML=viewHtml(updated,language());
        const replacement=container.firstElementChild;
        if(!replacement) throw Error('Timeline refresh failed');
        section.replaceWith(replacement);
        bindCard(replacement,updated);
        const feedback=replacement.querySelector('[data-ep-tl-success]');
        if(feedback){feedback.textContent=(WORDS[language()]||WORDS.ru).saved;feedback.hidden=false;}
      } catch (_) {
        if(generation===requestId && root()?.contains(section)) setError(w.saveError);
      } finally {
        busy=false;
        if(save) save.textContent=w.saveDates;
        // Re-enable Save without erasing the visible error on failed requests.
        if (save) {
          const latest=values();
          save.disabled=!(latest.P1!==original.P1||latest.P5!==original.P5)
            || !validInputDate(latest.P1,bounds)||!validInputDate(latest.P5,bounds);
        }
      }
    });
  }
  function root() { return document.querySelector('#exam-prep-host-root'); }
  function canShow(r) {
    const c=internal.lastCapabilities;
    const hub=document.querySelector('#courses-subject-hub');
    return window.iClubExamPrepSimpleTimelineUiEnabled===true && Boolean(r && !r.hidden &&
      hub?.dataset?.subjectKey==='mathematics' &&
      c?.coreAccess===true && c?.killSwitch===false &&
      c?.rolloutState==='controlled_beta');
  }
  function reconcile() {
    const r=root();
    if (!canShow(r)) {currentIntro=null;requestId++;return;}
    const intro=r.querySelector('.ep-live-dashboard-intro');
    if (!intro) {currentIntro=null;requestId++;return;}
    if (intro===currentIntro || intro.nextElementSibling?.matches?.(SELECTOR)) return;
    currentIntro=intro;
    const myId=++requestId;
    const sb=window.sb;
    if (!sb || typeof sb.rpc!=='function') return;
    void (async()=>{
      try {
        const {data,error}=await sb.rpc(RPC,{});
        if (error || myId!==requestId || !canShow(r) ||
            !r.contains(intro) || intro.nextElementSibling?.matches?.(SELECTOR)) return;
        const model=parsePayload(Array.isArray(data)?data[0]:data);
        if (!model) return;
        const card=document.createElement('div');
        card.innerHTML=viewHtml(model,language());
        const inserted=card.firstElementChild;
        if (inserted) {
          // Moving the element detaches it from the temporary wrapper.
          // Capture it BEFORE insertAdjacentElement or listeners are lost.
          intro.insertAdjacentElement('afterend',inserted);
          bindCard(inserted,model);
        }
      } catch (_) { /* Fail closed. Existing Exam Prep UI stays untouched. */ }
    })();
  }
  function schedule() {
    if (pending) return;
    pending=true;
    Promise.resolve().then(()=>{pending=false;reconcile();});
  }
  internal.simpleTimelineUi=Object.freeze({version:VERSION,parsePayload,viewHtml,reconcile,inputDate,validInputDate,bindCard,acceptWeekly});
  if (typeof MutationObserver==='function') {
    observer=new MutationObserver(schedule);
    observer.observe(document.documentElement,{childList:true,subtree:true,attributes:true,
      attributeFilter:['hidden','data-subject-key']});
  }
  window.addEventListener?.('iclub:exam-prep-capabilities',schedule);
  if (document.readyState==='loading') document.addEventListener('DOMContentLoaded',schedule,{once:true});
  else schedule();
})();
