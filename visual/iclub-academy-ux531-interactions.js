/* iClub Academy OS UX #531: presentation-only rail pagination and subject hub panels.
   No Supabase, localStorage, assessment state, profile writes, or route overrides. */
(()=>{'use strict';
  // Both subject families swipe; each competitive card shares one deep blue,
  // while pinned Study keeps its distinct lighter blue. Dots affect navigation only.
  const rails=[
    {id:'home-competitive-list',child:'.home-competitive-card'},
    {id:'home-study-list',child:'.home-pinned-tile'}
  ];
  const activeObservers=[];
  const copy=()=>{
    const lang=(document.documentElement.lang||'ru').toLowerCase();
    return lang.startsWith('uz')
      ? {competitive:'Musobaqa fanlari',pinned:'Biriktirilgan fanlar',item:'Fan',current:'Joriy fan'}
      : lang.startsWith('en')
        ? {competitive:'Competitive subjects',pinned:'Pinned subjects',item:'Subject',current:'Current subject'}
        : {competitive:'Соревновательные предметы',pinned:'Закреплённые предметы',item:'Предмет',current:'Текущий предмет'};
  };
  function mountRail({id,child}){
    const root=document.getElementById(id);if(!root)return;
    let pagination=root.nextElementSibling;
    if(!pagination||!pagination.classList.contains('academy-rail-pagination')){
      pagination=document.createElement('div');
      pagination.className='academy-rail-pagination';
      pagination.setAttribute('role','group');
      pagination.setAttribute('aria-label',id==='home-study-list'?copy().pinned:copy().competitive);
      root.after(pagination);
    }
    let buttons=[],cards=[];
    function sync(){
      if(cards.length<2||!buttons.length)return;
      const left=root.scrollLeft;
      let nearest=0,dist=Infinity;
      for(let i=0;i<cards.length;i++){
        const delta=Math.abs(cards[i].offsetLeft-cards[0].offsetLeft-left);
        if(delta<dist){dist=delta;nearest=i;}
      }
      buttons.forEach((b,i)=>{
        b.setAttribute('aria-current',i===nearest?'true':'false');
        b.setAttribute('aria-label',(i===nearest?copy().current+', ':copy().item+' ')+(i+1)+' / '+cards.length);
      });
    }
    function rebuild(){
      cards=[...root.children].filter(el=>el.matches(child));
      pagination.replaceChildren();
      buttons=[];
      const many=cards.length>1;
      pagination.hidden=!many;
      if(!many){root.scrollLeft=0;return;}
      cards.forEach((card,i)=>{
        const dot=document.createElement('button');dot.type='button';
        dot.className='academy-rail-dot';dot.setAttribute('aria-label',copy().item+' '+(i+1)+' / '+cards.length);
        dot.addEventListener('click',()=>root.scrollTo({
          left:card.offsetLeft-cards[0].offsetLeft,
          behavior:matchMedia('(prefers-reduced-motion: reduce)').matches?'auto':'smooth'
        }));
        pagination.append(dot);buttons.push(dot);
      });
      sync();
    }
    root.addEventListener('scroll',sync,{passive:true});
    const observer=new MutationObserver(rebuild);
    observer.observe(root,{childList:true});
    activeObservers.push(observer);
    const langObserver=new MutationObserver(()=>{
      pagination.setAttribute('aria-label',id==='home-study-list'?copy().pinned:copy().competitive);
      sync();
    });
    langObserver.observe(document.documentElement,{attributes:true,attributeFilter:['lang']});
    activeObservers.push(langObserver);
    rebuild();
  }
  function mountHub(){
    const hub=document.getElementById('courses-subject-hub');
    if(!hub)return;
    const tabs=[...hub.querySelectorAll('.academy-hub-tab[data-academy-pane]')];
    const panels=[...hub.querySelectorAll('.academy-hub-pane[data-academy-pane]')];
    if(tabs.length!==3||panels.length!==3)return;
    let current='preparation';
    function show(which,focus=false){
      if(!panels.some(p=>p.dataset.academyPane===which))return;
      current=which;
      tabs.forEach(t=>{
        const selected=t.dataset.academyPane===which;
        t.setAttribute('aria-selected',String(selected));
        t.tabIndex=selected?0:-1;
        if(selected&&focus)t.focus();
      });
      panels.forEach(p=>{
        const selected=p.dataset.academyPane===which;
        p.hidden=!selected;
      });
    }
    tabs.forEach((tab,index)=>{
      tab.addEventListener('click',()=>show(tab.dataset.academyPane));
      tab.addEventListener('keydown',event=>{
        if(!['ArrowLeft','ArrowRight','Home','End'].includes(event.key))return;
        event.preventDefault();
        const n=event.key==='Home'?0:event.key==='End'?tabs.length-1:
          (index+(event.key==='ArrowLeft'?-1:1)+tabs.length)%tabs.length;
        show(tabs[n].dataset.academyPane,true);
      });
    });
    let observedSubject=hub.dataset.subjectKey||'';
    const identityObserver=new MutationObserver(mutations=>{
      if(!mutations.some(m=>m.attributeName==='data-subject-key'))return;
      const next=hub.dataset.subjectKey||'';
      if(next!==observedSubject){observedSubject=next;show('preparation');}
    });
    identityObserver.observe(hub,{attributes:true,attributeFilter:['data-subject-key']});
    activeObservers.push(identityObserver);
    show(current);
  }
  function start(){
    rails.forEach(mountRail);
    mountHub();
  }
  if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',start,{once:true});
  else start();
})();
