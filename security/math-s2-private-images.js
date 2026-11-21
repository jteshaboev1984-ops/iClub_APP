(() => {
  "use strict";
  // Dormant until its signed, private-bucket backend is separately installed.
  // Mathematics Season 2 only. Never modifies the existing S1/other-subject API.
  const BUCKET = "iclub-math-s2-private";
  const MAX_BYTES = 4 * 1024 * 1024;
  const PRELOAD_TIMEOUT_MS = 15000;
  const issuedBlobs = new Set();

  function sb() {
    const client = window.sb;
    if (!client || typeof client.rpc !== "function" || !client.storage?.from) {
      throw new Error("math_s2_secure_client_unavailable");
    }
    return client;
  }

  function positiveId(value) {
    const num = Number(value);
    if (!Number.isSafeInteger(num) || num <= 0) {
      throw new Error("math_s2_invalid_id");
    }
    return num;
  }

  async function rpc(name, args) {
    const { data, error } = await sb().rpc(name, args);
    if (error) throw new Error("math_s2_secure_service_unavailable");
    return data;
  }

  async function isMathSeason2(subjectId, seasonId) {
    if (Number(subjectId) !== 5) return false;
    const id = positiveId(seasonId);
    const { data, error } = await sb()
      .from("seasons").select("season_no").eq("id", id).maybeSingle();
    if (error || !data || !Number.isInteger(Number(data.season_no))) {
      throw new Error("math_s2_season_scope_unavailable");
    }
    return Number(data.season_no) === 2;
  }

  async function preflight(tourId) {
    const data = await rpc("get_math_s2_tour_preflight_v1", {
      p_tour_id: positiveId(tourId)
    });
    if (!data || data.ready !== true || Number(data.question_count) !== 20 ||
      !Number.isInteger(Number(data.image_count)) || Number(data.image_count) < 1) {
      throw new Error("math_s2_private_assets_not_ready");
    }
    return Object.freeze({ questionCount: 20, imageCount: Number(data.image_count) });
  }

  async function existingAttempt(tourId) {
    const value = await rpc("get_math_s2_resume_attempt_v1", {
      p_tour_id: positiveId(tourId)
    });
    if (value == null) return null;
    return positiveId(value);
  }

  function ownBlobUrl(url) {
    return typeof url === "string" && issuedBlobs.has(url);
  }

  function decodeImage(url) {
    return new Promise((resolve, reject) => {
      const image = new Image();
      let settled = false;
      const timeout = setTimeout(() => done(false), PRELOAD_TIMEOUT_MS);
      const done = (ok) => {
        if (settled) return;
        settled = true;
        clearTimeout(timeout);
        image.onload = null;
        image.onerror = null;
        if (ok && image.naturalWidth > 0) resolve();
        else reject(new Error("math_s2_private_image_decode_failed"));
      };
      image.onload = () => done(true);
      image.onerror = () => done(false);
      image.src = url;
      if (image.complete && image.naturalWidth > 0) done(true);
    });
  }

  async function hydrateIssuedQuestions(attemptId, originalRows, expectedImageCount) {
    const id = positiveId(attemptId);
    const rows = Array.isArray(originalRows) ? originalRows : [];
    if (rows.length !== 20) throw new Error("math_s2_issued_questions_not_20");
    const manifest = await rpc("get_math_s2_image_manifest_v1", { p_attempt_id: id });
    if (!Array.isArray(manifest)) throw new Error("math_s2_manifest_unavailable");
    const map = new Map();
    for (const entry of manifest) {
      const qid = positiveId(entry.question_id);
      const path = String(entry.object_path || "");
      if (!/^s2\/math\/[a-z0-9_/-]+\.(?:png|jpg|jpeg|webp|svg)$/.test(path) ||
        map.has(qid)) throw new Error("math_s2_bad_manifest");
      map.set(qid, path);
    }
    if (map.size !== Number(expectedImageCount)) {
      throw new Error("math_s2_manifest_count_changed");
    }

    const ids = new Set(rows.map(row => positiveId(row.id)));
    if (ids.size !== 20 || Array.from(map.keys()).some(key => !ids.has(key))) {
      throw new Error("math_s2_manifest_cross_attempt");
    }
    for (const row of rows) {
      if (String(row.image_url || "").trim() && !map.has(Number(row.id))) {
        throw new Error("math_s2_missing_private_image");
      }
    }

    const allocated = [];
    const privateUrls = new Map();
    try {
      for (const [qid, objectPath] of map) {
        // JWT-authenticated Storage download; never create public/signed URLs.
        const { data: blob, error } = await sb().storage.from(BUCKET).download(objectPath);
        if (error || !blob || typeof blob.size !== "number" ||
          blob.size <= 0 || blob.size > MAX_BYTES ||
          !/^image\/(?:png|jpeg|webp|svg\+xml)$/.test(String(blob.type || ""))) {
          throw new Error("math_s2_private_image_unavailable");
        }
        const localUrl = URL.createObjectURL(blob);
        issuedBlobs.add(localUrl);
        allocated.push(localUrl);
        await decodeImage(localUrl);
        privateUrls.set(qid, localUrl);
      }
      // Never pass a legacy public image URL into the active S2 renderer.
      return rows.map(row => ({
        ...row,
        image_url: privateUrls.get(Number(row.id)) || null
      }));
    } catch (error) {
      allocated.forEach(url => {
        issuedBlobs.delete(url);
        URL.revokeObjectURL(url);
      });
      throw error;
    }
  }

  function releaseImages() {
    for (const url of issuedBlobs) URL.revokeObjectURL(url);
    issuedBlobs.clear();
  }
  window.addEventListener("pagehide", releaseImages);
  window.iclubMathS2PrivateImages = Object.freeze({
    version: "math-s2-private-v1",
    isMathSeason2,
    preflight,
    existingAttempt,
    hydrateIssuedQuestions,
    ownBlobUrl,
    releaseImages
  });
})();
