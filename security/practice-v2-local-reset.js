(() => {
  "use strict";
  const MARKER = "iclub_math_practice_v2_local_reset_20261007_v1";
  const LEGACY_PREFIX = "practice_history_v2:mathematics:tour_";
  let inFlight = null;
  globalThis.iclubMathPracticeV2ResetAfterPublish = (client) => {
    if (inFlight) return inFlight;
    inFlight = (async () => {
      let storage;
      try {
        storage = globalThis.localStorage;
        if (!storage || storage.getItem(MARKER) === "1" ||
            !client || typeof client.rpc !== "function") return false;
      } catch { return false; }
      let timer = null;
      let result;
      try {
        result = await Promise.race([
          Promise.resolve().then(() => client.rpc("is_math_practice_v2_published_safe_v1")),
          new Promise(resolve => {
            timer = setTimeout(() => resolve({ data: false, error: "timeout" }), 2500);
          })
        ]);
      } catch { return false; }
      finally { if (timer !== null) clearTimeout(timer); }
      if (result?.error || result?.data !== true) return false;
      try {
        const legacyKeys = [];
        for (let i = 0; i < storage.length; i += 1) {
          const key = storage.key(i);
          if (typeof key === "string" && key.toLowerCase().startsWith(LEGACY_PREFIX))
            legacyKeys.push(key);
        }
        for (const key of legacyKeys) storage.removeItem(key);
        storage.setItem(MARKER, "1");
        return true;
      } catch { return false; }
    })();
    return inFlight.finally(() => { inFlight = null; });
  };
})();
