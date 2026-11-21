#!/usr/bin/env node
'use strict';
/* #574. Actual Practice renderer + Topic/Tabs/standalone History source and
   genuine local HTTP PostgREST/JWT/PG17, synthetic learners and bank only.
   Read-only UI cases mock unrelated shell/onStart. The scoped write case runs
   actual app.js Topic Start/Submit/Pause and signed local PG17 RPCs.
   Telegram login and Tour statistics remain untested; never production. */
const assert=require('node:assert/strict');
const crypto=require('node:crypto');
const fs=require('node:fs');
const http=require('node:http');
const path=require('node:path');
const {chromium}=require('playwright');
assert(process.env.CI==='true'&&
 process.env.PRACTICE_SEASON2_ISOLATED==='true'&&
 process.env.PRACTICE_TOPIC_CUTOVER_ISOLATED==='true'&&
 process.env.PGHOST==='127.0.0.1'&&
 process.env.PRACTICE_TOPIC_DB==='practice_topic_cutover',
 'REFUSED: isolated local PG17 with signed JWT required');
const secret=process.env.PRACTICE_SEASON2_JWT_SECRET;
assert(secret&&secret.length>=48,'ephemeral signing secret missing');
const A='11111111-1111-4111-8111-111111111111';
const B='22222222-2222-4222-8222-222222222222';
const b64=x=>Buffer.from(JSON.stringify(x)).toString('base64url');
function signed(uid,expires=600){
 const head=b64({alg:'HS256',typ:'JWT'});
 const now=Math.floor(Date.now()/1000);
 const input=head+'.'+b64({role:'authenticated',sub:uid,aud:'authenticated',iat:now,exp:now+expires});
 return input+'.'+crypto.createHmac('sha256',secret).update(input).digest('base64url');
}
const root=path.resolve(__dirname,'..');
const original=fs.readFileSync(path.join(root,'app.js'),'utf8');
const index=fs.readFileSync(path.join(root,'index.html'),'utf8');
const start=original.indexOf('async function renderPracticeStart() {');
const finish=original.indexOf('async function renderToursStart()',start+100);
assert(start>0&&finish>start,'actual Practice start renderer not found');
const renderer=original.slice(start,finish).trim();
assert(renderer.indexOf('window.iClubPracticeTopicChoice?.mount({')<
 renderer.indexOf('await getPracticeTourCards(subjectKey)'),
 'Topic must mount independently before Tour stats');
const screenStart=index.indexOf('<section id="courses-practice-start"');
const screenEnd=index.indexOf('<!-- Practice Quiz -->',screenStart);
assert(screenStart>0&&screenEnd>screenStart,'actual Practice and History DOM missing');
const quizEnd=index.indexOf('<!-- Practice Result -->',screenEnd);
assert(quizEnd>screenEnd,'actual Practice quiz DOM missing');
const actualDom=index.slice(screenStart,quizEnd);
assert(actualDom.includes('id="courses-practice-history"'),
 'standalone History missing from original DOM');
const uiHtml='<!doctype html><html><head><meta charset="utf-8">'+
 '<meta name="viewport" content="width=device-width,initial-scale=1"></head>'+
 '<body class="iclub-visual-v3"><main>'+actualDom+'</main></body></html>';
const allowed=new Map([
 ['/practice-topic-choice.js','practice-topic-choice.js'],
 ['/security/legacy-assessment-safe-api.js','security/legacy-assessment-safe-api.js'],
 ['/practice-results-tabs.js','practice-results-tabs.js'],
 ['/practice-history-screen.js','practice-history-screen.js'],
 ['/practice-topic-choice.css','practice-topic-choice.css'],
 ['/practice-results-tabs.css','practice-results-tabs.css'],
 ['/academy.css','visual/iclub-academy-ux531-b04b08.css']
]);
const upstream=new Map([
 ['get_practice_available_topics_safe_v1',3001],
 ['get_practice_topic_history_safe_v1',3001],
 ['get_practice_season2_progress_safe_v1',3000],
 ['start_practice_topic_drill_choice_safe_v1',3001],
 ['get_practice_drill_resume_safe_v4',3001],
 ['submit_practice_drill_answer_safe_v5',3001]
]);
const server=http.createServer(async(req,res)=>{
 let uri;try{uri=new URL(req.url,'http://127.0.0.1')}catch{res.writeHead(400).end();return;}
 const name=uri.pathname.startsWith('/rest/v1/rpc/')?
  uri.pathname.slice('/rest/v1/rpc/'.length):null;
 if(name&&upstream.has(name)&&req.method==='POST'){
  let bytes=0;
  const parts=[];
  for await(const chunk of req){
   bytes+=chunk.length;
   if(bytes>4096){res.writeHead(413).end();return;}
   parts.push(chunk);
  }
  try{
   const r=await fetch('http://127.0.0.1:'+upstream.get(name)+'/rpc/'+name,{
    method:'POST',
    headers:{
     'content-type':'application/json',
     ...(req.headers.authorization?{authorization:req.headers.authorization}:{})
    },
    body:Buffer.concat(parts)
   });
   const response=await r.text();
   res.writeHead(r.status,{'content-type':'application/json; charset=utf-8',
    'cache-control':'no-store'});
   res.end(response);
  }catch{res.writeHead(502,{'content-type':'application/json'}).end('{"code":"BAD_GATEWAY"}');}
  return;
 }
 if(req.method!=='GET'){res.writeHead(405).end();return;}
 if(uri.pathname==='/'){
  res.writeHead(200,{'content-type':'text/html; charset=utf-8','cache-control':'no-store'});
  res.end(uiHtml);return;
 }
 const file=allowed.get(uri.pathname);
 if(!file){res.writeHead(404).end();return;}
 try{
  const content=fs.readFileSync(path.join(root,file));
  res.writeHead(200,{'content-type':file.endsWith('.css')?'text/css':'text/javascript',
    'cache-control':'no-store'});
  res.end(content);
 }catch{res.writeHead(404).end();}
});
const screens=process.env.PRACTICE_S2_SCREENSHOT_DIR||'';
if(screens)fs.mkdirSync(screens,{recursive:true});
async function postRaw(base,fn,subject,token){
 const r=await fetch(base+'/rest/v1/rpc/'+fn,{
  method:'POST',headers:{'content-type':'application/json',
   ...(token?{authorization:'Bearer '+token}:{})},
  body:JSON.stringify({p_subject_key:subject})
 });
 let data=null;try{data=await r.json()}catch{}
 return {ok:r.ok,status:r.status,data};
}
(async()=>{
 await new Promise(resolve=>server.listen(0,'127.0.0.1',resolve));
 const url='http://127.0.0.1:'+server.address().port;
 try{
  const anon=await postRaw(url,'get_practice_available_topics_safe_v1','mathematics',null);
  const expired=await postRaw(url,'get_practice_available_topics_safe_v1','mathematics',signed(A,-3600));
  assert(!anon.ok&&anon.status>=400,'anonymous catalog allowed');
  assert(!expired.ok&&expired.status>=400,'expired JWT catalog allowed');
  const deniedHistory=await postRaw(url,'get_practice_topic_history_safe_v1','mathematics',null);
  assert(!deniedHistory.ok&&deniedHistory.status>=400,'anonymous Topic History allowed');
  const authA=await postRaw(url,'get_practice_available_topics_safe_v1','mathematics',signed(A));
  assert(authA.ok&&authA.data?.topics?.[0]?.question_count===5,'real signed eligible Math topics wrong');
  const authChem=await postRaw(url,'get_practice_available_topics_safe_v1','chemistry',signed(A));
  assert(authChem.ok&&authChem.data?.topics?.[0]?.question_count===1,'cross-subject catalog wrong');
  const hA=await postRaw(url,'get_practice_topic_history_safe_v1','mathematics',signed(A));
  const hB=await postRaw(url,'get_practice_topic_history_safe_v1','mathematics',signed(B));
  assert(hA.ok&&hA.data.completed_sessions===3,'owner A history wrong after earlier signed HTTP finalizes S1 session #104');
  assert(hB.ok&&hB.data.completed_sessions===1,'owner B History not isolated');
  assert(!JSON.stringify(hB.data).includes('"session_id":100'),
   'other owner old S1 attempt appeared in History');
  const progressA=await postRaw(url,'get_practice_season2_progress_safe_v1','mathematics',signed(A));
  const progressChem=await postRaw(url,'get_practice_season2_progress_safe_v1','chemistry',signed(A));
  assert(progressA.ok&&progressA.data?.period_active===true,
    'Math S2 progress RPC not current');
  assert(progressChem.ok&&progressChem.data?.practice_access?.open_season_no===1,
    'Chemistry S1 Practice closed due to Mathematics');

  const browser=await chromium.launch({headless:true,args:['--no-sandbox']});
  try{
   const cases=[
    ...['ru','uz','en'].flatMap(locale=>[320,375,430,1440].map(width=>
      ({locale,width,uid:A,subject:'mathematics'}))),
    {locale:'ru',width:375,uid:B,subject:'mathematics'},
    {locale:'en',width:375,uid:A,subject:'chemistry'}
   ];
   for(const item of cases){
    const page=await browser.newPage({viewport:{width:item.width,height:900}});
    const networkFailures=[];
    page.on('pageerror',e=>networkFailures.push(String(e.message||e)));
    await page.route('**/*',route=>{
      const u=new URL(route.request().url());
      if(u.hostname!=='127.0.0.1'){networkFailures.push('External network blocked');return route.abort();}
      return route.continue();
    });
    try{
     await page.goto(url,{waitUntil:'domcontentloaded'});
     await page.evaluate(language=>{document.documentElement.lang=language;},item.locale);
     await page.addStyleTag({content:
      '*{box-sizing:border-box}html,body{margin:0;background:#f5f8fe;color:#142b50;font:14px system-ui}'+
      '.stack-screen{display:none}.stack-screen.is-active{display:block}main{max-width:1500px}'+
      '.section{padding:12px}.h1{font-weight:750;font-size:20px}'});
     for(const file of ['practice-topic-choice.css','practice-results-tabs.css',
      'academy.css'])
      await page.addStyleTag({url:url+'/'+file});
     for(const file of ['practice-topic-choice.js','practice-history-screen.js','practice-results-tabs.js'])
      await page.addScriptTag({url:url+'/'+file});
     // Only the host's unrelated Tour selector and learner initialization are
     // stubbed. Every catalog, completed Topic History and period RPC request
     // below crosses real HTTP -> signed JWT/PostgREST -> actual PG17 SQL.
     const jwt=signed(item.uid);
     await page.evaluate(({subject,token})=>{
      window.__starts=[];
      window.__tourWaiters={};
      window.__rpcCalls=[];
      window.__practiceState={courses:{subjectKey:subject}};
      window.state=window.__practiceState;
      window.__practiceStartRenderSeq=0;
      window.$=s=>document.querySelector(s);
      window.subjectByKey=key=>({title:key});
      window.subjectTitle=(key,title)=>title||key;
      window.t=k=>k;
      window.tr3=(ru,uz,en)=>{
        const lang=document.documentElement.lang;
        return lang==='uz'?uz:lang==='en'?en:ru;
      };
      window.renderTrendBars=()=>{};
      window.beginUiLoading=()=>({active:()=>true,finish:()=>{}});
      window.uiLoadingRetry=()=>{};
      window.logClientError=()=>{};
      window.currentLang=()=>document.documentElement.lang;
      window.startPracticeByRec=(rec,origin)=>{
        window.__starts.push({topic:rec.topic,origin,subject:window.state.courses.subjectKey});
      };
      window.updatePracticeStartButtonForTour=()=>{};
      window.computePracticeStageStats=async()=>({totalCount:0,masteredCount:0,last:[]});
      window.renderPracticeTourPicker=()=>{};
      window.loadPracticeHistory=()=>({best:null,last:[]});
      window.getPracticeTourCards=async key=>{
       const r=await window.sb.rpc('get_practice_season2_progress_safe_v1',{p_subject_key:key});
       if(r.error)throw new Error('synthetic Tour shell progress load');
       return new Promise(resolve=>{
        window.__tourWaiters[key]=()=>resolve({
         subjectKey:key,currentTourNo:1,selectedTourNo:1,cards:[],
         season2Period:r.data,periodCutoff:r.data.period_active?
           r.data.period_starts_at:null,activeTourNo:null,lastCompletedTourNo:1
        });
       });
      };
      window.sb={rpc:async(name,args)=>{
       if(!['get_practice_available_topics_safe_v1',
             'get_practice_topic_history_safe_v1',
             'get_practice_season2_progress_safe_v1',
             'start_practice_topic_drill_choice_safe_v1',
             'get_practice_drill_resume_safe_v4',
             'submit_practice_drill_answer_safe_v5'].includes(name))
        return {data:null,error:{code:'UNRELATED_MOCKED_RPC'},status:404};
       const r=await fetch('/rest/v1/rpc/'+name,{
        method:'POST',
        headers:{'content-type':'application/json',
                 authorization:'Bearer '+token},
        body:JSON.stringify(args)
       });
       let data=null;try{data=await r.json()}catch{}
       window.__rpcCalls.push({name,subject:args.p_subject_key,status:r.status});
       return {data:r.ok?data:null,
        error:r.ok?null:{code:data?.code||'HTTP_'+r.status,status:r.status},
        status:r.status};
      }};
      window.addEventListener('iclub-practice-open-history',()=>{
       document.getElementById('courses-practice-start').classList.remove('is-active');
       document.getElementById('courses-practice-history').classList.add('is-active');
       window.iClubPracticeHistoryScreenV1.render();
      });
      document.getElementById('courses-practice-start').classList.add('is-active');
     },{subject:item.subject,token:jwt});
     await page.addScriptTag({content:renderer});
     await page.evaluate(()=>{void renderPracticeStart();});
     await page.waitForFunction(key=>Boolean(window.__tourWaiters?.[key]),item.subject);
     // Tour selector intentionally PAUSED: the real Topic RPC must still render.
     await page.locator('#practice-results-tab-topics').click();
     const tile=page.locator('.practice-topic-choice-item');
     await tile.first().waitFor({timeout:10000});
     assert.equal(await tile.count(),1,'real Topic catalog was not mounted while Tour awaits');
     assert((await tile.first().innerText()).includes('Synthetic'),
      'wrong catalog data or subject');
     const h=await page.evaluate(key=>window.sb.rpc('get_practice_topic_history_safe_v1',
      {p_subject_key:key}),item.subject);
     assert(h.data?.ok===true,'genuine owner History HTTP unavailable');
     if(item.subject==='mathematics')
      assert.equal(h.data.completed_sessions,item.uid===A?3:1,'owner History leak');
     if(item.subject==='chemistry')
      assert.equal(h.data.completed_sessions,1,'Chemistry S1 Topic history unavailable');
     assert.equal(await page.evaluate(()=>window.__starts.length),0,'catalog auto-started an attempt');

     // Actual one-tap Topic button; do NOT create a test attempt in DB.
     await tile.first().click();
     assert.equal(await page.evaluate(()=>window.__starts.length),1,'one-tap callback missing');
     assert.equal((await page.evaluate(()=>window.__starts))[0].subject,item.subject);

     // Release the separate Tour shell, now show actual standalone History.
     await page.evaluate(key=>window.__tourWaiters[key](),item.subject);
     const histLink=page.locator('.iclub-practice-history-entry');
     await histLink.waitFor({timeout:10000});
     await histLink.click();
     await page.locator('#courses-practice-history.is-active .iclub-ph-root').waitFor({timeout:10000});
     const history=page.locator('.iclub-ph-root');
     if(item.subject==='mathematics'){
      assert.equal(await history.getAttribute('data-history-season'),'2');
      await history.locator('#iclub-ph-tab-topics').click();
      assert.equal(await history.getAttribute('data-history-type'),'topics');
      if((await history.locator('.iclub-ph-arrow').last().isVisible())===true){
       await history.locator('.iclub-ph-arrow').last().click();
       assert.equal(await history.getAttribute('data-history-season'),'1','S1 archived season lost');
      }
     }else{
      assert.equal(await history.getAttribute('data-history-season'),'1',
       'Chemistry Practice must remain in open S1');
      assert.equal(await history.locator('.iclub-ph-current-badge').textContent(),
       {ru:'Текущая практика',uz:'Joriy amaliyot',en:'Current practice'}[item.locale]);
     }
     assert.equal(networkFailures.length,0,'actual browser exceptions: '+networkFailures.join('; ').slice(0,120));
     const requests=await page.evaluate(()=>window.__rpcCalls.filter(x=>
      x.name==='get_practice_available_topics_safe_v1'));
     assert(requests.some(x=>x.status===200&&x.subject===item.subject),
      'real browser did not make signed catalog HTTP call');
     const overflow=await page.evaluate(()=>document.documentElement.scrollWidth-window.innerWidth);
     assert(overflow<=1,'horizontal overflow '+item.locale+'/'+item.width);
     if(screens&&item.locale==='ru'&&item.width===375&&item.uid===A&&item.subject==='mathematics')
      await page.screenshot({path:path.join(screens,'practice-real-jwt-postgrest-history-ru-375.png'),
       animations:'disabled'});

     // An additional real learner write path in the same isolated Chromium session.
     // Earlier read-only assertions and History baseline have already passed.
     if(item.subject==='mathematics'&&item.locale==='ru'&&item.width===375&&item.uid===A){
       const range=(from,to)=>{
         const begin=original.indexOf(from),end=original.indexOf(to,begin+from.length);
         assert(begin>=0&&end>begin,'actual app.js handler unavailable: '+from);
         return original.slice(begin,end);
       };
       const liveHandlers=[
         ['function parseOptionsText(', 'function isNumericLike('],
         ['function pickContentText(', 'async function buildPracticeSetByRec('],
         ['function getPracticeSafeApi()', 'function practiceSafeReviewRowsToDetails('],
         ['function loadPracticeDraft()', 'function stripTourQuestionSecrets('],
         ['function savePracticeDraft(', 'function loadMyRecs()'],
         ['async function startPracticeByRec(', 'async function startPracticeRetryMistakes('],
         ['function renderPracticeQuiz()', 'function updatePracticeSubmitEnabled()'],
         ['function updatePracticeSubmitEnabled()', 'function handlePracticePause()'],
         ['function handlePracticePause()', 'async function handlePracticeDrillSubmitSafe('],
         ['async function handlePracticeDrillSubmitSafe(', 'async function handlePracticeSubmit(']
       ].map(([from,to])=>range(from,to)).join('\n');
       await page.evaluate(uid=>{
         window.loadProfile=()=>({language:document.documentElement.lang});
         window.PRACTICE_CONFIG={total:10,timeByDifficulty:{easy:45,medium:60,hard:90}};
         window.normalizeDifficulty=x=>String(x||'medium');
         window.formatMMSS=x=>'00:'+String(Math.floor(Number(x)||0)).padStart(2,'0');
         window.escapeHTML=x=>String(x).replace(/[&<>"']/g,c=>
           ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'})[c]);
         window.dbWriteWithRetry=fn=>fn();
         window.showAsyncOverlay=()=>{};
         window.hideAsyncOverlay=()=>{};
         window.showToast=()=>{};
         window.saveState=()=>true;
         window.stopPracticeQuestionTimer=()=>{};
         window.startPracticeQuestionTimer=()=>{};
         window.trackEvent=()=>{};
         window.finishPractice=()=>{window.__qaFinished=true;};
         window.iClubPracticeDraftIdentityV1={
           bind:async()=>uid,
           ownsActiveQuiz:q=>q?.practiceOwnerUid===uid,
           read:()=>JSON.parse(sessionStorage.getItem('qa-topic-draft')||'null'),
           save:d=>{sessionStorage.setItem('qa-topic-draft',JSON.stringify(d));return true;},
           clear:()=>{sessionStorage.removeItem('qa-topic-draft');return true;}
         };
         window.pushCourses=screen=>{
           document.querySelectorAll('.stack-screen').forEach(el=>el.classList.remove('is-active'));
           document.getElementById('courses-'+screen)?.classList.add('is-active');
         };
         window.replaceCourses=window.pushCourses;
         document.getElementById('courses-practice-history').classList.remove('is-active');
         document.getElementById('courses-practice-start').classList.add('is-active');
       },A);
       await page.addScriptTag({url:url+'/security/legacy-assessment-safe-api.js'});
       await page.addScriptTag({content:liveHandlers});
       await page.evaluate(()=>{
         document.getElementById('practice-submit-btn').addEventListener(
           'click',()=>{void handlePracticeDrillSubmitSafe(false);});
         document.getElementById('practice-pause-btn').addEventListener(
           'click',()=>handlePracticePause());
       });
       await page.locator('.practice-topic-choice-item').first().click();
       await page.waitForFunction(()=>Number(window.state.quiz?.safeDrillSessionId)>0,
         null,{timeout:14000});
       const launched=await page.evaluate(()=>({
         id:state.quiz.safeDrillSessionId,
         total:state.quiz.questions.length,
         initial:state.quiz.questions[0]?.correctAnswer,
         shown:document.getElementById('practice-question')?.textContent
       }));
       assert.equal(launched.total,5,'signed UI Start must select five eligible questions');
       assert(!launched.initial,'unanswered correct answer exposed by UI');
       assert(/^RU Q/.test(launched.shown),'actual app.js localized quiz not displayed');
       const writeCalls=await page.evaluate(()=>window.__rpcCalls.slice());
       assert(writeCalls.some(c=>c.name==='start_practice_topic_drill_choice_safe_v1'&&c.status===200),
         'real browser Start missed signed RPC');
       assert(writeCalls.some(c=>c.name==='get_practice_drill_resume_safe_v4'&&c.status===200),
         'real browser Start missed owned question fetch');
       if(screens)await page.screenshot({path:path.join(screens,'qa-actual-start-ru-375.png'),
         animations:'disabled'});
       await page.locator('#practice-input').fill('WRONG');
       await page.locator('#practice-submit-btn').click();
       await page.waitForFunction(()=>state.quiz?.index===1,null,{timeout:13000});
       const submitted=await page.evaluate(()=>({
         correct:state.quiz.correct[0],
         answer:state.quiz.questions[0].correctAnswer,
         explanation:state.quiz.questions[0].explanation
       }));
       assert(submitted.correct===false&&submitted.answer==='RIGHT'&&
         submitted.explanation==='RU explanation','actual app.js submission/feedback mismatch');
       await page.locator('#practice-pause-btn').click();
       await page.waitForFunction(()=>state.quiz===null&&Boolean(
         sessionStorage.getItem('qa-topic-draft')),null,{timeout:13000});
       const draft=await page.evaluate(()=>loadPracticeDraft());
       assert.equal(Number(draft?.quiz?.safeDrillSessionId),Number(launched.id));
       assert(draft.quiz.questions.every(q=>!q.correctAnswer&&!q.explanation),
         'paused draft leaked answers or explanations');
       const unchanged=await postRaw(url,'get_practice_topic_history_safe_v1','mathematics',signed(A));
       assert(unchanged.ok&&unchanged.data?.completed_sessions===3,
         'unfinished browser attempt incorrectly finalized');
       assert.equal(networkFailures.length,0,
         'unexpected browser errors after real Submit/Pause: '+networkFailures.join('; ').slice(0,140));
     }
    }finally{await page.close();}
   }
  }finally{await browser.close();}
  console.log('PRACTICE_ACTUAL_UI_SIGNED_PG17_PASS: real Practice renderer and Topic/History modules + JWT/PostgREST/catalog+history/period; owner isolation; S1/Chemistry+S2/Math; 3 locales x 4 widths');
 }finally{await new Promise(resolve=>server.close(resolve));}
})().catch(error=>{console.error('PRACTICE_ACTUAL_UI_SIGNED_PG17_FAILED:',error?.stack||String(error));process.exitCode=1});
