#!/usr/bin/env node
'use strict';
// Final content-only mobile check: exact source app.js Practice question renderer,
// exact quiz section in index.html. No hosted DB, no claims of live auth E2E.
// Protected source stems/options remain in memory, never logs or artifacts.
const assert=require('node:assert/strict');
const fs=require('node:fs'),path=require('node:path');
const {chromium}=require('playwright');
const root=path.resolve(__dirname,'..');
const read=p=>fs.readFileSync(path.join(root,p),'utf8');
const app=read('app.js'),html=read('index.html');
const i=app.indexOf('function renderPracticeQuiz() {');
const j=app.indexOf('function updatePracticeSubmitEnabled()',i);
const k=app.indexOf('function handlePracticePause()',j);
assert(i>0&&j>i&&k>j,'actual renderer source boundary changed');
const renderer=app.slice(i,j)+'\n'+app.slice(j,k);
const a=html.indexOf('<section id="courses-practice-quiz"');
const b=html.indexOf('<!-- Practice Result -->',a);
assert(a>0&&b>a);
const dom=html.slice(a,b);
assert(dom.includes('id="practice-question"')&&dom.includes('id="practice-options"'));
const source=read('scripts/math-practice-v2-editorial-future-only-contract.cjs');
const matches=source.match(/const EXPECTED_IDS = new Set\(\[([^\]]+)\]\)/);
assert(matches,'source 112 set missing');
const wanted=new Set(matches[1].split(',').map(Number));
assert.equal(wanted.size,112);
for(const id of [7624,7797,7937,7791,7881]){
 assert(!wanted.has(id));
 wanted.add(id);
}
assert.equal(wanted.size,117);
const bank=path.join(root,'content/math/practice_v2');
const items=[];
for(const folder of fs.readdirSync(bank,{withFileTypes:true}).filter(x=>x.isDirectory())){
 for(const file of fs.readdirSync(path.join(bank,folder.name))
    .filter(x=>/^P1-[A-Z]{3}-\d{2}\.json$/.test(x))){
  for(const q of JSON.parse(fs.readFileSync(path.join(bank,folder.name,file),'utf8')).questions){
   const id=7484+Number(q.key.slice(-3));
   if(!wanted.has(id))continue;
   assert(['mcq','input'].includes(q.qtype));
   for(const lang of ['en','ru','uz']){
    assert(q.question?.[lang]&&q.explanation?.[lang]);
    if(q.qtype==='mcq')assert(q.options.every(o=>o.text?.[lang]));
   }
   items.push({id,type:q.qtype,difficulty:q.difficulty,question:q.question,
    options:q.qtype==='mcq'?Object.fromEntries(['en','ru','uz']
      .map(lang=>[lang,q.options.map(o=>o.text[lang])])):null});
  }
 }
}
assert.equal(items.length,117);
assert.equal(new Set(items.map(x=>x.id)).size,117);
const css=['style.css','visual/iclub-visual-v3.css',
 'visual/iclub-premium-v3.css','visual/iclub-academy-v55-shell-b01.css']
 .map(read).join('\n')+
 '\n#courses-practice-quiz{display:block!important;visibility:visible!important;opacity:1!important}'+
 '\nbody{margin:0!important;min-width:0!important}main{max-width:820px;margin:0 auto;min-width:0;padding:12px}';
const pageHtml='<!DOCTYPE html><html><head><meta charset="utf-8">'+
 '<meta name="viewport" content="width=device-width, initial-scale=1"></head>'+
 '<body class="iclub-visual-v3"><main>'+dom+'</main></body></html>';
const stubs=[
 'window.$=s=>document.querySelector(s);',
 'window.t=k=>k;',
 'window.formatMMSS=x=>String(Math.floor(x/60)).padStart(2,"0")+":"+String(x%60).padStart(2,"0");',
 'window.escapeHTML=v=>String(v).replace(/[&<>"\\x27]/g,c=>({"&":"&amp;","<":"&lt;",">":"&gt;",' +
 '"\\x22":"&quot;","\\x27":"&#39;"}[c]));',
 'window.PRACTICE_CONFIG={total:10,timeByDifficulty:{easy:45,medium:60,hard:90}};',
 'window.practiceSafeInputLooksValid=(q,s)=>/^-?\\d+(?:[.,]\\d+)?$/.test(s);',
 'window.saveState=()=>{};',
 'window.state={quiz:null};'
].join('\n')+'\n'+renderer;
(async()=>{
 const browser=await chromium.launch({headless:true,args:['--no-sandbox']});
 const totals={rendered:0,mcq:0,input:0,radiosClicked:0};
 try{
  for(const width of [320,375,430,1440]){
   const page=await browser.newPage({viewport:{width,height:900}});
   try{
    await page.setContent(pageHtml,{waitUntil:'domcontentloaded'});
    await page.addStyleTag({content:css});
    await page.addScriptTag({content:stubs});
    for(const lang of ['ru','uz','en']){
     const payload=items.map(x=>({id:x.id,type:x.type,
       difficulty:x.difficulty,question:x.question[lang],
       options:x.options?.[lang]||[]}));
     const res=await page.evaluate(questions=>{
      const problems=[];let mcq=0,input=0,radioClicks=0;
      for(const item of questions){
       try{
        window.state.quiz={
         mode:'practice',index:0,answers:[null],questions:[item],
         qTimeLeft:60,safeSessionId:117,_submitInFlight:false,_finishing:false
        };
        renderPracticeQuiz();
        const stem=document.querySelector('#practice-question');
        const wrap=document.querySelector('#practice-options');
        const btn=document.querySelector('#practice-submit-btn');
        const radios=wrap.querySelectorAll('input[type="radio"]');
        const numeric=wrap.querySelector('#practice-input');
        if(stem.textContent!==item.question)throw Error('question_render');
        if(item.type==='mcq'){
         if(radios.length!==4||numeric)throw Error('wrong_mcq_controls');
         const texts=[...wrap.querySelectorAll('label.option span')].map(x=>x.textContent);
         if(texts.length!==4||texts.some((v,i)=>v!==item.options[i]))
           throw Error('wrong_option_translation');
         if(!btn.disabled)throw Error('unanswered_mcq_not_blocked');
         radios[0].checked=true;
         radios[0].dispatchEvent(new Event('change',{bubbles:true}));
         if(btn.disabled)throw Error('radio_submit_disabled');
         mcq++;radioClicks++;
        }else{
         if(radios.length||!numeric)throw Error('wrong_input_controls');
         if(!btn.disabled)throw Error('unanswered_input_not_blocked');
         numeric.value='1';
         numeric.dispatchEvent(new Event('input',{bubbles:true}));
         if(btn.disabled)throw Error('typed_input_submit_disabled');
         input++;
        }
        if(document.documentElement.scrollWidth>document.documentElement.clientWidth+2)
         throw Error('horizontal_overflow');
       }catch(e){problems.push({id:item.id,code:String(e.message||e)});}
      }
      return {mcq,input,radioClicks,problems};
     },payload);
     if(res.problems.length)throw Error(JSON.stringify({
      width,lang,failures:res.problems.slice(0,12),count:res.problems.length}));
     assert.equal(res.mcq+res.input,117);
     totals.rendered+=117;totals.mcq+=res.mcq;
     totals.input+=res.input;totals.radiosClicked+=res.radioClicks;
    }
   }finally{await page.close();}
  }
  console.log(JSON.stringify({source:'ACTUAL_PRACTICE_QUIZ_RENDERER',auth:'NOT_TESTED',
   versions:117,locales:3,widths:4,totalChecks:totals.rendered,
   mcqChecks:totals.mcq,inputChecks:totals.input,
   radioActions:totals.radiosClicked,
   overflowFailures:0,protectedAnswerKeysPrinted:false,
   hostedWrites:0,result:'ACTUAL_RENDERER_PASS_NOT_SIGNED_E2E'}));
 }finally{await browser.close();}
})().catch(e=>{
 console.error('PRACTICE_117_RENDER_FAIL',String(e.message||e));
 process.exitCode=1;
});
