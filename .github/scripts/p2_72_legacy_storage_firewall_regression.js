const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

const assert = (condition, message) => { if (!condition) throw new Error(message); };
const read = file => fs.readFileSync(file, 'utf8');

(async () => {
  const forbiddenKeys = [
    'iclub_state_v1',
    'iclub_profile_v1',
    'iclub_practice_draft_v1',
    'iclub_pending_ops_v1'
  ];

  // Live Exam Prep is server-owned and must not have any browser-storage write path.
  for (const file of [
    'exam-prep/exam-prep-api.js',
    'exam-prep/exam-prep-host.js',
    'exam-prep/exam-prep-live.js'
  ]) {
    const source = read(file);
    assert(!/localStorage/i.test(source), `${file} must not access legacy localStorage`);
    assert(!/sessionStorage/i.test(source), `${file} must not access legacy sessionStorage`);
    for (const key of forbiddenKeys) {
      assert(!source.includes(key), `${file} references forbidden legacy storage key ${key}`);
    }
  }

  const configSource = read('exam-prep/exam-prep-config.js');
  const storeSource = read('exam-prep/exam-prep-store.js');
  for (const key of forbiddenKeys) {
    assert(configSource.includes(`"${key}"`), `preview config must explicitly forbid ${key}`);
  }
  assert(configSource.includes('previewStoragePrefix: "iclub_exam_prep_preview_"'), 'preview storage namespace drift');
  assert(storeSource.includes('localStorage.setItem(KEY'), 'preview store must write only through its scoped KEY');
  assert(!/localStorage\.(?:removeItem|clear)\s*\(/i.test(storeSource), 'preview store may not remove/clear browser storage');

  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();
  await page.route('http://iclub.test/', route => route.fulfill({
    status: 200,
    contentType: 'text/html',
    body: '<!doctype html><html><body></body></html>'
  }));
  await page.goto('http://iclub.test/');

  const sentinels = Object.fromEntries(forbiddenKeys.map((key, i) => [key, JSON.stringify({ sentinel: i + 1, value: `preserve-${i + 1}` })]));
  sentinels.p272_unrelated_key = 'preserve-unrelated';

  await page.evaluate(values => {
    for (const [key, value] of Object.entries(values)) localStorage.setItem(key, value);
    window.__p272StorageCalls = [];
    const nativeSet = Storage.prototype.setItem;
    const nativeRemove = Storage.prototype.removeItem;
    const nativeClear = Storage.prototype.clear;
    Storage.prototype.setItem = function(key, value) {
      window.__p272StorageCalls.push({ op: 'set', key: String(key) });
      return nativeSet.call(this, key, value);
    };
    Storage.prototype.removeItem = function(key) {
      window.__p272StorageCalls.push({ op: 'remove', key: String(key) });
      return nativeRemove.call(this, key);
    };
    Storage.prototype.clear = function() {
      window.__p272StorageCalls.push({ op: 'clear', key: '*' });
      return nativeClear.call(this);
    };
  }, sentinels);

  await page.addScriptTag({ path: path.resolve('exam-prep/exam-prep-config.js') });
  await page.addScriptTag({ path: path.resolve('exam-prep/exam-prep-contracts.js') });
  await page.addScriptTag({ path: path.resolve('exam-prep/exam-prep-static-data.js') });
  await page.addScriptTag({ path: path.resolve('exam-prep/exam-prep-store.js') });

  const result = await page.evaluate(values => {
    const store = window.iClubExamPrepPreview.store;
    store.assertNoLegacyKeyUse();
    store.load();
    store.set({ lang: 'en', component: 'P5', route: 'weekly-plan', mode: 'core' });
    const after = {};
    for (const key of Object.keys(values)) after[key] = localStorage.getItem(key);
    return {
      scopedKey: store.KEY,
      scopedValue: localStorage.getItem(store.KEY),
      after,
      calls: window.__p272StorageCalls
    };
  }, sentinels);

  assert(result.scopedKey === 'iclub_exam_prep_preview_ui_v1', `unexpected Exam Prep preview storage key ${result.scopedKey}`);
  assert(result.scopedValue, 'Exam Prep preview scoped value missing');
  for (const [key, value] of Object.entries(sentinels)) {
    assert(result.after[key] === value, `Exam Prep mutated legacy/unrelated browser storage key ${key}`);
  }
  assert(result.calls.length >= 1, 'expected scoped preview storage write was not observed');
  for (const call of result.calls) {
    assert(call.op === 'set', `Exam Prep preview attempted destructive storage operation ${call.op}`);
    assert(call.key.startsWith('iclub_exam_prep_preview_'), `Exam Prep preview wrote outside scoped namespace: ${call.key}`);
  }

  await browser.close();
  console.log('P2-72 legacy browser storage firewall regression: GREEN');
})().catch(error => {
  console.error(error);
  process.exit(1);
});
