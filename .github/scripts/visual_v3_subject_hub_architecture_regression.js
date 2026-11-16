/* iClub UX #531 v5.7: Subject Hub regression on the approved three-panel workspace.
   Retains original routes and the existing Exam Prep open/close safety contract. */
const fs=require('fs');
const {chromium}=require('playwright');
function assert(ok,message){if(!ok)throw Error(message);}
const html=fs.readFileSync('index.html','utf8');
const css=fs.readFileSync('visual/iclub-premium-v3.css','utf8');
const i18n=fs.readFileSync('i18n.js','utf8');
const ux=fs.readFileSync('visual/iclub-academy-ux531-b02b03.css','utf8');
const hub=(html.match(/<section id="courses-subject-hub"[\s\S]*?<\/section>/)||[])[0];
assert(hub,'Subject Hub source missing');
assert(css.includes('PREMIUM SUBJECT HUB LEARNING MODES v3.4'),'legacy source safety CSS missing');
assert(ux.includes('academy-hub-tabs'),'new workspace CSS missing');
for(const forbidden of [/localStorage/i,/sessionStorage/i,/supabase/i,/\.rpc\s*\(/,/\.from\s*\(/,/operational_stage\s*=/,/innerHTML\s*=/]){
 assert(!forbidden.test(ux),'workspace CSS must be presentation-only: '+forbidden);
}
const actions=['open-lessons','open-practice','open-tours','open-books','open-subject-mentor',
 'open-exam-prep','open-my-recommendations','open-certificates','open-archive','open-all-subjects'];
for(const action of actions){
 assert((hub.match(new RegExp('data-action="'+action+'"','g'))||[]).length===1,
  'original Subject Hub action must exist exactly once: '+action);
}
for(const key of ['academy_hub_prepare','academy_hub_materials','academy_hub_achievements']){
 assert((i18n.match(new RegExp('\\b'+key+':','g'))||[]).length===3,'RU/UZ/EN missing: '+key);
}
for(const pane of ['preparation','materials','achievements']){
 assert(hub.includes('id="academy-hub-pane-'+pane+'"'),'missing hub pane '+pane);
 assert(hub.includes('id="academy-hub-tab-'+pane+'"'),'missing tab '+pane);
}
(async()=>{
 const browser=await chromium.launch({headless:true});
 const page=await browser.newPage({viewport:{width:390,height:844},javaScriptEnabled:false});
 await page.goto(process.env.VISUAL_V3_PREMIUM_URL||'http://127.0.0.1:4173/index.html',{waitUntil:'load'});
 await page.evaluate(()=>{
  document.querySelectorAll('.view').forEach(el=>el.classList.remove('is-active'));
  document.getElementById('view-courses').classList.add('is-active');
  document.querySelectorAll('#courses-stack .stack-screen').forEach(el=>{
   el.classList.remove('is-active');el.hidden=true;el.setAttribute('aria-hidden','true');
  });
  const hub=document.getElementById('courses-subject-hub');
  hub.classList.add('is-active','exam-prep-available');
  hub.hidden=false;hub.setAttribute('aria-hidden','false');
  const entry=document.getElementById('subject-hub-exam-prep-entry');
  entry.hidden=false;entry.setAttribute('aria-hidden','false');
 });
 const st=await page.evaluate(()=>{
  const hub=document.getElementById('courses-subject-hub');
  const prep=hub.querySelector('[data-academy-pane="preparation"].academy-hub-pane');
  const mats=hub.querySelector('[data-academy-pane="materials"].academy-hub-pane');
  const achievements=hub.querySelector('[data-academy-pane="achievements"].academy-hub-pane');
  const primary=prep.querySelector('.subject-hub-primary-modes');
  const practice=primary.querySelector('.subject-mode-card-practice');
  const tours=primary.querySelector('.subject-mode-card-tours');
  const entry=primary.querySelector('#subject-hub-exam-prep-entry');
  const steps=[...hub.querySelectorAll('.academy-hub-tabs .academy-hub-tab')];
  const statusP=practice.querySelector('.subject-mode-status-practice');
  const statusT=tours.querySelector('.subject-mode-status-tours');
  const head=hub.querySelector('.subject-hub-head');
  const top=getComputedStyle(head);
  return {
    hubDisplay:getComputedStyle(hub).display,
    headerHeight:head.getBoundingClientRect().height,
    headerBackground:top.backgroundImage,
    tabs:steps.length,
    tabNames:steps.map(x=>x.dataset.academyPane),
    paneOrder:[...hub.children].filter(x=>x.classList?.contains('academy-hub-pane')).map(x=>x.dataset.academyPane),
    prepVisible:getComputedStyle(prep).display!=='none',
    materialsHidden:getComputedStyle(mats).display==='none',
    achievementsHidden:getComputedStyle(achievements).display==='none',
    prepColumns:getComputedStyle(primary).gridTemplateColumns.split(' ').length,
    practiceHeight:practice.getBoundingClientRect().height,
    toursHeight:tours.getBoundingClientRect().height,
    practiceRadius:getComputedStyle(practice).borderRadius,
    toursRadius:getComputedStyle(tours).borderRadius,
    examRadius:getComputedStyle(entry).borderRadius,
    statusesDistinct:getComputedStyle(statusP).backgroundColor!==getComputedStyle(statusT).backgroundColor,
    mentorInMaterials:!!mats.querySelector('#subject-hub-mentor-btn'),
    booksInMaterials:!!mats.querySelector('[data-action="open-books"]'),
    certificatesInAchievements:!!achievements.querySelector('[data-action="open-certificates"]'),
    archiveInAchievements:!!achievements.querySelector('[data-action="open-archive"]'),
    examHostDirectChild:document.getElementById('exam-prep-host-root').parentElement===hub,
    width:document.documentElement.scrollWidth,
    viewport:innerWidth
  };
 });
 assert(st.hubDisplay==='flex','Subject Hub display '+JSON.stringify(st));
 assert(st.headerHeight>=145&&st.headerHeight<=170,'consistent subject header height '+JSON.stringify(st));
 assert(st.tabs===3&&JSON.stringify(st.tabNames)===JSON.stringify(['preparation','materials','achievements']),'incorrect workspace tabs '+JSON.stringify(st));
 assert(JSON.stringify(st.paneOrder)===JSON.stringify(['preparation','materials','achievements']),'incorrect pane order '+JSON.stringify(st));
 assert(st.prepVisible&&st.materialsHidden&&st.achievementsHidden,'default preparation pane safety '+JSON.stringify(st));
 assert(st.prepColumns===2,'390px preparation cards must be two-column '+JSON.stringify(st));
 assert(st.practiceHeight>=88&&st.toursHeight>=88,'Preparation click target lost '+JSON.stringify(st));
 assert(st.practiceRadius===st.toursRadius&&st.examRadius==='17px','Preparation card radii mismatch '+JSON.stringify(st));
 assert(st.statusesDistinct,'Practice/Tours status distinction lost');
 assert(st.mentorInMaterials&&st.booksInMaterials&&st.certificatesInAchievements&&st.archiveInAchievements,'Original functional destinations moved incorrectly');
 assert(st.examHostDirectChild,'Exam Prep host cannot be nested inside hidden tab panes');
 assert(st.width<=st.viewport,'Subject Hub horizontal overflow '+JSON.stringify(st));
 await page.evaluate(()=>{
  const hub=document.getElementById('courses-subject-hub');
  const root=document.getElementById('exam-prep-host-root');
  root.hidden=false;root.setAttribute('aria-hidden','false');
  hub.classList.add('exam-prep-host-open');
 });
 const opened=await page.evaluate(()=>{
  const hub=document.getElementById('courses-subject-hub');
  return{
    intro:getComputedStyle(hub.querySelector('.subject-hub-head')).display,
    tabs:getComputedStyle(hub.querySelector('.academy-hub-tabs')).display,
    prepVisible:hub.querySelector('.subject-hub-primary-modes').getClientRects().length>0,
    root:getComputedStyle(document.getElementById('exam-prep-host-root')).display,
    width:document.documentElement.scrollWidth,viewport:innerWidth
  };
 });
 assert(opened.intro==='none'&&opened.tabs==='none'&&!opened.prepVisible&&opened.root!=='none',
   'Exam Prep host must hide overview panes but retain independent runtime '+JSON.stringify(opened));
 assert(opened.width<=opened.viewport,'Exam Prep open layout overflow');
 await page.evaluate(()=>{
  const hub=document.getElementById('courses-subject-hub');
  hub.classList.remove('exam-prep-host-open','is-active');hub.hidden=true;
 });
 assert(await page.evaluate(()=>getComputedStyle(document.getElementById('courses-subject-hub')).display)==='none',
   'inactive Hub must remain hidden');
 await browser.close();
 console.log('Visual v3 Subject Hub / Academy OS approved hierarchy and Exam Prep isolation: GREEN');
})().catch(e=>{console.error(e);process.exit(1);});
