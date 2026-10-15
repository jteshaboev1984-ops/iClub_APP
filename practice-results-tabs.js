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
      if(data?.ok===true&&count>2){
        const link=node('button','iclub-sx-history-link',
          locale==='uz'?'Yana ko‘rish':locale==='en'?'Show more':'Показать ещё');
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
    for(const attempt of (Array.isArray(data.recent)?data.recent.slice(0,compact?2:5):[])){
      if(score(attempt)==='—')continue;
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
      icon.setAttribute('aria-hidden','true');
      button.prepend(icon);
      right.append(node('span','iclub-topic-history-row-score '+state,score(attempt)));
      right.append(node('span','iclub-topic-history-arrow','›'));
      button.append(info,right);
      button.addEventListener('click',()=>openTopicAttempt(attempt,data.subject_key));
      list.append(button);
    }
    holder.append(list);
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
      const summary=node('summary','iclub-sx-attempt-question-head');
      summary.append(node('span','iclub-sx-attempt-question-no',String(i+1)));
      summary.append(node('span','iclub-sx-attempt-question-label',
        stem||tr('Вопрос','Savol','Question')));
      const chevron=node('span','iclub-sx-attempt-question-arrow','⌄');
      chevron.setAttribute('aria-hidden','true');
      summary.append(chevron);
      card.append(summary);
      const detail=node('div','iclub-sx-attempt-question-body');
      // The collapsed summary already contains the question. Repeat the full
      // version only when it is long enough to be truncated there.
      if(stem.length>90)detail.append(node('p','iclub-sx-attempt-question-full',stem));
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
