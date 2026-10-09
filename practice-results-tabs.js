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
    for (const [label,value] of [
      [c.correct,correct+' / '+total],
      [c.mistakes,errors],
      [c.duration,time],
      [c.topics,topics]
    ]) {
      const card = node('div','iclub-result-metric');
      card.append(node('span','iclub-result-metric-label',label),
                  node('strong','iclub-result-metric-value',value));
      metrics.append(card);
    }
    meta.className='iclub-result-overview';
    meta.replaceChildren(hero,metrics);
    return true;
  }
  function topicHistory(holder, data, unavailable, language) {
    if (!holder) return false;
    const locale = ['ru','uz','en'].includes(language) ? language : lang();
    const c = HISTORY_COPY[locale];
    holder.replaceChildren();
    if (unavailable || !data || data.ok!==true) {
      holder.append(node('div','iclub-topic-history-empty',c.error));
      return false;
    }
    const count = Math.max(0, Math.trunc(Number(data.completed_sessions)||0));
    if (!count) {
      holder.append(node('div','iclub-topic-history-empty',c.empty));
      return true;
    }
    const heading=node('div','iclub-topic-history-header');
    heading.append(node('strong','',c.heading),
      node('span','iclub-topic-history-count',count+' '+c.attempts));
    holder.append(heading);
    const metrics=node('div','iclub-topic-history-metrics');
    const safeScore = row => {
      if (!row || !Number.isInteger(Number(row.correct)) || !Number.isInteger(Number(row.total))) return '—';
      const yes=Number(row.correct),all=Number(row.total);
      return yes>=0 && all>0 && yes<=all ? yes+' / '+all : '—';
    };
    for (const [label,value] of [
      [c.last,safeScore(data.last)],[c.best,safeScore(data.best)],
      [c.cumulative,String(Math.max(0,Number(data.total_correct_answers)||0))+' / '+
        String(Math.max(0,Number(data.total_answered)||0))]
    ]) {
      const card=node('div','iclub-topic-history-metric');
      card.append(node('span','',label),node('strong','',value));
      metrics.append(card);
    }
    holder.append(metrics);
    const recent=Array.isArray(data.recent)?data.recent.slice(0,5):[];
    if (recent.length) {
      holder.append(node('div','iclub-topic-history-recent-label',c.recent));
      const list=node('div','iclub-topic-history-recent');
      for(const attempt of recent) {
        if(safeScore(attempt)==='—') continue;
        const row=node('div','iclub-topic-history-row');
        const info=node('div','iclub-topic-history-row-info');
        info.append(node('strong','',String(attempt.topic||c.heading).slice(0,200)));
        const date=new Date(String(attempt.finished_at||''));
        if(Number.isFinite(date.getTime())) info.append(node('small','',date.toLocaleDateString(locale)));
        row.append(info,node('span','iclub-topic-history-row-score',safeScore(attempt)));
        list.append(row);
      }
      holder.append(list);
    }
    return true;
  }
  window.iClubPracticePremiumResult = Object.freeze({render:premiumResult});
  window.iClubPracticeTopicHistoryV1 = Object.freeze({render:topicHistory});

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
