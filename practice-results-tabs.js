/* iClub Practice Stage 03: presentation-only tabs. No storage, API or score writes. */
(function () {
  'use strict';
  const COPY = Object.freeze({
    ru: {tours:'По турам', topics:'По темам', resume:'Продолжить попытку'},
    uz: {tours:'Turlar bo‘yicha', topics:'Mavzular bo‘yicha', resume:'Urinishni davom ettirish'},
    en: {tours:'By tour', topics:'By topic', resume:'Resume attempt'}
  });
  const ROOT_ID = 'courses-practice-start';
  const lang = () => {
    const v = String(document.documentElement.lang || 'ru').slice(0,2).toLowerCase();
    return COPY[v] ? v : 'ru';
  };


  const RESULT_COPY = Object.freeze({
    ru: {tour:'По турам',topic:'По темам',drill:'Тренировка',correct:'Правильно',
         mistakes:'Ошибки',duration:'Время',topics:'Темы',outOf:'из',accuracy:'Точность'},
    uz: {tour:'Turlar bo‘yicha',topic:'Mavzular bo‘yicha',drill:'Mashq',correct:'To‘g‘ri',
         mistakes:'Xatolar',duration:'Vaqt',topics:'Mavzular',outOf:'tadan',accuracy:'Aniqlik'},
    en: {tour:'By tour',topic:'By topic',drill:'Practice',correct:'Correct',
         mistakes:'Mistakes',duration:'Time',topics:'Topics',outOf:'of',accuracy:'Accuracy'}
  });
  const HISTORY_COPY = Object.freeze({
    ru: {heading:'История практики по темам',last:'Последний',best:'Лучший',
         cumulative:'Всего правильно',attempts:'попыток',recent:'Последние попытки',
         empty:'Завершённых попыток по темам пока нет.',error:'Не удалось загрузить историю по темам.'},
    uz: {heading:'Mavzular bo‘yicha amaliyot tarixi',last:'So‘nggi',best:'Eng yaxshi',
         cumulative:'Jami to‘g‘ri',attempts:'urinish',recent:'So‘nggi urinishlar',
         empty:'Mavzular bo‘yicha yakunlangan urinishlar hali yo‘q.',error:'Mavzular tarixini yuklab bo‘lmadi.'},
    en: {heading:'Practice by topic history',last:'Latest',best:'Best',
         cumulative:'Total correct',attempts:'attempts',recent:'Recent attempts',
         empty:'No completed topic attempts yet.',error:'Could not load topic practice history.'}
  });
  function node(tag, className, value) {
    const item = document.createElement(tag);
    if (className) item.className = className;
    if (value !== undefined && value !== null) item.textContent = String(value);
    return item;
  }
  function premiumResult({meta,attempt,quiz,wrongCount,topicsCount}) {
    if (!meta || !attempt) return false;
    const c = RESULT_COPY[lang()];
    const total = Math.max(0, Math.trunc(Number(attempt.total) || 0));
    const correct = Math.max(0, Math.min(total, Math.trunc(Number(attempt.score) || 0)));
    const errors = Math.max(0, Math.trunc(Number(wrongCount) || 0));
    const topics = Math.max(0, Math.trunc(Number(topicsCount) || 0));
    const percent = total ? Math.round(100*correct/total) : 0;
    const seconds = Math.max(0, Math.trunc(Number(attempt.durationSec) || 0));
    const time = Math.floor(seconds/60) + ':' + String(seconds%60).padStart(2,'0');
    const topicChoice = quiz?.topicChoiceOrigin === true;
    const mode = topicChoice ? c.topic : (quiz?.drillType ? c.drill : c.tour);
    const suffix = topicChoice ? String(quiz?.recTopic || '').slice(0,90)
      : (!quiz?.drillType ? String(Number(quiz?.practiceTourNo) || 1) : '');
    const hero = node('div','iclub-result-hero');
    const kicker = node('div','iclub-result-kicker');
    kicker.append(node('span','iclub-result-kicker-dot'));
    kicker.append(node('span','',mode + (suffix ? ' · ' + (topicChoice ? suffix : (lang()==='en'?'Tour ':lang()==='uz'?'Tur ':'Тур ')+suffix) : '')));
    const top = node('div','iclub-result-main');
    const score = node('div','iclub-result-score');
    score.append(node('div','iclub-result-score-value',percent + '%'));
    score.append(node('div','iclub-result-score-label',c.accuracy));
    score.append(node('div','iclub-result-score-detail',correct + ' ' + c.outOf + ' ' + total));
    const ring = node('div','iclub-result-ring');
    ring.style.setProperty('--iclub-result-percent',String(percent)+'%');
    ring.setAttribute('aria-hidden','true');
    ring.append(node('div','iclub-result-ring-inner','✓'));
    top.append(score,ring);
    hero.append(kicker,top);
    const metrics = node('div','iclub-result-metrics');
    const visibleMetrics=[
      [c.correct,correct+' / '+total],
      [c.mistakes,errors],
      [c.duration,time]
    ];
    if(!topicChoice) visibleMetrics.push([c.topics,topics]);
    for (const [label,value] of visibleMetrics) {
      const card = node('div','iclub-result-metric');
      card.append(node('span','iclub-result-metric-label',label),
                  node('strong','iclub-result-metric-value',value));
      metrics.append(card);
    }
    meta.className='iclub-result-overview';
    meta.replaceChildren(hero,metrics);
    return true;
  }

  let activeTopicReview=null;
  function openTopicAttempt(attempt,subjectKey) {
    if (!attempt || !String(subjectKey||'').trim()) return;
    activeTopicReview={attempt,subjectKey:String(subjectKey)};
    window.dispatchEvent(new CustomEvent('iclub-practice-open-history-review',{
      detail:{subjectKey:activeTopicReview.subjectKey}
    }));
  }
  function topicHistory(holder,data,unavailable,language,compact=false) {
    if(!holder)return false;
    const locale=['ru','uz','en'].includes(language)?language:lang();
    const c=HISTORY_COPY[locale];
    holder.replaceChildren();
    // The standalone History screen already has its own title and subtitle.
    // Do not repeat them inside the list. The compact preview gets one heading.
    if(compact){
      const heading=node('div','iclub-topic-history-header');
      heading.append(node('strong','',locale==='uz'?'Amaliyot tarixi':
        locale==='en'?'Practice history':'История практики'));
      const count=Math.max(0,Math.trunc(Number(data?.completed_sessions)||0));
      if(data?.ok===true&&count>0){
        const link=node('button','iclub-sx-history-link',
          locale==='uz'?'Ochish':locale==='en'?'Open':'Открыть');
        link.type='button';
        link.addEventListener('click',()=>window.dispatchEvent(
          new CustomEvent('iclub-practice-open-history-list',{
            detail:{subjectKey:String(data.subject_key||'')}
          })));
        heading.append(link);
      }
      holder.append(heading);
    }
    if(unavailable||!data||data.ok!==true){
      holder.append(node('div','iclub-topic-history-empty',c.error));
      return false;
    }
    const count=Math.max(0,Math.trunc(Number(data.completed_sessions)||0));
    if(!count){
      holder.append(node('div','iclub-topic-history-empty',c.empty));
      return true;
    }
    const score=row=>{
      const good=Number(row?.correct),all=Number(row?.total);
      return Number.isInteger(good)&&Number.isInteger(all)&&all>0&&good>=0&&good<=all?good+' / '+all:'—';
    };
    const list=node('div','iclub-topic-history-recent');
    const recentAttempts=Array.isArray(data.recent)?data.recent:[];
    const makeRow=attempt=>{
      if(score(attempt)==='—')return null;
      const button=node('button','iclub-topic-history-row');
      button.type='button';
      button.setAttribute('aria-label',(locale==='ru'?'Разбор: ':locale==='uz'?'Tahlil: ':'Review: ')+String(attempt.topic||'')+', '+score(attempt));
      const info=node('div','iclub-topic-history-row-info');
      info.append(node('strong','',String(attempt.topic||c.heading).slice(0,200)));
      const dt=new Date(String(attempt.finished_at||''));
      if(Number.isFinite(dt.getTime()))info.append(node('small','',dt.toLocaleDateString(locale)));
      const right=node('span','iclub-topic-history-row-meta');
      const ratio=Number(attempt.correct)/Number(attempt.total);
      const state=ratio===1?'good':ratio<=.2?'bad':'neutral';
      const icon=node('span','iclub-sx-history-icon '+state,state==='good'?'✓':state==='bad'?'!':'↺');
      icon.setAttribute('aria-hidden','true');button.prepend(icon);
      right.append(node('span','iclub-topic-history-row-score '+state,score(attempt)));
      right.append(node('span','iclub-topic-history-arrow','›'));
      button.append(info,right);
      button.addEventListener('click',()=>openTopicAttempt(attempt,data.subject_key));
      return button;
    };
    const primary=compact?recentAttempts.slice(1,3):recentAttempts.slice(0,3);
    primary.map(makeRow).filter(Boolean).forEach(row=>list.append(row));
    if(!compact||list.children.length)holder.append(list);
    if(!compact&&recentAttempts.length>3){
      const older=recentAttempts.slice(3);
      const disclosure=node('details','iclub-s2-history-earlier');
      const label=PERIOD_COPY[locale];
      disclosure.append(node('summary','',label.earlier+' ('+older.length+')'));
      const rows=node('div','iclub-topic-history-recent');disclosure.append(rows);
      const more=node('button','iclub-s2-history-more');
      more.type='button';more.hidden=true;disclosure.append(more);
      let shown=0;
      const append=()=>{
        older.slice(shown,shown+5).map(makeRow).filter(Boolean).forEach(row=>rows.append(row));
        shown=Math.min(older.length,shown+5);
        const remaining=older.length-shown;
        more.hidden=remaining===0;
        if(remaining)more.textContent=label.more+' ('+Math.min(5,remaining)+')';
      };
      disclosure.addEventListener('toggle',()=>{if(disclosure.open&&shown===0)append();});
      more.addEventListener('click',append);
      holder.append(disclosure);
    }
    if(!compact&&count>recentAttempts.length){
      holder.append(node('p','iclub-s2-history-note',PERIOD_COPY[locale].partial));
    }
    return true;
  }
  function renderTopicReview(language) {
    const title=document.getElementById('my-rec-topic-review-title');
    const subtitle=document.getElementById('my-rec-topic-review-subtitle');
    const body=document.getElementById('my-rec-topic-review-body');
    if(!body)return false;
    const locale=['ru','uz','en'].includes(language)?language:lang();
    const tr=(ru,uz,en)=>locale==='uz'?uz:locale==='en'?en:ru;
    body.replaceChildren();
    const selected=activeTopicReview;
    if(title)title.textContent=tr('Разбор попытки','Urinish tahlili','Attempt review');
    if(!selected?.attempt){
      if(subtitle)subtitle.textContent='';
      body.append(node('div','iclub-topic-history-empty',
        tr('Выберите попытку в истории практики.','Amaliyot tarixidan urinishni tanlang.','Select an attempt from practice history.')));
      return false;
    }
    const attempt=selected.attempt;
    const topic=String(attempt.topic||'').slice(0,200);
    const correct=Number(attempt.correct),total=Number(attempt.total);
    if(!Number.isInteger(correct)||!Number.isInteger(total)||total<1||correct<0||correct>total){
      body.append(node('div','iclub-topic-history-empty',
        tr('Результат попытки недоступен.','Urinish natijasi mavjud emas.','This attempt result is unavailable.')));
      return false;
    }
    const errorCount=Number(attempt.mistakes);
    const mistakes=Number.isInteger(errorCount)&&errorCount>=0&&errorCount<=total?errorCount:total-correct;
    const errorsNoun=n=>locale==='ru'
      ? (n%10===1&&n%100!==11?'ошибка':
         n%10>=2&&n%10<=4&&!(n%100>=12&&n%100<=14)?'ошибки':'ошибок')
      :locale==='uz'?'xato':n===1?'mistake':'mistakes';
    const date=new Date(String(attempt.finished_at||''));
    const printedDate=Number.isFinite(date.getTime())?date.toLocaleDateString(locale):'';
    const percent=Math.round(correct*100/total);
    if(subtitle)subtitle.textContent='';
    const intro=node('header','iclub-sx-attempt-intro');
    intro.append(node('span','iclub-sx-kicker',tr('ЗАВЕРШЁННАЯ ПОПЫТКА','YAKUNLANGAN URINISH','COMPLETED ATTEMPT')+
      (printedDate?' · '+printedDate:'')));
    intro.append(node('h2','iclub-sx-attempt-title',topic||tr('Практика по темам','Mavzular bo‘yicha amaliyot','Practice by topic')));
    intro.append(node('p','iclub-sx-attempt-mode',
      tr('По темам','Mavzular bo‘yicha','By topic')+' · '+total+' '+tr('вопросов','savol','questions')));
    body.append(intro);

    const panel=node('section','iclub-sx-attempt-panel');
    const metrics=node('div','iclub-sx-attempt-metrics');
    const left=node('div','iclub-sx-attempt-score');
    left.append(node('span','iclub-sx-kicker',tr('ИТОГОВЫЙ РЕЗУЛЬТАТ','YAKUNIY NATIJA','FINAL RESULT')));
    const big=node('strong','iclub-sx-attempt-number',correct+'/'+total);
    if(mistakes===0)big.classList.add('good');
    left.append(big);
    left.append(node('span','iclub-sx-attempt-percent',percent+'% '+
      tr('правильных ответов','to‘g‘ri javoblar','correct answers')));
    const emblem=node('div','iclub-sx-attempt-emblem'+(mistakes===0?' good':''),mistakes?'!':'✓');
    emblem.setAttribute('aria-hidden','true');
    metrics.append(left,emblem);panel.append(metrics);
    const chips=node('div','iclub-sx-attempt-chips');
    chips.append(node('span','iclub-sx-attempt-chip'+(mistakes?' bad':' good'),mistakes+' '+errorsNoun(mistakes)));
    panel.append(chips);

    const saved=Array.isArray(attempt.review)?attempt.review:[];
    const wrongIds=Array.from(new Set(saved.map(d=>Number(d.question_id||0))
      .filter(id=>Number.isSafeInteger(id)&&id>0))).slice(0,10);
    const sessionId=Number(attempt.session_id||0);
    const canRetry=mistakes>0&&wrongIds.length>0&&Number.isSafeInteger(sessionId)&&sessionId>0;
    if(canRetry){
      const retryNoun=locale==='ru'
        ?(wrongIds.length%10===1&&wrongIds.length%100!==11?'ошибку':errorsNoun(wrongIds.length))
        :errorsNoun(wrongIds.length);
      const retry=node('button','btn primary iclub-sx-attempt-retry',
        tr('Исправить ','Tuzatish: ','Correct ')+wrongIds.length+' '+retryNoun);
      retry.type='button';
      retry.addEventListener('click',()=>{
        window.dispatchEvent(new CustomEvent('iclub-practice-correct-history',{
          detail:{subjectKey:selected.subjectKey,sourceSessionId:sessionId,questionIds:wrongIds,topic}
        }));
      });
      panel.append(retry);
    }
    const note=node('div','iclub-sx-attempt-note',mistakes
      ?tr('Исправление запускает отдельную тренировку. Исходный результат остаётся без изменений.',
          'Tuzatish alohida mashg‘ulotni boshlaydi. Dastlabki natija o‘zgarmaydi.',
          'Correction starts a separate practice session. The original result stays unchanged.')
      :tr('В этой попытке ошибок не было. Результат сохранён в истории.',
          'Bu urinishda xato yo‘q. Natija tarixda saqlangan.',
          'No mistakes in this attempt. The result remains in history.'));
    panel.append(note);
    body.append(panel);

    const heading=node('div','iclub-sx-attempt-list-head');
    heading.append(node('h3','',mistakes
      ?tr('Разбор ошибок','Xatolar tahlili','Mistake review')
      :tr('Разбор попытки','Urinish tahlili','Attempt review')));
    body.append(heading);
    if(!mistakes){
      body.append(node('div','iclub-sx-attempt-empty',
        tr('Все ответы правильные. Исправлять нечего.',
          'Barcha javoblar to‘g‘ri. Tuzatish kerak emas.',
          'All answers were correct. No mistakes to correct.')));
      return true;
    }
    if(!saved.length){
      body.append(node('div','iclub-sx-attempt-empty',
        tr('Разбор этой попытки сейчас недоступен.',
          'Bu urinish tahlili hozircha mavjud emas.',
          'This attempt review is currently unavailable.')));
      return true;
    }
    if(saved.length<mistakes)body.append(node('p','iclub-sx-attempt-partial',
      tr('Часть старых вопросов недоступна для разбора.',
        'Ba’zi eski savollar tahlil uchun mavjud emas.',
        'Some older questions cannot be reviewed.')));
    const questions=node('div','iclub-sx-attempt-questions');
    for(let i=0;i<saved.length;i++){
      const d=saved[i];
      const stem=String(d['question_'+locale]||d.question_en||'').trim();
      const raw=d['options_'+locale]||d.options_en||'';
      let options=[];
      try{const values=typeof raw==='string'?JSON.parse(raw):raw;if(Array.isArray(values))options=values;}catch{}
      const answer=value=>{
        const key=String(value??'').trim();
        const ix=/^[A-Z]$/i.test(key)?key.toUpperCase().charCodeAt(0)-65:-1;
        return ix>=0&&ix<options.length?key+' — '+String(options[ix]):key||'—';
      };
      const card=node('details','iclub-sx-attempt-question');
      if(i===0)card.open=true;
      const summary=node('summary','iclub-sx-attempt-question-head');
      summary.append(node('span','iclub-sx-attempt-question-no',String(i+1)));
      summary.append(node('span','iclub-sx-attempt-question-label',
        stem||tr('Вопрос','Savol','Question')));
      const chevron=node('span','iclub-sx-attempt-question-arrow','⌄');
      chevron.setAttribute('aria-hidden','true');
      summary.append(chevron);
      card.append(summary);
      const detail=node('div','iclub-sx-attempt-question-body');
      const wrong=node('div','iclub-sx-attempt-answer bad');
      wrong.append(node('strong','',tr('ВАШ ОТВЕТ','SIZNING JAVOBINGIZ','YOUR ANSWER')));
      wrong.append(node('div','',answer(d.user_answer)));
      detail.append(wrong);
      const correctAnswer=node('div','iclub-sx-attempt-answer good');
      correctAnswer.append(node('strong','',tr('ПРАВИЛЬНЫЙ ОТВЕТ','TO‘G‘RI JAVOB','CORRECT ANSWER')));
      correctAnswer.append(node('div','',answer(d.correct_answer)));
      detail.append(correctAnswer);
      const why=d['feedback_'+locale]||d['explanation_'+locale]||d.explanation_en||'';
      if(why){
        const explanation=node('div','iclub-sx-attempt-explanation');
        explanation.append(node('strong','',tr('Пояснение','Izoh','Explanation')));
        explanation.append(node('div','',String(why)));
        detail.append(explanation);
      }
      card.append(detail);
      questions.append(card);
    }
    body.append(questions);
    return true;
  }
  function topicLatest(holder,data,unavailable,language) {
    if(!holder)return false;
    holder.replaceChildren();
    if(unavailable||data?.ok!==true)return false;
    const attempt=data.last?.total?data.last:(Array.isArray(data.recent)?data.recent[0]:null);
    const correct=Number(attempt?.correct),total=Number(attempt?.total);
    if(!Number.isInteger(correct)||!Number.isInteger(total)||total<=0||correct<0||correct>total)return false;
    const locale=['ru','uz','en'].includes(language)?language:lang();
    const txt=(ru,uz,en)=>locale==='uz'?uz:locale==='en'?en:ru;
    const card=node('section','iclub-sx-last');
    const head=node('div','iclub-sx-last-head');
    head.append(node('span','iclub-sx-kicker',txt('ПОСЛЕДНЯЯ ПОПЫТКА','OXIRGI URINISH','LATEST ATTEMPT')));
    const dt=new Date(String(attempt.finished_at||''));
    if(Number.isFinite(dt.getTime()))head.append(node('small','',dt.toLocaleDateString(locale)));
    card.append(head);
    const middle=node('div','iclub-sx-last-body');
    const left=node('div','iclub-sx-last-info');
    left.append(node('strong','',String(attempt.topic||'—')));
    left.append(node('small','',txt('Практика по темам','Mavzular bo‘yicha amaliyot','Practice by topic')+' · '+total+' '+txt('вопросов','savol','questions')));
    const score=node('span','iclub-sx-last-result',correct+' / '+total);
    if(correct===total)score.classList.add('good');
    else if(correct/total<0.3)score.classList.add('bad');
    middle.append(left,score);card.append(middle);
    const footer=node('div','iclub-sx-last-footer');
    const errors=total-correct;
    const noun=locale==='ru'?
      (errors%10===1&&errors%100!==11?'ошибка':
       errors%10>=2&&errors%10<=4&&!(errors%100>=12&&errors%100<=14)?'ошибки':'ошибок'):
       txt('ошибок','xato',errors===1?'mistake':'mistakes');
    footer.append(node('span','iclub-sx-last-errors',errors+' '+noun));
    const link=node('button','iclub-sx-link',txt('Разбор попытки','Urinishni tahlil qilish','Review attempt')+' →');
    link.type='button';link.addEventListener('click',()=>openTopicAttempt(attempt,data.subject_key));
    footer.append(link);card.append(footer);holder.append(card);
    return true;
  }
  function topicHistoryPage(language,subjectKey,data,unavailable=false) {
    const holder=document.getElementById('my-rec-topic-history-body');
    if(!holder)return false;
    const title=document.getElementById('my-rec-topic-history-title');
    const subtitle=document.getElementById('my-rec-topic-history-subtitle');
    if(title)title.textContent=language==='uz'?'Amaliyot tarixi':language==='en'?'Practice history':'История практики';
    if(subtitle)subtitle.textContent=language==='uz'?'So‘nggi yakunlangan urinishlar':
      language==='en'?'Recent completed attempts':'Последние завершённые попытки';
    if(unavailable||data?.ok!==true||String(data.subject_key||'')!==String(subjectKey||'')){
      holder.replaceChildren(node('div','iclub-topic-history-empty',
        language==='uz'?'Tarixni yuklab bo‘lmadi. Keyinroq qayta urinib ko‘ring.':
        language==='en'?'Could not load history. Please retry later.':
        'Не удалось загрузить историю. Попробуйте ещё раз позже.'));
      return false;
    }
    return topicHistory(holder,data,false,language,false);
  }
    window.iClubPracticePremiumResult = Object.freeze({render:premiumResult});
  window.iClubPracticeTopicHistoryV1 = Object.freeze({render:topicHistory,renderReview:renderTopicReview,renderLatest:topicLatest,renderHistoryPage:topicHistoryPage,openAttempt:openTopicAttempt});

  // Presentation-only view for completed ordinary Practice by Tour sessions.
  // The caller fetches authenticated history. Never join these rows to recommendations.
  const tourRecTexts={
    ru:{last:'ПОСЛЕДНЯЯ ПОПЫТКА',tour:'Тур ',practice:'Практика по туру',
      emptyTitle:'Результаты практики по турам',empty:'После завершённой попытки здесь появится её результат.',
      unavailable:'Не удалось загрузить результаты практики. Рекомендации доступны ниже.',
      history:'История практики по турам',previous:'Предыдущие завершённые попытки',
      more:'Показать ещё'},
    uz:{last:'SO‘NGGI URINISH',tour:'Tur ',practice:'Tur bo‘yicha amaliyot',
      emptyTitle:'Turlar bo‘yicha amaliyot natijalari',empty:'Yakunlangan urinishdan so‘ng natija shu yerda ko‘rinadi.',
      unavailable:'Amaliyot natijalarini yuklab bo‘lmadi. Tavsiyalar quyida mavjud.',
      history:'Turlar bo‘yicha amaliyot tarixi',previous:'Oldingi yakunlangan urinishlar',
      more:'Yana ko‘rsatish'},
    en:{last:'LATEST ATTEMPT',tour:'Tour ',practice:'Practice by tour',
      emptyTitle:'Practice by tour results',empty:'Your result will appear here after a completed attempt.',
      unavailable:'Could not load Practice results. Recommendations remain available below.',
      history:'Practice by tour history',previous:'Previous completed attempts',more:'Show more'}
  };
  const tourRecLang=language=>['ru','uz','en'].includes(language)?language:lang();
  function tourRecRows(data){
    return (Array.isArray(data?.last)?data.last:[]).filter(row=>{
      const no=Number(row?.tour_no);
      return Number.isSafeInteger(no)&&no>0&&Number.isFinite(Date.parse(String(row?.created_at||'')));
    });
  }
  function tourRecScore(row){
    const total=Number(row?.answers_total);
    const score=row?.score==null?NaN:Number(row.score);
    const pct=row?.percent==null?NaN:Number(row.percent);
    if(Number.isInteger(total)&&total>0&&Number.isInteger(score)&&score>=0&&score<=total)
      return score+' / '+total;
    return Number.isFinite(pct)&&pct>=0&&pct<=100?Math.round(pct)+'%':'—';
  }
  function tourRecDate(row,language){
    const d=new Date(String(row?.created_at||''));
    if(!Number.isFinite(d.getTime()))return '';
    try{return d.toLocaleDateString(language==='en'?'en-GB':language==='uz'?'uz-UZ':'ru-RU');}
    catch{return '';}
  }
  function tourRecLatest(holder,data,unavailable,language){
    if(!holder)return false;
    holder.replaceChildren();
    const locale=tourRecLang(language),t=tourRecTexts[locale];
    if(unavailable||data?.ok!==true){
      holder.append(node('p','iclub-sx-tour-unavailable',t.unavailable));
      return false;
    }
    const rows=tourRecRows(data);
    const card=node('section','iclub-sx-tour-last');
    if(!rows.length){
      card.classList.add('iclub-sx-tour-last-empty');
      card.append(node('strong','',t.emptyTitle),node('p','',t.empty));
      holder.append(card);
      return true;
    }
    const latest=rows[0];
    const top=node('div','iclub-sx-tour-last-top');
    top.append(node('span','iclub-sx-kicker',t.last));
    top.append(node('small','',tourRecDate(latest,locale)));
    const middle=node('div','iclub-sx-tour-last-body');
    const info=node('div','iclub-sx-tour-last-info');
    info.append(node('strong','',t.tour+String(latest.tour_no)));
    info.append(node('span','',t.practice));
    middle.append(info,node('strong','iclub-sx-tour-last-score',tourRecScore(latest)));
    card.append(top,middle);
    const pct=latest.percent==null?NaN:Number(latest.percent);
    const seconds=latest.time_seconds==null?NaN:Number(latest.time_seconds);
    if((Number.isFinite(pct)&&pct>=0&&pct<=100)||(Number.isFinite(seconds)&&seconds>=0)){
      const foot=node('div','iclub-sx-tour-last-foot');
      if(Number.isFinite(pct)&&pct>=0&&pct<=100)
        foot.append(node('span','',Math.round(pct)+'%'));
      if(Number.isFinite(seconds)&&seconds>=0)
        foot.append(node('span','',Math.floor(seconds/60)+':'+String(Math.round(seconds%60)).padStart(2,'0')));
      card.append(foot);
    }
    holder.append(card);
    return true;
  }
  function tourRecHistory(holder,data,unavailable,language){
    if(!holder)return false;
    holder.replaceChildren();
    const rows=!unavailable&&data?.ok===true?tourRecRows(data):[];
    const past=rows.slice(1);
    holder.hidden=!past.length;
    if(!past.length)return false;
    const locale=tourRecLang(language),t=tourRecTexts[locale];
    const section=node('div','iclub-sx-tour-history');
    section.dataset.sxTourGroup='1';
    section.append(node('h2','',t.history),node('p','',t.previous));
    const list=node('div','iclub-sx-tour-history-list');
    const appendRow=(item,i,holder)=>{
      const row=node('div','iclub-sx-tour-history-row');
      row.append(node('span','iclub-sx-tour-history-index',String(i+1).padStart(2,'0')));
      const middle=node('span','iclub-sx-tour-history-description');
      middle.append(node('strong','',t.tour+String(item.tour_no)));
      middle.append(node('small','',tourRecDate(item,locale)));
      row.append(middle,node('strong','iclub-sx-tour-history-score',tourRecScore(item)));
      holder.append(row);
    };
    past.slice(0,3).forEach((row,i)=>appendRow(row,i,list));
    section.append(list);
    if(past.length>3){
      const older=past.slice(3),label=PERIOD_COPY[locale];
      const disclosure=node('details','iclub-s2-history-earlier');
      disclosure.append(node('summary','',label.earlier+' ('+older.length+')'));
      const rows=node('div','iclub-sx-tour-history-list');disclosure.append(rows);
      const more=node('button','iclub-s2-history-more');
      more.type='button';more.hidden=true;disclosure.append(more);
      let shown=0;
      const append=()=>{
        older.slice(shown,shown+5).forEach((item,i)=>appendRow(item,shown+i+3,rows));
        shown=Math.min(older.length,shown+5);
        const remaining=older.length-shown;
        more.hidden=remaining===0;
        if(remaining)more.textContent=label.more+' ('+Math.min(5,remaining)+')';
      };
      disclosure.addEventListener('toggle',()=>{if(disclosure.open&&shown===0)append();});
      more.addEventListener('click',append);
      section.append(disclosure);
    }
    const total=Number(data.attempts_count);
    if(Number.isInteger(total)&&total>rows.length){
      section.append(node('p','iclub-s2-history-note',PERIOD_COPY[locale].partial));
    }
    holder.append(section);
    return true;
  }
  window.iClubPracticeTourHistoryV1=Object.freeze({render:tourRecHistory,renderLatest:tourRecLatest});


  // Season 2 Practice history follows the ACCEPTED Mathematics Exam Prep approach:
  // 3 recent items, native <details> for older, five more per click.
  // Server returns at most 20 rows per lane; this is NOT cursor pagination.
  // Read-only; no action here creates/regrades/deletes an attempt.
  const PERIOD_COPY={
    ru:{title:'История практики · Сезон 2',since:'Отсчёт с',current:'Новые результаты',
      previous:'Предыдущие сезоны',earlier:'Более ранние записи',
      more:'Показать ещё',partial:'Показаны только последние записи. Остальные результаты сохранены в истории.',
      empty:'В новом сезоне пока нет завершённых попыток.',
      main:'Практика по турам',topic:'Практика по темам',attempts:'попыток'},
    uz:{title:'Amaliyot tarixi · 2-mavsum',since:'Boshlanish sanasi',current:'Yangi natijalar',
      previous:'Oldingi mavsumlar',earlier:'Avvalgi natijalar',
      more:'Yana ko‘rsatish',partial:'Faqat so‘nggi natijalar ko‘rsatilmoqda. Qolganlari tarixda saqlangan.',
      empty:'Yangi mavsumda hali yakunlangan urinishlar yo‘q.',
      main:'Turlar bo‘yicha amaliyot',topic:'Mavzular bo‘yicha amaliyot',attempts:'urinish'},
    en:{title:'Practice history · Season 2',since:'Counting from',current:'New results',
      previous:'Previous seasons',earlier:'Earlier entries',
      more:'Show more',partial:'Only recent entries are shown. Older results remain in history.',
      empty:'No completed attempts this season yet.',
      main:'Practice by tour',topic:'Practice by topic',attempts:'attempts'}
  };
  function renderSeason2Period(period,subjectKey,language){
    const root=document.getElementById(ROOT_ID);
    if(!root)return false;
    const holders=['tours','topics'].map(key=>root.querySelector('[data-practice-s2-history="'+key+'"]'));
    const valid=period?.ok===true&&period?.period_active===true&&
      String(period.subject_key||'')===String(subjectKey||'');
    root.dataset.practiceS2Active=valid?'true':'false';
    holders.forEach(holder=>{if(holder){holder.replaceChildren();holder.hidden=!valid;}});
    if(!valid)return false;
    const locale=['ru','uz','en'].includes(language)?language:lang();
    const c=PERIOD_COPY[locale],fmt=stamp=>{
      const d=new Date(String(stamp||''));
      return Number.isFinite(d.getTime())?
        d.toLocaleDateString(locale==='en'?'en-GB':locale==='uz'?'uz-UZ':'ru-RU',{timeZone:'Asia/Tashkent'}):'';
    };
    function item(row,kind){
      const el=node('div','iclub-s2-history-row');
      const left=node('span','iclub-s2-history-row-left');
      const topic=kind==='topics'?String(row?.topic||c.topic).slice(0,120):c.main;
      left.append(node('strong','',topic),node('small','',fmt(row?.created_at)));
      const right=node('span','iclub-s2-history-score');
      if(kind==='topics'){
        const score=Number(row?.correct),total=Number(row?.total);
        right.textContent=Number.isInteger(score)&&Number.isInteger(total)&&total>0&&score>=0&&score<=total?
          score+' / '+total:'—';
      }else{
        const percent=Number(row?.percent);
        right.textContent=row?.percent!=null&&Number.isFinite(percent)&&percent>=0&&percent<=100?
          Math.round(percent)+'%':'—';
      }
      el.append(left,right);return el;
    }
    function appendLimited(holder,rows,offset,n,kind){
      for(const row of rows.slice(offset,offset+n))holder.append(item(row,kind));
    }
    function historyGroup(container,rows,total,heading,kind,collapsed){
      const size=Math.max(0,Math.trunc(Number(total)||0));
      const sample=Array.isArray(rows)?rows.slice(0,20):[];
      if(collapsed&&size===0)return;
      const main=collapsed?node('details','iclub-s2-history-archive'):node('div','iclub-s2-history-current');
      const title=collapsed?node('summary','iclub-s2-history-caption',heading+' · '+size):
        node('strong','iclub-s2-history-caption',heading+' · '+size);
      main.append(title);
      const body=node('div','iclub-s2-history-rows');
      main.append(body);
      let initialized=false,shown=0;
      const draw=()=>{
        if(initialized)return;
        initialized=true;
        appendLimited(body,sample,0,3,kind);shown=Math.min(3,sample.length);
        if(!sample.length)body.append(node('p','iclub-s2-history-empty',c.empty));
        if(sample.length>3){
          const earlier=node('details','iclub-s2-history-earlier');
          earlier.append(node('summary','',c.earlier+' ('+(sample.length-3)+')'));
          const older=node('div','iclub-s2-history-rows');earlier.append(older);
          const more=node('button','iclub-s2-history-more');
          more.type='button';more.hidden=true;earlier.append(more);
          let displayed=0;
          const append=()=>{
            const batch=sample.slice(3+displayed,3+displayed+5);
            batch.forEach(row=>older.append(item(row,kind)));
            displayed+=batch.length;
            const left=sample.length-3-displayed;
            more.hidden=left<=0;
            if(left>0)more.textContent=c.more+' ('+Math.min(5,left)+')';
          };
          earlier.addEventListener('toggle',()=>{if(earlier.open&&displayed===0)append();});
          more.addEventListener('click',append);
          main.append(earlier);
        }
        if(size>sample.length)main.append(node('p','iclub-s2-history-note',c.partial));
      };
      if(collapsed)main.addEventListener('toggle',()=>{if(main.open)draw();});
      else draw();
      container.append(main);
    }
    for(const [idx,kind] of ['tours','topics'].entries()){
      const holder=holders[idx];if(!holder)continue;
      const source=kind==='tours'?period.main:period.topic;
      const count=kind==='tours'?source?.attempts_count:source?.sessions_count;
      const prev=kind==='tours'?source?.archived_attempts_count:source?.archived_sessions_count;
      const block=node('section','iclub-s2-history-block');
      block.append(node('h2','iclub-s2-history-title',c.title));
      const start=fmt(period.period_starts_at);
      if(start)block.append(node('p','iclub-s2-history-note',c.since+' '+start));
      historyGroup(block,source?.recent,count,c.current,kind,false);
      historyGroup(block,source?.archived_recent,prev,c.previous,kind,true);
      holder.append(block);
    }
    return true;
  }
  window.iClubPracticeSeason2HistoryV1=Object.freeze({render:renderSeason2Period});

  function install() {
    const root = document.getElementById(ROOT_ID);
    if (!root || root.dataset.practiceResultsTabsReady === 'true') return;
    const picker = root.querySelector('#practice-tour-picker');
    const hero = root.querySelector('.practice-hero');
    const last = root.querySelector('.practice-last');
    const actions = root.querySelector('.practice-start-actions');
    const topics = root.querySelector('#practice-topic-choice');
    if (![picker,hero,last,actions,topics].every(Boolean)) return;

    const bar = document.createElement('div');
    bar.className = 'practice-results-tabs';
    bar.setAttribute('role','tablist');
    bar.setAttribute('aria-label','Practice results');
    const create = (id,panel) => {
      const b = document.createElement('button');
      b.id=id; b.type='button'; b.className='practice-results-tab';
      b.setAttribute('role','tab'); b.setAttribute('aria-controls',panel);
      return b;
    };
    const tourTab = create('practice-results-tab-tours','practice-results-panel-tours');
    const topicTab = create('practice-results-tab-topics','practice-results-panel-topics');
    bar.append(tourTab,topicTab);
    root.insertBefore(bar,picker);

    const tourPanel=document.createElement('section');
    tourPanel.id='practice-results-panel-tours';
    tourPanel.className='practice-results-panel';
    tourPanel.setAttribute('role','tabpanel');
    tourPanel.setAttribute('aria-labelledby',tourTab.id);
    root.insertBefore(tourPanel,picker);
    [picker,hero,last,actions].forEach(el=>tourPanel.appendChild(el));
    const tourSeasonHistory=node('div','iclub-s2-history');
    tourSeasonHistory.dataset.practiceS2History='tours';
    tourSeasonHistory.hidden=true;
    tourPanel.append(tourSeasonHistory);

    const topicPanel=document.createElement('section');
    topicPanel.id='practice-results-panel-topics';
    topicPanel.className='practice-results-panel';
    topicPanel.setAttribute('role','tabpanel');
    topicPanel.setAttribute('aria-labelledby',topicTab.id);
    root.insertBefore(topicPanel,tourPanel.nextSibling);
    const resumed=document.createElement('button');
    resumed.id='practice-topic-resume-btn';
    resumed.className='btn practice-topic-resume';
    resumed.type='button';
    resumed.setAttribute('data-action','practice-resume');
    resumed.hidden=true;
    topicPanel.append(resumed,topics);
    const topicSeasonHistory=node('div','iclub-s2-history');
    topicSeasonHistory.dataset.practiceS2History='topics';
    topicSeasonHistory.hidden=true;
    topicPanel.append(topicSeasonHistory);
    const realResume=document.getElementById('practice-resume-btn');
    const syncResume=()=>{
      const visible=realResume && realResume.style.display !== 'none' && !realResume.disabled;
      resumed.hidden=!visible;
      resumed.textContent=COPY[lang()].resume;
    };
    if (realResume) new MutationObserver(syncResume).observe(realResume,{attributes:true,attributeFilter:['style','disabled']});

    let active='tours';
    const label=()=>{
      const c=COPY[lang()];
      tourTab.textContent=c.tours; topicTab.textContent=c.topics;
      syncResume();
    };
    const centerSelected=()=>{
      if (active!=='tours') return;
      const row=picker.querySelector('.practice-tour-chip-row');
      const selected=row?.querySelector('.practice-tour-chip.is-selected');
      if (!row || !selected || !row.clientWidth) return;
      const outer=row.getBoundingClientRect(), inner=selected.getBoundingClientRect();
      row.scrollLeft += inner.left-outer.left-(row.clientWidth-selected.clientWidth)/2;
    };
    const openTopics=()=>{
      if (active!=='topics') return;
      const toggle=topics.querySelector('.practice-topic-choice-toggle');
      if (toggle?.getAttribute('aria-expanded')==='false') toggle.click();
    };
    function choose(next,focus=false) {
      active=next;
      root.dataset.practiceResultsMode=next;
      const isTours=next==='tours';
      tourPanel.hidden=!isTours; topicPanel.hidden=isTours;
      for (const [button,selected] of [[tourTab,isTours],[topicTab,!isTours]]) {
        button.setAttribute('aria-selected',String(selected));
        button.tabIndex=selected?0:-1;
      }
      if (focus) (isTours?tourTab:topicTab).focus();
      if (isTours) requestAnimationFrame(centerSelected);
      else openTopics();
      syncResume();
    }
    tourTab.addEventListener('click',()=>choose('tours'));
    topicTab.addEventListener('click',()=>choose('topics'));
    bar.addEventListener('keydown',event=>{
      if (!['ArrowLeft','ArrowRight','Home','End'].includes(event.key)) return;
      event.preventDefault();
      const next=(event.key==='Home'||event.key==='ArrowLeft')?'tours':'topics';
      choose(next,true);
    });
    new MutationObserver(()=>requestAnimationFrame(centerSelected))
      .observe(picker,{childList:true});
    new MutationObserver(openTopics).observe(topics,{childList:true});
    new MutationObserver(label).observe(document.documentElement,{attributes:true,attributeFilter:['lang']});
    root.dataset.practiceResultsTabsReady='true';
    label();
    choose('tours');
  }
  if (document.readyState==='loading') document.addEventListener('DOMContentLoaded',install,{once:true});
  else install();
})();
