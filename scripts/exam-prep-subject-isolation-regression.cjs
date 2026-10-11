// Isolated subject-routing regression. No network, Supabase, production or user writes.
"use strict";
const fs = require("fs");
const vm = require("vm");
const assert = require("assert").strict;
const app = fs.readFileSync("app.js", "utf8");
const live = fs.readFileSync("exam-prep/exam-prep-live.js", "utf8");
const apiSource = fs.readFileSync("exam-prep/exam-prep-api.js", "utf8");

const subjectStart = app.indexOf("async function renderSubjectHub()");
const beforeGuard = app.indexOf("await window.iClubCommercialAccessUI?.guardStudy?.(subjectKey)", subjectStart);
const beforeSync = app.indexOf("window.iClubExamPrep?.syncSubjectHub?.(", subjectStart);
assert(subjectStart >= 0 && beforeSync > subjectStart && beforeSync < beforeGuard,
  "Exam Prep must receive the new subject before async access checks");
assert(apiSource.includes('exam-prep-live.js?v=p304aitutor1-subjectfix1'), "Live script cache must be fresh");

function makeSession() {
  const hub = { dataset: { subjectKey: "mathematics" } };
  const root = {
    hidden: true, htmlWrites: [],
    _html: "",
    get innerHTML() { return this._html; },
    set innerHTML(v) { this._html = String(v); this.htmlWrites.push(this._html); },
    querySelector() { return null; },
    querySelectorAll() { return []; }
  };
  const calls = { profile: 0, progress: 0, sync: [], open: [] };
  let readProfile = async () => ({ ok: true, data: null });
  const host = {
    active: false,
    async syncSubjectHub(context) {
      calls.sync.push(context.subjectKey);
      hub.dataset.subjectKey = context.subjectKey;
      this.active = false;
      root.hidden = true;
      root.innerHTML = "";
      return true;
    },
    async open(context) {
      calls.open.push(context.subjectKey);
      this.active = true;
      root.hidden = false;
      root.innerHTML = context.subjectKey === "mathematics"
        ? "MATHEMATICS_HOST" : "COMING_SOON_" + context.subjectKey;
      return true;
    },
    async refreshCapabilities() { return {}; },
    close() { this.active = false; root.hidden = true; root.innerHTML = ""; return true; },
    back() { this.active = false; root.hidden = true; return true; },
    isOpen() { return this.active; }
  };
  const window = {
    iClubExamPrep: host,
    iClubExamPrepHostInternal: {
      lastCapabilities: { coreAccess: true, killSwitch: false, rolloutState: "controlled_beta" },
      api: {
        examProfile: (...args) => { calls.profile++; return readProfile(...args); },
        diagnosticProgress: async () => { calls.progress++; return { ok: true, data: { stage0_complete: false } }; }
      }
    }
  };
  const document = {
    querySelector(sel) {
      if (sel === "#courses-subject-hub") return hub;
      if (sel === "#exam-prep-host-root") return root;
      return null;
    }
  };
  vm.runInNewContext(live, { window, document, setTimeout, clearTimeout, setInterval, clearInterval, console }, { filename: "exam-prep-live.js" });
  return { window, root, hub, calls, setProfileRead(fn) { readProfile = fn; } };
}

async function main() {
  const subjects = ["informatics", "economics", "biology", "chemistry", "english_a1", "sat"];
  for (const key of subjects) {
    const session = makeSession();
    await session.window.iClubExamPrep.syncSubjectHub({ subjectKey: key, language: "ru" });
    assert.equal(session.hub.dataset.subjectKey, key);
    const opened = await session.window.iClubExamPrep.open({ subjectKey: key, language: "ru" });
    assert.equal(opened, true, key + " informational route");
    assert.equal(session.calls.profile, 0, key + " must not query Mathematics examProfile");
    assert.equal(session.calls.progress, 0, key + " must not query P1/P5");
    assert.equal(session.root.innerHTML, "COMING_SOON_" + key, key + " must retain informational screen");
  }

  const maths = makeSession();
  await maths.window.iClubExamPrep.syncSubjectHub({ subjectKey: "mathematics", language: "ru" });
  assert.equal(await maths.window.iClubExamPrep.open({ subjectKey: "mathematics", language: "ru" }), true);
  assert.equal(maths.calls.profile, 1, "Authorized Mathematics must still mount live Exam Prep");
  assert(maths.root.innerHTML.includes("ep-live-form"), "Mathematics beta profile flow remains accessible");

  for (const key of subjects) {
    const switched = makeSession();
    let release;
    switched.setProfileRead(() => new Promise(resolve => { release = resolve; }));
    await switched.window.iClubExamPrep.syncSubjectHub({ subjectKey: "mathematics", language: "ru" });
    const oldOpen = switched.window.iClubExamPrep.open({ subjectKey: "mathematics", language: "ru" });
    for (let i=0; i<8 && !release; i++) await Promise.resolve();
    assert.equal(typeof release, "function", "Math profile pending");
    await switched.window.iClubExamPrep.syncSubjectHub({ subjectKey: key, language: "uz" });
    await switched.window.iClubExamPrep.open({ subjectKey: key, language: "uz" });
    release({ ok: true, data: null });
    await oldOpen;
    assert.equal(switched.calls.profile, 1, "one delayed Mathematics request");
    assert.equal(switched.root.innerHTML, "COMING_SOON_" + key, "late Mathematics response must not overwrite " + key);
    assert.equal(switched.calls.progress, 0, "late Mathematics must not request P1/P5");
  }

  console.log("Exam Prep subject isolation: 6 other subjects, Mathematics beta, 6 late-response races: GREEN");
}
main().catch(err => { console.error(err); process.exitCode = 1; });