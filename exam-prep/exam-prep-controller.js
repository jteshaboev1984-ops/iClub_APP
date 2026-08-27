(() => {
  "use strict";

  const root = (window.iClubExamPrepPreview = window.iClubExamPrepPreview || {});
  const { config, contracts, staticData, store, engine, ui } = root;

  let unsubscribe = null;

  function selfTest() {
    const checks = [];
    const check = (name, condition) => {
      contracts.invariant(Boolean(condition), `Self-test failed: ${name}`);
      checks.push(name);
    };

    check("preview-only", config.previewOnly === true && config.liveApiEnabled === false);
    check("feature-default-off", config.featureDefault === "off");
    check("15-profiles", staticData.profiles.length === 15);
    check("81-skills", staticData.skills.length === 81);
    check("p1-45", staticData.skills.filter(x => x.component === "P1").length === 45);
    check("p5-36", staticData.skills.filter(x => x.component === "P5").length === 36);
    check("geometric-present", staticData.skills.filter(x => x.family === "GEO").length === 3);
    check("23-mixed", staticData.mixedNodes.length === 23);
    check("legacy-storage-isolated", store.assertNoLegacyKeyUse());

    for (const profile of staticData.profiles) {
      check(`state-parity-${profile.id}`, engine.assertAcademicParity(profile.id));
      const core = engine.buildViewModel({ profileId: profile.id, mode: "core", lang: "en", component: "P1" });
      const ai = engine.buildViewModel({ profileId: profile.id, mode: "ai", lang: "en", component: "P1" });
      check(`no-core-mentor-queue-${profile.id}`, core.mentor.queueCount === 0 && !core.mentor.assigned);
      check(`no-ai-mentor-queue-${profile.id}`, ai.mentor.queueCount === 0 && !ai.mentor.assigned);
    }

    let queueUniverse = 0;
    for (let i = 0; i < 600; i += 1) {
      const mode = i < 10 ? "mentor" : (i % 2 ? "ai" : "core");
      const profile = staticData.profiles[i % staticData.profiles.length];
      const vm = engine.buildViewModel({ profileId: profile.id, mode, lang: "en", component: "P1" });
      if (vm.mentor.assigned) queueUniverse += 1;
    }
    check("600-10-assignment-isolation", queueUniverse === 10);

    return Object.freeze(checks);
  }

  function updateSafetyStatus(checks) {
    const el = document.querySelector("#ep-safety-status");
    if (!el) return;
    el.textContent = `P0-01 · ${staticData.profiles.length}/15 scenarios · 81 skills · 600/10 ✓ · live API OFF · ${checks.length} checks passed`;
  }

  function bindControls() {
    const lang = document.querySelector("#ep-language");
    const profile = document.querySelector("#ep-profile");
    const service = document.querySelector("#ep-service");

    lang?.addEventListener("change", event => store.set({ lang: event.target.value }));
    profile?.addEventListener("change", event => store.set({ profileId: event.target.value }));
    service?.addEventListener("change", event => store.set({ mode: event.target.value }));

    document.querySelector("#ep-route-nav")?.addEventListener("click", event => {
      const button = event.target.closest("[data-route]");
      if (!button) return;
      store.set({ route: button.dataset.route });
    });

    document.querySelector("#exam-prep-root")?.addEventListener("click", event => {
      const routeButton = event.target.closest("[data-route]");
      if (routeButton) {
        store.set({ route: routeButton.dataset.route });
        return;
      }

      const componentButton = event.target.closest('[data-action="set-component"]');
      if (componentButton) {
        store.set({ component: componentButton.dataset.component, route: "placement-run" });
        return;
      }

      const option = event.target.closest('[data-action="pick-demo"]');
      if (option) {
        document.querySelectorAll(".ep-option.is-selected").forEach(el => el.classList.remove("is-selected"));
        option.classList.add("is-selected");
        const note = document.querySelector("#ep-demo-answer-note");
        if (note) note.textContent = root.i18n.get(store.get().lang).noAnswerSaved;
        return;
      }

      const submit = event.target.closest('[data-action="demo-submit"]');
      if (submit) {
        const note = document.querySelector("#ep-demo-answer-note");
        if (note) note.textContent = root.i18n.get(store.get().lang).noAnswerSaved;
      }
    });
  }

  function start() {
    contracts.assertPreviewIsolation();
    const checks = selfTest();
    const state = store.load();
    bindControls();
    unsubscribe = store.subscribe(next => ui.render(next));
    ui.render(state);
    updateSafetyStatus(checks);

    document.documentElement.classList.add("ep-preview-ready");
  }

  function stop() {
    if (unsubscribe) unsubscribe();
    unsubscribe = null;
    const rootEl = document.querySelector("#exam-prep-root");
    if (rootEl) rootEl.innerHTML = "";
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", start, { once: true });
  } else {
    start();
  }

  root.controller = Object.freeze({ start, stop, selfTest });
})();
