const { chromium } = require('playwright');
const path = require('path');
const fs = require('fs');
const liveSource = fs.readFileSync('exam-prep/exam-prep-live.js', 'utf8');
const hostCss = fs.readFileSync('exam-prep/exam-prep-host.css', 'utf8');
if (liveSource.includes('ensureStyle(') || liveSource.includes('ep-live-flow-style') || liveSource.includes('document.createElement("style")')) throw new Error('runtime live-flow style injection returned');
if (!hostCss.includes('EXAM PREP CENTRALIZED LIVE FLOW v1') || !hostCss.includes('.ep-live-card{')) throw new Error('centralized live-flow CSS contract missing');
if (!liveSource.includes('diagnosticComplete && corrections > 0')) throw new Error('stage-0 correction link gating missing');
if (!hostCss.includes('max-width: calc(100% - 44px)')) throw new Error('mobile component stage alignment missing');
if (!hostCss.includes('EXAM PREP MOBILE UX v1')) throw new Error('mobile UX contract missing');
if (!hostCss.includes('min-height: 44px')) throw new Error('mobile touch target contract missing');

(async () => {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage({ viewport: { width: 390, height: 844 } });
  await page.route('http://iclub.test/', route => route.fulfill({ status: 200, contentType: 'text/html', body: `<!doctype html><html><head></head><body class="iclub-visual-v3"><section id="courses-subject-hub"><div id="subject-hub-exam-prep-entry" hidden aria-hidden="true"><span id="subject-hub-exam-prep-title"></span><span id="subject-hub-exam-prep-sub"></span></div><div id="exam-prep-host-root" hidden aria-hidden="true"></div></section></body></html>` }));
  await page.goto('http://iclub.test/');
  await page.addStyleTag({path:path.resolve('exam-prep/exam-prep-host.css')});

  await page.evaluate(() => {
    window.__calls = [];
    window.__profile = null;
    window.__progress = {
      P1: { component_code:'P1', placement_status:'screening_incomplete', route:'pending_evidence', profile_complete:true, content_ready:true, stage0_complete:false, screening:{required_items:24,required_areas:8,answered_items:0,answered_areas:0}, active_session:null, max_unlocked_stage:0, foundation_learning_access:false },
      P5: { component_code:'P5', placement_status:'screening_incomplete', route:'pending_evidence', profile_complete:true, content_ready:true, stage0_complete:false, screening:{required_items:15,required_areas:5,answered_items:0,answered_areas:0}, active_session:null, max_unlocked_stage:0, foundation_learning_access:false }
    };
    window.__state = {
      P1:{engine_version:'objective_state_v1',components:[{component_code:'P1',operational_stage:0,coverage_pct:0,levels:{L0:45,L1:0,L2:0,L3:0}}],skills:[]},
      P5:{engine_version:'objective_state_v1',components:[{component_code:'P5',operational_stage:0,coverage_pct:0,levels:{L0:36,L1:0,L2:0,L3:0}}],skills:[]}
    };
    window.__session = null;
    window.__caps = { program_key:'math_as_p1_p5', rollout_state:'controlled_beta', core_access:true, ai_assist:false, mentor_care_entitled:false, mentor_assignment_active:false, mentor_authority:false, kill_switch:false };
    window.sb = { rpc: async (name,args={}) => {
      window.__calls.push({name,args});
      if (name==='get_exam_prep_capabilities_v1') return {data:[window.__caps],error:null};
      if (name==='get_my_exam_prep_beta_invitation_v1') return {data:{invited:false,invitations:[]},error:null};
      if (name==='get_exam_prep_exam_profile_v1') return {data:window.__profile?[window.__profile]:[],error:null};
      if (name==='save_exam_prep_exam_profile_v2') {
        window.__profile={exam_series:args.p_exam_series,target_grade:args.p_target_grade,total_student_hours_available:args.p_total_student_hours_available,mathematics_hours_budget:args.p_mathematics_hours_budget,active_week_no:1};
        return {data:{...window.__profile,profile_revision:1,paper_comparability_epoch:1,series_changed:false,target_changed:false,hours_changed:false,progress_retained:true,plan_rebuild_required:false},error:null};
      }
      if (name==='get_exam_prep_diagnostic_progress_safe_v1') return {data:window.__progress[args.p_component_code],error:null};
      if (name==='get_exam_prep_state_safe_v1') return {data:window.__state[args.p_component_code],error:null};
      if (name==='start_exam_prep_next_diagnostic_safe_v1') {
        window.__session={
          session_id:'00000000-0000-4000-8000-000000009901',
          status:'active',component_code:args.p_component_code,session_type:'diagnostic',total_items:2,
          items:[
            {item_order:1,item_kind:'question',primary_skill_code:'P1-QUA-01',reserve_role:'diagnostic',answered:false,qtype:'mcq',text:'What is 2 + 2?',options:['2','4','6','8']},
            {item_order:2,item_kind:'question',primary_skill_code:'P1-QUA-02',reserve_role:'diagnostic',answered:false,qtype:'mcq',text:'What is 3 + 3?',options:['4','5','6','7']}
          ]
        };
        return {data:{session_id:window.__session.session_id},error:null};
      }
      if (name==='get_exam_prep_session_safe_v1') return {data:window.__session,error:null};
      if (name==='submit_exam_prep_response_safe_v1') {
        const item = window.__session.items.find(x => x.item_order === args.p_item_order);
        if (item) {
          item.answered=true;
          item.response_id=`00000000-0000-4000-8000-0000000099${String(args.p_item_order).padStart(2,'0')}`;
          item.selected_answer=String(args.p_payload.picked_index);
          item.feedback_deferred=true;
        }
        return {data:{item_order:args.p_item_order,selected_answer:String(args.p_payload.picked_index),verification_status:'app_verified',feedback_deferred:true,replayed:false},error:null};
      }
      if (name==='finalize_exam_prep_session_safe_v1') {
        window.__session.status='finalized';
        window.__progress.P1.screening.answered_items=2;
        window.__progress.P1.screening.answered_areas=2;
        return {data:{status:'finalized'},error:null};
      }
      return {data:null,error:{message:`unexpected rpc ${name}`}};
    }};
  });

  await page.addScriptTag({path:path.resolve('exam-prep/exam-prep-api.js')});
  await page.addScriptTag({path:path.resolve('exam-prep/exam-prep-host.js')});
  await page.addScriptTag({path:path.resolve('exam-prep/exam-prep-live.js')});
  const assert=(x,m)=>{if(!x) throw new Error(m);};

  let r=await page.evaluate(async()=>{const synced=await window.iClubExamPrep.syncSubjectHub({subjectKey:'mathematics',language:'en'});const opened=await window.iClubExamPrep.open({subjectKey:'mathematics',language:'en'});return{synced,opened,profile:!!document.querySelector('[data-ep-live-profile-form]'),version:window.iClubExamPrep.liveFlowVersion};});
  assert(r.synced&&r.opened&&r.profile,'profile screen must open for controlled-beta Core');
  assert(r.version==='p260signal1','live flow version mismatch');

  await page.fill('input[name="exam_series"]','Oct/Nov 2026');
  await page.fill('input[name="target_grade"]','A');
  await page.fill('input[name="total_hours"]','12');
  await page.fill('input[name="math_hours"]','6');
  await page.click('[data-ep-live-save-profile]');
  await page.waitForFunction(()=>document.querySelector('[data-ep-live-open-component="P1"]'));
  r=await page.evaluate(()=>({
    cards:document.querySelectorAll('[data-ep-live-open-component]').length,
    calls:window.__calls.map(x=>x.name),
    hasGenericTitle:Boolean(document.querySelector('#exam-prep-host-root .ep-host-title')),
    horizontalOverflow:document.documentElement.scrollWidth > innerWidth + 1,
    stateReads:window.__calls
      .filter(x=>['get_exam_prep_diagnostic_progress_safe_v1','get_exam_prep_state_safe_v1'].includes(x.name))
      .map(x=>`${x.name}:${x.args.p_component_code}`)
  }));
  assert(r.cards===2,'overview must expose exactly two component route cards');
  assert(r.hasGenericTitle===false,'mobile overview must not repeat the generic Exam Prep header above the route');
  assert(r.horizontalOverflow===false,'mobile overview must not create horizontal overflow at 390px');
  assert(JSON.stringify(r.stateReads)===JSON.stringify([
    'get_exam_prep_diagnostic_progress_safe_v1:P1',
    'get_exam_prep_diagnostic_progress_safe_v1:P5'
  ]),'incomplete Stage 0 dashboard must not rebuild derived state that cannot change the learner route');
  assert(!r.calls.includes('start_exam_prep_next_diagnostic_safe_v1'),'opening Exam Prep must not start an assessment');
  assert(!r.calls.some(name=>name.startsWith('generate_exam_prep_weekly_plan')),'opening Exam Prep must not generate a weekly plan');

  await page.click('[data-ep-live-open-component="P1"]');
  await page.waitForFunction(()=>document.querySelector('[data-ep-component-home="P1"]'));
  r=await page.evaluate(()=>({
    primary:document.querySelector('[data-ep-component-primary]')?.textContent,
    calls:window.__calls.map(x=>x.name),
    hasGenericHead:Boolean(document.querySelector('#exam-prep-host-root .ep-live-head')),
    hasComponentHero:Boolean(document.querySelector('[data-ep-component-home="P1"] .ep-component-hero')),
    backHeight:document.querySelector('[data-ep-component-back]')?.getBoundingClientRect().height || 0,
    horizontalOverflow:document.documentElement.scrollWidth > innerWidth + 1
  }));
  assert(/Start the next check section/i.test(r.primary),'P1 component home must show one immediate diagnostic action');
  assert(!r.calls.includes('start_exam_prep_next_diagnostic_safe_v1'),'viewing P1 must remain read-only before learner action');
  assert(!r.calls.includes('get_exam_prep_state_safe_v1'),'incomplete Stage 0 component home must not rebuild derived state');
  assert(r.hasComponentHero,'P1 component identity must remain visible on the component screen');
  assert(!r.hasGenericHead,'component screen must not repeat the generic Exam Prep intro above the paper identity');
  assert(r.backHeight>=44,`component back touch target must be at least 44px; got ${r.backHeight}`);
  assert(r.horizontalOverflow===false,'P1 component home must not overflow horizontally at 390px');

  await page.click('[data-ep-component-primary="diagnostic"]');
  await page.waitForFunction(()=>document.querySelector('input[name="ep_live_answer"]'));

  r=await page.evaluate(()=>({
    hasGenericTitle:Boolean(document.querySelector('#exam-prep-host-root .ep-host-title')),
    hasQuestionCard:Boolean(document.querySelector('#exam-prep-host-root .ep-live-question-card')),
    submitHeight:document.querySelector('[data-ep-live-submit]')?.getBoundingClientRect().height || 0,
    horizontalOverflow:document.documentElement.scrollWidth > innerWidth + 1
  }));
  assert(r.hasGenericTitle===false,'mobile question must not repeat the generic module title');
  assert(r.hasQuestionCard===true,'mobile question must use the compact question surface');
  assert(r.submitHeight>=44,`mobile submit touch target must be at least 44px; got ${r.submitHeight}`);
  assert(r.horizontalOverflow===false,'mobile question must not overflow horizontally at 390px');

  await page.check('input[name="ep_live_answer"][value="1"]');
  await page.click('[data-ep-live-submit]');
  await page.waitForFunction(()=>document.querySelector('#exam-prep-host-root')?.textContent.includes('Question 2 / 2'));

  r=await page.evaluate(()=>({
    text:document.querySelector('#exam-prep-host-root').textContent,
    calls:window.__calls,
    session:window.__session
  }));
  assert(r.session.status==='active','protected diagnostic must remain active after the first response');
  assert(r.session.items[0].feedback_deferred===true,'active protected response must carry deferred-feedback state');
  assert(!('is_correct' in r.session.items[0]),'active protected session must not expose correctness');
  assert(!/\bCorrect\b|Review this mistake|2 \+ 2 = 4/i.test(r.text),'active protected diagnostic must not show correctness or explanation before finalization');
  assert(r.calls.filter(x=>x.name==='finalize_exam_prep_session_safe_v1').length===0,'protected diagnostic must not finalize before all items are answered');

  await page.check('input[name="ep_live_answer"][value="2"]');
  await page.click('[data-ep-live-submit]');
  await page.waitForFunction(()=>document.querySelector('[data-ep-component-home="P1"]'));

  r=await page.evaluate(()=>({text:document.querySelector('#exam-prep-host-root').textContent,calls:window.__calls,answered:window.__progress.P1.screening.answered_items}));
  const names=r.calls.map(x=>x.name);
  for (const name of ['save_exam_prep_exam_profile_v2','start_exam_prep_next_diagnostic_safe_v1','get_exam_prep_session_safe_v1','submit_exam_prep_response_safe_v1','finalize_exam_prep_session_safe_v1']) assert(names.includes(name),`${name} missing`);
  assert(!names.includes('get_exam_prep_state_safe_v1'),'partial Stage 0 must remain free of redundant derived-state rebuilds after finalization');
  assert(!names.includes('save_exam_prep_exam_profile_v1'),'legacy profile save must not be used');
  const submits=r.calls.filter(x=>x.name==='submit_exam_prep_response_safe_v1');
  assert(submits.length===2,'both diagnostic responses must be submitted');
  assert(submits[0].args.p_payload.picked_index===1,'first MCQ index must be zero-based');
  assert(submits[1].args.p_payload.picked_index===2,'second MCQ index must be zero-based');
  assert(r.answered===2,'diagnostic progress must refresh after finalization');
  assert(/Continue entry check/i.test(r.text),'component home must return with the next diagnostic action');
  assert(!/Core beta|Synthetic learner data|Screening complete/i.test(r.text),'learner UI must not expose internal rollout terminology');

  // Once Stage 0 is complete, the derived state becomes authoritative again.
  r=await page.evaluate(async()=>{
    window.__calls=[];
    window.__progress.P1.stage0_complete=true;
    window.__progress.P1.placement_status='complete';
    window.__progress.P1.screening.answered_items=24;
    window.__progress.P1.screening.answered_areas=8;
    const opened=await window.iClubExamPrep.open({subjectKey:'mathematics',language:'en'});
    return {
      opened,
      stateReads:window.__calls
        .filter(x=>['get_exam_prep_diagnostic_progress_safe_v1','get_exam_prep_state_safe_v1'].includes(x.name))
        .map(x=>`${x.name}:${x.args.p_component_code}`)
    };
  });
  assert(r.opened,'completed Stage 0 dashboard must still open');
  assert(JSON.stringify(r.stateReads)===JSON.stringify([
    'get_exam_prep_diagnostic_progress_safe_v1:P1',
    'get_exam_prep_state_safe_v1:P1',
    'get_exam_prep_diagnostic_progress_safe_v1:P5'
  ]),'getState must return exactly when a component completes Stage 0, while incomplete components still skip it');

  await browser.close();
  console.log('P0-17 live entry-check browser flow: PASS');
})().catch(e=>{console.error(e);process.exit(1);});
