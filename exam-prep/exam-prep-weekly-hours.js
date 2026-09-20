/* Optional shared Mathematics weekdays inside ONE existing Exam Plan editor.
 * Separate server enrollment is mandatory; never auto-replan or edit grades.
 */
(() => {
  'use strict';
  const internal=(window.iClubExamPrepHostInternal=window.iClubExamPrepHostInternal||{});
  if(internal.weeklyDayHours) return;
  const DAYS=['mon','tue','wed','thu','fri','sat','sun'];
  const VERSION='weekly_day_availability_v1';
  const words={
    ru:{title:'Свободное время на математику по дням',
      note:'Необязательно. Укажите часы обычной недели: 0 — времени нет. Заполните все семь дней или оставьте все поля пустыми, чтобы очистить распределение. Это один общий бюджет для P1 и P5, а не дополнительные часы.',
      caveat:'Это распределение обычной недели, а не подсчёт оставшихся часов сегодня. Задания текущей недели не заменяются.',
      stale:'После изменения учебного времени подтвердите распределение по дням ещё раз.',
      refresh:'План изменился на другом устройстве. Вернитесь к обзору и откройте план заново.',
      invalid:'Заполните все семь дней или оставьте все пустыми. Значения от 0 до 24 с шагом 0,5 часа. Сумма не должна превышать недельный бюджет математики.',
      day:['Пн','Вт','Ср','Чт','Пт','Сб','Вс']},
    uz:{title:'Matematika uchun haftalik bo‘sh vaqtni kunlarga ajrating',
      note:'Ixtiyoriy. Oddiy haftadagi soatlarni kiriting: 0 — bo‘sh vaqt yo‘q. Yetti kunning barchasini to‘ldiring yoki taqsimotni tozalash uchun hammasini bo‘sh qoldiring. Bu P1 va P5 uchun umumiy vaqt, qo‘shimcha soatlar emas.',
      caveat:'Bu odatiy hafta taqsimoti, bugunga qolgan vaqt hisobi emas. Joriy haftadagi vazifalar almashtirilmaydi.',
      stale:'O‘qish vaqti o‘zgarganidan keyin kunlik taqsimotni qayta tasdiqlang.',
      refresh:'Reja boshqa qurilmada o‘zgargan. Umumiy ko‘rinishga qaytib, rejani qaytadan oching.',
      invalid:'Yetti kunning barchasini to‘ldiring yoki hammasini bo‘sh qoldiring. 0 dan 24 gacha, 0,5 soat qadam bilan kiriting. Jami soat matematikaning haftalik vaqt chegarasidan oshmasin.',
      day:['Du','Se','Ch','Pa','Ju','Sh','Ya']},
    en:{title:'Available Mathematics hours by weekday',
      note:'Optional. Enter hours for a typical week: 0 means no time. Fill all seven days, or leave every field blank to clear the distribution. This is one shared P1 and P5 budget, not extra hours.',
      caveat:'This describes a typical week, not the hours still available today. Current-week tasks are not replaced.',
      stale:'After changing your study budget, confirm the weekday distribution again.',
      refresh:'Your plan changed on another device. Return to the overview and open it again.',
      invalid:'Fill all seven days or leave all fields blank. Use 0–24 in half-hour steps. The total cannot exceed your weekly Mathematics budget.',
      day:['Mon','Tue','Wed','Thu','Fri','Sat','Sun']}
  };
  const fail=reason=>Object.freeze({ok:false,reason});
  function allowed(){
    const caps=internal.lastCapabilities;
    return window.iClubExamPrepWeeklyFlowEnabled===true && caps?.coreAccess===true &&
      caps?.killSwitch===false && caps?.rolloutState==='controlled_beta';
  }
  function copy(){
    let lang='ru';
    try{lang=String(window.i18n?.getLang?.()||document.documentElement.lang||'ru').toLowerCase();}
    catch(_){/* locale fallback */}
    return words[lang]||words.ru;
  }
  async function rpc(name,args){
    if(!allowed()) return fail('disabled');
    if(typeof window.sb?.rpc!=='function') return fail('unavailable');
    try{
      const {data,error}=await window.sb.rpc(name,args);
      if(!allowed()) return fail('revoked');
      if(error?.code==='40001') return fail('profile_changed_refresh_required');
      if(error||!data||typeof data!=='object'||Array.isArray(data)) return fail('server_rejected');
      return Object.freeze({ok:true,data});
    }catch(_){return fail('network_unavailable');}
  }
  function validSlots(value){
    if(value===null) return true;
    return Boolean(value&&typeof value==='object'&&!Array.isArray(value)&&Object.keys(value).length===7&&
      DAYS.every(day=>Object.hasOwn(value,day)&&typeof value[day]==='number'&&
        Number.isFinite(value[day])&&value[day]>=0&&value[day]<=24&&Number.isInteger(value[day]*2)));
  }
  function validContract(data){
    return data?.contract_version===VERSION&&data.enabled===true&&
      data.scope==='shared_mathematics_week'&&data.planning_only===true&&
      data.does_not_change_current_plan===true&&typeof data.confirmed==='boolean'&&
      typeof data.needs_reconfirmation==='boolean'&&Number.isInteger(data.profile_revision)&&
      data.profile_revision>=1&&Number.isInteger(data.availability_revision)&&
      data.availability_revision>=0&&Number.isFinite(Number(data.mathematics_hours_budget))&&
      Number.isFinite(Number(data.total_student_hours_available))&&validSlots(data.weekday_hours)&&
      (data.weekday_hours!==null||(!data.confirmed&&!data.needs_reconfirmation))&&
      (data.weekday_hours===null||data.confirmed||data.needs_reconfirmation)&&
      !(data.confirmed&&data.needs_reconfirmation);
  }
  function matchesProfile(data,profile){
    return String(data.exam_series||'').trim().toLowerCase()===String(profile.exam_series||'').trim().toLowerCase()&&
      String(data.target_grade||'').trim().toUpperCase()===String(profile.target_grade||'').trim().toUpperCase()&&
      Number(data.total_student_hours_available)===Number(profile.total_student_hours_available)&&
      Number(data.mathematics_hours_budget)===Number(profile.mathematics_hours_budget);
  }
  async function decorate(form,profile){
    if(!allowed()||!form?.isConnected||form.dataset.epWeekdayHours) return false;
    form.dataset.epWeekdayHours='loading';
    const fetched=await rpc('get_my_exam_prep_weekday_availability_safe_v1',{});
    if(!form.isConnected) return false;
    if(!allowed()||!fetched.ok||!validContract(fetched.data)){
      form.dataset.epWeekdayHours='unavailable';return false;
    }
    if(!matchesProfile(fetched.data,profile)){
      form.dataset.epWeekdayHours='stale';
      const error=document.createElement('p');error.className='ep-day-hours-reconfirm';
      error.setAttribute('role','alert');error.textContent=copy().refresh;
      form.querySelector('.ep-live-actions')?.before(error);
      return false;
    }
    const c=copy();
    const fields=document.createElement('fieldset');fields.className='ep-day-hours';
    fields.dataset.epWeekdayHoursFields='true';
    const legend=document.createElement('legend');legend.textContent=c.title;
    const note=document.createElement('p');note.className='ep-day-hours-note';note.textContent=c.note;
    const grid=document.createElement('div');grid.className='ep-day-hours-grid';
    for(let i=0;i<DAYS.length;i++){
      const day=DAYS[i];
      const label=document.createElement('label');label.className='ep-day-hours-field';
      const title=document.createElement('span');title.textContent=c.day[i];
      const input=document.createElement('input');
      input.type='number';input.name=`ep_day_${day}`;input.min='0';input.max='24';
      input.step='0.5';input.inputMode='decimal';input.autocomplete='off';
      input.setAttribute('aria-label',`${c.title}: ${c.day[i]}`);
      if(fetched.data.weekday_hours) input.value=String(fetched.data.weekday_hours[day]);
      label.append(title,input);grid.append(label);
    }
    const caveat=document.createElement('p');caveat.className='ep-day-hours-note';caveat.textContent=c.caveat;
    fields.append(legend,note,grid,caveat);
    if(fetched.data.needs_reconfirmation){
      const stale=document.createElement('p');stale.className='ep-day-hours-reconfirm';
      stale.setAttribute('role','status');stale.textContent=c.stale;fields.append(stale);
    }
    const actions=form.querySelector('.ep-live-actions');
    if(!actions){form.dataset.epWeekdayHours='unavailable';return false;}
    form.insertBefore(fields,actions);
    form.dataset.epWeekdayHours='ready';
    form.dataset.epWeekdayExpectedRevision=String(fetched.data.profile_revision);
    form.dataset.epWeekdayAvailabilityRevision=String(fetched.data.availability_revision);
    return true;
  }
  function read(form,mathHours){
    if(!form||form.dataset.epWeekdayHours!=='ready') return fail('not_ready');
    const raw=DAYS.map(day=>String(form.elements[`ep_day_${day}`]?.value??'').trim());
    if(raw.every(value=>value==='')) return Object.freeze({ok:true,days:null});
    if(raw.some(value=>value==='')) return fail('invalid_hours');
    const days={};let total=0;
    for(let i=0;i<DAYS.length;i++){
      const value=Number(raw[i]);
      if(!Number.isFinite(value)||value<0||value>24||!Number.isInteger(value*2)) return fail('invalid_hours');
      days[DAYS[i]]=value;total+=value;
    }
    if(!Number.isFinite(mathHours)||total>mathHours) return fail('invalid_hours');
    return Object.freeze({ok:true,days:Object.freeze(days)});
  }
  async function save(form,profile){
    if(!allowed()||form?.dataset.epWeekdayHours!=='ready') return fail('disabled');
    const available=read(form,profile.mathHours);
    if(!available.ok) return available;
    const revision=Number(form.dataset.epWeekdayExpectedRevision);
    const dayRevision=Number(form.dataset.epWeekdayAvailabilityRevision);
    if(!Number.isInteger(revision)||revision<1||!Number.isInteger(dayRevision)||dayRevision<0)
      return fail('missing_revision');
    const result=await rpc('save_my_exam_prep_profile_with_weekday_availability_safe_v1',{
      p_exam_series:profile.examSeries,p_target_grade:profile.targetGrade,
      p_total_student_hours_available:profile.totalHours,p_mathematics_hours_budget:profile.mathHours,
      p_weekday_hours:available.days,p_expected_profile_revision:revision,
      p_expected_availability_revision:dayRevision
    });
    if(!result.ok) return result;
    if(result.data.day_availability_saved!==true||result.data.progress_retained!==true||
       result.data.does_not_replace_current_week!==true||
       result.data.availability_revision!==dayRevision+1) return fail('invalid_save_contract');
    return result;
  }
  internal.weeklyDayHours=Object.freeze({version:VERSION,decorate,read,save,
    invalidMessage:()=>copy().invalid,refreshMessage:()=>copy().refresh});
})();
