(function(){
  'use strict';
  const $=id=>document.getElementById(id);
  const set=(id,value)=>{const n=$(id);if(n&&n.textContent!==value)n.textContent=value};
  const COPY={
    ru:{competitive:'Соревновательный',mentor:'ВАШ МЕНТОР',content:'Контент',practice:'Практика',tours:'Туры',resources:'Ресурсы',video:'Видео-уроки',videoSub:'Видео-уроки доступны в Telegram',recs:'Мои рекомендации',recsSub:'Повторный доступ к чтению',aiSection:'AI-возможности',system:'Системные',cert:'Сертификаты',certSub:'Туры и финальные результаты',archive:'Архив туров',archiveSub:'Самопроверка • вне рейтинга',all:'Все предметы',allSub:'Каталог предметов',mentorName:'Erkinov Azizbek',mentorSub:'AS Level Economics'},
    en:{competitive:'Competitive',mentor:'YOUR MENTOR',content:'Content',practice:'Practice',tours:'Tours',resources:'Resources',video:'Video lessons',videoSub:'Video lessons are available in Telegram',recs:'My recommendations',recsSub:'Return to saved reading',aiSection:'AI features',system:'System',cert:'Certificates',certSub:'Tours and final results',archive:'Tour archive',archiveSub:'Self-check • outside ranking',all:'All subjects',allSub:'Subject catalogue',mentorName:'Erkinov Azizbek',mentorSub:'AS Level Economics'},
    uz:{competitive:'Musobaqa rejimi',mentor:'SIZNING MENTORINGIZ',content:'Kontent',practice:'Mashq',tours:'Turlar',resources:'Resurslar',video:'Video darslar',videoSub:'Video darslar Telegramda mavjud',recs:'Mening tavsiyalarim',recsSub:'O‘qish materialiga qaytish',aiSection:'AI imkoniyatlari',system:'Tizim',cert:'Sertifikatlar',certSub:'Turlar va yakuniy natijalar',archive:'Turlar arxivi',archiveSub:'O‘zini tekshirish • reytingdan tashqari',all:'Barcha fanlar',allSub:'Fanlar katalogi',mentorName:'Erkinov Azizbek',mentorSub:'AS Level Economics'}
  };
  let built=false;
  function lang(){return COPY[document.documentElement.lang]?document.documentElement.lang:'ru'}
  function x(){return COPY[lang()]}
  function markup(){return `
    <div class="main-hub-head">
      <h1 class="main-hub-title" id="hub-title">Экономика</h1>
      <div class="main-hub-meta" id="hub-subtitle">Соревновательный</div>
      <span id="hub-plan-badge" class="main-hub-hidden-state"></span>
    </div>
    <button class="main-mentor-card" type="button" aria-label="Mentor profile">
      <span class="main-mentor-avatar"><img src="demo-mentor-economics.svg" alt=""></span>
      <span class="main-mentor-copy"><span class="main-mentor-kicker" data-main-copy="mentor"></span><span class="main-mentor-name" data-main-copy="mentorName"></span><span class="main-mentor-sub" data-main-copy="mentorSub"></span></span>
    </button>
    <div class="main-hub-tabs" role="tablist" aria-label="Subject hub tabs">
      <button class="main-hub-tab is-active" type="button" data-main-copy="content"></button>
      <button class="main-hub-tab" type="button" data-main-practice data-main-copy="practice"></button>
      <button class="main-hub-tab" type="button" data-main-copy="tours"></button>
      <button class="main-hub-tab" type="button" data-main-copy="resources"></button>
    </div>
    <div class="main-hub-list">
      <button class="main-nav-row" type="button"><span class="main-nav-icon">▣</span><span class="main-nav-copy"><span class="main-nav-title" data-main-copy="video"></span><span class="main-nav-sub" data-main-copy="videoSub"></span></span><span class="main-nav-arrow">›</span></button>
      <button class="main-nav-row" type="button"><span class="main-nav-icon">▤</span><span class="main-nav-copy"><span class="main-nav-title" data-main-copy="recs"></span><span class="main-nav-sub" data-main-copy="recsSub"></span></span><span class="main-nav-arrow">›</span></button>
    </div>
    <div class="main-hub-section-label" data-main-copy="aiSection"></div>
    <div class="main-hub-list main-hub-paid">
      <button class="main-nav-row" id="main-hub-ai-row" type="button"><span class="main-nav-icon ai-mark-wrap" id="hub-ai-mark"><img src="iclub-ai-mark.svg" alt=""><span class="ai-mark-lock" aria-hidden="true">•</span></span><span class="main-nav-copy"><span class="main-nav-title" id="hub-ai-title"></span><span class="main-nav-sub" id="hub-ai-sub"></span></span><span class="main-nav-right"><span class="main-nav-badge"></span><span class="main-nav-arrow">›</span></span></button>
      <button class="main-nav-row" id="main-hub-diagnostic-row" type="button"><span class="main-nav-icon">7</span><span class="main-nav-copy"><span class="main-nav-title" id="hub-diagnostic-title"></span><span class="main-nav-sub" id="hub-diagnostic-sub"></span></span><span class="main-nav-right"><span class="main-nav-badge" id="main-diagnostic-plan"></span><span class="main-nav-arrow">›</span></span></button>
      <button id="hub-ai-action" class="main-hub-hidden-state" type="button"></button>
      <button id="hub-open-diagnostic" class="main-hub-hidden-state" type="button"></button>
    </div>
    <div class="main-hub-section-label" data-main-copy="system"></div>
    <div class="main-hub-list">
      <button class="main-nav-row" type="button"><span class="main-nav-icon">◆</span><span class="main-nav-copy"><span class="main-nav-title" data-main-copy="cert"></span><span class="main-nav-sub" data-main-copy="certSub"></span></span><span class="main-nav-arrow">›</span></button>
      <button class="main-nav-row" type="button"><span class="main-nav-icon">▰</span><span class="main-nav-copy"><span class="main-nav-title" data-main-copy="archive"></span><span class="main-nav-sub" data-main-copy="archiveSub"></span></span><span class="main-nav-arrow">›</span></button>
      <button class="main-nav-row" type="button"><span class="main-nav-icon">◎</span><span class="main-nav-copy"><span class="main-nav-title" data-main-copy="all"></span><span class="main-nav-sub" data-main-copy="allSub"></span></span><span class="main-nav-arrow">›</span></button>
    </div>
    <div class="main-hub-hidden-state" aria-hidden="true"><span id="demo-profile-name"></span><span id="demo-profile-status"></span><span id="demo-profile-progress-label"></span><span id="hub-tour-label"></span><span id="hub-tour-meta"></span><span id="hub-practice-label"></span><span id="hub-practice-meta"></span><span id="hub-attention-title"></span><span id="hub-attention-copy"></span><span id="hub-history-title"></span><span id="hub-history-sub"></span><span id="hub-history-row-1"></span><span id="hub-history-row-2"></span><span id="hub-history-row-3"></span><span id="hub-history-tabs"></span></div>`}
  function build(){
    const hub=$('subject-hub-screen'); if(!hub||hub.dataset.mainReplica==='1')return false;
    hub.innerHTML=markup(); hub.dataset.mainReplica='1'; hub.classList.add('main-app-hub'); built=true;
    $('main-hub-ai-row')?.addEventListener('click',e=>{e.preventDefault();$('hub-ai-action')?.click()});
    $('main-hub-diagnostic-row')?.addEventListener('click',e=>{e.preventDefault();$('hub-open-diagnostic')?.click()});
    document.querySelector('[data-main-practice]')?.addEventListener('click',e=>{e.preventDefault();$('hub-open-diagnostic')?.click()});
    return true;
  }
  function apply(){
    if(!build()&&!built)return;
    const c=x(),hub=$('subject-hub-screen'); if(!hub)return;
    document.querySelectorAll('[data-main-copy]').forEach(n=>{const k=n.dataset.mainCopy;if(c[k]&&n.textContent!==c[k])n.textContent=c[k]});
    const plan=document.body.dataset.demoPlan||'free';
    const source=window.ICLUB_DEMO_GATE2_COPY?.[lang()]||window.ICLUB_DEMO_GATE2_COPY?.ru||{};
    set('hub-title',source.economics||'Economics');
    set('hub-subtitle',c.competitive);
    set('hub-ai-title',plan==='free'?source.aiFreeTitle:plan==='plus'?source.aiPlusTitle:source.aiProTitle);
    set('hub-ai-sub',plan==='free'?source.aiFreeSub:plan==='plus'?source.aiPlusSub:source.aiProSub);
    set('hub-diagnostic-title',source.currentDiagnosis||'Diagnostic practice');
    set('hub-diagnostic-sub',source.currentDiagnosisSub||'');
    set('main-diagnostic-plan',plan[0].toUpperCase()+plan.slice(1));
  }
  const wait=setInterval(()=>{if(build()){clearInterval(wait);apply()}},20);
  setTimeout(()=>{clearInterval(wait);apply()},1500);
  new MutationObserver(apply).observe(document.documentElement,{attributes:true,attributeFilter:['lang']});
  new MutationObserver(apply).observe(document.body,{attributes:true,attributeFilter:['data-demo-plan']});
  document.addEventListener('click',e=>{if(e.target.closest('.language-btn,[data-demo-plan]'))setTimeout(apply,20)});
})();