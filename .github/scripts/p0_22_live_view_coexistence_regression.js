const { chromium } = require('playwright');
const path = require('path');

(async () => {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();

  await page.route('http://iclub.test/', route => route.fulfill({
    status: 200,
    contentType: 'text/html',
    body: '<!doctype html><html><head></head><body><section id="courses-subject-hub"><div id="subject-hub-exam-prep-entry" hidden aria-hidden="true"><span id="subject-hub-exam-prep-title"></span><span id="subject-hub-exam-prep-sub"></span></div><div id="exam-prep-host-root" hidden aria-hidden="true"></div></section></body></html>'
  }));
  await page.goto('http://iclub.test/');

  await page.evaluate(() => {
    const caps = { program_key:'math_as_p1_p5', rollout_state:'controlled_beta', core_access:true, ai_assist:false, mentor_care_entitled:false, mentor_assignment_active:false, mentor_authority:false, kill_switch:false };
    const profile = { exam_series:'May/June 2027', target_grade:'A', total_student_hours_available:12, mathematics_hours_budget:5, active_week_no:1 };
    const progress = {
      P1:{component_code:'P1',placement_status:'screening_incomplete',route:'pending_evidence',profile_complete:true,content_ready:true,stage0_complete:false,screening:{required_items:24,required_areas:8,answered_items:5,answered_areas:3},active_session:null},
      P5:{component_code:'P5',placement_status:'screening_incomplete',route:'pending_evidence',profile_complete:true,content_ready:true,stage0_complete:false,screening:{required_items:15,required_areas:5,answered_items:6,answered_areas:2},active_session:null}
    };
    const states = {
      P1:{engine_version:'objective_state_v1',components:[{component_code:'P1',operational_stage:0,coverage_pct:0,levels:{L0:45,L1:0,L2:0,L3:0}}],skills:[]},
      P5:{engine_version:'objective_state_v1',components:[{component_code:'P5',operational_stage:0,coverage_pct:0,levels:{L0:36,L1:0,L2:0,L3:0}}],skills:[]}
    };
    const overview = {
      P1:{component_code:'P1',operational_stage:0,coverage_count:0,denominator_count:45,coverage_pct:0,last_evidence:{evidence_type:'diagnostic',is_correct:false,created_at:'2026-09-07T05:54:25Z'},next_action:{action_code:'continue_entry_check'}},
      P5:{component_code:'P5',operational_stage:0,coverage_count:0,denominator_count:36,coverage_pct:0,last_evidence:{evidence_type:'diagnostic',is_correct:true,created_at:'2026-09-07T05:55:44Z'},next_action:{action_code:'continue_entry_check'}}
    };
    const placement = {
      P1:{component_code:'P1',available:true,placement_status:'screening_incomplete',provisional_route:'pending_evidence',stage0_complete:false,ambiguity:true,screening:{required_items:24,required_areas:8,answered_items:5,answered_areas:3},prerequisites:{unknown_count:8,blocker_count:0},next_action_code:'continue_entry_check'},
      P5:{component_code:'P5',available:true,placement_status:'screening_incomplete',provisional_route:'pending_evidence',stage0_complete:false,ambiguity:true,screening:{required_items:15,required_areas:5,answered_items:6,answered_areas:2},prerequisites:{unknown_count:10,blocker_count:0},next_action_code:'continue_entry_check'}
    };
    const tracker = {
      P1:{component_code:'P1',denominator_count:45,coverage_count:0,coverage_pct:0,open_correction_count:0,areas:[{official_syllabus_section:'1.1 Quadratics',skill_count:6,coverage_count:0,skills:[{sequence_no:1,skill_code:'P1-QUA-01',objective_level:0,evidence_total:0,correction_case_id:null}]}]},
      P5:{component_code:'P5',denominator_count:36,coverage_count:0,coverage_pct:0,open_correction_count:0,areas:[{official_syllabus_section:'5.1 Representation of data',skill_count:10,coverage_count:0,skills:[{sequence_no:1,skill_code:'P5-DAT-01',objective_level:0,evidence_total:0,correction_case_id:null}]}]}
    };
    const queue = {component_code:'P1',active_count:0,retest_due_count:0,cases:[],recent_resolved:[]};

    window.sb={rpc:async(name,args={})=>{
      if(name==='get_exam_prep_capabilities_v1') return {data:[caps],error:null};
      if(name==='get_my_exam_prep_beta_invitation_v1') return {data:{invited:false,invitations:[]},error:null};
      if(name==='get_exam_prep_exam_profile_v1') return {data:[profile],error:null};
      if(name==='get_exam_prep_diagnostic_progress_safe_v1') return {data:progress[args.p_component_code],error:null};
      if(name==='get_exam_prep_state_safe_v1') return {data:states[args.p_component_code],error:null};
      if(name==='get_exam_prep_overview_safe_v1') return {data:overview[args.p_component_code],error:null};
      if(name==='get_exam_prep_placement_result_safe_v1') return {data:placement[args.p_component_code],error:null};
      if(name==='get_exam_prep_syllabus_tracker_safe_v1') return {data:tracker[args.p_component_code],error:null};
      if(name==='get_exam_prep_correction_queue_safe_v1') return {data:{...queue,component_code:args.p_component_code},error:null};
      return {data:null,error:{message:`unexpected rpc ${name}`}};
    }};
  });

  await page.addScriptTag({path:path.resolve('exam-prep/exam-prep-api.js')});
  await page.addScriptTag({path:path.resolve('exam-prep/exam-prep-host.js')});
  await page.addScriptTag({path:path.resolve('exam-prep/exam-prep-live.js')});
  await page.addScriptTag({path:path.resolve('exam-prep/exam-prep-learner-views.js')});
  await page.addScriptTag({path:path.resolve('exam-prep/exam-prep-overview-placement.js')});

  const assert=(x,m)=>{if(!x)throw new Error(m);};
  await page.evaluate(async()=>{
    await window.iClubExamPrep.syncSubjectHub({subjectKey:'mathematics',language:'en'});
    await window.iClubExamPrep.open({subjectKey:'mathematics',language:'en'});
  });

  await page.waitForSelector('[data-ep-overview-strip="P1"]');
  await page.waitForSelector('[data-ep-views-tracker="P1"]');
  await page.waitForSelector('[data-ep-placement-open="P1"]');
  let counts=await page.evaluate(()=>({
    tracker:document.querySelectorAll('[data-ep-views-tracker="P1"]').length,
    placement:document.querySelectorAll('[data-ep-placement-open="P1"]').length,
    strip:document.querySelectorAll('[data-ep-overview-strip="P1"]').length
  }));
  assert(counts.tracker===1&&counts.placement===1&&counts.strip===1,'dashboard enhancements must inject exactly once');

  await page.click('[data-ep-views-tracker="P1"]');
  await page.waitForFunction(()=>document.querySelector('#exam-prep-host-root')?.textContent.includes('Syllabus progress'));
  assert((await page.locator('#exam-prep-host-root').textContent()).includes('0 / 45'),'tracker remains usable with overview module loaded');
  await page.click('[data-ep-views-back]');

  await page.waitForSelector('[data-ep-placement-open="P1"]');
  await page.click('[data-ep-placement-open="P1"]');
  await page.waitForFunction(()=>document.querySelector('#exam-prep-host-root')?.textContent.includes('Entry check result'));
  assert((await page.locator('#exam-prep-host-root').textContent()).includes('5 / 24'),'placement remains usable with learner views loaded');
  await page.click('[data-ep-placement-back]');

  await page.waitForSelector('[data-ep-overview-strip="P1"]');
  await page.waitForSelector('[data-ep-views-tracker="P1"]');
  counts=await page.evaluate(()=>({
    tracker:document.querySelectorAll('[data-ep-views-tracker="P1"]').length,
    placement:document.querySelectorAll('[data-ep-placement-open="P1"]').length,
    strip:document.querySelectorAll('[data-ep-overview-strip="P1"]').length
  }));
  assert(counts.tracker===1&&counts.placement===1&&counts.strip===1,'returning to overview must not duplicate injected controls');

  const text=await page.locator('#exam-prep-host-root').textContent();
  assert(!/pending_evidence|objective_state_v1|P1-QUA-01/.test(text),'combined learner overview must not leak internal terminology');

  await browser.close();
  console.log('P0-22 combined learner views coexistence: PASS');
})().catch(error=>{console.error(error);process.exit(1);});