const { chromium } = require('playwright');
const path = require('path');

const assert = (condition, message) => {
  if (!condition) throw new Error(`P2-03 browser regression: ${message}`);
};

(async () => {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage({ viewport: { width: 390, height: 844 } });

  await page.setContent(`
    <!doctype html>
    <html lang="en">
      <body>
        <div id="exam-prep-host-root">
          <div class="ep-live-card">
            <div class="ep-live-timed-row"><button data-ep-live-timed-start="231">Start timed 1</button></div>
            <div class="ep-live-timed-row"><button data-ep-live-timed-start="233">Start timed 2</button></div>
            <div class="ep-live-timed-row"><button data-ep-live-timed-start="235">Start modified</button></div>
            <div class="ep-live-timed-row"><button data-ep-live-timed-start="237">Start full</button></div>
          </div>
        </div>
      </body>
    </html>
  `);

  await page.evaluate(() => {
    window.__originalStarts = 0;
    document.querySelectorAll('[data-ep-live-timed-start]').forEach(button => {
      button.addEventListener('click', () => { window.__originalStarts += 1; });
    });
    window.i18n = { getLang: () => 'en' };
    const p1 = {
      component_code: 'P1',
      external_resources: [{
        resource_id: 1,
        rights_status: 'metadata_only_external',
        official_url: 'https://www.cambridgeinternational.org/programmes-and-qualifications/cambridge-international-as-and-a-level-mathematics-9709/past-papers/'
      }],
      original_full_simulations: [
        { assessment_id: 237, attempt_kind: 'full_paper', marks_available: 75 }
      ],
      similar_practice: [
        { assessment_id: 231, attempt_kind: 'timed_section', marks_available: 15 },
        { assessment_id: 233, attempt_kind: 'timed_section', marks_available: 15 },
        { assessment_id: 235, attempt_kind: 'modified_paper', marks_available: 20 },
        { assessment_id: 999999, attempt_kind: 'timed_section', marks_available: 15 }
      ],
      copyright_boundary: {
        stores_official_question_content: false,
        stores_official_mark_schemes: false,
        stores_official_answer_keys: false,
        external_metadata_only: true
      }
    };
    const p5 = {
      component_code: 'P5',
      external_resources: [],
      original_full_simulations: [{ assessment_id: 999001, attempt_kind: 'full_paper', marks_available: 50 }],
      similar_practice: [{ assessment_id: 999002, attempt_kind: 'timed_section', marks_available: 15 }],
      copyright_boundary: {
        stores_official_question_content: false,
        stores_official_mark_schemes: false,
        stores_official_answer_keys: false,
        external_metadata_only: true
      }
    };
    window.iClubExamPrepHostInternal = {
      lastCapabilities: { coreAccess: true, killSwitch: false, rolloutState: 'controlled_beta' },
      api: {
        pastPaperCompanion: async component => ({ ok: true, data: component === 'P1' ? p1 : p5 })
      }
    };
  });

  await page.addScriptTag({ path: path.resolve('exam-prep/exam-prep-past-paper.js') });
  await page.waitForSelector('[data-ep-past-paper="P1"]');

  const summary = await page.evaluate(() => {
    const panel = document.querySelector('[data-ep-past-paper="P1"]');
    const official = panel?.querySelector('.ep-past-paper-link');
    const actions = Array.from(panel?.querySelectorAll('[data-ep-past-paper-start]') || []);
    return {
      panel: Boolean(panel),
      officialHref: official?.href || '',
      officialRel: official?.rel || '',
      actionIds: actions.map(button => Number(button.dataset.epPastPaperStart)),
      labels: actions.map(button => button.textContent),
      text: panel?.innerText || ''
    };
  });

  assert(summary.panel, 'P1 companion panel missing');
  assert(summary.officialHref.startsWith('https://www.cambridgeinternational.org/'), 'official link hostname is not pinned');
  assert(summary.officialRel.includes('noopener') && summary.officialRel.includes('noreferrer'), 'external-link isolation missing');
  assert(JSON.stringify(summary.actionIds) === JSON.stringify([237,231,233,235]),
    `actions must include only currently visible governed catalog IDs, got ${JSON.stringify(summary.actionIds)}`);
  assert(!summary.actionIds.includes(999999), 'hidden/unavailable Similar Practice leaked into actionable UI');
  assert(summary.text.includes('Full paper 1') && summary.text.includes('Timed practice 1') &&
         summary.text.includes('Timed practice 2') && summary.text.includes('Modified paper 1'),
    'per-type learner action numbering/labels are incorrect');

  await page.locator('[data-ep-past-paper-start="231"]').click();
  const afterClick = await page.evaluate(() => ({
    starts: window.__originalStarts,
    activeId: Number(document.activeElement?.dataset?.epLiveTimedStart || 0)
  }));
  assert(afterClick.starts === 0, 'companion action started an assessment instead of navigating safely');
  assert(afterClick.activeId === 231, 'companion action did not focus the existing governed catalog control');

  await browser.close();
  console.log('P2-03 Past Paper Companion actionable links browser regression: GREEN');
})().catch(error => {
  console.error(error);
  process.exit(1);
});
