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

function showViewTransitionOverlay(duration = 220) {
  const el = document.getElementById("view-transition-overlay");
  if (!el) return;

  const txt = el.querySelector(".view-transition-text");
  if (txt && typeof t === "function") {
    txt.textContent = t("loading") || txt.textContent;
  }

  el.classList.remove("hidden");

  if (__viewTransitionTimer) {
    clearTimeout(__viewTransitionTimer);
    __viewTransitionTimer = null;
  }

  __viewTransitionTimer = setTimeout(() => {
    el.classList.add("hidden");
    __viewTransitionTimer = null;
  }, duration);
}

function showCertificateDownloadOverlay() {
  const el = document.getElementById("view-transition-overlay");
  if (!el) return;

  const txt = el.querySelector(".view-transition-text");
  if (txt) {
    txt.textContent = t("certificate_download_preparing");
  }

  if (__viewTransitionTimer) {
    clearTimeout(__viewTransitionTimer);
    __viewTransitionTimer = null;
  }

  el.classList.remove("hidden");
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
            if (!res?.ok) keep.push(op);
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
            // ✅ best-effort: insert analytics event
            const { error } = await window.sb.from("app_events").insert({
              user_id: op.userId,
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
   
   async function initSupabaseSession() {
    if (!SUPABASE_URL || !SUPABASE_ANON_KEY) return null;
    if (!window.supabase?.createClient) return null;

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
    }

    // 1) ensure we have a session (Anonymous Sign-in)
        const { data: sessData } = await sb.auth.getSession();
    if (!sessData?.session) {
      const { data: anonData, error: anonErr } = await sb.auth.signInAnonymously();

      if (anonErr) {
        console.error("[Supabase] Anonymous sign-in failed:", anonErr);

        const statusEl = document.getElementById("splash-status");
        if (statusEl) statusEl.textContent = "Supabase auth error: " + (anonErr.message || "unknown");

        // Не валим приложение — просто работаем без базы (пока не починим настройки)
        return sb;
      }
    }

    // 2) ensure users row exists (id == auth.uid())
    const { data: userData } = await sb.auth.getUser();
    const u = userData?.user;
    if (!u?.id) return sb;

    const tg = getTelegramUserSafe();
    const langGuess = tg?.language_code || (typeof getTelegramLang === "function" ? getTelegramLang() : null) || "ru";

// ✅ если локальный профиль уже есть — считаем content language источником истины
const lp = safeJsonParse(localStorage.getItem(LS.profile), null);
const contentLang = lp?.language || langGuess;

const payload = {
  id: u.id,
  telegram_user_id: tg?.id ? String(tg.id) : null,
  avatar_url: null,
  language_code: contentLang,
};

// ✅ НЕ перезатираем имя/фамилию в NULL на boot
if (tg?.first_name) payload.first_name = String(tg.first_name).trim();
if (tg?.last_name) payload.last_name = String(tg.last_name).trim();

// upsert by primary key id (critical) — with retry + safe catch
try {
  await dbWriteWithRetry(async () => {
    const { error } = await sb.from("users").upsert(payload, { onConflict: "id" });
    if (error) throw error;
    return true;
  }, { tries: 3, baseDelayMs: 350 });
} catch (e) {
  // не валим приложение — но фиксируем в events
  try {
    const uid = u?.id || null;
    await logDbErrorToEvents(uid, "boot_users_upsert_failed", e, { has_tg: !!tg });
  } catch {}
}

// ✅ reset subject cache for this session (prevents poisoned null cache)
try { _subjectIdByKeyCache.clear(); } catch {}

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

// ✅ Earned Credentials: hydrate local events store from Supabase (only if local empty)
try {
  const changed = await hydrateLocalEventsFromSupabase(sb, u.id);

  // Always recalc after hydration attempt:
  // - changed=true  -> we merged DB events
  // - changed=false -> still ensures daily job runs at least once per day
  try { runDailyCredentialJobs(); } catch {}

  // If we merged something new — update profile UI if it’s already on screen
  if (changed) {
    try { renderProfile(); } catch {}
    try { renderSubjectHub(); } catch {}
  }
} catch {}

    return sb;
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

    const item = {
      id,
      type,
      ts,
      day: dayKeyTashkent(ts),
      payload: Object.assign({}, (payload || {}), { client_event_id: id })
    };

    store.items.push(item);

    // keep last N events (avoid LS overflow)
    if (store.items.length > 2000) store.items = store.items.slice(-2000);

    saveJsonLS(LS.events, store);

    // optional: mirror to Supabase app_events
    mirrorEventToSupabase(type, { ...payload, ts: new Date(ts).toISOString() });

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
        .in("status", ["submitted", "time_expired", "anti_cheat"])
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
  const c = credentialsStore();
  const today = dayKeyTashkent(Date.now());

  // ✅ Уже делали daily пересчёты сегодня — выходим
  if (c.last_daily_eval_day === today) return;

  evaluateConsistentLearnerDaily();
  evaluateResearchOrientedDaily();
  evaluateErrorDrivenDailyOrOnReview();

  // ✅ фиксируем, что daily пересчёт на сегодня выполнен
  c.last_daily_eval_day = today;
  saveCredentialsStore(c);

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
    nextState.quiz = stripPracticeQuizSecrets(nextState.quiz);
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

  // 1) Loading state
  listEl.innerHTML = `
    <div class="empty muted">${t("archive_loading")}</div>
  `;

  // 2) Determine availability
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
      // No DB: fallback to local schedule rule
      isLocked = !canOpenArchiveNow();
    }
  } catch {
    availabilityUnknown = true;
  }

  // 3) Locked / unavailable UI (on screen, not toast)
  if (availabilityUnknown) {
    listEl.innerHTML = `
      <div class="empty muted">
        <div style="font-weight:800; margin-bottom:6px;">${t("archive_unavailable_title")}</div>
        <div class="small">${t("archive_unavailable_sub")}</div>
      </div>
    `;
    return;
  }

  if (isLocked) {
    listEl.innerHTML = `
      <div class="empty muted">
        <div style="font-weight:800; margin-bottom:6px;">${t("archive_locked_title")}</div>
        <div class="small">${t("archive_locked_sub")}</div>
      </div>
    `;
    return;
  }

  // 4) If DB not available for content, show empty (safe)
  if (!window.sb) {
    listEl.innerHTML = `
      <div class="empty muted">${t("archive_empty")}</div>
    `;
    return;
  }

  // 5) Load archive items for current subject
  const subjectKey = state?.courses?.subjectKey;
  const uid = await getAuthUid();

  if (!uid || !subjectKey) {
    listEl.innerHTML = `
      <div class="empty muted">${t("archive_empty")}</div>
    `;
    return;
  }

  const subjectId = await getSubjectIdByKey(subjectKey);
  if (!subjectId) {
    listEl.innerHTML = `
      <div class="empty muted">${t("archive_empty")}</div>
    `;
    return;
  }

  // Load tours for subject
  const { data: tours, error: toursErr } = await window.sb
    .from("tours")
    .select("id,tour_no,start_date,end_date,is_active")
    .eq("subject_id", subjectId)
    .order("tour_no", { ascending: true });

  if (toursErr || !Array.isArray(tours) || tours.length === 0) {
    listEl.innerHTML = `
      <div class="empty muted">${t("archive_empty")}</div>
    `;
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

  // Past = not active now OR is_active === false
  const pastTours = tours.filter(t => !t?.is_active || !isInWindow(t));
  const pastTourIds = pastTours.map(t => Number(t.id)).filter(Boolean);

  if (pastTourIds.length === 0) {
    listEl.innerHTML = `
      <div class="empty muted">${t("archive_empty")}</div>
    `;
    return;
  }

  // Load user attempts for those tours
  const { data: atts, error: attsErr } = await window.sb
    .from("tour_attempts")
    .select("tour_id,score,total_time,status")
    .eq("user_id", uid)
    .in("tour_id", pastTourIds)
    .in("status", ["submitted", "time_expired"]);

  if (attsErr || !Array.isArray(atts) || atts.length === 0) {
    listEl.innerHTML = `
      <div class="empty muted">${t("archive_empty")}</div>
    `;
    return;
  }

  // Best attempt per tour: max score, then min time
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

  // Render list
  const rows = pastTours
    .filter(t => bestByTour.has(Number(t.id)))
    .map(t => {
      const best = bestByTour.get(Number(t.id));
      const title = `${tr("tours_tour_label", "Тур")} ${t.tour_no}`;

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
    return;
  }

  listEl.innerHTML = rows.join("");
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

  return data.map(r => {
    const fromPath = toPublicUrl(r.photo_path);
    return {
      name: String(r.name || ""),
      role: String(r.role || ""),
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

function ensureTeamCacheInit() {
  if (!state.about) state.about = { tab: "project" };

  if (Number(state.about.teamPeopleCacheVersion || 0) !== TEAM_CACHE_VERSION) {
    state.about.teamPeopleCache = {};
    state.about.teamPeopleCacheTs = {};
    state.about.teamPeopleResolved = {};
    state.about.teamPeopleCacheVersion = TEAM_CACHE_VERSION;
    saveState();
  }

  if (!state.about.teamPeopleCache) state.about.teamPeopleCache = {};
  if (!state.about.teamPeopleCacheTs) state.about.teamPeopleCacheTs = {};
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
  if (!tooOld && Array.isArray(cached) && hasAnyPhoto) return;

  // иначе перечитываем из БД
  fetchTeamPeopleFromDb(s).then(list => {
    if (!Array.isArray(list) || list.length === 0) return;
    ensureTeamCacheInit();
    state.about.teamPeopleCache[s] = list;
    state.about.teamPeopleCacheTs[s] = Date.now();
    saveState();
    renderAboutView();
  }).catch(() => null);
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
    ? `<img class="person-photo" src="${escapeHTML(photoUrl)}" alt="${escapeHTML(name || "")}" loading="lazy" />`
    : `<div class="person-avatar ${vacant ? "is-vacant" : ""}">${vacant ? "" : escapeHTML(initials(name))}</div>`;

  const bodyHtml = `
    ${avatarHtml}
    <div class="person-body">
      <div class="person-name">${escapeHTML(vacant ? t("about_team_vacant_title") : name)}</div>
      <div class="person-role">${escapeHTML(role || "")}</div>
      ${meta ? `<div class="person-meta muted small">${escapeHTML(meta)}</div>` : ""}
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

const enrichPersonProfile = (x) => {
  const role = String(x.role || "");
  const meta = String(x.meta || "");
  const group = String(x.group || "");

  let about = "";
  let achievements = "";
  let education = meta || "";

  if (group === "board") {
    about = t("about_member_about_board") || "Loyiha strategiyasi, sifat va rivojlanish yo‘nalishlari ustida ishlaydi.";
    achievements = meta || (t("about_member_achievements_default") || "Tajriba va faolligi bilan jamoa ishiga hissa qo‘shadi.");
  } else if (group === "media") {
    about = t("about_member_about_media") || "Kontent, kommunikatsiya va iClub’ning media yo‘nalishlari ustida ishlaydi.";
    achievements = meta || (t("about_member_achievements_default") || "Jamoa ishiga amaliy hissa qo‘shadi.");
  } else {
    about = t("about_member_about_mentor") || "O‘quvchilarga fan bo‘yicha yo‘nalish, tushuncha va motivatsiya beradi.";
    achievements = meta || (t("about_member_achievements_default") || "Fan bo‘yicha tayyorgarlik va amaliyotda yordam beradi.");
  }

  if (/IELTS/i.test(meta) || /SAT/i.test(meta)) {
    achievements = meta;
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
      name: "Erkinov Azizbek Jasurbek o‘g‘li",
      role: "Ta’sischi — Prezident",
      meta: "Toshkent viloyati Nurafshon shahridagi Prezident maktabi 10 “Blue” sinf o‘quvchisi",
      vacant: false
    },
    { name: "", role: "Vitse-Prezident", meta: "", vacant: true },
    { name: "", role: "Chief Operating Officer", meta: "", vacant: true },
    { name: "", role: "Media guruh rahbari", meta: "", vacant: true },
    {
      name: "Marhabo Mahkamtoasheva",
      role: "Academic Quality Assurance Lead",
      meta: "Yosh kitobxon tanlovi g‘olibasi (2023) • IELTS 7",
      vacant: false
    }
  ];

  const mentors = [
    { name: "Komiljonova Ruxsora", role: "AS level Chemistry", meta: "Toshkent viloyati Nurafshon shahridagi Prezident maktabi 10 “Blue” sinf o‘quvchisi" },
    { name: "Olimov Shohjahon", role: "AS level Biology", meta: "Toshkent viloyati Nurafshon shahridagi Prezident maktabi 10 “Blue” sinf o‘quvchisi" },
    { name: "Jasur Abduhakimov", role: "IGCSE Computer Science", meta: "Toshkent shahridagi Prezident maktabi 10 “Blue” sinf o‘quvchisi" },
    { name: "Erkinov Azizbek", role: "AS level Economics", meta: "Toshkent viloyati Nurafshon shahridagi Prezident maktabi 10 “Blue” sinf o‘quvchisi" },
    { name: "To‘ychiboyeva Madina", role: "AS level Mathematics", meta: "Toshkent viloyati Nurafshon shahridagi Prezident maktabi 10 “Blue” sinf o‘quvchisi" },
    { name: "Akobirov Humoyun", role: "IELTS mentor", meta: "Toshkent viloyati Nurafshon shahridagi Prezident maktabi 10 “Green” sinf o‘quvchisi • IELTS 8.0" },

    { name: "Jamshidbek Yaxiyakulov", role: "SAT English", meta: "Samarqand viloyati Invest in education xususiy maktabi 11-sinf • IELTS 7.5 • SAT English 690" },
    { name: "Iskandarov Bunyodbek", role: "SAT Math", meta: "Xorazm viloyati Hazorasp tumani, To‘laqim FM xususiy maktabi 11-sinf • SAT Math 790" },
    { name: "Munisa Ro‘ziboyeva", role: "English A2 mentor", meta: "Samarqand viloyati Paxtachi tumani 12-maktab 11 “Moliya-iqtisod” • IELTS 6" },
    { name: "Madina Umarova", role: "English B1 mentor", meta: "Toshkent Davlat sharqshunoslik universiteti 1-kurs • IELTS 6.5" },
    { name: "Kamolaxon Qodirova", role: "Ingliz tili mentori", meta: "Navoiy davlat universiteti 3-bosqich • IELTS 7.5" }
  ];

  const media = [
    { name: "Akbaraliyeva Zilola", role: "Video tahrirchi", meta: "Toshkent Xalqaro Vestminster universiteti 1-kurs talabasi" },
    { name: "Iskandarov Shohrubek", role: "Video tahrirchi", meta: "Xiva shahridagi Prezident maktabining 10 “Green” sinf o‘quvchisi" },
    { name: "", role: "Copywriter", meta: "", vacant: true },
    { name: "", role: "Dizayner", meta: "", vacant: true },
    { name: "Davlatboyeva Sevara", role: "Telegram menejer", meta: "Toshkent viloyati Nurafshon shahridagi Prezident maktabi 10 “Blue” sinf o‘quvchisi" },
    { name: "Kucharova Dilrabo", role: "Instagram menejer", meta: "Toshkent viloyati Nurafshon shahridagi Prezident maktabi 10 “Green” sinf o‘quvchisi" }
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
state.about.teamPeopleResolved.board = list.map(x => ({
  ...x,
  group: "board",
  memberKey: memberKeyOf(x)
}));

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
  state.about.teamPeopleResolved.mentors = list.map(x => ({
    ...x,
    group: "mentors",
    memberKey: memberKeyOf(x)
  }));

  contentEl.innerHTML = `
    ${subHeader("about_team_mentors_title")}
    <div class="card">
      <div class="muted small">${escapeHTML(t("about_team_mentors_note"))}</div>
      <div class="people-grid" style="margin-top:10px">
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
state.about.teamPeopleResolved.media = list.map(x => ({
  ...x,
  group: "media",
  memberKey: memberKeyOf(x)
}));

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
  const src = state.about.teamPeopleResolved?.[prev] || [];
  const raw = Array.isArray(src)
    ? src.find(x => String(x.memberKey || "") === String(state.about.teamMemberKey || ""))
    : null;

  if (!raw) {
    state.about.teamScreen = prev;
    state.about.teamMemberKey = null;
    saveState();
    renderAboutView();
    return;
  }

  const person = enrichPersonProfile(raw);
  const hasPhoto = !!(person.photoUrl && String(person.photoUrl).trim());

  contentEl.innerHTML = `
    ${subHeader("about_team_profile_title")}

    <div class="card team-profile-card">
      <div class="team-profile-hero">
        ${hasPhoto
          ? `<img class="team-profile-photo" src="${escapeHTML(person.photoUrl)}" alt="${escapeHTML(person.name || "")}" loading="lazy" />`
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

// ✅ show answers consistently: "B — option text" (if options exist)
function formatAnswerForDisplay(q, rawAnswer) {
  const raw = String(rawAnswer ?? "").trim();
  if (!raw) return "—";

  const qType = String(q?.qtype ?? q?.type ?? "mcq").toLowerCase();
  const isMcq = (qType === "mcq" || qType === "multiple_choice");

  // Для input-вопросов ничего не преобразуем в буквы.
  // Числа должны оставаться числами, текст — текстом.
  if (!isMcq) {
    return raw;
  }

  let opts = null;
  try {
    const oText = (typeof pickContentText === "function")
      ? pickContentText(q, "options_text")
      : (q?.options_text ?? null);
    opts = parseOptionsText(oText);
  } catch {}

  if (isNumericLike(raw)) {
    const idx = Math.trunc(Number(raw));

    if (opts && idx >= 0 && idx < opts.length) {
      const L = idxToLetter(idx);
      const txt = String(opts[idx] ?? "").trim();
      return txt ? `${L} — ${txt}` : (L || raw);
    }

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
   
// --- DB-first practice set builder ---
async function buildPracticeSet(subjectKey) {
  if (!window.sb) return [];

  const uid = await getAuthUid();
  if (!uid) return [];

  const subjectId = await getSubjectIdByKey(subjectKey);
  if (!subjectId) {
    await logDbErrorToEvents(uid, "subject_lookup", { message: "subject_id not found" }, { subject_key: subjectKey });
    return [];
  }

  const { data, error } = await window.sb
    .from("questions")
    .select("id, topic, difficulty, time_limit_sec, qtype, question_text, options_text, correct_answer, explanation, image_url, is_active, question_text_ru, question_text_uz, question_text_en, options_text_ru, options_text_uz, options_text_en, explanation_ru, explanation_uz, explanation_en")
    .eq("subject_id", subjectId)
    .eq("is_active", true)
    .limit(200);

  if (error) {
    await logDbErrorToEvents(uid, "practice_questions_select", error, { subject_id: subjectId, subject_key: subjectKey });
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

  const pool = poolRaw.map(r => {
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
      inputKind: type === "input" ? (isNumericLike(correctAnswer) ? "numeric" : "text") : null,
      inputHint: type === "input" ? (isNumericLike(correctAnswer) ? "Введите число" : "Введите ответ") : ""
    };
  }).filter(q => Number.isFinite(q.id));

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

  function practiceStorageKey(subjectKey) {
    return `practice_history_v1:${subjectKey}`;
  }

  function loadPracticeHistory(subjectKey) {
    try {
      const raw = localStorage.getItem(practiceStorageKey(subjectKey));
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

  function savePracticeHistory(subjectKey, data) {
    try {
      localStorage.setItem(practiceStorageKey(subjectKey), JSON.stringify(data));
    } catch {}
  }

  function updatePracticeHistory(subjectKey, attempt) {
    const h = loadPracticeHistory(subjectKey);
    const last = [attempt, ...(h.last || [])].slice(0, PRACTICE_CONFIG.keepLastAttempts);

    let best = h.best;
    if (!best || (attempt.percent > best.percent) || (attempt.percent === best.percent && attempt.durationSec < best.durationSec)) {
      best = attempt;
    }

    savePracticeHistory(subjectKey, { best, last });
    return { best, last };
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

    if (q.inputKind === "numeric") {
      // допускаем:
      // 12
      // 12.5 / 12,5
      // 1.505e23
      // 1.505*10^23 / 1.505×10^23 / 1.505x10^23
      return /^-?\d+([.,]\d+)?(([eE][+-]?\d+)|(([x×*])\s*10\^[+-]?\d+))?$/.test(v);
    }

    if (q.inputKind === "letter") {
      // ровно 1 буква, запрещаем a/b/c/d (чтобы не путали с MCQ)
      if (!/^[A-Za-zА-Яа-я]$/.test(v)) return false;
      const low = v.toLowerCase();
      if (low === "a" || low === "b" || low === "c" || low === "d") return false;
      return true;
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
        const res = await window.sb
          .from("districts")
          .select("id, region_id, name_ru, name_uz, name_en")
          .eq("region_id", regionId)
          .order("name_ru", { ascending: true });

        rows = (!res?.error && Array.isArray(res?.data)) ? res.data : [];
        if (rows.length) geoCacheSet(dCacheKey, rows);
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
    "certificates",
    "certificate-verify",
    "archive"
  ];

    function showView(viewName) {
  if (viewName !== "splash") {
    showViewTransitionOverlay();
  }

  VIEWS.forEach(v => {
    const el = $(`#view-${v}`);
    if (!el) return;
    el.classList.toggle("is-active", v === viewName);
  });

  updateTopbarForView(viewName);

  // ✅ FIX: не просто "вверх страницы", а "к началу активного view"
  const target = document.getElementById(`view-${viewName}`);
  if (!target) return;

  const jumpToTargetTop = () => {
    // 1) если скроллится main — сбрасываем его
    const mainEl = document.getElementById("main");
    if (mainEl) mainEl.scrollTop = 0;

    // 2) если скроллится документ — тоже сбрасываем
    document.documentElement.scrollTop = 0;
    document.body.scrollTop = 0;

    // 3) главное: принудительно ставим начало активного view в верх видимой области
    // (работает даже если браузер/вебвью "держит" странную позицию)
    try {
      target.scrollIntoView({ block: "start", inline: "nearest" });
    } catch (e) {
      // fallback
      target.scrollIntoView(true);
    }
  };

  // достаточно одного вызова с микро-задержкой, чтобы дать DOM перерисоваться
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
    // push to stack and show
    if (!VIEWS.includes(viewName)) return;

    // If user is in quiz lock, do not allow leaving
    if (state.quizLock === "tour") {
      showToast(t("toast_tour_in_progress"));
      return;
    }
    if (state.quizLock === "practice") {
      showToast(t("toast_pause_practice_to_leave"));
      return;
    }

    // base should exist
    if (!Array.isArray(state.viewStack) || state.viewStack.length === 0) {
      state.viewStack = [state.tab || "home"];
    }

           const top = state.viewStack[state.viewStack.length - 1];
    if (top === viewName) {

      // Earned Credentials: Research-Oriented — resource opened
      if (viewName === "resources") {
        try { trackEvent("resource_opened", { source: "global_resources" }); } catch {}
      }

      showView(viewName);

      if (viewName === "about") {
        renderAboutView();
      }

            if (viewName === "certificates") {
        (async () => {
          const subjectKey = state?.courses?.subjectKey || null;
          if (subjectKey) {
            const subjectId = await getSubjectIdByKey(subjectKey).catch(() => null);
            if (subjectId) {
              await tryIssueFinalCertificateForSubject(subjectId).catch(() => null);
            }
          }
          await renderCertificatesView();
        })();
      }

      return;
    }

        state.viewStack.push(viewName);
    saveState();

    // Earned Credentials: Research-Oriented — resource opened
    if (viewName === "resources") {
      try { trackEvent("resource_opened", { source: "global_resources" }); } catch {}
    }

        showView(viewName);

    if (viewName === "archive") {
      renderArchiveView();
    }

    if (viewName === "about") {
      renderAboutView();
    }

        if (viewName === "certificates") {
      (async () => {
        const subjectKey = state?.courses?.subjectKey || null;
        if (subjectKey) {
          const subjectId = await getSubjectIdByKey(subjectKey).catch(() => null);
          if (subjectId) {
            await tryIssueFinalCertificateForSubject(subjectId).catch(() => null);
          }
        }
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
    if (["resources", "news", "notifications", "community", "about", "certificates", "archive"].includes(viewName)) {
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
  scope: "district", // district | region | country
  q: "",
  subjectId: null,
  tourId: null, // null = All tours
  _booted: false,
  _loading: false,
  _token: 0,
   // search paging
  _searchKey: "",
  _searchOffset: 0,
  _searchLimit: 200,
  _searchRows: []
};

function getLeaderboardDataMock(scope) {
  // Позже заменим на Supabase: district/region/country + subject/tour + competitive only
  const base = [
    { rank: 1, name: "Shakhzod Alimov", meta: "Tashkent International School", score: 980, time: "12:45", avatar: null },
    { rank: 2, name: "Nilufar Karimova", meta: "Presidential School", score: 975, time: "13:10", avatar: null },
    { rank: 3, name: "Jasur Akhmedov", meta: "Samarkand Lyceum #1", score: 962, time: "14:05", avatar: null },
    { rank: 4, name: "Bekzod Saitov", meta: "School 142, Tashkent", score: 958, time: "14:22", avatar: null },
    { rank: 5, name: "Madina Kenjayeva", meta: "Westminster Academy", score: 944, time: "15:10", avatar: null },
    { rank: 6, name: "Aziz Umarov", meta: "Bukhara State Lyceum", score: 940, time: "15:45", avatar: null },
    { rank: 7, name: "Lola Mansurova", meta: "School 50, Fergana", score: 938, time: "16:02", avatar: null }
  ];

  // Для ощущения “разных” вкладок — слегка двигаем очки
  const delta = (scope === "district") ? 0 : (scope === "region" ? -6 : -12);
  return base.map(x => ({ ...x, score: x.score + delta }));
}

function getMyRankMock(scope) {
  const p = loadProfile();
  const displayName = (p?.full_name || p?.name || "You").trim();
  const district = p?.district || "—";
  const region = p?.region || "—";
  const meta = [district, region].filter(Boolean).join(" • ");

  // Мок “моего” места и очков
  const rank = (scope === "district") ? 12 : (scope === "region" ? 28 : 64);
  const score = (scope === "district") ? 892 : (scope === "region" ? 861 : 820);
  const time = "18:30";

  return { rank, name: displayName, meta, score, time };
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

    // ✅ reuse UID for 10 seconds to prevent auth lock contention
    if (_cachedAuthUid && (now - _cachedAuthUidAt) < 10000) {
      return _cachedAuthUid;
    }

    const { data } = await window.sb.auth.getUser();
    const uid = data?.user?.id || null;

    _cachedAuthUid = uid;
    _cachedAuthUidAt = now;

    return uid;
  } catch {
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
    // 1) local fallback (if your project has it)
    const lp = (typeof loadProfile === "function") ? loadProfile() : null;

    // if local profile exists and looks valid, return it immediately
    if (lp && typeof lp === "object") {
      // optional: if local profile has uid and matches, prefer it
      if (!lp.id || !uid || String(lp.id) === String(uid)) return lp;
    }

    // 2) DB fetch
    if (!window.sb || !uid) return lp || null;

    const { data, error } = await window.sb
      .from("users")
      .select("id, telegram_user_id, first_name, last_name, avatar_url, language_code, is_school_student, region, district, school, class, region_id, district_id")
      .eq("id", uid)
      .maybeSingle();

    if (error) return lp || null;
    return data || lp || null;
  } catch {
    return (typeof loadProfile === "function") ? (loadProfile() || null) : null;
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

  const uid = await getAuthUid();
  if (!uid) return { ok: false, reason: "no_uid" };

  const tgUser = getTelegramUserSafe() || {};
  const avatar = tgUser?.photo_url || null;

   // 1) update users row
  const fullNameRaw = String(profile?.full_name || profile?.name || "").trim();
  const nameParts = fullNameRaw ? fullNameRaw.split(/\s+/).filter(Boolean) : [];
  const firstFromProfile = nameParts.length ? nameParts[0] : null;
  const lastFromProfile = (nameParts.length > 1) ? nameParts.slice(1).join(" ") : null;

  const usersPayload = {
    id: uid,
    telegram_user_id: (tgUser?.id != null) ? String(tgUser.id) : null,

    // ✅ если Telegram не дал first/last_name — берём из формы регистрации
    first_name: tgUser?.first_name || firstFromProfile || null,
    last_name: tgUser?.last_name || lastFromProfile || null,

    avatar_url: avatar,
        language_code: profile?.language || tgUser?.language_code || "ru",
    is_school_student: !!profile?.is_school_student,

    // ✅ сохраняем ID (FK), а текст оставляем для отображения/резерва
    region_id: (profile?.region_id != null && profile.region_id !== "") ? Number(profile.region_id) : null,
    district_id: (profile?.district_id != null && profile.district_id !== "") ? Number(profile.district_id) : null,

    region: profile?.region || null,
    district: profile?.district || null,

    school: profile?.school || null,
    class: profile?.class || null
  };

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
    try { trackEvent("registration_db_error", { where: "users_upsert", message: String(uErr?.message || uErr) }); } catch {}
    return { ok: false, reason: "users_upsert_failed" };
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

async function hydrateLocalProfileFromSupabaseIfMissing() {
  if (loadProfile()) return { ok: true, skipped: true, reason: "local_profile_exists" };
  if (!window.sb) return { ok: false, reason: "no_sb" };

  const uid = await getAuthUid();
  if (!uid) return { ok: false, reason: "no_uid" };

  const me = await getMyUserRow(uid);
  if (!me) return { ok: false, reason: "no_users_row" };

  // Load user_subjects with subject_key (FK relationship expected)
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

   // ✅ Маркер завершённой регистрации в БД:
  // users.is_school_student должен быть именно TRUE/FALSE. Если NULL — регистрация не завершена.
  const regFlag =
    (me.is_school_student === true) ? true :
    (me.is_school_student === false) ? false :
    null;

  if (regFlag === null) {
    // Не создаём local profile-заглушку, иначе апп “проскочит” регистрацию
    return { ok: true, hydrated: false, reason: "db_registration_not_completed" };
  }

  const profile = {
    created_at: nowISO(),
    full_name: fullName || "",
    // language = язык контента (туры/практика)
    language: me.language_code || "ru",
    // uiLanguage = язык интерфейса (если ранее был выбран локально — сохраняем)
    uiLanguage: (loadProfile()?.uiLanguage) || (me.language_code || "ru"),

    // ✅ ВАЖНО: не !!..., а строго boolean из БД
    is_school_student: regFlag,

    region: me.region || "",
    district: me.district || "",
    school: me.school || "",
    class: me.class || "",
    telegram: {
      id: null,
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

async function issueFinalCertificateDb(userId, subjectId) {
  try {
    if (!window.sb || !userId || !subjectId) return null;

    const { data, error } = await window.sb.rpc("issue_final_certificate", {
      p_user_id: userId,
      p_subject_id: Number(subjectId)
    });

    if (error) {
      try {
        const uid = await getAuthUid();
        await logDbErrorToEvents(uid, "issue_final_certificate_rpc", error, {
          p_user_id: userId,
          p_subject_id: Number(subjectId)
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
        p_subject_id: Number(subjectId)
      });
    } catch {}
    return null;
  }
}
   const __finalCertReadyCache = new Map();

async function canIssueFinalCertificateNow(subjectId) {
  try {
    if (!window.sb || !subjectId) return false;

    const sid = Number(subjectId);
    if (!sid) return false;

    const cacheKey = `${sid}`;
    const cached = __finalCertReadyCache.get(cacheKey);
    if (cached && (Date.now() - cached.ts < 60 * 1000)) {
      return !!cached.ready;
    }

    const today = new Date();
    const todayIso = `${today.getFullYear()}-${String(today.getMonth() + 1).padStart(2, "0")}-${String(today.getDate()).padStart(2, "0")}`;

    const { data, error } = await window.sb
      .from("tours")
      .select("tour_no,end_date,is_active")
      .eq("subject_id", sid)
      .gte("tour_no", 1)
      .lte("tour_no", 7);

    if (error || !Array.isArray(data) || data.length === 0) {
      __finalCertReadyCache.set(cacheKey, { ready: false, ts: Date.now() });
      return false;
    }

    const uniqTours = new Set(
      data.map(x => Number(x.tour_no)).filter(n => Number.isFinite(n) && n >= 1 && n <= 7)
    );

    const allFinished =
      uniqTours.size === 7 &&
      data.every(row => !!row?.end_date && String(row.end_date) < todayIso);

    __finalCertReadyCache.set(cacheKey, { ready: allFinished, ts: Date.now() });
    return allFinished;
  } catch {
    return false;
  }
}

   async function tryIssueFinalCertificateForSubject(subjectId) {
  try {
    if (!window.sb || !subjectId) return null;

    const sid = Number(subjectId);
    if (!sid) return null;

    const ready = await canIssueFinalCertificateNow(sid);
    if (!ready) return null;

    const uid = await getAuthUid();
    if (!uid) return null;

    const row = await issueFinalCertificateDb(uid, sid);
    if (!row?.id) return null;

    if (!state.certificates) {
      state.certificates = { selectedId: null, lastIssuedId: null };
    }

    state.certificates.selectedId = Number(row.id);
    state.certificates.lastIssuedId = Number(row.id);
    saveState();

    return row;
  } catch {
    return null;
  }
}
   
async function fetchMyCertificatesDb() {
  try {
    if (!window.sb) return [];

    const uid = await getAuthUid();
    if (!uid) return [];

    const { data, error } = await window.sb
      .from("certificates")
      .select(`
        id,
        user_id,
        subject_id,
        tour_id,
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

async function renderCertificatesView() {
  const listEl = document.getElementById("certificates-list");
  if (!listEl) return;

  listEl.innerHTML = `
    <div class="empty muted">${escapeHTML(t("loading") || "Loading…")}</div>
  `;

  const rows = await fetchMyCertificatesDb();

    if (!rows.length) {
    listEl.innerHTML = `
      <div class="card" style="text-align:center; padding:20px;">
        <div style="font-size:34px; line-height:1; margin-bottom:10px;">🏅</div>
        <div style="font-weight:900; margin-bottom:6px;">
          ${escapeHTML(t("certificates_empty_title") || "Сертификатов пока нет")}
        </div>
        <div class="muted" style="margin-bottom:14px;">
          ${escapeHTML(t("certificates_empty") || "Пока сертификатов нет.")}
        </div>
        <div class="muted small">
          ${escapeHTML(t("certificates_empty_hint") || "Завершите активный тур, чтобы здесь появился ваш официальный результат.")}
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
    listEl.innerHTML = "";
    await renderCertificateViewer(rows);
    return;
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
    const qrSize = mobile ? 80 : 94;

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
      padding: 4
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
      .select("id,user_id,subject_id,tour_id,certificate_type,score,percent,certificate_number,language_code,created_at")
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
          .select("first_name,last_name,school,class,region,district")
          .eq("id", certRow.user_id)
          .maybeSingle();

        userRow = data || null;
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
      first_name: baseRow?.first_name || userRow?.first_name || null,
      last_name: baseRow?.last_name || userRow?.last_name || null,
      school: baseRow?.school || userRow?.school || null,
      class: baseRow?.class || userRow?.class || null,
      region: baseRow?.region || userRow?.region || null,
      district: baseRow?.district || userRow?.district || null
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

  const subjectText = row.subject_key
    ? subjectTitle(row.subject_key, row.subject_title || "")
    : (row.subject_title || (t("subject_label") || "Предмет"));

    const typeText =
    String(row?.certificate_type || "") === "final"
      ? (t("cert_final_label") || "Итоговый сертификат")
      : `${t("tours_tour_label") || "Тур"} ${Number(row?.tour_no || 0) || "—"}`;

  const participantName =
    String(
      [row?.first_name, row?.last_name].filter(Boolean).join(" ").trim() ||
      row?.full_name ||
      ""
    ).trim() || "—";

  const schoolText = String(row?.school || "").trim();
  const classText = String(row?.class || "").trim();
  const regionText = String(row?.region || "").trim();
  const districtText = String(row?.district || "").trim();

  resultEl.innerHTML = `
    <div class="card cert-verify-card">
      <div class="cert-verify-badge">${escapeHTML(t("certificate_verify_valid") || "Сертификат действителен")}</div>

      <div class="cert-verify-grid">
        <div class="cert-verify-row">
          <div class="cert-verify-label">${escapeHTML(t("certificate_number_label") || "Номер сертификата")}</div>
          <div class="cert-verify-value cert-verify-number">${escapeHTML(String(row.certificate_number || "—"))}</div>
        </div>

               <div class="cert-verify-row">
          <div class="cert-verify-label">${escapeHTML(t("participant_label") || "Участник")}</div>
          <div class="cert-verify-value">${escapeHTML(participantName)}</div>
        </div>

        <div class="cert-verify-row">
          <div class="cert-verify-label">${escapeHTML(t("subject_label") || "Предмет")}</div>
          <div class="cert-verify-value">${escapeHTML(subjectText)}</div>
        </div>

        ${
          schoolText
            ? `
              <div class="cert-verify-row">
                <div class="cert-verify-label">${escapeHTML(t("school_prefix") || "Школа")}</div>
                <div class="cert-verify-value">${escapeHTML(schoolText)}${classText ? ` · ${escapeHTML(classText)} ${escapeHTML(t("class_suffix") || "класс")}` : ""}</div>
              </div>
            `
            : ""
        }

        ${
          (regionText || districtText)
            ? `
              <div class="cert-verify-row">
                <div class="cert-verify-label">${escapeHTML(t("rank_region_label") || "Регион")} / ${escapeHTML(t("rank_district_label") || "Район")}</div>
                <div class="cert-verify-value">${escapeHTML(regionText || "—")}${districtText ? ` · ${escapeHTML(districtText)}` : ""}</div>
              </div>
            `
            : ""
        }
        <div class="cert-verify-row">
          <div class="cert-verify-label">${escapeHTML(t("certificates_title") || "Сертификат")}</div>
          <div class="cert-verify-value">${escapeHTML(typeText)}</div>
        </div>

        <div class="cert-verify-row">
          <div class="cert-verify-label">${escapeHTML(t("certificate_result_label") || "Результат")}</div>
          <div class="cert-verify-value">${escapeHTML(String(row.score ?? "—"))} ${escapeHTML(t("points_label") || "балл")} · ${escapeHTML(String(row.percent ?? "—"))}%</div>
        </div>

        <div class="cert-verify-row">
          <div class="cert-verify-label">${escapeHTML(t("date_label") || "Дата")}</div>
          <div class="cert-verify-value">${escapeHTML(formatDateShortSafe(row.created_at))}</div>
        </div>
      </div>
    </div>
  `;
}

function certificateViewerHtml(row) {
  if (!row) {
    return `
      <div class="card">
        <div class="muted">${escapeHTML(t("certificates_empty") || "Пока сертификатов нет.")}</div>
      </div>
    `;
  }

  const profile = loadProfile?.() || {};
  const certLang = String(row?.language_code || currentLang() || "ru").toLowerCase();

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
      profile?.full_name ||
      profile?.fullName ||
      profile?.fullname ||
      profile?.name ||
      ""
    ).trim() ||
    [profile?.first_name, profile?.last_name].filter(Boolean).join(" ").trim() ||
    "iClub User";

    const subjectText = row.subject_title || (certT("subject_label", "Предмет"));
  const regionText =
    String(
      (profile?.region_tr && profile.region_tr[certLang]) ||
      profile?.region_name ||
      profile?.region ||
      row?.region ||
      certT("rank_region_label", "Регион")
    ).trim();
  const districtText =
    String(
      (profile?.district_tr && profile.district_tr[certLang]) ||
      profile?.district_name ||
      profile?.district ||
      row?.district ||
      certT("rank_district_label", "Район")
    ).trim();

  return `
    <div class="card" id="certificate-viewer-card" style="padding:0; overflow:hidden;">
      <div id="certificate-canvas-root" class="cert-sheet">
        <div class="cert-paper">
          <div class="cert-top">
            <div class="cert-brand">
              <img src="logo.png" alt="iClub" class="cert-logo" />
              <div>
                <div class="cert-brand-name">iClub</div>
                <div class="cert-brand-sub">${escapeHTML(certT("brand_tagline") || "Smarter together")}</div>
              </div>
            </div>
          </div>

          <div class="cert-hero">
            <div class="cert-kicker">${escapeHTML(certT("certificate_awarded_label", "Официальный сертификат участника"))}</div>
            <div class="cert-name">${escapeHTML(fullName)}</div>
          </div>

                   <div class="cert-grid-main-3 cert-info-grid">
            <div class="cert-info-card">
              <div class="cert-info-label">${escapeHTML(certT("subject_label", "Предмет"))}</div>
              <div class="cert-info-value">${escapeHTML(subjectText)}</div>
            </div>

            <div class="cert-info-card">
              <div class="cert-info-label">
                ${
                  String(row?.certificate_type || "") === "final"
                    ? escapeHTML(certT("certificates_title", "Сертификат"))
                    : escapeHTML(certT("tours_tour_label", "Тур"))
                }
              </div>
              <div class="cert-info-value">
                ${
                  String(row?.certificate_type || "") === "final"
                    ? escapeHTML(certT("cert_final_label", "Итоговый сертификат"))
                    : escapeHTML(String(row.tour_no || "—"))
                }
              </div>
            </div>

            <div class="cert-info-card">
              <div class="cert-info-label">${escapeHTML(certT("participants_total_label", "Участников"))}</div>
              <div class="cert-info-value">${escapeHTML(String(row.participants_total ?? "—"))}</div>
            </div>
          </div>

          <div class="cert-grid-main-2 cert-result-grid">
            <div class="cert-stat cert-stat-primary">
              <div class="cert-stat-label">${escapeHTML(certT("certificate_result_label", "Результат"))}</div>
              <div class="cert-stat-value">${escapeHTML(String(row.score ?? "—"))} ${escapeHTML(certT("points_label", "балл"))}</div>
            </div>

            <div class="cert-stat cert-stat-primary">
              <div class="cert-stat-label">${escapeHTML(certT("correct_answers_percent_label", "Правильных ответов"))}</div>
              <div class="cert-stat-value">${escapeHTML(String(row.percent ?? "—"))}%</div>
            </div>
          </div>

          <div class="cert-grid-main-3 cert-rank-grid">
            <div class="cert-rank">
              <div class="cert-rank-label">${escapeHTML(certT("rank_country_label", "Республика"))}</div>
              <div class="cert-rank-value">${escapeHTML(String(row.rank_country ?? "—"))}-${escapeHTML(certT("rank_suffix_label", "место"))}</div>
            </div>

            <div class="cert-rank">
              <div class="cert-rank-label">${escapeHTML(regionText)}</div>
              <div class="cert-rank-value">${escapeHTML(String(row.rank_region ?? "—"))}-${escapeHTML(certT("rank_suffix_label", "место"))}</div>
            </div>

            <div class="cert-rank">
              <div class="cert-rank-label">${escapeHTML(districtText)}</div>
              <div class="cert-rank-value">${escapeHTML(String(row.rank_district ?? "—"))}-${escapeHTML(certT("rank_suffix_label", "место"))}</div>
            </div>
          </div>

          ${
            String(row?.certificate_type || "") === "final"
              ? `
          <div class="cert-final-box">
            <div class="cert-final-label">${escapeHTML(certT("completed_tours_label", "Завершено туров"))}</div>
            <div class="cert-final-value">${escapeHTML(String(row.completed_tours ?? 0))}/${escapeHTML(String(row.total_tours ?? 7))}</div>
          </div>
          `
              : ``
          }

                    <div class="cert-bottom">
            <div class="cert-bottom-meta">
              <div class="cert-date-line">
                <span>${escapeHTML(certT("date_label", "Дата"))}:</span>
                <b>${escapeHTML(formatDateForLangSafe(row.created_at, certLang))}</b>
              </div>

              <div class="cert-number-box cert-number-box-bottom">
                <div class="cert-number-label">${escapeHTML(certT("certificate_number_label") || "Номер сертификата")}</div>
                <div class="cert-number-value">${escapeHTML(String(row.certificate_number || "—"))}</div>
              </div>

              <div class="cert-qr-hint">${escapeHTML(certT("certificate_qr_hint") || "QR orqali tekshirish")}</div>
            </div>

            <div class="cert-qr-wrap">
              <div id="certificate-qr" class="cert-qr"></div>
              <div class="cert-qr-caption">${escapeHTML(certT("certificate_qr_caption") || "Tekshirish")}</div>
            </div>
          </div>
        </div>
      </div>

      <div class="cert-actions">
        <button class="btn primary" type="button" data-action="certificate-download-png" data-id="${Number(row.id)}">
          ${escapeHTML(certT("download_png_label", "Скачать PNG"))}
        </button>
        <button class="btn" type="button" data-action="certificate-download-pdf" data-id="${Number(row.id)}">
          ${escapeHTML(certT("download_pdf_label", "Скачать PDF"))}
        </button>
      </div>
    </div>
  `;
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
  wrap.style.marginTop = "16px";
  wrap.innerHTML = certificateViewerHtml(selected);

  listEl.parentNode.appendChild(wrap);
  await renderCertificateQr(selected);
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
  if (!root) {
    showToast(t("certificates_empty") || "Пока сертификатов нет.");
    return null;
  }

  await ensureHtml2CanvasLoaded();

  root.classList.add("cert-export-mode");

  try {
    const canvas = await window.html2canvas(root, {
      backgroundColor: null,
      scale: 2,
      useCORS: true
    });

    if (kind === "png") {
      return await new Promise((resolve) => canvas.toBlob(resolve, "image/png"));
    }

    return canvas;
  } finally {
    root.classList.remove("cert-export-mode");
  }
}

async function downloadCertificateAsPng(row) {
  try {
    showCertificateDownloadOverlay();
    await waitForOverlayPaint();

    const blob = await buildCertificateCanvasBlob("png");
    if (!blob) return;

    triggerBlobDownload(blob, buildCertificateDownloadName(row, "png"));
  } catch {
    showToast(t("save_failed_try_again") || "Не удалось сохранить. Проверьте интернет.");
  } finally {
    hideCertificateDownloadOverlay();
  }
}

async function downloadCertificateAsPdf(row) {
  try {
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
    hideCertificateDownloadOverlay();
  }
}
   
async function logDbErrorToEvents(uid, where, error, extraPayload = {}) {
  try {
    if (!window.sb || !uid) return;
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

  const rows = details.map((d, i) => {
    const rawUA = answers[i];
    const userAnswer = (rawUA === null || rawUA === undefined) ? null : String(rawUA);

    return {
      attempt_id: attemptId,
      question_id: Number(d?.id),
      user_answer: userAnswer,
      is_correct: !!d?.isCorrect,
      time_spent: Math.max(0, Math.round(Number(d?.timeSpent) || 0))
    };
  }).filter(r => Number.isFinite(r.question_id));

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
    .select("id,first_name,last_name,avatar_url,is_school_student,region,district,school,class")
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

  // 2) default subject:
  const uid = await getAuthUid();
  const myComp = await getMyCompetitiveSubjects(uid);

  // если участник — дефолт = его competitive предмет
  // если не участник — дефолт = первый из списка
  const defaultSubjectId = (myComp?.[0]?.subject_id) || (subjects?.[0]?.id) || null;
  ratingsState.subjectId = defaultSubjectId ? Number(defaultSubjectId) : null;

  // отрисуем subjects без placeholder
  renderRatingsSelectOptions(subjectSelect, subjectItems);
  if (ratingsState.subjectId && subjectSelect) subjectSelect.value = String(ratingsState.subjectId);

  // 3) tours for subject
  const tours = await loadRatingsToursForSubject(ratingsState.subjectId);
  const tourItems = [
    { value: "__all__", label: t("ratings_all_tours") || "All tours" },
    ...tours.map(tt => ({ value: tt.id, label: `Tour ${tt.tour_no}` }))
  ];
  renderRatingsSelectOptions(tourSelect, tourItems);

  // default = All tours
ratingsState.tourId = "__all__";
if (tourSelect) tourSelect.value = "__all__";

  ratingsState._booted = true;
}

 async function renderRatings() {
  const listEl = $("#ratings-list");
   listEl.innerHTML = "";
  const loadingEl = $("#ratings-loading");

  const mybar = $("#ratings-mybar");
  const myRankEl = $("#ratings-mybar-rank");
  const myTotalEl = $("#ratings-mybar-total");
  const myScoreEl = $("#ratings-mybar-score");
  const myTimeEl = $("#ratings-mybar-time");
  const hintEl = $("#ratings-viewer-hint");

  if (!listEl) return;

  const q = String(ratingsState.q || "").trim().toLowerCase();

  const showLoading = () => { if (loadingEl) loadingEl.style.display = "flex"; };
  const hideLoading = () => { if (loadingEl) loadingEl.style.display = "none"; };

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

  const token = ++ratingsState._token;

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

  // hint
  if (hintEl) hintEl.style.display = isParticipant ? "none" : "block";

    // если у меня нет district/region — принудительно country, иначе фильтры бессмысленны
  if ((ratingsState.scope === "district" && !me?.district) || (ratingsState.scope === "region" && !me?.region)) {
    ratingsState.scope = "country";
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

    const cacheHasData = !cacheProbe?.error && Array.isArray(cacheProbe?.data) && cacheProbe.data.length > 0;

    if (!cacheHasData) {
      // -------- fallback: compute leaderboard from tour_attempts --------
            const attemptsRes = await window.sb
        .from("tour_attempts")
        .select("user_id,score,total_time,status,users(first_name,last_name,school,class,region,district,region_id,district_id)")
        .eq("tour_id", tourId);
      if (token !== ratingsState._token) return;

      if (attemptsRes?.error) {
        hideLoading();
        listEl.innerHTML = `<div class="empty muted">${escapeHTML(t("ratings_load_error"))}</div>`;
        return;
      }

            const raw = Array.isArray(attemptsRes?.data) ? attemptsRes.data : [];

      // keep only completed attempts (different DB variants)
      const OK_STATUSES = new Set(["submitted", "time_expired", "anti_cheat", "finished"]);
      let pool = raw.filter(r => {
        const st = String(r?.status || "").trim();
        return !st || OK_STATUSES.has(st);
      });

            // scope filter via user profile (same behavior as cache)
      if (ratingsState.scope === "district") {
        const myDid = me?.district_id != null ? String(me.district_id) : "";
        if (myDid) {
          pool = pool.filter(r => String(r?.users?.district_id ?? "") === myDid);
        } else if (me?.district) {
          pool = pool.filter(r => String(r?.users?.district || "") === String(me.district));
        }
      } else if (ratingsState.scope === "region") {
        const myRid = me?.region_id != null ? String(me.region_id) : "";
        if (myRid) {
          pool = pool.filter(r => String(r?.users?.region_id ?? "") === myRid);
        } else if (me?.region) {
          pool = pool.filter(r => String(r?.users?.region || "") === String(me.region));
        }
      }

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
      .select("user_id,score,total_time,rank_no,users(first_name,last_name,school,class,region,district)")
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
        .select("user_id,score,total_time,rank_no,users(first_name,last_name,school,class,region,district)")
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
      .select("user_id,score,total_time,rank_no,users(first_name,last_name,school,class,region,district)")
      .eq("tour_id", tourId)
      .eq("rank_type", scopeRankType)
      .order("rank_no", { ascending: false })
      .limit(3);

    if (token !== ratingsState._token) return;
    if (!bottomRes?.error && Array.isArray(bottomRes?.data)) bottomData = bottomRes.data.slice().reverse();

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
          .in("status", ["submitted", "time_expired"])
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
        .in("status", ["submitted", "time_expired"])
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

      myScoreEl.textContent = `${String(myRow.score ?? "—")} pts`;
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

if (token !== ratingsState._token) return;

if (attErr) {
  hideLoading();
  listEl.innerHTML = `<div class="empty muted">${escapeHTML(t("ratings_load_error"))}</div>`;
  return;
}

const OK_STATUSES = new Set(["finished", "submitted", "time_expired", "anti_cheat"]);

// filter by status + scope using my profile
const filteredAttempts = (Array.isArray(attempts) ? attempts : []).filter(a => {
  const st = String(a?.status || "").trim();
  if (st && !OK_STATUSES.has(st)) return false;

  const u = a.users || {};

  if (ratingsState.scope === "district") {
    const myDid = me?.district_id != null ? String(me.district_id) : "";
    if (myDid) return String(u.district_id ?? "") === myDid;
    return !!me?.district && String(u.district || "") === String(me.district || "");
  }

  if (ratingsState.scope === "region") {
    const myRid = me?.region_id != null ? String(me.region_id) : "";
    if (myRid) return String(u.region_id ?? "") === myRid;
    return !!me?.region && String(u.region || "") === String(me.region || "");
  }

  return true; // country
});
    
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

      myScoreEl.textContent = `${String(mine.score)} pts`;
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

      // tours reload
      if (window.sb && ratingsState.subjectId) {
        const tours = await loadRatingsToursForSubject(ratingsState.subjectId);
        const tourItems = [
          { value: "__all__", label: t("ratings_all_tours") || "All tours" },
          ...tours.map(tt => ({ value: tt.id, label: `Tour ${tt.tour_no}` }))
        ];
        renderRatingsSelectOptions(tourSelect, tourItems);
        if (tourSelect) tourSelect.value = "__all__";
        ratingsState.tourId = null;
      }

      renderRatings();
    });
  }

  if (tourSelect) {
    tourSelect.addEventListener("change", () => {
      const v = tourSelect.value;
      ratingsState.tourId = (v && v !== "__all__") ? Number(v) : null;
      renderRatings();
    });
  }

  // segmented tabs
  $$(".lb-segment .seg-btn").forEach(btn => {
    btn.addEventListener("click", () => {
      const scope = btn.dataset.scope;
      if (!scope) return;
      ratingsState.scope = scope;
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
      renderToursStart();          // ✅ вернёт корректный вид туров после выхода из правил
    } else if (next === "practice-start") {
      renderPracticeStart();
    } else if (next === "subject-hub") {
      renderSubjectHub();
    } else if (next === "books") {
      renderBooks();
    } else if (next === "my-recs") {
      renderMyRecs();
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

  // ✅ special-case: "my-recs" может быть открыт из Profile (stack=1),
  // но back должен вести обратно в entryTab через popCourses()
  if (top === "my-recs") return true;

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
        showToast("Не удалось сохранить. Попробуйте ещё раз.");
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

  showToast(isPinned ? t("toast_removed_pinned") : t("toast_added_pinned"));
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

  // --- Best / Trend / Stability (реальные данные из practice_history_v1:*) ---
  const keys = subjects.map(s => s.key).filter(Boolean);

  // Best (max percent)
  let best = null;
  const allAttempts = [];

  keys.forEach(k => {
    const h = loadPracticeHistory(k);
    if (h?.best) {
      if (!best || (Number(h.best.percent) > Number(best.percent))) best = h.best;
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

    // ✅ translate legacy hardcoded RU messages (and keep normal messages intact)
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
  }

  function initRegSubjectChips() {
  const wrap = $("#reg-subject-chips");
  const main1 = $("#reg-main-subject-1");
  const main2 = $("#reg-main-subject-2");
  if (!wrap || !main1 || !main2) return;

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
  
     document.addEventListener("reg-subjects-i18n-updated", updateSummary);
  
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

  main1.addEventListener("change", syncChipsFromSelects);
  main2.addEventListener("change", syncChipsFromSelects);
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

    // Если школьник — нужны subjects (минимум 1 competitive) + базовые поля школы
    if (p.is_school_student === true) {
      const subjects = Array.isArray(p.subjects) ? p.subjects : [];
      const compCnt = subjects.filter(s => s && s.mode === "competitive" && s.key).length;
      if (compCnt < 1) return false;

      const region = String(p.region || "").trim();
      const district = String(p.district || "").trim();
      if (!region) return false;

      // district может быть не обязателен в твоей форме, но если он есть в форме как required — он уже проверяется там.
      // Здесь не ужесточаем лишнего: оставляем как мягкое условие.
      // if (!district) return false;
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

  try {
    if (!window.sb) return { moduleNo: 1, progressPct: 0, rankNo: null, completedCount: 0, totalTours: 0 };

    const subjectId = await getSubjectIdByKey(subjectKey);
    if (!subjectId) return { moduleNo: 1, progressPct: 0, rankNo: null, completedCount: 0, totalTours: 0 };

    const uid = await getAuthUid();
    if (!uid) return { moduleNo: 1, progressPct: 0, rankNo: null, completedCount: 0, totalTours: 0 };

    // 1) tours for this subject
    const toursRes = await window.sb
      .from("tours")
      .select("id,tour_no")
      .eq("subject_id", subjectId)
      .order("tour_no", { ascending: true });

    const tours = Array.isArray(toursRes?.data) ? toursRes.data : [];
    if (!tours.length) return { moduleNo: 1, progressPct: 0, rankNo: null, completedCount: 0, totalTours: 0 };

    // 2) attempts for this subject (submitted only)
    const attemptRes = await window.sb
      .from("tour_attempts")
      .select("id,tour_id,percent,status")
      .eq("user_id", uid)
      .in("status", ["submitted"])
      .order("created_at", { ascending: false });

    const attempts = Array.isArray(attemptRes?.data) ? attemptRes.data : [];

    const completedTourIds = new Set(attempts.map(a => Number(a.tour_id)).filter(Boolean));
    const completedCount = tours.filter(t => completedTourIds.has(Number(t.id))).length;

    const totalTours = tours.length || 0;
    const progressPct = totalTours ? Math.round((completedCount / totalTours) * 100) : 0;

    // moduleNo = next tour number (1..7)
    const moduleNo = Math.min(7, Math.max(1, completedCount + 1));

        // 3) rank: show place for the latest COMPLETED tour, not for the next module
    let rankNo = null;
    try {
      const completedToursDesc = tours
        .filter(t => completedTourIds.has(Number(t.id)))
        .sort((a, b) => Number(b.tour_no) - Number(a.tour_no));

      const rankTour =
        completedToursDesc[0] ||
        tours.find(t => Number(t.tour_no) === Number(moduleNo)) ||
        tours[tours.length - 1];

      if (rankTour?.id) {
        const rRes = await window.sb
          .from("ratings_cache")
          .select("rank_no")
          .eq("tour_id", Number(rankTour.id))
          .eq("user_id", uid)
          .eq("rank_type", "country")
          .limit(1);

        const row = Array.isArray(rRes?.data) ? rRes.data[0] : null;
        if (row && row.rank_no != null) rankNo = Number(row.rank_no);
      }
    } catch {}

    const out = { moduleNo, progressPct, rankNo, completedCount, totalTours: tours.length };
    _homeStatsCache.set(cacheKey, { ts: Date.now(), data: out });
    return out;
  } catch {
    return { moduleNo: 1, progressPct: 0, rankNo: null, completedCount: 0, totalTours: 0 };
  }
}

async function updateHomeCompetitiveCard(cardEl, subjectKey) {
  try {
    if (!cardEl) return;

    const modEl = cardEl.querySelector(".js-home-comp-module");
    const rankEl = cardEl.querySelector(".js-home-comp-rank");
    const fillEl = cardEl.querySelector(".js-home-comp-fill");

    const s = await computeHomeStudyPracticeStats(subjectKey);
    const done = Number(s?.masteredCount || 0);
    const total = Number(s?.totalCount || 0);
    const progressPct = total > 0 ? Math.max(0, Math.min(100, Math.round((done / total) * 100))) : 0;

    if (modEl) modEl.textContent = t("home_practice_progress_label");
    if (rankEl) rankEl.textContent = total > 0 ? `${done}/${total}` : "—/—";
    if (fillEl) fillEl.style.width = `${progressPct}%`;
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
    if (!window.sb) return { masteredCount: 0, totalCount: 0 };

    const subjectId = await getSubjectIdByKey(subjectKey);
    if (!subjectId) return { masteredCount: 0, totalCount: 0 };

    const uid = await getAuthUid();
    if (!uid) return { masteredCount: 0, totalCount: 0 };

    // 1) all practice questions of this subject
    const poolsRes = await window.sb
      .from("practice_pools")
      .select("id")
      .eq("subject_id", subjectId)
      .eq("is_active", true);

    const poolIds = (Array.isArray(poolsRes?.data) ? poolsRes.data : [])
      .map(x => Number(x?.id))
      .filter(Boolean);

    let totalCount = 0;
    if (poolIds.length) {
      const ppqRes = await window.sb
        .from("practice_pool_questions")
        .select("question_id")
        .in("pool_id", poolIds)
        .eq("is_active", true);

      const totalQuestionIds = new Set(
        (Array.isArray(ppqRes?.data) ? ppqRes.data : [])
          .map(x => Number(x?.question_id))
          .filter(Boolean)
      );

      totalCount = totalQuestionIds.size;
    }

    // 2) unique correctly answered practice questions by this user in this subject
    const attemptsRes = await window.sb
      .from("practice_attempts")
      .select("id")
      .eq("user_id", uid)
      .eq("subject_id", subjectId);

    const attemptIds = (Array.isArray(attemptsRes?.data) ? attemptsRes.data : [])
      .map(x => Number(x?.id))
      .filter(Boolean);

    let masteredCount = 0;
    if (attemptIds.length) {
      const answersRes = await window.sb
        .from("practice_answers")
        .select("question_id")
        .in("attempt_id", attemptIds)
        .eq("is_correct", true);

      const masteredQuestionIds = new Set(
        (Array.isArray(answersRes?.data) ? answersRes.data : [])
          .map(x => Number(x?.question_id))
          .filter(Boolean)
      );

      masteredCount = masteredQuestionIds.size;
    }

    const out = { masteredCount, totalCount };
    _homeStatsCache.set(cacheKey, { ts: Date.now(), data: out });
    return out;
  } catch {
    return { masteredCount: 0, totalCount: 0 };
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

      const badgeActive = t("badge_active") || "ACTIVE";
  const moduleTxt = t("home_practice_progress_label") || "";

  el.innerHTML = `
    <div class="home-competitive-badge">${escapeHTML(badgeActive)}</div>
    <div class="home-competitive-hero">
      <div class="home-competitive-hero-img" aria-hidden="true"></div>
    </div>
    <div class="home-competitive-body">
      <div class="home-competitive-module js-home-comp-module">${escapeHTML(moduleTxt)}</div>
      <div class="home-competitive-title">${escapeHTML(title)}</div>
      <div class="home-competitive-meta">
        <span>${t("home_practice_progress_label")}</span>
        <span class="home-competitive-rank js-home-comp-rank">—/—</span>
      </div>
      <div class="home-progress">
        <div class="home-progress-fill js-home-comp-fill" style="width:0%"></div>
      </div>
    </div>
   `;

  const btn = document.createElement("button");
  btn.type = "button";
  btn.className = "btn primary home-competitive-btn";
  btn.textContent = t("open_subject_btn") || "Open subject";
  btn.addEventListener("click", (e) => {
  e.stopPropagation();

  // ✅ Home: сразу открываем Subject Hub (без промежуточных туров)
    state.courses.subjectKey = userSubject.key;

  // ✅ Home is the entry point for this flow
  state.courses.entryTab = "home";

  saveState();
  setTab("courses");
  replaceCourses("subject-hub");
  renderSubjectHub();
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
const isStudyActive = mode === "study";

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
  const isActiveInCurrentTab = isCompetitiveTab ? isComp : isStudyActive;

  footer.className = "catalog-toggle-row" + (isActiveInCurrentTab ? " is-on" : "");

  const left = document.createElement("div");
  left.className = "catalog-toggle-left";

  const stateLine = document.createElement("div");
  stateLine.className = "catalog-toggle-state";
  stateLine.textContent = isActiveInCurrentTab
    ? (t("course_toggle_on") || "Включено")
    : (t("course_toggle_off") || "Выключено");

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
          title: t("courses_activate_study_title") || "Включить предмет?",
          message:
            t("courses_activate_study_text") ||
            "Предмет будет активирован в учебном режиме.",
          okText: t("courses_activate_study_ok") || "Включить",
          cancelText: t("cancel") || "Отмена"
        });

        if (!ok) {
          input.checked = false;
          return;
        }

        const updated = upsertUserSubjectMode(fresh, s.key, "study");
        saveProfile(updated);

        try {
          const res = await syncUserSubjectToSupabase(s.key, "study", false);
          if (!res?.ok) {
            input.checked = false;
            showToast(t("save_failed_db_try_again"));
            renderAllSubjects();
            return;
          }

          showToast(t("toast_subject_activated_study") || "Предмет включён в учебный режим.");
        } catch {
          input.checked = false;
          showToast(t("network_error_try_again") || "Ошибка сети. Попробуйте ещё раз.");
          renderAllSubjects();
          return;
        }
      } else {
        const ok = await uiConfirm({
          title: t("courses_deactivate_study_title") || "Выключить предмет?",
          message:
            t("courses_deactivate_study_text") ||
            "Предмет будет выключен в учебном режиме.",
          okText: t("courses_deactivate_study_ok") || "Выключить",
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

          showToast(t("toast_subject_deactivated") || "Предмет выключен.");
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
    pushCourses("subject-hub");
    renderSubjectHub();
  }
         
// ---------------------------
// Subject Hub mentor
// ---------------------------
const TEAM_CACHE_VERSION = 2;

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
    name: String(local.name || ""),
    role: String(local.role || ""),
    meta: String(local.meta || ""),
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
    function renderSubjectHub() {
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
      const pinLabel = us.pinned ? t("hub_pinned") : t("hub_not_pinned");
      metaEl.textContent = `${modeLabel} • ${pinLabel}`;
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
    renderSubjectHubMentorCard(subjectKey).catch(() => null);
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
        await renderVideo({ id: lesson.id, title: lesson.title, topic, order_no: lesson.order_no });
      });

      list.appendChild(item);
    });
  }

    async function renderVideo(lesson) {
    const tEl = $("#video-title");
    const mEl = $("#video-meta");
    if (tEl) tEl.textContent = getLessonDisplayTitle(lesson);
    if (mEl) mEl.textContent = lesson?.topic || "";

    const wrapEl = document.getElementById("video-player-wrap");
    const iframe = document.getElementById("video-player");
    const emptyEl = document.getElementById("video-empty");
    const externalBox = document.getElementById("video-external-box");
    const externalBtn = document.getElementById("video-open-external");
    const externalHint = document.getElementById("video-external-hint");

    // reset UI
    try {
      if (ytPlayer && typeof ytPlayer.stopVideo === "function") ytPlayer.stopVideo();
      if (iframe) iframe.removeAttribute("src");
      if (wrapEl) wrapEl.style.display = "none";
      if (emptyEl) emptyEl.style.display = "block";
      if (externalBox) externalBox.style.display = "none";
      if (externalBtn) {
        externalBtn.onclick = null;
        externalBtn.removeAttribute("data-url");
      }
      if (externalHint) {
        externalHint.textContent = t("video_external_hint") || "Откройте видео по кнопке ниже.";
      }
    } catch {}

    if (!window.sb || !lesson?.id) {
      updateTopbarForView("courses");
      return;
    }

    const { data, error } = await window.sb
      .from("videos")
      .select("video_url")
      .eq("lesson_id", lesson.id)
      .limit(1)
      .maybeSingle();

    if (error) {
      logClientError("videos_select_error", error);
      updateTopbarForView("courses");
      return;
    }

    const url = String(data?.video_url || "").trim();
    if (!url) {
      updateTopbarForView("courses");
      return;
    }

    const videoId = extractYouTubeVideoId(url);
    const isTelegramUrl = isTelegramVideoUrl(url);

    try {
      const subject_id = state?.courses?.subjectKey ? String(state.courses.subjectKey) : "";
      const lesson_id = lesson?.id ? String(lesson.id) : "";

      trackEvent("video_opened", {
        subject_id,
        lesson_id,
        provider: videoId ? "youtube" : (isTelegramUrl ? "telegram" : "external")
      });

      insertVideoEventToSupabase("opened", lesson_id, 0);
    } catch {}

    try {
      if (videoId) {
        if (wrapEl) wrapEl.style.display = "block";
        if (emptyEl) emptyEl.style.display = "none";

        const isTg = !!(window.Telegram && window.Telegram.WebApp);

        const base = `https://www.youtube-nocookie.com/embed/${videoId}`;
        const params = new URLSearchParams();
        params.set("playsinline", "1");
        params.set("rel", "0");
        params.set("modestbranding", "1");

        if (!isTg) {
          params.set("enablejsapi", "1");
          params.set("origin", window.location.origin);
        } else {
          params.set("enablejsapi", "0");
        }

        if (iframe) {
          iframe.src = `${base}?${params.toString()}`;
        }

        if (!isTg && isYtReady && window.YT && window.YT.Player) {
          if (!ytPlayer) {
            ytPlayer = new window.YT.Player("video-player", {
              host: "https://www.youtube-nocookie.com",
              playerVars: { origin: window.location.origin }
            });
          }
        }
      } else if (isTelegramUrl) {
        if (emptyEl) emptyEl.style.display = "none";
        if (externalBox) externalBox.style.display = "block";
        if (externalHint) {
          externalHint.textContent =
            t("video_external_telegram_hint") ||
            "Это видео открывается через Telegram.";
        }
        if (externalBtn) {
          externalBtn.setAttribute("data-url", url);
          externalBtn.onclick = () => {
            try {
              const lesson_id = lesson?.id ? String(lesson.id) : "";
              insertVideoEventToSupabase("started", lesson_id, 0);
            } catch {}
            openTelegramUrl(url);
          };
        }
      } else {
        if (emptyEl) emptyEl.style.display = "none";
        if (externalBox) externalBox.style.display = "block";
        if (externalHint) {
          externalHint.textContent =
            t("video_external_link_hint") ||
            "Это видео открывается по внешней ссылке.";
        }
        if (externalBtn) {
          externalBtn.setAttribute("data-url", url);
          externalBtn.onclick = () => {
            try {
              const lesson_id = lesson?.id ? String(lesson.id) : "";
              insertVideoEventToSupabase("started", lesson_id, 0);
            } catch {}
            openExternal(url);
          };
        }
      }
    } catch (e) {
      logClientError("video_player_bind_error", e);
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
        inputHint: type === "input" ? (isNumericLike(correctAnswer) ? "Введите число" : "Введите ответ") : ""
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
      async function saveTourRecsToDB(subjectKey, tourNo, recs) {
  try {
    if (!window.sb) return false;

    const uid = await getAuthUid();
    if (!uid) return false;

    const subjectId = await getSubjectIdByKey(subjectKey);
    if (!subjectId) return false;

    const items = (Array.isArray(recs) ? recs : [])
      .map(r => ({
        source_type: "tour",
        topic: String(r?.topic || "").trim(),
        subtopic: r?.subtopic ? String(r.subtopic).trim() : null,
        tour_no: Number(tourNo || 0) || null
      }))
      .filter(r => r.topic && r.tour_no);

    if (!items.length) return false;

    const { data: existing, error: selErr } = await window.sb
      .from("recommendations")
      .select("id, topic, subtopic, tour_no")
      .eq("user_id", uid)
      .eq("subject_id", subjectId)
      .eq("source_type", "tour")
      .eq("tour_no", Number(tourNo));

    if (selErr) {
      logClientError("tour_recs_existing_select_error", selErr);
      return false;
    }

    const existingSet = new Set(
      (Array.isArray(existing) ? existing : []).map(x =>
        `${Number(x?.tour_no || 0)}::${String(x?.topic || "").trim()}::${x?.subtopic ? String(x.subtopic).trim() : ""}`
      )
    );

    const toInsert = items
      .filter(r => !existingSet.has(`${r.tour_no}::${r.topic}::${r.subtopic || ""}`))
      .map(r => ({
        user_id: uid,
        subject_id: subjectId,
        source_type: "tour",
        tour_no: r.tour_no,
        topic: r.topic,
        subtopic: r.subtopic,
        book_id: null,
        book_reference: null
      }));

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

    if (!subjectKey || !tourNo) return { added: 0, recs: [] };

    const wrong = (Array.isArray(ctx?.answers) ? ctx.answers : [])
      .filter(a => a && a.isCorrect === false)
      .map(a => {
        const q = ctx?.questions?.[Number(a.index)] || null;
        return {
          topic: String(q?.topic || "General").trim(),
          subtopic: q?.subtopic ? String(q.subtopic).trim() : null
        };
      })
      .filter(x => x.topic);

    if (!wrong.length) return { added: 0, recs: [] };

    const uniqMap = new Map();
    wrong.forEach(r => {
      const k = `${tourNo}::${r.topic}::${r.subtopic || ""}`;
      if (!uniqMap.has(k)) uniqMap.set(k, r);
    });

    const uniq = Array.from(uniqMap.values());
    const store = loadMyTourRecs();
    store.bySubject = store.bySubject || {};

    const existing = new Set(
      (store.bySubject[subjectKey] || []).map(x =>
        `${Number(x?.tourNo || 0)}::${String(x?.topic || "").trim()}::${x?.subtopic ? String(x.subtopic).trim() : ""}`
      )
    );

    const nowTs = Date.now();

    const added = uniq
      .filter(r => !existing.has(`${tourNo}::${r.topic}::${r.subtopic || ""}`))
      .map(r => ({
        source_type: "tour",
        topic: r.topic,
        subtopic: r.subtopic,
        tourNo,
        ts: nowTs
      }));

    if (!added.length) return { added: 0, recs: [] };

        store.bySubject[subjectKey] = [
      ...added,
      ...(store.bySubject[subjectKey] || [])
    ].slice(0, 100);

    saveMyTourRecs(store);

    // DB-first persistence; local остаётся как безопасный fallback
    saveTourRecsToDB(subjectKey, tourNo, added).catch(() => {});

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

    // recs: [{ topic, subtopic }]
    const normalized = (Array.isArray(recs) ? recs : [])
  .map(r => {
    // backwards compatible:
    // - string -> topic
    // - object -> {topic, subtopic}
    if (typeof r === "string") {
      return { topic: String(r).trim(), subtopic: null };
    }
    return {
      topic: String(r?.topic || "").trim(),
      subtopic: r?.subtopic ? String(r.subtopic).trim() : null
    };
  })
  .filter(r => r.topic);

    if (!normalized.length) return;

    // unique by topic+subtopic
    const key = (r) => `${r.topic}::${r.subtopic || ""}`;
    const uniqMap = new Map();
    normalized.forEach(r => { uniqMap.set(key(r), r); });
    const uniq = Array.from(uniqMap.values());
    const topics = Array.from(new Set(uniq.map(r => r.topic)));

    // 1) existing in DB (avoid duplicates)
    const { data: existingRows, error: selErr } = await window.sb
      .from("recommendations")
      .select("topic, subtopic")
      .eq("user_id", uid)
      .eq("subject_id", subjectId)
      .eq("source_type", "practice")
      .in("topic", topics);

    if (selErr) {
      logClientError("recommendations_select_error", selErr);
      return;
    }

    const exists = new Set(
      (existingRows || []).map(r => `${String(r.topic || "").trim()}::${r.subtopic ? String(r.subtopic).trim() : ""}`)
    );

    const need = uniq.filter(r => !exists.has(key(r)));
    if (!need.length) return;

    // 2) try to enrich with book_id/book_reference via topic_book_map (best-effort)
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

    // pick best match: (topic+subtopic) first, else (topic only)
    const bestFor = (topic, subtopic) => {
      const t = String(topic || "").trim();
      const s = subtopic ? String(subtopic).trim() : null;

      const exact = mapRows.find(x =>
        String(x.topic || "").trim() === t &&
        (String(x.subtopic || "").trim() || null) === (s || null)
      );
      if (exact) return exact;

      const byTopic = mapRows.find(x =>
        String(x.topic || "").trim() === t &&
        (x.subtopic == null || String(x.subtopic).trim() === "")
      );
      return byTopic || null;
    };

    const toInsert = need.map(r => {
      const best = bestFor(r.topic, r.subtopic);
      return {
        user_id: uid,
        subject_id: subjectId,
        source_type: "practice",
        topic: r.topic,
        subtopic: r.subtopic,
        book_id: best?.book_id || null,
        book_reference: best?.book_reference || null
      };
    });

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

  // build unique recs by topic+subtopic
  const recMap = new Map();
  wrong.forEach(d => {
    const topic = String(d?.topic || "General").trim();
    const subtopic = d?.subtopic ? String(d.subtopic).trim() : null;
    const k = `${topic}::${subtopic || ""}`;
    if (!recMap.has(k)) recMap.set(k, { topic, subtopic });
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

    function normalizeNumericInput(v) {
    return String(v ?? "")
      .trim()
      .replace(/\s+/g, "")
      .replace(/,/g, ".")
      .replace(/−/g, "-")
      .replace(/×/g, "*");
  }

  function parseFlexibleScientificNumber(v) {
    const s0 = normalizeNumericInput(v);
    if (!s0) return null;

    let s = s0;

    // 1.5050*10^23  /  1.5050x10^23  /  1.5050×10^23
    s = s.replace(/^([+-]?\d+(?:\.\d+)?)(?:\*|x)10\^([+-]?\d+)$/i, "$1e$2");

    // обычное число или scientific e-формат
    if (!/^[+-]?\d+(?:\.\d+)?(?:e[+-]?\d+)?$/i.test(s)) return null;

    const n = Number(s);
    return Number.isFinite(n) ? n : null;
  }

  function areNumericAnswersEquivalent(a, b) {
    const na = parseFlexibleScientificNumber(a);
    const nb = parseFlexibleScientificNumber(b);

    if (na === null || nb === null) {
      return normalizeNumericInput(a) === normalizeNumericInput(b);
    }

    const diff = Math.abs(na - nb);
    const scale = Math.max(1, Math.abs(na), Math.abs(nb));

    return diff <= scale * 1e-9;
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
  function renderPracticeStart() {
    const subjectKey = state.courses.subjectKey;
    const subj = subjectByKey(subjectKey);

    // --- Subject title in hero card ---
    const titleEl = $("#practice-subject-title");
    if (titleEl) titleEl.textContent = subjectTitle(subjectKey, subj?.title || subjectKey || "—");

    const h = loadPracticeHistory(subjectKey);
    const best = h?.best || null;
    const last = Array.isArray(h?.last) ? h.last : [];

    const bestScoreEl = $("#practice-best-score");
    const bestPctEl = $("#practice-best-percent");
    const bestTimeEl = $("#practice-best-time");

    const formatSecShort = (sec) => {
      const s = Number(sec);
      if (!Number.isFinite(s) || s < 0) return "—";
      if (s < 60) return `${s}${t("practice_time_sec_suffix")}`;
      const m = Math.floor(s / 60);
      const r = s % 60;
      return `${m}${t("practice_time_min_suffix")} ${r}${t("practice_time_sec_suffix")}`;
    };

    if (best) {
      if (bestScoreEl) bestScoreEl.textContent = `${best.score}/${best.total}`;
      if (bestPctEl) bestPctEl.textContent = `(${best.percent}%)`;
      if (bestTimeEl) bestTimeEl.textContent = formatSecShort(best.durationSec);
    } else {
      if (bestScoreEl) bestScoreEl.textContent = "—";
      if (bestPctEl) bestPctEl.textContent = "";
      if (bestTimeEl) bestTimeEl.textContent = "—";
    }

    // --- Last attempts table (up to 5) ---
    const tbody = $("#practice-last-tbody");
    const emptyEl = $("#practice-last-empty");
    if (tbody) tbody.innerHTML = "";

    const rows = last.slice(0, 5);
    
    if (!rows.length) {
      if (emptyEl) emptyEl.style.display = "block";
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
     // Trend (>=2 attempts): bars + delta like screenshot
      renderTrendBars({
        wrapEl: document.getElementById("practice-micro-bars"),
        deltaEl: document.getElementById("practice-micro-delta"),
        attemptsNewestFirst: last,         // last is newest-first
        barClass: "practice-micro-bar",
        lastClass: "is-last"
      });
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

// UI: show loading first to avoid 1-sec "wrong screen" flicker
if (statusTitle) statusTitle.textContent = tr("loading", "Загрузка…");
if (statusDesc) statusDesc.textContent = tr("loading_desc", "Получаем список туров…");
if (openBtn) openBtn.classList.add("hidden");

// NULL dates = no restriction (ok for test)
const isInWindow = (row) => {
  const sd = row?.start_date ? String(row.start_date) : null;
  const ed = row?.end_date ? String(row.end_date) : null;
  const afterStart = !sd || sd <= todayISO;
  const beforeEnd = !ed || ed >= todayISO;
  return afterStart && beforeEnd;
};

let dbTours = [];
let toursErr = null;

// 1) Prefer join by subject_key (so we don't зависим от subjectId)
if (window.sb && subjectKey) {
  try {
    const { data, error } = await window.sb
      .from("tours")
      .select("id, subject_id, tour_no, start_date, end_date, is_active, subjects!inner(subject_key)")
      .eq("subjects.subject_key", String(subjectKey))
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
      .select("id, subject_id, tour_no, start_date, end_date, is_active")
      .eq("subject_id", subjectId)
      .order("tour_no", { ascending: true });

    if (error) toursErr = toursErr || error;
    if (!error && Array.isArray(data)) dbTours = data;
  } catch (e) {
    toursErr = toursErr || e;
  }
}

// pick active tour: is_active=true AND date window contains today
const activeTours = dbTours.filter(r => !!r.is_active && isInWindow(r));
const activeTour = activeTours.length ? activeTours[0] : null;

// save active tour context for start button / quiz
if (!state.courses) state.courses = {};
state.courses.activeTourId = activeTour?.id || null;
state.courses.activeTourNo = activeTour?.tour_no || null;

// label
if (tourLabelEl) {
  tourLabelEl.textContent = activeTour
    ? `${tr("tours_tour_label", "Тур")} ${activeTour.tour_no}`
    : tr("tours_status_title", "Туры пока недоступны");
}

// Status + Open button (DB)
if (!activeTour) {
  if (statusTitle) {
    statusTitle.textContent = tr("tours_status_title", "Туры пока недоступны");
  }

  // если есть ошибка чтения туров — показываем человеческий текст (а не “как будто туров нет”)
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
  }
} else {
  const sd = activeTour.start_date ? String(activeTour.start_date) : null;
  const ed = activeTour.end_date ? String(activeTour.end_date) : null;
  const dateTxt = (sd || ed) ? `${sd || "—"} → ${ed || "—"}` : "";

  // default: show active info
  if (statusTitle) {
    statusTitle.textContent = tr("tours_active_now", "Активный тур сейчас");
  }
  if (statusDesc) {
    statusDesc.textContent =
      `${tr("tours_tour_label", "Тур")} ${activeTour.tour_no}${dateTxt ? " • " + dateTxt : ""}`;
  }

  // ✅ if already attempted — show it here and hide "Open tour"
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
      // ✅ show start button for active tour
      openBtn.classList.remove("hidden");
      openBtn.style.display = "";
      openBtn.disabled = false;

      // Button title (fallback if missing in i18n)
      openBtn.textContent = tr("open_tour_btn", "Открыть тур");

      // start flow
      openBtn.onclick = () => openTourRules();
    }
  }
}
     try { await renderToursHistorySummary(subjectId); } catch {}
     
      saveState();
      } finally {
     hideToursLoading();
   }
  }

 // --------------------------------------
// Completed tours (DB summary by subject)
// Best = max percent, tie-break = min time
// --------------------------------------
async function renderToursHistorySummary(subjectId) {
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

  let attempts = [];
  try {
    const uid = await getAuthUid();
    if (window.sb && uid && subjectId) {
      const { data, error } = await window.sb
        .from("tour_attempts")
        .select("id, tour_id, score, percent, total_time, created_at, tours!inner(tour_no, subject_id)")
        .eq("user_id", uid)
        .eq("tours.subject_id", subjectId)
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
      handlePracticeSubmit(true);
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
  function openPracticeStart() {
  const subjectKey = state.courses.subjectKey;

  // Always open Practice Start screen first (premium UX)
  pushCourses("practice-start");
  renderPracticeStart();

  // If paused draft exists — show Resume button
  const draft = loadPracticeDraft();
  const resumeBtn = $("#practice-resume-btn");
  const restartBtn = $("#practice-restart-btn");

    const canResume = !!(
    draft?.status === "paused" &&
    draft?.subjectKey === subjectKey &&
    draft?.quiz &&
    Array.isArray(draft.quiz.questions) &&
    draft.quiz.questions.length > 0
  );

   if (resumeBtn) resumeBtn.style.display = canResume ? "block" : "none";
  if (restartBtn) restartBtn.textContent = canResume ? t("practice_restart") : t("practice_start");

  if (canResume) {
    showToast(t("practice_resume_prompt"));
  }
}

async function startPracticeNew() {
  const subjectKey = state.courses.subjectKey;

  // DB-first questions (may fallback to local automatically)
  const questions = await buildPracticeSet(subjectKey);

      if (!Array.isArray(questions) || questions.length === 0) {
    showToast(t("practice_no_questions") || "Нет вопросов для практики по этому предмету.");
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
    questions,
    answers: Array.from({ length: questions.length }).map(() => null),
    correct: Array.from({ length: questions.length }).map(() => false),

    qTimeLeft: Number(questions[0]?.timeLimitSec) || PRACTICE_CONFIG.timeByDifficulty[questions[0]?.difficulty] || 60,
    qEndsAtMs: null,   // ✅ NEW (deadline for current question)
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
      <div class="muted small">${escapeHTML(q.inputHint || "")}</div>
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

  function handlePracticeSubmit(isAutoTimeout = false) {
    const quiz = state.quiz;
    if (!quiz || quiz.mode !== "practice") return;

    const q = quiz.questions[quiz.index];
    const userAns = quiz.answers[quiz.index];

    // Validate: must have answer if manual submit
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

        // Evaluate correctness
    let isCorrect = false;

    if (q.type === "mcq") {
      const idx = (userAns === null || userAns === undefined) ? null : Number(userAns);
      if (idx !== null && idx === Number(q.correctIndex)) isCorrect = true;
    } else {
      const raw = String(userAns ?? "").trim();
      if (raw) {
        if (q.inputKind === "numeric") {
          isCorrect = areNumericAnswersEquivalent(raw, q.correctAnswer);
        } else {
          isCorrect = (raw.toLowerCase() === String(q.correctAnswer || "").trim().toLowerCase());
        }
      }
    }

    quiz.correct[quiz.index] = isCorrect;

    if (isAutoTimeout) {
      showToast(userAns ? t("toast_time_expired_answer_saved") : t("toast_time_expired_no_answer"));
    }

  // ---- time_spent per question (seconds) ----
  // We store: time_allowed - time_left at the moment of submit/timeout.
    const allowed = Number(q.timeLimitSec) || Number(PRACTICE_CONFIG.timeByDifficulty[q.difficulty]) || 60;
  const left = Number(quiz.qTimeLeft) || 0;

  if (!Array.isArray(quiz.timeSpent)) quiz.timeSpent = new Array(quiz.questions.length).fill(0);
  quiz.timeSpent[quiz.index] = Math.max(0, Math.min(allowed, allowed - left));

  // Next question or finish
  stopPracticeQuestionTimer();

  const nextIndex = quiz.index + 1;

    if (nextIndex >= quiz.questions.length) {
      finishPractice();
      return;
    }

       quiz.index = nextIndex;
    const nextQ = quiz.questions[quiz.index];
    quiz.qTimeLeft = Number(nextQ.timeLimitSec) || PRACTICE_CONFIG.timeByDifficulty[nextQ.difficulty] || 60;
    quiz.qEndsAtMs = null; // ✅ NEW: force recompute for next question

    saveState();
    renderPracticeQuiz();
    startPracticeQuestionTimer();
  }

  function finishPractice() {
    const quiz = state.quiz;
    if (!quiz || quiz.mode !== "practice") return;

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
     explanation: q.explanation || ""
   };
 });

     const attempt = {
      ts: finishedAt,
      subjectKey: quiz.subjectKey,
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

// state for result/review/recs screens (DO NOT lose db info)
// ✅ drills must NOT overwrite "last practice" UX
if (!quiz?.drillType) {
  state.practiceLastAttempt = {
    ...(attempt || {}),
    db: (state.practiceLastAttempt && state.practiceLastAttempt.db) ? state.practiceLastAttempt.db : null
  };
}

// ✅ DB-first: save attempt + answers to Supabase (non-blocking UX)
(async () => {
  // DEBUG 1: we entered DB save branch
  try {
    trackEvent("practice_db_save_started", {
      subject_key: quiz?.subjectKey || null,
      attempt_key,
      score: attempt?.score ?? null,
      percent: attempt?.percent ?? null
    });
  } catch {}

  try {
  // ✅ Variant A: drills (retry_mistakes / topic_drill) do NOT write to practice_attempts
  let res = { ok: true, reason: "drill_no_db" };

  if (!quiz?.drillType) {
    res = await savePracticeAttemptToSupabase(attempt, quiz);

    if (res?.ok) {
      clearPracticeDraft();
    } else {
      // ✅ offline-safe: queue practice save for retry after reconnect
           enqueuePendingOp({
        type: "practice_save",
        payload: buildPracticeSavePayload(attempt, quiz)
      });
    }
  } else {
    // drill: never clear normal draft, never enqueue DB save
  }

    // DEBUG 2: DB save result
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

    // merge db result into current attempt without overwriting the attempt object
    if (!quiz?.drillType) {
  state.practiceLastAttempt = { ...(state.practiceLastAttempt || attempt || {}), db: res };
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
  meta.textContent =
    `Score: ${attempt.score}/${attempt.total} (${attempt.percent}%) • ${attempt.durationSec}s` +
    ` • ${t("practice_errors")}: ${wrong.length}` +
    ` • ${t("practice_topics")}: ${recKeys.length}`;
}

const reviewCountEl = $("#practice-review-count");
if (reviewCountEl) reviewCountEl.textContent = String(wrong.length);

const recsCountEl = $("#practice-recs-count");
if (recsCountEl) recsCountEl.textContent = String(recKeys.length);

// ✅ set “exit” button label based on context (main vs drill)
try {
  const exitKey = quiz?.drillType ? "practice_to_recs" : "practice_to_subject";
  const btn1 = $("#practice-to-subject-btn");
  const btn2 = $("#practice-review-to-subject-btn");
  if (btn1) btn1.textContent = t(exitKey);
  if (btn2) btn2.textContent = t(exitKey);
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
    hx = updatePracticeHistory(quiz.subjectKey, attempt);
  } catch (e) {
    try { trackEvent("practice_history_error", { message: String(e?.message || e || "unknown") }); } catch {}
  }

  // Optional: toast best update
  if (hx && hx.best && hx.best.ts === attempt.ts) {
    showToast(t("practice_best_new_toast") || "Новый лучший результат");
  }

  // badges / subject widgets rely on main practice only
  syncPracticeResultBadges(attempt);
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
      left.innerHTML = `
        <div style="font-weight:900">${escapeHTML(topic)}</div>
        <div class="muted small">Вопросов: ${totalCount} • Ошибок: ${wrongCount}</div>
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

        // ✅ pretty answers: convert "0/1/2/3" -> "A/B/C/D" and show text if available
let userDisp = "";
let corrDisp = "";
try {
  const qForFmt = {
    // formatAnswerForDisplay reads options_text; we pass options as JSON
    options_text: Array.isArray(d.options) ? JSON.stringify(d.options) : (d.options_text || null)
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
      // fallback to local
      const localDetails = Array.isArray(attempt?.details) ? attempt.details : [];
      renderFromDetails(localDetails);
      return;
    }

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

      // 3) normalize into the same "details" shape UI expects
            const contentLang = (loadProfile()?.language) || "ru";
      const pickL = (obj, base) => {
        const k = contentLang === "uz" ? (base + "_uz") : contentLang === "en" ? (base + "_en") : (base + "_ru");
        const v = (obj && obj[k] != null) ? String(obj[k]).trim() : "";
        // ✅ правильный fallback: сначала локализованное, потом base
        return v !== "" ? obj[k] : (obj?.[base] ?? "");
      };

      const details = (ansRows || []).map((a) => {
  const q = qMap.get(Number(a.question_id)) || null;

  let type = "mcq";
  if (q?.qtype) type = String(q.qtype);

  let difficulty = q?.difficulty ? String(q.difficulty) : "easy";

  // ✅ options по content language
  let options = null;
  const optionsRaw = q ? pickL(q, "options_text") : null;
  if (optionsRaw) {
    try {
      const parsed = JSON.parse(String(optionsRaw));
      if (Array.isArray(parsed)) options = parsed.map(x => String(x));
    } catch {}
  }

  const ua = (a.user_answer === null || a.user_answer === undefined) ? "" : String(a.user_answer);
  const ca = (q?.correct_answer === null || q?.correct_answer === undefined) ? "" : String(q.correct_answer);

  const toIdx = (raw) => {
    const s = String(raw || "").trim();
    if (!s) return null;

    if (isNumericLike(s)) {
      return Math.trunc(Number(s));
    }

    const li = letterToIdx(s);
    return (li !== null && li >= 0) ? li : null;
  };

  let normalizedIsCorrect = !!a.is_correct;

  if (String(type).toLowerCase() === "mcq") {
    const uaIdx = toIdx(ua);
    const caIdx = toIdx(ca);

    if (uaIdx !== null && caIdx !== null) {
      normalizedIsCorrect = (uaIdx === caIdx);
    } else {
      const uaDisp = formatAnswerForDisplay(q, ua);
      const caDisp = formatAnswerForDisplay(q, ca);

      if (uaDisp && caDisp && uaDisp === caDisp) {
        normalizedIsCorrect = true;
      }
    }
  }

  return {
    id: Number(a.question_id),
    topic: q?.topic || "General",
    subtopic: q?.subtopic || null,
    difficulty,
    type,
    question: q ? (pickL(q, "question_text") || "") : "",
    options,
    userAnswer: ua || "—",
    correctAnswer: ca || "—",
    explanation: q ? (pickL(q, "explanation") || "") : "",
    isCorrect: normalizedIsCorrect,
    timeSpent: Number(a.time_spent) || 0
  };
});

      // 4) render DB-first
      renderFromDetails(details);

    } catch (e) {
      // fallback
      try { trackEvent("practice_review_db_crash", { message: String(e?.message || e || "unknown"), attempt_id: dbAttemptId || null }); } catch {}
      try {
        const uid = await getAuthUid();
        await logDbErrorToEvents(uid, "practice_review_db_crash", e, { attempt_id: dbAttemptId || null });
      } catch {}

      const localDetails = Array.isArray(attempt?.details) ? attempt.details : [];
      renderFromDetails(localDetails);
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

    const attempt = state.practiceLastAttempt;
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
        btn?.addEventListener("click", (e) => {
          e.stopPropagation();
          pushCourses("books");
          renderBooks();
        });

        wrap.appendChild(item);
      });
    })();
  }

async function fetchMyRecsDB(subjectKey) {
  try {
    if (!window.sb) return [];

    const uid = await getAuthUid();
    if (!uid) return [];

    const subjectId = await getSubjectIdByKey(subjectKey);
    if (!subjectId) return [];

    const { data, error } = await window.sb
  .from("recommendations")
  .select("id, source_type, tour_no, topic, subtopic, book_id, book_reference, created_at")
  .eq("user_id", uid)
  .eq("subject_id", subjectId)
  .order("created_at", { ascending: false })
  .limit(100);

    if (error) {
      logClientError("myrecs_select_error", error);
      return [];
    }
    return Array.isArray(data) ? data : [];
  } catch (e) {
    logClientError("myrecs_select_exception", e);
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

  wrap.innerHTML = `<div class="empty muted">${escapeHTML(t("loading") || "Загрузка…")}</div>`;

    // DB-first for both practice and tour
  const dbRows = await fetchMyRecsDB(subjectKey);

  let practiceRows = dbRows.filter(r => String(r?.source_type || "") === "practice");
  let tourRows = dbRows
    .filter(r => String(r?.source_type || "") === "tour")
    .map(r => ({
      ...r,
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
      book_id: null,
      book_reference: null,
      created_at: x.ts ? new Date(x.ts).toISOString() : null
    }));
  }

  if (practiceRows.length) {
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

  // TOUR fallback only if DB has nothing yet
  if (!tourRows.length) {
    const tourStore = loadMyTourRecs();
    tourRows = (tourStore?.bySubject?.[subjectKey] || []).map(x => ({
      id: null,
      source_type: "tour",
      topic: x.topic || "General",
      subtopic: x.subtopic || null,
      created_at: x.ts ? new Date(x.ts).toISOString() : null,
      tourNo: Number(x.tourNo || 0) || null
    }));
  }
        try {
    if (!dbRows.some(r => String(r?.source_type || "") === "tour") && tourRows.length) {
      const byTour = new Map();
      tourRows.forEach(r => {
        const key = Number(r?.tourNo || 0) || 0;
        if (!key) return;
        if (!byTour.has(key)) byTour.set(key, []);
        byTour.get(key).push(r);
      });

      for (const [tourNo, recs] of byTour.entries()) {
        await saveTourRecsToDB(subjectKey, tourNo, recs);
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

      return `
        <div class="list-item" data-open-rec="practice">
          <div style="font-weight:900">${escapeHTML(rec.topic || "General")}</div>
          ${sub ? `<div class="muted small" style="margin-top:4px">${escapeHTML(sub)}</div>` : ""}
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
      const tourNo = Number(el.getAttribute("data-tour-no") || 0);
      const rec = {
        id: el.getAttribute("data-rec-id") ? Number(el.getAttribute("data-rec-id")) : null,
        source_type: "tour",
        topic: String(el.getAttribute("data-topic") || "").trim() || "General",
        subtopic: String(el.getAttribute("data-subtopic") || "").trim() || null,
        created_at: String(el.getAttribute("data-created-at") || "").trim() || null,
        book_reference: String(el.getAttribute("data-book-reference") || "").trim() || null,
        tourNo
      };

      const canOpen = tourNo > 0
        ? await isTourGloballyClosed(subjectKey, tourNo)
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
  if (titleEl) titleEl.textContent = topic;
  if (subEl) {
    subEl.textContent = isTourRec
      ? (subtopic || (t("tour_rec_detail_subtitle") || "Рекомендации по итогам тура"))
      : (subtopic ? subtopic : (t("rec_detail_subtitle") || "Персональный разбор и план"));
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
        <div style="font-weight:900">${escapeHTML(t("rec_drill_mini_title") || "Natija")}</div>
        <div class="muted small" style="margin-top:6px">${escapeHTML(line)}</div>
        <div style="margin-top:10px">
          <button class="btn" type="button" data-action="my-rec-repeat-drill">
            ${escapeHTML(t("rec_drill_repeat") || "Yana bir bor")}
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
      <div style="font-weight:900">${escapeHTML(t("rec_mistakes_title") || "Ошибки по теме")}</div>
      <span class="pill">${escapeHTML(String(totalMistakes))}</span>
    </div>
    <div class="muted small" style="margin-top:6px">
      ${escapeHTML(t("rec_mistakes_subtitle") || "Ваши последние неправильные ответы по этой теме.")}
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
            <div style="font-weight:900">${escapeHTML(t("rec_mistake_card_title") || "Ошибка")}</div>
            <span class="pill">${escapeHTML(num)}</span>
          </div>

          <div style="margin-top:6px">${escapeHTML(qText || "")}</div>

          <div class="muted small" style="margin-top:8px">
            ${escapeHTML(t("rec_your_answer") || "Ваш ответ")}: ${escapeHTML(uaDisp)}
          </div>

          <div class="muted small">
            ${escapeHTML(t("rec_correct_answer") || "Правильный")}: ${escapeHTML(caDisp)}
          </div>

          ${expl ? `
            <details style="margin-top:10px">
              <summary class="muted small" style="cursor:pointer;font-weight:800">
                ${escapeHTML(t("rec_show_expl") || "Пояснение")}
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
        ${escapeHTML(t("rec_no_mistakes_text") || "По этой теме пока нет зафиксированных ошибок.")}
      </div>
    </div>
  `;
   
        const refsHtml = refs.length
  ? refs.map(r => {
      const title = r.title ? escapeHTML(r.title) : (r.book_id ? `Книга #${escapeHTML(String(r.book_id))}` : "Книга");
      const ref = r.book_reference ? `• ${escapeHTML(String(r.book_reference))}` : "";
      const has = !!r.file_url;
      return `
        <div class="list-item">
          <div style="font-weight:900">${title}</div>
          ${ref ? `<div class="muted small" style="margin-top:6px">${ref}</div>` : ""}
          ${has ? `<div style="margin-top:10px"><button class="btn" type="button" data-open-book-url="${escapeHTML(r.file_url)}">${escapeHTML(t("rec_open_book") || "Открыть")}</button></div>` : ""}
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
      .select("id, topic, subtopic, difficulty, time_limit_sec, qtype, question_text, options_text, correct_answer, explanation, image_url, is_active, question_text_ru, question_text_uz, question_text_en, options_text_ru, options_text_uz, options_text_en, explanation_ru, explanation_uz, explanation_en")
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
      .select("id, topic, subtopic, difficulty, time_limit_sec, qtype, question_text, options_text, correct_answer, explanation, image_url, is_active, question_text_ru, question_text_uz, question_text_en, options_text_ru, options_text_uz, options_text_en, explanation_ru, explanation_uz, explanation_en")
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
      inputHint: type === "input" ? (isNumericLike(correctAnswer) ? "Введите число" : "Введите ответ") : ""
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
    .select("id, topic, subtopic, difficulty, time_limit_sec, qtype, question_text, options_text, correct_answer, explanation, image_url, is_active, question_text_ru, question_text_uz, question_text_en, options_text_ru, options_text_uz, options_text_en, explanation_ru, explanation_uz, explanation_en")
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
      inputHint: type === "input" ? (isNumericLike(correctAnswer) ? "Введите число" : "Введите ответ") : ""
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

async function loadActiveTourBySubjectAndNo(subjectId, tourNo) {
  if (!window.sb || !subjectId || !tourNo) return null;

  const { data, error } = await window.sb
    .from("tours")
    .select("id,subject_id,tour_no,start_date,end_date,is_active")
    .eq("subject_id", subjectId)
    .eq("tour_no", tourNo)
    .eq("is_active", true)
    .maybeSingle();

  if (error) return null;
  return data || null;
}

async function loadTourQuestionsDB(tourId) {
  if (!window.sb || !tourId) return null;

    const { data, error } = await window.sb
  .from("tour_questions")
  .select("order_no, question:questions(id,topic,subtopic,difficulty,qtype,question_text,options_text,correct_answer,image_url,is_active,question_text_ru,question_text_uz,question_text_en,options_text_ru,options_text_uz,options_text_en)")
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
    await dbWriteWithRetry(async () => {
      const { error } = await window.sb
        .from("tour_attempts")
        .update({
          score: Number(patch.score || 0),
          percent: Number(patch.percent || 0),
          total_time: Number(patch.total_time || 0),
          status: String(patch.status || "submitted")
        })
        .eq("id", attemptId);

      if (error) throw error;
      return true;
    }, { tries: 3, baseDelayMs: 350 });

    return { ok: true };
  } catch (e) {
    try { trackEvent("tour_db_save_failed", { attempt_id: String(attemptId), message: String(e?.message || e) }); } catch {}
    return { ok: false, reason: "db_error", error: e };
  }
}

  function initTourSession({ subjectKey = null, tourNo = 1, tourId = null, attemptId = null, questions = [], isArchive = false } = {}) {
  state.tourContext = {
    isArchive,
    subjectKey,
    tourNo,
    tourId,        // ✅ DB tour id
    attemptId,     // ✅ DB attempt id (null for archive)
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

  // 1) eligibility: only school students can participate (tours/ratings)
  const uid = await getAuthUid();
  const me = uid ? await getUserProfile(uid) : null;

  if (!me?.is_school_student) {
    await uiAlert({
      title: t("disabled_title") || t("not_available"),
      message: t("tour_disabled_nonstudent") || "Туры доступны только для школьников."
    });
    return;
  }

  // 2) resolve subject_id and active tour (tour_no=1 for now; later from UI selection)
  const subjectId = await getSubjectIdByKey(subjectKey);
  if (!subjectId) {
    showToast(t("toast_subject_id_not_found"));
    return;
  }

  const tourNo = 1; // TODO: take selected tour from Tours List
  const tour = await loadActiveTourBySubjectAndNo(subjectId, tourNo);

  if (!tour?.id) {
    await uiAlert({
      title: t("tour_unavailable_title") || "Тур недоступен",
      message: t("tour_unavailable_no_active") || "Нет активного тура для этого предмета."
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
      subject_id: String(subjectId),
      subject_key: String(subjectKey || "")
    });
  } catch {}

  initTourSession({
    subjectKey,
    tourNo,
    tourId: tour.id,
    attemptId,
    questions,
    isArchive: false
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
      finishTour({ reason: "violations" });
      return;
    }

    // 2) per-question timeout: auto submit if exceeded and not answered for this question index
    const qElapsed = Math.floor((monoNow() - (ctx.qStartedAtMono ?? ctx.qStartedAt)) / 1000);
    if (qElapsed >= ctx.questionTimeLimit) {
      if (!ctx.answers.some(a => a.index === ctx.index)) {
        submitTourAnswer({ pickedIndex: null, auto: true });
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

    const warnBtn = $("#tour-warn-btn");
    if (warnBtn) warnBtn.style.display = "inline-flex";

    const warnPill = $("#tour-anti-cheat"); // legacy id might exist elsewhere
    if (warnPill) warnPill.style.display = "inline-flex";

    showToast(t("tour_violation_toast", { v: ctx.violations, max: TOUR_CONFIG.maxViolations }));
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
    finishTour({ reason: "done" });
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
  `;

  wrap.appendChild(inputWrap);

  const inputEl = inputWrap.querySelector("#tour-input");

  const nextBtn =
    $("#tour-next-btn") ||
    $("#quiz-next-btn") ||
    document.querySelector('[data-action="tour-next"]');

  if (nextBtn) {
  nextBtn.disabled = true; // ⛔ пока пусто

  const isLast = (ctx.index >= TOUR_CONFIG.total - 1);
  nextBtn.textContent = isLast
    ? (t("tour_finish_button") || "Finish Tour →")
    : (t("tour_next_question") || "Next Question →");
}

  // ✅ активируем Next только когда есть ввод
  if (inputEl && nextBtn) {
    inputEl.addEventListener("input", () => {
      nextBtn.disabled = inputEl.value.trim().length === 0;
    });
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

    function submitTourAnswer({ pickedIndex, auto = false } = {}) {
    const ctx = state.tourContext;
    if (!ctx) return;

    const q = ctx.questions?.[ctx.index];
    if (!q) return;

    const spentSec = Math.max(0, Math.floor((monoNow() - (ctx.qStartedAtMono ?? ctx.qStartedAt)) / 1000));

    // normalize correct index (supports both correctIndex and legacy correct_index)
    const correctIdx =
      (q.correctIndex !== undefined && q.correctIndex !== null) ? Number(q.correctIndex)
      : (q.correct_index !== undefined && q.correct_index !== null) ? Number(q.correct_index)
      : null;

        // normalize question type (DB uses qtype, older code may use type)
    const qType =
      (q?.qtype != null ? String(q.qtype) : (q?.type != null ? String(q.type) : "mcq"))
        .toLowerCase();
    const isMcq = (qType === "mcq" || qType === "multiple_choice");

    const pickedNum = (pickedIndex === null || pickedIndex === undefined) ? null : Number(pickedIndex);

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
    const isNumericInputQuestion = (!isMcq && expected !== "" && parseFlexibleScientificNumber(expected) !== null);

    // correctness
    const isCorrect = isMcq
      ? ((pickedNum !== null && correctIdx !== null) ? (pickedNum === correctIdx) : false)
      : (
          expected
            ? (
                isNumericInputQuestion
                  ? areNumericAnswersEquivalent(inputVal, expected)
                  : (inputVal.toLowerCase() === expected.toLowerCase())
              )
            : false
        );

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

    // DB autosave (only for active tour) — fire-and-forget (no await inside non-async fn)
    try {
      const ctx2 = state.tourContext;
      if (ctx2?.attemptId && q?.id && !ctx2?.isArchive) {
                const spentSec2 = Math.max(0, Math.round((Date.now() - (ctx2.qStartedAt || Date.now())) / 1000));
        const pickedForDb = (pickedNum === null ? "" : (idxToLetter(pickedNum) || String(pickedNum)));

        // if someday you add input questions, this will safely read it (otherwise empty)
        const inputEl = document.getElementById("tour-input");
        const inputVal = inputEl ? String(inputEl.value || "").trim() : "";

        const answerForDb = isMcq ? pickedForDb : inputVal;

               Promise
          .resolve(upsertTourAnswer(ctx2.attemptId, q.id, {
            user_answer: answerForDb,
            answered: true,
            is_correct: isCorrect,
            time_spent: spentSec2
          }))
          .then((res) => {
            if (!res?.ok) {
              ctx2.pendingDbAnswers = Array.isArray(ctx2.pendingDbAnswers) ? ctx2.pendingDbAnswers : [];
              ctx2.pendingDbAnswers.push({
                attemptId: ctx2.attemptId,
                questionId: q.id,
                patch: {
                  user_answer: answerForDb,
                  answered: true,
                  is_correct: isCorrect,
                  time_spent: spentSec2
                }
              });
              saveState();
            }
          })
          .catch(() => {
            ctx2.pendingDbAnswers = Array.isArray(ctx2.pendingDbAnswers) ? ctx2.pendingDbAnswers : [];
            ctx2.pendingDbAnswers.push({
              attemptId: ctx2.attemptId,
              questionId: q.id,
              patch: {
                user_answer: answerForDb,
                answered: true,
                is_correct: isCorrect,
                time_spent: spentSec2
              }
            });
            saveState();
          });
      }
        } catch {}

    // anti-slip: current answered question no longer needs secrets in runtime
    stripAnsweredTourQuestionInRuntime(ctx, ctx.index);

    // clear transient pick cache before moving on
    ctx._pickedIndex = null;

    // next index
    ctx.index += 1;
    saveState();

    if (ctx.index >= TOUR_CONFIG.total) {
      finishTour({ reason: auto ? "auto_done" : "done" });
      return;
    }

    renderTourQuestion();
  }

         async function isTourGloballyClosed(subjectKey, tourNo) {
  try {
    if (!window.sb) return false;

    const subjectId = await getSubjectIdByKey(subjectKey);
    if (!subjectId) return false;

    const { data, error } = await window.sb
      .from("tours")
      .select("id, tour_no, start_date, end_date, is_active")
      .eq("subject_id", subjectId)
      .eq("tour_no", Number(tourNo || 0))
      .maybeSingle();

    if (error || !data) return false;

    const todayISO = new Date().toISOString().slice(0, 10);
    const endDate = data?.end_date ? String(data.end_date) : "";

    if (endDate && endDate < todayISO) return true;
    if (!data?.is_active && endDate && endDate <= todayISO) return true;

    return false;
  } catch {
    return false;
  }
}
   
   async function renderTourReview() {
  const wrap = $("#tour-review-list");
  if (!wrap) return;

  wrap.innerHTML = `<div class="empty muted">${escapeHTML(t("loading") || "Загрузка…")}</div>`;

  const attemptId = Number(state?.courses?.lastTourAttemptId || 0);
  const localPayload = state?.courses?.lastTourReviewPayload || null;

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
  if (localPayload && Array.isArray(localPayload.items) && localPayload.items.length) {
    renderFromDetails(localPayload.items);
  }

  // 2) DB-backed version (authoritative)
  if (!window.sb || !attemptId) {
    if (!(localPayload && Array.isArray(localPayload.items) && localPayload.items.length)) {
      renderFromDetails([]);
    }
    return;
  }

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
      if (!(localPayload && Array.isArray(localPayload.items) && localPayload.items.length)) {
        renderFromDetails([]);
      }
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
    if (!(localPayload && Array.isArray(localPayload.items) && localPayload.items.length)) {
      renderFromDetails([]);
    }
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
  const score = Number(ctx?.correct || 0);
  const percent = total ? Math.round((score / total) * 100) : 0;

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
        score: ctx.correct,
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

    trackEvent("tour_attempt_finished", {
      ts,
      status: "done",
      tour_id,
      is_archive,
      subject_id: String(subject_id || ""),
      subject_key: String(ctx?.subjectKey || state?.courses?.subjectKey || "")
    });
  } catch {}

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

    // локально сохраняем туровые рекомендации по ошибкам
    addMyTourRecsFromTourAttempt(ctx);
  } catch {
    state.courses.lastTourReviewPayload = null;
  }

  if (!state.certificates) {
    state.certificates = { selectedId: null, lastIssuedId: null };
  }

  // try to issue certificate only after successful DB finalize
    if (
    finalizeSavedToDb &&
    ctx?.attemptId &&
    !ctx?.isArchive &&
    reason !== "violations"
  ) {
    try {
      const certRow = await issueTourCertificateDb(ctx.attemptId);
      if (certRow?.id) {
        state.courses.lastTourCertificateId = Number(certRow.id);
        state.certificates.selectedId = Number(certRow.id);
        state.certificates.lastIssuedId = Number(certRow.id);
      }

      const subjectKey = state?.courses?.subjectKey || null;
      if (subjectKey) {
        const subjectId = await getSubjectIdByKey(subjectKey).catch(() => null);
        if (subjectId) {
          await tryIssueFinalCertificateForSubject(subjectId).catch(() => null);
        }
      }
    } catch {}
  }

   // unlock
  state.quizLock = null;
  state.tourContext = null;
  saveState();

  pushCourses("tour-result");

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

  const handle = (btn) => {
    const tab = btn.dataset.tab;
    if (!tab) return;
    
     // ✅ До регистрации табы запрещены (и на registration таббар скрыт, но это страховка)
  const p0 = loadProfile();
  if (!p0) {
    showToast(t("complete_registration_first") || "Сначала завершите регистрацию.");
    showView("registration");
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
      handle(btn);

      // ✅ убираем “липкий” focus на мобилках
      try { btn.blur(); } catch {}
    });

    // ✅ Desktop fallback
    btn.addEventListener("click", () => {
      handle(btn);
      try { btn.blur(); } catch {}
    });
  });
}

  function bindTopbar() {
    const backBtn = $("#topbar-back");
    if (!backBtn) return;

    backBtn.addEventListener("click", (event) => {
  event.stopPropagation();
  if (state.quizLock) return;

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
  if (topView && ["resources","news","notifications","community","about","certificates","archive"].includes(topView)) {
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
    if (isSchool) isSchool.addEventListener("change", updateSchoolFieldsVisibility);
    if (isSchoolToggle) {
      isSchoolToggle.addEventListener("change", updateSchoolFieldsVisibility);
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

    form.addEventListener("submit", async (e) => {
  e.preventDefault();

    const submitBtn = form.querySelector('button[type="submit"]');
  const __prevSubmitText = submitBtn ? submitBtn.textContent : null;

  if (submitBtn) {
    submitBtn.disabled = true;
    submitBtn.textContent = (t("saving") || "Сохранение…");
    submitBtn.classList.add("is-loading");
  }

  try {
    const fullName = $("#reg-fullname")?.value?.trim() || "";
    const lang = $("#reg-language")?.value || "ru";

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

    // district required ONLY when select is enabled and has real options
    const districtRequired =
      !!districtEl &&
      !districtEl.disabled &&
      (districtEl.options?.length || 0) > 1;

    if (
      !fullName ||
      !region ||
      (districtRequired && !district) ||
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
      showToast("Не удалось сохранить регистрацию в базе. Попробуйте ещё раз.");
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

      saveProfile(profile);

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

      // порядок важен: сначала активируем таб, потом рисуем
      setTab("home");
      renderHome();
      renderAllSubjects();
        } finally {
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

  // ✅ FALLBACK: если видим settings профиля, но state.tab почему-то не "profile"
  const ps = document.getElementById("profile-settings");
  const psActive = ps && ps.classList.contains("is-active") && ps.hidden !== true;
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

  if (topView && ["resources","news","notifications","community","about","certificates","archive"].includes(topView)) {
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
      if (action === "open-notifications") { openGlobal("notifications"); return; }
      if (action === "open-news") {
  // Telegram channel (news live here)
  openTelegramUrl("https://t.me/iClubuzofficial");
  return;
}

if (action === "open-community") {
  // Telegram chat (community)
  openTelegramUrl("https://t.me/+yp3GKhnohKQxOTdi");
  return;
}
      if (action === "open-about") { openGlobal("about"); return; }

if (action === "open-subject-mentor") {
  const mentor = state?.courses?.subjectHubMentor;
  if (!mentor) return;

  if (!state.about) state.about = { tab: "project" };
  state.about.tab = "team";
  state.about.teamEntry = "subject";
  state.about.teamPrevScreen = "mentors";
  state.about.teamScreen = "member";
  state.about.teamPeopleResolved = state.about.teamPeopleResolved || {};
  state.about.teamPeopleResolved.mentors = [{
    ...mentor,
    group: "mentors",
    vacant: false,
    memberKey: memberKeyOf(mentor)
  }];
  state.about.teamMemberKey = memberKeyOf(mentor);
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

  const src = state.about.teamPeopleResolved?.[group];
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

        if (!state.certificates) {
          state.certificates = { selectedId: null, lastIssuedId: null };
        }

        state.certificates.selectedId = certId;
        saveState();

        await renderCertificatesView();
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

  replaceCourses("my-recs");
  renderMyRecs();
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
  // назад к списку рекомендаций
  replaceCourses("my-recs");
  renderMyRecs();
  return;
}

if (action === "my-rec-open-books") {
  pushCourses("books");
  renderBooks();
  return;
}
   if (action === "my-rec-open-practice") {
  openPracticeStart();
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

if (action === "profile-open-ratings") {
  setTab("ratings");
  return;
}

      // Courses actions
      if (action === "to-subject-hub") {
        // ✅ after drills: go back to My Rec Detail (AI tutor), not Subject Hub
try {
  const d = state?.courses?.myRecDrillLast;
  if (d?.drillType && state?.courses?.myRecReturnTarget === "my-rec-detail") {
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
        pushCourses("lessons");
        renderLessons();
        return;
      }

      if (action === "open-practice") {
        openPracticeStart();
        return;
      }

      if (action === "practice-start") {
        startPracticeNew();
        return;
      }

   if (action === "practice-resume") {
  const subjectKey = state.courses.subjectKey;
  const draft = loadPracticeDraft();
  if (!(draft?.status === "paused" && draft?.subjectKey === subjectKey && draft?.quiz)) {
    showToast(t("not_available"));
    return;
  }

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
        handlePracticeSubmit(false);
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

  submitTourAnswer({ pickedIndex: picked, auto: false });
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
          showToast(
            t("tour_review_locked_until_global_end") ||
            "Подробный разбор тура будет доступен после завершения тура для всех участников."
          );
          replaceCourses("subject-hub");
          renderSubjectHub();
          return;
        }

        pushCourses("tour-review");
        await renderTourReview();
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
        openPracticeStart();
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
        pushCourses("books");
        renderBooks();
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

        pushCourses("my-recs");
        renderMyRecs();
        return;
      }

      if (action === "video-skip") {
        const subject_id = state?.courses?.subjectKey ? String(state.courses.subjectKey) : (state?.activeSubjectKey ? String(state.activeSubjectKey) : "");
        const lesson_id = state?.courses?.lessonId ? String(state.courses.lessonId) : "";
        trackEvent("video_skipped", { subject_id, lesson_id });

        try {
          const ws = (ytPlayer && typeof ytPlayer.getCurrentTime === 'function') ? Math.round(ytPlayer.getCurrentTime()) : 0;
          if (ytPlayer && typeof ytPlayer.stopVideo === 'function') ytPlayer.stopVideo();
          
          const iframe = document.getElementById("video-player");
          if (iframe && iframe.tagName === "IFRAME") iframe.removeAttribute("src");
          
          insertVideoEventToSupabase("skipped", lesson_id, ws);
        } catch {}

        openPracticeStart();
        return;
      }

      if (action === "video-complete") {
        const subject_id = state?.courses?.subjectKey ? String(state.courses.subjectKey) : (state?.activeSubjectKey ? String(state.activeSubjectKey) : "");
        const lesson_id = state?.courses?.lessonId ? String(state.courses.lessonId) : "";
        trackEvent("video_completed", { subject_id, lesson_id });

        try {
          const ws = (ytPlayer && typeof ytPlayer.getCurrentTime === 'function') ? Math.round(ytPlayer.getCurrentTime()) : 0;
          if (ytPlayer && typeof ytPlayer.stopVideo === 'function') ytPlayer.stopVideo();
          
          const iframe = document.getElementById("video-player");
          if (iframe && iframe.tagName === "IFRAME") iframe.removeAttribute("src");
          
          insertVideoEventToSupabase("completed", lesson_id, ws);
        } catch {}

        openPracticeStart();
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

        // ✅ gentle periodic flush (in case events were missed)
        setInterval(() => {
          try { scheduleFlushPendingOps(0); } catch {}
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

// Stage B2: always sync user_subjects from DB → local profile (single source for UI)
try { await syncUserSubjectsFromSupabaseIntoLocalProfile(); } catch {}

      const verifyCertificateNumber = getVerifyCertificateNumberFromUrl();
      if (verifyCertificateNumber) {
        showView("certificate-verify");
        await renderCertificateVerifyView(verifyCertificateNumber);
        return;
      }

      if (!isRegistered()) {
        showView("registration");
        bindRegistration();
        return;
      }

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

  // Practice: attempts_count>=5 как мягкий прогресс (без новых правил) — показываем только если есть счётчики
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
    // мягко: если opens>=2 или days>=1, показываем только когда близко к 60%
    if (opens >= 2 || days >= 1) return t("cred_progress_research", { x: String(opens), y: String(days) });
    return "";
  }

  return "";
}

function renderProfileCredentialsUI() {
  const grid = document.querySelector(".profile-credentials-grid");
  if (!grid) return;

  const hints = document.getElementById("profile-credentials-hints"); // если есть в HTML
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

  // Иконки нейтральные, “академические”
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

    // “Earned Credentials” = только active
    if (status === "active") {
      actives.push({ key: k, title, statusText, achieved, status });
    }

    // Progress hints (>=60%) — собираем отдельно
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

  // 2) Progress (выводим, если есть контейнер)
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
}

     // Earned Credentials — daily evaluation jobs (once per Tashkent day)
  try { runDailyCredentialJobs(); } catch {}

    // Init
  bindUI();
  boot();

})();
