(() => {
  "use strict";

  const root = (window.iClubExamPrepPreview = window.iClubExamPrepPreview || {});
  const { config, staticData } = root;

  const KEY = `${config.previewStoragePrefix}ui_v1`;
  const DEFAULT = Object.freeze({
    lang: "ru",
    profileId: staticData.profiles[0].id,
    mode: "core",
    route: "overview",
    component: "P1"
  });

  let memory = { ...DEFAULT };
  const listeners = new Set();

  function sanitize(input = {}) {
    const next = { ...DEFAULT };
    if (config.allowedLanguages.includes(input.lang)) next.lang = input.lang;
    if (staticData.profiles.some(p => p.id === input.profileId)) next.profileId = input.profileId;
    if (config.allowedServiceModes.includes(input.mode)) next.mode = input.mode;
    if (config.routes.includes(input.route)) next.route = input.route;
    if (config.allowedComponents.includes(input.component)) next.component = input.component;
    return next;
  }

  function load() {
    try {
      const raw = localStorage.getItem(KEY);
      if (raw) memory = sanitize(JSON.parse(raw));
    } catch (_) {
      memory = { ...DEFAULT };
    }
    return get();
  }

  function persist() {
    try {
      localStorage.setItem(KEY, JSON.stringify(memory));
    } catch (_) {
      // Preview remains functional without storage.
    }
  }

  function get() {
    return Object.freeze({ ...memory });
  }

  function set(patch = {}) {
    memory = sanitize({ ...memory, ...patch });
    persist();
    for (const listener of listeners) listener(get());
    return get();
  }

  function subscribe(listener) {
    if (typeof listener !== "function") return () => {};
    listeners.add(listener);
    return () => listeners.delete(listener);
  }

  function assertNoLegacyKeyUse() {
    const source = [KEY];
    for (const forbidden of config.legacyStorageKeysForbidden) {
      if (source.includes(forbidden)) throw new Error(`[Exam Prep preview] Forbidden legacy storage key: ${forbidden}`);
    }
    return true;
  }

  root.store = Object.freeze({ KEY, DEFAULT, load, get, set, subscribe, assertNoLegacyKeyUse });
})();
