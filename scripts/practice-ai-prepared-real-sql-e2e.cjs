'use strict';
// Single disposable end-to-end path: actual branch UI -> actual Edge handler
// (only origins/base URL rebound for local CI) -> real PostgreSQL candidate RPC.
// Auth and REST HTTP envelopes are locally emulated. No production traffic or secrets.
const assert=require('node:assert/strict');
const http=require('node:http');
const fs=require('node:fs');
const os=require('node:os');
const path=require('node:path');
const {spawn,spawnSync}=require('node:child_process');
const {chromium}=require('playwright');

if(process.env.PGHOST!=='127.0.0.1'||process.env.PGDATABASE!=='postgres'||
 !String(process.env.PGOPTIONS||'').includes('iclub.isolated_practice_context=true')){
 throw Error('REFUSED: isolated Postgres runner required');
}
const ROOT=path.resolve(__dirname,'..');
const PROD='https://mmmduffgpvwjdpruzikw.supabase.co';
const USER='00000000-0000-4000-8000-000000000011';
const BEARER='qa-token-'+('a'.repeat(60));
const ANON='qa-anon-'+('b'.repeat(60));
const SERVICE='qa-service-'+('c'.repeat(60));
const EDGE_PORT=18765;
const files={
 '/':'scripts/fixtures/practice-ai-prepared-preview.html',
 '/practice-ai-prepared-qa.js':'practice-ai-prepared-qa.js',
 '/practice-ai-prepared-qa.css':'practice-ai-prepared-qa.css'
};
const metric={edgeCalls:0,dbCalls:0,forbidden:0,authCalls:0,rpcCalls:0,edgeResponses:[]};
const reply=(res,status,data,headers={})=>{
 res.writeHead(status,{'content-type':'application/json; charset=utf-8',...headers});
 res.end(JSON.stringify(data));
};
function psqlContext(data){
 // Strictly validated values ONLY; not arbitrary SQL or credentials.
 assert.equal(data.p_user_id,USER);
 assert.ok(Number.isSafeInteger(data.p_attempt_id)&&data.p_attempt_id>0);
 assert.ok(['practice_visibility','practice_result','practice_next_step','practice_history_comparison','practice_error'].includes(data.p_intent));
 assert.ok(['ru','uz','en'].includes(data.p_locale));
 assert.ok(data.p_question_id===null||Number.isSafeInteger(data.p_question_id));
 const args=[
  "'"+USER+"'::uuid",
  String(data.p_attempt_id),
  "'"+data.p_intent+"'",
  data.p_question_id===null?'NULL':String(data.p_question_id),
  "'"+data.p_locale+"'"
 ];
 const sql="BEGIN; SET LOCAL request.jwt.claim.role = 'service_role'; "+
 "SELECT public.get_iclub_ai_practice_context_v1_service("+args.join(',')+"); COMMIT;";
 const proc=spawnSync('psql',['-X','-q','-A','-t','-v','ON_ERROR_STOP=1','-c',sql],
   {encoding:'utf8',timeout:5000,env:process.env});
 if(proc.status!==0)throw Error('Isolated SQL failure '+String(proc.stderr||'').slice(0,600));
 const row=proc.stdout.split(/\r?\n/).find(s=>s.trim().startsWith('{'));
 if(!row)throw Error('Isolated SQL returned no JSON');
 metric.dbCalls++;
 return JSON.parse(row);
}
async function main(){
 let server,deno,browser,temporary;
 const errors=[];
 try{
  // Rebind the disposable PC1 owner after the preceding genuine GoTrue test.
  // The hard 127.0.0.1 database precondition above forbids production writes.
  const restored=spawnSync('psql',['-X','-v','ON_ERROR_STOP=1','-q','-c',
   "UPDATE private.iclub_ai_practice_context_v1_control "+
   "SET owner_user_id='"+USER+"'::uuid, enabled=true WHERE singleton=1;"],
   {encoding:'utf8',timeout:5000,env:process.env});
  if(restored.status!==0)throw Error('Isolated owner restore failed '+String(restored.stderr).slice(0,320));
  server=http.createServer(async(req,res)=>{
   try{
    const route=new URL(req.url,'http://127.0.0.1').pathname;
    if(files[route]){
     const file=files[route], ext=path.extname(file);
     res.setHeader('content-type',ext==='.js'?'text/javascript; charset=utf-8':
       ext==='.css'?'text/css; charset=utf-8':'text/html; charset=utf-8');
     res.end(fs.readFileSync(path.join(ROOT,file)));
     return;
    }
    if(route==='/auth/v1/user'){
     metric.authCalls++;
     if(req.headers.authorization!=='Bearer '+BEARER||req.headers.apikey!==ANON)
      return reply(res,401,{message:'Invalid token'});
     return reply(res,200,{id:USER,role:'authenticated'});
    }
    if(route==='/rest/v1/rpc/get_iclub_ai_practice_context_v1_service'){
     metric.rpcCalls++;
     if(req.method!=='POST'||req.headers.apikey!==SERVICE||
       req.headers.authorization!=='Bearer '+SERVICE)
       return reply(res,403,{message:'service access required'});
     let data='';
     for await(const c of req){data+=c;if(data.length>4096)throw Error('Too large');}
     return reply(res,200,psqlContext(JSON.parse(data)));
    }
    metric.forbidden++;
    reply(res,404,{message:'not found'});
   }catch(e){errors.push(String(e));reply(res,500,{message:'QA gateway error'});}
  });
  await new Promise(resolve=>server.listen(0,'127.0.0.1',resolve));
  const gateway='http://127.0.0.1:'+server.address().port;
  const src=fs.readFileSync(path.join(ROOT,'supabase/functions/iclub-ai-practice-prepared/index.ts'),'utf8');
  const prodBase='const BASE="'+PROD+'";';
  assert.equal(src.split(prodBase).length,2);
  assert.equal(src.split('Deno.serve(async').length,2);
  assert.match(src,/const ORIGIN=\/\^https:/);
  let modified=src.replace(prodBase,'const BASE="'+gateway+'";')
   .replace(/const ORIGIN=.*;/,'const ORIGIN=/^http:\\/\\/127\\.0\\.0\\.1:\\d+$/;')
   .replace('Deno.serve(async','Deno.serve({hostname:"127.0.0.1",port:'+EDGE_PORT+'},async');
  temporary=path.join(os.tmpdir(),'iclub-ai-local-handler-'+process.pid+'.ts');
  fs.writeFileSync(temporary,modified);
  // Env are synthetic. Deno network permission is localhost ONLY.
  deno=spawn('deno',['run','--quiet','--allow-net=127.0.0.1',
    '--allow-env=SUPABASE_URL,SUPABASE_ANON_KEY,SUPABASE_SERVICE_ROLE_KEY',temporary],{
    env:{...process.env,SUPABASE_URL:gateway,SUPABASE_ANON_KEY:ANON,
      SUPABASE_SERVICE_ROLE_KEY:SERVICE},stdio:['ignore','pipe','pipe']
  });
  let denoErrors='';
  deno.stderr.on('data',c=>{denoErrors+=c.toString();});
  let up=false;
  for(let attempt=0;attempt<80;attempt++){
    if(deno.exitCode!==null)throw Error('Deno exited before ready: '+denoErrors.slice(0,1000));
    try{
      const probe=await fetch('http://127.0.0.1:'+EDGE_PORT+'/',{headers:{Origin:gateway}});
      if(probe.status===405){up=true;break;}
    }catch{}
    await new Promise(resolve=>setTimeout(resolve,100));
  }
  if(!up)throw Error('Edge did not start: '+denoErrors.slice(0,1000));

  // Verify no auth bypass on actual Edge code. Not counted as a user flow.
  const probe=await fetch('http://127.0.0.1:'+EDGE_PORT+'/',{
    method:'POST',headers:{Origin:gateway,'content-type':'application/json'},
    body:JSON.stringify({intent:'practice_prepared'})});
  assert.equal(probe.status,401);

  browser=await chromium.launch({headless:true,args:['--no-sandbox']});
  const context=await browser.newContext({viewport:{width:390,height:844},deviceScaleFactor:1});
  await context.route('**/*',async route=>{
   const request=route.request();
   const url=request.url();
   if(url.startsWith(gateway+'/'))return route.continue();
   if(url===PROD+'/functions/v1/iclub-ai-practice-prepared'){
    if(request.method()==='POST')metric.edgeCalls++;
    const forwardedHeaders=new Headers(request.headers());
    forwardedHeaders.set('origin',gateway);
    const response=await fetch('http://127.0.0.1:'+EDGE_PORT+'/',{
     method:request.method(),
     headers:forwardedHeaders,
     body:request.method()==='POST'?request.postData():undefined
    });
    const diagnostic=await response.text();
    metric.edgeResponses.push({status:response.status,body:diagnostic.slice(0,500)});
    return route.fulfill({
     status:response.status,
     headers:Object.fromEntries(response.headers),
     body:diagnostic
    });
   }
   metric.forbidden++;
   return route.abort('blockedbyclient');
  });
  const page=await context.newPage();
  // Allow real localhost RPC only for this disposable CI browser.
  await page.addInitScript(()=>{
    window.__ICLUB_PRACTICE_E2E_ENV__ = 'isolated-ci';
  });
  page.on('pageerror',e=>errors.push(e.message));
  await page.goto(gateway+'/?qa=0');
  try {
    await page.locator('#iclub-ai-prepared-qa-card').waitFor({timeout:6500});
  } catch(err) {
    console.error('VISIBILITY DIAGNOSTIC',JSON.stringify({
      metric,errors,denoErrors:denoErrors.slice(-800),
      screen:await page.evaluate(()=>({
        card:!!document.getElementById('iclub-ai-prepared-qa-card'),
        active:document.getElementById('courses-practice-result')?.classList.contains('is-active'),
        attempt:document.getElementById('courses-practice-result')?.dataset?.practiceAiAttemptId,
        qa:window.__ICLUB_PRACTICE_PREPARED_QA__,
        isolated:window.__ICLUB_PRACTICE_E2E_ENV__,
        hasAttach:!!window.iClubPracticePreparedQa
      }))
    }));
    throw err;
  }
  await page.getByRole('button',{name:'Объяснить результат'}).click();
  try {
   await page.waitForFunction(()=>{
    const s=document.querySelector('[data-prepared-output]')?.textContent||'';
    return s.includes('7 из 10')&&s.includes('№2')&&s.includes('№6')&&s.includes('№9');
   },null,{timeout:7000});
  } catch (err) {
   console.error('E2E DIAGNOSTIC',JSON.stringify({
     currentOutput:await page.locator('[data-prepared-output]').textContent(),
     currentHtml:await page.locator('[data-prepared-output]').evaluate(el=>el.outerHTML),
     requests:await page.evaluate(()=>window.__requests),
     metric,errors,denoErrors:denoErrors.slice(-1200)
   }));
   throw err;
  }
  const summary=await page.locator('[data-prepared-output]').textContent();
  assert.match(summary,/70%/);
  assert.equal(metric.dbCalls,2);

  await page.getByRole('button',{name:'Что делать дальше?'}).click();
  await page.waitForFunction(()=>document.querySelector('[data-prepared-output]')?.textContent.includes('Найдите причину каждой ошибки'),null,{timeout:10000});
  assert.equal(metric.dbCalls,3);
  const next=await page.locator('[data-prepared-output]').textContent();
  assert.match(next,/Найдите причину каждой ошибки/);

  await fs.promises.mkdir(path.join(ROOT,'artifacts'),{recursive:true});
  await page.screenshot({path:path.join(ROOT,'artifacts','practice-ai-isolated-real-sql.png'),fullPage:true});
  await page.getByRole('button',{name:'UZ',exact:true}).click();
  await page.getByRole('button',{name:'Natijani tushuntirish'}).click();
  await page.waitForFunction(()=>document.querySelector('[data-prepared-output]')?.textContent.includes('Natija: 10 ta savoldan 7 tasi'),null,{timeout:10000});
  assert.equal(metric.dbCalls,5);

  // Caller does not get answers to somebody else's or nonexistent attempt.
  const unauthorized=await fetch('http://127.0.0.1:'+EDGE_PORT+'/',{
    method:'POST',headers:{Origin:gateway,authorization:'Bearer '+BEARER,
       'content-type':'application/json'},
    body:JSON.stringify({intent:'practice_prepared',
      request_id:'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
      purpose:'practice_result',attempt_ref:999,question_ref:null,locale:'ru'})
  });
  assert.equal(unauthorized.status,403);
  assert.equal(metric.dbCalls,6);

  assert.deepEqual(errors,[]);
  assert.equal(metric.forbidden,0);
  assert.equal(metric.edgeCalls,5);
  console.log('PASS UI -> local Deno Edge -> isolated real PostgreSQL RPC -> Chromium');
  console.log('RESULT: '+summary);
  console.log('NEXT: '+next);
  console.log('RU+UZ, server-authorized visibility, owned 7/10, 3 verified errors, denied unknown attempt; NO production traffic');
 }finally{
  if(browser)await browser.close();
  if(deno){deno.kill('SIGTERM');await new Promise(resolve=>{
    if(deno.exitCode!==null)return resolve();
    deno.once('exit',resolve);
    setTimeout(resolve,1200);
   });}
  if(temporary)try{fs.unlinkSync(temporary);}catch{}
  if(server)await new Promise(resolve=>server.close(resolve));
 }
}
main().catch(e=>{console.error(e);process.exitCode=1;});
