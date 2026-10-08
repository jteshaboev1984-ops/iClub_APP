#!/usr/bin/env node
"use strict";

// Standalone, no-account browser verification of approved registration v2.
// It never opens production or uses a real learner identity.
const path = require("node:path");
const { pathToFileURL } = require("node:url");
const { chromium } = require("playwright");

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

const previewUrl = pathToFileURL(path.resolve(__dirname, "../qa/iclub-registration-v2-preview.html")).href;
const plans = ["free","plus","pro"];
const langs = ["ru","uz","en"];
const roles = ["yes","no"];
const modes = ["new","existing"];
const sizes = [{width:320,height:720},{width:390,height:844}];

async function testScenario(browser, {width,height,lang,role,mode,plan}) {
  const page = await browser.newPage({ viewport:{width,height} });
  const errors = [];
  const outsideRequests = [];
  page.on("pageerror", error => errors.push(String(error?.stack || error)));
  page.on("request", request => {
    if (!request.url().startsWith("file:")) outsideRequests.push(request.url());
  });
  const tag = [width,lang,role,mode,plan].join("/");

  try {
    await page.goto(previewUrl, {waitUntil:"load"});
    await page.locator("#lang").selectOption(lang);
    await page.locator("#mode").selectOption(mode);
    await page.locator("#school").selectOption(role);
    await page.locator('[data-plan="'+plan+'"]').click();

    const current = () => page.evaluate(() => window.__iclubRegistrationPreview.snapshot());
    let data = await current();
    assert(data.plan === plan && data.mode === mode && data.school === (role === "yes"),tag+" wrong preview settings");
    assert(await page.locator("#existing-panel").isVisible() === (mode === "existing"),tag+" existing profile confirmation mismatch");
    assert((await page.locator("#preview").innerText()).includes("iClub"),tag+" app branding missing");
    const text = await page.locator("#preview").innerText();
    assert(!/\bCompetitive\b|\binternal units\b|\bprovider\b/i.test(text),tag+" technical copy leaked");
    assert(await page.locator("#study-count").textContent() ===
      (plan === "pro" ? "5/5" : (mode === "existing" ? "1" : "0") + "/" + (plan === "plus" ? "3" : "1")),
      tag+" unexpected initial study count");

    if (plan === "free") {
      assert(await page.locator('[data-kind="competition"]').count() === 0,tag+" Free has duplicate competition selector");
      assert(await page.locator("#continue").isDisabled() === (mode === "new"),tag+" unexpected Free continue state");
      await page.locator('[data-kind="study"][data-subject="biology"]').click();
      data = await current();
      assert(data.study.length === 1 && data.study[0] === "biology",tag+" Free must have exactly one chosen study subject");
      assert(data.competitive.length === (role === "yes" ? 1 : 0),tag+" Free school eligibility mismatch");
      if (role === "yes") assert(data.competitive[0] === "biology",tag+" Free Competition not the same subject");
      await page.locator('[data-kind="study"][data-subject="mathematics"]').click();
      data = await current();
      assert(data.study.join() === "mathematics" && data.competitive.join() === (role === "yes" ? "mathematics" : ""),tag+" Free subject swap failed");
    } else if (plan === "plus") {
      for (const key of ["biology","chemistry","economics","informatics","mathematics"]) {
        data = await current();
        if (data.study.length >= 3) break;
        if (!data.study.includes(key)) await page.locator('[data-kind="study"][data-subject="'+key+'"]').click();
      }
      data = await current();
      assert(data.study.length === 3,tag+" Plus should allow three study subjects");
      const fourth = ["biology","chemistry","economics","informatics","mathematics"].find(x => !data.study.includes(x));
      await page.locator('[data-kind="study"][data-subject="'+fourth+'"]').click();
      assert((await current()).study.length === 3,tag+" Plus allowed a fourth study subject");
      if(role==="yes") {
        // Existing users may carry an auto-selected Free competition slot.
        // Clear it in this isolated preview before exercising the Plus 2-slot cap.
        for (const selected of (await current()).competitive) {
          await page.locator('[data-kind="competition"][data-subject="'+selected+'"]').click();
        }
        const chosen = (await current()).study;
        await page.locator('[data-kind="competition"][data-subject="'+chosen[0]+'"]').click();
        await page.locator('[data-kind="competition"][data-subject="'+chosen[1]+'"]').click();
        await page.locator('[data-kind="competition"][data-subject="'+chosen[2]+'"]').click();
        assert((await current()).competitive.length === 2,tag+" Plus allowed three competition subjects");
        await page.locator('[data-kind="study"][data-subject="'+chosen[0]+'"]').click();
        assert(!(await current()).competitive.includes(chosen[0]),tag+" removed Study remained Competitive");
      } else {
        assert(await page.locator('[data-kind="competition"]').count() === 0,tag+" non-school Plus got competition choices");
      }
    } else {
      data = await current();
      assert(data.study.length === 5,tag+" Pro must include all five active subjects");
      assert(await page.locator('[data-kind="study"]').count() === 0,tag+" Pro must not have five unnecessary toggles");
      if(role==="yes") {
        // Start from no Competitive picks so this test measures the cap, not a toggle-off.
        for (const selected of (await current()).competitive) {
          await page.locator('[data-kind="competition"][data-subject="'+selected+'"]').click();
        }
        for(const key of ["biology","mathematics","economics"]) await page.locator('[data-kind="competition"][data-subject="'+key+'"]').click();
        assert((await current()).competitive.length === 2,tag+" Pro allowed three competition choices");
      } else {
        assert((await current()).competitive.length === 0,tag+" non-school Pro got competition access");
      }
    }

    assert(await page.locator("#continue").isEnabled(),tag+" selection did not enable continue");
    await page.locator("#continue").click();
    assert((await page.locator("#result").textContent()).trim().length > 0,tag+" preview finish message missing");
    assert((await page.locator("#preview").evaluate(el => el.scrollWidth)) <= width + 2,tag+" mobile horizontal overflow");
    assert(outsideRequests.length===0,tag+" preview unexpectedly accessed network: "+outsideRequests.join());
    assert(errors.length===0,tag+" browser errors: "+errors.join());
  } finally {
    await page.close();
  }
}

(async() => {
  const browser = await chromium.launch({headless:true});
  let passed = 0;
  try {
    for (const size of sizes) {
      for (const lang of langs) {
        for (const role of roles) {
          for (const mode of modes) {
            for (const plan of plans) {
              await testScenario(browser,{...size,lang,role,mode,plan});
              passed++;
            }
          }
        }
      }
    }
    assert(passed===72,"registration v2 preview matrix incomplete");
    console.log("iClub Registration v2 approved preview: 72/72 GREEN; no real accounts, network, DB or storage writes.");
  } finally {
    await browser.close();
  }
})().catch(e => { console.error(e); process.exitCode=1; });
