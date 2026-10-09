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
