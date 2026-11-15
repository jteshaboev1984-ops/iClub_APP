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
    assert.equal(await page.locator("#reg-subject-section").isVisible(), false);
    assert.equal(await page.locator("#reg-school-block").isVisible(), false);
    assert.equal(await page.locator("#reg-main-subject-1").inputValue(), "");
    await page.locator("#view-registration .reg-toggle .switch").click();
    assert.equal(await page.locator("#reg-is-school-toggle").isChecked(), true);
    assert.equal(await page.locator("#reg-school-block").isVisible(), true);
    assert.equal(await page.locator("#reg-subject-chips .chip-btn.is-active").count(), 0);
    await page.waitForFunction(() => document.getElementById("reg-subject-summary")?.textContent === window.i18n.t("reg_subject_summary_none"));

    // Preserve personal values through real Step 2 -> Step 1 -> Step 2.
    await page.locator(".reg-b00-prev").click();
    assert.equal(await page.locator("#reg-fullname").inputValue(), "Example Student");
    assert.equal(await page.locator("#reg-region").inputValue(), "1");
    assert.equal(await page.locator("#reg-district").inputValue(), "11");
    await page.locator(".reg-b00-next").click();

    const nonschool = language === "en";
    if (nonschool) {
      await page.locator("#view-registration .reg-toggle .switch").click();
      assert.equal(await page.locator("#reg-is-school-toggle").isChecked(), false);
      if (mode === "success") {
        await page.waitForFunction(() => !document.getElementById("toast")?.classList.contains("is-show"), null, { timeout: 5000 });
        await page.evaluate(() => window.scrollTo(0, 0));
        await page.screenshot({
          path: path.join(root, "b00-runtime-nonschool-" + language + "-" + width + ".png"),
          fullPage: true
        });
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
      const writes = await page.evaluate(() => window.__B00_FAKE.writes);
      const userRows = writes.filter(w => w.table === "users" && w.action === "upsert");
      const subjectsRows = writes.filter(w => w.table === "user_subjects" && w.action === "upsert");
      assert.equal(userRows.length, 1, "original users upsert exactly once");
      assert.equal(userRows[0].data.language_code, language);
      assert.equal(userRows[0].data.is_school_student, !nonschool);
      assert.equal(subjectsRows.length, nonschool ? 0 : 1);
      if (!nonschool) {
        assert.equal(subjectsRows[0].data.length, language === "ru" ? 2 : 1);
      }
    }


    // Work P1: non-school learner must still bind Settings language handlers.
    if (mode === "success" && nonschool && width === 320) {
      assert.equal(await page.locator('#home-competitive-list').isVisible(), false,
        'Non-school Home must not advertise restricted competitions');
      await page.locator('#tabbar [data-tab="profile"]').click();
      await page.locator('#view-profile.is-active').waitFor();
      assert.equal(await page.locator('#profile-competitive-slots-list').isVisible(), false,
        'Non-school profile must not invite to restricted competitive slots');
      await page.locator('#topbar-action[data-action="profile-settings"]').click();
      await page.locator('#profile-settings.is-active').waitFor();
      await page.locator('#profile-settings-language [data-lang="uz"]').click();
      await page.waitForFunction(() => window.i18n.getLang() === "uz");
      assert.equal(await page.locator('#tabbar [data-tab="home"] .tab-txt').innerText(), "Bosh sahifa");
      assert.equal(await page.locator('#profile-settings-language [data-lang="uz"].is-active').count(),1);
      await page.locator('#profile-settings-language [data-lang="en"]').click();
      await page.waitForFunction(() => window.i18n.getLang() === "en");
      assert.equal(await page.locator('#tabbar [data-tab="home"] .tab-txt').innerText(), "Home");
      assert.equal(await page.locator('#profile-settings-content-language [data-lang="en"].is-active').count(),1,
        "Changing UI language MUST NOT alter question language");
      console.log("PASS Work P1: non-school RU/UZ/EN UI controls remain usable, content language unchanged");
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
