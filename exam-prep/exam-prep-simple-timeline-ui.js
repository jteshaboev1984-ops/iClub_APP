/* iClub Mathematics P1/P5: compact learner timeline.
 * OPT-IN only. Read-only. Never modifies exam profile, weekly schedule,
 * progress, localStorage, content language, sessions or assessment routes.
 */
(() => {
  'use strict';
  if (window.iClubExamPrepSimpleTimelineUiEnabled !== true) return;
  const internal = (window.iClubExamPrepHostInternal = window.iClubExamPrepHostInternal || {});
  const VERSION = 'p2_15_simple_timeline_ui_v1';
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
      noDates: 'Укажите даты экзаменов P1 и P5, чтобы рассчитать недельный ориентир.',
      assumption: 'Приблизительная оценка iClub по разделам Cambridge и вашим результатам. Фактическое время может отличаться.',
      noTime: 'Время пока недоступно', noChange: 'Ваше расписание не изменено.'
    },
    uz: {
      title: 'Imtihongacha yo‘lim', start: 'Boshlanishi', today: 'Bugun', exam: 'Imtihonlar',
      unset: 'Sana kiritilmagan', covered: 'Tasdiqlangan', working: 'O‘rganilmoqda',
      unchecked: 'Tekshirilmagan', remaining: 'Taxminan qoldi',
      total: 'Jami qolgan vaqt', weekly: 'Haftalik mo‘ljal', chosen: 'Hozir ajratilgan',
      hours: 'soat', perWeek: 'soat/hafta', skills: 'ko‘nikma',
      noDates: 'Haftalik mo‘ljal uchun P1 va P5 imtihon sanalarini kiriting.',
      assumption: 'iClub taxmini Cambridge bo‘limlari va natijalaringizga asoslangan. Haqiqiy vaqt farq qilishi mumkin.',
      noTime: 'Vaqt hozircha mavjud emas', noChange: 'Jadvalingiz o‘zgartirilmadi.'
    },
    en: {
      title: 'My exam timeline', start: 'Started', today: 'Today', exam: 'Exams',
      unset: 'Date not selected', covered: 'Confirmed', working: 'In progress',
      unchecked: 'Not yet checked', remaining: 'About',
      total: 'Estimated time left', weekly: 'Weekly target', chosen: 'Your current plan',
      hours: 'h', perWeek: 'h/week', skills: 'skills',
      noDates: 'Add your P1 and P5 exam dates to calculate a weekly target.',
      assumption: 'This is an approximate iClub estimate based on Cambridge topics and your results. Actual study time may vary.',
      noTime: 'Estimate unavailable', noChange: 'Your study plan has not changed.'
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
        examAt:s.exam_date_status==='valid_exam_date' ? s.exam_at : null });
    }
    if (!finite(payload.estimated_remaining_math_hours,0,140) ||
        Math.abs(payload.estimated_remaining_math_hours-cards.reduce((t,c)=>t+c.hours,0))>0.12) return null;
    const weekly=payload.joint_paper_dates_status==='both_paper_dates_confirmed' &&
      finite(payload.estimated_joint_math_hours_per_week,0,500)
      ? payload.estimated_joint_math_hours_per_week : null;
    const chosen=finite(payload.existing_chosen_math_hours_per_week,0,168)
      ? payload.existing_chosen_math_hours_per_week : null;
    return {startAt:payload.start_at,asOf:payload.as_of,cards,
      totalHours:payload.estimated_remaining_math_hours,weekly,chosen};
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
  function viewHtml(model,lang='ru') {
    const w=WORDS[lang]||WORDS.ru;
    const date=n=>esc(formatDate(n,lang)||w.unset);
    const metric=(label,value)=>'<div class="ep-tl-stat"><span>'+esc(label)+'</span><strong>'+esc(value)+'</strong></div>';
    const exams=model.cards.map(x=>'<span><strong>'+x.code+'</strong> '+date(x.examAt)+'</span>').join('');
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
    const pace=model.weekly===null
      ? '<p class="ep-tl-guidance">'+esc(w.noDates)+'</p>'
      : metric(w.weekly,niceNumber(model.weekly,lang)+' '+w.perWeek);
    const current=model.chosen===null?'':metric(w.chosen,niceNumber(model.chosen,lang)+' '+w.perWeek);
    return '<section class="ep-tl-card" data-ep-simple-timeline aria-label="'+esc(w.title)+'">'+
      '<h3 class="ep-tl-title">'+esc(w.title)+'</h3>'+
      '<div class="ep-tl-rail" aria-hidden="true"><span></span><span></span><span></span></div>'+
      '<div class="ep-tl-milestones">'+
        '<div><span>'+esc(w.start)+'</span><strong>'+date(model.startAt)+'</strong></div>'+
        '<div><span>'+esc(w.today)+'</span><strong>'+date(model.asOf)+'</strong></div>'+
        '<div><span>'+esc(w.exam)+'</span><div class="ep-tl-exams">'+exams+'</div></div></div>'+
      '<div class="ep-tl-papers">'+cards+'</div>'+
      '<div class="ep-tl-bottom">'+sum+pace+current+'</div>'+
      '<p class="ep-tl-footnote">'+esc(w.assumption)+' '+esc(w.noChange)+'</p>'+
      '</section>';
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
        if (card.firstElementChild) intro.insertAdjacentElement('afterend',card.firstElementChild);
      } catch (_) { /* Fail closed. Existing Exam Prep UI stays untouched. */ }
    })();
  }
  function schedule() {
    if (pending) return;
    pending=true;
    Promise.resolve().then(()=>{pending=false;reconcile();});
  }
  internal.simpleTimelineUi=Object.freeze({version:VERSION,parsePayload,viewHtml,reconcile});
  if (typeof MutationObserver==='function') {
    observer=new MutationObserver(schedule);
    observer.observe(document.documentElement,{childList:true,subtree:true,attributes:true,
      attributeFilter:['hidden','data-subject-key']});
  }
  window.addEventListener?.('iclub:exam-prep-capabilities',schedule);
  if (document.readyState==='loading') document.addEventListener('DOMContentLoaded',schedule,{once:true});
  else schedule();
})();
