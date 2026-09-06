const { chromium } = require('playwright');
const path = require('path');

(async () => {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();
  await page.route('http://iclub.test/', route => route.fulfill({ status: 200, contentType: 'text/html', body: `<!doctype html><html><head></head><body><section id="courses-subject-hub"><div id="subject-hub-exam-prep-entry" hidden aria-hidden="true"><span id="subject-hub-exam-prep-title"></span><span id="subject-hub-exam-prep-sub"></span></div><div id="exam-prep-host-root" hidden aria-hidden="true"></div></section></body></html>` }));
  await page.goto('http://iclub.test/');

  await page.evaluate(() => {
    window.__calls = [];
    window.__profile = null;
    window.__progress = {
      P1: { component_code:'P1', placement_status:'screening_incomplete', route:'pending_evidence', profile_complete:true, content_ready:true, stage0_complete:false, screening:{required_items:24,required_areas:8,answered_items:0,answered_areas:0}, active_session:null, max_unlocked_stage:0, foundation_learning_access:false },
      P5: { component_code:'P5', placement_status:'screening_incomplete', route:'pending_evidence', profile_complete:true, content_ready:true, stage0_complete:false, screening:{required_items:15,required_areas:5,answered_items:0,answered_areas:0}, active_session:null, max_unlocked_stage:0, foundation_learning_access:false }
    };
    window.__session = null;
    window.__caps = { program_key:'math_as_p1_p5', rollout_state:'controlled_beta', core_access:true, ai_assist:false, mentor_care_entitled:false, mentor_assignment_active:false, mentor_authority:false, kill_switch:false };
    window.sb = { rpc: async (name,args={}) => {
      window.__calls.push({name,args});
      if (name==='get_exam_prep_capabilities_v1') return {data:[window.__caps],error:null};
      if (name==='get_my_exam_prep_beta_invitation_v1') return {data:{invited:false,invitations:[]},error:null};
      if (name==='get_exam_prep_exam_profile_v1') return {data:window.__profile?[window.__profile]:[],error:null};
      if (name==='save_exam_prep_exam_profile_v1') { window.__profile={exam_series:args.p_exam_series,target_grade:args.p_target_grade,total_student_hours_available:args.p_total_student_hours_available,mathematics_hours_budget:args.p_mathematics_hours_budget,active_week_no:1}; return {data:window.__profile,error:null}; }
      if (name==='get_exam_prep_diagnostic_progress_safe_v1') return {data:window.__progress[args.p_component_code],error:null};
      if (name==='start_exam_prep_next_diagnostic_safe_v1') { window.__session={session_id:'00000000-0000-4000-8000-000000009901',status:'active',component_code:args.p_component_code,session_type:'diagnostic',total_items:1,items:[{item_order:1,item_kind:'question',primary_skill_code:'P1-QUA-01',answered:false,qtype:'mcq',text:'What is 2 + 2?',options:['2','4','6','8']}]}; return {data:{session_id:window.__session.session_id},error:null}; }
      if (name==='get_exam_prep_session_safe_v1') return {data:window.__session,error:null};
      if (name==='submit_exam_prep_response_safe_v1') { window.__session.items[0].answered=true; return {data:{item_order:1,is_correct:args.p_payload.picked_index===1,explanation:'2 + 2 = 4.'},error:null}; }
      if (name==='finalize_exam_prep_session_safe_v1') { window.__session.status='finalized'; window.__progress.P1.screening.answered_items=1; window.__progress.P1.screening.answered_areas=1; return {data:{status:'finalized'},error:null}; }
      return {data:null,error:{message:`unexpected rpc ${name}`}};
    }};
  });

  await page.addScriptTag({path:path.resolve('exam-prep/exam-prep-api.js')});
  await page.addScriptTag({path:path.resolve('exam-prep/exam-prep-host.js')});
  await page.addScriptTag({path:path.resolve('exam-prep/exam-prep-live.js')});
  const assert=(x,m)=>{if(!x) throw new Error(m);};

  let r=await page.evaluate(async()=>{const synced=await window.iClubExamPrep.syncSubjectHub({subjectKey:'mathematics',language:'en'});const opened=await window.iClubExamPrep.open({subjectKey:'mathematics',language:'en'});return{synced,opened,profile:!!document.querySelector('[data-ep-live-profile-form]'),version:window.iClubExamPrep.liveFlowVersion};});
  assert(r.synced&&r.opened&&r.profile,'profile screen must open for controlled-beta Core');
  assert(r.version==='p018plan1','live flow version mismatch');

  await page.fill('input[name="exam_series"]','Oct/Nov 2026'); await page.fill('input[name="target_grade"]','A'); await page.fill('input[name="total_hours"]','12'); await page.fill('input[name="math_hours"]','6'); await page.click('[data-ep-live-save-profile]');
  await page.waitForFunction(()=>document.querySelector('[data-ep-live-start="P1"]'));
  await page.click('[data-ep-live-start="P1"]'); await page.waitForFunction(()=>document.querySelector('input[name="ep_live_answer"]'));
  await page.check('input[name="ep_live_answer"][value="1"]'); await page.click('[data-ep-live-submit]');
  await page.waitForFunction(()=>document.querySelector('#exam-prep-host-root')?.textContent.includes('1 / 24'));
  r=await page.evaluate(()=>({text:document.querySelector('#exam-prep-host-root').textContent,calls:window.__calls}));
  const names=r.calls.map(x=>x.name);
  for (const name of ['save_exam_prep_exam_profile_v1','start_exam_prep_next_diagnostic_safe_v1','get_exam_prep_session_safe_v1','submit_exam_prep_response_safe_v1','finalize_exam_prep_session_safe_v1']) assert(names.includes(name),`${name} missing`);
  const submit=r.calls.find(x=>x.name==='submit_exam_prep_response_safe_v1'); assert(submit.args.p_payload.picked_index===1,'MCQ index must be zero-based'); assert(r.text.includes('1 / 24'),'progress must refresh');
  await browser.close(); console.log('P0-17 live diagnostic browser flow: PASS');
})().catch(e=>{console.error(e);process.exit(1);});