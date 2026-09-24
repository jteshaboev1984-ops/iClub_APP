'use strict';
const assert = require('node:assert/strict');
const path = require('node:path');
const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({headless:true});
  try {
    for (const language of ['ru','uz','en']) {
      // Current component-first route: route cards intentionally do not receive
      // the legacy Progress UX overview panels. They must therefore never be
      // hidden behind the old dashboard hydration gate.
      const componentPage = await browser.newPage({viewport:{width:320,height:750}});
      await componentPage.setContent(`<!doctype html><html lang="${language}"><head></head><body>
        <div id="exam-prep-host-root"><section class="ep-host-shell ep-live"><div class="ep-live-grid">
          <button class="ep-live-component-card ep-live-component-entry" data-ep-live-component="P1" data-ep-component-entry="1">P1</button>
          <button class="ep-live-component-card ep-live-component-entry" data-ep-live-component="P5" data-ep-component-entry="1">P5</button>
        </div></section></div></body></html>`);
      await componentPage.evaluate(lang => {
        window.iClubExamPrepProgressUxEnabled = true;
        window.i18n = {getLang:()=>lang};
        window.iClubExamPrepHostInternal = {lastCapabilities:{coreAccess:true,killSwitch:false,rolloutState:'controlled_beta'}};
      },language);
      await componentPage.addStyleTag({path:path.resolve('exam-prep/exam-prep-progress-ux-stability.css')});
      await componentPage.addScriptTag({path:path.resolve('exam-prep/exam-prep-progress-ux-stability.js')});
      await componentPage.waitForTimeout(250);
      assert.equal(await componentPage.locator('#exam-prep-host-root').getAttribute('data-ep-pux-loading'),null,
        `${language}: compact P1/P5 route screen must not wait for removed overview panels`);

      await componentPage.evaluate(() => {
        document.querySelector('#exam-prep-host-root').innerHTML = `<section class="ep-host-shell ep-live">
          <section data-ep-component-home="P1"><button data-ep-component-primary="diagnostic">Continue</button></section>
        </section>`;
      });
      await componentPage.click('[data-ep-component-primary="diagnostic"]');
      assert.equal(await componentPage.locator('#exam-prep-host-root').getAttribute('data-ep-pux-loading'),'question',
        `${language}: component CTA must arm the question transition`);
      await componentPage.evaluate(() => {
        document.querySelector('#exam-prep-host-root').innerHTML = '<section class="ep-host-shell ep-live"><div role="status">Loading…</div></section>';
      });
      await componentPage.waitForTimeout(100);
      await componentPage.evaluate(() => {
        document.querySelector('#exam-prep-host-root').innerHTML = `<section class="ep-host-shell ep-live"><div class="ep-live-card">
          <div class="ep-live-head"><strong>Question 1 / 2</strong></div><div class="ep-live-qtext">Loaded question</div>
          <div class="ep-live-options"><label><input type="radio">Answer</label></div>
          <button data-ep-live-submit>Submit</button></div></section>`;
      });
      await componentPage.waitForFunction(()=>!document.querySelector('#exam-prep-host-root').dataset.epPuxLoading);
      assert.equal(await componentPage.locator('.ep-live-qtext').innerText(),'Loaded question',
        `${language}: loaded question must be visible after component CTA`);
      await componentPage.close();

      const page = await browser.newPage({viewport:{width:320,height:750}});
      await page.setContent(`<!doctype html><html lang="${language}"><head></head><body>
        <div id="exam-prep-host-root"><section class="ep-host-shell ep-live"><div class="ep-live-grid">
        <article class="ep-live-component-card" data-ep-live-component="P1"><div class="ep-live-actions"></div></article>
        <article class="ep-live-component-card" data-ep-live-component="P5"><div class="ep-live-actions"></div></article>
        </div><div class="ep-live-dashboard-profile"><strong>Saved plan</strong></div></section></div></body></html>`);
      await page.evaluate(lang => {
        window.iClubExamPrepProgressUxEnabled = true;
        window.i18n = {getLang:()=>lang};
        window.iClubExamPrepHostInternal = {lastCapabilities:{coreAccess:true,killSwitch:false,rolloutState:'controlled_beta'}};
      },language);
      await page.addStyleTag({path:path.resolve('exam-prep/exam-prep-progress-ux-stability.css')});
      await page.addScriptTag({path:path.resolve('exam-prep/exam-prep-progress-ux-stability.js')});
      await page.waitForFunction(()=>document.querySelector('#exam-prep-host-root').dataset.epPuxLoading==='dashboard');
      const root = '#exam-prep-host-root';
      assert.equal(await page.locator(`${root} .ep-pux-overview`).count(),0);
      await page.evaluate(()=>{
        document.querySelector('[data-ep-live-component="P1"]').insertAdjacentHTML('beforeend','<section class="ep-pux-overview">P1 goals</section>');
      });
      await page.waitForTimeout(160);
      assert.equal(await page.locator(root).getAttribute('data-ep-pux-loading'),'dashboard','first component alone must not reveal dashboard');
      await page.evaluate(()=>{
        document.querySelector('[data-ep-live-component="P5"]').insertAdjacentHTML('beforeend','<section class="ep-pux-overview">P5 goals</section>');
      });
      await page.waitForTimeout(160);
      assert.equal(await page.locator(root).getAttribute('data-ep-pux-loading'),'dashboard','missing saved-plan edit must not reveal intermediate UI');
      await page.evaluate(()=>{
        document.querySelector('.ep-live-dashboard-profile').insertAdjacentHTML('beforeend','<button data-ep-exam-plan-edit>Change plan</button>');
        document.querySelector('.ep-live-component-card').insertAdjacentHTML('beforeend','<button data-ep-live-plan="P1">Plan</button>');
      });
      await page.waitForFunction(()=>!document.querySelector('#exam-prep-host-root').dataset.epPuxLoading);
      assert.equal(await page.locator(root).getAttribute('aria-busy'),null,'ready dashboard must release busy state');

      await page.click('[data-ep-live-plan="P1"]');
      assert.equal(await page.locator(root).getAttribute('data-ep-pux-loading'),'plan','plan transition must be masked immediately');
      await page.evaluate(()=>{
        document.querySelector('#exam-prep-host-root').innerHTML = `<section class="ep-host-shell ep-live"><div class="ep-live-card">
        <div class="ep-live-head"><strong>P1 · Weekly plan</strong></div>
        <div class="ep-live-plan-item"><div><strong>Learning</strong></div><button data-ep-live-plan-item="1">Start</button></div>
        <div class="ep-live-plan-item"><div><strong>Learning</strong></div></div>
        </div></section>`;
      });
      await page.waitForTimeout(160);
      assert.equal(await page.locator(root).getAttribute('data-ep-pux-loading'),'plan','unhydrated weekly plan must remain masked');
      await page.evaluate(()=>{
        document.querySelector('.ep-live-card').insertAdjacentHTML('beforeend','<section class="ep-pux-week">Two stable goals</section>');
      });
      await page.waitForTimeout(160);
      assert.equal(await page.locator(root).getAttribute('data-ep-pux-loading'),'plan','goal counter must wait for enriched task titles');
      await page.evaluate(()=>{
        document.querySelectorAll('.ep-live-plan-item').forEach(row => {
          row.dataset.epFlowPlan='flowux4';
          row.querySelector('strong').textContent='Final task title';
        });
      });
      await page.waitForFunction(()=>!document.querySelector('#exam-prep-host-root').dataset.epPuxLoading);
      assert.equal(await page.locator('.ep-pux-week').count(),1);

      await page.click('[data-ep-live-plan-item="1"]');
      assert.equal(await page.locator(root).getAttribute('data-ep-pux-loading'),'question','question request must show loading');
      await page.evaluate(()=>{
        document.querySelector('#exam-prep-host-root').innerHTML=`<section class="ep-host-shell ep-live" data-ep-transition-hold="1">
        <div class="ep-live-card"><div class="ep-live-head"><strong>P1 · Weekly plan</strong></div>
        <div class="ep-live-plan-item"><strong>Old task</strong></div><section class="ep-pux-week">Old goals</section></div></section>`;
      });
      await page.waitForTimeout(180);
      assert.equal(await page.locator(root).getAttribute('data-ep-pux-loading'),'question','disabled previous plan must not be mistaken for ready new plan');
      await page.evaluate(()=>{
        document.querySelector('#exam-prep-host-root').innerHTML=`<section class="ep-host-shell ep-live"><div role="status">Loading…</div></section>`;
      });
      await page.waitForTimeout(160);
      assert.equal(await page.locator(root).getAttribute('data-ep-pux-loading'),'question','loading status must remain covered');
      await page.evaluate(()=>{
        document.querySelector('#exam-prep-host-root').innerHTML=`<section class="ep-host-shell ep-live"><div class="ep-live-card">
        <div class="ep-live-head"><strong>Question 1 / 2</strong></div><div class="ep-live-qtext">A complete question</div>
        <div class="ep-live-options"><label><input name="answer" type="radio">Answer</label></div>
        <button data-ep-live-submit>Submit</button></div></section>`;
      });
      await page.waitForFunction(()=>!document.querySelector('#exam-prep-host-root').dataset.epPuxLoading);
      await page.click('[data-ep-live-submit]');
      assert.equal(await page.locator(root).getAttribute('data-ep-pux-loading'),'question');
      await page.evaluate(()=>{
        document.querySelector('#exam-prep-host-root').innerHTML=`<section class="ep-flow-pending-visual">
        <div class="ep-live-qtext">Old question held while saving</div><div class="ep-live-options">Old answers</div><button data-ep-live-submit disabled>Saving</button></section>`;
      });
      await page.waitForTimeout(180);
      assert.equal(await page.locator(root).getAttribute('data-ep-pux-loading'),'question','held old question must not uncover during answer save');
      await page.evaluate(()=>{
        document.querySelector('#exam-prep-host-root').innerHTML=`<section><div class="ep-live-qtext">New question</div>
        <div class="ep-live-options">New answers</div><button data-ep-live-submit>Submit</button></section>`;
      });
      await page.waitForFunction(()=>!document.querySelector('#exam-prep-host-root').dataset.epPuxLoading);

      await page.evaluate(()=>{
        document.querySelector('#exam-prep-host-root').innerHTML=`<section><button data-ep-live-plan="P1">Open plan</button></section>`;
      });
      await page.click('[data-ep-live-plan="P1"]');
      await page.evaluate(()=>{
        document.querySelector('#exam-prep-host-root').innerHTML='<section class="ep-host-shell ep-live"><div class="ep-live-error">Could not load plan.</div></section>';
      });
      await page.waitForFunction(()=>!document.querySelector('#exam-prep-host-root').dataset.epPuxLoading);
      assert.equal(await page.locator('.ep-live-error').count(),1,'failed request must show the existing error instead of endless loading');
      await page.evaluate(()=>{
        document.querySelector('#exam-prep-host-root').innerHTML='<section><div role="status">Loading…</div></section>';
      });
      await page.waitForFunction(()=>document.querySelector('#exam-prep-host-root').dataset.epPuxLoading==='question');
      await page.evaluate(()=>{window.iClubExamPrepProgressUxEnabled=false;document.querySelector('#exam-prep-host-root').setAttribute('aria-hidden','true');});
      await page.waitForFunction(()=>!document.querySelector('#exam-prep-host-root').dataset.epPuxLoading);
      assert.equal(await page.locator(root).getAttribute('aria-busy'),null,'revoking feature must release visual gate');
      await page.close();
    }
    console.log('Atomic presentation: PASS RU/UZ/EN, 320px, dashboard/plan/question, held screen, error and revocation');
  } finally {await browser.close();}
})().catch(error=>{console.error(error);process.exit(1);});