const { chromium } = require('playwright');
const path = require('path');

(async () => {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage({ viewport: { width: 390, height: 844 } });
  await page.route('http://iclub.test/', route => route.fulfill({
    status: 200,
    contentType: 'text/html',
    body: '<!doctype html><html lang="en"><head></head><body><section id="courses-subject-hub"><div id="subject-hub-exam-prep-entry" hidden aria-hidden="true"><span id="subject-hub-exam-prep-title"></span><span id="subject-hub-exam-prep-sub"></span></div><div id="exam-prep-host-root" hidden aria-hidden="true"></div></section></body></html>'
  }));
  await page.goto('http://iclub.test/');

  await page.evaluate(() => {
    window.__calls = [];
    window.__profileReads = 0;
    window.__profile = {
      exam_series:'October 2027', target_grade:'A',
      total_student_hours_available:12, mathematics_hours_budget:6, active_week_no:12
    };
    window.__caps = {program_key:'math_as_p1_p5',rollout_state:'controlled_beta',core_access:true,ai_assist:false,mentor_care_entitled:false,mentor_assignment_active:false,mentor_authority:false,kill_switch:false};
    window.__progress = {
      P1:{component_code:'P1',placement_status:'conservative_foundation',route:'foundation',profile_complete:true,content_ready:true,stage0_complete:true,screening:{required_items:24,required_areas:8,answered_items:24,answered_areas:8,accuracy_pct:75},active_session:null,max_unlocked_stage:2,foundation_learning_access:true},
      P5:{component_code:'P5',placement_status:'conservative_foundation',route:'foundation',profile_complete:true,content_ready:true,stage0_complete:true,screening:{required_items:15,required_areas:5,answered_items:15,answered_areas:5,accuracy_pct:75},active_session:null,max_unlocked_stage:2,foundation_learning_access:true}
    };
    window.__state = {
      P1:{engine_version:'objective_state_v1',components:[{component_code:'P1',operational_stage:2,coverage_pct:30,levels:{L0:25,L1:5,L2:10,L3:5}}],skills:[]},
      P5:{engine_version:'objective_state_v1',components:[{component_code:'P5',operational_stage:2,coverage_pct:25,levels:{L0:21,L1:6,L2:6,L3:3}}],skills:[]}
    };

    window.sb = { rpc: async (name,args={}) => {
      window.__calls.push({name,args});
      if (name==='get_exam_prep_capabilities_v1') return {data:[window.__caps],error:null};
      if (name==='get_my_exam_prep_beta_invitation_v1') return {data:{invited:false,invitations:[]},error:null};
      if (name==='get_exam_prep_exam_profile_v1') {
        window.__profileReads += 1;
        await new Promise(resolve => setTimeout(resolve, 25));
        return {data:[window.__profile],error:null};
      }
      if (name==='get_exam_prep_diagnostic_progress_safe_v1') return {data:window.__progress[args.p_component_code],error:null};
      if (name==='get_exam_prep_state_safe_v1') return {data:window.__state[args.p_component_code],error:null};
      if (name==='save_exam_prep_exam_profile_v2') {
        const oldSeries = window.__profile.exam_series;
        const oldTarget = window.__profile.target_grade;
        const oldTotal = window.__profile.total_student_hours_available;
        const oldMath = window.__profile.mathematics_hours_budget;
        const seriesChanged = oldSeries.toLowerCase() !== String(args.p_exam_series || '').toLowerCase();
        const targetChanged = oldTarget !== args.p_target_grade;
        const hoursChanged = Number(oldTotal)!==Number(args.p_total_student_hours_available) || Number(oldMath)!==Number(args.p_mathematics_hours_budget);
        window.__profile = {
          exam_series:args.p_exam_series,target_grade:args.p_target_grade,
          total_student_hours_available:args.p_total_student_hours_available,
          mathematics_hours_budget:args.p_mathematics_hours_budget,active_week_no:12
        };
        return {data:{...window.__profile,profile_revision:2,paper_comparability_epoch:seriesChanged?2:1,series_changed:seriesChanged,target_changed:targetChanged,hours_changed:hoursChanged,progress_retained:true,prior_papers_remain_history:true,plan_rebuild_required:seriesChanged||targetChanged||hoursChanged,timetable_reconfirmation_required:seriesChanged},error:null};
      }
      if (name==='generate_exam_prep_weekly_plan_safe_v3') return {data:{component_code:args.p_component_code,progress_retained:true},error:null};
      return {data:null,error:{message:`unexpected rpc ${name}`}};
    }};
  });

  await page.addStyleTag({path:path.resolve('exam-prep/exam-prep-host.css')});
  await page.addScriptTag({path:path.resolve('exam-prep/exam-prep-api.js')});
  await page.addScriptTag({path:path.resolve('exam-prep/exam-prep-host.js')});
  await page.addScriptTag({path:path.resolve('exam-prep/exam-prep-live.js')});
  await page.addScriptTag({path:path.resolve('exam-prep/exam-prep-exam-map.js')});

  const assert = (condition,message) => { if (!condition) throw new Error(message); };

  await page.evaluate(async () => {
    await window.iClubExamPrep.syncSubjectHub({subjectKey:'mathematics',language:'en'});
    await window.iClubExamPrep.open({subjectKey:'mathematics',language:'en'});
    const root = document.querySelector('#exam-prep-host-root');
    for (let i=0;i<8;i+=1) {
      root.setAttribute('data-race-probe', String(i));
      root.appendChild(document.createComment(`race-${i}`));
    }
  });

  await page.waitForSelector('[data-ep-exam-plan-edit]');
  await page.waitForTimeout(80);
  let presentation = await page.evaluate(() => ({
    editButtons:document.querySelectorAll('[data-ep-exam-plan-edit]').length,
    duplicateCards:document.querySelectorAll('[data-ep-exam-plan-card]').length,
    summaryText:document.querySelector('.ep-live-dashboard-profile')?.textContent || '',
    rootHidden:document.querySelector('#exam-prep-host-root')?.hidden === true,
    rootWidth:document.querySelector('#exam-prep-host-root')?.getBoundingClientRect().width || 0,
    scrollWidth:document.querySelector('#exam-prep-host-root')?.scrollWidth || 0
  }));
  assert(presentation.editButtons===1,`exam plan edit action duplicated: ${presentation.editButtons}`);
  assert(presentation.duplicateCards===0,'separate Exam plan card must not duplicate Saved plan');
  assert(presentation.summaryText.includes('Saved plan'),'saved-plan summary missing');
  assert(presentation.summaryText.includes('October 2027'),'current custom exam series missing');
  assert(presentation.summaryText.includes('Change exam plan'),'edit action is not placed inside Saved plan');
  assert(!presentation.rootHidden,'Exam Prep unexpectedly closed');
  assert(presentation.scrollWidth <= presentation.rootWidth + 1,`dashboard overflow: ${presentation.scrollWidth} > ${presentation.rootWidth}`);

  await page.click('[data-ep-exam-plan-edit]');
  await page.waitForSelector('[data-ep-exam-plan-form]');
  let text = await page.locator('#exam-prep-host-root').textContent();
  assert(text.includes('Previous progress, correction work and scheduled checks are kept.'),'non-destructive edit explanation missing');

  const editor = await page.evaluate(() => ({
    seriesTag:document.querySelector('[data-ep-exam-plan-form] [name="exam_series"]')?.tagName,
    targetTag:document.querySelector('[data-ep-exam-plan-form] [name="target_grade"]')?.tagName,
    seriesValue:document.querySelector('[data-ep-exam-plan-form] [name="exam_series"]')?.value,
    targetOptions:Array.from(document.querySelector('[data-ep-exam-plan-form] [name="target_grade"]')?.options || []).map(x=>x.value),
    seriesOptions:Array.from(document.querySelector('[data-ep-exam-plan-form] [name="exam_series"]')?.options || []).map(x=>x.value)
  }));
  assert(editor.seriesTag==='SELECT','exam series must be selectable');
  assert(editor.targetTag==='SELECT','target grade must be selectable');
  assert(editor.seriesValue==='October 2027','legacy/custom current series must remain selected until learner changes it');
  assert(JSON.stringify(editor.targetOptions)===JSON.stringify(['A','B','C','D','E']),'target-grade options must be A-E');
  assert(editor.seriesOptions.includes('June 2027') && editor.seriesOptions.includes('November 2027'),'standard Cambridge session choices missing');

  // The app-level back arrow must step out of the editor first, not close Exam Prep.
  await page.evaluate(() => window.iClubExamPrep.back());
  await page.waitForSelector('.ep-live-dashboard-profile');
  assert(!(await page.locator('#exam-prep-host-root').evaluate(el=>el.hidden)),'nested Back closed the whole Exam Prep module');

  await page.waitForSelector('[data-ep-exam-plan-edit]');
  await page.click('[data-ep-exam-plan-edit]');
  await page.selectOption('[data-ep-exam-plan-form] select[name="exam_series"]','November 2027');
  await page.selectOption('[data-ep-exam-plan-form] select[name="target_grade"]','B');
  await page.fill('[data-ep-exam-plan-form] input[name="total_hours"]','10');
  await page.fill('[data-ep-exam-plan-form] input[name="math_hours"]','5');
  await page.click('[data-ep-exam-plan-form] button[type="submit"]');

  await page.waitForFunction(() => document.querySelector('#exam-prep-host-root')?.textContent?.includes('Previous results remain in your history.'));
  await page.waitForSelector('[data-ep-exam-plan-edit]');
  await page.waitForTimeout(60);

  const result = await page.evaluate(() => ({
    calls:window.__calls,
    text:document.querySelector('#exam-prep-host-root').textContent,
    editButtons:document.querySelectorAll('[data-ep-exam-plan-edit]').length,
    duplicateCards:document.querySelectorAll('[data-ep-exam-plan-card]').length,
    hasP1Plan:Boolean(document.querySelector('[data-ep-live-plan="P1"]')),
    hasP5Plan:Boolean(document.querySelector('[data-ep-live-plan="P5"]'))
  }));
  const names = result.calls.map(x=>x.name);
  assert(names.includes('save_exam_prep_exam_profile_v2'),'versioned profile save missing');
  assert(!names.includes('save_exam_prep_exam_profile_v1'),'legacy profile save must not be used');

  const planCalls = result.calls.filter(x=>x.name==='generate_exam_prep_weekly_plan_safe_v3');
  assert(planCalls.length===2,'profile change must independently rebuild P1 and P5 plans');
  assert(planCalls.some(x=>x.args.p_component_code==='P1'),'P1 plan rebuild missing');
  assert(planCalls.some(x=>x.args.p_component_code==='P5'),'P5 plan rebuild missing');

  for (const forbidden of ['submit_exam_prep_response_safe_v1','finalize_exam_prep_session_safe_v1','finalize_exam_prep_timed_safe_v1']) {
    assert(!names.includes(forbidden),`${forbidden} must not be called by profile editing`);
  }

  assert(result.text.includes('November 2027'),'updated series not shown');
  assert(result.text.includes('Target grade: B'),'updated target grade not shown');
  assert(result.text.includes('P1 and P5 remain separate'),'component-separation learner notice missing');
  assert(result.hasP1Plan && result.hasP5Plan,'dashboard must remain available after plan update');
  assert(result.editButtons===1,'exam plan action duplicated after save/remount');
  assert(result.duplicateCards===0,'old duplicate plan card returned after save/remount');
  assert(!/profile_revision|paper_comparability_epoch|comparability|controlled_beta|synthetic|internal skill/i.test(result.text),'internal terminology leaked to learner UI');

  // On the dashboard, Back is allowed to leave Exam Prep and return to the Mathematics subject hub.
  await page.evaluate(() => window.iClubExamPrep.back());
  assert(await page.locator('#exam-prep-host-root').evaluate(el=>el.hidden),'dashboard Back should leave Exam Prep');

  await browser.close();
  console.log('P2-09 Exam Map learner editor, dedupe, selectable profile and contextual back: PASS');
})().catch(error => { console.error(error); process.exit(1); });
