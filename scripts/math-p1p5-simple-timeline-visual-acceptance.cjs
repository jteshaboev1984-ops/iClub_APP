#!/usr/bin/env node
'use strict';
// P2-15 isolated visual QA, synthetic only. No prod/network/student records.
// Runs under GitHub Actions' Playwright Chromium on Ubuntu 24.04.
const {chromium}=require('playwright');
const fs=require('node:fs');
const path=require('node:path');
const assert=require('node:assert/strict');
const output=path.resolve('progress-ux-visual-evidence');
fs.mkdirSync(output,{recursive:true});
const LABELS={
  ru:{title:'Мой путь к экзамену',missing:'Укажите даты экзаменов P1 и P5'},
  uz:{title:'Imtihongacha yo‘lim',missing:'Haftalik mo‘ljal uchun P1 va P5'},
  en:{title:'My exam timeline',missing:'Add your P1 and P5 exam dates'}
};
function data(withDates){
  const future1=withDates?'2027-05-12T09:00:00+05:00':null;
  const future5=withDates?'2027-05-20T09:00:00+05:00':null;
  return {
    contract_version:'exam_prep_one_line_progress_timeline_v2_estimated',
    factors_are_iclub_planning_assumptions_not_official_cambridge:true,
    source_guided_hours_are_not_private_study_hours:true,
    recommended_schedule_applied_automatically:false,
    learning_evidence_mutated:false,
    start_at:'2026-09-15T10:00:00+05:00',
    as_of:'2026-11-03T10:00:00+05:00',
    estimated_remaining_math_hours:118.5,estimated_joint_math_hours_per_week:withDates?5.3:null,
    joint_paper_dates_status:withDates?'both_paper_dates_confirmed':'missing_at_least_one_paper_exam_date',
    existing_chosen_math_hours_per_week:8,
    P1:{component_code:'P1',total_syllabus_skills:45,objectively_covered_skills:4,
      already_attempted_not_yet_confirmed_skills:9,not_yet_checked_skills:32,
      skills_not_yet_objectively_covered:41,estimated_remaining_study_hours:73.5,
      exam_date_status:withDates?'valid_exam_date':'exam_date_not_yet_selected',exam_at:future1},
    P5:{component_code:'P5',total_syllabus_skills:36,objectively_covered_skills:0,
      already_attempted_not_yet_confirmed_skills:4,not_yet_checked_skills:32,
      skills_not_yet_objectively_covered:36,estimated_remaining_study_hours:45,
      exam_date_status:withDates?'valid_exam_date':'exam_date_not_yet_selected',exam_at:future5}
  };
}
function html(lang){
  return '<!doctype html><html lang="'+lang+'"><head><meta name="viewport" content="width=device-width, initial-scale=1"></head><body>'+
    '<main id="courses-subject-hub" class="exam-prep-host-open" data-subject-key="mathematics">'+
    '<div id="exam-prep-host-root" class="exam-prep-host-root">'+
    '<section class="ep-host-shell ep-live"><section class="ep-live-dashboard-intro"><h2>Cambridge AS Mathematics</h2></section>'+
    '<div class="ep-live-grid">'+
    '<article data-ep-live-component="P1" class="ep-live-card"><strong>Paper 1</strong></article>'+
    '<article data-ep-live-component="P5" class="ep-live-card"><strong>Paper 5</strong></article>'+
    '</div></section></div></main></body></html>';
}
(async()=>{
  const browser=await chromium.launch({headless:true});
  try{
    let captures=0;
    for(const lang of ['ru','uz','en'])for(const width of [320,390,1440])for(const withDates of [false,true]){
      const page=await browser.newPage({viewport:{width,height:900},deviceScaleFactor:1});
      const errors=[];page.on('pageerror',err=>errors.push(err.message));
      await page.setContent(html(lang));
      for(const c of ['style.css','visual/iclub-visual-v3.css','visual/iclub-premium-v3.css',
        'exam-prep/exam-prep-host.css','exam-prep/exam-prep-simple-timeline-ui.css']){
        await page.addStyleTag({path:path.resolve(c)});
      }
      await page.evaluate(({payload,lang})=>{
        window.iClubExamPrepSimpleTimelineUiEnabled=true;
        window.i18n={getLang:()=>lang};
        window.iClubExamPrepHostInternal={lastCapabilities:{
          coreAccess:true,killSwitch:false,rolloutState:'controlled_beta'}};
        window.__p2DateSaves=[];
        window.sb={rpc:async (name,args)=>{
          if(name==='get_exam_prep_simple_learning_timeline_with_hours_safe_v2')
            return {data:payload,error:null};
          if(name!=='save_my_exam_prep_timeline_dates_safe_v1')
            throw Error('Unexpected RPC '+name);
          window.__p2DateSaves.push(args);
          const both=Boolean(args.p_p1_date&&args.p_p5_date);
          const toStamp=date=>date?date+'T12:00:00+05:00':null;
          const next={
            ...payload,joint_paper_dates_status:both?'both_paper_dates_confirmed':'missing_at_least_one_paper_exam_date',
            estimated_joint_math_hours_per_week:both?5.5:null,
            P1:{...payload.P1,exam_at:toStamp(args.p_p1_date),
              exam_date_status:args.p_p1_date?'valid_exam_date':'exam_date_not_yet_selected'},
            P5:{...payload.P5,exam_at:toStamp(args.p_p5_date),
              exam_date_status:args.p_p5_date?'valid_exam_date':'exam_date_not_yet_selected'}
          };
          return {data:next,error:null};
        }};
      },{payload:data(withDates),lang});
      await page.addScriptTag({path:path.resolve('exam-prep/exam-prep-simple-timeline-ui.js')});
      await page.waitForSelector('[data-ep-simple-timeline]');
      assert.equal(await page.locator('[data-ep-simple-timeline]').count(),1);
      assert.equal(await page.locator('[data-ep-tl-paper]').count(),2);
      const txt=await page.locator('[data-ep-simple-timeline]').innerText();
      assert(txt.includes(LABELS[lang].title),lang);
      if(!withDates) assert(txt.includes(LABELS[lang].missing));
      else assert(!txt.includes(LABELS[lang].missing));
      assert.equal(await page.evaluate(()=>
        document.documentElement.scrollWidth<=document.documentElement.clientWidth),
        true,lang+' '+width+'px: horizontal overflow');
      const viewport=await page.locator('[data-ep-simple-timeline]').boundingBox();
      assert(viewport && viewport.width<=width+0.5 && viewport.x>=-0.5,
        'Timeline cannot clip outside viewport '+lang+' '+width);
      assert.deepEqual(errors,[],'No JavaScript errors in '+lang+' '+width);
      const tag='math-timeline-'+lang+'-'+width+'-'+(withDates?'dated':'no-dates');
      await page.locator('[data-ep-simple-timeline]').screenshot({
        path:path.join(output,tag+'.png'),animations:'disabled'});
      captures++;
      await page.locator('[data-ep-tl-open-date="P1"]').click();
      await page.waitForFunction(()=>document.querySelector('[data-ep-tl-date-editor]')?.hidden===false);
      assert.equal(await page.locator('[data-ep-tl-date]').count(),2);
      await page.locator('[data-ep-tl-date-editor]').screenshot({
        path:path.join(output,tag+'-editor.png'),animations:'disabled'});
      captures++;
      await page.locator('[data-ep-tl-date="P1"]').fill('2028-02-12');
      assert.equal(await page.locator('[data-ep-tl-save]').isDisabled(),false);
      await page.locator('[data-ep-tl-save]').click();
      await page.waitForFunction(()=>document.querySelector('[data-ep-tl-success]')?.hidden===false);
      assert.equal(await page.locator('[data-ep-simple-timeline]').count(),1);
      const writes=await page.evaluate(()=>window.__p2DateSaves);
      assert.equal(writes.length,1,'Date saving must be one explicit action');
      assert.equal(writes[0].p_p1_date,'2028-02-12');
      assert.equal(writes[0].p_p5_date,withDates?'2027-05-20':null);
      const savedText=await page.locator('[data-ep-simple-timeline]').innerText();
      assert(!/school confirmation|подтверждение школ|maktab tasdiqlash/i.test(savedText));
      if(withDates) assert(!savedText.includes(LABELS[lang].missing));
      else assert(savedText.includes(LABELS[lang].missing));
      assert.equal(await page.evaluate(()=>
        document.documentElement.scrollWidth<=document.documentElement.clientWidth),true,
        lang+' '+width+' saved state cannot overflow');
      await page.locator('[data-ep-simple-timeline]').screenshot({
        path:path.join(output,tag+'-saved.png'),animations:'disabled'});
      captures++;
      await page.close();
    }
    console.log('PASS P2-16 VISUAL: '+captures+' synthetic RU/UZ/EN P1/P5 timelines, 320/390/1440 widths, dated and undated, no clipping/errors.');
  } finally {await browser.close();}
})().catch(e=>{console.error(e);process.exitCode=1;});
