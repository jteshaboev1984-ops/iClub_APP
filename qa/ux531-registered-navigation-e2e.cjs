/* B00 full app.js + i18n.js integration QA, using an in-process fake backend.
   No real Supabase, Telegram services, production writes or external requests. */
"use strict";
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const http = require("node:http");
const { chromium } = require("playwright");

const root = path.resolve(__dirname, "..");
const mainHtml = fs.readFileSync(path.join(root, "index.html"), "utf8");
const pageHtml = mainHtml
  .replace(/<script\b[^>]*>[\s\S]*?<\/script>/gi, "")
  .replace(/<link\b[^>]*rel="stylesheet"[^>]*>/gi, "")
  .replace("</head>", [
    '<link rel="stylesheet" href="/style.css">',
    '<link rel="stylesheet" href="/visual/iclub-visual-v3.css">',
    '<link rel="stylesheet" href="/visual/iclub-premium-v3.css">',
    '<link rel="stylesheet" href="/visual/iclub-academy-v55-shell-b01.css">',
    '<link rel="stylesheet" href="/visual/iclub-academy-ux531-b02b03.css">',
    '<link rel="stylesheet" href="/visual/iclub-registration-b00.css">',
    '<link rel="stylesheet" href="/visual/iclub-academy-ux531-b04b08.css">',
    "</head>"
  ].join("\n"))
  .replace("</body>", [
    '<script src="/i18n.js"></script>',
    '<script src="/app.js"></script>',
    '<script src="/visual/iclub-academy-ux531-interactions.js"></script>',
    '<script src="/registration-b00-ui.js"></script>',
    "</body>"
  ].join("\n"));
const allowedFiles = new Set([
  "/style.css", "/visual/iclub-visual-v3.css",
  "/visual/iclub-premium-v3.css", "/visual/iclub-registration-b00.css",
  "/visual/iclub-academy-ux531-b04b08.css",
  "/i18n.js", "/app.js", "/registration-b00-ui.js", "/logo.png",
  "/visual/iclub-academy-v55-shell-b01.css", "/visual/iclub-academy-ux531-b02b03.css",
  "/visual/iclub-academy-ux531-interactions.js"
]);
const types = { ".js": "text/javascript", ".css": "text/css", ".png": "image/png" };
const server = http.createServer((req, res) => {
  let url;
  try { url = new URL(req.url, "http://127.0.0.1"); } catch { res.writeHead(400).end(); return; }
  if (url.pathname === "/") {
    res.writeHead(200, { "content-type": "text/html; charset=utf-8" });
    res.end(pageHtml);
    return;
  }
  if (!allowedFiles.has(url.pathname)) { res.writeHead(404).end(); return; }
  const filename = path.join(root, url.pathname.substring(1));
  try {
    const data = fs.readFileSync(filename);
    res.writeHead(200, { "content-type": types[path.extname(filename)] || "application/octet-stream" });
    res.end(data);
  } catch { res.writeHead(404).end(); }
});

async function launchCase(browser, baseUrl, { language, mode, width }) {
  const page = await browser.newPage({ viewport: { width, height: 820 } });
  const pageErrors = [];
  const prohibitedRequests = [];
  page.on("pageerror", (error) => pageErrors.push(String(error?.message || error)));
  await page.route("**/*", async (route) => {
    if (new URL(route.request().url()).hostname === "127.0.0.1") return route.continue();
    prohibitedRequests.push(route.request().url().split("?")[0]);
    return route.abort("blockedbyclient");
  });
  await page.addInitScript(({ lang, failMode }) => {
    const U = "00000000-0000-4000-8000-000000000007";
    const subjects = [
      { id: 5, subject_key: "mathematics", is_active: true },
      { id: 4, subject_key: "chemistry", is_active: true },
      { id: 3, subject_key: "biology", is_active: true },
      { id: 6, subject_key: "informatics", is_active: true },
      { id: 7, subject_key: "economics", is_active: true }
    ];
    const regions = [{ id: 1, name_ru: "Тестовый регион", name_uz: "Sinov viloyati", name_en: "Test region" }];
    const districts = [{ id: 11, region_id: 1, name_ru: "Тестовый район", name_uz: "Sinov tumani", name_en: "Test district" }];

    const tracker = window.__B00_FAKE = {
      uid: null, writes: [], reads: [], anonymousStarts: 0, appCloses: 0, failMode
    };
    window.Telegram = { WebApp: {
      initData: "",
      initDataUnsafe: { user: { id: 777001, language_code: lang, first_name: "Sample" } },
      close: () => { tracker.appCloses += 1; },
      ready() {}, expand() {}, sendData() {}
    } };

    const getRows = (table, filters) => {
      if (table === "subjects") return subjects.filter(row =>
        !filters.subject_key || row.subject_key === filters.subject_key);
      if (table === "regions") return regions.filter(row => !filters.id || row.id === filters.id);
      if (table === "districts") return districts.filter(row =>
        !filters.region_id || row.region_id === Number(filters.region_id));
      if (table === "users") return tracker.writes
        .filter(x => x.table === "users" && x.action === "upsert")
        .flatMap(x => [].concat(x.data));
      if (table === "user_subjects") return tracker.writes
        .filter(x => x.table === "user_subjects" && x.action === "upsert")
        .flatMap(x => [].concat(x.data)).map(row => ({
          ...row, subjects: { subject_key: subjects.find(s => s.id === row.subject_id)?.subject_key }
        }));
      return [];
    };
    const builder = (table) => {
      const filters = {};
      let selected = "";
      const query = {
        select(fields) { selected = fields; return this; },
        eq(field, val) { filters[field] = val; return this; },
        in() { return this; }, gt() { return this; }, gte() { return this; },
        lte() { return this; }, is() { return this; },
        order() { return this; }, limit() { return this; },
        maybeSingle() {
          tracker.reads.push({ table, selected, filters: { ...filters }, single: true });
          return Promise.resolve({ data: getRows(table, filters)[0] || null, error: null });
        },
        single() { return this.maybeSingle(); },
        then(resolve, reject) {
          tracker.reads.push({ table, selected, filters: { ...filters } });
          return Promise.resolve({ data: getRows(table, filters), error: null }).then(resolve, reject);
        },
        upsert(data) {
          tracker.writes.push({ table, action: "upsert", data });
          if (table === "users" && failMode === "duplicate") {
            return Promise.resolve({ error: { message: 'duplicate key value violates unique constraint "users_telegram_user_id_key"' } });
          }
          if (table === "users" && failMode === "save_error") {
            return Promise.resolve({ error: { message: "synthetic offline DB error" } });
          }
          return Promise.resolve({ data, error: null });
        },
        insert(data) {
          tracker.writes.push({ table, action: "insert", data });
          return Promise.resolve({ data, error: null });
        },
        update(data) {
          tracker.writes.push({ table, action: "update", data });
          return this;
        }
      };
      return query;
    };
    const fake = {
      auth: {
        async getSession() {
          return { data: { session: tracker.uid ? { user: { id: tracker.uid } } : null } };
        },
        async getUser() {
          return { data: { user: tracker.uid ? { id: tracker.uid } : null } };
        },
        async signInAnonymously() {
          tracker.anonymousStarts += 1;
          tracker.uid = U;
          return { data: { session: { user: { id: U } }, user: { id: U } }, error: null };
        }
      },
      from: builder
    };
    window.supabase = { createClient: () => fake };
    window.sb = fake;
  }, { lang: language, failMode: mode });

  try {
    await page.goto(baseUrl, { waitUntil: "domcontentloaded" });
    await page.locator("#view-registration.is-active .reg-b00-next").waitFor({ timeout: 20000 });
    await page.waitForFunction(() => document.getElementById("reg-form")?.dataset.submitBound === "1", { timeout: 10000 });

    const i18n = await page.evaluate(() => ({
      current: window.i18n.getLang(),
      step: document.querySelector(".reg-b00-counter")?.textContent,
      heading: document.querySelector("#view-registration h1")?.textContent,
      expected: window.i18n.t("reg_create_title"),
      consent: document.querySelector("#view-registration [data-i18n=reg_terms_text]")?.textContent,
      expectedConsent: window.i18n.t("reg_terms_text")
    }));
    assert.equal(i18n.current, language);
    assert.equal(await page.locator("#reg-language").inputValue(), language);
    assert.equal(i18n.heading, i18n.expected);
    assert.equal(i18n.consent, i18n.expectedConsent);
    assert.match(i18n.step, language === "ru" ? /1 из 2/ : language === "uz" ? /1-bosqich/ : /Step 1 of 2/);
    assert.equal(await page.locator("#topbar-title").textContent(), "iClub");
    assert.equal(await page.locator("#topbar-subtitle").textContent(), "Smarter together");
    assert.equal(await page.locator("#tabbar").isVisible(), false);
    assert.equal(await page.locator("#view-registration").getAttribute("data-reg-b00-step"),"1");
    assert.equal(await page.locator("#topbar-back").isVisible(),false,
      "Step 1 must not show the redundant app-exit back arrow");
    const regBrand = await page.evaluate(() => ({
      logo: document.querySelector("#topbar .topbar-brand").getBoundingClientRect().left,
      back: getComputedStyle(document.getElementById("topbar-back")).display
    }));
    assert.equal(regBrand.back,"none","Step 1 must not reserve a clickable back control");
    if (mode === "success") await page.screenshot({
      path: path.join(root, "b00-runtime-step1-" + language + "-" + width + ".png"),
      fullPage: true
    });

    await page.locator(".reg-b00-next").click();
    assert.equal(await page.locator("#reg-b00-step-one").isVisible(), true);
    assert.equal(await page.evaluate(() => window.__B00_FAKE.writes.length), 0);

    await page.locator("#reg-fullname").fill("Example Student");
    await page.locator("#reg-region option[value='1']").waitFor({ state: "attached", timeout: 8000 });
    await page.locator("#reg-region").selectOption("1");
    await page.locator("#reg-district:not([disabled]) option[value='11']").waitFor({ state: "attached", timeout: 8000 });
    await page.locator("#reg-district").selectOption("11");
    await page.locator(".reg-b00-next").click();
    assert.equal(await page.locator("#reg-b00-step-two").isVisible(), true);
    assert.equal(await page.locator("#topbar-back").isVisible(),true,
      "Step 2 topbar keeps its original application exit handler");
    const prevStyle = await page.locator(".reg-b00-prev").evaluate(el => {
      const v=getComputedStyle(el);
      return {border:v.borderTopWidth,style:v.borderTopStyle,bg:v.backgroundColor,radius:v.borderRadius};
    });
    assert.equal(prevStyle.style,"solid","Step 2 Back must have a visible border");
    assert.ok(parseFloat(prevStyle.border)>=1,"Step 2 Back is not a framed button");
    assert.ok(parseFloat(prevStyle.radius)>=10,"Step 2 Back requires rounded corners");
    assert.equal(await page.evaluate(() => window.__B00_FAKE.writes.length), 0);
    const viewGeometry = await page.evaluate(() => ({
      barBottom: document.getElementById("topbar").getBoundingClientRect().bottom,
      progressTop: document.querySelector(".reg-b00-progress").getBoundingClientRect().top,
      headingTop: document.querySelector("#view-registration h1").getBoundingClientRect().top
    }));
    assert.ok(viewGeometry.progressTop >= viewGeometry.barBottom - 2,
      "Step progress must not be clipped under sticky topbar: " + JSON.stringify(viewGeometry));
    assert.ok(viewGeometry.headingTop >= viewGeometry.barBottom - 2,
      "Step heading must not be clipped under sticky topbar: " + JSON.stringify(viewGeometry));

    // Parenthesized qualification is one typographic unit: never leave
    // "(для" at line-end with "рейтинга)" alone on the next line.
    if (language === "ru") {
      const titleLines = await page.locator("#reg-subject-section .card-title").evaluate(el => {
        const node = Array.from(el.childNodes).find(n =>
          n.nodeType === Node.TEXT_NODE && n.textContent.includes("(для рейтинга)"));
        if (!node) return { failure: "Original source text not present", value: el.textContent };
        const start = node.textContent.indexOf("(для рейтинга)");
        const getRect = offset => {
          const range = document.createRange();
          range.setStart(node, offset);
          range.setEnd(node, offset + 1);
          const rect = range.getBoundingClientRect();
          return { top: Math.round(rect.top), left: Math.round(rect.left) };
        };
        return { open: getRect(start), close: getRect(start + "(для рейтинга)".length - 1), width: el.getBoundingClientRect().width };
      });
      assert.ok(titleLines.open && titleLines.close &&
        Math.abs(titleLines.open.top - titleLines.close.top) <= 2,
      "Keep (для рейтинга) on ONE rendered line: " + JSON.stringify(titleLines));
    }

    assert.deepEqual(await page.locator("#reg-class option").allTextContents(), ["7", "8", "9", "10", "11"]);
    assert.equal(await page.locator("#reg-school-block").isVisible(), true);
    const chips = page.locator("#reg-subject-chips .chip-btn");
    assert.equal(await chips.count(), 5);
    await page.locator('#reg-subject-chips [data-subject-key="mathematics"]').click();
    await page.locator('#reg-subject-chips [data-subject-key="economics"]').click();
    await page.locator('#reg-subject-chips [data-subject-key="biology"]').click();
    assert.equal(await page.locator("#reg-subject-chips .chip-btn.is-active").count(), 2);
    // Existing app.js ranks selected chips in DOM order, not click order.
    assert.equal(await page.locator("#reg-main-subject-1").inputValue(), "economics");
    assert.equal(await page.locator("#reg-main-subject-2").inputValue(), "mathematics");
    assert.equal(await page.locator("#reg-subject-summary").isVisible(), true);
    if (mode === "success") {
      // The preceding third-chip test intentionally triggers a short toast.
      // Wait for that expected message to close before photographing the form.
      await page.waitForFunction(
        () => !document.getElementById("toast")?.classList.contains("is-show"),
        null, { timeout: 7000 }
      );
      await page.evaluate(() => window.scrollTo(0, 0));
      await page.screenshot({
        path: path.join(root, "b00-runtime-step2-" + language + "-" + width + ".png"),
        fullPage: true
      });
    }

    // Actual app.js controls visibility and clears competitive picks when school is OFF.
    await page.locator("#view-registration .reg-toggle .switch").click();
    assert.equal(await page.locator("#reg-is-school-toggle").isChecked(), false);
    assert.equal(await page.locator("#reg-nonstudent-subjects").isVisible(), true);
    assert.equal(await page.locator("#reg-subject-section").isVisible(), true,
      "Non-school registration must show the starting Study subject selector");
    assert.equal(await page.locator("#reg-school-block").isVisible(), false);
    assert.equal(await page.locator("#reg-main-subject-1").inputValue(), "");
    await page.locator("#view-registration .reg-toggle .switch").click();
    assert.equal(await page.locator("#reg-is-school-toggle").isChecked(), true);
    assert.equal(await page.locator("#reg-school-block").isVisible(), true);
    assert.equal(await page.locator("#reg-subject-chips .chip-btn.is-active").count(), 0);
    await page.waitForFunction(() => document.getElementById("reg-subject-summary")?.textContent === window.i18n.t("reg_subject_summary_none"));

    // Preserve personal values through real Step 2 -> Step 1 -> Step 2.
    await page.locator(".reg-b00-prev").click();
    assert.equal(await page.locator("#topbar-back").isVisible(),false,
      "Returning to Step 1 must hide the redundant arrow again");
    assert.equal(await page.locator("#reg-fullname").inputValue(), "Example Student");
    assert.equal(await page.locator("#reg-region").inputValue(), "1");
    assert.equal(await page.locator("#reg-district").inputValue(), "11");
    await page.locator(".reg-b00-next").click();

    const nonschool = language === "en";
    if (nonschool) {
      await page.locator("#view-registration .reg-toggle .switch").click();
      assert.equal(await page.locator("#reg-is-school-toggle").isChecked(), false);
      assert.equal(await page.locator("#reg-subject-section").isVisible(), true);
      const counterText = (n) => ({
        ru: `Выбрано: ${n} из 2 предметов`,
        uz: `Tanlangan: ${n}/2 ta fan`,
        en: `Selected: ${n} of 2 subjects`
      })[language];
      const assertCounter = async (n) => {
        const label = counterText(n);
        await page.waitForFunction(expected =>
          document.querySelector(".reg-b00-selected-count")?.textContent===expected,
          label,{timeout:4000});
        assert.equal(await page.locator(".reg-b00-selected-count").innerText(),label);
      };
      await assertCounter(0);
      if (mode === "success") {
        await page.waitForFunction(() => !document.getElementById("toast")?.classList.contains("is-show"), null, { timeout: 5000 });
        await page.evaluate(() => window.scrollTo(0, 0));
        await page.screenshot({
          path: path.join(root, "b00-runtime-nonschool-" + language + "-" + width + ".png"),
          fullPage: true
        });
      }
      // Selection is mandatory before any Auth/DB writes. Exact app.js path.
      await page.locator("#reg-consent").check();
      const beforeEmptySubmit = await page.evaluate(() => window.__B00_FAKE.writes.length);
      await page.locator("#reg-submit").click();
      assert.equal(await page.locator("#view-registration").isVisible(), true);
      assert.equal(await page.evaluate(() => window.__B00_FAKE.writes.length),beforeEmptySubmit,
        "Zero selected non-school subjects must not write user or credentials");
      await page.locator('#reg-subject-chips [data-subject-key="mathematics"]').click();
      await assertCounter(1);
      await page.locator('#reg-subject-chips [data-subject-key="economics"]').click();
      await assertCounter(2);
      await page.locator('#reg-subject-chips [data-subject-key="mathematics"]').click();
      await assertCounter(1);
      await page.locator('#reg-subject-chips [data-subject-key="economics"]').click();
      await assertCounter(0);
      // Re-select: one required initial Study subject, optional second.
      await page.locator('#reg-subject-chips [data-subject-key="mathematics"]').click();
      await assertCounter(1);
      assert.equal(await page.locator("#reg-main-subject-1").inputValue(),"mathematics");
      assert.equal(await page.locator("#reg-subject-summary").isVisible(),true);
      if (width === 390 || width === 1440) {
        await page.locator('#reg-subject-chips [data-subject-key="economics"]').click();
        await assertCounter(2);
      }
    } else {
      await page.locator("#reg-school").fill("154");
      await page.locator("#reg-class").selectOption("9");
      await page.locator('#reg-subject-chips [data-subject-key="mathematics"]').click();
      if (language === "ru") {
        await page.locator('#reg-subject-chips [data-subject-key="economics"]').click();
      }
    }
    await page.locator("#reg-consent").check();

    if (mode === "duplicate") {
      await page.locator("#reg-submit").click();
      await page.locator("#modal-root .modal-title").waitFor({ timeout: 15000 });
      assert.match(await page.locator("#modal-root .modal-title").textContent(), /Профиль уже существует/);
      assert.deepEqual(
        (await page.locator("#modal-root [data-modal-action]").allTextContents()).map(s => s.trim()),
        ["Отмена", "Восстановить профиль"]
      );
      assert.equal(await page.locator("#view-registration").isVisible(), true);
      assert.equal(await page.locator("#reg-b00-step-two").isVisible(), true);
      assert.equal(await page.evaluate(() => window.__B00_FAKE.writes.filter(w => w.table === "users").length), 3);
      await page.screenshot({ path: path.join(root, "b00-runtime-recovery-ru.png"), fullPage: true });
    } else if (mode === "save_error") {
      await page.locator("#reg-submit").click();
      await page.locator("#modal-root .modal-title").waitFor({ timeout: 15000 });
      assert.match(await page.locator("#modal-root .modal-title").textContent(), /Could not save registration/);
      assert.equal(await page.locator("#modal-root [data-modal-action]").count(), 1);
      assert.equal(await page.locator("#view-registration").isVisible(), true);
      assert.equal(await page.evaluate(() => window.__B00_FAKE.writes.filter(w => w.table === "users").length), 3);
      assert.equal(await page.evaluate(() => window.__B00_FAKE.writes.filter(w => w.table === "user_subjects").length), 0);
    } else {
      await page.locator("#reg-submit").click();
      await page.locator("#view-home.is-active").waitFor({ timeout: 16000 });
      // Visually verify the real Academy OS CSS, not a mock style screenshot.
      if (nonschool) {
        await page.locator("#home-study-list > .home-pinned-tile").first().waitFor();
        const study = await page.locator("#home-study-list > .home-pinned-tile").first().evaluate(el => ({
          color:getComputedStyle(el).backgroundColor,
          image:getComputedStyle(el).backgroundImage
        }));
        assert.equal(study.color,"rgb(48, 113, 225)",
          "Every pinned Study card must use owner's screenshot 2 solid #3071E1");
        assert.equal(study.image,"none",
          "Pinned Study background must be a flat color, not a gradient");
        const visual = await page.locator("#home-study-list > .home-pinned-tile").first().evaluate(el => {
          const card = el.getBoundingClientRect();
          const title = el.querySelector(".home-pinned-title");
          const titleBox = title.getBoundingClientRect();
          const css = getComputedStyle(title);
          const outer = getComputedStyle(el);
          return {
            textAlign:css.textAlign,fontSize:parseFloat(css.fontSize),
            outerAlign:outer.textAlign,cardHeight:card.height,
            leftOffset:titleBox.left-card.left,
            rightGap:card.right-titleBox.right,
            topCount:el.querySelectorAll(".home-pinned-top").length,
            footerCount:el.querySelectorAll(".home-pinned-bottom").length
          };
        });
        assert.equal(visual.textAlign,"left","Approved Study title must be left-aligned");
        assert.equal(visual.outerAlign,"left","Approved Study card must not center content");
        assert.ok(visual.fontSize>=17 && visual.fontSize<=19.1,
          "Approved Study title must be 17-19px, not an oversized heading: "+JSON.stringify(visual));
        assert.ok(visual.leftOffset>=10 && visual.leftOffset<=24,
          "Study title must align to card's left inset: "+JSON.stringify(visual));
        assert.equal(visual.topCount,1);
        assert.equal(visual.footerCount,1);
        assert.ok(visual.cardHeight>=128 && visual.cardHeight<=240,
          "Study card should stay compact while allowing long translations");
        assert.equal(await page.locator("#home-competitive-list .home-competitive-card").count(),0,
          "Non-school cannot inherit Competitive cards");
      } else {
        await page.locator("#home-competitive-list .home-competitive-card").first().waitFor();
        const comp = await page.locator("#home-competitive-list .home-competitive-card").first().evaluate(el => ({
          color:getComputedStyle(el).backgroundColor,
          image:getComputedStyle(el).backgroundImage
        }));
        assert.equal(comp.color,"rgb(23, 74, 171)",
          "Competitive cards must use owner's screenshot 1 solid #174AAB");
        assert.equal(comp.image,"none",
          "Competitive swipes must not alternate colors through a gradient");
      }
      const writes = await page.evaluate(() => window.__B00_FAKE.writes);
      const userRows = writes.filter(w => w.table === "users" && w.action === "upsert");
      const subjectsRows = writes.filter(w => w.table === "user_subjects" && w.action === "upsert");
      assert.equal(userRows.length, 1, "original users upsert exactly once");
      assert.equal(userRows[0].data.language_code, language);
      assert.equal(userRows[0].data.is_school_student, !nonschool);
      assert.equal(subjectsRows.length,1,"Initial subject choices must be persisted for both user modes");
      if (nonschool) {
        const studyRows=subjectsRows[0].data;
        assert.equal(studyRows.length, width === 390 || width === 1440 ? 2 : 1);
        assert.ok(studyRows.every(row => row.mode === "study" && row.is_pinned === true),
          "Non-school initial choices must be Study only and pinned");
      } else {
        assert.equal(subjectsRows[0].data.length, language === "ru" ? 2 : 1);
      }
    }


    // Native accessible names must follow the translated visible labels.
    if (mode === "success") {
      const expected = {
        ru: ["Главная", "Предметы", "Рейтинг", "Профиль"],
        uz: ["Bosh sahifa", "Fanlar", "Reyting", "Profil"],
        en: ["Home", "Subjects", "Ratings", "Profile"]
      }[language];
      const tabs = ["home","courses","ratings","profile"];
      for (let i=0;i<tabs.length;i++) {
        const button = page.locator('#tabbar [data-tab="'+tabs[i]+'"]');
        assert.equal(await button.getAttribute("aria-label"), null,
          "Static English aria-label must not override translated visible text");
        assert.equal(await button.getAttribute("aria-labelledby"),"tabbar-"+tabs[i]+"-label");
        assert.equal(await page.locator("#tabbar").getByRole("button",{name:expected[i],exact:true}).count(),1,
          "Accessible navigation name mismatch: "+language+" "+tabs[i]);
      }
    }
    // Work P1: non-school learner must still bind Settings language handlers.
    if (mode === "success" && nonschool && [320,390,528,1440].includes(width)) {
      assert.equal(await page.locator('#courses-filter-row [data-main-filter="competitive"]').count(),0,
        "Non-school catalogue must not offer Competitive choices");
      await page.locator('#tabbar [data-tab="courses"]').click();
      await page.locator('#courses-all-subjects.is-active').waitFor();
      assert.equal(await page.locator('#courses-filter-row [data-main-filter="competitive"]').count(),0);
      assert.equal(await page.locator('#courses-filter-row').isVisible(),false);
      assert.ok(await page.locator('#subjects-grid .catalog-card').count() >= 3,
        "Non-school catalogue must preserve Study subjects");
      await page.locator('#subjects-grid .catalog-head').first().click();
      await page.locator('#courses-subject-hub.is-active').waitFor();
      assert.equal(await page.locator('#courses-subject-hub [data-action="open-tours"]').isVisible(),false,
        "Non-school Mathematics hub must not display inaccessible Tours CTA");
      assert.equal(await page.locator('#courses-subject-hub [data-action="open-practice"]').isVisible(),true,
        "Non-school Practice access must remain available");
      // The Practice card uses the same visual family as Exam Prep:
      // blue-white border, left aligned text and independent arrow track.
      const practiceLayout=await page.locator('#courses-subject-hub [data-action="open-practice"]').evaluate(el=>{
        const card=el.getBoundingClientRect();
        const badge=el.querySelector(".subject-mode-status").getBoundingClientRect();
        const arrow=el.querySelector(".subject-mode-arrow").getBoundingClientRect();
        const head=el.querySelector(".subject-mode-topline");
        const style=getComputedStyle(el);
        return {
          cardWidth:card.width,hubWidth:el.parentElement.getBoundingClientRect().width,
          badgeRight:badge.right,arrowLeft:arrow.left,
          arrowRightInset:card.right-arrow.right,
          topCols:getComputedStyle(head).gridTemplateColumns.split(" ").length,
          radius:style.borderRadius,bg:style.backgroundImage,
          align:style.textAlign
        };
      });
      assert.equal(practiceLayout.topCols,2,
        "Iconless Practice must reserve separate tracks for status and arrow");
      assert.ok(practiceLayout.arrowLeft-practiceLayout.badgeRight>=8,
        "Practice arrow must not touch 'Always available': "+JSON.stringify(practiceLayout));
      assert.ok(practiceLayout.arrowRightInset>=5 && practiceLayout.arrowRightInset<=32,
        "Practice arrow must align near card right edge");
      assert.equal(practiceLayout.align,"left");
      assert.match(practiceLayout.bg,/linear-gradient/,"Practice must have a real Exam Prep-family surface");
      if(nonschool) assert.ok(practiceLayout.cardWidth>=practiceLayout.hubWidth-3,
        "Mobile Practice must match Exam Prep full-width footprint");

      await page.locator('#tabbar [data-tab="home"]').click();
      await page.locator('#view-home.is-active').waitFor();
      assert.equal(await page.locator('#home-competitive-list').isVisible(), false,
        'Non-school Home must not advertise restricted competitions');
      await page.locator('#tabbar [data-tab="profile"]').click();
      await page.locator('#view-profile.is-active').waitFor();
      assert.equal(await page.locator('#profile-competitive-slots-list').isVisible(), false,
        'Non-school profile must not invite to restricted competitive slots');
      await page.locator('#topbar-action[data-action="profile-settings"]').click();
      await page.locator('#profile-settings.is-active').waitFor();
      assert.equal(await page.locator('#profile-competitive-list').isVisible(),false,
        "Non-school Settings must not duplicate the restricted-mode explanation");
      assert.equal(await page.locator('#settings-competitive-note').innerText(),
        await page.evaluate(() => window.i18n.t("disabled_not_school")));
      await page.locator('#profile-settings-language [data-lang="uz"]').click();
      await page.waitForFunction(() => window.i18n.getLang() === "uz");
      assert.equal(await page.locator('#tabbar [data-tab="home"] .tab-txt').innerText(), "Bosh sahifa");
      assert.equal(await page.locator('#tabbar').getByRole("button",{name:"Bosh sahifa",exact:true}).count(),1,
        "UZ accessible name must match visible tab");
      assert.equal(await page.locator('#profile-settings-language [data-lang="uz"].is-active').count(),1);
      await page.locator('#profile-settings-language [data-lang="en"]').click();
      await page.waitForFunction(() => window.i18n.getLang() === "en");
      assert.equal(await page.locator('#tabbar [data-tab="home"] .tab-txt').innerText(), "Home");
      assert.equal(await page.locator('#tabbar').getByRole("button",{name:"Home",exact:true}).count(),1,
        "EN accessible name must match visible tab");
      assert.equal(await page.locator('#profile-settings-content-language [data-lang="en"].is-active').count(),1,
        "Changing UI language MUST NOT alter question language");
      console.log("PASS Work P1/P2: non-school language/accessibility, Study-only catalogue/Hub, single note at "+width+"px");
    }

    if (mode === "success" && language === "ru" && width === 390) {
      // REAL app.js + accepted B00 adapter + Academy OS presentation enhancement.
      // No mock route functions: click actual source navigation and source hub actions.
      const labels = await page.locator('#tabbar .tab-txt').allTextContents();
      assert.ok(labels.some(v => v.trim() === "Предметы"), "Approved Subjects navigation must use RU copy");
      assert.equal(await page.locator('#academy-home-title').isVisible(), true);
      assert.equal(await page.locator('#academy-home-continue').isVisible(), false,
        "No authenticated paused draft must NEVER create fake Continue");
      const pre=await page.evaluate(()=>({writes:window.__B00_FAKE.writes.length,
        profile:window.localStorage.getItem("iclub_profile_v1")}));
      await page.locator('#tabbar [data-tab="courses"]').click();
      await page.locator('#view-courses.is-active #academy-subjects-title').waitFor();
      assert.equal((await page.locator('#academy-subjects-title').textContent()).trim(),"Предметы");
      assert.equal(await page.locator('#courses-all-subjects.is-active').isVisible(),true);
      await page.locator('#courses-filter-row [data-main-filter="competitive"]').click();
      assert.equal(await page.locator('#courses-filter-row [data-main-filter="competitive"].is-active').count(),1);
      await page.locator('#courses-filter-row [data-main-filter="study"]').click();
      assert.equal(await page.locator('#courses-filter-row [data-main-filter="study"].is-active').count(),1);
      // Five source subjects minus the two Competitive selections remain in Study.
      const visibleStudy=await page.locator('#subjects-grid .catalog-card').count();
      assert.ok(visibleStudy>=3,
        "Study catalogue must retain the remaining 3 subjects, found "+visibleStudy);
      // Explicitly cancel activation: no profile changes, no DB writes, no reset.
      const beforeCancel=await page.evaluate(()=>({writes:window.__B00_FAKE.writes.length,
        profile:window.localStorage.getItem("iclub_profile_v1")}));
      // Styled native input is visually hidden; exercise the real visible switch label.
      await page.locator('#subjects-grid .catalog-toggle-row .switch').first().click();
      await page.locator('#modal-root [data-modal-action="cancel"]').waitFor();
      await page.locator('#modal-root [data-modal-action="cancel"]').click();
      const afterCancel=await page.evaluate(()=>({writes:window.__B00_FAKE.writes.length,
        profile:window.localStorage.getItem("iclub_profile_v1")}));
      assert.deepEqual(afterCancel,beforeCancel,"Canceled subject activation must not change user profile or DB");
      // Opening the subject title is separate from selecting/unselecting it.
      const beforeOpen=await page.evaluate(()=>window.__B00_FAKE.writes.length);
      await page.locator('#subjects-grid .catalog-head').first().click();
      await page.locator('#courses-subject-hub.is-active').waitFor();
      assert.equal(await page.locator('#courses-subject-hub .academy-hub-tab').count(),3);
      assert.equal(await page.locator('#academy-hub-pane-preparation').isVisible(),true);
      assert.equal(await page.locator('#exam-prep-host-root').count(),1);
      // The Practice card uses the same visual family as Exam Prep:
      // blue-white border, left aligned text and independent arrow track.
      const practiceLayout=await page.locator('#courses-subject-hub [data-action="open-practice"]').evaluate(el=>{
        const card=el.getBoundingClientRect();
        const badge=el.querySelector(".subject-mode-status").getBoundingClientRect();
        const arrow=el.querySelector(".subject-mode-arrow").getBoundingClientRect();
        const head=el.querySelector(".subject-mode-topline");
        const style=getComputedStyle(el);
        return {
          cardWidth:card.width,hubWidth:el.parentElement.getBoundingClientRect().width,
          badgeRight:badge.right,arrowLeft:arrow.left,
          arrowRightInset:card.right-arrow.right,
          topCols:getComputedStyle(head).gridTemplateColumns.split(" ").length,
          radius:style.borderRadius,bg:style.backgroundImage,
          align:style.textAlign
        };
      });
      assert.equal(practiceLayout.topCols,2,
        "Iconless Practice must reserve separate tracks for status and arrow");
      assert.ok(practiceLayout.arrowLeft-practiceLayout.badgeRight>=8,
        "Practice arrow must not touch 'Always available': "+JSON.stringify(practiceLayout));
      assert.ok(practiceLayout.arrowRightInset>=5 && practiceLayout.arrowRightInset<=32,
        "Practice arrow must align near card right edge");
      assert.equal(practiceLayout.align,"left");
      assert.match(practiceLayout.bg,/linear-gradient/,"Practice must have a real Exam Prep-family surface");
      if(nonschool) assert.ok(practiceLayout.cardWidth>=practiceLayout.hubWidth-3,
        "Mobile Practice must match Exam Prep full-width footprint");
      assert.equal(await page.evaluate(()=>window.__B00_FAKE.writes.length),beforeOpen,
        "Opening a subject may not accidentally toggle a competitive/study selection");
      await page.locator('#courses-subject-hub [data-academy-pane="materials"].academy-hub-tab').click();
      assert.equal(await page.locator('#academy-hub-pane-materials').isVisible(),true);
      assert.equal(await page.locator('#academy-hub-pane-preparation').isVisible(),false);
      assert.equal(await page.locator('#academy-hub-pane-materials [data-action="open-lessons"]').count(),1);
      assert.equal(await page.locator('#academy-hub-pane-materials [data-action="open-books"]').count(),1);
      await page.locator('#courses-subject-hub [data-academy-pane="achievements"].academy-hub-tab').click();
      assert.equal(await page.locator('#academy-hub-pane-achievements').isVisible(),true);
      assert.equal(await page.locator('#academy-hub-pane-achievements [data-action="open-certificates"]').count(),1);
      assert.equal(await page.locator('#academy-hub-pane-achievements [data-action="open-archive"]').count(),1);
      await page.locator('#courses-subject-hub [data-academy-pane="preparation"].academy-hub-tab').click();
      assert.equal(await page.locator('#academy-hub-pane-preparation').isVisible(),true);
      // Source back routing preserves catalog, subject and registration records.
      await page.locator('#topbar-back').click();
      await page.locator('#courses-all-subjects.is-active').waitFor();
      await page.locator('#tabbar [data-tab="home"]').click();
      await page.locator('#view-home.is-active').waitFor();
      const post=await page.evaluate(()=>({writes:window.__B00_FAKE.writes.length,
        profile:window.localStorage.getItem("iclub_profile_v1")}));
      assert.equal(post.writes,pre.writes,"Read-only subject navigation must not write DB rows");
      assert.equal(post.profile,pre.profile,"Navigation must not rewrite registration local profile");
      console.log("PASS accepted B00 -> actual Home -> Subjects filters -> Subject Hub 3 tabs -> Back -> Home");
      // School-only routes: read-only Tours/Ratings navigation, never start a Tour attempt.
      assert.equal(await page.locator('#home-competitive-list').isVisible(), true);
      await page.locator('#tabbar [data-tab="profile"]').click();
      await page.locator('#view-profile.is-active').waitFor();
      assert.equal(await page.locator('#profile-competitive-slots-list').isVisible(), true,
        "School learner must retain real Competitive slots");
      assert.equal(await page.locator('#profile-competitive-slots-list .slot-card').count(), 2,
        "School learner must have two selected Competitive subject cards");
      await page.locator('#profile-competitive-slots-list .slot-card button').first().click();
      await page.locator('#courses-subject-hub.is-active').waitFor();
      await page.locator('#courses-subject-hub [data-action="open-tours"]').click();
      await page.locator('#courses-tours.is-active').waitFor({timeout:8000});
      assert.equal(await page.locator('#courses-tour-quiz').isVisible(),false,
        "Read-only Tours list cannot open timed attempt");
      await page.locator('#tabbar [data-tab="ratings"]').click();
      await page.locator('#view-ratings.is-active').waitFor();
      assert.equal(await page.locator('#ratings-mybar').isVisible(),false,
        "No real attempts: cannot fabricate My rank");
      const forbiddenWrites = await page.evaluate(() => window.__B00_FAKE.writes.filter(w =>
        ["tour_attempts","tour_answers","practice_attempts","practice_answers"].includes(w.table)));
      assert.deepEqual(forbiddenWrites,[],"School UI smoke must not create any scores or attempts");
      console.log("PASS school-mode restricted Tours list + Ratings without attempt creation");
    }

    const over = await page.evaluate(() => document.documentElement.scrollWidth - innerWidth);
    assert.ok(over <= 1, "No horizontal overflow: " + width + "px; delta=" + over);
    console.log("PASS real app.js/i18n.js B00", language, mode, width, "no external network", "blocked:", prohibitedRequests.length);
    assert.equal(prohibitedRequests.length, 0, "No real external network requests allowed");
    assert.equal(pageErrors.length, 0, "Uncaught real app.js exceptions: " + pageErrors.slice(0, 3).join(" | "));
  } finally {
    await page.close();
  }
}

(async () => {
  await new Promise(resolve => server.listen(0, "127.0.0.1", resolve));
  const base = "http://127.0.0.1:" + server.address().port + "/";
  const browser = await chromium.launch({ headless: true });
  try {
    for (const testCase of [
      { language: "ru", mode: "success", width: 320 },
      { language: "ru", mode: "success", width: 390 },
      { language: "uz", mode: "success", width: 375 },
      { language: "en", mode: "success", width: 320 },
      { language: "en", mode: "success", width: 390 },
      { language: "en", mode: "success", width: 528 },
      { language: "en", mode: "success", width: 1440 },
      { language: "en", mode: "save_error", width: 390 },
      { language: "ru", mode: "duplicate", width: 390 }
    ]) {
      await launchCase(browser, base, testCase);
    }
  } finally {
    await browser.close();
    await new Promise(resolve => server.close(resolve));
  }
})().catch(error => {
  console.error(error);
  server.close();
  process.exitCode = 1;
});
