const { chromium } = require('playwright');
const path = require('path');

const assert = (condition, message) => { if (!condition) throw new Error(message); };

(async () => {
  const seed = Number(process.env.P273_SEED || 0);
  const candidateSha = String(process.env.P273_CANDIDATE_SHA || '').toLowerCase();
  assert(Number.isInteger(seed) && seed > 0, 'P2-73 deterministic seed is required');
  assert(/^[0-9a-f]{40}$/.test(candidateSha), 'P2-73 exact candidate SHA is required');

  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();
  await page.route('http://iclub.test/', route => route.fulfill({
    status: 200,
    contentType: 'text/html',
    body: '<!doctype html><html><body></body></html>'
  }));
  await page.goto('http://iclub.test/');

  for (const file of [
    'exam-prep/exam-prep-config.js',
    'exam-prep/exam-prep-contracts.js',
    'exam-prep/exam-prep-static-data.js',
    'exam-prep/exam-prep-engine.js'
  ]) {
    await page.addScriptTag({ path: path.resolve(file) });
  }

  const result = await page.evaluate(seedValue => {
    const root = window.iClubExamPrepPreview;
    const profiles = root.staticData.profiles;
    const langs = ['en', 'ru', 'uz'];
    const components = ['P1', 'P5'];
    const offset = seedValue % profiles.length;
    const ordered = profiles.slice(offset).concat(profiles.slice(0, offset));
    const seen = [];

    for (const profile of ordered) {
      if (!root.engine.assertAcademicParity(profile.id)) {
        throw new Error(`academic parity failed for ${profile.id}`);
      }
      for (const lang of langs) {
        for (const component of components) {
          const core = root.engine.buildViewModel({ profileId: profile.id, mode: 'core', lang, component });
          const ai = root.engine.buildViewModel({ profileId: profile.id, mode: 'ai', lang, component });
          if (!core || core.component.code !== component) throw new Error(`core render failed ${profile.id}/${lang}/${component}`);
          if (!ai || ai.component.code !== component) throw new Error(`ai render failed ${profile.id}/${lang}/${component}`);
          if (core.mentor.assigned || core.mentor.queueCount !== 0) throw new Error(`core mentor leakage ${profile.id}/${component}`);
          if (ai.mentor.assigned || ai.mentor.queueCount !== 0) throw new Error(`ai mentor leakage ${profile.id}/${component}`);
        }
      }
      seen.push(profile.id);
    }

    return {
      count: seen.length,
      unique: new Set(seen).size,
      first: seen[0],
      last: seen[seen.length - 1],
      locales: langs.length,
      components: components.length
    };
  }, seed);

  assert(result.count === 15 && result.unique === 15, `canonical profile rehearsal incomplete: ${JSON.stringify(result)}`);
  assert(result.locales === 3 && result.components === 2, 'locale/component rehearsal scope drift');

  await browser.close();
  console.log(`P2-73 canonical browser rehearsal: GREEN sha=${candidateSha} seed=${seed} profiles=15 locales=3 components=2 order=${result.first}->${result.last}`);
})().catch(error => {
  console.error(error);
  process.exit(1);
});
