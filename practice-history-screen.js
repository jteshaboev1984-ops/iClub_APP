/* #574 — Practice History viewer, source-only Academy OS candidate.
 * Read-only visual state; never starts attempts or invents a season from a date.
 * The host Courses stack owns its only Back control.
 */
(function(){
  'use strict';
  const ROOT_ID='practice-history-content';
  const COPY={
    ru:{title:'История практики',subtitle:'Результаты тренировок по турам, темам и сезонам.',
      tours:'По турам',topics:'По темам',season:'Сезон',currentSeason:'Текущий сезон',archive:'Архив прошлых сезонов',
      earlier:'Ранние записи',empty:'В этом разделе пока нет результатов.',
      noData:'История сезонов пока недоступна. Ранее сохранённые попытки не удалены.',
      more:'Показать ещё',limited:'Показаны последние записи. Более ранние результаты сохранены.',
      newer:'К более новому сезону',older:'К более раннему сезону',count:'записей',
      legacyNote:'Записи, для которых не подтверждён официальный сезон.'},
    uz:{title:'Amaliyot tarixi',subtitle:'Mashqlar natijalari turlar, mavzular va mavsumlar bo‘yicha.',
      tours:'Turlar bo‘yicha',topics:'Mavzular bo‘yicha',season:'Mavsum',currentSeason:'Joriy mavsum',archive:'Oldingi mavsumlar arxivi',
      earlier:'Avvalgi natijalar',empty:'Bu bo‘limda hozircha natija yo‘q.',
      noData:'Mavsumlar tarixi hozircha mavjud emas. Oldingi urinishlar o‘chirilmagan.',
      more:'Yana ko‘rsatish',limited:'So‘nggi natijalar ko‘rsatilmoqda. Avvalgilari saqlangan.',
      newer:'Yangiroq mavsumga',older:'Oldinroq mavsumga',count:'natija',
      legacyNote:'Rasmiy mavsumi tasdiqlanmagan avvalgi natijalar.'},
    en:{title:'Practice history',subtitle:'Practice results across tours, topics and seasons.',
      tours:'By tour',topics:'By topic',season:'Season',currentSeason:'Current season',archive:'Previous seasons',
      earlier:'Earlier entries',empty:'No results in this section yet.',
      noData:'Season history is not available yet. Earlier attempts have not been deleted.',
      more:'Show 5 more',limited:'Only recent entries are shown. Older results remain saved.',
      newer:'Newer season',older:'Older season',count:'records',
      legacyNote:'Earlier records without a verified official season.'}
  };
  let source=null,sourceSubject='',language='ru',seasonIndex=0,mode='tours';
  const el=(tag,cl,text)=>{
    const n=document.createElement(tag);
    if(cl)n.className=cl;
    if(text!==undefined)n.textContent=String(text);
    return n;
  };
  const loc=()=>COPY[language]||COPY.ru;
  const positive=(v)=>Math.max(0,Math.trunc(Number(v)||0));
  const date=v=>{
    const dt=new Date(String(v||''));
    return Number.isFinite(dt.getTime())?dt.toLocaleDateString(
      language==='en'?'en-GB':language==='uz'?'uz-UZ':'ru-RU',
      {timeZone:'Asia/Tashkent'}):'';
  };
  const historyData=()=>{
    if(!source?.ok||source.period_active!==true||
      String(source.subject_key||'')!==sourceSubject)return null;
    const currentNo=Number(source.season_no);
    if(!Number.isInteger(currentNo)||currentNo<1)return null;
    const current={key:'season-'+currentNo,no:currentNo,
      tours:{count:positive(source.main?.attempts_count),rows:source.main?.recent||[]},
      topics:{count:positive(source.topic?.sessions_count),rows:source.topic?.recent||[]}};
    const archivedTours=positive(source.main?.archived_attempts_count);
    const archivedTopics=positive(source.topic?.archived_sessions_count);
    const raw=Array.isArray(source.archive_seasons)?source.archive_seasons:[];
    const entries=raw.map(a=>{
      const no=Number(a?.season_no);
      const isSeason=Number.isInteger(no)&&no>=1&&no<currentNo;
      if(!isSeason&&!['legacy','previous'].includes(a?.key))return null;
      return {key:isSeason?'season-'+no:a.key,no:isSeason?no:null,
        tours:{count:positive(a?.main?.attempts_count),rows:a?.main?.recent||[]},
        topics:{count:positive(a?.topic?.sessions_count),rows:a?.topic?.recent||[]}};
    }).filter(Boolean);
    const archivedSum=entries.reduce((x,e)=>({
      tours:x.tours+e.tours.count,topics:x.topics+e.topics.count
    }),{tours:0,topics:0});
    if(archivedSum.tours!==archivedTours||archivedSum.topics!==archivedTopics){
      entries.length=0; // never claim a precise historic season from inconsistent RPC rows
      if(archivedTours+archivedTopics>0)entries.push({
        key:'previous',no:null,
        tours:{count:archivedTours,rows:source.main?.archived_recent||[]},
        topics:{count:archivedTopics,rows:source.topic?.archived_recent||[]}
      });
    }
    const seasons=entries.filter(e=>e.no!==null&&(e.tours.count+e.topics.count)>0)
      .sort((a,b)=>b.no-a.no);
    const old=entries.filter(e=>e.no===null&&(e.tours.count+e.topics.count)>0);
    // Older unlabeled rows are kept as a collapsible subsection, never falsely
    // promoted to Season 1/2 and never exposed as a fake swipe season.
    const early=old.length?{
      tours:{count:old.reduce((n,e)=>n+e.tours.count,0),
        rows:old.flatMap(e=>e.tours.rows).slice(0,20)},
      topics:{count:old.reduce((n,e)=>n+e.topics.count,0),
        rows:old.flatMap(e=>e.topics.rows).slice(0,20)}
    }:null;
    return {seasons:[current,...seasons],early};
  };
  function historyRows(holder,items,total,kind){
    const copy=loc(),rows=Array.isArray(items)?items.slice(0,20):[];
    holder.replaceChildren();
    let shown=0;
    const list=el('div','iclub-ph-list');
    const append=(n)=>{
      rows.slice(shown,shown+n).forEach(a=>{
        const row=el('div','iclub-ph-row');
        const info=el('div','iclub-ph-row-main');
        info.append(el('strong','',kind==='topics'?String(a.topic||copy.topics).slice(0,115):copy.tours));
        info.append(el('small','',date(a.created_at)));
        const score=el('span','iclub-ph-score','—');
        if(kind==='topics'){
          const v=Number(a.correct),all=Number(a.total);
          if(Number.isInteger(v)&&Number.isInteger(all)&&all>0&&v>=0&&v<=all)score.textContent=v+' / '+all;
        } else {
          const v=Number(a.percent);
          if(a.percent!=null&&Number.isFinite(v)&&v>=0&&v<=100)score.textContent=Math.round(v)+'%';
        }
        row.append(info,score);list.append(row);
      });
      shown=Math.min(rows.length,shown+n);
      const more=holder.querySelector('.iclub-ph-more');
      if(more)more.hidden=shown>=rows.length;
    };
    if(!rows.length)holder.append(el('p','iclub-ph-empty',copy.empty));
    else {
      holder.append(list);
      const more=el('button','iclub-ph-more',copy.more);
      more.type='button';more.hidden=rows.length<=3;
      more.addEventListener('click',()=>append(5));
      holder.append(more);
      append(3);
    }
    if(positive(total)>rows.length)holder.append(el('p','iclub-ph-limit',copy.limited));
  }
  function render(){
    const host=document.getElementById(ROOT_ID);
    if(!host)return false;
    const c=loc();
    const title=document.getElementById('practice-history-title');
    const subtitle=document.getElementById('practice-history-subtitle');
    if(title)title.textContent=c.title;
    if(subtitle)subtitle.textContent=c.subtitle;
    host.replaceChildren();
    const data=historyData();
    if(!data){host.append(el('p','iclub-ph-empty',c.noData));return false;}
    const {seasons,early}=data;
    seasonIndex=Math.min(Math.max(seasonIndex,0),seasons.length-1);
    const root=el('div','iclub-ph-root');
    const navigator=el('div','iclub-ph-season-nav');
    const previous=el('button','iclub-ph-arrow','‹');
    const next=el('button','iclub-ph-arrow','›');
    previous.type=next.type='button';
    previous.setAttribute('aria-label',c.newer);
    next.setAttribute('aria-label',c.older);
    const identity=el('div','iclub-ph-season-identity');
    const seasonName=el('strong','iclub-ph-season-name');
    const currentBadge=el('span','iclub-ph-current-badge',c.currentSeason);
    const position=el('small','iclub-ph-season-position');
    identity.append(currentBadge,seasonName,position);
    navigator.append(previous,identity,next);
    const indicators=el('div','iclub-ph-dots');
    const tabs=el('div','iclub-ph-tabs');
    tabs.setAttribute('role','tablist');
    tabs.setAttribute('aria-label',c.title);
    const buttons={};
    for(const type of ['tours','topics']){
      const button=el('button','iclub-ph-tab',c[type]);
      button.type='button';
      button.id='iclub-ph-tab-'+type;
      button.setAttribute('role','tab');
      button.setAttribute('aria-controls','iclub-ph-results');
      buttons[type]=button;
      tabs.append(button);
    }
    const results=el('section','iclub-ph-results');
    results.id='iclub-ph-results';
    results.setAttribute('role','tabpanel');
    const earlyDetails=el('details','iclub-ph-early');
    const earlyLabel=el('summary','iclub-ph-early-label',c.earlier);
    const earlyHolder=el('div','iclub-ph-early-holder');
    earlyDetails.append(earlyLabel,el('p','iclub-ph-early-note',c.legacyNote),earlyHolder);
    const repaint=()=>{
      const s=seasons[seasonIndex];
      seasonName.textContent=c.season+' '+s.no;
      currentBadge.hidden=seasonIndex!==0;
      position.textContent=seasons.length>1?(seasonIndex+1)+' / '+seasons.length:'';
      previous.disabled=seasonIndex===0;
      next.disabled=seasonIndex===seasons.length-1;
      previous.hidden=next.hidden=seasons.length<=1;
      indicators.replaceChildren();
      if(seasons.length>1&&seasons.length<=6){
        for(let i=0;i<seasons.length;i++){
          const dot=el('span','iclub-ph-dot'+(i===seasonIndex?' is-current':''));
          indicators.append(dot);
        }
      }
      for(const type of ['tours','topics']){
        const active=type===mode;
        buttons[type].setAttribute('aria-selected',String(active));
        buttons[type].tabIndex=active?0:-1;
        buttons[type].classList.toggle('is-current',active);
      }
      results.setAttribute('aria-labelledby',buttons[mode].id);
      const group=s[mode];
      const summary=el('div','iclub-ph-results-label',group.count+' '+c.count);
      results.replaceChildren(summary);
      const holder=el('div','iclub-ph-current-list');
      results.append(holder);historyRows(holder,group.rows,group.count,mode);
      if(early&&(early.tours.count+early.topics.count)>0&&seasonIndex===seasons.length-1){
        const older=early[mode];
        earlyLabel.textContent=c.earlier+' · '+older.count;
        historyRows(earlyHolder,older.rows,older.count,mode);
        results.append(earlyDetails);
      }
      root.dataset.historySeason=String(s.no);
      root.dataset.historyType=mode;
    };
    const changeSeason=i=>{if(i>=0&&i<seasons.length&&i!==seasonIndex){seasonIndex=i;repaint();}};
    previous.addEventListener('click',()=>changeSeason(seasonIndex-1));
    next.addEventListener('click',()=>changeSeason(seasonIndex+1));
    for(const type of ['tours','topics']){
      buttons[type].addEventListener('click',()=>{mode=type;repaint();});
    }
    tabs.addEventListener('keydown',event=>{
      if(!['ArrowLeft','ArrowRight','Home','End'].includes(event.key))return;
      event.preventDefault();
      mode=(event.key==='ArrowRight'||event.key==='End')?'topics':'tours';
      repaint();buttons[mode].focus();
    });
    let gesture=null;
    root.addEventListener('touchstart',e=>{
      if(e.touches.length!==1){gesture=null;return;}
      gesture={x:e.touches[0].clientX,y:e.touches[0].clientY};
    },{passive:true});
    root.addEventListener('touchend',e=>{
      if(!gesture||e.changedTouches.length!==1)return;
      const dx=e.changedTouches[0].clientX-gesture.x;
      const dy=e.changedTouches[0].clientY-gesture.y;
      gesture=null;
      if(Math.abs(dx)>=58&&Math.abs(dx)>Math.abs(dy)*1.45)
        changeSeason(seasonIndex+(dx<0?1:-1));
    },{passive:true});
    root.addEventListener('touchcancel',()=>{gesture=null;},{passive:true});
    root.append(navigator,indicators,tabs,results);
    host.append(root);
    repaint();
    return true;
  }
  function setData(data,key,locale){
    source=data||null;
    sourceSubject=String(key||'');
    language=['ru','uz','en'].includes(locale)?locale:'ru';
    seasonIndex=0;mode='tours';
    // Never open history or create an attempt from an asynchronous data update.
    if(document.querySelector('#courses-practice-history.is-active'))render();
  }
  window.iClubPracticeHistoryScreenV1=Object.freeze({setData,render});
})();