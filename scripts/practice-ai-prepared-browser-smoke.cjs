'use strict';
// Real Chromium QA on branch JS/CSS with synthetic responses only.
// No Supabase/OpenAI/Vercel credentials or network connections.
const assert=require('node:assert/strict');
const http=require('node:http');
const fs=require('node:fs');
const path=require('node:path');
const {chromium}=require('playwright');
const ROOT=path.resolve(__dirname,'..');
const SCREENSHOT=path.join(ROOT,'artifacts','practice-ai-preview-ru.png');
const FILES={
 '/':'scripts/fixtures/practice-ai-prepared-preview.html',
 '/practice-ai-prepared-qa.js':'practice-ai-prepared-qa.js',
 '/practice-ai-prepared-qa.css':'practice-ai-prepared-qa.css'
};
async function run(){
 const server=http.createServer((req,res)=>{
  const route=new URL(req.url,'http://127.0.0.1').pathname;
  const name=FILES[route];
  if(!name){res.writeHead(404);res.end('Not found');return;}
  res.setHeader('Content-Type',name.endsWith('.js')?'text/javascript; charset=utf-8':
   name.endsWith('.css')?'text/css; charset=utf-8':'text/html; charset=utf-8');
  res.end(fs.readFileSync(path.join(ROOT,name)));
 });
 await new Promise(ok=>server.listen(0,'127.0.0.1',ok));
 let browser=null;
 try{
  const origin='http://127.0.0.1:'+server.address().port;
  browser=await chromium.launch({headless:true,args:['--no-sandbox']});
  const context=await browser.newContext({viewport:{width:390,height:844},deviceScaleFactor:1});
  await context.route('**/*',route=>{
   if(route.request().url().startsWith(origin+'/'))return route.continue();
   return route.abort('blockedbyclient');
  });
  const page=await context.newPage();
  const jsErrors=[];
  page.on('pageerror',error=>jsErrors.push(error.message));

  // Script is inert when QA toggle is not provided.
  await page.goto(origin+'/?qa=0');
  assert.equal(await page.locator('#iclub-ai-prepared-qa-card').count(),0);
  assert.equal(await page.evaluate(()=>window.__requests.length),0);

  await page.goto(origin+'/?qa=1');
  await page.locator('#iclub-ai-prepared-qa-card').waitFor();
  assert.equal(await page.getByRole('button',{name:'Объяснить результат'}).count(),1);
  assert.equal(await page.getByRole('button',{name:'Что делать дальше?'}).count(),1);

  await page.getByRole('button',{name:'Объяснить результат'}).click();
  await page.waitForFunction(()=>document.querySelector('[data-prepared-output]')?.textContent.includes('№2, №6, №9'));
  const first=await page.evaluate(()=>window.__requests[0]);
  assert.deepEqual(Object.keys(first).sort(),
    ['attempt_ref','intent','locale','purpose','question_ref','request_id'].sort());
  assert.equal(first.attempt_ref,501);
  assert.equal(first.purpose,'practice_result');
  assert.equal(first.locale,'ru');
  assert.equal(first.question_ref,null);
  await fs.promises.mkdir(path.dirname(SCREENSHOT),{recursive:true});
  await page.screenshot({path:SCREENSHOT,fullPage:true});

  await page.getByRole('button',{name:'Что делать дальше?'}).click();
  await page.waitForFunction(()=>document.querySelector('[data-prepared-output]')?.textContent.includes('Найдите причину каждой ошибки'));
  assert.equal(await page.evaluate(()=>window.__requests[1].purpose),'practice_next_step');

  await page.getByRole('button',{name:'UZ',exact:true}).click();
  await page.getByRole('button',{name:'Natijani tushuntirish'}).click();
  await page.waitForFunction(()=>window.__requests.length===3);
  assert.equal(await page.evaluate(()=>window.__requests[2].locale),'uz');
  await page.waitForFunction(()=>document.querySelector('[data-prepared-output]')?.textContent.includes('Natija: 10 ta savoldan 7 tasi'));
  await page.getByRole('button',{name:'EN',exact:true}).click();
  await page.getByRole('button',{name:'Explain my result'}).click();
  await page.waitForFunction(()=>document.querySelector('[data-prepared-output]')?.textContent.includes('Result: 7 of 10 correct'));
  assert.equal(await page.evaluate(()=>window.__requests[3].locale),'en');
  await page.getByRole('button',{name:'UZ',exact:true}).click();

  // Navigation away before the response must not resurrect stale content.
  await page.evaluate(()=>{window.__defer=true;});
  await page.getByRole('button',{name:'Natijani tushuntirish'}).click();
  await page.waitForFunction(()=>Boolean(window.__resolvePending));
  await page.evaluate(()=>{
    const el=document.getElementById('courses-practice-result');
    el.classList.remove('is-active');
    el.dataset.practiceAiAttemptId='502';
    document.dispatchEvent(new Event('iclub:practice-ai-context-changed'));
    window.__resolvePending();
  });
  await page.waitForFunction(()=>!document.querySelector('[data-iclub-ai-prepared-qa-card]'));
  assert.equal(await page.evaluate(()=>window.__externalFetch),0);
  assert.deepEqual(jsErrors,[]);
  console.log('PASS Chromium: QA OFF, result 7/10 with 3 errors, next step, RU/UZ/EN, navigation safety, zero network');
  console.log('SCREENSHOT '+SCREENSHOT);
 }finally{
  if(browser)await browser.close();
  await new Promise(ok=>server.close(ok));
 }
}
run().catch(e=>{console.error(e);process.exitCode=1;});
