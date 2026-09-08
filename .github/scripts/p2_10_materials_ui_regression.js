const { chromium } = require('playwright');
const path = require('path');

(async () => {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();
  await page.route('http://iclub.test/', route => route.fulfill({
    status: 200,
    contentType: 'text/html',
    body: `<!doctype html><html lang="en"><head></head><body>
      <section id="exam-prep-host-root">
        <div>Overview</div>
        <article class="ep-live-card"><div class="ep-live-actions"><button data-ep-live-plan="P1">Weekly plan</button></div></article>
        <article class="ep-live-card"><div class="ep-live-actions"><button data-ep-live-plan="P5">Weekly plan</button></div></article>
      </section>
    </body></html>`
  }));
  await page.goto('http://iclub.test/');

  await page.evaluate(() => {
    window.__calls = [];
    window.__opened = [];
    window.open = url => { window.__opened.push(url); return null; };
    window.iClubExamPrepHostInternal = {
      lastCapabilities: {
        rolloutState:'controlled_beta', coreAccess:true, aiAssist:false,
        mentorCareEntitled:false, mentorAssignmentActive:false,
        mentorAuthority:false, killSwitch:false
      }
    };
    window.sb = { rpc: async (name,args={}) => {
      window.__calls.push({name,args});
      if (name === 'get_exam_prep_materials_library_safe_v1') return {data:{
        language:'en', rights_respected:true, protected_content_embedded:false, official_links_open_externally:true,
        materials:[
          {material_key:'cambridge_9709_syllabus_2026_2027',component_code:null,resource_kind:'official_syllabus',title:'Cambridge 9709 syllabus 2026–2027',note:'Official scope reference for the current Exam Prep syllabus version.',access_mode:'official_external',external_url:'https://www.cambridgeinternational.org/Images/697427-2026-2027-syllabus.pdf',licensed_copy_required:false,school_request_required:false},
          {material_key:'complete_pure_mathematics_1_reference',component_code:'P1',resource_kind:'coursebook_reference',title:'Complete Pure Mathematics 1',note:'Teaching and chapter-reference source for P1.',access_mode:'licensed_reference',external_url:null,licensed_copy_required:true,school_request_required:false},
          {material_key:'complete_probability_statistics_1_reference',component_code:'P5',resource_kind:'coursebook_reference',title:'Complete Probability & Statistics 1',note:'Teaching and chapter-reference source for P5.',access_mode:'licensed_reference',external_url:null,licensed_copy_required:true,school_request_required:false},
          {material_key:'cambridge_9709_past_papers_index',component_code:null,resource_kind:'official_past_paper_index',title:'Cambridge 9709 past papers',note:'Official Cambridge page.',access_mode:'official_external',external_url:'https://www.cambridgeinternational.org/programmes-and-qualifications/cambridge-international-as-and-a-level-mathematics-9709/past-papers/',licensed_copy_required:false,school_request_required:false},
          {material_key:'cambridge_9709_examiner_reports_index',component_code:null,resource_kind:'examiner_feedback_index',title:'Cambridge 9709 examiner reports',note:'Official examiner feedback.',access_mode:'official_external',external_url:'https://www.cambridgeinternational.org/programmes-and-qualifications/cambridge-international-as-and-a-level-mathematics-9709/past-papers/',licensed_copy_required:false,school_request_required:false}
        ]
      },error:null};
      return {data:null,error:{message:`unexpected rpc ${name}`}};
    }};
  });

  await page.addScriptTag({path:path.resolve('exam-prep/exam-prep-api.js')});
  await page.addScriptTag({path:path.resolve('exam-prep/exam-prep-materials.js')});

  const assert = (condition,message) => { if (!condition) throw new Error(message); };

  await page.waitForSelector('[data-ep-materials-open="P1"]');
  await page.waitForSelector('[data-ep-materials-open="P5"]');
  await page.click('[data-ep-materials-open="P1"]');
  await page.waitForSelector('[data-ep-materials-screen]');

  const p1 = await page.evaluate(() => ({
    text:document.querySelector('#exam-prep-host-root').textContent,
    calls:window.__calls,
    materialKeys:Array.from(document.querySelectorAll('[data-ep-material]')).map(x=>x.dataset.epMaterial),
    externalButtons:Array.from(document.querySelectorAll('[data-ep-materials-external]')).map(x=>x.dataset.epMaterialsExternal)
  }));

  assert(p1.text.includes('Study materials'),'learner Materials Library title missing');
  assert(p1.text.includes('Cambridge 9709 syllabus 2026–2027'),'official syllabus missing');
  assert(p1.text.includes('Complete Pure Mathematics 1'),'P1 coursebook reference missing');
  assert(!p1.text.includes('Complete Probability & Statistics 1'),'P5-only coursebook leaked into P1 library');
  assert(p1.text.includes('Cambridge 9709 past papers'),'official past-paper index missing');
  assert(p1.text.includes('Cambridge 9709 examiner reports'),'examiner reports index missing');
  assert(p1.text.includes('Use a copy that is legally available to you.'),'licensed-copy guidance missing');
  assert(p1.text.includes('iClub does not copy protected Cambridge or coursebook material into this library.'),'copyright boundary copy missing');
  assert(p1.materialKeys.length===4,'P1 library should contain three shared materials plus one P1 reference');
  assert(p1.externalButtons.length===3,'only official external resources should be clickable');
  assert(p1.externalButtons.every(url=>url.startsWith('https://')),'non-HTTPS external resource exposed');

  const calls = p1.calls.filter(x=>x.name==='get_exam_prep_materials_library_safe_v1');
  assert(calls.length===1,'Materials Library safe RPC should be called exactly once');
  assert(calls[0].args.p_language==='en','Materials Library language was not forwarded');

  for (const forbidden of [
    'submit_exam_prep_response_safe_v1','finalize_exam_prep_session_safe_v1','finalize_exam_prep_timed_safe_v1',
    'save_exam_prep_exam_profile_v2','generate_exam_prep_weekly_plan_safe_v3'
  ]) assert(!p1.calls.some(x=>x.name===forbidden),`${forbidden} must not be called by Materials Library`);

  assert(!/source_level|rights_status|can_define_scope|can_define_coverage|downstream_only|metadata_only_external|controlled_beta/i.test(p1.text),'internal source-governance terminology leaked to learner UI');

  await page.click('[data-ep-materials-external]');
  const opened = await page.evaluate(() => window.__opened.slice());
  assert(opened.length===1 && opened[0].startsWith('https://'),'official source did not open through a safe HTTPS link');

  await browser.close();
  console.log('P2-10 Materials Library learner UI: PASS');
})().catch(error => { console.error(error); process.exit(1); });
