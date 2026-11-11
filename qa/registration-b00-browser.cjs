/* Isolated read-only browser test for the actual registration markup and B00 adapter.
   Intentionally NEVER loads app.js, Supabase, Telegram, or an external service. */
"use strict";
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const { chromium } = require("playwright");

(async () => {
  const root = path.resolve(__dirname, "..");
  const source = fs.readFileSync(path.join(root, "index.html"), "utf8");
  const registration = source.match(/<section id="view-registration"[\s\S]*?<\/section>/)?.[0];
  assert.ok(registration, "Real registration section must exist");
  const markup = registration.replace('class="view"', 'class="view is-active"');
  const browser = await chromium.launch({ headless: true });
  try {
    for (const width of [320, 375, 390, 1440]) {
      const page = await browser.newPage({ viewport: { width, height: 840 }, deviceScaleFactor: 1 });
      try {
        await page.setContent('<!doctype html><html lang="ru"><head><meta charset="utf-8">' +
          '<meta name="viewport" content="width=device-width,initial-scale=1"></head>' +
          '<body class="iclub-visual-v3"><main class="main">' + markup + '</main></body></html>');
        for (const css of ["style.css", "visual/iclub-visual-v3.css",
          "visual/iclub-premium-v3.css", "visual/iclub-registration-b00.css"]) {
          await page.addStyleTag({ path: path.join(root, css) });
        }
        await page.addScriptTag({ path: path.join(root, "registration-b00-ui.js") });

        assert.equal(await page.locator("#reg-form").count(), 1);
        assert.equal(await page.locator("#reg-submit").count(), 1);
        assert.equal(await page.locator("#reg-consent").count(), 1);
        assert.equal(await page.locator("#reg-b00-step-one").isVisible(), true);
        assert.equal(await page.locator("#reg-b00-step-two").isVisible(), false);
        assert.match(await page.locator(".reg-b00-counter").innerText(), /1 из 2/i);
        assert.deepEqual(await page.locator("#reg-class option").allTextContents(), ["7", "8", "9", "10", "11"]);

        // Step 1 may not advance until existing required fields are valid.
        await page.locator(".reg-b00-next").click();
        assert.equal(await page.locator("#reg-b00-step-one").isVisible(), true);

        await page.locator("#reg-fullname").fill("Example Student");
        await page.evaluate(() => {
          const region = document.getElementById("reg-region");
          const district = document.getElementById("reg-district");
          region.add(new Option("Example region", "1"));
          region.value = "1";
        });
        // A selected region cannot bypass a still-disabled district picker.
        await page.locator(".reg-b00-next").click();
        assert.equal(await page.locator("#reg-b00-step-one").isVisible(), true);
        await page.evaluate(() => {
          const district = document.getElementById("reg-district");
          district.add(new Option("Example district", "2"));
          district.disabled = false;
          district.value = "2";
        });
        await page.locator(".reg-b00-next").click();
        assert.equal(await page.locator("#reg-b00-step-one").isVisible(), false);
        assert.equal(await page.locator("#reg-b00-step-two").isVisible(), true);
        assert.match(await page.locator(".reg-b00-counter").innerText(), /2 из 2/i);

        // The same real form fields and values survive both navigation directions.
        await page.locator(".reg-b00-prev").click();
        assert.equal(await page.locator("#reg-fullname").inputValue(), "Example Student");
        assert.equal(await page.locator("#reg-region").inputValue(), "1");
        assert.equal(await page.locator("#reg-district").inputValue(), "2");
        assert.equal(await page.locator("#reg-b00-step-one").isVisible(), true);

        // Pressing Enter on Step 1 is navigation, not accidental final submit.
        await page.evaluate(() => {
          window.b00Submits = 0;
          document.getElementById("reg-form").addEventListener("submit", (event) => {
            event.preventDefault();
            window.b00Submits += 1;
          });
        });
        await page.locator("#reg-fullname").press("Enter");
        assert.equal(await page.locator("#reg-b00-step-two").isVisible(), true);
        assert.equal(await page.evaluate(() => window.b00Submits), 0);

        // One final native submission: no new save handler.
        await page.locator("#reg-consent").check();
        await page.locator("#reg-submit").click();
        assert.equal(await page.evaluate(() => window.b00Submits), 1);

        await page.locator(".reg-b00-prev").click();
        await page.locator("#reg-language").selectOption("uz");
        assert.match(await page.locator(".reg-b00-counter").innerText(), /1-bosqich/);
        await page.locator(".reg-b00-next").click();

        // no horizontal overflow at all mobile/desktop breakpoints.
        const metrics = await page.evaluate(() => ({
          viewport: window.innerWidth,
          content: document.documentElement.scrollWidth,
          subjectDisplay: getComputedStyle(document.getElementById("reg-subject-chips")).display,
          iconWidth: parseFloat(getComputedStyle(document.querySelector("#reg-subject-chips .chip-btn"), "::before").width) || 0,
          offending: Array.from(document.querySelectorAll("body *")).map(el => {
            const r = el.getBoundingClientRect();
            return { tag: el.tagName, id: el.id, className: typeof el.className === "string" ? el.className.slice(0, 90) : "", left: Math.round(r.left), right: Math.round(r.right), scrollWidth: el.scrollWidth };
          }).filter(x => x.right > window.innerWidth + 1 || x.left < -1).slice(0, 12)
        }));
        assert.ok(metrics.content <= metrics.viewport + 1,
          `Horizontal overflow at ${width}px: ${JSON.stringify(metrics)}`);
        assert.equal(metrics.subjectDisplay, "flex",
          `Subject chips use the SAME wrapping Stitch-style layout at ${width}px`);
        assert.ok(metrics.iconWidth >= 16,
          `Each subject chip has a visible decorative icon at ${width}px`);
        assert.equal(await page.locator(".reg-b00-fields-card > label.field").count(), 4);
        assert.equal(await page.locator("#reg-b00-step-one > .reg-b00-next").count(), 1);
        assert.equal(await page.locator(".reg-b00-school-card > .reg-toggle").count(), 1);
        assert.equal(await page.locator(".reg-b00-school-card > #reg-school-block").count(), 1);

        if (width === 390) {
          await page.screenshot({ path: path.join(root, "b00-qa-step2-390.png"), fullPage: true });
          await page.locator(".reg-b00-prev").click();
          await page.screenshot({ path: path.join(root, "b00-qa-step1-390.png"), fullPage: true });
        }
        process.stdout.write(`PASS registration B00 at ${width}px: navigation/validity/submit/locale/overflow\n`);
      } finally {
        await page.close();
      }
    }
  } finally {
    await browser.close();
  }
})().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
