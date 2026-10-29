#!/usr/bin/env node
'use strict';
// Real Chromium DOM with isolated synthetic RPCs; NO production login or writes.
const assert=require('node:assert/strict');
const {chromium}=require('playwright');
const path=require('node:path');
const file=x=>path.resolve(x);
const languages=['ru','uz','en'];
const viewports=[390,1280];
const restricted={
  ru:['Доступ ограничен','Economics Exam Prep сейчас доступен только участникам тестирования.'],
  uz:['Kirish cheklangan','Economics Exam Prep hozircha faqat sinov ishtirokchilari uchun ochiq.'],
  en:['Limited access','Economics Exam Prep is currently available only to testing participants.']
};
const chemistry={ru:'В разработке',uz:'Ishlab chiqilmoqda',en:'In development'};
async function check(browser,lang,width){
  const page=await browser.newPage({viewport:{width,height:820}}),errors=[];
  page.on('pageerror',error=>errors.push(error.message));
  try {
    const body=[
      '<!doctype html><html><head><meta name="viewport" content="width=device-width,initial-scale=1"></head><body>',
      '<main id="courses-subject-hub" data-subject-key="economics">',
      '<section id="subject-hub-exam-prep-entry">',
      '<button data-action="open-exam-prep">Exam Prep</button>',
      '<span id="subject-hub-exam-prep-badge"></span>',
      '<h2 id="subject-hub-exam-prep-title"></h2>',
      '<p id="subject-hub-exam-prep-sub"></p>',
      '<span id="subject-hub-exam-prep-p1"></span>',
      '<span id="subject-hub-exam-prep-p5"></span>',
      '<div id="subject-hub-exam-prep-note"></div>',
      '<span id="subject-hub-exam-prep-cta"></span>',
      '<div class="exam-prep-feature-components">P1/P3</div>',
      '</section><section id="exam-prep-host-root" hidden></section>',
      '</main></body></html>'
    ].join('');
    await page.setContent(body);
    await page.addStyleTag({path:file('exam-prep/exam-prep-host.css')});
    await page.evaluate(()=>{
      window.__accessCalls=[];
      window.sb={rpc:async name=>{
        window.__accessCalls.push(name);
        if(name==='get_my_exam_prep_program_shell_v1'||
           name==='get_my_exam_prep_chemistry_shell_v1'||
           name==='get_my_exam_prep_chemistry_entry_shell_v1')
          return {data:{}};
        throw Error('Unauthorized screen must not call '+name);
      }};
    });
    await page.addScriptTag({path:file('exam-prep/exam-prep-host.js')});
    await page.evaluate(lang=>window.iClubExamPrep.syncSubjectHub({subjectKey:'economics',language:lang}),lang);
    assert.equal(await page.locator('#subject-hub-exam-prep-badge').textContent(),restricted[lang][0],
      lang+' Economics locked badge');
    assert.equal(await page.locator('#subject-hub-exam-prep-sub').textContent(),restricted[lang][1],
      lang+' Economics locked subtitle');
    assert.equal(await page.locator('.exam-prep-feature-components').evaluate(el=>getComputedStyle(el).display),
      'none','MCQ options must not be presented to non-beta learner');
    await page.evaluate(lang=>window.iClubExamPrep.open({subjectKey:'economics',language:lang}),lang);
    assert.equal(await page.locator('.ep-host-coming-soon .ep-host-kicker').textContent(),restricted[lang][0],
      'Opened Economics locked panel badge');
    assert.equal(await page.locator('.ep-host-coming-soon .ep-host-note').first().textContent(),
      restricted[lang][1],'Opened Economics locked panel subtitle');
    assert.equal(await page.locator('input[name="ep-native-choice"]').count(),0,
      'Unauthorized exam cannot be entered');
    assert.deepEqual(await page.evaluate(()=>window.__accessCalls),
      ['get_my_exam_prep_program_shell_v1'],'No write or hidden release request');
    await page.evaluate(()=>{
      document.getElementById('courses-subject-hub').dataset.subjectKey='chemistry';
    });
    await page.evaluate(lang=>window.iClubExamPrep.syncSubjectHub({subjectKey:'chemistry',language:lang}),lang);
    assert.equal(await page.locator('#subject-hub-exam-prep-badge').textContent(),chemistry[lang],
      'Chemistry in-development text must stay unchanged');
    assert.equal(errors.length,0,errors.join('; '));
  }finally{await page.close();}
}
(async()=>{
  const browser=await chromium.launch({headless:true});
  try {
    let count=0;
    for(const lang of languages)for(const width of viewports){
      await check(browser,lang,width);count++;
    }
    console.log('PASS Economics limited-access copy and locked navigation:',count,
      'Chromium RU/UZ/EN × mobile/desktop scenarios; Chemistry unaffected');
  }finally{await browser.close();}
})().catch(e=>{console.error(e);process.exitCode=1;});
