const { chromium } = require('playwright');

const assert = (condition, message) => {
  if (!condition) throw new Error(message);
};

(async () => {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage({ viewport: { width: 1280, height: 900 } });
  const pageErrors = [];
  const localRequestFailures = [];

  page.on('pageerror', error => pageErrors.push(String(error?.stack || error?.message || error)));
  page.on('requestfailed', request => {
    try {
      const url = new URL(request.url());
      if (url.hostname === '127.0.0.1' || url.hostname === 'localhost') {
        localRequestFailures.push(`${request.method()} ${request.url()} :: ${request.failure()?.errorText || 'failed'}`);
      }
    } catch {}
  });

  const response = await page.goto('http://127.0.0.1:4173/', {
    waitUntil: 'domcontentloaded',
    timeout: 30000
  });
  assert(response && response.ok(), `root response not OK: ${response?.status()}`);
  await page.waitForTimeout(5000);

  const result = await page.evaluate(async () => {
    let directOpen = null;
    try {
      directOpen = await window.iClubExamPrep?.open?.({ subjectKey: 'mathematics', language: 'en' });
    } catch {
      directOpen = false;
    }

    return {
      bodyTextLen: (document.body?.innerText || '').trim().length,
      hasApp: Boolean(document.querySelector('#app')),
      hasActiveView: Boolean(document.querySelector('.view.is-active')),
      hasCourses: Boolean(document.querySelector('#view-courses')),
      hasPractice: Boolean(document.querySelector('#courses-practice-start')),
      hasTours: Boolean(document.querySelector('#courses-tours')),
      hasRatings: Boolean(document.querySelector('#view-ratings')),
      hasProfile: Boolean(document.querySelector('#view-profile')),
      hasCertificates: Boolean(document.querySelector('#view-certificates')),
      hostEntryExists: Boolean(document.querySelector('#subject-hub-exam-prep-entry')),
      hostEntryHidden: document.querySelector('#subject-hub-exam-prep-entry')?.hidden === true,
      hostRootHidden: document.querySelector('#exam-prep-host-root')?.hidden === true,
      hostFacade: typeof window.iClubExamPrep === 'object' && Boolean(window.iClubExamPrep),
      hostOpen: window.iClubExamPrep?.isOpen?.() === true,
      directOpen,
      scripts: Array.from(document.scripts).map(s => s.getAttribute('src') || ''),
      safeApi: {
        root: typeof window.iclubSafeAssessment === 'object' && Boolean(window.iclubSafeAssessment),
        practice: typeof window.iclubSafeAssessment?.practice === 'object' && Boolean(window.iclubSafeAssessment?.practice),
        practiceStart: typeof window.iclubSafeAssessment?.practice?.start === 'function',
        practiceReview: typeof window.iclubSafeAssessment?.practice?.review === 'function',
        practiceReset: typeof window.iclubSafeAssessment?.practice?.resetProgress === 'function',
        tour: typeof window.iclubSafeAssessment?.tour === 'object' && Boolean(window.iclubSafeAssessment?.tour),
        tourPreflight: typeof window.iclubSafeAssessment?.tour?.preflight === 'function',
        tourStart: typeof window.iclubSafeAssessment?.tour?.start === 'function',
        tourSubmit: typeof window.iclubSafeAssessment?.tour?.submit === 'function',
        tourFinalize: typeof window.iclubSafeAssessment?.tour?.finalize === 'function',
        tourReview: typeof window.iclubSafeAssessment?.tour?.review === 'function'
      }
    };
  });

  assert(result.bodyTextLen > 20, `page appears blank: bodyTextLen=${result.bodyTextLen}`);
  assert(result.hasApp && result.hasActiveView, 'legacy app shell/active view missing');
  assert(result.hasCourses && result.hasPractice && result.hasTours, 'legacy Courses/Practice/Tours DOM missing');
  assert(result.hasRatings && result.hasProfile && result.hasCertificates, 'legacy Ratings/Profile/Certificates DOM missing');
  assert(result.hostEntryExists && result.hostEntryHidden && result.hostRootHidden, 'Exam Prep must remain hidden with real OFF capability');
  assert(result.hostFacade && !result.hostOpen && result.directOpen !== true, 'direct Exam Prep open must fail closed while unauthenticated/OFF');
  assert(result.scripts.some(x => x.includes('security/legacy-assessment-safe-api.js?v=p002v4reset1')), 'legacy safe assessment API script missing');
  assert(result.scripts.some(x => x.includes('exam-prep/exam-prep-api.js?v=p014h1')), 'Exam Prep host API script missing');
  assert(result.scripts.some(x => x.includes('exam-prep/exam-prep-host.js?v=p014h1')), 'Exam Prep host controller script missing');
  assert(result.scripts.some(x => x.includes('app.js?v=support4-p0legacysaveoff1-p014host1')), 'P0-14 app cache key missing');
  assert(result.safeApi.root && result.safeApi.practice && result.safeApi.tour, 'legacy safe assessment facade missing');
  assert(result.safeApi.practiceStart && result.safeApi.practiceReview && result.safeApi.practiceReset, 'legacy safe Practice APIs missing');
  assert(result.safeApi.tourPreflight && result.safeApi.tourStart && result.safeApi.tourSubmit && result.safeApi.tourFinalize && result.safeApi.tourReview, 'legacy safe Tour APIs missing');
  assert(pageErrors.length === 0, `uncaught page errors: ${JSON.stringify(pageErrors)}`);
  assert(localRequestFailures.length === 0, `local asset request failures: ${JSON.stringify(localRequestFailures)}`);

  console.log(JSON.stringify({ ok: true, result, pageErrors, localRequestFailures }, null, 2));
  await browser.close();
})().catch(error => {
  console.error(error);
  process.exit(1);
});
