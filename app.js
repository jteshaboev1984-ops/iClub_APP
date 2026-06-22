/* =========================================================
   iClub WebApp — app.js (v1 skeleton, aligned to new index.html)
   Plain HTML/CSS/JS, no build tools
   ========================================================= */

(() => {
  "use strict";

    // --- YouTube API (Telegram Safe) ---
  let ytPlayer = null;
  let isYtReady = false;

  const isTelegramWebApp = (() => {
    try {
      return !!(window.Telegram && window.Telegram.WebApp);
    } catch {
      return false;
    }
  })();

  // В Telegram WebApp: НЕ грузим YouTube IFrame API (часто ломает postMessage/origin)
  if (!isTelegramWebApp) {
    const ytScript = document.createElement('script');
    ytScript.src = "https://www.youtube.com/iframe_api";
    const firstScriptTag = document.getElementsByTagName('script')[0];
    if (firstScriptTag && firstScriptTag.parentNode) {
      firstScriptTag.parentNode.insertBefore(ytScript, firstScriptTag);
    } else {
      document.head.appendChild(ytScript);
    }

    window.onYouTubeIframeAPIReady = function() {
      isYtReady = true;
    };
  }
  // ---------------------------
  // Helpers
  // ---------------------------
  const $ = (sel, root = document) => root.querySelector(sel);
const $$ = (sel, root = document) => Array.from(root.querySelectorAll(sel));

// ---------------------------
// Tours loading overlay (Subject Tours screen)
// ---------------------------
function showToursLoading() {
  const el = document.getElementById("tours-loading");
  if (!el) return;

  // update label via i18n if available
  const txt = el.querySelector(".tours-loading-text");
  if (txt && typeof t === "function") txt.textContent = t("loading") || txt.textContent;

  el.classList.remove("hidden");
}

function hideToursLoading() {
  const el = document.getElementById("tours-loading");
  if (!el) return;
  el.classList.add("hidden");
}

function formatTourDateShort(isoDate) {
  const raw = String(isoDate || "").trim();
  if (!raw) return "";

  const m = raw.match(/^(\d{4})-(\d{2})-(\d{2})$/);
  if (!m) return raw;

  return `${m[3]}.${m[2]}.${m[1]}`;
}

function formatTourDateText(startDate, endDate) {
  const sd = formatTourDateShort(startDate);
  const ed = formatTourDateShort(endDate);

  if (sd && ed) return `${sd} → ${ed}`;
  if (sd) return sd;
  if (ed) return ed;
  return "";
}

let __viewTransitionTimer = null;

function currentLang() {
  try {
    if (window.i18n && typeof window.i18n.getLang === "function") {
      return String(window.i18n.getLang() || "ru").toLowerCase();
    }
  } catch {}

  try {
    const profile = typeof loadProfile === "function" ? loadProfile() : null;
    return String(profile?.uiLanguage || profile?.language || "ru").toLowerCase();
  } catch {}

  return "ru";
}

function currentContentLang() {
  try {
    const profile = typeof loadProfile === "function" ? loadProfile() : null;
    return String(profile?.language || profile?.uiLanguage || "ru").toLowerCase();
  } catch {}
  return "ru";
}

function tr3(ru, uz, en) {
  const lang = currentLang();
  if (lang === "uz") return String(uz ?? ru ?? en ?? "");
  if (lang === "en") return String(en ?? ru ?? uz ?? "");
  return String(ru ?? uz ?? en ?? "");
}

function tc3(ru, uz, en) {
  const lang = currentContentLang();
  if (lang === "uz") return String(uz ?? ru ?? en ?? "");
  if (lang === "en") return String(en ?? ru ?? uz ?? "");
  return String(ru ?? uz ?? en ?? "");
}

function inputHintForAnswer(correctAnswer) {
  const expected = String(correctAnswer ?? "").trim();

  if (parseFlexibleScientificNumber(expected) !== null) {
    if (inputExpectedRequiresExplicitSign(expected)) {
      return tr3(
        "Введите число со знаком, например +4 или -3",
        "Belgili son kiriting, masalan +4 yoki -3",
        "Enter a signed number, e.g. +4 or -3"
      );
    }

    if (/[eE]/.test(expected)) {
      return tr3(
        "Введите число в формате e, например 1.5e3",
        "Sonni e formatida kiriting, masalan 1.5e3",
        "Enter a number in e format, e.g. 1.5e3"
      );
    }

    return tr3(
      "Введите только число без слов, единиц и знаков",
      "Faqat son kiriting: so‘z, birlik va belgisiz",
      "Enter only the number: no words, units or signs"
    );
  }

  return tr3(
    "Введите ответ",
    "Javobni kiriting",
    "Enter answer"
  );
}

function refreshLiveProgressSurfaces() {
  try { _homeStatsCache?.clear?.(); } catch {}

  try { renderHome(); } catch {}
  try { renderProfileMain(); } catch {}
  try { renderProfileSettings(); } catch {}

  try {
    if (state?.tab === "courses" && typeof getCoursesTopScreen === "function" && getCoursesTopScreen() === "subject-hub") {
      renderSubjectHub();
    }
  } catch {}
}

function showViewTransitionOverlay(duration = 220) {
  const el = document.getElementById("view-transition-overlay");
  if (!el) return;

  const txt = el.querySelector(".view-transition-text");
  if (txt && typeof t === "function") {
    txt.textContent = t("loading") || txt.textContent;
  }

  el.classList.remove("hidden");
  el.classList.remove("is-busy");

  if (__viewTransitionTimer) {
    clearTimeout(__viewTransitionTimer);
    __viewTransitionTimer = null;
  }

  __viewTransitionTimer = setTimeout(() => {
    el.classList.add("hidden");
    el.classList.remove("is-busy");
    __viewTransitionTimer = null;
  }, duration);
}

function showAsyncOverlay(label) {
  const el = document.getElementById("view-transition-overlay");
  if (!el) return;

  const txt = el.querySelector(".view-transition-text");
  if (txt) {
    txt.textContent =
      String(label || "").trim() ||
      (typeof t === "function" ? (t("loading") || "Загрузка…") : "Загрузка…");
  }

  if (__viewTransitionTimer) {
    clearTimeout(__viewTransitionTimer);
    __viewTransitionTimer = null;
  }

  el.classList.remove("hidden");
  el.classList.add("is-busy");
}

function hideAsyncOverlay() {
  const el = document.getElementById("view-transition-overlay");
  if (!el) return;

  const txt = el.querySelector(".view-transition-text");
  if (txt && typeof t === "function") {
    txt.textContent = t("loading") || txt.textContent;
  }

  el.classList.remove("is-busy");
  el.classList.add("hidden");
}

function showCertificateFlowOverlay(i18nKey = "certificate_download_preparing", fallback = "Подготавливаем сертификат…") {
  const el = document.getElementById("view-transition-overlay");
  if (!el) return;

  const txt = el.querySelector(".view-transition-text");
  if (txt) {
    const label = (typeof t === "function" ? t(i18nKey) : "") || fallback;
    txt.textContent = label;
  }

  if (__viewTransitionTimer) {
    clearTimeout(__viewTransitionTimer);
    __viewTransitionTimer = null;
  }

  el.classList.remove("hidden");
}

function showCertificateDownloadOverlay() {
  showCertificateFlowOverlay("certificate_download_preparing", "Подготавливаем сертификат…");
}

function hideCertificateDownloadOverlay() {
  const el = document.getElementById("view-transition-overlay");
  if (!el) return;

  const txt = el.querySelector(".view-transition-text");
  if (txt && typeof t === "function") {
    txt.textContent = t("loading") || txt.textContent;
  }

  el.classList.add("hidden");
}

async function waitForOverlayPaint() {
  await new Promise((resolve) => requestAnimationFrame(() => requestAnimationFrame(resolve)));
  await new Promise((resolve) => setTimeout(resolve, 60));
}

  function escapeHTML(value) {
    return String(value ?? "")
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;")
      .replace(/'/g, "&#039;");
  }

  // ---------------------------
  // Credentials: normalize subject_id (IMPORTANT)
  // ---------------------------
  function normSubjectId(v) {
    return String(v ?? "").trim().toLowerCase();
  }

    function safeJsonParse(s, fallback) {
  if (s === null || s === undefined || s === "") return fallback;
  try { return JSON.parse(s); } catch { return fallback; }
}

async function getSeasonOneId() {
  try {
    if (!window.sb) return null;

    const { data, error } = await window.sb
      .from("seasons")
      .select("id")
      .eq("season_no", 1)
      .maybeSingle();

    if (error || !data?.id) return null;
    return Number(data.id) || null;
  } catch {
    return null;
  }
}

async function getCurrentSeasonId() {
  try {
    if (!window.sb) return null;

    const { data, error } = await window.sb
      .from("seasons")
      .select("id,season_no,status")
      .eq("status", "current")
      .order("season_no", { ascending: false })
      .limit(1);

    if (!error && Array.isArray(data) && data[0]?.id) {
      return Number(data[0].id) || null;
    }
  } catch {}

  return await getSeasonOneId();
}

async function getTourSeasonIdByTourId(tourId) {
  try {
    if (!window.sb || !tourId) return null;

    const { data, error } = await window.sb
      .from("tours")
      .select("season_id")
      .eq("id", tourId)
      .maybeSingle();

    if (error || !data?.season_id) return null;
    return Number(data.season_id) || null;
  } catch {
    return null;
  }
}

async function resolveTourSeasonId({
  seasonId = null,
  tourId = null
} = {}) {
  const direct = Number(seasonId || 0);

  if (Number.isFinite(direct) && direct > 0) {
    return direct;
  }

  const byTour = await getTourSeasonIdByTourId(tourId);

  if (byTour) {
    return byTour;
  }

  return await getCurrentSeasonId();
}

function tourRecommendationKeyV1(seasonId, tourNo, topic, subtopic) {
  return [
    Number(seasonId || 0),
    Number(tourNo || 0),
    String(topic || "").trim(),
    subtopic ? String(subtopic).trim() : ""
  ].join("::");
}


    // ---------------------------
  // DB write retry (critical writes only)
  // ---------------------------
  async function dbWriteWithRetry(fn, { tries = 3, baseDelayMs = 350 } = {}) {
    let lastErr = null;
    for (let i = 0; i < tries; i++) {
      try {
        return await fn();
      } catch (e) {
        lastErr = e;
        const delay = baseDelayMs * Math.pow(2, i);
        await new Promise(r => setTimeout(r, delay));
      }
    }
    throw lastErr;
  }

   async function hasDbUserRow(uid) {
  try {
    if (!window.sb || !uid) return false;

    const { data, error } = await window.sb
      .from("users")
      .select("id")
      .eq("id", uid)
      .maybeSingle();

    return !error && !!data?.id;
  } catch {
    return false;
  }
}

   async function checkDbUserRow(uid) {
  try {
    if (!window.sb || !uid) {
      return { ok: false, exists: false, reason: "missing_sb_or_uid" };
    }

    const { data, error } = await window.sb
      .from("users")
      .select("id")
      .eq("id", uid)
      .maybeSingle();

    if (error) {
      return { ok: false, exists: false, reason: "db_error", error };
    }

    return {
      ok: true,
      exists: !!data?.id
    };
  } catch (e) {
    return {
      ok: false,
      exists: false,
      reason: "exception",
      error: e
    };
  }
}
   
async function ensureHomeDbReady() {
  try {
    const profile = loadProfile();
    if (!profile || !window.sb) return { ok: true, skipped: true };

    if (!__profileSubjectsDbReady) {
      try { await ensureProfileSubjectsDbSynced(); } catch {}
    }

    try { await ensureProfileGeoTranslationsHydrated(); } catch {}

    return { ok: true };
  } catch {
    return { ok: false };
  }
}
  // ---------------------------
  // Pending DB ops (offline-safe)
  // ---------------------------
  function loadPendingOps() {
    try {
      const raw = localStorage.getItem(LS.pendingOps);
      const arr = raw ? JSON.parse(raw) : [];
      return Array.isArray(arr) ? arr : [];
    } catch {
      return [];
    }
  }

    function savePendingOps(arr) {
    try {
      localStorage.setItem(LS.pendingOps, JSON.stringify(Array.isArray(arr) ? arr.slice(0, 200) : []));
    } catch {}
  }

   function clearPendingTourOpsAfterIdentityRecovery() {
  try {
    const arr = loadPendingOps();
    if (!Array.isArray(arr) || !arr.length) return { ok: true, removed: 0 };

    const keep = [];
    let removed = 0;

    for (const op of arr) {
      const type = String(op?.type || "");
      if (type === "tour_answer" || type === "tour_finalize") {
        removed += 1;
        continue;
      }
      keep.push(op);
    }

    if (removed > 0) savePendingOps(keep);

    return { ok: true, removed };
  } catch {
    return { ok: false, removed: 0 };
  }
}
   
  function hasPendingOpsQueued() {
    try {
      return loadPendingOps().length > 0;
    } catch {
      return false;
    }
  }

    function enqueuePendingOp(op) {
    try {
      const arr = loadPendingOps();

      const next = { ...op, ts: Date.now() };

      // ✅ дедупликация: держим только последнюю версию
      if (next?.type === "tour_answer" && next.attemptId && next.questionId) {
        const aId = String(next.attemptId);
        const qId = String(next.questionId);

        for (let i = arr.length - 1; i >= 0; i--) {
          const it = arr[i];
          if (it?.type === "tour_answer" && String(it.attemptId) === aId && String(it.questionId) === qId) {
            arr.splice(i, 1);
            break;
          }
        }
      }

            if (next?.type === "tour_finalize" && next.attemptId) {
        const aId = String(next.attemptId);
        for (let i = arr.length - 1; i >= 0; i--) {
          const it = arr[i];
          if (it?.type === "tour_finalize" && String(it.attemptId) === aId) {
            arr.splice(i, 1);
            break;
          }
        }
      }

      // ✅ дедупликация app_event по clientEventId (чтобы не спамить)
      if (next?.type === "app_event" && next.clientEventId != null) {
        const eId = String(next.clientEventId);
        for (let i = arr.length - 1; i >= 0; i--) {
          const it = arr[i];
          if (it?.type === "app_event" && String(it.clientEventId) === eId) {
            arr.splice(i, 1);
            break;
          }
        }
      }

      // ✅ лимит очереди (безопасно)
      arr.push(next);
      savePendingOps(arr);
    } catch {}
  }

  let _flushPendingOpsInFlight = false;
  let _flushPendingOpsTimer = null;

  function scheduleFlushPendingOps(delayMs = 0) {
    try {
      if (_flushPendingOpsTimer) clearTimeout(_flushPendingOpsTimer);
      _flushPendingOpsTimer = setTimeout(() => {
        _flushPendingOpsTimer = null;
        flushPendingOps().catch(() => null);
      }, Math.max(0, Number(delayMs) || 0));
    } catch {}
  }

    async function flushPendingOps() {
    if (_flushPendingOpsInFlight) return;
    if (!window.sb) return;

    // ✅ не пытаемся синкать в оффлайне
    try {
      if (typeof navigator !== "undefined" && navigator.onLine === false) return;
    } catch {}

    const uid = await getAuthUid().catch(() => null);
    if (!uid) return;

    const ops = loadPendingOps();
    if (!ops.length) return;

    _flushPendingOpsInFlight = true;
    try {
      const keep = [];

      for (const op of ops) {
        try {
                    if (op?.type === "practice_save") {
            // op.payload: { attempt, quiz }
            const res = await savePracticeAttemptToSupabase(op.payload?.attempt, op.payload?.quiz);

            if (res?.ok) {
              try {
                refreshLiveProgressSurfaces();
              } catch {}
            } else {
              keep.push(op);
            }

            continue;
          }

          if (op?.type === "tour_answer") {
            const r = await upsertTourAnswer(op.attemptId, op.questionId, op.patch || {});
            if (!r?.ok) keep.push(op);
            continue;
          }

                    if (op?.type === "tour_finalize") {
            const r = await updateTourAttempt(op.attemptId, op.patch || {});
            if (!r?.ok) keep.push(op);
            continue;
          }

                    if (op?.type === "app_event") {
            const eventUserId = String(op.userId || "");

            // ✅ не пишем app_events, пока нет полноценной users-row
            const canWriteEvent = await hasDbUserRow(eventUserId);
            if (!canWriteEvent) {
              keep.push(op);
              continue;
            }

            const { error } = await window.sb.from("app_events").insert({
              user_id: eventUserId,
              event_type: op.eventType,
              payload: op.payload || {}
            });

            if (error) keep.push(op);
            continue;
          }

          // unknown op → keep (safer)
          keep.push(op);
        } catch {
          keep.push(op);
        }
      }

      savePendingOps(keep);
    } finally {
      _flushPendingOpsInFlight = false;
    }
  }

  // ---------------------------
  // Supabase (v1 connect)
  // ---------------------------
  // ✅ ВАЖНО: заполни эти 2 значения из Supabase → Project Settings → API
  const SUPABASE_URL = "https://mmmduffgpvwjdpruzikw.supabase.co";      // например: https://xxxx.supabase.co
  const SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1tbWR1ZmZncHZ3amRwcnV6aWt3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjkwNzEwMzksImV4cCI6MjA4NDY0NzAzOX0.G3bV2tOaToFsMr9ejTRuXBHYZQvissIds3g_g7K0t7I"; // anon public key

  let sb = null;

// ✅ auth single-flight guards
let __initSupabaseSessionPromise = null;
let __anonSignInPromise = null;
let __authRateLimitedUntil = 0;

function isAuthRateLimitedNow() {
  return Date.now() < Number(__authRateLimitedUntil || 0);
}

function markAuthRateLimited(err, fallbackMs = 45000) {
  const msg = String(err?.message || err || "").toLowerCase();
  const code = String(err?.status || err?.code || "").toLowerCase();

  if (
    msg.includes("429") ||
    msg.includes("rate limit") ||
    code === "429"
  ) {
    __authRateLimitedUntil = Date.now() + Math.max(5000, Number(fallbackMs) || 45000);
    return true;
  }

  return false;
}

async function ensureAnonymousSessionSingleFlight() {
  const client = window.sb || sb;
  if (!client?.auth) return null;

  if (isAuthRateLimitedNow()) {
    return null;
  }

  if (__anonSignInPromise) {
    return __anonSignInPromise;
  }

  __anonSignInPromise = (async () => {
    try {
      // уже есть сессия → ничего не делаем
      const { data: beforeData } = await client.auth.getSession();
      if (beforeData?.session) return beforeData.session;

      // в оффлайне не пытаемся плодить auth-попытки
      try {
        if (typeof navigator !== "undefined" && navigator.onLine === false) {
          return null;
        }
      } catch {}

      const { data: anonData, error: anonErr } = await client.auth.signInAnonymously();

      if (anonErr) {
        markAuthRateLimited(anonErr);
        return null;
      }

      // ✅ не делаем второй getSession сразу после signInAnonymously()
      return anonData?.session || null;
    } catch (e) {
      markAuthRateLimited(e);
      return null;
    } finally {
      __anonSignInPromise = null;
    }
  })();

  return __anonSignInPromise;
}

     // ✅ Автоматическое подключение пользователя к боту
      async function tryLinkBotOnce(reason = "registration") {
  try {
    const tg = window.Telegram?.WebApp;
    if (!tg || typeof tg.sendData !== "function") return false;

    // если уже отправляли — не повторяем
    if (localStorage.getItem(LS.botLinked) === "1") return true;

        let uid = null;
    try {
      const { data } = await (sb || window.sb)?.auth?.getUser();
      uid = data?.user?.id || null;
    } catch {}

    const u = window.Telegram?.WebApp?.initDataUnsafe?.user || null;

    const payload = {
      type: "link_bot",
      v: 1,
      reason,
      uid,
      telegram_user_id: u?.id ? String(u.id) : null
    };

    tg.sendData(JSON.stringify(payload));

    localStorage.setItem(LS.botLinked, "1");
    return true;
  } catch {
    return false;
  }
}
   
   async function initSupabaseSession({ allowAnonymousBootstrap = false } = {}) {
  if (!SUPABASE_URL || !SUPABASE_ANON_KEY) return null;
  if (!window.supabase?.createClient) return null;

  if (__initSupabaseSessionPromise) {
    return __initSupabaseSessionPromise;
  }

  __initSupabaseSessionPromise = (async () => {
    if (!sb) {
      sb = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
        auth: {
          persistSession: true,
          autoRefreshToken: true,
          detectSessionInUrl: false,
        },
      });

      // compatibility bridge:
      // large parts of the app still read window.sb directly
      window.sb = sb;
    } else if (!window.sb) {
      window.sb = sb;
    }

    // 1) На обычном boot НЕ создаём anonymous auth.
    // Используем существующую сессию, если она уже есть.
    // Anonymous bootstrap разрешаем только там, где это явно нужно
    // (например, на финальном шаге регистрации).
    try {
      const { data: sessData } = await sb.auth.getSession();

      if (!sessData?.session && allowAnonymousBootstrap) {
        await ensureAnonymousSessionSingleFlight();
      }
        } catch (anonErr) {
      markAuthRateLimited(anonErr);
      console.error("[Supabase] Session bootstrap failed:", anonErr);

      if (!isAuthRateLimitedNow()) {
        const statusEl = document.getElementById("splash-status");
        if (statusEl) {
          statusEl.textContent = "Supabase auth error: " + (anonErr?.message || "unknown");
        }
      }

      // Не валим приложение — просто работаем без базы
      return sb;
    }

    // 2) get auth user, but НЕ создаём public.users-строку до завершения регистрации
    const { data: userData } = await sb.auth.getUser();
    const u = userData?.user;
    if (!u?.id) return sb;
     
    const tg = getTelegramUserSafe();

    // ✅ Проверяем, существует ли уже полноценная DB-строка пользователя.
    // Если её нет, значит регистрация ещё не завершена — shell-row на boot НЕ создаём.
    let hasDbUserRow = false;
    try {
      const { data: existingUserRow, error } = await sb
        .from("users")
        .select("id")
        .eq("id", u.id)
        .maybeSingle();

      hasDbUserRow = !error && !!existingUserRow?.id;
    } catch {
      hasDbUserRow = false;
    }

    // ✅ reset subject cache for this session (prevents poisoned null cache)
    try { _subjectIdByKeyCache.clear(); } catch {}

    // ✅ boot event и hydrate credentials делаем только если users-row уже существует.
    // Иначе app_events/users FK ломается, а в users попадают неполные shell-данные.
    if (hasDbUserRow) {
      // ✅ boot event: write at most once per day per device (prevents DB flooding)
      try {
        const day = dayKeyTashkent(Date.now());
        const k = "iclub_boot_day_v1";
        const last = String(localStorage.getItem(k) || "");
        if (last !== day) {
          await sb.from("app_events").insert({
            user_id: u.id,
            event_type: "boot",
            payload: { has_tg: !!tg, ua: navigator.userAgent },
          });
          localStorage.setItem(k, day);
        }
      } catch (e) {
        logClientError("boot_event_insert", e);
      }

      // ✅ Earned Credentials: hydrate local events store from Supabase
      try {
        const changed = await hydrateLocalEventsFromSupabase(sb, u.id);

        try { runDailyCredentialJobs(); } catch {}

        if (changed) {
          try { renderProfile(); } catch {}
          try { renderSubjectHub(); } catch {}
        }
      } catch {}
    }

    return sb;
  })();

  try {
    return await __initSupabaseSessionPromise;
  } finally {
    __initSupabaseSessionPromise = null;
  }
}

async function ensureRegistrationAuthUid({ totalWaitMs = 5000, pollMs = 1000 } = {}) {
  try {
    // ✅ registration-flow может поднять auth, но без спама
    await initSupabaseSession({ allowAnonymousBootstrap: true }).catch(() => null);

    if (!window.sb?.auth) return null;

    let uid = await getAuthUid().catch(() => null);
    if (uid) return uid;

    const startedAt = Date.now();
    let retriedBootstrap = false;

    while ((Date.now() - startedAt) < totalWaitMs) {
      await new Promise((resolve) => setTimeout(resolve, pollMs));

      uid = await getAuthUid().catch(() => null);
      if (uid) return uid;

      if (isAuthRateLimitedNow()) {
        break;
      }

      // ✅ максимум одна мягкая повторная попытка
      if (!retriedBootstrap && (Date.now() - startedAt) >= 2200) {
        retriedBootstrap = true;
        await ensureAnonymousSessionSingleFlight().catch(() => null);

        uid = await getAuthUid().catch(() => null);
        if (uid) return uid;
      }
    }

    return await getAuthUid().catch(() => null);
  } catch (e) {
    markAuthRateLimited(e);
    return null;
  }
}
   
function nowISO() {
  return new Date().toISOString();
}

  // ✅ monotonic time (not affected by changing device clock)
  function monoNow() {
    try {
      if (typeof performance !== "undefined" && typeof performance.now === "function") {
        return performance.now();
      }
    } catch {}
    return Date.now();
  }
     // ---------------------------
  // Earned Credentials: hydrate LS.events from Supabase app_events
  // LS.events must be { seq:number, items:[{id,type,payload,ts,day}] }
  // ---------------------------
  async function hydrateLocalEventsFromSupabase(sbClient, userId) {
  if (!sbClient || !userId) return false;

  // Always keep strict format: { seq:number, items:[{id,type,payload,ts,day}] }
  const local = loadJsonLS(LS.events, { seq: 0, items: [] });
  const localItems = Array.isArray(local?.items) ? local.items : [];
  let seq = Number(local?.seq) || 0;

  // Build a fast "already have" set using db_created_at signature
  const have = new Set(
    localItems
      .map(e => e?.payload?._db_created_at ? `${e.type}|${e.payload._db_created_at}` : null)
      .filter(Boolean)
  );

    // Fetch only NEW events from DB (lightweight)
  let lastDbTs = null;
  try {
    const dbTs = localItems
      .map(e => e?.payload?._db_created_at ? Date.parse(e.payload._db_created_at) : NaN)
      .filter(n => Number.isFinite(n))
      .sort((a,b) => b-a)[0];
    if (Number.isFinite(dbTs)) lastDbTs = new Date(dbTs).toISOString();
  } catch {}

  let q = sbClient
    .from("app_events")
    .select("event_type,payload,created_at")
    .eq("user_id", userId)
    .order("created_at", { ascending: true })
    .limit(500);

  if (lastDbTs) q = q.gt("created_at", lastDbTs);

  const { data, error } = await q;

  if (error) throw error;

  let added = 0;

  (data || []).forEach((r) => {
    const dbCreatedAt = r.created_at || null;
    const sig = dbCreatedAt ? `${r.event_type}|${dbCreatedAt}` : null;

    // If we already merged this DB row before — skip
    if (sig && have.has(sig)) return;

    const ts = Date.parse(dbCreatedAt) || Date.now();

    const evt = {
      id: ++seq,
      type: r.event_type,
      payload: { ...(r.payload || {}), _db_created_at: dbCreatedAt },
      ts,
      day: dayKeyTashkent(ts),
    };

    localItems.push(evt);
    if (sig) have.add(sig);
    added += 1;
  });

  // keep last N events (avoid LS overflow)
  if (localItems.length > 2000) {
    const sliced = localItems.slice(-2000);
    // re-seq to keep ids compact and monotonic
    let s = 0;
    const re = sliced.map(e => ({ ...e, id: ++s }));
    saveJsonLS(LS.events, { seq: s, items: re });
  } else {
    saveJsonLS(LS.events, { seq, items: localItems });
  }

  return added > 0;
}

  // ---------------------------
  // Storage keys
  // ---------------------------
    const LS = {
  state: "iclub_state_v1",
  profile: "iclub_profile_v1",
  practiceDraft: "iclub_practice_draft_v1",
  myRecs: "iclub_my_recs_v1",
  myTourRecs: "iclub_my_tour_recs_v1",
  botLinked: "iclub_bot_linked_v1",
  homeExtraOpen: "iclub_home_extra_open_v1",
  pendingOps: "iclub_pending_ops_v1",
  events: "iclub_events_v1",
  credentials: "iclub_credentials_v1"
};

  // ---------------------------
  // i18n
  // ---------------------------
  const t = (key, vars) => (window.i18n?.t ? window.i18n.t(key, vars) : key);

function applyStaticI18n() {
    document.querySelectorAll("[data-i18n]").forEach(el => {
      const key = el.dataset.i18n;
      if (key) el.textContent = t(key);
    });
    document.querySelectorAll("[data-i18n-placeholder]").forEach(el => {
      const key = el.dataset.i18nPlaceholder;
      if (key) el.setAttribute("placeholder", t(key));
    });
  }

     function updateOfflineBanner() {
    try {
      const el = document.getElementById("offline-banner");
      if (!el) return;
      const isOn = (navigator.onLine === false);
      el.style.display = isOn ? "block" : "none";
    } catch {}
  }

     function logClientError(where, err) {
    try {
      console.warn("[iClub]", where, err);
    } catch {}
  }
  // =========================================================
  // Earned Credentials — Engine (v1.3 FINAL) + Event Mapping
  // Plain storage (local) + optional Supabase app_events mirror
  // =========================================================

  const TZ = "Asia/Tashkent";

  function loadJsonLS(key, fallback) {
    return safeJsonParse(localStorage.getItem(key), fallback);
  }
  function saveJsonLS(key, value) {
    localStorage.setItem(key, JSON.stringify(value));
  }

  function pad2(n) { return String(n).padStart(2, "0"); }

  // Local “calendar day” key in Asia/Tashkent
  function dayKeyTashkent(ts = Date.now()) {
    try {
      const d = new Date(ts);
      const parts = new Intl.DateTimeFormat("en-CA", {
        timeZone: TZ,
        year: "numeric",
        month: "2-digit",
        day: "2-digit"
      }).formatToParts(d);
      const y = parts.find(p => p.type === "year")?.value || "1970";
      const m = parts.find(p => p.type === "month")?.value || "01";
      const da = parts.find(p => p.type === "day")?.value || "01";
      return `${y}-${m}-${da}`;
    } catch {
      const d = new Date(ts);
      return `${d.getFullYear()}-${pad2(d.getMonth() + 1)}-${pad2(d.getDate())}`;
    }
  }

      function eventsStore() {
    let s = loadJsonLS(LS.events, { seq: 0, items: [] });

    // accept old shapes:
    // 1) array of events
    // 2) { items: [...], hydrated_at: ... }
    if (Array.isArray(s)) {
      s = { seq: 0, items: s };
    } else if (s && !Array.isArray(s.items) && Array.isArray(s?.items?.items)) {
      // just in case of nested shapes
      s = { seq: 0, items: s.items.items };
    } else if (s && !Array.isArray(s.items) && Array.isArray(s?.items)) {
      s = { seq: 0, items: s.items };
    }

    if (!s || typeof s !== "object") s = { seq: 0, items: [] };
    if (!Array.isArray(s.items)) s.items = [];
    if (typeof s.seq !== "number") s.seq = 0;

    // ✅ normalize events (fix ts/day/id)
    let maxId = 0;
    for (let i = 0; i < s.items.length; i++) {
      const e = s.items[i] || {};
      // ts: allow number OR ISO string
      let ts = e.ts;
      if (typeof ts === "string") {
        const parsed = Date.parse(ts);
        ts = Number.isFinite(parsed) ? parsed : Date.now();
      } else if (typeof ts !== "number" || !Number.isFinite(ts)) {
        ts = Date.now();
      }

      // id
      let id = e.id;
      if (typeof id !== "number" || !Number.isFinite(id)) id = i + 1;

      // day
      const day = e.day || dayKeyTashkent(ts);

      s.items[i] = {
        id,
        type: e.type,
        payload: e.payload || {},
        ts,
        day
      };

      if (id > maxId) maxId = id;
    }

    // ensure seq >= max id
    if (maxId > s.seq) s.seq = maxId;

    // persist normalized store (important for next runs)
    try { saveJsonLS(LS.events, s); } catch {}

    return s;
  }

  function credentialsStore() {
    const base = {
      version: "v1.3",
      last_daily_eval_day: null,

      consistent_learner: {
        status: "inactive",
        achieved_at: null,
        last_evaluated_at: null,
        evidence: { computed_at: null, window_start: null, window_end: null, active_days_14d: 0, last_events: [] },
        // buffer counter required by contract (degradation buffer)
        degradation_counter_days: 0
      },

      focused_study_streak: {
        status: "inactive",
        achieved_at: null,
        last_evaluated_at: null,
        evidence: { computed_at: null, current_subject_id: null, focused_sessions_in_row: 0, last_events: [] }
      },

      active_video_learner: {
        status: "inactive",
        achieved_at: null,
        last_evaluated_at: null,
        evidence: { computed_at: null, videos_decided: 0, videos_completed: 0, completion_rate: 0, last_events: [] },
        decided_by_lesson: {} // { [lesson_id]: { decided: true, completed: bool } }
      },

      practice_mastery_subject: {
        by_subject: {} // subject_id => { status, achieved_at, last_evaluated_at, evidence:{attempts_count,best,median,last_events}, percents:[] }
      },

      error_driven_learner: {
        status: "inactive",
        achieved_at: null,
        last_evaluated_at: null,
        evidence: { computed_at: null, cycles_count: 0, error_reduction: 0, last_events: [] },
        // minimal trace:
        // - last attempt A with errors per (subject_id + topic)
        last_attempt_a: {}, // key => { attempt_key, errors_count, ts, subject_id, topic }
        // - review opened markers for attempt A
        reviewed_attempts: {}, // attempt_key => { ts }
        cycles_count: 0
      },

      research_oriented_learner: {
        status: "inactive",
        achieved_at: null,
        last_evaluated_at: null,
        evidence: { computed_at: null, resource_opens_total: 0, distinct_return_days: 0, last_events: [] }
      },

      fair_play_participant: {
        status: "inactive",
        achieved_at: null,
        last_evaluated_at: null,
        evidence: { computed_at: null, tours_participated: 0, has_critical_violation: false, last_events: [] },
        tours_participated: 0,
        has_critical_violation: false
      }
    };

    const s = loadJsonLS(LS.credentials, base);
    // Ensure missing keys for forward safety
    return Object.assign({}, base, s);
  }

  function saveCredentialsStore(s) {
  saveJsonLS(LS.credentials, s);
}

// ✅ UI-обёртка (renderProfileCredentialsUI читает через неё)
function getCredentialStore() {
  return credentialsStore();
}

  function pushLastEvents(list, eventId, limit = 5) {
    const arr = Array.isArray(list) ? list.slice() : [];
    if (eventId) arr.unshift(eventId);
    return arr.slice(0, limit);
  }

    async function mirrorEventToSupabase(type, payload) {
    try {
      if (!window.sb) return;

      const { data: userData } = await window.sb.auth.getUser();
      const u = userData?.user;
      if (!u?.id) return;

      const p = payload || {};
      const clientEventId = p.client_event_id;

      // ✅ отправляем через pending ops (надёжно при оффлайне)
      enqueuePendingOp({
        type: "app_event",
        userId: u.id,
        eventType: type,
        payload: p,
        clientEventId
      });

      // ✅ пробуем синкнуть сразу (если онлайн)
      try { scheduleFlushPendingOps(0); } catch {}
    } catch {
      // silent
    }
  }

      // ---------------------------
// ✅ Credentials → Supabase (user_credentials) sync
// ---------------------------
let __credIdsCache = null;           // { code: id }
let __credSyncTimer = null;
let __credSyncInFlight = false;

async function getCredentialIdsMap() {
  if (__credIdsCache && typeof __credIdsCache === "object") return __credIdsCache;
  if (!window.sb) return {};

  const { data, error } = await window.sb
    .from("credential_definitions")
    .select("id,code")
    .eq("is_active", true);

  if (error) {
    try { console.error("[cred] credential_definitions read error:", error); } catch {}
    return {};
  }

  const map = {};
  (data || []).forEach(r => { if (r?.code && r?.id) map[r.code] = r.id; });
  __credIdsCache = map;
  return map;
}

function buildCredentialSnapshotForDb(cStore) {
  // Берём ровно те коды, которые у тебя есть в credentialsStore()
  return {
    consistent_learner: cStore.consistent_learner || null,
    focused_study_streak: cStore.focused_study_streak || null,
    active_video_learner: cStore.active_video_learner || null,
    practice_mastery_subject: cStore.practice_mastery_subject || null,
    error_driven_learner: cStore.error_driven_learner || null,
    research_oriented_learner: cStore.research_oriented_learner || null,
    fair_play_participant: cStore.fair_play_participant || null
  };
}

async function syncCredentialsToSupabaseOnce() {
  if (__credSyncInFlight) return;
  if (!window.sb) return;

  __credSyncInFlight = true;
  try {
    const { data: userData } = await window.sb.auth.getUser();
    const uid = userData?.user?.id;
    if (!uid) return;

    // ✅ не пишем user_credentials, пока нет полноценной users-row
    const canWriteCreds = await hasDbUserRow(uid);
    if (!canWriteCreds) return;

    const ids = await getCredentialIdsMap();
    if (!ids || Object.keys(ids).length === 0) return;

    const c = credentialsStore();
    const snap = buildCredentialSnapshotForDb(c);

    const rows = [];
    Object.keys(snap).forEach(code => {
      const defId = ids[code];
      const rec = snap[code];
      if (!defId || !rec) return;

      // статус для practice_mastery_subject вычисляем: active если есть хоть один active по предметам
      let status = (rec.status || "inactive");
      if (code === "practice_mastery_subject") {
        const by = rec?.by_subject || {};
        const anyActive = Object.values(by).some(x => x && x.status === "active");
        status = anyActive ? "active" : "inactive";
      }

      rows.push({
        user_id: uid,
        credential_id: defId,
        status: status,
        achieved_at: rec.achieved_at ? new Date(rec.achieved_at).toISOString() : null,
        evidence_snapshot: rec, // кладём весь record (как jsonb snapshot)
        last_evaluated_at: rec.last_evaluated_at ? new Date(rec.last_evaluated_at).toISOString() : null
      });
    });

    if (rows.length === 0) return;

    const { error: upErr } = await window.sb
      .from("user_credentials")
      .upsert(rows, { onConflict: "user_id,credential_id" });

    if (upErr) {
      // ✅ если это всё ещё FK-гонка, не шумим лишний раз — просто подождём следующего sync
      if (String(upErr?.code || "") === "23503") return;
      try { console.error("[cred] user_credentials upsert error:", upErr); } catch {}
    }
  } catch (e) {
    try { console.error("[cred] sync exception:", e); } catch {}
  } finally {
    __credSyncInFlight = false;
  }
}
function scheduleCredentialsDbSync(delayMs = 1200) {
  if (!window.sb) return;
  if (__credSyncTimer) clearTimeout(__credSyncTimer);
  __credSyncTimer = setTimeout(() => {
    __credSyncTimer = null;
    syncCredentialsToSupabaseOnce();
  }, Math.max(200, Number(delayMs) || 1200));
}

    function trackEvent(type, payload = {}) {
  const store = eventsStore();
  const id = ++store.seq;
  const ts = Date.now();

  const payloadForEvent = Object.assign({}, (payload || {}), {
    client_event_id: id,
    ts: new Date(ts).toISOString()
  });

  const item = {
    id,
    type,
    ts,
    day: dayKeyTashkent(ts),
    payload: payloadForEvent
  };

  store.items.push(item);

  // keep last N events (avoid LS overflow)
  if (store.items.length > 2000) store.items = store.items.slice(-2000);

  saveJsonLS(LS.events, store);

  // optional: mirror to Supabase app_events
  mirrorEventToSupabase(type, payloadForEvent);

  // realtime evaluation hooks
  evaluateRealtimeCredentials(item);

  return item;
}

  // ✅ DB sync for video analytics (video_events)
    async function insertVideoEventToSupabase(event_type, lesson_id, watch_seconds) {
    try {
      if (!window.sb) return;

      const lid = Number(lesson_id);
      if (!lid) return;

      const { data: uData, error: uErr } = await window.sb.auth.getUser();
      if (uErr) return;

      const uid = uData?.user?.id;
      if (!uid) return;

      const ws = Math.max(0, Math.round(Number(watch_seconds) || 0));

      const { error: insErr } = await window.sb.from("video_events").insert({
        user_id: uid,
        lesson_id: lid,
        event_type: String(event_type),
        watch_seconds: ws
      });

      if (insErr) logClientError("video_events_insert_error", insErr);
    } catch (e) {
      logClientError("video_events_insert_exception", e);
    }
  }

  async function getProfileCompletedToursCount() {
    try {
      if (!window.sb) return null;

      const uid = await getAuthUid();
      if (!uid) return null;

      const { data, error } = await window.sb
        .from("tour_attempts")
        .select("tour_id, percent, status")
        .eq("user_id", uid)
        .in("status", ["submitted", "time_expired", "anti_cheat", "finished"])
        .order("tour_id", { ascending: true });

      if (error) {
        logClientError("profile_tours_count_error", error);
        return null;
      }

      const uniq = new Set();
      (data || []).forEach(row => {
        const tourId = Number(row?.tour_id || 0);
        if (tourId > 0) uniq.add(tourId);
      });

      return uniq.size;
    } catch (e) {
      logClientError("profile_tours_count_exception", e);
      return null;
    }
  }

  function listEventsByType(types) {
    const st = eventsStore();
    const set = new Set(Array.isArray(types) ? types : [types]);
    return st.items.filter(e => set.has(e.type));
  }

  function getEventsInLastDays(days) {
    const st = eventsStore();
    const cutoff = Date.now() - Math.max(0, Number(days) || 0) * 24 * 60 * 60 * 1000;
    return st.items.filter(e => e.ts >= cutoff);
  }

  // ---------------------------
  // Credential evaluation
  // ---------------------------

  function evaluateConsistentLearnerDaily() {
    const c = credentialsStore();
    const todayDay = dayKeyTashkent(Date.now());

    // run once per “calendar day”
    if (c.last_daily_eval_day === todayDay) return c;

    const windowEvents = getEventsInLastDays(14);
    const activeTypes = new Set([
      "video_opened",
      "video_completed",
      "video_skipped",
      "practice_attempt_finished",
      "tour_attempt_finished",
      "resource_opened",
      "recommendation_opened"
    ]);

    const activeDays = new Set();
    windowEvents.forEach(e => {
      if (activeTypes.has(e.type)) activeDays.add(e.day);
    });

    const active_days_14d = activeDays.size;
    const exists_valid_14d_window = (active_days_14d >= 7);

    const hadEverActive = (c.consistent_learner.achieved_at != null) || (c.consistent_learner.status === "active");

    if (exists_valid_14d_window) {
      c.consistent_learner.status = "active";
      if (!c.consistent_learner.achieved_at) c.consistent_learner.achieved_at = Date.now();
      c.consistent_learner.degradation_counter_days = 0;
    } else {
      // buffer logic (no “instant death”)
      if (hadEverActive) {
        c.consistent_learner.degradation_counter_days = (Number(c.consistent_learner.degradation_counter_days) || 0) + 1;
        if (c.consistent_learner.degradation_counter_days >= 14) {
          c.consistent_learner.status = "inactive";
        } else {
          c.consistent_learner.status = "active"; // inside buffer
        }
      } else {
        // never earned: stays inactive until first valid window
        c.consistent_learner.status = "inactive";
        c.consistent_learner.degradation_counter_days = 0;
      }
    }

    c.consistent_learner.last_evaluated_at = Date.now();
    c.consistent_learner.evidence = {
      computed_at: Date.now(),
      window_start: Date.now() - 13 * 24 * 60 * 60 * 1000,
      window_end: Date.now(),
      active_days_14d,
      last_events: (c.consistent_learner.evidence?.last_events || []).slice(0, 5)
    };

    c.last_daily_eval_day = todayDay;
    saveCredentialsStore(c);
    return c;
  }

  function evaluateResearchOrientedDaily() {
    const c = credentialsStore();
    const ev = listEventsByType(["resource_opened", "recommendation_opened"]);
    const opens = ev.length;
    const days = new Set(ev.map(x => x.day));
    const distinct_return_days = days.size;

    const active = (opens >= 3 && distinct_return_days >= 2);

    const prev = c.research_oriented_learner.status;
    c.research_oriented_learner.status = active ? "active" : "inactive";
    if (active && !c.research_oriented_learner.achieved_at) c.research_oriented_learner.achieved_at = Date.now();
    c.research_oriented_learner.last_evaluated_at = Date.now();
    c.research_oriented_learner.evidence = {
      computed_at: Date.now(),
      resource_opens_total: opens,
      distinct_return_days,
      last_events: (c.research_oriented_learner.evidence?.last_events || []).slice(0, 5)
    };

    if (prev !== c.research_oriented_learner.status) saveCredentialsStore(c);
    else saveCredentialsStore(c);
    return c;
  }

  function median(arr) {
    const a = arr.slice().sort((x, y) => x - y);
    if (!a.length) return 0;
    const mid = Math.floor(a.length / 2);
    if (a.length % 2) return a[mid];
    return Math.round((a[mid - 1] + a[mid]) / 2);
  }

  function ensurePracticeSubjectBucket(c, subjectId) {
    const sid = String(subjectId || "");
    if (!sid) return null;
    if (!c.practice_mastery_subject.by_subject[sid]) {
      c.practice_mastery_subject.by_subject[sid] = {
        status: "inactive",
        achieved_at: null,
        last_evaluated_at: null,
        evidence: { computed_at: null, attempts_count: 0, best_percent: 0, median_percent: 0, last_events: [] },
        percents: []
      };
    }
    return c.practice_mastery_subject.by_subject[sid];
  }

  function evaluatePracticeMasteryRealtime(subjectId, percent, eventId) {
    const c = credentialsStore();
    const bucket = ensurePracticeSubjectBucket(c, subjectId);
    if (!bucket) return;

    const p = Math.max(0, Math.min(100, Number(percent) || 0));
    bucket.percents = Array.isArray(bucket.percents) ? bucket.percents : [];
    bucket.percents.push(p);

    // keep last 30 attempts for stats stability
    if (bucket.percents.length > 30) bucket.percents = bucket.percents.slice(-30);

    const attempts_count = bucket.percents.length;
    const best_percent = Math.max(...bucket.percents);
    const median_percent = median(bucket.percents);

    const active = (attempts_count >= 8 && best_percent >= 80 && median_percent >= 70);

    bucket.status = active ? "active" : bucket.status; // no loss (фиксируется на момент достижения)
    if (active && !bucket.achieved_at) bucket.achieved_at = Date.now();

    bucket.last_evaluated_at = Date.now();
    bucket.evidence = {
      computed_at: Date.now(),
      attempts_count,
      best_percent,
      median_percent,
      last_events: pushLastEvents(bucket.evidence?.last_events, eventId, 5)
    };

    saveCredentialsStore(c);
  }

  function evaluateActiveVideoLearnerRealtime(event) {
    const c = credentialsStore();
    const lessonId = event?.payload?.lesson_id ? String(event.payload.lesson_id) : "";
    if (!lessonId) return;

    const decided = c.active_video_learner.decided_by_lesson || {};
    const prev = decided[lessonId] || null;

    if (event.type === "video_skipped") {
      decided[lessonId] = { decided: true, completed: false };
    }
    if (event.type === "video_completed") {
      decided[lessonId] = { decided: true, completed: true };
    }

    c.active_video_learner.decided_by_lesson = decided;

    const all = Object.values(decided);
    const videos_decided = all.filter(x => x && x.decided).length;
    const videos_completed = all.filter(x => x && x.decided && x.completed).length;
    const completion_rate = videos_decided ? (videos_completed / videos_decided) : 0;

    const active = (videos_decided >= 10 && completion_rate >= 0.70);

    c.active_video_learner.status = active ? "active" : "inactive";
    if (active && !c.active_video_learner.achieved_at) c.active_video_learner.achieved_at = Date.now();

    c.active_video_learner.last_evaluated_at = Date.now();
    c.active_video_learner.evidence = {
      computed_at: Date.now(),
      videos_decided,
      videos_completed,
      completion_rate: Math.round(completion_rate * 1000) / 1000,
      last_events: pushLastEvents(c.active_video_learner.evidence?.last_events, event.id, 5)
    };

    saveCredentialsStore(c);
  }

    function evaluateFocusedStreakRealtime(event) {
    // valid sessions: video_completed / practice_attempt_finished / tour_attempt_finished
    if (!["video_completed", "practice_attempt_finished", "tour_attempt_finished"].includes(event.type)) return;

    const c = credentialsStore();
    const subjectId = event?.payload?.subject_id ? String(event.payload.subject_id) : "";
    if (!subjectId) return;

    const ev = c.focused_study_streak.evidence || {};
    const current_subject_id = ev.current_subject_id ? String(ev.current_subject_id) : null;
    let counter = Number(ev.focused_sessions_in_row) || 0;

    if (current_subject_id && current_subject_id === subjectId) {
      counter += 1;
    } else {
      // subject switch kills streak + expires if was active
      if (c.focused_study_streak.status === "active") {
        c.focused_study_streak.status = "expired";
      } else if (c.focused_study_streak.status !== "expired") {
        // keep inactive/expired as-is, but we restart counter
      }
      counter = 1;
    }

    // earned
    if (counter >= 5) {
      c.focused_study_streak.status = "active";
      if (!c.focused_study_streak.achieved_at) c.focused_study_streak.achieved_at = Date.now();
    } else {
      // before earned: keep inactive; after earned: keep whatever (active/expired)
      if (!c.focused_study_streak.achieved_at && c.focused_study_streak.status !== "expired") {
        c.focused_study_streak.status = "inactive";
      }
    }

    c.focused_study_streak.last_evaluated_at = Date.now();
    c.focused_study_streak.evidence = {
      computed_at: Date.now(),
      current_subject_id: subjectId,
      focused_sessions_in_row: counter,
      last_events: pushLastEvents(ev.last_events, event.id, 5)
    };

    saveCredentialsStore(c);
  }

  function evaluateFairPlayRealtime(event) {
    const c = credentialsStore();

    if (event.type === "anti_cheat_event") {
      const severity = String(event?.payload?.severity || "").toLowerCase();
      if (severity === "critical") {
        c.fair_play_participant.status = "revoked";
        c.fair_play_participant.has_critical_violation = true;
        c.fair_play_participant.last_evaluated_at = Date.now();
        c.fair_play_participant.evidence = {
          computed_at: Date.now(),
          tours_participated: Number(c.fair_play_participant.tours_participated) || 0,
          has_critical_violation: true,
          last_events: pushLastEvents(c.fair_play_participant.evidence?.last_events, event.id, 5)
        };
        saveCredentialsStore(c);
      }
      return;
    }

    if (event.type === "tour_attempt_finished") {
      const isArchive = !!event?.payload?.is_archive;
      if (!isArchive) {
        c.fair_play_participant.tours_participated = (Number(c.fair_play_participant.tours_participated) || 0) + 1;
      }

      const tours_participated = Number(c.fair_play_participant.tours_participated) || 0;
      const has_critical_violation = !!c.fair_play_participant.has_critical_violation;

      if (has_critical_violation) {
        c.fair_play_participant.status = "revoked";
      } else if (tours_participated >= 1) {
        c.fair_play_participant.status = "active";
        if (!c.fair_play_participant.achieved_at) c.fair_play_participant.achieved_at = Date.now();
      } else {
        c.fair_play_participant.status = "inactive";
      }

      c.fair_play_participant.last_evaluated_at = Date.now();
      c.fair_play_participant.evidence = {
        computed_at: Date.now(),
        tours_participated,
        has_critical_violation,
        last_events: pushLastEvents(c.fair_play_participant.evidence?.last_events, event.id, 5)
      };

      saveCredentialsStore(c);
    }
  }

        function evaluateErrorDrivenDailyOrOnReview() {
    const c = credentialsStore();

    const cyclesCount = Number(c.error_driven_learner.cycles_count) || 0;

    const baseline = Math.max(0, Number(c.error_driven_learner?.evidence?.baseline_errors) || 0);
    const current = Math.max(0, Number(c.error_driven_learner?.evidence?.current_errors) || 0);

    let lastReduction = Math.max(0, Number(c.error_driven_learner?.evidence?.error_reduction) || 0);
    if (baseline > 0) {
      lastReduction = Math.max(0, (baseline - current) / baseline);
    }

    c.error_driven_learner.status = (cyclesCount >= 3 && lastReduction >= 0.30)
      ? "active"
      : "inactive";

    if (c.error_driven_learner.status === "active" && !c.error_driven_learner.achieved_at) {
      c.error_driven_learner.achieved_at = Date.now();
    }

    c.error_driven_learner.last_evaluated_at = Date.now();
    c.error_driven_learner.evidence = {
      ...(c.error_driven_learner.evidence || {}),
      computed_at: Date.now(),
      cycles_count: cyclesCount,
      baseline_errors: baseline,
      current_errors: current,
      error_reduction: Math.round(lastReduction * 1000) / 1000,
      last_events: (c.error_driven_learner.evidence?.last_events || []).slice(0, 5)
    };

    saveCredentialsStore(c);
    return c;
  }

  function onPracticeReviewOpened(attemptKey, eventId) {
    const c = credentialsStore();
    const key = String(attemptKey || "");
    if (!key) return;
    c.error_driven_learner.reviewed_attempts = c.error_driven_learner.reviewed_attempts || {};
    c.error_driven_learner.reviewed_attempts[key] = { ts: Date.now() };
    c.error_driven_learner.evidence = {
      ...(c.error_driven_learner.evidence || {}),
      last_events: pushLastEvents(c.error_driven_learner.evidence?.last_events, eventId, 5)
    };
    saveCredentialsStore(c);
    evaluateErrorDrivenDailyOrOnReview();
  }

  function onPracticeAttemptFinishedForErrorDriven(subjectId, topicsErrorsMap, attemptKey, eventId) {
  // topicsErrorsMap: { [topic]: errorsCount }
  const c = credentialsStore();
  const sid = String(subjectId || "");
  if (!sid) return;

  c.error_driven_learner.last_attempt_a = c.error_driven_learner.last_attempt_a || {};
  c.error_driven_learner.reviewed_attempts = c.error_driven_learner.reviewed_attempts || {};
  c.error_driven_learner.cycles_count = Number(c.error_driven_learner.cycles_count) || 0;

  Object.keys(topicsErrorsMap || {}).forEach(topic => {
    const safeTopic = String(topic || "General");
    const key = `${sid}::${safeTopic}`;
    const errors = Math.max(0, Number(topicsErrorsMap[topic]) || 0);

    const prevA = c.error_driven_learner.last_attempt_a[key];
    const reviewed = prevA?.attempt_key
      ? c.error_driven_learner.reviewed_attempts[String(prevA.attempt_key || "")]
      : null;

    // 1) If we already have A + review, current attempt becomes candidate B
    if (prevA && prevA.attempt_key && reviewed) {
      const aErr = Math.max(0, Number(prevA.errors_count) || 0);
      const bErr = errors;

      if (aErr > 0) {
        const reduction = (aErr - bErr) / aErr;

        if (bErr < aErr && reduction >= 0.30) {
          c.error_driven_learner.cycles_count += 1;

          c.error_driven_learner.evidence = {
            ...(c.error_driven_learner.evidence || {}),
            computed_at: Date.now(),
            cycles_count: c.error_driven_learner.cycles_count,
            baseline_errors: aErr,
            current_errors: bErr,
            error_reduction: Math.round(reduction * 1000) / 1000,
            subject_id: sid,
            topic: safeTopic,
            last_events: pushLastEvents(c.error_driven_learner.evidence?.last_events, eventId, 5)
          };

          // consume A so same baseline cannot be farmed repeatedly
          delete c.error_driven_learner.last_attempt_a[key];
          return;
        }
      }

      // no sufficient improvement -> if current attempt still has errors, replace baseline with fresher A
      if (errors > 0) {
        c.error_driven_learner.last_attempt_a[key] = {
          attempt_key: String(attemptKey || ""),
          errors_count: errors,
          ts: Date.now(),
          subject_id: sid,
          topic: safeTopic
        };
      } else {
        // perfect attempt but without valid cycle -> clear stale baseline
        delete c.error_driven_learner.last_attempt_a[key];
      }

      return;
    }

    // 2) No valid reviewed A yet -> if current attempt has errors, save as new baseline A
    if (errors > 0) {
      c.error_driven_learner.last_attempt_a[key] = {
        attempt_key: String(attemptKey || ""),
        errors_count: errors,
        ts: Date.now(),
        subject_id: sid,
        topic: safeTopic
      };
    }
  });

  saveCredentialsStore(c);
  evaluateErrorDrivenDailyOrOnReview();
}

function evaluateRealtimeCredentials(event) {
  // Consistent learner is daily; but we still want its evidence “last events”
  // We'll update evidence list opportunistically
  const c = credentialsStore();
  c.consistent_learner.evidence = c.consistent_learner.evidence || { last_events: [] };
  c.consistent_learner.evidence.last_events = pushLastEvents(c.consistent_learner.evidence.last_events, event.id, 5);
  saveCredentialsStore(c);

  // Focused streak: realtime
  evaluateFocusedStreakRealtime(event);

  // Active Video Learner: realtime on decided events
  if (event.type === "video_skipped" || event.type === "video_completed") {
    evaluateActiveVideoLearnerRealtime(event);
  }

  // Fair Play: realtime
  if (event.type === "tour_attempt_finished" || event.type === "anti_cheat_event") {
    evaluateFairPlayRealtime(event);
  }

  // ✅ после любых realtime-пересчётов — пушим снапшот в БД (с дебаунсом)
  scheduleCredentialsDbSync(1200);
}

function runDailyCredentialJobs() {
  const today = dayKeyTashkent(Date.now());

  // ✅ Уже делали daily пересчёты сегодня — выходим
  // Читаем store только для проверки, НЕ сохраняем эту копию потом
  {
    const check = credentialsStore();
    if (check.last_daily_eval_day === today) return;
  }

  evaluateConsistentLearnerDaily();
  evaluateResearchOrientedDaily();
  evaluateErrorDrivenDailyOrOnReview();

  // ✅ фиксируем, что daily пересчёт на сегодня выполнен
  // Читаем СВЕЖУЮ копию store после всех evaluate-функций,
  // чтобы не затереть их изменения (stale overwrite fix)
  const fresh = credentialsStore();
  fresh.last_daily_eval_day = today;
  saveCredentialsStore(fresh);

  // ✅ daily пересчёты тоже фиксируем в БД
  scheduleCredentialsDbSync(1200);
}
  // =========================================================
  // End Earned Credentials Engine
  // =========================================================

  // ---------------------------
  // Telegram WebApp integration (safe)
  // ---------------------------
    const tg = (window.Telegram && window.Telegram.WebApp) ? window.Telegram.WebApp : null;
  if (tg) {
    try {
      tg.ready();
      tg.expand();
    } catch (e) {
      logClientError("tg_ready_expand", e);
    }
  }

  function getTelegramLang() {
    const code = tg?.initDataUnsafe?.user?.language_code;
    return window.i18n?.normalizeLang ? window.i18n.normalizeLang(code) : "ru";
  }

  // ✅ #21: Safe external links (block javascript:, data:, file:, etc.)
  function normalizeExternalUrl(raw) {
    const s = String(raw || "").trim();
    if (!s) return null;

    // allow t.me links (with or without scheme)
    if (/^t\.me\//i.test(s)) return `https://${s}`;
    if (/^https?:\/\/t\.me\//i.test(s)) return s;

    // allow only http/https
    try {
      const u = new URL(s);
      if (u.protocol === "http:" || u.protocol === "https:") return u.toString();
      return null;
    } catch {
      return null;
    }
  }

  function openExternal(url) {
    const safeUrl = normalizeExternalUrl(url);

    if (!safeUrl) {
      try { showToast(t("invalid_link") || "Неверная ссылка."); } catch {}
      logClientError("openExternal_blocked", { url });
      return;
    }

    // Prefer Telegram openTelegramLink/openLink if available
    try {
      if (tg?.openTelegramLink && /^https?:\/\/t\.me\//i.test(safeUrl)) {
        tg.openTelegramLink(safeUrl.replace(/^https?:\/\//i, ""));
        return;
      }
      if (tg?.openLink) {
        tg.openLink(safeUrl);
        return;
      }
    } catch (e) {
      logClientError("openExternal_tg_error", e);
    }

    window.open(safeUrl, "_blank", "noopener,noreferrer");
  }

            function openTelegramUrl(url) {
  try {
    const tg = window.Telegram && window.Telegram.WebApp;
    if (tg && typeof tg.openTelegramLink === "function") {
      tg.openTelegramLink(url);
      return;
    }
  } catch {}
  try { window.open(url, "_blank", "noopener"); } catch {}
}

function extractYouTubeVideoId(rawUrl) {
  const url = String(rawUrl || "").trim();
  if (!url) return "";

  let videoId = "";

  if (url.includes("youtu.be/")) {
    videoId = url.split("youtu.be/")[1]?.split("?")[0] || "";
  } else if (url.includes("youtube.com/watch")) {
    try { videoId = new URL(url).searchParams.get("v") || ""; } catch {}
  } else if (url.includes("youtube.com/embed/")) {
    videoId = url.split("youtube.com/embed/")[1]?.split("?")[0] || "";
  }

  return String(videoId || "").replace(/[^a-zA-Z0-9_-]/g, "");
}

function isTelegramVideoUrl(rawUrl) {
  const url = String(rawUrl || "").trim();
  return /^https?:\/\/t\.me\//i.test(url) || /^t\.me\//i.test(url);
}

const SUBJECT_TELEGRAM_LESSON_URLS = Object.freeze({
  mathematics: "https://t.me/iclubuzvideodarslar/1583/1613",
  biology: "https://t.me/iclubuzvideodarslar/432/566",
  informatics: "https://t.me/iclubuzvideodarslar/319/344",
  chemistry: "https://t.me/iclubuzvideodarslar/356/458",
  economics: "https://t.me/iclubuzvideodarslar/78/246"
});

function getSubjectTelegramLessonUrl(subjectKey) {
  const key = String(subjectKey || "").trim().toLowerCase();
  return SUBJECT_TELEGRAM_LESSON_URLS[key] || "";
}

async function getSubjectPrimaryLessonId(subjectKey) {
  try {
    if (!window.sb) return null;

    const subjectId = await getSubjectIdByKey(subjectKey);
    if (!subjectId) return null;

    const { data, error } = await window.sb
      .from("lessons")
      .select("id")
      .eq("subject_id", subjectId)
      .order("order_no", { ascending: true })
      .limit(1)
      .maybeSingle();

    if (error) {
      logClientError("video_primary_lesson_select_error", error);
      return null;
    }

    return data?.id ? Number(data.id) : null;
  } catch (e) {
    logClientError("video_primary_lesson_exception", e);
    return null;
  }
}

function getLessonDisplayTitle(lesson) {
  const rawTitle = String(lesson?.title || "").trim();
  const orderNo = Number(lesson?.order_no || 0);

  if (orderNo > 0) {
    const template = t("video_lesson_title") || "Видеоурок {n}";
    return template.replace("{n}", String(orderNo));
  }

  return rawTitle || (t("lesson") || "Урок");
}

  // ---------------------------
  // App state
  // ---------------------------
    const defaultState = {
  tab: "home", // home | courses | ratings | profile
  prevTab: "home",
  viewStack: ["home"], // global screens stack
  courses: {
    stack: ["all-subjects"],
    subjectKey: null,
    lessonId: null,
    entryTab: "home",
    lastTourAttemptId: null,
    lastTourCertificateId: null
  },
  profile: {
    stack: ["main"] // main | settings
  },

  certificates: {
    selectedId: null,
    lastIssuedId: null
  },

  // ✅ About tabs state
  about: {
  tab: "project",         // project | rules | team
  teamScreen: "overview", // overview | board | mentors | media | member
  teamPrevScreen: "overview",
  teamMemberKey: null,
  teamEntry: null         // null | subject
},

  quizLock: null
};

  let state = loadState();

    function loadState() {
    const saved = safeJsonParse(localStorage.getItem(LS.state), null);
    if (!saved) return structuredClone(defaultState);

    // soft merge
    const merged = {
      ...structuredClone(defaultState),
      ...saved,
      courses: { ...structuredClone(defaultState.courses), ...(saved.courses || {}) },
      profile: { ...structuredClone(defaultState.profile), ...(saved.profile || {}) },
      certificates: { ...structuredClone(defaultState.certificates), ...(saved.certificates || {}) }
    };
    // Ensure viewStack sane
    if (!Array.isArray(merged.viewStack) || merged.viewStack.length === 0) merged.viewStack = ["home"];
    if (!["home", "courses", "ratings", "profile"].includes(merged.tab)) merged.tab = "home";
    if (!["home", "courses", "ratings", "profile"].includes(merged.prevTab)) merged.prevTab = merged.tab || "home";
    if (!["home", "courses", "ratings", "profile"].includes(merged.courses.entryTab)) {
      merged.courses.entryTab = merged.prevTab || "home";
    }
    return merged;
  }

        function saveState() {
  const nextState = structuredClone(state);

  if (nextState?.quiz?.mode === "practice") {
    // Practice is a learning mode. Telegram WebView can reload mid-practice;
    // if correctness data is stripped from the saved runtime state, correct MCQ
    // answers may later be saved as wrong. Keep correctness data for active Practice.
    nextState.quiz = {
      ...nextState.quiz,
      qTimerId: null,
      qEndsAtMono: null
    };
  }

  if (nextState?.tourContext && !nextState.tourContext.isArchive) {
    nextState.tourContext = stripActiveTourContextSecrets(nextState.tourContext);
  }

  localStorage.setItem(LS.state, JSON.stringify(nextState));
}

    // ---------------------------
  // Profile (local demo)
  // later replace with Supabase
  // ---------------------------
  function loadProfile() {
    return safeJsonParse(localStorage.getItem(LS.profile), null);
  }
   
  function saveProfile(profile) {
    localStorage.setItem(LS.profile, JSON.stringify(profile));
  }

      // ---------------------------
// ✅ Geo translations hydration (region/district)
// For old profiles that don't have region_tr/district_tr yet
// ---------------------------
let __geoHydrateInFlight = null;

async function ensureProfileGeoTranslationsHydrated() {
  if (__geoHydrateInFlight) return __geoHydrateInFlight;

  __geoHydrateInFlight = (async () => {
    const p = loadProfile();
    if (!p) return { ok: false, reason: "no_profile" };
    if (!window.sb) return { ok: false, reason: "no_supabase" };

    const needRegion = !!p.region_id && (!p.region_tr || !p.region_tr.ru || !p.region_tr.uz || !p.region_tr.en);
    const needDistrict = !!p.district_id && (!p.district_tr || !p.district_tr.ru || !p.district_tr.uz || !p.district_tr.en);

    if (!needRegion && !needDistrict) return { ok: true, skipped: true };

    let changed = false;

    try {
      if (needRegion) {
        const { data: rRow } = await window.sb
          .from("regions")
          .select("id,name_ru,name_uz,name_en,name")
          .eq("id", Number(p.region_id))
          .maybeSingle();

        if (rRow) {
          p.region_tr = {
            ru: String(rRow.name_ru || rRow.name || "").trim(),
            uz: String(rRow.name_uz || rRow.name_ru || rRow.name || "").trim(),
            en: String(rRow.name_en || rRow.name_ru || rRow.name || "").trim()
          };
          changed = true;
        }
      }

      if (needDistrict) {
        const { data: dRow } = await window.sb
          .from("districts")
          .select("id,name_ru,name_uz,name_en,name")
          .eq("id", Number(p.district_id))
          .maybeSingle();

        if (dRow) {
          p.district_tr = {
            ru: String(dRow.name_ru || dRow.name || "").trim(),
            uz: String(dRow.name_uz || dRow.name_ru || dRow.name || "").trim(),
            en: String(dRow.name_en || dRow.name_ru || dRow.name || "").trim()
          };
          changed = true;
        }
      }
        } catch (e) {
      return { ok: false, reason: "exception" };
    }

    if (changed) {
      saveProfile(p);
      return { ok: true, updated: true };
    }

    return { ok: true, updated: false };
  })();

  try {
    return await __geoHydrateInFlight;
  } finally {
    __geoHydrateInFlight = null;
  }
}
   function togglePinnedSubject(profile, subjectKey) {
  if (!profile) return null;
  const p = structuredClone(profile);
  p.subjects = Array.isArray(p.subjects) ? p.subjects : [];

  const idx = p.subjects.findIndex(s => s.key === subjectKey);

  if (idx === -1) {
    // если предмет не был добавлен — добавляем как study+pinned
    p.subjects.push({ key: subjectKey, mode: "study", pinned: true });
    return p;
  }

  // уже есть — переключаем pinned
  p.subjects[idx].pinned = !p.subjects[idx].pinned;

  // Если выключили pinned и предмет был чисто учебным и "ничем не нужен" —
  // в v1 оставляем его (чтобы не терять режим/историю). Удаление сделаем позже, если потребуется.
  return p;
}
function upsertUserSubjectMode(profile, subjectKey, mode) {
  if (!profile) return null;

  const p = structuredClone(profile);
  p.subjects = Array.isArray(p.subjects) ? p.subjects : [];

  const idx = p.subjects.findIndex(s => s.key === subjectKey);
  const normalizedMode = (mode === "competitive") ? "competitive" : "study";

  if (idx === -1) {
    p.subjects.push({
      key: subjectKey,
      mode: normalizedMode,
      pinned: false
    });
    return p;
  }

  p.subjects[idx].mode = normalizedMode;

  if (normalizedMode === "competitive") {
    p.subjects[idx].pinned = false;
  } else {
    p.subjects[idx].pinned = !!p.subjects[idx].pinned;
  }

  return p;
}

function removeUserSubject(profile, subjectKey) {
  if (!profile) return null;

  const p = structuredClone(profile);
  p.subjects = Array.isArray(p.subjects) ? p.subjects : [];
  p.subjects = p.subjects.filter(s => s.key !== subjectKey);
  return p;
}

async function deleteUserSubjectFromSupabase(subjectKey) {
  try {
    if (!window.sb) return { ok: false, reason: "no_sb" };

    const uid = await getAuthUid();
    if (!uid) return { ok: false, reason: "no_uid" };

    const subjectId = await getSubjectIdByKey(subjectKey);
    if (!subjectId) return { ok: false, reason: "no_subject_id" };

    const { error } = await window.sb
      .from("user_subjects")
      .delete()
      .eq("user_id", uid)
      .eq("subject_id", subjectId);

    if (error) {
      try {
        await logDbErrorToEvents(uid, "user_subjects_delete", error, {
          subject_id: subjectId,
          subject_key: subjectKey
        });
      } catch {}
      return { ok: false, reason: "delete_failed" };
    }

    return { ok: true, uid, subjectId };
  } catch (e) {
    try {
      const uid = await getAuthUid();
      await logDbErrorToEvents(uid, "user_subjects_delete_exception", e, { subject_key: subjectKey });
    } catch {}
    return { ok: false, reason: "exception" };
  }
}
  // ---------------------------
  // Demo subjects (keys match index.html selects)
  // ---------------------------
    const SUBJECTS = [
    { key: "informatics", title: "Информатика", type: "main" },
    { key: "economics", title: "Экономика", type: "main" },
    { key: "biology", title: "Биология", type: "main" },
    { key: "chemistry", title: "Химия", type: "main" },
    { key: "mathematics", title: "Математика", type: "main" },

    { key: "english_a1", title: "English (A1)", type: "additional" },
    { key: "english_a2", title: "English (A2)", type: "additional" },
    { key: "english_b1", title: "English (B1)", type: "additional" },
    { key: "sat", title: "SAT", type: "additional" },
    { key: "ielts", title: "IELTS", type: "additional" }
  ];

  function getDefaultActiveSubjectKeys() {
    return SUBJECTS.map(s => String(s.key || "").trim()).filter(Boolean);
  }

  function getActiveSubjectKeys() {
    const raw = Array.isArray(state?.catalog?.activeSubjectKeys)
      ? state.catalog.activeSubjectKeys
      : [];
    const list = raw.length ? raw : getDefaultActiveSubjectKeys();
    return Array.from(new Set(list.map(x => String(x || "").trim()).filter(Boolean)));
  }

  function setActiveSubjectKeys(keys) {
    state.catalog = state.catalog || {};
    state.catalog.activeSubjectKeys = Array.from(
      new Set((Array.isArray(keys) ? keys : []).map(x => String(x || "").trim()).filter(Boolean))
    );
    saveState();
  }

  function isSubjectActive(subjectKey) {
    const key = String(subjectKey || "").trim();
    if (!key) return false;
    return getActiveSubjectKeys().includes(key);
  }

  function getVisibleSubjectsCatalog() {
    return SUBJECTS.filter(s => isSubjectActive(s.key));
  }

  function filterActiveUserSubjects(list) {
    return (Array.isArray(list) ? list : []).filter(s => isSubjectActive(s?.key));
  }

  async function refreshActiveSubjectsCatalogFromSupabase() {
    try {
      if (!window.sb) return { ok: false, reason: "no_sb" };

      const { data, error } = await window.sb
        .from("subjects")
        .select("subject_key,is_active");

      if (error) {
        logClientError("subjects_active_catalog_error", error);
        return { ok: false, reason: "select_failed" };
      }

      const activeKeys = (Array.isArray(data) ? data : [])
        .filter(row => row?.is_active === true)
        .map(row => String(row?.subject_key || "").trim())
        .filter(Boolean);

      if (activeKeys.length) {
        setActiveSubjectKeys(activeKeys);
      }

      return { ok: true, keys: activeKeys };
    } catch (e) {
      logClientError("subjects_active_catalog_exception", e);
      return { ok: false, reason: "exception" };
    }
  }

    function subjectByKey(key) {
    return SUBJECTS.find(s => s.key === key) || null;
  }

  // i18n subject title resolver (key -> subj_<key>)
  function subjectTitle(subjectKey, fallbackTitle = "") {
    const k = String(subjectKey || "").toLowerCase();
    if (!k) return fallbackTitle || "";
    const i18nKey = `subj_${k}`;
    const v = t(i18nKey);
    // if translation missing, t() returns the key itself
    if (v && v !== i18nKey) return v;
    return fallbackTitle || k;
  }

     // ---------------------------
  // Availability rules (v1: local profile-based)
  // ---------------------------
  function isSchoolUser(profile) {
    return !!profile?.is_school_student;
  }

  function getUserSubject(profile, subjectKey) {
    return profile?.subjects?.find(s => s.key === subjectKey) || null;
  }

  function isMainSubjectKey(subjectKey) {
    return subjectByKey(subjectKey)?.type === "main";
  }

  function isAdditionalSubjectKey(subjectKey) {
    return subjectByKey(subjectKey)?.type === "additional";
  }

  function isCompetitiveForUser(profile, subjectKey) {
    return getUserSubject(profile, subjectKey)?.mode === "competitive";
  }

  // Tours eligibility (ACTIVE tours): school + main + competitive
  function canOpenActiveTours(profile, subjectKey) {
    if (!profile) return { ok: false, reason: "no_profile" };
    if (!isSchoolUser(profile)) return { ok: false, reason: "not_school" };
    if (!isMainSubjectKey(subjectKey)) return { ok: false, reason: "not_main" };
    if (!isCompetitiveForUser(profile, subjectKey)) return { ok: false, reason: "not_competitive" };
    return { ok: true, reason: "ok" };
  }

  function getToursDeniedText(reason) {
  if (reason === "not_main") return t("disabled_not_main") || "Туры доступны только для основных предметов.";
  if (reason === "not_school") return t("disabled_not_school") || "";
  if (reason === "not_competitive") return t("disabled_not_competitive") || "";
  return t("not_available") || "";
}

function toastToursDenied(reason) {
  const msg = getToursDeniedText(reason);
  showToast(msg || (t("tours_denied_title") || "Туры недоступны"));
}

async function getProfileCompetitiveSlotHint(subjectKey) {
  try {
    if (!window.sb || !subjectKey) {
      return t("profile_slot_hint_unpublished");
    }

    let subjectId = null;

    try {
      subjectId = await getSubjectIdByKey(subjectKey);
    } catch {}

    if (!subjectId) {
      const { data: srow, error: serr } = await window.sb
        .from("subjects")
        .select("id")
        .eq("subject_key", String(subjectKey))
        .maybeSingle();

      if (!serr && srow?.id) subjectId = Number(srow.id);
    }

    if (!subjectId) {
      return t("profile_slot_hint_unpublished");
    }

    const { data, error } = await window.sb
      .from("tours")
      .select("tour_no,start_date,end_date,is_active")
      .eq("subject_id", subjectId)
      .eq("is_active", true)
      .order("tour_no", { ascending: true });

    if (error || !Array.isArray(data) || !data.length) {
      return t("profile_slot_hint_unpublished");
    }

    const pad2 = (n) => String(n).padStart(2, "0");
    const now = new Date();
    const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const todayISO = `${today.getFullYear()}-${pad2(today.getMonth() + 1)}-${pad2(today.getDate())}`;

    const isInWindow = (row) => {
      const sd = row?.start_date ? String(row.start_date) : null;
      const ed = row?.end_date ? String(row.end_date) : null;
      const afterStart = !sd || sd <= todayISO;
      const beforeEnd = !ed || ed >= todayISO;
      return afterStart && beforeEnd;
    };

    const activeTour = data.find(isInWindow);
    if (activeTour) {
      return t("profile_slot_hint_active_now");
    }

    const futureTours = data
      .filter(row => row?.start_date && String(row.start_date) > todayISO)
      .sort((a, b) => String(a.start_date).localeCompare(String(b.start_date)));

    const nextTour = futureTours[0];
    if (!nextTour?.start_date) {
      return t("profile_slot_hint_unpublished");
    }

    const startAt = parseLocalDateStart(String(nextTour.start_date));
    const diffMs = startAt - today.getTime();
    const diffDays = Math.round(diffMs / (24 * 60 * 60 * 1000));

    if (diffDays <= 0) return t("profile_slot_hint_today");
    if (diffDays === 1) return t("profile_slot_hint_tomorrow");
    return t("profile_slot_hint_in_days", { n: diffDays });
  } catch (e) {
    logClientError("profile_slot_hint_error", e);
    return t("profile_slot_hint_unpublished");
  }
}

     // ---------------------------
  // Tour schedule (v1: local stub, later from Supabase)
  // ---------------------------
  // Формат: YYYY-MM-DD (локальное время пользователя)
  const TOUR_SCHEDULE = [
    // Пример (позже заменим на реальные даты из базы/админки):
    // { subjectKey: "economics", tourNo: 1, start: "2026-02-01", end: "2026-02-07" },
  ];

  function parseLocalDateStart(yyyy_mm_dd) {
    const [y, m, d] = String(yyyy_mm_dd).split("-").map(Number);
    return new Date(y, (m - 1), d, 0, 0, 0, 0).getTime();
  }

  function parseLocalDateEnd(yyyy_mm_dd) {
    const [y, m, d] = String(yyyy_mm_dd).split("-").map(Number);
    return new Date(y, (m - 1), d, 23, 59, 59, 999).getTime();
  }

  function getActiveTourEntry(subjectKey) {
    const now = Date.now();
    const list = TOUR_SCHEDULE.filter(x => x.subjectKey === subjectKey);
    for (const e of list) {
      const s = parseLocalDateStart(e.start);
      const t = parseLocalDateEnd(e.end);
      if (now >= s && now <= t) return e;
    }
    return null;
  }

  function hasAnyActiveTourNow() {
    const now = Date.now();
    for (const e of TOUR_SCHEDULE) {
      const s = parseLocalDateStart(e.start);
      const t = parseLocalDateEnd(e.end);
      if (now >= s && now <= t) return true;
    }
    return false;
  }

  function canOpenArchiveNow() {
    // По правилам: архив открывается только когда активный тур завершён (то есть активных сейчас нет)
    return !hasAnyActiveTourNow();
  }

         // DB check (real source of truth). If DB not available — fallback to local schedule.
async function dbHasAnyActiveTourNow() {
  if (!window.sb) return null; // unknown

  const pad2 = (n) => String(n).padStart(2, "0");
  const d0 = new Date();
  const todayISO = `${d0.getFullYear()}-${pad2(d0.getMonth() + 1)}-${pad2(d0.getDate())}`;

  const isInWindow = (row) => {
    const sd = row?.start_date ? String(row.start_date) : null;
    const ed = row?.end_date ? String(row.end_date) : null;
    const afterStart = !sd || sd <= todayISO;
    const beforeEnd = !ed || ed >= todayISO;
    return afterStart && beforeEnd;
  };

    try {
    const { data, error } = await window.sb
      .from("tours")
      .select("id,start_date,end_date,is_active")
      .eq("is_active", true);

    if (error) return null;
    const list = Array.isArray(data) ? data : [];
    return list.some(r => !!r.is_active && isInWindow(r));
  } catch (e) {
    logClientError("dbHasAnyActiveTourNow", e);
    return null;
  }
}

            async function renderArchiveView() {
  const listEl = document.getElementById("archive-list");
  if (!listEl) return;

  listEl.innerHTML = `
    <div class="empty muted">${t("archive_loading")}</div>
  `;

  showAsyncOverlay(tr3(
    "Загружаем архив…",
    "Arxiv yuklanmoqda…",
    "Loading archive…"
  ));

  let isLocked = false;
  let availabilityUnknown = false;

  try {
    if (window.sb) {
      const hasActive = await dbHasAnyActiveTourNow();
      if (hasActive === null) {
        availabilityUnknown = true;
      } else {
        isLocked = !!hasActive;
      }
    } else {
      isLocked = !canOpenArchiveNow();
    }
  } catch {
    availabilityUnknown = true;
  }

  if (availabilityUnknown) {
    listEl.innerHTML = `
      <div class="empty muted">
        <div style="font-weight:800; margin-bottom:6px;">${t("archive_unavailable_title")}</div>
        <div class="small">${t("archive_unavailable_sub")}</div>
      </div>
    `;
    hideAsyncOverlay();
    return;
  }

  if (isLocked) {
    listEl.innerHTML = `
      <div class="empty muted">
        <div style="font-weight:800; margin-bottom:6px;">${t("archive_locked_title")}</div>
        <div class="small">${t("archive_locked_sub")}</div>
      </div>
    `;
    hideAsyncOverlay();
    return;
  }

  if (!window.sb) {
    listEl.innerHTML = `
      <div class="empty muted">${t("archive_empty")}</div>
    `;
    hideAsyncOverlay();
    return;
  }

  const subjectKey = state?.courses?.subjectKey;
  const uid = await getAuthUid();

  if (!uid || !subjectKey) {
    listEl.innerHTML = `
      <div class="empty muted">${t("archive_empty")}</div>
    `;
    hideAsyncOverlay();
    return;
  }

  const subjectId = await getSubjectIdByKey(subjectKey);
  if (!subjectId) {
    listEl.innerHTML = `
      <div class="empty muted">${t("archive_empty")}</div>
    `;
    hideAsyncOverlay();
    return;
  }

  const { data: tours, error: toursErr } = await window.sb
    .from("tours")
    .select("id,tour_no,start_date,end_date,is_active")
    .eq("subject_id", subjectId)
    .order("tour_no", { ascending: true });

  if (toursErr || !Array.isArray(tours) || tours.length === 0) {
    listEl.innerHTML = `
      <div class="empty muted">${t("archive_empty")}</div>
    `;
    hideAsyncOverlay();
    return;
  }

  const pad2 = (n) => String(n).padStart(2, "0");
  const d0 = new Date();
  const todayISO = `${d0.getFullYear()}-${pad2(d0.getMonth() + 1)}-${pad2(d0.getDate())}`;

  const isInWindow = (row) => {
    const sd = row?.start_date ? String(row.start_date) : null;
    const ed = row?.end_date ? String(row.end_date) : null;
    const afterStart = !sd || sd <= todayISO;
    const beforeEnd = !ed || ed >= todayISO;
    return afterStart && beforeEnd;
  };

  const pastTours = tours.filter(t => !t?.is_active || !isInWindow(t));
  const pastTourIds = pastTours.map(t => Number(t.id)).filter(Boolean);

  if (pastTourIds.length === 0) {
    listEl.innerHTML = `
      <div class="empty muted">${t("archive_empty")}</div>
    `;
    hideAsyncOverlay();
    return;
  }

    const { data: atts, error: attsErr } = await window.sb
    .from("tour_attempts")
    .select("tour_id,score,total_time,status")
    .eq("user_id", uid)
    .in("tour_id", pastTourIds)
    .in("status", ["submitted", "time_expired", "anti_cheat", "finished"]);

  if (attsErr || !Array.isArray(atts) || atts.length === 0) {
    listEl.innerHTML = `
      <div class="empty muted">${t("archive_empty")}</div>
    `;
    hideAsyncOverlay();
    return;
  }

  const bestByTour = new Map();
  for (const a of atts) {
    const tid = Number(a.tour_id);
    const score = Number(a.score) || 0;
    const time = Number(a.total_time) || 0;

    const cur = bestByTour.get(tid);
    if (!cur) {
      bestByTour.set(tid, { score, time });
      continue;
    }
    if (score > cur.score || (score === cur.score && time > 0 && time < cur.time)) {
      bestByTour.set(tid, { score, time });
    }
  }

    const rows = pastTours
    .filter(tour => bestByTour.has(Number(tour.id)))
    .map(tour => {
      const best = bestByTour.get(Number(tour.id));
      const title = `${tr("tours_tour_label", "Тур")} ${tour.tour_no}`;

      const parts = [];
      parts.push(`${t("archive_score_label")}: ${best.score}`);
      if (best.time) parts.push(`${t("archive_time_label")}: ${formatSecondsToMMSS(best.time)}`);

      return `
        <div class="list-item" style="cursor:default;">
          <div style="font-weight:800; margin-bottom:4px;">${title}</div>
          <div class="muted small">${parts.join(" • ")}</div>
        </div>
      `;
    });
               
  if (rows.length === 0) {
    listEl.innerHTML = `
      <div class="empty muted">${t("archive_empty")}</div>
    `;
    hideAsyncOverlay();
    return;
  }

  listEl.innerHTML = rows.join("");
  hideAsyncOverlay();
}

function setNotificationsBadge(count) {
  const badgeEl = document.getElementById("topbar-notifications-badge");
  const notifBtn = document.getElementById("topbar-notifications");
  if (!badgeEl || !notifBtn) return;

  const n = Math.max(0, Number(count || 0));

  if (n <= 0) {
    badgeEl.hidden = true;
    badgeEl.textContent = "0";
    return;
  }

  badgeEl.hidden = false;
  badgeEl.textContent = n > 99 ? "99+" : String(n);
}

async function refreshNotificationsBadge() {
  try {
    if (!window.sb) {
      setNotificationsBadge(0);
      return;
    }

    const uid = await getAuthUid().catch(() => null);
    if (!uid) {
      setNotificationsBadge(0);
      return;
    }

    const { count, error } = await window.sb
      .from("user_notifications")
      .select("id", { count: "exact", head: true })
      .eq("user_id", uid)
      .is("read_at", null)
      .is("deleted_at", null);

    if (error) throw error;

    setNotificationsBadge(Number(count || 0));
  } catch (e) {
    logClientError("refreshNotificationsBadge", e);
    setNotificationsBadge(0);
  }
}

async function markNotificationsRead(rows) {
  try {
    if (!window.sb) return;

    const uid = await getAuthUid().catch(() => null);
    if (!uid) return;

    const unreadIds = (Array.isArray(rows) ? rows : [])
      .filter(r => !r?.read_at)
      .map(r => Number(r?.id))
      .filter(Boolean);

    if (!unreadIds.length) {
      await refreshNotificationsBadge();
      return;
    }

    const { error } = await window.sb
      .from("user_notifications")
      .update({ read_at: new Date().toISOString() })
      .eq("user_id", uid)
      .in("id", unreadIds);

    if (error) throw error;

    await refreshNotificationsBadge();
  } catch (e) {
    logClientError("markNotificationsRead", e);
  }
}

function setNotificationsClearAllVisible(isVisible) {
  const btn = document.getElementById("notifications-clear-all");
  if (!btn) return;
  btn.hidden = !isVisible;
  btn.disabled = !isVisible;
}

function confirmNotificationsClearAll(count) {
  const root = document.getElementById("modal-root");
  const title = t("notifications_delete_all_title") || "Очистить уведомления?";
  const message =
    t("notifications_delete_all_message", { n: String(count || 0) }) ||
    "Все сообщения в колокольчике будут скрыты для вас.";
  const okText = t("notifications_delete_all") || "Очистить все";
  const cancelText = t("notifications_delete_cancel") || t("cancel") || "Отмена";

  if (!root) {
    try {
      return Promise.resolve(window.confirm(`${title}\n\n${message}`));
    } catch {
      return Promise.resolve(false);
    }
  }

  return new Promise((resolve) => {
    const close = (answer) => {
      try {
        root.setAttribute("aria-hidden", "true");
        root.innerHTML = "";
        document.body.classList.remove("modal-open");
      } catch {}
      resolve(!!answer);
    };

    root.innerHTML = `
      <div class="modal-backdrop" data-action="notifications-modal-cancel">
        <div class="modal" role="dialog" aria-modal="true">
          <div class="modal-title">${escapeHTML(title)}</div>
          <div class="modal-text">${escapeHTML(message)}</div>
          <div class="modal-actions">
            <button class="btn" type="button" data-action="notifications-modal-cancel">
              ${escapeHTML(cancelText)}
            </button>
            <button class="btn danger" type="button" data-action="notifications-modal-ok">
              ${escapeHTML(okText)}
            </button>
          </div>
        </div>
      </div>
    `;

    root.setAttribute("aria-hidden", "false");
    document.body.classList.add("modal-open");

    const okBtn = root.querySelector('[data-action="notifications-modal-ok"]');
    const cancelEls = root.querySelectorAll('[data-action="notifications-modal-cancel"]');
    const modal = root.querySelector(".modal");

    if (modal) {
      modal.addEventListener("click", (e) => e.stopPropagation());
    }

    if (okBtn) {
      okBtn.addEventListener("click", () => close(true), { once: true });
    }

    cancelEls.forEach(el => {
      el.addEventListener("click", () => close(false), { once: true });
    });
  });
}

async function deleteNotificationById(rawId) {
  const id = Number(rawId || 0);
  if (!id || !window.sb) return;

  showAsyncOverlay(t("notifications_deleting") || "Удаляем уведомление…");

  try {
    const uid = await getAuthUid().catch(() => null);
    if (!uid) throw new Error("missing_uid");

    const { error } = await window.sb
      .from("user_notifications")
      .update({ deleted_at: new Date().toISOString() })
      .eq("user_id", uid)
      .eq("id", id);

    if (error) throw error;

    try {
      trackEvent("notification_deleted", {
        user_notification_id: id
      });
    } catch {}

    showToast(t("notifications_deleted_toast") || "Уведомление удалено.");
    await renderNotificationsView();
  } catch (e) {
    logClientError("deleteNotificationById", e);
    showToast(t("notifications_delete_failed") || "Не удалось удалить уведомление.");
  } finally {
    hideAsyncOverlay();
  }
}

async function deleteAllVisibleNotifications() {
  try {
    const rows = Array.isArray(state?.notificationsRows)
      ? state.notificationsRows
      : [];

    const ids = rows
      .map(r => Number(r?.id || 0))
      .filter(Boolean);

    if (!ids.length || !window.sb) return;

    const confirmed = await confirmNotificationsClearAll(ids.length);
    if (!confirmed) return;

    showAsyncOverlay(t("notifications_deleting") || "Удаляем уведомления…");

    const uid = await getAuthUid().catch(() => null);
    if (!uid) throw new Error("missing_uid");

    const { error } = await window.sb
      .from("user_notifications")
      .update({ deleted_at: new Date().toISOString() })
      .eq("user_id", uid)
      .in("id", ids);

    if (error) throw error;

    try {
      trackEvent("notifications_deleted_all", {
        count: ids.length
      });
    } catch {}

    showToast(t("notifications_deleted_all_toast") || "Уведомления очищены.");
    await renderNotificationsView();
  } catch (e) {
    logClientError("deleteAllVisibleNotifications", e);
    showToast(t("notifications_delete_failed") || "Не удалось удалить уведомления.");
  } finally {
    hideAsyncOverlay();
  }
}
   
function applyNotificationTemplate(text, meta = {}) {
  let out = String(text || "");
  const subjectKey = String(meta?.subject_key || "").trim();
  const subjectFallback = String(meta?.subject_title || "").trim();
  const subjectText = subjectKey
    ? subjectTitle(subjectKey, subjectFallback)
    : subjectFallback;

  const tourNo = meta?.tour_no != null ? String(meta.tour_no) : "";

  out = out.replaceAll("{subject_title}", subjectText);
  out = out.replaceAll("{tour_no}", tourNo);

  return out.trim();
}

function pickNotificationText(notification, lang = currentLang()) {
  const n = notification || {};
  const safeLang = String(lang || "ru").toLowerCase();

  const rawTitle =
    (safeLang === "uz" ? n.title_uz : safeLang === "en" ? n.title_en : n.title_ru) ||
    n.title_ru ||
    n.title_uz ||
    n.title_en ||
    "";

  const rawBody =
    (safeLang === "uz" ? n.body_uz : safeLang === "en" ? n.body_en : n.body_ru) ||
    n.body_ru ||
    n.body_uz ||
    n.body_en ||
    "";

  return {
    title: applyNotificationTemplate(rawTitle, n.meta || {}),
    body: applyNotificationTemplate(rawBody, n.meta || {})
  };
}

async function renderNotificationsView() {
  const listEl = document.getElementById("notifications-list");
  if (!listEl) return;

  state.notificationsRows = [];
  setNotificationsClearAllVisible(false);

  listEl.innerHTML = `
    <div class="empty muted">${escapeHTML(t("notifications_loading"))}</div>
  `;

  showAsyncOverlay(tr3(
    "Загружаем уведомления…",
    "Bildirishnomalar yuklanmoqda…",
    "Loading notifications…"
  ));

  if (!window.sb) {
    listEl.innerHTML = `
      <div class="empty muted">${escapeHTML(t("notifications_no_db"))}</div>
    `;
    await refreshNotificationsBadge();
    hideAsyncOverlay();
    return;
  }

  const uid = await getAuthUid().catch(() => null);
  if (!uid) {
    listEl.innerHTML = `
      <div class="empty muted">${escapeHTML(t("notifications_empty"))}</div>
    `;
    await refreshNotificationsBadge();
    hideAsyncOverlay();
    return;
  }

  let rows = [];

  try {
    const { data, error } = await window.sb
      .from("user_notifications")
      .select(`
        id,
        read_at,
        created_at,
        deleted_at,
        notification:notifications (
          id,
          publish_at,
          kind,
          title_ru,
          title_uz,
          title_en,
          body_ru,
          body_uz,
          body_en,
          meta
        )
      `)
      .eq("user_id", uid)
      .is("deleted_at", null)
      .order("created_at", { ascending: false })
      .limit(100);

    if (error) throw error;
    rows = Array.isArray(data) ? data.filter(r => r?.notification) : [];
  } catch (e) {
    logClientError("renderNotificationsView_load", e);
    listEl.innerHTML = `
      <div class="empty muted">
        ${escapeHTML(t("notifications_load_error"))}
        <div class="small" style="margin-top:8px">${escapeHTML(t("support_route_after_retry"))}</div>
      </div>
    `;
    await refreshNotificationsBadge();
    hideAsyncOverlay();
    return;
  }

  state.notificationsRows = rows;
  setNotificationsClearAllVisible(rows.length > 0);

  if (!rows.length) {
    listEl.innerHTML = `
      <div class="empty muted">${escapeHTML(t("notifications_empty"))}</div>
    `;
    await refreshNotificationsBadge();
    hideAsyncOverlay();
    return;
  }

  const lang = currentLang();

  listEl.innerHTML = rows.map(row => {
    const notification = row.notification || {};
    const copy = pickNotificationText(notification, lang);
    const stamp = notification.publish_at || row.created_at || null;
    const dateText = stamp ? formatDateTime(stamp) : "";
    const unreadClass = row.read_at ? "" : " is-unread";

    return `
      <article class="card notification-card${unreadClass}">
        <div class="notification-main">
          <div class="notification-head">
            <div class="notification-title">${escapeHTML(copy.title || t("notifications_title"))}</div>
            <div class="notification-date">${escapeHTML(dateText)}</div>
          </div>
          <div class="notification-body">${escapeHTML(copy.body)}</div>
        </div>

        <button
          class="notification-delete-btn"
          type="button"
          data-action="notification-delete"
          data-id="${Number(row.id)}"
          aria-label="${escapeHTML(t("notifications_delete_one") || "Удалить")}"
          title="${escapeHTML(t("notifications_delete_one") || "Удалить")}"
        >
          ×
        </button>
      </article>
    `;
  }).join("");

  await markNotificationsRead(rows);
  hideAsyncOverlay();
}

      function renderAboutView() {
  const tabsEl = document.getElementById("about-tabs");
  const contentEl = document.getElementById("about-content");
  if (!tabsEl || !contentEl) return;

  const tab = (state.about && state.about.tab) ? state.about.tab : "project";

  const tabBtn = (key, value) => {
    const active = (tab === value) ? "is-active" : "";
    return `
      <button class="hub-tab ${active}" type="button" data-action="about-tab" data-tab="${value}">
        ${escapeHTML(t(key))}
      </button>
    `;
  };

  tabsEl.innerHTML = `
    <div class="subject-hub-tabs about-tabs">
      ${tabBtn("about_tab_project", "project")}
      ${tabBtn("about_tab_rules", "rules")}
      ${tabBtn("about_tab_team", "team")}
    </div>
  `;

  if (tab === "project") {
    contentEl.innerHTML = `
      <div class="card">
        <div class="card-title">${escapeHTML(t("about_project_title"))}</div>
        <div class="muted small" style="margin-top:6px">${escapeHTML(t("about_project_desc"))}</div>
      </div>

      <div class="list-item">
        <div style="font-weight:900">${escapeHTML(t("about_why_title"))}</div>
        <ul class="muted small" style="margin:10px 0 0 18px; line-height:1.35">
          <li>${escapeHTML(t("about_why_1"))}</li>
          <li>${escapeHTML(t("about_why_2"))}</li>
          <li>${escapeHTML(t("about_why_3"))}</li>
        </ul>
      </div>

      <div class="list-item">
        <div style="font-weight:900">${escapeHTML(t("about_steps_title"))}</div>
        <ol class="muted small" style="margin:10px 0 0 18px; line-height:1.35">
          <li>${escapeHTML(t("about_step_1"))}</li>
          <li>${escapeHTML(t("about_step_2"))}</li>
          <li>${escapeHTML(t("about_step_3"))}</li>
          <li>${escapeHTML(t("about_step_4"))}</li>
        </ol>
      </div>

      <div class="list-item">
        <div style="font-weight:900">${escapeHTML(t("about_modes_title"))}</div>
        <ul class="muted small" style="margin:10px 0 0 18px; line-height:1.35">
          <li><b>${escapeHTML(t("about_mode_study_title"))}:</b> ${escapeHTML(t("about_mode_study_text"))}</li>
          <li><b>${escapeHTML(t("about_mode_comp_title"))}:</b> ${escapeHTML(t("about_mode_comp_text"))}</li>
        </ul>
      </div>
    `;
    return;
  }

  if (tab === "rules") {
    contentEl.innerHTML = `
      <div class="list-item">
        <div style="font-weight:900">${escapeHTML(t("about_rules_participation_title"))}</div>
        <ul class="muted small" style="margin:10px 0 0 18px; line-height:1.35">
          <li>${escapeHTML(t("about_rules_participation_1"))}</li>
          <li>${escapeHTML(t("about_rules_participation_2"))}</li>
        </ul>
      </div>

      <div class="list-item">
        <div style="font-weight:900">${escapeHTML(t("about_rules_format_title"))}</div>
        <ul class="muted small" style="margin:10px 0 0 18px; line-height:1.35">
          <li>${escapeHTML(t("about_rules_format_1"))}</li>
          <li>${escapeHTML(t("about_rules_format_2"))}</li>
          <li>${escapeHTML(t("about_rules_format_3"))}</li>
        </ul>
      </div>

      <div class="list-item">
        <div style="font-weight:900">${escapeHTML(t("about_rules_fair_title"))}</div>
        <ul class="muted small" style="margin:10px 0 0 18px; line-height:1.35">
          <li>${escapeHTML(t("about_rules_fair_1"))}</li>
          <li>${escapeHTML(t("about_rules_fair_2"))}</li>
        </ul>
      </div>

      <div class="list-item">
        <div style="font-weight:900">${escapeHTML(t("about_rules_scoring_title"))}</div>
        <ul class="muted small" style="margin:10px 0 0 18px; line-height:1.35">
          <li>${escapeHTML(t("about_rules_scoring_1"))}</li>
          <li>${escapeHTML(t("about_rules_scoring_2"))}</li>
        </ul>
      </div>

      <div class="list-item">
        <div style="font-weight:900">${escapeHTML(t("about_rules_recs_title"))}</div>
        <ul class="muted small" style="margin:10px 0 0 18px; line-height:1.35">
          <li>${escapeHTML(t("about_rules_recs_1"))}</li>
          <li>${escapeHTML(t("about_rules_recs_2"))}</li>
          <li>${escapeHTML(t("about_rules_recs_3"))}</li>
        </ul>
      </div>

      <div class="card">
        <div class="card-title">${escapeHTML(t("about_faq_title"))}</div>
        <div class="muted small" style="margin-top:10px; line-height:1.45">
          <b>${escapeHTML(t("about_faq_q1"))}</b><br/>
          ${escapeHTML(t("about_faq_a1"))}
          <br/><br/>
          <b>${escapeHTML(t("about_faq_q2"))}</b><br/>
          ${escapeHTML(t("about_faq_a2"))}
          <br/><br/>
          <b>${escapeHTML(t("about_faq_q3"))}</b><br/>
          ${escapeHTML(t("about_faq_a3"))}
        </div>
      </div>
    `;
    return;
  }

         // ---------------------------
// About → Team: DB-backed people (optional, safe)
// Table supported:
// 1) public.team_people
//
// Expected columns (minimum):
// group_key: "board" | "mentors" | "media"
// name, role, meta, photo_path, is_vacant, priority, is_active
// ---------------------------
async function fetchTeamPeopleFromDb(groupKey) {
  try {
    if (!window.sb) return null;

    const g = String(groupKey || "").trim().toLowerCase();
    if (!g) return null;

    const toPublicUrl = (photoPath) => {
      const p = String(photoPath || "").trim();
      if (!p) return null;
      try {
        const res = window.sb.storage.from("team-photos").getPublicUrl(p);
        return res?.data?.publicUrl || null;
      } catch {
        return null;
      }
    };

    const tryTable = async (table) => {
  const { data, error } = await window.sb
    .from(table)
    .select("group_key,name,role,meta,photo_path,is_vacant,priority,is_active")
    .eq("group_key", g)
    .eq("is_active", true)
    .order("priority", { ascending: true })
    .limit(100);

  if (error) return null;
  if (!Array.isArray(data) || data.length === 0) return [];

  const fallbackList =
    g === "board" ? (Array.isArray(board) ? board : []) :
    g === "mentors" ? (Array.isArray(mentors) ? mentors : []) :
    g === "media" ? (Array.isArray(media) ? media : []) :
    [];

  return data.map(r => {
    const fromPath = toPublicUrl(r.photo_path);

    const dbName = String(r.name || "").trim();
    const dbRole = String(r.role || "").trim();

    const local =
      fallbackList.find(x =>
        String(x?.memberKey || "") &&
        String(x?.memberKey || "") === `${g}_${dbName}_${dbRole}`
      ) ||
      fallbackList.find(x =>
        String(x?.name || "").trim() === dbName &&
        String(x?.role || "").trim() === dbRole
      ) ||
      fallbackList.find(x =>
        String(x?.role || "").trim() === dbRole
      ) ||
      null;

    if (local) {
  const hasLocalRichProfile =
    !!String(local?.memberKey || "").trim() &&
    (
      !!String(local?.name || "").trim() ||
      !!local?.name_i18n ||
      !!local?.meta_i18n ||
      !!local?.about_i18n ||
      !!local?.achievements_i18n ||
      !!local?.education_i18n
    );

  const mergedName = String(dbName || local?.name || "").trim();
  const mergedRole = String(dbRole || local?.role || "").trim();
  const mergedMeta =
    String(local?.meta || "").trim() ||
    String(r.meta || "").trim();

  return {
    ...local,
    name: mergedName,
    role: mergedRole,
    meta: mergedMeta,
    photoUrl: fromPath || local.photoUrl || null,
    vacant: hasLocalRichProfile ? !!local.vacant : ((r.is_vacant != null) ? !!r.is_vacant : !!local.vacant)
  };
}

    return {
      name: dbName,
      role: dbRole,
      meta: String(r.meta || ""),
      photoUrl: fromPath,
      vacant: !!r.is_vacant
    };
  });
};

    const a = await tryTable("team_people");
    if (a !== null) return a;

    return null;
  } catch {
    return null;
  }
}

function getTeamLocalConfigSignature() {
  try {
    const compact = (list) => (Array.isArray(list) ? list : []).map(x => ({
      memberKey: String(x?.memberKey || ""),
      name: String(x?.name || ""),
      role: String(x?.role || ""),
      role_i18n: x?.role_i18n || null,
      meta_i18n: x?.meta_i18n || null,
      about_i18n: x?.about_i18n || null,
      achievements_i18n: x?.achievements_i18n || null,
      education_i18n: x?.education_i18n || null,
      vacant: !!x?.vacant,
      photoUrl: String(x?.photoUrl || "")
    }));

    return JSON.stringify({
      board: compact(typeof board !== "undefined" ? board : []),
      mentors: compact(typeof mentors !== "undefined" ? mentors : []),
      media: compact(typeof media !== "undefined" ? media : [])
    });
  } catch {
    return "team-local-signature-fallback";
  }
}

function ensureTeamCacheInit() {
  if (!state.about) state.about = { tab: "project" };

  const localSig = getTeamLocalConfigSignature();
  const versionChanged = Number(state.about.teamPeopleCacheVersion || 0) !== TEAM_CACHE_VERSION;
  const configChanged = String(state.about.teamPeopleLocalSig || "") !== String(localSig);

  if (versionChanged || configChanged) {
    state.about.teamPeopleCache = {};
    state.about.teamPeopleCacheTs = {};
    state.about.teamPeopleResolved = {};
    state.about.teamPeopleLoading = {};
    state.about.teamPeopleCacheVersion = TEAM_CACHE_VERSION;
    state.about.teamPeopleLocalSig = localSig;
    saveState();
  }

  if (!state.about.teamPeopleCache) state.about.teamPeopleCache = {};
  if (!state.about.teamPeopleCacheTs) state.about.teamPeopleCacheTs = {};
  if (!state.about.teamPeopleLoading) state.about.teamPeopleLoading = {};
  if (!state.about.teamPeopleLocalSig) state.about.teamPeopleLocalSig = localSig;
}

function warmTeamPhotoCache(list) {
  if (!Array.isArray(list) || !list.length) return;

  list.forEach(item => {
    const url = String(item?.photoUrl || "").trim();
    if (!url) return;

    try {
      const img = new Image();
      img.decoding = "async";
      img.src = url;
    } catch {}
  });
}

// loads once per screen (or refresh after 6h)
function ensureTeamPeopleLoaded(screenKey) {
  ensureTeamCacheInit();

  const s = String(screenKey || "overview");
  const ts = Number(state.about.teamPeopleCacheTs?.[s]) || 0;
  const cached = state.about.teamPeopleCache?.[s];
  const tooOld = !ts || (Date.now() - ts > 6 * 60 * 60 * 1000);

  const hasAnyPhoto = Array.isArray(cached) && cached.some(x => !!String(x?.photoUrl || "").trim());

  // если кэш свежий и уже содержит хотя бы одно фото — не дёргаем БД
  if (!tooOld && Array.isArray(cached) && hasAnyPhoto) {
    warmTeamPhotoCache(cached);
    return;
  }

  // защита от повторных параллельных загрузок одного и того же экрана
  if (state.about.teamPeopleLoading?.[s]) return;
  state.about.teamPeopleLoading[s] = true;

  fetchTeamPeopleFromDb(s).then(list => {
    if (!Array.isArray(list) || list.length === 0) return;

    ensureTeamCacheInit();

    const prevList = Array.isArray(state.about.teamPeopleCache?.[s]) ? state.about.teamPeopleCache[s] : [];
    const prevSig = JSON.stringify(prevList.map(x => [x?.name || "", x?.role || "", x?.photoUrl || "", !!x?.vacant]));
    const nextSig = JSON.stringify(list.map(x => [x?.name || "", x?.role || "", x?.photoUrl || "", !!x?.vacant]));

    state.about.teamPeopleCache[s] = list;
    state.about.teamPeopleCacheTs[s] = Date.now();
    saveState();

    warmTeamPhotoCache(list);

    // перерисовываем только если данные реально изменились
    if (prevSig !== nextSig) {
      renderAboutView();
    }
  }).catch(() => null).finally(() => {
    if (state?.about?.teamPeopleLoading) {
      state.about.teamPeopleLoading[s] = false;
    }
  });
}
      // team — overview + sub-screens (top-app)
  if (!state.about) state.about = { tab: "project" };
  const teamScreen = state.about.teamScreen || "overview";

  const initials = (name) => {
    const s = String(name || "").trim();
    if (!s) return "—";
    const parts = s.split(/\s+/).filter(Boolean);
    const a = (parts[0] || "")[0] || "";
    const b = (parts[1] || "")[0] || "";
    return (a + b).toUpperCase() || "—";
  };

  const personCard = ({ name, role, meta, vacant, photoUrl, large, group, memberKey }) => {
  const hasPhoto = !!(photoUrl && String(photoUrl).trim());
  const cardCls = `person-card${large ? " is-large" : ""}${!vacant ? " is-clickable" : ""}`;

  const avatarHtml = hasPhoto
  ? `<img class="person-photo" src="${escapeHTML(photoUrl)}" alt="${escapeHTML(name || "")}" decoding="async" />`
  : `<div class="person-avatar ${vacant ? "is-vacant" : ""}">${vacant ? "" : escapeHTML(initials(name))}</div>`;

  const bodyHtml = `
    ${avatarHtml}
    <div class="person-body">
      <div class="person-name">${escapeHTML(vacant ? t("about_team_vacant_title") : name)}</div>
      <div class="person-role">${escapeHTML(role || "")}</div>
      ${(!vacant && meta) ? `<div class="person-meta muted small">${escapeHTML(meta)}</div>` : ""}
      ${vacant ? `<div class="person-meta muted small" style="margin-top:6px">${escapeHTML(t("about_team_vacant_text"))}</div>` : ""}
    </div>
  `;

  if (vacant) {
    return `<div class="${cardCls}">${bodyHtml}</div>`;
  }

  return `
    <button class="${cardCls}" type="button" data-action="about-person-open" data-group="${escapeHTML(group || "")}" data-key="${escapeHTML(memberKey || "")}">
      ${bodyHtml}
    </button>
  `;
};
         const memberKeyOf = (x) => {
  const a = String(x.name || "").trim().toLowerCase();
  const b = String(x.role || "").trim().toLowerCase();
  return `${a}__${b}`;
};

         const TEAM_ROLE_I18N = {
  "Ta’sischi — Prezident": {
    ru: "Основатель — Президент",
    uz: "Ta’sischi — Prezident",
    en: "Founder — President"
  },
  "Vitse-Prezident": {
    ru: "Вице-президент",
    uz: "Vitse-Prezident",
    en: "Vice President"
  },
  "Chief Operating Officer": {
    ru: "Операционный директор",
    uz: "Operatsion direktor",
    en: "Chief Operating Officer"
  },
  "Media guruh rahbari": {
    ru: "Руководитель медиа-группы",
    uz: "Media guruhi rahbari",
    en: "Head of Media Group"
  },
  "Academic Quality Assurance Lead": {
    ru: "Руководитель по контролю академического качества",
    uz: "Akademik sifat nazorati rahbari",
    en: "Academic Quality Assurance Lead"
  },

  "AS level Chemistry": {
    ru: "Химия AS Level",
    uz: "AS Level Chemistry",
    en: "AS Level Chemistry"
  },
  "AS level Biology": {
    ru: "Биология AS Level",
    uz: "AS Level Biology",
    en: "AS Level Biology"
  },
  "IGCSE Computer Science": {
    ru: "Компьютерные науки IGCSE",
    uz: "IGCSE Computer Science",
    en: "IGCSE Computer Science"
  },
  "AS level Economics": {
    ru: "Экономика AS Level",
    uz: "AS Level Economics",
    en: "AS Level Economics"
  },
  "AS level Mathematics": {
    ru: "Математика AS Level",
    uz: "AS Level Mathematics",
    en: "AS Level Mathematics"
  },
  "IELTS mentor": {
    ru: "Ментор IELTS",
    uz: "IELTS mentori",
    en: "IELTS Mentor"
  },
  "SAT English": {
    ru: "SAT English",
    uz: "SAT English",
    en: "SAT English"
  },
  "SAT Math": {
    ru: "SAT Math",
    uz: "SAT Math",
    en: "SAT Math"
  },
  "English A2 mentor": {
    ru: "Ментор English A2",
    uz: "English A2 mentori",
    en: "English A2 Mentor"
  },
  "English B1 mentor": {
    ru: "Ментор English B1",
    uz: "English B1 mentori",
    en: "English B1 Mentor"
  },
  "Ingliz tili mentori": {
    ru: "Ментор по английскому языку",
    uz: "Ingliz tili mentori",
    en: "English Language Mentor"
  },

  "Video tahrirchi": {
    ru: "Видеоредактор",
    uz: "Video tahrirchi",
    en: "Video Editor"
  },
  "Copywriter": {
    ru: "Копирайтер",
    uz: "Kopirayter",
    en: "Copywriter"
  },
  "Dizayner": {
    ru: "Дизайнер",
    uz: "Dizayner",
    en: "Designer"
  },
  "Telegram menejer": {
    ru: "Менеджер Telegram",
    uz: "Telegram menejeri",
    en: "Telegram Manager"
  },
  "Instagram menejer": {
    ru: "Менеджер Instagram",
    uz: "Instagram menejeri",
    en: "Instagram Manager"
  }
};

const TEAM_META_I18N = {
  "Toshkent viloyati Nurafshon shahridagi Prezident maktabi 10 “Blue” sinf o‘quvchisi": {
    ru: "Ученик 10 «Blue» класса Президентской школы города Нурафшан, Ташкентская область",
    uz: "Toshkent viloyati Nurafshon shahridagi Prezident maktabi 10 “Blue” sinf o‘quvchisi",
    en: "Student of Grade 10 “Blue”, Presidential School of Nurafshon, Tashkent Region"
  },
  "Toshkent viloyati Nurafshon shahridagi Prezident maktabi 10 “Green” sinf o‘quvchisi": {
    ru: "Ученик 10 «Green» класса Президентской школы города Нурафшан, Ташкентская область",
    uz: "Toshkent viloyati Nurafshon shahridagi Prezident maktabi 10 “Green” sinf o‘quvchisi",
    en: "Student of Grade 10 “Green”, Presidential School of Nurafshon, Tashkent Region"
  },
  "Toshkent shahridagi Prezident maktabi 10 “Blue” sinf o‘quvchisi": {
    ru: "Ученик 10 «Blue» класса Президентской школы города Ташкент",
    uz: "Toshkent shahridagi Prezident maktabi 10 “Blue” sinf o‘quvchisi",
    en: "Student of Grade 10 “Blue”, Presidential School of Tashkent"
  },
  "Yosh kitobxon tanlovi g‘olibasi (2023) • IELTS 7": {
    ru: "Победительница конкурса «Yosh kitobxon» (2023) • IELTS 7",
    uz: "Yosh kitobxon tanlovi g‘olibasi (2023) • IELTS 7",
    en: "Winner of the “Yosh kitobxon” competition (2023) • IELTS 7"
  },
  "Toshkent viloyati Nurafshon shahridagi Prezident maktabi 10 “Green” sinf o‘quvchisi • IELTS 8.0": {
    ru: "Ученик 10 «Green» класса Президентской школы города Нурафшан, Ташкентская область • IELTS 8.0",
    uz: "Toshkent viloyati Nurafshon shahridagi Prezident maktabi 10 “Green” sinf o‘quvchisi • IELTS 8.0",
    en: "Student of Grade 10 “Green”, Presidential School of Nurafshon, Tashkent Region • IELTS 8.0"
  },
  "Samarqand viloyati Invest in education xususiy maktabi 11-sinf • IELTS 7.5 • SAT English 690": {
    ru: "11 класс частной школы Invest in Education, Самаркандская область • IELTS 7.5 • SAT English 690",
    uz: "Samarqand viloyati Invest in education xususiy maktabi 11-sinf • IELTS 7.5 • SAT English 690",
    en: "Grade 11, Invest in Education private school, Samarkand Region • IELTS 7.5 • SAT English 690"
  },
  "Xorazm viloyati Hazorasp tumani, To‘laqim FM xususiy maktabi 11-sinf • SAT Math 790": {
    ru: "11 класс частной школы To‘laqim FM, Хазараспский район, Хорезмская область • SAT Math 790",
    uz: "Xorazm viloyati Hazorasp tumani, To‘laqim FM xususiy maktabi 11-sinf • SAT Math 790",
    en: "Grade 11, To‘laqim FM private school, Hazorasp District, Khorezm Region • SAT Math 790"
  },
  "Samarqand viloyati Paxtachi tumani 12-maktab 11 “Moliya-iqtisod” • IELTS 6": {
    ru: "11 «Финансы-экономика» класс школы №12, Пахтачинский район, Самаркандская область • IELTS 6",
    uz: "Samarqand viloyati Paxtachi tumani 12-maktab 11 “Moliya-iqtisod” • IELTS 6",
    en: "Grade 11 “Finance-Economics”, School No. 12, Paxtachi District, Samarkand Region • IELTS 6"
  },
  "Toshkent Davlat sharqshunoslik universiteti 1-kurs • IELTS 6.5": {
    ru: "1 курс Ташкентского государственного университета востоковедения • IELTS 6.5",
    uz: "Toshkent Davlat sharqshunoslik universiteti 1-kurs • IELTS 6.5",
    en: "1st year student, Tashkent State University of Oriental Studies • IELTS 6.5"
  },
  "Navoiy davlat universiteti 3-bosqich • IELTS 7.5": {
    ru: "3 курс Навоийского государственного университета • IELTS 7.5",
    uz: "Navoiy davlat universiteti 3-bosqich • IELTS 7.5",
    en: "3rd year student, Navoi State University • IELTS 7.5"
  },
  "Toshkent Xalqaro Vestminster universiteti 1-kurs talabasi": {
    ru: "Студент 1 курса Международного Вестминстерского университета в Ташкенте",
    uz: "Toshkent Xalqaro Vestminster universiteti 1-kurs talabasi",
    en: "1st year student, Westminster International University in Tashkent"
  },
  "Xiva shahridagi Prezident maktabining 10 “Green” sinf o‘quvchisi": {
    ru: "Ученик 10 «Green» класса Президентской школы города Хива",
    uz: "Xiva shahridagi Prezident maktabining 10 “Green” sinf o‘quvchisi",
    en: "Student of Grade 10 “Green”, Presidential School of Khiva"
  }
};

function pickTeamLocalizedText(value, dict) {
  const raw = String(value || "").trim();
  if (!raw) return "";

  const lang = currentLang();
  const row = dict?.[raw];

  if (!row || typeof row !== "object") return raw;
  if (lang === "uz") return String(row.uz || row.ru || row.en || raw).trim();
  if (lang === "en") return String(row.en || row.ru || row.uz || raw).trim();
  return String(row.ru || row.uz || row.en || raw).trim();
}

function pickLangValue(v) {
  if (!v || typeof v !== "object") return "";
  const lang = currentLang();
  if (lang === "uz") return String(v.uz || v.ru || v.en || "").trim();
  if (lang === "en") return String(v.en || v.ru || v.uz || "").trim();
  return String(v.ru || v.uz || v.en || "").trim();
}

function localizeTeamPersonCardData(person) {
  const x = { ...(person || {}) };

  x.name = x.name_i18n ? pickLangValue(x.name_i18n) : String(x.name || "").trim();
  x.role = x.role_i18n ? pickLangValue(x.role_i18n) : pickTeamLocalizedText(x.role, TEAM_ROLE_I18N);
  x.meta = x.meta_i18n ? pickLangValue(x.meta_i18n) : pickTeamLocalizedText(x.meta, TEAM_META_I18N);

  if (x.about_i18n) x.about = pickLangValue(x.about_i18n);
  if (x.achievements_i18n) x.achievements = pickLangValue(x.achievements_i18n);
  if (x.education_i18n) x.education = pickLangValue(x.education_i18n);

  return x;
}
         
function clearAboutTeamResolvedCache() {
  if (!state.about) state.about = { tab: "project" };
  state.about.teamPeopleResolved = {};
}

function getAboutTeamSourceList(group) {
  ensureTeamCacheInit();

  const g = String(group || "board");

  if (g === "board") {
    const dbList = state.about.teamPeopleCache?.board;
    return Array.isArray(dbList) && dbList.length ? dbList : board;
  }

  if (g === "mentors") {
    const dbList = state.about.teamPeopleCache?.mentors;
    const sourceList = Array.isArray(dbList) && dbList.length ? dbList : mentors;
    return sourceList.filter(x => isMentorVisibleBySubjectActivity(x));
  }

  if (g === "media") {
    const dbList = state.about.teamPeopleCache?.media;
    return Array.isArray(dbList) && dbList.length ? dbList : media;
  }

  return [];
}

function getAboutTeamPersonByKey(group, key) {
  const list = getAboutTeamSourceList(group);
  if (!Array.isArray(list) || !list.length) return null;

  const targetKey = String(key || "");
  return list.find(x => String(x?.memberKey || memberKeyOf(x) || "") === targetKey) || null;
}

const enrichPersonProfile = (x) => {
  const meta = String(x.meta || "");
  const group = String(x.group || "");

  let about = String(x.about || "").trim();
  let achievements = String(x.achievements || "").trim();
  let education = String(x.education || "").trim() || meta;

  if (!about) {
    if (group === "board") {
      about = t("about_member_about_board") || "Loyiha strategiyasi, sifat va rivojlanish yo‘nalishlari ustida ishlaydi.";
    } else if (group === "media") {
      about = t("about_member_about_media") || "Kontent, kommunikatsiya va iClub’ning media yo‘nalishlari ustida ishlaydi.";
    } else {
      about = t("about_member_about_mentor") || "O‘quvchilarga fan bo‘yicha yo‘nalish, tushuncha va motivatsiya beradi.";
    }
  }

  if (!achievements) {
    if (group === "board") {
      achievements = meta || (t("about_member_achievements_default") || "Tajriba va faolligi bilan jamoa ishiga hissa qo‘shadi.");
    } else if (group === "media") {
      achievements = meta || (t("about_member_achievements_default") || "Jamoa ishiga amaliy hissa qo‘shadi.");
    } else {
      achievements = meta || (t("about_member_achievements_default") || "Fan bo‘yicha tayyorgarlik va amaliyotda yordam beradi.");
    }
  }

  return {
    ...x,
    about,
    achievements,
    education
  };
};

  // DATA v1 (from your posters) — later will be loaded from DB
  const board = [
    {
      memberKey: "board_azizbek_president",
      name: "Erkinov Azizbek Jasurbek o‘g‘li",
      name_i18n: {
        ru: "Erkinov Azizbek",
        uz: "Erkinov Azizbek Jasurbek o‘g‘li",
        en: "Erkinov Azizbek"
      },
      role: "Ta’sischi — Prezident",
      role_i18n: {
        ru: "Основатель · Президент",
        uz: "Asoschi · Prezident",
        en: "Founder · President"
      },
      meta_i18n: {
        ru: "Основатель и президент iClub. Работает над стратегией, качеством и развитием проекта, объединяя образование и технологии.",
        uz: "iClub asoschisi va prezidenti. Ta’lim va texnologiyani birlashtirib, loyiha strategiyasi, sifati va rivojlanishi ustida ishlaydi.",
        en: "Founder and president of iClub. Works on the strategy, quality and development of the project, combining education and technology."
      },
      about_i18n: {
        ru: "Основатель и президент iClub. Работает над развитием современной, системной и результативной образовательной среды для школьников.",
        uz: "iClub asoschisi va prezidenti. Yoshlar uchun zamonaviy, tizimli va natijaga yo‘naltirilgan ta’lim muhitini rivojlantirish ustida ishlaydi.",
        en: "Founder and president of iClub. Works on building a modern, structured, and results-driven learning environment for students."
      },
      achievements_i18n: {
        ru: "Основатель iClub. Участвовал в проектах уровня Министерства экономики и финансов. Руководил командами численностью более 50 человек. Имеет результат SAT 1550.",
        uz: "iClub asoschisi. Iqtisodiyot va moliya vazirligi darajasidagi loyihalarda ishtirok etgan. 50 dan ortiq kishidan iborat jamoalarni boshqargan. SAT 1550 natijaga ega.",
        en: "Founder of iClub. Participated in projects at the level of the Ministry of Economy and Finance. Led teams of more than 50 people. Scored 1550 on the SAT."
      },
      education_i18n: {
        ru: "Ученик Президентской школы города Нурафшан.",
        uz: "Nurafshon shahridagi Prezident maktabi o‘quvchisi.",
        en: "Student at Nurafshan Presidential School."
      },
      vacant: false
    },
    { name: "", role: "Vitse-Prezident", meta: "", vacant: true },
{
  memberKey: "board_safina_coo",
  name: "Safina Teshabayeva",
  photoUrl: "https://mmmduffgpvwjdpruzikw.supabase.co/storage/v1/object/public/team-photos/coo.jpg",
  role: "Chief Operating Officer",
  role_i18n: {
    ru: "Стратегический советник",
    uz: "Strategik maslahatchi",
    en: "Strategic Advisor"
  },
  meta_i18n: {
    ru: "Стратегический советник iClub. Поддерживает развитие проекта, партнёрства и реализацию образовательных и социальных инициатив.",
    uz: "iClub strategik maslahatchisi. Loyiha rivoji, hamkorliklar hamda ta’limiy va ijtimoiy tashabbuslarni qo‘llab-quvvatlaydi.",
    en: "Strategic Advisor at iClub. Supports project growth, partnerships, and the implementation of educational and social initiatives."
  },
  about_i18n: {
    ru: "Менеджер проектов с опытом более 6 лет в образовательных, технологических и социальных инициативах в Центральной Азии. Как стратегический советник, помогает проекту экспертизой, партнёрствами и управленческим опытом.",
    uz: "Markaziy Osiyoda ta’lim, texnologiya va ijtimoiy ta’sir yo‘nalishidagi tashabbuslarda 6 yildan ortiq tajribaga ega loyiha menejeri. Strategik maslahatchi sifatida loyiha rivojiga ekspertiza, hamkorlik va boshqaruv tajribasi bilan hissa qo‘shadi.",
    en: "Project manager with 6+ years of experience in educational, technological, and social impact initiatives across Central Asia. As a strategic advisor, supports the project with expertise, partnerships, and management experience."
  },
  achievements_i18n: {
  ru: "Работала в роли Tracker в UzCombinator, Chief Operating Officer в Impact Admissions, официального представителя FIRST в Узбекистане и Assistant Dean в Central Asian University. Имеет опыт в STEM и робототехнике, международном сотрудничестве, управлении командами и взаимодействии с государственным и образовательным секторами.",
  uz: "UzCombinator’da Tracker, Impact Admissions’da Chief Operating Officer, O‘zbekistonda FIRST’ning rasmiy vakili, Central Asian University’da Assistant Dean sifatida faoliyat yuritgan. STEM va robototexnika, xalqaro hamkorlik, jamoa boshqaruvi hamda davlat va ta’lim sektori bilan ishlash bo‘yicha tajribaga ega.",
  en: "Has served as Tracker at UzCombinator, Chief Operating Officer at Impact Admissions, Official Representative of FIRST in Uzbekistan, and Assistant Dean at Central Asian University. Experienced in STEM and robotics, international partnerships, team management, and collaboration with public and education sectors."
},
  education_i18n: {
  ru: "Профессионально работает на стыке образования, STEM, международных программ и управления проектами в Узбекистане и Центральной Азии.",
  uz: "Professional faoliyati ta’lim, STEM, xalqaro dasturlar va loyiha boshqaruvi yo‘nalishlari kesishmasida shakllangan.",
  en: "Her professional background is built at the intersection of education, STEM, international programs, and project management in Uzbekistan and Central Asia."
},
  vacant: false
},
    { name: "", role: "Media guruh rahbari", meta: "", vacant: true },
    {
      name: "Marhabo Mahkamtoasheva",
      role: "Academic Quality Assurance Lead",
      meta: "Yosh kitobxon tanlovi g‘olibasi (2023) • IELTS 7",
      vacant: false
    }
  ];

  const mentors = [
    {
      memberKey: "mentor_ruxsora_chemistry",
      name: "Ruxsora Komiljonova",
      role: "AS level Chemistry",
      role_i18n: {
        ru: "AS Level Chemistry",
        uz: "AS Level Chemistry",
        en: "AS Level Chemistry"
      },
      meta_i18n: {
        ru: "Помогает ученикам развивать понимание химии, практическое мышление и исследовательский интерес.",
        uz: "Kimyo yo‘nalishida tushuncha, amaliy fikrlash va ilmiy qiziqishni rivojlantirishga yordam beradi.",
        en: "Helps learners strengthen chemistry understanding, practical thinking, and scientific curiosity."
      },
      about_i18n: {
        ru: "Помогает ученикам в изучении химии, развитии практического мышления и научного интереса.",
        uz: "Kimyo yo‘nalishida o‘quvchilarga nazariy tushuncha, amaliy fikrlash va ilmiy qiziqish bo‘yicha yo‘l ko‘rsatadi.",
        en: "Guides learners in chemistry through conceptual clarity, practical thinking, and scientific curiosity."
      },
      achievements_i18n: {
        ru: "Сооснователь проекта “Lucid Vision”. Руководитель направления Chemical Engineering в Muhandis.uz. Менеджер команды контента Grand Zone. Проводит исследование на тему “Biodegradable Bioplastic”. Провела Chemistry Show примерно в 10 школах Ташкентской области. Призёр INNOVUM — 2 место.",
        uz: "“Lucid Vision” loyihasi hammuassisi. Muhandis.uz platformasida Chemical Engineering bo‘limi rahbari. Grand Zone loyihasida kontent jamoasi menejeri. “Biodegradable Bioplastic” mavzusida tadqiqot olib bormoqda. Toshkent viloyatidagi taxminan 10 ta maktabda Chemistry Show dasturlarini o‘tkazgan. INNOVUM olimpiadasida 2-o‘rin sohibasi.",
        en: "Co-founder of the “Lucid Vision” project. Head of the Chemical Engineering Department at Muhandis.uz. Content Creation Team Manager at Grand Zone. Conducting research on “Biodegradable Bioplastic.” Led Chemistry Shows in around 10 schools across Tashkent region. 2nd place winner of the INNOVUM Olympiad."
      },
      education_i18n: {
        ru: "Ученица Nurafshan Presidential School. Основное направление — Chemical Engineering.",
        uz: "Nurafshon Presidential School o‘quvchisi. Asosiy yo‘nalishi — Chemical Engineering.",
        en: "Student at Nurafshan Presidential School. Major: Chemical Engineering."
      }
    },
    {
      memberKey: "mentor_shohjahon_biology",
      name: "Olimov Shohjahon",
      role: "AS level Biology",
      role_i18n: {
        ru: "AS Level Biology",
        uz: "AS Level Biology",
        en: "AS Level Biology"
      },
      meta_i18n: {
        ru: "Помогает ученикам разбираться в биологии, укреплять базовые темы и уверенно продвигаться в практике.",
        uz: "Biologiya fanini tushunish, asosiy mavzularni mustahkamlash va amaliy tayyorgarlikda yordam beradi.",
        en: "Helps learners understand biology, strengthen core topics, and move forward confidently in practice."
      },
      about_i18n: {
        ru: "Помогает ученикам лучше понимать биологию, укреплять ключевые темы и уверенно двигаться в практике.",
        uz: "Biologiya fanini tushunish, asosiy mavzularni mustahkamlash va amaliy tayyorgarlikda o‘quvchilarga yo‘l ko‘rsatadi.",
        en: "Guides learners in understanding biology, strengthening essential topics, and improving through practice."
      },
      achievements_i18n: {
        ru: "Имеет оценку A по IGCSE Biology. Имеет результат IELTS 7.5.",
        uz: "IGCSE Biology fanidan A bahoga ega. IELTS 7.5 natijaga ega.",
        en: "Earned grade A in IGCSE Biology. Holds IELTS 7.5."
      },
      education_i18n: {
        ru: "Ученик Президентской школы города Нурафшан.",
        uz: "Nurafshon shahridagi Prezident maktabi o‘quvchisi.",
        en: "Student at Nurafshan Presidential School."
      }
    },
    {
      memberKey: "mentor_jasur_cs",
      name: "Abduxakimov Jasur",
      role: "IGCSE Computer Science",
      role_i18n: {
        ru: "IGCSE Computer Science",
        uz: "IGCSE Computer Science",
        en: "IGCSE Computer Science"
      },
      meta_i18n: {
        ru: "Помогает ученикам развивать алгоритмическое мышление, навыки программирования и уверенное понимание Computer Science.",
        uz: "Dasturlash, algoritmik fikrlash va informatika asoslarini mustahkamlashda yordam beradi.",
        en: "Helps learners build algorithmic thinking, programming skills, and a strong foundation in Computer Science."
      },
      about_i18n: {
        ru: "Помогает ученикам в развитии алгоритмического мышления, программирования и понимания современных технологий.",
        uz: "Informatika yo‘nalishida algoritmik fikrlash, dasturlash va zamonaviy texnologiyalar bo‘yicha o‘quvchilarga yo‘l ko‘rsatadi.",
        en: "Supports learners in algorithmic thinking, programming, and understanding modern technologies."
      },
      achievements_i18n: {
        ru: "Владеет Python, React, Node.js и Tailwind. Имеет результаты IGCSE: Mathematics A*, Physics A*, Chemistry A, Economics A. Занял 2 место на национальном соревновании по информатике.",
        uz: "Python, React, Node.js va Tailwind bilan ishlaydi. IGCSE Mathematics fanidan A*, Physics fanidan A*, Chemistry fanidan A, Economics fanidan A natijalarga ega. Informatika bo‘yicha milliy tanlovda 2-o‘rin olgan.",
        en: "Works with Python, React, Node.js, and Tailwind. Holds IGCSE results: Mathematics A*, Physics A*, Chemistry A, Economics A. Won 2nd place in the national informatics competition."
      },
      education_i18n: {
        ru: "Ученик Президентской школы города Ташкент.",
        uz: "Toshkent shahridagi Prezident maktabi o‘quvchisi.",
        en: "Student at Tashkent Presidential School."
      }
    },
    {
      memberKey: "mentor_azizbek_economics",
      name: "Erkinov Azizbek",
      role: "AS level Economics",
      role_i18n: {
        ru: "Economics Mentor",
        uz: "Economics Mentor",
        en: "Economics Mentor"
      },
      meta_i18n: {
        ru: "Помогает ученикам развивать понимание экономики, практическое мышление и подготовку к олимпиаде по экономике.",
        uz: "Iqtisodiyot bo‘yicha nazariy tushuncha, amaliy fikrlash va iqtisodiyot olimpiadasiga tayyorgarlik yo‘nalishida o‘quvchilarga yo‘l ko‘rsatadi.",
        en: "Helps learners build economics understanding, practical thinking, and preparation for economics olympiads."
      },
      about_i18n: {
        ru: "Помогает ученикам в изучении экономики, развитии практического мышления и подготовке к олимпиаде по экономике.",
        uz: "Iqtisodiyot bo‘yicha nazariy tushuncha, amaliy fikrlash va iqtisodiyot olimpiadasiga tayyorgarlik yo‘nalishida o‘quvchilarga yo‘l ko‘rsatadi.",
        en: "Guides learners in economics through conceptual clarity, practical thinking, and economics olympiad preparation."
      },
      achievements_i18n: {
        ru: "IGCSE Economics: A*. Дважды вошёл в Top 20 на республиканском этапе олимпиады по экономике. Проходил практику при Министерстве экономики и финансов.",
        uz: "IGCSE Economics: A*. Iqtisodiyot olimpiadasining respublika bosqichida 2 marta Top 20 natija ko‘rsatgan. Iqtisodiyot va moliya vazirligi huzurida amaliyot o‘tagan.",
        en: "IGCSE Economics: A*. Reached Top 20 twice at the republican stage of the economics olympiad. Completed internship experience under the Ministry of Economy and Finance."
      },
      education_i18n: {
        ru: "Ученик Президентской школы города Нурафшан.",
        uz: "Nurafshon shahridagi Prezident maktabi o‘quvchisi.",
        en: "Student at Nurafshan Presidential School."
      }
    },
    {
      memberKey: "mentor_madina_math",
      name: "Madina To‘ychiboyeva",
      role: "AS level Mathematics",
      role_i18n: {
        ru: "AS Level Mathematics",
        uz: "AS Level Mathematics",
        en: "AS Level Mathematics"
      },
      meta_i18n: {
        ru: "Помогает ученикам развивать логическое мышление, интерес к науке и устойчивую академическую подготовку.",
        uz: "Mantiqiy fikrlash, fanlararo qiziqish va izchil tayyorgarlik yo‘lida o‘quvchilarga yordam beradi.",
        en: "Helps learners build logical thinking, scientific curiosity, and steady academic preparation."
      },
      about_i18n: {
        ru: "Помогает ученикам развивать логическое мышление, междисциплинарный интерес и системную академическую подготовку.",
        uz: "Mantiqiy fikrlash, fanlararo qiziqish va izchil akademik rivojlanish yo‘nalishida o‘quvchilarga yo‘l ko‘rsatadi.",
        en: "Supports learners in building logical thinking, interdisciplinary curiosity, and consistent academic growth."
      },
      achievements_i18n: {
        ru: "Полуфиналист IRN. Лауреат JLSAAT Courage Award. Призёр INNOVUM — 2 место.",
        uz: "IRN semi-finalisti. JLSAAT Courage Award sovrindori. INNOVUM olimpiadasida 2-o‘rin sohibasi.",
        en: "IRN semi-finalist. JLSAAT Courage Award recipient. 2nd place winner in INNOVUM."
      },
      education_i18n: {
        ru: "Ученица Nurafshan Presidential School ’27. Основное направление — Neuroscience.",
        uz: "Nurafshon Presidential School ’27 o‘quvchisi. Asosiy yo‘nalishi — Neuroscience.",
        en: "Student at Nurafshan Presidential School ’27. Major: Neuroscience."
      }
    },

    { name: "Jamshidbek Yaxiyakulov", role: "SAT English", meta: "Samarqand viloyati Invest in education xususiy maktabi 11-sinf • IELTS 7.5 • SAT English 690" },
    { name: "Iskandarov Bunyodbek", role: "SAT Math", meta: "Xorazm viloyati Hazorasp tumani, To‘laqim FM xususiy maktabi 11-sinf • SAT Math 790" },
    { name: "Munisa Ro‘ziboyeva", role: "English A2 mentor", meta: "Samarqand viloyati Paxtachi tumani 12-maktab 11 “Moliya-iqtisod” • IELTS 6" },
    { name: "Madina Umarova", role: "English B1 mentor", meta: "Toshkent Davlat sharqshunoslik universiteti 1-kurs • IELTS 6.5" },
    { name: "Kamolaxon Qodirova", role: "Ingliz tili mentori", meta: "Navoiy davlat universiteti 3-bosqich • IELTS 7.5" }
  ];

  const media = [
    {
      memberKey: "media_zilola_video_editor",
      name: "Akbaraliyeva Zilola",
      role: "Video tahrirchi",
      role_i18n: {
        ru: "Видеомонтажёр",
        uz: "Video tahrirchi",
        en: "Video Editor"
      },
      meta_i18n: {
        ru: "Работает над визуальной подачей и качеством видеоконтента iClub.",
        uz: "iClub videokontentining vizual sifati va taqdimoti ustida ishlaydi.",
        en: "Works on the visual quality and presentation of iClub video content."
      },
      about_i18n: {
        ru: "Работает над визуальной подачей и монтажом видеоконтента для iClub.",
        uz: "iClub uchun videokontentning vizual taqdimoti va montaji ustida ishlaydi.",
        en: "Works on editing and visual presentation of video content for iClub."
      },
      achievements_i18n: {
        ru: "Участвует в создании и оформлении видеоматериалов для проекта.",
        uz: "Loyiha uchun videomateriallarni tayyorlash va bezashda ishtirok etadi.",
        en: "Contributes to the creation and editing of video materials for the project."
      },
      education_i18n: {
        ru: "Студентка 1 курса Ташкентского международного Вестминстерского университета.",
        uz: "Toshkent Xalqaro Vestminster universiteti 1-kurs talabasi.",
        en: "First-year student at Westminster International University in Tashkent."
      }
    },
    {
      memberKey: "media_shohrubek_video_editor",
      name: "Iskandarov Shohrubek",
      role: "Video tahrirchi",
      role_i18n: {
        ru: "Видеомонтажёр",
        uz: "Video tahrirchi",
        en: "Video Editor"
      },
      meta_i18n: {
        ru: "Помогает команде в создании и монтаже видеоконтента iClub.",
        uz: "iClub videokontentini tayyorlash va montaj qilishda jamoaga yordam beradi.",
        en: "Supports the team in creating and editing iClub video content."
      },
      about_i18n: {
        ru: "Работает над монтажом видеоматериалов и визуальной подачей контента.",
        uz: "Videomateriallar montaji va kontentning vizual taqdimoti ustida ishlaydi.",
        en: "Works on video editing and visual presentation of content."
      },
      achievements_i18n: {
        ru: "Участвует в подготовке видеоконтента для медиа-направления iClub.",
        uz: "iClub media yo‘nalishi uchun videokontent tayyorlashda ishtirok etadi.",
        en: "Contributes to video production for the iClub media direction."
      },
      education_i18n: {
        ru: "Ученик Президентской школы города Хива.",
        uz: "Xiva shahridagi Prezident maktabining o‘quvchisi.",
        en: "Student at Khiva Presidential School."
      }
    },
    {
      memberKey: "media_copywriter_vacant",
      name: "",
      role: "Copywriter",
      role_i18n: {
        ru: "Копирайтер",
        uz: "Copywriter",
        en: "Copywriter"
      },
      meta_i18n: {
        ru: "Позиция открыта. Кандидаты рассматриваются.",
        uz: "Lavozim ochiq. Nomzodlar ko‘rib chiqilmoqda.",
        en: "Position is open. Candidates are under review."
      },
      vacant: true
    },
    {
      memberKey: "media_designer_vacant",
      name: "",
      role: "Dizayner",
      role_i18n: {
        ru: "Дизайнер",
        uz: "Dizayner",
        en: "Designer"
      },
      meta_i18n: {
        ru: "Позиция открыта. Кандидаты рассматриваются.",
        uz: "Lavozim ochiq. Nomzodlar ko‘rib chiqilmoqda.",
        en: "Position is open. Candidates are under review."
      },
      vacant: true
    },
    {
      memberKey: "media_sevara_telegram_manager",
      name: "Davlatboyeva Sevara",
      role: "Telegram menejer",
      role_i18n: {
        ru: "Telegram-менеджер",
        uz: "Telegram menejer",
        en: "Telegram Manager"
      },
      meta_i18n: {
        ru: "Работает над коммуникацией и развитием iClub в Telegram.",
        uz: "iClub’ning Telegram’dagi kommunikatsiyasi va rivoji ustida ishlaydi.",
        en: "Works on communication and growth of iClub on Telegram."
      },
      about_i18n: {
        ru: "Отвечает за коммуникацию, подачу и поддержку активности iClub в Telegram.",
        uz: "Telegram’da iClub kommunikatsiyasi, taqdimoti va faolligini qo‘llab-quvvatlash ustida ishlaydi.",
        en: "Supports communication, presentation, and activity of iClub on Telegram."
      },
      achievements_i18n: {
        ru: "Участвует в развитии Telegram-направления и работе с аудиторией проекта.",
        uz: "Loyihaning Telegram yo‘nalishini rivojlantirish va auditoriya bilan ishlashda ishtirok etadi.",
        en: "Contributes to the Telegram direction of the project and audience communication."
      },
      education_i18n: {
        ru: "Ученица Президентской школы города Нурафшан.",
        uz: "Nurafshon shahridagi Prezident maktabi o‘quvchisi.",
        en: "Student at Nurafshan Presidential School."
      }
    },
    {
      memberKey: "media_dilrabo_instagram_manager",
      name: "Kucharova Dilrabo",
      role: "Instagram menejer",
      role_i18n: {
        ru: "Instagram-менеджер",
        uz: "Instagram menejer",
        en: "Instagram Manager"
      },
      meta_i18n: {
        ru: "Работает над развитием и визуальной подачей iClub в Instagram.",
        uz: "iClub’ning Instagram’dagi rivoji va vizual taqdimoti ustida ishlaydi.",
        en: "Works on growth and visual presentation of iClub on Instagram."
      },
      about_i18n: {
        ru: "Отвечает за визуальную подачу и развитие присутствия iClub в Instagram.",
        uz: "Instagram’da iClub’ning vizual taqdimoti va rivojlanishi ustida ishlaydi.",
        en: "Supports the visual presence and growth of iClub on Instagram."
      },
      achievements_i18n: {
        ru: "Участвует в развитии Instagram-направления и медиа-коммуникации проекта.",
        uz: "Loyihaning Instagram yo‘nalishi va media kommunikatsiyasini rivojlantirishda ishtirok etadi.",
        en: "Contributes to the Instagram direction and media communication of the project."
      },
      education_i18n: {
        ru: "Ученица Президентской школы города Нурафшан.",
        uz: "Nurafshon shahridagi Prezident maktabi o‘quvchisi.",
        en: "Student at Nurafshan Presidential School."
      }
    }
  ];

  const subHeader = (titleKey) => `
    <div class="about-subhead">
      <button class="about-subhead-back" type="button" data-action="about-team-back">‹</button>
      <div class="about-subhead-title">${escapeHTML(t(titleKey))}</div>
    </div>
  `;

  if (teamScreen === "board") {
  ensureTeamCacheInit();

  const dbList = state.about.teamPeopleCache?.board;
const list = Array.isArray(dbList) && dbList.length ? dbList : board;

state.about.teamPeopleResolved = state.about.teamPeopleResolved || {};
state.about.teamPeopleResolved.board = list.map(x => {
  const localized = localizeTeamPersonCardData(x);
  return {
    ...localized,
    group: "board",
    memberKey: String(x?.memberKey || memberKeyOf(x) || "")
  };
});

contentEl.innerHTML = `
  ${subHeader("about_team_board_title")}
  <div class="card">
    <div class="people-grid">
      ${state.about.teamPeopleResolved.board.map(x => personCard({ ...x, large: true })).join("")}
    </div>
  </div>
`;

  // if we’re still on fallback — try DB in background
  if (!(Array.isArray(dbList) && dbList.length)) {
    try { ensureTeamPeopleLoaded("board"); } catch {}
  }

  return;
}

    if (teamScreen === "mentors") {
  ensureTeamCacheInit();

  const dbList = state.about.teamPeopleCache?.mentors;
  const sourceList = Array.isArray(dbList) && dbList.length ? dbList : mentors;
  const list = sourceList.filter(x => isMentorVisibleBySubjectActivity(x));

  state.about.teamPeopleResolved = state.about.teamPeopleResolved || {};
state.about.teamPeopleResolved.mentors = list.map(x => {
  const localized = localizeTeamPersonCardData(x);
  return {
    ...localized,
    group: "mentors",
    memberKey: String(x?.memberKey || memberKeyOf(x) || "")
  };
});

  contentEl.innerHTML = `
  ${subHeader("about_team_mentors_title")}
  <div class="card">
    <div class="people-grid">
      ${state.about.teamPeopleResolved.mentors.map(x => personCard({ ...x, vacant: !!x.vacant, large: true })).join("")}
    </div>
  </div>
`;

  if (!(Array.isArray(dbList) && dbList.length)) {
    try { ensureTeamPeopleLoaded("mentors"); } catch {}
  }

  return;
}

  if (teamScreen === "media") {
  ensureTeamCacheInit();

  const dbList = state.about.teamPeopleCache?.media;
const list = Array.isArray(dbList) && dbList.length ? dbList : media;

state.about.teamPeopleResolved = state.about.teamPeopleResolved || {};
state.about.teamPeopleResolved.media = list.map(x => {
  const localized = localizeTeamPersonCardData(x);
  return {
    ...localized,
    group: "media",
    memberKey: String(x?.memberKey || memberKeyOf(x) || "")
  };
});

contentEl.innerHTML = `
  ${subHeader("about_team_media_title")}
  <div class="card">
    <div class="people-grid">
      ${state.about.teamPeopleResolved.media.map(x => personCard({ ...x, large: true })).join("")}
    </div>
  </div>
`;

  if (!(Array.isArray(dbList) && dbList.length)) {
    try { ensureTeamPeopleLoaded("media"); } catch {}
  }

  return;
}
      if (teamScreen === "member") {
  const prev = state.about.teamPrevScreen || "board";
  const raw = getAboutTeamPersonByKey(prev, state.about.teamMemberKey || "");

  if (!raw) {
    state.about.teamScreen = prev;
    state.about.teamMemberKey = null;
    saveState();
    renderAboutView();
    return;
  }

  const localizedRaw = localizeTeamPersonCardData({
  ...raw,
  group: prev,
  memberKey: String(raw?.memberKey || memberKeyOf(raw) || "")
});

  const person = enrichPersonProfile(localizedRaw);
  const hasPhoto = !!(person.photoUrl && String(person.photoUrl).trim());

  contentEl.innerHTML = `
    ${subHeader("about_team_profile_title")}

    <div class="card team-profile-card">
      <div class="team-profile-hero">
        ${hasPhoto
  ? `<img class="team-profile-photo" src="${escapeHTML(person.photoUrl)}" alt="${escapeHTML(person.name || "")}" decoding="async" />`
  : `<div class="team-profile-fallback">${escapeHTML(initials(person.name))}</div>`
}

        <div class="team-profile-head">
          <div class="team-profile-name">${escapeHTML(person.name || "")}</div>
          <div class="team-profile-role">${escapeHTML(person.role || "")}</div>
        </div>
      </div>
    </div>

    <div class="card">
      <div class="card-title">${escapeHTML(t("about_member_about_title"))}</div>
      <div class="muted small" style="margin-top:8px; line-height:1.45">${escapeHTML(person.about || "")}</div>
    </div>

    <div class="card">
      <div class="card-title">${escapeHTML(t("about_member_achievements_title"))}</div>
      <div class="muted small" style="margin-top:8px; line-height:1.45">${escapeHTML(person.achievements || "")}</div>
    </div>

    <div class="card">
      <div class="card-title">${escapeHTML(t("about_member_education_title"))}</div>
      <div class="muted small" style="margin-top:8px; line-height:1.45">${escapeHTML(person.education || "")}</div>
    </div>
  `;
  return;
}
  // overview
  contentEl.innerHTML = `
    <div class="card">
      <div class="card-title">${escapeHTML(t("about_team_who_title"))}</div>
      <div class="muted small" style="margin-top:6px">${escapeHTML(t("about_team_who_text"))}</div>
    </div>

    <div class="card">
      <div class="card-title">${escapeHTML(t("about_team_structure_title"))}</div>
      <div class="muted small" style="margin-top:6px">${escapeHTML(t("about_team_structure_sub"))}</div>

      <div class="settings-list" style="margin-top:10px">
        <button class="settings-nav" type="button" data-action="about-team-open" data-screen="board">
          <span class="settings-nav-ico">🏛</span>
          <span class="settings-nav-text">
            <span class="settings-nav-title">${escapeHTML(t("about_team_nav_board"))}</span>
          </span>
          <span class="settings-nav-arrow">›</span>
        </button>

        <button class="settings-nav" type="button" data-action="about-team-open" data-screen="mentors">
          <span class="settings-nav-ico">🎓</span>
          <span class="settings-nav-text">
            <span class="settings-nav-title">${escapeHTML(t("about_team_nav_mentors"))}</span>
          </span>
          <span class="settings-nav-arrow">›</span>
        </button>

        <button class="settings-nav" type="button" data-action="about-team-open" data-screen="media">
          <span class="settings-nav-ico">🎬</span>
          <span class="settings-nav-text">
            <span class="settings-nav-title">${escapeHTML(t("about_team_nav_media"))}</span>
          </span>
          <span class="settings-nav-arrow">›</span>
        </button>
      </div>
    </div>

    <div class="card">
      <div class="card-title">${escapeHTML(t("about_team_contact_title"))}</div>

      <button class="btn primary" type="button" data-action="open-admin" style="width:100%; margin-top:10px">
        ${escapeHTML(t("about_team_admin_btn"))}
      </button>

      <div class="muted small" style="margin-top:8px">
        ${escapeHTML(t("about_team_admin_sub"))}
      </div>
    </div>
  `;
}
     // ---------------------------
  // Practice v1 (10Q: 3/5/2 + MCQ+INPUT + per-question timer + attempts history)
  // ---------------------------

  const PRACTICE_CONFIG = {
    total: 10,
    dist: { easy: 3, medium: 5, hard: 2 },
    // таймер по сложности (сек)
    timeByDifficulty: { easy: 45, medium: 60, hard: 90 },
    // максимум сохраняемых попыток
    keepLastAttempts: 5
  };

function getReadingRefs(subjectKey, topic) {
  const map = (typeof READING_MAP !== "undefined" && READING_MAP) ? READING_MAP : null;
  if (!map || typeof map !== "object") return [];

  const s = map?.[subjectKey] || null;
  if (!s || typeof s !== "object") return [];

  const refs = s?.[topic] || [];
  return Array.isArray(refs) ? refs : [];
}
   
  function shuffle(arr) {
    const a = [...arr];
    for (let i = a.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      [a[i], a[j]] = [a[j], a[i]];
    }
    return a;
  }

  function normalizeDifficulty(d) {
    const x = String(d || "").toLowerCase();
    if (x === "easy" || x === "medium" || x === "hard") return x;
    return "medium";
  }

function pickN(pool, n, usedIds = new Set()) {
  const limit = Math.max(0, Number(n) || 0);
  if (!Array.isArray(pool) || limit <= 0) return [];

  const fresh = shuffle(pool).filter(q => !usedIds.has(String(q?.id)));
  const picked = fresh.slice(0, limit);

  picked.forEach(q => usedIds.add(String(q?.id)));
  return picked;
}
// --- helpers: options parsing + answer normalization ---
function parseOptionsText(raw) {
  if (raw === null || raw === undefined) return null;
  if (Array.isArray(raw)) return raw.map(String);

  const s = String(raw).trim();
  if (!s) return null;

  // try JSON first
  try {
    const parsed = JSON.parse(s);
    if (Array.isArray(parsed)) return parsed.map(x => String(x));
  } catch {}

  // fallback: split lines / separators
  if (s.includes("\n")) return s.split("\n").map(x => x.trim()).filter(Boolean);
  if (s.includes("||")) return s.split("||").map(x => x.trim()).filter(Boolean);
  if (s.includes("|")) return s.split("|").map(x => x.trim()).filter(Boolean);

  return [s];
}

function isNumericLike(v) {
  const s = String(v ?? "").trim().replace(",", ".");
  return s !== "" && !Number.isNaN(Number(s));
}

   function idxToLetter(i) {
  const n = Number(i);
  if (!Number.isFinite(n)) return "";
  const idx = Math.trunc(n);
  const ABCD = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
  return (idx >= 0 && idx < ABCD.length) ? ABCD[idx] : "";
}

function letterToIdx(ch) {
  const s = String(ch ?? "").trim().toUpperCase();
  if (!s) return null;
  const code = s.charCodeAt(0) - 65; // A->0
  return (code >= 0 && code < 26) ? code : null;
}

function getQuestionOptionsArray(q) {
  try {
    if (Array.isArray(q?.options)) return q.options.map(String);

    const raw =
      pickContentText(q || {}, "options_text") ||
      q?.options_text ||
      q?.optionsText ||
      "";

    return parseOptionsText(raw) || [];
  } catch {
    return [];
  }
}

function getMcqCorrectIndexFromQuestion(q) {
  if (!q || typeof q !== "object") return null;

  const direct = q.correctIndex ?? q.correct_index;
  if (direct !== null && direct !== undefined && direct !== "") {
    const n = Number(direct);
    if (Number.isFinite(n)) return Math.trunc(n);
  }

  const raw = String(
    q.correct_answer ??
    q.correctAnswer ??
    q.correct ??
    q.answer ??
    ""
  ).trim();

  if (!raw) return null;

  if (/^[A-D]$/i.test(raw)) {
    return letterToIdx(raw);
  }

  if (/^[0-3]$/.test(raw)) {
    return Number(raw);
  }

  const opts = getQuestionOptionsArray(q);
  if (opts.length) {
    const idx = opts.findIndex(o => String(o).trim().toLowerCase() === raw.toLowerCase());
    if (idx >= 0) return idx;
  }

  return null;
}

function isMcqPickedIndexCorrect(q, pickedIndex) {
  const picked = (pickedIndex === null || pickedIndex === undefined || pickedIndex === "")
    ? null
    : Number(pickedIndex);

  const correctIdx = getMcqCorrectIndexFromQuestion(q);

  return (
    picked !== null &&
    Number.isFinite(picked) &&
    correctIdx !== null &&
    Number.isFinite(Number(correctIdx)) &&
    Math.trunc(picked) === Math.trunc(Number(correctIdx))
  );
}

async function fetchQuestionRuntimeSecrets(questionId) {
  try {
    const client = window.sb || sb || null;
    const id = Number(questionId);
    if (!client || !Number.isFinite(id) || id <= 0) return null;

    const { data, error } = await client
      .from("questions")
            .select("id,topic,subtopic,difficulty,qtype,time_limit_sec,question_text,options_text,correct_answer,explanation,image_url,book_ref,question_text_ru,question_text_uz,question_text_en,options_text_ru,options_text_uz,options_text_en,explanation_ru,explanation_uz,explanation_en")
      .eq("id", id)
      .maybeSingle();

    if (error || !data) return null;
    return data;
  } catch {
    return null;
  }
}

function mergeRuntimeQuestionSecrets(oldQ, row, fallbackTimeLimitSec = 60) {
  if (!row) return oldQ;

  const type = String(row.qtype || oldQ?.qtype || oldQ?.type || "mcq").toLowerCase() === "input" ? "input" : "mcq";
  const optionsRaw = pickContentText(row, "options_text");
  const opts = type === "mcq" ? (parseOptionsText(optionsRaw) || []) : [];
  const diff = normalizeDifficulty(row.difficulty || oldQ?.difficulty || "easy");

  const merged = {
    ...(oldQ || {}),
    id: Number(row.id || oldQ?.id),
    topic: row.topic || oldQ?.topic || "General",
    subtopic: row.subtopic || oldQ?.subtopic || null,
    difficulty: diff,
    type,
    qtype: type,
    question: oldQ?.question || pickContentText(row, "question_text") || "",
    options: opts.length ? opts : (Array.isArray(oldQ?.options) ? oldQ.options : []),
    correct_answer: String(row.correct_answer ?? oldQ?.correct_answer ?? oldQ?.correctAnswer ?? "").trim(),
    correctAnswer: String(row.correct_answer ?? oldQ?.correct_answer ?? oldQ?.correctAnswer ?? "").trim(),
    explanation: pickContentText(row, "explanation") || oldQ?.explanation || "",
    imageUrl: row.image_url || oldQ?.imageUrl || null,
    book_ref: row.book_ref || oldQ?.book_ref || null,
    bookReference: row.book_ref || oldQ?.bookReference || oldQ?.book_ref || null,
    timeLimitSec: Number(oldQ?.timeLimitSec || row.time_limit_sec || fallbackTimeLimitSec)
  };

  if (type === "mcq") {
    merged.correctIndex = getMcqCorrectIndexFromQuestion(merged);
  } else {
    merged.inputKind = isNumericLike(merged.correctAnswer) ? "numeric" : "text";
    merged.inputHint = inputHintForAnswer(merged.correctAnswer);
  }

  return merged;
}

async function restoreActiveTourQuestionSecrets(ctx, questionIndex) {
  try {
    if (!ctx || ctx.isArchive || !Array.isArray(ctx.questions)) return null;

    const idx = Number(questionIndex ?? ctx.index ?? 0);
    if (!Number.isFinite(idx) || idx < 0 || idx >= ctx.questions.length) return null;

    const oldQ = ctx.questions[idx];
    const row = await fetchQuestionRuntimeSecrets(oldQ?.id);
    if (!row) return null;

    const restored = mergeRuntimeQuestionSecrets(oldQ, row, TOUR_CONFIG.defaultQuestionTimeSec);
    ctx.questions[idx] = restored;
    return restored;
  } catch {
    return null;
  }
}

async function getSavedTourAttemptScore(attemptId) {
  try {
    const client = window.sb || sb || null;
    const id = Number(attemptId);
    if (!client || !Number.isFinite(id) || id <= 0) return null;

    const { data, error } = await client
      .from("tour_answers")
      .select("id,is_correct")
      .eq("attempt_id", id)
      .limit(30);

    if (error || !Array.isArray(data)) return null;

    const score = data.filter(x => !!x?.is_correct).length;
    const answerRows = data.length;
    const percent = TOUR_CONFIG.total
      ? Math.round((score / TOUR_CONFIG.total) * 10000) / 100
      : 0;

    return { score, percent, answerRows };
  } catch {
    return null;
  }
}

// ✅ show answers consistently: "B — option text" (if options exist)
function formatAnswerForDisplay(q, rawAnswer) {
  const raw = String(rawAnswer ?? "").trim();
  if (!raw) return "—";

  const qTypeRaw = String(q?.qtype ?? q?.type ?? "").toLowerCase();

  const isExplicitMcq =
    qTypeRaw === "mcq" ||
    qTypeRaw === "multiple_choice" ||
    qTypeRaw === "mcq_single";

  const isExplicitInput =
    qTypeRaw === "input" ||
    qTypeRaw === "input_number" ||
    qTypeRaw === "input_text" ||
    qTypeRaw === "input_text_short";

  let opts = null;
  try {
    const oText = (typeof pickContentText === "function")
      ? pickContentText(q, "options_text")
      : (q?.options_text ?? null);
    opts = parseOptionsText(oText);
  } catch {}

  // ✅ input всегда показываем как есть
  if (isExplicitInput) {
    return raw;
  }

  // ✅ если тип вообще не передали и вариантов нет, не гадаем что это MCQ
  const inferredMcq = !isExplicitInput && !isExplicitMcq && Array.isArray(opts) && opts.length > 0;
  const isMcq = isExplicitMcq || inferredMcq;

  if (!isMcq) {
    return raw;
  }

  if (isNumericLike(raw)) {
    const idx = Math.trunc(Number(raw));

    if (opts && idx >= 0 && idx < opts.length) {
      const L = idxToLetter(idx);
      const txt = String(opts[idx] ?? "").trim();
      return txt ? `${L} — ${txt}` : (L || raw);
    }

    // ✅ для явного MCQ без options оставляем старое поведение: 0 -> A
    const L = idxToLetter(idx);
    if (L) return L;

    return raw;
  }

  if (opts) {
    const li = letterToIdx(raw);
    if (li !== null && li >= 0 && li < opts.length) {
      const L = raw.toUpperCase();
      const txt = String(opts[li] ?? "").trim();
      return txt ? `${L} — ${txt}` : L;
    }
  }

  return raw;
}
   
// --- Practice stage helpers + DB-first practice set builder ---
async function getPracticeStageContext(subjectKey) {
  if (!window.sb) return null;

  const subjectId = await getSubjectIdByKey(subjectKey);
  if (!subjectId) return null;

  const poolsRes = await window.sb
    .from("practice_pools")
    .select("id,subject_id,tour_no,title,is_active")
    .eq("subject_id", subjectId)
    .eq("is_active", true)
    .order("tour_no", { ascending: true });

  const pools = Array.isArray(poolsRes?.data) ? poolsRes.data : [];
  const maxPoolTourNo = Math.max(1, ...pools.map(p => Number(p?.tour_no || 0)).filter(Boolean), 1);

  const toursRes = await window.sb
    .from("tours")
    .select("id,tour_no,start_date,end_date,is_active")
    .eq("subject_id", subjectId)
    .order("tour_no", { ascending: true });

  const tours = Array.isArray(toursRes?.data) ? toursRes.data : [];
  const totalTours = tours.length;

  const pad2 = (n) => String(n).padStart(2, "0");
  const d0 = new Date();
  const todayISO = `${d0.getFullYear()}-${pad2(d0.getMonth() + 1)}-${pad2(d0.getDate())}`;

  const isInWindow = (row) => {
    const sd = row?.start_date ? String(row.start_date) : null;
    const ed = row?.end_date ? String(row.end_date) : null;
    const afterStart = !sd || sd <= todayISO;
    const beforeEnd = !ed || ed >= todayISO;
    return afterStart && beforeEnd;
  };

  const activeTour = tours
    .filter(t => !!t?.is_active && isInWindow(t))
    .sort((a, b) => Number(a?.tour_no || 0) - Number(b?.tour_no || 0))[0] || null;

  const globallyClosedCount = tours.filter(t => {
    const ed = t?.end_date ? String(t.end_date) : null;
    return !!ed && ed < todayISO;
  }).length;

  let practiceTourNo = 1;

  if (activeTour?.tour_no) {
    practiceTourNo = Number(activeTour.tour_no);
  } else if (totalTours > 0 && globallyClosedCount >= totalTours) {
    practiceTourNo = Math.min(maxPoolTourNo, totalTours);
  } else {
    practiceTourNo = Math.min(maxPoolTourNo, Math.max(1, globallyClosedCount + 1));
  }

  const poolRow =
    pools.find(p => Number(p?.tour_no || 0) === Number(practiceTourNo)) ||
    pools[0] ||
    null;

  return {
    subjectId,
    practiceTourNo: Number(poolRow?.tour_no || practiceTourNo || 1),
    poolId: Number(poolRow?.id || 0) || null,
    poolRow,
    pools,
    activeTourNo: activeTour?.tour_no ? Number(activeTour.tour_no) : null,
    globallyClosedCount,
    totalTours
  };
}

async function getPracticePoolQuestionIds(poolId) {
  if (!window.sb || !poolId) return [];

  const res = await window.sb
    .from("practice_pool_questions")
    .select("question_id,order_no")
    .eq("pool_id", Number(poolId))
    .eq("is_active", true)
    .order("order_no", { ascending: true });

  return (Array.isArray(res?.data) ? res.data : [])
    .map(r => Number(r?.question_id))
    .filter(Boolean);
}

async function getClosedPracticeQuestionIds(subjectId, uid, questionIds) {
  if (!window.sb || !subjectId || !uid || !Array.isArray(questionIds) || !questionIds.length) {
    return new Set();
  }

  const attemptsRes = await window.sb
    .from("practice_attempts")
    .select("id")
    .eq("user_id", uid)
    .eq("subject_id", subjectId);

  const attemptIds = (Array.isArray(attemptsRes?.data) ? attemptsRes.data : [])
    .map(x => Number(x?.id))
    .filter(Boolean);

  if (!attemptIds.length) return new Set();

  const answersRes = await window.sb
    .from("practice_answers")
    .select("question_id")
    .in("attempt_id", attemptIds)
    .in("question_id", questionIds)
    .eq("is_correct", true);

  return new Set(
    (Array.isArray(answersRes?.data) ? answersRes.data : [])
      .map(x => Number(x?.question_id))
      .filter(Boolean)
  );
}

function practiceStorageKey(subjectKey, practiceTourNo = 1) {
  return `practice_history_v2:${subjectKey}:tour_${Number(practiceTourNo || 1)}`;
}

function loadPracticeHistory(subjectKey, practiceTourNo = 1) {
  try {
    const raw = localStorage.getItem(practiceStorageKey(subjectKey, practiceTourNo));
    const parsed = raw ? JSON.parse(raw) : null;
    if (!parsed) return { best: null, last: [] };
    return {
      best: parsed.best || null,
      last: Array.isArray(parsed.last) ? parsed.last : []
    };
  } catch {
    return { best: null, last: [] };
  }
}

function savePracticeHistory(subjectKey, practiceTourNo = 1, data) {
  try {
    localStorage.setItem(
      practiceStorageKey(subjectKey, practiceTourNo),
      JSON.stringify(data)
    );
  } catch {}
}

function updatePracticeHistory(subjectKey, practiceTourNo, attempt) {
  const h = loadPracticeHistory(subjectKey, practiceTourNo);
  const last = [attempt, ...(h.last || [])].slice(0, PRACTICE_CONFIG.keepLastAttempts);

  let best = h.best;
  if (
    !best ||
    Number(attempt.percent) > Number(best.percent) ||
    (
      Number(attempt.percent) === Number(best.percent) &&
      Number(attempt.durationSec) < Number(best.durationSec)
    )
  ) {
    best = attempt;
  }

  savePracticeHistory(subjectKey, practiceTourNo, { best, last });
  return { best, last };
}

function loadAllPracticeHistoryBySubject(subjectKey) {
  const prefix = `practice_history_v2:${subjectKey}:tour_`;
  const allAttempts = [];

  try {
    for (let i = 0; i < localStorage.length; i++) {
      const key = localStorage.key(i);
      if (!key || !key.startsWith(prefix)) continue;

      const raw = localStorage.getItem(key);
      const parsed = raw ? JSON.parse(raw) : null;
      const last = Array.isArray(parsed?.last) ? parsed.last : [];
      allAttempts.push(...last);
    }
  } catch {}

  allAttempts.sort((a, b) => (Number(b?.ts) || 0) - (Number(a?.ts) || 0));

  let best = null;
  allAttempts.forEach(a => {
    if (
      !best ||
      Number(a?.percent) > Number(best?.percent) ||
      (
        Number(a?.percent) === Number(best?.percent) &&
        Number(a?.durationSec) < Number(best?.durationSec)
      )
    ) {
      best = a;
    }
  });

  return { best, last: allAttempts };
}

   function getSelectedPracticeTourNo(subjectKey, fallbackTourNo = 1) {
  try {
    const key = String(subjectKey || state?.courses?.subjectKey || "").trim();
    const saved = Number(state?.courses?.selectedPracticeTourNoBySubject?.[key] || 0);
    if (saved > 0) return saved;
  } catch {}

  return Math.max(1, Number(fallbackTourNo || 1) || 1);
}

function setSelectedPracticeTourNo(subjectKey, tourNo) {
  try {
    const key = String(subjectKey || state?.courses?.subjectKey || "").trim();
    const n = Math.max(1, Number(tourNo || 1) || 1);
    state.courses = state.courses || {};
    state.courses.selectedPracticeTourNoBySubject = state.courses.selectedPracticeTourNoBySubject || {};
    state.courses.selectedPracticeTourNoBySubject[key] = n;
    saveState();
  } catch {}
}

function getLocalTodayISO() {
  const d0 = new Date();
  const p = (n) => String(n).padStart(2, "0");
  return `${d0.getFullYear()}-${p(d0.getMonth() + 1)}-${p(d0.getDate())}`;
}

function isTourRowInWindow(row, todayISO = getLocalTodayISO()) {
  const sd = row?.start_date ? String(row.start_date) : null;
  const ed = row?.end_date ? String(row.end_date) : null;
  return (!sd || sd <= todayISO) && (!ed || ed >= todayISO);
}

async function getPracticeTourCards(subjectKey) {
  const ctx = await getPracticeStageContext(subjectKey).catch(() => null);
  const subjectId = Number(ctx?.subjectId || 0);
  const currentTourNo = Number(ctx?.practiceTourNo || 1) || 1;
  const pools = Array.isArray(ctx?.pools) ? ctx.pools : [];

  if (!subjectId || !pools.length) return { currentTourNo, selectedTourNo: currentTourNo, cards: [] };

  let tours = [];
  try {
    if (window.sb) {
      const { data, error } = await window.sb
        .from("tours")
        .select("id,tour_no,start_date,end_date,is_active")
        .eq("subject_id", subjectId)
        .order("tour_no", { ascending: true });

      if (!error && Array.isArray(data)) tours = data;
    }
  } catch {}

  const todayISO = getLocalTodayISO();
  const tourByNo = new Map(tours.map(r => [Number(r?.tour_no || 0), r]));

    const poolTourNos = pools
    .map(p => Number(p?.tour_no || 0))
    .filter(n => Number.isFinite(n) && n > 0);

  const dbTourNos = tours
    .map(t => Number(t?.tour_no || 0))
    .filter(n => Number.isFinite(n) && n > 0);

  const allTourNos = Array.from(new Set([...dbTourNos, ...poolTourNos]))
    .sort((a, b) => a - b);

  const rawCards = await Promise.all(
    allTourNos.map(async (tourNo) => {
      const tourRow = tourByNo.get(tourNo) || null;
      const hasPool = pools.some(p => Number(p?.tour_no || 0) === Number(tourNo));

      let stats = null;
      if (hasPool) {
        stats = await computePracticeStageStats(subjectKey, tourNo).catch(() => null);
      }

      let stateName = "available";

      if (tourRow) {
        if (tourRow?.is_active === true && isTourRowInWindow(tourRow, todayISO)) {
          stateName = "active";
        } else if (tourRow?.start_date && String(tourRow.start_date) > todayISO) {
          stateName = "locked";
        } else {
          stateName = "past";
        }
      } else {
        stateName = tourNo <= currentTourNo ? (tourNo === currentTourNo ? "active" : "past") : "locked";
      }

      const total = Number(stats?.totalCount || 0);
      const done = Number(stats?.masteredCount || 0);
      const open = Math.max(0, total - done);

      // В Practice замок означает только "ещё не опубликовано / будущий этап".
      // Нельзя блокировать прошедший тур только из-за total=0:
      // stats могут временно не успеть/не загрузиться, а сама практика при этом доступна.
      const locked = stateName === "locked" || !hasPool;

      return {
        tourNo,
        stateName,
        isLocked: locked,
        isActive: stateName === "active",
        isDone: total > 0 && done >= total,
        total,
        done,
        open,
        best: stats?.best || null,
        last: Array.isArray(stats?.last) ? stats.last : []
      };
    })
  );
  const selectedRaw = getSelectedPracticeTourNo(subjectKey, currentTourNo);
  const selectedCard = rawCards.find(c => c.tourNo === selectedRaw && !c.isLocked);
  const fallbackCard =
    rawCards.find(c => c.isActive && !c.isLocked) ||
    rawCards.find(c => !c.isLocked) ||
    rawCards[0];

  const selectedTourNo = Number(selectedCard?.tourNo || fallbackCard?.tourNo || currentTourNo || 1);
  setSelectedPracticeTourNo(subjectKey, selectedTourNo);

  return { currentTourNo, selectedTourNo, cards: rawCards };
}

   function updatePracticeStartButtonForTour(tourNo, canResume = false) {
  const restartBtn = $("#practice-restart-btn");
  const restartLabelEl = $("#practice-restart-label");
  if (!restartBtn) return;

  const n = Math.max(1, Number(tourNo || 1) || 1);

  const label = canResume
    ? (t("practice_restart") || "Начать заново")
    : (
        t("practice_start_for_tour", { n }) ||
        tr3(
          `Начать практику ${n} тура`,
          `${n}-tur amaliyotini boshlash`,
          `Start practice for Tour ${n}`
        )
      );

  restartBtn.textContent = "";

  if (restartLabelEl) {
    restartLabelEl.textContent = label;
    restartBtn.appendChild(restartLabelEl);
  } else {
    restartBtn.textContent = label;
  }
}

function renderPracticeTourPicker(cards, selectedTourNo) {
  const el = document.getElementById("practice-tour-picker");
  if (!el) return;

  if (!Array.isArray(cards) || !cards.length) {
    el.innerHTML = "";
    return;
  }

  el.innerHTML = `
    <div class="practice-tour-picker-head">
      <div class="practice-tour-picker-title">${escapeHTML(tr3("Выбор тура", "Tur tanlash", "Tour selection"))}</div>
    </div>

    <div class="practice-tour-chip-row" aria-label="${escapeHTML(tr3("Выбор тура", "Tur tanlash", "Tour selection"))}">
      ${cards.map(c => {
        const selected = Number(c.tourNo) === Number(selectedTourNo);

        const cls = [
          "practice-tour-chip",
          selected ? "is-selected" : "",
          c.isDone ? "is-completed" : "",
          (!c.isDone && c.isActive) ? "is-active" : "",
          (!c.isDone && !c.isActive && !c.isLocked) ? "is-not-started" : "",
          c.isLocked ? "is-locked" : ""
        ].filter(Boolean).join(" ");

        return `
          <button
            class="${cls}"
            type="button"
            ${c.isLocked ? "disabled aria-disabled=\"true\"" : `data-action="practice-select-tour" data-tour-no="${Number(c.tourNo)}"`}
          >
            <span class="practice-tour-chip-label">
              ${c.isLocked ? `<span class="practice-tour-chip-lock">🔒</span>` : ""}
              ${escapeHTML(tr3("Тур", "Tur", "Tour"))} ${Number(c.tourNo)}
            </span>
          </button>
        `;
      }).join("")}
    </div>
  `;
}
   
async function computePracticeStageStats(subjectKey, forcedTourNo = null) {
  const uid = await getAuthUid().catch(() => null);
  if (!uid) {
    return {
      practiceTourNo: Number(forcedTourNo || 1),
      poolId: null,
      totalCount: 0,
      masteredCount: 0,
      openCount: 0,
      best: null,
      last: []
    };
  }

  const ctx = await getPracticeStageContext(subjectKey);
  if (!ctx?.subjectId) {
    return {
      practiceTourNo: Number(forcedTourNo || 1),
      poolId: null,
      totalCount: 0,
      masteredCount: 0,
      openCount: 0,
      best: null,
      last: []
    };
  }

  let poolId = ctx.poolId;
  let practiceTourNo = ctx.practiceTourNo;

  if (forcedTourNo != null) {
    const row = (Array.isArray(ctx.pools) ? ctx.pools : []).find(
      p => Number(p?.tour_no || 0) === Number(forcedTourNo)
    );
    if (row) {
      poolId = Number(row.id || 0) || null;
      practiceTourNo = Number(row.tour_no || forcedTourNo || 1);
    }
  }

  const allIds = await getPracticePoolQuestionIds(poolId);
  const closedIds = await getClosedPracticeQuestionIds(ctx.subjectId, uid, allIds);

  const totalCount = allIds.length;
  const masteredCount = Array.from(closedIds).length;
  const openCount = Math.max(0, totalCount - masteredCount);

  const h = loadPracticeHistory(subjectKey, practiceTourNo);

  return {
    practiceTourNo,
    poolId,
    totalCount,
    masteredCount,
    openCount,
    best: h?.best || null,
    last: Array.isArray(h?.last) ? h.last : []
  };
}

async function buildPracticeSet(subjectKey) {
  if (!window.sb) return [];

  const uid = await getAuthUid();
  if (!uid) return [];

  const ctx = await getPracticeStageContext(subjectKey);
  if (!ctx?.subjectId || !ctx?.poolId) return [];

  const allQuestionIds = await getPracticePoolQuestionIds(ctx.poolId);
  if (!allQuestionIds.length) return [];

  const closedIds = await getClosedPracticeQuestionIds(ctx.subjectId, uid, allQuestionIds);
  const questionIds = allQuestionIds.filter(id => !closedIds.has(Number(id)));

  if (!questionIds.length) return [];

  const { data, error } = await window.sb
    .from("questions")
    .select("id, topic, subtopic, difficulty, time_limit_sec, qtype, question_text, options_text, correct_answer, explanation, image_url, is_active, book_ref, question_text_ru, question_text_uz, question_text_en, options_text_ru, options_text_uz, options_text_en, explanation_ru, explanation_uz, explanation_en")
    .eq("subject_id", ctx.subjectId)
    .eq("is_active", true)
    .in("id", questionIds)
    .limit(300);

  if (error) {
    await logDbErrorToEvents(uid, "practice_questions_select", error, {
      subject_id: ctx.subjectId,
      subject_key: subjectKey,
      practice_tour_no: ctx.practiceTourNo
    });
    return [];
  }

  const poolRaw = Array.isArray(data) ? data : [];
  if (!poolRaw.length) return [];

  const normalizeType = (t) => (String(t || "mcq").toLowerCase() === "input" ? "input" : "mcq");

  const contentLang = (loadProfile()?.language) || "ru";
  const pickL = (obj, base) => {
    const k = contentLang === "uz" ? (base + "_uz") : contentLang === "en" ? (base + "_en") : (base + "_ru");
    return (obj && obj[k] != null && String(obj[k]).trim() !== "") ? obj[k] : obj[base];
  };

  const orderMap = new Map(allQuestionIds.map((id, idx) => [Number(id), idx]));

  const pool = poolRaw
    .map(r => {
      const type = normalizeType(r.qtype);
      const diff = normalizeDifficulty(r.difficulty || "easy");

      const optionsRaw = pickL(r, "options_text");
      const opts = type === "mcq" ? (parseOptionsText(optionsRaw) || []) : [];

      let correctIndex = 0;
      if (type === "mcq") {
        const ca = String(r.correct_answer ?? "").trim();
        const asInt = Number(ca);

        if (!Number.isNaN(asInt) && Number.isFinite(asInt)) {
          correctIndex = asInt;
        } else if (/^[A-D]$/i.test(ca)) {
          correctIndex = ca.toUpperCase().charCodeAt(0) - "A".charCodeAt(0);
        } else if (opts.length) {
          const idx = opts.findIndex(x => String(x).trim().toLowerCase() === ca.toLowerCase());
          if (idx >= 0) correctIndex = idx;
        }

        if (!Number.isFinite(correctIndex) || correctIndex < 0) correctIndex = 0;
      }

      const correctAnswer = type === "input" ? String(r.correct_answer ?? "").trim() : "";

      return {
        id: Number(r.id),
        topic: r.topic || "General",
        subtopic: r.subtopic || null,
        difficulty: diff,
        timeLimitSec:
          (r.time_limit_sec != null && Number(r.time_limit_sec) >= 10)
            ? Number(r.time_limit_sec)
            : (PRACTICE_CONFIG?.timeByDifficulty?.[diff] || 60),
        type,
        question: pickL(r, "question_text") || "",
        options: opts || [],
        correctIndex,
        correctAnswer,
        explanation: pickL(r, "explanation") || "",
        imageUrl: r.image_url || null,
        book_ref: r.book_ref || null,
        bookReference: r.book_ref || null,
        inputKind: type === "input" ? (parseFlexibleScientificNumber(correctAnswer) !== null ? "numeric" : "text") : null, 
        inputHint: type === "input" ? inputHintForAnswer(correctAnswer) : "",
        practiceTourNo: Number(ctx.practiceTourNo || 1),
        practicePoolId: Number(ctx.poolId || 0) || null
      };
    })
    .filter(q => Number.isFinite(q.id))
    .sort((a, b) => {
      const ao = orderMap.get(Number(a?.id)) ?? 999999;
      const bo = orderMap.get(Number(b?.id)) ?? 999999;
      return ao - bo;
    });

  if (!pool.length) return [];

  const usedIds = new Set();
  const by = {
    easy: pool.filter(q => q.difficulty === "easy"),
    medium: pool.filter(q => q.difficulty === "medium"),
    hard: pool.filter(q => q.difficulty === "hard")
  };

  const set = [];
  set.push(...pickN(by.easy, PRACTICE_CONFIG.dist.easy, usedIds));
  set.push(...pickN(by.medium, PRACTICE_CONFIG.dist.medium, usedIds));
  set.push(...pickN(by.hard, PRACTICE_CONFIG.dist.hard, usedIds));

  if (set.length < PRACTICE_CONFIG.total) {
    set.push(...pickN(pool, PRACTICE_CONFIG.total - set.length, usedIds));
  }

  const order = { easy: 1, medium: 2, hard: 3 };
  set.sort((a, b) => (order[a.difficulty] - order[b.difficulty]));

  return set.slice(0, PRACTICE_CONFIG.total);
}

   async function buildPracticeSetForTour(subjectKey, forcedTourNo) {
  if (!window.sb) return [];

  const uid = await getAuthUid().catch(() => null);
  if (!uid) return [];

  const ctx = await getPracticeStageContext(subjectKey);
  if (!ctx?.subjectId) return [];

  const row = (Array.isArray(ctx.pools) ? ctx.pools : []).find(
    p => Number(p?.tour_no || 0) === Number(forcedTourNo)
  );

  const poolId = Number(row?.id || 0) || null;
  const practiceTourNo = Number(row?.tour_no || forcedTourNo || 1);

  if (!poolId) return [];

  const allQuestionIds = await getPracticePoolQuestionIds(poolId);
  if (!allQuestionIds.length) return [];

  const closedIds = await getClosedPracticeQuestionIds(ctx.subjectId, uid, allQuestionIds);
  const questionIds = allQuestionIds.filter(id => !closedIds.has(Number(id)));

  if (!questionIds.length) return [];

  const { data, error } = await window.sb
    .from("questions")
    .select("id, topic, subtopic, difficulty, time_limit_sec, qtype, question_text, options_text, correct_answer, explanation, image_url, is_active, book_ref, question_text_ru, question_text_uz, question_text_en, options_text_ru, options_text_uz, options_text_en, explanation_ru, explanation_uz, explanation_en")
    .eq("subject_id", ctx.subjectId)
    .eq("is_active", true)
    .in("id", questionIds)
    .limit(300);

  if (error) return [];

  const poolRaw = Array.isArray(data) ? data : [];
  if (!poolRaw.length) return [];

  const normalizeType = (v) => (String(v || "mcq").toLowerCase() === "input" ? "input" : "mcq");

  const contentLang = (loadProfile()?.language) || "ru";
  const pickL = (obj, base) => {
    const k = contentLang === "uz" ? (base + "_uz") : contentLang === "en" ? (base + "_en") : (base + "_ru");
    return (obj && obj[k] != null && String(obj[k]).trim() !== "") ? obj[k] : obj[base];
  };

  const orderMap = new Map(allQuestionIds.map((id, idx) => [Number(id), idx]));

  const pool = poolRaw
    .map(r => {
      const type = normalizeType(r.qtype);
      const diff = normalizeDifficulty(r.difficulty || "easy");

      const optionsRaw = pickL(r, "options_text");
      const opts = type === "mcq" ? (parseOptionsText(optionsRaw) || []) : [];

      let correctIndex = 0;
      if (type === "mcq") {
        const ca = String(r.correct_answer ?? "").trim();
        const asInt = Number(ca);

        if (!Number.isNaN(asInt) && Number.isFinite(asInt)) {
          correctIndex = asInt;
        } else if (/^[A-D]$/i.test(ca)) {
          correctIndex = ca.toUpperCase().charCodeAt(0) - "A".charCodeAt(0);
        } else if (opts.length) {
          const idx = opts.findIndex(x => String(x).trim().toLowerCase() === ca.toLowerCase());
          if (idx >= 0) correctIndex = idx;
        }

        if (!Number.isFinite(correctIndex) || correctIndex < 0) correctIndex = 0;
      }

      const correctAnswer = type === "input" ? String(r.correct_answer ?? "").trim() : "";

      return {
        id: Number(r.id),
        topic: r.topic || "General",
        subtopic: r.subtopic || null,
        difficulty: diff,
        timeLimitSec:
          (r.time_limit_sec != null && Number(r.time_limit_sec) >= 10)
            ? Number(r.time_limit_sec)
            : (PRACTICE_CONFIG?.timeByDifficulty?.[diff] || 60),
        type,
        question: pickL(r, "question_text") || "",
        options: opts || [],
        correctIndex,
        correctAnswer,
        explanation: pickL(r, "explanation") || "",
        imageUrl: r.image_url || null,
        book_ref: r.book_ref || null,
        bookReference: r.book_ref || null,
        inputKind: type === "input" ? (parseFlexibleScientificNumber(correctAnswer) !== null ? "numeric" : "text") : null,
        inputHint: type === "input" ? inputHintForAnswer(correctAnswer) : "",
        practiceTourNo,
        practicePoolId: poolId,
        orderNo: orderMap.get(Number(r.id)) ?? 999999
      };
    })
    .filter(q => Number.isFinite(q.id));

  if (!pool.length) return [];

  const usedIds = new Set();
  const by = {
    easy: pool.filter(q => q.difficulty === "easy"),
    medium: pool.filter(q => q.difficulty === "medium"),
    hard: pool.filter(q => q.difficulty === "hard")
  };

  const set = [];
  set.push(...pickN(by.easy, PRACTICE_CONFIG.dist.easy, usedIds));
  set.push(...pickN(by.medium, PRACTICE_CONFIG.dist.medium, usedIds));
  set.push(...pickN(by.hard, PRACTICE_CONFIG.dist.hard, usedIds));

  if (set.length < PRACTICE_CONFIG.total) {
    set.push(...pickN(pool, PRACTICE_CONFIG.total - set.length, usedIds));
  }

  const order = { easy: 1, medium: 2, hard: 3 };
  set.sort((a, b) => {
    const byTour = Number(a.practiceTourNo || 0) - Number(b.practiceTourNo || 0);
    if (byTour !== 0) return byTour;
    const byDiff = (order[a.difficulty] || 9) - (order[b.difficulty] || 9);
    if (byDiff !== 0) return byDiff;
    return Number(a.orderNo || 0) - Number(b.orderNo || 0);
  });

  return set.slice(0, PRACTICE_CONFIG.total);
}

async function getPastPracticeTourNos(subjectKey) {
  const ctx = await getPracticeStageContext(subjectKey);
  const currentTourNo = Number(ctx?.practiceTourNo || 1);

  return (Array.isArray(ctx?.pools) ? ctx.pools : [])
    .map(p => Number(p?.tour_no || 0))
    .filter(n => Number.isFinite(n) && n > 0 && n < currentTourNo)
    .sort((a, b) => a - b);
}

async function computePastPracticeStats(subjectKey) {
  const uid = await getAuthUid().catch(() => null);
  const ctx = await getPracticeStageContext(subjectKey);

  if (!uid || !ctx?.subjectId) {
    return { tourNos: [], totalCount: 0, masteredCount: 0, openCount: 0 };
  }

  const tourNos = await getPastPracticeTourNos(subjectKey);
  if (!tourNos.length) {
    return { tourNos: [], totalCount: 0, masteredCount: 0, openCount: 0 };
  }

  const poolRows = (Array.isArray(ctx.pools) ? ctx.pools : []).filter(
    p => tourNos.includes(Number(p?.tour_no || 0))
  );

  const allIdsNested = await Promise.all(
    poolRows.map(p => getPracticePoolQuestionIds(Number(p?.id || 0) || 0))
  );

  const allIds = Array.from(new Set(allIdsNested.flat().map(Number).filter(Boolean)));
  const closedIds = await getClosedPracticeQuestionIds(ctx.subjectId, uid, allIds);

  const totalCount = allIds.length;
  const masteredCount = Array.from(closedIds).length;
  const openCount = Math.max(0, totalCount - masteredCount);

  return { tourNos, totalCount, masteredCount, openCount };
}

async function buildPastPracticeSet(subjectKey) {
  const tourNos = await getPastPracticeTourNos(subjectKey);
  if (!tourNos.length) return [];

  const sets = await Promise.all(
    tourNos.map(tourNo => buildPracticeSetForTour(subjectKey, tourNo))
  );

  const merged = [];
  const usedIds = new Set();

  sets.forEach(arr => {
    (Array.isArray(arr) ? arr : []).forEach(q => {
      const qid = Number(q?.id || 0);
      if (!qid || usedIds.has(qid)) return;
      usedIds.add(qid);
      merged.push(q);
    });
  });

  if (!merged.length) return [];

  const order = { easy: 1, medium: 2, hard: 3 };
  merged.sort((a, b) => {
    const byTour = Number(a.practiceTourNo || 0) - Number(b.practiceTourNo || 0);
    if (byTour !== 0) return byTour;
    const byDiff = (order[a.difficulty] || 9) - (order[b.difficulty] || 9);
    if (byDiff !== 0) return byDiff;
    return Number(a.orderNo || 0) - Number(b.orderNo || 0);
  });

  return merged.slice(0, PRACTICE_CONFIG.total);
}
   
function formatDateTime(ts) {
    try {
      const d = new Date(ts);
      return d.toLocaleString();
    } catch {
      return "";
    }
  }

        function isValidInputAnswer(q, value) {
    const v = String(value ?? "").trim();
    if (!v) return false;

    const expected = getInputExpectedAnswer(q);
    const expectedIsNumeric = parseStrictNumberAnswer(expected) !== null;

       if (q?.inputKind === "numeric" || expectedIsNumeric) {
      return parseStrictNumberAnswer(v) !== null && hasAllowedNumericSign(v, expected);
    }

    if (q?.inputKind === "letter") {
      // ровно 1 буква, запрещаем a/b/c/d (чтобы не путали с MCQ)
      if (!/^[A-Za-zА-Яа-я]$/.test(v)) return false;
      const low = v.toLowerCase();
      if (low === "a" || low === "b" || low === "c" || low === "d") return false;
      return true;
    }

    if (isFormulaLikeExpectedAnswer(expected)) {
      // Formula/token input must be compact: no spaces, no subscripts.
      if (/[₀₁₂₃₄₅₆₇₈₉]/.test(v)) return false;
      if (/\s/.test(v)) return false;
      return /^[A-Za-z][A-Za-z0-9]*$/.test(v);
    }

    return true;
  }
   // ---------------------------
  // Regions / Districts
  // - Uses Supabase if available (regions/districts tables)
  // - Falls back to local demo map
  // ---------------------------
  const REGIONS = {
    "Tashkent": ["Chilonzor", "Yunusobod", "Mirzo Ulug‘bek", "Shaykhontohur", "Yakkasaroy"],
    "Samarkand": ["Samarkand city", "Urgut", "Kattakurgan", "Payariq"],
    "Fergana": ["Fergana city", "Margilan", "Kokand", "Quva"],
    "Andijan": ["Andijan city", "Asaka", "Shahrixon", "Xo‘jaobod"],
    "Bukhara": ["Bukhara city", "G‘ijduvon", "Kogon", "Vobkent"]
  };

  function fillSelectOptions(selectEl, options, placeholder) {
    if (!selectEl) return;

    selectEl.innerHTML = "";

    const ph = document.createElement("option");
    ph.value = "";
    ph.disabled = true;
    ph.selected = true;
    ph.textContent = placeholder;
    selectEl.appendChild(ph);

    options.forEach(v => {
      const o = document.createElement("option");
      o.value = String(v);
      o.textContent = String(v);
      selectEl.appendChild(o);
    });
  }

  function fillSelectOptionsKV(selectEl, options, placeholder) {
    // options: [{value, label}]
    if (!selectEl) return;

    selectEl.innerHTML = "";

    const ph = document.createElement("option");
    ph.value = "";
    ph.disabled = true;
    ph.selected = true;
    ph.textContent = placeholder;
    selectEl.appendChild(ph);

    options.forEach(it => {
      const o = document.createElement("option");
      o.value = String(it.value);
      o.textContent = String(it.label);
      selectEl.appendChild(o);
    });
  }

    function refreshRegionDistrictPlaceholders() {
    const regionEl = $("#reg-region");
    const districtEl = $("#reg-district");
    if (!regionEl || !districtEl) return;

    // update placeholder texts (first option)
    if (regionEl.options?.length) {
      const opt0 = regionEl.options[0];
      if (opt0 && opt0.value === "") opt0.textContent = t("reg_select_region") || "Выберите регион…";
    }

    if (districtEl.options?.length) {
      const opt0 = districtEl.options[0];
      if (opt0 && opt0.value === "") {
        opt0.textContent = districtEl.disabled
          ? (t("reg_select_region_first") || "Сначала выберите регион…")
          : (t("reg_select_district") || "Выберите район…");
      }
    }
  }

  function refreshRegionDistrictOptionLabels() {
    const regionEl = $("#reg-region");
    const districtEl = $("#reg-district");
    if (!regionEl || !districtEl) return;

    const lang = (window.i18n?.getLang ? window.i18n.getLang() : "ru");

    const pick = (opt) => {
      if (!opt) return "";
      if (lang === "uz") return opt.dataset.uz || opt.dataset.ru || opt.textContent || "";
      if (lang === "en") return opt.dataset.en || opt.dataset.ru || opt.textContent || "";
      return opt.dataset.ru || opt.textContent || "";
    };

    // skip placeholder (index 0)
    for (let i = 1; i < regionEl.options.length; i++) {
      const o = regionEl.options[i];
      o.textContent = String(pick(o)).trim();
    }
    for (let i = 1; i < districtEl.options.length; i++) {
      const o = districtEl.options[i];
      o.textContent = String(pick(o)).trim();
    }
  }

  async function initRegionDistrictUI() {
    const regionEl = $("#reg-region");
    const districtEl = $("#reg-district");
    if (!regionEl || !districtEl) return;

    // prevent double-binding
    if (regionEl.dataset.bound === "1") {
      refreshRegionDistrictPlaceholders();
      refreshRegionDistrictOptionLabels();
      return;
    }
    regionEl.dataset.bound = "1";

    // initial state
    districtEl.disabled = true;
    regionEl.innerHTML = "";
    districtEl.innerHTML = "";

    // placeholders
    const regPh = document.createElement("option");
    regPh.value = "";
    regPh.disabled = true;
    regPh.selected = true;
    regPh.textContent = t("reg_select_region") || "Выберите регион…";
    regionEl.appendChild(regPh);

    const distPh = document.createElement("option");
    distPh.value = "";
    distPh.disabled = true;
    distPh.selected = true;
    distPh.textContent = t("reg_select_region_first") || "Сначала выберите регион…";
    districtEl.appendChild(distPh);

        // DB only
    if (!window.sb) {
      try { await initSupabaseSession(); } catch {}
    }
    if (!window.sb) {
      showToast(t("toast_supabase_not_ready"));
      return;
    }

    // ---------------------------
    // Geo cache (TTL)
    // ---------------------------
    const GEO_TTL_MS = 7 * 24 * 60 * 60 * 1000;

    const geoCacheGet = (key) => {
      try {
        const raw = localStorage.getItem(key);
        if (!raw) return null;
        const obj = JSON.parse(raw);
        if (!obj || !obj.data || !obj.updated_at) return null;
        if ((Date.now() - Number(obj.updated_at)) > GEO_TTL_MS) return null;
        return obj.data;
      } catch {
        return null;
      }
    };

    const geoCacheSet = (key, data) => {
      try {
        localStorage.setItem(key, JSON.stringify({ updated_at: Date.now(), data }));
      } catch {}
    };
     
    const langCode = (window.i18n?.getLang ? window.i18n.getLang() : "ru");
    const nameField = langCode === "uz" ? "name_uz" : (langCode === "en" ? "name_en" : "name_ru");

                const regionsCacheKey = "geo_regions_v1";
    let regions = geoCacheGet(regionsCacheKey);

    if (!Array.isArray(regions) || regions.length === 0) {
      showAsyncOverlay(tr3(
        "Загружаем регионы…",
        "Hududlar yuklanmoqda…",
        "Loading regions…"
      ));

      try {
        const res = await window.sb
          .from("regions")
          .select(`id, name_ru, name_uz, name_en`)
          .order("name_ru", { ascending: true });

        if (res?.error || !Array.isArray(res?.data) || res.data.length === 0) {
          showToast(t("toast_no_regions_in_db"));
          return;
        }

        regions = res.data;
        geoCacheSet(regionsCacheKey, regions);
      } finally {
        hideAsyncOverlay();
      }
    }

        regions.forEach(r => {
      const o = document.createElement("option");
      o.value = String(r.id);

      o.dataset.ru = String(r?.name_ru || "").trim();
      o.dataset.uz = String(r?.name_uz || "").trim();
      o.dataset.en = String(r?.name_en || "").trim();

      o.textContent = String(r?.[nameField] || r?.name_ru || "").trim();
      regionEl.appendChild(o);
    });
      // ensure labels match current UI language (in case user switched language while loading)
    refreshRegionDistrictOptionLabels();

    regionEl.addEventListener("change", async () => {
      const regionId = regionEl.value ? Number(regionEl.value) : null;

      districtEl.disabled = true;
      districtEl.innerHTML = "";

      const ph = document.createElement("option");
      ph.value = "";
      ph.disabled = true;
      ph.selected = true;
      ph.textContent = t("reg_loading_districts");
      districtEl.appendChild(ph);

      if (!regionId) {
        refreshRegionDistrictPlaceholders();
        return;
      }

                         const dCacheKey = `geo_districts_v1_${regionId}`;
      let rows = geoCacheGet(dCacheKey);

      if (!Array.isArray(rows)) rows = [];

      if (rows.length === 0) {
        showAsyncOverlay(tr3(
          "Загружаем районы…",
          "Tumanlar yuklanmoqda…",
          "Loading districts…"
        ));

        try {
          const res = await window.sb
            .from("districts")
            .select("id, region_id, name_ru, name_uz, name_en")
            .eq("region_id", regionId)
            .order("name_ru", { ascending: true });

          rows = (!res?.error && Array.isArray(res?.data)) ? res.data : [];
          if (rows.length) geoCacheSet(dCacheKey, rows);
        } finally {
          hideAsyncOverlay();
        }
      }

      districtEl.innerHTML = "";
      const ph2 = document.createElement("option");
      ph2.value = "";
      ph2.disabled = true;
      ph2.selected = true;
      ph2.textContent = rows.length ? t("reg_select_district") : t("reg_no_districts");
      districtEl.appendChild(ph2);

      if (!rows.length) {
        districtEl.disabled = true;
        return;
      }

            rows.forEach(d => {
        const o = document.createElement("option");
        o.value = String(d.id);

        o.dataset.ru = String(d?.name_ru || "").trim();
        o.dataset.uz = String(d?.name_uz || "").trim();
        o.dataset.en = String(d?.name_en || "").trim();

        o.textContent = String(d?.[nameField] || d?.name_ru || "").trim();
        districtEl.appendChild(o);
      });

      // ensure labels match current UI language
      refreshRegionDistrictOptionLabels();

      districtEl.disabled = false;
    });
  }

  // ---------------------------
  // UI: Views & Tabs
  // ---------------------------
    const VIEWS = [
    "splash",
    "registration",
    "home",
    "courses",
    "ratings",
    "profile",
    // Global screens
    "resources",
    "news",
    "notifications",
    "community",
    "about",
    "support",
    "support-topic",
    "certificates",
    "certificate-verify",
    "archive"
  ];

    function showView(viewName) {
  const currentActive = document.querySelector(".view.is-active");
  const currentViewName = currentActive?.dataset?.view || "";
  const isSplashToRegistration = currentViewName === "splash" && viewName === "registration";

  if (viewName !== "splash" && !isSplashToRegistration) {
    showViewTransitionOverlay();
  }

  VIEWS.forEach(v => {
    const el = $(`#view-${v}`);
    if (!el) return;
    el.classList.toggle("is-active", v === viewName);
  });

  updateTopbarForView(viewName);

  const target = document.getElementById(`view-${viewName}`);
  if (!target) return;

  const jumpToTargetTop = () => {
    const mainEl = document.getElementById("main");
    if (mainEl) mainEl.scrollTop = 0;

    document.documentElement.scrollTop = 0;
    document.body.scrollTop = 0;

    try {
      target.scrollIntoView({ block: "start", inline: "nearest" });
    } catch (e) {
      target.scrollIntoView(true);
    }
  };

  // ✅ для splash → registration не делаем отложенный принудительный jump
  if (isSplashToRegistration) {
    const mainEl = document.getElementById("main");
    if (mainEl) mainEl.scrollTop = 0;
    document.documentElement.scrollTop = 0;
    document.body.scrollTop = 0;
    return;
  }

  setTimeout(jumpToTargetTop, 10);
}

  function setTab(tabName) {
    if (!["home", "courses", "ratings", "profile"].includes(tabName)) tabName = "home";
    const prevTab = state.tab;
    if (prevTab && prevTab !== tabName) {
      state.prevTab = prevTab;
      if (tabName === "courses") state.courses.entryTab = prevTab;
    }
     state.tab = tabName;
    saveState();

    // Tabbar active
    $$(".tabbar .tab").forEach(btn => {
      btn.classList.toggle("is-active", btn.dataset.tab === tabName);
    });

        // Maintain global view stack: tab screen becomes "base"
    setGlobalBaseView(tabName);

    // ✅ При уходе из Profile снимаем липкое состояние внутренних profile-screen,
    // чтобы hidden Profile не перехватывал generic back в других табах.
    if (tabName !== "profile") {
      document.querySelectorAll("#view-profile .profile-screen").forEach(el => {
        el.classList.remove("is-active");
        el.hidden = true;
        el.style.display = "none";
      });
    }

    if (tabName === "courses") {
  renderCoursesStack();
}
if (tabName === "profile") {
  renderProfileStack();
}
if (tabName === "ratings") {
  // ✅ show loader immediately (before async boot/selects)
  try {
    const loadingEl = document.getElementById("ratings-loading");
    if (loadingEl) loadingEl.style.display = "flex";
  } catch {}

  renderRatings();
}
}

  function setGlobalBaseView(tabName) {
    // base view should be one of: home/courses/ratings/profile
    if (!["home", "courses", "ratings", "profile"].includes(tabName)) tabName = "home";
    state.viewStack = [tabName];
    saveState();
    showView(tabName);
  }

  function openGlobal(viewName) {
  if (!VIEWS.includes(viewName)) return;

  if (state.quizLock === "tour") {
    showToast(t("toast_tour_in_progress"));
    return;
  }
  if (state.quizLock === "practice") {
    showToast(t("toast_pause_practice_to_leave"));
    return;
  }

  if (!Array.isArray(state.viewStack) || state.viewStack.length === 0) {
    state.viewStack = [state.tab || "home"];
  }

  const top = state.viewStack[state.viewStack.length - 1];
  if (top === viewName) {
    showView(viewName);

        if (viewName === "notifications") {
      renderNotificationsView();
    }

    if (viewName === "about") {
      renderAboutView();
    }

    if (viewName === "support") {
      renderSupportView();
    }

    if (viewName === "support-topic") {
      renderSupportTopicView();
    }

    if (viewName === "certificates") {
      (async () => {
        await renderCertificatesView();
      })();
    }

    return;
  }

  state.viewStack.push(viewName);
  saveState();

  showView(viewName);

  if (viewName === "archive") renderArchiveView();
      if (viewName === "notifications") {
      renderNotificationsView();
    }

    if (viewName === "about") {
      renderAboutView();
    }

    if (viewName === "support") {
      renderSupportView();
    }

    if (viewName === "support-topic") {
      renderSupportTopicView();
    }

    if (viewName === "certificates") {
      (async () => {
        await renderCertificatesView();
      })();
    }
}

  function canGlobalBack() {
    return Array.isArray(state.viewStack) && state.viewStack.length > 1;
  }

  function globalBack() {
    if (!canGlobalBack()) return;
    state.viewStack.pop();
    saveState();
    const top = state.viewStack[state.viewStack.length - 1];
    showView(top);
  }

  // ---------------------------
  // Topbar behavior
  // ---------------------------
  function updateTopbarForView(viewName) {
const topbarEl = $("#topbar");
const backBtn = $("#topbar-back");
const titleEl = $("#topbar-title");
const subEl = $("#topbar-subtitle");
const logoEl = $("#topbar-logo");
const notifBtn = $("#topbar-notifications");
const actionBtn = $("#topbar-action");

if (!backBtn || !titleEl || !subEl) return;

// ✅ Splash/Loading: topbar и tabbar не показываем вообще
const tabbarEl = $("#tabbar");

if (topbarEl) {
  if (viewName === "splash") {
    topbarEl.style.display = "none";
    if (tabbarEl) tabbarEl.style.display = "none";
    return;
  }
  topbarEl.style.display = ""; // вернуть дефолт (grid из CSS)
}

if (tabbarEl) tabbarEl.style.display = ""; // вернуть таббар после splash

// лого теперь не прячем
if (logoEl) logoEl.style.display = "block";

// notif по умолчанию скрыт (ВАЖНО: display, чтобы не резервировать место справа)
if (notifBtn) {
  notifBtn.style.display = "none";
  notifBtn.style.visibility = "hidden"; // ✅ важно: index.html имеет inline visibility:hidden
  notifBtn.dataset.action = "open-notifications";
}

// action по умолчанию скрыт (ВАЖНО: display, чтобы не резервировать место справа)
if (actionBtn) {
  actionBtn.style.display = "none";
  actionBtn.style.visibility = "hidden"; // ✅ index.html тоже имеет inline visibility:hidden
  actionBtn.dataset.action = "topbar-action";
  const icon = actionBtn.querySelector(".icon");
  if (icon) icon.textContent = "⋯";
}

    // Default
    titleEl.textContent = t("app_name");
    subEl.textContent = "Smarter together";
    backBtn.style.visibility = "hidden";

     // ✅ sync: если back скрыт — двигаем бренд на место кнопки (CSS .topbar.is-no-left уже есть)
   function syncTopbarLeftState() {
  if (!topbarEl || !backBtn) return;

  // ✅ 1) сначала снимаем "липкий" класс, чтобы back мог вернуться из display:none!important
  topbarEl.classList.remove("is-no-left");
  backBtn.style.display = ""; // вернём дефолтный display кнопки (inline-flex из CSS)

  // ✅ 2) решаем по ЯВНО установленному visibility (а не computedStyle, которое ломается из-за is-no-left)
  const shouldNoLeft = (backBtn.style.visibility === "hidden");

  topbarEl.classList.toggle("is-no-left", shouldNoLeft);
}

       if (viewName === "splash") {
     titleEl.textContent = t("app_name");
     syncTopbarLeftState();
     return;
   }

       if (viewName === "registration") {
  // ✅ Topbar как везде
  titleEl.textContent = t("app_name");
  subEl.textContent = "Smarter together";

  // ✅ Back показываем: он закрывает апп (bindTopbar уже делает close на registration)
  backBtn.style.visibility = "visible";

  // ✅ На регистрации нижний таббар не показываем вообще
  if (tabbarEl) tabbarEl.style.display = "none";

  syncTopbarLeftState();
  return;
}

     // применяем для default-состояния
     syncTopbarLeftState();

        if (viewName === "certificate-verify") {
    titleEl.textContent = t("certificate_verify_title");
  subEl.textContent = t("certificate_verify_sub");
  backBtn.style.visibility = "hidden";
  if (tabbarEl) tabbarEl.style.display = "none";
  syncTopbarLeftState();
  return;
}

            // Global screens (resources/news/...)
    if (["resources", "news", "notifications", "community", "about", "support", "support-topic", "certificates", "archive"].includes(viewName)) {
  const certViewerOpened =
    viewName === "certificates" && Number(state?.certificates?.selectedId || 0) > 0;

  backBtn.style.visibility = (certViewerOpened || canGlobalBack()) ? "visible" : "hidden";

  if (certViewerOpened) {
    titleEl.textContent = t("certificates_title") || "Сертификаты";
    subEl.textContent = t("certificates_sub") || "";
  } else {
    titleEl.textContent = t("app_name");
    subEl.textContent = "Smarter together";
  }

  syncTopbarLeftState();
  return;
}

        if (viewName === "home") {
  titleEl.textContent = t("app_name");
  subEl.textContent = "Smarter together";
  backBtn.style.visibility = "hidden";
  if (logoEl) logoEl.style.display = "block";

  if (notifBtn) {
    notifBtn.style.display = "inline-flex";
    notifBtn.style.visibility = "visible"; // ✅ иначе остаётся hidden из index.html
    refreshNotificationsBadge();
  }

  syncTopbarLeftState();
  return;
}

    if (viewName === "ratings") {
  titleEl.textContent = t("app_name");
  subEl.textContent = "Smarter together";
  backBtn.style.visibility = "hidden";
  syncTopbarLeftState();
  return;
}

    if (viewName === "profile") {
  const top = getProfileTopScreen();

  // В topbar всегда бренд
  titleEl.textContent = t("app_name");
  subEl.textContent = "Smarter together";

  // Back показываем только в settings (и он будет работать через action="back")
  backBtn.style.visibility = (top === "settings") ? "visible" : "hidden";

  // Шестерёнка в topbar справа — только на главном экране профиля
  if (actionBtn) {
    if (top === "main") {
      actionBtn.style.display = "inline-flex";
      actionBtn.style.visibility = "visible";
      actionBtn.dataset.action = "profile-settings";
      const icon = actionBtn.querySelector(".icon");
      if (icon) icon.textContent = "⚙";
    } else {
      actionBtn.style.display = "none";
      actionBtn.style.visibility = "hidden";
    }
  }
   syncTopbarLeftState();
   return;
 }

       if (viewName === "courses") {
     const canGoBack = canCoursesBack();
     backBtn.style.visibility = (state.quizLock ? "hidden" : (canGoBack ? "visible" : "hidden"));

     // ✅ Рядом с лого всегда бренд как на Home/Profile
     titleEl.textContent = t("app_name");
     subEl.textContent = "Smarter together";
     syncTopbarLeftState();
     return;
   }
}

// ---------------------------
// Ratings (Leaderboard) — UI skeleton now, DB later
// ---------------------------
const ratingsState = {
  scope: state?.ratings?.scope || "district", // district | region | country
  q: "",
  subjectId: state?.ratings?.subjectId || null,
  tourId: state?.ratings?.tourId || "__all__", // "__all__" = All tours
  tourNo: state?.ratings?.tourNo || "__all__", // "__all__" or number
  _booted: false,
  _loading: false,
  _token: 0,
   // search paging
  _searchKey: "",
  _searchOffset: 0,
  _searchLimit: 200,
  _searchRows: []
};

function saveRatingsFiltersToState() {
  try {
    state.ratings = state.ratings || {};
    state.ratings.scope = ratingsState.scope || "district";
    state.ratings.subjectId = ratingsState.subjectId ? Number(ratingsState.subjectId) : null;
    state.ratings.tourId = ratingsState.tourId || "__all__";
    state.ratings.tourNo = ratingsState.tourNo || "__all__";
    saveState();
  } catch {}
}

function resetRatingsSearchPaging() {
  ratingsState.q = String(ratingsState.q || "");
  ratingsState._searchKey = "";
  ratingsState._searchOffset = 0;
  ratingsState._searchRows = [];

  ratingsState._fbSearchOffset = 0;
  ratingsState._fbSearchRows = [];
  ratingsState._fbSearchKey = "";
  ratingsState._pagingMode = "";
}

 function formatSecondsToMMSS(totalSeconds) {
  const s = Math.max(0, Number(totalSeconds) || 0);
  const mm = Math.floor(s / 60);
  const ss = s % 60;
  return `${String(mm).padStart(2,"0")}:${String(ss).padStart(2,"0")}`;
}

function getFullName(u) {
  const fn = (u?.first_name || "").trim();
  const ln = (u?.last_name || "").trim();
  const name = `${fn} ${ln}`.trim();
  return name || "—";
}

function buildUserMeta(u) {
  const parts = [];

  const lang = (window.i18n?.getLang ? window.i18n.getLang() : "ru");

  const pickTr = (tr, fallback) => {
    let obj = tr;
    if (typeof obj === "string") {
      try { obj = JSON.parse(obj); } catch { obj = null; }
    }
    if (obj && typeof obj === "object") {
      if (lang === "uz") return String(obj.uz || obj.ru || fallback || "").trim();
      if (lang === "en") return String(obj.en || obj.ru || fallback || "").trim();
      return String(obj.ru || fallback || "").trim();
    }
    return String(fallback || "").trim();
  };

  // class
  if (u?.class) {
    const c = String(u.class).trim();
    const suffix = t("class_suffix") || "";
    // если suffix задан — показываем "10 класс" / "10-sinf" / "10 grade"
    parts.push(suffix ? `${c} ${suffix}`.trim() : c);
  }

  // school
  if (u?.school) {
    let s = String(u.school).trim();
    if (s && !/^№/i.test(s)) s = `№${s}`;
    const sp = t("school_prefix") || "";
    parts.push(sp ? `${sp} ${s}`.trim() : s);
  }

  const districtLabel = pickTr(u?.district_tr, u?.district);
  const regionLabel = pickTr(u?.region_tr, u?.region);

  if (districtLabel) parts.push(districtLabel);
  if (regionLabel) parts.push(regionLabel);

  return parts.filter(Boolean).join(" • ");
}

   async function enrichRatingsUsersGeoTranslations(rows) {
  try {
    if (!window.sb || !Array.isArray(rows) || !rows.length) return rows;

    const regionIds = Array.from(new Set(
      rows
        .map(r => Number(r?.users?.region_id || 0))
        .filter(n => Number.isFinite(n) && n > 0)
    ));

    const districtIds = Array.from(new Set(
      rows
        .map(r => Number(r?.users?.district_id || 0))
        .filter(n => Number.isFinite(n) && n > 0)
    ));

    const regionMap = new Map();
    const districtMap = new Map();

    if (regionIds.length) {
      const { data } = await window.sb
        .from("regions")
        .select("id,name_ru,name_uz,name_en,name")
        .in("id", regionIds);

      (Array.isArray(data) ? data : []).forEach(x => {
        regionMap.set(Number(x.id), {
          ru: String(x.name_ru || x.name || "").trim(),
          uz: String(x.name_uz || x.name_ru || x.name || "").trim(),
          en: String(x.name_en || x.name_ru || x.name || "").trim()
        });
      });
    }

    if (districtIds.length) {
      const { data } = await window.sb
        .from("districts")
        .select("id,name_ru,name_uz,name_en,name")
        .in("id", districtIds);

      (Array.isArray(data) ? data : []).forEach(x => {
        districtMap.set(Number(x.id), {
          ru: String(x.name_ru || x.name || "").trim(),
          uz: String(x.name_uz || x.name_ru || x.name || "").trim(),
          en: String(x.name_en || x.name_ru || x.name || "").trim()
        });
      });
    }

    rows.forEach(r => {
      const u = r?.users;
      if (!u) return;

      const rid = Number(u.region_id || 0);
      const did = Number(u.district_id || 0);

      if (rid > 0 && !u.region_tr && regionMap.has(rid)) {
        u.region_tr = regionMap.get(rid);
      }

      if (did > 0 && !u.district_tr && districtMap.has(did)) {
        u.district_tr = districtMap.get(did);
      }
    });

    return rows;
  } catch {
    return rows;
  }
}
   
function mapScopeToRankType(scope) {
  if (scope === "district") return "district";
  if (scope === "region") return "region";
  return "country";
}

let _cachedAuthUid = null;
let _cachedAuthUidAt = 0;

async function getAuthUid() {
  try {
    if (!window.sb?.auth?.getUser) return null;

    const now = Date.now();

    // reuse only REAL uid
    if (_cachedAuthUid && (now - _cachedAuthUidAt) < 10000) {
      return _cachedAuthUid;
    }

    const result = await Promise.race([
      window.sb.auth.getUser(),
      new Promise((resolve) => {
        setTimeout(() => resolve({ data: { user: null }, __timeout: true }), 4000);
      })
    ]);

    const uid = result?.data?.user?.id || null;

    if (uid) {
      _cachedAuthUid = uid;
      _cachedAuthUidAt = now;
    } else {
      _cachedAuthUid = null;
      _cachedAuthUidAt = 0;
    }

    return uid;
  } catch {
    _cachedAuthUid = null;
    _cachedAuthUidAt = 0;
    return null;
  }
}

   // ---------------------------
// ✅ Credentials DB → LS sync
// ---------------------------
let __credDbSyncInFlight = null;
let __credDbReady = false;

async function ensureCredentialsDbSynced() {
  if (__credDbReady) return { ok: true, skipped: true, reason: "already_ready" };
  if (__credDbSyncInFlight) return __credDbSyncInFlight;
  if (!window.sb) return { ok: false, reason: "no_sb" };

  __credDbSyncInFlight = (async () => {
    const uid = await getAuthUid();
    if (!uid) return { ok: false, reason: "no_uid" };

    // 1) читаем user_credentials
        const { data: urows, error: uerr } = await window.sb
      .from("user_credentials")
      .select("credential_id,status,achieved_at,evidence_snapshot,last_evaluated_at,created_at")
      .eq("user_id", uid);

    if (uerr) {
      try { console.error("[cred] user_credentials select error:", uerr); } catch {}
      return { ok: false, reason: "user_credentials_select_failed", error: String(uerr?.message || uerr) };
    }

    const ids = Array.from(new Set((urows || []).map(r => r.credential_id).filter(Boolean)));
    if (ids.length === 0) {
      __credDbReady = true;
      return { ok: true, empty: true, rows: 0 };
    }

    // 2) читаем credential_definitions для кодов
    const { data: defs, error: derr } = await window.sb
      .from("credential_definitions")
      .select("id,code,title,description,is_core,is_active")
      .in("id", ids);

    if (derr) {
      try { console.error("[cred] credential_definitions select error:", derr); } catch {}
      return { ok: false, reason: "credential_definitions_select_failed", error: String(derr?.message || derr) };
    }

    const idToCode = {};
    (defs || []).forEach(d => { if (d?.id && d?.code) idToCode[d.id] = d.code; });

    // 3) применяем в LS.credentials (в формате твоего credentialsStore())
    const s = credentialsStore();

    (urows || []).forEach(r => {
      const code = idToCode[r.credential_id];
      if (!code) return;

            const rec = {
        status: r.status || "inactive",
        achieved_at: r.achieved_at || null,
        last_evaluated_at: r.last_evaluated_at || null,
        evidence: r.evidence_snapshot || {},
        evidence_snapshot: r.evidence_snapshot || {}
      };

      // practice_mastery_subject — спец-структура по предметам
      if (code === "practice_mastery_subject") {
        const snap = r.evidence_snapshot || {};
        if (snap?.by_subject && typeof snap.by_subject === "object") {
          s.practice_mastery_subject = s.practice_mastery_subject || { by_subject: {} };
          s.practice_mastery_subject.by_subject = Object.assign({}, s.practice_mastery_subject.by_subject || {}, snap.by_subject);
        } else {
          // если храните 1 предмет в snapshot (subject_id)
          const sid = snap?.subject_id;
          if (sid != null) {
            s.practice_mastery_subject = s.practice_mastery_subject || { by_subject: {} };
            s.practice_mastery_subject.by_subject[sid] = {
              status: rec.status,
              achieved_at: rec.achieved_at,
              last_evaluated_at: rec.last_evaluated_at,
              evidence: rec.evidence,
              evidence_snapshot: rec.evidence_snapshot
            };
          }
        }
        return;
      }

      // прямые коды (consistent_learner, focused_study_streak, error_driven_learner, research_oriented_learner, fair_play_participant, active_video_learner)
      if (s[code] && typeof s[code] === "object") {
        s[code] = Object.assign({}, s[code], rec);
        // поддержим оба имени поля evidence/evidence_snapshot
        s[code].evidence = rec.evidence;
        s[code].evidence_snapshot = rec.evidence_snapshot;
        return;
      }

      // если БД использует короткие коды под UI
      if (code === "research_oriented" && s.research_oriented_learner) {
        s.research_oriented_learner = Object.assign({}, s.research_oriented_learner, rec);
        s.research_oriented_learner.evidence = rec.evidence;
        s.research_oriented_learner.evidence_snapshot = rec.evidence_snapshot;
        return;
      }
      if (code === "fair_play" && s.fair_play_participant) {
        s.fair_play_participant = Object.assign({}, s.fair_play_participant, rec);
        s.fair_play_participant.evidence = rec.evidence;
        s.fair_play_participant.evidence_snapshot = rec.evidence_snapshot;
        return;
      }

      // иначе просто игнорируем неизвестный код (не ломаем UI)
    });

    saveCredentialsStore(s);
    __credDbReady = true;

    return { ok: true, rows: (urows || []).length, defs: (defs || []).length };
  })();

  const res = await __credDbSyncInFlight;
  __credDbSyncInFlight = null;
  return res;
}

// ✅ DB profile fetch (used by tours eligibility, etc.)
async function getUserProfile(uid) {
  try {
    const lp = (typeof loadProfile === "function") ? loadProfile() : null;

    // ✅ local profile доверяем только если он явно привязан к текущему uid
    if (lp && typeof lp === "object" && uid && lp.id && String(lp.id) === String(uid)) {
      return lp;
    }

    // ✅ если uid нет — лучше ничего не выдумывать
    if (!window.sb || !uid) return null;

    const { data, error } = await window.sb
      .from("users")
      .select("id, telegram_user_id, first_name, last_name, avatar_url, language_code, is_school_student, region, district, school, class, region_id, district_id")
      .eq("id", uid)
      .maybeSingle();

    if (error) return null;
    return data || null;
  } catch {
    return null;
  }
}

async function syncUserSubjectToSupabase(subjectKey, mode, isPinned) {
  if (!window.sb) return { ok: false, reason: "no_sb" };

  const uid = await getAuthUid();
  if (!uid) return { ok: false, reason: "no_uid" };

  const subjectId = await getSubjectIdByKey(subjectKey);
  if (!subjectId) {
    try { await logDbErrorToEvents(uid, "subject_lookup", { message: "subject_id not found" }, { subject_key: subjectKey }); } catch {}
    return { ok: false, reason: "no_subject_id" };
  }

  const payload = {
  user_id: uid,
  subject_id: subjectId,
  mode: (mode === "competitive") ? "competitive" : "study",
  is_pinned: !!isPinned
};

// ✅ DB-guard: competitive subjects cannot be pinned (project rule)
if (payload.mode === "competitive" && payload.is_pinned) {
  payload.is_pinned = false;
}

  // 1) Prefer UPSERT (requires unique constraint on (user_id, subject_id))
  let { error } = await window.sb
    .from("user_subjects")
    .upsert(payload, { onConflict: "user_id,subject_id" });

  // 2) Fallback: UPDATE (if upsert fails for any reason)
  if (error) {
    const { error: updErr } = await window.sb
      .from("user_subjects")
      .update({ mode: payload.mode, is_pinned: payload.is_pinned })
      .eq("user_id", uid)
      .eq("subject_id", subjectId);

    if (!updErr) return { ok: true, uid, subjectId, method: "update" };

    try { await logDbErrorToEvents(uid, "user_subjects_save", updErr, { subject_id: subjectId, subject_key: subjectKey }); } catch {}
    return { ok: false, reason: "user_subjects_save_failed" };
  }

  return { ok: true, uid, subjectId, method: "upsert" };
}

   async function writeUserSubjectsHistory(row) {
  try {
    if (!window.sb) return { ok: false };
    const uid = row?.user_id || await getAuthUid();
    if (!uid) return { ok: false };

    const payload = {
      user_id: uid,
      subject_id: Number(row?.subject_id),
      action: String(row?.action),
      from_mode: row?.from_mode ?? null,
      to_mode: row?.to_mode ?? null,
      from_pinned: row?.from_pinned ?? null,
      to_pinned: row?.to_pinned ?? null,
      source: row?.source ?? null,
      meta: row?.meta ?? null
    };

    const { error } = await window.sb.from("user_subjects_history").insert(payload);
    if (error) {
      try { await logDbErrorToEvents(uid, "user_subjects_history_insert", error, payload); } catch {}
      return { ok: false };
    }
    return { ok: true };
  } catch {
    return { ok: false };
  }
}
   
// ---------------------------
// Stage B (DB-backed registration)
// - Save registration fields into public.users
// - Save selected subjects into public.user_subjects
// - Optional: hydrate local profile from DB if missing
// ---------------------------

function getTelegramUserSafe() {
  try {
    const tg = window.Telegram?.WebApp;
    return tg?.initDataUnsafe?.user || null;
  } catch {
    return null;
  }
}

async function saveRegistrationToSupabase(profile) {
  if (!window.sb) return { ok: false, reason: "no_sb" };

        const uid = await ensureRegistrationAuthUid();
  if (!uid) {
    try {
      trackEvent("registration_db_error", {
        where: "ensure_registration_auth_uid",
        message: "no_uid_after_retry"
      });
    } catch {}
    return { ok: false, reason: "no_uid" };
  }

  const tgUser = getTelegramUserSafe() || {};
const avatar = tgUser?.photo_url || null;

// 1) update users row
const fullNameRaw = String(profile?.full_name || profile?.name || "").trim();
const nameParts = fullNameRaw ? fullNameRaw.split(/\s+/).filter(Boolean) : [];
const firstFromProfile = nameParts.length ? nameParts[0] : null;
const lastFromProfile = (nameParts.length > 1) ? nameParts.slice(1).join(" ") : null;

const normalizedLang = ["ru", "uz", "en"].includes(
  String(profile?.language || tgUser?.language_code || "ru").toLowerCase()
)
  ? String(profile?.language || tgUser?.language_code || "ru").toLowerCase()
  : "ru";

const schoolFlag =
  profile?.is_school_student === true ? true :
  profile?.is_school_student === false ? false :
  null;

if (
  !fullNameRaw ||
  schoolFlag === null ||
  !(Number(profile?.region_id) > 0) ||
  !(Number(profile?.district_id) > 0) ||
  !String(profile?.district || "").trim() ||
  (schoolFlag === true && (
    !String(profile?.school || "").trim() ||
    !String(profile?.class || "").trim()
  ))
) {
  try {
    trackEvent("registration_db_error", {
      where: "preflight_invalid_profile",
      has_full_name: !!fullNameRaw,
      school_flag_known: schoolFlag !== null,
      region_id: Number(profile?.region_id) || null,
      district_id: Number(profile?.district_id) || null,
      has_region_text: !!String(profile?.region || "").trim(),
      has_district_text: !!String(profile?.district || "").trim(),
      has_school: !!String(profile?.school || "").trim(),
      has_class: !!String(profile?.class || "").trim(),
      subjects_count: Array.isArray(profile?.subjects) ? profile.subjects.length : 0,
      tg_id_present: tgUser?.id != null
    });
  } catch {}
  return { ok: false, reason: "invalid_profile_payload" };
}

const usersPayload = {
    id: uid,
    telegram_user_id: (tgUser?.id != null) ? String(tgUser.id) : null,

    // ✅ если Telegram не дал first/last_name — берём из формы регистрации
    first_name: tgUser?.first_name || firstFromProfile || null,
    last_name: tgUser?.last_name || lastFromProfile || null,

    avatar_url: avatar,
    language_code: normalizedLang,
    is_school_student: schoolFlag,

    // ✅ сохраняем ID (FK), а текст оставляем для отображения/резерва
    region_id: (profile?.region_id != null && profile.region_id !== "") ? Number(profile.region_id) : null,
    district_id: (profile?.district_id != null && profile.district_id !== "") ? Number(profile.district_id) : null,

    region: profile?.region || null,
    district: profile?.district || null,

    school: profile?.school || null,
    class: profile?.class || null
  };

   try {
  trackEvent("registration_db_payload", {
    uid_present: !!uid,
    tg_id_present: tgUser?.id != null,
    has_first_name: !!usersPayload.first_name,
    has_last_name: !!usersPayload.last_name,
    language_code: usersPayload.language_code,
    is_school_student: usersPayload.is_school_student,
    region_id: Number(usersPayload.region_id) || null,
    district_id: Number(usersPayload.district_id) || null,
    has_region_text: !!String(usersPayload.region || "").trim(),
    has_district_text: !!String(usersPayload.district || "").trim(),
    has_school: !!String(usersPayload.school || "").trim(),
    has_class: !!String(usersPayload.class || "").trim(),
    subjects_count: Array.isArray(profile?.subjects) ? profile.subjects.length : 0
  });
} catch {}
   
    let uErr = null;
  try {
    await dbWriteWithRetry(async () => {
      const { error } = await window.sb
        .from("users")
        .upsert(usersPayload, { onConflict: "id" });

      if (error) throw error;
      return true;
    }, { tries: 3, baseDelayMs: 350 });

  } catch (e) {
    uErr = e;
  }

    if (uErr) {
    const rawMsg = String(uErr?.message || uErr || "");

    try {
      trackEvent("registration_db_error", {
        where: "users_upsert",
        message: rawMsg
      });
    } catch {}

    // ✅ точная причина для случая, который мы уже видели в логах:
    // duplicate key value violates unique constraint "users_telegram_user_id_key"
    if (
      rawMsg.includes('users_telegram_user_id_key') ||
      rawMsg.includes('duplicate key value violates unique constraint')
    ) {
      return {
        ok: false,
        reason: "telegram_already_linked",
        detail: rawMsg
      };
    }

    return {
      ok: false,
      reason: "users_upsert_failed",
      detail: rawMsg
    };
  }

    // 2) upsert user_subjects rows
  const subjects = Array.isArray(profile?.subjects) ? profile.subjects : [];
  const rows = [];

  for (const s of subjects) {
    const key = String(s?.key || "").trim();
    if (!key) continue;

    const subjectId = await getSubjectIdByKey(key);
    if (!subjectId) continue;

    const mode = (s?.mode === "competitive") ? "competitive" : "study";

    rows.push({
      user_id: uid,
      subject_id: subjectId,
      mode,
      // ❗ project rule: competitive subjects cannot be pinned
      is_pinned: (mode === "competitive") ? false : !!s?.pinned
    });
  }

  if (rows.length) {
        // ✅ Теперь в БД есть UNIQUE(user_id, subject_id) → можно безопасно upsert
    let upErr = null;

    try {
      await dbWriteWithRetry(async () => {
        const { error } = await window.sb
          .from("user_subjects")
          .upsert(rows, { onConflict: "user_id,subject_id" });

        if (error) throw error;
        return true;
      }, { tries: 3, baseDelayMs: 350 });

    } catch (e) {
      upErr = e;
    }

    if (upErr) {
      try {
        trackEvent("registration_db_error", {
          where: "user_subjects_upsert",
          message: String(upErr?.message || upErr)
        });
      } catch {}
      return { ok: false, reason: "user_subjects_upsert_failed" };
    }

    // ✅ NEW: стартовая точка для аналитики (только регистрация)
    try {
      const historyRows = rows.map(r => ({
        user_id: uid,
        subject_id: r.subject_id,
        action: "initial_registration",
        from_mode: null,
        to_mode: r.mode,
        from_pinned: null,
        to_pinned: r.is_pinned,
        source: "registration",
        meta: { v: 1 }
      }));

      const { error: hErr } = await window.sb
        .from("user_subjects_history")
        .insert(historyRows);

      if (hErr) {
        try {
          trackEvent("registration_db_error", {
            where: "user_subjects_history_insert",
            message: String(hErr?.message || hErr)
          });
        } catch {}
        // ❗ Регистрацию НЕ валим — история вторична, subjects уже сохранены
      }
    } catch {}
  }

  __profileSubjectsDbReady = false;
  return { ok: true, user_id: uid, user_subjects_rows: rows.length, subjects_saved: rows.length };
}

   function getRegistrationSaveErrorUi(dbRes) {
  const reason = String(dbRes?.reason || "").trim();

  if (reason === "telegram_already_linked") {
    return {
      title: tr3(
        "Этот Telegram-аккаунт уже связан с профилем iClub.",
        "Bu Telegram akkaunt iClub profiliga ulangan.",
        "This Telegram account is already linked to an iClub profile."
      ),
      recommendation: tr3(
        "Попробуйте открыть приложение на устройстве или в браузере, где вы уже входили раньше. Если это не поможет, напишите в поддержку.",
        "Ilovani avval kirgan qurilmangizda yoki brauzeringizda ochib ko‘ring. Agar yordam bermasa, qo‘llab-quvvatlashga yozing.",
        "Try opening the app on the device or browser where you used it before. If that does not help, contact support."
      )
    };
  }

  if (reason === "no_uid") {
    return {
      title: tr3(
        "Не удалось создать сессию входа.",
        "Kirish sessiyasini yaratib bo‘lmadi.",
        "Could not create a sign-in session."
      ),
      recommendation: tr3(
        "Проверьте интернет и попробуйте ещё раз.",
        "Internetni tekshirib, yana urinib ko‘ring.",
        "Check your internet connection and try again."
      )
    };
  }

  if (reason === "user_subjects_upsert_failed") {
    return {
      title: tr3(
        "Основной профиль сохранён, но не удалось сохранить выбранные предметы.",
        "Asosiy profil saqlandi, lekin tanlangan fanlarni saqlab bo‘lmadi.",
        "Your main profile was saved, but the selected subjects could not be saved."
      ),
      recommendation: tr3(
        "Попробуйте ещё раз. Если ошибка повторится, напишите в поддержку.",
        "Yana urinib ko‘ring. Xato takrorlansa, qo‘llab-quvvatlashga yozing.",
        "Please try again. If the problem continues, contact support."
      )
    };
  }

  return {
    title: tr3(
      "Не удалось сохранить регистрацию.",
      "Ro‘yxatdan o‘tishni saqlab bo‘lmadi.",
      "Could not save registration."
    ),
    recommendation: tr3(
      "Попробуйте ещё раз немного позже. Если ошибка повторится, напишите в поддержку.",
      "Birozdan keyin yana urinib ko‘ring. Xato takrorlansa, qo‘llab-quvvatlashga yozing.",
      "Please try again a little later. If the problem continues, contact support."
    )
  };
}
   function closeIClubApp() {
  try {
    const tgApp = window.Telegram?.WebApp;
    if (tgApp && typeof tgApp.close === "function") {
      tgApp.close();
      return true;
    }
  } catch {}

  try {
    window.close();
    return true;
  } catch {}

  return false;
}

async function showRecoveryCancelledAndClose() {
  await uiAlert({
    title: tr3(
      "Восстановление отменено.",
      "Tiklash bekor qilindi.",
      "Recovery cancelled."
    ),
    message: tr3(
      "Данные не изменены. Используйте устройство, где профиль сейчас активен, или заново откройте приложение и подтвердите восстановление.",
      "Ma’lumotlar o‘zgartirilmadi. Profil hozir faol bo‘lgan qurilmadan foydalaning yoki ilovani qayta ochib, tiklashni tasdiqlang.",
      "No data was changed. Use the device where the profile is currently active, or reopen the app and confirm recovery."
    ),
    okText: tr3(
      "Закрыть приложение",
      "Ilovani yopish",
      "Close app"
    )
  });

  const closed = closeIClubApp();

  if (!closed) {
    await uiAlert({
      title: tr3(
        "Закройте приложение вручную.",
        "Ilovani qo‘lda yoping.",
        "Close the app manually."
      ),
      message: tr3(
        "Telegram не разрешил закрыть окно автоматически.",
        "Telegram oynani avtomatik yopishga ruxsat bermadi.",
        "Telegram did not allow the window to close automatically."
      )
    });
  }
}

function resetUiAfterIdentityRecovery(options = {}) {
  try {
    const preserve = options?.preserveCourseContext || null;

    const keepSubjectKey = preserve?.subjectKey
      ? String(preserve.subjectKey)
      : "";

    const keepStack = Array.isArray(preserve?.stack) && preserve.stack.length
      ? preserve.stack
      : ["subject-tours"];

    const keepEntryTab = preserve?.entryTab
      ? String(preserve.entryTab)
      : (state?.courses?.entryTab || state?.prevTab || "home");

    const keepTourNo = preserve?.activeTourNo != null
      ? Number(preserve.activeTourNo)
      : null;

    const keepTourId = preserve?.activeTourId != null && preserve?.activeTourId !== ""
      ? String(preserve.activeTourId)
      : null;

    state.courses = state.courses || {};

    if (keepSubjectKey) {
      state.tab = "courses";
      state.prevTab = keepEntryTab;
      state.viewStack = ["courses"];

      state.courses.stack = keepStack;
      state.courses.subjectKey = keepSubjectKey;
      state.courses.lessonId = null;
      state.courses.entryTab = keepEntryTab;

      if (keepTourNo && Number.isFinite(keepTourNo) && keepTourNo > 0) {
        state.courses.activeTourNo = keepTourNo;
      }

      if (keepTourId) {
        state.courses.activeTourId = keepTourId;
      }
    } else {
      state.tab = "home";
      state.prevTab = "home";
      state.viewStack = ["home"];

      state.courses.stack = ["all-subjects"];
      state.courses.subjectKey = null;
      state.courses.lessonId = null;
      state.courses.entryTab = "home";
    }

    state.courses.lastTourAttemptId = null;
    state.courses.lastTourCertificateId = null;

    state.quizLock = null;

// local экранный контекст квиза убираем, DB-прогресс не трогаем
try { delete state.quiz; } catch {}
try { delete state.tourContext; } catch {}

// ВАЖНО: после смены identity нельзя продолжать старые tour_answer/tour_finalize.
// Иначе pending ops могут писать в attempt старого uid и снова ловить RLS.
try { clearPendingTourOpsAfterIdentityRecovery(); } catch {}

saveState();
  } catch {}
}
   function isCheckOnlyRecoverySource(source) {
  const s = String(source || "").trim().toLowerCase();
  return (
    s === "boot_auto_recovery" ||
    s === "boot_linked_profile_check" ||
    s === "missing_uid_boot_auto" ||
    s === "inactive_session_boot_auto" ||
    s === "focus_active_identity_check" ||
    s === "tour_start_profile_check"
  );
}

function isSystemNoLimitRecoverySource(source) {
  const s = String(source || "").trim().toLowerCase();
  return (
    s === "missing_uid_boot" ||
    s === "inactive_session_boot" ||
    s === "boot_existing_telegram_profile"
  );
}

function isUserRiskyRecoverySource(source) {
  const s = String(source || "").trim().toLowerCase();
  return (
    s === "registration_conflict" ||
    s === "manual_profile_recovery" ||
    s === "support_manual_recovery" ||
    s === "tour_start_profile_recovery"
  );
}

   const TG_PROFILE_CHECK_CACHE_MS = 8000;
const TG_PROFILE_RECOVERY_CACHE_MS = 12000;
const TG_PROFILE_FAILURE_CACHE_MS = 2500;

let __tgProfileCheckCache = null;
let __tgProfileRecoveryCache = null;
const __tgProfileCheckInFlight = new Map();
const __tgProfileRecoveryInFlight = new Map();

function getTelegramProfileRequestKey(source, currentUid, initData) {
  const src = String(source || "").trim().toLowerCase();
  const uid = String(currentUid || "");
  const initTail = String(initData || "").slice(-80);
  return `${src}|${uid}|${initTail}`;
}

function isFreshTgProfileCache(cache, key, ttlMs) {
  return !!(
    cache &&
    cache.key === key &&
    cache.ts &&
    Date.now() - cache.ts < ttlMs
  );
}
   
   async function trySilentBootProfileRecovery(source = "boot_auto_recovery") {
  const statusEl = document.getElementById("splash-status");
  const prevText = statusEl?.textContent || "";

  try {
    if (statusEl) {
      statusEl.textContent = tr3(
        "Проверяем профиль…",
        "Profil tekshirilmoqda…",
        "Checking profile…"
      );
    }

    const checkRes = await checkTelegramLinkedProfile({
      source: "boot_linked_profile_check"
    }).catch((e) => ({
      ok: false,
      reason: "exception",
      message: String(e?.message || e)
    }));

    if (checkRes?.ok && checkRes?.linked && checkRes?.is_current) {
      return {
        ok: true,
        reason: "already_current",
        data: checkRes?.data || null
      };
    }

    return {
      ok: false,
      reason:
        checkRes?.reason ||
        (checkRes?.linked ? "system_profile_mismatch" : "no_linked_profile"),
      linked: !!checkRes?.linked,
      is_current: !!checkRes?.is_current,
      user_id: checkRes?.user_id || null,
      current_uid: checkRes?.current_uid || null,
      data: checkRes?.data || null
    };
  } finally {
    if (statusEl) {
      statusEl.textContent =
        prevText ||
        (typeof t === "function" ? (t("loading") || "Загрузка…") : "Загрузка…");
    }
  }
}

   async function checkTelegramLinkedProfile({ source = "boot_linked_profile_check", force = false } = {}) {
  try {
    if (!window.sb?.functions?.invoke) {
      return { ok: false, reason: "functions_not_available" };
    }

    const initData = String(window.Telegram?.WebApp?.initData || "").trim();
    if (!initData) {
      return { ok: false, reason: "telegram_init_data_missing" };
    }

    const currentUid = await getAuthUid().catch(() => null);
    const key = getTelegramProfileRequestKey(source, currentUid, initData);

    if (!force && isFreshTgProfileCache(__tgProfileCheckCache, key, TG_PROFILE_CHECK_CACHE_MS)) {
      return {
        ...__tgProfileCheckCache.result,
        from_cache: true
      };
    }

    if (!force && __tgProfileCheckInFlight.has(key)) {
      return await __tgProfileCheckInFlight.get(key);
    }

    const task = (async () => {
      const { data, error } = await window.sb.functions.invoke("recover-telegram-user", {
        body: {
          initData,
          mode: "check",
          source
        }
      });

      if (error) {
        const res = {
          ok: false,
          reason: "edge_function_error",
          message: String(error?.message || error)
        };

        __tgProfileCheckCache = {
          key,
          ts: Date.now(),
          result: res
        };

        return res;
      }

      const res = {
        ok: !!data?.ok,
        linked: !!data?.linked,
        is_current: !!data?.is_current,
        user_id: data?.user_id || null,
        current_uid: data?.current_uid || null,
        reason: data?.reason || null,
        data
      };

      __tgProfileCheckCache = {
        key,
        ts: Date.now(),
        result: res
      };

      return res;
    })();

    __tgProfileCheckInFlight.set(key, task);

    try {
      return await task;
    } finally {
      __tgProfileCheckInFlight.delete(key);
    }
  } catch (e) {
    return {
      ok: false,
      reason: "exception",
      message: String(e?.message || e)
    };
  }
}
   
async function recoverTelegramLinkedProfile({
  source = "registration_conflict",
  silentBoot = false,
  force = false,
  preserveCourseContext = null
} = {}) {
  try {
    if (!window.sb?.functions?.invoke) {
      return { ok: false, reason: "functions_not_available" };
    }

    const initData = String(window.Telegram?.WebApp?.initData || "").trim();

    if (!initData) {
      return { ok: false, reason: "telegram_init_data_missing" };
    }

    if (typeof isCheckOnlyRecoverySource === "function" && isCheckOnlyRecoverySource(source)) {
      return {
        ok: false,
        reason: "system_source_check_only"
      };
    }

    // ✅ confirm-recovery должен идти уже с реальным current auth uid,
    // иначе функция не сможет понять, на какой uid переносить профиль
    await initSupabaseSession({ allowAnonymousBootstrap: true }).catch(() => null);

    const currentUid = await ensureRegistrationAuthUid().catch(() => null);
    if (!currentUid) {
      return { ok: false, reason: "no_current_auth_uid" };
    }

    const key = getTelegramProfileRequestKey(source, currentUid, initData);

    if (!force && isFreshTgProfileCache(__tgProfileRecoveryCache, key, TG_PROFILE_RECOVERY_CACHE_MS)) {
      return {
        ...__tgProfileRecoveryCache.result,
        from_cache: true
      };
    }

    if (!force && __tgProfileRecoveryInFlight.has(key)) {
      return await __tgProfileRecoveryInFlight.get(key);
    }

    const task = (async () => {
      const { data, error } = await window.sb.functions.invoke("recover-telegram-user", {
        body: {
          initData,
          confirm: true,
          source
        }
      });

      if (error) {
        const res = {
          ok: false,
          reason: "edge_function_error",
          message: String(error?.message || error)
        };

        __tgProfileRecoveryCache = {
          key,
          ts: Date.now() - TG_PROFILE_RECOVERY_CACHE_MS + TG_PROFILE_FAILURE_CACHE_MS,
          result: res
        };

        return res;
      }

      if (!data?.ok) {
        const res = {
          ok: false,
          reason: data?.reason || "recovery_failed",
          message: data?.message || null,
          data
        };

        __tgProfileRecoveryCache = {
          key,
          ts: Date.now() - TG_PROFILE_RECOVERY_CACHE_MS + TG_PROFILE_FAILURE_CACHE_MS,
          result: res
        };

        return res;
      }

      // Только local profile пересобираем под новый активный uid.
// Practice/tour progress не чистим.
const profileBeforeRecovery = loadProfile();

try { localStorage.removeItem(LS.profile); } catch {}

// ВАЖНО: старые tour pending ops могли принадлежать старому auth.uid.
try { clearPendingTourOpsAfterIdentityRecovery(); } catch {}

try {
  await hydrateLocalProfileFromSupabaseIfMissing({
    force: true,
    preserveUiLanguage:
      profileBeforeRecovery?.uiLanguage ||
      profileBeforeRecovery?.language ||
      null
  });
} catch {}

try { await syncUserSubjectsFromSupabaseIntoLocalProfile(); } catch {}
try { await ensureProfileGeoTranslationsHydrated(); } catch {}
      const recoveredOk = isRegistered();

      if (!recoveredOk) {
        const res = {
          ok: false,
          reason: "recovered_but_profile_incomplete",
          data
        };

        __tgProfileRecoveryCache = {
          key,
          ts: Date.now() - TG_PROFILE_RECOVERY_CACHE_MS + TG_PROFILE_FAILURE_CACHE_MS,
          result: res
        };

        return res;
      }

      try { await refreshNotificationsBadge(); } catch {}

      const restoredProfile = loadProfile();
      const restoredLang = restoredProfile?.uiLanguage || restoredProfile?.language || getTelegramLang() || "ru";

      try { window.i18n?.setLang(restoredLang); } catch {}
      try { applyStaticI18n(); } catch {}

      resetUiAfterIdentityRecovery({ preserveCourseContext });

      if (!silentBoot) {
        showToast(
          tr3(
            "Профиль восстановлен.",
            "Profil tiklandi.",
            "Profile restored."
          )
        );
      }

      const res = {
        ok: true,
        reason: data?.reason || "recovered",
        data
      };

      __tgProfileRecoveryCache = {
        key,
        ts: Date.now(),
        result: res
      };

      return res;
    })();

    __tgProfileRecoveryInFlight.set(key, task);

    try {
      return await task;
    } finally {
      __tgProfileRecoveryInFlight.delete(key);
    }
  } catch (e) {
    return {
      ok: false,
      reason: "exception",
      message: String(e?.message || e)
    };
  }
}
   
async function confirmAndRecoverTelegramProfile({ source = "registration_conflict", variant = "linked_profile" } = {}) {
  const isInactiveSession = variant === "inactive_session";

  const confirmed = await uiConfirm({
    title: isInactiveSession
      ? tr3(
          "Профиль открыт на другом устройстве",
          "Profil boshqa qurilmada ochilgan",
          "Profile opened on another device"
        )
      : tr3(
          "Профиль уже существует",
          "Profil mavjud",
          "Profile already exists"
        ),
    message: isInactiveSession
      ? tr3(
          "Этот профиль был активирован на другом устройстве. Чтобы использовать iClub здесь, восстановите профиль на этом устройстве. После подтверждения это устройство станет активным. В целях безопасности восстановление ограничено: 2 раза за 24 часа, 4 раза за 7 дней и 6 раз за 30 дней. Продолжить?",
"Bu profil boshqa qurilmada faollashtirilgan. iClub’dan bu yerda foydalanish uchun profilni shu qurilmada tiklang. Tasdiqlasangiz, shu qurilma faol bo‘ladi. Xavfsizlik uchun tiklash cheklangan: 24 soatda 2 marta, 7 kunda 4 marta va 30 kunda 6 marta. Davom etamizmi?",
"This profile was activated on another device. To use iClub here, restore the profile on this device. After confirmation, this device will become active. For security, recovery is limited to twice per 24 hours, four times per 7 days, and six times per 30 days. Continue?"
        )
      : tr3(
          "Этот Telegram-аккаунт уже связан с профилем iClub. Можно восстановить профиль на этом устройстве. После подтверждения активным станет это устройство, а предыдущая сессия будет отключена. В целях безопасности восстановление ограничено: 2 раза за 24 часа, 4 раза за 7 дней и 6 раз за 30 дней. Продолжить?",
"Bu Telegram akkaunt iClub profiliga ulangan. Profilni shu qurilmada tiklash mumkin. Tasdiqlasangiz, shu qurilma faol bo‘ladi, oldingi sessiya esa nofaol bo‘ladi. Xavfsizlik uchun tiklash cheklangan: 24 soatda 2 marta, 7 kunda 4 marta va 30 kunda 6 marta. Davom etamizmi?",
"This Telegram account is already linked to an iClub profile. You can restore the profile on this device. After confirmation, this device will become active and the previous session will be disabled. For security, recovery is limited to twice per 24 hours, four times per 7 days, and six times per 30 days. Continue?"
        ),
    okText: tr3(
      "Восстановить профиль",
      "Profilni tiklash",
      "Restore profile"
    ),
    cancelText: tr3(
      "Отмена",
      "Bekor qilish",
      "Cancel"
    )
  });

  if (!confirmed) {
    await showRecoveryCancelledAndClose();
    return { ok: false, reason: "cancelled" };
  }

  showAsyncOverlay(
    tr3(
      "Восстанавливаем профиль…",
      "Profil tiklanmoqda…",
      "Restoring profile…"
    )
  );

  const recRes = await recoverTelegramLinkedProfile({ source }).catch((e) => ({
    ok: false,
    reason: "exception",
    message: String(e?.message || e)
  }));

  hideAsyncOverlay();

  if (!recRes?.ok) {
  const reason = String(recRes?.reason || recRes?.data?.reason || "");

  if (reason === "recovery_limit_reached") {
    await uiAlert({
      title: tr3(
        "Лимит восстановления исчерпан.",
        "Tiklash limiti tugadi.",
        "Recovery limit reached."
      ),
      message: tr3(
        "В целях безопасности профиль можно восстановить не чаще 2 раз за 24 часа, 4 раз за 7 дней и 6 раз за 30 дней. Если вам нужно восстановить доступ раньше, обратитесь к администратору.",
"Xavfsizlik uchun profilni 24 soatda 2 martadan, 7 kunda 4 martadan va 30 kunda 6 martadan ko‘p tiklab bo‘lmaydi. Agar profilni bundan oldinroq tiklash kerak bo‘lsa, administratorga murojaat qiling.",
"For security, the profile can be restored no more than twice per 24 hours, four times per 7 days, and six times per 30 days. If you need access earlier, contact the administrator."
      )
    });

    return recRes;
  }

  await uiAlert({
    title: tr3(
      "Не удалось восстановить профиль.",
      "Profilni tiklashning imkoni bo‘lmadi.",
      "Could not restore the profile."
    ),
    message: tr3(
      "Закройте и заново откройте приложение из Telegram. Если ошибка повторится, напишите в поддержку.",
      "Ilovani yopib, Telegram orqali qayta oching. Xato takrorlansa, qo‘llab-quvvatlashga yozing.",
      "Close and reopen the app from Telegram. If the problem continues, contact support."
    )
  });

  return recRes;
}

  showToast(
  tr3(
    "Профиль восстановлен.",
    "Profil tiklandi.",
    "Profile restored."
  )
);

// ✅ после server-side recovery notification обновляем колокольчик
try { await refreshNotificationsBadge(); } catch {}

const restoredProfile = loadProfile();
  const restoredLang = restoredProfile?.uiLanguage || restoredProfile?.language || getTelegramLang() || "ru";

  try { window.i18n?.setLang(restoredLang); } catch {}
  try { applyStaticI18n(); } catch {}

  resetUiAfterIdentityRecovery();

  setTab("home");
  await ensureHomeDbReady();
  renderHome();
  renderAllSubjects();

  return { ok: true, reason: "recovered" };
}

async function ensureActiveIdentityOrShowRecovery() {
  try {
    const localProfile = loadProfile();
    if (!localProfile || !window.sb) {
      return { ok: true, skipped: true };
    }

    let uid = await getAuthUid().catch(() => null);

    // ✅ Если сети нет — не тащим пользователя в recovery по временной оффлайн-ситуации.
    if (!uid) {
      try {
        if (typeof navigator !== "undefined" && navigator.onLine === false) {
          return { ok: true, skipped: true, reason: "no_uid_offline" };
        }
      } catch {}

      // ✅ Для boot-проблемы "local profile есть, uid нет"
      // сначала делаем ТИХОЕ восстановление прямо на splash.
      const silentRec = await trySilentBootProfileRecovery("missing_uid_boot_auto");

      if (silentRec?.ok) {
        return {
          ok: true,
          active: true,
          recovered: true,
          reason: silentRec?.reason || "missing_uid_boot_auto"
        };
      }

      // fallback — только если тихое восстановление не удалось
      showView("registration");
      bindRegistration();

      const rec = await confirmAndRecoverTelegramProfile({
        source: "missing_uid_boot",
        variant: "inactive_session"
      });

      return {
        ok: !!rec?.ok,
        blocked: !rec?.ok,
        reason: rec?.reason || "missing_uid_boot"
      };
    }

    const userRowCheck = await checkDbUserRow(uid);

    // Важно: если база/сеть не ответила уверенно — НЕ блокируем пользователя.
    // Иначе при временном сбое можно случайно показать recovery нормальному активному пользователю.
    if (!userRowCheck?.ok) {
      return {
        ok: true,
        skipped: true,
        reason: userRowCheck?.reason || "db_user_check_failed"
      };
    }

    // Если текущий uid активен, но local profile старый/без id — тихо пересобираем local profile.
    if (userRowCheck.exists) {
      if (!localProfile.id || String(localProfile.id) !== String(uid)) {
        try { localStorage.removeItem(LS.profile); } catch {}
        try { await hydrateLocalProfileFromSupabaseIfMissing(); } catch {}
        try { await syncUserSubjectsFromSupabaseIntoLocalProfile(); } catch {}
        try { await ensureProfileGeoTranslationsHydrated(); } catch {}
      }

      return { ok: true, active: true };
    }

    // ✅ users-row для текущего uid нет:
    // сначала пробуем тихо восстановить профиль на splash
    const silentRec = await trySilentBootProfileRecovery("inactive_session_boot_auto");

    if (silentRec?.ok) {
      return {
        ok: true,
        active: true,
        recovered: true,
        reason: silentRec?.reason || "inactive_session_boot_auto"
      };
    }

    // fallback — только если тихое восстановление не удалось
    try { localStorage.removeItem(LS.profile); } catch {}

    showView("registration");
    bindRegistration();

    const rec = await confirmAndRecoverTelegramProfile({
      source: "inactive_session_boot",
      variant: "inactive_session"
    });

    return {
      ok: !!rec?.ok,
      blocked: !rec?.ok,
      reason: rec?.reason || "inactive_session"
    };
  } catch {
    return { ok: true, skipped: true, reason: "exception_safe_skip" };
  }
}
   
   async function ensureKnownTelegramProfileOnBoot() {
  try {
    // Если local profile уже есть, этот кейс обрабатывает ensureActiveIdentityOrShowRecovery().
    if (loadProfile()) {
      return { ok: true, skipped: true, reason: "local_profile_exists" };
    }

    if (!window.sb?.functions?.invoke) {
      return { ok: true, skipped: true, reason: "functions_not_available" };
    }

    const initData = String(window.Telegram?.WebApp?.initData || "").trim();
    if (!initData) {
      return { ok: true, skipped: true, reason: "telegram_init_data_missing" };
    }

    const check = await checkTelegramLinkedProfile({
      source: "boot_no_local_profile_check"
    });

    // Важно: если check не сработал из-за сети/Edge — НЕ блокируем.
    // Просто оставляем обычную регистрацию.
    if (!check?.ok) {
      return {
        ok: true,
        skipped: true,
        reason: check?.reason || "check_failed"
      };
    }

    // Telegram профиль не найден в БД → это реально новый пользователь.
    if (!check.linked) {
      return { ok: true, linked: false };
    }

    // Уже привязан к текущему uid. Теоретически hydrate должен был поднять профиль,
    // но если нет — не мешаем обычному flow.
    if (check.is_current) {
      return { ok: true, linked: true, is_current: true };
    }

    // Telegram уже связан с другим active user_id.
    // Показываем recovery сразу, без заполнения регистрации.
    showView("registration");
    bindRegistration();

    const rec = await confirmAndRecoverTelegramProfile({
      source: "boot_existing_telegram_profile"
    });

    return {
      ok: !!rec?.ok,
      handled: true,
      blocked: !rec?.ok,
      reason: rec?.reason || "boot_existing_telegram_profile"
    };
  } catch {
    return { ok: true, skipped: true, reason: "exception_safe_skip" };
  }
}

      let __identityRuntimeGuardInFlight = null;
let __identityRuntimeGuardLastCheckedAt = 0;
let __identityRuntimeBlocking = false;
let __identityRuntimeGuardsBound = false;

function isIdentityRecoverySurfaceActive() {
  try {
    const regView = document.getElementById("view-registration");
    const certView = document.getElementById("view-certificate-verify");

    const regActive = !!(regView && regView.classList.contains("is-active"));
    const certActive = !!(certView && certView.classList.contains("is-active"));

    const topView = Array.isArray(state?.viewStack)
      ? state.viewStack[state.viewStack.length - 1]
      : "";

    return (
      regActive ||
      certActive ||
      topView === "registration" ||
      topView === "certificate-verify"
    );
  } catch {
    return false;
  }
}

function resetRuntimeForInactiveIdentity() {
  try {
    if (typeof stopPracticeQuestionTimer === "function") {
      stopPracticeQuestionTimer();
    }
  } catch {}

  try {
    if (state?.quiz?.qTimerId) clearInterval(state.quiz.qTimerId);
  } catch {}

  try {
    if (state?.tourContext?.timerId) clearInterval(state.tourContext.timerId);
  } catch {}

  try {
    state.quizLock = null;

    try { delete state.quiz; } catch {}
    try { delete state.tourContext; } catch {}

    state.tab = "home";
    state.prevTab = "home";
    state.viewStack = ["registration"];

    state.courses = state.courses || {};
    state.courses.stack = ["all-subjects"];
    state.courses.subjectKey = null;
    state.courses.lessonId = null;
    state.courses.entryTab = "home";
    state.courses.lastTourAttemptId = null;
    state.courses.lastTourCertificateId = null;

    saveState();
  } catch {}
}

async function enforceActiveIdentityOrBlock({ source = "runtime_active_identity", force = false } = {}) {
  try {
    if (__identityRuntimeBlocking) return false;

    // На registration/recovery/certificate-verify не мешаем текущему flow.
    if (isIdentityRecoverySurfaceActive()) return true;

    const localProfile = loadProfile();
    if (!localProfile || !window.sb) return true;

    const now = Date.now();

    // Не бьём БД на каждый микроклик.
    if (!force && (now - __identityRuntimeGuardLastCheckedAt) < 5000) {
      return true;
    }

    if (__identityRuntimeGuardInFlight) {
      return await __identityRuntimeGuardInFlight;
    }

    __identityRuntimeGuardInFlight = (async () => {
      const uid = await getAuthUid().catch(() => null);
      if (!uid) return true;

      const userRowCheck = await checkDbUserRow(uid);

      // Если сеть/БД не ответили уверенно — не блокируем нормального пользователя.
      if (!userRowCheck?.ok) {
        return true;
      }

      __identityRuntimeGuardLastCheckedAt = Date.now();

      // Текущий uid всё ещё активен.
      if (userRowCheck.exists) {
        return true;
      }

      // База уверенно сказала: public.users для текущего uid больше нет.
      // Значит эта открытая вкладка/устройство уже не активны.
      __identityRuntimeBlocking = true;

      resetRuntimeForInactiveIdentity();

      try { localStorage.removeItem(LS.profile); } catch {}

            showView("registration");
      bindRegistration();

      try {
        await confirmAndRecoverTelegramProfile({
          source,
          variant: "inactive_session"
        });
      } finally {
        __identityRuntimeBlocking = false;
      }

      // Важно: старое действие/клик НЕ продолжаем после recovery.
      return false;
    })();

    try {
      return await __identityRuntimeGuardInFlight;
    } finally {
      __identityRuntimeGuardInFlight = null;
    }
  } catch {
    return true;
  }
}

function bindIdentityRuntimeGuards() {
  if (__identityRuntimeGuardsBound) return;
  __identityRuntimeGuardsBound = true;

  const run = (source) => {
    enforceActiveIdentityOrBlock({ source, force: true }).catch(() => null);
  };

  try {
    document.addEventListener("visibilitychange", () => {
      if (!document.hidden) run("visibility_active_identity_check");
    });
  } catch {}

  try {
    window.addEventListener("focus", () => {
      run("focus_active_identity_check");
    });
  } catch {}

  try {
    window.addEventListener("online", () => {
      setTimeout(() => run("online_active_identity_check"), 400);
    });
  } catch {}

  // Если оба устройства открыты одновременно, старое окно не должно жить вечно.
  try {
    setInterval(() => {
      if (document.hidden) return;

      enforceActiveIdentityOrBlock({
        source: "interval_active_identity_check",
        force: false
      }).catch(() => null);
    }, 20000);
  } catch {}
}
   
async function hydrateLocalProfileFromSupabaseIfMissing(options = {}) {
  const force = !!options?.force;
  const existingProfile = loadProfile();

  if (existingProfile && !force) {
    return { ok: true, skipped: true, reason: "local_profile_exists" };
  }

  if (!window.sb) return { ok: false, reason: "no_sb" };

  const uid = await getAuthUid();
  if (!uid) return { ok: false, reason: "no_uid" };

  const me = await getMyUserRow(uid);
  if (!me) return { ok: false, reason: "no_users_row" };

  // Load user_subjects with subject_key
  let subjRows = [];
  try {
    const { data, error } = await window.sb
      .from("user_subjects")
      .select("mode,is_pinned, subjects(subject_key)")
      .eq("user_id", uid);

    if (!error && Array.isArray(data)) subjRows = data;
  } catch {}

  const subjects = subjRows
    .map(r => {
      const key = r?.subjects?.subject_key;
      if (!key) return null;
      return {
        key,
        mode: (r?.mode === "competitive") ? "competitive" : "study",
        pinned: !!r?.is_pinned
      };
    })
    .filter(Boolean);

  const fullName = [me.first_name, me.last_name].filter(Boolean).join(" ").trim();

  const regFlag =
    (me.is_school_student === true) ? true :
    (me.is_school_student === false) ? false :
    null;

  if (regFlag === null) {
    return { ok: true, hydrated: false, reason: "db_registration_not_completed" };
  }

  const regionId = Number(me.region_id) > 0 ? Number(me.region_id) : null;
  const districtId = Number(me.district_id) > 0 ? Number(me.district_id) : null;

  let regionText = String(me.region || "").trim();
  let districtText = String(me.district || "").trim();
  let regionTr = null;
  let districtTr = null;

  if (regionId) {
    try {
      const { data: rRow } = await window.sb
        .from("regions")
        .select("id,name_ru,name_uz,name_en,name")
        .eq("id", regionId)
        .maybeSingle();

      if (rRow) {
        regionTr = {
          ru: String(rRow.name_ru || rRow.name || "").trim(),
          uz: String(rRow.name_uz || rRow.name_ru || rRow.name || "").trim(),
          en: String(rRow.name_en || rRow.name_ru || rRow.name || "").trim()
        };

        regionText =
          regionText ||
          regionTr.ru ||
          regionTr.uz ||
          regionTr.en ||
          "";
      }
    } catch {}
  }

  if (districtId) {
    try {
      const { data: dRow } = await window.sb
        .from("districts")
        .select("id,name_ru,name_uz,name_en,name")
        .eq("id", districtId)
        .maybeSingle();

      if (dRow) {
        districtTr = {
          ru: String(dRow.name_ru || dRow.name || "").trim(),
          uz: String(dRow.name_uz || dRow.name_ru || dRow.name || "").trim(),
          en: String(dRow.name_en || dRow.name_ru || dRow.name || "").trim()
        };

        districtText =
          districtText ||
          districtTr.ru ||
          districtTr.uz ||
          districtTr.en ||
          "";
      }
    } catch {}
  }

  const profile = {
    id: uid,
    created_at: nowISO(),
    full_name: fullName || "",

    language: me.language_code || "ru",
    uiLanguage:
      options?.preserveUiLanguage ||
      existingProfile?.uiLanguage ||
      existingProfile?.language ||
      me.language_code ||
      "ru",

    is_school_student: regFlag,

    region_id: regionId,
    district_id: districtId,
    region_tr: regionTr,
    district_tr: districtTr,

    region: regionText,
    district: districtText,
    school: me.school || "",
    class: me.class || "",

    telegram: {
      id: me.telegram_user_id || null,
      username: null,
      first_name: me.first_name || null,
      last_name: me.last_name || null,
      photo_url: me.avatar_url || null
    },

    subjects
  };

  saveProfile(profile);
  return { ok: true, hydrated: true, subjects: subjects.length };
}

      async function syncUserSubjectsFromSupabaseIntoLocalProfile() {
  if (!window.sb) return { ok: false, reason: "no_sb" };

  await refreshActiveSubjectsCatalogFromSupabase().catch(() => null);

  const uid = await getAuthUid();
  if (!uid) return { ok: false, reason: "no_uid" };

  // Read user's subjects from DB (join subjects to get subject_key)
  let data = null;
let error = null;

({ data, error } = await window.sb
  .from("user_subjects")
  .select("subject_id, mode, is_pinned, subjects(subject_key)")
  .eq("user_id", uid));

let list = [];

if (!error) {
  // ✅ основной путь (если relationship работает)
  list = (Array.isArray(data) ? data : [])
    .map(r => ({
      key: r?.subjects?.subject_key || null,
      mode: r?.mode || "study",
      pinned: !!r?.is_pinned
    }))
    .filter(x => !!x.key);
} else {
  // ✅ fallback путь (без join)
  try { await logDbErrorToEvents(uid, "user_subjects_select_join_failed", error, {}); } catch {}

  const { data: usRows, error: usErr } = await window.sb
    .from("user_subjects")
    .select("subject_id, mode, is_pinned")
    .eq("user_id", uid);

  if (usErr) {
    try { await logDbErrorToEvents(uid, "user_subjects_select_plain_failed", usErr, {}); } catch {}
    return { ok: false, reason: "select_failed" };
  }

  const ids = Array.from(new Set((Array.isArray(usRows) ? usRows : [])
    .map(r => Number(r?.subject_id))
    .filter(n => Number.isFinite(n) && n > 0)));

  const idToKey = new Map();
  if (ids.length) {
    const { data: subjRows, error: subjErr } = await window.sb
      .from("subjects")
      .select("id, subject_key")
      .in("id", ids);

    if (subjErr) {
      try { await logDbErrorToEvents(uid, "subjects_select_for_map_failed", subjErr, { ids_count: ids.length }); } catch {}
    } else {
      (Array.isArray(subjRows) ? subjRows : []).forEach(s => {
        const id = Number(s?.id);
        const key = String(s?.subject_key || "").trim();
        if (Number.isFinite(id) && id > 0 && key) idToKey.set(id, key);
      });
    }
  }

  list = (Array.isArray(usRows) ? usRows : [])
    .map(r => ({
      key: idToKey.get(Number(r?.subject_id)) || null,
      mode: r?.mode || "study",
      pinned: !!r?.is_pinned
    }))
    .filter(x => !!x.key);
}

    const profile = loadProfile();
  if (!profile) {
    // no local profile yet (registration may still be shown)
    return { ok: true, applied: false, count: filterActiveUserSubjects(list).length };
  }

  profile.subjects = filterActiveUserSubjects(list);
  saveProfile(profile);

  return { ok: true, applied: true, count: profile.subjects.length };
}

   // ---------------------------
// Profile counts must be DB-accurate
// ---------------------------
let __profileSubjectsDbReady = false;
let __profileSubjectsDbSyncing = false;

async function ensureProfileSubjectsDbSynced() {
  if (!window.sb) return { ok: false, reason: "no_sb" };
  if (__profileSubjectsDbSyncing) return { ok: true, skipped: true };
  if (__profileSubjectsDbReady) return { ok: true, skipped: true };

  __profileSubjectsDbSyncing = true;
  try {
    const res = await syncUserSubjectsFromSupabaseIntoLocalProfile();
    if (res?.ok) __profileSubjectsDbReady = true;
    return res;
  } finally {
    __profileSubjectsDbSyncing = false;
  }
}

// ---------------------------
// Practice → Supabase (DB-first)
// - Writes practice_attempts + practice_answers
// - On failure writes practice_db_error into app_events
// ---------------------------
const _subjectIdByKeyCache = new Map();

// ✅ Home (Competitive) stats cache (in-memory)
const _homeStatsCache = new Map();
const HOME_STATS_CACHE_TTL_MS = 5 * 60 * 1000; // 5 minutes

async function getSubjectIdByKey(subjectKey) {
  const key = String(subjectKey || "").trim();
  if (!key || !window.sb) return null;

  // IMPORTANT: if cache holds a real number, return it.
  // Do NOT cache null/undefined (it becomes a “poisoned cache”).
  if (_subjectIdByKeyCache.has(key)) {
    const cached = _subjectIdByKeyCache.get(key);
    if (cached !== null && cached !== undefined) return cached;
    // cached null → ignore and re-fetch
  }

  const { data, error } = await window.sb
    .from("subjects")
    .select("id,subject_key,is_active")
    .eq("subject_key", key)
    .maybeSingle();

  if (error) {
    // log the real reason (RLS / permissions / network)
    try {
      const uid = await getAuthUid();
      await logDbErrorToEvents(uid, "subject_lookup_select_error", error, { subject_key: key });
    } catch {}
    return null;
  }

    const isActive = (data?.is_active === true);
  const id = (isActive && data?.id) ? Number(data.id) : null;

  // если предмет деактивирован — очищаем кеш и возвращаем null
  if (!isActive) {
    try { _subjectIdByKeyCache.delete(key); } catch {}
    return null;
  }

  // cache only when we have a real id
  if (id) _subjectIdByKeyCache.set(key, id);

  return id;
}

      function normalizeRpcSingleRow(data) {
  if (Array.isArray(data)) return data[0] || null;
  return data || null;
}

           function formatDateShortSafe(value) {
  try {
    if (!value) return "—";
    const d = new Date(value);
    if (Number.isNaN(d.getTime())) return "—";
    return new Intl.DateTimeFormat(currentLang(), {
      day: "numeric",
      month: "long",
      year: "numeric"
    }).format(d);
  } catch {
    return "—";
  }
}

function formatDateForLangSafe(value, lang = "ru") {
  try {
    if (!value) return "—";

    const d = new Date(value);
    if (Number.isNaN(d.getTime())) return "—";

    const months = {
      ru: ["января","февраля","марта","апреля","мая","июня","июля","августа","сентября","октября","ноября","декабря"],
      uz: ["yanvar","fevral","mart","aprel","may","iyun","iyul","avgust","sentyabr","oktyabr","noyabr","dekabr"],
      en: ["January","February","March","April","May","June","July","August","September","October","November","December"]
    };

    const safeLang = String(lang || "ru").toLowerCase();
    const pack = months[safeLang] || months.ru;

    return `${d.getDate()} ${pack[d.getMonth()]} ${d.getFullYear()}`;
  } catch {
    return "—";
  }
}

function buildCertificateDownloadName(row, ext) {
  const type = String(row?.certificate_type || "certificate").toLowerCase();
  const subjectKey = String(row?.subject_key || "subject").toLowerCase();
  const suffix =
    type === "final"
      ? "final"
      : `tour-${Number(row?.tour_no || 0) || "x"}`;

  return `iclub-${subjectKey}-${suffix}-${Number(row?.id || 0)}.${ext}`;
}
   
async function issueTourCertificateDb(attemptId) {
  try {
    if (!window.sb || !attemptId) return null;

    const { data, error } = await window.sb.rpc("issue_tour_certificate", {
      p_attempt_id: Number(attemptId)
    });

    if (error) {
      try {
        const uid = await getAuthUid();
        await logDbErrorToEvents(uid, "issue_tour_certificate_rpc", error, {
          attempt_id: Number(attemptId)
        });
      } catch {}
      return null;
    }

    return normalizeRpcSingleRow(data);
  } catch (e) {
    try {
      const uid = await getAuthUid();
      await logDbErrorToEvents(uid, "issue_tour_certificate_rpc_catch", e, {
        attempt_id: Number(attemptId)
      });
    } catch {}
    return null;
  }
}

async function issueFinalCertificateDb(userId, subjectId, seasonIdArg = null) {
  try {
    if (!window.sb || !userId || !subjectId) return null;

    const seasonId = Number(seasonIdArg || 0);

    const rpcName = seasonId > 0
      ? "issue_final_certificate_for_current_user"
      : "issue_final_certificate";

    const rpcParams = seasonId > 0
      ? {
          p_subject_id: Number(subjectId),
          p_season_id: seasonId
        }
      : {
          p_user_id: userId,
          p_subject_id: Number(subjectId)
        };

    const { data, error } = await window.sb.rpc(rpcName, rpcParams);

    if (error) {
      try {
        const uid = await getAuthUid();

        await logDbErrorToEvents(uid, "issue_final_certificate_rpc", error, {
          rpc_name: rpcName,
          p_user_id: userId,
          p_subject_id: Number(subjectId),
          p_season_id: seasonId > 0 ? seasonId : null
        });
      } catch {}

      return null;
    }

    return normalizeRpcSingleRow(data);
  } catch (e) {
    try {
      const uid = await getAuthUid();

      await logDbErrorToEvents(uid, "issue_final_certificate_rpc_catch", e, {
        p_user_id: userId,
        p_subject_id: Number(subjectId),
        p_season_id: Number(seasonIdArg || 0) || null
      });
    } catch {}

    return null;
  }
}

      function isTourGloballyClosed(row, todayIso) {
  if (!row) return false;

  const endDate = String(row?.end_date || "").trim();
  if (!endDate) return false;

  // ✅ строгое правило:
  // тур считается глобально закрытым только после фактического окончания даты тура
  return endDate < todayIso;
}
      function isTourGloballyClosedRow(row, todayIso) {
  if (!row) return false;

  const endDate = String(row?.end_date || "").trim();
  if (!endDate) return false;

  // ✅ строгое правило:
  // тур считается глобально закрытым только после фактического окончания даты тура
  return endDate < todayIso;
}
   
   const __tourCertReadyCache = new Map();

async function canIssueTourCertificateNow(tourId) {
  try {
    if (!window.sb || !tourId) return false;

    const tid = Number(tourId);
    if (!tid) return false;

    const cacheKey = `tour:${tid}`;
    const cached = __tourCertReadyCache.get(cacheKey);
    if (cached && (Date.now() - cached.ts < 60 * 1000)) {
      return !!cached.ready;
    }

    const today = new Date();
    const todayIso = `${today.getFullYear()}-${String(today.getMonth() + 1).padStart(2, "0")}-${String(today.getDate()).padStart(2, "0")}`;

        const { data, error } = await window.sb
      .from("tours")
      .select("id,end_date,is_active")
      .eq("id", tid)
      .limit(1)
      .maybeSingle();

    if (error || !data) {
      __tourCertReadyCache.set(cacheKey, { ready: false, ts: Date.now() });
      return false;
    }

    const ready = isTourGloballyClosedRow(data, todayIso);

    __tourCertReadyCache.set(cacheKey, { ready, ts: Date.now() });
    return ready;
  } catch {
    return false;
  }
}

async function ensureEligibleCertificatesIssued() {
  try {
    if (!window.sb) return;

    const uid = await getAuthUid();
    if (!uid) return;

    const { data: attempts, error } = await window.sb
      .from("tour_attempts")
      .select("id,tour_id,status")
      .eq("user_id", uid)
      .in("status", ["submitted", "time_expired"])
      .order("id", { ascending: false });

    if (error || !Array.isArray(attempts) || !attempts.length) {
      return;
    }

    const uniqueTourIds = [
      ...new Set(
        attempts
          .map(row => Number(row?.tour_id || 0))
          .filter(number => number > 0)
      )
    ];

    const tourMetaById = new Map();

    if (uniqueTourIds.length) {
      const { data: tourRows, error: toursError } = await window.sb
        .from("tours")
        .select("id,subject_id,season_id")
        .in("id", uniqueTourIds);

      if (
        !toursError &&
        Array.isArray(tourRows)
      ) {
        tourRows.forEach(row => {
          const tourId = Number(row?.id || 0);

          if (!tourId) return;

          tourMetaById.set(tourId, {
            subjectId: Number(row?.subject_id || 0),
            seasonId: Number(row?.season_id || 0)
          });
        });
      }
    }

    const seenTourIds = new Set();
    const subjectSeasonPairs = new Map();

    for (const row of attempts) {
      const attemptId = Number(row?.id || 0);
      const tourId = Number(row?.tour_id || 0);
      const tourMeta = tourMetaById.get(tourId) || null;

      const subjectId = Number(
        tourMeta?.subjectId || 0
      );

      const seasonId = Number(
        tourMeta?.seasonId || 0
      );

      if (subjectId > 0 && seasonId > 0) {
        subjectSeasonPairs.set(
          `${subjectId}:${seasonId}`,
          {
            subjectId,
            seasonId
          }
        );
      }

      if (
        attemptId > 0 &&
        tourId > 0 &&
        !seenTourIds.has(tourId)
      ) {
        seenTourIds.add(tourId);

        const tourReady =
          await canIssueTourCertificateNow(tourId);

        if (tourReady) {
          await issueTourCertificateDb(attemptId)
            .catch(() => null);
        }
      }
    }

    for (const pair of subjectSeasonPairs.values()) {
      const finalReady =
        await canIssueFinalCertificateNow(
          pair.subjectId,
          pair.seasonId
        );

      if (!finalReady) continue;

      await tryIssueFinalCertificateForSubject(
        pair.subjectId,
        pair.seasonId
      ).catch(() => null);
    }
  } catch {}
}

   
   const __finalCertReadyCache = new Map();

async function canIssueFinalCertificateNow(subjectRef, seasonIdArg = null) {
  try {
    if (!window.sb) return false;

    let sid = Number(subjectRef || 0);

    if (!Number.isFinite(sid) || sid <= 0) {
      sid = await getSubjectIdByKey(subjectRef);
    }

    if (!sid) return false;

    const seasonId =
      Number(seasonIdArg || 0) ||
      await getCurrentSeasonId();

    const cacheKey = `final:${sid}:${Number(seasonId || 0)}`;
    const cached = __finalCertReadyCache.get(cacheKey);

    if (cached && (Date.now() - cached.ts < 60 * 1000)) {
      return !!cached.ready;
    }

    let query = window.sb
      .from("tours")
      .select("tour_no,end_date,is_active,season_id")
      .eq("subject_id", sid)
      .gte("tour_no", 1)
      .lte("tour_no", 7);

    if (seasonId) {
      query = query.eq("season_id", seasonId);
    }

    const { data, error } = await query;

    if (error || !Array.isArray(data) || !data.length) {
      __finalCertReadyCache.set(cacheKey, {
        ready: false,
        ts: Date.now()
      });

      return false;
    }

    const uniqueTourNumbers = new Set(
      data
        .map(row => Number(row?.tour_no || 0))
        .filter(number =>
          Number.isFinite(number) &&
          number >= 1 &&
          number <= 7
        )
    );

    const today = new Date();
    const todayISO =
      `${today.getFullYear()}-` +
      `${String(today.getMonth() + 1).padStart(2, "0")}-` +
      `${String(today.getDate()).padStart(2, "0")}`;

    const ready =
      uniqueTourNumbers.size === 7 &&
      data.every(row => {
        const endDate = String(row?.end_date || "").trim();
        return !!endDate && endDate < todayISO;
      });

    __finalCertReadyCache.set(cacheKey, {
      ready,
      ts: Date.now()
    });

    return ready;
  } catch {
    return false;
  }
}




   async function tryIssueFinalCertificateForSubject(
  subjectId,
  seasonIdArg = null
) {
  try {
    if (!window.sb || !subjectId) return null;

    const sid = Number(subjectId);
    if (!sid) return null;

    const seasonId =
      Number(seasonIdArg || 0) ||
      await getCurrentSeasonId();

    if (!seasonId) return null;

    const ready = await canIssueFinalCertificateNow(
      sid,
      seasonId
    );

    if (!ready) return null;

    const uid = await getAuthUid();
    if (!uid) return null;

    const row = await issueFinalCertificateDb(
      uid,
      sid,
      seasonId
    );

    if (!row?.id) return null;

    if (!state.certificates) {
      state.certificates = {
        selectedId: null,
        lastIssuedId: null
      };
    }

    state.certificates.selectedId = Number(row.id);
    state.certificates.lastIssuedId = Number(row.id);
    saveState();

    return row;
  } catch {
    return null;
  }
}

   
async function fetchMyCertificatesDb(
  seasonIdArg = null
) {
  try {
    if (!window.sb) return [];

    const uid = await getAuthUid();
    if (!uid) return [];

    const seasonId =
      Number(seasonIdArg || 0) ||
      await getCurrentSeasonId();

    if (!seasonId) return [];

    const { data, error } = await window.sb
      .from("certificates")
      .select(`
        id,
        user_id,
        subject_id,
        tour_id,
        season_id,
        certificate_type,
        score,
        percent,
        participants_total,
        rank_district,
        rank_region,
        rank_country,
        certificate_number,
        language_code,
        created_at,
        completed_tours,
        total_tours
      `)
      .eq("user_id", uid)
      .eq("season_id", Number(seasonId))
      .order("created_at", { ascending: false });

    if (error) {
      try { await logDbErrorToEvents(uid, "certificates_select_failed", error, {}); } catch {}
      return [];
    }

    const rows = Array.isArray(data) ? data : [];
    if (!rows.length) return [];

    const subjectIds = Array.from(
      new Set(rows.map(r => Number(r.subject_id)).filter(n => Number.isFinite(n) && n > 0))
    );

    const tourIds = Array.from(
      new Set(rows.map(r => Number(r.tour_id)).filter(n => Number.isFinite(n) && n > 0))
    );

    const subjectMap = new Map();
    const tourMap = new Map();

    if (subjectIds.length) {
      const { data: srows, error: serr } = await window.sb
        .from("subjects")
        .select("id, subject_key, title")
        .in("id", subjectIds);

      if (!serr && Array.isArray(srows)) {
        srows.forEach(s => {
          subjectMap.set(Number(s.id), {
            subject_key: String(s.subject_key || "").trim(),
            title: String(s.title || "").trim()
          });
        });
      }
    }

    if (tourIds.length) {
      const { data: trows, error: terr } = await window.sb
        .from("tours")
        .select("id, tour_no")
        .in("id", tourIds);

      if (!terr && Array.isArray(trows)) {
        trows.forEach(tour => {
          tourMap.set(Number(tour.id), Number(tour.tour_no || 0));
        });
      }
    }

    return rows.map(row => {
      const sMeta = subjectMap.get(Number(row.subject_id)) || {};
      const subjectKey = String(sMeta.subject_key || "").trim();
      const subjectTitleText = subjectKey
        ? subjectTitle(subjectKey, sMeta.title || "")
        : (sMeta.title || `#${row.subject_id}`);

      return {
        ...row,
        subject_key: subjectKey,
        subject_title: subjectTitleText,
        tour_no: row.tour_id ? (tourMap.get(Number(row.tour_id)) || null) : null
      };
    });
  } catch {
    return [];
  }
}

function certificateTypeLabel(row) {
  if (String(row?.certificate_type || "") === "final") {
    return t("cert_final_label") || "Итоговый сертификат";
  }
  const no = Number(row?.tour_no || 0);
  return `${t("tours_tour_label") || "Тур"} ${no || "—"}`;
}

function renderCertificateStatsHtml(row) {
  const chips = [];

  if (row?.score != null) {
    chips.push(`
      <div class="cert-list-chip">
        <span class="cert-list-chip-label">${escapeHTML(t("archive_score_label") || "Балл")}</span>
        <b>${escapeHTML(String(row.score))}</b>
      </div>
    `);
  }

  if (row?.percent != null) {
    chips.push(`
      <div class="cert-list-chip">
        <span class="cert-list-chip-label">%</span>
        <b>${escapeHTML(String(row.percent))}</b>
      </div>
    `);
  }

  if (row?.rank_country != null) {
    chips.push(`
      <div class="cert-list-chip">
        <span class="cert-list-chip-label">${escapeHTML(t("rank_country_label") || "Республика")}</span>
        <b>${escapeHTML(String(row.rank_country))}</b>
      </div>
    `);
  }

  if (row?.created_at) {
    chips.push(`
      <div class="cert-list-chip">
        <span class="cert-list-chip-label">${escapeHTML(t("date_label") || "Дата")}</span>
        <b>${escapeHTML(formatDateForLangSafe(row.created_at, currentLang()))}</b>
      </div>
    `);
  }

  if (String(row?.certificate_type || "") === "final") {
    chips.push(`
      <div class="cert-list-chip">
        <span class="cert-list-chip-label">${escapeHTML(t("completed_tours_label") || "Завершено туров")}</span>
        <b>${escapeHTML(String(row.completed_tours || 0))}/${escapeHTML(String(row.total_tours || 7))}</b>
      </div>
    `);
  }

  return `<div class="cert-list-meta-row">${chips.join("")}</div>`;
}
async function canAccessCertificateRow(row) {
  if (!row) return false;

  if (String(row?.certificate_type || "") === "final") {
    return await canIssueFinalCertificateNow(
      Number(row?.subject_id || 0),
      Number(row?.season_id || 0) || null
    );
  }

  return await canIssueTourCertificateNow(Number(row?.tour_id || 0));
}

function getCertificateLockedMessage(row) {
  if (String(row?.certificate_type || "") === "final") {
    return t("certificate_final_locked_toast") || "Итоговый сертификат станет доступен после глобального завершения всех туров.";
  }

  return t("certificate_tour_locked_toast") || "Сертификат станет доступен после глобального завершения этого тура.";
}

async function filterAvailableCertificateRows(rows) {
  const src = Array.isArray(rows) ? rows : [];
  const out = [];

  for (const row of src) {
    const ok = await canAccessCertificateRow(row);
    if (ok) out.push(row);
  }

  return out;
}
   
async function renderCertificatesView() {
  const listEl = document.getElementById("certificates-list");
  if (!listEl) return;

  listEl.innerHTML = `
    <div class="empty muted">${escapeHTML(t("loading") || "Loading…")}</div>
  `;

  showAsyncOverlay(tr3(
    "Загружаем сертификаты…",
    "Sertifikatlar yuklanmoqda…",
    "Loading certificates…"
  ));

  let rawRows = [];
  let rows = [];

  try {
    await ensureEligibleCertificatesIssued();

    const certificateSeasonId =
      Number(
        state?.certificates?.selectedSeasonId ||
        0
      ) ||
      await getCurrentSeasonId();

    rawRows = await fetchMyCertificatesDb(
      certificateSeasonId
    );

    rows = await filterAvailableCertificateRows(rawRows);
  } finally {
    hideAsyncOverlay();
  }

      if (!rows.length) {
    listEl.innerHTML = `
      <div class="card" style="text-align:center; padding:20px;">
        <div style="font-size:34px; line-height:1; margin-bottom:10px;">🏅</div>
        <div style="font-weight:900; margin-bottom:6px;">
          ${escapeHTML(t("certificates_empty_title") || "Certificates are not available yet")}
        </div>
        <div class="muted" style="margin-bottom:14px;">
          ${escapeHTML(t("certificates_empty") || "No certificates yet")}
        </div>
        <div class="muted small">
          ${escapeHTML(t("certificates_empty_hint") || "Certificates become available only after the global completion of the corresponding tour or all tours.")}
        </div>
      </div>
    `;

    const oldViewer = document.getElementById("certificate-viewer-wrap");
    if (oldViewer) oldViewer.remove();
    return;
  }

          const selectedId =
    Number(state?.certificates?.selectedId || 0) ||
    0;

  if (selectedId) {
    const selectedRow = rows.find(r => Number(r.id) === selectedId) || null;

    if (!selectedRow) {
      if (!state.certificates) {
        state.certificates = { selectedId: null, lastIssuedId: null };
      }
      state.certificates.selectedId = null;
      saveState();
    } else {
      listEl.innerHTML = "";
      await renderCertificateViewer(rows);
      return;
    }
  }

  listEl.innerHTML = rows.map((row) => {
    const title = certificateTypeLabel(row);
    const subjectText = row.subject_title || (t("subject_label") || "Предмет");
    const statsHtml = renderCertificateStatsHtml(row);

    return `
      <div
        class="list-item cert-list-card"
        data-action="certificate-open"
        data-id="${Number(row.id)}"
      >
        <div class="cert-list-head">
          <div>
            <div class="cert-list-title">${escapeHTML(title)}</div>
            <div class="cert-list-subtitle">${escapeHTML(subjectText)}</div>
          </div>
        </div>

        ${statsHtml}
      </div>
    `;
  }).join("");

  const oldViewer = document.getElementById("certificate-viewer-wrap");
  if (oldViewer) oldViewer.remove();
}
      function findSelectedCertificateRow(rows) {
  const selectedId = Number(state?.certificates?.selectedId || 0);
  if (!selectedId) return null;
  return rows.find(r => Number(r.id) === selectedId) || null;
}

function buildCertificateVerifyUrl(certificateNumber) {
  const certNo = String(certificateNumber || "").trim();
  if (!certNo) return "";

  try {
    const url = new URL(window.location.href);
    url.search = "";
    url.hash = "";
    url.searchParams.set("verify_certificate", certNo);
    return url.toString();
  } catch {
    return `${window.location.origin}${window.location.pathname}?verify_certificate=${encodeURIComponent(certNo)}`;
  }
}

function getVerifyCertificateNumberFromUrl() {
  try {
    const url = new URL(window.location.href);
    return String(url.searchParams.get("verify_certificate") || "").trim();
  } catch {
    return "";
  }
}

async function ensureQriousLoaded() {
  if (window.QRious) return true;

  await new Promise((resolve, reject) => {
    const existing = document.querySelector('script[data-qrious="1"]');
    if (existing) {
      existing.addEventListener("load", resolve, { once: true });
      existing.addEventListener("error", reject, { once: true });
      return;
    }

    const s = document.createElement("script");
    s.src = "https://cdn.jsdelivr.net/npm/qrious@4.0.2/dist/qrious.min.js";
    s.async = true;
    s.dataset.qrious = "1";
    s.onload = resolve;
    s.onerror = reject;
    document.head.appendChild(s);
  });

  return !!window.QRious;
}

async function renderCertificateQr(row) {
  const mount = document.getElementById("certificate-qr");
  if (!mount) return;

  const verifyUrl = buildCertificateVerifyUrl(row?.certificate_number);
  if (!verifyUrl) {
    mount.innerHTML = "";
    return;
  }

  try {
    await ensureQriousLoaded();
    if (!window.QRious) return;

    const mobile = window.matchMedia("(max-width: 640px)").matches;
    const qrSize = mobile ? 148 : 156;

            mount.innerHTML = "";
    mount.style.position = "relative";
    mount.style.display = "flex";
    mount.style.alignItems = "center";
    mount.style.justifyContent = "center";
    mount.style.padding = "0";

    const canvas = document.createElement("canvas");
    canvas.width = qrSize;
    canvas.height = qrSize;
    canvas.style.width = `${qrSize}px`;
    canvas.style.height = `${qrSize}px`;
    canvas.style.position = "static";
    canvas.style.display = "block";
    canvas.style.margin = "0";
    canvas.style.transform = "none";

        new window.QRious({
      element: canvas,
      value: verifyUrl,
      size: qrSize,
      level: "H",
      background: "#ffffff",
      foreground: "#0f172a",
      padding: 0
    });

    mount.appendChild(canvas);
  } catch {
    mount.innerHTML = "";
  }
}

async function fetchCertificateVerificationRow(certificateNumber) {
  try {
    if (!window.sb || !certificateNumber) return null;

    const certNo = String(certificateNumber).trim();

    let baseRow = null;

    try {
      const { data, error } = await window.sb.rpc("verify_certificate", {
        p_certificate_number: certNo
      });

      if (!error) {
        baseRow = normalizeRpcSingleRow(data);
      }
    } catch {}

    const { data: certRow, error: certErr } = await window.sb
  .from("certificates")
  .select("id,user_id,subject_id,tour_id,certificate_type,score,percent,certificate_number,language_code,created_at,participant_name")
  .eq("certificate_number", certNo)
  .maybeSingle();

    if (certErr || !certRow) {
      return baseRow;
    }

    let userRow = null;
    let subjectRow = null;
    let tourRow = null;

    try {
            if (certRow.user_id) {
        const { data } = await window.sb
          .from("users")
          .select("first_name,last_name,school,class,region,district,region_id,district_id")
          .eq("id", certRow.user_id)
          .maybeSingle();

        userRow = data || null;

        if (userRow?.region_id && !userRow.region_tr) {
          try {
            const { data: rRow } = await window.sb
              .from("regions")
              .select("id,name_ru,name_uz,name_en,name")
              .eq("id", Number(userRow.region_id))
              .maybeSingle();

            if (rRow) {
              userRow.region_tr = {
                ru: String(rRow.name_ru || rRow.name || "").trim(),
                uz: String(rRow.name_uz || rRow.name_ru || rRow.name || "").trim(),
                en: String(rRow.name_en || rRow.name_ru || rRow.name || "").trim()
              };
            }
          } catch {}
        }

        if (userRow?.district_id && !userRow.district_tr) {
          try {
            const { data: dRow } = await window.sb
              .from("districts")
              .select("id,name_ru,name_uz,name_en,name")
              .eq("id", Number(userRow.district_id))
              .maybeSingle();

            if (dRow) {
              userRow.district_tr = {
                ru: String(dRow.name_ru || dRow.name || "").trim(),
                uz: String(dRow.name_uz || dRow.name_ru || dRow.name || "").trim(),
                en: String(dRow.name_en || dRow.name_ru || dRow.name || "").trim()
              };
            }
          } catch {}
        }
      }
    } catch {}

    try {
      if (certRow.subject_id) {
        const { data } = await window.sb
          .from("subjects")
          .select("id,subject_key,title")
          .eq("id", certRow.subject_id)
          .maybeSingle();

        subjectRow = data || null;
      }
    } catch {}

    try {
      if (certRow.tour_id) {
        const { data } = await window.sb
          .from("tours")
          .select("id,tour_no")
          .eq("id", certRow.tour_id)
          .maybeSingle();

        tourRow = data || null;
      }
    } catch {}

        return {
  ...(baseRow || {}),
  ...certRow,
  subject_key: baseRow?.subject_key || subjectRow?.subject_key || null,
  subject_title: baseRow?.subject_title || subjectRow?.title || null,
  tour_no: baseRow?.tour_no || tourRow?.tour_no || null,
  participant_name:
    baseRow?.participant_name ||
    certRow?.participant_name ||
    null,
  first_name: baseRow?.first_name || userRow?.first_name || null,
  last_name: baseRow?.last_name || userRow?.last_name || null,
  school: baseRow?.school || userRow?.school || null,
  class: baseRow?.class || userRow?.class || null,
  region: baseRow?.region || userRow?.region || null,
  district: baseRow?.district || userRow?.district || null,
  region_tr: baseRow?.region_tr || userRow?.region_tr || null,
  district_tr: baseRow?.district_tr || userRow?.district_tr || null
};
  } catch {
    return null;
  }
}

async function renderCertificateVerifyView(certificateNumber) {
  const resultEl = document.getElementById("certificate-verify-result");
  if (!resultEl) return;

  resultEl.innerHTML = `
    <div class="card cert-verify-card">
      <div class="muted">${escapeHTML(t("certificate_verify_loading") || "Проверяем сертификат…")}</div>
    </div>
  `;

  const row = await fetchCertificateVerificationRow(certificateNumber);

  if (!row) {
    resultEl.innerHTML = `
      <div class="card cert-verify-card cert-verify-card-empty">
        <div class="cert-verify-state">✕</div>
        <div class="cert-verify-title">${escapeHTML(t("certificate_verify_not_found_title") || "Сертификат не найден")}</div>
        <div class="muted">${escapeHTML(t("certificate_verify_not_found_text") || "Проверьте номер сертификата или QR-код.")}</div>
      </div>
    `;
    return;
  }

  const certLang = String(
    row?.language_code ||
    currentLang() ||
    "ru"
  ).toLowerCase();

  const verifyT = (key, fallback = "") => {
    try {
      const prev = window.i18n?.getLang ? window.i18n.getLang() : "ru";
      if (window.i18n?.setLang) window.i18n.setLang(certLang);
      const out = window.i18n?.t ? window.i18n.t(key) : fallback;
      if (window.i18n?.setLang) window.i18n.setLang(prev);
      return out || fallback;
    } catch {
      return fallback;
    }
  };

  const subjectText = row.subject_key
    ? subjectTitle(row.subject_key, row.subject_title || "")
    : (row.subject_title || verifyT("subject_label", "Subject"));

  const typeText =
    String(row?.certificate_type || "") === "final"
      ? verifyT("cert_final_label", "Final Certificate")
      : `${verifyT("tours_tour_label", "Tour")} ${Number(row?.tour_no || 0) || "—"}`;

  const participantName =
    String(
      row?.participant_name ||
      row?.full_name ||
      row?.name ||
      [row?.first_name, row?.last_name].filter(Boolean).join(" ").trim() ||
      ""
    ).trim() || "—";

    const pickTr = (tr, fallback) => {
    let obj = tr;
    if (typeof obj === "string") {
      try { obj = JSON.parse(obj); } catch { obj = null; }
    }
    if (obj && typeof obj === "object") {
      if (certLang === "uz") return String(obj.uz || obj.ru || fallback || "").trim();
      if (certLang === "en") return String(obj.en || obj.ru || fallback || "").trim();
      return String(obj.ru || fallback || "").trim();
    }
    return String(fallback || "").trim();
  };

  const rawSchoolText = String(row?.school || "").trim();
  const rawClassText = String(row?.class || "").trim();

  const formatSchoolValue = (value, lang) => {
    const v = String(value || "").trim();
    if (!v) return "";

    if (/^\d+$/.test(v)) {
      if (lang === "uz") return `${v}-maktab`;
      if (lang === "en") return `School ${v}`;
      return `Школа №${v}`;
    }

    return v;
  };

  const formatClassValue = (value, lang) => {
    const v = String(value || "").trim();
    if (!v) return "";

    if (/^\d+$/.test(v)) {
      if (lang === "uz") return `${v}-sinf`;
      if (lang === "en") return `Grade ${v}`;
      return `${v} класс`;
    }

    return v;
  };

  const schoolText = formatSchoolValue(rawSchoolText, certLang);
  const classText = formatClassValue(rawClassText, certLang);

  const regionText = pickTr(row?.region_tr, row?.region);
  const districtText = pickTr(row?.district_tr, row?.district);

  const schoolClassValue =
    String([schoolText, classText].filter(Boolean).join(" · ")).trim() || "—";

  const regionDistrictValue =
    String([regionText, districtText].filter(Boolean).join(" · ")).trim() || "—";

  const scoreValue = row?.score != null && row?.score !== ""
    ? escapeHTML(String(row.score))
    : "—";

  const percentValue = row?.percent != null && row?.percent !== ""
    ? `${escapeHTML(String(row.percent))}%`
    : "—";

  const dateValue = row?.created_at
    ? escapeHTML(formatDateForLangSafe(row.created_at, certLang))
    : "—";

  resultEl.innerHTML = `
    <div class="cert-verify-shell cert-verify-shell-compact">
      <div class="card cert-verify-hero cert-verify-hero-compact">
        <div class="cert-verify-hero-mark">✓</div>
        <div class="cert-verify-hero-copy">
          <div class="cert-verify-hero-title">${escapeHTML(verifyT("certificate_verify_valid", "Certificate is valid"))}</div>
          <div class="cert-verify-hero-sub">${escapeHTML(verifyT("certificate_verify_valid_sub", "The authenticity of this document has been confirmed in the iClub system."))}</div>
        </div>
      </div>

      <div class="card cert-verify-card cert-verify-card-premium cert-verify-card-compact">
        <div class="cert-verify-section-title">${escapeHTML(verifyT("certificate_verify_doc_section", "Document details"))}</div>

        <div class="cert-verify-grid cert-verify-grid-premium cert-verify-grid-compact">
          <div class="cert-verify-row cert-verify-row-premium cert-verify-row-accent cert-verify-row-compact">
            <div class="cert-verify-label">${escapeHTML(verifyT("certificate_number_label", "Certificate ID"))}</div>
            <div class="cert-verify-value cert-verify-number">${escapeHTML(String(row?.certificate_number || "—"))}</div>
          </div>

          <div class="cert-verify-grid cert-verify-grid-two">
            <div class="cert-verify-row cert-verify-row-premium cert-verify-row-compact">
              <div class="cert-verify-label">${escapeHTML(verifyT("participant_label", "Participant"))}</div>
              <div class="cert-verify-value">${escapeHTML(participantName)}</div>
            </div>

            <div class="cert-verify-row cert-verify-row-premium cert-verify-row-compact">
              <div class="cert-verify-label">${escapeHTML(verifyT("subject_label", "Subject"))}</div>
              <div class="cert-verify-value">${escapeHTML(subjectText)}</div>
            </div>
          </div>

          <div class="cert-verify-grid cert-verify-grid-two">
            <div class="cert-verify-row cert-verify-row-premium cert-verify-row-compact">
              <div class="cert-verify-label">${escapeHTML(verifyT("certificate_verify_type_label", "Certificate type"))}</div>
              <div class="cert-verify-value">${escapeHTML(typeText)}</div>
            </div>

            <div class="cert-verify-row cert-verify-row-premium cert-verify-row-compact">
              <div class="cert-verify-label">${escapeHTML(verifyT("date_label", "Date"))}</div>
              <div class="cert-verify-value">${dateValue}</div>
            </div>
          </div>
        </div>

        <div class="cert-verify-section-title">${escapeHTML(verifyT("certificate_verify_result_section", "Result"))}</div>

        <div class="cert-verify-stats cert-verify-stats-compact">
          <div class="cert-verify-stat cert-verify-stat-compact">
            <div class="cert-verify-stat-label">${escapeHTML(verifyT("certificate_result_label", "Result"))}</div>
            <div class="cert-verify-stat-value">${scoreValue}</div>
          </div>

          <div class="cert-verify-stat cert-verify-stat-compact">
            <div class="cert-verify-stat-label">${escapeHTML(verifyT("correct_answers_percent_label", "Correct answers"))}</div>
            <div class="cert-verify-stat-value">${percentValue}</div>
          </div>
        </div>

        <div class="cert-verify-section-title">${escapeHTML(verifyT("certificate_verify_participant_section", "Participant details"))}</div>

        <div class="cert-verify-grid cert-verify-grid-premium cert-verify-grid-compact">
          <div class="cert-verify-grid cert-verify-grid-two">
            <div class="cert-verify-row cert-verify-row-premium cert-verify-row-compact">
              <div class="cert-verify-label">${escapeHTML(verifyT("certificate_verify_school_class_label", "School / Grade"))}</div>
              <div class="cert-verify-value">${escapeHTML(schoolClassValue)}</div>
            </div>

            <div class="cert-verify-row cert-verify-row-premium cert-verify-row-compact">
              <div class="cert-verify-label">${escapeHTML(verifyT("certificate_verify_region_district_label", "Region / District"))}</div>
              <div class="cert-verify-value">${escapeHTML(regionDistrictValue)}</div>
            </div>
          </div>
        </div>

        </div>
    </div>
  `;
}

   function formatCertificatePlace(rank, lang) {
  const n = Number(rank);
  if (!Number.isFinite(n) || n <= 0) return "—";

  const l = String(lang || "en").toLowerCase();

  if (l === "ru") {
    return `${n}-е место`;
  }

  if (l === "uz") {
    return `${n}-o‘rin`;
  }

  const mod10 = n % 10;
  const mod100 = n % 100;

  let suffix = "th";
  if (mod10 === 1 && mod100 !== 11) suffix = "st";
  else if (mod10 === 2 && mod100 !== 12) suffix = "nd";
  else if (mod10 === 3 && mod100 !== 13) suffix = "rd";

  return `${n}${suffix} place`;
}
   
function certificateViewerHtml(row) {
  const profile = (typeof loadProfile === "function" ? loadProfile() : null) || {};

  const certLang = String(
    row?.language_code ||
    profile?.language ||
    currentLang() ||
    "en"
  ).toLowerCase();

  const certT = (key, fallback = "") => {
    try {
      const prev = window.i18n?.getLang ? window.i18n.getLang() : "ru";
      if (window.i18n?.setLang) window.i18n.setLang(certLang);
      const out = window.i18n?.t ? window.i18n.t(key) : fallback;
      if (window.i18n?.setLang) window.i18n.setLang(prev);
      return out || fallback;
    } catch {
      return fallback;
    }
  };

  const fullName =
  String(
    row?.participant_name ||
    profile?.full_name ||
    profile?.fullName ||
    profile?.fullname ||
    [profile?.first_name, profile?.last_name].filter(Boolean).join(" ") ||
    profile?.name ||
    certT("participant_label", "Participant")
  ).trim();

  const subjectText =
    String(
      row?.subject_title ||
      row?.subject_key ||
      certT("subject_label", "Subject")
    ).trim();

    const regionText = String(
    (profile?.region_tr && profile.region_tr[certLang]) ||
    profile?.region_name ||
    profile?.region ||
    row?.region ||
    certT("rank_region_label", "Region")
  ).trim();

  const districtText = String(
    (profile?.district_tr && profile.district_tr[certLang]) ||
    profile?.district_name ||
    profile?.district ||
    row?.district ||
    certT("rank_district_label", "District")
  ).trim();

    const countryPlace =
    row?.rank_country != null && row?.rank_country !== ""
      ? escapeHTML(formatCertificatePlace(row.rank_country, certLang))
      : "—";

  const regionPlace =
    row?.rank_region != null && row?.rank_region !== ""
      ? escapeHTML(formatCertificatePlace(row.rank_region, certLang))
      : "—";

  const districtPlace =
    row?.rank_district != null && row?.rank_district !== ""
      ? escapeHTML(formatCertificatePlace(row.rank_district, certLang))
      : "—";

  const isFinal = String(row?.certificate_type || "") === "final";

  return `
    <div class="card" id="certificate-viewer-card" style="padding:0; overflow:visible;">
      <div class="certificate-preview-stage">
        <div class="certificate-preview-scale" id="certificate-preview-scale">
          <div id="certificate-canvas-root" class="cert-sheet-premium">
            <div class="cert-paper-premium">
              <div class="cert-frame-inner"></div>

              <div class="cert-header-premium">
                <div class="cert-brand-premium">
                  <img src="logo.png" alt="iClub" class="cert-logo-premium" />
                  <div class="cert-brand-copy">
                    <div class="cert-brand-name-premium">iClub</div>
                    <div class="cert-brand-sub-premium">Smarter together</div>
                  </div>
                </div>
              </div>

              <div class="cert-title-top">
                ${escapeHTML(certT("certificate_awarded_label", "Official participant certificate"))}
              </div>

              <div class="cert-name-premium">
                ${escapeHTML(fullName)}
              </div>

              <div class="cert-lead-premium">
                ${escapeHTML(certT("certificate_footer_label", "Official result of an iClub platform participant"))}
              </div>

              <div class="cert-subject-premium">
                ${escapeHTML(subjectText)}
              </div>

              <div class="cert-main-premium">
                <div class="cert-main-left">
                  <div class="cert-line-premium">
                    <span class="cert-line-label-premium">${escapeHTML(certT("rank_country_label", "Country"))}:</span>
                    <span class="cert-line-value-premium">${countryPlace}</span>
                  </div>

                  <div class="cert-line-premium">
                    <span class="cert-line-label-premium">${escapeHTML(regionText)}:</span>
                    <span class="cert-line-value-premium">${regionPlace}</span>
                  </div>

                  <div class="cert-line-premium">
                    <span class="cert-line-label-premium">${escapeHTML(districtText)}:</span>
                    <span class="cert-line-value-premium">${districtPlace}</span>
                  </div>
                </div>

                <div class="cert-main-divider"></div>

                <div class="cert-main-right">
                  <div class="cert-line-premium">
                    <span class="cert-line-label-premium">${escapeHTML(certT("certificate_result_label", "Result"))}:</span>
                    <span class="cert-line-value-premium">
                      ${escapeHTML(String(row.score ?? "—"))} ${escapeHTML(certT("points_label", "points"))}
                    </span>
                  </div>

                  <div class="cert-line-premium">
                    <span class="cert-line-label-premium">${escapeHTML(certT("correct_answers_percent_label", "Correct answers"))}:</span>
                    <span class="cert-line-value-premium">
                      ${escapeHTML(String(row.percent ?? "—"))}%
                    </span>
                  </div>

                  <div class="cert-line-premium">
                    <span class="cert-line-label-premium">${escapeHTML(isFinal ? certT("completed_tours_label", "Completed Tours") : certT("tours_tour_label", "Tour"))}:</span>
                    <span class="cert-line-value-premium">
                      ${
                        isFinal
                          ? `${escapeHTML(String(row.completed_tours ?? 0))}/${escapeHTML(String(row.total_tours ?? 7))}`
                          : `${escapeHTML(String(row.tour_no ?? "—"))}`
                      }
                    </span>
                  </div>

                  <div class="cert-line-premium">
                    <span class="cert-line-label-premium">${escapeHTML(certT("participants_total_label", "Participants"))}:</span>
                    <span class="cert-line-value-premium">
                      ${escapeHTML(String(row.participants_total ?? "—"))}
                    </span>
                  </div>
                </div>
              </div>

              <div class="cert-footer-premium">
                <div class="cert-footer-left">
                  <div class="cert-footer-date">
                    ${escapeHTML(formatDateForLangSafe(row.created_at, certLang))}
                  </div>

                  <div class="cert-footer-id">
                    <span class="cert-footer-id-label">${escapeHTML(certT("certificate_number_label", "Certificate Number"))}:</span>
                    <span class="cert-footer-id-value">${escapeHTML(String(row.certificate_number || "—"))}</span>
                  </div>

                  <div class="cert-footer-line"></div>
                </div>

                <div class="cert-qr-wrap-premium">
                  <div id="certificate-qr" class="cert-qr-premium"></div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div class="cert-actions">
        <button class="btn primary" type="button" data-action="certificate-download-png" data-id="${Number(row.id)}">
          ${escapeHTML(certT("download_png_label", "Download PNG"))}
        </button>
        <button class="btn" type="button" data-action="certificate-download-pdf" data-id="${Number(row.id)}">
          ${escapeHTML(certT("download_pdf_label", "Download PDF"))}
        </button>
      </div>
    </div>
  `;
}

   function syncCertificatePreviewScale() {
  const wrap = document.getElementById("certificate-viewer-wrap");
  const stage = document.querySelector("#certificate-viewer-wrap .certificate-preview-stage");
  const scaleEl = document.getElementById("certificate-preview-scale");
  const actions = document.querySelector("#certificate-viewer-wrap .cert-actions");

  if (!wrap || !stage || !scaleEl) return;

  const baseWidth = 1365;
  const baseHeight = Math.round(baseWidth * 3 / 4); // 4:3

  const wrapWidth = Math.max(280, wrap.clientWidth || stage.clientWidth || 0);

  const viewportH = window.innerHeight || document.documentElement.clientHeight || 800;
  const topbarH = document.getElementById("topbar")?.offsetHeight || 72;
  const tabbarH = document.getElementById("tabbar")?.offsetHeight || 64;
  const actionsH = actions?.offsetHeight || 64;

  // Оставляем место под заголовок экрана, кнопки и нижний таббар
  const reservedH = topbarH + tabbarH + actionsH + 150;
  const maxPreviewH = Math.max(220, viewportH - reservedH);

  const scaleByWidth = wrapWidth / baseWidth;
  const scaleByHeight = maxPreviewH / baseHeight;
  const scale = Math.min(1, scaleByWidth, scaleByHeight);

  scaleEl.style.width = `${baseWidth}px`;
  scaleEl.style.height = `${baseHeight}px`;
  scaleEl.style.transform = `scale(${scale})`;

  stage.style.height = `${Math.round(baseHeight * scale)}px`;
}
   
async function renderCertificateViewer(rows) {
  const listEl = document.getElementById("certificates-list");
  if (!listEl) return;

  try { await ensureProfileGeoTranslationsHydrated(); } catch {}

  const selectedId = Number(state?.certificates?.selectedId || 0);
  const oldViewer = document.getElementById("certificate-viewer-wrap");
  if (oldViewer) oldViewer.remove();

  if (!selectedId) return;

  const selected =
    (rows || []).find(r => Number(r.id) === selectedId) ||
    null;

  if (!selected) return;

      const wrap = document.createElement("div");
  wrap.id = "certificate-viewer-wrap";
  wrap.className = "certificate-viewer-wrap-premium";
  wrap.style.marginTop = "16px";
  wrap.innerHTML = certificateViewerHtml(selected);

    listEl.parentNode.appendChild(wrap);
  await renderCertificateQr(selected);

  syncCertificatePreviewScale();
  requestAnimationFrame(() => {
    syncCertificatePreviewScale();
    requestAnimationFrame(syncCertificatePreviewScale);
  });

  if (!window.__certificatePreviewResizeBound) {
    window.addEventListener("resize", syncCertificatePreviewScale, { passive: true });
    window.__certificatePreviewResizeBound = true;
  }
}

async function ensureHtml2CanvasLoaded() {
  if (window.html2canvas) return true;
  await new Promise((resolve, reject) => {
    const s = document.createElement("script");
    s.src = "https://cdn.jsdelivr.net/npm/html2canvas@1.4.1/dist/html2canvas.min.js";
    s.onload = resolve;
    s.onerror = reject;
    document.head.appendChild(s);
  });
  return !!window.html2canvas;
}

async function ensureJsPdfLoaded() {
  if (window.jspdf?.jsPDF) return true;
  await new Promise((resolve, reject) => {
    const s = document.createElement("script");
    s.src = "https://cdn.jsdelivr.net/npm/jspdf@2.5.1/dist/jspdf.umd.min.js";
    s.onload = resolve;
    s.onerror = reject;
    document.head.appendChild(s);
  });
  return !!window.jspdf?.jsPDF;
}

function triggerBlobDownload(blob, filename) {
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = url;
  a.download = filename;
  document.body.appendChild(a);
  a.click();
  setTimeout(() => {
    try { URL.revokeObjectURL(url); } catch {}
    try { a.remove(); } catch {}
  }, 1500);
}

async function buildCertificateCanvasBlob(kind) {
  const root = document.getElementById("certificate-canvas-root");
  const stage = document.querySelector("#certificate-viewer-wrap .certificate-preview-stage");
  const scaleEl = document.getElementById("certificate-preview-scale");

  if (!root) {
    showToast(t("certificates_empty") || "Пока сертификатов нет.");
    return null;
  }

  await ensureHtml2CanvasLoaded();

  const prevRootWidth = root.style.width;
  const prevRootMaxWidth = root.style.maxWidth;
  const prevRootMinWidth = root.style.minWidth;
  const prevRootPadding = root.style.padding;
  const prevRootOverflow = root.style.overflow;

  const prevStageHeight = stage ? stage.style.height : "";
  const prevStageOverflow = stage ? stage.style.overflow : "";
  const prevStageDisplay = stage ? stage.style.display : "";
  const prevStageJustify = stage ? stage.style.justifyContent : "";
  const prevStageAlign = stage ? stage.style.alignItems : "";

  const prevScaleTransform = scaleEl ? scaleEl.style.transform : "";
  const prevScaleWidth = scaleEl ? scaleEl.style.width : "";
  const prevScaleHeight = scaleEl ? scaleEl.style.height : "";
  const prevScaleOrigin = scaleEl ? scaleEl.style.transformOrigin : "";

  root.classList.add("cert-export-mode");
  root.style.width = "1365px";
  root.style.maxWidth = "1365px";
  root.style.minWidth = "1365px";
  root.style.padding = "0";
  root.style.overflow = "visible";

  if (stage) {
    stage.style.height = "auto";
    stage.style.overflow = "visible";
    stage.style.display = "block";
    stage.style.justifyContent = "initial";
    stage.style.alignItems = "initial";
  }

  if (scaleEl) {
    scaleEl.style.transform = "none";
    scaleEl.style.width = "1365px";
    scaleEl.style.height = `${Math.round(1365 * 3 / 4)}px`;
    scaleEl.style.transformOrigin = "top left";
  }

  try {
    await new Promise((resolve) => requestAnimationFrame(() => requestAnimationFrame(resolve)));

    const canvas = await window.html2canvas(root, {
      backgroundColor: "#f6f3eb",
      scale: 3,
      useCORS: true
    });

    if (kind === "png") {
      return await new Promise((resolve) => canvas.toBlob(resolve, "image/png"));
    }

    return canvas;
  } finally {
    root.classList.remove("cert-export-mode");
    root.style.width = prevRootWidth;
    root.style.maxWidth = prevRootMaxWidth;
    root.style.minWidth = prevRootMinWidth;
    root.style.padding = prevRootPadding;
    root.style.overflow = prevRootOverflow;

    if (stage) {
      stage.style.height = prevStageHeight;
      stage.style.overflow = prevStageOverflow;
      stage.style.display = prevStageDisplay;
      stage.style.justifyContent = prevStageJustify;
      stage.style.alignItems = prevStageAlign;
    }

    if (scaleEl) {
      scaleEl.style.transform = prevScaleTransform;
      scaleEl.style.width = prevScaleWidth;
      scaleEl.style.height = prevScaleHeight;
      scaleEl.style.transformOrigin = prevScaleOrigin;
    }
  }
}

async function downloadCertificateAsPng(row) {
  const btn = document.querySelector(`[data-action="certificate-download-png"][data-id="${Number(row.id)}"]`);

  try {
    if (btn) {
      btn.disabled = true;
      btn.classList.add("is-loading");
    }

    showCertificateDownloadOverlay();
    await waitForOverlayPaint();

    const blob = await buildCertificateCanvasBlob("png");
    if (!blob) return;

    triggerBlobDownload(blob, buildCertificateDownloadName(row, "png"));
  } catch {
    showToast(t("save_failed_try_again") || "Не удалось сохранить. Проверьте интернет.");
  } finally {
    if (btn) {
      btn.disabled = false;
      btn.classList.remove("is-loading");
    }
    hideCertificateDownloadOverlay();
  }
}

async function downloadCertificateAsPdf(row) {
  const btn = document.querySelector(`[data-action="certificate-download-pdf"][data-id="${Number(row.id)}"]`);

  try {
    if (btn) {
      btn.disabled = true;
      btn.classList.add("is-loading");
    }

    showCertificateDownloadOverlay();
    await waitForOverlayPaint();

    const canvas = await buildCertificateCanvasBlob("pdf");
    if (!canvas) return;

    await ensureJsPdfLoaded();

    const { jsPDF } = window.jspdf;

    const pdfOrientation = canvas.width > canvas.height ? "landscape" : "portrait";

    const pdf = new jsPDF({
      orientation: pdfOrientation,
      unit: "px",
      format: [canvas.width, canvas.height],
      hotfixes: ["px_scaling"]
    });

    const imgData = canvas.toDataURL("image/png");
    pdf.addImage(imgData, "PNG", 0, 0, canvas.width, canvas.height, undefined, "NONE");
    pdf.save(buildCertificateDownloadName(row, "pdf"));
  } catch {
    showToast(t("save_failed_try_again") || "Не удалось сохранить. Проверьте интернет.");
  } finally {
    if (btn) {
      btn.disabled = false;
      btn.classList.remove("is-loading");
    }
    hideCertificateDownloadOverlay();
  }
}
   
async function logDbErrorToEvents(uid, where, error, extraPayload = {}) {
  try {
    if (!window.sb || !uid) return;

    const canWriteEvent = await hasDbUserRow(uid);
    if (!canWriteEvent) return;

    await window.sb.from("app_events").insert({
      user_id: uid,
      event_type: "practice_db_error",
      payload: {
        where: String(where || "unknown"),
        message: String(error?.message || error || "unknown"),
        code: error?.code || null,
        details: error?.details || null,
        hint: error?.hint || null,
        ...extraPayload
      }
    });
  } catch {}
}

async function savePracticeAttemptToSupabase(attempt, quiz) {
  if (!window.sb) return { ok: false, reason: "no_sb" };

  const uid = await getAuthUid();
  if (!uid) return { ok: false, reason: "no_uid" };

  const subjectId = await getSubjectIdByKey(quiz?.subjectKey);
  if (!subjectId) {
    await logDbErrorToEvents(uid, "subject_lookup", { message: "subject_id not found" }, { subject_key: quiz?.subjectKey });
    return { ok: false, reason: "no_subject_id" };
  }

  // Build answers payload:
  // - MCQ: quiz.answers[i] is usually 0/1/2/3 → store as "0"/"1"/"2"/"3" (TEXT in DB, but it's still the index)
  // - INPUT: quiz.answers[i] is text → store as text
  const details = Array.isArray(attempt?.details) ? attempt.details : [];
  const answers = Array.isArray(quiz?.answers) ? quiz.answers : [];

  const answersPayload = details.map((d, i) => {
  const rawUA = answers[i];

  let userAnswer = "";
  if (rawUA !== null && rawUA !== undefined) {
    if (String(d?.type || "").toLowerCase() === "mcq") {
      const idx = Number(rawUA);
      userAnswer = idxToLetter(idx) || String(rawUA);
    } else {
      userAnswer = String(rawUA);
    }
  }

  return {
    question_id: Number(d?.id),
    user_answer: userAnswer,
    is_correct: !!d?.isCorrect,
    time_spent: Math.max(0, Math.round(Number(d?.timeSpent) || 0))
  };
}).filter(r => Number.isFinite(r.question_id) && r.question_id > 0);

  // =========================
  // RPC path (atomic + anti-duplicate via unique index + ON CONFLICT)
  // =========================
  try {
    const rpcCall = async () => {
      const { data, error } = await window.sb.rpc("submit_practice_attempt", {
        p_subject_id: subjectId,
        p_score: Number(attempt?.score) || 0,
        p_percent: Number(attempt?.percent) || 0,
        p_time_seconds: Number(attempt?.durationSec) || 0,
        p_answers: answersPayload
      });
      if (error) throw error;
      return data;
    };

    const attemptIdRpc = await dbWriteWithRetry(rpcCall, { tries: 3, baseDelayMs: 350 });

    const attemptId = (attemptIdRpc !== null && attemptIdRpc !== undefined) ? Number(attemptIdRpc) : null;
    if (!attemptId) {
      await logDbErrorToEvents(uid, "practice_rpc_bad_id", { message: "RPC returned empty attempt_id" }, { subject_id: subjectId });
      return { ok: false, reason: "rpc_bad_id" };
    }

    return { ok: true, attemptId, subjectId, via: "rpc" };
  } catch (e) {
    // If RPC is missing or fails — fallback to legacy so UX never breaks
    try { await logDbErrorToEvents(uid, "practice_rpc_failed", e, { subject_id: subjectId }); } catch {}
  }

  // =========================
  // Legacy fallback (safe): current 2-step method
  // =========================

  // 1) insert attempt WITH returning id
  const insertAttemptPayload = {
    user_id: uid,
    subject_id: subjectId,
    score: Number(attempt?.score) || 0,
    percent: Number(attempt?.percent) || 0,
    time_seconds: Number(attempt?.durationSec) || 0
  };

  let insRow = null;
  let insErr = null;

  try {
    insRow = await dbWriteWithRetry(async () => {
      const { data, error } = await window.sb
        .from("practice_attempts")
        .insert(insertAttemptPayload)
        .select("id")
        .single();

      if (error) throw error;
      return data || null;
    }, { tries: 3, baseDelayMs: 350 });
  } catch (e) {
    insErr = e;
  }

  if (!insRow?.id) {
    await logDbErrorToEvents(
      uid,
      "attempt_insert",
      insErr || { message: "no_returning_id" },
      { subject_id: subjectId }
    );
    return { ok: false, reason: "attempt_insert_failed" };
  }

  const attemptId = Number(insRow.id);

    const rows = answersPayload.map(r => ({
    attempt_id: attemptId,
    question_id: Number(r?.question_id),
    user_answer: r?.user_answer ?? null,
    is_correct: !!r?.is_correct,
    time_spent: Math.max(0, Math.round(Number(r?.time_spent) || 0))
  })).filter(r => Number.isFinite(r.question_id) && r.question_id > 0);

  if (rows.length) {
    let ansErr = null;

    try {
      await dbWriteWithRetry(async () => {
        const { error } = await window.sb
          .from("practice_answers")
          .insert(rows);

        if (error) throw error;
        return true;
      }, { tries: 3, baseDelayMs: 350 });
    } catch (e) {
      ansErr = e;
    }

    if (ansErr) {
      await logDbErrorToEvents(uid, "answers_insert", ansErr, { attempt_id: attemptId, rows: rows.length });

      // cleanup: не оставляем сиротскую попытку без ответов
      try {
        await dbWriteWithRetry(async () => {
          const { error } = await window.sb
            .from("practice_attempts")
            .delete()
            .eq("id", attemptId)
            .eq("user_id", uid);
          if (error) throw error;
          return true;
        }, { tries: 2, baseDelayMs: 250 });
      } catch {}

      return { ok: false, reason: "answers_insert_failed" };
    }
  }

  return { ok: true, attemptId, subjectId, via: "legacy" };
}

   async function getPracticeDbMetricsBySubjectKey(subjectKey) {
  if (!window.sb) return { ok: false, reason: "no_sb" };

  const uid = await getAuthUid();
  if (!uid) return { ok: false, reason: "no_uid" };

  const subjectId = await getSubjectIdByKey(subjectKey);
  if (!subjectId) return { ok: false, reason: "no_subject_id" };

  // Pull last 30 attempts to compute streak reliably
  const { data: rows, error } = await window.sb
    .from("practice_attempts")
    .select("percent,created_at")
    .eq("user_id", uid)
    .eq("subject_id", subjectId)
    .order("created_at", { ascending: false })
    .limit(30);

  if (error) {
    await logDbErrorToEvents(uid, "practice_metrics_select", error, { subject_id: subjectId });
    return { ok: false, reason: "select_failed", subjectId };
  }

  const attempts = Array.isArray(rows) ? rows : [];

  // Mastery: avg percent over last 10
  const last10 = attempts.slice(0, 10);
  const mastery = last10.length
    ? Math.round(last10.reduce((s, r) => s + (Number(r.percent) || 0), 0) / last10.length)
    : 0;

  // Focus streak: consecutive days with at least 1 attempt
  // Normalize to YYYY-MM-DD in UTC
  const days = [];
  for (const r of attempts) {
    const d = new Date(r.created_at);
    if (Number.isNaN(d.getTime())) continue;
    const y = d.getUTCFullYear();
    const m = String(d.getUTCMonth() + 1).padStart(2, "0");
    const dd = String(d.getUTCDate()).padStart(2, "0");
    days.push(`${y}-${m}-${dd}`);
  }

  const uniqDays = Array.from(new Set(days)); // already in desc order due to attempts order
  let streak = 0;

  if (uniqDays.length) {
    // Compare day-by-day starting from most recent day
    const toDay = (s) => {
      const [y, m, d] = s.split("-").map(Number);
      return Date.UTC(y, m - 1, d) / 86400000;
    };

    let prev = toDay(uniqDays[0]);
    streak = 1;

    for (let i = 1; i < uniqDays.length; i++) {
      const cur = toDay(uniqDays[i]);
      if (prev - cur === 1) {
        streak += 1;
        prev = cur;
      } else {
        break;
      }
    }
  }

  return { ok: true, subjectId, mastery, streak };
}

async function getMyUserRow(uid) {
  if (!uid) return null;
  const { data, error } = await window.sb
    .from("users")
    .select("id,first_name,last_name,avatar_url,is_school_student,region,district,region_id,district_id,country_code,country,school,class")
    .eq("id", uid)
    .maybeSingle();
  if (error) return null;
  return data || null;
}
async function getMyCompetitiveSubjects(uid) {
  if (!uid) return [];
  const { data, error } = await window.sb
    .from("user_subjects")
    .select("subject_id,mode")
    .eq("user_id", uid)
    .eq("mode", "competitive");
  if (error) return [];
  return Array.isArray(data) ? data : [];
}

async function loadRatingsSubjectsForSelect() {
  // показываем все активные main subjects (competitive по смыслу)
  const { data, error } = await window.sb
    .from("subjects")
    .select("id,subject_key,title,type,is_active")
    .eq("is_active", true)
    .eq("type", "main")
    .order("title", { ascending: true });

  if (error) return [];
  return Array.isArray(data) ? data : [];
}

async function loadRatingsToursForSubject(subjectId) {
  if (!subjectId || !window.sb) return [];

  let subjectKey = null;

  // 1) Сначала узнаём subject_key по id
  try {
    const { data: subjRow, error: subjErr } = await window.sb
      .from("subjects")
      .select("id,subject_key")
      .eq("id", subjectId)
      .maybeSingle();

    if (!subjErr && subjRow?.subject_key) {
      subjectKey = String(subjRow.subject_key).trim();
    }
  } catch {}

  // 2) Предпочтительный путь: через subjects!inner(subject_key)
  if (subjectKey) {
    try {
      const { data, error } = await window.sb
        .from("tours")
        .select("id,subject_id,tour_no,is_active,start_date,end_date,subjects!inner(subject_key)")
        .eq("subjects.subject_key", subjectKey)
        .order("tour_no", { ascending: true });

      if (!error && Array.isArray(data) && data.length) {
        return data;
      }
    } catch {}
  }

  // 3) Fallback: старый путь по subject_id
  try {
    const { data, error } = await window.sb
      .from("tours")
      .select("id,subject_id,tour_no,is_active,start_date,end_date")
      .eq("subject_id", subjectId)
      .order("tour_no", { ascending: true });

    if (error) return [];
    return Array.isArray(data) ? data : [];
  } catch {
    return [];
  }
}

function renderRatingsSelectOptions(selectEl, items, { placeholder = null } = {}) {
  if (!selectEl) return;
  selectEl.innerHTML = "";

  if (placeholder) {
    const opt = document.createElement("option");
    opt.value = "";
    opt.textContent = placeholder;
    selectEl.appendChild(opt);
  }

  items.forEach(it => {
  const opt = document.createElement("option");
  opt.value = String(it.value);
  opt.textContent = String(it.label);

  if (it.tourNo != null) {
    opt.dataset.tourNo = String(it.tourNo);
  }

  selectEl.appendChild(opt);
});
}

async function ensureRatingsBoot() {
  if (ratingsState._booted) return;

  if (!window.sb) {
    // если Supabase ещё не поднялся — просто выйдем, UI покажет заглушку
    return;
  }

  const subjectSelect = document.getElementById("ratings-subject");
  const tourSelect = document.getElementById("ratings-tour");

  // 1) subjects
  const subjects = await loadRatingsSubjectsForSelect();
  const subjectItems = subjects.map(s => ({
    value: s.id,
    label: subjectTitle(s.subject_key, s.title)
  }));

  renderRatingsSelectOptions(subjectSelect, subjectItems, {
    placeholder: t("loading")
  });

  // 2) subject: keep saved subject if it still exists, otherwise choose default
const uid = await getAuthUid();
const myComp = await getMyCompetitiveSubjects(uid);

const savedSubjectId = Number(ratingsState.subjectId || state?.ratings?.subjectId || 0);
const savedSubjectExists = savedSubjectId > 0 && subjects.some(s => Number(s?.id || 0) === savedSubjectId);

const defaultSubjectId = (myComp?.[0]?.subject_id) || (subjects?.[0]?.id) || null;
ratingsState.subjectId = savedSubjectExists
  ? savedSubjectId
  : (defaultSubjectId ? Number(defaultSubjectId) : null);

// отрисуем subjects без placeholder
renderRatingsSelectOptions(subjectSelect, subjectItems);
if (ratingsState.subjectId && subjectSelect) subjectSelect.value = String(ratingsState.subjectId);
   
  // 3) tours for subject
  const tours = await loadRatingsToursForSubject(ratingsState.subjectId);
  const tourItems = [
    { value: "__all__", label: t("ratings_all_tours") || "All tours" },
    ...tours.map(tt => ({ value: tt.id, label: `Tour ${tt.tour_no}`, tourNo: Number(tt.tour_no || 0) }))
  ];
  renderRatingsSelectOptions(tourSelect, tourItems);

// keep saved tour by tour number, because tour_id is different per subject
const savedTourNo =
  ratingsState.tourNo && ratingsState.tourNo !== "__all__"
    ? Number(ratingsState.tourNo)
    : null;

const savedTourRow = savedTourNo
  ? tours.find(tt => Number(tt?.tour_no || 0) === Number(savedTourNo))
  : null;

ratingsState.tourId = savedTourRow?.id ? Number(savedTourRow.id) : "__all__";
ratingsState.tourNo = savedTourRow?.tour_no ? Number(savedTourRow.tour_no) : "__all__";

if (tourSelect) tourSelect.value = String(ratingsState.tourId || "__all__");

saveRatingsFiltersToState();
   
  ratingsState._booted = true;
}

  async function renderRatings() {
  const listEl = $("#ratings-list");
  if (!listEl) return;

  listEl.innerHTML = "";

  const loadingEl = $("#ratings-loading");

  const mybar = $("#ratings-mybar");
  const myRankEl = $("#ratings-mybar-rank");
  const myTotalEl = $("#ratings-mybar-total");
  const myScoreEl = $("#ratings-mybar-score");
  const myTimeEl = $("#ratings-mybar-time");
  const hintEl = $("#ratings-viewer-hint");

  const q = String(ratingsState.q || "").trim().toLowerCase();

  const token = ++ratingsState._token;

const showLoading = () => { if (loadingEl) loadingEl.style.display = "flex"; };
const hideLoading = () => {
  if (token !== ratingsState._token) return;
  if (loadingEl) loadingEl.style.display = "none";
};

  // total participants (used for "out of N")
  let totalN = 0;

    function applyRatingsNamePolicy(rows) {
    const arr = Array.isArray(rows) ? rows : [];
    const counts = new Map();

    for (const r of arr) {
      const full = String(r?.name || "—").trim();
      const first = full.split(/\s+/)[0] || "—";
      counts.set(first, (counts.get(first) || 0) + 1);
    }

    for (const r of arr) {
      const full = String(r?.name || "—").trim();
      const first = full.split(/\s+/)[0] || "—";
      const dup = (counts.get(first) || 0) > 1;

      // по умолчанию — только имя, но если имя дублируется — показываем полное ФИО
      r.display_name = (first !== "—" && !dup) ? first : (full || "—");
    }
  }

  const renderRowHTML = (row) => {
    const topClass =
      row.rank === 1 ? "is-top1" :
      (row.rank === 2 ? "is-top2" :
      (row.rank === 3 ? "is-top3" : ""));

    const displayName = row.display_name || row.name || "—";

    return `
      <div class="lb-row">
        <div class="lb-rank">
          <div class="lb-rank-badge ${topClass}">${row.rank}</div>
        </div>

        <div class="lb-student">
          <div class="lb-student-text">
            <div class="lb-name">${escapeHTML(displayName)}</div>
            <div class="lb-meta">${escapeHTML(row.meta || "")}</div>
          </div>
        </div>

        <div class="lb-score">${row.score}</div>
        <div class="lb-time">${escapeHTML(row.time)}</div>
      </div>
    `;
  };

  const renderSection = (title, rows, subText) => {
    if (!rows || !rows.length) return "";
    const sub = subText ? `<div class="lb-section-sub">${escapeHTML(subText)}</div>` : `<div class="lb-section-sub"></div>`;
    return `
      <div class="lb-section">
        <div class="lb-section-head">
          <div class="lb-section-title">${escapeHTML(title)}</div>
          ${sub}
        </div>
        ${rows.map(renderRowHTML).join("")}
      </div>
    `;
  };

    // ✅ Ties are valid (several people can be #1).
  // Dedupe ONLY the same person across sections (Top/Around/Bottom), not by rank.
  const rowDedupeKey = (r) => {
    if (!r) return "";
    if (r.user_id) return `u:${String(r.user_id)}`;
    if (r.telegram_user_id) return `tg:${String(r.telegram_user_id)}`;
    return `f:${String(r.name || "")}|${String(r.score ?? "")}|${String(r.total_time ?? "")}|${String(r.time ?? "")}`;
  };

  const dedupeByRank = (rows) => {
    if (!Array.isArray(rows)) return [];
    const seen = new Set();
    const out = [];
    for (const r of rows) {
      const k = rowDedupeKey(r);
      if (!k || seen.has(k)) continue;
      seen.add(k);
      out.push(r);
    }
    return out;
  };

  // сегменты
  $$(".lb-segment .seg-btn").forEach(btn => {
    const active = btn.dataset.scope === ratingsState.scope;
    btn.classList.toggle("is-active", active);
    btn.setAttribute("aria-selected", active ? "true" : "false");
  });

  // если Supabase ещё не готов
  if (!window.sb) {
    listEl.innerHTML = `<div class="empty muted">${t("loading")}</div>`;
    if (mybar) mybar.style.display = "none";
    if (hintEl) hintEl.style.display = "none";
    hideLoading();
    return;
  }

    // boot selects (once)
  await ensureRatingsBoot();

  // loading UI
  listEl.innerHTML = "";
  showLoading();
  if (mybar) mybar.style.display = "none";

  // user / participant
    const uid = await getAuthUid();
  const me = await getMyUserRow(uid);
  const myComp = await getMyCompetitiveSubjects(uid);
  const isParticipant = !!me?.is_school_student && (myComp?.length > 0);

  const myRegionId = Number(me?.region_id || 0) > 0 ? String(me.region_id) : "";
  const myDistrictId = Number(me?.district_id || 0) > 0 ? String(me.district_id) : "";

  const myRegionText = String(me?.region || "").trim();
  const myDistrictText = String(me?.district || "").trim();

  const hasMyRegion = !!myRegionId || !!myRegionText;
  const hasMyDistrict = !!myDistrictId || !!myDistrictText;

  const sameMyRegion = (u) => {
    if (myRegionId) return String(u?.region_id ?? "") === myRegionId;
    return !!myRegionText && String(u?.region || "").trim() === myRegionText;
  };

  const sameMyDistrict = (u) => {
    if (myDistrictId) return String(u?.district_id ?? "") === myDistrictId;
    return !!myDistrictText && String(u?.district || "").trim() === myDistrictText;
  };

  const applyLocalRatingsScope = (rows) => {
    const arr = Array.isArray(rows) ? rows : [];

    if (ratingsState.scope === "district") {
      return arr.filter(r => sameMyDistrict(r?.users || r));
    }

    if (ratingsState.scope === "region") {
      return arr.filter(r => sameMyRegion(r?.users || r));
    }

    return arr;
  };

  // hint
  if (hintEl) hintEl.style.display = isParticipant ? "none" : "block";

  // если у меня реально нет district/region — только тогда принудительно country
  if (
    (ratingsState.scope === "district" && !hasMyDistrict) ||
    (ratingsState.scope === "region" && !hasMyRegion)
  ) {
    ratingsState.scope = "country";
    saveRatingsFiltersToState();

    $$(".lb-segment .seg-btn").forEach(btn => {
      const active = btn.dataset.scope === ratingsState.scope;
      btn.classList.toggle("is-active", active);
      btn.setAttribute("aria-selected", active ? "true" : "false");
    });
  }

  // guards
  if (!ratingsState.subjectId) {
    hideLoading();
    listEl.innerHTML = `<div class="empty muted">No subjects.</div>`;
    return;
  }

  const scopeRankType = mapScopeToRankType(ratingsState.scope);

 // =========================
// A) конкретный тур: ratings_cache
// =========================
if (ratingsState.tourId && ratingsState.tourId !== "__all__") {
  const tourId = Number(ratingsState.tourId);

       // If cache is empty for this tour+scope — fallback to tour_attempts (so Tour 1 works even without cache build)
    const cacheProbe = await window.sb
      .from("ratings_cache")
      .select("rank_no")
      .eq("tour_id", tourId)
      .eq("rank_type", scopeRankType)
      .limit(1);

    if (token !== ratingsState._token) return;

    // ratings_cache безопасен для country.
    // Для district/region считаем live из tour_attempts, потому что cache не хранит group key.
    const cacheHasData =
      ratingsState.scope === "country" &&
      !cacheProbe?.error &&
      Array.isArray(cacheProbe?.data) &&
      cacheProbe.data.length > 0;

    if (!cacheHasData) {
      // -------- fallback: compute leaderboard from tour_attempts --------
            const attemptsRes = await window.sb
  .from("tour_attempts")
  .select("user_id,score,total_time,status,users(first_name,last_name,school,class,region,district,region_id,district_id)")
  .eq("tour_id", tourId);
if (token !== ratingsState._token) return;

if (attemptsRes?.error) {
  hideLoading();
  listEl.innerHTML = `
    <div class="empty muted">
      ${escapeHTML(t("ratings_load_error"))}
      <div class="small" style="margin-top:8px">${escapeHTML(t("support_route_after_retry"))}</div>
    </div>
  `;
  return;
}

          const raw = Array.isArray(attemptsRes?.data) ? attemptsRes.data : [];
      await enrichRatingsUsersGeoTranslations(raw);

      // keep only completed attempts (different DB variants)
      const OK_STATUSES = new Set(["submitted", "time_expired", "anti_cheat", "finished"]);
      let pool = raw.filter(r => {
        const st = String(r?.status || "").trim();
        return !st || OK_STATUSES.has(st);
      });

                  // scope filter via user profile: ID-first, text fallback
      pool = applyLocalRatingsScope(pool);

      // sort: score desc, time asc
      pool.sort((a, b) => {
        const ds = Number(b.score || 0) - Number(a.score || 0);
        if (ds !== 0) return ds;
        return Number(a.total_time || 0) - Number(b.total_time || 0);
      });

      const rowsAll = pool.map((r, idx) => {
        const u = r.users || {};
        const timeVal = Number(r.total_time || 0);
        return {
          rank: idx + 1,
          name: getFullName(u),
          meta: buildUserMeta(u),
          score: Number(r.score || 0),
          total_time: timeVal,
          time: formatSecondsToMMSS(timeVal),
          user_id: r.user_id
        };
      });

      totalN = rowsAll.length;

      // search inside fallback (same search UX)
      const qq = String(ratingsState.q || "").trim().toLowerCase();
      if (qq) {
        const filtered = rowsAll.filter(x => {
          const blob = `${x.name || ""} ${x.meta || ""}`.toLowerCase();
          return blob.includes(qq);
        });

        applyRatingsNamePolicy(filtered);

        const resetLabel = t("ratings_reset") || (t("btn_reset") || "Reset");
        const resultsLabel = t("ratings_results") || "Results";
        const htmlRows = filtered.slice(0, 200).map(renderRowHTML).join("");

        listEl.innerHTML = `
          <div class="lb-section-head lb-results-head">
            <div class="lb-section-title">${escapeHTML(resultsLabel)}</div>

            <button type="button" class="lb-search-reset" id="ratings-reset-search" aria-label="Reset search">
              <span class="lb-reset-label">${escapeHTML(resetLabel)}</span>
              <span class="lb-reset-q">“${escapeHTML(String(qq))}”</span>
              <span class="lb-reset-x">✕</span>
            </button>
          </div>

          ${htmlRows || `<div class="empty muted">${t("ratings_empty") || "Ничего не найдено."}</div>`}
        `;

        if (mybar) mybar.style.display = "none";
        hideLoading();
        return;
      }

      // normal sections (Top / Around / Bottom)
      applyRatingsNamePolicy(rowsAll);

      const topRows = rowsAll.slice(0, 10);

      let aroundRows = [];
      let myIndex = -1;
      if (isParticipant && uid) myIndex = rowsAll.findIndex(r => String(r.user_id) === String(uid));
      if (isParticipant && myIndex >= 0) {
        const lo = Math.max(0, myIndex - 2);
        const hi = Math.min(rowsAll.length, myIndex + 3);
        aroundRows = rowsAll.slice(lo, hi);
      }

      const bottomRows = rowsAll.length > 13 ? rowsAll.slice(-3) : [];
      const shouldShowBottom = bottomRows.length && bottomRows.some(r => r.rank > 10);

      const topKeys = new Set(dedupeByRank(topRows).map(rowDedupeKey));
      aroundRows = (aroundRows || []).filter(r => !topKeys.has(rowDedupeKey(r)));

      const aroundKeys = new Set(dedupeByRank(aroundRows).map(rowDedupeKey));
       
      const bottomClean = (bottomRows || []).filter(r => !topKeys.has(rowDedupeKey(r)) && !aroundKeys.has(rowDedupeKey(r)));

      listEl.innerHTML =
        renderSection(t("ratings_top") || "Top 10", dedupeByRank(topRows), "") +
        (isParticipant && myIndex >= 0 ? renderSection(t("ratings_around") || "Around me", dedupeByRank(aroundRows), "±2") : "") +
        (shouldShowBottom ? renderSection(
          t("ratings_bottom") || "Bottom 3",
          dedupeByRank(bottomClean),
          totalN ? t("ratings_of_total", { total: totalN }) : ""
        ) : "");

            // My rank (only if participant)
      if (isParticipant && mybar) {
        if (myIndex >= 0) {
          const mine = rowsAll[myIndex];
          myRankEl.textContent = String(mine.rank);

          const totalLabel = t("ratings_total_participants");
          if (myTotalEl) myTotalEl.textContent = totalN ? `${totalLabel}: ${totalN}` : "—";
          if (myScoreEl) myScoreEl.textContent = `${mine.score} ${t("points_short") || "pts"}`;
          if (myTimeEl) myTimeEl.textContent = mine.time || "—";

          mybar.style.display = "flex";
        } else {
          mybar.style.display = "none";
        }
      }

      hideLoading();
      return;
    }

    // 1) my row (for around + mybar)
    let myRow = null;
    if (isParticipant && uid) {
      const mr = await window.sb
        .from("ratings_cache")
        .select("rank_no,score,total_time")
        .eq("tour_id", tourId)
        .eq("rank_type", scopeRankType)
        .eq("user_id", uid)
        .maybeSingle();
      if (!mr?.error) myRow = mr?.data || null;
    }

    // 2) top 50
        const topRes = await window.sb
      .from("ratings_cache")
      .select("user_id,score,total_time,rank_no,users(first_name,last_name,school,class,region,district,region_id,district_id)")
      .eq("tour_id", tourId)
      .eq("rank_type", scopeRankType)
      .lte("rank_no", 10)
      .order("rank_no", { ascending: true });

         // total participants (max rank_no) for "out of N"
    const totalRes = await window.sb
      .from("ratings_cache")
      .select("rank_no")
      .eq("tour_id", tourId)
      .eq("rank_type", scopeRankType)
      .order("rank_no", { ascending: false })
      .limit(1);

    if (token !== ratingsState._token) return;

    if (topRes?.error) {
      hideLoading();
      listEl.innerHTML = `<div class="empty muted">${escapeHTML(t("ratings_load_error"))}</div>`;
      return;
    }

    // 3) around me ±10
    let aroundData = [];
    if (isParticipant && myRow?.rank_no) {
      const myRank = Number(myRow.rank_no || 0);
      const lo = Math.max(1, myRank - 2);
      const hi = myRank + 2;

            const aroundRes = await window.sb
        .from("ratings_cache")
        .select("user_id,score,total_time,rank_no,users(first_name,last_name,school,class,region,district,region_id,district_id)")
        .eq("tour_id", tourId)
        .eq("rank_type", scopeRankType)
        .gte("rank_no", lo)
        .lte("rank_no", hi)
        .order("rank_no", { ascending: true });

      if (token !== ratingsState._token) return;
      if (!aroundRes?.error && Array.isArray(aroundRes?.data)) aroundData = aroundRes.data;
    }

    // 4) bottom 20 (optional)
    let bottomData = [];
        const bottomRes = await window.sb
      .from("ratings_cache")
      .select("user_id,score,total_time,rank_no,users(first_name,last_name,school,class,region,district,region_id,district_id)")
      .eq("tour_id", tourId)
      .eq("rank_type", scopeRankType)
      .order("rank_no", { ascending: false })
      .limit(3);

    if (token !== ratingsState._token) return;
    if (!bottomRes?.error && Array.isArray(bottomRes?.data)) bottomData = bottomRes.data.slice().reverse();

          const cacheRowsForGeo = [
      ...(Array.isArray(topRes?.data) ? topRes.data : []),
      ...(Array.isArray(aroundData) ? aroundData : []),
      ...(Array.isArray(bottomData) ? bottomData : [])
    ];

    await enrichRatingsUsersGeoTranslations(cacheRowsForGeo);
   
    const mapDbToRow = (r) => {
      const u = r.users || {};
      return {
        rank: Number(r.rank_no || 0),
        name: getFullName(u),
        meta: buildUserMeta(u),
        score: Number(r.score || 0),
        total_time: Number(r.total_time || 0),
        time: formatSecondsToMMSS(r.total_time),
                // avatar removed from ratings UI
        user_id: r.user_id
      };
    };

    let topRows = (topRes.data || []).map(mapDbToRow);
    let aroundRows = (aroundData || []).map(mapDbToRow);
    let bottomRows = (bottomData || []).map(mapDbToRow);

    totalN = (totalRes?.data && totalRes.data.length) ? Number(totalRes.data[0].rank_no || 0) : 0;

    // -------------------------
    // Fallback search paging state
    // -------------------------
    if (ratingsState._fbSearchLimit == null) ratingsState._fbSearchLimit = 300;
    if (ratingsState._fbSearchOffset == null) ratingsState._fbSearchOffset = 0;
    if (!Array.isArray(ratingsState._fbSearchRows)) ratingsState._fbSearchRows = [];
    if (ratingsState._pagingMode == null) ratingsState._pagingMode = "";
   
    // =========================
    // Search mode (cache) + "Load more"
    // =========================
    if (q) {
      const searchKey = `${scopeRankType}|${tourId}|${String(q).trim().toLowerCase()}`;

      // reset paging when query or filters changed
      if (ratingsState._searchKey !== searchKey) {
        ratingsState._searchKey = searchKey;
        ratingsState._searchOffset = 0;
        ratingsState._searchRows = [];
      }

      const from = ratingsState._searchOffset;
      const to = from + ratingsState._searchLimit - 1;

      const { data: pageData, error: pageErr } = await window.sb
        .from("ratings_cache")
        .select("user_id,score,total_time,rank_no,users(first_name,last_name,school,class,region,district)")
        .eq("tour_id", tourId)
        .eq("rank_type", scopeRankType)
        .order("rank_no", { ascending: true })
        .range(from, to);

      if (token !== ratingsState._token) return;

      if (pageErr) {
        listEl.innerHTML = `<div class="empty muted">${escapeHTML(t("ratings_load_error"))}</div>`;
        hideLoading();
        return;
      }

      let pageRows = (Array.isArray(pageData) ? pageData : []).map(mapDbToRow);

      // filter by name + meta
      const qq = String(q).trim().toLowerCase();
      pageRows = pageRows.filter(x => {
        const blob = `${x.name || ""} ${x.meta || ""}`.toLowerCase();
        return blob.includes(qq);
      });

      // append (avoid duplicates by user_id+rank)
      const seen = new Set(ratingsState._searchRows.map(r => `${r.user_id}|${r.rank}`));
      for (const r of pageRows) {
        const k = `${r.user_id}|${r.rank}`;
        if (!seen.has(k)) {
          ratingsState._searchRows.push(r);
          seen.add(k);
        }
      }

      applyRatingsNamePolicy(ratingsState._searchRows);

      hideLoading();

      const shown = ratingsState._searchRows.slice(0, 10000); // safety
      const htmlRows = shown.slice(0, 400).map(renderRowHTML).join(""); // DOM safety (пока)

      // load more visibility: if we got full page, there might be more
      const maybeHasMore = (Array.isArray(pageData) && pageData.length === ratingsState._searchLimit);

listEl.innerHTML = `
  <div class="lb-section-head lb-results-head">
    <div class="lb-section-title">${escapeHTML(t("ratings_results") || "Results")}</div>

    <button type="button" class="lb-search-reset" id="ratings-reset-search" aria-label="Reset search">
      <span class="lb-reset-label">${escapeHTML(t("ratings_reset") || (t("btn_reset") || "Reset"))}</span>
      <span class="lb-reset-q">“${escapeHTML(String(q))}”</span>
      <span class="lb-reset-x">✕</span>
    </button>
  </div>


  <div class="lb-section-sub">${shown.length}${totalN ? ` / ${totalN}` : ""}</div>
  ${htmlRows || `<div class="empty muted">Ничего не найдено.</div>`}
        ${maybeHasMore ? `
          <div class="lb-loadmore-wrap">
            <button id="ratings-load-more" type="button" class="lb-loadmore-btn">Показать ещё</button>
          </div>
        ` : ``}
      `;

      // hide mybar during search (clean UX)
      if (mybar) mybar.style.display = "none";

      return;
    }

     // Fallback: if cache is empty, compute leaderboard from tour_attempts for this tour
    const cacheEmpty = !topRows.length && !aroundRows.length && !bottomRows.length;

      if (cacheEmpty) {

      // =========================
      // Fallback SEARCH (paged) to avoid pulling 5000 rows at once
      // =========================
      if (q) {
        ratingsState._pagingMode = "fb_search";

        const fbKey = `${scopeRankType}|${tourId}|${String(q).trim().toLowerCase()}|${ratingsState.scope}`;
        if (ratingsState._fbSearchKey !== fbKey) {
          ratingsState._fbSearchKey = fbKey;
          ratingsState._fbSearchOffset = 0;
          ratingsState._fbSearchRows = [];
        }

        const from = ratingsState._fbSearchOffset;
        const to = from + ratingsState._fbSearchLimit - 1;

        const { data: pageData, error: pageErr } = await window.sb
          .from("tour_attempts")
          .select("user_id,score,total_time,status,tour_id,users(first_name,last_name,school,class,region,district,region_id,district_id)")
          .eq("tour_id", tourId)
          .in("status", ["submitted", "time_expired", "anti_cheat", "finished"])
          .order("score", { ascending: false })
          .order("total_time", { ascending: true })
          .range(from, to);

        if (token !== ratingsState._token) return;

        if (pageErr) {
          listEl.innerHTML = `<div class="empty muted">${escapeHTML(t("ratings_load_error"))}</div>`;
          hideLoading();
          return;
        }

        // scope filter (id-first, string fallback)
        const myRid = me?.region_id != null ? String(me.region_id) : "";
        const myDid = me?.district_id != null ? String(me.district_id) : "";
        const scopedPage = (Array.isArray(pageData) ? pageData : []).filter(a => {
          const u = a.users || {};
          if (ratingsState.scope === "district") {
            if (myDid) return String(u.district_id ?? "") === myDid;
            if (me?.district) return String(u.district || "") === String(me.district || "");
            return false;
          }
          if (ratingsState.scope === "region") {
            if (myRid) return String(u.region_id ?? "") === myRid;
            if (me?.region) return String(u.region || "") === String(me.region || "");
            return false;
          }
          return true;
        });

        // map
        let pageRows = scopedPage.map(a => {
          const u = a.users || {};
          return {
            user_id: a.user_id,
            score: Number(a.score || 0),
            total_time: Number(a.total_time || 0),
            name: getFullName(u),
            meta: buildUserMeta(u),
            time: formatSecondsToMMSS(Number(a.total_time || 0))
          };
        });

        // filter by search string
        const qq = String(q).trim().toLowerCase();
        pageRows = pageRows.filter(x => {
          const blob = `${x.name || ""} ${x.meta || ""}`.toLowerCase();
          return blob.includes(qq);
        });

        // append unique (avoid duplicates)
        const seen = new Set(ratingsState._fbSearchRows.map(r => String(r.user_id)));
        for (const r of pageRows) {
          const k = String(r.user_id);
          if (!seen.has(k)) {
            ratingsState._fbSearchRows.push(r);
            seen.add(k);
          }
        }

        applyRatingsNamePolicy(ratingsState._fbSearchRows);

        hideLoading();

        const shown = ratingsState._fbSearchRows.slice(0, 400);
        const htmlRows = shown.map(renderRowHTML).join("");

        const maybeHasMore = Array.isArray(pageData) && pageData.length === ratingsState._fbSearchLimit;

        listEl.innerHTML = `
          <div class="lb-section-head lb-results-head">
            <div class="lb-section-title">${escapeHTML(t("ratings_results") || "Results")}</div>

            <button type="button" class="lb-search-reset" id="ratings-reset-search" aria-label="Reset search">
              <span class="lb-reset-label">${escapeHTML(t("ratings_reset") || (t("btn_reset") || "Reset"))}</span>
              <span class="lb-reset-q">“${escapeHTML(String(q))}”</span>
              <span class="lb-reset-x">✕</span>
            </button>
          </div>

          <div class="lb-section-sub">${shown.length}${totalN ? ` / ${totalN}` : ""}</div>
          ${htmlRows || `<div class="empty muted">${escapeHTML(t("ratings_empty") || "Ничего не найдено.")}</div>`}
          ${maybeHasMore ? `
            <div class="lb-loadmore-wrap">
              <button id="ratings-load-more" type="button" class="lb-loadmore-btn">Показать ещё</button>
            </div>
          ` : ``}
        `;

        if (mybar) mybar.style.display = "none";
        return;
      }

      // default fallback (no search): keep previous behavior (safe)
      ratingsState._pagingMode = "";
      const { data: attData, error: attErr } = await window.sb
        .from("tour_attempts")
        .select("user_id,score,total_time,status,tour_id,users(first_name,last_name,school,class,region,district,region_id,district_id)")
        .eq("tour_id", tourId)
        .in("status", ["submitted", "time_expired", "anti_cheat", "finished"])
        .limit(5000);

      if (attErr) {
        listEl.innerHTML = `<div class="empty muted">${escapeHTML(t("ratings_load_error"))}</div>`;
        hideLoading();
        return;
      }

      // scope filter by my profile (district/region)
      const scoped = (Array.isArray(attData) ? attData : []).filter(a => {
        const u = a.users || {};
        if (ratingsState.scope === "district") return !!me?.district && String(u.district || "") === String(me.district || "");
        if (ratingsState.scope === "region") return !!me?.region && String(u.region || "") === String(me.region || "");
        return true;
      });

      let rows = scoped.map(a => {
        const u = a.users || {};
        return {
          user_id: a.user_id,
          score: Number(a.score || 0),
          total_time: Number(a.total_time || 0),
          name: getFullName(u),
          meta: buildUserMeta(u),
          time: formatSecondsToMMSS(Number(a.total_time || 0))
        };
      });

      // search by name + meta
      if (q) {
        rows = rows.filter(x => {
          const blob = `${x.name || ""} ${x.meta || ""}`.toLowerCase();
          return blob.includes(q);
        });
      }

      // rank
      rows.sort((a, b) => {
        if (b.score !== a.score) return b.score - a.score;
        return a.total_time - b.total_time;
      });
      rows = rows.map((r, idx) => ({ ...r, rank: idx + 1 }));

      // sections: top10 / around±2 / bottom3 (no duplicates)
      let topRows2 = rows.slice(0, 10);
      let aroundRows2 = [];
      let bottomRows2 = rows.length > 13 ? rows.slice(-3) : [];

      if (isParticipant && uid) {
        const myIndex = rows.findIndex(r => String(r.user_id) === String(uid));
        if (myIndex >= 0) {
          const lo = Math.max(0, myIndex - 2);
          const hi = Math.min(rows.length, myIndex + 3);
          aroundRows2 = rows.slice(lo, hi);
        }
      }

      const topKeys = new Set(dedupeByRank(topRows2).map(rowDedupeKey));
      aroundRows2 = (aroundRows2 || []).filter(r => !topKeys.has(rowDedupeKey(r)));

      const aroundKeys = new Set(dedupeByRank(aroundRows2).map(rowDedupeKey));
      bottomRows2 = (bottomRows2 || []).filter(r => !topKeys.has(rowDedupeKey(r)) && !aroundKeys.has(rowDedupeKey(r)));

      const shouldShowBottom2 = bottomRows2.length && bottomRows2.some(r => r.rank > 10);

            const showSearchHead = !!q;

      const searchHeadHTML = showSearchHead ? `
        <div class="lb-section-head lb-results-head">
          <div class="lb-section-title">Results</div>

          <button type="button" class="lb-search-reset" id="ratings-reset-search" aria-label="Reset search">
            <span class="lb-reset-label">Reset</span>
            <span class="lb-reset-q">“${escapeHTML(String(q))}”</span>
            <span class="lb-reset-x">✕</span>
          </button>
        </div>
      ` : ``;

      listEl.innerHTML =
        searchHeadHTML +
        renderSection(t("ratings_top") || "Top 10", dedupeByRank(topRows2), "") +
        (isParticipant ? renderSection(t("ratings_around") || "Around me", dedupeByRank(aroundRows2), "±2") : "") +
        (shouldShowBottom2
          ? renderSection(
              t("ratings_bottom") || "Bottom 3",
              dedupeByRank(bottomRows2),
              t("ratings_of_total", { total: rows.length })
            )
          : ""
        );

      // UX: во время поиска — как и в single-tour — скрываем mybar, чтобы не мешал
      if (showSearchHead && mybar) mybar.style.display = "none";

      // My rank: out of N
      if (isParticipant && mybar) {
        const myIndex2 = rows.findIndex(r => String(r.user_id) === String(uid));
        if (myIndex2 >= 0) {
          const mine = rows[myIndex2];
          myRankEl.textContent = String(mine.rank);
      const totalLabel = t("ratings_total_participants");
      if (myTotalEl) myTotalEl.textContent = totalN ? `${totalLabel}: ${totalN}` : "—";

      myScoreEl.textContent = `${String(mine.score)} pts`;
      myTimeEl.textContent = formatSecondsToMMSS(mine.total_time);
      mybar.style.display = "flex";
        } else {
          mybar.style.display = "none";
        }
      }

      hideLoading();
      return;
    }

         // remove duplicates across sections (Top -> Around -> Bottom)
    const topRanks = new Set(dedupeByRank(topRows).map(r => String(r.rank)));
    aroundRows = (aroundRows || []).filter(r => !topRanks.has(String(r.rank)));

    const aroundRanks = new Set(dedupeByRank(aroundRows).map(r => String(r.rank)));
    bottomRows = (bottomRows || []).filter(r => !topRanks.has(String(r.rank)) && !aroundRanks.has(String(r.rank)));

    // search inside
    if (q) {
      const f = (arr) => arr.filter(x =>
        String(x.name || "").toLowerCase().includes(q) ||
        String(x.meta || "").toLowerCase().includes(q)
      );
      topRows = f(topRows);
      aroundRows = f(aroundRows);
      bottomRows = f(bottomRows);
    }

    // bottom show only if ranks exceed top zone
    const shouldShowBottom = bottomRows.length && bottomRows.some(r => r.rank > 10);

    hideLoading();

    if (!topRows.length && !aroundRows.length && !bottomRows.length) {
      listEl.innerHTML = `<div class="empty muted">${escapeHTML(t("ratings_nothing_found"))}</div>`;
    } else {
          // политика имени: только имя, но если имена повторяются — показываем фамилию (полное ФИО)
      applyRatingsNamePolicy([...(topRows || []), ...(aroundRows || []), ...(bottomRows || [])]);
            listEl.innerHTML =
        renderSection(t("ratings_top") || "Top 10", dedupeByRank(topRows), "") +
        (isParticipant && myRow?.rank_no ? renderSection(t("ratings_around") || "Around me", dedupeByRank(aroundRows), "±2") : "") +
        (shouldShowBottom ? renderSection(
  t("ratings_bottom") || "Bottom 3",
  dedupeByRank(bottomRows),
  totalN ? t("ratings_of_total", { total: totalN }) : ""
) : "");
    }

                // mybar
    if (isParticipant && mybar && myRow) {
      myRankEl.textContent = String(myRow.rank_no ?? "—");

      const totalLabel = t("ratings_total_participants");
      // total участников в rating_cache проще всего взять по максимальному рангу из bottomData (если он есть)
      const totalN = (bottomData && bottomData.length)
        ? Number(bottomData[bottomData.length - 1].rank_no || 0)
        : 0;
      if (myTotalEl) myTotalEl.textContent = totalN ? `${totalLabel}: ${totalN}` : "—";

      myScoreEl.textContent = `${String(myRow.score ?? "—")} ${tr3("балл", "ball", "pts")}`;
      myTimeEl.textContent = formatSecondsToMMSS(myRow.total_time);
      mybar.style.display = "flex";
    } else {
      if (mybar) mybar.style.display = "none";
    }

    return;
  }

  // =========================
// B) All tours: tour_attempts aggregation
// =========================
const tours = await loadRatingsToursForSubject(ratingsState.subjectId);
const tourIds = Array.from(
  new Set((Array.isArray(tours) ? tours : []).map(x => Number(x?.id)).filter(Boolean))
);

if (!tourIds.length) {
  hideLoading();
  listEl.innerHTML = `<div class="empty muted">${escapeHTML(t("tours_empty_for_subject"))}</div>`;
  return;
}

const { data: attempts, error: attErr } = await window.sb
  .from("tour_attempts")
  .select("user_id,score,total_time,status,tour_id,users(first_name,last_name,school,class,region,district,region_id,district_id)")
  .in("tour_id", tourIds)
  .limit(5000);

await enrichRatingsUsersGeoTranslations(Array.isArray(attempts) ? attempts : []);

if (token !== ratingsState._token) return;

if (attErr) {
  hideLoading();
  listEl.innerHTML = `<div class="empty muted">${escapeHTML(t("ratings_load_error"))}</div>`;
  return;
}

const OK_STATUSES = new Set(["finished", "submitted", "time_expired", "anti_cheat"]);

// filter by status first
const completedAttempts = (Array.isArray(attempts) ? attempts : []).filter(a => {
  const st = String(a?.status || "").trim();
  return !st || OK_STATUSES.has(st);
});

// then scope filter: ID-first, text fallback
const filteredAttempts = applyLocalRatingsScope(completedAttempts);
    
  // aggregate per user
  const agg = new Map();
  for (const a of filteredAttempts) {
    const u = a.users || {};
    const id = a.user_id;
    if (!id) continue;
    const prev = agg.get(id) || { user_id: id, score: 0, total_time: 0, users: u };
    prev.score += Number(a.score || 0);
    prev.total_time += Number(a.total_time || 0);
    prev.users = u;
    agg.set(id, prev);
  }

  let rowsAll = Array.from(agg.values()).map(r => {
    const u = r.users || {};
    return {
      user_id: r.user_id,
      name: getFullName(u),
      meta: buildUserMeta(u),
      score: Number(r.score || 0),
      total_time: Number(r.total_time || 0),
      time: formatSecondsToMMSS(r.total_time),
      avatar: u.avatar_url || null
    };
  });

  // search
  if (q) {
    rowsAll = rowsAll.filter(x =>
      String(x.name || "").toLowerCase().includes(q) ||
      String(x.meta || "").toLowerCase().includes(q)
    );
  }

  // sort + rank
  rowsAll.sort((a, b) => {
    if (b.score !== a.score) return b.score - a.score;
    return a.total_time - b.total_time;
  });
    rowsAll = rowsAll.map((r, idx) => ({ ...r, rank: idx + 1 }));

  // total participants for this view
  totalN = rowsAll.length;

  hideLoading();

  if (!rowsAll.length) {
    listEl.innerHTML = `<div class="empty muted">${q ? t("ratings_empty") : t("ratings_no_participants")}</div>`;
    if (mybar) mybar.style.display = "none";
    return;
  }

    // sections
    if (q) {
    const view = rowsAll.slice(0, 200);

    const resetLabel = t("ratings_reset") || (t("btn_reset") || "Reset");
    const resultsLabel = t("ratings_results") || "Results";
    const htmlRows = view.map(renderRowHTML).join("");

    listEl.innerHTML = `
      <div class="lb-section-head lb-results-head">
        <div class="lb-section-title">${escapeHTML(resultsLabel)}</div>

        <button type="button" class="lb-search-reset" id="ratings-reset-search" aria-label="Reset search">
          <span class="lb-reset-label">${escapeHTML(resetLabel)}</span>
          <span class="lb-reset-q">“${escapeHTML(String(q))}”</span>
          <span class="lb-reset-x">✕</span>
        </button>
      </div>

      ${htmlRows || `<div class="empty muted">${t("ratings_empty") || "Ничего не найдено."}</div>`}
    `;

    // while searching: mybar hides (so UI doesn’t look “stuck”)
    if (mybar) mybar.style.display = "none";

    hideLoading();
    return;
  } else {
    const topRows = rowsAll.slice(0, 10);

    let aroundRows = [];
    let myIndex = -1;
    if (isParticipant && uid) myIndex = rowsAll.findIndex(r => String(r.user_id) === String(uid));
    if (isParticipant && myIndex >= 0) {
      const lo = Math.max(0, myIndex - 2);
      const hi = Math.min(rowsAll.length, myIndex + 3);
      aroundRows = rowsAll.slice(lo, hi);
    }

    const bottomRows = rowsAll.length > 13 ? rowsAll.slice(-3) : [];
    const shouldShowBottom = bottomRows.length && bottomRows.some(r => r.rank > 10);
    const topRanks = new Set(dedupeByRank(topRows).map(r => String(r.rank)));
    aroundRows = (aroundRows || []).filter(r => !topRanks.has(String(r.rank)));

    const aroundRanks = new Set(dedupeByRank(aroundRows).map(r => String(r.rank)));
    const bottomClean = (bottomRows || []).filter(r => !topRanks.has(String(r.rank)) && !aroundRanks.has(String(r.rank)));
  
        listEl.innerHTML =
      renderSection(t("ratings_top") || "Top 10", dedupeByRank(topRows), "") +
      (isParticipant && myIndex >= 0 ? renderSection(t("ratings_around") || "Around me", dedupeByRank(aroundRows), "±2") : "") +
      (shouldShowBottom ? renderSection(
        t("ratings_bottom") || "Bottom 3",
        dedupeByRank(bottomClean),
        totalN ? t("ratings_of_total", { total: totalN }) : ""

         ) : "");
     }

        // My rank (only if participant)
  if (isParticipant && mybar) {
    const myIndex = rowsAll.findIndex(r => String(r.user_id) === String(uid));
    if (myIndex >= 0) {
      const mine = rowsAll[myIndex];
      myRankEl.textContent = String(mine.rank);

      const totalLabel = t("ratings_total_participants");
      if (myTotalEl) myTotalEl.textContent = totalN ? `${totalLabel}: ${totalN}` : "—";

      myScoreEl.textContent = `${String(mine.score)} ${tr3("балл", "ball", "pts")}`;
      myTimeEl.textContent = formatSecondsToMMSS(mine.total_time);
      mybar.style.display = "flex";
    } else {
      mybar.style.display = "none";
    }
  } else {
    if (mybar) mybar.style.display = "none";
  }
}

  function openRatingsInfoModal() {
  const title = t("ratings_info_title");
  const text1 = t("ratings_info_text1");
  const text2 = t("ratings_info_text2");
  const text3 = t("ratings_info_text3");

  const html = `
    <div class="modal-backdrop" data-modal-backdrop data-close="backdrop">
      <div class="modal">
        <div class="modal-title">${escapeHTML(title)}</div>

        <div class="modal-text" style="text-align:left; line-height:1.45">
          <div style="font-weight:900; margin-bottom:8px;">${escapeHTML(text1)}</div>
          <div style="margin-bottom:8px;">${escapeHTML(text2)}</div>
          <div>${escapeHTML(text3)}</div>
        </div>

        <div class="modal-actions">
          <button type="button" class="btn primary" data-modal-action="ok">${escapeHTML(t("close"))}</button>
        </div>
      </div>
    </div>
  `;

  openModal(html);
}

   function openRatingsSearchPanel() {
  const panel = document.getElementById("ratings-search-panel");
  const backdrop = document.getElementById("ratings-search-backdrop");
  const input = document.getElementById("ratings-search");

  if (panel) panel.style.display = "block";
  if (backdrop) backdrop.style.display = "block";

  if (input) {
    input.placeholder = t("ratings_search_placeholder") || "Search...";
    setTimeout(() => { try { input.focus(); } catch {} }, 0);
  }
}

function closeRatingsSearchPanel() {
  const panel = document.getElementById("ratings-search-panel");
  const backdrop = document.getElementById("ratings-search-backdrop");

  if (panel) panel.style.display = "none";
  if (backdrop) backdrop.style.display = "none";
}

function bindRatingsUI() {
  const listEl = $("#ratings-list");
  const subjectSelect = $("#ratings-subject");
  const tourSelect = $("#ratings-tour");
     // Search panel controls
  const searchInput = document.getElementById("ratings-search");
  const searchClear = document.getElementById("ratings-search-clear");
  const searchBackdrop = document.getElementById("ratings-search-backdrop");

  let searchTimer = null;

  const applySearch = (val) => {
    ratingsState.q = String(val || "").trim();
    renderRatings();
  };

    if (searchBackdrop) {
    searchBackdrop.addEventListener("click", () => {
      closeRatingsSearchPanel();
    });
  }

  if (searchInput) {
    searchInput.placeholder = t("ratings_search_placeholder") || "Search...";

        // ✅ Debounce: пользователь перестал печатать → применяем поиск и показываем результат (закрываем панель)
    searchInput.addEventListener("input", () => {
      if (searchTimer) clearTimeout(searchTimer);

      searchTimer = setTimeout(() => {
        const v = String(searchInput.value || "").trim();

        // <2 символов: считаем, что поиска нет (сбрасываем фильтр), панель НЕ закрываем
        if (v.length < 2) {
          if (String(ratingsState.q || "") !== "") applySearch("");
          return;
        }

        applySearch(v);

        // ✅ UX: после автопоиска сразу показываем результаты
        closeRatingsSearchPanel();
      }, 2000);
    });

    // ✅ Enter — применяем сразу и закрываем панель
    searchInput.addEventListener("keydown", (e) => {
      if (e.key !== "Enter") return;

      if (searchTimer) clearTimeout(searchTimer);

      const v = String(searchInput.value || "").trim();
      if (v.length < 2) return;

      applySearch(v);
      closeRatingsSearchPanel();
    });
  }
  if (searchClear) {
    searchClear.addEventListener("click", () => {
      if (!searchInput) return;
      if (String(searchInput.value || "").length > 0) {
        searchInput.value = "";
        applySearch("");
      } else {
        // если пусто — закрываем панель
        closeRatingsSearchPanel();
      }
    });
  }
                // Load more + Reset (event delegation, because buttons are rendered dynamically)
    document.addEventListener("click", (e) => {
    const loadBtn = e?.target?.closest?.("#ratings-load-more");
    if (loadBtn) {
      if (ratingsState._pagingMode === "fb_search") {
        ratingsState._fbSearchOffset += ratingsState._fbSearchLimit;
      } else {
        ratingsState._searchOffset += ratingsState._searchLimit;
      }
      renderRatings();
      return;
    }

    const resetBtn = e?.target?.closest?.("#ratings-reset-search");
        if (resetBtn) {
      ratingsState.q = "";
      ratingsState._searchOffset = 0;
      ratingsState._searchRows = [];

      ratingsState._fbSearchOffset = 0;
      ratingsState._fbSearchRows = [];
      ratingsState._fbSearchKey = "";
      ratingsState._pagingMode = "";

      if (searchInput) searchInput.value = "";
      renderRatings();
      return;
    }
  });

  if (subjectSelect) {
  subjectSelect.addEventListener("change", async () => {
    const v = subjectSelect.value;
    ratingsState.subjectId = v ? Number(v) : null;

    const previousTourNo =
      ratingsState.tourNo && ratingsState.tourNo !== "__all__"
        ? Number(ratingsState.tourNo)
        : "__all__";

    resetRatingsSearchPaging();

    if (window.sb && ratingsState.subjectId) {
      const tours = await loadRatingsToursForSubject(ratingsState.subjectId);
      const tourItems = [
        { value: "__all__", label: t("ratings_all_tours") || "All tours" },
        ...tours.map(tt => ({ value: tt.id, label: `Tour ${tt.tour_no}`, tourNo: Number(tt.tour_no || 0) }))
      ];

      renderRatingsSelectOptions(tourSelect, tourItems);

      if (previousTourNo !== "__all__") {
        const sameTour = tours.find(tt => Number(tt?.tour_no || 0) === Number(previousTourNo));
        ratingsState.tourId = sameTour?.id ? Number(sameTour.id) : "__all__";
        ratingsState.tourNo = sameTour?.tour_no ? Number(sameTour.tour_no) : "__all__";
      } else {
        ratingsState.tourId = "__all__";
        ratingsState.tourNo = "__all__";
      }
    } else {
      ratingsState.tourId = "__all__";
      ratingsState.tourNo = "__all__";
    }

    if (tourSelect) tourSelect.value = String(ratingsState.tourId || "__all__");

    saveRatingsFiltersToState();
    renderRatings();
  });
}
 
   if (tourSelect) {
  tourSelect.addEventListener("change", () => {
    const v = tourSelect.value;
    const opt = tourSelect.options?.[tourSelect.selectedIndex] || null;

    ratingsState.tourId = (v && v !== "__all__") ? Number(v) : "__all__";
    ratingsState.tourNo = (v && v !== "__all__")
      ? Number(opt?.dataset?.tourNo || 0) || "__all__"
      : "__all__";

    resetRatingsSearchPaging();
    saveRatingsFiltersToState();
    renderRatings();
  });
}

  // segmented tabs
  $$(".lb-segment .seg-btn").forEach(btn => {
  btn.addEventListener("click", () => {
    const scope = btn.dataset.scope;
    if (!scope || scope === ratingsState.scope) return;

    ratingsState.scope = scope;
    resetRatingsSearchPaging();
    saveRatingsFiltersToState();

    $$(".lb-segment .seg-btn").forEach(x => {
      const active = x.dataset.scope === ratingsState.scope;
      x.classList.toggle("is-active", active);
      x.setAttribute("aria-selected", active ? "true" : "false");
    });

    renderRatings();
  });
});
    // optional: click on list rows later (open student profile) — пока пусто
  if (listEl) {
    listEl.addEventListener("click", (e) => {
      const row = e.target.closest(".lb-row");
      if (!row) return;
      // future: open profile modal
    });
  }
}
   
  // ---------------------------
  // Courses stack
  // ---------------------------
    const COURSES_SCREENS = [
    "all-subjects",
    "subject-hub",
    "lessons",
    "video",
    "practice-start",
    "practice-quiz",
    "practice-result",
    "practice-review",
    "practice-recs",
    "tours",
    "tour-rules",
    "tour-quiz",
    "tour-result",
    "tour-review",
    "books",
    "my-recs",
    "my-rec-detail"
  ];

  function getCoursesTopScreen() {
    const s = state.courses.stack;
    return s && s.length ? s[s.length - 1] : "all-subjects";
  }

  function showCoursesScreen(screenName) {
    COURSES_SCREENS.forEach(sc => {
      const el = $(`#courses-${sc}`);
      if (!el) return;
      el.classList.toggle("is-active", sc === screenName);
    });
    updateTopbarForView("courses");
  }

    function pushCourses(screenName) {
    // ✅ harden: stack must always be array
    state.courses = (state.courses && typeof state.courses === "object") ? state.courses : {};
    state.courses.stack = Array.isArray(state.courses.stack) ? state.courses.stack : ["all-subjects"];

    state.courses.stack.push(screenName);
    saveState();
    showCoursesScreen(screenName);
  }

  function replaceCourses(screenName) {
    state.courses.stack = [screenName];
    saveState();
    showCoursesScreen(screenName);
  }

   function replaceCoursesTop(screenName) {
  state.courses.stack = Array.isArray(state.courses.stack) ? state.courses.stack : [screenName];
  if (!state.courses.stack.length) state.courses.stack = [screenName];
  state.courses.stack[state.courses.stack.length - 1] = screenName;
  saveState();
  showCoursesScreen(screenName);
}
   
  function popCourses() {
  if (state.quizLock) return;

  const top = getCoursesTopScreen();

  // ✅ Ставим видео на паузу и жестко глушим iframe при уходе
  if (top === "video") {
    try {
      if (ytPlayer && typeof ytPlayer.pauseVideo === "function") ytPlayer.pauseVideo();
      const iframe = document.getElementById("video-player");
      if (iframe && iframe.tagName === "IFRAME") iframe.removeAttribute("src");
    } catch {}
  }

    // ✅ tour-result back MUST go to Subject Hub (no return to questions)
  if (top === "tour-result") {
    // чистим тур-флоу из стека, чтобы назад не вёл в quiz
    state.courses.stack = ["subject-hub"];
    saveState();
    showCoursesScreen("subject-hub");
    renderSubjectHub();
    return;
  }

  // ✅ Safety: если тур-экран оказался первым в стеке (stack=1),
  // то back должен вести в subject-hub, а не выкидывать в Home.
  const isTourFlowScreen = ["tours", "tour-rules", "tour-quiz", "tour-result", "tour-review"].includes(top);
  if (isTourFlowScreen && state.courses.stack.length <= 1) {
    state.courses.stack = ["subject-hub"];
    saveState();
    showCoursesScreen("subject-hub");
    renderSubjectHub();
    return;
  }

          if (state.courses.stack.length > 1) {
  state.courses.stack.pop();
  saveState();

  const next = getCoursesTopScreen();
  showCoursesScreen(next);

  // ✅ Ensure correct screen rendering after back
  if (next === "tours") {
    renderToursStart();
  } else if (next === "practice-start") {
    renderPracticeStart();
  } else if (next === "subject-hub") {
    renderSubjectHub();
  } else if (next === "books") {
    renderBooks();
  } else if (next === "my-recs") {
    renderMyRecs();
  } else if (next === "my-rec-detail") {
    renderMyRecDetail();
  }

  return;
}

    let targetTab = state.courses.entryTab || state.prevTab || "home";

  // ✅ Guard: back из Courses-стека не должен возвращать в базовый Courses (all-subjects без back)
  if (targetTab === "courses") targetTab = "home";

  setTab(targetTab);
}

function canCoursesBack() {
  const top = getCoursesTopScreen();

  // ✅ special-case: my-recs and my-rec-detail may be opened from Profile / Courses,
  // but back must stay visible and work through popCourses()
  if (top === "my-recs" || top === "my-rec-detail") return true;

  // ✅ туры/экраны тура: даже если stack=1 — back показываем (уйдём в subject-hub)
  if (["tours", "tour-rules", "tour-quiz", "tour-result", "tour-review"].includes(top)) return true;

  // ✅ Subject Hub: даже если stack=1 — back должен быть доступен (уйдём в entryTab/prevTab/home)
  if (top === "subject-hub") return true;

  return state.courses.stack.length > 1;
}

  function renderCoursesStack() {
    const top = getCoursesTopScreen();
    showCoursesScreen(top);
  }

   // ---------------------------
// Profile stack
// ---------------------------
const PROFILE_SCREENS = ["main", "settings"];

function getProfileTopScreen() {
  const s = state.profile?.stack;
  return (s && s.length) ? s[s.length - 1] : "main";
}

function showProfileScreen(screenName) {
  // ✅ Сначала скрываем ВСЕ проф-экраны (на всякий случай, даже если классы “сломались”)
  document.querySelectorAll("#view-profile .profile-screen").forEach(el => {
    el.hidden = true;
    el.style.display = "none";
    el.classList.remove("is-active");
  });

  // ✅ Затем показываем только нужный
  const target = document.getElementById(`profile-${screenName}`);
  if (target) {
    target.hidden = false;
    target.style.display = "block";
    target.classList.add("is-active");
  }

  updateTopbarForView("profile");
     // ✅ FIX: same scroll-restoration issue when switching inside profile stack
  const resetScroll = () => {
    try {
      window.scrollTo(0, 0);
      document.documentElement.scrollTop = 0;
      document.body.scrollTop = 0;
    } catch (e) {}
  };
  resetScroll();
  requestAnimationFrame(resetScroll);
  setTimeout(resetScroll, 0);
}

function pushProfile(screenName) {
  state.profile.stack = Array.isArray(state.profile.stack) ? state.profile.stack : ["main"];
  state.profile.stack.push(screenName);
  saveState();
  showProfileScreen(screenName);
}

function replaceProfile(screenName) {
  // ✅ ДЕРЖИМ СТРУКТУРУ: profile.stack
  state.profile = state.profile && typeof state.profile === "object" ? state.profile : { stack: ["main"] };
  state.profile.stack = Array.isArray(state.profile.stack) ? state.profile.stack : ["main"];

  // ✅ replace = один экран в стеке
  state.profile.stack = [screenName];

  saveState();
  showProfileScreen(screenName);

  // ✅ перерендер нужного экрана
  if (screenName === "main") renderProfileMain();
  if (screenName === "settings") renderProfileSettings();
}

function popProfile() {
  if (!state.profile?.stack || state.profile.stack.length <= 1) return;
  state.profile.stack.pop();
  saveState();
  showProfileScreen(getProfileTopScreen());
}

function openProfileSettings() {
  // ✅ заходим в Profile через setTab, чтобы корректно обновлялся prevTab
  if (state.tab !== "profile") setTab("profile");

  // ✅ гарантируем структуру стека
  state.profile = state.profile && typeof state.profile === "object" ? state.profile : { stack: ["main"] };
  state.profile.stack = Array.isArray(state.profile.stack) ? state.profile.stack : ["main"];

  // ✅ фиксируем settings в stack, чтобы "back" делал popProfile()
  if (getProfileTopScreen() !== "settings") {
    pushProfile("settings");
  } else {
    showProfileScreen("settings");
  }

  renderProfileSettings();
  updateTopbarForView("profile");
}

function openProfileMain() {
  // ✅ заходим в Profile через setTab, чтобы корректно обновлялся prevTab
  if (state.tab !== "profile") setTab("profile");

  // ✅ единый источник истины: stack + showProfileScreen()
  replaceProfile("main");
  updateTopbarForView("profile");
}

function renderProfileStack() {
  const top = getProfileTopScreen();
  showProfileScreen(top);
  if (top === "settings") renderProfileSettings();
  if (top === "main") renderProfileMain();
}

   function renderProfileSettings() {
  const profile = loadProfile();
  const list = document.getElementById("profile-competitive-list");
  const note = document.getElementById("settings-competitive-note");
  if (!list) return;

  list.innerHTML = "";

    if (!profile) {
    list.innerHTML = `<div class="empty muted">${t("home_need_registration")}</div>`;
    return;
  }

  // Non-school users: competitive is disabled by product rules
  if (!profile.is_school_student) {
    if (note) note.textContent = t("disabled_not_school");
    list.innerHTML = `<div class="empty muted">${t("disabled_not_school")}</div>`;
    return;
  }

  const current = Array.isArray(profile.subjects) ? profile.subjects : [];
  const currentComp = current.filter(s => s.mode === "competitive").map(s => s.key);
  const compCount = currentComp.length;

  if (note) note.textContent = t("settings_competitive_note", { count: compCount });

 // ✅ Competitive settings: показываем ТОЛЬКО main-предметы (study/non-main скрываем полностью)
const mainSubjects = Array.isArray(SUBJECTS) ? SUBJECTS.filter(s => s.type === "main") : [];

mainSubjects.forEach(subj => {
  const isOn = currentComp.includes(subj.key);
  const limitReached = (compCount >= 2 && !isOn);

  const row = document.createElement("div");
  row.className =
    "settings-row" +
    (isOn ? " is-on" : "") +
    (limitReached ? " is-disabled" : "");

  row.innerHTML = `
  <div class="settings-row-left">
    <div style="font-weight:800">${escapeHTML(subjectTitle(subj.key, subj.title))}</div>
    <div class="muted small">${isOn ? t("mode_competitive") : t("course_toggle_off")}</div>
  </div>
  <label class="switch">
    <input type="checkbox"
      ${isOn ? "checked" : ""}
      ${limitReached ? "disabled" : ""}>
    <span class="slider"></span>
  </label>
`;

  const input = row.querySelector('input[type="checkbox"]');

  input?.addEventListener("change", async () => {
    if (input.disabled) return;

    const fresh = loadProfile();
    if (!fresh) return;

    const subjects = Array.isArray(fresh.subjects) ? structuredClone(fresh.subjects) : [];
    const idx = subjects.findIndex(s => s.key === subj.key);

    if (idx === -1) subjects.push({ key: subj.key, mode: "study", pinned: false });

    const next = subjects.map(s => ({ ...s }));
    const was = next.find(s => s.key === subj.key);
    const fromMode = was?.mode || "study";
    const fromPinned = !!was?.pinned;
    const turningOn = !isCompetitiveForUser(fresh, subj.key);

    const ok = await uiConfirm({
      title: turningOn ? "Competitive режим" : "Выключить Competitive",
      message: turningOn
        ? "Сделать этот предмет Competitive?\n\nЭто включит: туры, рейтинги, сертификаты.\nУчебный режим останется доступен."
        : "Убрать предмет из Competitive?\n\nТуры/рейтинг/сертификаты по предмету станут недоступны.\nУчебный режим останется.",
      okText: turningOn ? "Включить" : "Выключить",
      cancelText: "Отмена"
    });

    if (!ok) {
      input.checked = !turningOn;
      return;
    }

    if (turningOn) {
      const compNow = next.filter(s => s.mode === "competitive").length;
      if (compNow >= 2) {
        input.checked = false;
        await uiAlert({
          title: "Лимит Competitive",
          message: "Максимум 2 предмета в Competitive.\nСначала выключите другой предмет.",
          okText: "Понял"
        });
        return;
      }
      was.mode = "competitive";
      showToast(t("toast_switched_to_competitive"));
    } else {
      was.mode = "study";
      showToast(t("toast_switched_to_study"));
    }

    fresh.subjects = next;
    saveProfile(fresh);
    const us = Array.isArray(fresh?.subjects) ? fresh.subjects.find(s => s.key === subj.key) : null;
    const mode = us?.mode || "study";
    const pinned = !!us?.pinned;
    const toMode = mode;
    const toPinned = (toMode === "competitive") ? false : pinned;
 
        try {
      trackEvent("user_subjects_save_started", { subject_key: subj.key, mode, is_pinned: pinned });
    } catch {}

    try {
      const res = await syncUserSubjectToSupabase(subj.key, mode, pinned);

      try {
        trackEvent("user_subjects_save_result", {
          ok: !!res?.ok,
          reason: res?.reason || null,
          method: res?.method || null,
          subject_key: subj.key
        });
      } catch {}

      // ✅ only on success: write history + resync profile snapshot
      if (res?.ok) {
        const subjectId = res?.subjectId || await getSubjectIdByKey(subj.key);
        if (subjectId) {
          await writeUserSubjectsHistory({
            user_id: res?.uid,
            subject_id: subjectId,
            action: "mode_change",
            from_mode: fromMode,
            to_mode: toMode,
            from_pinned: fromPinned,
            to_pinned: toPinned,
            source: "profile_settings",
            meta: { subject_key: subj.key }
          });
        }

        __profileSubjectsDbReady = false;
        await ensureProfileSubjectsDbSynced();
      } else {
        // ❗rollback UI if DB rejected (limit/RLS/etc.)
        input.checked = !turningOn;
        showToast(
          tr3(
            "Не удалось сохранить. Попробуйте ещё раз.",
            "Saqlab bo‘lmadi. Yana urinib ko‘ring.",
            "Could not save. Please try again."
          )
        );
        return;
      }
    } catch (e) {
      // ❗rollback UI on network/JS error
      input.checked = !turningOn;
      showToast(t("network_error_try_again"));
      return;
    }

    renderHome();
    if (state.tab === "courses") {
      renderAllSubjects();
      if (getCoursesTopScreen() === "subject-hub") renderSubjectHub();
    }

    renderProfileSettings();
  });

  list.appendChild(row);
});

      // --- Language segmented buttons ---
const langWrap = document.getElementById("profile-settings-language");
if (langWrap) {
  const currentLang = profile.uiLanguage || profile.language || "ru";

  langWrap.querySelectorAll(".lang-btn").forEach(btn => {
    const lang = btn.dataset.lang;
    btn.classList.toggle("is-active", lang === currentLang);

    btn.onclick = () => {
      const fresh = loadProfile();
      if (!fresh) return;

      const nextLang = String(btn.dataset.lang || "ru");
      const cur = fresh.uiLanguage || fresh.language || "ru";
      if (nextLang === cur) return;

            // ✅ меняем только язык интерфейса
      fresh.uiLanguage = nextLang;
      saveProfile(fresh);

      window.i18n?.setLang(nextLang);
      applyStaticI18n?.();

      try { clearAboutTeamResolvedCache(); } catch {}

      renderHome();
      if (state.tab === "courses") {
        renderAllSubjects();
        try {
          if (typeof getCoursesTopScreen === "function" && getCoursesTopScreen() === "subject-hub") {
            renderSubjectHub();
          }
        } catch {}
      }

      renderProfileMain();
      renderProfileSettings();

      try {
        const top = Array.isArray(state.viewStack) ? state.viewStack[state.viewStack.length - 1] : "";
        if (top === "about") renderAboutView();
      } catch {}

      showToast(t("toast_lang_updated"));
    };
  });
}

      // --- Content language segmented buttons (Tours/Practice) ---
const contentLangWrap = document.getElementById("profile-settings-content-language");
if (contentLangWrap) {
  const currentContentLang = profile.language || "ru";

  contentLangWrap.querySelectorAll(".lang-btn").forEach(btn => {
    const lang = btn.dataset.lang;
    btn.classList.toggle("is-active", lang === currentContentLang);

    btn.onclick = async () => {
      const fresh = loadProfile();
      if (!fresh) return;

      const nextLang = String(btn.dataset.lang || "ru");
      const cur = fresh.language || "ru";
      if (nextLang === cur) return;

     const ok = await uiConfirm({
  title: t("profile_content_language_title"),
  message: t("confirm_content_lang_change"),
  okText: t("yes"),
  cancelText: t("cancel")
});
if (!ok) return;

      // 1) DB wipe (если есть Supabase + uid)
      try {
        const uid = await getAuthUid();
        if (window.sb && uid) {
          // --- Practice wipe ---
          const { data: pAtt } = await window.sb
            .from("practice_attempts")
            .select("id")
            .eq("user_id", uid)
            .limit(10000);

          const pIds = (Array.isArray(pAtt) ? pAtt : []).map(x => x.id).filter(Boolean);
          if (pIds.length) {
            // delete answers by attempt_id (safe if column exists)
            for (let i = 0; i < pIds.length; i += 500) {
              const chunk = pIds.slice(i, i + 500);
              await window.sb.from("practice_answers").delete().in("attempt_id", chunk);
            }
          }
          await window.sb.from("practice_attempts").delete().eq("user_id", uid);

          // --- Tour wipe ---
          // ✅ Tours НЕ очищаем при смене языка контента.
          // Иначе user получает повторную попытку, что ломает one-attempt rule.

          // 2) update content language in users table
          await window.sb.from("users").upsert({ id: uid, language_code: nextLang }, { onConflict: "id" });
        }
      } catch (e) {
        // если где-то не получилось — лучше не падать UI
        try { trackEvent("content_lang_change_db_error", { message: String(e?.message || e) }); } catch {}
      }

      // 3) local wipe (без удаления профиля)
      try { localStorage.removeItem(LS.state); } catch {}
      try { localStorage.removeItem(LS.practiceDraft); } catch {}
      try { localStorage.removeItem(LS.myRecs); } catch {}
      try { localStorage.removeItem(LS.events); } catch {}
      try { localStorage.removeItem(LS.credentials); } catch {}

      // 4) apply content language
            fresh.language = nextLang;
      // UI язык не трогаем намеренно (ваше требование). Но если uiLanguage ещё нет — зафиксируем.
      if (!fresh.uiLanguage) fresh.uiLanguage = window.i18n?.getLang?.() || nextLang;
      saveProfile(fresh);

      try { clearAboutTeamResolvedCache(); } catch {}

      // 5) перерендер
      renderHome();

if (state.tab === "courses") {
  const top = getCoursesTopScreen();
  showCoursesScreen(top);

  if (top === "all-subjects") renderAllSubjects();
  else if (top === "subject-hub") renderSubjectHub();
  else if (top === "lessons") renderLessons();
  else if (top === "tours") { if (typeof renderToursStart === "function") renderToursStart(); }
  else if (top === "books") { if (typeof renderBooks === "function") renderBooks(); }
  else if (top === "my-recs") { if (typeof renderMyRecs === "function") renderMyRecs(); }
  else if (top === "practice-start") { if (typeof renderPracticeStart === "function") renderPracticeStart(); }
  else if (top === "practice-review") { if (typeof renderPracticeReview === "function") renderPracticeReview(); }
  else if (top === "practice-recs") { if (typeof renderPracticeRecs === "function") renderPracticeRecs(); }
}

renderProfileMain();
renderProfileSettings();

showToast(t("toast_lang_updated"));
    };
  });
}

    // --- Pinned list ---
  const pinnedToggleBtn = document.getElementById("profile-settings-pinned-toggle");
  if (pinnedToggleBtn) {
    const expanded = !!profile?.pinnedExpanded;
    pinnedToggleBtn.textContent = expanded ? t("settings_hide") : t("settings_show_all");

    pinnedToggleBtn.onclick = () => {
      const fresh = loadProfile();
      if (!fresh) return;
      fresh.pinnedExpanded = !fresh.pinnedExpanded;
      saveProfile(fresh);
      renderProfileSettings();
    };
  }

  const pinnedWrap = document.getElementById("profile-settings-pinned-list");
  if (pinnedWrap) {
    pinnedWrap.innerHTML = "";

    const expanded = !!profile?.pinnedExpanded;

    const userSubjects = Array.isArray(profile.subjects) ? profile.subjects : [];
   const pinnedSet = new Set(
     userSubjects
       .filter(s => !!s.pinned && s.mode === "study")
       .map(s => s.key)
      );

    // Study (Pinned) can show all subjects when expanded, otherwise only pinned
   const allSubjects = getVisibleSubjectsCatalog();

   const pinnedList = allSubjects.filter(s => pinnedSet.has(s.key));
   const otherList  = allSubjects.filter(s => !pinnedSet.has(s.key));

   const listToRender = expanded ? [...pinnedList, ...otherList] : pinnedList;

       if (!listToRender.length) {
         pinnedWrap.innerHTML = `<div class="empty muted">${t("settings_no_pinned")}</div>`;
         return;
       }

    listToRender.forEach(subj => {
      const isPinned = pinnedSet.has(subj.key);

      const row = document.createElement("div");
      row.className = "settings-row" + (isPinned ? " is-on" : "");

      row.innerHTML = `
  <div>
    <div style="font-weight:800">${escapeHTML(subjectTitle(subj.key, subj.title))}</div>
    <div class="muted small">${isPinned ? t("settings_pinned") : t("settings_not_pinned")}</div>
  </div>
  <label class="switch">
    <input type="checkbox" ${isPinned ? "checked" : ""}>
    <span class="slider"></span>
  </label>
`;

const input = row.querySelector('input[type="checkbox"]');

input?.addEventListener("change", async () => {
  const fresh = loadProfile();
  if (!fresh) return;

  // ✅ UI-guard: cannot pin if mode=competitive (project rule)
  const curr = Array.isArray(fresh?.subjects) ? fresh.subjects.find(s => s.key === subj.key) : null;
  const currMode = curr?.mode || "study";
  const currPinned = !!curr?.pinned;

  // If user is trying to TURN ON pin while competitive → block & revert UI
  const wantsPin = !currPinned; // because we toggle
  if (wantsPin && currMode === "competitive") {
    // revert toggle UI to OFF
    try { input.checked = false; } catch {}
    showToast(t("toast_pin_competitive_forbidden") || "Нельзя закрепить предмет в режиме Competitive");
    return; // IMPORTANT: no local change, no DB write
  }

  const updated = togglePinnedSubject(fresh, subj.key);
  saveProfile(updated);
  const after = (updated?.subjects || []).find(x => x.key === subj.key) || null;
  const fromPinned = currPinned;
  const toPinned = !!after?.pinned;
  const fromMode = currMode;
  const toMode = after?.mode || "study";

  try {
    const us = Array.isArray(updated?.subjects) ? updated.subjects.find(s => s.key === subj.key) : null;
    const mode = us?.mode || "study";
    const pinned = !!us?.pinned;

 try {
      trackEvent("user_subjects_save_started", { subject_key: subj.key, mode, is_pinned: pinned });
    } catch {}
     
        const res = await syncUserSubjectToSupabase(subj.key, mode, pinned);

  try {
    trackEvent("user_subjects_save_result", {
      ok: !!res?.ok,
      reason: res?.reason || null,
      method: res?.method || null,
      subject_key: subj.key
    });
  } catch {}

  if (res?.ok) {
    const subjectId = res?.subjectId || await getSubjectIdByKey(subj.key);
    if (subjectId) {
      await writeUserSubjectsHistory({
        user_id: res?.uid,
        subject_id: subjectId,
        action: "pin_change",
        from_mode: fromMode,
        to_mode: toMode,
        from_pinned: fromPinned,
        to_pinned: toPinned,
        source: "profile_settings",
        meta: { subject_key: subj.key }
      });
    }

    __profileSubjectsDbReady = false;
    await ensureProfileSubjectsDbSynced();
  } else {
    // rollback UI
    try { input.checked = fromPinned; } catch {}
    showToast(t("save_failed_try_again"));
    return;
  }
} catch {
  try { input.checked = fromPinned; } catch {}
  showToast("Ошибка сохранения. Попробуйте ещё раз.");
  return;
}

renderHome();
if (state.tab === "courses") renderAllSubjects();
renderProfileMain();
renderProfileSettings();

showToast(toPinned ? t("toast_added_pinned") : t("toast_removed_pinned"));
});

      pinnedWrap.appendChild(row);
    });
  }
}

  function renderProfileMain() {
  const profile = loadProfile();

  // ✅ ensure old profiles get region_tr/district_tr from DB (so geo translates on UI language switch)
  if (profile && window.sb) {
    ensureProfileGeoTranslationsHydrated()
      .then((res) => {
        if (res?.ok && res?.updated) {
          try { renderHome(); } catch {}
          if (state?.tab === "profile") {
            try { renderProfileMain(); } catch {}
            try { renderProfileSettings(); } catch {}
          }
        }
      })
      .catch(() => {});
  }

  if (profile && window.sb && !__profileSubjectsDbReady) {
    const compElTmp = document.getElementById("profile-metric-competitive");
    const studyElTmp = document.getElementById("profile-metric-study");
    if (compElTmp) compElTmp.textContent = "…";
    if (studyElTmp) studyElTmp.textContent = "…";

       ensureProfileSubjectsDbSynced()
     .then((res) => {
       // ✅ перерисовываем ТОЛЬКО после завершённого sync,
       // чтобы не уйти в цикл мгновенных .then() при res.skipped=true
       if (res?.ok && !res?.skipped && state?.tab === "profile") {
         try { renderProfileMain(); } catch {}
         try { renderProfileSettings(); } catch {}
       }
     })
     .catch(() => {});
   return;
  }
  
  const nameEl = document.getElementById("profile-dash-name");
  const metaEl = document.getElementById("profile-dash-meta");
  const avatarEl = document.getElementById("profile-avatar");
  const avatarInitials = document.getElementById("profile-avatar-initials");
  const currentLevelEl = document.getElementById("profile-current-level");
  const slotsCountEl = document.getElementById("profile-competitive-slots-count");
  const slotsListEl = document.getElementById("profile-competitive-slots-list");
     
  const compEl = document.getElementById("profile-metric-competitive");
  const studyEl = document.getElementById("profile-metric-study");

  const bestEl = document.getElementById("profile-metric-best");
  const trendEl = document.getElementById("profile-metric-trend");
  const stabilityEl = document.getElementById("profile-metric-stability");
  const toursEl = document.getElementById("profile-metric-tours");

  const hintEl = document.getElementById("profile-dash-hint");
  const ratingsBtn = document.querySelector('[data-action="profile-open-ratings"]');

  if (!nameEl || !metaEl || !compEl || !studyEl || !bestEl || !trendEl || !stabilityEl || !toursEl) return;

    if (!profile) {
    nameEl.textContent = t("profile_need_registration_title");
    metaEl.textContent = "—";
    if (avatarEl) avatarEl.style.backgroundImage = "";
    if (avatarInitials) avatarInitials.textContent = "";
    if (currentLevelEl) currentLevelEl.textContent = "—";
    if (slotsCountEl) slotsCountEl.textContent = "0/2";
    if (slotsListEl) slotsListEl.innerHTML = `<div class="empty muted">${t("home_need_registration")}</div>`;
       
    compEl.textContent = "0";
    studyEl.textContent = "0";

    bestEl.textContent = "—";
    trendEl.textContent = "—";
    stabilityEl.textContent = "—";
    toursEl.textContent = "—";

    if (ratingsBtn) ratingsBtn.disabled = true;

    if (hintEl) hintEl.textContent = t("profile_need_registration_hint");
    return;
  }

    const fullName = String(profile.full_name || "").trim();
  nameEl.textContent = fullName || t("profile_title");

  if (avatarEl) {
    const photo = profile?.telegram?.photo_url || "";
    avatarEl.style.backgroundImage = photo ? `url("${photo}")` : "";
    if (avatarInitials) avatarInitials.textContent = photo ? "" : (fullName.split(" ").map(p => p[0]).slice(0, 2).join("").toUpperCase() || "IC");
  }

    // ✅ Geo should follow current UI language (not the language used during registration)
  const lang = (window.i18n?.getLang ? window.i18n.getLang() : "ru");

  const pickTr = (tr, fallback) => {
    let obj = tr;
    if (typeof obj === "string") {
      try { obj = JSON.parse(obj); } catch { obj = null; }
    }
    if (obj && typeof obj === "object") {
      if (lang === "uz") return String(obj.uz || obj.ru || fallback || "").trim();
      if (lang === "en") return String(obj.en || obj.ru || fallback || "").trim();
      return String(obj.ru || fallback || "").trim();
    }
    return String(fallback || "").trim();
  };

  // If we have ids but no translations cached locally — hydrate once from DB and rerender
  if (window.sb && (profile.region_id || profile.district_id) && (!profile.region_tr || !profile.district_tr)) {
    (async () => {
      try {
        const p2 = loadProfile();
        if (!p2) return;

        let changed = false;

        if (p2.region_id && !p2.region_tr) {
          const { data: rRow } = await window.sb
            .from("regions")
            .select("id,name_ru,name_uz,name_en,name")
            .eq("id", Number(p2.region_id))
            .maybeSingle();

          if (rRow) {
            p2.region_tr = {
              ru: String(rRow.name_ru || rRow.name || "").trim(),
              uz: String(rRow.name_uz || rRow.name_ru || rRow.name || "").trim(),
              en: String(rRow.name_en || rRow.name_ru || rRow.name || "").trim()
            };
            changed = true;
          }
        }

        if (p2.district_id && !p2.district_tr) {
          const { data: dRow } = await window.sb
            .from("districts")
            .select("id,name_ru,name_uz,name_en,name")
            .eq("id", Number(p2.district_id))
            .maybeSingle();

          if (dRow) {
            p2.district_tr = {
              ru: String(dRow.name_ru || dRow.name || "").trim(),
              uz: String(dRow.name_uz || dRow.name_ru || dRow.name || "").trim(),
              en: String(dRow.name_en || dRow.name_ru || dRow.name || "").trim()
            };
            changed = true;
          }
        }

        if (changed) {
          saveProfile(p2);
          // rerender profile so meta updates immediately after hydrate
          renderProfileMain();
        }
      } catch {}
    })();
  }

  const metaParts = [];

  const regionLabel = pickTr(profile.region_tr, profile.region);
  const districtLabel = pickTr(profile.district_tr, profile.district);

  if (regionLabel) metaParts.push(regionLabel);
  if (districtLabel) metaParts.push(districtLabel);

  if (profile.school) {
    metaParts.push(`№${String(profile.school).replace(/^№/,"")}`);
  }

  if (profile.class) {
    const suffix = t("class_suffix") || "";
    metaParts.push(suffix ? `${String(profile.class).trim()} ${suffix}`.trim() : String(profile.class).trim());
  }

  metaEl.textContent = metaParts.join(" • ") || "—";

          const subjects = filterActiveUserSubjects(profile.subjects || []);
  const comp = subjects.filter(s => s.mode === "competitive");
  const study = subjects.filter(s => s.mode === "study" && !!s.pinned);
  const pinned = subjects.filter(s => !!s.pinned);

  compEl.textContent = String(comp.length);
  studyEl.textContent = String(study.length);

  // --- Best / Trend / Stability (только новая tour-bound история practice_history_v2:*) ---
const keys = subjects.map(s => s.key).filter(Boolean);

// Best (max percent)
let best = null;
const allAttempts = [];

keys.forEach(k => {
  const h = loadAllPracticeHistoryBySubject(k);
  if (h?.best) {
    if (
      !best ||
      Number(h.best.percent) > Number(best.percent) ||
      (
        Number(h.best.percent) === Number(best.percent) &&
        Number(h.best.durationSec) < Number(best.durationSec)
      )
    ) {
      best = h.best;
    }
  }
  if (Array.isArray(h?.last)) allAttempts.push(...h.last.map(a => ({ ...a, _subjectKey: k })));
});

  bestEl.textContent = best ? `${Math.round(Number(best.percent) || 0)}%` : "—";

  // Trend: avg(last 3) - avg(prev 3)
  allAttempts.sort((a, b) => (Number(b.ts) || 0) - (Number(a.ts) || 0));
  const last6 = allAttempts.slice(0, 6);
  if (last6.length >= 4) {
    const a3 = last6.slice(0, 3);
    const b3 = last6.slice(3, 6);

    const avg = arr => arr.reduce((s, x) => s + (Number(x.percent) || 0), 0) / Math.max(1, arr.length);
    const diff = Math.round(avg(a3) - avg(b3));

    trendEl.textContent = (diff === 0) ? "0%" : `${diff > 0 ? "+" : ""}${diff}%`;
  } else {
    trendEl.textContent = "—";
  }

  // Stability: уникальные дни с практикой за последние 7 дней
  const now = Date.now();
  const weekMs = 7 * 24 * 60 * 60 * 1000;
  const days = new Set();
  allAttempts.forEach(a => {
    const ts = Number(a.ts) || 0;
    if (!ts) return;
    if (now - ts > weekMs) return;
    const d = new Date(ts);
    const key = `${d.getFullYear()}-${d.getMonth() + 1}-${d.getDate()}`;
    days.add(key);
  });
    const activeDays = days.size;

    if (!allAttempts.length) {
    stabilityEl.textContent = t("profile_stability_no_data");
  } else {
    const pct = Math.round((activeDays / 7) * 100);
    stabilityEl.textContent = (pct > 0) ? `${pct}%` : t("profile_stability_no_activity");
  }

  toursEl.textContent = "…";
  getProfileCompletedToursCount()
    .then((count) => {
      if (!toursEl) return;
      toursEl.textContent = (count == null) ? "—" : String(count);
    })
    .catch(() => {
      if (!toursEl) return;
      toursEl.textContent = "—";
    });
  
  if (currentLevelEl) {
    const bestPct = Number(best?.percent || 0);
    const level = bestPct >= 85 ? t("profile_level_advanced") : (bestPct >= 70 ? t("profile_level_intermediate") : (bestPct > 0 ? t("profile_level_beginner") : "—"));
    currentLevelEl.textContent = level;
  }

    if (slotsCountEl) slotsCountEl.textContent = `${comp.length}/2`;
  if (slotsListEl) {
    slotsListEl.innerHTML = "";

    // 1) Активные competitive слоты (0..2)
        comp.forEach(us => {
      const subj = subjectByKey(us.key);
      const row = document.createElement("div");
      row.className = "slot-card";
      row.innerHTML = `
        <div>
          <div class="slot-title">${escapeHTML(subjectTitle(us.key, subj?.title || us.key))}</div>
          <div class="muted small" data-slot-hint="${escapeHTML(us.key)}">${t("profile_slot_hint_loading")}</div>
        </div>
        <button type="button" class="btn mini" data-subject="${escapeHTML(us.key)}">${t("profile_view_btn")}</button>
      `;

      row.querySelector("button")?.addEventListener("click", () => {
        state.courses.subjectKey = us.key;
        saveState();
        setTab("courses");
        replaceCourses("subject-hub");
        renderSubjectHub();
      });

      slotsListEl.appendChild(row);

      getProfileCompetitiveSlotHint(us.key)
        .then((hint) => {
          const hintEl = row.querySelector(`[data-slot-hint="${CSS.escape(String(us.key))}"]`);
          if (hintEl) hintEl.textContent = hint || t("profile_slot_hint_unpublished");
        })
        .catch(() => {
          const hintEl = row.querySelector(`[data-slot-hint="${CSS.escape(String(us.key))}"]`);
          if (hintEl) hintEl.textContent = t("profile_slot_hint_unpublished");
        });
    });

    // 2) Пустые слоты до 2 (Empty slot + JOIN)
    const emptyCount = Math.max(0, 2 - comp.length);
    for (let i = 0; i < emptyCount; i++) {
      const row = document.createElement("div");
      row.className = "slot-card is-empty";
      row.innerHTML = `
        <div>
          <div class="slot-empty-title">${t("profile_empty_slot")}</div>
          <div class="muted small">${t("reg_competitive_subject_hint")}</div>
        </div>
        <button type="button" class="btn join" data-action="profile-settings">${t("profile_join_btn")}</button>
      `;

      row.querySelector("button")?.addEventListener("click", () => {
        setTab("profile");
        replaceProfile("settings");
      });

      slotsListEl.appendChild(row);
    }
  }
   
  // Disabled state: рейтинг/туры только школьникам
  if (ratingsBtn) {
    const isSchool = !!profile.is_school_student;
    ratingsBtn.disabled = !isSchool;
    if (!isSchool) ratingsBtn.title = t("disabled_not_school");
  }

  if (hintEl) {
  hintEl.textContent = pinned.length
    ? t("profile_pinned_hint_has")
    : t("profile_pinned_hint_empty");
}
      // Credentials (Profile: list + progress)
try { renderProfileCredentialsUI(); } catch {}

   // ✅ подтягиваем из БД и перерисовываем (чтобы работало у всех и всегда)
   if (window.sb) {
     ensureCredentialsDbSynced()
       .then(() => { try { renderProfileCredentialsUI(); } catch {} })
       .catch(() => {});
      }
    }

     // ---------------------------
  // Modal (for confirmations in Telegram WebApp)
  // ---------------------------
  let modalResolve = null;

  function closeModal(result = null) {
    const root = document.getElementById("modal-root");
    if (!root) return;
    root.innerHTML = "";
    root.setAttribute("aria-hidden", "true");
    document.body.classList.remove("modal-open");
    if (typeof modalResolve === "function") {
      const r = modalResolve;
      modalResolve = null;
      r(result);
    }
  }

  function openModal(html) {
    const root = document.getElementById("modal-root");
    if (!root) return;
    root.innerHTML = html;
    root.setAttribute("aria-hidden", "false");
    document.body.classList.add("modal-open");

    // backdrop close (only if data-close="backdrop")
    const backdrop = root.querySelector("[data-modal-backdrop]");
    if (backdrop) {
      backdrop.addEventListener("click", (e) => {
        if (e.target === backdrop && backdrop.dataset.close === "backdrop") {
          closeModal(false);
        }
      });
    }

    // buttons
    root.querySelectorAll("[data-modal-action]").forEach(btn => {
      btn.addEventListener("click", () => {
        const act = btn.getAttribute("data-modal-action");
        if (act === "ok") closeModal(true);
        if (act === "cancel") closeModal(false);
      });
    });
  }

  function uiConfirm({ title, message, okText, cancelText } = {}) {
  const _ok = okText ?? t("ok");
  const _cancel = cancelText ?? t("cancel");

  return new Promise((resolve) => {
    modalResolve = resolve;

    const html = `
      <div class="modal-backdrop" data-modal-backdrop data-close="none">
        <div class="modal">
          <div class="modal-title">${escapeHTML(title || "")}</div>
          <div class="modal-text">${escapeHTML(message || "")}</div>
          <div class="modal-actions">
            <button type="button" class="btn" data-modal-action="cancel">${escapeHTML(_cancel)}</button>
            <button type="button" class="btn primary" data-modal-action="ok">${escapeHTML(_ok)}</button>
          </div>
        </div>
      </div>
    `;

    openModal(html);
  });
}

function uiAlert({ title, message, okText } = {}) {
  const _ok = okText ?? t("ok");

  return new Promise((resolve) => {
    modalResolve = resolve;

    const html = `
      <div class="modal-backdrop" data-modal-backdrop data-close="none">
        <div class="modal">
          <div class="modal-title">${escapeHTML(title || "")}</div>
          <div class="modal-text">${escapeHTML(message || "")}</div>
          <div class="modal-actions modal-actions-single">
            <button type="button" class="btn primary" data-modal-action="ok">${escapeHTML(_ok)}</button>
          </div>
        </div>
      </div>
    `;

    openModal(html);
  });
}

  // ---------------------------
  // Toast
  // ---------------------------
    let toastTimer = null;
  function showToast(message, ms = 2500) {
    const el = $("#toast");
    if (!el) return;

    let msg = message;
    if (typeof msg === "string") {
      const legacyMap = {
        "Выберите вариант ответа": "select_option_required",
        "Проверьте формат ответа": "invalid_answer_format",
        "Ошибка сети. Попробуйте ещё раз.": "network_error_try_again",
        "Неверная ссылка.": "invalid_link",
        "Не удалось сохранить. Попробуйте ещё раз.": "save_failed_try_again",
        "Не удалось сохранить в базе. Попробуйте ещё раз.": "save_failed_db_try_again",
        "Туры доступны только для основных предметов.": "disabled_not_main"
      };
      const key = legacyMap[msg];
      if (key) msg = t(key);
    }

    el.textContent = msg;
    el.classList.add("is-show");
    if (toastTimer) clearTimeout(toastTimer);
    toastTimer = setTimeout(() => el.classList.remove("is-show"), ms);
  }

   // ---------------------------
  // Support
  // ---------------------------
  const SUPPORT_BOT_USERNAME = "iClub_Ariza_bot";
  const SUPPORT_MIN_MESSAGE_LEN = 10;

  let supportUi = {
    category: "",
    sourceErrorCode: null
  };

  function normalizeSupportSignature(value) {
    return String(value || "")
      .toLowerCase()
      .trim()
      .replace(/\s+/g, " ")
      .slice(0, 400);
  }

  function getSupportContext() {
    const topView = Array.isArray(state?.viewStack) && state.viewStack.length
      ? state.viewStack[state.viewStack.length - 1]
      : (state?.tab || "home");

    return {
      tab: state?.tab || "home",
      top_view: topView,
      profile_screen: (state?.tab === "profile" && typeof getProfileTopScreen === "function")
        ? getProfileTopScreen()
        : null,
      course_screen: (state?.tab === "courses" && typeof getCoursesTopScreen === "function")
        ? getCoursesTopScreen()
        : null,
      subject_key: state?.courses?.subjectKey || null,
      lesson_id: state?.courses?.lessonId || null,
      tour_id: state?.tourContext?.tourId || null,
      attempt_id: state?.tourContext?.attemptId || state?.courses?.lastTourAttemptId || null,
      certificate_id: state?.certificates?.selectedId || null,
      ui_language: currentLang(),
      is_online: (typeof navigator !== "undefined" ? navigator.onLine !== false : true),
      error_code: supportUi.sourceErrorCode || null
    };
  }

  function getSupportTelegramUserId() {
    try {
      const tgId = window.Telegram?.WebApp?.initDataUnsafe?.user?.id;
      const n = Number(tgId || 0);
      if (n > 0) return n;
    } catch {}

    try {
      const profileTgId = loadProfile()?.telegram_user_id;
      const n = Number(profileTgId || 0);
      if (n > 0) return n;
    } catch {}

    return null;
  }

  async function invokeSupportDispatch(ticketId) {
    const fnUrl = `${SUPABASE_URL}/functions/v1/support-dispatch`;

    const headers = {
      "Content-Type": "application/json",
      "apikey": SUPABASE_ANON_KEY,
      "Authorization": `Bearer ${SUPABASE_ANON_KEY}`
    };

    const res = await fetch(fnUrl, {
      method: "POST",
      headers,
      body: JSON.stringify({ ticket_id: Number(ticketId) })
    });

    const data = await res.json().catch(() => null);

    if (!res.ok || !data?.ok) {
      throw new Error(data?.error || "support_dispatch_failed");
    }

    return data;
  }

  function getSupportTopics() {
    return [
      {
        key: "login",
        title: t("support_topic_login"),
        sub: tr3("Проблемы со входом, профилем и регистрацией", "Kirish, profil va ro‘yxatdan o‘tish muammolari", "Problems with login, profile, and registration"),
        faqs: [
          {
            q: tr3("Не получается войти или профиль выглядит пустым", "Kirish ishlamayapti yoki profil bo‘sh ko‘rinmoqda", "I cannot log in or the profile looks empty"),
            a: tr3("Проверьте интернет и перезапустите приложение. Если проблема повторяется, отправьте обращение ниже.", "Internetni tekshiring va ilovani qayta oching. Muammo takrorlansa, quyida murojaat yuboring.", "Check your internet and reopen the app. If the issue repeats, send a request below.")
          }
        ]
      },
      {
        key: "modes",
        title: t("support_topic_modes"),
        sub: tr3("Competitive, Study и доступность предметов", "Competitive, Study va fanlar holati", "Competitive, Study, and subject availability"),
        faqs: [
          {
            q: tr3("Почему туры недоступны", "Nega turlar yopiq", "Why are tours unavailable"),
            a: tr3("Активные туры доступны только школьникам и только по competitive-предметам.", "Faol turlar faqat maktab o‘quvchilari va faqat competitive fanlar uchun ochiladi.", "Active tours are available only for school students and only for competitive subjects.")
          }
        ]
      },
      {
        key: "practice",
        title: t("support_topic_practice"),
        sub: tr3("Практика, разбор ошибок и рекомендации", "Amaliyot, xatolar tahlili va tavsiyalar", "Practice, review, and recommendations"),
        faqs: [
          {
            q: tr3("Где разбор ошибок и рекомендации", "Xatolar tahlili va tavsiyalar qayerda", "Where are review and recommendations"),
            a: tr3("Они появляются после завершения практики на экране результата.", "Ular amaliyot tugagach natija ekranida ko‘rinadi.", "They appear on the result screen after you finish practice.")
          }
        ]
      },
      {
        key: "tours",
        title: t("support_topic_tours"),
        sub: tr3("Туры, таймер и завершение попытки", "Turlar, taymer va urinish yakuni", "Tours, timer, and attempt completion"),
        faqs: [
          {
            q: tr3("Почему тур завершился раньше", "Nega tur oldinroq tugadi", "Why did the tour finish earlier"),
            a: tr3("Тур может завершиться по времени или из-за anti-cheat правил. Если вы считаете, что это ошибка, нужен ручной разбор.", "Tur vaqt tugagani yoki anti-cheat qoidalari sabab yakunlanishi mumkin. Agar buni xato deb hisoblasangiz, qo‘lda tekshiruv kerak.", "A tour may finish because time expired or because of anti-cheat rules. If you believe it was a mistake, it requires manual review.")
          }
        ]
      },
      {
        key: "ratings",
        title: t("support_topic_ratings"),
        sub: tr3("Рейтинг, позиции и отображение результатов", "Reyting, o‘rinlar va natijalar ko‘rinishi", "Ratings, positions, and result visibility"),
        faqs: [
          {
            q: tr3("Кажется, рейтинг неправильный", "Reyting noto‘g‘ri ko‘rinmoqda", "The rating looks incorrect"),
            a: tr3("Это спорный случай и он не решается автоматически. Отправьте обращение ниже.", "Bu bahsli holat va avtomatik hal qilinmaydi. Quyida murojaat yuboring.", "This is a disputed case and it is not resolved automatically. Send a request below.")
          }
        ]
      },
      {
        key: "certificates",
        title: t("support_topic_certificates"),
        sub: tr3("Открытие, доступность и итоговые сертификаты", "Ochilishi, mavjudligi va yakuniy sertifikatlar", "Opening, availability, and final certificates"),
        faqs: [
          {
            q: tr3("Почему сертификат не открывается", "Nega sertifikat ochilmayapti", "Why the certificate does not open"),
            a: tr3("Сначала убедитесь, что он уже доступен по правилам. Если должен открываться, но не открывается, отправьте обращение ниже.", "Avval sertifikat qoidalarga ko‘ra ochilganini tekshiring. Ochilishi kerak bo‘lsa-yu ochilmasa, quyida murojaat yuboring.", "First make sure it is already available by the rules. If it should open but still does not, send a request below.")
          },
          {
            q: tr3("Когда появляется итоговый сертификат", "Yakuniy sertifikat qachon paydo bo‘ladi", "When does the final certificate appear"),
            a: tr3("Итоговый сертификат открывается только после глобального завершения всей серии.", "Yakuniy sertifikat butun seriya global yakunlangandan keyin ochiladi.", "The final certificate becomes available only after the whole series is globally completed.")
          }
        ]
      },
      {
        key: "content",
        title: t("support_topic_content"),
        sub: tr3("Вопросы, ответы, объяснения и переводы", "Savollar, javoblar, tushuntirishlar va tarjimalar", "Questions, answers, explanations, and translations"),
        faqs: [
          {
            q: tr3("Ошибка в вопросе, переводе или объяснении", "Savolda, tarjimada yoki tushuntirishda xato", "There is an issue in a question, translation, or explanation"),
            a: tr3("Такие случаи не решаются автоматически. Отправьте обращение и укажите как можно больше деталей.", "Bunday holatlar avtomatik hal qilinmaydi. Murojaat yuborib, iloji boricha ko‘proq detal yozing.", "These cases are not resolved automatically. Send a request and include as many details as possible.")
          }
        ]
      },
      {
        key: "technical",
        title: t("support_topic_technical"),
        sub: tr3("Сеть, загрузка, сохранение и технические ошибки", "Tarmoq, yuklash, saqlash va texnik xatolar", "Network, loading, saving, and technical errors"),
        faqs: [
          {
            q: tr3("Ошибка сети или сохранения", "Tarmoq yoki saqlash xatosi", "Network or saving error"),
            a: tr3("Сначала попробуйте повторить действие при стабильном интернете. Если проблема повторяется, отправьте обращение ниже.", "Avval internet barqaror bo‘lganda amalni yana bir marta bajarib ko‘ring. Muammo takrorlansa, quyida murojaat yuboring.", "First retry the action with a stable internet connection. If it happens again, send a request below.")
          }
        ]
      }
    ];
  }

  function getSupportTopicByKey(key) {
    return getSupportTopics().find(x => x.key === key) || null;
  }

  function renderSupportView() {
    const topicsEl = document.getElementById("support-topics");
    if (!topicsEl) return;

    const topics = getSupportTopics();

    topicsEl.innerHTML = topics.map(topic => `
      <button class="card-btn support-cat-btn" type="button" data-action="open-support-topic" data-key="${escapeHTML(topic.key)}">
        <div class="card-title">${escapeHTML(topic.title)}</div>
        <div class="muted small" style="margin-top:6px">${escapeHTML(topic.sub)}</div>
      </button>
    `).join("");
  }

  function renderSupportTopicView() {
    const topic = getSupportTopicByKey(supportUi.category);
    const titleEl = document.getElementById("support-topic-title");
    const subEl = document.getElementById("support-topic-sub");
    const faqEl = document.getElementById("support-topic-faq");
    const msgEl = document.getElementById("support-message");
    const statusEl = document.getElementById("support-submit-status");

    if (!topic || !titleEl || !subEl || !faqEl) return;

    titleEl.textContent = topic.title;
    subEl.textContent = topic.sub || "";

    faqEl.innerHTML = topic.faqs.map(item => `
      <div class="card">
        <div style="font-weight:800; margin-bottom:6px">${escapeHTML(item.q)}</div>
        <div class="muted small">${escapeHTML(item.a)}</div>
      </div>
    `).join("");

    if (msgEl) {
      msgEl.value = "";
      msgEl.setAttribute("placeholder", t("support_message_placeholder"));
    }

    if (statusEl) {
      statusEl.textContent = "";
    }
  }

  function openSupport(prefill = {}) {
    supportUi = {
      ...supportUi,
      category: "",
      sourceErrorCode: prefill.errorCode || null
    };

    openGlobal("support");
    renderSupportView();

    try {
      trackEvent("support_opened", getSupportContext());
    } catch {}
  }

  function openSupportTopic(topicKey) {
    supportUi.category = String(topicKey || "").trim();
    openGlobal("support-topic");
    renderSupportTopicView();

    try {
      trackEvent("support_category_selected", {
        category: supportUi.category,
        ...getSupportContext()
      });
    } catch {}
  }

  async function findRecentSupportDuplicate(userId, category, signature) {
    if (!window.sb || !userId || !category || !signature) return null;

    const sinceIso = new Date(Date.now() - 30 * 60 * 1000).toISOString();

    const { data, error } = await window.sb
      .from("support_tickets")
      .select("id, created_at, status")
      .eq("user_id", userId)
      .eq("category", category)
      .eq("signature", signature)
      .gte("created_at", sinceIso)
      .order("created_at", { ascending: false })
      .limit(1);

    if (error) return null;
    return Array.isArray(data) && data.length ? data[0] : null;
  }

  async function submitSupportTicket() {
    const msgEl = document.getElementById("support-message");
    const statusEl = document.getElementById("support-submit-status");
    const submitBtn = document.getElementById("support-submit");

    const category = String(supportUi.category || "").trim();
    const message = String(msgEl?.value || "").trim();

    if (!category) {
      showToast(t("support_select_topic_first"));
      return;
    }

        if (!message) {
      showToast(t("support_message_required"));
      return;
    }

    if (message.length < SUPPORT_MIN_MESSAGE_LEN) {
      showToast(t("support_message_too_short"));
      if (statusEl) statusEl.textContent = t("support_message_too_short");
      return;
    }

    if (typeof navigator !== "undefined" && navigator.onLine === false) {
      if (statusEl) statusEl.textContent = t("support_ticket_offline");
      showToast(t("support_ticket_offline"));
      return;
    }

    const uid = await getAuthUid().catch(() => null);
    if (!uid || !window.sb) {
      if (statusEl) statusEl.textContent = t("support_ticket_failed");
      showToast(t("support_ticket_failed"));
      return;
    }

    const tgUid = getSupportTelegramUserId();
    const signature = normalizeSupportSignature(`${category}::${message}`);

    try {
      if (submitBtn) {
        submitBtn.disabled = true;
        submitBtn.classList.add("is-loading");
      }
      if (statusEl) statusEl.textContent = "";

      const dup = await findRecentSupportDuplicate(uid, category, signature);
      if (dup) {
        if (statusEl) statusEl.textContent = t("support_ticket_duplicate");
        showToast(t("support_ticket_duplicate"));
        return;
      }

      const payload = {
        user_id: uid,
        telegram_user_id: tgUid,
        category,
        subcategory: null,
        message,
        signature,
        context_json: getSupportContext(),
        severity: ["ratings", "certificates", "tours", "content"].includes(category) ? "high" : "normal",
        status: "new",
        source: "app"
      };

      const { data, error } = await window.sb
        .from("support_tickets")
        .insert(payload)
        .select("id")
        .single();

      if (error) throw error;

      let dispatchRes = null;
      try {
        dispatchRes = await invokeSupportDispatch(Number(data?.id || 0));
      } catch (dispatchErr) {
        try {
          trackEvent("support_dispatch_failed", {
            ticket_id: Number(data?.id || 0) || null,
            category,
            message: String(dispatchErr?.message || dispatchErr || "unknown")
          });
        } catch {}

        if (statusEl) statusEl.textContent = t("support_ticket_dispatch_delayed");
        showToast(t("support_ticket_dispatch_delayed"));
        if (msgEl) msgEl.value = "";
        return;
      }

      try {
        trackEvent("support_ticket_submit_success", {
          ticket_id: Number(data?.id || 0) || null,
          category,
          user_sent: !!dispatchRes?.user_sent
        });
      } catch {}

      const successKey = dispatchRes?.user_sent === false
        ? "support_ticket_saved_start_bot"
        : "support_ticket_saved";

      if (statusEl) statusEl.textContent = t(successKey);
      showToast(t(successKey));

      if (msgEl) msgEl.value = "";
    } catch (e) {
      try {
        trackEvent("support_ticket_submit_failed", {
          category,
          message: String(e?.message || e || "unknown")
        });
      } catch {}

      if (statusEl) statusEl.textContent = t("support_ticket_failed");
      showToast(t("support_ticket_failed"));
    } finally {
      if (submitBtn) {
        submitBtn.disabled = false;
        submitBtn.classList.remove("is-loading");
      }
    }
  }

  // ---------------------------
  // Registration UI
  // ---------------------------
    function updateSchoolFieldsVisibility() {
    const select = $("#reg-is-school");
    const toggle = $("#reg-is-school-toggle");

    const isSchool = toggle ? !!toggle.checked : (select?.value === "yes");

    // keep hidden select in sync (legacy)
    if (select && toggle) {
      select.value = isSchool ? "yes" : "no";
    }

    // show/hide school fields
    const block = $("#reg-school-block");
    if (block) block.style.display = isSchool ? "grid" : "none";

    // ✅ dynamic subject card texts (competitive vs study)
    const labelEl = document.querySelector('[data-i18n="reg_competitive_subject_label"]');
    const hintEl  = document.querySelector('[data-i18n="reg_competitive_subject_hint"]');

    if (labelEl) {
      labelEl.textContent = isSchool ? t("reg_subject_label_competitive") : t("reg_subject_label_study");
    }
    if (hintEl) {
      hintEl.textContent = isSchool ? t("reg_subject_hint_competitive") : t("reg_subject_hint_study");
    }

    // update subject names in chips/selects too
    try { applyRegSubjectI18n(); } catch {}
           // show/hide subjects section for non-school users
    const subjectSection = $("#reg-subject-section");
    const nonStudentCard = $("#reg-nonstudent-subjects");

    if (subjectSection) subjectSection.classList.toggle("hidden", !isSchool);
    if (nonStudentCard) nonStudentCard.classList.toggle("hidden", isSchool);

    // when switching OFF school mode: clear selected subjects (avoid accidental saving)
    if (!isSchool) {
      const main1 = $("#reg-main-subject-1");
      const main2 = $("#reg-main-subject-2");
      const add1  = $("#reg-additional-subject");

      if (main1) main1.value = "";
      if (main2) main2.value = "";
      if (add1) add1.value = "";

      // clear chip UI
      const chipBtns = $$("#reg-subject-chips .chip-btn");
      chipBtns.forEach(b => b.classList.remove("is-active"));
    }

    // refresh submit readiness (if implemented)
    try { updateRegSubmitReady?.(); } catch {}
  }

            function applyRegSubjectI18n() {
    // chips
    const chipBtns = $$("#reg-subject-chips .chip-btn");
    chipBtns.forEach(btn => {
      const key = String(btn.dataset.subjectKey || "").trim();
      if (!key) return;

      btn.classList.toggle("hidden", !isSubjectActive(key));

      const k = "subj_" + key;
      const val = t(k);
      if (val && val !== k) btn.textContent = val;
    });

    // selects options (keep values, translate labels)
    const ids = ["reg-main-subject-1", "reg-main-subject-2", "reg-additional-subject"];
    ids.forEach(id => {
      const sel = document.getElementById(id);
      if (!sel) return;

      Array.from(sel.options).forEach(opt => {
        const v = String(opt.value || "").trim();

        if (!v) {
          if (id === "reg-additional-subject") opt.textContent = t("reg_choose_none");
          else opt.textContent = t("reg_choose_placeholder");
          opt.hidden = false;
          return;
        }

        opt.hidden = !isSubjectActive(v);

        const k = "subj_" + v;
        const val = t(k);
        if (val && val !== k) opt.textContent = val;
      });

      const selected = String(sel.value || "").trim();
      if (selected && !isSubjectActive(selected)) {
        sel.value = "";
      }
    });

    // ✅ refresh translated summary text after language switch
       try {
      document.dispatchEvent(new CustomEvent("reg-subjects-i18n-updated"));
    } catch {}

    const noteEl = document.getElementById("reg-subject-change-note");
    if (noteEl) {
      noteEl.textContent = tr3(
        "Основной предмет можно изменить позже в профиле. Соревновательные предметы тоже можно менять в пределах лимита.",
        "Asosiy fanni keyinroq profilda o‘zgartirish mumkin. Musobaqa fanlarini ham limit doirasida o‘zgartirish mumkin.",
        "You can change your main subject later in Profile. Competitive subjects can also be changed within the limit."
      );
    }
  }

  function initRegSubjectChips() {
  const wrap = $("#reg-subject-chips");
  const main1 = $("#reg-main-subject-1");
  const main2 = $("#reg-main-subject-2");
  if (!wrap || !main1 || !main2) return;

  if (wrap.dataset.bound === "1") {
    try { document.dispatchEvent(new CustomEvent("reg-subjects-i18n-updated")); } catch {}
    return;
  }
  wrap.dataset.bound = "1";

  const summaryEl = $("#reg-subject-summary");
  const buttons = () => $$("#reg-subject-chips .chip-btn");

  const tt = (key, fallback) => {
    const v = t(key);
    return (v && v !== key) ? v : fallback;
  };

  const getSubjectLabel = (subjectKey) => {
    if (!subjectKey) return "";
    const k = "subj_" + subjectKey;
    const v = t(k);
    if (v && v !== k) return v;

    const btn = buttons().find(b => b.dataset.subjectKey === subjectKey);
    return btn ? btn.textContent.trim() : subjectKey;
  };

  const updateSummary = () => {
    if (!summaryEl) return;

    const a = (main1.value || "").trim();
    const b = (main2.value || "").trim();

        if (!a && !b) {
      summaryEl.textContent = t("reg_subject_summary_none");
      return;
    }

    const primaryTag = t("reg_subject_primary_tag");
    const secondaryTag = t("reg_subject_secondary_tag");

    const rows = [];
    if (a) {
      rows.push(
        `<div class="reg-subject-line"><span class="reg-subject-tag">${escapeHTML(primaryTag)}</span><span class="reg-subject-val">${escapeHTML(getSubjectLabel(a))}</span></div>`
      );
    }
    if (b) {
      rows.push(
        `<div class="reg-subject-line"><span class="reg-subject-tag">${escapeHTML(secondaryTag)}</span><span class="reg-subject-val">${escapeHTML(getSubjectLabel(b))}</span></div>`
      );
    }
    summaryEl.innerHTML = rows.join("");
  };
  
     if (!wrap.dataset.i18nBound) {
  document.addEventListener("reg-subjects-i18n-updated", updateSummary);
  wrap.dataset.i18nBound = "1";
}
  
     const syncChipsFromSelects = () => {
    const selected = [main1.value, main2.value].filter(Boolean);
    buttons().forEach(btn => {
      btn.classList.toggle("is-active", selected.includes(btn.dataset.subjectKey));
    });
    updateSummary();
  };

  const syncSelectsFromChips = () => {
    const selected = buttons().filter(b => b.classList.contains("is-active")).map(b => b.dataset.subjectKey);
    main1.value = selected[0] || "";
    main2.value = selected[1] || "";
    updateSummary();
  };

  wrap.addEventListener("click", (e) => {
    const btn = e.target.closest(".chip-btn");
    if (!btn) return;

    const current = buttons().filter(b => b.classList.contains("is-active"));

    if (btn.classList.contains("is-active")) {
      btn.classList.remove("is-active");
      syncSelectsFromChips();
      return;
    }

    if (current.length >= 2) {
      showToast(t("reg_subjects_limit"));
      return;
    }

    btn.classList.add("is-active");
    syncSelectsFromChips();
  });

  if (!main1.dataset.boundChange) {
  main1.addEventListener("change", syncChipsFromSelects);
  main1.dataset.boundChange = "1";
}
if (!main2.dataset.boundChange) {
  main2.addEventListener("change", syncChipsFromSelects);
  main2.dataset.boundChange = "1";
}
syncChipsFromSelects();
}
       // live language switch on registration
         const langSel = $("#reg-language");
     if (langSel) {
       langSel.addEventListener("change", () => {
         try { window.i18n?.setLang(langSel.value); } catch {}
         try { applyStaticI18n(); } catch {}
         try { updateSchoolFieldsVisibility(); } catch {}
         try { applyRegSubjectI18n(); } catch {}
         try { refreshRegionDistrictPlaceholders?.(); } catch {}
         try { refreshRegionDistrictOptionLabels?.(); } catch {}
       });
     }

    // first paint (ensures no RU/EN mix)
    try { applyRegSubjectI18n(); } catch {}

      function isRegistered() {
    const p = loadProfile();
    if (!p || typeof p !== "object") return false;

    const fullName = String(p.full_name || "").trim();
    const lang = String(p.language || "").trim();

    // Ключевой маркер завершённой регистрации:
    // пользователь явно выбрал "школьник/не школьник", значит это boolean, а не null/undefined
    if (typeof p.is_school_student !== "boolean") return false;

    if (!fullName) return false;
    if (!lang) return false;

    const region = String(p.region || "").trim();
    if (!region) return false;

    // Если district_id уже есть в профиле, название района тоже должно быть заполнено.
    // Это не ломает старые профили без district_id, но закрывает обход "пустой district".
    const hasDistrictId = (p.district_id != null && String(p.district_id).trim() !== "");
    const district = String(p.district || "").trim();
    if (hasDistrictId && !district) return false;

    // Если школьник — нужны subjects (минимум 1 competitive) + базовые поля школы
    if (p.is_school_student === true) {
      const subjects = Array.isArray(p.subjects) ? p.subjects : [];
      const subjectKeys = subjects.map(s => String(s?.key || "").trim()).filter(Boolean);

      if (new Set(subjectKeys).size !== subjectKeys.length) return false;
      if (!subjectKeys.every(k => isSubjectActive(k))) return false;

      const compCnt = subjects.filter(s => s && s.mode === "competitive" && s.key).length;
      if (compCnt < 1) return false;

      const school = String(p.school || "").trim();
      const klass = String(p.class || "").trim();
      if (!school || !klass) return false;
    }

    return true;
  }

  // ---------------------------
  // Home rendering (demo)
  // ---------------------------
  function applyHomeExtraState() {
  const card = $("#home-extra-card");
  const body = $("#home-extra-body");
  if (!card || !body) return;

  let open = false;
  try {
    open = localStorage.getItem(LS.homeExtraOpen) === "1";
  } catch {}

  card.classList.toggle("is-open", !!open);
}

function toggleHomeExtra() {
  const card = $("#home-extra-card");
  if (!card) return;

  const next = !card.classList.contains("is-open");
  card.classList.toggle("is-open", next);

  try {
    localStorage.setItem(LS.homeExtraOpen, next ? "1" : "0");
  } catch {}
}

function renderHome() {
    const profile = loadProfile();
    const compWrap = $("#home-competitive-list");
    const pinnedWrap = $("#home-study-list");
    if (!compWrap || !pinnedWrap) return;

    compWrap.innerHTML = "";
    pinnedWrap.innerHTML = "";

    if (!profile) {
      compWrap.innerHTML = `<div class="empty muted">${t("home_need_registration")}</div>`;
      pinnedWrap.innerHTML = `<div class="empty muted">${t("home_need_registration")}</div>`;
      return;
    }

        const visibleUserSubjects = filterActiveUserSubjects(profile.subjects || []);
    const comp = visibleUserSubjects.filter(s => s.mode === "competitive");
    const pinned = visibleUserSubjects.filter(s => !!s.pinned && s.mode === "study");


    if (!comp.length) compWrap.innerHTML = `<div class="empty muted">${t("home_competitive_empty")}</div>`;
    if (!pinned.length) pinnedWrap.innerHTML = `<div class="empty muted">${t("home_pinned_empty")}</div>`;

        comp.forEach(s => {
      const card = homeCompetitiveCardEl(s);
      compWrap.appendChild(card);
      // ✅ догружаем реальные Rank + Progress (если есть Supabase-данные)
      updateHomeCompetitiveCard(card, s.key);
    });

    pinned.slice(0, 4).forEach((s, idx) => {
  const tile = homePinnedTileEl(s, idx);
  pinnedWrap.appendChild(tile);
  updateHomePinnedTile(tile, s.key);
});

// ✅ Home extra accordion (restore open/closed)
applyHomeExtraState();
}

      // ===========================
// Home (Competitive) — real Rank + Progress
// ===========================
async function computeHomeCompetitiveStats(subjectKey) {
  const cacheKey = `home_comp:${String(subjectKey || "").trim()}`;
  const cached = _homeStatsCache.get(cacheKey);
  if (cached && (Date.now() - cached.ts) < HOME_STATS_CACHE_TTL_MS) {
    return cached.data;
  }

  const fallback = {
    moduleNo: 1,
    progressPct: 0,
    rankNo: null,
    completedCount: 0,
    totalTours: 0,
    practiceTourNo: 1,
    practiceDone: 0,
    practiceTotal: 0,
    practicePct: 0,
    bestPracticePct: null,
    currentTourNo: 1,
    tourState: "active",
  };

  try {
    if (!window.sb) return fallback;

    const subjectId = await getSubjectIdByKey(subjectKey);
    if (!subjectId) return fallback;

    const uid = await getAuthUid();
    if (!uid) return fallback;

    const toursRes = await window.sb
      .from("tours")
      .select("id,tour_no,start_date,end_date,is_active")
      .eq("subject_id", subjectId)
      .order("tour_no", { ascending: true });

    const tours = Array.isArray(toursRes?.data) ? toursRes.data : [];
    if (!tours.length) return fallback;

    const attemptRes = await window.sb
      .from("tour_attempts")
      .select("id,tour_id,status")
      .eq("user_id", uid)
      .in("status", ["submitted", "time_expired", "anti_cheat", "finished"])
      .order("created_at", { ascending: false });

    const attempts = Array.isArray(attemptRes?.data) ? attemptRes.data : [];
    const completedTourIds = new Set(
      attempts.map(a => Number(a?.tour_id)).filter(Boolean)
    );

    const completedCount = tours.filter(t => completedTourIds.has(Number(t.id))).length;
    const totalTours = tours.length || 0;

    const pad2 = (n) => String(n).padStart(2, "0");
    const d0 = new Date();
    const todayISO = `${d0.getFullYear()}-${pad2(d0.getMonth() + 1)}-${pad2(d0.getDate())}`;

    const isInWindow = (row) => {
      const sd = row?.start_date ? String(row.start_date) : null;
      const ed = row?.end_date ? String(row.end_date) : null;
      const afterStart = !sd || sd <= todayISO;
      const beforeEnd = !ed || ed >= todayISO;
      return afterStart && beforeEnd;
    };

        const activeTour = tours
      .filter(t => !!t?.is_active && isInWindow(t))
      .sort((a, b) => Number(a?.tour_no || 0) - Number(b?.tour_no || 0))[0] || null;

    const upcomingTour = tours
      .filter(t => {
        if (!t?.is_active) return false;
        const sd = t?.start_date ? String(t.start_date) : null;
        return !!sd && sd > todayISO;
      })
      .sort((a, b) => Number(a?.tour_no || 0) - Number(b?.tour_no || 0))[0] || null;

    const hasStartedOrEndedTour = tours.some(t => {
      const sd = t?.start_date ? String(t.start_date) : null;
      const ed = t?.end_date ? String(t.end_date) : null;
      return (!!sd && sd <= todayISO) || (!!ed && ed < todayISO);
    });

    let tourState = "upcoming";
    if (activeTour) {
      tourState = completedTourIds.has(Number(activeTour.id)) ? "passed" : "active";
    } else if (upcomingTour) {
      tourState = "upcoming";
    } else if (hasStartedOrEndedTour) {
      tourState = "finished";
    }

    const practiceStageCtx = await getPracticeStageContext(subjectKey);
    const practiceTourNo = Number(
      practiceStageCtx?.practiceTourNo ||
      activeTour?.tour_no ||
      upcomingTour?.tour_no ||
      1
    );

    const stageStats = await computePracticeStageStats(subjectKey, practiceTourNo);

    const practiceDone = Number(stageStats?.masteredCount || 0);
    const practiceTotal = Number(stageStats?.totalCount || 0);
    const practicePct = practiceTotal > 0
      ? Math.max(0, Math.min(100, Math.round((practiceDone / practiceTotal) * 100)))
      : 0;

    const bestPracticePct = (
      stageStats?.best?.percent != null &&
      Number.isFinite(Number(stageStats.best.percent))
    )
      ? Math.round(Number(stageStats.best.percent))
      : null;

       const out = {
      moduleNo: practiceTourNo,
      progressPct: practicePct,
      rankNo: null,
      completedCount,
      totalTours,
      practiceTourNo,
      practiceDone,
      practiceTotal,
      practicePct,
      bestPracticePct,
      currentTourNo: Number(activeTour?.tour_no || upcomingTour?.tour_no || practiceTourNo || 1),
      upcomingTourNo: Number(upcomingTour?.tour_no || practiceTourNo || 1),
      upcomingTourStartDate: upcomingTour?.start_date ? String(upcomingTour.start_date) : null,
      activeTourStartDate: activeTour?.start_date ? String(activeTour.start_date) : null,
      activeTourEndDate: activeTour?.end_date ? String(activeTour.end_date) : null,
      tourState,
    };

    _homeStatsCache.set(cacheKey, { ts: Date.now(), data: out });
    return out;
  } catch {
    return fallback;
  }
}

async function updateHomeCompetitiveCard(cardEl, subjectKey) {
  try {
    if (!cardEl) return;

    const badgeEl = cardEl.querySelector(".home-competitive-badge");
    const modEl = cardEl.querySelector(".js-home-comp-module");
    const noteEl = cardEl.querySelector(".js-home-comp-note");
    const rankEl = cardEl.querySelector(".js-home-comp-rank");
    const percentEl = cardEl.querySelector(".js-home-comp-percent");
        const fillEl = cardEl.querySelector(".js-home-comp-fill");
    const btnEl = cardEl.querySelector(".home-competitive-btn");

    const s = await computeHomeCompetitiveStats(subjectKey);

    const practiceTourNo = Number(s?.practiceTourNo || s?.moduleNo || 1);
    const done = Number(s?.practiceDone || 0);
    const total = Number(s?.practiceTotal || 0);
    const practicePct = total > 0
      ? Math.max(0, Math.min(100, Math.round((done / total) * 100)))
      : Number(s?.practicePct || 0);

    const bestPracticePct = (
      s?.bestPracticePct != null && Number.isFinite(Number(s.bestPracticePct))
    )
      ? Math.round(Number(s.bestPracticePct))
      : null;

        const tourState = String(s?.tourState || "active");

    let badgeKey = "home_badge_tour_active";
    let noteKey = "home_note_tour_active";

    if (tourState === "passed") {
      badgeKey = "home_badge_tour_passed";
      noteKey = "home_note_tour_passed";
    } else if (tourState === "upcoming") {
      badgeKey = "home_badge_tour_upcoming";
      noteKey = "home_note_tour_upcoming";
    } else if (tourState === "finished") {
      badgeKey = "home_badge_tour_finished";
      noteKey = "home_note_tour_finished";
    }

    if (badgeEl) {
  badgeEl.textContent = t(badgeKey) || "";
  badgeEl.classList.toggle("is-passed", tourState === "passed");
  badgeEl.classList.toggle("is-finished", tourState === "finished");
}

if (modEl) {
  modEl.textContent =
    t("home_practice_for_tour", { n: practiceTourNo }) ||
    `Practice for Tour ${practiceTourNo}`;
}

if (noteEl) {
  let noteText = t(noteKey) || "";

  if (tourState === "upcoming") {
    const upcomingTourNo = Number(s?.upcomingTourNo || s?.currentTourNo || practiceTourNo || 1);
    const upcomingStartDate = formatTourDateText(s?.upcomingTourStartDate, null);

    noteText = upcomingStartDate
      ? (t("home_note_tour_upcoming_on", { n: upcomingTourNo, date: upcomingStartDate }) || noteText)
      : noteText;
  }

  noteEl.textContent = noteText;
}

if (rankEl) {
  rankEl.textContent = total > 0 ? `${done}/${total}` : "—/—";
}

if (percentEl) {
  percentEl.textContent =
    bestPracticePct != null
      ? `${t("practice_best_result") || "Лучший результат"}: ${bestPracticePct}%`
      : "";
}

        if (fillEl) {
      fillEl.style.width = `${practicePct}%`;
    }

    if (btnEl) btnEl.disabled = false;
  } catch {
    // silent
  }
}

   async function computeHomeStudyPracticeStats(subjectKey) {
  const cacheKey = `home_study:${String(subjectKey || "").trim()}`;
  const cached = _homeStatsCache.get(cacheKey);
  if (cached && (Date.now() - cached.ts) < HOME_STATS_CACHE_TTL_MS) {
    return cached.data;
  }

  try {
    const stats = await computePracticeStageStats(subjectKey);

    const out = {
      practicedTourNo: Number(stats?.practiceTourNo || 1),
      masteredCount: Number(stats?.masteredCount || 0),
      totalCount: Number(stats?.totalCount || 0),
      openCount: Number(stats?.openCount || 0)
    };

    _homeStatsCache.set(cacheKey, { ts: Date.now(), data: out });
    return out;
  } catch {
    return {
      practicedTourNo: 1,
      masteredCount: 0,
      totalCount: 0,
      openCount: 0
    };
  }
}

async function updateHomePinnedTile(tileEl, subjectKey) {
  try {
    if (!tileEl) return;

    const countEl = tileEl.querySelector(".js-home-pin-count");
    if (!countEl) return;

    const s = await computeHomeStudyPracticeStats(subjectKey);
    const done = Number(s?.masteredCount || 0);
    const total = Number(s?.totalCount || 0);

    countEl.textContent = total > 0 ? `${done}/${total}` : "—/—";
  } catch {
    // silent
  }
} 
   
      function homeCompetitiveCardEl(userSubject) {
  const subj = subjectByKey(userSubject.key);
  const title = subjectTitle(userSubject.key, subj ? subj.title : userSubject.key);

  const el = document.createElement("div");
  el.className = "home-competitive-card";

  // ✅ нужно для CSS-картинок по предмету
  el.dataset.subject = String(userSubject.key || "").toLowerCase();

  const badgeTxt = t("loading") || "Загрузка…";
  const moduleTxt = t("loading") || "Загрузка…";
  const noteTxt = "";

  el.innerHTML = `
  <div class="home-competitive-badge">${escapeHTML(badgeTxt)}</div>
  <div class="home-competitive-hero">
    <div class="home-competitive-hero-img" aria-hidden="true"></div>
  </div>
  <div class="home-competitive-body">
    <div class="home-competitive-title">${escapeHTML(title)}</div>
    <div class="home-competitive-note js-home-comp-note">${escapeHTML(noteTxt)}</div>

    <div class="home-competitive-meta">
      <span class="home-competitive-module js-home-comp-module">${escapeHTML(moduleTxt)}</span>
      <span class="home-competitive-rank js-home-comp-rank">—/—</span>
    </div>

    <div class="home-competitive-percent js-home-comp-percent"></div>

    <div class="home-progress">
      <div class="home-progress-fill js-home-comp-fill" style="width:0%"></div>
    </div>
  </div>
`;

  const btn = document.createElement("button");
  btn.type = "button";
  btn.className = "btn primary home-competitive-btn";
    btn.textContent = t("open_subject_btn") || "Open subject";
  btn.disabled = true;

  setTimeout(() => {
    try { btn.disabled = false; } catch {}
  }, 3500);

  btn.addEventListener("click", async (e) => {
    e.stopPropagation();

    showAsyncOverlay(tr3(
      "Загружаем предмет…",
      "Fan yuklanmoqda…",
      "Loading subject…"
    ));

    try {
      state.courses.subjectKey = userSubject.key;
      state.courses.entryTab = "home";

      saveState();
      setTab("courses");
      replaceCourses("subject-hub");
      await renderSubjectHub();
    } finally {
      hideAsyncOverlay();
    }
  });
  el.appendChild(btn);
  return el;
}
    function homePinnedTileEl(userSubject, index = 0) {
  const subj = subjectByKey(userSubject.key);
  const title = subjectTitle(userSubject.key, subj ? subj.title : userSubject.key);
    const lessons = "—/—";

  const el = document.createElement("button");
  el.type = "button";
  el.className = "home-pinned-tile";
  el.innerHTML = `
    <div class="home-pinned-ico">📘</div>
    <div class="home-pinned-title">${escapeHTML(title)}</div>
    <div class="home-pinned-meta"><span class="js-home-pin-count">${escapeHTML(lessons)}</span> ${escapeHTML(t("home_practice_progress_label") || "")}</div>
  `;

  el.addEventListener("click", () => {
        state.courses.subjectKey = userSubject.key;

    // ✅ Home is the entry point for this flow
    state.courses.entryTab = "home";

    saveState();
    setTab("courses");
    replaceCourses("subject-hub");
    renderSubjectHub();
});

  return el;
}

  // ---------------------------
  // Courses: All Subjects rendering
  // ---------------------------
  function setImgWithFallback(imgEl, candidates) {
  if (!imgEl) return;
  const list = (candidates || []).filter(Boolean);
  if (!list.length) return;

  let i = 0;
  const next = () => {
    i += 1;
    if (i < list.length) imgEl.src = list[i];
  };

  imgEl.onerror = () => next();
  imgEl.src = list[0];
}

function subjectIconCandidates(subjectKey) {
  const k = String(subjectKey || "").trim();

  // ✅ основной формат (у тебя main уже так загружены)
  const a = [
    `asset/${k}.png.png`,
    `asset/${k}.png`,
    `asset/${k}.PNG`,
  ];

  // ✅ спец-кейс: у тебя файл IELTS.png (с заглавными)
  if (k.toLowerCase() === "ielts") {
    a.push("asset/IELTS.png");
  }

  return a;
}

   function renderAllSubjects() {
  const grid = $("#subjects-grid");
  if (!grid) return;

  const profile = loadProfile();

  // Если нет профиля — каталогу нечего делать (но это не должно случаться)
  grid.innerHTML = "";
  if (!profile) {
    grid.innerHTML = `<div class="empty muted">${escapeHTML(t("need_registration_short"))}</div>`;
    return;
  }

    const userSubjects = filterActiveUserSubjects(profile.subjects || []);
  const competitiveCount = userSubjects.filter(s => s.mode === "competitive").length;

  const visibleSubjects = getVisibleSubjectsCatalog();
  const mainSubjects = visibleSubjects.filter(s => s.type === "main");
const additionalSubjects = visibleSubjects.filter(s => s.type !== "main");

       // ---- Main catalog filter (Competitive / Study) — chips under Courses title
state.courses = state.courses || {};

// миграция: если осталось "all" — считаем "study"
if (!state.courses.mainFilter || state.courses.mainFilter === "all") {
  state.courses.mainFilter = "study"; // competitive | study
  saveState();
}

const filtersWrap = $("#courses-filter-row");
if (filtersWrap) filtersWrap.innerHTML = "";

const renderMainFilterRow = () => {
  if (!filtersWrap) return;

  const row = document.createElement("div");
  row.className = "grid-section-filters";
    row.innerHTML = `
    <button type="button" class="chip ${state.courses.mainFilter === "competitive" ? "is-active" : ""}" data-main-filter="competitive">${escapeHTML(t("courses_filter_competitive") || "Competitive")}</button>
    <button type="button" class="chip ${state.courses.mainFilter === "study" ? "is-active" : ""}" data-main-filter="study">${escapeHTML(t("courses_filter_study") || "Study")}</button>
  `;

  row.querySelectorAll("[data-main-filter]").forEach(btn => {
    const v = btn.getAttribute("data-main-filter");
    btn.addEventListener("pointerup", (e) => {
      e.preventDefault();
      state.courses.mainFilter = v;
      saveState();
      renderAllSubjects();
    });
    btn.addEventListener("click", () => {
      state.courses.mainFilter = v;
      saveState();
      renderAllSubjects();
    });
  });

  filtersWrap.appendChild(row);
};

    const getUserSubjectRow = (key) => {
    return userSubjects.find(x => x.key === key) || null;
  };

  const isCompetitiveKey = (key) => {
    const us = getUserSubjectRow(key);
    return (us?.mode || null) === "competitive";
  };

  const isStudyActiveKey = (key) => {
    const us = getUserSubjectRow(key);
    return (us?.mode || null) === "study";
  };

  const sortByCurrentTabState = (list) => {
    return list.slice().sort((a, b) => {
      const aOn = state.courses.mainFilter === "competitive"
        ? Number(isCompetitiveKey(a.key))
        : Number(isStudyActiveKey(a.key));

      const bOn = state.courses.mainFilter === "competitive"
        ? Number(isCompetitiveKey(b.key))
        : Number(isStudyActiveKey(b.key));

      return bOn - aOn;
    });
  };

const appendSectionTitle = (text) => {
  const el = document.createElement("div");
  el.className = "grid-section-title";
  el.textContent = text;
  grid.appendChild(el);
};

const appendSubjectCard = (s) => {
  const us = userSubjects.find(x => x.key === s.key) || null;
const mode = us?.mode || null;
const isComp = mode === "competitive";
const isStudyPinned = mode === "study" && !!us?.pinned;

const card = document.createElement("div");
card.className = "catalog-card";
   
  // Top clickable area: open hub (but does NOT change profile)
  const head = document.createElement("button");
  head.type = "button";
  head.className = "catalog-head";
  const imgKey = String(s.key || "").trim();
const imgPng2 = `asset/${imgKey}.png.png`;
const imgPng = `asset/${imgKey}.png`;

head.innerHTML = `
  <div class="catalog-row">
    <div class="catalog-left">
      <div class="catalog-ico" aria-hidden="true">
        <img class="catalog-ico-img" alt="" loading="lazy">
      </div>

      <div class="catalog-text">
        <div class="card-title" style="margin:0">${escapeHTML(subjectTitle(s.key, s.title))}</div>
      </div>
    </div>
  </div>
`;
// ✅ icon image with robust fallback (.png.png -> .png -> .PNG + IELTS special)
const imgEl = head.querySelector(".catalog-ico-img");
setImgWithFallback(imgEl, subjectIconCandidates(s.key));

    head.addEventListener("click", () => {
    // "Открыть" — без изменения профиля, как в контракте
    state.courses.subjectKey = s.key;
    saveState();
    pushCourses("subject-hub");
    renderSubjectHub();
  });

  card.appendChild(head); // ✅ вернуть заголовок с названием предмета

      // Footer row:
  // Competitive tab -> toggle subject active/inactive in competitive
  // Study tab       -> toggle subject active/inactive in study
  const footer = document.createElement("div");
const isCompetitiveTab = state.courses.mainFilter === "competitive";
const isActiveInCurrentTab = isCompetitiveTab ? isComp : isStudyPinned;

  footer.className = "catalog-toggle-row" + (isActiveInCurrentTab ? " is-on" : "");

  const left = document.createElement("div");
  left.className = "catalog-toggle-left";

  const stateLine = document.createElement("div");
stateLine.className = "catalog-toggle-state";
stateLine.textContent = isCompetitiveTab
  ? (
      isActiveInCurrentTab
        ? (t("course_toggle_on") || "Включено")
        : (t("course_toggle_off") || "Выключено")
    )
  : (
      isActiveInCurrentTab
        ? (t("settings_pinned") || "Закреплено")
        : (t("settings_not_pinned") || "Не закреплено")
    );
   
  left.appendChild(stateLine);

  const sw = document.createElement("label");
  sw.className = "switch";

  sw.innerHTML = `
    <input
      type="checkbox"
      ${isActiveInCurrentTab ? "checked" : ""}
      aria-label="${escapeHTML(
        isCompetitiveTab
          ? (t("courses_filter_competitive") || "Competitive")
          : (t("courses_filter_study") || "Study")
      )}"
    >
    <span class="slider"></span>
  `;

  const input = sw.querySelector("input");

  input.addEventListener("click", (e) => e.stopPropagation());

  input.addEventListener("change", async (e) => {
    e.stopPropagation();

    const wantsOn = !!input.checked;
    const fresh = loadProfile() || profile;

    if (isCompetitiveTab) {
      if (wantsOn) {
        const compNow = (fresh.subjects || []).filter(x => (x.mode || "study") === "competitive").length;

        if (compNow >= 2) {
          input.checked = false;
          await uiAlert({
            title: t("comp_limit_title") || "Лимит Competitive",
            message:
              t("comp_limit_text") ||
              "Можно выбрать максимум 2 основных предмета в Competitive.",
            okText: t("comp_limit_ok") || t("ok") || "OK"
          });
          return;
        }

        const ok = await uiConfirm({
          title: t("courses_activate_comp_title") || "Включить в Competitive?",
          message:
            t("courses_activate_comp_text") ||
            "Предмет будет активирован в соревновательном режиме.",
          okText: t("courses_activate_comp_ok") || "Включить",
          cancelText: t("cancel") || "Отмена"
        });

        if (!ok) {
          input.checked = false;
          return;
        }

        const updated = upsertUserSubjectMode(fresh, s.key, "competitive");
        saveProfile(updated);

        try {
          const res = await syncUserSubjectToSupabase(s.key, "competitive", false);
          if (!res?.ok) {
            input.checked = false;
            showToast(t("save_failed_db_try_again"));
            renderAllSubjects();
            return;
          }

          try {
            const uid = await getAuthUid();
            const subjectId = res?.subjectId || await getSubjectIdByKey(s.key);
            if (uid && subjectId) {
              await writeUserSubjectsHistory({
                user_id: uid,
                subject_id: subjectId,
                action: "attach_competitive",
                from_mode: mode || null,
                to_mode: "competitive",
                source: "courses",
                meta: { subject_key: s.key }
              });
            }
          } catch {}

          showToast(t("toast_subject_activated_competitive") || "Предмет включён в соревновательный режим.");
        } catch {
          input.checked = false;
          showToast(t("network_error_try_again") || "Ошибка сети. Попробуйте ещё раз.");
          renderAllSubjects();
          return;
        }
      } else {
        const ok = await uiConfirm({
          title: t("courses_deactivate_comp_title") || "Выключить предмет?",
          message:
            t("courses_deactivate_comp_text") ||
            "Предмет будет выключен в соревновательном режиме. Прогресс Competitive по предмету будет сброшен.",
          okText: t("courses_deactivate_comp_ok") || "Выключить",
          cancelText: t("cancel") || "Отмена"
        });

        if (!ok) {
          input.checked = true;
          return;
        }

        const updated = removeUserSubject(fresh, s.key);
        saveProfile(updated);

        try {
          const res = await deleteUserSubjectFromSupabase(s.key);
          if (!res?.ok) {
            input.checked = true;
            showToast(t("save_failed_db_try_again"));
            renderAllSubjects();
            return;
          }

          try {
            const subjectId = res?.subjectId || await getSubjectIdByKey(s.key);

            if (window.sb && subjectId) {
              const { error } = await window.sb.rpc("reset_subject_progress", { p_subject_id: subjectId });

              if (error) {
                try {
                  const uid2 = await getAuthUid();
                  await logDbErrorToEvents(uid2, "reset_subject_progress", error, {
                    subject_id: subjectId,
                    subject_key: s.key
                  });
                } catch {}
              }
            }
          } catch {}

          showToast(t("toast_subject_deactivated") || "Предмет выключен.");
        } catch {
          input.checked = true;
          showToast(t("network_error_try_again") || "Ошибка сети. Попробуйте ещё раз.");
          renderAllSubjects();
          return;
        }
      }
    } else {
  if (wantsOn) {
    const ok = await uiConfirm({
      title: t("courses_activate_study_title") || "Закрепить предмет?",
      message:
        t("courses_activate_study_text") ||
        "Предмет будет закреплён на главном экране в учебном режиме.",
      okText: t("courses_activate_study_ok") || "Закрепить",
      cancelText: t("cancel") || "Отмена"
    });

    if (!ok) {
      input.checked = false;
      return;
    }

    const updated = upsertUserSubjectMode(fresh, s.key, "study");

    if (Array.isArray(updated?.subjects)) {
      const idx = updated.subjects.findIndex(x => x.key === s.key);
      if (idx >= 0) {
        updated.subjects[idx].pinned = true;
      }
    }

    saveProfile(updated);

    try {
      const res = await syncUserSubjectToSupabase(s.key, "study", true);
      if (!res?.ok) {
        input.checked = false;
        showToast(t("save_failed_db_try_again"));
        renderAllSubjects();
        return;
      }

      showToast(t("toast_added_pinned") || "Предмет закреплён.");
    } catch {
      input.checked = false;
      showToast(t("network_error_try_again") || "Ошибка сети. Попробуйте ещё раз.");
      renderAllSubjects();
      return;
    }
  } else {
    const ok = await uiConfirm({
      title: t("courses_deactivate_study_title") || "Убрать предмет?",
      message:
        t("courses_deactivate_study_text") ||
        "Предмет будет убран из закреплённых на главном экране.",
      okText: t("courses_deactivate_study_ok") || "Убрать",
      cancelText: t("cancel") || "Отмена"
    });

    if (!ok) {
      input.checked = true;
      return;
    }

    const updated = removeUserSubject(fresh, s.key);
    saveProfile(updated);

    try {
      const res = await deleteUserSubjectFromSupabase(s.key);
      if (!res?.ok) {
        input.checked = true;
        showToast(t("save_failed_db_try_again"));
        renderAllSubjects();
        return;
      }

      showToast(t("toast_removed_pinned") || "Предмет убран.");
    } catch {
      input.checked = true;
      showToast(t("network_error_try_again") || "Ошибка сети. Попробуйте ещё раз.");
      renderAllSubjects();
      return;
    }
  }
}
     
    renderHome();
    renderAllSubjects();
    renderProfileSettings?.();
  });

  footer.appendChild(left);
  footer.appendChild(sw);
  card.appendChild(footer);
  grid.appendChild(card);
};

  // ---- MAIN section + filter row + pinned-first + filter mode
  // ✅ chips render once under "Courses"
renderMainFilterRow();

if (mainSubjects.length) {
  appendSectionTitle(t("courses_section_main") || "Main (Cambridge)");

  let mainOut = mainSubjects.slice();

  if (state.courses.mainFilter === "competitive") {
    // если competitive < 2 — показываем все main
    // если competitive = 2 — показываем только эти 2
    if (competitiveCount >= 2) {
      mainOut = mainOut.filter(s => isCompetitiveKey(s.key));
    }
  } else if (state.courses.mainFilter === "study") {
    // в study показываем только те main, которые не находятся в competitive
    mainOut = mainOut.filter(s => !isCompetitiveKey(s.key));
  }

  mainOut = sortByCurrentTabState(mainOut);
  mainOut.forEach(appendSubjectCard);
}


    // ---- ADDITIONAL section (always Study by spec), pinned-first
  // ✅ при Competitive additional не показываем
      if (state.courses.mainFilter !== "competitive" && additionalSubjects.length) {
     appendSectionTitle(t("courses_section_additional") || "Additional");
     const addOut = sortByCurrentTabState(additionalSubjects);
     addOut.forEach(appendSubjectCard);
   }
}

        function openSubjectHub(subjectKey) {
    if (!isSubjectActive(subjectKey)) {
      showToast(t("not_available"));
      setTab("courses");
      replaceCourses("all-subjects");
      renderAllSubjects();
      return;
    }

    state.courses.subjectKey = subjectKey;
    saveState();

    try {
      const subj = subjectByKey(subjectKey);
      const profile = loadProfile();
      const us = profile?.subjects?.find(x => x.key === subjectKey) || null;

      trackEvent("subject_hub_opened", {
        subject_key: String(subjectKey || ""),
        subject_title: String(subj?.title || ""),
        mode: String(us?.mode || ""),
        pinned: !!us?.pinned
      });
    } catch {}

    pushCourses("subject-hub");
    renderSubjectHub();
  }
         
// ---------------------------
// Subject Hub mentor
// ---------------------------
const TEAM_CACHE_VERSION = 11;

function mentorPhotoUrlFromPath(photoPath) {
  const p = String(photoPath || "").trim();
  if (!p || !window.sb?.storage) return null;
  try {
    const res = window.sb.storage.from("team-photos").getPublicUrl(p);
    return res?.data?.publicUrl || null;
  } catch {
    return null;
  }
}

function mentorRoleForSubject(subjectKey) {
  const key = String(subjectKey || "").trim().toLowerCase();
  const map = {
    chemistry: "AS level Chemistry",
    biology: "AS level Biology",
    informatics: "IGCSE Computer Science",
    economics: "AS level Economics",
    mathematics: "AS level Mathematics"
  };
  return map[key] || null;
}

function mentorRoleToSubjectKey(role) {
  const r = String(role || "").trim().toLowerCase();

  const map = {
    "as level chemistry": "chemistry",
    "as level biology": "biology",
    "igcse computer science": "informatics",
    "as level economics": "economics",
    "as level mathematics": "mathematics",

    "ielts mentor": "ielts",
    "sat english": "sat",
    "sat math": "sat",
    "english a2 mentor": "english_a2",
    "english b1 mentor": "english_b1",
    "ingliz tili mentori": "english_a1"
  };

  return map[r] || null;
}

function isMentorVisibleBySubjectActivity(person) {
  const subjectKey = mentorRoleToSubjectKey(person?.role);
  if (!subjectKey) return true;
  return isSubjectActive(subjectKey);
}

async function fetchSubjectMentor(subjectKey) {
  if (!isSubjectActive(subjectKey)) return null;

  const role = mentorRoleForSubject(subjectKey);
  if (!role) return null;

    // cache first
  state.courses = state.courses || {};
  state.courses.subjectMentorCache = state.courses.subjectMentorCache || {};

  if (Number(state.courses.subjectMentorCacheVersion || 0) !== TEAM_CACHE_VERSION) {
    state.courses.subjectMentorCache = {};
    state.courses.subjectMentorCacheVersion = TEAM_CACHE_VERSION;
    saveState();
  }

    const cachedMentor = state.courses.subjectMentorCache[subjectKey];
  if (!isSubjectActive(subjectKey)) {
    delete state.courses.subjectMentorCache[subjectKey];
    saveState();
    return null;
  }
  if (cachedMentor && String(cachedMentor?.photoUrl || "").trim()) {
    return cachedMentor;
  }

  // DB first
  try {
    if (window.sb) {
      const { data, error } = await window.sb
        .from("team_people")
        .select("name,role,meta,photo_path,is_vacant,is_active")
        .eq("group_key", "mentors")
        .eq("role", role)
        .eq("is_active", true)
        .limit(1);

      if (!error && Array.isArray(data) && data[0] && !data[0].is_vacant) {
        const row = data[0];
        const mentor = {
          name: String(row.name || ""),
          role: String(row.role || ""),
          meta: String(row.meta || ""),
          photoUrl: mentorPhotoUrlFromPath(row.photo_path)
        };
        state.courses.subjectMentorCache[subjectKey] = mentor;
        saveState();
        return mentor;
      }
    }
  } catch {}

  // local fallback
  const local = (Array.isArray(mentors) ? mentors : []).find(x => String(x.role || "") === role);
  if (!local) return null;

  const mentor = {
  ...local,
  memberKey: String(local?.memberKey || memberKeyOf(local) || ""),
  name: local.name_i18n ? pickLangValue(local.name_i18n) : String(local.name || ""),
  role: local.role_i18n ? pickLangValue(local.role_i18n) : String(local.role || ""),
  meta: local.meta_i18n ? pickLangValue(local.meta_i18n) : String(local.meta || ""),
  photoUrl: null
};
  state.courses.subjectMentorCache[subjectKey] = mentor;
  saveState();
  return mentor;
}

function memberKeyOf(x) {
  const a = String(x?.name || "").trim().toLowerCase();
  const b = String(x?.role || "").trim().toLowerCase();
  return `${a}__${b}`;
}

async function renderSubjectHubMentorCard(subjectKey) {
  const requestedKey = String(subjectKey || "").trim();

  const btnEl = $("#subject-hub-mentor-btn");
  const avatarEl = $("#subject-hub-mentor-avatar");
  const titleEl = $("#subject-hub-mentor-title");
  const subEl = $("#subject-hub-mentor-sub");
  if (!btnEl || !avatarEl || !titleEl || !subEl) return;

  // default
  btnEl.disabled = true;
  avatarEl.classList.remove("has-photo");
  avatarEl.style.backgroundImage = "";
  titleEl.textContent = t("mentor_assigning") || "Ментор назначается";
  subEl.textContent = t("mentor_profile_soon") || "Скоро появится профиль";

  if (!isSubjectActive(requestedKey)) {
    return;
  }

  const mentor = await fetchSubjectMentor(requestedKey).catch(() => null);

  // subject changed while waiting
  if (requestedKey !== String(state?.courses?.subjectKey || "").trim()) return;
  if (!mentor) return;

  state.courses.subjectHubMentor = mentor;
  saveState();

  btnEl.disabled = false;
  titleEl.textContent = mentor.name || (t("mentor_assigning") || "Ментор назначается");
  subEl.textContent = mentor.role || (t("mentor_profile_soon") || "Скоро появится профиль");

  if (mentor.photoUrl) {
    avatarEl.classList.add("has-photo");
    avatarEl.style.backgroundImage = `url("${mentor.photoUrl}")`;
  }
}

// ---------------------------
  // Subject Hub rendering
  // ---------------------------
    async function renderSubjectHub() {
  const profile = loadProfile();
  const subj = subjectByKey(state.courses.subjectKey);

  const titleEl = $("#subject-hub-title");
  const metaEl = $("#subject-hub-meta");

  const subjectKey = state.courses.subjectKey;

  if (!isSubjectActive(subjectKey)) {
    showToast(t("not_available") || "Недоступно");
    replaceCourses("all-subjects");
    renderAllSubjects();
    return;
  }
  const us = profile?.subjects?.find(x => x.key === subjectKey) || null;

    if (titleEl) titleEl.textContent = subjectTitle(subjectKey, subj ? subj.title : "Subject");
  if (metaEl) {
  if (us) {
    const modeLabel = us.mode === "competitive" ? t("mode_competitive") : t("mode_study");
    metaEl.textContent = modeLabel;
  } else {
    metaEl.textContent = t("hub_not_added") || "Not added";
  }
}

  // ✅ Visual-only mode flag for CSS (Study vs Competitive)
  const hubRoot = $("#courses-subject-hub");
  if (hubRoot) {
    hubRoot.classList.toggle("is-study", us?.mode === "study");
    hubRoot.classList.toggle("is-competitive", us?.mode === "competitive");
  }
         // ---- Availability toggles in Subject Hub (Tours only when allowed) ----
    const toursBtn = document.querySelector('#courses-subject-hub [data-action="open-tours"]');
    const toursSub = toursBtn?.querySelector(".muted.small");

    if (toursBtn) {
      const eligibility = canOpenActiveTours(profile, state.courses.subjectKey);

            // Additional subjects: tours do not exist by spec
      if (isAdditionalSubjectKey(state.courses.subjectKey)) {
        toursBtn.disabled = false;
        toursBtn.classList.add("is-disabled");
        if (toursSub) toursSub.textContent = getToursDeniedText("not_main");
      } else if (!eligibility.ok) {
        toursBtn.disabled = false;
        toursBtn.classList.add("is-disabled");
        if (toursSub) toursSub.textContent = getToursDeniedText(eligibility.reason);
      } else {
        toursBtn.disabled = false;
        toursBtn.classList.remove("is-disabled");
        if (toursSub) toursSub.textContent = t("tours_active_and_completed") || "Активные и прошедшие";
      }
    }

        updateTopbarForView("courses");

        // ✅ Subject mentor card
    await renderSubjectHubMentorCard(subjectKey).catch(() => null);
  }
  // ---------------------------
  // Lessons (demo)
  // ---------------------------
  async function renderLessons() {
    const list = $("#lessons-list");
    const subj = subjectByKey(state.courses.subjectKey);
    if (!list) return;

    list.innerHTML = `<div class="empty muted">${escapeHTML(t("loading") || "Загрузка...")}</div>`;

    if (!window.sb) {
      list.innerHTML = `<div class="empty muted">${escapeHTML(t("lessons_no_db") || "База не подключена. Уроки недоступны.")}</div>`;
      return;
    }

    const subjectKey = state.courses.subjectKey;
    const subjectId = await getSubjectIdByKey(subjectKey);

    if (!subjectId) {
      list.innerHTML = `<div class="empty muted">${escapeHTML(t("lessons_empty") || "Уроки пока не добавлены.")}</div>`;
      return;
    }

    const { data, error } = await window.sb
      .from("lessons")
      .select("id,title,topic,order_no")
      .eq("subject_id", subjectId)
      .order("order_no", { ascending: true });

    if (error) {
      logClientError("lessons_select_error", error);
      list.innerHTML = `<div class="empty muted">${escapeHTML(t("lessons_load_error") || "Ошибка загрузки уроков.")}</div>`;
      return;
    }

    const lessons = Array.isArray(data) ? data : [];
    if (!lessons.length) {
      list.innerHTML = `<div class="empty muted">${escapeHTML(t("lessons_empty") || "Уроки пока не добавлены.")}</div>`;
      return;
    }

    list.innerHTML = "";

    lessons.forEach((lesson) => {
      const item = document.createElement("div");
      item.className = "list-item";

            const title = getLessonDisplayTitle(lesson);
      const topic = String(lesson?.topic || "").trim();

      item.innerHTML = `
        <div style="font-weight:800">${escapeHTML(title)}</div>
        <div class="muted small">${escapeHTML(subjectTitle(subjectKey, subj ? subj.title : ""))}${topic ? ` • ${escapeHTML(topic)}` : ""}</div>
      `;

            item.addEventListener("click", async () => {
  state.courses.lessonId = lesson.id;
  saveState();
  pushCourses("video");
  await renderVideo();
});

      list.appendChild(item);
    });
  }

    async function renderVideo() {
  const subjectKey = String(state?.courses?.subjectKey || "").trim().toLowerCase();
  const subj = subjectByKey(subjectKey);

  const tEl = $("#video-title");
  const mEl = $("#video-meta");
  const subjectEl = document.getElementById("video-hub-subject");

  const wrapEl = document.getElementById("video-player-wrap");
  const iframe = document.getElementById("video-player");
  const emptyEl = document.getElementById("video-empty");
  const externalBox = document.getElementById("video-external-box");
  const externalBtn = document.getElementById("video-open-external");
  const externalHint = document.getElementById("video-external-hint");

  try {
    if (ytPlayer && typeof ytPlayer.stopVideo === "function") ytPlayer.stopVideo();
    if (iframe) iframe.removeAttribute("src");
  } catch {}

  if (wrapEl) wrapEl.style.display = "none";
  if (emptyEl) emptyEl.style.display = "none";
  if (externalBox) externalBox.style.display = "block";

  if (tEl) tEl.textContent = t("hub_video_lessons_title") || "Видео-уроки";
if (mEl) mEl.textContent = t("video_hub_subtitle") || "Уроки по предмету доступны в Telegram";
if (subjectEl) subjectEl.textContent = subjectTitle(subjectKey, subj ? subj.title : "");

  const url = getSubjectTelegramLessonUrl(subjectKey);

  // ✅ привязываем subject-level экран к первому lesson_id предмета,
  // чтобы skip/complete и video_events не ломались
  const primaryLessonId = await getSubjectPrimaryLessonId(subjectKey);
  state.courses = state.courses || {};
  state.courses.lessonId = primaryLessonId || null;
  saveState();

  if (!url) {
    if (emptyEl) {
      emptyEl.style.display = "block";
      emptyEl.textContent = t("video_empty") || "Видео недоступно.";
    }
    if (externalBox) externalBox.style.display = "none";
    updateTopbarForView("courses");
    return;
  }

  try {
    trackEvent("video_opened", {
      subject_id: subjectKey,
      lesson_id: primaryLessonId ? String(primaryLessonId) : "",
      provider: "telegram_subject_group"
    });

    if (primaryLessonId) {
      insertVideoEventToSupabase("opened", primaryLessonId, 0);
    }
  } catch {}

  if (externalHint) {
    externalHint.textContent =
      t("video_uz_language_note") ||
      "Пока все видео-уроки доступны на узбекском языке.";
  }

  if (externalBtn) {
    externalBtn.onclick = () => {
      try {
        trackEvent("video_started", {
          subject_id: subjectKey,
          lesson_id: primaryLessonId ? String(primaryLessonId) : "",
          provider: "telegram_subject_group"
        });

        if (primaryLessonId) {
          insertVideoEventToSupabase("started", primaryLessonId, 0);
        }
      } catch {}

      openTelegramUrl(url);
    };
  }

  updateTopbarForView("courses");
}

    // ---------------------------
  // Practice v1 — per spec:
  // 10 questions (3/5/2), MCQ + INPUT, per-question timer, pause/resume,
  // best + last 5 attempts, review + recommendations
  // ---------------------------

    function loadPracticeDraft() {
    return safeJsonParse(localStorage.getItem(LS.practiceDraft), null);
  }

  function stripPracticeQuestionSecrets(q) {
    if (!q || typeof q !== "object") return q;

    const clean = { ...q };
    delete clean.correctIndex;
    delete clean.correctAnswer;
    delete clean.explanation;
    delete clean.inputKind;
    delete clean.inputHint;

    return clean;
  }

    function stripPracticeQuizSecrets(quiz) {
    if (!quiz || typeof quiz !== "object") return quiz;

    const clean = {
      ...quiz,
      qTimerId: null,
      qEndsAtMono: null
    };

    // paused draft should not carry correctness cache
    if (Array.isArray(clean.correct)) {
      clean.correct = Array.from({ length: clean.correct.length }).map(() => false);
    }

    if (Array.isArray(clean.questions)) {
      clean.questions = clean.questions.map(stripPracticeQuestionSecrets);
    }

    return clean;
  }

      function stripTourQuestionSecrets(q) {
  if (!q || typeof q !== "object") return q;

  const clean = { ...q };

  delete clean.correctIndex;
  delete clean.correct_index;
  delete clean.correctAnswer;
  delete clean.correct_answer;
  delete clean.correct;
  delete clean.answer;

  delete clean.explanation;
  delete clean.explanation_ru;
  delete clean.explanation_uz;
  delete clean.explanation_en;

  return clean;
}

  function stripActiveTourContextSecrets(ctx) {
    if (!ctx || typeof ctx !== "object") return ctx;
    if (ctx.isArchive) return ctx;

    const clean = { ...ctx };

    if (Array.isArray(clean.questions)) {
      clean.questions = clean.questions.map(stripTourQuestionSecrets);
    }

    return clean;
  }

  function stripAnsweredTourQuestionInRuntime(ctx, questionIndex) {
    if (!ctx || ctx.isArchive) return;
    if (!Array.isArray(ctx.questions)) return;

    const idx = Number(questionIndex);
    if (!Number.isFinite(idx) || idx < 0 || idx >= ctx.questions.length) return;

    const q = ctx.questions[idx];
    if (!q) return;

    ctx.questions[idx] = stripTourQuestionSecrets(q);
  }

  function buildPracticeSavePayload(attempt, quiz) {
  return {
    attempt,
    quiz: {
      subjectKey: quiz?.subjectKey || null,
      practiceTourNo: Number(quiz?.practiceTourNo || 1),
      practicePoolId: Number(quiz?.practicePoolId || 0) || null,
      answers: Array.isArray(quiz?.answers) ? quiz.answers.slice() : []
    }
  };
}

  async function restorePracticeQuizSecrets(quiz) {
  try {
    if (!quiz || quiz.mode !== "practice") return null;
    if (!Array.isArray(quiz.questions) || !quiz.questions.length) return null;

    const alreadyReady = quiz.questions.every(q =>
      q && (
        Object.prototype.hasOwnProperty.call(q, "correctAnswer") ||
        Object.prototype.hasOwnProperty.call(q, "correctIndex")
      )
    );
    if (alreadyReady) return { ...quiz };

    const sbClient = sb || null;
    if (!sbClient) return null;

    const ids = quiz.questions
      .map(q => Number(q?.id))
      .filter(id => Number.isFinite(id) && id > 0);

    if (!ids.length) return null;

    const subjectId = await getSubjectIdByKey(quiz.subjectKey);
    if (!subjectId) return null;

    const { data, error } = await sbClient
      .from("questions")
      .select("id,subject_id,topic,difficulty,qtype,question_text,options_text,correct_answer,explanation,image_url,question_text_ru,question_text_uz,question_text_en,options_text_ru,options_text_uz,options_text_en,explanation_ru,explanation_uz,explanation_en")
      .eq("subject_id", subjectId)
      .in("id", ids)
      .limit(100);

    if (error) return null;

    const rows = Array.isArray(data) ? data : [];
    const byId = new Map(rows.map(r => [Number(r.id), r]));
    const contentLang = (loadProfile()?.language) || "ru";

    const pickL = (obj, base) => {
      const k =
        contentLang === "uz" ? (base + "_uz")
        : contentLang === "en" ? (base + "_en")
        : (base + "_ru");

      return (obj && obj[k] != null && String(obj[k]).trim() !== "") ? obj[k] : obj[base];
    };

    const restoredQuestions = quiz.questions.map(oldQ => {
      const row = byId.get(Number(oldQ?.id));
      if (!row) return oldQ;

      const type = String(row.qtype || oldQ?.type || "mcq").toLowerCase() === "input" ? "input" : "mcq";
      const optionsRaw = pickL(row, "options_text");
      const opts = type === "mcq" ? (parseOptionsText(optionsRaw) || []) : [];

      let correctIndex = 0;
      const correctAnswer = String(row.correct_answer ?? "");

      if (type === "mcq") {
        const ca = String(row.correct_answer ?? "").trim();

        if (isNumericLike(ca)) {
          correctIndex = Math.max(0, Math.min(opts.length - 1, Number(String(ca).replace(",", "."))));
        } else if (/^[A-D]$/i.test(ca)) {
          correctIndex = ca.toUpperCase().charCodeAt(0) - "A".charCodeAt(0);
        } else if (opts.length) {
          const idx = opts.findIndex(o => String(o).trim().toLowerCase() === ca.toLowerCase());
          if (idx >= 0) correctIndex = idx;
        }
      }

      return {
        ...oldQ,
        type,
        correctIndex,
        correctAnswer,
        explanation: pickL(row, "explanation") || "",
        inputKind: type === "input" ? (isNumericLike(correctAnswer) ? "numeric" : "text") : null,
        inputHint: type === "input" ? inputHintForAnswer(correctAnswer) : ""
      };
    });

    return {
      ...quiz,
      questions: restoredQuestions
    };
  } catch {
    return null;
  }
}

  function savePracticeDraft(draft) {
    const safeDraft = draft && typeof draft === "object"
      ? {
          ...draft,
          quiz: stripPracticeQuizSecrets(draft.quiz)
        }
      : draft;

    localStorage.setItem(LS.practiceDraft, JSON.stringify(safeDraft));
  }

  function clearPracticeDraft() {
    localStorage.removeItem(LS.practiceDraft);
  }

   function loadMyRecs() {
  return safeJsonParse(localStorage.getItem(LS.myRecs), { bySubject: {} });
}

function saveMyRecs(data) {
  localStorage.setItem(LS.myRecs, JSON.stringify(data));
}

   function loadMyTourRecs() {
  return safeJsonParse(localStorage.getItem(LS.myTourRecs), { bySubject: {} });
}

function saveMyTourRecs(data) {
  localStorage.setItem(LS.myTourRecs, JSON.stringify(data));
}

   async function saveTourRecsToDB(subjectKey, tourNo, recs, seasonIdArg = null) {
  try {
    if (!window.sb) return false;

    const uid = await getAuthUid();
    if (!uid) return false;

    const subjectId = await getSubjectIdByKey(subjectKey);
    if (!subjectId) return false;

    const seasonId = await resolveTourSeasonId({
      seasonId: seasonIdArg,
      tourId: state?.tourContext?.tourId || state?.courses?.activeTourId || null,
      subjectId,
      subjectKey,
      tourNo
    });

    const normalized = (Array.isArray(recs) ? recs : [])
      .map(r => {
        const bookIdRaw = r?.book_id ?? r?.bookId ?? null;
        const bookId = Number(bookIdRaw || 0) > 0 ? Number(bookIdRaw) : null;
        const bookReference = String(
          r?.book_reference ||
          r?.bookReference ||
          r?.book_ref ||
          r?.bookRef ||
          ""
        ).trim() || null;

        return {
          season_id: seasonId || null,
          source_type: "tour",
          topic: String(r?.topic || "").trim(),
          subtopic: r?.subtopic ? String(r.subtopic).trim() : null,
          tour_no: Number(tourNo || r?.tourNo || r?.tour_no || 0) || null,
          book_id: bookId,
          book_reference: bookReference
        };
      })
      .filter(r => r.topic && r.tour_no);

    if (!normalized.length) return false;

    const key = (r) => tourRecommendationKeyV1(
      r.season_id || seasonId || 0,
      r.tour_no,
      r.topic,
      r.subtopic
    );

    const uniqMap = new Map();
    normalized.forEach(r => {
      const k = key(r);
      const prev = uniqMap.get(k);

      if (!prev || (!prev.book_reference && r.book_reference) || (!prev.book_id && r.book_id)) {
        uniqMap.set(k, { ...prev, ...r });
      }
    });

    const items = Array.from(uniqMap.values());
    const topics = Array.from(new Set(items.map(r => r.topic).filter(Boolean)));

    let query = window.sb
      .from("recommendations")
      .select("id, season_id, topic, subtopic, tour_no, book_id, book_reference")
      .eq("user_id", uid)
      .eq("subject_id", subjectId)
      .eq("source_type", "tour")
      .eq("tour_no", Number(tourNo));

    if (seasonId) query = query.eq("season_id", seasonId);
    else query = query.is("season_id", null);

    const { data: existing, error: selErr } = await query;

    if (selErr) {
      logClientError("tour_recs_existing_select_error", selErr);
      return false;
    }

    let mapRows = [];
    try {
      const { data: mData, error: mErr } = await window.sb
        .from("topic_book_map")
        .select("topic, subtopic, book_id, book_reference, priority, is_active")
        .eq("subject_id", subjectId)
        .eq("is_active", true)
        .in("topic", topics)
        .order("priority", { ascending: true });

      if (!mErr && Array.isArray(mData)) mapRows = mData;
    } catch {}

    const norm = (v) => String(v || "").trim();
    const normSub = (v) => {
      const st = norm(v);
      return st ? st : null;
    };

    const bestFor = (item) => {
      const topic = norm(item.topic);
      const subtopic = normSub(item.subtopic);
      const directRef = norm(item.book_reference) || null;

      const exactByDirectRef = directRef
        ? mapRows.find(x =>
            norm(x.book_reference) === directRef &&
            norm(x.topic) === topic &&
            normSub(x.subtopic) === subtopic
          )
        : null;

      const exact = mapRows.find(x =>
        norm(x.topic) === topic &&
        normSub(x.subtopic) === subtopic
      );

      const byTopic = mapRows.find(x =>
        norm(x.topic) === topic &&
        normSub(x.subtopic) === null
      );

      const anyByDirectRef = directRef
        ? mapRows.find(x => norm(x.book_reference) === directRef)
        : null;

      const picked = exactByDirectRef || exact || byTopic || anyByDirectRef || null;

      return {
        book_id: item.book_id || picked?.book_id || null,
        book_reference: directRef || picked?.book_reference || null
      };
    };

    const existingByKey = new Map(
      (Array.isArray(existing) ? existing : []).map(x => [key(x), x])
    );

    for (const item of items) {
      const row = existingByKey.get(key(item));
      if (!row?.id) continue;

      const best = bestFor(item);
      const patch = {};

      if (!row.book_reference && best.book_reference) patch.book_reference = best.book_reference;
      if (!row.book_id && best.book_id) patch.book_id = best.book_id;
      if (!row.season_id && seasonId) patch.season_id = seasonId;

      if (Object.keys(patch).length) {
        const { error: updErr } = await window.sb
          .from("recommendations")
          .update(patch)
          .eq("id", row.id);

        if (updErr) logClientError("tour_recs_update_refs_error", updErr);
      }
    }

    const toInsert = items
      .filter(r => !existingByKey.has(key(r)))
      .map(r => {
        const best = bestFor(r);
        return {
          user_id: uid,
          subject_id: subjectId,
          season_id: seasonId || null,
          source_type: "tour",
          tour_no: r.tour_no,
          topic: r.topic,
          subtopic: r.subtopic,
          book_id: best.book_id || null,
          book_reference: best.book_reference || null
        };
      });

    if (!toInsert.length) return true;

    const { error: insErr } = await window.sb
      .from("recommendations")
      .insert(toInsert);

    if (insErr) {
      logClientError("tour_recs_insert_error", insErr);
      return false;
    }

    return true;
  } catch (e) {
    logClientError("tour_recs_insert_exception", e);
    return false;
  }
}

   
function addMyTourRecsFromTourAttempt(ctx) {
  try {
    const subjectKey = String(ctx?.subjectKey || "").trim();
    const tourNo = Number(ctx?.tourNo || 0);
    const seasonId = Number(ctx?.seasonId || ctx?.season_id || state?.tourContext?.seasonId || 0) || 0;

    if (!subjectKey || !tourNo) return { added: 0, recs: [] };

    const wrong = (Array.isArray(ctx?.answers) ? ctx.answers : [])
      .filter(a => a && a.isCorrect === false)
      .map(a => {
        const q = ctx?.questions?.[Number(a.index)] || null;
        return {
          topic: String(q?.topic || "General").trim(),
          subtopic: q?.subtopic ? String(q.subtopic).trim() : null,
          book_id: q?.book_id || q?.bookId || null,
          book_reference: String(q?.book_reference || q?.bookReference || q?.book_ref || q?.bookRef || "").trim() || null
        };
      })
      .filter(x => x.topic);

    if (!wrong.length) return { added: 0, recs: [] };

    const uniqMap = new Map();
    wrong.forEach(r => {
      const k = tourRecommendationKeyV1(seasonId, tourNo, r.topic, r.subtopic);
      const prev = uniqMap.get(k);

      if (!prev || (!prev.book_reference && r.book_reference) || (!prev.book_id && r.book_id)) {
        uniqMap.set(k, { ...prev, ...r });
      }
    });

    const uniq = Array.from(uniqMap.values());
    const store = loadMyTourRecs();
    store.bySubject = store.bySubject || {};

    const existing = new Set(
      (store.bySubject[subjectKey] || []).map(x =>
        tourRecommendationKeyV1(
          x?.seasonId || x?.season_id || 0,
          x?.tourNo || 0,
          x?.topic || "",
          x?.subtopic || ""
        )
      )
    );

    const nowTs = Date.now();

    const added = uniq
      .filter(r => !existing.has(tourRecommendationKeyV1(seasonId, tourNo, r.topic, r.subtopic)))
      .map(r => ({
        source_type: "tour",
        seasonId: seasonId || null,
        topic: r.topic,
        subtopic: r.subtopic,
        tourNo,
        book_id: r.book_id || null,
        book_reference: r.book_reference || null,
        ts: nowTs
      }));

    if (!added.length) return { added: 0, recs: [] };

    store.bySubject[subjectKey] = [
      ...added,
      ...(store.bySubject[subjectKey] || [])
    ].slice(0, 100);

    saveMyTourRecs(store);

    saveTourRecsToDB(subjectKey, tourNo, added, seasonId || null).catch(() => {});

    return { added: added.length, recs: added };
  } catch {
    return { added: 0, recs: [] };
  }
}

   
// ✅ DB sync for recommendations table
async function syncMyRecsToSupabase(subjectKey, recs) {
  try {
    if (!window.sb) return;

    const uid = await getAuthUid();
    if (!uid) return;

    const subjectId = await getSubjectIdByKey(subjectKey);
    if (!subjectId) return;

    const normalized = (Array.isArray(recs) ? recs : [])
      .map(r => {
        if (typeof r === "string") {
          return {
            topic: String(r).trim(),
            subtopic: null,
            book_id: null,
            book_reference: null
          };
        }

        const bookIdRaw = r?.book_id ?? r?.bookId ?? null;
        const bookId = Number(bookIdRaw || 0) > 0 ? Number(bookIdRaw) : null;
        const bookReference = String(
          r?.book_reference ||
          r?.bookReference ||
          r?.book_ref ||
          r?.bookRef ||
          ""
        ).trim() || null;

        return {
          topic: String(r?.topic || "").trim(),
          subtopic: r?.subtopic ? String(r.subtopic).trim() : null,
          book_id: bookId,
          book_reference: bookReference
        };
      })
      .filter(r => r.topic);

    if (!normalized.length) return;

    const key = (r) => `${String(r.topic || "").trim()}::${r.subtopic ? String(r.subtopic).trim() : ""}`;

    const uniqMap = new Map();
    normalized.forEach(r => {
      const k = key(r);
      const prev = uniqMap.get(k);

      if (!prev || (!prev.book_reference && r.book_reference) || (!prev.book_id && r.book_id)) {
        uniqMap.set(k, { ...prev, ...r });
      }
    });

    const uniq = Array.from(uniqMap.values());
    const topics = Array.from(new Set(uniq.map(r => r.topic).filter(Boolean)));

    const { data: existingRows, error: selErr } = await window.sb
      .from("recommendations")
      .select("id, topic, subtopic, book_id, book_reference")
      .eq("user_id", uid)
      .eq("subject_id", subjectId)
      .eq("source_type", "practice")
      .in("topic", topics);

    if (selErr) {
      logClientError("recommendations_select_error", selErr);
      return;
    }

    let mapRows = [];
    try {
      const { data: mData, error: mErr } = await window.sb
        .from("topic_book_map")
        .select("topic, subtopic, book_id, book_reference, priority, is_active")
        .eq("subject_id", subjectId)
        .eq("is_active", true)
        .in("topic", topics)
        .order("priority", { ascending: true });

      if (!mErr && Array.isArray(mData)) mapRows = mData;
    } catch {}

    const norm = (v) => String(v || "").trim();
    const normSub = (v) => {
      const s = norm(v);
      return s ? s : null;
    };

    const bestFor = (item) => {
      const topic = norm(item.topic);
      const subtopic = normSub(item.subtopic);
      const directRef = norm(item.book_reference) || null;

      const exactByDirectRef = directRef
        ? mapRows.find(x =>
            norm(x.book_reference) === directRef &&
            norm(x.topic) === topic &&
            normSub(x.subtopic) === subtopic
          )
        : null;

      const exact = mapRows.find(x =>
        norm(x.topic) === topic &&
        normSub(x.subtopic) === subtopic
      );

      const byTopic = mapRows.find(x =>
        norm(x.topic) === topic &&
        normSub(x.subtopic) === null
      );

      const anyByDirectRef = directRef
        ? mapRows.find(x => norm(x.book_reference) === directRef)
        : null;

      const picked = exactByDirectRef || exact || byTopic || anyByDirectRef || null;

      return {
        book_id: item.book_id || picked?.book_id || null,
        book_reference: directRef || picked?.book_reference || null
      };
    };

    const existingByKey = new Map(
      (Array.isArray(existingRows) ? existingRows : []).map(r => [key(r), r])
    );

    for (const item of uniq) {
      const row = existingByKey.get(key(item));
      if (!row?.id) continue;

      const best = bestFor(item);
      const patch = {};

      if (!row.book_reference && best.book_reference) patch.book_reference = best.book_reference;
      if (!row.book_id && best.book_id) patch.book_id = best.book_id;

      if (Object.keys(patch).length) {
        const { error: updErr } = await window.sb
          .from("recommendations")
          .update(patch)
          .eq("id", row.id);

        if (updErr) logClientError("recommendations_update_refs_error", updErr);
      }
    }

    const toInsert = uniq
      .filter(r => !existingByKey.has(key(r)))
      .map(r => {
        const best = bestFor(r);

        return {
          user_id: uid,
          subject_id: subjectId,
          source_type: "practice",
          topic: r.topic,
          subtopic: r.subtopic,
          book_id: best.book_id || null,
          book_reference: best.book_reference || null
        };
      });

    if (!toInsert.length) return;

    const { error: insErr } = await window.sb.from("recommendations").insert(toInsert);
    if (insErr) {
      logClientError("recommendations_insert_error", insErr);
      try {
        const uid2 = await getAuthUid();
        await logDbErrorToEvents(uid2, "recommendations_insert_error", insErr, { subject_id: subjectId, count: toInsert.length });
      } catch {}
    }
  } catch (e) {
    logClientError("recommendations_sync_exception", e);
    try {
      const uid2 = await getAuthUid();
      await logDbErrorToEvents(uid2, "recommendations_sync_exception", e, {});
    } catch {}
  }
}

function addMyRecsFromAttempt(attempt) {
  const wrong = (attempt?.details || []).filter(d => !d.isCorrect);

  // build unique recs by topic+subtopic and keep book source if available
  const recMap = new Map();
  wrong.forEach(d => {
    const topic = String(d?.topic || "General").trim();
    const subtopic = d?.subtopic ? String(d.subtopic).trim() : null;
    const k = `${topic}::${subtopic || ""}`;

    const bookIdRaw = d?.book_id ?? d?.bookId ?? null;
    const bookId = Number(bookIdRaw || 0) > 0 ? Number(bookIdRaw) : null;
    const bookReference = String(
      d?.book_reference ||
      d?.bookReference ||
      d?.book_ref ||
      d?.bookRef ||
      ""
    ).trim() || null;

    const next = {
      topic,
      subtopic,
      book_id: bookId,
      book_reference: bookReference
    };

    const prev = recMap.get(k);
    if (!prev || (!prev.book_reference && next.book_reference) || (!prev.book_id && next.book_id)) {
      recMap.set(k, { ...prev, ...next });
    }
  });

  const recs = Array.from(recMap.values());
  if (!recs.length) return { added: 0, recs: [], addedRecs: [] };

  const store = loadMyRecs();
  store.bySubject = store.bySubject || {};
  const subjKey = attempt.subjectKey || "unknown";

  const existing = new Set(
    (store.bySubject[subjKey] || []).map(x =>
      `${String(x?.topic || "").trim()}::${x?.subtopic ? String(x.subtopic).trim() : ""}`
    )
  );

  const nowTs = Date.now();

  const add = recs
    .filter(r => !existing.has(`${r.topic}::${r.subtopic || ""}`))
    .map(r => ({
      topic: r.topic,
      subtopic: r.subtopic || null,
      book_id: r.book_id || null,
      book_reference: r.book_reference || null,
      ts: nowTs
    }));

  store.bySubject[subjKey] = [...add, ...(store.bySubject[subjKey] || [])].slice(0, 50);
  saveMyRecs(store);

  return { added: add.length, recs, addedRecs: add };
}

  function formatMMSS(sec) {
    const s = Math.max(0, Number(sec) || 0);
    const mm = Math.floor(s / 60);
    const ss = s % 60;
    return `${String(mm).padStart(2, "0")}:${String(ss).padStart(2, "0")}`;
  }

        function normalizeInputAnswerText(v) {
    return String(v ?? "")
      .trim()
      .replace(/[−–—]/g, "-");
  }

    function normalizeNumericInput(v) {
    return normalizeInputAnswerText(v);
  }

  function hasInternalWhitespace(v) {
    const s = normalizeInputAnswerText(v);
    return /\s/.test(s);
  }

  function parseStrictNumberAnswer(v) {
    const s = normalizeNumericInput(v);
    if (!s) return null;

    // Strict app format:
    // 12
    // 12.5
    // +4 / -3
    // 1.505e23 / 1.505E23
    //
    // Intentionally NOT accepted here:
    // 12,5
    // 1.505×10^23
    // 1.505*10^23
    // answers with units or spaces
    if (hasInternalWhitespace(s)) return null;
    if (!/^[+-]?\d+(?:\.\d+)?(?:[eE][+-]?\d+)?$/.test(s)) return null;

    const n = Number(s);
    return Number.isFinite(n) ? n : null;
  }

  // Backward-compatible name used in older parts of the app.
  // Now intentionally strict, because question texts specify the exact input format.
  function parseFlexibleScientificNumber(v) {
    return parseStrictNumberAnswer(v);
  }

    function inputExpectedRequiresExplicitSign(expectedRaw) {
    const expected = normalizeNumericInput(expectedRaw);

    // For oxidation-number style answers like +4 or -3,
    // the sign is part of the required academic format.
    // If expected is +4, user must write +4, not plain 4.
    return /^[+-]\d+(?:\.\d+)?(?:[eE][+-]?\d+)?$/.test(expected);
  }

  function hasAllowedNumericSign(userRaw, expectedRaw) {
    const expected = normalizeNumericInput(expectedRaw);
    const user = normalizeNumericInput(userRaw);

    if (!user || !expected) return false;

    // Signed expected answer: user must use the same explicit sign.
    // Example: expected +4 => +4 only, not 4.
    // Example: expected -3 => -3 only, not 3.
    if (inputExpectedRequiresExplicitSign(expected)) {
      if (expected.startsWith("+")) return user.startsWith("+");
      if (expected.startsWith("-")) return user.startsWith("-");
      return true;
    }

    // Plain numeric expected answer: user must NOT add a sign.
    // Example: expected 6 => 6 only, not +6.
    return !/^[+-]/.test(user);
  }

  function areNumericAnswersEquivalent(a, b) {
    const na = parseStrictNumberAnswer(a);
    const nb = parseStrictNumberAnswer(b);

    if (na === null || nb === null) return false;
    if (!hasAllowedNumericSign(a, b)) return false;

    const diff = Math.abs(na - nb);
    const scale = Math.max(1, Math.abs(na), Math.abs(nb));

    return diff <= scale * 1e-9;
  }
  function normalizeFreeTextAnswer(v) {
    return normalizeInputAnswerText(v)
      .replace(/\s+/g, "")
      .toLowerCase();
  }

  function getInputExpectedAnswer(q) {
    if (!q) return "";

    const raw =
      q.correctAnswer ?? q.correct_answer ?? q.correct ?? q.answer ?? "";

    return String(raw ?? "").trim();
  }

  function isFormulaLikeExpectedAnswer(expectedRaw) {
    const expected = String(expectedRaw ?? "").trim();

    // Short formula/token style answers:
    // MgO, CO2, C2H6O, BaSO4, NH3, RETURN, EOF
    return /^[A-Z][A-Za-z0-9]*$/.test(expected);
  }

    function isInputAnswerCorrect(userRaw, expectedRaw) {
    const user = String(userRaw ?? "").trim();
    const expected = String(expectedRaw ?? "").trim();

    if (!user || !expected) return false;

    const expectedNumber = parseStrictNumberAnswer(expected);

    if (expectedNumber !== null) {
      return areNumericAnswersEquivalent(user, expected);
    }

    if (isFormulaLikeExpectedAnswer(expected)) {
      // Keep formula/token answers compact even if correctness is called directly.
      // Lowercase is accepted as user-friendly input, but spaces/subscripts are not.
      if (/[₀₁₂₃₄₅₆₇₈₉]/.test(user)) return false;
      if (/\s/.test(user)) return false;
      if (!/^[A-Za-z][A-Za-z0-9]*$/.test(user)) return false;

      return normalizeInputAnswerText(user).toLowerCase() === normalizeInputAnswerText(expected).toLowerCase();
    }

    return normalizeFreeTextAnswer(user) === normalizeFreeTextAnswer(expected);
  }

  function renderTrendBars({ wrapEl, deltaEl, attemptsNewestFirst, barClass, lastClass }) {
  if (!wrapEl) return;

  const list = Array.isArray(attemptsNewestFirst) ? attemptsNewestFirst : [];
  if (list.length < 2) {
    if (wrapEl) wrapEl.innerHTML = "";
    if (deltaEl) deltaEl.textContent = "";
    // hide container (parent card section)
    const root = wrapEl.closest(".practice-micro, .tours-micro");
    if (root) root.style.display = "none";
    return;
  }

  const root = wrapEl.closest(".practice-micro, .tours-micro");
  if (root) root.style.display = "block";

  // delta between newest and previous
  const a0 = Number(list[0]?.percent) || 0;
  const a1 = Number(list[1]?.percent) || 0;
  const d = a0 - a1;
  const sign = d > 0 ? "+" : d < 0 ? "−" : "";
  const abs = Math.abs(d);
  const txt = sign ? `${sign}${abs.toFixed(1)}%` : `0.0%`;

  if (deltaEl) {
    deltaEl.textContent = txt;
    deltaEl.classList.remove("is-pos", "is-neg");
    if (d > 0) deltaEl.classList.add("is-pos");
    if (d < 0) deltaEl.classList.add("is-neg");
  }

  // bars: oldest -> newest, up to 5
  const seq = list.slice(0, 5).slice().reverse(); // oldest-first
  wrapEl.innerHTML = "";

  seq.forEach((a, idx) => {
    const p = Math.max(0, Math.min(100, Number(a.percent) || 0));
    const h = 6 + Math.round((p / 100) * 16);

    const b = document.createElement("div");
    b.className = barClass + (idx === seq.length - 1 ? ` ${lastClass}` : "");
    b.style.height = `${h}px`;
    b.title = `${p}%`;
    wrapEl.appendChild(b);
  });
}
   
   // ---- Practice history render (inject into practice-start) ----
  async function renderPracticeStart() {
  const subjectKey = state.courses.subjectKey;
  const subj = subjectByKey(subjectKey);
  const viewSubjectKey = subjectKey;

  const titleEl = $("#practice-subject-title");
  if (titleEl) titleEl.textContent = subjectTitle(subjectKey, subj?.title || subjectKey || "—");

  const stageMetaEl = $("#practice-stage-meta");
  if (stageMetaEl) stageMetaEl.textContent = "—";

  const bestScoreEl = $("#practice-best-score");
  const bestPctEl = $("#practice-best-percent");
  const bestTimeEl = $("#practice-best-time");

  if (bestScoreEl) bestScoreEl.textContent = "—";
  if (bestPctEl) bestPctEl.textContent = "";
  if (bestTimeEl) bestTimeEl.textContent = "—";

  const tbody = $("#practice-last-tbody");
  const emptyEl = $("#practice-last-empty");
  if (tbody) tbody.innerHTML = "";
  if (emptyEl) emptyEl.style.display = "block";

  renderTrendBars({
    wrapEl: document.getElementById("practice-micro-bars"),
    deltaEl: document.getElementById("practice-micro-delta"),
    attemptsNewestFirst: [],
    barClass: "practice-micro-bar",
    lastClass: "is-last"
  });

  const formatSecShort = (sec) => {
    const s = Number(sec);
    if (!Number.isFinite(s) || s < 0) return "—";
    if (s < 60) return `${s}${t("practice_time_sec_suffix")}`;
    const m = Math.floor(s / 60);
    const r = s % 60;
    return `${m}${t("practice_time_min_suffix")} ${r}${t("practice_time_sec_suffix")}`;
  };

   return (async () => {
    const picker = await getPracticeTourCards(subjectKey);
    if (state?.courses?.subjectKey !== viewSubjectKey) return;

    const selectedTourNo = Number(picker?.selectedTourNo || 1);
updatePracticeStartButtonForTour(selectedTourNo, false);

const stageStats = await computePracticeStageStats(subjectKey, selectedTourNo);
if (state?.courses?.subjectKey !== viewSubjectKey) return;

renderPracticeTourPicker(picker.cards, selectedTourNo);
updatePracticeStartButtonForTour(selectedTourNo, false);
     
    const done = Number(stageStats?.masteredCount || 0);
    const total = Number(stageStats?.totalCount || 0);
    const open = Math.max(0, total - done);

    if (stageMetaEl) {
      const titlePart =
        t("practice_stage_for_tour", { n: selectedTourNo }) ||
        `Practice for Tour ${selectedTourNo}`;

      const progressPart = total > 0
        ? (t("practice_stage_progress", { done, total }) || `${done}/${total}`)
        : "";

      const leftPart = total > 0
        ? tr3(`Осталось ${open}`, `${open} ta qoldi`, `${open} left`)
        : "";

      stageMetaEl.textContent = [titlePart, progressPart, leftPart].filter(Boolean).join(" • ");
    }

    const h = loadPracticeHistory(subjectKey, selectedTourNo);
    const best = h?.best || null;
    const last = Array.isArray(h?.last) ? h.last : [];

    if (best) {
      if (bestScoreEl) bestScoreEl.textContent = `${best.score}/${best.total}`;
      if (bestPctEl) bestPctEl.textContent = `(${best.percent}%)`;
      if (bestTimeEl) bestTimeEl.textContent = formatSecShort(best.durationSec);
    }

    if (tbody) tbody.innerHTML = "";

    const rows = last.slice(0, 5);

    if (!rows.length) {
      if (emptyEl) emptyEl.style.display = "block";
      renderTrendBars({
        wrapEl: document.getElementById("practice-micro-bars"),
        deltaEl: document.getElementById("practice-micro-delta"),
        attemptsNewestFirst: [],
        barClass: "practice-micro-bar",
        lastClass: "is-last"
      });
      return;
    }

    if (emptyEl) emptyEl.style.display = "none";

    const pctClass = (p) => {
      const n = Number(p);
      if (!Number.isFinite(n)) return "pct-med";
      if (n < 40) return "pct-low";
      if (n < 70) return "pct-med";
      return "pct-high";
    };

    rows.forEach(a => {
      const tr = document.createElement("tr");

      const dt = formatDateTime(a.ts);
      const dateMain = dt.split(",")[0] || dt;
      const dateSub = dt.includes(",") ? dt.split(",").slice(1).join(",").trim() : "";

      tr.innerHTML = `
        <td>
          <div class="practice-date">
            <div class="practice-date-main">${escapeHTML(dateMain)}</div>
            ${dateSub ? `<div class="practice-date-sub">${escapeHTML(dateSub)}</div>` : ""}
          </div>
        </td>
        <td>
          <div class="practice-score">
            <span class="practice-score-main">${escapeHTML(`${a.score}/${a.total}`)}</span>
            <span class="pct-badge ${pctClass(a.percent)}">${escapeHTML(`${a.percent}%`)}</span>
          </div>
        </td>
        <td class="practice-time">${escapeHTML(formatSecShort(a.durationSec))}</td>
      `;

      if (tbody) tbody.appendChild(tr);
    });

    renderTrendBars({
      wrapEl: document.getElementById("practice-micro-bars"),
      deltaEl: document.getElementById("practice-micro-delta"),
      attemptsNewestFirst: last,
      barClass: "practice-micro-bar",
      lastClass: "is-last"
    });
  })().catch(() => {});
}
   
         async function renderToursStart() {
  showToursLoading();
  try {
    const profile = loadProfile?.() || null;
    const subjectKey = state.courses?.subjectKey || null;
    const subj = subjectByKey(subjectKey);

    // subject title
    const titleEl = document.getElementById("tours-subject-title");
    if (titleEl) titleEl.textContent = subjectTitle(subjectKey, subj ? subj.title : "Subject");

    // --------------------------------------
// Active tour by DB dates (no selection)
// --------------------------------------
const tourLabelEl = document.getElementById("tours-tour-label");
const statusTitle = document.getElementById("tours-status-title");
const statusDesc = document.getElementById("tours-status-desc");
const openBtn = document.getElementById("tours-open-btn");

// ✅ local i18n helper: if translation missing, show fallback (not the key)
const tr = (key, fallback) => {
  const v = (typeof t === "function") ? t(key) : key;
  return (v && v !== key) ? v : fallback;
};

// eligibility stays exactly as you had
const eligibility = (typeof canOpenActiveTours === "function")
  ? canOpenActiveTours(profile, subjectKey)
  : { ok: true };

// resolve subject_id
let subjectId = null;

// 1) Try existing helper (if it works — great)
try {
  subjectId = await getSubjectIdByKey(subjectKey);
} catch {}

// 2) Fallback: resolve subjectId directly from DB by subject_key (most reliable)
if (!subjectId && window.sb && subjectKey) {
  try {
    const { data: srow, error: serr } = await window.sb
      .from("subjects")
      .select("id")
      .eq("subject_key", String(subjectKey))
      .maybeSingle();

    if (!serr && srow?.id) subjectId = srow.id;
  } catch {}
}

// load tours for this subject (LOCAL date, not UTC)
const pad2 = (n) => String(n).padStart(2, "0");
const d0 = new Date();
const todayISO = `${d0.getFullYear()}-${pad2(d0.getMonth() + 1)}-${pad2(d0.getDate())}`;

const operationalSeasonId =
  await getCurrentSeasonId();

// UI: show loading first to avoid 1-sec "wrong screen" flicker
if (statusTitle) statusTitle.textContent = tr("loading", "Загрузка…");
if (statusDesc) statusDesc.textContent = tr("loading_desc", "Получаем список туров…");
if (openBtn) openBtn.classList.add("hidden");

// Тур без обеих дат остаётся скрытым.
const isInWindow = (row) => {
  const sd = row?.start_date
    ? String(row.start_date)
    : "";

  const ed = row?.end_date
    ? String(row.end_date)
    : "";

  if (!sd || !ed) {
    return false;
  }

  return sd <= todayISO && ed >= todayISO;
};

let dbTours = [];
let toursErr = null;

// 1) Prefer join by subject_key (so we don't зависим от subjectId)
if (window.sb && subjectKey) {
  try {
    const { data, error } = await window.sb
      .from("tours")
      .select("id, subject_id, tour_no, start_date, end_date, is_active, season_id, subjects!inner(subject_key)")
      .eq("subjects.subject_key", String(subjectKey))
      .eq("season_id", Number(operationalSeasonId))
      .order("tour_no", { ascending: true });

    if (error) toursErr = error;
    if (!error && Array.isArray(data)) {
      dbTours = data;

      // backfill subjectId for any later logic that still wants it
      if (!subjectId && dbTours.length && dbTours[0]?.subject_id) {
        subjectId = dbTours[0].subject_id;
      }
    }
  } catch (e) {
    toursErr = e;
  }
}

// 2) Fallback: by subject_id (if join is blocked by policy)
if (!dbTours.length && window.sb && subjectId) {
  try {
    const { data, error } = await window.sb
      .from("tours")
      .select("id, subject_id, tour_no, start_date, end_date, is_active, season_id")
      .eq("subject_id", subjectId)
      .eq("season_id", Number(operationalSeasonId))
      .order("tour_no", { ascending: true });

    if (error) toursErr = toursErr || error;
    if (!error && Array.isArray(data)) dbTours = data;
  } catch (e) {
    toursErr = toursErr || e;
  }
}

 // pick active / upcoming tours
const activeTours = dbTours.filter(r => !!r.is_active && isInWindow(r));
const activeTour = activeTours.length ? activeTours[0] : null;

const upcomingTours = dbTours
  .filter(r => {
    if (!r?.is_active) return false;
    const sd = r?.start_date ? String(r.start_date) : null;
    return !!sd && sd > todayISO;
  })
  .sort((a, b) => Number(a?.tour_no || 0) - Number(b?.tour_no || 0));

const upcomingTour = upcomingTours.length ? upcomingTours[0] : null;

// save active / upcoming context for later flow
if (!state.courses) state.courses = {};
state.courses.activeTourId = activeTour?.id || null;
state.courses.activeTourNo = activeTour?.tour_no || null;
state.courses.activeSeasonId =
  activeTour?.season_id ||
  operationalSeasonId ||
  null;

state.courses.upcomingTourId = upcomingTour?.id || null;
state.courses.upcomingTourNo = upcomingTour?.tour_no || null;
state.courses.upcomingSeasonId =
  upcomingTour?.season_id ||
  operationalSeasonId ||
  null;

// label
if (tourLabelEl) {
  if (activeTour) {
    tourLabelEl.textContent = `${tr("tours_tour_label", "Тур")} ${activeTour.tour_no}`;
  } else if (upcomingTour) {
    tourLabelEl.textContent = `${tr("tours_tour_label", "Тур")} ${upcomingTour.tour_no}`;
  } else {
    tourLabelEl.textContent = tr("tours_status_title", "Туры пока недоступны");
  }
}

// Status + Open button (DB)
if (!activeTour && !upcomingTour) {
  if (statusTitle) {
    statusTitle.textContent = tr("tours_status_title", "Туры пока недоступны");
  }

  const baseDesc = tr(
    "tours_status_desc",
    "Даты и список туров появятся здесь после публикации."
  );
  const errHint = toursErr ? " (нет доступа к базе туров)" : "";

  if (statusDesc) {
    statusDesc.textContent = baseDesc + errHint;
  }

  if (openBtn) {
    openBtn.classList.add("hidden");
    openBtn.style.display = "none";
    openBtn.onclick = null;
  }
} else if (!activeTour && upcomingTour) {
  const dateTxt = formatTourDateText(upcomingTour?.start_date, upcomingTour?.end_date);

  if (statusTitle) {
    statusTitle.textContent =
      t("tours_status_upcoming_title") ||
      tr3("Тур скоро начнётся", "Tur tez orada boshlanadi", "Tour starts soon");
  }

  if (statusDesc) {
    statusDesc.textContent =
      t("tours_status_upcoming_desc", { n: upcomingTour.tour_no, date: dateTxt }) ||
      `${tr("tours_tour_label", "Тур")} ${upcomingTour.tour_no}${dateTxt ? " • " + dateTxt : ""}`;
  }

  if (openBtn) {
    openBtn.classList.add("hidden");
    openBtn.style.display = "none";
    openBtn.onclick = null;
  }
} else {
  const dateTxt = formatTourDateText(activeTour?.start_date, activeTour?.end_date);

  if (statusTitle) {
    statusTitle.textContent = tr("tours_active_now", "Активный тур сейчас");
  }
  if (statusDesc) {
    statusDesc.textContent =
      `${tr("tours_tour_label", "Тур")} ${activeTour.tour_no}${dateTxt ? " • " + dateTxt : ""}`;
  }

  let alreadyAttempted = false;
  try {
    const uid = await getAuthUid();
    if (uid && typeof hasTourAttempt === "function" && activeTour?.id) {
      alreadyAttempted = await hasTourAttempt(uid, activeTour.id);
    }
  } catch {}

  if (alreadyAttempted) {
    if (statusTitle) {
      statusTitle.textContent = tr("tour_unavailable_title", "Тур недоступен");
    }
    if (statusDesc) {
      statusDesc.textContent = tr(
        "tour_unavailable_already_attempted",
        "Вы уже завершили этот тур. Повторное прохождение недоступно."
      );
    }

    if (openBtn) {
      openBtn.classList.add("hidden");
      openBtn.style.display = "none";
      openBtn.onclick = null;
    }
  } else {
    if (openBtn) {
      openBtn.classList.remove("hidden");
      openBtn.style.display = "";
      openBtn.disabled = false;
      openBtn.textContent = tr("open_tour_btn", "Открыть тур");
      openBtn.onclick = () => openTourRules();
    }
  }
}
     try {
       await renderToursHistorySummary(
         subjectId,
         operationalSeasonId
       );
     } catch {}
     
      saveState();
      } finally {
     hideToursLoading();
   }
  }

 // --------------------------------------
// Completed tours (DB summary by subject)
// Best = max percent, tie-break = min time
// --------------------------------------
async function renderToursHistorySummary(
  subjectId,
  seasonIdArg = null
) {
  const bestScoreEl = document.getElementById("tours-best-score");
  const bestPctEl = document.getElementById("tours-best-percent");
  const bestTimeEl = document.getElementById("tours-best-time");

  const historyCard = document.getElementById("tours-history-card");
  const historyListEl = document.getElementById("tours-history-list");
  const historyEmptyEl = document.getElementById("tours-history-empty");
  const historySubEl = document.getElementById("tours-history-sub");

  const formatSecShort = (sec) => {
    const s = Number(sec);
    if (!Number.isFinite(s) || s < 0) return "—";
    if (s < 60) return `${s}${t("practice_time_sec_suffix")}`;
    const m = Math.floor(s / 60);
    const r = s % 60;
    return `${m}${t("practice_time_min_suffix")} ${r}${t("practice_time_sec_suffix")}`;
  };

  const seasonId =
    Number(seasonIdArg || 0) ||
    await getCurrentSeasonId();

  let attempts = [];

  try {
    const uid = await getAuthUid();

    if (
      window.sb &&
      uid &&
      subjectId &&
      seasonId
    ) {
      const { data, error } = await window.sb
        .from("tour_attempts")
        .select("id, tour_id, score, percent, total_time, created_at, tours!inner(tour_no, subject_id, season_id)")
        .eq("user_id", uid)
        .eq("tours.subject_id", subjectId)
        .eq("tours.season_id", Number(seasonId))
        .order("created_at", { ascending: false });

      if (!error && Array.isArray(data)) attempts = data;
    }
  } catch {}

  // Group best attempt per tour_no (although now it's usually 1 attempt)
  const byTour = new Map();
  for (const a of attempts) {
    const tourNo = Number(a?.tours?.tour_no);
    if (!Number.isFinite(tourNo)) continue;

    const prev = byTour.get(tourNo) || null;
    if (!prev) {
      byTour.set(tourNo, a);
      continue;
    }

    const ap = Number(a?.percent || 0);
    const pp = Number(prev?.percent || 0);
    const at = Number(a?.total_time || 1e9);
    const pt = Number(prev?.total_time || 1e9);

    if (ap > pp) byTour.set(tourNo, a);
    else if (ap === pp && at < pt) byTour.set(tourNo, a);
  }

  const rows = Array.from(byTour.entries())
    .sort((x, y) => x[0] - y[0])
    .map(([tourNo, a]) => ({ tourNo, a }));

  // Best across ALL completed tours for this subject
  let best = null;
  for (const { a } of rows) {
    if (!best) { best = a; continue; }
    const ap = Number(a?.percent || 0);
    const bp = Number(best?.percent || 0);
    const at = Number(a?.total_time || 1e9);
    const bt = Number(best?.total_time || 1e9);
    if (ap > bp) best = a;
    else if (ap === bp && at < bt) best = a;
  }

  // Fill BEST metrics (total questions in tour = 20)
  const TOTAL_TOUR_Q = 20;
  if (best) {
    const score = Number(best?.score ?? 0);
    const pct = Math.round(Number(best?.percent ?? 0));
    const time = Number(best?.total_time ?? 0);

    if (bestScoreEl) bestScoreEl.textContent = `${score}/${TOTAL_TOUR_Q}`;
    if (bestPctEl) bestPctEl.textContent = `(${pct}%)`;
    if (bestTimeEl) bestTimeEl.textContent = formatSecShort(time);
  } else {
    if (bestScoreEl) bestScoreEl.textContent = "—";
    if (bestPctEl) bestPctEl.textContent = "";
    if (bestTimeEl) bestTimeEl.textContent = "—";
  }

  // Render completed list
  if (historyCard) historyCard.style.display = "";
  if (historyListEl) historyListEl.innerHTML = "";

  if (!rows.length) {
    if (historyEmptyEl) historyEmptyEl.style.display = "";
    if (historySubEl) historySubEl.textContent = "";
  } else {
    if (historyEmptyEl) historyEmptyEl.style.display = "none";
    if (historySubEl) historySubEl.textContent =
      (typeof t === "function" && t("tours_completed_sub", { n: rows.length }) !== "tours_completed_sub")
        ? t("tours_completed_sub", { n: rows.length })
        : `Всего: ${rows.length}`;

    for (const { tourNo, a } of rows) {
      const score = Number(a?.score ?? 0);
      const pct = Math.round(Number(a?.percent ?? 0));
      const time = Number(a?.total_time ?? 0);

      const rowEl = document.createElement("div");
      rowEl.className = "tours-history-row";
      rowEl.innerHTML = `
        <div class="tours-history-left">
          <div class="tours-history-tour">${t("tours_tour_label")} ${tourNo}</div>
          <div class="tours-history-meta">${pct}%</div>
        </div>
        <div class="tours-history-right">
          <div class="tours-history-score">${score}/${TOTAL_TOUR_Q}</div>
          <div class="tours-history-time">${formatSecShort(time)}</div>
        </div>
      `;
      if (historyListEl) historyListEl.appendChild(rowEl);
    }
  }

  // Trend bars (based on completed tours list)
  try {
    const trendWrap = document.getElementById("tours-micro-bars");
    const trendDelta = document.getElementById("tours-micro-delta");
    const trendBox = document.getElementById("tours-trend");

    const trendAttemptsNewestFirst = rows
      .slice()
      .sort((a, b) => a.tourNo - b.tourNo)
      .map(x => ({ percent: Number(x.a?.percent ?? 0) }))
      .reverse();

    if (trendAttemptsNewestFirst.length >= 2) {
      if (trendBox) trendBox.style.display = "";
      renderTrendBars({
        wrapEl: trendWrap,
        deltaEl: trendDelta,
        attemptsNewestFirst: trendAttemptsNewestFirst,
        barClass: "tours-micro-bar",
        lastClass: "is-last"
      });
    } else {
      if (trendBox) trendBox.style.display = "none";
    }
  } catch {}
}

  // ---- Practice timer (per-question) ----
    function stopPracticeQuestionTimer() {
    if (state.quiz?.qTimerId) {
      clearInterval(state.quiz.qTimerId);
      state.quiz.qTimerId = null;
    }
  }

  function tickPracticeTimerNow() {
    const quiz = state.quiz;
    if (!quiz || quiz.mode !== "practice") return;
    if (quiz.paused) return;

    if (!quiz.qEndsAtMono) {
      quiz.qEndsAtMono = monoNow() + (Number(quiz.qTimeLeft) || 0) * 1000;
    }

    const now = monoNow();
    const leftSec = Math.max(0, Math.ceil((Number(quiz.qEndsAtMono) - now) / 1000));

    // keep existing API for the rest of the code
    quiz.qTimeLeft = leftSec;

    const timerEl = $("#practice-timer");
    if (timerEl) timerEl.textContent = formatMMSS(leftSec);

    if (leftSec <= 0) {
      stopPracticeQuestionTimer();
      handlePracticeSubmit(true).catch(() => null);
    }
  }

        function startPracticeQuestionTimer() {
    stopPracticeQuestionTimer();

    // initialize deadline from current qTimeLeft (monotonic)
    try {
      if (state.quiz && state.quiz.mode === "practice") {
        state.quiz.qEndsAtMono = monoNow() + (Number(state.quiz.qTimeLeft) || 0) * 1000;
      }
    } catch {}

    // paint immediately (important after returning from background)
    tickPracticeTimerNow();

    // faster tick to avoid background throttling issues; logic is deadline-based
    state.quiz.qTimerId = setInterval(() => {
      tickPracticeTimerNow();
    }, 250);
  }

  // ---- Entry point from Subject Hub ----
  async function openPracticeStart() {
  const subjectKey = state.courses.subjectKey;

  showAsyncOverlay(tr3(
    "Загружаем практику…",
    "Amaliyot yuklanmoqda…",
    "Loading practice…"
  ));

  try {
    pushCourses("practice-start");

    const resumeBtn = $("#practice-resume-btn");
    const restartBtn = $("#practice-restart-btn");

    if (resumeBtn) resumeBtn.style.display = "none";
    if (restartBtn) restartBtn.textContent = t("practice_start");

    const currentStage = await getPracticeStageContext(subjectKey);

    if (state?.courses?.subjectKey !== subjectKey) return;
    if (typeof getCoursesTopScreen === "function" && getCoursesTopScreen() !== "practice-start") return;

    const picker = await getPracticeTourCards(subjectKey);

    const draft = loadPracticeDraft();
    const draftTourNo = Number(
      draft?.practiceTourNo ||
      draft?.quiz?.practiceTourNo ||
      1
    );

    let currentTourNo = Number(picker?.selectedTourNo || currentStage?.practiceTourNo || 1);

    if (
      draft?.status === "paused" &&
      draft?.subjectKey === subjectKey &&
      draftTourNo > 0
    ) {
      currentTourNo = draftTourNo;
      setSelectedPracticeTourNo(subjectKey, draftTourNo);
    }

    await renderPracticeStart();

    if (state?.courses?.subjectKey !== subjectKey) return;
    if (typeof getCoursesTopScreen === "function" && getCoursesTopScreen() !== "practice-start") return;

    const canResume = !!(
      draft?.status === "paused" &&
      draft?.subjectKey === subjectKey &&
      draft?.quiz &&
      Array.isArray(draft.quiz.questions) &&
      draft.quiz.questions.length > 0 &&
      draftTourNo === currentTourNo
    );

    if (resumeBtn) resumeBtn.style.display = canResume ? "block" : "none";

    updatePracticeStartButtonForTour(currentTourNo, canResume);

    if (canResume) {
      showToast(t("practice_resume_prompt"));
    }
  } finally {
    hideAsyncOverlay();
  }
}
   
async function startPracticeNew() {
  const subjectKey = state.courses.subjectKey;

  let questions = [];
  let stageCtx = null;

  showAsyncOverlay(tr3(
    "Загружаем вопросы практики…",
    "Amaliyot savollari yuklanmoqda…",
    "Loading practice questions…"
  ));

  try {
  stageCtx = await getPracticeStageContext(subjectKey);

const picker = await getPracticeTourCards(subjectKey);
const selectedTourNo = Number(picker?.selectedTourNo || stageCtx?.practiceTourNo || 1);

const selectedCard = (Array.isArray(picker?.cards) ? picker.cards : []).find(
  c => Number(c?.tourNo || 0) === Number(selectedTourNo)
);

if (selectedCard?.isLocked) {
  showToast(
    t("practice_tour_locked") ||
    tr3(
      "Эта практика откроется вместе с соответствующим туром.",
      "Bu amaliyot tegishli tur bilan birga ochiladi.",
      "This practice opens with the corresponding tour."
    )
  );
  return;
}

const selectedStats = await computePracticeStageStats(subjectKey, selectedTourNo);

stageCtx = {
  ...stageCtx,
  poolId: Number(selectedStats?.poolId || 0) || null,
  practiceTourNo: Number(selectedStats?.practiceTourNo || selectedTourNo || 1)
};

questions = await buildPracticeSetForTour(subjectKey, stageCtx.practiceTourNo);
} finally {
  hideAsyncOverlay();
}
  if (!stageCtx?.poolId) {
    showToast(
      t("practice_stage_not_ready") ||
      "Практика для этого этапа пока не опубликована."
    );
    return;
  }

  if (!Array.isArray(questions) || questions.length === 0) {
    const stageStats = await computePracticeStageStats(subjectKey, stageCtx.practiceTourNo);

    if (Number(stageStats?.totalCount || 0) > 0 && Number(stageStats?.openCount || 0) <= 0) {
      showToast(
        t("practice_stage_all_closed") ||
        "Все вопросы этого этапа уже закрыты. Новый этап откроется после смены официального тура."
      );
    } else {
      showToast(t("practice_no_questions") || "Нет вопросов для практики по этому предмету.");
    }
    return;
  }

  try {
    trackEvent("practice_attempt_started", {
      subject_id: normSubjectId(subjectKey),
      subject_key: String(subjectKey || ""),
      practice_tour_no: Number(stageCtx?.practiceTourNo || 1),
      practice_pool_id: Number(stageCtx?.poolId || 0) || null,
      questions_total: Array.isArray(questions) ? questions.length : 0,
      source: "subject_hub"
    });
  } catch {}

  state.quizLock = "practice";
  state.quiz = {
    mode: "practice",
    subjectKey,
    practiceTourNo: Number(stageCtx?.practiceTourNo || questions[0]?.practiceTourNo || 1),
    practicePoolId: Number(stageCtx?.poolId || questions[0]?.practicePoolId || 0) || null,
    startedAt: Date.now(),
    paused: false,
    pauseStartedAt: null,
    pausedTotalMs: 0,

    index: 0,
    questions,
    answers: Array.from({ length: questions.length }).map(() => null),
    correct: Array.from({ length: questions.length }).map(() => false),

    qTimeLeft: Number(questions[0]?.timeLimitSec) || PRACTICE_CONFIG.timeByDifficulty[questions[0]?.difficulty] || 60,
    qEndsAtMs: null,
    qTimerId: null
  };

  saveState();
  replaceCourses("practice-quiz");
  renderPracticeQuiz();
  startPracticeQuestionTimer();
}

   async function startPracticePast() {
  const subjectKey = state.courses.subjectKey;

  let questions = [];
  let stats = null;

  showAsyncOverlay(tr3(
    "Загружаем практику по прошедшим турам…",
    "O‘tgan turlar amaliyoti yuklanmoqda…",
    "Loading practice for past tours…"
  ));

  try {
    stats = await computePastPracticeStats(subjectKey);
    questions = await buildPastPracticeSet(subjectKey);
  } finally {
    hideAsyncOverlay();
  }

  if (!Array.isArray(stats?.tourNos) || !stats.tourNos.length) {
    showToast(t("practice_past_empty") || "Для прошлых туров пока нет доступных вопросов.");
    return;
  }

  if (!Array.isArray(questions) || !questions.length) {
    showToast(
      Number(stats?.openCount || 0) <= 0
        ? (t("practice_past_done") || "Все вопросы прошлых туров уже закрыты правильно.")
        : (t("practice_past_empty") || "Для прошлых туров пока нет доступных вопросов.")
    );
    return;
  }

  state.quizLock = "practice";
  state.quiz = {
    mode: "practice",
    drillType: "past_tours",
    subjectKey,
    practiceTourNo: 0,
    practicePoolId: null,
    startedAt: Date.now(),
    paused: false,
    pauseStartedAt: null,
    pausedTotalMs: 0,

    index: 0,
    questions,
    answers: Array.from({ length: questions.length }).map(() => null),
    correct: Array.from({ length: questions.length }).map(() => false),
    timeSpent: Array.from({ length: questions.length }).map(() => 0),

    qTimeLeft: Number(questions[0]?.timeLimitSec) || PRACTICE_CONFIG.timeByDifficulty[questions[0]?.difficulty] || 60,
    qEndsAtMono: null,
    qTimerId: null
  };

  saveState();
  replaceCourses("practice-quiz");
  renderPracticeQuiz();
  startPracticeQuestionTimer();
}
   
  // ---- Rendering question (MCQ or INPUT) ----
  function renderPracticeQuiz() {
    const quiz = state.quiz;
    if (!quiz || quiz.mode !== "practice") return;

    const q = quiz.questions[quiz.index];
    if (!q) return;
   // ✅ keep Pause button translated (and allow drill-specific label)
try {
  const btn = document.querySelector('[data-action="practice-pause"]');
  if (btn) {
    const key = quiz?.drillType ? "practice_pause_btn_drill" : "practice_pause_btn";
    btn.textContent = t(key) || btn.textContent;
  }
} catch {}

    const qno = $("#practice-qno");
    const qtext = $("#practice-question");
    const wrap = $("#practice-options");
    const timerEl = $("#practice-timer");

    if (qno) qno.textContent = `${quiz.index + 1}/${Array.isArray(quiz.questions) ? quiz.questions.length : PRACTICE_CONFIG.total}`;
    if (timerEl) timerEl.textContent = formatMMSS(quiz.qTimeLeft);
    if (qtext) qtext.textContent = q.question || (t("practice_question_placeholder") || "Вопрос…");
    if (!wrap) return;

    wrap.innerHTML = "";

    // Difficulty hint (small)
    const diff = document.createElement("div");
    diff.className = "muted small";
    diff.style.marginBottom = "8px";
    const diffLabel = t("practice_difficulty") || "Сложность";
    const diffKey = `difficulty_${String(q.difficulty || "").toLowerCase()}`;
    const diffText = t(diffKey) || q.difficulty || "";
    diff.textContent = `${diffLabel}: ${diffText}`;
    wrap.appendChild(diff);

    if (q.type === "mcq") {
      const selectedIndex = quiz.answers[quiz.index];

      (q.options || []).forEach((optText, idx) => {
        const row = document.createElement("label");
        row.className = "option";
        row.innerHTML = `
          <input type="radio" name="practice-opt" value="${idx}">
          <span>${escapeHTML(optText)}</span>
        `;
        const input = row.querySelector('input[type="radio"]');
        if (input && selectedIndex === idx) input.checked = true;

        input?.addEventListener("change", () => {
          quiz.answers[quiz.index] = idx;
          saveState();
          updatePracticeSubmitEnabled();
        });

        wrap.appendChild(row);
      });

      return;
    }

    // INPUT
        const box = document.createElement("div");
    box.className = "input-wrap";
    box.innerHTML = `
      <input id="practice-input" class="text-input" type="text" placeholder="${escapeHTML(q.inputHint || "")}">
      <div id="practice-input-error" class="muted small" style="margin-top:6px; display:none;"></div>
    `;
    wrap.appendChild(box);

    const inputEl = $("#practice-input");
    const errEl = $("#practice-input-error");
    const prev = quiz.answers[quiz.index];
    if (inputEl && typeof prev === "string") inputEl.value = prev;

    inputEl?.addEventListener("input", () => {
      quiz.answers[quiz.index] = inputEl.value;
      saveState();
      updatePracticeSubmitEnabled();
      if (errEl) errEl.style.display = "none";
    });
     updatePracticeSubmitEnabled();
  }

   function updatePracticeSubmitEnabled() {
  const quiz = state.quiz;
  const btn = $("#practice-submit-btn");
  if (!btn || !quiz || quiz.mode !== "practice") return;

  if (quiz._submitInFlight || quiz._finishing) {
    btn.disabled = true;
    return;
  }

  const q = quiz.questions[quiz.index];
  const ua = quiz.answers[quiz.index];

  let ok = false;

  if (q.type === "mcq") {
    ok = (ua !== null && ua !== undefined);
  } else {
    ok = isValidInputAnswer(q, String(ua ?? "").trim());
  }

  btn.disabled = !ok;
}

  // ---- Pause / Submit / Finish ----
      function handlePracticePause() {
    const quiz = state.quiz;
    if (!quiz || quiz.mode !== "practice") return;

    stopPracticeQuestionTimer();

    // mark paused time
    quiz.paused = true;
    quiz.pauseStartedAt = Date.now();

    // store snapshot to draft (so even refresh won't kill it)
    try {
      // do not persist secrets or timer id
      const quizForDraft = stripPracticeQuizSecrets(quiz);

      savePracticeDraft({
  status: "paused",
  subjectKey: quiz.subjectKey,
  practiceTourNo: Number(quiz.practiceTourNo || 1),
  practicePoolId: Number(quiz.practicePoolId || 0) || null,
  pausedAt: Date.now(),
  quiz: quizForDraft
});
    } catch (e) {
      // if draft NOT saved — do NOT destroy current attempt
      showToast(t("not_available"));
      return;
    }

    // unlock UI navigation
    state.quizLock = null;
    state.quiz = null;
    saveState();

    showToast(t("practice_paused"));
    replaceCourses("subject-hub");
    renderSubjectHub();
  }

   async function handlePracticeSubmit(isAutoTimeout = false) {
  const quiz = state.quiz;
  if (!quiz || quiz.mode !== "practice") return;
  if (quiz._submitInFlight || quiz._finishing) return;

  quiz._submitInFlight = true;

  const submitBtn = $("#practice-submit-btn");
  if (submitBtn) submitBtn.disabled = true;

  const releaseSubmitLock = () => {
    if (state.quiz === quiz && !quiz._finishing) {
      quiz._submitInFlight = false;
      updatePracticeSubmitEnabled();
    }
  };

    try {
    let q = quiz.questions[quiz.index];

    if (String(q?.type || "mcq").toLowerCase() === "mcq" && getMcqCorrectIndexFromQuestion(q) === null) {
      const restoredQuiz = await restorePracticeQuizSecrets(quiz);

      if (!restoredQuiz || !Array.isArray(restoredQuiz.questions) || !restoredQuiz.questions.length) {
        showToast(t("save_failed_try_again") || t("not_available") || "Please try again.");
        return;
      }

      Object.assign(quiz, restoredQuiz);
      state.quiz = quiz;
      q = quiz.questions[quiz.index];
    }

    const userAns = quiz.answers[quiz.index];

    if (!isAutoTimeout) {
      if (q.type === "mcq") {
        if (userAns === null || userAns === undefined) {
          showToast(t("select_option_required"));
          return;
        }
      } else {
        const val = String(userAns ?? "").trim();
        if (!isValidInputAnswer(q, val)) {
          const errEl = $("#practice-input-error");
          if (errEl) {
            errEl.textContent = t("invalid_answer_format");
            errEl.style.display = "block";
          } else {
            showToast(t("invalid_answer_format"));
          }
          return;
        }
      }
    }

       let isCorrect = false;

      if (q.type === "mcq") {
      isCorrect = isMcqPickedIndexCorrect(q, userAns);
    } else {
      const raw = String(userAns ?? "").trim();
      isCorrect = isInputAnswerCorrect(raw, getInputExpectedAnswer(q));
    }

    quiz.correct[quiz.index] = isCorrect;
     
    if (isAutoTimeout) {
      showToast(userAns ? t("toast_time_expired_answer_saved") : t("toast_time_expired_no_answer"));
    }

    const allowed = Number(q.timeLimitSec) || Number(PRACTICE_CONFIG.timeByDifficulty[q.difficulty]) || 60;
    const left = Number(quiz.qTimeLeft) || 0;

    if (!Array.isArray(quiz.timeSpent)) {
      quiz.timeSpent = new Array(quiz.questions.length).fill(0);
    }
    quiz.timeSpent[quiz.index] = Math.max(0, Math.min(allowed, allowed - left));

    stopPracticeQuestionTimer();

    const nextIndex = quiz.index + 1;

    if (nextIndex >= quiz.questions.length) {
      quiz._submitInFlight = false;
      finishPractice();
      return;
    }

    quiz.index = nextIndex;
    const nextQ = quiz.questions[quiz.index];
    quiz.qTimeLeft = Number(nextQ.timeLimitSec) || PRACTICE_CONFIG.timeByDifficulty[nextQ.difficulty] || 60;
    quiz.qEndsAtMs = null;

    saveState();
    renderPracticeQuiz();
    startPracticeQuestionTimer();
  } catch (e) {
    try {
      trackEvent("practice_submit_crash", {
        message: String(e?.message || e || "unknown"),
        subject_key: quiz?.subjectKey || null,
        index: Number(quiz?.index || 0)
      });
    } catch {}

    try { console.error("[practice] handlePracticeSubmit crash:", e); } catch {}
    showToast(t("save_failed_try_again"));
  } finally {
    releaseSubmitLock();
  }
}

  function finishPractice() {
  const quiz = state.quiz;
  if (!quiz || quiz.mode !== "practice") return;
  if (quiz._finishing) return;

  quiz._finishing = true;

  try {
    stopPracticeQuestionTimer();

    // duration excluding pauses
    const finishedAt = Date.now();
    const startedAt = quiz.startedAt || finishedAt;
    const durationMs = Math.max(0, finishedAt - startedAt - (quiz.pausedTotalMs || 0));
    const durationSec = Math.round(durationMs / 1000);

    const total = Array.isArray(quiz.questions) ? quiz.questions.length : 0;
    const score = Array.isArray(quiz.correct) ? quiz.correct.filter(Boolean).length : 0;
    const percent = total ? Math.round((score / total) * 100) : 0;

    // ✅ DRILL mini-result for My Recs (no DB, no last-practice overwrite)
try {
  if (quiz?.drillType && (quiz.drillType === "rec_mistakes" || quiz.drillType === "rec_topic")) {
    if (!state.courses) state.courses = {};
    state.courses.myRecDrillLast = {
      subjectKey: quiz.subjectKey || null,
      topic: quiz.recTopic || null,
      subtopic: quiz.recSubtopic || null,
      drillType: quiz.drillType,
      score,
      total,
      percent,
      ts: Date.now()
    };
    saveState();
  }
} catch {}
     
    // Build details for review/recs
     if (!Array.isArray(quiz.timeSpent)) quiz.timeSpent = new Array(quiz.questions.length).fill(0);
    const details = quiz.questions.map((q, i) => {
      const ua = quiz.answers[i];
      let correctDisplay = "";
      let userDisplay = "";

      if (q.type === "mcq") {
        correctDisplay = (q.options && q.options[q.correctIndex] != null) ? q.options[q.correctIndex] : String(q.correctIndex);
        userDisplay = (ua === null || ua === undefined)
          ? ""
          : ((q.options && q.options[Number(ua)] != null) ? q.options[Number(ua)] : String(ua));
      } else {
        correctDisplay = String(q.correctAnswer ?? "");
        userDisplay = String(ua ?? "").trim();
      }

         return {
     id: q.id,
     topic: q.topic || (t("topic_general") || "General"),
     subtopic: q.subtopic || null,
     difficulty: q.difficulty,
     type: q.type,
     question: q.question,
     userAnswer: userDisplay,
     correctAnswer: correctDisplay,
     isCorrect: !!quiz.correct[i],
     timeSpent: Number(quiz.timeSpent[i]) || 0,
     explanation: q.explanation || "",
     book_id: q.book_id || q.bookId || null,
     book_reference: String(q.book_reference || q.bookReference || q.book_ref || q.bookRef || "").trim() || null,
     book_ref: String(q.book_ref || q.bookReference || q.book_reference || q.bookRef || "").trim() || null
   };
 });

     const attempt = {
  ts: finishedAt,
  attemptKey: String(finishedAt),
  subjectKey: quiz.subjectKey,
  practiceTourNo: Number(quiz.practiceTourNo || 1),
  practicePoolId: Number(quiz.practicePoolId || 0) || null,
  score,
  total,
  percent,
  durationSec,
  details
};

    // ✅ Save "My recommendations" + sync to DB right here (always, no UI dependency)
    try {
      // only for main practice (do NOT generate new recs from drill sessions)
      if (!quiz?.drillType) {
        const res = addMyRecsFromAttempt(attempt);

        if (res?.added) {
          // optional UX toast (keep existing behavior)
          try { showToast(t("practice_saved_to_my_recs")); } catch {}

          // ✅ write recs into DB (non-blocking)
          try {
            syncMyRecsToSupabase(attempt.subjectKey, res.addedRecs || res.recs || []);
          } catch {}
        }
      }
    } catch {}

    // ---------------------------
    // Earned Credentials — events + realtime evaluation
    // ---------------------------
    const subject_id = normSubjectId(attempt.subjectKey);
    const attempt_key = String(attempt.ts || finishedAt);

   const ev = trackEvent(quiz?.drillType ? "practice_drill_finished" : "practice_attempt_finished", {
  subject_id,
  score: attempt.score,
  percent: attempt.percent,
  time_seconds: attempt.durationSec,
  attempt_key,
  drill_type: quiz?.drillType || null
});

// state for result/review/recs screens
// ✅ new main attempt must NEVER inherit stale db attemptId from previous subject/attempt
if (!quiz?.drillType) {
  state.practiceLastAttempt = {
    ...(attempt || {}),
    db: null
  };
}

// ✅ DB-first: save attempt + answers to Supabase (non-blocking UX)
(async () => {
  try {
    let res = { ok: true, reason: quiz?.drillType ? "drill_no_db" : "not_started" };

    if (!quiz?.drillType) {
      try {
        trackEvent("practice_db_save_started", {
          subject_key: quiz?.subjectKey || null,
          attempt_key,
          score: attempt?.score ?? null,
          percent: attempt?.percent ?? null
        });
      } catch {}

      res = await savePracticeAttemptToSupabase(attempt, quiz);

      if (res?.ok) {
        clearPracticeDraft();
        try {
          refreshLiveProgressSurfaces();
        } catch {}
      } else {
        enqueuePendingOp({
          type: "practice_save",
          payload: buildPracticeSavePayload(attempt, quiz)
        });
      }

      try {
        trackEvent("practice_db_save_result", {
          ok: !!res?.ok,
          reason: res?.reason || null,
          attempt_id: res?.attemptId ?? null,
          subject_id_db: res?.subjectId ?? null,
          subject_key: quiz?.subjectKey || null,
          attempt_key
        });
      } catch {}

      const currentAttemptKey = String(state?.practiceLastAttempt?.attemptKey || "");
      const resultAttemptKey = String(attempt?.attemptKey || "");

      if (currentAttemptKey && resultAttemptKey && currentAttemptKey === resultAttemptKey) {
        state.practiceLastAttempt = {
          ...(state.practiceLastAttempt || attempt || {}),
          db: res
        };
      }
    }
  } catch (e) {
    // DEBUG 3: crash (must show in app_events no matter what)
    try {
      trackEvent("practice_db_save_crash", {
        message: String(e?.message || e || "unknown"),
        subject_key: quiz?.subjectKey || null,
        attempt_key
      });
    } catch {}

    try {
      const uid = await getAuthUid();
      await logDbErrorToEvents(uid, "savePracticeAttemptToSupabase_crash", e, { attempt_key, subject_key: quiz?.subjectKey || null });
    } catch {}
  }
})();

    // Unlock
    state.quizLock = null;
    state.quiz = null;
    saveState();

    // Render result
    const meta = $("#practice-result-meta");

const wrong = attempt.details.filter(d => !d.isCorrect);
const recKeys = Array.from(new Set(
  wrong.map(d => {
    const topic = String(d?.topic || t("topic_general") || "General").trim();
    const subtopic = d?.subtopic ? String(d.subtopic).trim() : "";
    return `${topic}::${subtopic}`;
  })
));

if (meta) {
  const scoreLabel = t("archive_score_label") || "Результат";
  const timeLabel = t("archive_time_label") || "Время";
  const secSuffix = t("practice_time_sec_suffix") || "с";

  meta.textContent =
    `${scoreLabel}: ${attempt.score}/${attempt.total} (${attempt.percent}%)` +
    ` • ${timeLabel}: ${attempt.durationSec}${secSuffix}` +
    ` • ${t("practice_errors")}: ${wrong.length}` +
    ` • ${t("practice_topics")}: ${recKeys.length}`;
}

const reviewCountEl = $("#practice-review-count");
if (reviewCountEl) reviewCountEl.textContent = String(wrong.length);

const recsCountEl = $("#practice-recs-count");
if (recsCountEl) recsCountEl.textContent = String(recKeys.length);

// ✅ set “exit” button label based on context (main vs drill)
try {
  const exitKey =
  (quiz?.drillType && quiz.drillType !== "past_tours")
    ? "practice_to_recs"
    : "practice_to_subject";

  const btn1 = $("#practice-to-subject-btn");
  const btn2 = $("#practice-review-to-subject-btn");
  const btn3 = $("#practice-recs-to-subject-btn");

  if (btn1) btn1.textContent = t(exitKey);
  if (btn2) btn2.textContent = t(exitKey);
  if (btn3) btn3.textContent = t(exitKey);
} catch {}
     
      // Show result screen (replace quiz screen to avoid "dead" back navigation)
if (quiz?.drillType) replaceCoursesTop("practice-result");
else replaceCourses("practice-result");

// ✅ remember which attempt should be used by Result/Review (main vs drill)
state.courses = state.courses || {};
state.courses.practiceContext = quiz?.drillType ? "drill" : "main";

// ✅ store drill attempt separately (must NOT overwrite main practice last attempt)
if (quiz?.drillType) {
  state.practiceLastDrillAttempt = attempt;
} else {
  state.practiceLastDrillAttempt = null;
}

saveState();

      // Save best + last 5 (ONLY for main practice; drills must not affect Subject Hub stats)
let hx = null;
if (!quiz?.drillType) {
  try {
    hx = updatePracticeHistory(
      quiz.subjectKey,
      Number(quiz.practiceTourNo || 1),
      attempt
    );
  } catch (e) {
    try { trackEvent("practice_history_error", { message: String(e?.message || e || "unknown") }); } catch {}
  }

  // Optional: toast best update
  if (hx && hx.best && hx.best.ts === attempt.ts) {
    showToast(t("practice_best_new_toast") || "Новый лучший результат");
  }

  // badges / subject widgets rely on main practice only
  syncPracticeResultBadges(attempt);
  refreshLiveProgressSurfaces();
}

  } catch (e) {
    try {
      trackEvent("practice_finish_crash", {
        message: String(e?.message || e || "unknown"),
        subject_key: quiz?.subjectKey || null,
        attempt_key: String(quiz?.attemptKey || "")
      });
    } catch {}

    try { console.error("[practice] finishPractice crash:", e); } catch {}

    if (state.quiz === quiz) {
      quiz._finishing = false;
      quiz._submitInFlight = false;
      updatePracticeSubmitEnabled();
    }

    showToast(t("save_failed_try_again"));
   }
 }

function renderPracticeReview() {
  const wrap = $("#practice-review-list");
  if (!wrap) return;

  const ctx = state?.courses?.practiceContext || "main";
const attempt =
  (ctx === "drill" && state.practiceLastDrillAttempt)
    ? state.practiceLastDrillAttempt
    : state.practiceLastAttempt;

  // Earned Credentials — review opened (for Error-Driven cycle)
  if (attempt && attempt.ts) {
    const subject_id = attempt.subjectKey ? String(attempt.subjectKey) : "";
    const attempt_key = String(attempt.ts);
    const ev = trackEvent("practice_review_opened", { subject_id, attempt_key });
    onPracticeReviewOpened(attempt_key, ev?.id);
  }

  // Helper: render from "details" array in one place
  const renderFromDetails = (details) => {
    if (!Array.isArray(details) || !details.length) {
  wrap.innerHTML = `<div class="empty muted">${escapeHTML(t("practice_review_empty"))}</div>`;
  return;
}

    // Group by topic
    const byTopic = new Map();
    details.forEach((d, idx) => {
      const topic = d.topic || "General";
      if (!byTopic.has(topic)) byTopic.set(topic, []);
      byTopic.get(topic).push({ ...d, _idx: idx });
    });

    // Sort topics: topics with more wrong first, then alphabetically
    const topics = Array.from(byTopic.keys()).sort((a, b) => {
      const wa = byTopic.get(a).filter(x => !x.isCorrect).length;
      const wb = byTopic.get(b).filter(x => !x.isCorrect).length;
      if (wb !== wa) return wb - wa;
      return String(a).localeCompare(String(b));
    });

    wrap.innerHTML = "";

    topics.forEach((topic, tIndex) => {
      const items = byTopic.get(topic);
      const wrongCount = items.filter(x => !x.isCorrect).length;
      const totalCount = items.length;

      const block = document.createElement("div");
      block.className = "card";
      block.style.marginBottom = "10px";

      const head = document.createElement("button");
      head.type = "button";
      head.className = "btn";
      head.style.width = "100%";
      head.style.display = "flex";
      head.style.justifyContent = "space-between";
      head.style.alignItems = "center";
      head.style.gap = "10px";
      head.style.padding = "12px 12px";
      head.style.borderRadius = "16px";

            const left = document.createElement("div");
      left.style.textAlign = "left";

      const questionsLabel = t("tours_fact_questions") || "Вопросов";
      const errorsLabel = t("practice_errors") || "Ошибок";

      left.innerHTML = `
        <div style="font-weight:900">${escapeHTML(topic)}</div>
        <div class="muted small">${escapeHTML(questionsLabel)}: ${totalCount} • ${escapeHTML(errorsLabel)}: ${wrongCount}</div>
      `;

      const right = document.createElement("div");
      right.className = "badge badge-pin";
      right.textContent = wrongCount ? `❌ ${wrongCount}` : `✅ 0`;

      head.appendChild(left);
      head.appendChild(right);

      const body = document.createElement("div");
      body.style.marginTop = "10px";
      body.style.display = (tIndex === 0) ? "block" : "none"; // первая тема раскрыта
      body.dataset.open = (tIndex === 0) ? "1" : "0";

      head.addEventListener("click", () => {
        const open = body.dataset.open === "1";
        body.dataset.open = open ? "0" : "1";
        body.style.display = open ? "none" : "block";
      });

      // Render questions inside topic
      items.forEach(d => {
        const row = document.createElement("div");
        row.className = "list-item";
        row.style.marginBottom = "10px";

        const status = d.isCorrect ? "✅" : "❌";
        const n = d._idx + 1;

               // ✅ pretty answers: convert MCQ indexes to letters, but keep INPUT answers as-is
let userDisp = "";
let corrDisp = "";
try {
  const qForFmt = {
    qtype: d.type,
    type: d.type,
    // formatAnswerForDisplay reads options_text; we pass options as JSON
    options_text: Array.isArray(d.options) ? JSON.stringify(d.options) : (d.options_text || null),
    options_text_ru: Array.isArray(d.options) ? JSON.stringify(d.options) : (d.options_text_ru || null),
    options_text_uz: Array.isArray(d.options) ? JSON.stringify(d.options) : (d.options_text_uz || null),
    options_text_en: Array.isArray(d.options) ? JSON.stringify(d.options) : (d.options_text_en || null)
  };
  userDisp = formatAnswerForDisplay(qForFmt, d.userAnswer);
  corrDisp = formatAnswerForDisplay(qForFmt, d.correctAnswer);
} catch {
  userDisp = String(d.userAnswer || "—");
  corrDisp = String(d.correctAnswer || "—");
}
         
const diffKey = `difficulty_${String(d.difficulty || "").toLowerCase()}`;
const diffText = t(diffKey) || d.difficulty || "";
const yourAnsLabel = t("your_answer") || "Ваш ответ";
const correctLabel = t("correct_answer") || "Правильно";
const explLabel = t("rec_show_expl") || "Объяснение";

const topicText = String(d.topic || t("topic_general") || "General").trim();
const subtopicText = String(d.subtopic || "").trim();

row.innerHTML = `
  <div style="font-weight:900">${status} ${n}. ${escapeHTML(topicText)}</div>
  ${subtopicText ? `<div class="muted small" style="margin-top:4px">${escapeHTML(subtopicText)}</div>` : ``}
  ${diffText ? `<div class="muted small" style="margin-top:4px">${escapeHTML(diffText)}</div>` : ``}
  <div class="muted small" style="margin-top:8px">${escapeHTML(d.question || "")}</div>

  <div class="muted small" style="margin-top:8px">
    ${escapeHTML(yourAnsLabel)}: <b>${escapeHTML(userDisp || "—")}</b>
  </div>
  <div class="muted small">
    ${escapeHTML(correctLabel)}: <b>${escapeHTML(corrDisp || "—")}</b>
  </div>

  ${d.explanation ? `<div class="muted small" style="margin-top:8px"><b>${escapeHTML(explLabel)}:</b> ${escapeHTML(d.explanation)}</div>` : ``}
`;
        body.appendChild(row);
      });

      block.appendChild(head);
      block.appendChild(body);
      wrap.appendChild(block);
    });
  };

     // If we have DB attempt id -> DB-first review
  const dbAttemptId = attempt?.db?.ok ? Number(attempt?.db?.attemptId) : null;

  // First paint: loading
  wrap.innerHTML = `<div class="empty muted">${escapeHTML(t("practice_review_loading_db"))}</div>`;

  // DB-first flow (best-effort)
  (async () => {
    if (!window.sb || !dbAttemptId) {
      const localDetails = Array.isArray(attempt?.details) ? attempt.details : [];
      renderFromDetails(localDetails);
      return;
    }

    showAsyncOverlay(tr3(
      "Загружаем разбор практики…",
      "Amaliyot tahlili yuklanmoqda…",
      "Loading practice review…"
    ));

    try {
      const uid = await getAuthUid();
      if (!uid) {
        const localDetails = Array.isArray(attempt?.details) ? attempt.details : [];
        renderFromDetails(localDetails);
        return;
      }

      // 1) read answers for this attempt
      const { data: ansRows, error: ansErr } = await window.sb
        .from("practice_answers")
        .select("question_id,user_answer,is_correct,time_spent,created_at")
        .eq("attempt_id", dbAttemptId)
        .order("id", { ascending: true });

      if (ansErr) {
        try { trackEvent("practice_review_db_error", { where: "answers_select", attempt_id: dbAttemptId }); } catch {}
        await logDbErrorToEvents(uid, "practice_review_answers_select", ansErr, { attempt_id: dbAttemptId });
        const localDetails = Array.isArray(attempt?.details) ? attempt.details : [];
        renderFromDetails(localDetails);
        return;
      }

      const ids = (ansRows || []).map(r => Number(r.question_id)).filter(n => Number.isFinite(n));
      if (!ids.length) {
        const localDetails = Array.isArray(attempt?.details) ? attempt.details : [];
        renderFromDetails(localDetails);
        return;
      }

      // 2) read questions
      const { data: qRows, error: qErr } = await window.sb
        .from("questions")
        .select("id,topic,subtopic,difficulty,qtype,question_text,options_text,correct_answer,explanation,image_url,question_text_ru,question_text_uz,question_text_en,options_text_ru,options_text_uz,options_text_en,explanation_ru,explanation_uz,explanation_en")
        .in("id", ids)
        .eq("is_active", true);

      if (qErr) {
        try { trackEvent("practice_review_db_error", { where: "questions_select", attempt_id: dbAttemptId }); } catch {}
        await logDbErrorToEvents(uid, "practice_review_questions_select", qErr, { attempt_id: dbAttemptId, ids: ids.length });
        const localDetails = Array.isArray(attempt?.details) ? attempt.details : [];
        renderFromDetails(localDetails);
        return;
      }

      const qMap = new Map((qRows || []).map(q => [Number(q.id), q]));

      const details = (ansRows || []).map((x, idx) => {
        const q = qMap.get(Number(x.question_id)) || {};
        const type = String(q?.qtype || "mcq").toLowerCase() === "input" ? "input" : "mcq";
        const options = parseOptionsText(pickContentText(q, "options_text") || "") || [];

        return {
          id: Number(q?.id || x?.question_id || idx + 1),
          topic: q?.topic || (t("topic_general") || "General"),
          subtopic: q?.subtopic || null,
          difficulty: q?.difficulty || "easy",
          type,
          question: pickContentText(q, "question_text") || "",
          options,
          userAnswer: String(x?.user_answer ?? ""),
          correctAnswer: String(q?.correct_answer ?? ""),
          explanation: pickContentText(q, "explanation") || "",
          isCorrect: !!x?.is_correct,
          timeSpent: Number(x?.time_spent || 0)
        };
      });

      renderFromDetails(details);
    } catch {
      const localDetails = Array.isArray(attempt?.details) ? attempt.details : [];
      renderFromDetails(localDetails);
    } finally {
      hideAsyncOverlay();
    }
   })();
  }

function syncPracticeResultBadges(attemptOverride) {
  const attempt = attemptOverride || state.practiceLastAttempt;
  if (!attempt || !Array.isArray(attempt.details)) return;

  const wrong = attempt.details.filter(d => !d.isCorrect);

  const recKeys = Array.from(new Set(
    wrong.map(d => {
      const topic = String(d?.topic || t("topic_general") || "General").trim();
      const subtopic = d?.subtopic ? String(d.subtopic).trim() : "";
      return `${topic}::${subtopic}`;
    })
  ));

  const reviewCountEl = $("#practice-review-count");
  if (reviewCountEl) reviewCountEl.textContent = String(wrong.length);

  const recsCountEl = $("#practice-recs-count");
  if (recsCountEl) recsCountEl.textContent = String(recKeys.length);
}
 
    function renderPracticeRecs() {
    const wrap = $("#practice-recs-list");
    if (!wrap) return;

    const ctx = state?.courses?.practiceContext || "main";
    const attempt =
      (ctx === "drill" && state.practiceLastDrillAttempt)
        ? state.practiceLastDrillAttempt
        : state.practiceLastAttempt;

    if (!attempt || !Array.isArray(attempt.details)) {
      wrap.innerHTML = `<div class="empty muted">${escapeHTML(t("practice_recs_empty"))}</div>`;
      return;
    }

    const wrong = attempt.details.filter(d => !d.isCorrect);

const uniq = Array.from(new Map(
  wrong.map(d => {
    const topic = String(d?.topic || t("topic_general") || "General").trim();
    const subtopic = d?.subtopic ? String(d.subtopic).trim() : "";
    return [`${topic}::${subtopic}`, { topic, subtopic }];
  })
).values());

if (!uniq.length) {
  wrap.innerHTML = `<div class="empty muted">${escapeHTML(t("practice_recs_no_errors"))}</div>`;
  return;
}

        // v1: если refs пусто — показываем корректный текст:
    // - если книги по предмету есть -> "Книги уже доступны"
    // - если книг нет -> "Будет добавлено позже"
    wrap.innerHTML = `<div class="empty muted">${escapeHTML(t("books_loading") || "Loading…")}</div>`;

    (async () => {
      let booksAvailable = false;

      try {
        if (window.sb) {
          const subjectId = await getSubjectIdByKey(attempt.subjectKey);
          if (subjectId) {
            const { data, error } = await window.sb
              .from("books")
              .select("id")
              .eq("subject_id", subjectId)
              .eq("is_active", true)
              .limit(1);

            if (!error && Array.isArray(data) && data.length) booksAvailable = true;
          }
        }
      } catch {}

     wrap.innerHTML = "";
uniq.forEach(rec => {
  const item = document.createElement("div");
  item.className = "list-item";

    const preferredKey = rec.subtopic || rec.topic;
  const preferredRefs = getReadingRefs(attempt.subjectKey, preferredKey);
  const refs = preferredRefs.length
    ? preferredRefs
    : getReadingRefs(attempt.subjectKey, rec.topic);

  let refsHtml = "";
  if (refs.length) {
    refsHtml = `
      <div class="muted small" style="margin-top:6px">
        ${refs.slice(0, 3).map(r =>
          `• ${escapeHTML(r.title || "")}${r.ref ? ` — ${escapeHTML(r.ref)}` : ""}${r.pages ? ` (${escapeHTML(r.pages)})` : ""}`
        ).join("<br>")}
      </div>
    `;
  }

  const fallbackText = booksAvailable
    ? t("recs_books_available_source")
    : t("recs_books_later_source");
        item.innerHTML = `
  <div style="font-weight:900">${escapeHTML(rec.topic)}</div>
  ${rec.subtopic ? `<div class="muted small" style="margin-top:4px">${escapeHTML(rec.subtopic)}</div>` : ``}
  ${refsHtml || `<div class="muted small" style="margin-top:6px">${escapeHTML(fallbackText)}</div>`}
  <div style="margin-top:10px">
    <button type="button" class="btn" data-open-books="1">${escapeHTML(t("rec_btn_books") || "Книги")}</button>
  </div>
`;

        const btn = item.querySelector('button[data-open-books="1"]');
                btn?.addEventListener("click", async (e) => {
          e.stopPropagation();

          showAsyncOverlay(tr3(
            "Загружаем книги…",
            "Kitoblar yuklanmoqda…",
            "Loading books…"
          ));

          try {
            pushCourses("books");
            await renderBooks();
          } finally {
            hideAsyncOverlay();
          }
        });

        wrap.appendChild(item);
      });
    })();
  }

async function fetchMyRecsDB(subjectKey, seasonIdArg = null) {
  try {
    if (!window.sb) return [];

    const uid = await getAuthUid();
    if (!uid) return [];

    const subjectId = await getSubjectIdByKey(subjectKey);
    if (!subjectId) return [];

    const seasonId =
      Number(seasonIdArg || 0) ||
      await getCurrentSeasonId();

    const practicePromise = window.sb
      .from("recommendations")
      .select(
        "id, source_type, tour_no, season_id, topic, subtopic, book_id, book_reference, created_at"
      )
      .eq("user_id", uid)
      .eq("subject_id", subjectId)
      .eq("source_type", "practice")
      .order("created_at", { ascending: false })
      .limit(100);

    let tourQuery = window.sb
      .from("recommendations")
      .select(
        "id, source_type, tour_no, season_id, topic, subtopic, book_id, book_reference, created_at"
      )
      .eq("user_id", uid)
      .eq("subject_id", subjectId)
      .eq("source_type", "tour")
      .order("created_at", { ascending: false })
      .limit(100);

    if (seasonId > 0) {
      tourQuery = tourQuery.eq("season_id", seasonId);
    } else {
      tourQuery = tourQuery.is("season_id", null);
    }

    const [practiceResult, tourResult] = await Promise.all([
      practicePromise,
      tourQuery
    ]);

    if (practiceResult.error) {
      logClientError(
        "myrecs_practice_select_error",
        practiceResult.error
      );
    }

    if (tourResult.error) {
      logClientError(
        "myrecs_tour_select_error",
        tourResult.error
      );
    }

    const practiceRows =
      !practiceResult.error &&
      Array.isArray(practiceResult.data)
        ? practiceResult.data
        : [];

    const tourRows =
      !tourResult.error &&
      Array.isArray(tourResult.data)
        ? tourResult.data
        : [];

    return [...practiceRows, ...tourRows]
      .sort((a, b) => {
        const aTime = new Date(a?.created_at || 0).getTime();
        const bTime = new Date(b?.created_at || 0).getTime();
        return bTime - aTime;
      });
  } catch (error) {
    logClientError("myrecs_select_exception", error);
    return [];
  }
}


async function renderMyRecs() {
  const wrap = $("#my-recs-list");
  if (!wrap) return;

  const subjectKey = String(state?.courses?.subjectKey || "").trim();
  if (!subjectKey) {
    wrap.innerHTML = `<div class="empty muted">${escapeHTML(t("recommendations_empty") || "Пока рекомендаций нет.")}</div>`;
    return;
  }

  const activeTab = String(state?.courses?.myRecsActiveTab || "practice");

  const selectedSeasonId = await getCurrentSeasonId();
  const seasonOneId = await getSeasonOneId();

  wrap.innerHTML = `<div class="empty muted">${escapeHTML(t("loading") || "Загрузка…")}</div>`;

    // DB-first for both practice and tour
  const dbRows = await fetchMyRecsDB(
    subjectKey,
    selectedSeasonId
  );

  let practiceRows = dbRows.filter(r => String(r?.source_type || "") === "practice");
  let tourRows = dbRows
    .filter(r => String(r?.source_type || "") === "tour")
    .map(r => ({
      ...r,
      seasonId: Number(r?.season_id || 0) || null,
      tourNo: Number(r?.tour_no || 0) || null
    }));

  // PRACTICE fallback
  if (!practiceRows.length) {
    const store = loadMyRecs();
    const local = store?.bySubject?.[subjectKey] || [];
    practiceRows = local.map(x => ({
      id: null,
      source_type: "practice",
      topic: x.topic || "General",
      subtopic: x.subtopic || null,
      book_id: x.book_id || null,
      book_reference: x.book_reference || null,
      created_at: x.ts ? new Date(x.ts).toISOString() : null
    }));
  }

    if (activeTab === "practice" && practiceRows.length) {
    const checks = await Promise.all(
      practiceRows.map(async (rec) => {
        try {
          const mistakes = await fetchRecentMistakesByRec(subjectKey, rec);
          return { rec, keep: Array.isArray(mistakes) && mistakes.length > 0 };
        } catch {
          return { rec, keep: true };
        }
      })
    );

    practiceRows = checks.filter(x => x.keep).map(x => x.rec);
  }
   
  // TOUR fallback only if DB has nothing yet.
  // Legacy rows without seasonId belong to Season 1 only.
  if (!tourRows.length) {
    const tourStore = loadMyTourRecs();
    const localRows =
      tourStore?.bySubject?.[subjectKey] || [];

    tourRows = localRows
      .filter(row => {
        const rowSeasonId = Number(
          row?.seasonId ||
          row?.season_id ||
          0
        );

        if (rowSeasonId > 0) {
          return rowSeasonId === Number(selectedSeasonId || 0);
        }

        return (
          Number(selectedSeasonId || 0) > 0 &&
          Number(selectedSeasonId || 0) ===
            Number(seasonOneId || 0)
        );
      })
      .map(row => ({
        id: null,
        source_type: "tour",
        seasonId:
          Number(
            row?.seasonId ||
            row?.season_id ||
            seasonOneId ||
            0
          ) || null,
        topic: row.topic || "General",
        subtopic: row.subtopic || null,
        book_id: row.book_id || null,
        book_reference: row.book_reference || null,
        created_at: row.ts
          ? new Date(row.ts).toISOString()
          : null,
        tourNo: Number(row.tourNo || 0) || null
      }));
  }

  try {
    const shouldSyncTourRows = tourRows.length && (
      !dbRows.some(r => String(r?.source_type || "") === "tour") ||
      tourRows.some(r => !String(r?.book_reference || "").trim())
    );

    if (shouldSyncTourRows) {
      const bySeasonAndTour = new Map();

      tourRows.forEach(row => {
        const tourNo = Number(row?.tourNo || 0) || 0;
        const seasonId =
          Number(
            row?.seasonId ||
            row?.season_id ||
            selectedSeasonId ||
            0
          ) || 0;

        if (!tourNo || !seasonId) return;

        const key = `${seasonId}:${tourNo}`;

        if (!bySeasonAndTour.has(key)) {
          bySeasonAndTour.set(key, {
            seasonId,
            tourNo,
            rows: []
          });
        }

        bySeasonAndTour.get(key).rows.push(row);
      });

      for (const group of bySeasonAndTour.values()) {
        await saveTourRecsToDB(
          subjectKey,
          group.tourNo,
          group.rows,
          group.seasonId
        );
      }
    }
  } catch {}
  const hasPractice = practiceRows.length > 0;
  const hasTour = tourRows.length > 0;

  if (!hasPractice && !hasTour) {
    wrap.innerHTML = `<div class="empty muted">${escapeHTML(t("recommendations_empty") || "Пока рекомендаций нет.")}</div>`;
    return;
  }

  const tabBtn = (key, label, isActive) => `
    <button
      type="button"
      class="btn ${isActive ? "primary" : ""}"
      data-myrecs-tab="${escapeHTML(key)}"
      style="flex:1 1 0"
    >
      ${escapeHTML(label)}
    </button>
  `;

  const renderPracticeList = () => {
    if (!practiceRows.length) {
      return `<div class="empty muted">${escapeHTML(t("my_recs_practice_empty") || "Рекомендаций по практике пока нет.")}</div>`;
    }

    return practiceRows.map(rec => {
      const dt = rec.created_at ? formatDateTime(rec.created_at) : "";
      const sub = rec.subtopic ? String(rec.subtopic) : "";
      const bookRef = String(rec.book_reference || "").trim();

      return `
        <div class="list-item" data-open-rec="practice">
          <div style="font-weight:900">${escapeHTML(rec.topic || "General")}</div>
          ${sub ? `<div class="muted small" style="margin-top:4px">${escapeHTML(sub)}</div>` : ""}
          ${bookRef ? `<div class="muted small" style="margin-top:4px">📘 ${escapeHTML(bookRef)}</div>` : ""}
          <div class="muted small" style="margin-top:4px">${escapeHTML(t("saved_at_label") || "Сохранено")}: ${escapeHTML(dt)}</div>
        </div>
      `;
    }).join("");
  };

  const renderTourList = () => {
    if (!tourRows.length) {
      return `<div class="empty muted">${escapeHTML(t("my_recs_tour_empty") || "Рекомендаций по турам пока нет.")}</div>`;
    }

    const groups = new Map();
    tourRows.forEach(rec => {
      const key = Number(rec.tourNo || 0) || 0;
      if (!groups.has(key)) groups.set(key, []);
      groups.get(key).push(rec);
    });

    const orderedKeys = Array.from(groups.keys()).sort((a, b) => b - a);

    return orderedKeys.map(tourNo => {
      const items = groups.get(tourNo) || [];
      const title = tourNo > 0
        ? `${t("tours_tour_label") || "Тур"} ${tourNo}`
        : (t("tour_label_generic") || "Тур");

      const cards = items.map(rec => {
        const dt = rec.created_at ? formatDateTime(rec.created_at) : "";
        const sub = rec.subtopic ? String(rec.subtopic) : "";

               return `
          <div
            class="list-item"
            data-open-rec="tour"
            data-rec-id="${escapeHTML(String(rec.id || ""))}"
            data-tour-no="${escapeHTML(String(tourNo || 0))}"
            data-season-id="${escapeHTML(String(rec.seasonId || rec.season_id || selectedSeasonId || ""))}"
            data-topic="${escapeHTML(rec.topic || "")}"
            data-subtopic="${escapeHTML(sub)}"
            data-created-at="${escapeHTML(rec.created_at || "")}"
            data-book-reference="${escapeHTML(String(rec.book_reference || ""))}"
          >
            <div style="font-weight:900">${escapeHTML(rec.topic || "General")}</div>
            ${sub ? `<div class="muted small" style="margin-top:4px">${escapeHTML(sub)}</div>` : ""}
            <div class="muted small" style="margin-top:4px">${escapeHTML(t("saved_at_label") || "Сохранено")}: ${escapeHTML(dt)}</div>
          </div>
        `;
      }).join("");

      return `
        <div class="list-item" style="padding-bottom:10px">
          <div style="font-weight:900">${escapeHTML(title)}</div>
        </div>
        ${cards}
      `;
    }).join("");
  };

  wrap.innerHTML = `
    <div style="display:flex;gap:10px;margin-bottom:12px">
      ${tabBtn("practice", t("my_recs_tab_practice") || "Практика", activeTab === "practice")}
      ${tabBtn("tour", t("my_recs_tab_tour") || "Туры", activeTab === "tour")}
    </div>
    ${activeTab === "tour" ? renderTourList() : renderPracticeList()}
  `;

  wrap.querySelectorAll("[data-myrecs-tab]").forEach(btn => {
    btn.addEventListener("click", async () => {
      state.courses = state.courses || {};
      state.courses.myRecsActiveTab = String(btn.getAttribute("data-myrecs-tab") || "practice");
      saveState();
      await renderMyRecs();
    });
  });

  if (activeTab === "practice") {
    const cards = Array.from(wrap.querySelectorAll('[data-open-rec="practice"]'));
    cards.forEach((el, idx) => {
      const rec = practiceRows[idx];
      el.addEventListener("click", async () => {
        state.courses.myRecCurrent = rec;
        saveState();
        pushCourses("my-rec-detail");
        await renderMyRecDetail();
      });
    });
    return;
  }

   wrap.querySelectorAll('[data-open-rec="tour"]').forEach(el => {
    el.addEventListener("click", async () => {
      const tourNo = Number(
        el.getAttribute("data-tour-no") || 0
      );

      const seasonId = Number(
        el.getAttribute("data-season-id") || 0
      ) || null;

      const rec = {
        id: el.getAttribute("data-rec-id")
          ? Number(el.getAttribute("data-rec-id"))
          : null,
        source_type: "tour",
        seasonId,
        topic: String(el.getAttribute("data-topic") || "").trim() || "General",
        subtopic: String(el.getAttribute("data-subtopic") || "").trim() || null,
        created_at: String(el.getAttribute("data-created-at") || "").trim() || null,
        book_reference: String(el.getAttribute("data-book-reference") || "").trim() || null,
        tourNo
      };

      const canOpen = tourNo > 0
        ? await isTourGloballyClosed(
            subjectKey,
            tourNo,
            seasonId
          )
        : false;

      if (!canOpen) {
        showToast(
          t("tour_rec_locked_until_global_end") ||
          "Рекомендации по этому туру будут доступны после завершения тура для всех участников."
        );
        return;
      }

      state.courses.myRecCurrent = rec;
      saveState();
      pushCourses("my-rec-detail");
      await renderMyRecDetail();
    });
  });
}
   async function fetchRecentMistakesByRec(subjectKey, rec) {
  try {
    if (!window.sb) return [];

    const uid = await getAuthUid();
    if (!uid) return [];

    const subjectId = await getSubjectIdByKey(subjectKey);
    if (!subjectId) return [];

    // 1) последние попытки практики пользователя по предмету
    const { data: attempts, error: aErr } = await window.sb
      .from("practice_attempts")
      .select("id, created_at")
      .eq("user_id", uid)
      .eq("subject_id", subjectId)
      .order("created_at", { ascending: false })
      .limit(12);

    if (aErr || !Array.isArray(attempts) || !attempts.length) return [];

    const attemptIds = attempts.map(x => x.id);

    // 2) неправильные ответы + вопрос
    const { data: ans, error: pErr } = await window.sb
      .from("practice_answers")
      .select("id, attempt_id, question_id, user_answer, is_correct, created_at, question:questions(id, topic, subtopic, question_text, options_text, correct_answer, explanation, qtype, difficulty, is_active, question_text_ru, question_text_uz, question_text_en, options_text_ru, options_text_uz, options_text_en, explanation_ru, explanation_uz, explanation_en)")
      .in("attempt_id", attemptIds)
      .eq("is_correct", false)
      .order("created_at", { ascending: false })
      .limit(150);

    if (pErr || !Array.isArray(ans)) return [];

        const norm = (v) => String(v || "").trim().toLowerCase();

    const topic = norm(rec?.topic);
    const subtopic = rec?.subtopic ? norm(rec.subtopic) : "";

            const cleaned = ans
      .map(x => ({ ...x, q: x.question }))
      .filter(x => x.q && x.q.is_active)
      .filter(x => {
        const q = x.q;
        const qType = String(q.qtype || "mcq").toLowerCase();

        // Для input/других типов оставляем как есть
        if (qType !== "mcq") return true;

        const uaRaw = String(x.user_answer ?? "").trim();
        const caRaw = String(q.correct_answer ?? "").trim();

        const toIdx = (raw) => {
          if (!raw) return null;
          if (isNumericLike(raw)) return Math.trunc(Number(raw));
          const li = letterToIdx(raw);
          return (li !== null && li >= 0) ? li : null;
        };

        const uaIdx = toIdx(uaRaw);
        const caIdx = toIdx(caRaw);

        // Если оба значения распознаны и они совпадают — такую "ошибку" не показываем
        if (uaIdx !== null && caIdx !== null && uaIdx === caIdx) return false;

        const uaDisp = formatAnswerForDisplay(q, x.user_answer);
        const caDisp = formatAnswerForDisplay(q, q.correct_answer);

        // Дополнительная защита на уровне отображения
        if (uaDisp && caDisp && uaDisp === caDisp) return false;

        return true;
      });

    const base = cleaned
      .filter(x => {
        const qt = norm(x.q.topic);
        return topic ? qt === topic : true;
      });

    const exact = subtopic
      ? base.filter(x => norm(x.q.subtopic) === subtopic).slice(0, 10)
      : [];

    const filtered = exact.length
      ? exact
      : base.slice(0, 10);

    return filtered;
  } catch (e) {
    logClientError("myrec_mistakes_exception", e);
    return [];
  }
}

async function fetchBookRefsForRec(subjectKey, rec) {
  // приоритет:
  // 1) то, что уже записано в recommendations (последние патчи)
  // 2) topic_book_map (если есть)
  const direct = [];
  if (rec?.book_id || rec?.book_reference) {
    direct.push({
      book_id: rec.book_id || null,
      book_reference: rec.book_reference || null,
      title: null,
      file_url: null
    });
  }

  try {
    if (!window.sb) return direct;

    const subjectId = await getSubjectIdByKey(subjectKey);
    if (!subjectId) return direct;

    let maps = [];
let mErr = null;

// 1) exact: topic + subtopic
if (rec.subtopic) {
  const exactQ = await window.sb
    .from("topic_book_map")
    .select("book_id, book_reference, priority")
    .eq("subject_id", subjectId)
    .eq("topic", rec.topic)
    .eq("subtopic", rec.subtopic)
    .eq("is_active", true)
    .order("priority", { ascending: true })
    .limit(5);

  maps = Array.isArray(exactQ.data) ? exactQ.data : [];
  mErr = exactQ.error || null;
}

// 2) fallback: topic only
if (!maps.length) {
  const baseQ = await window.sb
    .from("topic_book_map")
    .select("book_id, book_reference, priority")
    .eq("subject_id", subjectId)
    .eq("topic", rec.topic)
    .eq("is_active", true)
    .order("priority", { ascending: true })
    .limit(5);

  maps = Array.isArray(baseQ.data) ? baseQ.data : [];
  mErr = mErr || baseQ.error || null;
}

if (mErr || !maps.length) return direct;

    const bookIds = Array.from(new Set(maps.map(m => m.book_id).filter(Boolean)));
    let books = [];
    if (bookIds.length) {
      const { data: b, error: bErr } = await window.sb
        .from("books")
        .select("id, title, file_url")
        .in("id", bookIds)
        .eq("is_active", true);
      if (!bErr && Array.isArray(b)) books = b;
    }
    const byId = new Map(books.map(x => [String(x.id), x]));

    const mapped = maps.map(m => {
      const bk = m.book_id ? byId.get(String(m.book_id)) : null;
      return {
        book_id: m.book_id || null,
        book_reference: m.book_reference || null,
        title: bk?.title || null,
        file_url: bk?.file_url || null
      };
    });

    // merge unique
    const all = [...direct, ...mapped];
    const seen = new Set();
    return all.filter(x => {
      const k = `${x.book_id || ""}::${x.book_reference || ""}`;
      if (seen.has(k)) return false;
      seen.add(k);
      return true;
    });
  } catch (e) {
    logClientError("myrec_refs_exception", e);
    return direct;
  }
}

async function renderMyRecDetail() {
  const rec = state?.courses?.myRecCurrent;
  const subjectKey = state?.courses?.subjectKey;
  const body = $("#my-rec-body");
  const titleEl = $("#my-rec-title");
  const subEl = $("#my-rec-subtitle");
  if (!body || !rec || !subjectKey) return;

  const isTourRec = String(rec?.source_type || "practice") === "tour";
  const topic = rec.topic || "General";
  const subtopic = rec.subtopic ? String(rec.subtopic) : "";

     const recText = {
    subtitlePractice: tc3(
      "Персональный разбор и план",
      "Shaxsiy tahlil va reja",
      "Personal review and plan"
    ),
    subtitleTour: tc3(
      "Рекомендации по итогам тура",
      "Tur yakunlari bo‘yicha tavsiyalar",
      "Recommendations based on the tour"
    ),
    resultTitle: tc3(
      "Результат",
      "Natija",
      "Result"
    ),
    resultRepeat: tc3(
      "Повторить ещё раз",
      "Yana bir bor",
      "Repeat again"
    ),
    mistakesTitle: tc3(
      "Ошибки по теме",
      "Mavzu bo‘yicha xatolar",
      "Mistakes by topic"
    ),
    mistakesSubtitle: tc3(
      "Ваши последние неправильные ответы по этой теме.",
      "Ushbu mavzu bo‘yicha so‘nggi noto‘g‘ri javoblaringiz.",
      "Your latest incorrect answers on this topic."
    ),
    mistakeCardTitle: tc3(
      "Ошибка",
      "Xato",
      "Mistake"
    ),
    yourAnswer: tc3(
      "Ваш ответ",
      "Sizning javobingiz",
      "Your answer"
    ),
    correctAnswer: tc3(
      "Правильный",
      "To‘g‘ri javob",
      "Correct"
    ),
    explanation: tc3(
      "Пояснение",
      "Izoh",
      "Explanation"
    ),
    noMistakes: tc3(
      "По этой теме пока нет зафиксированных ошибок.",
      "Bu mavzu bo‘yicha hozircha xatolar qayd etilmagan.",
      "No mistakes recorded for this topic yet."
    ),
    bookFallback: tc3(
      "Книга",
      "Kitob",
      "Book"
    ),
    openBook: tc3(
      "Открыть",
      "Ochish",
      "Open"
    )
  };

   if (titleEl) titleEl.textContent = topic;
if (subEl) {
  subEl.textContent = isTourRec
    ? (subtopic || recText.subtitleTour)
    : (subtopic ? subtopic : recText.subtitlePractice);
}

   // ✅ mini result (only for current rec/topic)
let drillMiniHtml = "";
try {
  const d = state?.courses?.myRecDrillLast;
  const same =
  d &&
  String(d.subjectKey || "") === String(subjectKey || "") &&
  String(d.topic || "") === String(rec?.topic || "") &&
  String(d.subtopic || "") === String(rec?.subtopic || "") &&
  (d.drillType === "rec_mistakes" || d.drillType === "rec_topic");

  if (same) {
    const line = (t("rec_drill_mini_line") || "{score}/{total} • {percent}%")
      .replace("{score}", String(d.score))
      .replace("{total}", String(d.total))
      .replace("{percent}", String(d.percent));

    drillMiniHtml = `
      <div class="list-item" style="margin-top:10px">
        <div style="font-weight:900">${escapeHTML(recText.resultTitle)}</div>
        <div class="muted small" style="margin-top:6px">${escapeHTML(line)}</div>
        <div style="margin-top:10px">
          <button class="btn" type="button" data-action="my-rec-repeat-drill">
            ${escapeHTML(recText.resultRepeat)}
          </button>
        </div>
      </div>
    `;
  }
} catch {}
   
    body.innerHTML = `<div class="empty muted">${escapeHTML(t("my_rec_loading") || "Загрузка…")}</div>`;

  const refs = await fetchBookRefsForRec(subjectKey, rec);

  let mistakes = [];
  if (!isTourRec) {
    mistakes = await fetchRecentMistakesByRec(subjectKey, rec);

    state.courses.myRecMistakeQids = Array.isArray(mistakes)
      ? Array.from(new Set(mistakes.map(m => m?.q?.id).filter(Boolean))).slice(0, 10)
      : [];
    saveState();
  } else {
    state.courses.myRecMistakeQids = [];
    saveState();
  }

   const totalMistakes = Array.isArray(mistakes) ? mistakes.length : 0;

// ✅ Header (with total count) — always shown
const mistakesHeaderHtml = `
  <div class="list-item" style="margin-top:10px">
    <div style="display:flex;align-items:center;justify-content:space-between;gap:10px">
      <div style="font-weight:900">${escapeHTML(recText.mistakesTitle)}</div>
      <span class="pill">${escapeHTML(String(totalMistakes))}</span>
    </div>
    <div class="muted small" style="margin-top:6px">
      ${escapeHTML(recText.mistakesSubtitle)}
    </div>
  </div>
`;
     
const mistakesHtml = totalMistakes
  ? mistakes.map((x, idx) => {
      const q = x.q;
      const qText = pickContentText(q, "question_text");
      const expl = pickContentText(q, "explanation");

      const uaDisp = formatAnswerForDisplay(q, x.user_answer);
      const caDisp = formatAnswerForDisplay(q, q.correct_answer);

      const num = `${idx + 1}/${totalMistakes}`;

      return `
        <div class="list-item">
          <div style="display:flex;align-items:center;justify-content:space-between;gap:10px">
            <div style="font-weight:900">${escapeHTML(recText.mistakeCardTitle)}</div>
            <span class="pill">${escapeHTML(num)}</span>
          </div>

          <div style="margin-top:6px">${escapeHTML(qText || "")}</div>

          <div class="muted small" style="margin-top:8px">
            ${escapeHTML(recText.yourAnswer)}: ${escapeHTML(uaDisp)}
          </div>

          <div class="muted small">
            ${escapeHTML(recText.correctAnswer)}: ${escapeHTML(caDisp)}
          </div>

          ${expl ? `
            <details style="margin-top:10px">
              <summary class="muted small" style="cursor:pointer;font-weight:800">
                ${escapeHTML(recText.explanation)}
              </summary>
              <div class="muted small" style="margin-top:8px">${escapeHTML(expl)}</div>
            </details>
          ` : ""}
        </div>
      `;
    }).join("")
  : `
    <div class="list-item">
      <div class="muted small" style="font-weight:800">
        ${escapeHTML(recText.noMistakes)}
      </div>
    </div>
  `;
   
        const refsHtml = refs.length
  ? refs.map(r => {
      const title = r.title
  ? escapeHTML(r.title)
  : (r.book_id ? `${escapeHTML(recText.bookFallback)} #${escapeHTML(String(r.book_id))}` : escapeHTML(recText.bookFallback));
      const ref = r.book_reference ? `• ${escapeHTML(String(r.book_reference))}` : "";
      const has = !!r.file_url;
      return `
        <div class="list-item">
          <div style="font-weight:900">${title}</div>
          ${ref ? `<div class="muted small" style="margin-top:6px">${ref}</div>` : ""}
          ${has ? `<div style="margin-top:10px"><button class="btn" type="button" data-open-book-url="${escapeHTML(r.file_url)}">${escapeHTML(recText.openBook)}</button></div>` : ""}
        </div>
      `;
    }).join("")
  : ``;
   
    const readBlockHtml = refs.length ? `
  <div class="list-item">
    <div style="font-weight:900">
      ${escapeHTML(t("rec_read_title") || "Что прочитать")}
    </div>
    <div class="muted small" style="margin-top:6px">
      ${escapeHTML((t("rec_read_line") || 'Тема в книге — "{topic}".').replace("{topic}", String(rec.topic || "").trim()))}
    </div>
  </div>

  ${refsHtml}
` : ``;

body.innerHTML = isTourRec ? `
  <div class="list-item">
    <div style="font-weight:900">${escapeHTML(t("tour_rec_readonly_title") || "Рекомендации по туру")}</div>
    <div class="muted small" style="margin-top:6px">
      ${escapeHTML(t("tour_rec_readonly_text") || "Подробный разбор туровых вопросов недоступен здесь. Отработать тему дополнительно можно в практике.")}
    </div>
  </div>

  ${readBlockHtml || `
    <div class="list-item">
      <div class="muted small">${escapeHTML(t("recs_books_later_source") || "Книги по этой теме будут добавлены позже.")}</div>
    </div>
  `}

  <div class="list-item">
    <div style="margin-top:4px">
      <button class="btn" type="button" data-action="my-rec-open-practice">
        ${escapeHTML(t("tour_review_open_practice") || "Открыть практику")}
      </button>
    </div>
  </div>
` : `
  ${mistakesHeaderHtml}
  ${mistakesHtml}
  ${drillMiniHtml}
  ${readBlockHtml}
`;

  body.querySelectorAll("button[data-open-book-url]").forEach(btn => {
    btn.addEventListener("click", (e) => {
      e.preventDefault();
      const url = btn.getAttribute("data-open-book-url");
      if (url) openExternal(url);
    });
  });
}

async function deleteMyRecCurrent() {
  try {
    const rec = state?.courses?.myRecCurrent;
    const subjectKey = state?.courses?.subjectKey;
    if (!rec || !subjectKey) return;

    const ok = await uiConfirm({
      title: t("rec_delete_title") || "Отметить как освоено?",
      message: t("rec_delete_text") || "Рекомендация будет удалена из списка.",
      okText: t("rec_delete_ok") || "Удалить",
      cancelText: t("rec_delete_cancel") || (t("cancel") || "Отмена")
    });

    if (!ok) return;

    // DB delete (only this record)
    try {
      const uid = await getAuthUid().catch(() => null);
      if (window.sb && uid && rec?.id) {
        const { error } = await window.sb
          .from("recommendations")
          .delete()
          .eq("id", rec.id)
          .eq("user_id", uid);

        if (error) logClientError("myrec_delete_db_error", error);
      }
    } catch (e) {
      logClientError("myrec_delete_db_exception", e);
    }

    showToast(t("rec_deleted_toast") || "Рекомендация удалена.");

    // go back to list + refresh
    state.courses.myRecCurrent = null;
    saveState();

    replaceCourses("my-recs");
    renderMyRecs();
  } catch (e) {
    logClientError("myrec_delete_exception", e);
  }
}

// helper: content language pick
function pickContentText(obj, base) {
  try {
    const lang = (loadProfile()?.language) || "ru";
    const k = lang === "uz" ? (base + "_uz") : lang === "en" ? (base + "_en") : (base + "_ru");
    const v = obj && obj[k] != null && String(obj[k]).trim() !== "" ? obj[k] : obj[base];
    return v != null ? String(v) : "";
  } catch {
    return (obj && obj[base] != null) ? String(obj[base]) : "";
  }
}
   async function buildPracticeSetByRec(subjectKey, rec) {
  if (!window.sb) return [];

  const uid = await getAuthUid();
  if (!uid) return [];

  const subjectId = await getSubjectIdByKey(subjectKey);
  if (!subjectId) return [];

  const topic = String(rec?.topic || "").trim();
  const subtopic = rec?.subtopic ? String(rec.subtopic).trim() : null;
  if (!topic) return [];

    let data = [];
  let error = null;

  // 1) exact: topic + subtopic
  if (subtopic) {
    const exactQ = await window.sb
      .from("questions")
      .select("id, topic, subtopic, difficulty, time_limit_sec, qtype, question_text, options_text, correct_answer, explanation, image_url, is_active, book_ref, question_text_ru, question_text_uz, question_text_en, options_text_ru, options_text_uz, options_text_en, explanation_ru, explanation_uz, explanation_en")
      .eq("subject_id", subjectId)
      .eq("is_active", true)
      .eq("topic", topic)
      .eq("subtopic", subtopic)
      .limit(200);

    data = Array.isArray(exactQ.data) ? exactQ.data : [];
    error = exactQ.error || null;
  }

  // 2) fallback: topic only
  if (!data.length) {
    const baseQ = await window.sb
      .from("questions")
      .select("id, topic, subtopic, difficulty, time_limit_sec, qtype, question_text, options_text, correct_answer, explanation, image_url, is_active, book_ref, question_text_ru, question_text_uz, question_text_en, options_text_ru, options_text_uz, options_text_en, explanation_ru, explanation_uz, explanation_en")
      .eq("subject_id", subjectId)
      .eq("is_active", true)
      .eq("topic", topic)
      .limit(200);

    data = Array.isArray(baseQ.data) ? baseQ.data : [];
    error = error || baseQ.error || null;
  }

  if (error || !data.length) return [];

  // нормализация = как в buildPracticeSet()
  const normalizeDiff = (d) => normalizeDifficulty(d || "easy");
  const normalizeType = (t) => (String(t || "mcq").toLowerCase() === "input" ? "input" : "mcq");

  const lang = (loadProfile()?.language) || "ru";
  const pickL = (obj, base) => {
    const k = lang === "uz" ? (base + "_uz") : lang === "en" ? (base + "_en") : (base + "_ru");
    return (obj && obj[k] != null && String(obj[k]).trim() !== "") ? obj[k] : obj[base];
  };

  const pool = data.map(r => {
    const type = normalizeType(r.qtype);
    const optionsRaw = pickL(r, "options_text");
    const opts = type === "mcq" ? (parseOptionsText(optionsRaw) || []) : [];

    let correctIndex = 0;
    if (type === "mcq") {
      const ca = String(r.correct_answer ?? "").trim();
      const asInt = Number(ca);
      if (!Number.isNaN(asInt) && Number.isFinite(asInt)) {
        correctIndex = asInt;
      } else if (/^[A-D]$/i.test(ca)) {
        correctIndex = ca.toUpperCase().charCodeAt(0) - "A".charCodeAt(0);
      } else if (opts.length) {
        const idx = opts.findIndex(x => String(x).trim().toLowerCase() === ca.toLowerCase());
        if (idx >= 0) correctIndex = idx;
      }
      if (!Number.isFinite(correctIndex) || correctIndex < 0) correctIndex = 0;
    }

    const correctAnswer = type === "input" ? String(r.correct_answer ?? "").trim() : "";
    const diff = normalizeDiff(r.difficulty);

    return {
      id: Number(r.id),
      topic: r.topic || "General",
      subtopic: r.subtopic || null,
      difficulty: diff,
      timeLimitSec:
        (r.time_limit_sec != null && Number(r.time_limit_sec) >= 10)
          ? Number(r.time_limit_sec)
          : (PRACTICE_CONFIG?.timeByDifficulty?.[diff] || 60),
      type,
      question: pickL(r, "question_text") || "",
      options: opts,
      correctIndex,
      correctAnswer,
      explanation: pickL(r, "explanation") || "",
      imageUrl: r.image_url || null,
      inputKind: type === "input" ? (isNumericLike(correctAnswer) ? "numeric" : "text") : null,
      inputHint: type === "input" ? inputHintForAnswer(correctAnswer) : ""
    };
  }).filter(q => Number.isFinite(q.id));

  if (!pool.length) return [];

  // делаем набор как обычная практика (6/9/5), но только внутри темы
  const by = {
    easy: pool.filter(q => q.difficulty === "easy"),
    medium: pool.filter(q => q.difficulty === "medium"),
    hard: pool.filter(q => q.difficulty === "hard")
  };

  const set = [
    ...pickN(by.easy.length ? by.easy : pool, PRACTICE_CONFIG.dist.easy),
    ...pickN(by.medium.length ? by.medium : pool, PRACTICE_CONFIG.dist.medium),
    ...pickN(by.hard.length ? by.hard : pool, PRACTICE_CONFIG.dist.hard)
  ];

  const need = PRACTICE_CONFIG.total - set.length;
  if (need > 0) {
    const used = new Set(set.map(x => x.id));
    const rest = pool.filter(x => !used.has(x.id));
    set.push(...pickN(rest.length ? rest : pool, need));
  }

  const order = { easy: 1, medium: 2, hard: 3 };
  set.sort((a, b) => (order[a.difficulty] - order[b.difficulty]));

  return set.slice(0, PRACTICE_CONFIG.total);
}

     async function buildPracticeSetByQuestionIds(subjectKey, questionIds) {
  if (!window.sb) return [];

  const subjectId = await getSubjectIdByKey(subjectKey);
  if (!subjectId) return [];

  const ids = Array.isArray(questionIds) ? questionIds.filter(Boolean).slice(0, 10) : [];
  if (!ids.length) return [];

  const { data, error } = await window.sb
    .from("questions")
    .select("id, topic, subtopic, difficulty, time_limit_sec, qtype, question_text, options_text, correct_answer, explanation, image_url, is_active, book_ref, question_text_ru, question_text_uz, question_text_en, options_text_ru, options_text_uz, options_text_en, explanation_ru, explanation_uz, explanation_en")
    .eq("subject_id", subjectId)
    .eq("is_active", true)
    .in("id", ids);

  if (error || !Array.isArray(data) || !data.length) return [];

  // same normalization as buildPracticeSetByRec
  const normalizeDiff = (d) => normalizeDifficulty(d || "easy");
  const normalizeType = (t) => (String(t || "mcq").toLowerCase() === "input" ? "input" : "mcq");

  const lang = (loadProfile()?.language) || "ru";
  const pickL = (obj, base) => {
    const k = lang === "uz" ? (base + "_uz") : lang === "en" ? (base + "_en") : (base + "_ru");
    return (obj && obj[k] != null && String(obj[k]).trim() !== "") ? obj[k] : obj[base];
  };

  return data.map(r => {
    const type = normalizeType(r.qtype);
    const optionsRaw = pickL(r, "options_text");
    const opts = type === "mcq" ? (parseOptionsText(optionsRaw) || []) : [];

    let correctIndex = 0;
    if (type === "mcq") {
      const ca = String(r.correct_answer ?? "").trim();
      const asInt = Number(ca);
      if (!Number.isNaN(asInt) && Number.isFinite(asInt)) {
        correctIndex = asInt;
      } else if (/^[A-D]$/i.test(ca)) {
        correctIndex = ca.toUpperCase().charCodeAt(0) - "A".charCodeAt(0);
      } else if (opts.length) {
        const idx = opts.findIndex(x => String(x).trim().toLowerCase() === ca.toLowerCase());
        if (idx >= 0) correctIndex = idx;
      }
      if (!Number.isFinite(correctIndex) || correctIndex < 0) correctIndex = 0;
    }

    const correctAnswer = type === "input" ? String(r.correct_answer ?? "").trim() : "";
    const diff = normalizeDiff(r.difficulty);

    return {
      id: Number(r.id),
      topic: r.topic || "General",
      subtopic: r.subtopic || null,
      difficulty: diff,
      timeLimitSec:
        (r.time_limit_sec != null && Number(r.time_limit_sec) >= 10)
          ? Number(r.time_limit_sec)
          : (PRACTICE_CONFIG?.timeByDifficulty?.[diff] || 60),
      type,
      question: pickL(r, "question_text") || "",
      options: opts,
      correctIndex,
      correctAnswer,
      explanation: pickL(r, "explanation") || "",
      imageUrl: r.image_url || null,
      inputKind: type === "input" ? (isNumericLike(correctAnswer) ? "numeric" : "text") : null,
      inputHint: type === "input" ? inputHintForAnswer(correctAnswer) : ""
    };
  }).filter(q => Number.isFinite(q.id));
} 
async function startPracticeByRec() {
  const rec = state?.courses?.myRecCurrent;
  const subjectKey = state?.courses?.subjectKey;
  if (!rec || !subjectKey) return;

  const questionsAll = await buildPracticeSetByRec(subjectKey, rec);
  if (!questionsAll.length) {
    showToast(t("rec_no_questions") || "Нет вопросов для тренировки по этой теме.");
    return;
  }

  // ✅ Topic practice is also a DRILL (Variant A): short, focused, no DB write
  const DRILL_LIMIT = 10;
  const questions = questionsAll.slice(0, DRILL_LIMIT);

  state.quizLock = "practice";
  state.quiz = {
    mode: "practice",
    subjectKey,
    startedAt: Date.now(),
    paused: false,
    pauseStartedAt: null,
    pausedTotalMs: 0,

    index: 0,
    questions,
    answers: Array.from({ length: questions.length }).map(() => null),
    correct: Array.from({ length: questions.length }).map(() => false),

    qTimeLeft:
      Number(questions[0]?.timeLimitSec) ||
      (PRACTICE_CONFIG?.timeByDifficulty?.[questions[0]?.difficulty] || 60),
    qEndsAtMs: null,
    qTimerId: null,

    // метка, чтобы потом в аналитике видеть, что это “тренировка по рекомендации”
    recTopic: rec.topic || null,
    recSubtopic: rec.subtopic || null,

    // ✅ important: treated as DRILL everywhere (no overwriting last practice, no DB save)
    drillType: "rec_topic"
  };

   // ✅ remember return target for drills
try {
  if (!state.courses) state.courses = {};
  state.courses.myRecReturnTarget = "my-rec-detail";
} catch {}
   
  saveState();
pushCourses("practice-quiz");
renderPracticeQuiz();
startPracticeQuestionTimer();
}

   async function startPracticeRetryMistakes() {
  const rec = state?.courses?.myRecCurrent;
  const subjectKey = state?.courses?.subjectKey;
  const qids = state?.courses?.myRecMistakeQids || [];
  if (!rec || !subjectKey) return;

  if (!Array.isArray(qids) || !qids.length) {
    showToast(t("rec_retry_empty") || "Нет ошибок для повтора.");
    return;
  }

  const questions = await buildPracticeSetByQuestionIds(subjectKey, qids);
  if (!questions.length) {
    showToast(t("rec_retry_empty") || "Нет ошибок для повтора.");
    return;
  }

  state.quizLock = "practice";
  state.quiz = {
    mode: "practice",
    subjectKey,
    startedAt: Date.now(),
    paused: false,
    pauseStartedAt: null,
    pausedTotalMs: 0,

    index: 0,
    questions: questions.slice(0, 10),
    answers: Array.from({ length: Math.min(10, questions.length) }).map(() => null),
    correct: Array.from({ length: Math.min(10, questions.length) }).map(() => false),

    qTimeLeft: Number(questions[0]?.timeLimitSec) || 60,
    qEndsAtMs: null,
    qTimerId: null,

    recTopic: rec.topic || null,
    recSubtopic: rec.subtopic || null,
    drillType: "rec_mistakes"
  };

      // ✅ remember return target for drills
try {
  if (!state.courses) state.courses = {};
  state.courses.myRecReturnTarget = "my-rec-detail";
} catch {}
      
  saveState();
pushCourses("practice-quiz");
renderPracticeQuiz();
startPracticeQuestionTimer();
}
   
async function renderBooks() {
  const wrap = $("#books-list");
  if (!wrap) return;

  // show loading
  wrap.innerHTML = `<div class="empty muted">${escapeHTML(t("books_loading") || "")}</div>`;

  const subjectKey = state?.courses?.subjectKey ? String(state.courses.subjectKey) : "";
  if (!subjectKey) {
    wrap.innerHTML = `<div class="empty muted">${escapeHTML(t("books_pick_subject_first") || "")}</div>`;
    return;
  }

  if (!window.sb) {
    wrap.innerHTML = `<div class="empty muted">${escapeHTML(t("books_no_db") || "")}</div>`;
    return;
  }

  // Resolve subject_id (prefer existing helper if present)
  let subjectId = null;
  try {
    if (typeof getSubjectIdByKey === "function") {
      subjectId = await getSubjectIdByKey(subjectKey);
    }
  } catch {}

  if (!subjectId) {
    try {
      const { data, error } = await window.sb
        .from("subjects")
        .select("id")
        .eq("subject_key", subjectKey)
        .maybeSingle();
      if (!error && data?.id) subjectId = data.id;
    } catch {}
  }

  if (!subjectId) {
    wrap.innerHTML = `<div class="empty muted">${escapeHTML(t("books_subject_not_found") || "")}</div>`;
    return;
  }

  // Load books
  let rows = [];
  try {
    const { data, error } = await window.sb
      .from("books")
      .select("id,title,file_url,is_active,created_at")
      .eq("subject_id", subjectId)
      .eq("is_active", true)
      .order("created_at", { ascending: false });

    if (!error && Array.isArray(data)) rows = data;
  } catch {}

  if (!rows.length) {
    wrap.innerHTML = `<div class="empty muted">${escapeHTML(t("books_empty") || "")}</div>`;
    return;
  }

  wrap.innerHTML = "";

  rows.forEach((b) => {
    const btn = document.createElement("button");
    btn.type = "button";
    btn.className = "settings-nav";
    btn.innerHTML = `
      <span class="settings-nav-ico">📘</span>
      <span class="settings-nav-text">
        <span class="settings-nav-title">${escapeHTML(b.title || "Book")}</span>
        <span class="settings-nav-sub muted small">${escapeHTML(t("books_open_pdf") || "")}</span>
      </span>
      <span class="settings-nav-arrow">›</span>
    `;
        btn.addEventListener("click", () => {
      const url = String(b.file_url || "").trim();
      if (!url) return;

      try {
        trackEvent("resource_opened", {
          resource_type: "book",
          resource_id: String(b.id || ""),
          title: String(b.title || ""),
          url,
          subject_key: String(state?.courses?.subjectKey || "")
        });
      } catch {}

      openExternal(url);
    });
    wrap.appendChild(btn);
  });
}

    // ---------------------------
  // Tour (strict) — T1+T2+T3 (mock now, DB later)
  // ---------------------------
  const TOUR_CONFIG = {
  total: 20,
  dist: { easy: 6, medium: 9, hard: 5 },
  defaultQuestionTimeSec: 45, // ✅ фоллбек ТОЛЬКО если у вопроса нет своего лимита
  maxViolations: 2,
};

  let tourTick = null;

  function openTourRules() {
    pushCourses("tour-rules");
    const cb = $("#tour-rules-accept");
    if (cb) cb.checked = false;
  }

  // ---------- T3: Data contract ----------
  // UI expects rows in this shape:
  // { id, subject_key, tour_no, difficulty, question_text, options[], correct_index, explanation?, source? }
  function getTourQuestionsMock(subjectKey, tourNo) {
    // 20 вопросов: 6 easy / 9 medium / 5 hard (mock)
    const mk = (i, diff) => ({
      id: `mock_${subjectKey || "subject"}_${tourNo}_${i}`,
      subject_key: subjectKey || "subject",
      tour_no: tourNo || 1,
      difficulty: diff,
      question_text: `Which process occurs during the light-dependent stage of photosynthesis? (Q${i})`,
      options: [
        "Photolysis of water molecules",
        "Fixation of carbon dioxide",
        "Production of glucose",
        "Reduction of NADP to NADPH"
      ],
      correct_index: 0,
      explanation: "Light-dependent reactions include photolysis and formation of ATP/NADPH.",
      source: "Uzbekistan Academic Standards"
    });

    const items = [];
    let i = 1;

    for (let k = 0; k < TOUR_CONFIG.dist.easy; k++) items.push(mk(i++, "easy"));
    for (let k = 0; k < TOUR_CONFIG.dist.medium; k++) items.push(mk(i++, "medium"));
    for (let k = 0; k < TOUR_CONFIG.dist.hard; k++) items.push(mk(i++, "hard"));

    // маленькая перемешка (стабильная)
    return shuffleArrayStable(items, `${subjectKey || "s"}_${tourNo || 1}`);
  }

  function shuffleArrayStable(arr, seedStr) {
    const a = [...arr];
    let seed = 0;
    for (let i = 0; i < seedStr.length; i++) seed = (seed * 31 + seedStr.charCodeAt(i)) >>> 0;
    function rnd() {
      seed = (seed * 1664525 + 1013904223) >>> 0;
      return seed / 0xFFFFFFFF;
    }
    for (let i = a.length - 1; i > 0; i--) {
      const j = Math.floor(rnd() * (i + 1));
      [a[i], a[j]] = [a[j], a[i]];
    }
    return a;
  }

   // ---------------------------
// Tours (DB-first via tour_questions)
// ---------------------------

async function loadActiveTourBySubjectAndNo(
  subjectId,
  tourNo,
  seasonIdArg = null
) {
  if (!window.sb || !subjectId || !tourNo) {
    return null;
  }

  const seasonId =
    Number(seasonIdArg || 0) ||
    await getCurrentSeasonId();

  if (!seasonId) {
    return null;
  }

  const { data, error } = await window.sb
    .from("tours")
    .select(
      "id,subject_id,tour_no,start_date,end_date,is_active,season_id"
    )
    .eq("subject_id", Number(subjectId))
    .eq("tour_no", Number(tourNo))
    .eq("season_id", Number(seasonId))
    .eq("is_active", true)
    .maybeSingle();

  if (error || !data?.id) {
    return null;
  }

  const padLocal = (number) =>
    String(number).padStart(2, "0");

  const now = new Date();

  const todayISO =
    `${now.getFullYear()}-` +
    `${padLocal(now.getMonth() + 1)}-` +
    `${padLocal(now.getDate())}`;

  const startDate =
    data?.start_date
      ? String(data.start_date)
      : "";

  const endDate =
    data?.end_date
      ? String(data.end_date)
      : "";

  // Подготовительный тур без дат никогда не открывается.
  if (!startDate || !endDate) {
    return null;
  }

  if (startDate > todayISO) {
    return null;
  }

  if (endDate < todayISO) {
    return null;
  }

  return data;
}

async function loadTourQuestionsDB(tourId) {
  if (!window.sb || !tourId) return null;

    const { data, error } = await window.sb
  .from("tour_questions")
  .select("order_no, question:questions(id,topic,subtopic,difficulty,qtype,question_text,options_text,correct_answer,image_url,is_active,book_ref,question_text_ru,question_text_uz,question_text_en,options_text_ru,options_text_uz,options_text_en)")
  .eq("tour_id", tourId)
  .eq("is_active", true)
  .order("order_no", { ascending: true })
  .limit(200);

  if (error) return null;

  const rows = Array.isArray(data) ? data : [];
  const items = rows
    .map(r => r?.question || null)
    .filter(q => q && q.is_active);

  // normalize to Tour UI model (same spirit as practice builder)
  const normalizeDiff = (d) => normalizeDifficulty(d || "easy");
  const normalizeType = (t) => (String(t || "mcq").toLowerCase() === "input" ? "input" : "mcq");

   const contentLang = (loadProfile()?.language) || "ru";
   const pickL = (obj, base) => {
   const k = contentLang === "uz" ? (base + "_uz") : contentLang === "en" ? (base + "_en") : (base + "_ru");
   return (obj && obj[k] != null && String(obj[k]).trim() !== "") ? obj[k] : obj[base];
};

    return items.map(q => {
    const type = normalizeType(q.qtype);

      // ✅ options по языку контента
      const optionsRaw = pickL(q, "options_text");
      const opts = type === "mcq" ? (parseOptionsText(optionsRaw) || []) : null;

    // correctIndex for mcq:
    // - if correct_answer is numeric index => use it
    // - if correct_answer is A/B/C/D => convert to index
    // - else try match to option text (case-insensitive)
    let correctIndex = 0;
    if (type === "mcq") {
      const ca = String(q.correct_answer ?? "").trim();

      if (isNumericLike(ca)) {
        correctIndex = Math.max(
          0,
          Math.min((opts?.length || 1) - 1, Math.trunc(Number(String(ca).replace(",", "."))))
        );
      } else if (/^[A-D]$/i.test(ca)) {
        const idx = letterToIdx(ca);
        if (idx !== null) {
          correctIndex = Math.max(0, Math.min((opts?.length || 1) - 1, idx));
        }
      } else if (opts.length) {
        const idx = opts.findIndex(o => String(o).trim().toLowerCase() === ca.toLowerCase());
        if (idx >= 0) correctIndex = idx;
      }
    }

        return {
  id: Number(q.id),
  topic: q.topic || "General",
  subtopic: q.subtopic || null,
  difficulty: normalizeDiff(q.difficulty),
  type,
  question: pickL(q, "question_text") || "",
  options: opts || [],
  correctIndex,
  correct_answer: String(q.correct_answer ?? "").trim(),
  correctAnswer: String(q.correct_answer ?? "").trim(),
    imageUrl: q.image_url || null,
  book_ref: q.book_ref || null,
  bookReference: q.book_ref || null,
  timeLimitSec: TOUR_CONFIG.defaultQuestionTimeSec
    };
  });
}

async function hasTourAttempt(uid, tourId) {
  if (!window.sb || !uid || !tourId) return false;
  const { data, error } = await window.sb
    .from("tour_attempts")
    .select("id")
    .eq("user_id", uid)
    .eq("tour_id", tourId)
    .limit(1);

  if (error) return false;
  return Array.isArray(data) && data.length > 0;
}

async function createTourAttempt(uid, tourId) {
  if (!window.sb || !uid || !tourId) return null;

  // 0) if attempt already exists — reuse it (idempotent)
  try {
    const { data: existing, error: exErr } = await window.sb
      .from("tour_attempts")
      .select("id")
      .eq("user_id", uid)
      .eq("tour_id", tourId)
      .order("id", { ascending: true })
      .limit(1);

    if (!exErr && Array.isArray(existing) && existing.length) {
      return existing[0]?.id ?? null;
    }
  } catch {}

  // 1) try insert with retry
  let insertedId = null;
  try {
    const res = await dbWriteWithRetry(async () => {
      const { data, error } = await window.sb
        .from("tour_attempts")
        .insert([{ user_id: uid, tour_id: tourId, score: 0, percent: 0, total_time: 0, status: "submitted" }])
        .select("id")
        .single();
      if (error) throw error;
      return data?.id ?? null;
    }, { tries: 3, baseDelayMs: 350 });

    insertedId = res;
  } catch {
    insertedId = null;
  }

  // 2) final: pick earliest attempt id and delete duplicate we created (if any)
  try {
    const { data: pick, error: pErr } = await window.sb
      .from("tour_attempts")
      .select("id")
      .eq("user_id", uid)
      .eq("tour_id", tourId)
      .order("id", { ascending: true })
      .limit(1);

    if (!pErr && Array.isArray(pick) && pick.length) {
      const winnerId = pick[0]?.id ?? null;

      if (winnerId && insertedId && winnerId !== insertedId) {
        try {
          await window.sb.from("tour_attempts").delete().eq("id", insertedId);
        } catch {}
      }

      return winnerId;
    }
  } catch {}

  return insertedId;
}

async function upsertTourAnswer(attemptId, questionId, patch) {
  if (!window.sb || !attemptId || !questionId) return { ok: false, reason: "no_sb_or_ids" };

  try {
    await dbWriteWithRetry(async () => {
      const { error } = await window.sb
        .from("tour_answers")
        .upsert([{
          attempt_id: attemptId,
          question_id: questionId,
          user_answer: patch.user_answer ?? null,
          answered: !!patch.answered,
          is_correct: !!patch.is_correct,
          time_spent: Number(patch.time_spent || 0),
          finish_reason: patch.finish_reason ?? null
        }], { onConflict: "attempt_id,question_id" });

      if (error) throw error;
      return true;
    }, { tries: 3, baseDelayMs: 350 });

    return { ok: true };
  } catch (e) {
    try { logClientError("upsertTourAnswer_failed", e); } catch {}
    return { ok: false, reason: "db_error", error: e };
  }
}

async function updateTourAttempt(attemptId, patch) {
  if (!window.sb || !attemptId) return { ok: false, reason: "no_sb_or_id" };

  try {
    let finalScore = Number(patch.score || 0);
    let finalPercent = Number(patch.percent || 0);

    const savedScore = await getSavedTourAttemptScore(attemptId);
    const expectedRows = Number(patch.expected_answer_rows || 0);

    if (savedScore && expectedRows > 0 && savedScore.answerRows < expectedRows) {
      return { ok: false, reason: "answers_not_ready", savedRows: savedScore.answerRows, expectedRows };
    }

    if (savedScore && savedScore.answerRows > 0) {
      finalScore = savedScore.score;
      finalPercent = savedScore.percent;
    }

    await dbWriteWithRetry(async () => {
      const { error } = await window.sb
        .from("tour_attempts")
        .update({
          score: finalScore,
          percent: finalPercent,
          total_time: Number(patch.total_time || 0),
          status: String(patch.status || "submitted")
        })
        .eq("id", attemptId);

      if (error) throw error;
      return true;
    }, { tries: 3, baseDelayMs: 350 });

    return { ok: true, score: finalScore, percent: finalPercent };
  } catch (e) {
    try { trackEvent("tour_db_save_failed", { attempt_id: String(attemptId), message: String(e?.message || e) }); } catch {}
    return { ok: false, reason: "db_error", error: e };
  }
}

  function initTourSession({ subjectKey = null, tourNo = 1, tourId = null, seasonId = null, attemptId = null, questions = [], isArchive = false, tourEndDate = null } = {}) {
  state.tourContext = {
    isArchive,
    subjectKey,
    tourNo,
    tourId,        // ✅ DB tour id
    seasonId,      // ✅ DB season id
    attemptId,     // ✅ DB attempt id (null for archive)
    tourEndDate,   // ✅ end_date active tour
    questions,     // ✅ loaded from DB mapping tour_questions
    startedAt: Date.now(),
    qStartedAt: Date.now(),
    startedAtMono: monoNow(),
    qStartedAtMono: monoNow(),
    index: 0,
    correct: 0,
    answers: [],   // {qid, pickedIndex, userAnswer, isCorrect, spentSec}
    pendingDbAnswers: [], // ✅ NEW: ответы, которые не удалось записать в БД
    violations: 0,
    lastViolationAt: null,
    questionTimeLimit: TOUR_CONFIG.defaultQuestionTimeSec
  };

  // strict lock only for ACTIVE tour
  state.quizLock = isArchive ? null : "tour";
  saveState();
}

  let __tourStartInFlight = false;
 async function openTourQuiz() {
  if (__tourStartInFlight) return;
  __tourStartInFlight = true;

  const startBtn = document.querySelector('[data-action="tour-start"]');
  const __startPrevText = startBtn ? startBtn.textContent : null;

  if (startBtn) {
    startBtn.disabled = true;
    startBtn.classList.add("is-loading");
    startBtn.textContent = (t("saving") || "Сохранение…");
  }

  try {
    const accept = $("#tour-rules-accept");
    if (!accept || !accept.checked) {
      showToast(t("tour_rules_accept_required"));
      return;
    }

    const subjectKey = state.courses?.subjectKey || null;
  if (!subjectKey) {
    showToast(t("toast_subject_not_selected"));
    return;
  }

  const tourStartCourseContext = {
    subjectKey,
    stack: Array.isArray(state?.courses?.stack) && state.courses.stack.length
      ? [...state.courses.stack]
      : ["subject-tours"],
    entryTab: state?.courses?.entryTab || state?.prevTab || "home",
    activeTourNo: state?.courses?.activeTourNo || null,
    activeTourId: state?.courses?.activeTourId || null
  };

      // 1) current identity must exist in DB before any tour start
  let uid = await getAuthUid();

  if (!uid || !(await hasDbUserRow(uid))) {
    const checkRes = await checkTelegramLinkedProfile({
      source: "tour_start_profile_check"
    }).catch((e) => ({
      ok: false,
      reason: "exception",
      message: String(e?.message || e)
    }));

    if (!checkRes?.ok || !checkRes?.linked) {
      await uiAlert({
        title: t("not_available") || tr3("Недоступно", "Mavjud emas", "Not available"),
        message: tr3(
          "Не удалось подтвердить ваш профиль. Пожалуйста, закройте и заново откройте приложение из Telegram.",
          "Profilingizni tasdiqlab bo‘lmadi. Iltimos, ilovani Telegram orqali yopib qayta oching.",
          "We could not verify your profile. Please close and reopen the app from Telegram."
        )
      });
      return;
    }

    if (checkRes?.is_current && checkRes?.current_uid) {
      uid = String(checkRes.current_uid);

      if (!(await hasDbUserRow(uid))) {
        await uiAlert({
          title: t("not_available") || tr3("Недоступно", "Mavjud emas", "Not available"),
          message: tr3(
            "Профиль найден, но ещё не синхронизирован. Пожалуйста, заново откройте приложение через несколько секунд.",
            "Profil topildi, lekin hali sinxronlashmagan. Iltimos, bir necha soniyadan keyin ilovani qayta oching.",
            "The profile was found but is not synced yet. Please reopen the app again in a few seconds."
          )
        });
        return;
      }
    } else {
  // ВАЖНО:
  // tour-start не должен запускать ручное подтверждение профиля.
  // Если identity поплыл, это системный repair-path, а не пользовательский risky recovery.
  const recRes = await recoverTelegramLinkedProfile({
    source: "inactive_session_boot",
    silentBoot: true,
    force: true,
    preserveCourseContext: tourStartCourseContext
  }).catch((e) => ({
    ok: false,
    reason: "exception",
    message: String(e?.message || e)
  }));

  if (!recRes?.ok) {
    await uiAlert({
      title: tr3(
        "Профиль временно не удалось подтвердить.",
        "Profilni vaqtincha tasdiqlab bo‘lmadi.",
        "Profile could not be confirmed temporarily."
      ),
      message: tr3(
        "Пожалуйста, полностью закройте mini app и откройте его заново из Telegram. Если проблема повторится, напишите администратору.",
        "Iltimos, mini appni to‘liq yoping va Telegram orqali qayta oching. Muammo takrorlansa, administratorga yozing.",
        "Please fully close the mini app and reopen it from Telegram. If the problem happens again, contact the administrator."
      )
    });
    return;
  }

  uid = await getAuthUid();

  if (!uid || !(await hasDbUserRow(uid))) {
    await uiAlert({
      title: tr3(
        "Профиль временно не удалось подтвердить.",
        "Profilni vaqtincha tasdiqlab bo‘lmadi.",
        "Profile could not be confirmed temporarily."
      ),
      message: tr3(
        "Пожалуйста, полностью закройте mini app и откройте его заново из Telegram. Если проблема повторится, напишите администратору.",
        "Iltimos, mini appni to‘liq yoping va Telegram orqali qayta oching. Muammo takrorlansa, administratorga yozing.",
        "Please fully close the mini app and reopen it from Telegram. If the problem happens again, contact the administrator."
      )
    });
            return;
      }
    }
  }
  // 2) eligibility: only school students can participate (tours/ratings)
  const me = await getUserProfile(uid);

  if (!me?.is_school_student) {
    await uiAlert({
      title: t("disabled_title") || t("not_available"),
      message: t("tour_disabled_nonstudent") || "Туры доступны только для школьников."
    });
    return;
  }

   // 2) resolve subject_id and active tour selected from Tours List
  const subjectId = await getSubjectIdByKey(subjectKey);
  if (!subjectId) {
    showToast(t("toast_subject_id_not_found"));
    return;
  }

  const selectedTourNo = Number(state?.courses?.activeTourNo || 0);
  const selectedTourId = state?.courses?.activeTourId != null
    ? String(state.courses.activeTourId)
    : "";

  if (!selectedTourNo || !selectedTourId) {
    await uiAlert({
      title: t("tour_unavailable_title") || "Тур недоступен",
      message:
        t("tour_unavailable_no_active") ||
        tr3(
          "Нет активного тура для этого предмета. Пожалуйста, откройте список туров заново.",
          "Bu fan uchun faol tur yo‘q. Iltimos, turlar ro‘yxatini qayta oching.",
          "There is no active tour for this subject. Please reopen the tours list."
        )
    });
    return;
  }

  const selectedSeasonId =
    Number(state?.courses?.activeSeasonId || 0) ||
    null;

  const tourNo = selectedTourNo;

  const tour = await loadActiveTourBySubjectAndNo(
    subjectId,
    tourNo,
    selectedSeasonId
  );

  if (!tour?.id || String(tour.id) !== selectedTourId) {
    await uiAlert({
      title: t("tour_unavailable_title") || "Тур недоступен",
      message:
        t("tour_unavailable_no_active") ||
        tr3(
          "Данные тура обновились. Пожалуйста, вернитесь к списку туров и откройте тур заново.",
          "Tur ma’lumotlari yangilandi. Iltimos, turlar ro‘yxatiga qaytib, turni qayta oching.",
          "Tour data has been updated. Please return to the tours list and open the tour again."
        )
    });
    return;
  }

  // 3) one attempt rule
  const already = await hasTourAttempt(uid, tour.id);
  if (already) {
    await uiAlert({
      title: t("tour_unavailable_title") || "Тур недоступен",
      message: t("tour_unavailable_already_attempted") || "У вас уже была попытка в этом туре."
    });
    return;
  }

  // 4) load questions by mapping table tour_questions
  const questions = await loadTourQuestionsDB(tour.id);
  if (!questions || questions.length === 0) {
    await uiAlert({
      title: t("tour_unavailable_title") || "Тур недоступен",
      message: t("tour_unavailable_no_questions") || "Для тура не назначены вопросы."
    });
    return;
  }

    try {
    trackEvent("tour_rules_accepted", {
      ts: new Date().toISOString(),
      tour_id: String(tour.id),
      subject_id: String(subjectId),
      subject_key: String(subjectKey || ""),
      tour_no: Number(tour?.tour_no || tourNo || 0)
    });
  } catch {}

  // 5) create attempt row
  const attemptId = await createTourAttempt(uid, tour.id);
  if (!attemptId) {
    showToast(t("toast_tour_create_failed"));
    return;
  }

    // analytics: started
  try {
    trackEvent("tour_attempt_started", {
      ts: new Date().toISOString(),
      tour_id: String(tour.id),
      attempt_id: String(attemptId),
      subject_id: String(subjectId),
      subject_key: String(subjectKey || ""),
      tour_no: Number(tour?.tour_no || tourNo || 0)
    });
  } catch {}

    initTourSession({
    subjectKey,
    tourNo,
    tourId: tour.id,
    seasonId: tour?.season_id || null,
    attemptId,
    questions,
    isArchive: false,
    tourEndDate: tour?.end_date || null
  });

    pushCourses("tour-quiz");
  bindTourAntiCheatOnce();
  startTourTick();
  renderTourQuestion();
} finally {
  __tourStartInFlight = false;
  if (startBtn) {
    startBtn.disabled = false;
    startBtn.classList.remove("is-loading");
    if (__startPrevText != null) startBtn.textContent = __startPrevText;
     }
   }
}

    function enforceTourAutoRulesNow() {
    const ctx = state.tourContext;
    if (!ctx || ctx.isArchive) return;

    // 1) auto-finish if violations too many
    if (ctx.violations >= TOUR_CONFIG.maxViolations) {
      stopTourTick();
      finishTour({ reason: "violations" }).catch(() => null);
      return;
    }

    // 2) per-question timeout: auto submit if exceeded and not answered for this question index
    const qElapsed = Math.floor((monoNow() - (ctx.qStartedAtMono ?? ctx.qStartedAt)) / 1000);
    if (qElapsed >= ctx.questionTimeLimit) {
      if (!ctx.answers.some(a => a.index === ctx.index)) {
        submitTourAnswer({ pickedIndex: null, auto: true }).catch(() => null);
      }
    }
  }

  function startTourTick() {
    stopTourTick();
    tourTick = setInterval(() => {
      renderTourHUD();
      enforceTourAutoRulesNow();
    }, 250);
  }

  function stopTourTick() {
    if (tourTick) clearInterval(tourTick);
    tourTick = null;
  }

  // ---------- T2: Anti-cheat ----------
  let antiCheatBound = false;

  function bindTourAntiCheatOnce() {
    if (antiCheatBound) return;
    antiCheatBound = true;

        document.addEventListener("visibilitychange", () => {
      if (!state.tourContext || state.tourContext.isArchive) return;

      if (document.visibilityState !== "visible") {
        registerTourViolation("visibility");

        // если дошли до лимита — финишим сразу, не ждём тика
        try { enforceTourAutoRulesNow(); } catch {}
        return;
      }

      // при возврате на экран — сразу применяем авто-правила (timeout/violations)
      try { enforceTourAutoRulesNow(); } catch {}
    });

    window.addEventListener("blur", () => {
      if (!state.tourContext || state.tourContext.isArchive) return;
      registerTourViolation("blur");
    });
  }

  function registerTourViolation(type) {
    const ctx = state.tourContext;
    if (!ctx || ctx.isArchive) return;

    // simple debounce: 1 violation per 2s (✅ use monotonic time for delta)
    const nowMono = monoNow();
    const lastMono = Number(ctx.lastViolationAtMono ?? NaN);
    if (Number.isFinite(lastMono) && (nowMono - lastMono) < 2000) return;

    ctx.lastViolationAtMono = nowMono; // ✅ reliable delta across clock changes/sleep
    ctx.lastViolationAt = Date.now();  // optional calendar timestamp for logs

    ctx.violations += 1;
    saveState();

        // ✅ mirror to DB via app_events (trackEvent already mirrors)
    try {
      trackEvent("tour_violation", {
        violation_type: String(type || ""),
        violations: Number(ctx.violations || 0),
        tour_id: String(ctx.tourId || ""),
        attempt_id: String(ctx.attemptId || ""),
        subject_key: String(ctx.subjectKey || ""),
        tour_no: Number(ctx.tourNo || 0)
      });
    } catch {}

    try {
      const severity =
        Number(ctx.violations || 0) >= Number(TOUR_CONFIG.maxViolations || 0)
          ? "critical"
          : "warning";

      trackEvent("anti_cheat_event", {
        reason: String(type || ""),
        severity,
        violations: Number(ctx.violations || 0),
        tour_id: String(ctx.tourId || ""),
        attempt_id: String(ctx.attemptId || ""),
        subject_id: normSubjectId(ctx.subjectKey || ""),
        subject_key: String(ctx.subjectKey || ""),
        tour_no: Number(ctx.tourNo || 0)
      });
    } catch {}

        const warnBtn = $("#tour-warn-btn");
    if (warnBtn) warnBtn.style.display = "inline-flex";

    const warnPill = $("#tour-anti-cheat"); // legacy id might exist elsewhere
    if (warnPill) warnPill.style.display = "inline-flex";

    showToast(t("tour_violation_toast", { v: ctx.violations, max: TOUR_CONFIG.maxViolations }));

    Promise.resolve().then(() => {
      const left = Math.max(0, Number(TOUR_CONFIG.maxViolations || 0) - Number(ctx.violations || 0));
      uiAlert({
        title: tr3("Предупреждение", "Ogohlantirish", "Warning"),
        message: tr3(
          `Зафиксировано нарушение ${ctx.violations} из ${TOUR_CONFIG.maxViolations}. ${left > 0 ? `После следующего нарушения тур завершится автоматически.` : `Лимит нарушений исчерпан.`}`,
          `${ctx.violations}/${TOUR_CONFIG.maxViolations} qoidabuzarlik qayd etildi. ${left > 0 ? `Keyingi qoidabuzarlikdan so‘ng tur avtomatik yakunlanadi.` : `Qoidabuzarlik limiti tugadi.`}`,
          `Violation ${ctx.violations} of ${TOUR_CONFIG.maxViolations} has been recorded. ${left > 0 ? `After the next violation, the tour will finish automatically.` : `The violation limit has been reached.`}`
        ),
        okText: tr3("Понятно", "Tushunarli", "OK")
      });
    });
  }

  // ---------- Render ----------
  function renderTourHUD() {
    const ctx = state.tourContext;
    if (!ctx) return;

    const total = TOUR_CONFIG.total;
    const qNo = Math.min(total, ctx.index + 1);

    const qof = $("#tour-qof");
    if (qof) qof.textContent = t("tour_question_of", { q: qNo, total });

    const pct = Math.round((qNo / total) * 100);
    const pctEl = $("#tour-progress-pct");
    if (pctEl) pctEl.textContent = `${pct}%`;

    const fill = $("#tour-progress-fill");
    if (fill) fill.style.width = `${pct}%`;

    const badge = $("#tour-badge");
    if (badge) {
      const subjLabel = String(ctx.subjectKey || "SUBJECT").toUpperCase();
      badge.textContent = `CAMBRIDGE ${subjLabel} • TOUR #${ctx.tourNo}`;
    }

       const overall = formatMsToMMSS(monoNow() - (ctx.startedAtMono ?? ctx.startedAt));
    const overallEl = $("#tour-overall-time");
    if (overallEl) overallEl.textContent = overall;

    const qElapsed = formatMsToMMSS(monoNow() - (ctx.qStartedAtMono ?? ctx.qStartedAt));
    const qEl = $("#tour-question-time");
    if (qEl) qEl.textContent = qElapsed;
     // ✅ last-10-seconds warning on question timer
try {
  const qRow = ctx.questions?.[ctx.index] || null;

  const limitSecRaw =
    qRow?.time_limit_seconds ??
    qRow?.timeLimitSec ??
    TOUR_CONFIG.defaultQuestionTimeSec ??
    45;

  const limitSec = Math.max(1, Number(limitSecRaw) || 45);
  const elapsedSec = Math.max(0, Math.floor((monoNow() - (ctx.qStartedAtMono ?? ctx.qStartedAt)) / 1000));
  const remainSec = limitSec - elapsedSec;

  const qCard = (qEl && qEl.closest) ? qEl.closest(".tour-timer-card") : null;
  if (qCard) {
    if (remainSec <= 10) qCard.classList.add("danger");
    else qCard.classList.remove("danger");

    if (remainSec <= 5) qCard.classList.add("pulse");
    else qCard.classList.remove("pulse");
  }
} catch {}

    // warning visibility
    const warnBtn = $("#tour-warn-btn");
    if (warnBtn) warnBtn.style.display = (!ctx.isArchive && ctx.violations > 0) ? "inline-flex" : "none";
  }

  function renderTourQuestion() {
  const ctx = state.tourContext;
  if (!ctx) return;

  const q = ctx.questions?.[ctx.index];
  if (!q) {
    finishTour({ reason: "done" }).catch(() => null);
    return;
  }

  ctx.qStartedAt = Date.now();
  ctx.qStartedAtMono = monoNow();
  // сбрасываем прошлый выбор при показе нового вопроса
  ctx._pickedIndex = null;
  saveState();

  // question text (fallback ids)
  const qEl =
    $("#tour-question") ||
    $("#quiz-question") ||
    $("#tour-question-text");

  if (qEl) {
  const qText =
    (q.question ?? q.question_text ?? q.questionText ?? q.text ?? q.prompt ?? q.title ?? "");
  qEl.textContent = String(qText || "");
}

  // question type normalize (mcq vs input)
  const qTypeRaw = String(q.qtype ?? q.type ?? q.question_type ?? "mcq").toLowerCase();
  const isMcq = (qTypeRaw === "mcq" || qTypeRaw === "choice" || qTypeRaw === "multiple_choice");

  // options wrap (fallback ids/classes)
  const wrap =
    $("#tour-options") ||
    $("#tour-options-wrap") ||
    $("#tour-options-list") ||
    document.querySelector(".tour-options");

  if (wrap) {
    wrap.innerHTML = "";

    if (!isMcq) {
  // input question UI (no HTML edits needed)
  const inputWrap = document.createElement("div");
  inputWrap.className = "input-wrap";

    inputWrap.innerHTML = `
    <label class="input-label">${escapeHTML(t("answer") || "Answer")}</label>
    <input id="tour-input" class="text-input" type="text" placeholder="${escapeHTML(t("type_answer") || "Type your answer")}">
    <div id="tour-input-error" class="muted small" style="margin-top:6px; display:none;"></div>
  `;

  wrap.appendChild(inputWrap);

  const inputEl = inputWrap.querySelector("#tour-input");
  const errEl = inputWrap.querySelector("#tour-input-error");

  const nextBtn =
    $("#tour-next-btn") ||
    $("#quiz-next-btn") ||
    document.querySelector('[data-action="tour-next"]');

  if (nextBtn) {
  nextBtn.disabled = true; // ⛔ пока формат не валиден

  const isLast = (ctx.index >= TOUR_CONFIG.total - 1);
  nextBtn.textContent = isLast
    ? (t("tour_finish_button") || "Finish Tour →")
    : (t("tour_next_question") || "Next Question →");
}

  // ✅ активируем Next только когда input-формат валиден
  const syncTourInputState = () => {
    if (!inputEl || !nextBtn) return;

    const raw = String(inputEl.value || "");
    const hasValue = raw.trim().length > 0;
    const isValid = hasValue && isValidInputAnswer(q, raw);

    nextBtn.disabled = !isValid;

    if (errEl) {
      if (hasValue && !isValid) {
        errEl.textContent = t("invalid_answer_format");
        errEl.style.display = "block";
      } else {
        errEl.textContent = "";
        errEl.style.display = "none";
      }
    }
  };

  if (inputEl && nextBtn) {
    inputEl.addEventListener("input", syncTourInputState);
    syncTourInputState();
  }

  renderTourHUD();
  return;
}

    // MCQ options
    const opts = Array.isArray(q.options) && q.options.length
      ? q.options
      : ["Option A", "Option B", "Option C", "Option D"];

    opts.forEach((opt, i) => {
      const btn = document.createElement("button");
      btn.type = "button";
      btn.className = "option";
      btn.dataset.action = "tour-pick";
      btn.dataset.index = String(i);

      btn.innerHTML = `
        <span class="dot" aria-hidden="true"></span>
        <span class="opt-text">${escapeHTML(opt)}</span>
      `;

      btn.onclick = (ev) => {
        try { ev.preventDefault(); ev.stopPropagation(); } catch {}

        const ctx2 = state.tourContext;
        if (!ctx2) return;

        (wrap.querySelectorAll(".option") || []).forEach(o => o.classList.remove("is-selected"));
        btn.classList.add("is-selected");

        const nextBtn =
          $("#tour-next-btn") ||
          $("#quiz-next-btn") ||
          document.querySelector('[data-action="tour-next"]');

        if (nextBtn) nextBtn.disabled = false;

        ctx2._pickedIndex = i;
        saveState();
      };

      wrap.appendChild(btn);
    });
  }

  // disable next until choose (MCQ only)
  const nextBtn =
    $("#tour-next-btn") ||
    $("#quiz-next-btn") ||
    document.querySelector('[data-action="tour-next"]');

  if (nextBtn) {
  nextBtn.classList.remove("is-loading"); // <-- добавь
  nextBtn.disabled = true;

  const isLast = (ctx.index >= TOUR_CONFIG.total - 1);
  nextBtn.textContent = isLast
    ? (t("tour_finish_button") || "Finish Tour →")
    : (t("tour_next_question") || "Next Question →");
}

  renderTourHUD();
}

       async function submitTourAnswer({ pickedIndex, auto = false } = {}) {
    const ctx = state.tourContext;
    if (!ctx) return;

    let q = ctx.questions?.[ctx.index];
    if (!q) return;

    const spentSec = Math.max(0, Math.floor((monoNow() - (ctx.qStartedAtMono ?? ctx.qStartedAt)) / 1000));

    // normalize question type (DB uses qtype, older code may use type)
    const qType =
      (q?.qtype != null ? String(q.qtype) : (q?.type != null ? String(q.type) : "mcq"))
        .toLowerCase();
    const isMcq = (qType === "mcq" || qType === "multiple_choice");

          if (isMcq && getMcqCorrectIndexFromQuestion(q) === null && !ctx?.isArchive) {
      const restoredQ = await restoreActiveTourQuestionSecrets(ctx, ctx.index);
      if (restoredQ) q = restoredQ;
    }

        const correctIdx = isMcq ? getMcqCorrectIndexFromQuestion(q) : null;
    const pickedNum = (pickedIndex === null || pickedIndex === undefined) ? null : Number(pickedIndex);

    // Safety guard: if user selected an MCQ option but correctness data is still missing,
    // do NOT save it as wrong. This prevents false-negative tour answers after WebView reload.
    if (isMcq && correctIdx === null && !ctx?.isArchive && pickedNum !== null) {
      showToast(t("save_failed_try_again") || t("not_available") || "Please try again.");

      const nextBtn =
        $("#tour-next-btn") ||
        $("#quiz-next-btn") ||
        document.querySelector('[data-action="tour-next"]');

      if (nextBtn) {
        nextBtn.classList.remove("is-loading");
        nextBtn.disabled = false;

        const isLast = (ctx.index >= TOUR_CONFIG.total - 1);
        nextBtn.textContent = isLast
          ? (t("tour_finish_button") || "Finish Tour →")
          : (t("tour_next_question") || "Next Question →");
      }

      return;
    }

    // input value (for non-mcq)
    const inputEl = document.getElementById("tour-input");
    const inputVal = inputEl ? String(inputEl.value || "").trim() : "";

    // expected answer (for input questions)
    const expectedRaw =
      (q?.correct_answer != null ? q.correct_answer
        : (q?.correctAnswer != null ? q.correctAnswer
        : (q?.correct != null ? q.correct
        : (q?.answer != null ? q.answer : null))));

        const expected = (expectedRaw == null) ? "" : String(expectedRaw).trim();

    if (!isMcq && !auto && !isValidInputAnswer(q, inputVal)) {
      const errEl = document.getElementById("tour-input-error");
      if (errEl) {
        errEl.textContent = t("invalid_answer_format");
        errEl.style.display = "block";
      } else {
        showToast(t("invalid_answer_format"));
      }
      return;
    }

    // correctness
    const isCorrect = isMcq
      ? isMcqPickedIndexCorrect({ ...q, correctIndex: correctIdx }, pickedNum)
      : isInputAnswerCorrect(inputVal, expected);
       
    ctx.answers = ctx.answers || [];
    ctx.answers.push({
      qid: q.id,
      pickedIndex: pickedNum,
      input: isMcq ? "" : inputVal,
      isCorrect,
      spentSec,
      index: ctx.index
    });

    if (isCorrect) ctx.correct += 1;

    // DB autosave (only for active tour). Await it before moving forward;
    // otherwise Finish can finalize score before the last answer reaches DB.
    try {
      const ctx2 = state.tourContext;
      if (ctx2?.attemptId && q?.id && !ctx2?.isArchive) {
        const spentSec2 = Math.max(0, Math.round((Date.now() - (ctx2.qStartedAt || Date.now())) / 1000));
        const pickedForDb = (pickedNum === null ? "" : (idxToLetter(pickedNum) || String(pickedNum)));

        const inputEl = document.getElementById("tour-input");
        const inputVal = inputEl ? String(inputEl.value || "").trim() : "";

        const answerForDb = isMcq ? pickedForDb : inputVal;
        const answerPatch = {
          user_answer: answerForDb,
          answered: true,
          is_correct: isCorrect,
          time_spent: spentSec2
        };

        const res = await upsertTourAnswer(ctx2.attemptId, q.id, answerPatch);

        if (!res?.ok) {
          ctx2.pendingDbAnswers = Array.isArray(ctx2.pendingDbAnswers) ? ctx2.pendingDbAnswers : [];
          ctx2.pendingDbAnswers.push({
            attemptId: ctx2.attemptId,
            questionId: q.id,
            patch: answerPatch
          });
          saveState();
        }
      }
    } catch {
      try {
        const ctx2 = state.tourContext;
        if (ctx2?.attemptId && q?.id && !ctx2?.isArchive) {
          const pickedForDb = (pickedNum === null ? "" : (idxToLetter(pickedNum) || String(pickedNum)));
          const answerForDb = isMcq ? pickedForDb : inputVal;
          ctx2.pendingDbAnswers = Array.isArray(ctx2.pendingDbAnswers) ? ctx2.pendingDbAnswers : [];
          ctx2.pendingDbAnswers.push({
            attemptId: ctx2.attemptId,
            questionId: q.id,
            patch: {
              user_answer: answerForDb,
              answered: true,
              is_correct: isCorrect,
              time_spent: spentSec
            }
          });
          saveState();
        }
      } catch {}
    }

    // anti-slip: current answered question no longer needs secrets in runtime
    stripAnsweredTourQuestionInRuntime(ctx, ctx.index);

    // clear transient pick cache before moving on
    ctx._pickedIndex = null;

    // next index
    ctx.index += 1;
    saveState();

    if (ctx.index >= TOUR_CONFIG.total) {
      finishTour({ reason: auto ? "auto_done" : "done" }).catch(() => null);
      return;
    }

    renderTourQuestion();
  }
   
                  async function isTourGloballyClosed(
  subjectKey,
  tourNo,
  seasonIdArg = null
) {
  try {
    if (!window.sb) return false;

    const subjectId = await getSubjectIdByKey(subjectKey);
    if (!subjectId) return false;

    const seasonId =
      Number(seasonIdArg || 0) ||
      await getCurrentSeasonId();

    let query = window.sb
      .from("tours")
      .select(
        "id, tour_no, season_id, start_date, end_date, is_active"
      )
      .eq("subject_id", subjectId)
      .eq("tour_no", Number(tourNo || 0));

    if (seasonId > 0) {
      query = query.eq("season_id", seasonId);
    }

    const { data, error } = await query
      .limit(1)
      .maybeSingle();

    if (error || !data) return false;

    const today = new Date();
    const todayISO =
      `${today.getFullYear()}-` +
      `${String(today.getMonth() + 1).padStart(2, "0")}-` +
      `${String(today.getDate()).padStart(2, "0")}`;

    const endDate = String(data?.end_date || "").trim();
    if (!endDate) return false;

    return endDate < todayISO;
  } catch {
    return false;
  }
}

   function renderTourResultStatusSummary() {
  const reviewStatusEl = document.getElementById("tour-review-status");
  const certStatusEl = document.getElementById("tour-certificate-status");
  const noteWrapEl = document.getElementById("tour-result-summary-note");
  const noteTextEl = document.getElementById("tour-result-summary-text");

  if (!reviewStatusEl || !certStatusEl || !noteWrapEl || !noteTextEl) return;

  const payload = state?.courses?.lastTourReviewPayload || null;
  const items = Array.isArray(payload?.items) ? payload.items : [];
  const wrong = items.filter(x => !x?.isCorrect);
  const right = Math.max(0, items.length - wrong.length);

  const rawEndDate = String(state?.courses?.lastTourEndDate || "").trim();
  const endLabel = rawEndDate || tr3("после глобального завершения тура", "tur global yopilgandan keyin", "after the tour is globally closed");

  reviewStatusEl.textContent = rawEndDate
    ? tr3(`Полный разбор откроется после ${endLabel}.`, `${endLabel} dan keyin to‘liq tahlil ochiladi.`, `Full review will open after ${endLabel}.`)
    : tr3("Полный разбор откроется после глобального завершения тура.", "Tur global yopilgandan keyin to‘liq tahlil ochiladi.", "Full review will open after the tour is globally closed.");

  certStatusEl.textContent = rawEndDate
    ? tr3(`Сертификат станет доступен после ${endLabel}, если выполнены условия.`, `${endLabel} dan keyin, shartlar bajarilgan bo‘lsa, sertifikat ochiladi.`, `The certificate will become available after ${endLabel}, if the conditions are met.`)
    : tr3("Сертификат станет доступен после глобального завершения тура, если выполнены условия.", "Tur global yopilgandan keyin, shartlar bajarilgan bo‘lsa, sertifikat ochiladi.", "The certificate will become available after the tour is globally closed, if the conditions are met.");

  if (!items.length) {
    noteWrapEl.hidden = true;
    return;
  }

  const topicList = [...new Set(
    wrong
      .map(x => String(x?.topic || "").trim())
      .filter(Boolean)
  )].slice(0, 3);

  const topicText = topicList.length ? topicList.join(", ") : tr3("без выделенных тем", "ajratilgan mavzularsiz", "no highlighted topics");

  noteTextEl.textContent = tr3(
    `Сейчас доступна краткая сводка: верно ${right} из ${items.length}, ошибок ${wrong.length}. Слабые темы: ${topicText}.`,
    `Hozir qisqa xulosa mavjud: ${items.length} ta savoldan ${right} tasi to‘g‘ri, ${wrong.length} ta xato. Zaif mavzular: ${topicText}.`,
    `A short summary is available now: ${right} correct out of ${items.length}, ${wrong.length} wrong. Weak topics: ${topicText}.`
  );

  noteWrapEl.hidden = false;
}
   async function renderTourReview() {
  const wrap = $("#tour-review-list");
  if (!wrap) return;

  wrap.innerHTML = `<div class="empty muted">${escapeHTML(t("loading") || "Загрузка…")}</div>`;

  const attemptId = Number(state?.courses?.lastTourAttemptId || 0);
  const localPayload = state?.courses?.lastTourReviewPayload || null;
  const currentSubjectKey = String(state?.courses?.subjectKey || "").trim();
  const payloadSubjectKey = String(localPayload?.subjectKey || "").trim();
  const payloadItems = Array.isArray(localPayload?.items) ? localPayload.items : [];

  const hasFreshLocalTourPayload =
    payloadItems.length > 0 &&
    (!currentSubjectKey || !payloadSubjectKey || currentSubjectKey === payloadSubjectKey);

  const renderFromDetails = (details) => {
    const mistakesOnly = (Array.isArray(details) ? details : []).filter(d => !d.isCorrect);

    if (!mistakesOnly.length) {
      wrap.innerHTML = `
        <div class="empty muted">${escapeHTML(t("tour_review_no_mistakes") || "По этому туру ошибок не найдено.")}</div>
        <div class="list-item" style="margin-top:12px">
          <div class="muted small">${escapeHTML(t("tour_review_practice_hint") || "Отработать темы дополнительно можно в практике.")}</div>
          <div style="margin-top:10px">
            <button class="btn" type="button" data-action="tour-review-open-practice">
              ${escapeHTML(t("tour_review_open_practice") || "Открыть практику")}
            </button>
          </div>
        </div>
      `;
      return;
    }

    wrap.innerHTML = mistakesOnly.map((d, idx) => {
      const qForFmt = {
        qtype: d.type,
        options_text: Array.isArray(d.options) ? JSON.stringify(d.options) : null,
        options_text_ru: Array.isArray(d.options) ? JSON.stringify(d.options) : null,
        options_text_uz: Array.isArray(d.options) ? JSON.stringify(d.options) : null,
        options_text_en: Array.isArray(d.options) ? JSON.stringify(d.options) : null
      };

      const userDisp = formatAnswerForDisplay(qForFmt, d.userAnswer);
      const corrDisp = formatAnswerForDisplay(qForFmt, d.correctAnswer);

      return `
        <div class="list-item">
          <div style="display:flex;align-items:flex-start;gap:10px">
            <div style="font-size:24px;line-height:1">${d.isCorrect ? "✓" : "✕"}</div>
            <div style="min-width:0;flex:1">
              <div style="font-weight:900">${escapeHTML(`${idx + 1}. ${d.topic || (t("topic_general") || "General")}`)}</div>
              ${
                d.subtopic
                  ? `<div class="muted small" style="margin-top:4px">${escapeHTML(String(d.subtopic))}</div>`
                  : ""
              }
              ${d.difficulty ? `<div class="muted small" style="margin-top:4px">${escapeHTML(String(d.difficulty))}</div>` : ""}
              <div style="margin-top:10px">${escapeHTML(d.question || "")}</div>
              <div class="muted small" style="margin-top:10px">
                ${escapeHTML(t("rec_your_answer") || "Ваш ответ")}: <b>${escapeHTML(userDisp || "—")}</b>
              </div>
              <div class="muted small" style="margin-top:4px">
                ${escapeHTML(t("rec_correct_answer") || "Правильный")}: <b>${escapeHTML(corrDisp || "—")}</b>
              </div>
              ${d.explanation ? `
                <div class="muted small" style="margin-top:10px">
                  <b>${escapeHTML(t("explanation_label") || "Explanation")}:</b> ${escapeHTML(d.explanation)}
                </div>
              ` : ""}
            </div>
          </div>
        </div>
      `;
    }).join("") + `
      <div class="list-item" style="margin-top:12px">
        <div class="muted small">${escapeHTML(t("tour_review_practice_hint") || "Отработать темы дополнительно можно в практике.")}</div>
        <div style="margin-top:10px">
          <button class="btn" type="button" data-action="tour-review-open-practice">
            ${escapeHTML(t("tour_review_open_practice") || "Открыть практику")}
          </button>
        </div>
      </div>
    `;
  };

  // 1) instant local payload right after finish
  if (hasFreshLocalTourPayload) {
    renderFromDetails(payloadItems);
    return;
  }

  // 2) DB-backed version (authoritative fallback)
  if (!window.sb || !attemptId) {
    renderFromDetails([]);
    return;
  }

  showAsyncOverlay(tr3(
    "Загружаем разбор тура…",
    "Tur tahlili yuklanmoqda…",
    "Loading tour review…"
  ));

  try {
    const { data, error } = await window.sb
      .from("tour_answers")
      .select(`
        question_id,
        user_answer,
        is_correct,
        time_spent,
        question:questions(
          id,
          topic,
          subtopic,
          difficulty,
          qtype,
          question_text,
          options_text,
          correct_answer,
          explanation,
          question_text_ru,
          question_text_uz,
          question_text_en,
          options_text_ru,
          options_text_uz,
          options_text_en,
          explanation_ru,
          explanation_uz,
          explanation_en
        )
      `)
      .eq("attempt_id", attemptId)
      .eq("answered", true)
      .limit(100);

    if (error || !Array.isArray(data) || !data.length) {
      renderFromDetails([]);
      return;
    }

    const details = data.map((x, idx) => {
      const q = x?.question || {};
      const type = String(q?.qtype || "mcq").toLowerCase() === "input" ? "input" : "mcq";
      const options = parseOptionsText(pickContentText(q, "options_text") || "") || [];

      let normalizedIsCorrect = !!x?.is_correct;

      if (type === "mcq") {
        const uaDisp = formatAnswerForDisplay(q, x.user_answer);
        const caDisp = formatAnswerForDisplay(q, q.correct_answer);
        if (uaDisp && caDisp && uaDisp === caDisp) normalizedIsCorrect = true;
      }

      return {
        id: Number(q?.id || x?.question_id || idx + 1),
        topic: q?.topic || (t("topic_general") || "General"),
        subtopic: q?.subtopic || null,
        difficulty: q?.difficulty || "easy",
        type,
        question: pickContentText(q, "question_text") || "",
        options,
        userAnswer: String(x?.user_answer ?? ""),
        correctAnswer: String(q?.correct_answer ?? ""),
        explanation: pickContentText(q, "explanation") || "",
        isCorrect: normalizedIsCorrect,
        timeSpent: Number(x?.time_spent || 0)
      };
    });

    renderFromDetails(details);
  } catch {
    renderFromDetails([]);
  } finally {
    hideAsyncOverlay();
  }
}
   
   function getTourHistoryKey(subjectKey, tourNo) {
  return `tour_history:${subjectKey || "unknown"}:${tourNo || 1}`;
}

function loadTourHistoryLocal(subjectKey, tourNo) {
  try {
    const raw = localStorage.getItem(getTourHistoryKey(subjectKey, tourNo));
    const arr = raw ? JSON.parse(raw) : [];
    return Array.isArray(arr) ? arr : [];
  } catch {
    return [];
  }
}

function saveTourAttemptLocal(subjectKey, tourNo, attempt) {
  try {
    const key = getTourHistoryKey(subjectKey, tourNo);
    const arr = loadTourHistoryLocal(subjectKey, tourNo);
    arr.unshift(attempt);
    localStorage.setItem(key, JSON.stringify(arr.slice(0, 20)));
  } catch {}
}

   async function flushPendingTourAnswers(ctx) {
  if (!ctx || ctx.isArchive) return;

  const pend = Array.isArray(ctx.pendingDbAnswers) ? ctx.pendingDbAnswers : [];
  if (!pend.length) return;

  const keep = [];
  for (const item of pend) {
    try {
      const res = await upsertTourAnswer(item.attemptId, item.questionId, item.patch || {});
      if (!res?.ok) keep.push(item);
    } catch {
      keep.push(item);
    }
  }

    ctx.pendingDbAnswers = keep;
  saveState();

  // ✅ also mirror to global pending queue so answers survive even after ctx is cleared
  try {
    for (const item of keep) {
      enqueuePendingOp({
        type: "tour_answer",
        attemptId: item.attemptId,
        questionId: item.questionId,
        patch: item.patch || {}
      });
    }
  } catch {}
}
   
    async function finishTour({ reason = "done" } = {}) {
    stopTourTick();

    // anti-slip: before any final state save, strip all question secrets from runtime
    try {
      if (state?.tourContext && !state.tourContext.isArchive) {
        state.tourContext = stripActiveTourContextSecrets(state.tourContext);
      }
    } catch {}

  // UI feedback: saving (prevents “app frozen” feeling)
  const nextBtn =
    $("#tour-next-btn") ||
    $("#quiz-next-btn") ||
    document.querySelector('[data-action="tour-next"]');

  if (nextBtn) {
    nextBtn.disabled = true;
    nextBtn.classList.add("is-loading");
    nextBtn.textContent = (t("saving") || "Сохранение…");
  }

  const monitor = document.getElementById("tour-monitor");
  if (monitor) monitor.textContent = (t("saving") || "Сохранение…");

  const ctx = state.tourContext;

  // duration/score summary (used for local + DB)
  const durationSec = Math.max(0, Math.round((Date.now() - (ctx?.startedAt || Date.now())) / 1000));
    const total = TOUR_CONFIG.total;
  let score = Array.isArray(ctx?.answers)
    ? ctx.answers.filter(a => !!a?.isCorrect).length
    : Number(ctx?.correct || 0);
  let percent = total ? Math.round((score / total) * 100) : 0;

  // Save attempt locally (for stats/trend). Does not affect future DB integration.
  if (ctx?.subjectKey) {
    saveTourAttemptLocal(ctx.subjectKey, ctx.tourNo || 1, {
      ts: Date.now(),
      score,
      total,
      percent,
      durationSec
    });
  }

       // DB finalize (only active tours)
  let finalizeSavedToDb = false;

  try {
    if (ctx?.attemptId && !ctx?.isArchive) {
            const finalizePatch = {
        score,
        percent,
        total_time: durationSec,
        expected_answer_rows: Array.isArray(ctx?.answers) ? ctx.answers.length : 0,
        status:
          (reason === "violations") ? "anti_cheat"
          : (reason === "time_expired") ? "time_expired"
          : "submitted"
      };

      // 1) сначала пытаемся досохранить ответы
      await flushPendingTourAnswers(ctx);

      // 2) если ответы НЕ успели уйти в БД — НЕ ставим submitted сейчас
      const stillPending =
        Array.isArray(ctx?.pendingDbAnswers) && ctx.pendingDbAnswers.length > 0;

      if (stillPending) {
        enqueuePendingOp({
          type: "tour_finalize",
          attemptId: ctx.attemptId,
          patch: finalizePatch
        });

        try { scheduleFlushPendingOps(700); } catch {}

        showToast(t("save_failed_try_again") || "Не удалось сохранить. Проверьте интернет.");
      } else {
        // 3) ответы ушли — можно финализировать attempt
               const res = await updateTourAttempt(ctx.attemptId, finalizePatch);

        if (res?.ok && res.score !== undefined) {
          score = Number(res.score || 0);
          percent = Number(res.percent || 0);
        }

        if (!res?.ok) {
          enqueuePendingOp({
            type: "tour_finalize",
            attemptId: ctx.attemptId,
            patch: finalizePatch
          });

          try { scheduleFlushPendingOps(700); } catch {}

          showToast(t("save_failed_try_again") || "Не удалось сохранить. Проверьте интернет.");
        } else {
          finalizeSavedToDb = true;
        }
      }
    }
  } catch {}

  // result meta
  const meta = $("#tour-result-meta");
    if (meta && ctx) {
    meta.textContent = t("tour_result_meta", {
        score,
        total: TOUR_CONFIG.total,
        v: (ctx.violations || 0)
      });
  }

  if (ctx?.isArchive) {
     showToast(t("tour_archive_toast"));
   } else if (reason === "violations") {
     showToast(t("tour_violations_finish_toast"));
   }

      // Earned Credentials — tour finished
  try {
    const subject_id = normSubjectId(ctx?.subjectKey || state?.courses?.subjectKey);
    const tour_id = ctx?.tourId != null ? String(ctx.tourId) : "";
    const is_archive = !!ctx?.isArchive;

        try {
      const finishStatus =
        (reason === "violations") ? "anti_cheat"
        : (reason === "time_expired") ? "time_expired"
        : "submitted";

      trackEvent("tour_attempt_finished", {
        ts: new Date().toISOString(),
        status: finishStatus,
        tour_id,
        attempt_id: ctx?.attemptId != null ? String(ctx.attemptId) : "",
        is_archive,
        subject_id: String(subject_id || ""),
        subject_key: String(ctx?.subjectKey || state?.courses?.subjectKey || ""),
        tour_no: Number(ctx?.tourNo || 0),
        score: Number(score || 0),
        percent: Number(percent || 0),
        total_time: Number(durationSec || 0),
        violations: Number(ctx?.violations || 0)
      });
    } catch {}

    try { _homeStatsCache?.clear?.(); } catch {}

    // save result context for certificate button + review screen
    state.courses = state.courses || {};
    state.courses.lastTourAttemptId = ctx?.attemptId || null;
    state.courses.lastTourCertificateId = null;

    try {
      const reviewItems = Array.isArray(ctx?.answers)
        ? ctx.answers.map((ans, idx) => {
            const q = ctx?.questions?.[Number(ans.index)] || null;
            const qType = String(q?.type || q?.qtype || "mcq").toLowerCase();
            const isMcq = (qType === "mcq" || qType === "multiple_choice");

            const userAnswer = isMcq
              ? ((ans?.pickedIndex === null || ans?.pickedIndex === undefined) ? "" : (idxToLetter(Number(ans.pickedIndex)) || String(ans.pickedIndex)))
              : String(ans?.input || "").trim();

            const correctAnswer =
              q?.correct_answer != null
                ? String(q.correct_answer).trim()
                : (q?.correctAnswer != null
                    ? String(q.correctAnswer).trim()
                    : ((q?.correctIndex !== null && q?.correctIndex !== undefined)
                        ? (idxToLetter(Number(q.correctIndex)) || String(q.correctIndex))
                        : ""));

            return {
              id: Number(q?.id || idx + 1),
              topic: q?.topic || (t("topic_general") || "General"),
              subtopic: q?.subtopic || null,
              difficulty: q?.difficulty || "easy",
              type: isMcq ? "mcq" : "input",
              question: q?.question || "",
              options: Array.isArray(q?.options) ? q.options.slice() : [],
              userAnswer,
              correctAnswer,
              explanation: pickContentText(q || {}, "explanation") || "",
              isCorrect: !!ans?.isCorrect,
              timeSpent: Number(ans?.spentSec || 0)
            };
          })
        : [];

      state.courses.lastTourReviewPayload = {
        attemptId: ctx?.attemptId || null,
        subjectKey: ctx?.subjectKey || null,
        tourNo: ctx?.tourNo || 1,
        items: reviewItems
      };

      state.courses.lastTourEndDate = String(ctx?.tourEndDate || "").trim() || null;

      // локально сохраняем туровые рекомендации по ошибкам
      addMyTourRecsFromTourAttempt(ctx);
    } catch {
      state.courses.lastTourReviewPayload = null;
    }

    if (!state.certificates) {
      state.certificates = { selectedId: null, lastIssuedId: null };
    }

    // Сертификаты не выдаём сразу после финиша.
    // Они становятся доступны только после глобального завершения тура / всех туров.
    if (
      finalizeSavedToDb &&
      ctx?.attemptId &&
      !ctx?.isArchive &&
      reason !== "violations"
    ) {
      state.courses.lastTourCertificateId = null;
    }
  } catch {}

  // unlock
  state.quizLock = null;
  state.tourContext = null;
  saveState();

  pushCourses("tour-result");
  renderTourResultStatusSummary();
  refreshLiveProgressSurfaces();

  if (finalizeSavedToDb && !ctx?.isArchive) {
    showToast(
      t("tour_result_saved_toast") ||
      "Результат сохранён. Вы можете посмотреть своё место в рейтинге. Подробный разбор будет доступен после завершения тура для всех участников."
    );
  }
}

  function formatMsToMMSS(ms) {
    const sec = Math.max(0, Math.floor(ms / 1000));
    const mm = Math.floor(sec / 60);
    const ss = sec % 60;
    return `${mm}:${String(ss).padStart(2, "0")}`;
  }

  // ---------------------------
// Global UI bindings
// ---------------------------
function bindTabbar() {
  let lastTapTs = 0;

    const handle = async (btn) => {
  const tab = btn.dataset.tab;
  if (!tab) return;
    
     // ✅ До регистрации табы запрещены (и на registration таббар скрыт, но это страховка)
  if (!isRegistered()) {
    showToast(t("complete_registration_first") || "Сначала завершите регистрацию.");
    showView("registration");
    return;
  }

         if (!(await enforceActiveIdentityOrBlock({ source: `tab_${tab}`, force: true }))) {
    return;
  }
       
    // ✅ Ratings доступен только школьникам
    if (tab === "ratings") {
      const p = loadProfile();
      if (!p || !p.is_school_student) {
        showToast(t("disabled_not_school"));
        return;
      }
    }

    if (state.quizLock === "tour") {
      showToast("Tour is in progress");
      return;
    }
    if (state.quizLock === "practice") {
      showToast("Pause practice to leave");
      return;
    }

    // ✅ Требование: кнопка нижнего таба “Courses” всегда открывает All Subjects
      if (tab === "courses") {
        setTab("courses");
        replaceCourses("all-subjects"); // сбрасывает stack + показывает all-subjects

     // ✅ фикс: Subjects не обновлялись при смене UI-языка до перезагрузки
        renderAllSubjects();

        updateTopbarForView("courses");
        return;
      }
    setTab(tab);
  };

  $$(".tabbar .tab").forEach(btn => {
    // ✅ Mobile-friendly: pointerup работает стабильнее, чем click в WebView
        btn.addEventListener("pointerup", (e) => {
      const now = Date.now();
      if (now - lastTapTs < 250) return; // антидубль
      lastTapTs = now;

      e.preventDefault();
      handle(btn).catch(() => null);

      // ✅ убираем “липкий” focus на мобилках
      try { btn.blur(); } catch {}
    });

    // ✅ Desktop fallback
    btn.addEventListener("click", () => {
      handle(btn).catch(() => null);
      try { btn.blur(); } catch {}
    });
  });
}

  function bindTopbar() {
    const backBtn = $("#topbar-back");
    if (!backBtn) return;

    backBtn.addEventListener("click", async (event) => {
  event.stopPropagation();
  if (state.quizLock) return;

  if (!(await enforceActiveIdentityOrBlock({ source: "topbar_back", force: true }))) {
    event.preventDefault();
    return;
  }

    // ✅ Registration: назад = закрыть апп (возвращаться некуда)
  const regView = document.getElementById("view-registration");
  const isRegistrationActive =
    !!(regView && regView.classList.contains("is-active")) ||
    (Array.isArray(state?.viewStack) && state.viewStack[state.viewStack.length - 1] === "registration");

  if (isRegistrationActive) {
    try {
      if (window.Telegram?.WebApp?.close) {
        window.Telegram.WebApp.close();
        return;
      }
    } catch {}

    try { history.back(); } catch {}
    return;
  }

    const topView = state.viewStack?.[state.viewStack.length - 1];

    if (topView === "certificates" && Number(state?.certificates?.selectedId || 0) > 0) {
    showViewTransitionOverlay(260);
    state.certificates.selectedId = null;
    saveState();
    renderCertificatesView();
    updateTopbarForView("certificates");
    return;
  }

    // If we are on global screen -> go back in global stack
  if (topView && ["resources","news","notifications","community","about","support","support-topic","certificates","archive"].includes(topView)) {
    showViewTransitionOverlay(260);
    globalBack();
    return;
  }

      // ✅ Profile back MUST work even if state.tab accidentally isn't "profile"
const ps = document.getElementById("profile-settings");
const psActive = !!(ps && ps.classList.contains("is-active") && ps.hidden !== true);

// 1) Если реально открыт экран настроек профиля — возвращаем на main напрямую
if (psActive) {
  state.tab = "profile";
  replaceProfile("main");     // stack=["main"] + showProfileScreen("main")
  renderProfileMain();        // чтобы сразу перерисовать
  updateTopbarForView("profile");
  return;
}

// 2) Обычный сценарий профиля
if (state.tab === "profile") {
  popProfile();
  renderProfileStack();
  return;
}



      // If in courses -> pop courses stack
      if (state.tab === "courses") {
        popCourses();
        return;
      }
    });
  }

  function bindRegistration() {
    // ---------------------------
    // Registration language: default from Telegram user language_code
    // ---------------------------
    const langSel = $("#reg-language");
    if (langSel && !langSel.dataset.init) {
      const tgLang = window.Telegram?.WebApp?.initDataUnsafe?.user?.language_code || "";
      const defLang = window.i18n?.normalizeLang ? window.i18n.normalizeLang(tgLang || "ru") : "ru";

      langSel.value = defLang || "ru";
      langSel.dataset.init = "1";

      try { window.i18n?.setLang(langSel.value); } catch {}
      try { applyStaticI18n(); } catch {}
    }
    const isSchool = $("#reg-is-school");
const isSchoolToggle = $("#reg-is-school-toggle");

if (isSchool && isSchool.dataset.boundChange !== "1") {
  isSchool.addEventListener("change", updateSchoolFieldsVisibility);
  isSchool.dataset.boundChange = "1";
}
if (isSchoolToggle && isSchoolToggle.dataset.boundChange !== "1") {
  isSchoolToggle.addEventListener("change", updateSchoolFieldsVisibility);
  isSchoolToggle.dataset.boundChange = "1";
}

updateSchoolFieldsVisibility();

    initRegionDistrictUI();
    initRegSubjectChips();

    refreshActiveSubjectsCatalogFromSupabase()
      .then(() => {
        try { applyRegSubjectI18n(); } catch {}
      })
      .catch(() => null);

    const form = $("#reg-form");
if (!form) return;
if (form.dataset.submitBound === "1") return;
form.dataset.submitBound = "1";

form.addEventListener("submit", async (e) => {
  e.preventDefault();

    const submitBtn = form.querySelector('button[type="submit"]');
  const __prevSubmitText = submitBtn ? submitBtn.textContent : null;

    if (submitBtn) {
    submitBtn.disabled = true;
    submitBtn.textContent = (t("saving") || "Сохранение…");
    submitBtn.classList.add("is-loading");
  }

  showAsyncOverlay(tr3(
    "Сохраняем регистрацию…",
    "Ro‘yxatdan o‘tish saqlanmoqda…",
    "Saving registration…"
  ));

    try {
    const fullName = $("#reg-fullname")?.value?.trim() || "";
    const lang = $("#reg-language")?.value || "ru";
    const consentEl = $("#reg-consent");

    if (!consentEl?.checked) {
      showToast(
        tr3(
          "Подтвердите согласие с условиями и обработкой данных.",
          "Shartlar va ma’lumotlarni qayta ishlashga rozilikni tasdiqlang.",
          "Please confirm your agreement with the terms and data processing."
        )
      );
      return;
    }
    let region = "";
    let district = "";

    let region_tr = null;
    let district_tr = null;

    let region_id = null;
    let district_id = null;

    const regionEl = $("#reg-region");
    const districtEl = $("#reg-district");

    if (regionEl && regionEl.value) {
      region_id = Number(regionEl.value) || null;
      const regionOpt = regionEl.options[regionEl.selectedIndex];
      region = regionOpt ? regionOpt.textContent.trim() : "";
      region_tr = regionOpt ? { ru: regionOpt.dataset.ru || "", uz: regionOpt.dataset.uz || "", en: regionOpt.dataset.en || "" } : null;
    }

    if (districtEl && districtEl.value) {
      district_id = Number(districtEl.value) || null;
      const districtOpt = districtEl.options[districtEl.selectedIndex];
      district = districtOpt ? districtOpt.textContent.trim() : "";
      district_tr = districtOpt ? { ru: districtOpt.dataset.ru || "", uz: districtOpt.dataset.uz || "", en: districtOpt.dataset.en || "" } : null;
    }

    const isSchoolStudent = ($("#reg-is-school-toggle")?.checked || $("#reg-is-school")?.value === "yes");
const school = $("#reg-school")?.value?.trim() || "";
const klass = $("#reg-class")?.value?.trim() || "";

const main1Raw = $("#reg-main-subject-1")?.value || "";
const main2Raw = $("#reg-main-subject-2")?.value || "";
const add1Raw = $("#reg-additional-subject")?.value || "";

const main1 = isSubjectActive(main1Raw) ? main1Raw : "";
const main2 = isSubjectActive(main2Raw) ? main2Raw : "";
const add1 = isSubjectActive(add1Raw) ? add1Raw : "";

const langNorm = String(lang || "ru").toLowerCase();
const langAllowed = ["ru", "uz", "en"].includes(langNorm);

const regionSelected = Number(region_id) > 0;
const districtSelected = Number(district_id) > 0;

if (
  !fullName ||
  !langAllowed ||
  !regionSelected ||
  !district ||
  !districtSelected ||
  (isSchoolStudent && (!main1 || !school || !klass))
) {
  showToast(t("fill_required_fields"));
  return;
}
    const subjects = [];

    if (isSchoolStudent) {
      subjects.push({
        key: main1,
        mode: "competitive",
        pinned: false
      });

      if (main2) {
        subjects.push({
          key: main2,
          mode: "competitive",
          pinned: false
        });
      }

      if (add1) {
        subjects.push({
          key: add1,
          mode: "study",
          pinned: true
        });
      }
    } else {
      // Non-school users: no subjects during registration.
      // They can study/practice all subjects without tours and manage subjects later in Profile.
    }

        if (subjects.filter(s => s.mode === "competitive").length > 2) {
      showToast(t("competitive_subjects_limit_2"));
      return;
    }

    const subjectKeys = subjects.map(s => String(s?.key || "").trim()).filter(Boolean);
    if (new Set(subjectKeys).size !== subjectKeys.length) {
      showToast(
        tr3(
          "Выберите разные предметы: одинаковые предметы нельзя указать несколько раз.",
          "Turli fanlarni tanlang: bir xil fanni bir necha marta ko‘rsatib bo‘lmaydi.",
          "Choose different subjects: the same subject cannot be selected more than once."
        )
      );
      return;
    }

    const tgUser = tg?.initDataUnsafe?.user || {};
    const avatar = tgUser?.photo_url || "";

        const profile = {
      created_at: nowISO(),
      full_name: fullName,
      language: lang,
      is_school_student: isSchoolStudent,

      region_id,
      district_id,

      region_tr,
      district_tr,

      region,
      district,
      school: isSchoolStudent ? school : "",
      class: isSchoolStudent ? klass : "",
      telegram: {
        id: tgUser?.id || null,
        username: tgUser?.username || null,
        first_name: tgUser?.first_name || null,
        last_name: tgUser?.last_name || null,
        photo_url: avatar || null
      },
      subjects
    };

    // ✅ Stage B: DB-backed registration (users + user_subjects)
    try {
      trackEvent("registration_db_save_started", {
        is_school_student: !!profile.is_school_student,
        subjects_count: Array.isArray(profile.subjects) ? profile.subjects.length : 0
      });
    } catch {}

    const dbRes = await saveRegistrationToSupabase(profile);

    try {
      trackEvent("registration_db_save_result", {
        ok: !!dbRes?.ok,
        reason: dbRes?.reason || null,
        subjects_saved: dbRes?.subjects_saved ?? null
      });
    } catch {}

            if (!dbRes?.ok) {
  hideAsyncOverlay();

  if (dbRes?.reason === "telegram_already_linked") {
    await confirmAndRecoverTelegramProfile({
      source: "registration_conflict"
    });
    return;
  }

  const uiErr = getRegistrationSaveErrorUi(dbRes);

  await uiAlert({
    title: uiErr.title,
    message: uiErr.recommendation
  });
  return;
}
            // keep local profile as UX fallback (DB is source of truth now)

      // ✅ fresh start after re-registration (prevents showing old local attempts/stats)
      try {
        localStorage.removeItem(LS.practiceDraft);
        localStorage.removeItem(LS.myRecs);
        localStorage.removeItem(LS.events);
        localStorage.removeItem(LS.credentials);
        // если уже линковали бота раньше — при новой регистрации разрешаем снова
        try { localStorage.removeItem(LS.botLinked); } catch {}
      } catch {}

      saveProfile({
        ...profile,
        id: dbRes?.user_id || profile?.id || null
      });

      // ✅ auto-link this user to bot (chat_id will be captured by bot on web_app_data)
      // отправляем чуть позже, чтобы UI успел перейти на Home
      try {
        setTimeout(() => {
          try { tryLinkBotOnce("registration"); } catch {}
        }, 300);
      } catch {}

      // Уже сохранили в БД выше (dbRes). Повторно НЕ сохраняем, чтобы не ловить ошибки/дубли.
      try {
        trackEvent("registration_db_saved", {
          ok: true,
          reason: null,
          user_subjects_rows: dbRes?.user_subjects_rows ?? null
        });
      } catch {}

                 window.i18n?.setLang(lang);
      applyStaticI18n();

      state.tab = "home";
      state.prevTab = "home";
      state.viewStack = ["home"];
      state.courses.stack = ["all-subjects"];
      state.courses.subjectKey = null;
      state.courses.lessonId = null;
      state.courses.entryTab = "home";
      state.quizLock = null;
      saveState();

      // порядок важен: сначала активируем таб, потом ждём критичные данные, потом рисуем
      setTab("home");
      await ensureHomeDbReady();
      renderHome();
      renderAllSubjects();
                } finally {
      hideAsyncOverlay();
      if (submitBtn) {
        submitBtn.disabled = false;
        submitBtn.classList.remove("is-loading");
        if (__prevSubmitText != null) submitBtn.textContent = __prevSubmitText;
      }
    }
  });
}
   
      function bindActions() {
    document.addEventListener("click", async (e) => {
  const btn = e.target.closest("[data-action]");
  if (!btn) return;

  const action = btn.dataset.action;

  // ✅ Если это уже неактивное устройство, не даём продолжать пользоваться старым UI.
  // Registration/recovery/certificate screens не блокируем.
  if (!(await enforceActiveIdentityOrBlock({ source: `action_${action}` }))) {
    e.preventDefault();
    e.stopPropagation();
    return;
  }

            // ===== Profile local navigation (must work from anywhere) =====
      if (action === "profile-settings") {
       setTab("profile");
       openProfileSettings();   // ✅ push в стек + правильный рендер
       return;
      }
    
      if (action === "profile-settings-back") {
     // ✅ ведём себя как обычный back: из settings -> main профиля
     if (state.tab !== "profile") setTab("profile");
     openProfileMain();
     return;
   }


      // ---------- Global navigation actions (available everywhere) ----------
      if (action === "back") { // generic back
  if (state.quizLock) return;

    // ✅ FALLBACK только когда реально открыт профиль.
  // Иначе stale profile-settings перехватывает back у Courses/Tours.
  const profileView = document.getElementById("view-profile");
  const profileViewActive = profileView && profileView.classList.contains("is-active");

  const ps = document.getElementById("profile-settings");
  const psActive =
    profileViewActive &&
    ps &&
    ps.classList.contains("is-active") &&
    ps.hidden !== true;

  if (psActive) {
    // возвращаемся на main профиля предсказуемо
    state.tab = "profile";
    openProfileMain();
    return;
  }

    const topView = state.viewStack?.[state.viewStack.length - 1];

  if (topView === "certificates" && Number(state?.certificates?.selectedId || 0) > 0) {
    state.certificates.selectedId = null;
    saveState();
    renderCertificatesView();
    updateTopbarForView("certificates");
    return;
  }

      if (topView && ["resources","news","notifications","community","about","support","support-topic","certificates","archive"].includes(topView)) {
    globalBack();
    return;
  }
  if (state.tab === "courses") {
    popCourses();
    return;
  }
  if (state.tab === "profile") {
    if (getProfileTopScreen() !== "main") {
      popProfile();
      return;
    }
    setTab(state.prevTab || "home");
    return;
  }
  if (state.tab === "ratings") {
    setTab(state.prevTab || "home");
    return;
  }
  return;
}

      if (action === "go-home") { setTab("home"); return; }
      if (action === "go-profile") { setTab("profile"); return; }
            if (action === "open-ratings") { setTab("ratings"); return; }
      if (action === "ratings-search") {
        const panel = document.getElementById("ratings-search-panel");
        const isOpen = !!panel && panel.style.display === "block";
        const input = document.getElementById("ratings-search");
        const v = String(input?.value || "").trim();

        if (!isOpen) {
          openRatingsSearchPanel();
          return;
        }

        // панель открыта
        if (v.length >= 2) {
          ratingsState.q = v;
          // сбрасываем paging при новом применении
          ratingsState._searchOffset = 0;
          ratingsState._searchRows = [];
          renderRatings();
          closeRatingsSearchPanel();
          return;
        }

        // пусто → просто закрыть
        closeRatingsSearchPanel();
        return;
      }
      if (action === "ratings-info") { openRatingsInfoModal(); return; }

                        if (action === "open-resources") { openGlobal("resources"); return; }

      if (action === "open-notifications") {
        openGlobal("notifications");
        await renderNotificationsView();
        return;
      }

      if (action === "notification-delete") {
        await deleteNotificationById(btn.dataset.id);
        return;
      }

      if (action === "notifications-delete-all") {
        await deleteAllVisibleNotifications();
        return;
      }

      if (action === "open-news") {
        openTelegramUrl("https://t.me/iClubuzofficial");
        return;
      }

      if (action === "open-community") {
        openTelegramUrl("https://t.me/+yp3GKhnohKQxOTdi");
        return;
      }

      if (action === "open-about") { openGlobal("about"); return; }

            if (action === "open-support") {
        openSupport();
        return;
      }

      if (action === "open-support-topic") {
        openSupportTopic(String(btn.dataset.key || "").trim());
        return;
      }

      if (action === "support-submit") {
        await submitSupportTicket();
        return;
      }

if (action === "open-subject-mentor") {
  const mentor = state?.courses?.subjectHubMentor;
  if (!mentor) return;

  if (!state.about) state.about = { tab: "project" };
  ensureTeamCacheInit();

  const mentorKey = String(mentor?.memberKey || memberKeyOf(mentor) || "");
  const currentMentors = Array.isArray(state.about.teamPeopleCache?.mentors)
    ? state.about.teamPeopleCache.mentors
    : [];

  state.about.teamPeopleCache.mentors = [
    {
      ...mentor,
      memberKey: mentorKey,
      group: "mentors",
      vacant: false
    },
    ...currentMentors.filter(x => String(x?.memberKey || memberKeyOf(x) || "") !== String(mentorKey))
  ];
  state.about.teamPeopleCacheTs.mentors = Date.now();

  clearAboutTeamResolvedCache();

  state.about.tab = "team";
  state.about.teamEntry = "subject";
  state.about.teamPrevScreen = "mentors";
  state.about.teamScreen = "member";
  state.about.teamMemberKey = mentorKey;
  saveState();

  openGlobal("about");
  renderAboutView();
  return;
}
      // ✅ About tabs
      if (action === "about-tab") {
  const tab = btn.dataset.tab || "project";
  if (!state.about) state.about = { tab: "project" };
  state.about.tab = tab;

  // reset team subview when switching tabs
  if (tab !== "team") {
    state.about.teamScreen = "overview";
    state.about.teamPrevScreen = "overview";
    state.about.teamMemberKey = null;
  }

  saveState();
  renderAboutView();
  return;
}

      // ✅ About → Team sub-screens
      if (action === "about-team-open") {
  const screen = btn.dataset.screen || "overview";
  if (!state.about) state.about = { tab: "project" };
  state.about.teamScreen = screen;
  saveState();

  // render instantly (fallback), then try DB/photos
  renderAboutView();
  try { ensureTeamPeopleLoaded(screen); } catch {}

  return;
}

if (action === "about-person-open") {
  const group = btn.dataset.group || "board";
  const key = btn.dataset.key || "";
  if (!state.about) state.about = { tab: "project" };

  const src = state.about.teamPeopleResolved?.[group] || [];
  const person = Array.isArray(src)
    ? src.find(x => String(x.memberKey || "") === String(key))
    : null;

  if (!person || person.vacant) return;

  state.about.teamPrevScreen = group;
  state.about.teamScreen = "member";
  state.about.teamMemberKey = key;
  saveState();
  renderAboutView();
  return;
}

      if (action === "about-team-back") {
  if (!state.about) state.about = { tab: "project" };

  // entered from Subject Hub mentor card → return back to subject
  if (state.about.teamScreen === "member" && state.about.teamEntry === "subject") {
    state.about.teamScreen = "overview";
    state.about.teamPrevScreen = "overview";
    state.about.teamMemberKey = null;
    state.about.teamEntry = null;
    saveState();

    globalBack();
    renderSubjectHub();
    return;
  }

  if (state.about.teamScreen === "member") {
    state.about.teamScreen = state.about.teamPrevScreen || "overview";
    state.about.teamMemberKey = null;
  } else {
    state.about.teamScreen = "overview";
  }

  saveState();
  renderAboutView();
  return;
}
      if (action === "home-extra-toggle") { toggleHomeExtra(); return; }
            if (action === "open-certificates") {
        if (!state.certificates) {
          state.certificates = { selectedId: null, lastIssuedId: null };
        }
        state.certificates.selectedId = null;
        saveState();

        openGlobal("certificates");
        return;
      }

                   if (action === "certificate-open") {
        const certId = Number(btn.dataset.id || 0);
        if (!certId) return;

        showCertificateFlowOverlay("certificate_access_checking", "Проверяем сертификат…");
        await waitForOverlayPaint();

        try {
          const rows = await fetchMyCertificatesDb();
          const row = rows.find(r => Number(r.id) === certId);

          if (!row) {
            showToast(t("certificates_empty") || "Пока сертификатов нет.");
            return;
          }

          const allowed = await canAccessCertificateRow(row);
          if (!allowed) {
            if (!state.certificates) {
              state.certificates = { selectedId: null, lastIssuedId: null };
            }
            state.certificates.selectedId = null;
            saveState();

            showToast(getCertificateLockedMessage(row));
            await renderCertificatesView();
            return;
          }

          if (!state.certificates) {
            state.certificates = { selectedId: null, lastIssuedId: null };
          }

                    state.certificates.selectedId = certId;
          saveState();

          try {
            trackEvent("certificate_opened", {
              certificate_id: certId,
              certificate_type: String(row?.certificate_type || ""),
              subject_key: String(row?.subject_key || ""),
              tour_no: row?.tour_no ?? null
            });
          } catch {}

          await renderCertificatesView();
        } finally {
          hideCertificateDownloadOverlay();
        }
        return;
      }

             if (action === "certificates-back") {
        if (!state.certificates) {
          state.certificates = { selectedId: null, lastIssuedId: null };
        }

        state.certificates.selectedId = null;
        saveState();

        await renderCertificatesView();
        return;
      }

             if (action === "certificate-download-png" || action === "certificate-download-pdf") {
        const certId = Number(btn.dataset.id || 0);
        if (!certId) return;

        showCertificateFlowOverlay("certificate_access_checking", "Проверяем сертификат…");
        await waitForOverlayPaint();

        try {
          const rows = await fetchMyCertificatesDb();
          const row = rows.find(r => Number(r.id) === certId);

          if (!row) {
            showToast(t("certificates_empty") || "Пока сертификатов нет.");
            return;
          }

          const allowed = await canAccessCertificateRow(row);
          if (!allowed) {
            if (!state.certificates) {
              state.certificates = { selectedId: null, lastIssuedId: null };
            }
            state.certificates.selectedId = null;
            saveState();

            showToast(getCertificateLockedMessage(row));
            await renderCertificatesView();
            return;
          }
        } finally {
          hideCertificateDownloadOverlay();
        }

        const rows = await fetchMyCertificatesDb();
        const row = rows.find(r => Number(r.id) === certId);
        if (!row) {
          showToast(t("certificates_empty") || "Пока сертификатов нет.");
          return;
        }

        if (action === "certificate-download-png") {
          await downloadCertificateAsPng(row);
          return;
        }

        await downloadCertificateAsPdf(row);
        return;
      }

      if (action === "open-archive") { openGlobal("archive"); return; }

         // All Subjects from anywhere (Home tile, etc.)
if (action === "open-all-subjects") {
  if (state.quizLock) return;
  setTab("courses");
  replaceCourses("all-subjects");
  renderAllSubjects();
  return;
}

            // Community links
      if (action === "open-channel") {
        openExternal("https://t.me/iClubuzofficial");
        return;
      }
      if (action === "open-chat") {
        openExternal("https://t.me/+yp3GKhnohKQxOTdi");
        return;
      }

      // ✅ About → Team: admin contact
      if (action === "open-admin") {
        openExternal("https://t.me/AzizbekErkinovNPS");
        return;
      }

            // Resources hub: global books button
      if (action === "open-books-global") {
        const profile = loadProfile();
        const subjects = Array.isArray(profile?.subjects) ? profile.subjects : [];
        const pick =
          subjects.find(s => s.mode === "competitive")?.key ||
          subjects.find(s => s.pinned)?.key ||
          subjects[0]?.key ||
          null;

        if (!pick) {
          showToast("Сначала выберите предметы в Courses.");
          return;
        }

        state.courses.subjectKey = pick;
        saveState();
        setTab("courses");

        replaceCourses("books");
        renderBooks();
        return;
      }

              if (action === "open-my-recs-global") {
  const profile = loadProfile();
  const subjects = Array.isArray(profile?.subjects) ? profile.subjects : [];
  const pick =
    subjects.find(s => s.mode === "competitive")?.key ||
    subjects.find(s => s.pinned)?.key ||
    subjects[0]?.key ||
    null;

  if (!pick) {
    showToast(t("pick_subjects_first_toast") || "Сначала выберите предметы в Courses.");
    return;
  }

  state.courses = state.courses || {};
  state.courses.subjectKey = pick;
  state.courses.myRecsActiveTab = state.courses.myRecsActiveTab || "practice";
  saveState();

  setTab("courses");

  try {
    trackEvent("recommendation_opened", {
      source: "global_my_recs",
      subject_id: normSubjectId(pick)
    });
  } catch {}

   showAsyncOverlay(tr3(
    "Загружаем рекомендации…",
    "Tavsiyalar yuklanmoqda…",
    "Loading recommendations…"
  ));

  try {
    replaceCourses("my-recs");
    await renderMyRecs();
  } finally {
    hideAsyncOverlay();
  }

  return;
}
      // ---------- Tab-specific / Courses actions ----------
        if (action === "profile-certificates") {
          if (!state.certificates) {
            state.certificates = { selectedId: null, lastIssuedId: null };
          }
          state.certificates.selectedId = null;
          saveState();

          openGlobal("certificates");
          return;
        }
        if (action === "profile-community") { openGlobal("community"); return; }
        if (action === "profile-about") { openGlobal("about"); return; }
               if (action === "profile-open-my-recs") {
  const profile = loadProfile();
  const subjects = Array.isArray(profile?.subjects) ? profile.subjects : [];
  const pick =
    subjects.find(s => s.mode === "competitive")?.key ||
    subjects.find(s => s.pinned)?.key ||
    subjects[0]?.key ||
    null;

  if (!pick) {
    showToast(t("pick_subjects_first_toast") || "Сначала выберите предметы в Courses.");
    return;
  }

  state.courses = state.courses || {};
  state.courses.subjectKey = pick;
  state.courses.myRecsActiveTab = state.courses.myRecsActiveTab || "practice";
  saveState();

  setTab("courses");

  try {
    trackEvent("recommendation_opened", {
      source: "profile_my_recs",
      subject_id: normSubjectId(pick)
    });
  } catch {}

  replaceCourses("my-recs");
  renderMyRecs();
  return;
}
   if (action === "my-rec-back") {
  showAsyncOverlay(tr3(
    "Загружаем рекомендации…",
    "Tavsiyalar yuklanmoqda…",
    "Loading recommendations…"
  ));

  try {
    replaceCourses("my-recs");
    await renderMyRecs();
  } finally {
    hideAsyncOverlay();
  }

  return;
}

if (action === "my-rec-open-books") {
  showAsyncOverlay(tr3(
    "Загружаем книги…",
    "Kitoblar yuklanmoqda…",
    "Loading books…"
  ));

  try {
    pushCourses("books");
    await renderBooks();
  } finally {
    hideAsyncOverlay();
  }

  return;
}
       
     if (action === "my-rec-open-practice") {
  await openPracticeStart();
  return;
}
       
if (action === "my-rec-retry") {
  startPracticeRetryMistakes();
  return;
}

if (action === "my-rec-delete") {
  deleteMyRecCurrent();
  return;
}

if (action === "my-rec-train") {
  startPracticeByRec();
  return;
}
if (action === "my-rec-repeat-drill") {
  const d = state?.courses?.myRecDrillLast;
  if (!d) return;

  // repeat the same type of drill
  if (d.drillType === "rec_mistakes") {
    startPracticeRetryMistakes();
    return;
  }
  if (d.drillType === "rec_topic") {
    startPracticeByRec();
    return;
  }
  return;
}
if (action === "profile-open-courses") {
  setTab("courses");
  replaceCourses("all-subjects");
  renderAllSubjects();
  return;
}

if (action === "my-rec-to-subject") {
  state.courses = state.courses || {};
  state.courses.myRecReturnTarget = null;
  saveState();

  showAsyncOverlay(tr3(
    "Загружаем предмет…",
    "Fan yuklanmoqda…",
    "Loading subject…"
  ));

  try {
    replaceCourses("subject-hub");
    await renderSubjectHub();
  } finally {
    hideAsyncOverlay();
  }

  return;
}

if (action === "tour-to-subject") {
  state.courses = state.courses || {};
  state.courses.myRecReturnTarget = null;
  saveState();

  await openPracticeStart();
  return;
}
       
if (action === "profile-open-ratings") {
  setTab("ratings");
  return;
}

      // Courses actions
      if (action === "to-subject-hub") {
  // ✅ return to My Rec Detail only from practice drill flow,
  // never from tours / tour result / tour review
  try {
    const d = state?.courses?.myRecDrillLast;
    const top = getCoursesTopScreen();
    const fromPracticeFlow = ["practice-result", "practice-review", "practice-recs"].includes(top);

    if (fromPracticeFlow && d?.drillType && state?.courses?.myRecReturnTarget === "my-rec-detail") {
      replaceCourses("my-rec-detail");
      renderMyRecDetail();
      return;
    }
  } catch {}

  replaceCourses("subject-hub");
  renderSubjectHub();
  return;
}

      if (action === "open-all-subjects") {
        replaceCourses("all-subjects");
        renderAllSubjects();
        return;
      }

      if (action === "open-lessons") {
  pushCourses("video");
  renderVideo().catch(() => null);
  return;
}

            if (action === "open-practice") {
        await openPracticeStart();
        return;
      }

      if (action === "practice-start") {
  startPracticeNew();
  return;
}

if (action === "practice-select-tour") {
  const tourNo = Number(btn.dataset.tourNo || 0);
  if (tourNo > 0) {
    showAsyncOverlay(tr3(
      "Загружаем практику…",
      "Amaliyot yuklanmoqda…",
      "Loading practice…"
    ));

    setSelectedPracticeTourNo(state.courses.subjectKey, tourNo);
    updatePracticeStartButtonForTour(tourNo, false);

    try {
  await renderPracticeStart();
} finally {
  hideAsyncOverlay();
}
  }
  return;
}
       
if (action === "practice-start-past") {
  // legacy fallback: old button no longer exists, but keep safe behavior
  startPracticeNew();
  return;
}

   if (action === "practice-resume") {
  const subjectKey = state.courses.subjectKey;
  const draft = loadPracticeDraft();

  const draftTourNo = Number(draft?.practiceTourNo || draft?.quiz?.practiceTourNo || 1);

if (!(draft?.status === "paused" && draft?.subjectKey === subjectKey && draft?.quiz && draftTourNo > 0)) {
  showToast(t("not_available"));
  return;
}

setSelectedPracticeTourNo(subjectKey, draftTourNo);

  try {
    await initSupabaseSession();
  } catch {}

  const restoredQuiz = await restorePracticeQuizSecrets(draft.quiz);
  if (!restoredQuiz || !Array.isArray(restoredQuiz.questions) || !restoredQuiz.questions.length) {
    clearPracticeDraft();
    showToast(t("not_available"));
    return;
  }

  state.quizLock = "practice";
  state.quiz = restoredQuiz;
  state.quiz.qTimerId = null;

  // ✅ add paused time into pausedTotalMs (so итоговое время не включает паузу)
  try {
    const now = Date.now();
    const pausedAt = Number(draft?.pausedAt || state.quiz.pauseStartedAt || now);
    const addMs = Math.max(0, now - pausedAt);
    state.quiz.pausedTotalMs = Number(state.quiz.pausedTotalMs || 0) + addMs;
  } catch {}

  state.quiz.paused = false;
  state.quiz.pauseStartedAt = null;
  state.quiz.qEndsAtMs = null;
  state.quiz.qEndsAtMono = null;
  clearPracticeDraft();
  saveState();
  replaceCourses("practice-quiz");
  renderPracticeQuiz();
  startPracticeQuestionTimer();
  return;
}

      if (action === "practice-pause") {
        handlePracticePause();
        return;
      }

      if (action === "practice-submit") {
        handlePracticeSubmit(false).catch(() => null);
        return;
      }

      if (action === "practice-review") {
  pushCourses("practice-review");
  renderPracticeReview();
  return;
}

if (action === "practice-recommendations") {
  pushCourses("practice-recs");
  renderPracticeRecs();
  return;
}

if (action === "practice-exit") {
  const ctx = state?.courses?.practiceContext || "main";

  // ✅ DRILL: go back to recommendation detail (topic screen)
  if (ctx === "drill" && state?.courses?.myRecCurrent) {
  // ✅ restore stack so header back arrow appears:
  // my-recs -> my-rec-detail
  state.courses = state.courses || {};
  state.courses.stack = ["my-recs", "my-rec-detail"];
  saveState();

  showCoursesScreen("my-rec-detail");
  renderMyRecDetail();
  return;
}

  // ✅ MAIN: go to Subject Hub as before
  replaceCourses("subject-hub");
  renderSubjectHub();
  return;
}

      if (action === "practice-back-to-result") {
        // go to result without destroying stack
        // simplest: pop until practice-result
        while (state.courses.stack.length > 0 && getCoursesTopScreen() !== "practice-result") {
          state.courses.stack.pop();
        }
        if (state.courses.stack.length === 0) state.courses.stack = ["practice-result"];
        saveState();
        showCoursesScreen(getCoursesTopScreen());
        return;
      }

      if (action === "practice-again") {
  // ✅ if last finished was a drill — repeat that drill
  const d = state?.courses?.myRecDrillLast;
  if (d?.drillType === "rec_mistakes") {
    startPracticeRetryMistakes();
    return;
  }
  if (d?.drillType === "rec_topic") {
    startPracticeByRec();
    return;
  }

  // fallback: normal practice
  clearPracticeDraft();
  startPracticeNew();
  return;
}

           if (action === "open-tours") {
        // additional subjects: tours are not available
        if (isAdditionalSubjectKey(state.courses.subjectKey)) {
        toastToursDenied("not_main");
        return;
      }

        const profile = loadProfile();
        const eligibility = canOpenActiveTours(profile, state.courses.subjectKey);
        if (!eligibility.ok) {
          toastToursDenied(eligibility.reason);
          return;
        }

        pushCourses("tours");
        renderToursStart(); // ✅ fill stats + hide trend when <2
        return;
      }


       if (action === "open-tour") {
        openTourRules();
        return;
      }

     if (action === "open-archive-tours") {
  if (!canOpenArchiveNow()) {
    showToast(tr("tours_archive_locked_toast", "🔒 Архив закрыт. Сначала завершите активный тур."));
    return;
  }
  // пока архив — глобальный экран
  openGlobal("archive");
  return;
}

      if (action === "tour-start") {
        openTourQuiz();
        return;
      }

// pick option
if (action === "tour-pick") {
  const ctx = state.tourContext;
  if (!ctx) return;

  const picked = Number(btn.dataset.index);
  // highlight
  $$("#tour-options .option").forEach(o => o.classList.remove("is-selected"));
  btn.classList.add("is-selected");

  // enable next
  const next = $("#tour-next-btn");
  if (next) next.disabled = false;

  // store temporarily (not final submit yet)
  ctx._pickedIndex = picked;
  saveState();
  return;
}

// next / finish
if (action === "tour-next" || action === "tour-submit") {
  const ctx = state.tourContext;
  if (!ctx) return;

  // UI: show "Saving..." also on Next (not only Finish)
  const nextBtn =
    $("#tour-next-btn") ||
    $("#quiz-next-btn") ||
    document.querySelector('[data-action="tour-next"]');

  if (nextBtn) {
    nextBtn.classList.add("is-loading");
    nextBtn.disabled = true;
    nextBtn.textContent = (window.i18n?.t ? window.i18n.t("saving") : "Saving…");
  }

  const picked = (ctx._pickedIndex === null || ctx._pickedIndex === undefined) ? null : Number(ctx._pickedIndex);
  ctx._pickedIndex = null;
  saveState();

  submitTourAnswer({ pickedIndex: picked, auto: false }).catch(() => null);
  return;
}

                  if (action === "tour-review") {
        const reviewPayload = state?.courses?.lastTourReviewPayload || null;
        const subjectKey =
          String(reviewPayload?.subjectKey || state?.courses?.subjectKey || "").trim();
        const tourNo = Number(reviewPayload?.tourNo || state?.courses?.activeTourNo || 0);

        const canOpen = subjectKey && tourNo
          ? await isTourGloballyClosed(subjectKey, tourNo)
          : false;

        if (!canOpen) {
    renderTourResultStatusSummary();
    showToast(
      t("tour_review_locked_until_global_end") ||
      tr3(
        "Подробный разбор пока закрыт. Ниже доступна краткая сводка по результату тура.",
        "To‘liq tahlil hozircha yopiq. Pastda tur natijasi bo‘yicha qisqa xulosa mavjud.",
        "The full review is still locked. A short summary of the tour result is available below."
      )
    );
    return;
  }

               pushCourses("tour-review");
        await renderTourReview();

        try {
          trackEvent("tour_review_opened", {
            subject_key: subjectKey || null,
            tour_no: tourNo || null,
            attempt_id: Number(state?.courses?.lastTourAttemptId || 0) || null
          });
        } catch {}

        return;
      }

      if (action === "tour-back-to-result") {
        while (state.courses.stack.length > 0 && getCoursesTopScreen() !== "tour-result") {
          state.courses.stack.pop();
        }
        if (state.courses.stack.length === 0) state.courses.stack = ["tour-result"];
        saveState();
        showCoursesScreen(getCoursesTopScreen());
        return;
      }
                   if (action === "tour-review-open-practice") {
  await openPracticeStart();
  return;
}  
             if (action === "tour-certificate") {
        const certId = Number(state?.courses?.lastTourCertificateId || 0);

        if (!state.certificates) {
          state.certificates = { selectedId: null, lastIssuedId: null };
        }

        state.certificates.selectedId = null;
        if (certId) state.certificates.lastIssuedId = certId;
        saveState();

        openGlobal("certificates");

        if (!certId) {
          showToast(t("certificates_pending_hint") || "Сертификат появится после первой сохранённой попытки.");
        }

        return;
      }
       
                        if (action === "open-books") {
        showAsyncOverlay(tr3(
          "Загружаем книги…",
          "Kitoblar yuklanmoqda…",
          "Loading books…"
        ));

        try {
          pushCourses("books");
          await renderBooks();
        } finally {
          hideAsyncOverlay();
        }

        return;
      }

            if (action === "open-my-recommendations") {
        const subject_id = state?.courses?.subjectKey ? String(state.courses.subjectKey) : "";

        try {
          trackEvent("recommendation_opened", {
            source: "subject_hub_my_recs",
            subject_id: normSubjectId(subject_id)
          });
        } catch {}

        state.courses = state.courses || {};
        state.courses.myRecsActiveTab = state.courses.myRecsActiveTab || "practice";
        saveState();

                showAsyncOverlay(tr3(
          "Загружаем рекомендации…",
          "Tavsiyalar yuklanmoqda…",
          "Loading recommendations…"
        ));

        try {
          pushCourses("my-recs");
          await renderMyRecs();
        } finally {
          hideAsyncOverlay();
        }

        return;
      }

      if (action === "video-skip") {
  // legacy: buttons removed from the current video hub screen
  return;
}

if (action === "video-complete") {
  // legacy: buttons removed from the current video hub screen
  return;
}

   if (action === "resources-archive") {
     if (!canOpenArchiveNow()) {
       showToast("Архив откроется после завершения активного тура.");
       return;
      }
     openGlobal("archive");
     return;
   }
});

    // Tours list click (demo)
    const toursList = $("#tours-list");
    if (toursList) {
      toursList.addEventListener("click", () => {
        openTourRules();
      });
    }
  }

  // ---------------------------
  // Boot
  // ---------------------------
    // ---------------------------
  // Splash: wait for critical images
  // ---------------------------
  function preloadImages(urls, { timeoutMs = 6000 } = {}) {
    const unique = Array.from(new Set((urls || []).filter(Boolean)));

    const tasks = unique.map((url) => new Promise((resolve) => {
      const img = new Image();
      const done = () => resolve({ url, ok: true });

      img.onload = done;
      img.onerror = () => resolve({ url, ok: false });

      // ⚠️ чтобы не зависнуть навсегда на плохом файле
      const timer = setTimeout(() => resolve({ url, ok: false, timeout: true }), timeoutMs);

      img.onload = () => { clearTimeout(timer); done(); };
      img.onerror = () => { clearTimeout(timer); resolve({ url, ok: false }); };

      img.src = url;
    }));

    return Promise.all(tasks);
  }

  function preloadAppImages() {
    // ✅ критичные картинки, которые видны сразу
    const urls = [
      "logo.png",
      "asset/informatics.png.png",
      "asset/economics.png.png",
      "asset/biology.png.png",
      "asset/chemistry.png.png",
      "asset/mathematics.png.png",
    ];

    return preloadImages(urls, { timeoutMs: 6000 });
  }

     // ---------------------------
  // Debug: Registration reset helpers
  // ---------------------------
    function resetRegistrationSoft() {
    // Local-only reset (keeps Supabase auth session)
    try {
      localStorage.removeItem(LS.profile);
      localStorage.removeItem(LS.state);
    } catch (e) {}

    __profileSubjectsDbReady = false;
    showView("registration");
    bindRegistration();
  }

  async function resetRegistrationHard() {
    // Full reset: sign out + clear local storage + reload
    try {
      if (window.sb) {
        await window.sb.auth.signOut();
      }
    } catch (e) {}

    try {
      localStorage.clear();
    } catch (e) {}

    location.reload();
  }

  // expose to console
  window.resetRegistrationSoft = resetRegistrationSoft;
  window.resetRegistrationHard = resetRegistrationHard;

   async function boot() {
    try { document.documentElement.classList.add("i18n-pending"); } catch {}

    // ✅ показать splash и скрыть topbar (updateTopbarForView("splash") сработает внутри showView)
    showView("splash");

      const profile = loadProfile();
      // UI язык: uiLanguage (если есть), иначе fallback на content language (profile.language)
      const lang = profile?.uiLanguage || profile?.language || getTelegramLang() || "ru";
      window.i18n?.setLang(lang);
      applyStaticI18n();

      // снимаем "i18n-pending" после кадра отрисовки, чтобы не было мигания
      requestAnimationFrame(() => {
        requestAnimationFrame(() => {
          try { document.documentElement.classList.remove("i18n-pending"); } catch {}
        });
      });

      try {
        updateOfflineBanner();
        window.addEventListener("online", updateOfflineBanner);
        window.addEventListener("offline", updateOfflineBanner);

        // ✅ when internet returns — flush pending db ops (debounced)
        window.addEventListener("online", () => { scheduleFlushPendingOps(350); });

        // ✅ when user returns to app — also try to flush
        document.addEventListener("visibilitychange", () => {
          try {
            if (document.visibilityState === "visible") scheduleFlushPendingOps(250);
          } catch {}
        });

                // ✅ gentle periodic flush only when queue is not empty
        setInterval(() => {
          try {
            if (hasPendingOpsQueued()) {
              scheduleFlushPendingOps(0);
            }
          } catch {}
        }, 20000);
      } catch {}

      try {
        window.addEventListener("error", (e) => logClientError("window_error", e?.error || e?.message || e));
        window.addEventListener("unhandledrejection", (e) => logClientError("unhandledrejection", e?.reason || e));
      } catch {}

    const statusEl = $("#splash-status");
    if (statusEl) statusEl.textContent = t("loading");

    // ✅ минимум показываем splash чуть-чуть, чтобы не “мигало”
    const minDelay = new Promise((r) => setTimeout(r, 250));

    // ✅ параллельно поднимаем Supabase-сессию (не блокируем UX)
    const supaReady = initSupabaseSession().catch(() => null);

        Promise.all([preloadAppImages(), minDelay, supaReady]).then(async () => {
      // Stage B: if local profile is missing, try hydrate from DB
      try { await hydrateLocalProfileFromSupabaseIfMissing(); } catch {}

      // ✅ flush pending ops after Supabase is ready (debounced)
try { scheduleFlushPendingOps(0); } catch {}

const verifyCertificateNumber = getVerifyCertificateNumberFromUrl();
if (verifyCertificateNumber) {
  showView("certificate-verify");
  await renderCertificateVerifyView(verifyCertificateNumber);
  return;
}

// ✅ active-session guard:
// если local profile остался от старого uid, но текущий uid уже не активен,
// не пускаем в Home и предлагаем восстановление.
const activeIdentity = await ensureActiveIdentityOrShowRecovery();
if (activeIdentity?.blocked) {
  return;
}

// ✅ clean-device / Telegram Web guard:
// если local profile нет, но Telegram аккаунт уже связан с профилем,
// сразу предлагаем восстановление, без повторного заполнения регистрации.
const knownTelegramProfile = await ensureKnownTelegramProfileOnBoot();
if (knownTelegramProfile?.handled || knownTelegramProfile?.blocked) {
  return;
}

// Stage B2: always sync user_subjects from DB → local profile (single source for UI)
// Делаем это только после active identity check.
try { await syncUserSubjectsFromSupabaseIntoLocalProfile(); } catch {}

if (!isRegistered()) {
  showView("registration");
  bindRegistration();
  return;
}
      await ensureHomeDbReady();
      renderAllSubjects();
      renderHome();

      // ✅ Требование: при полном запуске (reload/новый старт) всегда стартуем с Home
      // Сворачивание/возврат не трогаем — там не происходит reload.
      state.tab = "home";
      saveState();

      // ✅ Courses всегда начинает с All Subjects (когда пользователь туда зайдёт)
      state.courses = state.courses || {};
      state.courses.stack = ["all-subjects"];
      saveState();

         // Start at Home
      setTab("home");

      try { await refreshNotificationsBadge(); } catch {}
    });
  }

   // ---------------------------
// Credentials UI (Profile + Subject Hub)
// ---------------------------
function getCredTitleKey(credKey) {
  switch (credKey) {
    case "consistent_learner": return "cred_consistent_learner";
    case "focused_study_streak": return "cred_focused_study_streak";
    case "active_video_learner": return "cred_active_video_learner";
    case "practice_mastery": return "cred_practice_mastery_subject";
    case "error_driven_learner": return "cred_error_driven_learner";
    case "research_oriented": return "cred_research_oriented_learner";
    case "fair_play": return "cred_fair_play_participant";
    default: return credKey;
  }
}

function formatCredStatus(status) {
  if (!status) return "";
  if (status === "active") return t("cred_status_active");
  if (status === "inactive") return t("cred_status_inactive");
  if (status === "expired") return t("cred_status_expired");
  if (status === "revoked") return t("cred_status_revoked");
  return String(status);
}

function formatDateShortSafe(ts) {
  if (!ts) return "";
  try {
    const d = new Date(ts);
    if (Number.isNaN(d.getTime())) return "";
    return new Intl.DateTimeFormat(currentLang() || "ru", {
      day: "numeric",
      month: "long",
      year: "numeric"
    }).format(d);
  } catch {
    return "";
  }
}

function readCredStoreSafe() {
  try {
    if (typeof getCredentialStore === "function") return getCredentialStore();
  } catch {}

  // ✅ fallback: если обёртку когда-то удалят
  try {
    if (typeof credentialsStore === "function") return credentialsStore();
  } catch {}

  return null;
}

function getCredRecord(store, credKey) {
  if (!store) return null;

  // 1) DB-формат: store.user_credentials[code]
  if (store.user_credentials && store.user_credentials[credKey]) return store.user_credentials[credKey];

  // 2) fallback: иногда кладут прямо в store.credentials
  if (store.credentials && store.credentials[credKey]) return store.credentials[credKey];

  // 3) Маппинг UI-ключей → реальные ключи стора/БД
  if (credKey === "research_oriented") {
    return store.user_credentials?.research_oriented_learner || store.research_oriented_learner || null;
  }
  if (credKey === "fair_play") {
    return store.user_credentials?.fair_play_participant || store.fair_play_participant || null;
  }

  // 4) Practice Mastery: UI просит "practice_mastery", а в сторе/логике это "practice_mastery_subject"
  if (credKey === "practice_mastery") {
    // если вдруг БД хранит агрегированный рекорд
    if (store.user_credentials?.practice_mastery) return store.user_credentials.practice_mastery;

    // иначе берём лучший/самый “живой” из by_subject
    const by = store.practice_mastery_subject?.by_subject || {};
    const entries = Object.values(by).filter(Boolean);
    if (entries.length === 0) return null;

    const actives = entries.filter(r => r.status === "active");
    if (actives.length > 0) {
      actives.sort((a, b) => (Number(new Date(b.achieved_at || 0)) - Number(new Date(a.achieved_at || 0))));
      return actives[0];
    }

    entries.sort((a, b) => {
      const ea = a?.evidence?.attempts_count ?? a?.evidence_snapshot?.attempts_count ?? 0;
      const eb = b?.evidence?.attempts_count ?? b?.evidence_snapshot?.attempts_count ?? 0;
      return Number(eb) - Number(ea);
    });
    return entries[0] || null;
  }

  // 5) Прямой доступ (consistent_learner, focused_study_streak, ...)
  if (store[credKey]) return store[credKey];

  return null;
}

function getCredEvidence(rec) {
  return rec?.evidence_snapshot || rec?.evidence || null;
}

function buildProgressLine(credKey, rec) {
  const ev = getCredEvidence(rec);
  if (!ev) return "";

  // Progress hints строго по документу (>=60%) — показываем только если уже есть метрики
  // Consistent: показывать когда active_days_14d >= 5
  if (credKey === "consistent_learner") {
    const x = Number(ev.active_days_14d ?? ev.active_days ?? NaN);
    if (!Number.isFinite(x)) return "";
    if (x >= 5 && x < 7) return t("cred_progress_consistent", { x: String(x) });
    return "";
  }

  // Focused: 3/5+
  if (credKey === "focused_study_streak") {
    const x = Number(ev.focused_sessions_in_row ?? ev.sessions_in_row ?? NaN);
    if (!Number.isFinite(x)) return "";
    if (x >= 3 && x < 5) return t("cred_progress_focused", { x: String(x) });
    return "";
  }

  // Practice: attempts_count>=5 как мягкий прогресс
  if (credKey === "practice_mastery") {
    const attempts = Number(ev.attempts_count ?? NaN);
    if (!Number.isFinite(attempts)) return "";
    if (attempts >= 5 && attempts < 8) return t("cred_progress_practice_attempts", { x: String(attempts) });
    return "";
  }

  // Error-driven: cycles_count>=2
  if (credKey === "error_driven_learner") {
    const cycles = Number(ev.cycles_count ?? NaN);
    if (!Number.isFinite(cycles)) return "";
    if (cycles >= 2 && cycles < 3) return t("cred_progress_error_cycles", { x: String(cycles) });
    return "";
  }

  // Research: opens>=2
  if (credKey === "research_oriented") {
    const opens = Number(ev.resource_opens_total ?? ev.opens ?? NaN);
    const days = Number(ev.distinct_return_days ?? ev.return_days ?? NaN);
    if (!Number.isFinite(opens) || !Number.isFinite(days)) return "";
    if (opens >= 2 || days >= 1) return t("cred_progress_research", { x: String(opens), y: String(days) });
    return "";
  }

  return "";
}

function renderProfileCredentialsUI() {
  const grid = document.querySelector(".profile-credentials-grid");
  if (!grid) return;

  const hints = document.getElementById("profile-credentials-hints");
  const store = readCredStoreSafe();

  const keys = [
    "consistent_learner",
    "focused_study_streak",
    "active_video_learner",
    "practice_mastery",
    "error_driven_learner",
    "research_oriented",
    "fair_play"
  ];

  const ICON = {
    consistent_learner: "📅",
    focused_study_streak: "🎯",
    active_video_learner: "▶️",
    practice_mastery: "🧠",
    error_driven_learner: "🧪",
    research_oriented: "📚",
    fair_play: "🛡️"
  };

  const actives = [];
  const progressLines = [];

  keys.forEach(k => {
    const rec = getCredRecord(store, k);
    if (!rec) return;

    const status = rec.status;
    const title = t(getCredTitleKey(k));
    const statusText = formatCredStatus(status);
    const achieved = formatDateShortSafe(rec.achieved_at);

    if (status === "active") {
      actives.push({ key: k, title, statusText, achieved, status });
    }

    const p = buildProgressLine(k, rec);
    if (p) progressLines.push(p);
  });

  // 1) Grid
  grid.innerHTML = "";

  if (actives.length === 0) {
    const empty = document.createElement("div");
    empty.className = "card-sub";
    empty.textContent = t("cred_none_yet");
    grid.appendChild(empty);
  } else {
    actives.forEach(item => {
      const card = document.createElement("div");
      card.className = "credential-item is-active";

      const ico = document.createElement("div");
      ico.className = "credential-ico";
      ico.textContent = ICON[item.key] || "✓";

      const body = document.createElement("div");
      body.className = "credential-body";

      const titleEl = document.createElement("div");
      titleEl.className = "credential-title";
      titleEl.textContent = item.title;

      const metaEl = document.createElement("div");
      metaEl.className = "credential-meta";
      metaEl.textContent = item.achieved
        ? `${item.statusText} • ${t("cred_meta_achieved")}: ${item.achieved}`
        : item.statusText;

      body.appendChild(titleEl);
      body.appendChild(metaEl);

      card.appendChild(ico);
      card.appendChild(body);
      grid.appendChild(card);
    });
  }

  // 2) Progress
  if (hints) {
    hints.innerHTML = "";
    if (progressLines.length > 0) {
      const kicker = document.createElement("div");
      kicker.className = "card-kicker";
      kicker.textContent = t("cred_kicker_progress");
      hints.appendChild(kicker);

      progressLines.slice(0, 4).forEach(line => {
        const p = document.createElement("div");
        p.className = "card-sub";
        p.textContent = line;
        hints.appendChild(p);
      });
    }
  }
}
  function bindUI() {
  bindTabbar();
  bindTopbar();
  bindActions();
  bindRatingsUI(); // ✅ Leaderboard controls
  bindIdentityRuntimeGuards(); // ✅ one-active-device runtime enforcement
}

// Earned Credentials — daily evaluation jobs (once per Tashkent day)
try { runDailyCredentialJobs(); } catch {}

// Init
bindUI();
boot();

})();
